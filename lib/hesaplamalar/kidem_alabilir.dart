import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const KidemTazminatiApp());
}

/// Girilen metni title case'e çevirir (her sözcüğün ilk harfi büyük).
String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

/// Olumsuz senaryoda kullanılacak özel dönüşüm: Her kelimenin ilk harfi büyük olacak,
/// fakat "veya" kelimesi tamamen küçük olarak kalacaktır.
String customTitleCase(String text) {
  return text.split(' ').map((word) {
    if (word.toLowerCase() == 'veya') {
      return 'veya';
    }
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

class KidemTazminatiApp extends StatelessWidget {
  const KidemTazminatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kıdem Tazminatı Kontrol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      home: const KidemTazminatiScreen(),
    );
  }
}

class KidemTazminatiScreen extends StatefulWidget {
  const KidemTazminatiScreen({super.key});

  @override
  _KidemTazminatiScreenState createState() => _KidemTazminatiScreenState();
}

class _KidemTazminatiScreenState extends State<KidemTazminatiScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  DateTime? sigortaBaslangicTarihi;

  int? primGunSayisi;
  int? calismaYil;

  Map<String, dynamic>? hesaplamaSonucu;
  String? _errorMessage;

  final List<String> aylar = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Tarih seçim kartı
  Widget _buildDateSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sigorta Başlangıç Tarihi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Gün seçimi
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Gün',
                      hintText: 'Gün',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedDay,
                    items: List.generate(31, (index) => index + 1)
                        .map((g) => DropdownMenuItem(
                      value: g,
                      child: Center(child: Text(g.toString())),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedDay = value),
                    validator: (value) => value == null ? 'Gün seçin' : null,
                  ),
                ),
                const SizedBox(width: 10),
                // Ay seçimi
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ay',
                      hintText: 'Ay',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedMonth != null ? aylar[_selectedMonth! - 1] : null,
                    items: aylar
                        .map((ay) => DropdownMenuItem(
                      value: ay,
                      child: Center(child: Text(ay)),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedMonth = aylar.indexOf(value!) + 1),
                    validator: (value) => value == null ? 'Ay seçin' : null,
                  ),
                ),
                const SizedBox(width: 10),
                // Yıl seçimi
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Yıl',
                      hintText: 'Yıl',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedYear,
                    items: List.generate(DateTime.now().year - 1990 + 1, (index) => 1990 + index)
                        .map((y) => DropdownMenuItem(
                      value: y,
                      child: Center(child: Text(y.toString())),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedYear = value),
                    validator: (value) => value == null ? 'Yıl seçin' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sayısal giriş kartı
  Widget _buildTextFieldCard({
    required String label,
    required String hint,
    required IconData icon,
    required Function(String?) onSaved,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.indigo),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onSaved: onSaved,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Lütfen $label girin';
            int? parsedValue = int.tryParse(value);
            if (parsedValue == null) return 'Geçerli bir sayı girin';
            if (parsedValue <= 0) return '$label sıfır veya negatif olamaz';
            return null;
          },
        ),
      ),
    );
  }

  /// Kıdem tazminatı hesaplama fonksiyonu
  Map<String, dynamic> kidemTazminatiHesapla(DateTime baslangic, int primGun, int calismaYil) {
    final int gunFarki = DateTime.now().difference(baslangic).inDays;
    final int yilFarki = gunFarki ~/ 365;

    if (gunFarki < primGun) {
      return {
        'hakKazandi': false,
        'mesaj': 'Hesaplama hatası: Başlangıç tarihi ile güncel tarih arasındaki gün farkı, girilen prim gün sayısından az!',
        'detaylar': {},
        'ekBilgi': {'Kontrol Tarihi': DateFormat('dd/MM/yyyy').format(DateTime.now())},
      };
    }

    bool cSigortalilik = false;
    bool cPrim = false;
    bool cCalisma = false;

    String sigortalilikDetay = '';
    String primDetay = '';
    String calismaDetay = '';
    String finalMsg = '';

    // ---- 08.09.1999 öncesi ----
    if (baslangic.isBefore(DateTime(1999, 9, 8))) {
      int neededYear = 15;
      int neededPrim = 3600;
      int neededCalisma = 1;

      if (yilFarki >= neededYear) {
        cSigortalilik = true;
        sigortalilikDetay = 'Gerçekleşen Süre: $yilFarki yıl, Gerekli Süre: $neededYear yıl\nDurum: Tamamlandı ✅';
      } else {
        int eksik = neededYear - yilFarki;
        sigortalilikDetay = 'Gerçekleşen Süre: $yilFarki yıl, Gerekli Süre: $neededYear yıl\nDurum: Eksik ($eksik yıl ❌)';
      }

      if (primGun >= neededPrim) {
        cPrim = true;
        primDetay = 'Gerçekleşen P.G.S: $primGun gün, Gerekli P.G.S: $neededPrim gün\nDurum: Tamamlandı ✅';
      } else {
        int eksik = neededPrim - primGun;
        primDetay = 'Gerçekleşen P.G.S: $primGun gün, Gerekli P.G.S: $neededPrim gün\nDurum: Eksik ($eksik gün ❌)';
      }

      if (calismaYil >= neededCalisma) {
        cCalisma = true;
        calismaDetay = 'Gerçekleşen Süre: $calismaYil yıl, Gerekli Süre: $neededCalisma yıl\nDurum: Tamamlandı ✅';
      } else {
        int eksik = neededCalisma - calismaYil;
        calismaDetay = 'Gerçekleşen Süre: $calismaYil yıl, Gerekli Süre: $neededCalisma yıl\nDurum: Eksik ($eksik yıl ❌)';
      }

      if (cSigortalilik && cPrim && cCalisma) {
        finalMsg = 'Kıdem Tazminatı Almaya Bu Koşullarda Hak Kazanabiliyorsunuz.';
      } else {
        finalMsg = 'Kıdem Tazminatı Almaya Bu Koşullarda Hak Kazanamıyorsunuz.';
      }
    }
    // ---- 08.09.1999 sonrası, 01.05.2008 öncesi ----
    else if (baslangic.isAfter(DateTime(1999, 9, 7)) && baslangic.isBefore(DateTime(2008, 5, 1))) {
      int neededYear = 25;
      if (yilFarki >= neededYear) {
        cSigortalilik = true;
        sigortalilikDetay = 'Gerçekleşen Süre: $yilFarki yıl, Gerekli Süre: $neededYear yıl\nDurum: Tamamlandı ✅';
      } else {
        int eksik = neededYear - yilFarki;
        sigortalilikDetay = 'Gerçekleşen Süre: $yilFarki yıl, Gerekli Süre: $neededYear yıl\nDurum: Eksik ($eksik yıl ❌)';
      }

      bool cPrim4500 = (primGun >= 4500);
      bool cPrim7000 = (primGun >= 7000);
      if (cPrim4500 || cPrim7000) {
        cPrim = true;
        primDetay = 'Gerçekleşen P.G.S: $primGun gün, Gerekli P.G.S: 4500 veya 7000 gün\nDurum: Tamamlandı ✅';
      } else {
        int eksik4500 = (primGun < 4500) ? (4500 - primGun) : 0;
        primDetay = 'Gerçekleşen P.G.S: $primGun gün, Gerekli: 4500 veya 7000\nDurum: Eksik ($eksik4500 gün ❌)';
      }

      if (calismaYil >= 1) {
        cCalisma = true;
        calismaDetay = 'Gerçekleşen Süre: $calismaYil yıl, Gerekli Süre: 1 yıl\nDurum: Tamamlandı ✅';
      } else {
        int eksik = 1 - calismaYil;
        calismaDetay = 'Gerçekleşen Süre: $calismaYil yıl, Gerekli Süre: 1 yıl\nDurum: Eksik ($eksik yıl ❌)';
      }

      bool finalCondition = ((cPrim4500 && cSigortalilik) || cPrim7000) && cCalisma;
      if (finalCondition) {
        finalMsg = 'Kıdem Tazminatı Almaya Bu Koşullarda Hak Kazanabiliyorsunuz.';
      } else {
        finalMsg = 'Kıdem Tazminatı Almaya Bu Koşullarda Hak Kazanamıyorsunuz.';
      }
    }
    // ---- 01.05.2008 sonrası ----
    else {
      int gerekenPrimGun = 0;
      final int year = baslangic.year;
      if (year < 2009) {
        gerekenPrimGun = 4600;
      } else if (year < 2010) {
        gerekenPrimGun = 4700;
      } else if (year < 2011) {
        gerekenPrimGun = 4800;
      } else if (year < 2012) {
        gerekenPrimGun = 4900;
      } else if (year < 2013) {
        gerekenPrimGun = 5000;
      } else if (year < 2014) {
        gerekenPrimGun = 5100;
      } else if (year < 2015) {
        gerekenPrimGun = 5200;
      } else if (year < 2016) {
        gerekenPrimGun = 5300;
      } else {
        gerekenPrimGun = 5400;
      }

      if (primGun >= gerekenPrimGun) {
        cPrim = true;
        primDetay = 'Gerçekleşen P.G.S: $primGun gün, Gerekli P.G.S: $gerekenPrimGun gün\nDurum: Tamamlandı ✅';
      } else {
        int eksik = gerekenPrimGun - primGun;
        primDetay = 'Gerçekleşen P.G.S: $primGun gün, Gerekli P.G.S: $gerekenPrimGun gün\nDurum: Eksik ($eksik gün ❌)';
      }

      if (calismaYil >= 1) {
        cCalisma = true;
        calismaDetay = 'Gerçekleşen Süre: $calismaYil yıl, Gerekli Süre: 1 yıl\nDurum: Tamamlandı ✅';
      } else {
        int eksik = 1 - calismaYil;
        calismaDetay = 'Gerçekleşen Süre: $calismaYil yıl, Gerekli Süre: 1 yıl\nDurum: Eksik ($eksik yıl ❌)';
      }

      sigortalilikDetay = '01.05.2008 sonrası: Sigortalılık süresi ayrı değerlendirilmiyor.';

      if (cPrim && cCalisma) {
        finalMsg = 'Kıdem Tazminatı Almaya Bu Koşullarda Hak Kazanabiliyorsunuz.';
      } else {
        finalMsg = 'Kıdem Tazminatı Almaya Bu Koşullarda Hak Kazanamıyorsunuz.';
      }
    }

    final Map<String, String> detayMap = {};
    if (baslangic.isBefore(DateTime(2008, 5, 1))) {
      detayMap['Sigortalılık Süresi'] = sigortalilikDetay;
      detayMap['Prim Gün Sayısı'] = primDetay;
      detayMap['Son İş Yerinde Çalışma Süresi'] = calismaDetay;
    } else {
      if (sigortalilikDetay.isNotEmpty && !sigortalilikDetay.contains('ayrı değerlendirilmiyor')) {
        detayMap['Sigortalılık Süresi'] = sigortalilikDetay;
      }
      detayMap['Prim Gün Sayısı'] = primDetay;
      detayMap['Son İş Yerinde Çalışma Süresi'] = calismaDetay;
    }

    return {
      'hakKazandi': finalMsg.contains('Hak Kazanabiliyorsunuz'),
      'mesaj': finalMsg,
      'detaylar': detayMap,
      'ekBilgi': {
        'Kontrol Tarihi': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'Not': finalMsg.contains('Kazanabiliyorsunuz')
            ? toTitleCase('Kıdem tazminatına esas yazı İçin SGK’ya başvurabilirsiniz.')
            : customTitleCase('Belirtilen eksik şart veya şartların tamamlanması halinde kıdem tazminatı almaya hak kazanabilirisiniz.')
      },
    };
  }

  void _kontrolEt() {
    _showHesaplamaSonucu();
  }

  void _showHesaplamaSonucu() {
    print("showHesaplamaSonucu çağrıldı");

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Lütfen tüm alanları eksiksiz ve doğru doldurun!';
        hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    _formKey.currentState!.save();

    if (_selectedDay == null || _selectedMonth == null || _selectedYear == null) {
      setState(() {
        _errorMessage = 'Lütfen gün, ay ve yılı eksiksiz seçin!';
        hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    sigortaBaslangicTarihi = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);

    if (primGunSayisi == null || primGunSayisi! <= 0) {
      setState(() {
        _errorMessage = 'Prim gün sayısı sıfır veya negatif olamaz!';
        hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    if (calismaYil == null || calismaYil! <= 0) {
      setState(() {
        _errorMessage = 'Son iş yerinde çalışma yılı sıfır veya negatif olamaz!';
        hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    if (sigortaBaslangicTarihi!.isAfter(DateTime.now())) {
      setState(() {
        _errorMessage = 'Sigorta başlangıç tarihi gelecekte olamaz!';
        hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    setState(() {
      hesaplamaSonucu = kidemTazminatiHesapla(
        sigortaBaslangicTarihi!,
        primGunSayisi!,
        calismaYil!,
      );
      _errorMessage = hesaplamaSonucu!['hakKazandi']
          ? 'Hesaplama başarıyla tamamlandı!'
          : hesaplamaSonucu!['mesaj'];
      print("Hesaplama Sonucu: ${hesaplamaSonucu!['detaylar']}");
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

  /// Detaylar kartı
  Widget _buildResultDetails(Map<String, String> detaylar) {
    final iconMap = {
      'Sigortalılık Süresi': Icons.access_time,
      'Prim Gün Sayısı': Icons.work,
      'Son İş Yerinde Çalışma Süresi': Icons.business_center,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...detaylar.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(iconMap[entry.key] ?? Icons.info_outline, color: Colors.indigo),
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(entry.value, style: const TextStyle(fontSize: 16)),
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

  /// Ek Bilgi kartı
  Widget _buildEkBilgiCard(Map<String, String> ekBilgi) {
    // Kartı her zaman gösteriyoruz, çünkü sabit mesajlar var
    final List<String> orderedKeys = [
      'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!',
      'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!',
      'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!',
      'Kontrol Tarihi',
      'Not'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Ek Bilgiler',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...orderedKeys.map((key) {
              // "Kontrol Tarihi" ve "Not" için dinamik veri gösteriyoruz
              if (key == 'Kontrol Tarihi' || key == 'Not') {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '$key: ${ekBilgi[key] ?? ''}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.left,
                  ),
                );
              }
              // Diğer sabit mesajlar için ikon ve kırmızı metin gösteriyoruz
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
                      key,
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
          ],
        ),
      ),
    );
  }

  /// Sonuç bölümünü oluşturur
  Widget _buildResultSection() {
    if (_errorMessage == null && hesaplamaSonucu == null) return Container();

    bool basarili = hesaplamaSonucu?['hakKazandi'] ?? false;
    String mesaj = _errorMessage ?? hesaplamaSonucu?['mesaj'] ?? 'Hesaplama yapılamadı!';
    Map<String, String> detaylar = {};
    if (hesaplamaSonucu != null && hesaplamaSonucu!['detaylar'] != null) {
      detaylar = Map<String, String>.from(hesaplamaSonucu!['detaylar']);
    }
    Map<String, String> ekBilgi = {};
    if (hesaplamaSonucu != null && hesaplamaSonucu!['ekBilgi'] != null) {
      ekBilgi = Map<String, String>.from(hesaplamaSonucu!['ekBilgi']);
    }

    final String formattedMessage = toTitleCase(mesaj);

    return Column(
      key: _resultKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              formattedMessage,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: basarili ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (detaylar.isNotEmpty) _buildResultDetails(detaylar),
        if (ekBilgi.isNotEmpty) _buildEkBilgiCard(ekBilgi),
      ],
    );
  }

  /// "Kontrol Et" butonu tasarımı
  Widget _buildKontrolEtButtonCard() {
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
          onPressed: _kontrolEt,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            'Kontrol Et',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kıdem Tazminatı Kontrol'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateSelectionCard(),
                _buildTextFieldCard(
                  label: 'Prim Gün Sayısı',
                  hint: '',
                  icon: Icons.work,
                  onSaved: (value) => primGunSayisi = int.parse(value!),
                ),
                _buildTextFieldCard(
                  label: 'Son İş Yerinde Çalışma Yılı',
                  hint: '',
                  icon: Icons.work_history,
                  onSaved: (value) => calismaYil = int.parse(value!),
                ),
                const SizedBox(height: 8),
                _buildKontrolEtButtonCard(),
                const SizedBox(height: 20),
                _buildResultSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KidemAlabilirScreen extends StatelessWidget {
  const KidemAlabilirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const KidemTazminatiScreen();
  }
}