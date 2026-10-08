import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/community_service.dart';
import '../../utils/app_design.dart';

class ToplulukModerasyonEkrani extends StatefulWidget {
  const ToplulukModerasyonEkrani({super.key});

  @override
  State<ToplulukModerasyonEkrani> createState() =>
      _ToplulukModerasyonEkraniState();
}

class _ToplulukModerasyonEkraniState extends State<ToplulukModerasyonEkrani> {
  static const _adminUids = {
    'yicHOHSjaPXH6sLwyc48ulCnai32',
    'jBEoEbfgjJUHklmfmrJqsrIBETF2',
  };
  final _service = CommunityService();
  bool _reportedOnly = true;

  bool get _isAdmin =>
      _adminUids.contains(FirebaseAuth.instance.currentUser?.uid);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('Topluluk Yönetimi'),
        body: !_isAdmin
            ? const Center(
                child: Text('Bu alan yalnızca yöneticilere açıktır.'))
            : AppContent(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.flag_outlined),
                          label: Text('Şikâyetler'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.forum_outlined),
                          label: Text('Tüm içerikler'),
                        ),
                      ],
                      selected: {_reportedOnly},
                      onSelectionChanged: (value) =>
                          setState(() => _reportedOnly = value.first),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<CommunityQuestion>>(
                      stream: _service.watchModerationQuestions(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('İçerikler yüklenemedi.'));
                        }
                        final questions = (snapshot.data ?? const [])
                            .where((item) =>
                                !_reportedOnly || item.reportCount > 0)
                            .toList(growable: false);
                        if (questions.isEmpty) {
                          return _ModerationEmpty(reportedOnly: _reportedOnly);
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          itemCount: questions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) => _ModerationQuestionCard(
                            question: questions[index],
                            service: _service,
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
      );
}

class _ModerationQuestionCard extends StatelessWidget {
  final CommunityQuestion question;
  final CommunityService service;
  const _ModerationQuestionCard({
    required this.question,
    required this.service,
  });

  Future<void> _setStatus(BuildContext context, String status) async {
    try {
      await service.setQuestionStatus(question.id, status);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Soru durumu değiştirilemedi.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _resolve(BuildContext context) async {
    try {
      await service.resolveQuestionReports(question.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Şikâyetler sonuçlandırılamadı.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Soruyu sil'),
        content: const Text(
          'Soru topluluk akışından kalıcı olarak kaldırılacak. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await service.deleteQuestion(question.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Soru silindi.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Soru silinemedi.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: question.status == 'published'
                    ? const Color(0xFF16A34A).withOpacity(.1)
                    : const Color(0xFFEF4444).withOpacity(.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                question.status == 'published' ? 'Yayında' : 'Gizli',
                style: TextStyle(
                  color: question.status == 'published'
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            if (question.reportCount > 0) ...[
              const Icon(Icons.flag_rounded,
                  size: 17, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text('${question.reportCount} şikâyet',
                  style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ]),
          const SizedBox(height: 12),
          Text(question.title,
              style: TextStyle(
                  color: AppDesign.activeInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(question.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppDesign.activeMuted, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ModerationAnswersPage(
                    question: question,
                    service: service,
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
              label: Text('${question.answerCount} yanıt'),
            ),
            if (question.status == 'published')
              OutlinedButton.icon(
                onPressed: () => _setStatus(context, 'hidden'),
                icon: const Icon(Icons.visibility_off_outlined, size: 17),
                label: const Text('Gizle'),
              )
            else
              FilledButton.tonalIcon(
                onPressed: () => _setStatus(context, 'published'),
                icon: const Icon(Icons.visibility_outlined, size: 17),
                label: const Text('Yayınla'),
              ),
            if (question.reportCount > 0)
              TextButton.icon(
                onPressed: () => _resolve(context),
                icon: const Icon(Icons.task_alt_rounded, size: 17),
                label: const Text('İncelendi'),
              ),
            TextButton.icon(
              onPressed: () => _delete(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('Sil'),
            ),
          ]),
        ]),
      );
}

class _ModerationAnswersPage extends StatelessWidget {
  final CommunityQuestion question;
  final CommunityService service;
  const _ModerationAnswersPage({
    required this.question,
    required this.service,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('Yanıtları Yönet'),
        body: AppContent(
          child: StreamBuilder<List<CommunityAnswer>>(
            stream: service.watchAnswersForModeration(question.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final answers = snapshot.data ?? const [];
              if (answers.isEmpty) {
                return const Center(child: Text('Bu soruda yanıt bulunmuyor.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                itemCount: answers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _ModerationAnswerCard(
                  questionId: question.id,
                  answer: answers[index],
                  service: service,
                ),
              );
            },
          ),
        ),
      );
}

class _ModerationAnswerCard extends StatelessWidget {
  final String questionId;
  final CommunityAnswer answer;
  final CommunityService service;
  const _ModerationAnswerCard({
    required this.questionId,
    required this.answer,
    required this.service,
  });

  Future<void> _update({
    String? status,
    bool? isExpert,
    bool? isApproved,
  }) =>
      service.setAnswerModeration(
        questionId: questionId,
        answerId: answer.id,
        status: status ?? answer.status,
        isExpert: isExpert ?? answer.isExpert,
        isApproved: isApproved ?? answer.isApproved,
      );

  @override
  Widget build(BuildContext context) => AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(answer.author,
                  style: TextStyle(
                      color: AppDesign.activeInk, fontWeight: FontWeight.w700)),
            ),
            Text(answer.status == 'published' ? 'Yayında' : 'Gizli',
                style: TextStyle(
                    color: answer.status == 'published'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 9),
          Text(answer.content,
              style: TextStyle(
                  color: AppDesign.activeMuted, fontSize: 13, height: 1.45)),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Uzman yanıtı'),
            value: answer.isExpert,
            onChanged: (value) => _update(isExpert: value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('İçerik onaylı'),
            value: answer.isApproved,
            onChanged: (value) => _update(isApproved: value),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _update(
                status: answer.status == 'published' ? 'hidden' : 'published',
              ),
              icon: Icon(answer.status == 'published'
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              label: Text(answer.status == 'published' ? 'Gizle' : 'Yayınla'),
            ),
          ),
        ]),
      );
}

class _ModerationEmpty extends StatelessWidget {
  final bool reportedOnly;
  const _ModerationEmpty({required this.reportedOnly});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_user_outlined, size: 52),
            const SizedBox(height: 12),
            Text(
              reportedOnly
                  ? 'Bekleyen şikâyet bulunmuyor.'
                  : 'Henüz topluluk içeriği bulunmuyor.',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}
