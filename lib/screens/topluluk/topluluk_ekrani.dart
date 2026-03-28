import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/rozet_tercihleri.dart';
import '../../utils/analytics_helper.dart';
import '../sgk_port/sgk_app_colors.dart';
import '../sgk_port/sgk_port_models.dart';

/// sgk_app [CommunityScreen] ile aynı içerik ve düzen (feed / detay / soru sor).
class ToplulukEkrani extends StatefulWidget {
  final bool inline;
  const ToplulukEkrani({super.key, this.inline = false});

  @override
  State<ToplulukEkrani> createState() => _ToplulukEkraniState();
}

class _ToplulukEkraniState extends State<ToplulukEkrani> {
  String _view = 'feed';
  SgkCommunityQuestion? _selectedQuestion;
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  static final List<SgkCommunityQuestion> mockQuestions = [
    SgkCommunityQuestion(
      id: '1',
      author: 'Anonim Çalışan',
      title: 'İstifa edersem kıdem tazminatı alabilir miyim?',
      content:
          '3 yıldır aynı iş yerinde çalışıyorum. Kendi isteğimle ayrılmak istiyorum ancak tazminatımı yakmak istemiyorum. Bir yolu var mı?',
      category: 'Kıdem Tazminatı',
      timestamp: '2 saat önce',
      upvotes: 12,
      answers: [
        SgkCommunityAnswer(
          id: 'a1',
          author: 'Av. Selin Demir',
          content:
              'Normal şartlarda istifa halinde kıdem tazminatı ödenmez. Ancak "Haklı Fesih" nedenleriniz varsa tazminatlı ayrılabilirsiniz.',
          timestamp: '1 saat önce',
          upvotes: 45,
          isExpert: true,
          isHakApproved: true,
        ),
      ],
    ),
    SgkCommunityQuestion(
      id: '2',
      author: 'Genç Yazılımcı',
      title: 'Fazla mesai ücreti nasıl hesaplanır?',
      content:
          'Haftalık 45 saati geçiyoruz ama maaşımız hep aynı yatıyor. Bordroda mesai görünmüyor.',
      category: 'Fazla Mesai',
      timestamp: '5 saat önce',
      upvotes: 8,
      answers: [
        SgkCommunityAnswer(
          id: 'a3',
          author: 'Hak AI',
          content:
              'Haftalık 45 saati aşan her saat için saatlik ücretinin %50 fazlasını almalısın.',
          timestamp: '4 saat önce',
          upvotes: 120,
          isHakApproved: true,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('topluluk_opened');
    _rozetBayrakKaydet();
  }

  Future<void> _rozetBayrakKaydet() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kRozetToplulukZiyaret, true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _view == 'feed'
            ? _buildFeed(darkMode)
            : _view == 'detail' && _selectedQuestion != null
                ? _buildDetail(darkMode)
                : _buildAsk(darkMode),
      ),
    );

    if (widget.inline) return body;

    return Scaffold(
      backgroundColor: darkMode ? SgkAppColors.slate950 : SgkAppColors.gray,
      body: SafeArea(child: body),
    );
  }

