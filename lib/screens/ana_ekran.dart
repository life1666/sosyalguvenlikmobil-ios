import '../utils/app_design.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../makaleler/makale.dart';
import 'hesaplamalar_ekrani.dart';
import 'yanmenu/hesabim_ekrani.dart';
import 'yanmenu/calisma_bilgilerim.dart';
import 'yanmenu/iletisim_ekrani.dart';
import 'yanmenu/sozlesme_ekrani.dart';
import 'yanmenu/kvkk_ekrani.dart';
import 'yanmenu/tema_ayarlari.dart';
import '../../cv/cv_olustur.dart';
import '../../sozluk/sozluk.dart';
import '../../sonhesaplama/sonhesaplama.dart';
import '../../mevzuat/asgariucret.dart';
import '../../mevzuat/mevzuat.dart';
import '../../utils/analytics_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../hesaplamalar/4a_hesapla.dart';
import '../../hesaplamalar/4b_hesapla.dart';
import '../../hesaplamalar/4c_hesapla.dart';
import '../../hesaplamalar/emeklilik_hesaplama.dart';
import '../../hesaplamalar/askerlik_dogum.dart';
import '../../hesaplamalar/kidem_hesap.dart';
import '../../hesaplamalar/kidem_alabilir.dart';
import '../../hesaplamalar/issizlik_sorguhesap.dart';
import '../../hesaplamalar/rapor_parasi.dart';
import '../../hesaplamalar/brutten_nete.dart';
import '../../hesaplamalar/netten_brute.dart';
import '../../hesaplamalar/asgari_iscilik.dart';
import '../../hesaplamalar/yillik_izin.dart';
import 'calisma_hayatim.dart';
import 'calisma_araclari.dart';
import 'topluluk_ekrani.dart';
import 'premium_ekrani.dart';
import 'premium_feature_gate.dart';
import 'ilerleme_ekrani.dart';
import 'admin/topluluk_moderasyon_ekrani.dart';
import '../utils/progress_service.dart';
import '../services/community_in_app_notification_service.dart';
import '../services/premium_access_service.dart';
import '../services/personal_profile_store.dart';
import '../services/notification_service.dart';

// ==================== MODELS ====================
class FeatureItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool isFree;
  final bool hasSubItems;
  final List<FeatureItem>? subItems;
  const FeatureItem({
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.color,
    this.isFree = false,
    this.hasSubItems = false,
    this.subItems,
  });
}

class Category {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<FeatureItem> items;
  final String? svgPath;
  const Category({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.items,
    this.svgPath,
  });
}

// Öne Çıkanlar: Firebase'den en çok kullanılanları göstermek için feature id -> bilgi
const Map<String, Map<String, dynamic>> _kOneCikanlarFeatureInfo = {
  'emeklilik_4a': {
    'title': 'Emeklilik Hesaplama',
    'icon': Icons.calculate_outlined
  },
  'cv_olustur': {'title': 'CV Oluştur', 'icon': Icons.description_outlined},
  'kidem_ihbar': {
    'title': 'Kıdem Tazminatı Hesaplama',
    'icon': Icons.receipt_long_outlined
  },
  'issizlik': {'title': 'İşsizlik Maaşı Hesaplama', 'icon': Icons.work_outline},
  'borclanma': {
    'title': 'Borçlanma Hesaplama',
    'icon': Icons.account_balance_outlined
  },
  'rapor': {'title': 'Rapor Parası', 'icon': Icons.local_hospital_outlined},
  'brutten_nete': {'title': 'Brütten Nete', 'icon': Icons.swap_horiz_outlined},
  'netten_brute': {'title': 'Netten Brüte', 'icon': Icons.swap_horiz_outlined},
  'kidem_alabilir': {
    'title': 'Kıdem Alabilir mi?',
    'icon': Icons.check_circle_outline
  },
  'emeklilik_4b': {'title': '4/b Emeklilik', 'icon': Icons.calculate_outlined},
  'emeklilik_4c': {'title': '4/c Emeklilik', 'icon': Icons.calculate_outlined},
  'yillik_izin': {'title': 'Yıllık İzin', 'icon': Icons.beach_access_outlined},
  'asgari_ucret': {'title': 'Asgari Ücret', 'icon': Icons.paid_outlined},
};

List<Map<String, dynamic>> _defaultOneCikanlarItems() {
  return [
    {
      'title': 'Emeklilik Hesaplama',
      'screen': 'emeklilik_4a',
      'icon': Icons.calculate_outlined
    },
    {
      'title': 'İşsizlik Maaşı Hesaplama',
      'screen': 'issizlik',
      'icon': Icons.work_outline
    },
    {
      'title': 'Borçlanma Hesaplama',
      'screen': 'borclanma',
      'icon': Icons.account_balance_outlined
    },
    {
      'title': 'Kıdem Tazminatı Hesaplama',
      'screen': 'kidem_ihbar',
      'icon': Icons.receipt_long_outlined
    },
  ];
}

class AnaEkran extends StatefulWidget {
  @override
  _AnaEkranState createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _selectedIndex = -1;
  User? _kullanici;
  String _appVersion = 'Bilinmiyor';
  int _refreshKey = 0;
  bool _showDisclaimer = false;
  int _mesajSayisi = 0;
  StreamSubscription<QuerySnapshot>? _mesajStreamSubscription;
  StreamSubscription<User?>? _authSubscription;
  List<Map<String, dynamic>> _sonKullanilanlar = [];
  List<Map<String, dynamic>>? _oneCikanlarItems;

