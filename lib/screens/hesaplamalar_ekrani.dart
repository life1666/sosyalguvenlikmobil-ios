import '../utils/app_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../hesaplamalar/brutten_nete.dart';
import '../hesaplamalar/asgari_iscilik.dart';
import '../hesaplamalar/rapor_parasi.dart';
import '../hesaplamalar/askerlik_dogum.dart';
import '../hesaplamalar/issizlik_sorguhesap.dart';
import '../hesaplamalar/kidem_alabilir.dart';
import '../hesaplamalar/kidem_hesap.dart';
import '../hesaplamalar/netten_brute.dart';
import '../hesaplamalar/yillik_izin.dart';
import '../hesaplamalar/4a_hesapla.dart';
import '../hesaplamalar/4b_hesapla.dart';
import '../hesaplamalar/4c_hesapla.dart';
import '../hesaplamalar/emeklilik_hesaplama.dart';

/// =================== GLOBAL KNOB'LAR ===================

// Sayfa yatay kenar boşluğu (sol/sağ eşit)
const double kPageHPad = 16.0;

// Yazı ölçeği (tüm metin)
const double kTextScale = 1.00; // 0.90–1.10 arasında oynat

// Yazı rengi ve kalınlıkları (global)
const Color kTextColor = Colors.black87;
const FontWeight kTitleWeight = FontWeight.w700; // AppBar başlığı
const FontWeight kBodyWeight = FontWeight.w400; // Ana menü satırları
const FontWeight kSmallWeight = FontWeight.w400; // Alt menü satırları

// Ok kalınlığı (görsel ağırlık) → thin / regular / bold
enum ArrowWeight { thin, regular, bold }

const ArrowWeight kArrowWeight = ArrowWeight.regular;

// Ok rengi & boyutu (global)
const Color kArrowColor = Colors.black38;
const double kArrowSize = 20;

// Divider (global)
const double kDividerThickness = 0.2; // çizgi kalınlığı (px)
const double kDividerSpace = 2.0; // çizgi etrafındaki toplam dikey alan (px)
/// ========================================================

class HesaplamalarEkrani extends StatefulWidget {
  final bool autoOpenEmeklilik;
  const HesaplamalarEkrani({super.key, this.autoOpenEmeklilik = false});

  @override
  State<HesaplamalarEkrani> createState() => _HesaplamalarEkraniState();
}

class _HesaplamalarEkraniState extends State<HesaplamalarEkrani> {
  final List<Map<String, dynamic>> hesaplamalar = [
    {'baslik': 'Emeklilik Hesaplama', 'ikon': Icons.calendar_today},
    {'baslik': 'Kıdem - İhbar Tazminatı İşlemleri', 'ikon': Icons.work_history},
    {
      'baslik': 'İşsizlik Maaşı İşlemleri',
      'ikon': Icons.person_outline_rounded
    },
    {
      'baslik': 'SGK Prim Borçlanma Tutarı Hesaplama',
      'ikon': Icons.account_balance
    },
    {
      'baslik': 'Brütten Nete Maaş Hesaplama',
      'ikon': Icons.account_balance_wallet
    },
    {'baslik': 'Netten Brüte Maaş Hesaplama', 'ikon': Icons.bar_chart},
    {'baslik': 'Rapor Parası Hesaplama', 'ikon': Icons.local_hospital},
    {'baslik': 'Yıllık İzin Süresi Hesaplama', 'ikon': Icons.beach_access},
    {'baslik': 'Asgari İşçilik Hesaplama', 'ikon': Icons.handyman},
  ];

  /// Tek açık alt menüyü tutan index (yoksa = null)
  int? _openIndex; // başlangıçta hiçbiri açık değil