  Widget _buildFeed(bool darkMode) {
    return Column(
      key: const ValueKey('feed'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.chevron_left_rounded,
                color: darkMode
                    ? SgkAppColors.slate400
                    : SgkAppColors.slate600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Topluluk',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: darkMode ? Colors.white : SgkAppColors.slate800,
              ),
            ),
            const Spacer(),
            Material(
              color: darkMode ? SgkAppColors.blue500 : SgkAppColors.navy,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => setState(() => _view = 'ask'),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Soru ara...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: darkMode
                        ? SgkAppColors.slate500
                        : SgkAppColors.slate400,
                  ),
                  filled: true,
                  fillColor: darkMode ? SgkAppColors.slate800 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: darkMode
                          ? SgkAppColors.slate700
                          : SgkAppColors.slate100,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: darkMode ? Colors.white : SgkAppColors.slate800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: darkMode ? SgkAppColors.slate800 : Colors.white,
                side: BorderSide(
                  color: darkMode
                      ? SgkAppColors.slate700
                      : SgkAppColors.slate100,
                ),
              ),
              icon: Icon(
                Icons.tune_rounded,
                color: darkMode
                    ? SgkAppColors.slate500
                    : SgkAppColors.slate400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: mockQuestions.map((q) => _questionCard(q, darkMode)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _questionCard(SgkCommunityQuestion q, bool darkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: darkMode ? SgkAppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedQuestion = q;
              _view = 'detail';
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: darkMode
                    ? SgkAppColors.slate700
                    : SgkAppColors.slate100,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: SgkAppColors.blue500.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        q.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: SgkAppColors.blue500,
                        ),
                      ),
                    ),
                    Text(
                      q.timestamp,
                      style: TextStyle(
                        fontSize: 10,
                        color: darkMode
                            ? SgkAppColors.slate500
                            : SgkAppColors.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  q.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkMode ? Colors.white : SgkAppColors.slate800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  q.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: darkMode
                        ? SgkAppColors.slate400
                        : SgkAppColors.slate500,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                    height: 1,
                    color: darkMode ? SgkAppColors.slate700 : SgkAppColors.slate50),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined,
                        size: 16,
                        color: darkMode
                            ? SgkAppColors.slate500
                            : SgkAppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      '${q.upvotes}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: darkMode
                            ? SgkAppColors.slate500
                            : SgkAppColors.slate400,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: darkMode
                            ? SgkAppColors.slate500
                            : SgkAppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      '${q.answers.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: darkMode
                            ? SgkAppColors.slate500
                            : SgkAppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(bool darkMode) {
    final q = _selectedQuestion!;
    return SingleChildScrollView(
      key: const ValueKey('detail'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _view = 'feed'),
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: darkMode
                  ? SgkAppColors.slate400
                  : SgkAppColors.slate600,
            ),
            label: Text(
              'Geri Dön',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: darkMode
                    ? SgkAppColors.slate400
                    : SgkAppColors.slate600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: darkMode ? SgkAppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: darkMode
                    ? SgkAppColors.slate700
                    : SgkAppColors.slate100,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: darkMode ? Colors.white : SgkAppColors.slate800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  q.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: darkMode
                        ? SgkAppColors.slate300
                        : SgkAppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'YANITLAR (${q.answers.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: darkMode
                  ? SgkAppColors.slate500
                  : SgkAppColors.slate400,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...q.answers.map((a) => _answerCard(a, darkMode)),
        ],
      ),
    );
  }

  Widget _answerCard(SgkCommunityAnswer a, bool darkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: a.isExpert
              ? (darkMode
                  ? SgkAppColors.blue500.withOpacity(0.1)
                  : SgkAppColors.blue50)
              : (darkMode ? SgkAppColors.slate800 : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: a.isExpert
                ? (darkMode
                    ? SgkAppColors.blue500.withOpacity(0.3)
                    : SgkAppColors.blue100)
                : (darkMode
                    ? SgkAppColors.slate700
                    : SgkAppColors.slate100),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.isExpert)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: SgkAppColors.blue500,
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'UZMAN YANITI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (a.isExpert) const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: a.isExpert
                        ? SgkAppColors.blue500
                        : (darkMode
                            ? SgkAppColors.slate700
                            : SgkAppColors.slate100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    a.author == 'Hak AI'
                        ? Icons.smart_toy_rounded
                        : Icons.emoji_events_rounded,
                    size: 18,
                    color: a.isExpert
                        ? Colors.white
                        : (darkMode
                            ? SgkAppColors.slate500
                            : SgkAppColors.slate400),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  a.author,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: a.isExpert
                        ? SgkAppColors.blue600
                        : (darkMode ? Colors.white : SgkAppColors.slate800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              a.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: darkMode
                    ? SgkAppColors.slate300
                    : SgkAppColors.slate700,
              ),
            ),
            if (a.isHakApproved) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.verified_rounded,
                      size: 16, color: SgkAppColors.green),
                  SizedBox(width: 4),
                  Text(
                    'Hak Onaylı',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: SgkAppColors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAsk(bool darkMode) {
    return SingleChildScrollView(
      key: const ValueKey('ask'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _view = 'feed'),
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: darkMode
                  ? SgkAppColors.slate400
                  : SgkAppColors.slate600,
            ),
            label: Text(
              'Vazgeç',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: darkMode
                    ? SgkAppColors.slate400
                    : SgkAppColors.slate600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: darkMode ? SgkAppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: darkMode
                    ? SgkAppColors.slate700
                    : SgkAppColors.slate100,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Sorunu kısa ve net özetle',
                    filled: true,
                    fillColor:
                        darkMode ? SgkAppColors.slate900 : SgkAppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: darkMode
                            ? SgkAppColors.slate700
                            : SgkAppColors.slate100,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: darkMode ? Colors.white : SgkAppColors.slate800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Durumunu detaylıca anlat...',
                    filled: true,
                    fillColor:
                        darkMode ? SgkAppColors.slate900 : SgkAppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: darkMode
                            ? SgkAppColors.slate700
                            : SgkAppColors.slate100,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: darkMode ? Colors.white : SgkAppColors.slate800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _view = 'feed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkMode
                          ? SgkAppColors.blue500
                          : SgkAppColors.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Soruyu Yayınla',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
