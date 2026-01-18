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
import '../../arama/aramaekrani.dart';
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
import '../../hesaplamalar/yurtdisi_borclanma.dart';
import '../../hesaplamalar/kidem_hesap.dart';
import '../../hesaplamalar/kidem_alabilir.dart';
import '../../hesaplamalar/issizlik_sorguhesap.dart';
import '../../hesaplamalar/rapor_parasi.dart';
import '../../hesaplamalar/brutten_nete.dart';
import '../../hesaplamalar/netten_brute.dart';
import '../../hesaplamalar/askerlik_dogum.dart';
import '../../hesaplamalar/yurtdisi_borclanma.dart';
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

class AnaEkran extends StatefulWidget {
  @override
  _AnaEkranState createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _selectedIndex = 0;
  int _selectedTabIndex = 0; // 0 = Ana Ekran, 1 = Çalışma Hayatım
  User? _kullanici;
  String _appVersion = 'Bilinmiyor';

  // Banner kaldırıldı
  // final PageController _bannerController = PageController();
  // int _currentBanner = 0;
  int _mesajSayisi = 0;
  StreamSubscription<QuerySnapshot>? _mesajStreamSubscription;
  List<Map<String, dynamic>> _sonKullanilanlar = [];

  final _firestore = FirebaseFirestore.instance;
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
    AnalyticsHelper.logScreenOpen('ana_ekran_opened');
  }

  Future<void> _checkAndRequestReview() async {
    // Sadece Android için in-app review
    if (!Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final launchCount = prefs.getInt('app_launch_count') ?? 0;
      final hasRequestedReview = prefs.getBool('has_requested_review') ?? false;

      // Giriş sayısını artır
      await prefs.setInt('app_launch_count', launchCount + 1);

      // Kombine yaklaşım: 3. girişten sonra VE en az 1 hesaplama yapılmışsa
      if (launchCount + 1 >= 3 && !hasRequestedReview) {
        // Son hesaplamaları kontrol et
        final hesaplamalar = await SonHesaplamalarDeposu.listele();
        
        // En az 1 başarılı hesaplama yapılmışsa review iste
        if (hesaplamalar.isNotEmpty) {
          final InAppReview inAppReview = InAppReview.instance;
          
          if (await inAppReview.isAvailable()) {
            // Kısa bir gecikme sonrası göster (kullanıcı uygulamayı görsün)
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
      // Parse hatası varsa boş liste
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
      // Admin için: okunmamış mesaj sayısı
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
            debugPrint('Admin mesaj sayısı güncellendi: ${_mesajSayisi}');
          }
        },
        onError: (error) {
          debugPrint('Mesaj stream hatası: $error');
          if (mounted) {
            setState(() {
              _mesajSayisi = 0;
            });
          }
        },
      );
    } else {
      // Normal kullanıcı için: okunmamış cevap sayısı
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
            debugPrint('Kullanıcı okunmamış cevap sayısı güncellendi: ${_mesajSayisi}');
          }
        },
        onError: (error) {
          debugPrint('Mesaj stream hatası: $error');
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
      
      // Stream'in güncellenmesi için kısa bir gecikme
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Yeni bildirim yok',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Henüz yeni mesaj veya cevap bulunmuyor.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                AnalyticsHelper.logCustomEvent('notification_dialog_closed');
                Navigator.pop(context);
              },
              child: Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    final mesaj = _isAdmin(_kullanici)
        ? '$_mesajSayisi yeni mesajınız var'
        : '$_mesajSayisi mesajınıza cevap geldi';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active, size: 48, color: Colors.indigo),
            SizedBox(height: 16),
            Text(
              mesaj,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AnalyticsHelper.logCustomEvent('notification_dialog_closed');
              Navigator.pop(context);
            },
            child: Text('Kapat'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: Text('Mesajları Gör'),
          ),
        ],
      ),
    );
  }

  void _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = 'Version: ${packageInfo.version}+${packageInfo.buildNumber}';
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

  // Banner kaldırıldı - bu fonksiyon artık kullanılmıyor
  /*
  VoidCallback _buildBannerAction(BannerItem item) {
    // Başlıkta "CV Oluştur" geçiyorsa CV ekranına git
    if (item.title.contains('CV Oluştur') || item.title.contains('CV+')) {
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CvApp()),
        );
      };
    }

    // "Asgari Ücret" içeriyorsa Hesaplamalar ekranına git
    if (item.title.contains('Asgari Ücret')) {
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HesaplamalarEkrani()),
        );
      };
    }

    // "Hemen Hesapla" veya "Hesapla" ise Hesaplamalar ekranına git
    if (item.title.contains('Hemen Hesapla') || item.title.contains('Hesapla')) {
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HesaplamalarEkrani()),
        );
      };
    }

    // "Mesai Takip" içeriyorsa Mesai Takip ekranına git
    if (item.title.contains('Mesai Takip')) {
      return () {
        Navigator.of(context).pushNamed('/mesai');
      };
    }

    // "Emeklilik Takip" içeriyorsa Emeklilik Takip ekranına git
    if (item.title.contains('Emeklilik Takip')) {
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmeklilikTakipApp()),
        );
      };
    }

    // "İK+" içeriyorsa şimdilik snackbar göster
    if (item.title.contains('İK+')) {
      return () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İK+ sayfası yakında')),
        );
      };
    }

    // Diğer tüm banner’lar için varsayılan davranış
    return () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} yakında')),
      );
    };
  }
  */
  // ▲▲▲ EKLEME SONU ▲▲▲

  // --- Banner verileri kaldırıldı ---
  /*
  final List<BannerItem> bannerItems = const [
    BannerItem(
      title: "Yeni CV Oluştur özelliği geldi!",
      description: "Profesyonel CV’nizi sadece 2 dakikada oluşturun.",
      buttonText: "Hemen Dene",
      icon: Icons.description,
      color: Colors.indigo,
    ),
    BannerItem(
      title: "Yeni Mesai Takip özelliği geldi!",
      description: "Günlük mesai saatlerinizi takip edin ve hesaplayın.",
      buttonText: "Hemen Dene",
      icon: Icons.access_time,
      color: Colors.indigo,
    ),
    BannerItem(
      title: "Yeni Emeklilik Takip Özelliği!",
      description: "Emeklilik sürecinizi takip edin ve ilerlemenizi görün.",
      buttonText: "Hemen Dene",
      icon: Icons.track_changes,
      color: Colors.indigo,
    ),
    BannerItem(
      title: "Hesaplamalar Ekranı Güncellendi!",
      description: "Emeklilik, Kıdem, İhbar Tazminatı ile İş ve Sosyal Güvenlik hayatına dair tüm hesaplamalar burada.",
      buttonText: "Hemen Hesapla",
      icon: Icons.attach_money,
      color: Colors.indigo,
    ),
  ];
  */

  // Helper method for feature tiles in modal bottom sheet
  Widget _buildFeatureTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Kategorize edilmiş özellikler - YENİ YAPILANDIRMA
  List<Category> get categories {
    return [
      Category(
        title: 'Emeklilik&SGK',
        description: 'Emeklilik hesaplama ve SGK prim borçlanma işlemleri',
        icon: Icons.account_balance,
        color: Colors.indigo,
        svgPath: 'assets/hesaplama.svg',
        items: [
          // Emeklilik Hesaplama - alt butonları var
          FeatureItem(
            title: 'Emeklilik Hesaplama',
            subtitle: '4/a, 4/b, 4/c emeklilik hesaplama seçenekleri',
            icon: Icons.event,
            hasSubItems: true,
            subItems: [
              FeatureItem(
                title: '4/a (SSK) Emeklilik Hesaplama',
                icon: Icons.calculate,
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
                icon: Icons.calculate,
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
                icon: Icons.calculate,
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
          // SGK Prim Borçlanma Tutarı Hesaplama - alt butonları var
          FeatureItem(
            title: 'SGK Prim Borçlanma Tutarı Hesaplama',
            subtitle: 'Askerlik, doğum ve yurt dışı borçlanma',
            icon: Icons.account_balance,
            hasSubItems: true,
            subItems: [
              FeatureItem(
                title: 'Askerlik, Doğum ve Diğer Borçlanmaların Prim Tutarı Hesaplama',
                icon: Icons.calculate,
                onTap: () {
                  AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'borclanma'});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BorclanmaHesaplamaScreen()),
                  );
                },
              ),
              FeatureItem(
                title: 'Yurt Dışı Borçlanması Prim Tutarı Hesaplama',
                icon: Icons.calculate,
                onTap: () {
                  AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'yurtdisi_borclanma'});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const YurtDisiBorclanmaHesaplamaScreen()),
                  );
                },
              ),
            ],
          ),
          // Asgari İşçilik Hesaplama
          FeatureItem(
            title: 'Asgari İşçilik Hesaplama',
            subtitle: 'Asgari işçilik matrahı ve prim hesaplama',
            icon: Icons.handyman,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'asgari_iscilik'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HesaplamaSayfasi()),
              );
            },
          ),
          // Emeklilik Takip
          FeatureItem(
            title: 'Emeklilik Takip',
            subtitle: 'Emeklilik durumunu takip et',
            icon: Icons.track_changes,
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
        icon: Icons.receipt_long,
        color: Colors.red,
        svgPath: 'assets/emeklilik.svg',
        items: [
          // Kıdem - İhbar Tazminatı Hesaplama
          FeatureItem(
            title: 'Kıdem - İhbar Tazminatı Hesaplama',
            subtitle: 'Kıdem ve ihbar tazminatı hesaplama',
            icon: Icons.calculate,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'kidem_ihbar'});
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompensationCalculatorScreen()),
              );
            },
          ),
          // SGK'dan Kıdem Tazminatı Alabilir Yazısı Sorgulama
          FeatureItem(
            title: 'SGK\'dan Kıdem Tazminatı Alabilir Yazısı Sorgulama',
            subtitle: 'Kıdem tazminatı sorgulama',
            icon: Icons.search,
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
        icon: Icons.payments,
        color: Colors.green,
        svgPath: 'assets/maasmesai.svg',
        items: [
          FeatureItem(
            title: 'Brütten Nete Maaş Hesaplama',
            subtitle: 'Brüt maaştan net maaş hesaplama',
            icon: Icons.swap_horiz,
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
            icon: Icons.swap_vert,
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
            icon: Icons.access_time,
            onTap: () {
              AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'mesai_takip'});
              Navigator.of(context).pushNamed('/mesai');
            },
          ),
          FeatureItem(
            title: 'Asgari Ücret',
            subtitle: 'Güncel asgari ücret bilgileri',
            icon: Icons.account_balance_wallet,
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
        icon: Icons.volunteer_activism,
        color: Colors.orange,
        svgPath: 'assets/cv.svg',
        items: [
          // İşsizlik Maaşı İşlemleri - alt butonları var
          FeatureItem(
            title: 'İşsizlik Maaşı İşlemleri',
            subtitle: 'İşsizlik maaşı hesaplama ve başvuru',
            icon: Icons.work_off,
            hasSubItems: true,
            subItems: [
              FeatureItem(
                title: 'İşsizlik Maaşı Hesaplama',
                icon: Icons.calculate,
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
                icon: Icons.description,
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
            icon: Icons.local_hospital,
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
            icon: Icons.beach_access,
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
        icon: Icons.menu_book,
        color: Colors.purple,
        svgPath: 'assets/makale.svg',
        items: [
          FeatureItem(
            title: 'Makaleler',
            subtitle: 'Uzman yazıları ve rehberler',
            icon: Icons.library_books,
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
            icon: Icons.gavel,
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
            icon: Icons.menu_book,
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

  // Eski menuItems kaldırıldı - artık categories kullanılıyor

  @override
  Widget build(BuildContext context) {
    final colorPrimary = Theme.of(context).primaryColor;

    final themeColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sosyal Güvenlik Mobil',
          style: TextStyle(color: themeColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.account_circle_rounded, color: themeColor, size: 28),
          onPressed: () => _showFullScreenMenu(context),
        ),
        actions: [
          // Arama ikonu
          IconButton(
            icon: Icon(Icons.search_rounded, color: themeColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AramaEkrani(),
                ),
              );
            },
          ),
          // Bildirim ikonu
          if (_kullanici != null)
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: themeColor),
                  onPressed: _showMesajBildirimDialog,
                ),
                if (_mesajSayisi > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_mesajSayisi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),

      body: Column(
        children: [
          // Cupertino Segmented Control
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedTabIndex,
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTabIndex = value;
                    });
                  }
                },
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Ana Ekran'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Çalışma Hayatım'),
                  ),
                },
              ),
            ),
          ),
          // İçerik
          Expanded(
            child: _selectedTabIndex == 0
                ? CustomScrollView(
                    slivers: [
                      // Sık Kullanılanlar
                      SliverToBoxAdapter(
                        child: _SikKullanilanlar(),
                      ),

          // Hızlı İşlemler Başlığı
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Text(
                '⚡ Hızlı İşlemler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),

          // Ana 4 Kategori (2x2 Grid)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final top4 = categories.take(4).toList();
                  final category = top4[index];
                  return _CategoryCard(
                    category: category,
                    onTap: () {
                      AnalyticsHelper.logCustomEvent('category_tapped', parameters: {'category': category.title});
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryScreen(category: category),
                        ),
                      );
                    },
                  );
                },
                childCount: 4, // Sadece 4 ana kategori
              ),
            ),
          ),

          // Tüm Özellikler Butonu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    AnalyticsHelper.logCustomEvent('all_features_tapped');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllFeaturesScreen(categories: categories),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.apps, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tüm Özellikler',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Makaleler, Mevzuat, Sözlük ve daha fazlası',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 1500),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value * 3, 0),
                              child: Icon(Icons.chevron_right, color: Colors.white),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Son Hesaplamalar Başlığı
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Text(
                '🕐 Son Hesaplamalar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),

                      // Son Aktiviteler
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          child: _SonHesaplamalarBlock(categories: categories),
                        ),
                      ),
                    ],
                  )
                : const CalismaHayatimEkrani(),
          ),
        ],
      ),
    );
  }

  // Yan menü
  void _showFullScreenMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Yan Menü',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);

        final padTop = MediaQuery.of(ctx).padding.top;
        final headerH = padTop + kToolbarHeight;
        final indigo = Theme.of(context).primaryColor;

        final items = <_MenuAction>[
          if (_kullanici == null)
            _MenuAction(Icons.login, 'Giriş Yap / Kayıt Ol', () {
              Navigator.of(ctx).pushNamed('/giris');
            })
          else
            _MenuAction(Icons.person, 'Hesabım', () {
              Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => HesabimEkrani()));
            }),
          _MenuAction(Icons.mail_outline, 'İletişim', () {
            Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => IletisimEkrani()));
          }),
          _MenuAction(Icons.star_rate, 'Uygulamayı Puanla', () => _rateApp()),
          _MenuAction(Icons.share, 'Uygulamayı Paylaş', () => _shareApp()),
          _MenuAction(Icons.description, 'Sözleşmeler', () {
            Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => SozlesmeEkrani()));
          }),
          _MenuAction(Icons.privacy_tip, 'KVKK', () {
            Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => KvkkEkrani()));
          }),
          if (_isAdmin(_kullanici))
            _MenuAction(Icons.message, 'Gelen Mesajlar', () {
              Navigator.of(ctx).pushNamed('/mesajlar');
            }),
          if (_kullanici != null)
            _MenuAction(Icons.logout, 'Çıkış Yap', () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Oturum kapatıldı")),
                );
              }
            }),
        ];

        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(curved),
          child: Material(
            color: Colors.white,
            child: LayoutBuilder(
              builder: (ctx, cons) {
                final availableH = cons.maxHeight - headerH - 24;
                final rowCount = items.length + 2;
                final rowH = (availableH / rowCount).clamp(52.0, 68.0);

                return Column(
                  children: [
                    // ÜST BAR (ana ekran app bar stili ile uyumlu)
                    Container(
                        height: headerH,
                        width: double.infinity,
                      color: Colors.white,
                        padding: EdgeInsets.only(left: 8, right: 8, top: padTop),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                              icon: Icon(Icons.arrow_back_rounded, color: Theme.of(ctx).primaryColor),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          Text(
                              'Sosyal Güvenlik Mobil',
                            style: TextStyle(
                              color: Theme.of(ctx).primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                          ],
                      ),
                    ),
                    for (final a in items)
                      _menuButton(
                        context: ctx,
                        icon: a.icon,
                        title: a.title,
                        onTap: a.onTap,
                        height: rowH,
                      ),
                    SizedBox(
                      height: rowH,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _social(const FaIcon(FontAwesomeIcons.instagram, size: 24, color: Color(0xFFE1306C)), () {
                            _launchURL('https://www.instagram.com/sosyalguvenlikmobil/?igsh=MW5sYjR1MWJlcWNidw%3D%3D&utm_source=qr#');
                          }),
                          const SizedBox(width: 10),
                          _social(const FaIcon(FontAwesomeIcons.facebook, size: 24, color: Colors.blue), () {
                            _launchURL('https://www.facebook.com/people/Sosyal-G%C3%BCvenlik-Mobil/61575847292304/');
                          }),
                          const SizedBox(width: 10),
                          _social(const FaIcon(FontAwesomeIcons.linkedin, size: 24, color: Colors.blueAccent), () {
                            _launchURL('https://www.linkedin.com/in/sosyal-g%C3%BCvenlik-mobil-931b89361/?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=ios_app');
                          }),
                          const SizedBox(width: 10),
                          _social(const FaIcon(FontAwesomeIcons.youtube, size: 24, color: Colors.red), () {
                            _launchURL('https://www.youtube.com/@sosyalguvenlikmobil');
                          }),
                          const SizedBox(width: 10),
                          _social(const FaIcon(FontAwesomeIcons.xTwitter, size: 24, color: Colors.black), () {
                            _launchURL('https://x.com/sgmobil_?s=21');
                          }),
                          const SizedBox(width: 10),
                          _social(const FaIcon(FontAwesomeIcons.tiktok, size: 24, color: Color(0xFF000000)), () {
                            _launchURL('https://www.tiktok.com/@sosyalguvenlikmobil?_r=1&_t=ZS-92OAfxvb3Vh');
                          }),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: rowH,
                      child: Center(
                        child: Text(
                          _appVersion,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required double height,
    required BuildContext context,
  }) {
    final themeColor = Theme.of(context).primaryColor;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: Colors.white,
          elevation: 1,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: themeColor.withOpacity(.08),
            highlightColor: themeColor.withOpacity(.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, color: themeColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _social(Widget icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: icon),
      ),
    );
  }
}


// class _QuickActions extends StatelessWidget {
//   final void Function(String) onTap;
//   const _QuickActions({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final actions = <String, IconData>{
//       'Hesapla': Icons.calculate_rounded,
//       'Alarmlar': Icons.alarm_rounded,
//       'Takip Listem': Icons.bookmark_border_rounded,
//       'Paylaş': Icons.share_rounded,
//     };

//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: actions.entries.map((e) {
//           return Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: ActionChip(
//               avatar: Icon(e.value, size: 18),
//               label: Text(e.key),
//               onPressed: () => onTap(e.key),
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// Kategori kartı - gradient ve shadow ile (ikon sol üstte)
class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = (category.svgPath != null)
        ? SvgPicture.asset(
            category.svgPath!,
            width: 42,
            height: 42,
            fit: BoxFit.contain,
            allowDrawingOutsideViewBox: true,
            errorBuilder: (ctx, err, stack) {
              debugPrint('SVG HATASI (${category.svgPath}): $err');
              return Icon(category.icon, size: 42, color: category.color);
            },
          )
        : Icon(category.icon, color: category.color, size: 42);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.color.withOpacity(0.08),
              category.color.withOpacity(0.04),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: category.color.withOpacity(.12),
          highlightColor: category.color.withOpacity(.06),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İkon sol üstte
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: iconWidget),
                ),
                const SizedBox(height: 12),
                // Başlık açıklamanın üzerinde
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // Açıklama alt kısımda
                Text(
                  category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Kategori ekranı - kategori içindeki özellikleri gösterir (genişletilebilir)
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
      appBar: AppBar(
        title: Text(
          widget.category.title,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        centerTitle: false, // Başlık sola hizalı (geri okunun yanında)
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.category.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = widget.category.items[i];
          final isOpen = _openIndex == i;
          
          final itemColor = item.color ?? widget.category.color;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  itemColor.withOpacity(0.08),
                  itemColor.withOpacity(0.04),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: itemColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: item.hasSubItems
                        ? () {
                            setState(() {
                              _openIndex = isOpen ? null : i;
                            });
                          }
                        : item.onTap ??
                            () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('"${item.title}" (yakında)')),
                                ),
                    splashColor: itemColor.withOpacity(0.12),
                    highlightColor: itemColor.withOpacity(0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: itemColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              color: itemColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (item.subtitle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.subtitle!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            item.hasSubItems
                                ? (isOpen ? Icons.expand_less : Icons.expand_more)
                                : Icons.chevron_right,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (item.hasSubItems && isOpen && item.subItems != null)
                  ...item.subItems!.map(
                    (subItem) => Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: subItem.onTap ??
                              () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('"${subItem.title}" (yakında)')),
                                  ),
                          splashColor: itemColor.withOpacity(0.08),
                          highlightColor: itemColor.withOpacity(0.04),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: itemColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    subItem.icon,
                                    size: 18,
                                    color: itemColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    subItem.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
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

// Tüm özellikler ekranı - ExpansionTile ile (önceki modern tasarım)
class AllFeaturesScreen extends StatelessWidget {
  final List<Category> categories;
  const AllFeaturesScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tüm Özellikler',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 56,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length + 1, // +1 for "Diğer Özellikler"
        itemBuilder: (context, i) {
          // Son item "Diğer Özellikler" bölümü - ExpansionTile olarak
          if (i == categories.length) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.teal.withOpacity(0.08),
                    Colors.teal.withOpacity(0.04),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ExpansionTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.more_horiz, color: Colors.teal, size: 24),
                ),
                title: Text(
                  'Diğer Özellikler',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Emeklilik Takip, CV Oluştur ve diğer araçlar',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                children: [
                  // Emeklilik Takip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'emeklilik_takip'});
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmeklilikTakipApp()),
                          );
                        },
                        splashColor: Colors.teal.withOpacity(0.08),
                        highlightColor: Colors.teal.withOpacity(0.04),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.track_changes,
                                  color: Colors.teal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emeklilik Takip',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Emeklilik durumunu takip et',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // CV Oluştur
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          AnalyticsHelper.logCustomEvent('feature_tapped', parameters: {'feature': 'cv_olustur'});
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CvApp()),
                          );
                        },
                        splashColor: Colors.teal.withOpacity(0.08),
                        highlightColor: Colors.teal.withOpacity(0.04),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.description,
                                  color: Colors.teal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CV Oluştur',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Profesyonel CV şablonları',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          final cat = categories[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cat.color.withOpacity(0.08),
                  cat.color.withOpacity(0.04),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: cat.color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 24),
              ),
              title: Text(
                cat.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  cat.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              children: cat.items
                  .map(
                    (it) {
                      final itemColor = it.color ?? cat.color;
                      if (it.hasSubItems && it.subItems != null) {
                        // Alt öğeleri olan item için ExpansionTile
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: itemColor.withOpacity(0.05),
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: itemColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(it.icon, size: 18, color: itemColor),
                            ),
                            title: Text(
                              it.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: it.subtitle != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      it.subtitle!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  )
                                : null,
                            children: it.subItems!
                                .map(
                                  (subItem) => Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: subItem.onTap ??
                                            () => ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('"${subItem.title}" (yakında)')),
                                                ),
                                        splashColor: itemColor.withOpacity(0.08),
                                        highlightColor: itemColor.withOpacity(0.04),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: itemColor.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  subItem.icon,
                                                  size: 16,
                                                  color: itemColor,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  subItem.title,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 16,
                                                color: Colors.grey[400],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      } else {
                        // Normal item
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: it.onTap ??
                                  () => ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('"${it.title}" (yakında)')),
                                      ),
                              splashColor: itemColor.withOpacity(0.08),
                              highlightColor: itemColor.withOpacity(0.04),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: itemColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        it.icon,
                                        color: itemColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            it.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (it.subtitle != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                it.subtitle!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _SonHesaplamalarBlock extends StatefulWidget {
  final List<Category> categories;
  const _SonHesaplamalarBlock({Key? key, required this.categories}) : super(key: key);

  @override
  State<_SonHesaplamalarBlock> createState() => _SonHesaplamalarBlockState();
}

class _SonHesaplamalarBlockState extends State<_SonHesaplamalarBlock> {
  List<SonHesaplama> _hesaplamalar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final liste = await SonHesaplamalarDeposu.listele();
    if (mounted) {
      setState(() {
        _hesaplamalar = liste.take(5).toList(); // En fazla 5 göster
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _hesaplamalar.isNotEmpty;

    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SonHesaplamalarEkrani(),
            ),
          ).then((_) => _yukle()); // Geri dönünce yenile
        },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
          child: _yukleniyor
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.indigo,
                    ),
                  ),
                )
              : hasData
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık kaldırıldı - artık üstte ayrı başlık var
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 4),
                        ..._hesaplamalar.map(
                          (hesaplama) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                                Icon(
                                  Icons.calculate_rounded,
                                  size: 18,
                                  color: Colors.indigo.withOpacity(0.7),
                                ),
                    const SizedBox(width: 8),
                    Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hesaplama.hesaplamaTuru,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                                      if (hesaplama.sonuclar.isNotEmpty)
                                        Text(
                                          hesaplama.sonuclar.entries.first.value,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                    ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.black45,
                                  size: 18,
                                ),
                  ],
                ),
              ),
            ),
          ],
        )
            : Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 120,
                color: Colors.indigo.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'Henüz Hesaplama Yok',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'İlk hesaplamanızı yapın ve burada görün!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  AnalyticsHelper.logCustomEvent('all_features_tapped');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllFeaturesScreen(categories: widget.categories),
                    ),
                  );
                },
                icon: Icon(Icons.calculate_rounded),
                label: Text('Hemen Hesapla'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
                    ),
        ),
      ),
    );
  }
}

