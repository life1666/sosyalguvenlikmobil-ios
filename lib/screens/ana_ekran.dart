import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'dart:async';


class AnaEkran extends StatefulWidget {
  @override
  _AnaEkranState createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _selectedIndex = 0;
  User? _kullanici;
  String _appVersion = 'Bilinmiyor';

  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  int _mesajSayisi = 0;
  StreamSubscription<QuerySnapshot>? _mesajStreamSubscription;

  final _firestore = FirebaseFirestore.instance;
  final String adminUID = 'yicHOHSjaPXH6sLwyc48ulCnai32';
  final String mevzuatUzmaniUID = 'jBEoEbfgjJUHklmfmrJqsrIBETF2';

  static const String playStoreLink =
      'https://play.google.com/store/apps/details?id=com.sosyalguvenlik.mobil';

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
    AnalyticsHelper.logScreenOpen('ana_ekran_opened');
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
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _mesajSayisi = snapshot.docs.length;
          });
        }
      });
    } else {
      // Normal kullanıcı için: okunmamış cevap sayısı
      _mesajStreamSubscription = _firestore
          .collection('messages')
          .where('userId', isEqualTo: _kullanici!.uid)
          .snapshots()
          .listen((snapshot) {
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
      });
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
    Future<bool> _try(String u) async {
      final uri = Uri.tryParse(u);
      if (uri == null) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    bool ok = await _try(url);
    if (!ok) ok = await _try(Uri.encodeFull(url));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link açılamadı: $url')),
      );
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Uygulamayı indir: $playStoreLink',
      subject: 'Sosyal Güvenlik Mobil',
    );
  }

  Future<void> _rateApp() async => _launchURL(playStoreLink);

  // Banner butonlarına tıklayınca ne olacak?
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
  // ▲▲▲ EKLEME SONU ▲▲▲

  // --- Banner verileri (değişmedi) ---
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

  // Ana menü kartları – Makaleler ve Asgari Ücret için SVG eklendi
  final List<MenuItemData> menuItems = [
    MenuItemData("Hesaplamalar", Icons.calculate, Colors.indigo,
        desc: "Emeklilik, Kıdem ve İhbar tazminat", svgPath: 'assets/hesaplama.svg'),
    MenuItemData("Emeklilik Takip", Icons.track_changes, Colors.indigo,
        desc: "Anlık emeklilik takibi", svgPath: 'assets/emeklilik.svg'),
    MenuItemData("Mesai Takip", Icons.access_time, Colors.green,
        desc: "Günlük mesailerini takip et", svgPath: 'assets/maasmesai.svg'),
    MenuItemData("CV Oluştur", Icons.description, Colors.orange,
        desc: "Hazır Cv şablonları", svgPath: 'assets/cv.svg'),
    MenuItemData("İK+", Icons.people_alt, Colors.blue,
        desc: "İnsan kaynakları araçları", svgPath: 'assets/ik.svg'),
    MenuItemData("Makaleler", Icons.library_books, Colors.purple,
        desc: "Uzman yazıları", svgPath: 'assets/makale.svg'),
    MenuItemData("Mevzuat", Icons.gavel, Colors.red,
        desc: "Kanun & yönetmelik", svgPath: 'assets/mevzuat.svg'),
    MenuItemData("Sözlük", Icons.menu_book, Colors.teal,
        desc: "Terimler", svgPath: 'assets/sozluk.svg'),
    MenuItemData("Asgari Ücret", Icons.account_balance_wallet, Colors.brown,
        desc: "Güncel veriler", svgPath: 'assets/asgari.svg'),
    MenuItemData("Hatırlatıcılar", Icons.alarm, Colors.indigo,
        desc: "Tarih uyarıları", svgPath: 'assets/hatirlatma.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorPrimary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sosyal Güvenlik Mobil',
          style: TextStyle(color: Colors.indigo),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.indigo),
          onPressed: () => _showFullScreenMenu(context),
        ),
        actions: [
          if (_kullanici != null)
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: Colors.indigo),
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

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchBar(),
                  // const SizedBox(height: 10),
                  // _QuickActions(
                  //   onTap: (label) {
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       SnackBar(content: Text('$label yakında eklenecek')),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ),

          // Banner
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: bannerItems.length,
                onPageChanged: (i) => setState(() => _currentBanner = i),
                itemBuilder: (context, index) {
                  final item = bannerItems[index];
                  final onPressed = _buildBannerAction(item); // ← aksiyonu üret

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      children: [
                        BannerCard(
                          item: item,
                          onPressed: onPressed, // ← butona ver
                        ),
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              bannerItems.length,
                                  (dotIndex) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentBanner == dotIndex ? 10 : 8,
                                height: _currentBanner == dotIndex ? 10 : 8,
                                decoration: BoxDecoration(
                                  color: _currentBanner == dotIndex
                                      ? item.color
                                      : Colors.grey.shade400,
                                  shape: BoxShape.circle,
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
            ),
          ),

          // Kart Grid

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.35,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = menuItems[index];
                  return _HomeCard(
                    title: item.title,
                    subtitle: item.desc,
                    icon: item.icon,
                    svgPath: item.svgPath,
                    color: item.color,
                    onTap: () {
                      if (item.title == "Hesaplamalar") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HesaplamalarEkrani()),
                        );
                      } else if (item.title == "Makaleler") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MakalelerView()),
                        );
                      } else if (item.title == "Mesai Takip") {
                        Navigator.of(context).pushNamed('/mesai');

                      } else if (item.title == "CV Oluştur") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CvApp()),
                        );

                      } else if (item.title == "Emeklilik Takip") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmeklilikTakipApp()),
                        );

                      } else if (item.title == "Sözlük") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SozlukHomePage()),
                        );
                      } else if (item.title == "Asgari Ücret") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AsgariUcretSayfasi()),
                        );
                      } else if (item.title == "Mevzuat") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MevzuatSayfasi()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.title} ekranı yakında eklenecek')),
                        );
                      }
                    },
                  );
                },
                childCount: menuItems.length,
              ),
            ),
          ),

          // Son Aktiviteler
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              child: _SonHesaplamalarBlock(),
            ),
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
          if (_kullanici?.uid == 'yicHOHSjaPXH6sLwyc48ulCnai32')
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
                              icon: const Icon(Icons.close_rounded, color: Colors.indigo),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          const Text(
                              'Sosyal Güvenlik Mobil',
                            style: TextStyle(
                              color: Colors.indigo,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                          ],
                      ),
                    ),
                    for (final a in items)
                      _menuButton(
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
  }) {
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
            splashColor: Colors.indigo.withOpacity(.08),
            highlightColor: Colors.indigo.withOpacity(.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, color: Colors.indigo),
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        readOnly: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AramaEkrani(),
            ),
          );
        },
        decoration: const InputDecoration(
          hintText: 'Ne yapmak istiyorsun?',
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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

class _HomeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? svgPath;
  final Color color;
  final VoidCallback onTap;

  const _HomeCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.svgPath,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Çerçevesiz, 42x42 alanda ikon
    final Widget iconWidget = (svgPath != null)
        ? SvgPicture.asset(
      svgPath!,
      width: 42,
      height: 42,
      fit: BoxFit.contain,
      allowDrawingOutsideViewBox: true,
      // colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      errorBuilder: (ctx, err, stack) {
        debugPrint('SVG HATASI ($svgPath): $err');
        return Icon(icon ?? Icons.image_not_supported_outlined,
            size: 42, color: color);
      },
    )
        : Icon(icon, color: color, size: 42);

    return Material(
      color: Colors.white,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: Colors.indigo.withOpacity(.08),
        highlightColor: Colors.indigo.withOpacity(.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              SizedBox(width: 42, height: 42, child: Center(child: iconWidget)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: title == "Emeklilik Takip" ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SonHesaplamalarBlock extends StatefulWidget {
  const _SonHesaplamalarBlock({Key? key}) : super(key: key);

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Son Hesaplamalar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ],
                        ),
            const SizedBox(height: 8),
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
            : Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.indigo),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                            'Henüz hesaplama bulunmuyor. Hızlıca bir hesaplama yapmak için butona dokun.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HesaplamalarEkrani(),
                              ),
                            );
                          },
                          child: const Text('Hesapla'),
                        ),
          ],
                    ),
        ),
      ),
    );
  }
}

class BannerCard extends StatelessWidget {
  final BannerItem item;
  final VoidCallback onPressed;  // YENİ

  const BannerCard({
    super.key,
    required this.item,
    required this.onPressed,      // YENİ
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.5,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [item.color.withOpacity(.12), item.color.withOpacity(.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.black12.withOpacity(.05)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.black87),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _darken(item.color, .15),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: onPressed,   // YENİ: dışarıdan gelen callback
                      style: FilledButton.styleFrom(
                        backgroundColor: item.color,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(item.buttonText, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: item.color.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}


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
