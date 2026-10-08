import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sonhesaplama/sonhesaplama.dart';
import '../services/personal_profile_store.dart';

class ProgressTask {
  final String id;
  final String title;
  final String description;
  final int points;
  final bool completed;

  const ProgressTask({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.completed,
  });
}

class ProgressBadge {
  final String title;
  final String description;
  final String emoji;
  final bool unlocked;

  const ProgressBadge({
    required this.title,
    required this.description,
    required this.emoji,
    required this.unlocked,
  });
}

class ProgressSnapshot {
  final int score;
  final String level;
  final List<ProgressTask> tasks;
  final List<ProgressBadge> badges;
  final int calculationCount;
  final int distinctCalculationCount;
  final int inviteShareCount;

  const ProgressSnapshot({
    required this.score,
    required this.level,
    required this.tasks,
    required this.badges,
    required this.calculationCount,
    required this.distinctCalculationCount,
    required this.inviteShareCount,
  });

  ProgressTask? get nextTask {
    for (final task in tasks) {
      if (!task.completed) return task;
    }
    return null;
  }
}

class ProgressService {
  ProgressService._();

  static const _eventKey = 'progress_events_v1';
  static const _uniqueEventKey = 'progress_unique_events_v1';
  static const _migrationKey = 'progress_events_v2_migrated';
  static const _uniqueMigrationKey = 'progress_unique_events_v2_migrated';

  static String? _uidFrom(String? Function()? uidProvider) {
    if (uidProvider != null) return uidProvider();
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static String _keyFor(String base, String? uid) =>
      '${base}_v2_${uid ?? 'guest'}';

  static Future<String?> _readScoped(SharedPreferences prefs, String base,
      String migrationKey, String? uid) async {
    final key = _keyFor(base, uid);
    final saved = prefs.getString(key);
    if (saved != null) {
      if (uid != null && prefs.getBool(migrationKey) != true) {
        await prefs.setBool(migrationKey, true);
        await prefs.remove(base);
      }
      return saved;
    }
    if (uid == null || prefs.getBool(migrationKey) == true) return null;
    final legacy = prefs.getString(base);
    if (legacy == null) return null;
    if (!await prefs.setString(key, legacy)) return null;
    await prefs.setBool(migrationKey, true);
    await prefs.remove(base);
    return legacy;
  }

  static Future<void> record(String event,
      {int increment = 1, String? Function()? uidProvider}) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uidFrom(uidProvider);
    final events =
        _readEvents(await _readScoped(prefs, _eventKey, _migrationKey, uid));
    events[event] = (events[event] ?? 0) + increment;
    await prefs.setString(_keyFor(_eventKey, uid), jsonEncode(events));
  }