  final _firestore = FirebaseFirestore.instance;
  final _communityNotifications = CommunityInAppNotificationService();
  static const String _featureUsageCollection = 'feature_usage';
  final String adminUID = 'yicHOHSjaPXH6sLwyc48ulCnai32';
  final String mevzuatUzmaniUID = 'jBEoEbfgjJUHklmfmrJqsrIBETF2';

  static const String playStoreLink =
      'https://play.google.com/store/apps/details?id=com.sosyalguvenlik.mobil&pcampaignid=web_share';
  static const String appStoreLink =
      'https://apps.apple.com/us/app/sosyal-g%C3%BCvenlik-mobil/id6752835301';

  @override
  void initState() {
    super.initState();
    _kullanici = FirebaseAuth.instance.currentUser;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _kullanici = user;
        _refreshKey++;
      });
      _mesajSayisiniGuncelle();
      NotificationService.instance.syncFromStoredPreferences();
    });
    _loadAppVersion();
    _mesajSayisiniGuncelle();
    _sonKullanilanlariYukle();
    _checkAndRequestReview();
    _checkAndShowDisclaimer();
    _loadOneCikanlar();
    _communityNotifications.start((question) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('“${question.title}” sorunuza yeni yanıt geldi.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Görüntüle',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ToplulukSoruDetayEkrani(questionId: question.id),
          )),
        ),
      ));
    });
    AnalyticsHelper.logScreenOpen('ana_ekran_opened');
  }

  Future<void> _loadOneCikanlar() async {
    try {
      final snapshot = await _firestore
          .collection(_featureUsageCollection)
          .orderBy('count', descending: true)
          .limit(4)
          .get();
      if (!mounted) return;
      final list = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final info = _kOneCikanlarFeatureInfo[doc.id];
        if (info != null) {
          list.add({
            'title': info['title'],
            'screen': doc.id,
            'icon': info['icon'],
          });
        }
      }
      if (list.length >= 3) {
        setState(() => _oneCikanlarItems = list);
      } else {
        setState(() => _oneCikanlarItems = _defaultOneCikanlarItems());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Öne çıkanlar yükleme hatası: $e');
      if (mounted)
        setState(() => _oneCikanlarItems = _defaultOneCikanlarItems());
    }
  }

  Future<void> _incrementFeatureUsage(String featureId) async {
    try {
      await _firestore
          .collection(_featureUsageCollection)
          .doc(featureId)
          .set({'count': FieldValue.increment(1)}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('feature_usage increment hatası: $e');
    }
  }

  void _onQuickAccessTap(BuildContext context, String screen) {
    _incrementFeatureUsage(screen);
    AnalyticsHelper.logCustomEvent('quick_access_tapped',
        parameters: {'feature': screen});
    if (screen == 'emeklilik_4a') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EmeklilikHesaplamaBirlesik(),
        ),
      );
    } else if (screen == 'kidem_ihbar') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CompensationCalculatorScreen()));
    } else if (screen == 'issizlik') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const IsizlikMaasiScreen()));
    } else if (screen == 'rapor') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RaporParasiScreen()));
    } else if (screen == 'brutten_nete') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => SalaryCalculatorScreen()));
    } else if (screen == 'cv_olustur') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CvApp()));
    } else if (screen == 'netten_brute') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NettenBruteScreen()));
    } else if (screen == 'kidem_alabilir') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const KidemTazminatiScreen()));
    } else if (screen == 'emeklilik_4b') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const EmeklilikHesaplamaBirlesik(initialIndex: 1)));
    } else if (screen == 'emeklilik_4c') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const EmeklilikHesaplamaBirlesik(initialIndex: 2)));
    } else if (screen == 'yillik_izin') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const YillikUcretliIzinSayfasi()));
    } else if (screen == 'asgari_ucret') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AsgariUcretSayfasi()));
    } else if (screen == 'borclanma') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const BorclanmaHesaplamaScreen()));
    }
  }

  Future<void> _checkAndShowDisclaimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenDisclaimer = prefs.getBool('has_seen_disclaimer') ?? false;

      if (!hasSeenDisclaimer) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _showDisclaimer = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Sorumluluk reddi kontrol hatası: $e');
    }
  }

  Future<void> _checkAndRequestReview() async {
    if (!Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final launchCount = prefs.getInt('app_launch_count') ?? 0;
      final hasRequestedReview = prefs.getBool('has_requested_review') ?? false;

      await prefs.setInt('app_launch_count', launchCount + 1);

      if (launchCount + 1 >= 3 && !hasRequestedReview) {
        final hesaplamalar = await SonHesaplamalarDeposu.listele();

        if (hesaplamalar.isNotEmpty) {
          final InAppReview inAppReview = InAppReview.instance;

          if (await inAppReview.isAvailable()) {
            await Future.delayed(const Duration(seconds: 2));

            if (mounted) {
              await inAppReview.requestReview();
              await prefs.setBool('has_requested_review', true);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('In-app review hatası: $e');
    }
  }

  Future<void> _sonKullanilanlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('son_kullanilanlar') ?? '[]';
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      setState(() {
        _sonKullanilanlar =
            list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      setState(() {
        _sonKullanilanlar = [];
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _mesajStreamSubscription?.cancel();
    _communityNotifications.dispose();
    super.dispose();
  }

  bool _isAdmin(User? user) {
    if (user == null) return false;
    return user.uid == adminUID || user.uid == mevzuatUzmaniUID;
  }

  void _mesajSayisiniGuncelle() {
    _mesajStreamSubscription?.cancel();

    if (_kullanici == null) {
      setState(() => _mesajSayisi = 0);
      return;
    }

    if (_isAdmin(_kullanici)) {
      _mesajStreamSubscription = _firestore
          .collection('messages')
          .where('read', isEqualTo: false)
          .snapshots()
          .listen(
        (snapshot) {
          if (mounted) {
            setState(() {
              _mesajSayisi = snapshot.docs.length;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _mesajSayisi = 0;
            });
          }
        },
      );
    } else {
      _mesajStreamSubscription = _firestore
          .collection('messages')
          .where('userId', isEqualTo: _kullanici!.uid)
          .snapshots()
          .listen(
        (snapshot) {
          if (mounted) {
            int okunmamisCevap = 0;
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final response = data['response'] as String?;
              final responses = data['responses'] as List<dynamic>?;
              final read = data['read'] as bool? ?? false;

              if (!read &&
                  ((response != null && response.isNotEmpty) ||
                      (responses != null && responses.isNotEmpty))) {
                okunmamisCevap++;
              }
            }
            setState(() {
              _mesajSayisi = okunmamisCevap;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _mesajSayisi = 0;
            });
          }
        },
      );
    }
  }

  Future<void> _mesajlariOkunduIsaretle() async {
    if (_kullanici == null) return;

    setState(() {
      _mesajSayisi = 0;
    });

    try {
      final batch = _firestore.batch();

      if (_isAdmin(_kullanici)) {
        final snapshot = await _firestore
            .collection('messages')
            .where('read', isEqualTo: false)
            .get();

        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'read': true});
        }
      } else {
        final snapshot = await _firestore
            .collection('messages')
            .where('userId', isEqualTo: _kullanici!.uid)
            .get();

        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'read': true});
        }
      }

      await batch.commit();
      await Future.delayed(Duration(milliseconds: 2000));
      if (mounted) {
        _mesajSayisiniGuncelle();
      }
    } catch (e) {
      debugPrint('Mesaj okundu işaretleme hatası: $e');
    }
  }

  void _showMesajBildirimDialog() {
    AnalyticsHelper.logCustomEvent('notification_bell_tapped');

    if (_mesajSayisi == 0) {
      _showModernDialog(
        icon: Icons.notifications_outlined,
        iconColor: const Color(0xFFB0BEC5),
        title: 'Yeni bildirim yok',
        message: 'Henüz yeni mesaj veya cevap bulunmuyor.',
        actions: [
          _DialogAction(
            label: 'Tamam',
            onPressed: () {
              AnalyticsHelper.logCustomEvent('notification_dialog_closed');
              Navigator.pop(context);
            },
          ),
        ],
      );
      return;
    }

    final mesaj = _isAdmin(_kullanici)
        ? '$_mesajSayisi yeni mesajınız var'
        : '$_mesajSayisi mesajınıza cevap geldi';

    _showModernDialog(
      icon: Icons.mark_email_unread_outlined,
      iconColor: Theme.of(context).primaryColor,
      title: 'Yeni Mesaj',
      message: mesaj,
      actions: [
        _DialogAction(
          label: 'Kapat',
          isOutlined: true,
          onPressed: () {
            AnalyticsHelper.logCustomEvent('notification_dialog_closed');
            Navigator.pop(context);
          },
        ),
        _DialogAction(
          label: 'Mesajları Gör',
          onPressed: () {
            AnalyticsHelper.logCustomEvent('notification_dialog_view_messages');
            Navigator.pop(context);
            _mesajlariOkunduIsaretle();
            if (_isAdmin(_kullanici)) {
              Navigator.pushNamed(context, '/mesajlar');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => IletisimEkrani()),
              );
            }
          },
        ),
      ],
    );
  }

  void _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _launchURL(String url) async {
    try {
      Future<bool> _try(String u) async {
        try {
          final uri = Uri.tryParse(u);
          if (uri == null) return false;
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('_launchURL _try hatası: $e');
          return false;
        }
      }

      bool ok = await _try(url);
      if (!ok) ok = await _try(Uri.encodeFull(url));
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link açılamadı: $url')),
        );
      }
    } catch (e) {
      debugPrint('_launchURL hatası: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  Future<void> _rateApp() async {
    final url = Platform.isIOS ? appStoreLink : playStoreLink;
    await _launchURL(url);
  }

  List<Category> get categories {
    return [
      Category(
        title: 'Emeklilik&SGK',
        description: 'Emeklilik hesaplama ve SGK prim borçlanma işlemleri',
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF5E35B1),
        svgPath: 'assets/hesaplama.svg',
        items: [
          FeatureItem(
            title: 'Emeklilik Hesaplama',
            subtitle: 'Sigorta statünüzü seçin ve emeklilik hesabınızı yapın',
            icon: Icons.calculate_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'emeklilik_hesaplama'});
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EmeklilikHesaplamaBirlesik()),
              );
            },
          ),
          FeatureItem(
            title: 'Kıdem - İhbar Tazminatı Hesaplama',
            subtitle: 'Kıdem ve ihbar tazminatı hesaplama',
            icon: Icons.calculate_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'kidem_ihbar'});
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CompensationCalculatorScreen()),
              );
            },
          ),
          FeatureItem(
            title: 'SGK\'dan Kıdem Tazminatı Alabilir Yazısı Sorgulama',
            subtitle: 'Kıdem tazminatı sorgulama',
            icon: Icons.search_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'kidem_alabilir'});
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Theme(
                    data: Theme.of(context),
                    child: const KidemTazminatiScreen(),
                  ),
                ),
              );
            },
          ),
          FeatureItem(
            title: 'İşsizlik Maaşı Hesaplama',
            subtitle: 'İşsizlik maaşı hesaplama',
            icon: Icons.work_outline,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'issizlik'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IsizlikMaasiScreen()),
              );
            },
          ),
          FeatureItem(
            title: 'İşsizlik Maaşı Başvurusu',
            subtitle: 'İŞKUR başvuru sayfasına yönlendirir',
            icon: Icons.description_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'issizlik_basvuru'});
              launchUrl(Uri.parse('https://www.iskur.gov.tr/'),
                  mode: LaunchMode.externalApplication);
            },
          ),
          FeatureItem(
            title: 'SGK Prim Borçlanma Tutarı Hesaplama',
            subtitle: 'Askerlik, doğum ve yurt dışı borçlanma',
            icon: Icons.account_balance_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'borclanma'});
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BorclanmaHesaplamaScreen()),
              );
            },
          ),
          FeatureItem(
            title: 'Rapor Parası Hesaplama',
            subtitle: 'Rapor parası hesaplama',
            icon: Icons.local_hospital_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'rapor'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaporParasiScreen()),
              );
            },
          ),
          FeatureItem(
            title: 'Asgari İşçilik Hesaplama',
            subtitle: 'Asgari işçilik matrahı ve prim hesaplama',
            icon: Icons.handyman_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'asgari_iscilik'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HesaplamaSayfasi()),
              );
            },
          ),
        ],
      ),
      Category(
        title: 'Maaş&Mesai',
        description: 'Brüt-net maaş, mesai takip ve asgari ücret',
        icon: Icons.payments_outlined,
        color: const Color(0xFF43A047),
        svgPath: 'assets/maasmesai.svg',
        items: [
          FeatureItem(
            title: 'Brütten Nete Maaş Hesaplama',
            subtitle: 'Brüt maaştan net maaş hesaplama',
            icon: Icons.swap_horiz_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'brutten_nete'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalaryCalculatorScreen()),
              );
            },
          ),
          FeatureItem(
            title: 'Netten Brüte Maaş Hesaplama',
            subtitle: 'Net maaştan brüt maaş hesaplama',
            icon: Icons.swap_vert_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'netten_brute'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NettenBruteScreen()),
              );
            },
          ),
          FeatureItem(
            title: 'Asgari Ücret',
            subtitle: 'Güncel asgari ücret bilgileri',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'asgari_ucret'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AsgariUcretSayfasi()),
              );
            },
          ),
        ],
      ),
      Category(
        title: 'Ödenekler&Haklar',
        description: 'İşsizlik maaşı, rapor parası ve diğer ödenekler',
        icon: Icons.volunteer_activism_outlined,
        color: const Color(0xFFFB8C00),
        svgPath: 'assets/cv.svg',
        items: [
          FeatureItem(
            title: 'Yıllık İzin Süresi Hesaplama',
            subtitle: 'Yıllık ücretli izin süresi hesaplama',
            icon: Icons.beach_access_outlined,
            isFree: true,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'yillik_izin'});
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const YillikUcretliIzinSayfasi()),
              );
            },
          ),
        ],
      ),
      Category(
        title: 'Bilgi Merkezi',
        description: 'Mevzuat, sözlük, makaleler',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF8E24AA),
        svgPath: 'assets/makale.svg',
        items: [
          FeatureItem(
            title: 'Makaleler',
            subtitle: 'Uzman yazıları ve rehberler',
            icon: Icons.library_books_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'makaleler'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MakalelerView()),
              );
            },
          ),
          FeatureItem(
            title: 'Mevzuat',
            subtitle: 'Kanun ve yönetmelikler',
            icon: Icons.gavel_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'mevzuat'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MevzuatSayfasi()),
              );
            },
          ),
          FeatureItem(
            title: 'Sözlük',
            subtitle: 'Terimler ve açıklamalar',
            icon: Icons.menu_book_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped',
                  parameters: {'feature': 'sozluk'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SozlukHomePage()),
              );
            },
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppDesign.activeBackground,
      body: Stack(
        children: [
          Builder(builder: _buildBody),

          // Modern Sorumluluk Reddi Popup
          if (_showDisclaimer) _buildDisclaimerOverlay(),
        ],
      ),
      bottomNavigationBar: _ModernBottomBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          if (index == 0) {
            AnalyticsHelper.logCustomEvent('all_features_tapped');
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AllFeaturesScreen(categories: categories)),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HaklarimEkrani()),
            );
          } else if (index == 2) {
            AnalyticsHelper.logCustomEvent('community_opened');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ToplulukEkrani()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SonHesaplamalarEkrani()),
            );
          }

          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted) setState(() => _selectedIndex = -1);
          });
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // AppBar: indigo (primaryColor)
        SliverAppBar(
          backgroundColor: AppDesign.activeBackground,
          elevation: 0,
          floating: true,
          snap: true,
          pinned: false,
          expandedHeight: 56,
          toolbarHeight: 56,
          flexibleSpace: Container(
            color: AppDesign.activeBackground,
          ),
          leadingWidth: 58,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Center(
              child: IconButton(
                tooltip: 'Ayarlar',
                onPressed: () => _showModernMenu(context),
                style: IconButton.styleFrom(
                  foregroundColor: AppDesign.activeInk,
                  backgroundColor: AppDesign.activeSurface,
                  side: BorderSide(color: AppDesign.activeBorder),
                  minimumSize: const Size(42, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.tune_rounded, size: 22),
              ),
            ),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'İş & Sosyal Güvenlik Mobil',
              maxLines: 1,
              style: TextStyle(
                color: AppDesign.activeInk,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          titleSpacing: 8,
          centerTitle: false,
          actions: [
            if (_kullanici != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: AppDesign.activeInk,
                      size: 26,
                    ),
                    onPressed: _showMesajBildirimDialog,
                  ),
                  if (_mesajSayisi > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(_mesajSayisi > 9 ? 3 : 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _mesajSayisi > 9 ? '9+' : '$_mesajSayisi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            IconButton(
              icon: _kullanici != null &&
                      _kullanici!.email != null &&
                      _kullanici!.email!.isNotEmpty
                  ? CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: Text(
                        _kullanici!.email!.trim()[0].toUpperCase(),
                        style: TextStyle(
                          color: AppDesign.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.account_circle_rounded,
                      color: AppDesign.activeInk,
                      size: 32,
                    ),
              onPressed: () {
                if (_kullanici == null) {
                  Navigator.of(context).pushNamed('/giris').then((_) {
                    if (mounted) setState(() => _refreshKey++);
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HesabimEkrani()),
                  ).then((_) {
                    if (mounted) setState(() => _refreshKey++);
                  });
                }
              },
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: AppContent(
              child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 28 + MediaQuery.of(context).padding.bottom),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PersonalGreeting(
                    key: ValueKey('greeting_$_refreshKey'),
                    user: _kullanici,
                    onProgress: () {
                      if (_kullanici == null) {
                        Navigator.of(context).pushNamed('/giris').then((_) {
                          if (mounted) setState(() => _refreshKey++);
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const IlerlemeEkrani()),
                        ).then((_) {
                          if (mounted) setState(() => _refreshKey++);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(
                      child: Text('Çalışma hayatım',
                          style: TextStyle(
                              color: AppDesign.activeInk,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),
                    _ProfileEntryAction(
                      key: ValueKey('profile_entry_$_refreshKey'),
                      onPressed: () async {
                        final saved = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CalismaBilgilerim()));
                        if (!mounted) return;
                        setState(() => _refreshKey++);
                        if (saved != true) return;
                        bool hasAccess = false;
                        try {
                          hasAccess = (await PremiumAccessService().load())
                              .canUsePersonalFeatures;
                        } catch (_) {}
                        if (!mounted) return;
                        if (!hasAccess) {
                          await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                  builder: (_) => const PremiumEkrani()));
                          if (mounted) setState(() => _refreshKey++);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Çalışma bilgileriniz kaydedildi.')));
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 12),
                  PremiumFeatureGate(
                    key: ValueKey('premium_home_$_refreshKey'),
                    title: 'Çalışma hayatım',
                    embedded: true,
                    previewBuilder: (context, status, openPremium) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: _SampleDataNotice(),
                        ),
                        CalismaHayatimContent(
                          key: ValueKey('demo_$_refreshKey'),
                          demoMode: true,
                          onPremiumTap: openPremium,
                        ),
                      ],
                    ),
                    child: CalismaHayatimContent(key: ValueKey(_refreshKey)),
                  ),
                ]),
          )),
        ),
      ],
    );
  }

  // Modern Sorumluluk Reddi Overlay
  Widget _buildDisclaimerOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppDesign.activeSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst kısım - ikon ve başlık
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppDesign.activeSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Sorumluluk Reddi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppDesign.activeInk,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Bu uygulama, herhangi bir kamu kurumu, devlet dairesi veya resmi kuruluş tarafından geliştirilmemiştir. SGK, e-Devlet ya da Çalışma ve Sosyal Güvenlik Bakanlığı ile herhangi bir bağlantısı bulunmamaktadır.\n\nUygulama yalnızca bilgi sağlamak amacıyla hazırlanmıştır. Sunulan hesaplamalar resmi belge niteliği taşımaz. Bu nedenle herhangi bir sorumluluk kabul edilmez.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppDesign.activeMuted,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('has_seen_disclaimer', true);
                            setState(() {
                              _showDisclaimer = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Okudum, Anladım',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern Dialog Helper
  void _showModernDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required List<_DialogAction> actions,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppDesign.activeSurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppDesign.activeInk,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: AppDesign.activeMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) SizedBox(width: 12),
                    Expanded(
                      child: actions[i].isOutlined
                          ? OutlinedButton(
                              onPressed: actions[i].onPressed,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppDesign.activeBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                actions[i].label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppDesign.activeMuted,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: actions[i].onPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: Text(
                                actions[i].label,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Menu — tam ekran Ayarlar sayfası
  void _showModernMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AyarlarEkrani(
          kullanici: _kullanici,
          isAdmin: _isAdmin(_kullanici),
          appVersion: _appVersion,
          adminUIDs: [adminUID, mevzuatUzmaniUID],
          onMenuItemTap: (action) => action(),
          onLaunchURL: _launchURL,
          onRateApp: _rateApp,
          onShowDisclaimer: () {
            if (mounted) setState(() => _showDisclaimer = true);
          },
          onRefresh: () {
            if (mounted) setState(() => _refreshKey++);
          },
        ),
      ),
    );
  }
}

