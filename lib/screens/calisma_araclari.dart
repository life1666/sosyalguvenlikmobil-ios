import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mesaitakip/mesaihesaplama.dart';
import '../utils/emeklilik_statulu_hesap.dart';
import '../sonhesaplama/sonhesaplama.dart';
import '../utils/app_design.dart';
import '../utils/kidem_yazisi_hesabi.dart';
import '../utils/progress_service.dart';
import '../services/notification_service.dart';
import '../services/account_scoped_local_store.dart';
import '../services/personal_profile_store.dart';
import '../services/premium_pdf_action.dart';
import 'yanmenu/calisma_bilgilerim.dart';
import 'premium_feature_gate.dart';

const _roleKey = 'app_user_role';
const _notificationKey = 'personal_notification_preferences';
const _comparisonKey = 'comparison_results';

class CalismaAraclariDeposu {
  static Future<String> rol() async =>
      (await SharedPreferences.getInstance()).getString(_roleKey) ?? 'Çalışan';

  static Future<void> rolKaydet(String value) async =>
      (await SharedPreferences.getInstance()).setString(_roleKey, value);

  static Future<Map<String, dynamic>> profil() async {
    return PersonalProfileStore().readMap();
  }

  static Future<Map<String, bool>> bildirimler() async {
    const defaults = NotificationService.defaultPreferences;
    final raw = await AccountScopedLocalStore().read(_notificationKey);
    if (raw == null) return Map<String, bool>.from(defaults);
    try {
      return {
        ...defaults,
        ...Map<String, dynamic>.from(jsonDecode(raw) as Map)
            .map((key, value) => MapEntry(key, value == true)),
      };
    } catch (_) {
      return Map<String, bool>.from(defaults);
    }
  }

  static Future<void> bildirimKaydet(Map<String, bool> value) async =>
      AccountScopedLocalStore().write(_notificationKey, jsonEncode(value));

  static Future<List<Map<String, dynamic>>> karsilastirmalar() async {
    final raw =
        (await SharedPreferences.getInstance()).getString(_comparisonKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class RolSecimiEkrani extends StatefulWidget {
  const RolSecimiEkrani({super.key});

  @override
  State<RolSecimiEkrani> createState() => _RolSecimiEkraniState();
}

class _RolSecimiEkraniState extends State<RolSecimiEkrani> {
  String _role = 'Çalışan';

  @override
  void initState() {
    super.initState();
    CalismaAraclariDeposu.rol().then((value) {
      if (mounted) setState(() => _role = value);
    });
  }

  @override
  Widget build(BuildContext context) => _ToolPage(
        title: 'Kullanım rolü',
        icon: Icons.badge_outlined,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'Çalışan', label: Text('Çalışan')),
              ButtonSegment(value: 'İşveren', label: Text('İşveren')),
            ],
            selected: {_role},
            onSelectionChanged: (value) async {
              setState(() => _role = value.first);
              await CalismaAraclariDeposu.rolKaydet(_role);
            },
          ),
          const SizedBox(height: 20),
          _InfoPanel(
            title: _role == 'Çalışan'
                ? 'Çalışan görünümü etkin'
                : 'İşveren görünümü etkin',
            text: _role == 'Çalışan'
                ? 'Haklar, emeklilik, izin ve kişisel çalışma bilgileri öne çıkarılır.'
                : 'Bordro, maliyet, bildirim ve işveren yükümlülükleri öne çıkarılır.',
          ),
        ]),
      );
}

class HaklarimEkrani extends StatefulWidget {
  const HaklarimEkrani({super.key, this.demoMode = false, this.onPremiumTap});

  final bool demoMode;
  final VoidCallback? onPremiumTap;

  @override
  State<HaklarimEkrani> createState() => _HaklarimEkraniState();
}

