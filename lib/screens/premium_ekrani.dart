import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/premium_trial_service.dart';
import '../services/premium_access_service.dart';
import '../services/premium_store_service.dart';
import '../utils/app_design.dart';
import 'yanmenu/calisma_bilgilerim.dart';
import 'auth/giris_ekrani.dart';

class PremiumEkrani extends StatefulWidget {
  const PremiumEkrani({super.key});

  @override
  State<PremiumEkrani> createState() => _PremiumEkraniState();
}

class _PremiumEkraniState extends State<PremiumEkrani> {
  static final _privacyUrl = Uri.parse(
      'https://life1666.github.io/sgmobil-gizlilik-politikasi/launch');
  static final _termsUrl = Uri.parse(
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/');
  static final _manageUrl = Uri.parse(
      'https://apps.apple.com/account/subscriptions');
  bool _yearlySelected = true;
  bool _trialBusy = false;
  final _trialService = PremiumTrialService();
  final _store = PremiumStoreService.instance;
  late Future<PremiumTrialStatus> _trialFuture;
  late Future<bool> _profileFuture;

  @override
  void initState() {
    super.initState();
    _trialFuture = _trialService.load();
    _profileFuture = PremiumAccessService().hasProfile();
    _store.addListener(_onStoreChanged);
    if (_store.initialized) {
      _store.refresh();
    } else {
      _store.initialize();
    }
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _reloadTrial() {
    setState(() => _trialFuture = _trialService.load());
  }

  Future<void> _signInForTrial() async {
    final signedIn = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => const GirisEkrani(returnToCaller: true),
    ));
    if (!mounted) return;
    _reloadTrial();
    if (signedIn == true) {
      setState(() => _profileFuture = PremiumAccessService().hasProfile());
      await _store.refresh();
    }
  }