class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: AppDesign.isDark ? .15 : .07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: .24)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.visibility_outlined, color: primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ÖRNEK GÖRÜNÜM',
                  style: TextStyle(
                      color: primary,
                      fontSize: 10.5,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Aşağıdaki bilgiler size ait değildir.',
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                  'Kendi emeklilik, maaş ve hak takibiniz için Bilgilerimi gir’e dokunun.',
                  style: TextStyle(
                      color: AppDesign.activeMuted,
                      fontSize: 12,
                      height: 1.35)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ProfileEntryAction extends StatefulWidget {
  const _ProfileEntryAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ProfileEntryAction> createState() => _ProfileEntryActionState();
}

class _ProfileEntryActionState extends State<_ProfileEntryAction> {
  late final Future<bool> _hasProfile = PremiumAccessService().hasProfile();

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _hasProfile,
        builder: (context, snapshot) {
          if (snapshot.data != true) {
            return _AttentionProfileButton(onPressed: widget.onPressed);
          }
          return TextButton.icon(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Düzenle',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          );
        },
      );
}

class _AttentionProfileButton extends StatefulWidget {
  const _AttentionProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AttentionProfileButton> createState() =>
      _AttentionProfileButtonState();
}

class _AttentionProfileButtonState extends State<_AttentionProfileButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final emphasis = Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(
          scale: 1 + .025 * emphasis,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: .10 + .14 * emphasis),
                  blurRadius: 7 + 8 * emphasis,
                  spreadRadius: 1 + 2 * emphasis,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: FilledButton.icon(
        onPressed: widget.onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11)),
        ),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
        label: const Text('Bilgilerimi gir',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PersonalGreeting extends StatelessWidget {
  final User? user;
  final VoidCallback onProgress;

  const _PersonalGreeting({
    super.key,
    required this.user,
    required this.onProgress,
  });

  Future<_GreetingData> _load() async {
    if (user == null) {
      return const _GreetingData(
        firstName: null,
        status: 'Kendi çalışma hayatını takip etmek için giriş yap',
        icon: Icons.person_outline_rounded,
        color: Color(0xFF64748B),
        progress: 0,
      );
    }
    final progress = await ProgressService.load();
    final raw = await PersonalProfileStore().readRaw();
    Map<String, dynamic> profile = {};
    try {
      if (raw != null) {
        profile = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {}

    final profileName = '${profile['adSoyad'] ?? ''}'.trim();
    final accountName = user?.displayName?.trim() ?? '';
    final emailName = user?.email?.split('@').first.trim() ?? '';
    final fullName = profileName.isNotEmpty
        ? profileName
        : accountName.isNotEmpty
            ? accountName
            : emailName;
    final firstName =
        fullName.isEmpty ? null : fullName.split(RegExp(r'\s+')).first;

    final fields = <bool>[
      profile['dogumTarihi'] != null,
      '${profile['cinsiyet'] ?? ''}'.trim().isNotEmpty,
      '${profile['sigortaKolu'] ?? ''}'.trim().isNotEmpty,
      profile['ilkIseGirisTarihi'] != null,
      profile['toplamPrimGun'] != null,
      profile['mevcutIsyeriBaslangic'] != null,
      ((profile['guncelBrutMaas'] as num?)?.toDouble() ?? 0) > 0,
    ];
    final missing = fields.where((filled) => !filled).length;
    final savedAt = profile['kayitTarihi'] is int
        ? DateTime.fromMillisecondsSinceEpoch(profile['kayitTarihi'] as int)
        : null;
    final stale =
        savedAt != null && DateTime.now().difference(savedAt).inDays > 90;

    if (missing > 0) {
      return _GreetingData(
        firstName: firstName,
        status: 'Takibi tamamlamak için $missing bilgi eksik',
        icon: Icons.info_outline_rounded,
        color: const Color(0xFFF59E0B),
        progress: progress.score,
      );
    }
    if (stale) {
      return _GreetingData(
        firstName: firstName,
        status: 'Bilgilerinizi kontrol etme zamanı',
        icon: Icons.update_rounded,
        color: const Color(0xFFF59E0B),
        progress: progress.score,
      );
    }
    return _GreetingData(
      firstName: firstName,
      status: 'Bilgileriniz güncel',
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF16A34A),
      progress: progress.score,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_GreetingData>(
        future: _load(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) return const SizedBox(height: 70);
          final greeting = data.firstName == null
              ? 'Merhaba 👋'
              : 'Merhaba, ${data.firstName} 👋';
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppDesign.activeInk,
                        fontSize: 22,
                        letterSpacing: -.35,
                        fontWeight: FontWeight.w800)),
                if (user != null) ...[
                const SizedBox(height: 7),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onProgress,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 4),
                      child: Row(children: [
                        Icon(data.icon, size: 16, color: data.color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(data.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppDesign.activeMuted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 7),
                        if (user != null)
                          Text('%${data.progress}',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        Icon(Icons.chevron_right_rounded,
                            size: 17, color: Theme.of(context).primaryColor),
                      ]),
                    ),
                  ),
                ),
                ],
              ]);
        },
      );
}

