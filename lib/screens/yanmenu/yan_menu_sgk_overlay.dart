import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/sgk_sosyal_medya_wrap.dart';
import '../akisi/akisi_modelleri.dart';
import '../akisi/akisi_renkleri.dart';
import '../sgk_port/sgk_app_colors.dart';
import '../sgk_port/sgk_port_models.dart';
import 'hesabim_ekrani.dart';
import 'profil_duzenle_sgk_ekrani.dart';
import 'iletisim_ekrani.dart';
import 'sozlesme_ekrani.dart';
import 'kvkk_ekrani.dart';

/// sgk_app [TabNames] ile aynı kimlikler (yan menü satırları).
abstract class YanMenuSgkKimlik {
  static const String anaSayfa = 'home';
  static const String hesaplamalar = 'calc';
  static const String haklarim = 'my-rights';
  static const String topluluk = 'community';
  static const String davet = 'referral';
  static const String sonHesaplamalar = 'history';
  static const String oyunlastirma = 'trophy';
  static const String premium = 'premium';
  static const String hesabimAyarlar = 'settings';
}

/// sgk_app [_buildSideMenu] ile aynı düzen + uygulama ekleri (iletişim, KVKK, sosyal).
class YanMenuSgkEkrani extends StatefulWidget {
  final User? kullanici;
  final String appVersion;
  final List<String> adminUIDs;
  final String aktifMenuId;
  final void Function(VoidCallback action) onMenuItemTap;
  final void Function(String menuId) onSgkMenuSecildi;
  final void Function(String url) onLaunchURL;
  final VoidCallback onRateApp;
  final VoidCallback onShareApp;
  final VoidCallback onRefresh;

  const YanMenuSgkEkrani({
    super.key,
    required this.kullanici,
    required this.appVersion,
    required this.adminUIDs,
    this.aktifMenuId = YanMenuSgkKimlik.anaSayfa,
    required this.onMenuItemTap,
    required this.onSgkMenuSecildi,
    required this.onLaunchURL,
    required this.onRateApp,
    required this.onShareApp,
    required this.onRefresh,
  });

  @override
  State<YanMenuSgkEkrani> createState() => _YanMenuSgkEkraniState();
}

class _YanMenuSgkEkraniState extends State<YanMenuSgkEkrani> {
  String? _takmaAd;
  AkisiProfilTipi? _profilTipi;
  int _xp = 0;

