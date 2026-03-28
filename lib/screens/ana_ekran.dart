import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../makaleler/makale.dart';
import 'hesaplamalar_ekrani.dart';
import 'yanmenu/hesabim_ekrani.dart';
import 'yanmenu/iletisim_ekrani.dart';
import 'yanmenu/tema_ayarlari.dart';
import 'yanmenu/sozlesme_ekrani.dart';
import 'yanmenu/kvkk_ekrani.dart';
import 'yanmenu/yan_menu_sgk_overlay.dart';
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
import '../../hesaplamalar/4a_hesapla.dart' show EmeklilikHesaplama4aSayfasi;
import '../../hesaplamalar/4b_hesapla.dart' show EmeklilikHesaplama4bSayfasi;
import '../../hesaplamalar/4c_hesapla.dart' show EmeklilikHesaplamaSayfasi;
import '../../hesaplamalar/askerlik_dogum.dart' show BorclanmaHesaplamaScreen;
import '../../hesaplamalar/kidem_hesap.dart' show CompensationCalculatorScreen;
import '../../hesaplamalar/kidem_alabilir.dart' show KidemTazminatiScreen;
import '../../hesaplamalar/issizlik_sorguhesap.dart' show IsizlikMaasiScreen;
import '../../hesaplamalar/rapor_parasi.dart' show RaporParasiScreen;
import '../../hesaplamalar/brutten_nete.dart' show SalaryCalculatorScreen;
import '../../hesaplamalar/netten_brute.dart' show NettenBruteScreen;
import '../../hesaplamalar/asgari_iscilik.dart' show HesaplamaSayfasi;
import '../../hesaplamalar/yillik_izin.dart' show YillikUcretliIzinSayfasi;
import 'akisi/akisi_renkleri.dart';
import 'ana_menu_sgk.dart';
import 'ana_sayfa_sgk_icerik.dart';
import 'haklarim/haklarim_ekrani.dart';
import 'rozetler/rozetler_ekrani.dart';
import 'topluluk/topluluk_ekrani.dart';
import 'yanmenu/profil_duzenle_sgk_ekrani.dart';
import 'yanmenu/hesabim_ayarlar_sgk_ekrani.dart';

