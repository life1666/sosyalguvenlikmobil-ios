import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  runApp(const IsizlikMaasiApp());
}

class IsizlikMaasiApp extends StatelessWidget {
  const IsizlikMaasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İşsizlik Maaşı Hesaplama',
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
      home: const IsizlikMaasiScreen(),
    );
  }
}

class IsizlikMaasiScreen extends StatefulWidget {
  const IsizlikMaasiScreen({super.key});

  @override
  _IsizlikMaasiScreenState createState() => _IsizlikMaasiScreenState();
}

class _IsizlikMaasiScreenState extends State<IsizlikMaasiScreen> {
  String? hizmetAkdi;
  String? primGunAraligi;
  String? istenCikisKodu;
  String? _errorMessage;

  // Ücret girişleri için tek alanlı TextEditingController’lar
  final TextEditingController kazanc1 = TextEditingController();
  final TextEditingController kazanc2 = TextEditingController();
  final TextEditingController kazanc3 = TextEditingController();
  final TextEditingController kazanc4 = TextEditingController();

  Map<String, dynamic>? _hesaplamaSonucu;

  // Sonuç ekranına kaydırmak için ScrollController ve GlobalKey
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  // 2025 yılına ait sabitler
  final double asgariUcretBrut = 26005;
  final double maxOran = 0.80;
  final double damgaVergisiOrani = 0.00759;
  final double tabanMaas = 10402.20;
  final double tavanMaas = 20804.40;
  final double aylikAsgariBrut = 20002.50;

  final List<String> issizlikMaasiHakKazanilanKodlar = [
    '4', '5', '12', '15', '17', '18', '23', '24', '25', '27', '28', '31', '32', '33', '34', '40'
  ];

  final Map<String, String> istenCikisKodlari = {
    '1': 'Deneme Süreli İş Sözleşmesinin İşverence Feshi',
    '2': 'Deneme Süreli İş Sözleşmesinin İşçi Tarafından Feshi',
    '3': 'Belirsiz Süreli İş Sözleşmesinin İşçi Tarafından Feshi (İstifa)',
    '4': 'Belirsiz Süreli İş Sözleşmesinin İşveren Tarafından Haklı Sebep Bildirilmeden Feshi',
    '5': 'Belirli Süreli İş Sözleşmesinin Sona Ermesi',
    '8': 'Emeklilik (yaşlılık) veya Toptan Ödeme Nedeniyle',
    '9': 'Malulen Emeklilik Nedeniyle',
    '10': 'Ölüm',
    '11': 'İş Kazası Sonucu Ölüm',
    '12': 'Askerlik',
    '13': 'Kadın İşçinin Evlenmesi',
    '14': 'Emeklilik İçin Yaş Dışında Diğer Şartların Tamamlanması',
    '15': 'Toplu İşçi Çıkarma',
    '16': 'Sözleşme Sona Ermeden Sigortalının Aynı İşverene Ait Diğer İşyerine Nakli',
    '17': 'İşyerinin Kapanması',
    '18': 'İşin Sona Ermesi',
    '19': 'Mevsim Bitimi',
    '20': 'Kampanya Bitimi',
    '21': 'Statü Değişikliği',
    '22': 'Diğer Nedenler',
    '23': 'İşçi Tarafından Zorunlu Nedenle Fesih',
    '24': 'İşçi Tarafından Sağlık Nedeniyle Fesih',
    '25': 'İşçi Tarafından İşverenin Ahlak ve İyiniyet Kurallarına Aykırı Davranışı Nedeni ile Fesih',
    '26': 'Disiplin Kurulu Kararı Nedeni ile Fesih',
    '27': 'İşveren Tarafından Zorunlu Nedenlerle ve Tutukluluk Nedeniyle Fesih',
    '28': 'İşveren Tarafından Sağlık Nedeni ile Fesih)',
    '29': 'İşveren Tarafından İşçinin Ahlak ve İyiniyet Kurallarına Aykırı Davranışı Nedeni ile Fesih',
    '30': 'Vize Süresinin Bitimi',
    '31': 'Borçlar Kanunu, Sendikalar Kanunu, Grev Ve Lokavt Kanunu Gereği Fesih',
    '32': '4046 Sayılı Kanun Kapsamında Özelleştirme Nedeniyle Fesih',
    '33': 'Gazeteci Tarafından Sözleşmenin Feshi',
    '34': 'İşyerinin Devri veya Niteliğinin Değişmesi Nedeniyle Fesih',
    '35': '6495 Sayılı Kanun Nedeniyle Devlet Memurluğuna Geçenler',
    '36': 'KHK ile İşyerinin Kapatılması',
    '37': 'KHK ile Kamu Görevinden Çıkarma',
    '38': 'Doğum Nedeniyle İşten Ayrılma',
    '39': '696 KHK İle Kamu İşçisi Kadrosuna Geçiş',
    '40': '696 KHK İle Kamu İşçiliğine Geçilememesi Sebebiyle Çıkış',
    '41': 'Resen İşten Ayrılış Bildirgesi Düzenlenenler',
    '42': '4857 Sayılı Kanun Madde 25-II-a',
    '43': '4857 Sayılı Kanun Madde 25-II-b',
    '44': '4857 Sayılı Kanun Madde 25-II-c',
    '45': '4857 Sayılı Kanun Madde 25-II-d',
    '46': '4857 Sayılı Kanun Madde 25-II-e',
    '47': '4857 Sayılı Kanun Madde 25-II-f',
    '48': '4857 Sayılı Kanun Madde 25-II-g',
    '49': '4857 Sayılı Kanun Madde 25-II-h',
    '50': '4857 Sayılı Kanun Madde 25-II-ı',
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
  }