class _GreetingData {
  final String? firstName;
  final String status;
  final IconData icon;
  final Color color;
  final int progress;

  const _GreetingData({
    required this.firstName,
    required this.status,
    required this.icon,
    required this.color,
    required this.progress,
  });
}

// Modern Quick Access Widget — Firebase'den en çok kullanılan 3-4 özellik veya varsayılan
class _ModernQuickAccess extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(BuildContext context, String screen) onTap;

  const _ModernQuickAccess({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Öne Çıkanlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                final screen = item['screen'] as String;

                return InkWell(
                  onTap: () => onTap(context, screen),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppDesign.activeSurface,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppDesign.activeBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppDesign.activeInk,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Bottom Bar
class _ModernBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _ModernBottomBar({required this.currentIndex, required this.onTap});
  @override
  Widget build(BuildContext context) => AppBottomMenu(
        selectedIndex: currentIndex,
        onTap: onTap,
        labels: const ['Hesapla', 'Haklarım', 'Topluluk', 'Geçmiş'],
        icons: const [
          Icons.grid_view_rounded,
          Icons.verified_user_rounded,
          Icons.groups_2_outlined,
          Icons.history_rounded
        ],
      );
}

// Tam ekran Ayarlar sayfası — auth state dinlenir, çıkış yapınca aynı ekranda güncellenir
class _AyarlarEkrani extends StatelessWidget {
  final User? kullanici;
  final bool isAdmin;
  final String appVersion;
  final List<String> adminUIDs;
  final Function(VoidCallback) onMenuItemTap;
  final Function(String) onLaunchURL;
  final VoidCallback onRateApp;
  final VoidCallback onShowDisclaimer;
  final VoidCallback onRefresh;

  const _AyarlarEkrani({
    required this.kullanici,
    required this.isAdmin,
    required this.appVersion,
    required this.adminUIDs,
    required this.onMenuItemTap,
    required this.onLaunchURL,
    required this.onRateApp,
    required this.onShowDisclaimer,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: AppDesign.activeBackground,
      appBar: AppDesign.appBar('Ayarlar'),
      body: SafeArea(
          child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: kullanici,
        builder: (context, snapshot) {
          final currentUser = snapshot.data;
          final isAdminNow =
              currentUser != null && adminUIDs.contains(currentUser.uid);
          return AppContent(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                _MenuItem(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Premium',
                  onTap: () => onMenuItemTap(() {
                    Navigator.of(context)
                        .push<bool>(MaterialPageRoute<bool>(
                      builder: (_) => const PremiumEkrani(),
                    ))
                        .then((activated) {
                      onRefresh();
                      if (activated == true && context.mounted) {
                        Navigator.of(context).maybePop();
                      }
                    });
                  }),
                ),
                if (currentUser == null)
                  _MenuItem(
                    icon: Icons.login_rounded,
                    title: 'Giriş Yap / Kayıt Ol',
                    onTap: () => onMenuItemTap(() {
                      Navigator.of(context).pushNamed('/giris');
                    }),
                  )
                else ...[
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Hesabım',
                    onTap: () => onMenuItemTap(() {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (_) => HesabimEkrani()))
                          .then((_) => onRefresh());
                    }),
                  ),
                ],
                _MenuItem(
                  icon: Icons.mail_outline_rounded,
                  title: 'İletişim',
                  onTap: () => onMenuItemTap(() {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => IletisimEkrani()));
                  }),
                ),
                _MenuItem(
                  icon: Icons.star_outline_rounded,
                  title: 'Uygulamayı Puanla',
                  onTap: () => onMenuItemTap(onRateApp),
                ),
                _MenuItem(
                  icon: Icons.description_outlined,
                  title: 'Sözleşmeler',
                  onTap: () => onMenuItemTap(() {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SozlesmeEkrani()));
                  }),
                ),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'KVKK',
                  onTap: () => onMenuItemTap(() {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => KvkkEkrani()));
                  }),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Sorumluluk Reddi',
                  onTap: () => onMenuItemTap(() {
                    Navigator.of(context).pop();
                    onShowDisclaimer();
                  }),
                ),
                if (isAdminNow)
                  _MenuItem(
                    icon: Icons.message_outlined,
                    title: 'Gelen Mesajlar',
                    onTap: () => onMenuItemTap(() {
                      Navigator.of(context).pushNamed('/mesajlar');
                    }),
                  ),
                if (isAdminNow)
                  _MenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Topluluk Yönetimi',
                    onTap: () => onMenuItemTap(() {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ToplulukModerasyonEkrani(),
                      ));
                    }),
                  ),
                _MenuItem(
                  icon: Icons.palette_outlined,
                  title: 'Tema Ayarları',
                  onTap: () => onMenuItemTap(() {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TemaAyarlariEkrani()));
                  }),
                ),
                if (currentUser != null)
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Çıkış Yap',
                    textColor: const Color(0xFFEF4444),
                    onTap: () => onMenuItemTap(() async {
                      await FirebaseAuth.instance.signOut();
                    }),
                  ),
                // Sosyal medya
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Divider(color: themeColor.withOpacity(0.25)),
                      SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SocialButton(
                            icon: FaIcon(FontAwesomeIcons.instagram, size: 20),
                            onTap: () => onLaunchURL(
                                'https://www.instagram.com/sosyalguvenlikmobil/?igsh=MW5sYjR1MWJlcWNidw%3D%3D&utm_source=qr#'),
                          ),
                          _SocialButton(
                            icon: FaIcon(FontAwesomeIcons.facebook, size: 20),
                            onTap: () => onLaunchURL(
                                'https://www.facebook.com/people/Sosyal-G%C3%BCvenlik-Mobil/61575847292304/'),
                          ),
                          _SocialButton(
                            icon: FaIcon(FontAwesomeIcons.linkedin, size: 20),
                            onTap: () => onLaunchURL(
                                'https://www.linkedin.com/in/sosyal-g%C3%BCvenlik-mobil-931b89361/?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=ios_app'),
                          ),
                          _SocialButton(
                            icon: FaIcon(FontAwesomeIcons.youtube, size: 20),
                            onTap: () => onLaunchURL(
                                'https://www.youtube.com/@sosyalguvenlikmobil'),
                          ),
                          _SocialButton(
                            icon: FaIcon(FontAwesomeIcons.xTwitter, size: 20),
                            onTap: () =>
                                onLaunchURL('https://x.com/sgmobil_?s=21'),
                          ),
                          _SocialButton(
                            icon: FaIcon(FontAwesomeIcons.tiktok, size: 20),
                            onTap: () => onLaunchURL(
                                'https://www.tiktok.com/@sosyalguvenlikmobil?_r=1&_t=ZS-92OAfxvb3Vh'),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'v$appVersion',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ]));
        },
      )),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  const _MenuItem(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.textColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppSurface(
            padding: EdgeInsets.zero,
            child: AppActionTile(
                title: title,
                icon: icon,
                onTap: onTap,
                foregroundColor: textColor)),
      );
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: themeColor),
            child: icon,
          ),
        ),
      ),
    );
  }
}

