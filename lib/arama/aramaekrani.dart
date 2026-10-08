import 'package:src/utils/app_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../makaleler/makale.dart';
import '../makaleler/calisan_makaleler.dart';
import '../makaleler/emeklilik_makaleler.dart';
import '../makaleler/isveren_makaleler.dart';
import '../screens/hesaplamalar_ekrani.dart';
import '../cv/cv_olustur.dart';
import '../emeklilik_takip/emeklilik_takip.dart';
import '../sozluk/sozluk.dart';

/// Arama sonucu modeli
class AramaSonucu {
  final String baslik;
  final String? altBaslik;
  final String tip; // 'makale', 'hesaplama', 'menu'
  final IconData? ikon;
  final VoidCallback onTap;
  final dynamic data; // Ek veri (makale objesi, route vb.)

  AramaSonucu({
    required this.baslik,
    this.altBaslik,
    required this.tip,
    this.ikon,
    required this.onTap,
    this.data,
  });
}

class AramaEkrani extends StatefulWidget {
  const AramaEkrani({super.key});

  @override
  State<AramaEkrani> createState() => _AramaEkraniState();
}

class _AramaEkraniState extends State<AramaEkrani> {
  final TextEditingController _aramaController = TextEditingController();
  List<AramaSonucu> _sonuclar = [];
  bool _aramaYapildi = false;

  @override
  void initState() {
    super.initState();
    _aramaController.addListener(_aramaYap);
  }

  @override
  void dispose() {
    _aramaController.removeListener(_aramaYap);
    _aramaController.dispose();
    super.dispose();
  }

  // Türkçe karakterleri normalize et
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('İ', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('Ç', 'c');
  }

  void _aramaYap() {
    final query = _aramaController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _sonuclar = [];
        _aramaYapildi = false;
      });
      return;
    }

    final normalizedQuery = _normalize(query);
    final sonuclar = <AramaSonucu>[];

    // Makaleleri ara
    final tumMakaleler = [
      ...calisanMakaleler,
      ...emeklilikMakaleler,
      ...isverenMakaleler,
    ];

    for (final makale in tumMakaleler) {
      if (_normalize(makale.title).contains(normalizedQuery) ||
          _normalize(makale.content).contains(normalizedQuery)) {
        sonuclar.add(AramaSonucu(
          baslik: makale.title,
          altBaslik: makale.content.split('\n').firstWhere(
            (e) => e.trim().isNotEmpty,
            orElse: () => '',
          ),
          tip: 'makale',
          ikon: Icons.article,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MakaleDetailScreen(makale: makale),
              ),
            );
          },
          data: makale,
        ));
      }
    }

    // Hesaplamalar menüsünü ara
    final hesaplamalar = [
      'Emeklilik Hesaplama',
      'Kıdem - İhbar Tazminatı İşlemleri',
      'İşsizlik Maaşı İşlemleri',
      'SGK Prim Borçlanma Tutarı Hesaplama',
      'Brütten Nete Maaş Hesaplama',
      'Netten Brüte Maaş Hesaplama',
      'Rapor Parası Hesaplama',
      'Yıllık İzin Süresi Hesaplama',
      'Asgari İşçilik Hesaplama',
    ];

    for (final hesaplama in hesaplamalar) {
      if (_normalize(hesaplama).contains(normalizedQuery)) {
        sonuclar.add(AramaSonucu(
          baslik: hesaplama,
          tip: 'hesaplama',
          ikon: Icons.calculate,
          onTap: () {
            Navigator.pop(context); // Arama ekranını kapat
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HesaplamalarEkrani(),
              ),
            );
          },
        ));
      }
    }

    // Ana menü öğelerini ara
    final menuItems = [
      'Hesaplamalar',
      'Mesai Takip',
      'CV Oluştur',
      'Makaleler',
      'Sözlük',
      'Emeklilik Takip',
    ];

    for (final menu in menuItems) {
      final normalizedMenu = _normalize(menu);
      // Özel eşleştirmeler: "Hesapla" -> "Hesaplamalar", "CV" -> "CV Oluştur"
      bool menuMatch = normalizedMenu.contains(normalizedQuery);
      
      if (menu == "Hesaplamalar" && normalizedQuery.contains('hesapla')) {
        menuMatch = true;
      } else if (menu == "CV Oluştur" && (normalizedQuery.contains('cv') || normalizedQuery == 'cv')) {
        menuMatch = true;
      }
      
      if (menuMatch) {
        VoidCallback onTap;
        
        if (menu == "Hesaplamalar") {
          onTap = () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HesaplamalarEkrani()),
            );
          };
        } else if (menu == "Makaleler") {
          onTap = () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MakalelerView()),
            );
          };
        } else if (menu == "Mesai Takip") {
          onTap = () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/mesai');
          };
        } else if (menu == "CV Oluştur") {
          onTap = () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CvApp()),
            );
          };
        } else if (menu == "Emeklilik Takip") {
          onTap = () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmeklilikTakipApp()),
            );
          };
        } else if (menu == "Sözlük") {
          onTap = () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SozlukHomePage()),
            );
          };
        } else {
          continue;
        }

        sonuclar.add(AramaSonucu(
          baslik: menu,
          tip: 'menu',
          ikon: Icons.apps,
          onTap: onTap,
        ));
      }
    }

    setState(() {
      _sonuclar = sonuclar;
      _aramaYapildi = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppMenuBar(
        title: Text(
          'Ara',
          style: TextStyle(
            color: AppDesign.activeInk,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppDesign.activeInk),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Material(
              color: AppDesign.activeSurface,
              elevation: 1,
              borderRadius: BorderRadius.circular(14),
              child: TextField(
                controller: _aramaController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ne yapmak istiyorsun?',
                  prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _aramaController.text.isEmpty && !_aramaYapildi
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aramak istediğiniz kelimeyi yazın',
                    style: tt.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _sonuclar.isEmpty && _aramaYapildi
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sonuç bulunamadı',
                        style: tt.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _sonuclar.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sonuc = _sonuclar[index];
                    return AppSurface(padding: EdgeInsets.zero, child: AppActionTile(
                      title: sonuc.baslik, subtitle: sonuc.altBaslik,
                      icon: sonuc.ikon ?? Icons.search_rounded, onTap: sonuc.onTap,
                    ));                  },
                ),
    );
  }
}