  @override
  void dispose() {
    kazanc1.dispose();
    kazanc2.dispose();
    kazanc3.dispose();
    kazanc4.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Rapor parası uygulamasındaki sayı formatlayıcısı
  String formatSayi(double sayi) {
    final formatter = NumberFormat("#,##0.00", "tr_TR");
    String formatted = formatter.format(sayi);
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
    return "$formatted TL";
  }

  double parseSayi(String input) {
    String normalized = input.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  void _hesapla() {
    _showHesaplamaSonucu();
  }

  void _showHesaplamaSonucu() {
    print("showHesaplamaSonucu çağrıldı");

    // Giriş doğrulama
    if (hizmetAkdi == null || primGunAraligi == null || istenCikisKodu == null) {
      setState(() {
        _hesaplamaSonucu = null;
        _errorMessage = 'Lütfen tüm seçimleri (işten çıkış kodu, hizmet akdi, prim gün aralığı) yapınız!';
      });
      _scrollToResult();
      return;
    }

    if (!issizlikMaasiHakKazanilanKodlar.contains(istenCikisKodu)) {
      setState(() {
        _hesaplamaSonucu = null;
        _errorMessage = 'Seçilen işten çıkış kodu işsizlik maaşı için uygun değil!';
      });
      _scrollToResult();
      return;
    }

    if (hizmetAkdi == "Hayır") {
      setState(() {
        _hesaplamaSonucu = null;
        _errorMessage = 'Son 120 gün hizmet akdi şartı sağlanmıyor!';
      });
      _scrollToResult();
      return;
    }

    if (primGunAraligi == "600 günden az") {
      setState(() {
        _hesaplamaSonucu = null;
        _errorMessage = 'Son 3 yılda en az 600 gün prim gerekli!';
      });
      _scrollToResult();
      return;
    }

    if (kazanc1.text.trim().isEmpty &&
        kazanc2.text.trim().isEmpty &&
        kazanc3.text.trim().isEmpty &&
        kazanc4.text.trim().isEmpty) {
      setState(() {
        _hesaplamaSonucu = null;
        _errorMessage = 'Lütfen son 4 aylık brüt kazançlarınızı giriniz!';
      });
      _scrollToResult();
      return;
    }

    List<String> eksikAylar = [];
    double k1 = parseSayi(kazanc1.text);
    double k2 = parseSayi(kazanc2.text);
    double k3 = parseSayi(kazanc3.text);
    double k4 = parseSayi(kazanc4.text);

    if (k1 > 0 && k1 < aylikAsgariBrut) eksikAylar.add("1. Ay");
    if (k2 > 0 && k2 < aylikAsgariBrut) eksikAylar.add("2. Ay");
    if (k3 > 0 && k3 < aylikAsgariBrut) eksikAylar.add("3. Ay");
    if (k4 > 0 && k4 < aylikAsgariBrut) eksikAylar.add("4. Ay");

    if (eksikAylar.isNotEmpty) {
      setState(() {
        _hesaplamaSonucu = null;
        _errorMessage = 'Brüt kazançlar asgari ücretin (${formatSayi(aylikAsgariBrut)}) altında olamaz: ${eksikAylar.join(", ")}';
      });
      _scrollToResult();
      return;
    }

    hesaplaIsizlikMaasi();
  }

  void hesaplaIsizlikMaasi() {
    int hakEdilenGun;
    if (primGunAraligi == "1080 gün ve üzeri") {
      hakEdilenGun = 300;
    } else if (primGunAraligi == "900 - 1079 gün") {
      hakEdilenGun = 240;
    } else {
      hakEdilenGun = 180;
    }

    double k1 = parseSayi(kazanc1.text);
    double k2 = parseSayi(kazanc2.text);
    double k3 = parseSayi(kazanc3.text);
    double k4 = parseSayi(kazanc4.text);

    double toplamKazanc = k1 + k2 + k3 + k4;
    double gunlukBrutKazanc = toplamKazanc / 120;
    double isizlikBrutMaasi = gunlukBrutKazanc * 30 * 0.40;
    double maxBrutMaas = asgariUcretBrut * maxOran;

    if (isizlikBrutMaasi > maxBrutMaas) {
      isizlikBrutMaasi = maxBrutMaas;
    }

    double damgaVergisi = isizlikBrutMaasi * damgaVergisiOrani;
    double netIsizlikMaasi = isizlikBrutMaasi - damgaVergisi;

    setState(() {
      _hesaplamaSonucu = {
        'basarili': true,
        'mesaj': 'Hesaplama Başarıyla Tamamlandı!',
        'detaylar': {
          'Hak Kazanılan Süre': '${(hakEdilenGun / 30).toStringAsFixed(0)} Ay ($hakEdilenGun Gün)',
          'Günlük Brüt Kazanç': formatSayi(gunlukBrutKazanc),
          'Aylık Brüt İşsizlik Maaşı': formatSayi(isizlikBrutMaasi),
          'Damga Vergisi Kesintisi': formatSayi(damgaVergisi),
          'Aylık Net İşsizlik Maaşı': formatSayi(netIsizlikMaasi),
        },
        'ekBilgi': {
          'Kontrol Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          'Not': istenCikisKodu == '12'
              ? 'Askerlikten Sonra Alınabilir.'
              : 'Hesaplama 2025 Yılı Verilerine Göre Yapılmıştır.',
          '2025 Yılı Taban Brüt Ücret': formatSayi(tabanMaas),
          '2025 Yılı Tavan Brüt Ücret': formatSayi(tavanMaas),
        },
      };
      _errorMessage = 'Hesaplama başarıyla tamamlandı!';
      print("Hesaplama Sonucu: ${_hesaplamaSonucu!['detaylar']}");
    });
    _scrollToResult();
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildAmountField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Brüt Ücret',
            suffix: Text('TL', style: TextStyle(color: Colors.indigo, fontSize: 14)),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            CustomCurrencyFormatter(),
            LengthLimitingTextInputFormatter(15),
          ],
        ),
      ],
    );
  }

  TextStyle get _labelStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.indigo,
  );

  Widget _buildResultSection() {
    if (_errorMessage == null && _hesaplamaSonucu == null) return Container();

    bool basarili = _hesaplamaSonucu?['basarili'] ?? false;
    String mesaj = _errorMessage ?? _hesaplamaSonucu?['mesaj'] ?? 'Hesaplama yapılamadı!';
    Map<String, String> detaylar = {};
    if (_hesaplamaSonucu != null && _hesaplamaSonucu!['detaylar'] != null) {
      detaylar = Map<String, String>.from(_hesaplamaSonucu!['detaylar']);
    }
    Map<String, String> ekBilgi = {};
    if (_hesaplamaSonucu != null && _hesaplamaSonucu!['ekBilgi'] != null) {
      ekBilgi = Map<String, String>.from(_hesaplamaSonucu!['ekBilgi']);
    }

    return Column(
      key: _resultKey,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  mesaj,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: basarili ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (basarili && detaylar.isNotEmpty) _buildResultDetails(detaylar),
        const SizedBox(height: 6),
        if (ekBilgi.isNotEmpty) _buildEkBilgiCard(ekBilgi),
      ],
    );
  }

  Widget _buildResultDetails(Map<String, String> detaylar) {
    final iconMap = {
      'Hak Kazanılan Süre': Icons.calendar_today,
      'Günlük Brüt Kazanç': Icons.account_balance_wallet,
      'Aylık Brüt İşsizlik Maaşı': Icons.account_balance_wallet,
      'Damga Vergisi Kesintisi': Icons.money_off,
      'Aylık Net İşsizlik Maaşı': Icons.account_balance_wallet,
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
              return Column(
                children: [
                  ListTile(
                    leading: Icon(iconMap[entry.key] ?? Icons.info_outline, color: Colors.indigo, size: 18),
                    title: Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
    // Kartı her zaman gösteriyoruz, çünkü sabit mesajlar var
    final List<String> orderedKeys = [
      'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!',
      'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!',
      'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!',
      'Kontrol Tarihi',
      'Not',
      '2025 Yılı Taban Brüt Ücret',
      '2025 Yılı Tavan Brüt Ücret'
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 4),
            ...orderedKeys.map((key) {
              // "Kontrol Tarihi", "Not", "2025 Yılı Taban Brüt Ücret" ve "2025 Yılı Tavan Brüt Ücret" için dinamik veri gösteriyoruz
              if (key == 'Kontrol Tarihi' ||
                  key == 'Not' ||
                  key == '2025 Yılı Taban Brüt Ücret' ||
                  key == '2025 Yılı Tavan Brüt Ücret') {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '$key: ${ekBilgi[key] ?? ''}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşsizlik Maaşı Hesaplama'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlk Kart: İşten Çıkış Kodunuz
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('İşten Çıkış Kodunuz', style: _labelStyle),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: istenCikisKodu,
                      hint: const Text('Seçiniz'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.work, color: Colors.indigo),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      items: istenCikisKodlari.entries
                          .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          '${entry.key} - ${entry.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => istenCikisKodu = value),
                    ),
                  ],
                ),
              ),
            ),

            // İkinci Kart: Son 120 Gün Hizmet Akdi ile Çalıştınız mı ?
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Son 120 Gün Hizmet Akdi ile Çalıştınız mı ?', style: _labelStyle),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: hizmetAkdi,
                      hint: const Text('Seçiniz'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.indigo),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'Evet',
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.indigo, size: 18),
                              SizedBox(width: 8),
                              Text('Evet'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Hayır',
                          child: Row(
                            children: const [
                              Icon(Icons.cancel, color: Colors.indigo, size: 18),
                              SizedBox(width: 8),
                              Text('Hayır'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => hizmetAkdi = value),
                    ),
                  ],
                ),
              ),
            ),

            // Üçüncü Kart: Son 3 Yıldaki Toplam Prim Gün Sayınız
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Son 3 Yıldaki Toplam Prim Gün Sayınız', style: _labelStyle),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: primGunAraligi,
                      hint: const Text('Seçiniz'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.date_range, color: Colors.indigo),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      items: [
                        '600 günden az',
                        '600 - 899 gün',
                        '900 - 1079 gün',
                        '1080 gün ve üzeri'
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (value) => setState(() => primGunAraligi = value),
                    ),
                  ],
                ),
              ),
            ),

            // Dördüncü Kart: Son 4 Aylık Brüt Kazançlarınız
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Son 4 Aylık Brüt Kazançlarınız', style: _labelStyle),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildAmountField('1. Ay', kazanc1)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildAmountField('2. Ay', kazanc2)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildAmountField('3. Ay', kazanc3)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildAmountField('4. Ay', kazanc4)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildHesaplaButton(),
            const SizedBox(height: 20),

            // Sonuç Kartı
            if (_hesaplamaSonucu != null || _errorMessage != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }
}

class CustomCurrencyFormatter extends TextInputFormatter {
  final NumberFormat integerFormat = NumberFormat.decimalPattern('tr_TR');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');
    if (digitsOnly.length < 5) {
      return newValue.copyWith(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    }
    String integerPart = digitsOnly.substring(0, digitsOnly.length - 2);
    String fractionalPart = digitsOnly.substring(digitsOnly.length - 2);
    String formattedInteger = integerFormat.format(int.parse(integerPart));
    String newText = '$formattedInteger,$fractionalPart';
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}