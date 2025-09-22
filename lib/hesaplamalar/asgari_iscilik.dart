import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asgari İşçilik Hesaplama',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      home: const HesaplamaSayfasi(),
    );
  }
}

class HesaplamaSayfasi extends StatefulWidget {
  const HesaplamaSayfasi({super.key});

  @override
  _HesaplamaSayfasiState createState() => _HesaplamaSayfasiState();
}

class _HesaplamaSayfasiState extends State<HesaplamaSayfasi> {
  String? secilenYil;
  String? secilenSinif;
  String? secilenGrup;
  String? secilenInsTuru;
  final TextEditingController alanController = TextEditingController();
  Map<String, dynamic>? _hesaplamaSonucu;

  // Sonuçlara otomatik kaydırma için ScrollController ve GlobalKey
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  // Reklam değişkenleri
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  // 2024 Birim Maliyetler (TL/m²)
  final Map<String, Map<String, double>> birimMaliyetler2024 = {
    'I': {'A': 1450.0, 'B': 2100.0},
    'II': {'A': 3500.0, 'B': 5250.0, 'C': 7750.0},
    'III': {'A': 12250.0, 'B': 14400.0},
    'IV': {'A': 15300.0, 'B': 17400.0, 'C': 18700.0},
    'V': {'A': 21300.0, 'B': 22250.0, 'C': 24300.0, 'D': 26800.0},
  };