  Future<void> _openProfile() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => const CalismaBilgilerim(),
    ));
    if (!mounted) return;
    setState(() => _profileFuture = PremiumAccessService().hasProfile());
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bilgileriniz kaydedildi.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _startTrial() async {
    setState(() => _trialBusy = true);
    try {
      final status = await _trialService.start();
      if (!mounted) return;
      setState(() => _trialFuture = Future.value(status));
      if (status.phase == PremiumTrialPhase.active) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Deneme başlatılamadı. Bağlantınızı kontrol edip tekrar deneyin.'),
        behavior: SnackBarBehavior.floating,
      ));
      _reloadTrial();
    } finally {
      if (mounted) setState(() => _trialBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: AppDesign.activeBackground,
      appBar: AppDesign.appBar('Premium'),
      body: SafeArea(
        child: AppContent(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.workspace_premium_rounded,
                      color: primary, size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Çalışma hayatınızı yakından takip edin',
                          style: TextStyle(
                            color: AppDesign.activeInk,
                            fontSize: 21,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 6),
                      Text(
                          'Kişisel bilgilerinizle güncellenen pano, haklarınız ve raporlar tek yerde.',
                          style: TextStyle(
                              color: AppDesign.activeMuted, height: 1.4)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              _buildTrialPanel(context),
              const SizedBox(height: 12),
              _buildProfilePanel(context),
              const SizedBox(height: 24),
              _sectionTitle('Plan karşılaştırması'),
              const SizedBox(height: 10),
              AppSurface(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Column(children: const [
                  _ComparisonHeader(),
                  _ComparisonRow(title: 'Hesaplamalar ve sonuçlar', free: true),
                  _ComparisonRow(title: 'Topluluk', free: true),
                  _ComparisonRow(title: 'Bildirimler', free: true),
                  _ComparisonRow(title: 'Çalışma Hayatım panosu'),
                  _ComparisonRow(title: 'Haklarım takibi'),
                  _ComparisonRow(title: '12 aylık maaş analizi'),
                  _ComparisonRow(title: 'PDF rapor ve çıktılar'),
                ]),
              ),
              const SizedBox(height: 22),
              _sectionTitle('Plan seçin'),
              const SizedBox(height: 10),
              _PlanCard(
                title: 'Yıllık',
                price: _store.products[PremiumStoreService.yearlyId]?.price ??
                    'Mağazada henüz yok',
                period: '/ yıl',
                detail: 'Yıllık ödeme',
                badge: _store.products.containsKey(PremiumStoreService.yearlyId)
                    ? 'Yıllık avantaj'
                    : null,
                selected: _yearlySelected,
                onTap: () => setState(() => _yearlySelected = true),
              ),
              const SizedBox(height: 10),
              _PlanCard(
                title: 'Aylık',
                price: _store.products[PremiumStoreService.monthlyId]?.price ??
                    'Mağazada henüz yok',
                period: '/ ay',
                detail: 'Aylık ödeme',
                selected: !_yearlySelected,
                onTap: () => setState(() => _yearlySelected = false),
              ),
              const SizedBox(height: 18),
              FutureBuilder<bool>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final productId = _yearlySelected
                      ? PremiumStoreService.yearlyId
                      : PremiumStoreService.monthlyId;
                  final needsProfile =
                      snapshot.connectionState == ConnectionState.done &&
                          snapshot.data == false;
                  final needsSignIn = snapshot.data == true && !_store.signedIn;
                  final ready = snapshot.data == true &&
                      _store.signedIn &&
                      !_store.entitlement.active &&
                      _store.verificationAvailable &&
                      _store.storeAvailable &&
                      _store.products.containsKey(productId) &&
                      !_store.busy;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (needsProfile)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _store.entitlement.active
                                ? 'Premium özelliklerini kullanmak için çalışma bilgilerinizi girin.'
                                : 'Abone olmak için önce çalışma bilgilerinizi girin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppDesign.activeMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (needsSignIn)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Bilgileriniz hazır. Premium deneme veya abonelik için giriş yapın. Aboneliğinize yeniden kurulumdan sonra aynı hesapla erişebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppDesign.activeMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: needsProfile
                            ? _openProfile
                            : needsSignIn
                                ? _signInForTrial
                                : ready
                                    ? () => _store.buy(productId)
                                    : null,
                        icon: Icon(needsProfile
                            ? Icons.person_add_alt_1_outlined
                            : needsSignIn
                                ? Icons.login_rounded
                                : _store.busy
                                    ? Icons.hourglass_top_rounded
                                    : Icons.workspace_premium_rounded),
                        label: Text(needsProfile
                            ? 'Bilgilerimi gir'
                            : needsSignIn
                                ? 'Giriş yap / Kayıt ol'
                                : _store.busy
                                    ? 'İşlem sürüyor...'
                                    : _store.entitlement.active
                                        ? 'Aboneliğiniz aktif'
                                        : ready
                                            ? '${_store.storeName} ile abone ol'
                                            : !_store.signedIn
                                                ? 'Abonelik için giriş yapın'
                                                : 'Satın alma henüz hazır değil'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              TextButton.icon(
                onPressed: _store.verificationAvailable && !_store.busy
                    ? _store.restore
                    : null,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Satın almaları geri yükle'),
              ),
              if (_store.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_store.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12)),
                ),
              const SizedBox(height: 8),
              Text(
                'Fiyatlar ${_store.storeName} tarafından gösterilir. 7 günlük kartsız deneme sonunda otomatik ücret alınmaz; mağaza aboneliği ayrı bir seçimdir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppDesign.activeMuted, fontSize: 11, height: 1.35),
              ),
              if (_store.storeName == 'App Store') ...[
                const SizedBox(height: 8),
                Text(
                  'App Store aboneliği seçilen dönem sonunda otomatik yenilenir. Yenilemeyi Apple hesap ayarlarından iptal edebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppDesign.activeMuted, fontSize: 11, height: 1.35),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => launchUrl(_termsUrl,
                          mode: LaunchMode.externalApplication),
                      child: const Text('Kullanım koşulları'),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(_privacyUrl,
                          mode: LaunchMode.externalApplication),
                      child: const Text('Gizlilik politikası'),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(_manageUrl,
                          mode: LaunchMode.externalApplication),
                      child: const Text('Aboneliği yönet'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: TextStyle(
          color: AppDesign.activeInk,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _buildProfilePanel(BuildContext context) => FutureBuilder<bool>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final ready = snapshot.data == true;
          return AppSurface(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    ready
                        ? 'Çalışma bilgileriniz hazır'
                        : 'Kendi bilgilerinizle takip edin',
                    style: TextStyle(
                        color: AppDesign.activeInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                    ready
                        ? 'Kayıtlı bilgileriniz cihazınızda saklanır. Dilerseniz güncelleyebilirsiniz.'
                        : 'Kişisel takip için bilgilerinizi girin. Deneme süreniz bu aşamada başlamaz.',
                    style:
                        TextStyle(color: AppDesign.activeMuted, height: 1.4)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: snapshot.connectionState == ConnectionState.done
                      ? _openProfile
                      : null,
                  icon: Icon(ready
                      ? Icons.edit_outlined
                      : Icons.person_add_alt_1_outlined),
                  label:
                      Text(ready ? 'Bilgilerimi düzenle' : 'Bilgilerimi gir'),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildTrialPanel(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return FutureBuilder<bool>(
      future: _profileFuture,
      builder: (context, profileSnapshot) => FutureBuilder<PremiumTrialStatus>(
        future: _trialFuture,
        builder: (context, snapshot) {
          final profileReady = profileSnapshot.data == true;
          final status = snapshot.data;
          final loading = snapshot.connectionState != ConnectionState.done;
          final active = status?.phase == PremiumTrialPhase.active;
          final expired = status?.phase == PremiumTrialPhase.expired;
          final signedOut = status?.phase == PremiumTrialPhase.signedOut;
          final paid = _store.entitlement.active;
          final title = paid
              ? 'Premium aboneliğiniz aktif'
              : active
                  ? 'Deneme süreniz aktif'
                  : expired
                      ? 'Deneme süreniz sona erdi'
                      : '7 gün ücretsiz deneyin';
          final description = paid
              ? 'Aboneliğiniz Google Play üzerinden doğrulandı.'
              : active
                  ? '${status!.daysRemaining} gün kaldı · ${_dateText(status.endsAt!)} tarihinde biter.'
                  : expired
                      ? 'Deneme yalnızca bir kez kullanılabilir. Abonelik açıldığında plan seçebilirsiniz.'
                      : 'Kart gerekmez. Süre sonunda otomatik ücret alınmaz.';
          return AppSurface(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Icons.timer_outlined, color: primary, size: 23),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            color: AppDesign.activeInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 7),
                Text(description,
                    style:
                        TextStyle(color: AppDesign.activeMuted, height: 1.4)),
                if (loading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ] else if (snapshot.hasError && !paid) ...[
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: _reloadTrial,
                      child: const Text('Tekrar dene')),
                ] else if ((active || paid) && profileReady) ...[
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Çalışma hayatıma geç'),
                  ),
                ] else if (!active && !paid && !expired && profileReady) ...[
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _trialBusy
                        ? null
                        : signedOut
                            ? _signInForTrial
                            : _startTrial,
                    child: Text(signedOut
                        ? 'Denemek için giriş yap'
                        : _trialBusy
                            ? 'Başlatılıyor...'
                            : '7 günlük denemeyi başlat'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _dateText(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        Expanded(
          flex: 6,
          child: Text('ÖZELLİK',
              style: TextStyle(
                  color: AppDesign.activeMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5)),
        ),
        Expanded(
          flex: 3,
          child: Text('ÜCRETSİZ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppDesign.activeMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
        ),
        Expanded(
          flex: 3,
          child: Text('PREMIUM',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: primary, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String title;
  final bool free;

  const _ComparisonRow({
    required this.title,
    this.free = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Column(children: [
      Divider(height: 1, color: AppDesign.activeBorder),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(children: [
          Expanded(
            flex: 6,
            child: Text(title,
                style: TextStyle(
                    color: AppDesign.activeInk,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: Icon(
              free ? Icons.check_circle_rounded : Icons.remove_circle_outline,
              color: free ? const Color(0xFF16A34A) : AppDesign.activeMuted,
              size: 19,
              semanticLabel: free ? 'Var' : 'Yok',
            ),
          ),
          Expanded(
            flex: 3,
            child: Icon(Icons.check_circle_rounded,
                color: primary, size: 19, semanticLabel: 'Var'),
          ),
        ]),
      ),
    ]);
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String detail;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Material(
      color: AppDesign.activeSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: selected ? primary : AppDesign.activeBorder,
            width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? primary : AppDesign.activeMuted, size: 23),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: TextStyle(
                            color: AppDesign.activeInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(badge!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(detail,
                      style: TextStyle(
                          color: AppDesign.activeMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(price,
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              Text(period,
                  style: TextStyle(color: AppDesign.activeMuted, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }
}