class _HaklarimEkraniState extends State<HaklarimEkrani> {
  bool _loading = true;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    ProgressService.record('rights_opened');
    _load();
  }

  Future<void> _load() async {
    final profile = widget.demoMode
        ? <String, dynamic>{
            'dogumTarihi': DateTime(1985, 6, 15).millisecondsSinceEpoch,
            'ilkIseGirisTarihi': DateTime(2006, 9, 1).millisecondsSinceEpoch,
            'mevcutIsyeriBaslangic':
                DateTime(2021, 1, 1).millisecondsSinceEpoch,
            'toplamPrimGun': 5400,
            'cinsiyet': 'Kadın',
            'sigortaKolu': '4/a (SSK)',
          }
        : await CalismaAraclariDeposu.profil();
    if (mounted)
      setState(() {
        _profile = profile;
        _loading = false;
      });
  }

  DateTime? _date(String key) {
    final value = _profile[key];
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  DateTime _addYears(DateTime value, int years) {
    final year = value.year + years;
    final lastDay = DateTime(year, value.month + 1, 0).day;
    return DateTime(year, value.month, value.day.clamp(1, lastDay));
  }

  DateTime _addMonths(DateTime value, int months) {
    final firstOfTarget = DateTime(value.year, value.month + months, 1);
    final lastDay =
        DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
    return DateTime(
        firstOfTarget.year, firstOfTarget.month, value.day.clamp(1, lastDay));
  }

  int get _recordedPrim => int.tryParse('${_profile['toplamPrimGun']}') ?? 0;

  List<_RightMilestone> _rights() {
    final now = DateUtils.dateOnly(DateTime.now());
    final jobStart = _date('mevcutIsyeriBaslangic');
    final rights = <_RightMilestone>[];

    if (jobStart != null) {
      final noticeWeeks = now.isBefore(_addMonths(jobStart, 6))
          ? 2
          : now.isBefore(_addMonths(jobStart, 18))
              ? 4
              : now.isBefore(_addYears(jobStart, 3))
                  ? 6
                  : 8;
      rights.add(_RightMilestone(
        title: 'İhbar süresi güvencesi',
        description:
            'Mevcut çalışma sürenize göre bildirim süreniz $noticeWeeks hafta.',
        detail:
            'Belirsiz süreli sözleşmelerde bildirim süresi; feshi yapan taraf, sözleşme ve somut duruma göre değerlendirilir.',
        date: DateUtils.dateOnly(jobStart),
        earned: true,
        icon: Icons.schedule_rounded,
        status: '$noticeWeeks hafta',
      ));

      final firstYear = _addYears(jobStart, 1);
      rights.addAll([
        _RightMilestone(
          title: 'Yıllık ücretli izin',
          description: now.isBefore(firstYear)
              ? 'Aynı işyerindeki bir yıllık çalışma süresi tamamlandığında başlar.'
              : 'Bir yıllık çalışma eşiğiniz tamamlandı; izin günlerinizi işveren kayıtlarıyla takip edin.',
          detail:
              'Kullanılmış veya devreden izin günleri uygulamada kayıtlı olmadığı için burada yalnızca çalışma süresine bağlı başlangıç eşiği izlenir.',
          date: firstYear,
          earned: !now.isBefore(firstYear),
          icon: Icons.beach_access_rounded,
          status: now.isBefore(firstYear)
              ? _remaining(firstYear, now)
              : 'Hak edildi',
        ),
        _RightMilestone(
          title: '20 günlük izin dönemi',
          description:
              'Aynı işverendeki hizmet süreniz beş yılı aştığında yıllık izin alt sınırı yükselir.',
          detail:
              'Bu tarih çalışma bilgilerinizdeki mevcut işe giriş tarihinden hesaplanır. İşveren kayıtlarındaki kıdem süresi esas alınmalıdır.',
          date: _addYears(jobStart, 5).add(const Duration(days: 1)),
          earned: !now
              .isBefore(_addYears(jobStart, 5).add(const Duration(days: 1))),
          icon: Icons.event_available_rounded,
          status:
              now.isBefore(_addYears(jobStart, 5).add(const Duration(days: 1)))
                  ? _remaining(
                      _addYears(jobStart, 5).add(const Duration(days: 1)), now)
                  : 'Hak edildi',
        ),
        _RightMilestone(
          title: '26 günlük izin dönemi',
          description:
              'Aynı işverendeki hizmet süreniz on beş yılı tamamladığında yıllık izin alt sınırı yükselir.',
          detail:
              'Bu tarih çalışma bilgilerinizdeki mevcut işe giriş tarihinden hesaplanır. Özel durumlar daha yüksek izin süresi doğurabilir.',
          date: _addYears(jobStart, 15),
          earned: !now.isBefore(_addYears(jobStart, 15)),
          icon: Icons.verified_rounded,
          status: now.isBefore(_addYears(jobStart, 15))
              ? _remaining(_addYears(jobStart, 15), now)
              : 'Hak edildi',
        ),
      ]);
    }

    final birth = _date('dogumTarihi');
    final insuranceStart = _date('ilkIseGirisTarihi');
    final gender = _profile['cinsiyet'] as String?;
    final insuranceType = '${_profile['sigortaKolu']}';

    if (insuranceStart != null && insuranceType.startsWith('4/a')) {
      DateTime primTarget(int requiredDays) {
        final missing = requiredDays - _recordedPrim;
        if (missing <= 0) return now;
        return _addMonths(now, (missing / 30).ceil());
      }

      DateTime later(DateTime first, DateTime second) =>
          first.isAfter(second) ? first : second;
      DateTime earlier(DateTime first, DateTime second) =>
          first.isBefore(second) ? first : second;

      final firstEmploymentYear =
          jobStart == null ? now : _addYears(jobStart, 1);
      final currentEmploymentYears = jobStart == null
          ? 0
          : now.difference(DateUtils.dateOnly(jobStart)).inDays ~/ 365;
      final sgkResult = kidemYazisiHesapla(
        sigortaBaslangici: insuranceStart,
        primGunu: _recordedPrim,
        sonIsyerindekiCalismaYili: currentEmploymentYears,
        kontrolTarihi: now,
      );
      late final DateTime sgkTarget;
      late final String conditionSummary;
      final beforeSeptember1999 = insuranceStart.isBefore(DateTime(1999, 9, 8));
      final beforeMay2008 = insuranceStart.isBefore(DateTime(2008, 5, 1));

      if (beforeSeptember1999) {
        final durationTarget = _addYears(insuranceStart, 15);
        sgkTarget = later(durationTarget, primTarget(3600));
        conditionSummary =
            '15 yıl sigortalılık ve 3600 prim günü · kayıtlı $_recordedPrim gün';
      } else if (beforeMay2008) {
        final durationTarget = _addYears(insuranceStart, 25);
        final alternativeTarget = later(durationTarget, primTarget(4500));
        final fullDayTarget = primTarget(7000);
        sgkTarget = earlier(alternativeTarget, fullDayTarget);
        conditionSummary =
            '7000 gün veya 25 yıl sigortalılık + 4500 gün · kayıtlı $_recordedPrim gün';
      } else {
        final gradualDays = sgkResult.gerekenPrim;
        sgkTarget = primTarget(gradualDays);
        conditionSummary =
            'Kademeli prim eşiği $gradualDays gün · kayıtlı $_recordedPrim gün';
      }

      final target = later(firstEmploymentYear, sgkTarget);
      final earned = sgkResult.hata == null && sgkResult.hakKazandi;
      rights.add(_RightMilestone(
        title: 'SGK kıdem yazısı koşulu',
        description: jobStart == null
            ? 'Mevcut işe başlangıç tarihinizi eklediğinizde bir yıllık işyeri koşulu kontrol edilir.'
            : sgkResult.hata != null
                ? 'Çalışma Hayatım bilgilerinizdeki sigorta başlangıcı ve prim gününü kontrol edin.'
                : earned
                    ? 'Kayıtlı bilgilerinize göre, SGK yazısıyla kendi isteğinizle ayrılarak kıdem tazminatı talep etme koşullarını sağlıyor görünüyorsunuz.'
                    : 'Yaş dışındaki emeklilik şartları ve aynı işverende bir yıllık çalışma koşulu henüz tamamlanmadı.',
        detail: jobStart == null
            ? '$conditionSummary. SGK kıdem yazısı için mevcut işveren yanında en az bir tam yıl çalışma bilgisi de gereklidir.'
            : sgkResult.hata != null
                ? sgkResult.hata!
                : earned
                    ? '$conditionSummary. İşten ayrılmadan önce SGK’dan kıdem tazminatı yazısı alınmalı; kesin değerlendirmede SGK kayıtları, iş sözleşmesi ve ayrılış işlemi esas alınır.'
                    : '$conditionSummary. Eksik prim: ${sgkResult.eksikPrim} gün. Mevcut işverende en az bir tam yıl gerekir. Tarih tahminidir; SGK hizmet dökümünüzdeki kayıtlar esas alınır.',
        date: DateUtils.dateOnly(target),
        earned: earned,
        icon: Icons.description_outlined,
        status: jobStart == null
            ? 'İş başlangıcı gerekli'
            : sgkResult.hata != null
                ? 'Bilgileri kontrol edin'
                : earned
                    ? 'SGK yazısı alınabilir'
                    : _remaining(target, now),
      ));
    }

    if (birth != null &&
        insuranceStart != null &&
        gender != null &&
        (insuranceType.startsWith('4/a') ||
            insuranceType.startsWith('4/b') ||
            insuranceType.startsWith('4/c'))) {
      try {
        final result = emeklilikHesaplaStatulu(
          sigortaKolu: insuranceType,
          dogumTarihi: birth,
          cinsiyet: gender,
          sigortaBaslangici: insuranceStart,
          primGunu: _recordedPrim,
        );
        if (result == null) throw StateError('Sigorta kolu tanınmadı.');
        final eligible = (result['emekliMi'] as Map?)?['normal'] == true;
        final estimate =
            (result['tahminiSonuclar'] as Map?)?['Normal Emeklilik'] as Map?;
        final rawDate = estimate?['tahminiTarih'];
        final requiredAge = result['reqAgeNormal'] as int? ?? 0;
        final requiredYears = result['reqInsuranceYearsNormal'] as int? ?? 0;
        final target = eligible
            ? now
            : rawDate is DateTime
                ? rawDate
                : rawDate is int
                    ? DateTime.fromMillisecondsSinceEpoch(rawDate)
                    : requiredAge > 0
                        ? _addYears(birth, requiredAge)
                        : requiredYears > 0
                            ? _addYears(insuranceStart, requiredYears)
                            : now;
        final requiredDays = result['reqPrimNormal'] as int? ?? 0;
        rights.add(_RightMilestone(
          title: 'Normal emeklilik',
          description: eligible
              ? 'Yaş ve prim şartları kayıtlı bilgilerinize göre tamamlandı.'
              : 'Tahmini tarih; yaş koşulu ve prim gününüzün düzenli artacağı varsayımıyla hesaplandı.',
          detail:
              'Hesapta kayıtlı $_recordedPrim gün kullanıldı${requiredDays > 0 ? '; hedef $requiredDays gün' : ''}${requiredYears > 0 ? '; hedef $requiredYears sigortalılık yılı' : ''}. Kesin hak sahipliği için SGK hizmet dökümü esas alınır.',
          date: DateUtils.dateOnly(target),
          earned: eligible,
          icon: Icons.account_balance_rounded,
          status: eligible ? 'Hak edildi' : _remaining(target, now),
        ));
      } catch (_) {
        // Eksik veya eski profil verisi diğer hakların gösterilmesini engellemez.
      }
    }
    rights.sort((a, b) => a.date.compareTo(b.date));
    return rights;
  }

  String _remaining(DateTime target, DateTime now) {
    final days = DateUtils.dateOnly(target).difference(now).inDays;
    if (days <= 0) return 'Tarih geldi';
    if (days < 60) return '$days gün kaldı';
    final months = (days / 30.44).ceil();
    if (months < 24) return '$months ay kaldı';
    return '${(days / 365.25).ceil()} yıl kaldı';
  }

  @override
  Widget build(BuildContext context) {
    final rights = _rights();
    final earned = rights.where((item) => item.earned).toList();
    final pending = rights.where((item) => !item.earned).toList();
    final hasWorkData = _date('mevcutIsyeriBaslangic') != null;
    final page = Scaffold(
      backgroundColor: AppDesign.activeBackground,
      appBar: AppDesign.appBar('Haklarım', actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield_rounded,
              color: Color(0xFF16A268), size: 23),
        ),
      ]),
      body: AppContent(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                  children: [
                    if (widget.demoMode) ...[
                      Row(children: [
                        const Icon(Icons.visibility_outlined, size: 18),
                        const SizedBox(width: 7),
                        const Expanded(
                            child: Text('Örnek veriler gösteriliyor')),
                        TextButton(
                            onPressed: widget.onPremiumTap,
                            child: const Text('Kendi haklarım')),
                      ]),
                      const SizedBox(height: 10),
                    ],
                    _RightsSummary(
                      earnedCount: earned.length,
                      hasWorkData: hasWorkData,
                    ),
                    if (!hasWorkData) ...[
                      const SizedBox(height: 16),
                      _MissingWorkInfo(onTap: _openProfile),
                    ],
                    if (earned.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      _sectionTitle('Kazanılmış Haklar'),
                      const SizedBox(height: 14),
                      for (var i = 0; i < earned.length; i++)
                        _RightTimelineCard(
                          item: earned[i],
                          onTap: () => _showRight(earned[i]),
                        ),
                    ],
                    if (pending.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _sectionTitle('Bekleyen Haklar'),
                      const SizedBox(height: 14),
                      for (var i = 0; i < pending.length; i++)
                        _RightTimelineCard(
                          item: pending[i],
                          onTap: () => _showRight(pending[i]),
                        ),
                    ],
                    const SizedBox(height: 22),
                    _RightsInfoBox(onEdit: _openProfile),
                    const SizedBox(height: 10),
                    Text(
                      'Kesin hak sahipliği; sözleşme, ayrılış nedeni, hizmet dökümü ve güncel mevzuata göre değişebilir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppDesign.activeMuted,
                          fontSize: 10.5,
                          height: 1.45),
                    ),
                  ],
                ),
              ),
      ),
    );
    if (widget.demoMode) return page;
    return PremiumFeatureGate(
      title: 'Haklarım',
      child: page,
      previewBuilder: (context, status, openPremium) =>
          HaklarimEkrani(demoMode: true, onPremiumTap: openPremium),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                letterSpacing: 1.25,
                fontWeight: FontWeight.w800)),
      );

  Future<void> _openProfile() async {
    if (widget.demoMode) {
      widget.onPremiumTap?.call();
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CalismaBilgilerim()),
    );
    if (changed == true && mounted) await _load();
  }

  void _showRight(_RightMilestone item) {
    ProgressService.recordUnique('rights_detail_opened', item.title);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppDesign.activeSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(item.title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppDesign.activeInk)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(
                  item.earned
                      ? Icons.check_circle_rounded
                      : Icons.lock_clock_rounded,
                  color: item.earned
                      ? const Color(0xFF16835A)
                      : AppDesign.activeMuted,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                  '${DateFormat('d MMMM yyyy', 'tr_TR').format(item.date)} · ${item.status}',
                  style: TextStyle(
                      color: AppDesign.activeInk, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            Text(item.detail,
                style: TextStyle(color: AppDesign.activeMuted, height: 1.55)),
          ]),
        ),
      ),
    );
  }
}