// ==================== MODELS ====================
class FeatureItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasSubItems;
  final List<FeatureItem>? subItems;
  const FeatureItem({
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.color,
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
  'emeklilik_4a': {'title': 'Emeklilik Hesaplama', 'icon': Icons.calculate_outlined},
  'cv_olustur': {'title': 'CV Oluştur', 'icon': Icons.description_outlined},
  'kidem_ihbar': {'title': 'Kıdem Tazminatı Hesaplama', 'icon': Icons.receipt_long_outlined},
  'issizlik': {'title': 'İşsizlik Maaşı Hesaplama', 'icon': Icons.work_outline},
  'borclanma': {'title': 'Borçlanma Hesaplama', 'icon': Icons.account_balance_outlined},
  'rapor': {'title': 'Rapor Parası', 'icon': Icons.local_hospital_outlined},
  'brutten_nete': {'title': 'Brütten Nete', 'icon': Icons.swap_horiz_outlined},
  'netten_brute': {'title': 'Netten Brüte', 'icon': Icons.swap_horiz_outlined},
  'kidem_alabilir': {'title': 'Kıdem Alabilir mi?', 'icon': Icons.check_circle_outline},
  'emeklilik_4b': {'title': '4/b Emeklilik', 'icon': Icons.calculate_outlined},
  'emeklilik_4c': {'title': '4/c Emeklilik', 'icon': Icons.calculate_outlined},
  'yillik_izin': {'title': 'Yıllık İzin', 'icon': Icons.beach_access_outlined},
  'asgari_ucret': {'title': 'Asgari Ücret', 'icon': Icons.paid_outlined},
};

List<Map<String, dynamic>> _defaultOneCikanlarItems() {
  return [
    {'title': 'Emeklilik Hesaplama', 'screen': 'emeklilik_4a', 'icon': Icons.calculate_outlined},
    {'title': 'İşsizlik Maaşı Hesaplama', 'screen': 'issizlik', 'icon': Icons.work_outline},
    {'title': 'Borçlanma Hesaplama', 'screen': 'borclanma', 'icon': Icons.account_balance_outlined},
    {'title': 'Kıdem Tazminatı Hesaplama', 'screen': 'kidem_ihbar', 'icon': Icons.receipt_long_outlined},
  ];
}

class AnaEkran extends StatefulWidget {
  @override
  _AnaEkranState createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  User? _kullanici;
  final ScrollController _anaScrollController = ScrollController();
  String _anaSelamAd = 'Kullanıcı';
  bool _anaIsverenProfili = false;
  String _anaIsletmeAdi = '';
  String _anaProfilAvatarUrl = '';
  String _appVersion = 'Bilinmiyor';
  int _refreshKey = 0;
  bool _showDisclaimer = false;
  int _mesajSayisi = 0;
  StreamSubscription<QuerySnapshot>? _mesajStreamSubscription;
  List<Map<String, dynamic>> _sonKullanilanlar = [];
  bool _isPremium = false;
  String _activeTab = 'home';
  Widget? _activeCalcWidget;
  List<Map<String, dynamic>>? _oneCikanlarItems;

  final _firestore = FirebaseFirestore.instance;
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
    _yukleAnaSayfaProfil();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() => _kullanici = user);
      _mesajSayisiniGuncelle();
      _yukleAnaSayfaProfil();
    });
    _loadAppVersion();
    _mesajSayisiniGuncelle();
    _sonKullanilanlariYukle();
    _checkAndRequestReview();
    _checkAndShowDisclaimer();
    _loadOneCikanlar();
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
      if (mounted) setState(() => _oneCikanlarItems = _defaultOneCikanlarItems());
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
    AnalyticsHelper.logCustomEvent('quick_access_tapped', parameters: {'feature': screen});
    if (screen == 'emeklilik_4a') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AllFeaturesScreen(
            categories: categories,
            initialExpandTitle: 'Emeklilik Hesaplama',
          ),
        ),
      );
    } else if (screen == 'kidem_ihbar') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CompensationCalculatorScreen()));
    } else if (screen == 'issizlik') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const IsizlikMaasiScreen()));
    } else if (screen == 'rapor') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RaporParasiScreen()));
    } else if (screen == 'brutten_nete') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SalaryCalculatorScreen()));
    } else if (screen == 'cv_olustur') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CvApp()));
    } else if (screen == 'netten_brute') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NettenBruteScreen()));
    } else if (screen == 'kidem_alabilir') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const KidemTazminatiScreen()));
    } else if (screen == 'emeklilik_4b') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EmeklilikHesaplama4bSayfasi()));
    } else if (screen == 'emeklilik_4c') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => EmeklilikHesaplamaSayfasi()));
    } else if (screen == 'yillik_izin') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const YillikUcretliIzinSayfasi()));
    } else if (screen == 'asgari_ucret') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AsgariUcretSayfasi()));
    } else if (screen == 'borclanma') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BorclanmaHesaplamaScreen()));
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
        _sonKullanilanlar = list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      setState(() {
        _sonKullanilanlar = [];
      });
    }
  }

  @override
  void dispose() {
    _anaScrollController.dispose();
    _mesajStreamSubscription?.cancel();
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
              
              if (!read && ((response != null && response.isNotEmpty) || (responses != null && responses.isNotEmpty))) {
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

  Future<void> _shareApp() async {
    final shareText = 'Çalışma hayatındaki herkesin cebinde olması gereken uygulamanın Android sürümünü: $playStoreLink, iOS sürümünü $appStoreLink linkinden indirebilirsiniz.';
    await Share.share(
      shareText,
      subject: 'Sosyal Güvenlik Mobil',
    );
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
            subtitle: '4/a, 4/b, 4/c emeklilik hesaplama seçenekleri',
            icon: Icons.calculate_outlined,
            hasSubItems: true,
            subItems: [
              FeatureItem(
                title: '4/a (SSK) Emeklilik Hesaplama',
                icon: Icons.calculate_outlined,
                onTap: () {
                  AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'emeklilik_4a'});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmeklilikHesaplama4aSayfasi()),
                  );
                },
              ),
              FeatureItem(
                title: '4/b (Bağ-kur) Emeklilik Hesaplama',
                icon: Icons.calculate_outlined,
                onTap: () {
                  AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'emeklilik_4b'});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmeklilikHesaplama4bSayfasi()),
                  );
                },
              ),
              FeatureItem(
                title: '4/c (Memur) Emeklilik Hesaplama',
                icon: Icons.calculate_outlined,
                onTap: () {
                  AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'emeklilik_4c'});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmeklilikHesaplamaSayfasi()),
                  );
                },
              ),
            ],
          ),
          FeatureItem(
            title: 'Kıdem - İhbar Tazminatı Hesaplama',
            subtitle: 'Kıdem ve ihbar tazminatı hesaplama',
            icon: Icons.calculate_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'kidem_ihbar'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompensationCalculatorScreen()),
              );
            },
          ),
          FeatureItem(
            title: 'SGK\'dan Kıdem Tazminatı Alabilir Yazısı Sorgulama',
            subtitle: 'Kıdem tazminatı sorgulama',
            icon: Icons.search_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'kidem_alabilir'});
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
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'issizlik'});
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
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'issizlik_basvuru'});
              launchUrl(Uri.parse('https://www.iskur.gov.tr/'), mode: LaunchMode.externalApplication);
            },
          ),
          FeatureItem(
            title: 'SGK Prim Borçlanma Tutarı Hesaplama',
            subtitle: 'Askerlik, doğum ve yurt dışı borçlanma',
            icon: Icons.account_balance_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'borclanma'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BorclanmaHesaplamaScreen()),
              );
            },
          ),
          FeatureItem(
            title: 'Rapor Parası Hesaplama',
            subtitle: 'Rapor parası hesaplama',
            icon: Icons.local_hospital_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'rapor'});
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
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'asgari_iscilik'});
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
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'brutten_nete'});
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
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'netten_brute'});
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
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'asgari_ucret'});
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
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'yillik_izin'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const YillikUcretliIzinSayfasi()),
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
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'makaleler'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MakalelerView()),
              );
            },
          ),
          FeatureItem(
            title: 'Mevzuat',
            subtitle: 'Kanun ve yönetmelikler',
            icon: Icons.gavel_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'mevzuat'});
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
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'sozluk'});
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

  Future<void> _yukleAnaSayfaProfil() async {
    final p = await SharedPreferences.getInstance();
    final takma = p.getString('akisi_takma_ad');
    final tip = p.getString('akisi_profil_tipi');
    final isletme = p.getString('akisi_isletme_adi');
    final avatarUrl = p.getString('yan_menu_avatar_url') ?? '';
    if (!mounted) return;
    final u = _kullanici;
    String ad;
    if (u?.displayName != null && u!.displayName!.trim().isNotEmpty) {
      ad = u.displayName!.trim();
    } else if (takma != null && takma.trim().isNotEmpty) {
      ad = takma.trim();
    } else if (u?.email != null && u!.email!.trim().isNotEmpty) {
      ad = u.email!.split('@').first;
    } else {
      ad = 'Kullanıcı';
    }
    setState(() {
      _anaSelamAd = ad;
      _anaIsverenProfili = tip == 'isveren';
      _anaIsletmeAdi = isletme?.trim() ?? '';
      _anaProfilAvatarUrl = avatarUrl.trim();
    });
  }

  void _sgkAnaSayfaHizliArac(bool isveren, int index) {
    if (isveren) {
      const basliklar = [
        'Çalışan Yönetimi',
        'Bordro Merkezi',
        'Yasal Takvim',
        'İşletme İstatistikleri',
      ];
      _yakindaSnackbar(basliklar[index]);
      return;
    }
    switch (index) {
      case 0:
        AnalyticsHelper.logCustomEvent('feature_tapped',
            parameters: {'feature': 'kidem_ihbar'});
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CompensationCalculatorScreen()),
        );
        break;
      case 1:
        AnalyticsHelper.logCustomEvent('feature_tapped',
            parameters: {'feature': 'emeklilik_4a'});
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const EmeklilikHesaplama4aSayfasi()),
        );
        break;
      case 2:
        AnalyticsHelper.logCustomEvent('feature_tapped',
            parameters: {'feature': 'kidem_ihbar_ihbar'});
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CompensationCalculatorScreen()),
        );
        break;
      case 3:
        AnalyticsHelper.logCustomEvent('feature_tapped',
            parameters: {'feature': 'rapor'});
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RaporParasiScreen()),
        );
        break;
      default:
        break;
    }
  }

  void _yakindaSnackbar(String baslik) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$baslik yakında eklenecek.')),
    );
  }

  Widget _sgkProfilAvatar() {
    if (_anaProfilAvatarUrl.isNotEmpty) {
      return Image.network(
        _anaProfilAvatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _sgkProfilAvatarFirebase(),
      );
    }
    return _sgkProfilAvatarFirebase();
  }

  Widget _sgkProfilAvatarFirebase() {
    final u = _kullanici;
    if (u != null &&
        u.photoURL != null &&
        u.photoURL!.trim().isNotEmpty) {
      return Image.network(
        u.photoURL!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _sgkProfilYedek(),
      );
    }
    return _sgkProfilYedek();
  }

  Widget _sgkProfilYedek() {
    final u = _kullanici;
    if (u != null &&
        u.email != null &&
        u.email!.trim().isNotEmpty) {
      return ColoredBox(
        color: Colors.white,
        child: Center(
          child: Text(
            u.email!.trim()[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return const ColoredBox(
      color: AkisiRenkleri.navy,
      child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
    );
  }

  Widget? _sgkBildirimSatiri() {
    if (_kullanici == null) return null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            Icons.notifications_none_rounded,
            color: AkisiRenkleri.slate600,
            size: 26,
          ),
          onPressed: _showMesajBildirimDialog,
        ),
        if (_mesajSayisi > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: EdgeInsets.all(_mesajSayisi > 9 ? 3 : 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkisiRenkleri.gray,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnaMenuSgkUstMenu(
                  title: 'İş & SGK Asistan',
                  onMenuTap: () => _showModernMenu(context),
                  onProfileTap: () {
                    if (_kullanici == null) {
                      Navigator.of(context).pushNamed('/giris').then((_) {
                        if (mounted) setState(() => _refreshKey++);
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilDuzenleSgkEkrani(
                            onKaydedildi: () {
                              if (mounted) {
                                setState(() => _refreshKey++);
                                _yukleAnaSayfaProfil();
                              }
                            },
                          ),
                        ),
                      ).then((_) {
                        if (mounted) {
                          setState(() => _refreshKey++);
                          _yukleAnaSayfaProfil();
                        }
                      });
                    }
                  },
                  profilAvatar: _sgkProfilAvatar(),
                  bildirimWidget: _sgkBildirimSatiri(),
                ),
                Expanded(
                  child: _activeTab == 'calcDetail' && _activeCalcWidget != null
                      ? _activeCalcWidget!
                      : _activeTab == 'calc'
                          ? _buildCalculatorPage()
                          : _activeTab == 'topluluk'
                              ? const ToplulukEkrani(inline: true)
                              : _activeTab == 'rozetler'
                                  ? const RozetlerEkrani(inline: true)
                                  : _buildBody(),
                ),
              ],
            ),
          ),
          if (_showDisclaimer) _buildDisclaimerOverlay(),
        ],
      ),
      bottomNavigationBar: AnaMenuSgkAltMenu(
        aktifTab: _activeTab == 'calcDetail' ? 'calc' : _activeTab,
        onAnaSayfa: () {
          if (_activeTab != 'home') {
            setState(() { _activeTab = 'home'; _activeCalcWidget = null; });
          } else if (_anaScrollController.hasClients) {
            _anaScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }
        },
        onHesapla: () {
          AnalyticsHelper.logCustomEvent('all_features_tapped');
          setState(() { _activeTab = 'calc'; _activeCalcWidget = null; });
        },
        onSohbet: () => _yakindaSnackbar('Hak AI sohbet'),
        onTopluluk: () => setState(() { _activeTab = 'topluluk'; _activeCalcWidget = null; }),
        onRozetler: () => setState(() { _activeTab = 'rozetler'; _activeCalcWidget = null; }),
      ),
    );
  }



  void _backToCalcList() {
    setState(() {
      _activeCalcWidget = null;
      _activeTab = 'calc';
    });
  }

  void _openCalculatorScreen(String type) {
    Widget? inlineScreen;

    switch (type) {
      case 'severance':
        inlineScreen = CompensationCalculatorScreen(inline: true, onBack: _backToCalcList);
        break;
      case 'retirement':
        _showRetirementPicker();
        return;
      case 'severanceEligibility':
        inlineScreen = KidemTazminatiScreen(inline: true, onBack: _backToCalcList);
        break;
      case 'unemployment':
        inlineScreen = IsizlikMaasiScreen(inline: true, onBack: _backToCalcList);
        break;
      case 'premiumDebt':
        inlineScreen = BorclanmaHesaplamaScreen(inline: true, onBack: _backToCalcList);
        break;
      case 'reportPay':
        inlineScreen = RaporParasiScreen(inline: true, onBack: _backToCalcList);
        break;
      case 'grossToNet':
        inlineScreen = SalaryCalculatorScreen(inline: true, onBack: _backToCalcList);
        break;
      case 'netToGross':
        inlineScreen = NettenBruteScreen(inline: true, onBack: _backToCalcList);
        break;
      case 'leaveDuration':
        inlineScreen = YillikUcretliIzinSayfasi(inline: true, onBack: _backToCalcList);
        break;
      case 'minLabor':
        inlineScreen = HesaplamaSayfasi(inline: true, onBack: _backToCalcList);
        break;
      case 'cvCreator':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CvApp()));
        return;
    }

    if (inlineScreen != null) {
      setState(() {
        _activeCalcWidget = inlineScreen;
        _activeTab = 'calcDetail';
      });
    }
  }

  void _showRetirementPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 220,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text('Sigorta Türü Seçiniz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.shield_rounded),
              title: const Text('4/a (SSK)'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _activeCalcWidget = EmeklilikHesaplama4aSayfasi(inline: true, onBack: _backToCalcList);
                  _activeTab = 'calcDetail';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.store_rounded),
              title: const Text('4/b (Bağ-Kur)'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _activeCalcWidget = EmeklilikHesaplama4bSayfasi(inline: true, onBack: _backToCalcList);
                  _activeTab = 'calcDetail';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_rounded),
              title: const Text('4/c (Emekli Sandığı)'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _activeCalcWidget = EmeklilikHesaplamaSayfasi(inline: true, onBack: _backToCalcList);
                  _activeTab = 'calcDetail';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorPage() {
    final calcs = AllFeaturesScreen._calculators;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Hesaplayıcılar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AkisiRenkleri.slate800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İhtiyacınız olan hesaplamayı seçin',
            style: TextStyle(
              fontSize: 14,
              color: AkisiRenkleri.slate600,
            ),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < calcs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            InkWell(
              onTap: () => _openCalculatorScreen(calcs[i].type),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AkisiRenkleri.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: calcs[i].iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(calcs[i].icon,
                          size: 24, color: calcs[i].iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        calcs[i].title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AkisiRenkleri.slate800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AkisiRenkleri.slate400,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      controller: _anaScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnaSayfaSgkIcerik(
              selamIsim: _anaSelamAd,
              isverenProfili: _anaIsverenProfili,
              isletmeAdi: _anaIsletmeAdi,
              calisanEksikVeri: false,
              isverenEksikVeri: false,
              seviyeAdi: 'Yeni Üye',
              xp: 0,
              level: 1,
              onDuzenle: () {
                if (_kullanici == null) {
                  Navigator.of(context).pushNamed('/giris').then((_) {
                    if (mounted) {
                      setState(() => _refreshKey++);
                      _yukleAnaSayfaProfil();
                    }
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilDuzenleSgkEkrani(
                        onKaydedildi: () {
                          if (mounted) {
                            setState(() => _refreshKey++);
                            _yukleAnaSayfaProfil();
                          }
                        },
                      ),
                    ),
                  ).then((_) {
                    if (mounted) {
                      setState(() => _refreshKey++);
                      _yukleAnaSayfaProfil();
                    }
                  });
                }
              },
              onBildirim: _showMesajBildirimDialog,
              onHizliArac: _sgkAnaSayfaHizliArac,
            ),
          ),
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
              color: Colors.white,
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
                          color: Colors.white,
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
                          color: const Color(0xFF1E293B),
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
                          color: const Color(0xFF64748B),
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
            color: Colors.white,
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
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
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
                            color: const Color(0xFFE2E8F0),
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
                            color: const Color(0xFF64748B),
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

  void _yanMenuSgkEylem(String id) {
    if (!mounted) return;
    switch (id) {
      case YanMenuSgkKimlik.anaSayfa:
        if (_anaScrollController.hasClients) {
          _anaScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
        break;
      case YanMenuSgkKimlik.hesaplamalar:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllFeaturesScreen(categories: categories),
          ),
        );
        break;
      case YanMenuSgkKimlik.haklarim:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HaklarimEkrani()),
        );
        break;
      case YanMenuSgkKimlik.topluluk:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ToplulukEkrani()),
        );
        break;
      case YanMenuSgkKimlik.davet:
        _shareApp();
        break;
      case YanMenuSgkKimlik.sonHesaplamalar:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SonHesaplamalarEkrani()),
        );
        break;
      case YanMenuSgkKimlik.oyunlastirma:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RozetlerEkrani()),
        );
        break;
      case YanMenuSgkKimlik.premium:
        _yakindaSnackbar('Premium üyelik');
        break;
      case YanMenuSgkKimlik.hesabimAyarlar:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HesabimAyarlarSgkEkrani(
              onProfilKaydi: () {
                if (mounted) {
                  setState(() => _refreshKey++);
                  _yukleAnaSayfaProfil();
                }
              },
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() => _refreshKey++);
            _yukleAnaSayfaProfil();
          }
        });
        break;
    }
  }

  // Yan menü (sgk_app tarzı panel)
  void _showModernMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YanMenuSgkEkrani(
          kullanici: _kullanici,
          appVersion: _appVersion,
          adminUIDs: [adminUID, mevzuatUzmaniUID],
          aktifMenuId: YanMenuSgkKimlik.anaSayfa,
          onMenuItemTap: (action) => action(),
          onSgkMenuSecildi: _yanMenuSgkEylem,
          onLaunchURL: _launchURL,
          onRateApp: _rateApp,
          onShareApp: _shareApp,
          onRefresh: () {
            if (mounted) {
              setState(() => _refreshKey++);
              _yukleAnaSayfaProfil();
            }
          },
        ),
      ),
    );
  }
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
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

