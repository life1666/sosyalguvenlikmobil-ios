import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'yanmenu/sozlesme_ekrani.dart';
import 'yanmenu/kvkk_ekrani.dart';
import '../../cv/cv_olustur.dart';
import '../../emeklilik_takip/emeklilik_takip.dart';
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
  'emeklilik_takip': {'title': 'Emeklilik Takip', 'icon': Icons.track_changes_outlined},
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
  int _selectedIndex = -1;
  User? _kullanici;
  String _appVersion = 'Bilinmiyor';
  int _refreshKey = 0;
  bool _showDisclaimer = false;
  int _mesajSayisi = 0;
  StreamSubscription<QuerySnapshot>? _mesajStreamSubscription;
  List<Map<String, dynamic>> _sonKullanilanlar = [];
  bool _isPremium = false;
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
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() => _kullanici = user);
      _mesajSayisiniGuncelle();
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
    } else if (screen == 'emeklilik_takip') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EmeklilikTakipApp()));
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
          FeatureItem(
            title: 'Emeklilik Takip',
            subtitle: 'Emeklilik durumunu takip et',
            icon: Icons.track_changes_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'emeklilik_takip'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmeklilikTakipApp()),
              );
            },
          ),
        ],
      ),
      Category(
        title: 'Tazminatlar',
        description: 'Kıdem ve ihbar tazminatı işlemleri',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFFE53935),
        svgPath: 'assets/emeklilik.svg',
        items: [
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
            title: 'Mesai Takip',
            subtitle: 'Günlük mesai takibi',
            icon: Icons.access_time_outlined,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'mesai_takip'});
              Navigator.of(context).pushNamed('/mesai');
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
            title: 'İşsizlik Maaşı İşlemleri',
            subtitle: 'İşsizlik maaşı hesaplama ve başvuru',
            icon: Icons.work_outline,
            hasSubItems: true,
            subItems: [
              FeatureItem(
                title: 'İşsizlik Maaşı Hesaplama',
                icon: Icons.calculate_outlined,
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
                icon: Icons.description_outlined,
                onTap: () {
                  AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'issizlik_basvuru'});
                  launchUrl(Uri.parse('https://www.iskur.gov.tr/'), mode: LaunchMode.externalApplication);
                },
              ),
            ],
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
                MaterialPageRoute(builder: (_) => const MakalelerView()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          _buildBody(),

          // Modern Sorumluluk Reddi Popup
          if (_showDisclaimer) _buildDisclaimerOverlay(),
        ],
      ),
      bottomNavigationBar: _ModernBottomBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          if (index == 0) {
            _showModernMenu(context);
          } else if (index == 1) {
            AnalyticsHelper.logCustomEvent('all_features_tapped');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AllFeaturesScreen(categories: categories)),
            );
          } else if (index == 2) {
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

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // Modern AppBar
        SliverAppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          floating: true,
          snap: true,
          pinned: false,
          leading: IconButton(
            icon: _kullanici != null && _kullanici!.email != null && _kullanici!.email!.isNotEmpty
                ? CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: 14,
                    child: Text(
                      _kullanici!.email!.trim()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Icon(Icons.person_outline_rounded, color: const Color(0xFF64748B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HesabimEkrani()),
              ).then((_) {
                if (mounted) setState(() => _refreshKey++);
              });
            },
          ),
          title: Text(
            'İş & SGK Asistan',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          titleSpacing: 20,
          centerTitle: true,
          actions: [
          if (_kullanici != null)
            Stack(
                clipBehavior: Clip.none,
              children: [
                IconButton(
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: const Color(0xFF64748B),
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
                      constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                      ),
                      child: Text(
                          _mesajSayisi > 9 ? '9+' : '$_mesajSayisi',
                        style: TextStyle(
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
            SizedBox(width: 8),
          ],
        ),

        // Öne Çıkanlar (Firebase'den en çok kullanılan 3-4 özellik veya varsayılan)
        SliverToBoxAdapter(
          child: _ModernQuickAccess(
            items: _oneCikanlarItems ?? _defaultOneCikanlarItems(),
            onTap: _onQuickAccessTap,
          ),
        ),

        // Çalışma Hayatım
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                SizedBox(width: 12),
                Text(
                  'Çalışma Hayatım',
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
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: CalismaHayatimContent(key: ValueKey(_refreshKey)),
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

  // Modern Menu — tam ekran Ayarlar sayfası
  void _showModernMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AyarlarEkrani(
          kullanici: _kullanici,
          isAdmin: _isAdmin(_kullanici),
          isPremium: _isPremium,
          appVersion: _appVersion,
          onMenuItemTap: (action) => action(),
          onLaunchURL: _launchURL,
          onRateApp: _rateApp,
          onShareApp: _shareApp,
          onRefresh: () {
            if (mounted) setState(() => _refreshKey++);
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

// Modern Bottom Bar
class _ModernBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
          color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
              child: Row(
                children: [
            _NavItem(
              label: "Ayarlar",
              icon: Icons.menu_rounded,
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              label: "Tüm Özellikler",
              icon: Icons.apps_rounded,
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              label: "Son Hesaplamalar",
              icon: Icons.history_rounded,
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).primaryColor : const Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tam ekran Ayarlar sayfası
class _AyarlarEkrani extends StatelessWidget {
  final User? kullanici;
  final bool isAdmin;
  final bool isPremium;
  final String appVersion;
  final Function(VoidCallback) onMenuItemTap;
  final Function(String) onLaunchURL;
  final VoidCallback onRateApp;
  final VoidCallback onShareApp;
  final VoidCallback onRefresh;

  const _AyarlarEkrani({
    required this.kullanici,
    required this.isAdmin,
    required this.isPremium,
    required this.appVersion,
    required this.onMenuItemTap,
    required this.onLaunchURL,
    required this.onRateApp,
    required this.onShareApp,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium durumu kutusu
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _PremiumKutu(isPremium: isPremium),
            ),

            // Menu items
            if (kullanici == null)
            _MenuItem(
              icon: Icons.login_rounded,
              title: 'Giriş Yap / Kayıt Ol',
              onTap: () => onMenuItemTap(() {
                Navigator.of(context).pushNamed('/giris');
              }),
            )
          else
            _MenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Hesabım',
              onTap: () => onMenuItemTap(() {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => HesabimEkrani())).then((_) => onRefresh());
              }),
            ),

          _MenuItem(
            icon: Icons.mail_outline_rounded,
            title: 'İletişim',
            onTap: () => onMenuItemTap(() {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => IletisimEkrani()));
            }),
          ),

          _MenuItem(
            icon: Icons.star_outline_rounded,
            title: 'Uygulamayı Puanla',
            onTap: () => onMenuItemTap(onRateApp),
          ),

          _MenuItem(
            icon: Icons.share_outlined,
            title: 'Uygulamayı Paylaş',
            onTap: () => onMenuItemTap(onShareApp),
          ),

          _MenuItem(
            icon: Icons.description_outlined,
            title: 'Sözleşmeler',
            onTap: () => onMenuItemTap(() {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => SozlesmeEkrani()));
            }),
          ),

          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'KVKK',
            onTap: () => onMenuItemTap(() {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => KvkkEkrani()));
            }),
          ),

          if (isAdmin)
            _MenuItem(
              icon: Icons.message_outlined,
              title: 'Gelen Mesajlar',
              onTap: () => onMenuItemTap(() {
                Navigator.of(context).pushNamed('/mesajlar');
              }),
            ),

          if (kullanici != null)
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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Divider(color: const Color(0xFFE2E8F0)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      icon: FaIcon(FontAwesomeIcons.instagram, size: 20),
                      onTap: () => onLaunchURL('https://www.instagram.com/sosyalguvenlikmobil/?igsh=MW5sYjR1MWJlcWNidw%3D%3D&utm_source=qr#'),
                    ),
                    SizedBox(width: 12),
                    _SocialButton(
                      icon: FaIcon(FontAwesomeIcons.facebook, size: 20),
                      onTap: () => onLaunchURL('https://www.facebook.com/people/Sosyal-G%C3%BCvenlik-Mobil/61575847292304/'),
                    ),
                    SizedBox(width: 12),
                    _SocialButton(
                      icon: FaIcon(FontAwesomeIcons.linkedin, size: 20),
                      onTap: () => onLaunchURL('https://www.linkedin.com/in/sosyal-g%C3%BCvenlik-mobil-931b89361/?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=ios_app'),
                    ),
                    SizedBox(width: 12),
                    _SocialButton(
                      icon: FaIcon(FontAwesomeIcons.youtube, size: 20),
                      onTap: () => onLaunchURL('https://www.youtube.com/@sosyalguvenlikmobil'),
                    ),
                    SizedBox(width: 12),
                    _SocialButton(
                      icon: FaIcon(FontAwesomeIcons.xTwitter, size: 20),
                      onTap: () => onLaunchURL('https://x.com/sgmobil_?s=21'),
                    ),
                    SizedBox(width: 12),
                    _SocialButton(
                      icon: FaIcon(FontAwesomeIcons.tiktok, size: 20),
                      onTap: () => onLaunchURL('https://www.tiktok.com/@sosyalguvenlikmobil?_r=1&_t=ZS-92OAfxvb3Vh'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'v$appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }
}

class _PremiumKutu extends StatelessWidget {
  final bool isPremium;

  const _PremiumKutu({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPremium ? const Color(0xFF81C784) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPremium
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                  : const Color(0xFF94A3B8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined,
              color: isPremium ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPremium ? 'Premium Üye' : 'Premium Değilsiniz',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPremium ? const Color(0xFF1B5E20) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium
                      ? 'Tüm premium özelliklerden yararlanıyorsunuz.'
                      : 'Tüm özelliklere erişmek için Premium\'a geçin.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPremium ? const Color(0xFF388E3C) : const Color(0xFF64748B),
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? const Color(0xFF1E293B);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: const Color(0xFF64748B)),
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

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final List<Widget> allTiles = [];

    // Tüm kategorilerdeki özellikleri başlıksız, tek listede topla (Ayarlar menüsü ile aynı sade stil)
    for (final cat in categories) {
      for (final it in cat.items) {
        if (it.hasSubItems && it.subItems != null) {
          allTiles.add(_buildExpandableItem(
            context,
            it,
            themeColor,
            initiallyExpanded: it.title == initialExpandTitle,
          ));
        } else {
          allTiles.add(_buildFeatureTile(
            context: context,
            icon: it.icon,
            title: it.title,
            subtitle: it.subtitle,
            onTap: it.onTap ?? () {},
          ));
        }
      }
    }

    // Diğer Özellikler (sadece CV Oluştur)
    allTiles.add(_buildFeatureTile(
      context: context,
      icon: Icons.description_outlined,
      title: 'CV Oluştur',
      subtitle: 'Profesyonel CV şablonları',
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CvApp()));
      },
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Tüm Özellikler',
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: allTiles.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) => allTiles[i],
      ),
    );
  }

  /// Ayarlar menüsündeki _MenuItem ile aynı sade stil: ikon + başlık + chevron, kart yok.
  Widget _buildFeatureTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E293B), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableItem(
    BuildContext context,
    FeatureItem it,
    Color color, {
    bool initiallyExpanded = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        childrenPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
        iconColor: color,
        collapsedIconColor: color,
        leading: Icon(it.icon, size: 22, color: color),
        title: Text(
          it.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
        ),
        subtitle: it.subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(it.subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              )
            : null,
        children: (it.subItems ?? [])
            .map(
              (subItem) => _buildFeatureTile(
                context: context,
                icon: subItem.icon,
                title: subItem.title,
                onTap: subItem.onTap ?? () {},
              ),
            )
            .toList(),
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
