import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityQuestion {
  final String id;
  final String authorUid;
  final String author;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final int voteCount;
  final int answerCount;
  final int reportCount;
  final String status;

  const CommunityQuestion({
    required this.id,
    required this.authorUid,
    required this.author,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.voteCount,
    required this.answerCount,
    required this.reportCount,
    required this.status,
  });

  factory CommunityQuestion.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};
    return CommunityQuestion(
      id: document.id,
      authorUid: data['authorUid'] as String? ?? '',
      author: data['authorName'] as String? ?? 'Anonim Üye',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      category: data['category'] as String? ?? 'Diğer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
      answerCount: (data['answerCount'] as num?)?.toInt() ?? 0,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'published',
    );
  }
}

class CommunityAnswer {
  final String id;
  final String authorUid;
  final String author;
  final String content;
  final DateTime createdAt;
  final int voteCount;
  final bool isExpert;
  final bool isApproved;
  final String status;

  const CommunityAnswer({
    required this.id,
    required this.authorUid,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.voteCount,
    required this.isExpert,
    required this.isApproved,
    required this.status,
  });

  factory CommunityAnswer.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};
    return CommunityAnswer(
      id: document.id,
      authorUid: data['authorUid'] as String? ?? '',
      author: data['authorName'] as String? ?? 'Anonim Üye',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
      isExpert: data['isExpert'] == true,
      isApproved: data['isApproved'] == true,
      status: data['status'] as String? ?? 'published',
    );
  }
}

class CommunityService {
  CommunityService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _questions =>
      _firestore.collection('community_questions');

