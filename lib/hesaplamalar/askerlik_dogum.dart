import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Noktalama ve parantezleri hem baştan hem sondan ayırarak
/// kalan kısmı "title case"e çevirir.
/// "tl" -> "TL", "icin" / "için" -> "İçin", vb. özel kuralları içerir.
String toTitleCase(String text) {
  if (text.isEmpty) return text;

  final punctuationChars = [
    ',',
    '.',
    ')',
    '!',
    '?',
    ';',
    ':',
    '(',
    '[',
    ']',
    '{',
    '}',
    '“',
    '”',
    '"',
    '\''
  ];

  List<String> words = text.split(' ');
  List<String> titleCasedWords = [];

  for (String originalWord in words) {
    if (originalWord.isEmpty) {
      titleCasedWords.add(originalWord);
      continue;
    }

    // 1) Baştaki noktalama/parantezleri ayır
    String leadingPunct = '';
    while (originalWord.isNotEmpty &&
        punctuationChars.contains(originalWord[0])) {
      leadingPunct += originalWord[0];
      originalWord = originalWord.substring(1);
    }

    // 2) Sondaki noktalama/parantezleri ayır
    String trailingPunct = '';
    while (originalWord.isNotEmpty &&
        punctuationChars.contains(originalWord[originalWord.length - 1])) {
      trailingPunct = originalWord[originalWord.length - 1] + trailingPunct;
      originalWord = originalWord.substring(0, originalWord.length - 1);
    }

    // 3) Küçük harfe çevirip özel kelimeleri kontrol et
    final lower = originalWord.toLowerCase();
    if (lower == 'tl') {
      // "tl" -> "TL"
      originalWord = 'TL';
    } else if (lower == 'icin' || lower == 'için') {
      // "icin" / "için" -> "İçin"
      originalWord = 'İçin';
    } else if (originalWord.isNotEmpty) {
      // Normal title-case mantığı
      originalWord = originalWord[0].toUpperCase() +
          originalWord.substring(1).toLowerCase();
    }

    // 4) Ayırdığımız baştaki ve sondaki noktalama/parantezleri geri ekle
    String finalWord = leadingPunct + originalWord + trailingPunct;
    titleCasedWords.add(finalWord);
  }

  return titleCasedWords.join(' ');
}

void main() {
  runApp(const BorclanmaHesaplamaApp());
}

class BorclanmaHesaplamaApp extends StatelessWidget {
  const BorclanmaHesaplamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Borçlanma Hesaplama',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
          headlineSmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      home: const BorclanmaHesaplamaScreen(),
    );
  }
}

class BorclanmaHesaplamaScreen extends StatefulWidget {
  const BorclanmaHesaplamaScreen({super.key});

  @override
  _BorclanmaHesaplamaScreenState createState() =>
      _BorclanmaHesaplamaScreenState();
}

class _BorclanmaHesaplamaScreenState extends State<BorclanmaHesaplamaScreen> {
  final TextEditingController _gunController = TextEditingController();

  Map<String, dynamic>? _hesaplamaSonucu;

  final double _asgariAylikGelir = 26005.50;
  final double _ustLimitGelir = 169035.75;
  final String _basvuruTarihi = '01.01.2025 - 31.12.2025';
  String? _secilenBorclanmaSuresi;

  final List<String> _borclanmaSureleri = [
    'Askerlik Borçlanması',
    'Ücretsiz Doğum veya Analık İzni Süreleri',
    'Aylıksız İzin Süreleri (4/c Kapsamında)',
    'Doktora veya Uzmanlık Eğitimi Süreleri',
    'Avukatlık Staj Süreleri',
    'Tutukluluk veya Gözaltı Süreleri',
    'Grev ve Lokavt Süreleri',
    'Hekimlerin Fahri Asistanlıkta Geçen Süreleri',
    'Seçim Kanunları Gereği Görevden Uzaklaşma Süreleri',
  ];

