import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'community_service.dart';

class CommunityInAppNotificationService {
  CommunityInAppNotificationService({
    FirebaseAuth? auth,
    CommunityService? communityService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _communityService = communityService ?? CommunityService();

  final FirebaseAuth _auth;
  final CommunityService _communityService;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<CommunityQuestion>>? _questionSubscription;
  final Map<String, int> _knownAnswerCounts = {};
  bool _initialized = false;

  void start(void Function(CommunityQuestion question) onNewAnswer) {
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((user) {
      _questionSubscription?.cancel();
      _knownAnswerCounts.clear();
      _initialized = false;
      if (user == null) return;
      _questionSubscription = _communityService
          .watchOwnQuestions(user.uid)
          .listen((questions) {
        if (!_initialized) {
          for (final question in questions) {
            _knownAnswerCounts[question.id] = question.answerCount;
          }
          _initialized = true;
          return;
        }
        for (final question in questions) {
          final previous = _knownAnswerCounts[question.id] ?? 0;
          if (question.answerCount > previous) onNewAnswer(question);
          _knownAnswerCounts[question.id] = question.answerCount;
        }
      });
    });
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _questionSubscription?.cancel();
  }
}