class _RightMilestone {
  final String title, description, detail, status;
  final DateTime date;
  final bool earned;
  final IconData icon;
  const _RightMilestone({
    required this.title,
    required this.description,
    required this.detail,
    required this.status,
    required this.date,
    required this.earned,
    required this.icon,
  });
}

class _RightsSummary extends StatelessWidget {
  final int earnedCount;
  final bool hasWorkData;
  const _RightsSummary({required this.earnedCount, required this.hasWorkData});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
        decoration: BoxDecoration(
          color: AppDesign.activeSurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppDesign.activeBorder),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0F172A), blurRadius: 18, offset: Offset(0, 6))
          ],
        ),
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFECF9F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Color(0xFF22A96E), size: 34),
          ),
          const SizedBox(height: 15),
          Text(
            hasWorkData ? 'Güvendesin!' : 'Haklarını takip et',
            style: TextStyle(
                color: AppDesign.activeInk,
                fontSize: 19,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          if (hasWorkData)
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Şu ana kadar '),
                TextSpan(
                    text: '$earnedCount yasal hakkın',
                    style: const TextStyle(
                        color: Color(0xFF16835A), fontWeight: FontWeight.w800)),
                const TextSpan(text: ' aktifleşti.'),
              ]),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppDesign.activeMuted, fontSize: 12, height: 1.4),
            )
          else
            Text(
              'Mevcut iş bilgilerini eklediğinizde haklarınız otomatik hesaplanır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppDesign.activeMuted, fontSize: 12, height: 1.4),
            ),
        ]),
      );
}

