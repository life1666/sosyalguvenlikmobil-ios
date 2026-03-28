import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../sonhesaplama/sonhesaplama.dart';
import '../../utils/analytics_helper.dart';
import '../sgk_port/sgk_app_colors.dart';
import '../sgk_port/sgk_port_models.dart';

/// sgk_app [GamificationScreen] ile aynı içerik ve düzen (İlerleme / Rozetler / Sıralama).
class RozetlerEkrani extends StatefulWidget {
  final bool inline;
  const RozetlerEkrani({super.key, this.inline = false});

  @override
  State<RozetlerEkrani> createState() => _RozetlerEkraniState();
}

class _RozetlerEkraniState extends State<RozetlerEkrani> {
  bool _yukleniyor = true;
  SgkUserStats _stats = SgkUserStats(
    xp: 0,
    level: 1,
    levelName: 'Yeni Üye',
    badges: sgkInitialBadges(),
  );
  String _leaderboardBenAd = 'Ahmet Yılmaz';

  static const List<Map<String, dynamic>> xpHistory = [
    {'action': 'Kıdem Hesaplama', 'xp': 50, 'time': 'Bugün 14:32'},
    {'action': 'Mevzuat Kartı Okundu', 'xp': 30, 'time': 'Dün 10:15'},
    {'action': 'Profil Güncelleme', 'xp': 50, 'time': '12 Mart'},
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('rozetler_opened');
    _yukle();
  }

  Future<void> _yukle() async {
    final p = await SharedPreferences.getInstance();
    final hesaplar = await SonHesaplamalarDeposu.listele();
    final user = FirebaseAuth.instance.currentUser;
    final tip = p.getString('akisi_profil_tipi');
    final takma = p.getString('akisi_takma_ad');
    int xp = p.getInt('yan_menu_xp') ?? 0;
    final profileType = sgkProfileTypeFromAkisi(tip);
    final level = (xp / 500).floor() + 1;
    final levelName =
        SgkAppLevels.getLevelName(profileType, level.clamp(1, 99));

    final badges = sgkInitialBadges()
        .map((b) {
          if (b.id == '2') {
            return b.copyWith(unlocked: hesaplar.isNotEmpty);
          }
          return b;
        })
        .toList();

    String benAd = 'Ahmet Yılmaz';
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      benAd = user.displayName!.trim();
    } else if (takma != null && takma.trim().isNotEmpty) {
      benAd = takma.trim();
    }

    if (!mounted) return;
    setState(() {
      _stats = SgkUserStats(
        xp: xp,
        level: level,
        levelName: levelName,
        badges: badges,
      );
      _leaderboardBenAd = benAd;
      _yukleniyor = false;
    });
  }

  List<Map<String, dynamic>> _leaderboard() => [
        {
          'rank': 1,
          'name': 'Kahraman47',
          'xp': 4250,
          'type': 'Çalışan',
          'isMe': false
        },
        {
          'rank': 2,
          'name': 'UstaYönetici',
          'xp': 3890,
          'type': 'İşveren',
          'isMe': false
        },
        {
          'rank': 3,
          'name': 'HukukSever',
          'xp': 3100,
          'type': 'Yeni Başlayan',
          'isMe': false
        },
        {
          'rank': 34,
          'name': _leaderboardBenAd,
          'xp': _stats.xp,
          'type': 'Çalışan',
          'isMe': true
        },
      ];

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    if (_yukleniyor) {
      if (widget.inline) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        backgroundColor:
            darkMode ? SgkAppColors.slate950 : SgkAppColors.gray,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _stats;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.inline)
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
                  'Başarıların',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: darkMode ? Colors.white : SgkAppColors.slate800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SgkAppColors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: SgkAppColors.amber, size: 24),
                ),
              ],
            ),
          if (widget.inline)
            Row(
              children: [
                Text(
                  'Başarıların',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: darkMode ? Colors.white : SgkAppColors.slate800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SgkAppColors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: SgkAppColors.amber, size: 24),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Expanded(
            child: _GamificationTabs(
              stats: stats,
              leaderboard: _leaderboard,
              xpHistory: xpHistory,
              onRefresh: _yukle,
            ),
          ),
        ],
      ),
    );

    if (widget.inline) return body;

    return Scaffold(
      backgroundColor: darkMode ? SgkAppColors.slate950 : SgkAppColors.gray,
      body: SafeArea(child: body),
    );
  }
}

class _GamificationTabs extends StatefulWidget {
  final SgkUserStats stats;
  final List<Map<String, dynamic>> Function() leaderboard;
  final List<Map<String, dynamic>> xpHistory;
  final Future<void> Function() onRefresh;

  const _GamificationTabs({
    required this.stats,
    required this.leaderboard,
    required this.xpHistory,
    required this.onRefresh,
  });

  @override
  State<_GamificationTabs> createState() => _GamificationTabsState();
}