  final Map<String, IconData> _borclanmaIconMap = {
    'Askerlik Borçlanması': Icons.military_tech,
    'Ücretsiz Doğum veya Analık İzni Süreleri': Icons.child_care,
    'Aylıksız İzin Süreleri (4/c Kapsamında)': Icons.no_accounts,
    'Doktora veya Uzmanlık Eğitimi Süreleri': Icons.school,
    'Avukatlık Staj Süreleri': Icons.gavel,
    'Tutukluluk veya Gözaltı Süreleri': Icons.lock,
    'Grev ve Lokavt Süreleri': Icons.campaign,
    'Hekimlerin Fahri Asistanlıkta Geçen Süreleri': Icons.medical_information,
    'Seçim Kanunları Gereği Görevden Uzaklaşma Süreleri': Icons.how_to_vote,
  };

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
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
    _showHesaplamaSonucu();
  }

  void _showHesaplamaSonucu() {
    print("showHesaplamaSonucu çağrıldı");
    if (_secilenBorclanmaSuresi == null || _gunController.text.isEmpty) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase('lütfen tüm alanları eksiksiz doldurun!'),
          'detaylar': {},
          'ekBilgi': {
            'Kontrol Tarihi':
            DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Not': toTitleCase('eksik bilgileri tamamlayarak tekrar deneyin.'),
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
          'mesaj': toTitleCase('lütfen geçerli bir gün sayısı girin!'),
          'detaylar': {},
          'ekBilgi': {
            'Kontrol Tarihi':
            DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Not': toTitleCase('gün sayısı pozitif bir tam sayı olmalıdır.'),
          },
        };
      });
      _scrollToResult();
      return;
    }

    // Ek giriş doğrulama: Askerlik borçlanması için maksimum 720 gün
    if (_secilenBorclanmaSuresi == 'Askerlik Borçlanması' && gunSayisi > 720) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase(
              'askerlik borçlanması için gün sayısı 720\'yi aşamaz!'),
          'detaylar': {},
          'ekBilgi': {
            'Kontrol Tarihi':
            DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Not': toTitleCase(
                'askerlik borçlanması maksimum 720 gün olabilir.'),
          },
        };
      });
      _scrollToResult();
      return;
    }

    double gunlukAsgariUcret = _asgariAylikGelir / 30;
    double altLimitGunlukBedel = gunlukAsgariUcret * 0.32;
    double altLimit = gunSayisi * altLimitGunlukBedel;

    double gunlukUstLimitGelir = _ustLimitGelir / 30;
    double ustLimitGunlukBedel = gunlukUstLimitGelir * 0.32;
    double ustLimit = gunSayisi * ustLimitGunlukBedel;

    setState(() {
      _hesaplamaSonucu = {
        'basarili': true,
        'mesaj': toTitleCase('borçlanma hesaplaması başarıyla tamamlandı!'),
        'detaylar': {
          'Başvuru Tarihi': toTitleCase(_basvuruTarihi),
          'Borçlanılacak Gün Sayısı': toTitleCase('$gunSayisi gün'),
          'Borçlanma Alt Limiti': toTitleCase(
            '${formatSayi(altLimit)} (beyan edilen aylık gelir ${_formatSayi(_asgariAylikGelir)} tl)',
          ),
          'Borçlanma Üst Limiti': toTitleCase(
            '${formatSayi(ustLimit)} (beyan edilen aylık gelir ${_formatSayi(_ustLimitGelir)} tl)',
          ),
        },
        'ekBilgi': {
          'Kontrol Tarihi':
          DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          'Not': toTitleCase(
            '$_basvuruTarihi tarihleri arasında $gunSayisi gün borçlanması için en az ${formatSayi(altLimit)} en çok ${formatSayi(ustLimit)} prim ödeyebilirsiniz.',
          ),
        },
      };
      print("Hesaplama Sonucu: $_hesaplamaSonucu");
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
          onPressed: _hesapla,
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

  Widget _buildResultDetails(Map<String, String> detaylar) {
    final iconMap = {
      'Başvuru Tarihi': Icons.date_range,
      'Borçlanılacak Gün Sayısı': Icons.calendar_today,
      'Borçlanma Alt Limiti': Icons.price_change,
      'Borçlanma Üst Limiti': Icons.price_check,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Detaylar',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...detaylar.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(iconMap[entry.key] ?? Icons.info_outline,
                        color: Colors.indigo),
                    title: Text(
                      toTitleCase(entry.key),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      toTitleCase(entry.value),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (entry.key != detaylar.keys.last) const Divider(height: 1),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEkBilgiCard(Map<String, String> ekBilgi) {
    return Card(
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
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Uyarı yazıları buraya taşındı
            Row(
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
                    'Sosyal Güvenlik Mobil Resmi Bir Kurumun Uygulaması Değildir!',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
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
                    'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
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
                    'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mevcut ek bilgiler
            ...ekBilgi.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '${toTitleCase(entry.key)}: ${toTitleCase(entry.value)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.left,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_hesaplamaSonucu == null) return Container();

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
        const SizedBox(height: 12),
        if (detaylar.isNotEmpty) _buildResultDetails(detaylar),
        const SizedBox(height: 12),
        if (ekBilgi.isNotEmpty) _buildEkBilgiCard(ekBilgi),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borçlanma Hesaplama'),
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
                child: Container(
                  width: double.infinity, // Kart genişliğini tam yapar
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Başvuru Tarihi',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          toTitleCase(_basvuruTarihi),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Borçlanma Türünü Seçiniz',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.list, color: Colors.indigo),
                          border: OutlineInputBorder(),
                        ),
                        value: _secilenBorclanmaSuresi,
                        hint: const Text('Seçiniz'),
                        items: _borclanmaSureleri.map((e) {
                          final icon = _borclanmaIconMap[e] ?? Icons.info_outline;
                          return DropdownMenuItem(
                            value: e,
                            child: Row(
                              children: [
                                Icon(icon, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Flexible(child: Text(e)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _secilenBorclanmaSuresi = value),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Borçlanılacak Gün Sayısı',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _gunController,
                        decoration: const InputDecoration(
                          prefixIcon:
                          Icon(Icons.calendar_today, color: Colors.indigo),
                          border: OutlineInputBorder(),
                          hintText: 'Gün Sayısı',
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
              _buildHesaplaButtonCard(),
              const SizedBox(height: 20),
              _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gunController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}