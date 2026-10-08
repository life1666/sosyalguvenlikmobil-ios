import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/community_service.dart';
import '../utils/app_design.dart';
import '../utils/progress_service.dart';

const _communityCategories = [
  'Kıdem Tazminatı',
  'Fazla Mesai',
  'Emeklilik',
  'İzin Hakları',
  'Ücret ve Bordro',
  'Diğer',
];

const _communityAdminUids = {
  'yicHOHSjaPXH6sLwyc48ulCnai32',
  'jBEoEbfgjJUHklmfmrJqsrIBETF2',
};

class ToplulukEkrani extends StatefulWidget {
  const ToplulukEkrani({super.key});

  @override
  State<ToplulukEkrani> createState() => _ToplulukEkraniState();
}

class _ToplulukEkraniState extends State<ToplulukEkrani> {
  final _service = CommunityService();
  final _searchController = TextEditingController();
  String? _category;
  int _limit = 20;

  @override
  void initState() {
    super.initState();
    ProgressService.record('community_opened');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Soru, yanıt ve oy işlemleri için giriş yapmalısınız.'),
      behavior: SnackBarBehavior.floating,
    ));
    await Navigator.of(context).pushNamed('/giris');
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<void> _openAsk() async {
    if (!await _ensureSignedIn() || !mounted) return;
    final published = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AskQuestionPage(service: _service),
      ),
    );
    if (published != true || !mounted) return;
    await ProgressService.record('community_question_created');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Sorunuz topluluk akışına eklendi.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _openCategoryFilter() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDesign.activeSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .72,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Kategori seçin',
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            Divider(height: 1, color: AppDesign.activeBorder),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.apps_rounded),
                    title: const Text('Tüm kategoriler'),
                    trailing: _category == null
                        ? Icon(Icons.check_rounded,
                            color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  for (final category in _communityCategories)
                    ListTile(
                      leading: const Icon(Icons.label_outline_rounded),
                      title: Text(category),
                      trailing: _category == category
                          ? Icon(Icons.check_rounded,
                              color: Theme.of(context).primaryColor)
                          : null,
                      onTap: () => Navigator.pop(context, category),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _category = selected.isEmpty ? null : selected;
      _limit = 20;
    });
  }

  List<CommunityQuestion> _filter(List<CommunityQuestion> questions) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return questions;
    return questions
        .where((question) =>
            question.title.toLowerCase().contains(query) ||
            question.content.toLowerCase().contains(query) ||
            question.category.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('Topluluk', actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filled(
              tooltip: 'Soru sor',
              onPressed: _openAsk,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ]),
        body: AppContent(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Soru ara...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: AppDesign.activeSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppDesign.activeBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Kategori filtrele',
                  onPressed: _openCategoryFilter,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    backgroundColor: _category == null
                        ? AppDesign.activeSurface
                        : Theme.of(context).primaryColor.withOpacity(.12),
                    side: BorderSide(color: AppDesign.activeBorder),
                  ),
                  icon: Icon(
                    Icons.tune_rounded,
                    color: _category == null
                        ? AppDesign.activeMuted
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ]),
            ),
            if (_category != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(_category!),
                    onDeleted: () => setState(() {
                      _category = null;
                      _limit = 20;
                    }),
                  ),
                ),
              ),
            Expanded(
              child: StreamBuilder<List<CommunityQuestion>>(
                stream: _service.watchQuestions(
                  category: _category,
                  limit: _limit,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _CommunityError(error: snapshot.error);
                  }
                  final allQuestions = snapshot.data ?? const [];
                  final questions = _filter(allQuestions);
                  if (questions.isEmpty) {
                    return _EmptyCommunity(
                      onAsk: _openAsk,
                      searching: _searchController.text.trim().isNotEmpty ||
                          _category != null,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: questions.length +
                        (allQuestions.length >= _limit ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == questions.length) {
                        return OutlinedButton.icon(
                          onPressed: () => setState(() => _limit += 20),
                          icon: const Icon(Icons.expand_more_rounded),
                          label: const Text('Daha fazla soru göster'),
                        );
                      }
                      final question = questions[index];
                      return _QuestionCard(
                        question: question,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ToplulukSoruDetayEkrani(
                              questionId: question.id,
                              service: _service,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      );
}

class _QuestionCard extends StatelessWidget {
  final CommunityQuestion question;
  final VoidCallback onTap;
  const _QuestionCard({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppDesign.activeSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppDesign.activeBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _CategoryBadge(question.category),
                  const Spacer(),
                  Text(_relativeTime(question.createdAt),
                      style: TextStyle(
                          color: AppDesign.activeMuted, fontSize: 11)),
                ]),
                const SizedBox(height: 12),
                Text(question.title,
                    style: TextStyle(
                        color: AppDesign.activeInk,
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(question.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppDesign.activeMuted,
                        fontSize: 13,
                        height: 1.45)),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppDesign.activeBorder),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.thumb_up_alt_outlined,
                      size: 17, color: AppDesign.activeMuted),
                  const SizedBox(width: 5),
                  Text('${question.voteCount}',
                      style: TextStyle(
                          color: AppDesign.activeMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 18),
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 17, color: AppDesign.activeMuted),
                  const SizedBox(width: 5),
                  Text('${question.answerCount}',
                      style: TextStyle(
                          color: AppDesign.activeMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Flexible(
                    child: Text(question.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppDesign.activeMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );
}

class ToplulukSoruDetayEkrani extends StatefulWidget {
  final String questionId;
  final CommunityService service;
  ToplulukSoruDetayEkrani({
    super.key,
    required this.questionId,
    CommunityService? service,
  }) : service = service ?? CommunityService();

  @override
  State<ToplulukSoruDetayEkrani> createState() =>
      _ToplulukSoruDetayEkraniState();
}

class _ToplulukSoruDetayEkraniState extends State<ToplulukSoruDetayEkrani> {
  final _answerController = TextEditingController();
  bool _anonymous = false;
  bool _sending = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _toggleVote() async {
    try {
      await widget.service.toggleQuestionVote(widget.questionId);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _sendAnswer() async {
    final content = _answerController.text.trim();
    if (content.length < 10) {
      _showError('Yanıt en az 10 karakter olmalı.');
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.service.createAnswer(
        questionId: widget.questionId,
        content: content,
        anonymous: _anonymous,
      );
      _answerController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _report() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showError('Şikâyet göndermek için giriş yapmalısınız.');
      return;
    }
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppDesign.activeSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Şikâyet nedeni',
              style: TextStyle(
                  color: AppDesign.activeInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          for (final reason in const [
            'Kişisel veya hassas bilgi',
            'Yanıltıcı bilgi',
            'Hakaret veya taciz',
            'Spam veya reklam',
          ])
            ListTile(
              title: Text(reason),
              onTap: () => Navigator.pop(context, reason),
            ),
        ]),
      ),
    );
    if (reason == null) return;
    try {
      await widget.service
          .reportQuestion(questionId: widget.questionId, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Şikâyetiniz inceleme için gönderildi.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteQuestion(CommunityQuestion question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Soruyu sil'),
        content: const Text(
          'Bu soru ve ekrandaki tüm yanıtları topluluktan kaldırılacak. '
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
            child: const Text('Soruyu sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteQuestion(question.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Soru silindi.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is StateError
        ? error.message
        : error is String
            ? error
            : 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppMenuBar(
          title: const Text('Soru Detayı'),
          leading: const AppBackButton(),
          actions: [
            IconButton(
              tooltip: 'Şikâyet et',
              onPressed: _report,
              icon: const Icon(Icons.flag_outlined),
            ),
          ],
        ),
        body: StreamBuilder<CommunityQuestion?>(
          stream: widget.service.watchQuestion(widget.questionId),
          builder: (context, questionSnapshot) {
            if (questionSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final question = questionSnapshot.data;
            if (question == null) {
              return const Center(child: Text('Bu soru artık mevcut değil.'));
            }
            return Column(children: [
              Expanded(
                child: AppContent(
                  child: StreamBuilder<List<CommunityAnswer>>(
                    stream: widget.service.watchAnswers(widget.questionId),
                    builder: (context, answerSnapshot) {
                      final answers = answerSnapshot.data ?? const [];
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        children: [
                          _QuestionDetailCard(
                            question: question,
                            service: widget.service,
                            onVote: _toggleVote,
                            onDelete: () => _deleteQuestion(question),
                          ),
                          const SizedBox(height: 22),
                          Text('YANITLAR (${question.answerCount})',
                              style: TextStyle(
                                  color: AppDesign.activeMuted,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          if (answerSnapshot.hasError)
                            _CommunityError(error: answerSnapshot.error)
                          else if (answerSnapshot.connectionState ==
                              ConnectionState.waiting)
                            const Center(child: CircularProgressIndicator())
                          else if (answers.isEmpty)
                            AppSurface(
                              child: Text('Bu soruya henüz yanıt verilmedi.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppDesign.activeMuted,
                                      height: 1.5)),
                            )
                          else
                            for (final answer in answers) ...[
                              _AnswerCard(
                                answer: answer,
                                questionId: widget.questionId,
                                service: widget.service,
                              ),
                              const SizedBox(height: 12),
                            ],
                          const SizedBox(height: 6),
                          Text(
                            'Topluluk paylaşımları genel bilgi amaçlıdır; resmi veya kişiye özel hukuki görüş değildir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppDesign.activeMuted,
                                fontSize: 11,
                                height: 1.4),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (FirebaseAuth.instance.currentUser != null)
                _AnswerComposer(
                  controller: _answerController,
                  anonymous: _anonymous,
                  sending: _sending,
                  onAnonymousChanged: (value) =>
                      setState(() => _anonymous = value),
                  onSend: _sendAnswer,
                )
              else
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/giris'),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Yanıt vermek için giriş yap'),
                    ),
                  ),
                ),
            ]);
          },
        ),
      );
}

class _QuestionDetailCard extends StatelessWidget {
  final CommunityQuestion question;
  final CommunityService service;
  final VoidCallback onVote;
  final VoidCallback onDelete;
  const _QuestionDetailCard({
    required this.question,
    required this.service,
    required this.onVote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _CategoryBadge(question.category),
            const Spacer(),
            Text(_relativeTime(question.createdAt),
                style: TextStyle(color: AppDesign.activeMuted, fontSize: 11)),
            if (_canDeleteQuestion(question)) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Soruyu sil',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626), size: 21),
              ),
            ],
          ]),
          const SizedBox(height: 16),
          Text(question.title,
              style: TextStyle(
                  color: AppDesign.activeInk,
                  fontSize: 21,
                  height: 1.25,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(question.content,
              style: TextStyle(
                  color: AppDesign.activeMuted, fontSize: 14, height: 1.55)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Text(question.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            StreamBuilder<bool>(
              stream: service.watchQuestionVote(question.id),
              builder: (context, snapshot) {
                final voted = snapshot.data == true;
                return TextButton.icon(
                  onPressed:
                      FirebaseAuth.instance.currentUser == null ? null : onVote,
                  icon: Icon(voted
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_alt_outlined),
                  label: Text('${question.voteCount}'),
                );
              },
            ),
          ]),
        ]),
      );
}

bool _canDeleteQuestion(CommunityQuestion question) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  return question.authorUid == uid || _communityAdminUids.contains(uid);
}

class _AnswerComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool anonymous;
  final bool sending;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onSend;
  const _AnswerComposer({
    required this.controller,
    required this.anonymous,
    required this.sending,
    required this.onAnonymousChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: AppDesign.activeSurface,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 10, 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Yanıtınızı yazın...',
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Yanıtı gönder',
                  onPressed: sending ? null : onSend,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ]),
              Row(children: [
                SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: anonymous,
                    onChanged: onAnonymousChanged,
                  ),
                ),
                const SizedBox(width: 7),
                Text('Anonim yanıtla',
                    style:
                        TextStyle(color: AppDesign.activeMuted, fontSize: 11)),
              ]),
            ]),
          ),
        ),
      );
}

class _AnswerCard extends StatelessWidget {
  final CommunityAnswer answer;
  final String questionId;
  final CommunityService service;
  const _AnswerCard({
    required this.answer,
    required this.questionId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final color = answer.isExpert
        ? const Color(0xFF2563EB)
        : Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: answer.isExpert
            ? color.withOpacity(AppDesign.isDark ? .12 : .06)
            : AppDesign.activeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              answer.isExpert ? color.withOpacity(.28) : AppDesign.activeBorder,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              answer.isExpert
                  ? Icons.workspace_premium_outlined
                  : Icons.person_outline_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(answer.author,
                    style: TextStyle(
                        color: AppDesign.activeInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text(_relativeTime(answer.createdAt),
                    style:
                        TextStyle(color: AppDesign.activeMuted, fontSize: 10)),
              ],
            ),
          ),
          if (answer.isExpert)
            const _StatusBadge(
              label: 'Uzman yanıtı',
              icon: Icons.verified_outlined,
            ),
        ]),
        const SizedBox(height: 14),
        Text(answer.content,
            style: TextStyle(
                color: AppDesign.activeInk, fontSize: 14, height: 1.55)),
        if (answer.isApproved) ...[
          const SizedBox(height: 14),
          const _StatusBadge(
            label: 'İçerik onaylı',
            icon: Icons.shield_outlined,
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: StreamBuilder<bool>(
            stream: service.watchAnswerVote(questionId, answer.id),
            builder: (context, snapshot) {
              final voted = snapshot.data == true;
              return TextButton.icon(
                onPressed: FirebaseAuth.instance.currentUser == null
                    ? null
                    : () async {
                        try {
                          await service.toggleAnswerVote(questionId, answer.id);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Oy işlemi tamamlanamadı.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: Icon(voted
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined),
                label: Text('${answer.voteCount}'),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _AskQuestionPage extends StatefulWidget {
  final CommunityService service;
  const _AskQuestionPage({required this.service});

  @override
  State<_AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<_AskQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  String _category = _communityCategories.first;
  bool _anonymous = false;
  bool _publishing = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _publishing = true);
    try {
      await widget.service.createQuestion(
        title: _title.text,
        content: _content.text,
        category: _category,
        anonymous: _anonymous,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is StateError
            ? error.message
            : 'Soru yayınlanamadı. Lütfen tekrar deneyin.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('Soru Sor'),
        body: AppContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: AppSurface(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Topluluğa danışın',
                        style: TextStyle(
                            color: AppDesign.activeInk,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Kişisel ve hassas bilgilerinizi paylaşmayın.',
                        style: TextStyle(
                            color: AppDesign.activeMuted,
                            fontSize: 13,
                            height: 1.4)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: _inputDecoration('Kategori'),
                      items: _communityCategories
                          .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _category = value ?? _category),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _title,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          _inputDecoration('Sorunuzu kısa ve net özetleyin'),
                      validator: (value) => (value ?? '').trim().length < 10
                          ? 'Başlık en az 10 karakter olmalı.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _content,
                      minLines: 5,
                      maxLines: 8,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          _inputDecoration('Durumunuzu detaylıca anlatın'),
                      validator: (value) => (value ?? '').trim().length < 20
                          ? 'Açıklama en az 20 karakter olmalı.'
                          : null,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _anonymous,
                      onChanged: (value) => setState(() => _anonymous = value),
                      title: const Text('Anonim paylaş'),
                      subtitle: const Text(
                          'Kimliğiniz yalnızca güvenlik ve moderasyon için saklanır.'),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _publishing ? null : _publish,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _publishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Soruyu yayınla'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppDesign.activeBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppDesign.activeBorder),
        ),
      );
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatusBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class _EmptyCommunity extends StatelessWidget {
  final VoidCallback onAsk;
  final bool searching;
  const _EmptyCommunity({required this.onAsk, required this.searching});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(searching ? Icons.search_off_rounded : Icons.forum_outlined,
                size: 58, color: AppDesign.activeMuted),
            const SizedBox(height: 16),
            Text(searching ? 'Eşleşen soru bulunamadı' : 'İlk soruyu siz sorun',
                style: TextStyle(
                    color: AppDesign.activeInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Aramanızı veya kategori seçiminizi değiştirin.'
                  : 'Topluluk henüz sessiz. Çalışma hayatıyla ilgili sorunuzu paylaşabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppDesign.activeMuted, height: 1.45),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAsk,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Soru sor'),
            ),
          ]),
        ),
      );
}

class _CommunityError extends StatelessWidget {
  final Object? error;
  const _CommunityError({this.error});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 14),
            Text('Topluluk akışı yüklenemedi',
                style: TextStyle(
                    color: AppDesign.activeInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(
              'İnternet bağlantınızı kontrol edin. İlk kurulumda Firestore dizini ve güvenlik kuralları da etkin olmalıdır.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppDesign.activeMuted, height: 1.4),
            ),
          ]),
        ),
      );
}

String _relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'Şimdi';
  if (difference.inHours < 1) return '${difference.inMinutes} dk önce';
  if (difference.inDays < 1) return '${difference.inHours} sa önce';
  if (difference.inDays < 7) return '${difference.inDays} gün önce';
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