  // 2025 Birim Maliyetler (TL/m²)
  final Map<String, Map<String, double>> birimMaliyetler2025 = {
    'I': {'A': 2100.0, 'B': 3050.0, 'C': 3300.0, 'D': 3900.0},
    'II': {'A': 6600.0, 'B': 10200.0, 'C': 12400.0},
    'III': {'A': 17100.0, 'B': 18200.0, 'C': 19150.0},
    'IV': {'A': 21500.0, 'B': 27500.0, 'C': 32600.0},
    'V': {'A': 34400.0, 'B': 35600.0, 'C': 39500.0, 'D': 43400.0, 'E': 86250.0},
  };

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    alanController.dispose();
    _scrollController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-6005798972779145/4051383467', // Test reklam kimliği
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          setState(() {
            _interstitialAd = ad;
            _isAdReady = true;
          });
          print('Reklam yüklendi');
        },
        onAdFailedToLoad: (LoadAdError error) {
          setState(() {
            _isAdReady = false;
          });
          print('Reklam yüklenemedi: $error');
        },
      ),
    );
  }

  double getAsgariIscilikOrani() {
    switch (secilenInsTuru) {
      case 'Yığma (Kargir) İnşaat':
        return 0.12;
      case 'Karkas İnşaat':
        return 0.09;
      case 'Bina İnşaatı':
        return 0.13;
      case 'Prefabrik':
        return 0.08;
      default:
        return 0.0;
    }
  }

  double getUygulanabilirAsgariIscilikOrani() {
    switch (secilenInsTuru) {
      case 'Yığma (Kargir) İnşaat':
        return 0.09;
      case 'Karkas İnşaat':
        return 0.0675;
      case 'Bina İnşaatı':
        return 0.0975;
      case 'Prefabrik':
        return 0.06;
      default:
        return 0.0;
    }
  }

  List<String> getGrupSecenekleri() {
    final currentMap = (secilenYil == '2024') ? birimMaliyetler2024 : birimMaliyetler2025;
    if (secilenSinif == null || !currentMap.containsKey(secilenSinif)) {
      return currentMap['I']!.keys.toList();
    }
    return currentMap[secilenSinif]!.keys.toList();
  }

  double birimMaliyetHesapla() {
    if (secilenSinif != null && secilenGrup != null) {
      final currentMap = (secilenYil == '2024') ? birimMaliyetler2024 : birimMaliyetler2025;
      return currentMap[secilenSinif]?[secilenGrup] ?? 0.0;
    }
    return 0.0;
  }

  double insaatMaliyetiHesapla() {
    double alan = double.tryParse(alanController.text) ?? 0.0;
    if (alan <= 0) return 0.0;
    double birimMaliyet = birimMaliyetHesapla();
    return alan * birimMaliyet;
  }

  double asgariIscilikMatrahiHesapla() {
    double insaatMaliyeti = insaatMaliyetiHesapla();
    double uygulanabilirOran = getUygulanabilirAsgariIscilikOrani();
    return insaatMaliyeti * uygulanabilirOran;
  }

  double odenmesiGerekenPrimHesapla() {
    double asgariIscilikMatrahi = asgariIscilikMatrahiHesapla();
    return asgariIscilikMatrahi * 0.3475;
  }

  String formatSayi(double sayi) {
    final formatter = NumberFormat("#,##0.00", "tr_TR");
    String formatted = formatter.format(sayi);
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
    return "$formatted TL";
  }

  bool _validateInputs() {
    if (secilenYil == null ||
        secilenSinif == null ||
        secilenGrup == null ||
        secilenInsTuru == null ||
        alanController.text.isEmpty) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': 'Lütfen tüm alanları eksiksiz doldurun!',
          'detaylar': {},
          'ekBilgi': {
            'Kontrol Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Asgari İşçilik Oranı': secilenInsTuru == null
                ? 'Seçilmedi'
                : '%${(getAsgariIscilikOrani() * 100).toStringAsFixed(2)} - Uygulanabilir: %${(getUygulanabilirAsgariIscilikOrani() * 100).toStringAsFixed(2)}',
          },
        };
      });
      _scrollToResult();
      return false;
    }

    double alan = double.tryParse(alanController.text) ?? 0.0;
    if (alan <= 0) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': 'İnşaat alanı geçerli bir sayı olmalı ve sıfırdan büyük olmalıdır!',
          'detaylar': {},
          'ekBilgi': {
            'Kontrol Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Asgari İşçilik Oranı': secilenInsTuru == null
                ? 'Seçilmedi'
                : '%${(getAsgariIscilikOrani() * 100).toStringAsFixed(2)} - Uygulanabilir: %${(getUygulanabilirAsgariIscilikOrani() * 100).toStringAsFixed(2)}',
          },
        };
      });
      _scrollToResult();
      return false;
    }

    return true;
  }

  void hesapla() {
    // Her hesaplama öncesi durumu sıfırla
    setState(() {
      _hesaplamaSonucu = null;
    });

    // Girişleri doğrula
    if (!_validateInputs()) {
      return;
    }

    // Doğrulama başarılıysa reklam göster
    if (_isAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          setState(() {
            _interstitialAd = null;
            _isAdReady = false;
          });
          _loadInterstitialAd();
          _showHesaplamaSonucu();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          setState(() {
            _interstitialAd = null;
            _isAdReady = false;
          });
          _loadInterstitialAd();
          _showHesaplamaSonucu();
        },
      );
      _interstitialAd!.show();
    } else {
      _showHesaplamaSonucu();
    }
  }

  void _showHesaplamaSonucu() {
    double birimMaliyet = birimMaliyetHesapla();
    double insaatMaliyeti = insaatMaliyetiHesapla();
    double asgariIscilikMatrahi = asgariIscilikMatrahiHesapla();
    double odenmesiGerekenPrim = odenmesiGerekenPrimHesapla();

    setState(() {
      _hesaplamaSonucu = {
        'basarili': true,
        'mesaj': 'Hesaplama Başarıyla Tamamlandı!',
        'detaylar': {
          'Birim Maliyet': '${formatSayi(birimMaliyet)}/m²',
          'İnşaat Maliyeti': formatSayi(insaatMaliyeti),
          'Asgari İşçilik Matrahı': formatSayi(asgariIscilikMatrahi),
          'Ödenmesi Gereken Prim': formatSayi(odenmesiGerekenPrim),
        },
        'ekBilgi': {
          'Kontrol Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          'Asgari İşçilik Oranı': secilenInsTuru == null
              ? 'Seçilmedi'
              : '%${(getAsgariIscilikOrani() * 100).toStringAsFixed(2)} - Uygulanabilir: %${(getUygulanabilirAsgariIscilikOrani() * 100).toStringAsFixed(2)}',
        },
      };
    });
    _scrollToResult();
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultKey.currentContext!,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.resmigazete.gov.tr/eskiler/2025/01/20250131-3.htm');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'URL açılamadı: $url';
    }
  }

  Widget _buildDropdownCard(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              iconEnabledColor: Colors.indigo,
              value: value,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
                border: OutlineInputBorder(),
                hintText: 'Seçiniz',
              ),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldCard(String label, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.area_chart, color: Colors.indigo),
                border: OutlineInputBorder(),
                hintText: 'm²',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHesaplaButtonCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo, Colors.blueAccent],
          ),
        ),
        child: ElevatedButton(
          onPressed: hesapla,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            'Hesapla',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_hesaplamaSonucu == null) return Container();

    bool basarili = _hesaplamaSonucu!['basarili'] ?? false;
    String mesaj = _hesaplamaSonucu!['mesaj'] ?? '';

    Map<String, String> detaylar = {};
    if (_hesaplamaSonucu!['detaylar'] != null) {
      detaylar = Map<String, String>.from(_hesaplamaSonucu!['detaylar']);
    }

    Map<String, String> ekBilgi = {};
    if (_hesaplamaSonucu!['ekBilgi'] != null) {
      ekBilgi = Map<String, String>.from(_hesaplamaSonucu!['ekBilgi']);
    }

    // Ana mesaj kartı
    Widget messageCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          mesaj,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: basarili ? Colors.green : Colors.red,
          ),
        ),
      ),
    );

    // Detaylar kartı
    final iconMap = {
      'Birim Maliyet': Icons.money_off,
      'İnşaat Maliyeti': Icons.home_work,
      'Asgari İşçilik Matrahı': Icons.build_circle_outlined,
      'Ödenmesi Gereken Prim': Icons.payment,
    };

    Widget detailsCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Center(
              child: Text(
                'Detaylar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...detaylar.entries.map((entry) {
              final icon = iconMap[entry.key] ?? Icons.info_outline;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (entry.key != detaylar.keys.last) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );

    // Ek Bilgi kartı
    // Ek Bilgi kartı
    Widget ekBilgiCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              child: const Text(
                'Ek Bilgiler',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Yeni ek bilgi mesajları
            ...[
              'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!',
              'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!',
              'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!',
            ].map((mesaj) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mesaj,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
            const SizedBox(height: 8),
            // Mevcut ek bilgiler (en altta)
            Text(
              ekBilgi['Kontrol Tarihi'] != null ? 'Kontrol Tarihi: ${ekBilgi['Kontrol Tarihi']}' : '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 4),
            Builder(
              builder: (_) {
                final String? asgariOran = ekBilgi['Asgari İşçilik Oranı'];
                if (asgariOran != null && asgariOran.contains(' - Uygulanabilir: ')) {
                  final splitted = asgariOran.split(' - Uygulanabilir: ');
                  final oranKismi = splitted[0];
                  final uygulanabilirKismi = splitted.length > 1 ? splitted[1] : '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asgari İşçilik Oranı: $oranKismi',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.left,
                      ),
                      Text(
                        'Uygulanabilir: $uygulanabilirKismi',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  );
                } else if (asgariOran != null) {
                  return Text(
                    'Asgari İşçilik Oranı: $asgariOran',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.left,
                  );
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );

    return Column(
      key: _resultKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        messageCard,
        const SizedBox(height: 12),
        if (detaylar.isNotEmpty) detailsCard,
        const SizedBox(height: 12),
        if (ekBilgi.isNotEmpty) ekBilgiCard,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asgari İşçilik Hesaplama'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: _launchURL,
                    child: const Text(
                      '2025 Yılı Yapı Yaklaşık Birim Maliyetleri Hakkında Tebliğ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              _buildDropdownCard(
                'Yıl',
                secilenYil,
                ['2024', '2025'].map((yil) => DropdownMenuItem(value: yil, child: Text(yil))).toList(),
                    (value) => setState(() {
                  secilenYil = value;
                  secilenSinif = null;
                  secilenGrup = null;
                }),
              ),
              _buildDropdownCard(
                'Sınıf',
                secilenSinif,
                ['I', 'II', 'III', 'IV', 'V']
                    .map((sinif) => DropdownMenuItem(value: sinif, child: Text('$sinif. Sınıf')))
                    .toList(),
                    (value) => setState(() {
                  secilenSinif = value;
                  secilenGrup = null;
                }),
              ),
              _buildDropdownCard(
                'Grup',
                secilenGrup,
                getGrupSecenekleri()
                    .map((grup) => DropdownMenuItem(value: grup, child: Text('$grup Grubu')))
                    .toList(),
                    (value) => setState(() => secilenGrup = value),
              ),
              _buildDropdownCard(
                'İnşaat Türü',
                secilenInsTuru,
                ['Yığma (Kargir) İnşaat', 'Karkas İnşaat', 'Bina İnşaatı', 'Prefabrik']
                    .map((tur) => DropdownMenuItem(value: tur, child: Text(tur)))
                    .toList(),
                    (value) => setState(() => secilenInsTuru = value),
              ),
              _buildTextFieldCard('İnşaat Alanı', alanController),
              const SizedBox(height: 20),
              Center(child: _buildHesaplaButtonCard()),
              const SizedBox(height: 20),
              _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }
}