class _MissingWorkInfo extends StatelessWidget {
  final VoidCallback onTap;
  const _MissingWorkInfo({required this.onTap});
  @override
  Widget build(BuildContext context) => AppSurface(
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D8),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.work_history_outlined,
                  color: Color(0xFFB66A00))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Mevcut iş bilgisi eksik',
                    style: TextStyle(
                        color: AppDesign.activeInk,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    'İşe giriş tarihi ve brüt maaşı ekleyerek kıdem ve izin takibini başlatın.',
                    style: TextStyle(
                        color: AppDesign.activeMuted,
                        fontSize: 12,
                        height: 1.4)),
              ])),
          IconButton(
              onPressed: onTap, icon: const Icon(Icons.arrow_forward_rounded)),
        ]),
      );
}

class _RightTimelineCard extends StatelessWidget {
  final _RightMilestone item;
  final VoidCallback onTap;
  const _RightTimelineCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF16835A);
    final mutedColor = const Color(0xFF94A3B8);
    final content = Material(
      color: item.earned
          ? AppDesign.activeSurface
          : (AppDesign.isDark
              ? const Color(0xFF172033)
              : const Color(0xFFF7F8FA)),
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.earned
                    ? const Color(0xFFECF9F2)
                    : const Color(0xFFE8EBEF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon,
                  color: item.earned ? activeColor : mutedColor, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: TextStyle(
                            color:
                                item.earned ? AppDesign.activeInk : mutedColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(item.description,
                        style: TextStyle(
                            color: item.earned
                                ? AppDesign.activeMuted
                                : const Color(0xFFA8B1C0),
                            fontSize: 10.5,
                            height: 1.35)),
                  ]),
            ),
            const SizedBox(width: 8),
            if (item.earned)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: Color(0xFF22A96E), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 15),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: Color(0xFFCBD2DC), size: 19),
                      const SizedBox(height: 4),
                      Text(item.status.toUpperCase(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800)),
                    ]),
              ),
          ]),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: item.earned
          ? DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFEDF1F5)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x080F172A),
                        blurRadius: 10,
                        offset: Offset(0, 3))
                  ]),
              child: content,
            )
          : CustomPaint(
              foregroundPainter: _DashedRRectPainter(
                  color: const Color(0xFFD8DEE7), radius: 17),
              child: content,
            ),
    );
  }
}

