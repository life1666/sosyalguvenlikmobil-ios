import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../referral/referral_kodu_servisi.dart';
import '../utils/app_design.dart';
import '../utils/progress_service.dart';
import 'calisma_araclari.dart';
import 'hesaplamalar_ekrani.dart';
import 'topluluk_ekrani.dart';
import 'yanmenu/calisma_bilgilerim.dart';

class IlerlemeEkrani extends StatefulWidget {
  const IlerlemeEkrani({super.key});

  @override
  State<IlerlemeEkrani> createState() => _IlerlemeEkraniState();
}

class _IlerlemeEkraniState extends State<IlerlemeEkrani> {
  static const _playStoreLink =
      'https://play.google.com/store/apps/details?id=com.sosyalguvenlik.mobil&pcampaignid=web_share';
  static const _appStoreLink =
      'https://apps.apple.com/us/app/sosyal-g%C3%BCvenlik-mobil/id6752835301';

  ProgressSnapshot? _snapshot;
  String? _referralCode;
  bool _loading = true;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<dynamic>([
      ProgressService.load(),
      ReferralKoduServisi.koduAl(),
    ]);
    if (!mounted) return;
    setState(() {
      _snapshot = results[0] as ProgressSnapshot;
      _referralCode = results[1] as String;
      _loading = false;
    });
  }

  Future<void> _openTask(ProgressTask task) async {
    Widget? page;
    switch (task.id) {
      case 'profile_core':
      case 'profile_work':
      case 'profile_current':
        page = const CalismaBilgilerim();
        break;
      case 'rights_open':
      case 'rights_details':
        page = const HaklarimEkrani();
        break;
      case 'community_open':
      case 'community_question':
        page = const ToplulukEkrani();
        break;
      case 'first_calculation':
      case 'calculation_explorer':
        page = const HesaplamalarEkrani();
        break;
      case 'invite':
        setState(() => _activeTab = 2);
        return;
      default:
        return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    await _load();
  }

  Future<void> _shareInvite() async {
    final code = _referralCode;
    if (code == null) return;
    await ReferralKoduServisi.paylas(
      referansKodu: code,
      playStoreLink: _playStoreLink,
      appStoreLink: _appStoreLink,
    );
    await ProgressService.record('invite_shared');
    await _load();
  }

  Future<void> _copyCode() async {
    final code = _referralCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Davet kodu kopyalandı.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('İlerlemem ve Kazanımlarım'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: AppContent(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    children: [
                      _ProgressHeader(snapshot: _snapshot!),
                      const SizedBox(height: 16),
                      _ProgressTabs(
                        value: _activeTab,
                        onChanged: (value) =>
                            setState(() => _activeTab = value),
                      ),
                      const SizedBox(height: 20),
                      if (_activeTab == 0) ...[
                        _SectionTitle(
                          title: _snapshot!.nextTask == null
                              ? 'Tüm adımlar tamamlandı'
                              : 'Sıradaki adımlar',
                          subtitle:
                              '${_snapshot!.tasks.where((task) => task.completed).length}/${_snapshot!.tasks.length} adım tamamlandı. Bir adıma dokunarak ilgili ekrana gidin.',
                        ),
                        const SizedBox(height: 12),
                        _TaskList(
                          tasks: [..._snapshot!.tasks]..sort((a, b) =>
                              (a.completed ? 1 : 0)
                                  .compareTo(b.completed ? 1 : 0)),
                          onTap: _openTask,
                        ),
                      ] else if (_activeTab == 1) ...[
                        const _SectionTitle(
                          title: 'Kazanımlar',
                          subtitle:
                              'Açılan rozetler çalışma hayatı takibindeki gelişiminizi gösterir.',
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _snapshot!.badges.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.12,
                          ),
                          itemBuilder: (_, index) =>
                              _BadgeCard(_snapshot!.badges[index]),
                        ),
                      ] else ...[
                        _InviteCard(
                          code: _referralCode ?? '--------',
                          shareCount: _snapshot!.inviteShareCount,
                          onCopy: _copyCode,
                          onShare: _shareInvite,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      );
}

class ProgressSummaryCard extends StatelessWidget {
  final VoidCallback onTap;
  const ProgressSummaryCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => FutureBuilder<ProgressSnapshot>(
        future: ProgressService.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final progress = snapshot.data!;
          return Material(
            color: AppDesign.activeSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppDesign.activeBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(alignment: Alignment.center, children: [
                      CircularProgressIndicator(
                        value: progress.score / 100,
                        strokeWidth: 5,
                        backgroundColor: AppDesign.activeBorder,
                      ),
                      Text('%${progress.score}',
                          style: TextStyle(
                              color: AppDesign.activeInk,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(progress.level,
                              style: TextStyle(
                                  color: AppDesign.activeInk,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(
                            progress.nextTask?.title ??
                                'Tüm ilerleme adımları tamamlandı.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppDesign.activeMuted, fontSize: 12),
                          ),
                        ]),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppDesign.activeMuted),
                ]),
              ),
            ),
          );
        },
      );
}

class _ProgressHeader extends StatelessWidget {
  final ProgressSnapshot snapshot;
  const _ProgressHeader({required this.snapshot});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppDesign.ink,
              Color.lerp(AppDesign.ink, Theme.of(context).primaryColor, .62)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('UYGULAMA KULLANIM İLERLEMESİ',
              style: TextStyle(
                  color: Color(0xFFB9D5FF),
                  fontSize: 11,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(snapshot.level,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: snapshot.score / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('%${snapshot.score} adım tamamlandı',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(
                '${snapshot.badges.where((b) => b.unlocked).length}/${snapshot.badges.length} kazanım',
                style: const TextStyle(color: Color(0xFFDBE4F1), fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(
            '${snapshot.calculationCount} hesaplama • ${snapshot.distinctCalculationCount} farklı tür',
            style: const TextStyle(color: Color(0xFFDBE4F1), fontSize: 12),
          ),
          if (snapshot.nextTask != null) ...[
            const SizedBox(height: 16),
            Text('Sıradaki: ${snapshot.nextTask!.title}',
                style: const TextStyle(color: Color(0xFFDBE4F1), fontSize: 13)),
          ],
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppDesign.activeInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: AppDesign.activeMuted, fontSize: 12, height: 1.4)),
        ],
      );
}

class _ProgressTabs extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _ProgressTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['İlerleme', 'Kazanımlar', 'Davet'];
    const icons = [
      Icons.trending_up_rounded,
      Icons.workspace_premium_outlined,
      Icons.group_add_outlined,
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppDesign.activeBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.activeBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = value == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      selected ? AppDesign.activeSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 16,
                      color: selected
                          ? Theme.of(context).primaryColor
                          : AppDesign.activeMuted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Theme.of(context).primaryColor
                              : AppDesign.activeMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<ProgressTask> tasks;
  final ValueChanged<ProgressTask> onTap;
  const _TaskList({required this.tasks, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppDesign.activeSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppDesign.activeBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < tasks.length; index++) ...[
              _TaskTile(
                task: tasks[index],
                onTap: () => onTap(tasks[index]),
              ),
              if (index != tasks.length - 1)
                Divider(height: 1, color: AppDesign.activeBorder),
            ],
          ],
        ),
      );
}

class _TaskTile extends StatelessWidget {
  final ProgressTask task;
  final VoidCallback onTap;
  const _TaskTile({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: task.completed
                    ? const Color(0xFF16A34A).withOpacity(.12)
                    : AppDesign.activeBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                  task.completed
                      ? Icons.check_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: task.completed
                      ? const Color(0xFF16A34A)
                      : AppDesign.activeMuted,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        style: TextStyle(
                            color: AppDesign.activeInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(task.description,
                        style: TextStyle(
                            color: AppDesign.activeMuted,
                            fontSize: 11,
                            height: 1.35)),
                  ]),
            ),
            const SizedBox(width: 8),
            Text(task.completed ? 'Tamam' : '+${task.points}',
                style: TextStyle(
                    color: task.completed
                        ? const Color(0xFF16A34A)
                        : Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            if (!task.completed) ...[
              const SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded,
                  color: AppDesign.activeMuted, size: 19),
            ],
          ]),
        ),
      );
}