  static const List<(String id, String baslik, IconData ikon)> _sgkOgeleleri = [
    (YanMenuSgkKimlik.anaSayfa, 'Ana Sayfa', Icons.home_rounded),
    (YanMenuSgkKimlik.hesaplamalar, 'Hesaplamalar Merkezi', Icons.calculate_rounded),
    (YanMenuSgkKimlik.haklarim, 'Haklarım', Icons.verified_user_rounded),
    (YanMenuSgkKimlik.topluluk, 'Topluluk', Icons.people_rounded),
    (YanMenuSgkKimlik.davet, 'Arkadaşını Davet Et', Icons.person_add_rounded),
    (YanMenuSgkKimlik.sonHesaplamalar, 'Son Hesaplamalarım', Icons.history_rounded),
    (YanMenuSgkKimlik.oyunlastirma, 'Oyunlaştırma', Icons.emoji_events_rounded),
    (YanMenuSgkKimlik.premium, 'Premium Üyelik', Icons.workspace_premium_rounded),
    (YanMenuSgkKimlik.hesabimAyarlar, 'Hesabım ve Ayarlar', Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _prefsOku();
  }

  Future<void> _prefsOku() async {
    final p = await SharedPreferences.getInstance();
    final ad = p.getString('akisi_takma_ad');
    final tipStr = p.getString('akisi_profil_tipi');
    final xpStr = p.getInt('yan_menu_xp');
    if (!mounted) return;
    setState(() {
      _takmaAd = ad;
      _profilTipi = akisiProfilTipiParse(tipStr);
      if (xpStr != null) _xp = xpStr;
    });
  }

  /// sgk yan menü: `profileType.name` (employee / employer / beginner).
  SgkProfileType _sgkProfilTipi() {
    switch (_profilTipi) {
      case AkisiProfilTipi.calisan:
        return SgkProfileType.employee;
      case AkisiProfilTipi.isveren:
        return SgkProfileType.employer;
      default:
        return SgkProfileType.beginner;
    }
  }

  /// sgk `_stats.levelName` ile aynı mantık (XP → seviye → AppLevels).
  String _seviyeAdiSgk() {
    final lv = (_xp / 500).floor() + 1;
    return SgkAppLevels.getLevelName(_sgkProfilTipi(), lv.clamp(1, 99));
  }

  void _kapatVe(String id) {
    Navigator.of(context).pop();
    widget.onSgkMenuSecildi(id);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final panelW = (mq.size.width * 0.85).clamp(0.0, 320.0);
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: ColoredBox(
          color: Colors.black54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: panelW,
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: darkMode ? SgkAppColors.slate900 : Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      initialData: widget.kullanici,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        final isAdminNow =
                            user != null && widget.adminUIDs.contains(user.uid);

                        return ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _ustLacivertBaslik(context, user),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Column(
                                children: [
                                  for (final o in _sgkOgeleleri)
                                    _sgkListeSatiri(
                                      darkMode: darkMode,
                                      baslik: o.$2,
                                      ikon: o.$3,
                                      aktif: widget.aktifMenuId == o.$1,
                                      onTap: () => _kapatVe(o.$1),
                                    ),
                                ],
                              ),
                            ),
                            Divider(
                                height: 1,
                                color: darkMode
                                    ? SgkAppColors.slate800
                                    : SgkAppColors.slate100),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Column(
                                children: [
                                  _sgkListeSatiri(
                                    darkMode: darkMode,
                                    baslik: 'İletişim',
                                    ikon: Icons.mail_outline_rounded,
                                    aktif: false,
                                    onTap: () => widget.onMenuItemTap(() {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => IletisimEkrani()),
                                      );
                                    }),
                                  ),
                                  _sgkListeSatiri(
                                    darkMode: darkMode,
                                    baslik: 'Uygulamayı Puanla',
                                    ikon: Icons.star_outline_rounded,
                                    aktif: false,
                                    onTap: () => widget.onMenuItemTap(() {
                                      Navigator.of(context).pop();
                                      widget.onRateApp();
                                    }),
                                  ),
                                  _sgkListeSatiri(
                                    darkMode: darkMode,
                                    baslik: 'Uygulamayı Paylaş',
                                    ikon: Icons.share_outlined,
                                    aktif: false,
                                    onTap: () => widget.onMenuItemTap(() {
                                      Navigator.of(context).pop();
                                      widget.onShareApp();
                                    }),
                                  ),
                                  _sgkListeSatiri(
                                    darkMode: darkMode,
                                    baslik: 'Sözleşmeler',
                                    ikon: Icons.description_outlined,
                                    aktif: false,
                                    onTap: () => widget.onMenuItemTap(() {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => SozlesmeEkrani()),
                                      );
                                    }),
                                  ),
                                  _sgkListeSatiri(
                                    darkMode: darkMode,
                                    baslik: 'KVKK',
                                    ikon: Icons.privacy_tip_outlined,
                                    aktif: false,
                                    onTap: () => widget.onMenuItemTap(() {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => KvkkEkrani()),
                                      );
                                    }),
                                  ),
                                  if (isAdminNow)
                                    _sgkListeSatiri(
                                      darkMode: darkMode,
                                      baslik: 'Gelen Mesajlar',
                                      ikon: Icons.message_outlined,
                                      aktif: false,
                                      onTap: () => widget.onMenuItemTap(() {
                                        Navigator.of(context).pop();
                                        Navigator.of(context)
                                            .pushNamed('/mesajlar');
                                      }),
                                    ),
                                ],
                              ),
                            ),
                            Divider(
                                height: 1,
                                color: darkMode
                                    ? SgkAppColors.slate800
                                    : SgkAppColors.slate100),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                              child: Text(
                                'Bizi Takip Edin',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AkisiRenkleri.slate400,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: SgkSosyalMedyaWrap(
                                temaRengi: Theme.of(context).primaryColor,
                                onUrlTap: widget.onLaunchURL,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 4),
                              child: Text(
                                'v${widget.appVersion}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AkisiRenkleri.slate400,
                                ),
                              ),
                            ),
                            if (user != null) ...[
                              Divider(
                                  height: 1,
                                  color: darkMode
                                      ? SgkAppColors.slate800
                                      : SgkAppColors.slate100),
                              ListTile(
                                leading: const Icon(Icons.logout_rounded,
                                    size: 22, color: Colors.red),
                                title: const Text(
                                  'Oturumu Kapat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                                onTap: () => widget.onMenuItemTap(() async {
                                  await FirebaseAuth.instance.signOut();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ustLacivertBaslik(BuildContext context, User? user) {
    final misafir = user == null;
    final ad = misafir
        ? (_takmaAd?.isNotEmpty == true ? _takmaAd! : 'Misafir')
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email ?? 'Kullanıcı'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 12),
      color: AkisiRenkleri.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: !misafir &&
                          user.photoURL != null &&
                          user.photoURL!.isNotEmpty
                      ? Image.network(
                          user.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _sgkProfilTipi().name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade200,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEVİYE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade200,
                      ),
                    ),
                    Text(
                      _seviyeAdiSgk(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'XP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade200,
                      ),
                    ),
                    Text(
                      '$_xp',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => widget.onMenuItemTap(() async {
                Navigator.of(context).pop();
                if (misafir) {
                  Navigator.of(context).pushNamed('/giris');
                } else {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfilDuzenleSgkEkrani(
                        onKaydedildi: widget.onRefresh,
                      ),
                    ),
                  );
                }
              }),
              icon: const Icon(Icons.person_rounded,
                  size: 16, color: Colors.white),
              label: const Text(
                'Profili Düzenle',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sgkListeSatiri({
    required bool darkMode,
    required String baslik,
    required IconData ikon,
    required bool aktif,
    required VoidCallback onTap,
  }) {
    final activeColor =
        darkMode ? SgkAppColors.blue400 : AkisiRenkleri.navy;
    final inactiveIcon =
        darkMode ? SgkAppColors.slate500 : SgkAppColors.slate400;
    final inactiveTitle =
        darkMode ? SgkAppColors.slate400 : SgkAppColors.slate600;
    final selectedBg = darkMode
        ? SgkAppColors.blue500.withOpacity(0.2)
        : AkisiRenkleri.navy.withOpacity(0.08);

    return ListTile(
      leading: Icon(
        ikon,
        size: 22,
        color: aktif ? activeColor : inactiveIcon,
      ),
      title: Text(
        baslik,
        style: TextStyle(
          fontSize: 14,
          fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
          color: aktif ? activeColor : inactiveTitle,
        ),
      ),
      trailing: aktif
          ? Icon(Icons.chevron_right_rounded, size: 20, color: activeColor)
          : null,
      selected: aktif,
      selectedTileColor: selectedBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
