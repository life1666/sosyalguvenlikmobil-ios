import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const YurtDisiBorclanmaHesaplamaApp());
}

class YurtDisiBorclanmaHesaplamaApp extends StatelessWidget {
  const YurtDisiBorclanmaHesaplamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yurt Dışı Borçlanma Hesaplama',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 14, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 12, color: Colors.black54),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        cardTheme: const CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
      home: const YurtDisiBorclanmaHesaplamaScreen(),
    );
  }
}

class YurtDisiBorclanmaHesaplamaScreen extends StatefulWidget {
  const YurtDisiBorclanmaHesaplamaScreen({super.key});

  @override
  _YurtDisiBorclanmaHesaplamaScreenState createState() => _YurtDisiBorclanmaHesaplamaScreenState();
}

class _YurtDisiBorclanmaHesaplamaScreenState extends State<YurtDisiBorclanmaHesaplamaScreen> {
  final TextEditingController _gunController = TextEditingController();
  Map<String, dynamic>? _hesaplamaSonucu;
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  final double _asgariAylikGelir = 26005.50;
  final double _ustLimitGelir = 169035.75;
  final double _borclanmaOrani = 0.45;
  final String _borclanmaTuru = 'Yurt Dışı Borçlanma';
  final String _basvuruTarihi = '01.01.2025 - 31.12.2025';
  final GlobalKey _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _gunController.dispose();
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

  // Kelimelerin ilk harfini büyük yapmaya yarayan fonksiyon
  String toTitleCase(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
        ? word[0].toUpperCase() + word.substring(1).toLowerCase()
        : word)
        .join(' ');
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

  String _formatSayi(double sayi) {
    final formatter = NumberFormat("#,##0.00", "tr_TR");
    String formatted = formatter.format(sayi);
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
    return formatted;
  }

  void _hesapla() {
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
    print("showHesaplamaSonucu çağrıldı");

    if (_gunController.text.isEmpty) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': 'Lütfen gün sayısını girin!',
          'detaylar': {},
          'ekBilgi': {
            'Kontrol Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Not': 'Eksik bilgileri tamamlayarak tekrar deneyin.',
          },
        };
      });
      _scrollToResult();
      return;
    }

    int gunSayisi = int.tryParse(_gunController.text) ?? 0;
    if (gunSayisi <= 0) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': 'Lütfen geçerli bir gün sayısı girin!',
          'detaylar': {},
          'ekBilgi': {
            'Kontrol Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Not': 'Gün sayısı pozitif bir tam sayı olmalıdır.',
          },
        };
      });
      _scrollToResult();
      return;
    }

    double gunlukAsgariUcret = _asgariAylikGelir / 30;
    double altLimitGunlukBedel = gunlukAsgariUcret * _borclanmaOrani;
    double altLimit = gunSayisi * altLimitGunlukBedel;

    double gunlukUstLimitGelir = _ustLimitGelir / 30;
    double ustLimitGunlukBedel = gunlukUstLimitGelir * _borclanmaOrani;
    double ustLimit = gunSayisi * ustLimitGunlukBedel;

    setState(() {
      _hesaplamaSonucu = {
        'basarili': true,
        'mesaj': 'Borçlanma Hesaplaması Başarıyla Tamamlandı!',
        'detaylar': {
          'Başvuru Tarihi': _basvuruTarihi,
          'Borçlanılacak Gün Sayısı': '$gunSayisi gün',
          'Borçlanma Alt Limiti': '${formatSayi(altLimit)} (Beyan Edilen Aylık Gelir ${_formatSayi(_asgariAylikGelir)} TL)',
          'Borçlanma Üst Limiti': '${formatSayi(ustLimit)} (Beyan Edilen Aylık Gelir ${_formatSayi(_ustLimitGelir)} TL)',
        },
        'ekBilgi': {
          'Kontrol Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          'Not': '$_basvuruTarihi Tarihleri Arasında $gunSayisi Gün $_borclanmaTuru İçin En Az ${formatSayi(altLimit)} En Çok ${formatSayi(ustLimit)} Prim Ödeyebilirsiniz.',
        },
      };
    });
    _scrollToResult();
    print("Hesaplama Sonucu: ${(_hesaplamaSonucu!['detaylar'] as Map).length} detay");
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildHesaplaButton() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ElevatedButton(
          onPressed: _hesapla,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            'Hesapla',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.indigo,
  );

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

    return Column(
      key: _resultKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Sonuç',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toTitleCase(mesaj),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (basarili && detaylar.isNotEmpty) _buildResultDetails(detaylar),
        const SizedBox(height: 6),
        _buildEkBilgiCard(ekBilgi),
      ],
    );
  }

  Widget _buildResultDetails(Map<String, String> detaylar) {
    final iconMap = {
      'Başvuru Tarihi': Icons.calendar_today,
      'Borçlanılacak Gün Sayısı': Icons.calendar_today,
      'Borçlanma Alt Limiti': Icons.account_balance_wallet,
      'Borçlanma Üst Limiti': Icons.account_balance_wallet,
    };

    List<MapEntry<String, String>> entries = detaylar.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Detaylar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 4),
            ...entries.map((entry) {
              String keyLabel = entry.key == 'Başvuru Tarihi'
                  ? 'Başvuru Tarih Aralığı'
                  : entry.key;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(iconMap[entry.key] ?? Icons.info_outline, color: Colors.indigo, size: 18),
                    title: Text(
                      keyLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(entry.value, style: const TextStyle(fontSize: 14)),
                  ),
                  if (entry != entries.last) const Divider(height: 1),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEkBilgiCard(Map<String, String> ekBilgi) {
    final List<String> orderedKeys = [
      'Uyarı: Sosyal Güvenlik Mobil Resmi Bir Kurumun Uygulaması Değildir!',
      'Uyarı: Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!',
      'Uyarı: Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!',
      'Kontrol Tarihi',
      'Not',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Ek Bilgiler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 4),
            ...orderedKeys.map((key) {
              if (key.startsWith('Uyarı:')) {
                String uyariMesaji = key.replaceFirst('Uyarı: ', '');
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
                        toTitleCase(uyariMesaji),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }
              if (!ekBilgi.containsKey(key)) return Container();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '${toTitleCase(key)}: ${ekBilgi[key]}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yurt Dışı Borçlanma Hesaplama'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.centerLeft,
                child: Text('Başvuru Tarih Aralığı: $_basvuruTarihi', style: _labelStyle),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Borçlanılacak Gün Sayısı', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _gunController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.indigo),
                        border: OutlineInputBorder(),
                        hintText: 'Gün sayısını girin (ör. 360)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(child: _buildHesaplaButton()),
            const SizedBox(height: 20),
            if (_hesaplamaSonucu != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }
}