// Category Screen ve All Features Screen aynı kalabilir, sadece renkleri güncelleyelim
class CategoryScreen extends StatefulWidget {
  final Category category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar(widget.category.title),
        body: SafeArea(
            child: AppContent(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
              AppIntro(
                  eyebrow: 'ÖZELLİKLER',
                  title: widget.category.title,
                  description: widget.category.description,
                  icon: widget.category.icon),
              const SizedBox(height: 20),
              for (final item in widget.category.items)
                _FeatureMenuCard(item: item),
            ]))),
      );
}

class AllFeaturesScreen extends StatelessWidget {
  final List<Category> categories;
  final String? initialExpandTitle;
  const AllFeaturesScreen(
      {super.key, required this.categories, this.initialExpandTitle});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar('Hesapla'),
        body: SafeArea(
            child: AppContent(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
              for (final category in categories)
                for (final item in category.items)
                  _FeatureMenuCard(
                      item: item,
                      initiallyExpanded: item.title == initialExpandTitle),
              _FeatureMenuCard(
                  item: FeatureItem(
                      title: 'CV Oluştur',
                      subtitle: 'Profesyonel CV şablonları',
                      icon: Icons.description_outlined,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CvApp())))),
            ]))),
      );
}

class _FeatureMenuCard extends StatelessWidget {
  final FeatureItem item;
  final bool initiallyExpanded;
  const _FeatureMenuCard({required this.item, this.initiallyExpanded = false});
  @override
  Widget build(BuildContext context) => Theme(
      data: Theme.of(context).copyWith(primaryColor: _menuAccent(item.title)),
      child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
                color: AppDesign.activeSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppDesign.activeBorder)),
            child: item.hasSubItems && item.subItems != null
                ? Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey(item.title),
                      initiallyExpanded: initiallyExpanded,
                      tilePadding: const EdgeInsets.all(16),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      iconColor: AppDesign.activeInk,
                      collapsedIconColor: AppDesign.activeMuted,
                      leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(14)),
                          child: Icon(item.icon,
                              color: Theme.of(context).primaryColor, size: 23)),
                      title: Text(item.title,
                          style: TextStyle(
                              color: AppDesign.activeInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      subtitle: item.subtitle == null
                          ? null
                          : Text(item.subtitle!,
                              style: TextStyle(
                                  color: AppDesign.activeMuted,
                                  fontSize: 12,
                                  height: 1.4)),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppDesign.activeBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0;
                                  i < item.subItems!.length;
                                  i++) ...[
                                if (i > 0) const SizedBox(height: 8),
                                AppSubmenuTile(
                                  title: item.subItems![i].title,
                                  subtitle: item.subItems![i].subtitle,
                                  icon: item.subItems![i].icon,
                                  onTap: item.subItems![i].onTap ?? () {},
                                  badge: item.subItems![i].isFree
                                      ? 'Ücretsiz'
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ))
                : AppActionTile(
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    onTap: item.onTap ?? () {},
                    badge: item.isFree ? 'Ücretsiz' : null),
          )));
}

// Dialog Action Helper Class
class _DialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;

  _DialogAction({
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
  });
}

Color _menuAccent(String title) {
  final text = title.toLowerCase();
  if (text.contains('kıdem')) return const Color(0xFF169B55);
  if (text.contains('rapor') || text.contains('netten'))
    return const Color(0xFFE11D48);
  if (text.contains('izin')) return const Color(0xFF0284C7);
  if (text.contains('borç') || text.contains('brütten'))
    return const Color(0xFF4F46E5);
  if (text.contains('işçilik')) return const Color(0xFF475569);
  return const Color(0xFF2563EB);
}
