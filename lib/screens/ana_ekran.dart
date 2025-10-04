import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:src/screens/yanmenu/hesabim_ekrani.dart';
import 'bilgi_kategorileri_ekrani.dart';
import 'yanmenu/hesabim_ekrani.dart';
import 'yanmenu/iletisim_ekrani.dart';
import 'yanmenu/sozlesme_ekrani.dart';
import 'yanmenu/kvkk_ekrani.dart';
//import 'package:src/reklamlar/banner_reklam_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class AnaEkran extends StatefulWidget {
  @override
  _AnaEkranState createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _selectedIndex = 0;
  int _menuButtonIndex = 0;
  User? _kullanici;
  late PageController _pageController;
  String _appVersion = 'Bilinmiyor';

  @override
  void initState() {
    super.initState();
    _kullanici = FirebaseAuth.instance.currentUser;

    // UID konsola yazdır
    print('🆔 UID: ${_kullanici?.uid}');

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _kullanici = user;
      });
    });

    _pageController = PageController(initialPage: _menuButtonIndex);
    _loadAppVersion();
  }

  void _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Version: ${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  // URL açma fonksiyonu
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link açılamadı: $url')),
      );
    }
  }

  // Paylaşım fonksiyonu (kullanılmıyor, ancak gelecekte aktif edilebilir)
  Future<void> _shareApp() async {
    await Share.share(
      'Sosyal Güvenlik Mobil ile emeklilik ve sigorta bilgilerinizi takip edin! Bizi Instagram\'dan takip edin: https://www.instagram.com/sosyalguvenlikmobil/?igsh=MW5sYjR1MWJlcWNidw%3D%3D&utm_source=qr#',
      subject: 'Sosyal Güvenlik Mobil',
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sosyal Güvenlik Mobil',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true, // Başlığı ortalar
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sosyal Güvenlik Mobil',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.workspace_premium, color: Colors.amber),
              title: Text('Premiumlu Ol', style: TextStyle(fontSize: 16, color: Colors.indigo)),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              dense: true,
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Premium ekranı yakında eklenecek!')),
                );
              },
            ),
            if (_kullanici == null)
              ListTile(
                leading: Icon(Icons.login, color: Colors.indigo),
                title: Text('Giriş Yap / Kayıt Ol', style: TextStyle(fontSize: 16, color: Colors.indigo)),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                dense: true,
                onTap: () {
                  Navigator.pushNamed(context, '/giris');
                },
              )
            else
              ListTile(
                leading: Icon(Icons.person, color: Colors.indigo),
                title: Text('Hesabım', style: TextStyle(fontSize: 16, color: Colors.indigo)),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                dense: true,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HesabimEkrani()));
                },
              ),
            ListTile(
              leading: Icon(Icons.track_changes, color: Colors.indigo),
              title: Text('Emeklilik Takip', style: TextStyle(fontSize: 16, color: Colors.indigo)),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              dense: true,
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Emeklilik Takip ekranı yakında eklenecek!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.alarm, color: Colors.indigo),
              title: Text('Hatırlatıcılar', style: TextStyle(fontSize: 16, color: Colors.indigo)),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              dense: true,
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hatırlatıcılar ekranı yakında eklenecek!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.indigo),
              title: Text('Ayarlar', style: TextStyle(fontSize: 16, color: Colors.indigo)),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              dense: true,
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ayarlar ekranı yakında eklenecek!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.mail_outline, color: Colors.indigo),
              title: Text('İletişim', style: TextStyle(fontSize: 16, color: Colors.indigo)),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              dense: true,
              onTap: () {
                Navigator.pushNamed(context, '/iletisim');
              },
            ),
            ListTile(
              leading: Icon(Icons.star_rate, color: Colors.indigo),
              title: Text('Uygulamayı Puanla', style: TextStyle(fontSize: 16, color: Colors.indigo)),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              dense: true,
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Puanlama özelliği yakında eklenecek!')),
                );
              },
            ),
            ExpansionTile(
              leading: Icon(Icons.rule, color: Colors.indigo),
              title: Text('Sözleşmeler / KVKK', style: TextStyle(fontSize: 16, color: Colors.indigo)),
              children: [
                ListTile(
                  title: Text('Sözleşmeler', style: TextStyle(fontSize: 16, color: Colors.indigo)),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  dense: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SozlesmeEkrani()),
                    );
                  },
                ),
                ListTile(
                  title: Text('KVKK', style: TextStyle(fontSize: 16, color: Colors.indigo)),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  dense: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => KvkkEkrani()),
                    );
                  },
                ),
              ],
            ),
            if (_kullanici?.uid == 'yicHOHSjaPXH6sLwyc48ulCnai32')
              ListTile(
                leading: Icon(Icons.message, color: Colors.indigo),
                title: Text('Gelen Mesajlar', style: TextStyle(fontSize: 16, color: Colors.indigo)),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                dense: true,
                onTap: () {
                  Navigator.pushNamed(context, '/mesajlar');
                },
              ),
            if (_kullanici != null) ...[
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.indigo),
                title: Text('Çıkış Yap', style: TextStyle(fontSize: 16, color: Colors.indigo)),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                dense: true,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context); // Drawer'ı kapat
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Oturum kapatıldı")),
                  );
                },
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      iconSize: 30,
                      icon: FaIcon(FontAwesomeIcons.instagram, color: Color(0xFFE1306C)),
                      onPressed: () => _launchURL('https://www.instagram.com/sosyalguvenlikmobil/?igsh=MW5sYjR1MWJlcWNidw%3D%3D&utm_source=qr#')),
                  IconButton(
                      iconSize: 30,
                      icon: FaIcon(FontAwesomeIcons.facebook, color: Colors.blue),
                      onPressed: () => _launchURL('https://www.facebook.com/people/Sosyal-G%C3%BCvenlik-Mobil/61575847292304/')),
                  IconButton(
                      iconSize: 30,
                      icon: FaIcon(FontAwesomeIcons.linkedin, color: Colors.blueAccent),
                      onPressed: () => _launchURL('https://www.linkedin.com/in/sosyal-g%C3%BCvenlik-mobil-931b89361/?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=ios_app')),
                  IconButton(
                      iconSize: 30,
                      icon: FaIcon(FontAwesomeIcons.youtube, color: Colors.red),
                      onPressed: () => _launchURL('https://www.youtube.com/@sosyalguvenlikmobil')),
                  IconButton(
                      iconSize: 30,
                      icon: FaIcon(FontAwesomeIcons.xTwitter, color: Colors.black),
                      onPressed: () => _launchURL('https://x.com/sgmobil_?s=21')),
                  IconButton(
                      iconSize: 30,
                      icon: FaIcon(FontAwesomeIcons.shareNodes, color: Colors.grey),
                      onPressed: null),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  _appVersion,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0), bottomRight: Radius.circular(0)),
            ),
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuButton('ANASAYFA', 0),
                _buildSeparator(),
                _buildMenuButton('ÇALIŞAN', 1),
                _buildSeparator(),
                _buildMenuButton('EMEKLİLİK', 2),
                _buildSeparator(),
                _buildMenuButton('İŞVEREN', 3),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _menuButtonIndex = index;
                });
              },
              children: [
                BilgiKategorileriEkrani(category: 'ANASAYFA'),
                BilgiKategorileriEkrani(category: 'ÇALIŞAN'),
                BilgiKategorileriEkrani(category: 'EMEKLİLİK'),
                BilgiKategorileriEkrani(category: 'İŞVEREN'),
              ],
            ),
          ),
         // BannerReklamWidget(),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.white24, // Hafif beyaz dalga efekti
          highlightColor: Colors.white10, // Hafif parlama
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 2),
          backgroundColor: Colors.indigo,
          elevation: 4,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => IletisimEkrani()),
              );
            } else if (index == 0) {
              setState(() {
                _selectedIndex = index;
                _menuButtonIndex = 0;
              });
              _pageController.animateToPage(
                0,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.bug_report), label: 'Hata Bildir'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _menuButtonIndex = index;
          _selectedIndex = 0;
        });
        _pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _menuButtonIndex == index ? Colors.white : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _menuButtonIndex == index ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 0.3,
      height: 12,
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 0.5),
    );
  }
}