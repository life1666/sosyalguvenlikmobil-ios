import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PremiumTrialPhase { signedOut, available, active, expired }

class PremiumTrialStatus {
  static const duration = Duration(days: 7);

  final PremiumTrialPhase phase;
  final DateTime? startedAt;

  const PremiumTrialStatus(this.phase, {this.startedAt});

  DateTime? get endsAt => startedAt?.add(duration);

  int get daysRemaining {
    final end = endsAt;
    if (end == null) return 0;
    final seconds = end.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) return 0;
    return (seconds / Duration.secondsPerDay).ceil();
  }
}

/// Deneme başlangıcı hesaba bağlı olarak sunucuda bir kez kaydedilir.
class PremiumTrialService {
  PremiumTrialService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<PremiumTrialStatus> load() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const PremiumTrialStatus(PremiumTrialPhase.signedOut);
    }
    final document = _firestore.collection('premium_trials').doc(user.uid);
    final prefs = await SharedPreferences.getInstance();
    final lastSeenKey = 'premium_trial_last_seen_${user.uid}';
    final confirmedKey = 'premium_trial_confirmed_${user.uid}';
    final now = DateTime.now();
    final lastSeen = prefs.getInt(lastSeenKey);
    final clockMovedBack = lastSeen != null &&
        now.isBefore(DateTime.fromMillisecondsSinceEpoch(lastSeen));

    DocumentSnapshot<Map<String, dynamic>> snapshot;
    var offline = false;
    try {
      snapshot = await document.get(const GetOptions(source: Source.server));
    } on FirebaseException catch (error) {
      if (error.code != 'unavailable' && error.code != 'deadline-exceeded') {
        rethrow;
      }
      snapshot = await document.get(const GetOptions(source: Source.cache));
      offline = true;
    }
    if (!snapshot.exists) {
      return const PremiumTrialStatus(PremiumTrialPhase.available);
    }
    final startedAt = snapshot.data()?['startedAt'];
    if (startedAt is! Timestamp) {
      throw StateError('Deneme başlangıç kaydı okunamadı.');
    }
    final start = startedAt.toDate();
    final end = start.add(PremiumTrialStatus.duration);
    var active = false;
    if (!offline) {
      try {
        // Firestore rules compare the trial start against request.time.
        // This read succeeds only while the server-side trial is active.
        await document.collection('access').doc('status')
            .get(const GetOptions(source: Source.server));
        active = true;
        await prefs.setInt(confirmedKey, now.millisecondsSinceEpoch);
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied') {
          active = false;
        } else {
          rethrow;
        }
      }
      await prefs.setInt(lastSeenKey,
          lastSeen == null || now.millisecondsSinceEpoch > lastSeen
              ? now.millisecondsSinceEpoch : lastSeen);
    } else {
      // Offline access requires a previous server confirmation and a clock
      // that has not moved back or passed the original end time.
      active = !clockMovedBack && prefs.getInt(confirmedKey) != null &&
          now.isBefore(end);
      if (active) await prefs.setInt(lastSeenKey, now.millisecondsSinceEpoch);
    }
    return PremiumTrialStatus(
      active ? PremiumTrialPhase.active : PremiumTrialPhase.expired,
      startedAt: start,
    );
  }

  Future<PremiumTrialStatus> start() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const PremiumTrialStatus(PremiumTrialPhase.signedOut);
    }
    final document = _firestore.collection('premium_trials').doc(user.uid);
    final current = await load();
    if (current.phase != PremiumTrialPhase.available) return current;

    // Kurallar yalnızca ilk oluşturmayı ve sunucu saatini kabul eder.
    await document.set({'startedAt': FieldValue.serverTimestamp()});
    return load();
  }
}