class _RightsInfoBox extends StatelessWidget {
  final VoidCallback onEdit;
  const _RightsInfoBox({required this.onEdit});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF6FF),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFD9EAFE)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(
                    text:
                        'Hakların, işe giriş tarihin ve çalışma sürene göre otomatik hesaplanır. '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: const Text('Bilgilerini düzenle',
                        style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
              style: const TextStyle(
                  color: Color(0xFF315D91), fontSize: 11, height: 1.45),
            ),
          ),
        ]),
      );
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
            metric.extractPath(
                distance, (distance + 6).clamp(0, metric.length)),
            paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class YasalTakvimEkrani extends StatefulWidget {
  const YasalTakvimEkrani({super.key});

  @override
  State<YasalTakvimEkrani> createState() => _YasalTakvimEkraniState();
}

class _YasalTakvimEkraniState extends State<YasalTakvimEkrani> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _role = 'Çalışan';
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    Future.wait([CalismaAraclariDeposu.rol(), CalismaAraclariDeposu.profil()])
        .then((values) {
      if (!mounted) return;
      setState(() {
        _role = values[0] as String;
        _profile = values[1] as Map<String, dynamic>;
      });
    });
  }

  List<(DateTime, String, String)> _events() {
    final result = <(DateTime, String, String)>[];
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    result.add((
      lastDay,
      'Aylık çalışma özeti',
      'Maaş, prim ve bordro bilgilerinizi kontrol edin.'
    ));
    final raw = _profile['mevcutIsyeriBaslangic'];
    if (raw is int) {
      final start = DateTime.fromMillisecondsSinceEpoch(raw);
      final anniversary = DateTime(_month.year, start.month, start.day);
      if (anniversary.month == _month.month) {
        result.add((
          anniversary,
          'Çalışma yıl dönümü',
          'Kıdem ve yıllık izin haklarınızı yeniden kontrol edin.'
        ));
      }
    }
    if (_role == 'İşveren') {
      result.add((
        DateTime(_month.year, _month.month, 10),
        'Bordro hazırlık kontrolü',
        'Çalışan ve ücret değişikliklerini gözden geçirin.'
      ));
      result.add((
        DateTime(_month.year, _month.month, 20),
        'Bildirim hazırlık kontrolü',
        'Resmî sürelerden önce bildirime esas kayıtları kontrol edin.'
      ));
    }
    result.sort((a, b) => a.$1.compareTo(b.$1));
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('Yasal takvim'),
        body: AppContent(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              AppSurface(
                child: Row(children: [
                  IconButton(
                      onPressed: () => setState(() =>
                          _month = DateTime(_month.year, _month.month - 1)),
                      icon: const Icon(Icons.chevron_left)),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', 'tr_TR').format(_month),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppDesign.activeInk),
                    ),
                  ),
                  IconButton(
                      onPressed: () => setState(() =>
                          _month = DateTime(_month.year, _month.month + 1)),
                      icon: const Icon(Icons.chevron_right)),
                ]),
              ),
              const SizedBox(height: 16),
              for (final event in _events()) ...[
                AppSurface(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            Text('${event.$1.day}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB))),
                            Text(DateFormat('EEE', 'tr_TR').format(event.$1),
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF2563EB))),
                          ]),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.$2,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppDesign.activeInk)),
                                const SizedBox(height: 5),
                                Text(event.$3,
                                    style: TextStyle(
                                        color: AppDesign.activeMuted,
                                        fontSize: 12,
                                        height: 1.4)),
                              ]),
                        ),
                      ]),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'Takvim, kişisel takip önerileri sunar. Resmî bildirim ve ödeme sürelerini ilgili kurumların güncel duyurularından doğrulayın.',
                style: TextStyle(
                    color: AppDesign.activeMuted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      );
}