// Sık Kullanılanlar Widget
class _SikKullanilanlar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final popularItems = [
      {'title': 'Emeklilik Hesaplama', 'route': 'emeklilik', 'screen': 'emeklilik_4a', 'icon': Icons.calculate_rounded},
      {'title': 'Emeklilik Takip', 'route': 'emeklilik_takip', 'screen': 'emeklilik_takip', 'icon': Icons.track_changes_rounded},
      {'title': 'CV Oluştur', 'route': 'cv_olustur', 'screen': 'cv_olustur', 'icon': Icons.description_rounded},
      {'title': 'Kıdem İhbar Tazminatı', 'route': 'kidem', 'screen': 'kidem_ihbar', 'icon': Icons.receipt_long_rounded},
      {'title': 'İşsizlik Maaşı', 'route': 'issizlik', 'screen': 'issizlik', 'icon': Icons.work_outline_rounded},
      {'title': 'Rapor Parası', 'route': 'rapor', 'screen': 'rapor', 'icon': Icons.local_hospital_rounded},
      {'title': 'Brütten Nete', 'route': 'brutten_nete', 'screen': 'brutten_nete', 'icon': Icons.swap_horiz_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⭐ Öne Çıkanlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: Stack(
              children: [
                ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: popularItems.length,
                  separatorBuilder: (_, __) => SizedBox(width: 10),
                  itemBuilder: (context, i) {
                final item = popularItems[i];
                final icon = item['icon'] as IconData? ?? Icons.star_rounded;
                final themeColor = Theme.of(context).primaryColor;
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    final screen = item['screen'] as String;
                    AnalyticsHelper.logCustomEvent('quick_access_tapped', parameters: {
                      'feature': item['route'] as String,
                    });
                    
                    // Her hesaplama için doğru ekrana yönlendir
                    if (screen == 'emeklilik_4a') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmeklilikHesaplama4aSayfasi()),
                      );
                    } else if (screen == 'kidem_ihbar') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CompensationCalculatorScreen()),
                      );
                    } else if (screen == 'issizlik') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IsizlikMaasiScreen()),
                      );
                    } else if (screen == 'rapor') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaporParasiScreen()),
                      );
                    } else if (screen == 'brutten_nete') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalaryCalculatorScreen()),
                      );
                    } else if (screen == 'cv_olustur') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CvApp()),
                      );
                    } else if (screen == 'emeklilik_takip') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmeklilikTakipApp()),
                      );
                    } else {
                      // Fallback: Hesaplamalar ekranına git
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HesaplamalarEkrani()),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeColor.withOpacity(0.12),
                          themeColor.withOpacity(0.06),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.08),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: themeColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                  },
                ),
                // Sağda fade gradient efekti (scroll göstergesi)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.8),
                          Colors.white,
                        ],
                      ),
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

// Banner kaldırıldı - gerekirse geri açılabilir (BannerCard ve BannerItem class'ları yorum içinde)

// Model class'ları - bunlar aktif kalmalı
class BannerItem {
  final String title;
  final String description;
  final String buttonText;
  final IconData icon;
  final Color color;

  const BannerItem({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.icon,
    required this.color,
  });
}

class MenuItemData {
  final String title;
  final IconData? icon;
  final Color color;
  final String? desc;
  final String? svgPath;
  MenuItemData(this.title, this.icon, this.color, {this.desc, this.svgPath});
}

class _MenuAction {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  _MenuAction(this.icon, this.title, this.onTap);
}