class _GamificationTabsState extends State<_GamificationTabs> {
  String _activeSubTab = 'progress';

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final stats = widget.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: darkMode ? SgkAppColors.slate800 : SgkAppColors.slate100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _tabButton('progress', 'İlerleme', darkMode),
              _tabButton('badges', 'Rozetler', darkMode),
              _tabButton('leaderboard', 'Sıralama', darkMode),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _activeSubTab == 'progress'
                ? _buildProgress(stats, darkMode)
                : _activeSubTab == 'badges'
                    ? _buildBadges(stats, darkMode)
                    : _buildLeaderboard(darkMode),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String id, String label, bool darkMode) {
    final isActive = _activeSubTab == id;
    return Expanded(
      child: Material(
        color: isActive
            ? (darkMode ? SgkAppColors.slate700 : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _activeSubTab = id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? (darkMode ? SgkAppColors.blue400 : SgkAppColors.navy)
                    : (darkMode
                        ? SgkAppColors.slate400
                        : SgkAppColors.slate500),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(SgkUserStats stats, bool darkMode) {
    final nextLevelXp = stats.level * 500;
    final progress = (stats.xp % 500) / 500;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        key: const ValueKey('progress'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: SgkAppColors.blue500.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.star_rounded,
                        size: 40, color: SgkAppColors.blue500),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stats.levelName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color:
                          darkMode ? Colors.white : SgkAppColors.slate800,
                    ),
                  ),
                  Text(
                    'Seviye ${stats.level}',
                    style: TextStyle(
                      fontSize: 14,
                      color: darkMode
                          ? SgkAppColors.slate400
                          : SgkAppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${stats.xp} XP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: darkMode
                              ? SgkAppColors.slate400
                              : SgkAppColors.slate500,
                        ),
                      ),
                      Text(
                        '$nextLevelXp XP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: darkMode
                              ? SgkAppColors.slate400
                              : SgkAppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: darkMode
                          ? SgkAppColors.slate700
                          : SgkAppColors.slate200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          SgkAppColors.blue500),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sonraki seviyeye ${nextLevelXp - stats.xp} XP kaldı',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SgkAppColors.blue500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'XP GEÇMİŞİ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: darkMode
                    ? SgkAppColors.slate500
                    : SgkAppColors.slate400,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                  for (int i = 0; i < widget.xpHistory.length; i++) ...[
                    if (i > 0)
                      Divider(
                          height: 1,
                          color: darkMode
                              ? SgkAppColors.slate700
                              : SgkAppColors.slate50),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SgkAppColors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bolt_rounded,
                                size: 18, color: SgkAppColors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.xpHistory[i]['action'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: darkMode
                                        ? Colors.white
                                        : SgkAppColors.slate800,
                                  ),
                                ),
                                Text(
                                  widget.xpHistory[i]['time'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: darkMode
                                        ? SgkAppColors.slate400
                                        : SgkAppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${widget.xpHistory[i]['xp']} XP',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: SgkAppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges(SgkUserStats stats, bool darkMode) {
    return GridView.builder(
      key: const ValueKey('badges'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: stats.badges.length,
      itemBuilder: (context, index) {
        final b = stats.badges[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: b.unlocked
                ? (darkMode ? SgkAppColors.slate800 : Colors.white)
                : (darkMode ? SgkAppColors.slate900 : SgkAppColors.slate50),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: b.unlocked
                  ? (darkMode
                      ? SgkAppColors.slate700
                      : SgkAppColors.slate100)
                  : (darkMode
                      ? SgkAppColors.slate800
                      : SgkAppColors.slate200),
            ),
          ),
          child: Opacity(
            opacity: b.unlocked ? 1 : 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(b.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  b.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: b.unlocked
                        ? (darkMode ? Colors.white : SgkAppColors.slate800)
                        : (darkMode
                            ? SgkAppColors.slate500
                            : SgkAppColors.slate400),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  b.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: darkMode
                        ? SgkAppColors.slate400
                        : SgkAppColors.slate500,
                  ),
                ),
                if (!b.unlocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: darkMode
                          ? SgkAppColors.slate700
                          : SgkAppColors.slate200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'KİLİTLİ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: darkMode
                            ? SgkAppColors.slate400
                            : SgkAppColors.slate600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboard(bool darkMode) {
    final list = widget.leaderboard();
    return SingleChildScrollView(
      key: const ValueKey('leaderboard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SgkAppColors.blue500,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SENİN SIRALAMAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '#34',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/ 1.247 Kullanıcı',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bu ayın birincisi 1 aylık Premium kazanıyor! Aramızda 240 XP fark var.',
                          style: TextStyle(fontSize: 10, height: 1.4, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
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
                for (int i = 0; i < list.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        color: darkMode
                            ? SgkAppColors.slate700
                            : SgkAppColors.slate50),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${list[i]['rank']}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: list[i]['rank'] == 1
                                  ? SgkAppColors.amber
                                  : list[i]['rank'] == 2
                                      ? SgkAppColors.slate400
                                      : list[i]['rank'] == 3
                                          ? SgkAppColors.amber700
                                          : SgkAppColors.slate300,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            'https://picsum.photos/100/100?random=${list[i]['rank']}',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${list[i]['name']}${list[i]['isMe'] == true ? ' (Sen)' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: list[i]['isMe'] == true
                                      ? SgkAppColors.blue500
                                      : (darkMode
                                          ? Colors.white
                                          : SgkAppColors.slate800),
                                ),
                              ),
                              Text(
                                list[i]['type'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: darkMode
                                      ? SgkAppColors.slate400
                                      : SgkAppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${list[i]['xp']} XP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: darkMode
                                ? SgkAppColors.slate300
                                : SgkAppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