class BildirimTercihleriEkrani extends StatefulWidget {
  const BildirimTercihleriEkrani({super.key});

  @override
  State<BildirimTercihleriEkrani> createState() =>
      _BildirimTercihleriEkraniState();
}

class _BildirimTercihleriEkraniState extends State<BildirimTercihleriEkrani> {
  Map<String, bool> _values = {};

  static const _items = {
    'emeklilik': (
      'Emeklilik ilerlemesi',
      'Prim ve yaş eşiklerindeki değişiklikler'
    ),
    'izin': ('Yıllık izin', 'Yeni izin hakkı oluştuğunda'),
    'vergi': ('Vergi dilimi', 'Maaş hesabındaki vergi dilimi değiştiğinde'),
    'kidem': ('Kıdem eşikleri', 'Yeni çalışma yılı tamamlandığında'),
    'takvim': ('Takvim hatırlatmaları', 'Yaklaşan kişisel takip tarihleri'),
    'duyuru': (
      'Mevzuat ve uygulama duyuruları',
      'SGK oranları ve önemli uygulama değişiklikleri'
    ),
  };

  bool _permissionGranted = false;
  bool _busy = false;
  int _scheduledCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await CalismaAraclariDeposu.bildirimler();
    final enabled = await NotificationService.instance.notificationsEnabled();
    final count = await NotificationService.instance.pendingPersonalCount();
    if (!mounted) return;
    setState(() {
      _values = value;
      _permissionGranted = enabled;
      _scheduledCount = count;
    });
  }

  Future<void> _requestPermission() async {
    if (_busy) return;
    setState(() => _busy = true);
    final granted = await NotificationService.instance.requestPermission();
    if (granted) {
      await NotificationService.instance.applyPreferences(_values);
    }
    final count = await NotificationService.instance.pendingPersonalCount();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _permissionGranted = granted;
      _scheduledCount = count;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(granted
          ? 'Bildirimler etkinleştirildi.'
          : 'Bildirim izni verilmedi. Sistem ayarlarından açabilirsiniz.'),
    ));
  }

  Future<void> _changePreference(String key, bool value) async {
    setState(() => _values[key] = value);
    await CalismaAraclariDeposu.bildirimKaydet(_values);
    await NotificationService.instance.applyPreferences(_values);
    final count = await NotificationService.instance.pendingPersonalCount();
    if (mounted) setState(() => _scheduledCount = count);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('Bildirimler'),
        body: AppContent(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const _InfoPanel(
                title: 'Size özel takip',
                text:
                    'Hatırlatmalar kayıtlı çalışma bilgileriniz ve hesaplama sonuçlarınız üzerinden hazırlanır.',
              ),
              const SizedBox(height: 16),
              AppSurface(
                child: Row(children: [
                  Icon(
                    _permissionGranted
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    color: _permissionGranted
                        ? const Color(0xFF16A268)
                        : AppDesign.activeMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _permissionGranted
                                ? 'Bildirimler aktif'
                                : 'Bildirim izni gerekli',
                            style: TextStyle(
                                color: AppDesign.activeInk,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _permissionGranted
                                ? '$_scheduledCount kişisel hatırlatma planlandı.'
                                : 'Hatırlatmaları alabilmek için cihaz iznini açın.',
                            style: TextStyle(
                                color: AppDesign.activeMuted, fontSize: 12),
                          ),
                        ]),
                  ),
                  if (!_permissionGranted)
                    TextButton(
                      onPressed: _busy ? null : _requestPermission,
                      child: Text(_busy ? 'Bekleyin' : 'Etkinleştir'),
                    )
                  else if (kDebugMode)
                    IconButton(
                      tooltip: 'Test bildirimi gönder',
                      onPressed:
                          NotificationService.instance.showTestNotification,
                      icon: const Icon(Icons.send_outlined),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              AppSurface(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [
                  for (final entry in _items.entries)
                    SwitchListTile.adaptive(
                      value: _values[entry.key] ?? false,
                      title: Text(entry.value.$1,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppDesign.activeInk)),
                      subtitle: Text(entry.value.$2,
                          style: TextStyle(
                              fontSize: 12, color: AppDesign.activeMuted)),
                      onChanged: (value) => _changePreference(entry.key, value),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              Text(
                'Kişisel hatırlatmalar Çalışma Hayatım verilerinizden cihazda hazırlanır. Genel duyurular Firebase Cloud Messaging üzerinden alınır.',
                style: TextStyle(
                    color: AppDesign.activeMuted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      );
}

class SenaryoKarsilastirmaEkrani extends StatefulWidget {
  const SenaryoKarsilastirmaEkrani({super.key});

  @override
  State<SenaryoKarsilastirmaEkrani> createState() =>
      _SenaryoKarsilastirmaEkraniState();
}

class _SenaryoKarsilastirmaEkraniState
    extends State<SenaryoKarsilastirmaEkrani> {
  final _first = TextEditingController(text: '50000');
  final _second = TextEditingController(text: '60000');
  final _years = TextEditingController(text: '5');
  String _type = 'Maaş';
  (double, double)? _result;
  List<Map<String, dynamic>> _saved = [];

  @override
  void initState() {
    super.initState();
    CalismaAraclariDeposu.karsilastirmalar().then((value) {
      if (mounted) setState(() => _saved = value.reversed.take(2).toList());
    });
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    _years.dispose();
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));

  void _calculate() {
    final first = _number(_first.text);
    final second = _number(_second.text);
    if (first == null || second == null || first <= 0 || second <= 0) return;
    if (_type == 'Maaş') {
      final engine = SalaryEngine(
          year: DateTime.now().year,
          status: EmployeeStatus.normal,
          incentive: Incentive.none);
      final month = DateTime.now().month - 1;
      setState(() => _result = (
            engine
                .calculateNetFromGross(
                    grossMonthly: first,
                    monthIndex: month,
                    cumulativeTaxBasePrev: 0)
                .net,
            engine
                .calculateNetFromGross(
                    grossMonthly: second,
                    monthIndex: month,
                    cumulativeTaxBasePrev: 0)
                .net,
          ));
    } else {
      final years = _number(_years.text) ?? 0;
      const ceiling = 64948.77;
      const stampRate = 0.00759;
      setState(() => _result = (
            first.clamp(0, ceiling) * years * (1 - stampRate),
            second.clamp(0, ceiling) * years * (1 - stampRate),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    return _ToolPage(
      title: 'Senaryo karşılaştırma',
      icon: Icons.compare_arrows_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'Maaş', label: Text('Maaş')),
            ButtonSegment(value: 'Kıdem', label: Text('Kıdem')),
          ],
          selected: {_type},
          onSelectionChanged: (value) => setState(() {
            _type = value.first;
            _result = null;
          }),
        ),
        const SizedBox(height: 20),
        TextField(
            controller: _first,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: '1. senaryo brüt tutarı')),
        const SizedBox(height: 14),
        TextField(
            controller: _second,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: '2. senaryo brüt tutarı')),
        if (_type == 'Kıdem') ...[
          const SizedBox(height: 14),
          TextField(
              controller: _years,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Çalışma süresi (yıl)')),
        ],
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _calculate, child: const Text('Karşılaştır')),
        if (_result != null) ...[
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: _ResultValue(
                    label: '1. senaryo', value: money.format(_result!.$1))),
            const SizedBox(width: 12),
            Expanded(
                child: _ResultValue(
                    label: '2. senaryo', value: money.format(_result!.$2))),
          ]),
          const SizedBox(height: 12),
          Text('Fark: ${money.format((_result!.$2 - _result!.$1).abs())}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppDesign.ink, fontWeight: FontWeight.w700)),
        ],
        if (_saved.isNotEmpty) ...[
          const SizedBox(height: 26),
          const Divider(color: AppDesign.border),
          const SizedBox(height: 10),
          const Text('Sonuçlardan eklenenler',
              style:
                  TextStyle(color: AppDesign.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final item in _saved)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item['title']?.toString() ?? 'Hesaplama'),
              subtitle: Text(item['date']?.toString() ?? ''),
              trailing: const Icon(Icons.chevron_right),
            ),
        ],
      ]),
    );
  }
}