class _BadgeCard extends StatelessWidget {
  final ProgressBadge badge;
  const _BadgeCard(this.badge);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppDesign.activeSurface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
              color: badge.unlocked
                  ? Theme.of(context).primaryColor.withOpacity(.35)
                  : AppDesign.activeBorder),
        ),
        child: Opacity(
          opacity: badge.unlocked ? 1 : .48,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(badge.unlocked ? badge.emoji : '🔒',
                style: const TextStyle(fontSize: 27)),
            const Spacer(),
            Text(badge.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppDesign.activeInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(badge.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppDesign.activeMuted, fontSize: 10.5, height: 1.3)),
          ]),
        ),
      );
}

class _InviteCard extends StatelessWidget {
  final String code;
  final int shareCount;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  const _InviteCard({
    required this.code,
    required this.shareCount,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) => AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(.12),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.group_add_outlined,
                  color: Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Arkadaşını davet et',
                        style: TextStyle(
                            color: AppDesign.activeInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('$shareCount kez paylaşıldı',
                        style: TextStyle(
                            color: AppDesign.activeMuted, fontSize: 11)),
                  ]),
            ),
          ]),
          const SizedBox(height: 15),
          Text('Kişisel davet kodunuz',
              style: TextStyle(color: AppDesign.activeMuted, fontSize: 11)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: AppDesign.activeBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppDesign.activeBorder)),
            child: Row(children: [
              Expanded(
                  child: Text(code,
                      style: TextStyle(
                          color: AppDesign.activeInk,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800))),
              IconButton(
                  tooltip: 'Kodu kopyala',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 19)),
            ]),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onShare,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13))),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Davet bağlantısını paylaş'),
          ),
          const SizedBox(height: 9),
          Text(
            'Paylaşım sayısı cihazda tutulur. Başarılı katılım ve Premium ödül takibi sunucu bağlantısı eklendiğinde etkinleşir.',
            style: TextStyle(
                color: AppDesign.activeMuted, fontSize: 10.5, height: 1.4),
          ),
        ]),
      );
}