  User get _requiredUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Bu işlem için giriş yapmanız gerekiyor.');
    }
    return user;
  }

  Stream<List<CommunityQuestion>> watchQuestions({
    String? category,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query =
        _questions.where('status', isEqualTo: 'published');
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(CommunityQuestion.fromDocument)
            .toList(growable: false));
  }

  Stream<List<CommunityQuestion>> watchModerationQuestions({int limit = 100}) =>
      _questions
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(CommunityQuestion.fromDocument)
              .toList(growable: false));

  Stream<List<CommunityQuestion>> watchOwnQuestions(String userUid) =>
      _questions.where('authorUid', isEqualTo: userUid).snapshots().map(
          (snapshot) => snapshot.docs
              .map(CommunityQuestion.fromDocument)
              .toList(growable: false));

  Stream<CommunityQuestion?> watchQuestion(String questionId) =>
      _questions.doc(questionId).snapshots().map((document) =>
          document.exists ? CommunityQuestion.fromDocument(document) : null);

  Stream<List<CommunityAnswer>> watchAnswers(String questionId) => _questions
      .doc(questionId)
      .collection('answers')
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map(CommunityAnswer.fromDocument)
          .toList(growable: false));

  Stream<List<CommunityAnswer>> watchAnswersForModeration(String questionId) =>
      _questions
          .doc(questionId)
          .collection('answers')
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(CommunityAnswer.fromDocument)
              .toList(growable: false));

  Stream<bool> watchQuestionVote(String questionId) {
    final user = _auth.currentUser;
    if (user == null) return Stream<bool>.value(false);
    return _questions
        .doc(questionId)
        .collection('votes')
        .doc(user.uid)
        .snapshots()
        .map((document) => document.exists);
  }

  Stream<bool> watchAnswerVote(String questionId, String answerId) {
    final user = _auth.currentUser;
    if (user == null) return Stream<bool>.value(false);
    return _questions
        .doc(questionId)
        .collection('answers')
        .doc(answerId)
        .collection('votes')
        .doc(user.uid)
        .snapshots()
        .map((document) => document.exists);
  }

  Future<void> createQuestion({
    required String title,
    required String content,
    required String category,
    required bool anonymous,
  }) async {
    final user = _requiredUser;
    final displayName = user.displayName?.trim();
    await _questions.add({
      'authorUid': user.uid,
      'authorName': anonymous || displayName == null || displayName.isEmpty
          ? 'Anonim Üye'
          : displayName,
      'anonymous': anonymous,
      'title': title.trim(),
      'content': content.trim(),
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'published',
      'voteCount': 0,
      'answerCount': 0,
      'reportCount': 0,
    });
  }

  Future<void> createAnswer({
    required String questionId,
    required String content,
    required bool anonymous,
  }) async {
    final user = _requiredUser;
    final question = _questions.doc(questionId);
    final answer = question.collection('answers').doc();
    final displayName = user.displayName?.trim();
    final batch = _firestore.batch();
    batch.set(answer, {
      'authorUid': user.uid,
      'authorName': anonymous || displayName == null || displayName.isEmpty
          ? 'Anonim Üye'
          : displayName,
      'anonymous': anonymous,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'published',
      'voteCount': 0,
      'isExpert': false,
      'isApproved': false,
    });
    batch.update(question, {
      'answerCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> toggleQuestionVote(String questionId) async {
    final user = _requiredUser;
    final question = _questions.doc(questionId);
    final vote = question.collection('votes').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final questionSnapshot = await transaction.get(question);
      if (!questionSnapshot.exists) {
        throw StateError('Soru artık mevcut değil.');
      }
      final voteSnapshot = await transaction.get(vote);
      final current =
          (questionSnapshot.data()?['voteCount'] as num?)?.toInt() ?? 0;
      if (voteSnapshot.exists) {
        transaction.delete(vote);
        transaction
            .update(question, {'voteCount': current > 0 ? current - 1 : 0});
      } else {
        transaction.set(vote, {
          'userUid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(question, {'voteCount': current + 1});
      }
    });
  }

  Future<void> toggleAnswerVote(String questionId, String answerId) async {
    final user = _requiredUser;
    final answer =
        _questions.doc(questionId).collection('answers').doc(answerId);
    final vote = answer.collection('votes').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final answerSnapshot = await transaction.get(answer);
      if (!answerSnapshot.exists) {
        throw StateError('Yanıt artık mevcut değil.');
      }
      final voteSnapshot = await transaction.get(vote);
      final current =
          (answerSnapshot.data()?['voteCount'] as num?)?.toInt() ?? 0;
      if (voteSnapshot.exists) {
        transaction.delete(vote);
        transaction
            .update(answer, {'voteCount': current > 0 ? current - 1 : 0});
      } else {
        transaction.set(vote, {
          'userUid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(answer, {'voteCount': current + 1});
      }
    });
  }

  Future<void> reportQuestion({
    required String questionId,
    required String reason,
  }) async {
    final user = _requiredUser;
    final question = _questions.doc(questionId);
    final report = question.collection('reports').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(report);
      if (existing.exists) {
        throw StateError('Bu soruyu daha önce şikâyet ettiniz.');
      }
      transaction.set(report, {
        'reporterUid': user.uid,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
      });
      transaction.update(question, {'reportCount': FieldValue.increment(1)});
    });
  }

  Future<void> setQuestionStatus(String questionId, String status) async {
    await _questions.doc(questionId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuestion(String questionId) async {
    _requiredUser;
    await _questions.doc(questionId).delete();
  }

  Future<void> setAnswerModeration({
    required String questionId,
    required String answerId,
    required String status,
    required bool isExpert,
    required bool isApproved,
  }) async {
    await _questions
        .doc(questionId)
        .collection('answers')
        .doc(answerId)
        .update({
      'status': status,
      'isExpert': isExpert,
      'isApproved': isApproved,
    });
  }

  Future<void> resolveQuestionReports(String questionId) async {
    final question = _questions.doc(questionId);
    final reports = await question.collection('reports').get();
    final batch = _firestore.batch();
    for (final report in reports.docs) {
      batch.update(report.reference, {'status': 'resolved'});
    }
    batch.update(question, {'reportCount': 0});
    await batch.commit();
  }
}