class PremiumRaporEkrani extends StatefulWidget {
  const PremiumRaporEkrani({super.key});

  @override
  State<PremiumRaporEkrani> createState() => _PremiumRaporEkraniState();
}

class _PremiumRaporEkraniState extends State<PremiumRaporEkrani> {
  Map<String, dynamic> _profile = {};
  List<SonHesaplama> _history = [];
  String _role = 'Çalışan';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.wait([
      CalismaAraclariDeposu.profil(),
      SonHesaplamalarDeposu.listele(),
      CalismaAraclariDeposu.rol(),
    ]).then((values) {
      if (!mounted) return;
      setState(() {
        _profile = values[0] as Map<String, dynamic>;
        _history = values[1] as List<SonHesaplama>;
        _role = values[2] as String;
        _loading = false;
      });
    });
  }

  int get _completeness {
    const keys = [
      'dogumTarihi',
      'ilkIseGirisTarihi',
      'toplamPrimGun',
      'mevcutIsyeriBaslangic',
      'guncelBrutMaas'
    ];
    return (keys.where((key) => _profile[key] != null).length /
            keys.length *
            100)
        .round();
  }

  Future<void> _sharePdf() async {
    final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final document = pw.Document();
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font),
      build: (_) => [
        pw.Text('İş & SGK Asistan - Çalışma Hayatı Raporu',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text('Rol: $_role'),
        pw.Text('Profil tamamlanma: %$_completeness'),
        pw.Text('Kayıtlı hesaplama: ${_history.length}'),
        pw.SizedBox(height: 18),
        pw.Text('Son hesaplamalar',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        for (final item in _history.take(8)) ...[
          pw.SizedBox(height: 10),
          pw.Text(item.hesaplamaTuru,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(DateFormat('dd.MM.yyyy HH:mm').format(item.tarihSaat)),
          for (final row in item.sonuclar.entries.take(6))
            pw.Text('${row.key}: ${row.value}'),
        ],
        pw.SizedBox(height: 16),
        pw.Text('Bu rapor bilgi amaçlıdır; resmî belge niteliği taşımaz.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    ));
    await Printing.sharePdf(
        bytes: await document.save(), filename: 'calisma_hayati_raporu.pdf');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('Premium rapor'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : AppContent(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF102A56), Color(0xFF1D4ED8)]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Çalışma hayatı raporunuz',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('$_role görünümü · ${_history.length} kayıt',
                                style: const TextStyle(color: Colors.white70)),
                          ]),
                    ),
                    const SizedBox(height: 16),
                    AppSurface(
                      child: Column(children: [
                        _ReportRow(
                            label: 'Profil tamamlanma',
                            value: '%$_completeness'),
                        const Divider(color: AppDesign.border),
                        _ReportRow(
                            label: 'Kayıtlı hesaplama',
                            value: '${_history.length}'),
                        const Divider(color: AppDesign.border),
                        _ReportRow(
                            label: 'Son işlem',
                            value: _history.isEmpty
                                ? 'Henüz yok'
                                : DateFormat('dd.MM.yyyy')
                                    .format(_history.first.tarihSaat)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => PremiumPdfAction.run(context, _sharePdf),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF raporu oluştur'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rapor; kayıtlı profiliniz ve son hesaplamalarınızdan hazırlanır.',
                      style: TextStyle(
                          color: AppDesign.muted, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
      );
}

class _ToolPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ToolPage(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AppContent(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Geri Dön')),
                    const SizedBox(height: 12),
                    AppSurface(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(icon,
                                      color: const Color(0xFF2563EB))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(title,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppDesign.ink))),
                            ]),
                            const SizedBox(height: 22),
                            child,
                          ]),
                    ),
                  ]),
            ),
          ),
        ),
      );
}

class _InfoPanel extends StatelessWidget {
  final String title, text;
  const _InfoPanel({required this.title, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
          const SizedBox(height: 5),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF475569), fontSize: 12, height: 1.5)),
        ]),
      );
}

class _ResultValue extends StatelessWidget {
  final String label, value;
  const _ResultValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF166534))),
          const SizedBox(height: 6),
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF166534)))),
        ]),
      );
}

class _ReportRow extends StatelessWidget {
  final String label, value;
  const _ReportRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppDesign.muted))),
          Text(value,
              style: const TextStyle(
                  color: AppDesign.ink, fontWeight: FontWeight.w700)),
        ]),
      );
}