  static Future<void> recordUnique(String event, String value,
      {String? Function()? uidProvider}) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uidFrom(uidProvider);
    final uniqueEvents = _readUniqueEvents(
        await _readScoped(prefs, _uniqueEventKey, _uniqueMigrationKey, uid));
    final values = uniqueEvents.putIfAbsent(event, () => <String>{});
    values.add(value);
    await prefs.setString(
      _keyFor(_uniqueEventKey, uid),
      jsonEncode(
          uniqueEvents.map((key, items) => MapEntry(key, items.toList()))),
    );
  }

  static Future<ProgressSnapshot> load(
      {String? Function()? uidProvider}) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uidFrom(uidProvider);
    final events =
        _readEvents(await _readScoped(prefs, _eventKey, _migrationKey, uid));
    final uniqueEvents = _readUniqueEvents(
        await _readScoped(prefs, _uniqueEventKey, _uniqueMigrationKey, uid));
    final profile = uid == null
        ? <String, dynamic>{}
        : _readMap(
            await PersonalProfileStore(uidProvider: () => uid).readRaw());
    final calculations =
        await SonHesaplamalarDeposu.listele(uidProvider: () => uid);
    final distinctCalculations =
        calculations.map((item) => item.hesaplamaTuru).toSet().length;
    final communityQuestionCreated =
        (events['community_question_created'] ?? 0) > 0;

    final coreFields = [
      profile['dogumTarihi'],
      profile['cinsiyet'],
      profile['sigortaKolu'],
      profile['ilkIseGirisTarihi'],
      profile['toplamPrimGun'],
    ];
    final coreComplete = coreFields.every(_hasValue);
    final workComplete = _hasValue(profile['mevcutIsyeriBaslangic']) &&
        ((profile['guncelBrutMaas'] as num?)?.toDouble() ?? 0) > 0;
    final savedAt = profile['kayitTarihi'] is int
        ? DateTime.fromMillisecondsSinceEpoch(profile['kayitTarihi'] as int)
        : null;
    final profileCurrent =
        savedAt != null && DateTime.now().difference(savedAt).inDays <= 90;
    final rightsOpened = (events['rights_opened'] ?? 0) > 0;
    final rightsDetails = uniqueEvents['rights_detail_opened']?.length ?? 0;
    final communityOpened = (events['community_opened'] ?? 0) > 0;
    final inviteShares = events['invite_shared'] ?? 0;

    final tasks = <ProgressTask>[
      ProgressTask(
        id: 'profile_core',
        title: 'Temel çalışma bilgilerini tamamla',
        description: 'Doğum, SGK statüsü, işe giriş ve prim bilgilerini ekle.',
        points: 20,
        completed: coreComplete,
      ),
      ProgressTask(
        id: 'profile_work',
        title: 'Mevcut iş ve maaşını ekle',
        description:
            'Kıdem, izin ve maaş analizlerinin kişiselleşmesini sağlar.',
        points: 10,
        completed: workComplete,
      ),
      ProgressTask(
        id: 'profile_current',
        title: 'Bilgilerini güncel tut',
        description: 'Çalışma bilgilerini son 90 gün içinde kontrol et.',
        points: 10,
        completed: coreComplete && profileCurrent,
      ),
      ProgressTask(
        id: 'first_calculation',
        title: 'İlk hesaplamanı tamamla',
        description: 'İhtiyacın olan bir hesaplayıcıyı kullan.',
        points: 10,
        completed: calculations.isNotEmpty,
      ),
      ProgressTask(
        id: 'calculation_explorer',
        title: 'Üç farklı hesaplamayı keşfet',
        description: 'Farklı çalışma hayatı senaryolarını karşılaştır.',
        points: 10,
        completed: distinctCalculations >= 3,
      ),
      ProgressTask(
        id: 'rights_open',
        title: 'Haklarını kontrol et',
        description: 'Haklarım zaman çizelgeni en az bir kez incele.',
        points: 10,
        completed: rightsOpened,
      ),
      ProgressTask(
        id: 'rights_details',
        title: 'Üç hakkın detayını incele',
        description: 'Hakların hangi koşullarda oluştuğunu öğren.',
        points: 10,
        completed: rightsDetails >= 3,
      ),
      ProgressTask(
        id: 'community_open',
        title: 'Topluluğu keşfet',
        description: 'Topluluk sorularını ve uzman yanıtlarını incele.',
        points: 5,
        completed: communityOpened,
      ),
      ProgressTask(
        id: 'community_question',
        title: 'İlk topluluk sorunu oluştur',
        description: 'Kişisel bilgi paylaşmadan topluluğa danış.',
        points: 5,
        completed: communityQuestionCreated,
      ),
      ProgressTask(
        id: 'invite',
        title: 'Uygulamayı bir arkadaşınla paylaş',
        description: 'Kişisel davet bağlantını paylaş.',
        points: 10,
        completed: inviteShares > 0,
      ),
    ];

    final score = tasks
        .where((task) => task.completed)
        .fold<int>(0, (total, task) => total + task.points)
        .clamp(0, 100);
    final level = score >= 100
        ? 'Takibini Tamamlayan'
        : score >= 75
            ? 'Düzenli Takipçi'
            : score >= 50
                ? 'Bilinçli Çalışan'
                : score >= 25
                    ? 'Haklarını Keşfeden'
                    : 'İlk Adım';

    final badges = <ProgressBadge>[
      ProgressBadge(
          title: 'İlk Adım',
          description: 'Temel çalışma bilgilerini tamamladın.',
          emoji: '🚀',
          unlocked: coreComplete),
      ProgressBadge(
          title: 'Hesap Uzmanı',
          description: 'Üç farklı hesaplama türünü kullandın.',
          emoji: '🧮',
          unlocked: distinctCalculations >= 3),
      ProgressBadge(
          title: 'Hak Takipçisi',
          description: 'Üç farklı hakkın ayrıntısını inceledin.',
          emoji: '🛡️',
          unlocked: rightsDetails >= 3),
      ProgressBadge(
          title: 'Güncel Profil',
          description: 'Çalışma ve maaş bilgilerini güncel tuttun.',
          emoji: '✅',
          unlocked: coreComplete && workComplete && profileCurrent),
      ProgressBadge(
          title: 'Topluluk Üyesi',
          description: 'Topluluğa ilk sorunu ekledin.',
          emoji: '💬',
          unlocked: communityQuestionCreated),
      ProgressBadge(
          title: 'Birlikte Güçlüyüz',
          description: 'Uygulamayı bir arkadaşınla paylaştın.',
          emoji: '🤝',
          unlocked: inviteShares > 0),
    ];

    return ProgressSnapshot(
      score: score,
      level: level,
      tasks: tasks,
      badges: badges,
      calculationCount: calculations.length,
      distinctCalculationCount: distinctCalculations,
      inviteShareCount: inviteShares,
    );
  }

  static Map<String, int> _readEvents(String? raw) {
    try {
      if (raw == null) return {};
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Map<String, Set<String>> _readUniqueEvents(String? raw) {
    try {
      if (raw == null) return {};
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((key, value) => MapEntry(
          key, (value as List).map((item) => item.toString()).toSet()));
    } catch (_) {
      return {};
    }
  }

  static Map<String, dynamic> _readMap(String? raw) {
    try {
      return raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> removeForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(_eventKey, uid));
    await prefs.remove(_keyFor(_uniqueEventKey, uid));
    await prefs.remove(_eventKey);
    await prefs.remove(_uniqueEventKey);
    await prefs.setBool(_migrationKey, true);
    await prefs.setBool(_uniqueMigrationKey, true);
  }

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    return true;
  }
}