  @override
  void initState() {
    super.initState();
    // Emeklilik takip ekranından geliyorsa emeklilik hesaplama seçeneğini otomatik aç
    if (widget.autoOpenEmeklilik) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _openIndex = 0; // Emeklilik Hesaplama index 0
          });
        }
      });
    }
  }

  // Bu index alt menüye sahip mi?
  bool _indexHasSubmenu(int index) {
    final t = hesaplamalar[index]['baslik'] as String;
    return t == 'Kıdem - İhbar Tazminatı İşlemleri' ||
        t == 'İşsizlik Maaşı İşlemleri' ||
        t == 'SGK Prim Borçlanma Tutarı Hesaplama';
  }

  // Bu index açık mı?
  bool _isOpen(int index) => _openIndex == index;

  // Tıklanınca: tek açık alt menü kuralı (anında değiştir)
  void _onTapRow(int index) {
    if (!_indexHasSubmenu(index)) {
      // Alt menü yoksa direkt navigasyon yap
      _navigateToScreen(index);
      return;
    }

    setState(() {
      if (_openIndex == index) {
        _openIndex = null; // aynı satıra basılırsa kapat
      } else {
        _openIndex =
            index; // başka satır → direkt onu aç, diğeri anında kapanır
      }
    });
  }

  // Ekrana navigasyon
  void _navigateToScreen(int index) {
    final title = hesaplamalar[index]['baslik'] as String;

    if (title == 'Emeklilik Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmeklilikHesaplamaBirlesik()),
      );
    } else if (title == 'Brütten Nete Maaş Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SalaryCalculatorScreen()),
      );
    } else if (title == 'Netten Brüte Maaş Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NettenBruteScreen()),
      );
    } else if (title == 'Asgari İşçilik Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HesaplamaSayfasi()),
      );
    } else if (title == 'Rapor Parası Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RaporParasiScreen()),
      );
    } else if (title == 'Yıllık İzin Süresi Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const YillikUcretliIzinSayfasi()),
      );
    }
  }

  // Alt menü item'ına tıklanınca
  void _onTapAltMenuItem(String title) {
    if (title == '4/a (SSK) Emeklilik Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const EmeklilikHesaplama4aSayfasi()),
      );
    } else if (title == '4/b (Bağ-kur) Emeklilik Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const EmeklilikHesaplama4bSayfasi()),
      );
    } else if (title == '4/c (Memur) Emeklilik Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EmeklilikHesaplamaSayfasi()),
      );
    } else if (title == 'Kıdem - İhbar Tazminatı Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const CompensationCalculatorScreen()),
      );
    } else if (title == 'SGK\'dan Kıdem Tazminatı Alabilir Yazısı Sorgulama') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Theme(
            data: Theme.of(context),
            child: const KidemTazminatiScreen(),
          ),
        ),
      );
    } else if (title == 'İşsizlik Maaşı Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IsizlikMaasiScreen()),
      );
    } else if (title == 'İşsizlik Maaşı Başvurusu') {
      _acIssizlikBasvuru();
    } else if (title ==
        'Askerlik, Doğum ve Diğer Borçlanmaların Prim Tutarı Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const BorclanmaHesaplamaScreen()),
      );
    } else if (title == 'Yurt Dışı Borçlanması Prim Tutarı Hesaplama') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const BorclanmaHesaplamaScreen()),
      );
    } else if (title == 'Borçlanma Başvurusu') {
      _acBorclanmaBasvuru();
    }
  }

  String _query = '';
  String _category = 'Tümü';
  static const _groups = [
    'Emeklilik',
    'Tazminat',
    'Destekler',
    'Emeklilik',
    'Maaş',
    'Maaş',
    'Destekler',
    'İzin',
    'İşveren'
  ];
  String _normalize(String text) => text
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g');
  static const _searchTerms = [
    'SSK Bağkur Bağ-kur memur 4a 4b 4c',
    'kıdem ihbar yazısı',
    'işsizlik başvuru',
    'askerlik doğum yurt dışı borçlanma',
    'brüt net ücret',
    'net brüt ücret',
    'rapor iş göremezlik',
    'yıllık izin',
    'asgari işçilik'
  ];

  @override
  Widget build(BuildContext context) {
    final visible = List.generate(hesaplamalar.length, (i) => i)
        .where((i) =>
            (_category == 'Tümü' || _groups[i] == _category) &&
            _normalize('${hesaplamalar[i]['baslik']} ${_searchTerms[i]}')
                .contains(_normalize(_query.trim())))
        .toList();
    return Scaffold(
      backgroundColor: AppDesign.activeBackground,
      appBar: AppDesign.appBar('Hesapla'),
      body: SafeArea(
          child: AppContent(
              child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
                hintText: 'Hesaplama ara',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppDesign.activeSurface,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppDesign.activeBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppDesign.activeBorder))),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            AppSurface(
                child: Text(
                    'Aramanıza uygun hesaplama bulunamadı. Başka bir kelime veya kategori deneyin.',
                    style: TextStyle(color: AppDesign.activeMuted))),
          for (final i in visible) ...[
            AppSurface(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  AppActionTile(
                      title: hesaplamalar[i]['baslik'] as String,
                      subtitle: _indexHasSubmenu(i)
                          ? 'Seçenekleri görüntüle'
                          : 'Bilgilerinizi girin, sonucu görün',
                      icon: hesaplamalar[i]['ikon'] as IconData,
                      onTap: () => _onTapRow(i),
                      badge: 'Ücretsiz',
                      expanded: _isOpen(i)),
                  if (_indexHasSubmenu(i) && _isOpen(i))
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12, right: 12),
                        child: _buildAltMenuForIndex(
                            i, Theme.of(context).textTheme)),
                ])),
            const SizedBox(height: 10),
          ],
        ],
      ))),
    );
  }

  // Ok ikonunu global "kalınlık" ayarına göre seç
  IconData _arrowIconData({required bool expanded}) {
    switch (kArrowWeight) {
      case ArrowWeight.thin:
        return expanded
            ? CupertinoIcons.chevron_down
            : CupertinoIcons.chevron_right;
      case ArrowWeight.regular:
        return expanded ? Icons.expand_more : Icons.chevron_right_rounded;
      case ArrowWeight.bold:
        return expanded
            ? Icons.keyboard_arrow_down_rounded
            : Icons.keyboard_arrow_right_rounded;
    }
  }

  // İlgili index'e göre alt menü üret (inset divider + optik hizalı padding)
  Widget _buildAltMenuForIndex(int index, TextTheme tt) {
    final title = hesaplamalar[index]['baslik'] as String;

    List<String> items;
    if (title == 'Emeklilik Hesaplama') {
      items = [
        '4/a (SSK) Emeklilik Hesaplama',
        '4/b (Bağ-kur) Emeklilik Hesaplama',
        '4/c (Memur) Emeklilik Hesaplama',
      ];
    } else if (title == 'Kıdem - İhbar Tazminatı İşlemleri') {
      items = [
        'Kıdem - İhbar Tazminatı Hesaplama',
        'SGK\'dan Kıdem Tazminatı Alabilir Yazısı Sorgulama',
      ];
    } else if (title == 'İşsizlik Maaşı İşlemleri') {
      items = [
        'İşsizlik Maaşı Hesaplama',
        'İşsizlik Maaşı Başvurusu',
      ];
    } else if (title == 'SGK Prim Borçlanma Tutarı Hesaplama') {
      items = [
        'Askerlik, Doğum ve Diğer Borçlanmaların Prim Tutarı Hesaplama',
        'Yurt Dışı Borçlanması Prim Tutarı Hesaplama',
        'Borçlanma Başvurusu',
      ];
    } else {
      items = [];
    }

    return _altMenuBlock(items, tt);
  }

  Widget _altMenuBlock(List<String> items, TextTheme tt) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppDesign.activeBackground,
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              AppSubmenuTile(
                  title: items[i],
                  icon: Icons.arrow_forward_rounded,
                  badge: items[i].contains('Başvurusu') ? null : 'Ücretsiz',
                  onTap: () => _onTapAltMenuItem(items[i])),
            ],
          ]),
        ),
      );
}

// 📌 Başvuru linkleri
void _acIssizlikBasvuru() async {
  final Uri url =
      Uri.parse('https://www.turkiye.gov.tr/issizlik-odenegi-basvurusu');
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      debugPrint("Link açılamadı: $url");
    }
  } catch (e) {
    debugPrint("Link açılırken hata oluştu: $e");
  }
}

void _acBorclanmaBasvuru() async {
  final Uri url =
      Uri.parse('https://www.turkiye.gov.tr/sosyal-guvenlik-kurumu');
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      debugPrint("Link açılamadı: $url");
    }
  } catch (e) {
    debugPrint("Link açılırken hata oluştu: $e");
  }
}