// Category Screen ve All Features Screen aynı kalabilir, sadece renkleri güncelleyelim
class CategoryScreen extends StatefulWidget {
  final Category category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int? _openIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.category.title,
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
        ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: widget.category.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = widget.category.items[i];
          final isOpen = _openIndex == i;
          final itemColor = item.color ?? widget.category.color;
          
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: item.hasSubItems
                      ? () => setState(() => _openIndex = isOpen ? null : i)
                      : item.onTap,
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          child: Icon(item.icon, color: itemColor, size: 24),
                            ),
                        SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  color: const Color(0xFF1E293B),
                                  ),
                                ),
                                if (item.subtitle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.subtitle!,
                                      style: TextStyle(
                                        fontSize: 13,
                                      color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            item.hasSubItems
                              ? (isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded)
                              : Icons.chevron_right_rounded,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                if (item.hasSubItems && isOpen && item.subItems != null)
                  ...item.subItems!.map(
                    (subItem) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                        onTap: subItem.onTap,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                  color: itemColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                child: Icon(subItem.icon, size: 18, color: itemColor),
                                  ),
                              SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    subItem.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              Icon(Icons.chevron_right_rounded, size: 18, color: const Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AllFeaturesScreen extends StatelessWidget {
  final List<Category> categories;
  final String? initialExpandTitle;

  const AllFeaturesScreen({
    super.key,
    required this.categories,
    this.initialExpandTitle,
  });

  static const _calculators = <({
    String type,
    String title,
    IconData icon,
    Color iconColor,
    List<String> inputs,
    String buttonLabel,
  })>[
    (
      type: 'severance',
      title: 'Kıdem Tazminatı',
      icon: Icons.trending_up_rounded,
      iconColor: AkisiRenkleri.green,
      inputs: [
        'picker:İşten Çıkış Kodunuz:01 - Deneme süreli iş sözleşmesinin işverence feshi,02 - Deneme süreli iş sözleşmesinin işçi tarafından feshi,03 - Belirsiz süreli iş sözleşmesinin işçi tarafından feshi (İstifa),04 - Belirsiz süreli iş sözleşmesinin işveren tarafından haklı sebep bildirmeden feshi,05 - Belirli süreli iş sözleşmesinin sona ermesi,08 - Emeklilik (yaşlılık) veya toptan ödeme nedeniyle,09 - Malulen emeklilik nedeniyle,10 - Ölüm,11 - İş kazası sonucu ölüm,12 - Askerlik,13 - Kadının evlenmesi,14 - Emeklilik için yaş dışında diğer şartların tamamlanması,15 - Toplu işçi çıkarma,17 - İşyerinin kapanması,18 - İşin sona ermesi,22 - Diğer nedenler,25 - İşçi tarafından zorunlu nedenle fesih,26 - Disiplin kurulu kararı ile fesih,27 - İşveren tarafından zorunlu nedenle fesih,28 - İşveren tarafından sağlık nedeniyle fesih,29 - İşveren tarafından askerlik nedeniyle fesih,34 - İşyerinin devri',
        'date:İşe Giriş Tarihi',
        'date:İşten Çıkış Tarihi',
        'number:Son Ay Giydirilmiş Brüt Ücret',
      ],
      buttonLabel: 'Hesapla',
    ),
    (
      type: 'retirement',
      title: 'Emeklilik Hesaplama',
      icon: Icons.calendar_today_rounded,
      iconColor: AkisiRenkleri.navy,
      inputs: [
        'picker:Sigorta Türü:4/a (SSK),4/b (Bağ-kur),4/c (Emekli Sandığı)',
        'gender:Cinsiyetiniz',
        'date:Doğum Tarihiniz',
        'date:Sigorta Başlangıç Tarihiniz',
        'number:Prim Gün Sayınız',
      ],
      buttonLabel: 'Sorgula',
    ),
    (
      type: 'severanceEligibility',
      title: 'Kıdem Tazminatı Alabilir Sorgulama',
      icon: Icons.verified_rounded,
      iconColor: AkisiRenkleri.green,
      inputs: [
        'date:Sigorta Başlangıç Tarihi',
        'number:Prim Gün Sayısı',
        'number:Son İş Yerinde Çalışma Yılı',
      ],
      buttonLabel: 'Sorgula',
    ),
    (
      type: 'unemployment',
      title: 'İşsizlik Maaşı Hesaplama',
      icon: Icons.person_outline_rounded,
      iconColor: Color(0xFF4F46E5),
      inputs: [
        'picker:İşten Çıkış Kodunuz:04 - Belirsiz süreli fesih (işveren),05 - Belirli süreli sona erme,12 - Askerlik,15 - Toplu işçi çıkarma,17 - İşyerinin kapanması,18 - İşin sona ermesi,25 - Zorunlu nedenle fesih (işçi),27 - Zorunlu nedenle fesih (işveren)',
        'picker:Son 120 Gün Hizmet Akdi ile Çalıştınız mı?:Evet,Hayır',
        'picker:Son 3 Yıldaki Toplam Prim Gün Sayınız:600 gün,900 gün,1080 gün ve üzeri',
        'number:1. Ay Brüt Ücret',
        'number:2. Ay Brüt Ücret',
        'number:3. Ay Brüt Ücret',
        'number:4. Ay Brüt Ücret',
      ],
      buttonLabel: 'Hesapla',
    ),
    (
      type: 'premiumDebt',
      title: 'SGK Prim Borçlanması',
      icon: Icons.monetization_on_rounded,
      iconColor: Color(0xFF4F46E5),
      inputs: [
        'picker:Borçlanma Türü:Askerlik Borçlanması,Doğum Borçlanması,Yurt Dışı Borçlanması,Diğer Borçlanmalar',
        'number:Borçlanılacak Gün Sayısı',
      ],
      buttonLabel: 'Hesapla',
    ),
    (
      type: 'reportPay',
      title: 'Rapor Parası',
      icon: Icons.medical_services_rounded,
      iconColor: Color(0xFFE11D48),
      inputs: [
        'picker:Rapor Nedeni:Hastalık,İş Kazası,Doğum',
        'number:Yatarak Raporlu Gün Sayısı',
        'number:Ayaktan Raporlu Gün Sayısı',
        'number:1. Ay Brüt Ücret',
        'number:1. Ay Prim Gün Sayısı',
        'number:2. Ay Brüt Ücret',
        'number:2. Ay Prim Gün Sayısı',
        'number:3. Ay Brüt Ücret',
        'number:3. Ay Prim Gün Sayısı',
      ],
      buttonLabel: 'Hesapla',
    ),
    (
      type: 'grossToNet',
      title: 'Brütten Nete Maaş Hesaplama',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AkisiRenkleri.navy,
      inputs: [
        'picker:Yıl Seçiniz:2024,2025,2026',
        'picker:Çalışan Statüsü:Normal Çalışan,Emekli Çalışan',
        'picker:Teşvik Seçiniz:Teşviksiz,5746 AR-GE Teşviki,17103 Genç-Kadın Teşviki',
        'number:Brüt Ücret (TL)',
      ],
      buttonLabel: 'Hesapla',
    ),
    (
      type: 'netToGross',
      title: 'Netten Brüte Maaş Hesaplama',
      icon: Icons.bar_chart_rounded,
      iconColor: AkisiRenkleri.navy,
      inputs: [
        'picker:Yıl Seçiniz:2024,2025,2026',
        'picker:Çalışan Statüsü:Normal Çalışan,Emekli Çalışan',
        'picker:Teşvik Seçiniz:Teşviksiz,5746 AR-GE Teşviki,17103 Genç-Kadın Teşviki',
        'number:Net Ücret (TL)',
      ],
      buttonLabel: 'Hesapla',
    ),
    (
      type: 'leaveDuration',
      title: 'Yıllık İzin Süresi Hesaplama',
      icon: Icons.flight_takeoff_rounded,
      iconColor: AkisiRenkleri.blue500,
      inputs: [
        'date:İşe Başlangıç Tarihi',
        'picker:Sigorta Kolu:4/a (SSK),4/b (Bağ-kur),4/c (Emekli Sandığı)',
      ],
      buttonLabel: 'Hesapla',
    ),
    (
      type: 'minLabor',
      title: 'Asgari İşçilik Hesaplama',
      icon: Icons.engineering_rounded,
      iconColor: AkisiRenkleri.slate600,
      inputs: [
        'date:İnşaat Başlangıç Tarihi',
        'date:İnşaat Bitiş Tarihi',
        'picker:Sınıf:1. Sınıf,2. Sınıf,3. Sınıf,4. Sınıf',
        'picker:Grup:1. Grup,2. Grup,3. Grup',
        'picker:İnşaat Türü:Konut,Ticaret,Sanayi,Diğer',
        'number:İnşaat Alanı (m²)',
      ],
      buttonLabel: 'Hesapla',
    ),
    (
      type: 'cvCreator',
      title: 'CV Oluşturucu',
      icon: Icons.badge_rounded,
      iconColor: Color(0xFF059669),
      inputs: ['text:Ad Soyad', 'text:Meslek'],
      buttonLabel: 'Devam Et',
    ),
  ];

  static void _navigateToCalc(BuildContext context, String type) {
    Widget? screen;
    switch (type) {
      case 'severance':
        screen = const CompensationCalculatorScreen();
        break;
      case 'retirement':
        _showRetirementPickerStatic(context);
        return;
      case 'severanceEligibility':
        screen = const KidemTazminatiScreen();
        break;
      case 'unemployment':
        screen = const IsizlikMaasiScreen();
        break;
      case 'premiumDebt':
        screen = const BorclanmaHesaplamaScreen();
        break;
      case 'reportPay':
        screen = const RaporParasiScreen();
        break;
      case 'grossToNet':
        screen = SalaryCalculatorScreen();
        break;
      case 'netToGross':
        screen = const NettenBruteScreen();
        break;
      case 'leaveDuration':
        screen = const YillikUcretliIzinSayfasi();
        break;
      case 'minLabor':
        screen = const HesaplamaSayfasi();
        break;
      case 'cvCreator':
        screen = const CvApp();
        break;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  static void _showRetirementPickerStatic(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 220,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text('Sigorta Türü Seçiniz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.shield_rounded),
              title: const Text('4/a (SSK)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmeklilikHesaplama4aSayfasi()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.store_rounded),
              title: const Text('4/b (Bağ-Kur)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmeklilikHesaplama4bSayfasi()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_rounded),
              title: const Text('4/c (Emekli Sandığı)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EmeklilikHesaplamaSayfasi()));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkisiRenkleri.gray,
      appBar: AppBar(
        title: const Text(
          'Hesaplamalar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        titleSpacing: 16,
        centerTitle: false,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Hesaplayıcılar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AkisiRenkleri.slate800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'İhtiyacınız olan hesaplamayı seçin',
              style: TextStyle(
                fontSize: 14,
                color: AkisiRenkleri.slate600,
              ),
            ),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _calculators.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = _calculators[index];
                return InkWell(
                  onTap: () => _navigateToCalc(context, c.type),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AkisiRenkleri.slate100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.icon, size: 24, color: c.iconColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            c.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AkisiRenkleri.slate800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AkisiRenkleri.slate400,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
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

