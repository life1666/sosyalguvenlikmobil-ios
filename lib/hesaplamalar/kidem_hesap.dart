import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const CompensationApp());
}

class CompensationApp extends StatelessWidget {
  const CompensationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kıdem ve İhbar Tazminatı Hesaplama',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 14, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 12, color: Colors.black54),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
      home: const CompensationCalculatorScreen(),
    );
  }
}

class CompensationCalculatorScreen extends StatefulWidget {
  const CompensationCalculatorScreen({super.key});

  @override
  _CompensationCalculatorScreenState createState() =>
      _CompensationCalculatorScreenState();
}

class _CompensationCalculatorScreenState
    extends State<CompensationCalculatorScreen> {
  String? selectedExitCode;
  String? startGun;
  String? startAy;
  String? startYil;
  String? endGun;
  String? endAy;
  String? endYil;
  final TextEditingController grossSalaryController = TextEditingController();

  Map<String, dynamic>? _hesaplamaSonucu;
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

  final Map<String, String> exitCodes = {
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

  final GlobalKey _resultKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    grossSalaryController.dispose();
    super.dispose();
  }

  /// Tavan ücreti hesaplama
  double getTavanUcreti(DateTime exitDate) {
    final year = exitDate.year;
    final month = exitDate.month;

    if (year < 2020) {
      return 6379.86;
    }

    if (year == 2020) {
      return month < 7 ? 6379.86 : 6730.15;
    }

    if (year == 2021) {
      return month < 7 ? 7117.17 : 8284.51;
    }

    if (year == 2022) {
      return month < 7 ? 10848.59 : 15371.40;
    }

    if (year == 2023) {
      return month < 7 ? 19982.31 : 23489.83;
    }

    if (year == 2024) {
      return month < 7 ? 35058.58 : 41828.42;
    }

    if (year == 2025) {
      return month < 7 ? 46655.43 : 53919.68;
    }

    return 53919.68;
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

  double parseSayi(String input) {
    String normalized = input.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  Map<String, dynamic> calculateSeverancePay(
      double salary, DateTime start, DateTime end) {
    double ceiling = getTavanUcreti(end);
    int daysWorked = end.difference(start).inDays + 1;
    double dailySalary = salary / 365;
    double severancePay = dailySalary * daysWorked;

    bool exceedsCeiling = dailySalary > ceiling / 365;
    if (exceedsCeiling) {
      severancePay = (ceiling / 365) * daysWorked;
    }

    double stampTax = severancePay * 0.00759;
    double netSeverancePay = severancePay - stampTax;

    return {
      'brut': severancePay,
      'net': netSeverancePay,
      'stampTax': stampTax,
      'daysWorked': daysWorked,
      'exceedsCeiling': exceedsCeiling,
    };
  }

  Map<String, double> calculateNoticePay(
      double salary, DateTime start, DateTime end) {
    int daysWorked = end.difference(start).inDays + 1;
    int noticeDays;

    if (daysWorked < 180) {
      noticeDays = 14;
    } else if (daysWorked < 540) {
      noticeDays = 28;
    } else if (daysWorked < 1095) {
      noticeDays = 42;
    } else {
      noticeDays = 56;
    }

    double dailySalary = salary / 30;
    double noticePay = dailySalary * noticeDays;

    double incomeTax;
    if (noticePay <= 158000) {
      incomeTax = noticePay * 0.15;
    } else if (noticePay <= 330000) {
      incomeTax = noticePay * 0.20;
    } else if (noticePay <= 800000) {
      incomeTax = noticePay * 0.27;
    } else {
      incomeTax = noticePay * 0.35;
    }

    double stampTax = noticePay * 0.00759;
    double netNoticePay = noticePay - incomeTax - stampTax;

    return {
      'brut': noticePay,
      'net': netNoticePay,
      'incomeTax': incomeTax,
      'stampTax': stampTax,
    };
  }

  bool isEligibleForNotice(String code) {
    return ['4', '15', '17', '18', '31', '32', '34', '40'].contains(code);
  }

  bool isEligibleForSeverance(String code) {
    return [
      '4', '5', '8', '9', '10', '11', '12', '13', '14', '15', '17',
      '18', '19', '20', '23', '24', '25', '31', '32', '33', '34',
      '35', '36', '39', '40'
    ].contains(code);
  }

  void _calculateCompensation() {
    _showHesaplamaSonucu();
  }

  void _showHesaplamaSonucu() {
    print("showHesaplamaSonucu çağrıldı");

    // Çıkış kodu kontrolü
    if (selectedExitCode == null) {
      setState(() {
        _errorMessage = '❌ Hata: İşten çıkış kodu seçiniz!';
        _hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    // Çıkış kodu uygun değilse
    if (!isEligibleForSeverance(selectedExitCode!) &&
        !isEligibleForNotice(selectedExitCode!)) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj':
          'Bu Şartlar Altında Kıdem Tazminatına Hak Kazanamıyorsunuz.',
          'detaylar': {
            'İşten Çıkış':
            '$selectedExitCode - ${exitCodes[selectedExitCode]}',
            'Kıdem Tazminatı': 'Hak Kazanılmadı.',
            'İhbar Tazminatı': 'Hak Kazanılmadı.',
          },
          'ekBilgi': {
            'Not':
            'İşten Çıkış Kodundan Dolayı Kıdem Ve İhbar Tazminatına Hak Kazanamıyorsunuz.',
            'Kontrol Tarihi':
            DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          },
        };
        _errorMessage = _hesaplamaSonucu!['mesaj'];
      });
      _scrollToResult();
      return;
    }

    // Diğer alanların kontrolü
    if (startGun == null ||
        startAy == null ||
        startYil == null ||
        endGun == null ||
        endAy == null ||
        endYil == null ||
        grossSalaryController.text.isEmpty) {
      setState(() {
        _errorMessage =
        '❌ Hata: Tüm alanları doldurmanız gerekiyor! İşten çıkış kodunuz kıdem ve ihbar tazminatı almaya uygundur.';
        _hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    // Tarih doğrulama
    DateTime? startDate;
    DateTime? endDate;
    try {
      int startAyIndex = aylar.indexOf(startAy!) + 1;
      int endAyIndex = aylar.indexOf(endAy!) + 1;
      startDate = DateTime(int.parse(startYil!), startAyIndex, int.parse(startGun!));
      endDate = DateTime(int.parse(endYil!), endAyIndex, int.parse(endGun!));
      if (endDate.isBefore(startDate)) {
        setState(() {
          _errorMessage = '❌ Hata: Çıkış tarihi giriş tarihinden önce olamaz!';
          _hesaplamaSonucu = null;
        });
        _scrollToResult();
        return;
      }
      if (startDate.isAfter(DateTime.now()) || endDate.isAfter(DateTime.now())) {
        setState(() {
          _errorMessage = '❌ Hata: Tarihler gelecekte olamaz!';
          _hesaplamaSonucu = null;
        });
        _scrollToResult();
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Hata: Geçersiz tarih (ör. 31 Şubat)!';
        _hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    // Brüt maaş kontrolü
    double grossSalary = parseSayi(grossSalaryController.text);
    if (grossSalary <= 0) {
      setState(() {
        _errorMessage = '❌ Hata: Brüt maaş sıfır veya negatif olamaz!';
        _hesaplamaSonucu = null;
      });
      _scrollToResult();
      return;
    }

    // Hesaplama
    final severance = calculateSeverancePay(grossSalary, startDate, endDate);
    final notice = calculateNoticePay(grossSalary, startDate, endDate);

    bool severanceEligible = isEligibleForSeverance(selectedExitCode!);
    bool noticeEligible = isEligibleForNotice(selectedExitCode!);

    // 1 yıl çalışma şartı
    if (severance['daysWorked'] < 365) {
      severanceEligible = false;
    }

    Map<String, String> detaylar = {};
    double totalBrut = 0;
    double totalNet = 0;

    if (severanceEligible) {
      totalBrut += severance['brut'];
      totalNet += severance['net'];
      detaylar['Çalışılan Gün'] = severance['daysWorked'].toString();
      detaylar['Kıdem Tazminatı (Brüt)'] = formatSayi(severance['brut']);
      detaylar['Damga Vergisi Kesintisi'] = formatSayi(severance['stampTax']);
      detaylar['Kıdem Tazminatı (Net)'] = formatSayi(severance['net']);
      if (severance['exceedsCeiling']) {
        detaylar['Not'] = 'Ücret Tavanı Aşıyor, Tavan Üzerinden Hesaplandı.';
      }
    } else {
      detaylar['İşten Çıkış'] =
      '$selectedExitCode - ${exitCodes[selectedExitCode]}';
      detaylar['Kıdem Tazminatı'] = 'Hak Kazanılmadı.';
    }

    if (noticeEligible) {
      totalBrut += notice['brut']!;
      totalNet += notice['net']!;
      detaylar['İhbar Tazminatı (Brüt)'] = formatSayi(notice['brut']!);
      detaylar['Gelir Vergisi Kesintisi'] = formatSayi(notice['incomeTax']!);
      detaylar['Damga Vergisi Kesintisi (İhbar)'] =
          formatSayi(notice['stampTax']!);
      detaylar['İhbar Tazminatı (Net)'] = formatSayi(notice['net']!);
    } else {
      detaylar['İhbar Tazminatı'] = 'Hak Kazanılmadı.';
    }

    detaylar['Toplam Hak Edilen (Brüt)'] = formatSayi(totalBrut);
    detaylar['Toplam Hak Edilen (Net)'] = formatSayi(totalNet);

    Map<String, String> ekBilgi = {
      'Kontrol Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
      'Not': severance['daysWorked'] < 365
          ? 'Kıdem Tazminatına Hak Kazanabilmeniz İçin Aynı İşverenin İşyeri veya İşyerlerinde En Az 1 Yıl Sürekli Çalışılmış Olması Gereklidir.'
          : 'Hesaplama tamamlandı. Detayları kontrol ediniz.',
    };

    setState(() {
      _hesaplamaSonucu = {
        'basarili': (severanceEligible || noticeEligible),
        'mesaj': (severanceEligible || noticeEligible)
            ? 'Hesaplama Başarıyla Tamamlandı!'
            : 'Bu Şartlar Altında Kıdem Tazminatına Hak Kazanamıyorsunuz.',
        'detaylar': detaylar,
        'ekBilgi': ekBilgi,
      };
      _errorMessage = _hesaplamaSonucu!['mesaj'];
      print("Hesaplama Sonucu: ${detaylar}");
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
          child: Container(
            height: 50,
            alignment: Alignment.center,
            child: Text(
              mesaj,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: basarili ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (detaylar.isNotEmpty) _buildResultDetails(detaylar),
        const SizedBox(height: 6),
        if (ekBilgi.isNotEmpty) _buildEkBilgiCard(ekBilgi),
      ],
    );
  }

  Widget _buildResultDetails(Map<String, String> detaylar) {
    final iconMap = {
      'Çalışılan Gün': Icons.calendar_today,
      'Kıdem Tazminatı (Brüt)': Icons.account_balance_wallet,
      'Damga Vergisi Kesintisi': Icons.money_off,
      'Kıdem Tazminatı (Net)': Icons.account_balance_wallet,
      'İhbar Tazminatı (Brüt)': Icons.account_balance_wallet,
      'Gelir Vergisi Kesintisi': Icons.money_off,
      'Damga Vergisi Kesintisi (İhbar)': Icons.money_off,
      'İhbar Tazminatı (Net)': Icons.account_balance_wallet,
      'Toplam Hak Edilen (Brüt)': Icons.attach_money,
      'Toplam Hak Edilen (Net)': Icons.attach_money,
      'Not': Icons.warning_amber_outlined,
      'İşten Çıkış': Icons.error_outline,
      'Kıdem Tazminatı': Icons.error_outline,
      'İhbar Tazminatı': Icons.error_outline,
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
            ),
            const Divider(),
            const SizedBox(height: 4),
            ...entries.map((entry) {
              return Column(
                children: [
                  ListTile(
                    leading: Icon(iconMap[entry.key] ?? Icons.info_outline,
                        color: Colors.indigo, size: 18),
                    title: Text(entry.key,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle:
                    Text(entry.value, style: const TextStyle(fontSize: 14)),
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
      'Not'
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
              // "Kontrol Tarihi" ve "Not" için dinamik veri gösteriyoruz
              if (key == 'Kontrol Tarihi' || key == 'Not') {
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

  TextStyle get _labelStyle => const TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kıdem Ve İhbar Tazminatı Hesaplama'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildDropdownContainer(
                  label: 'İşten Çıkış Kodunuz',
                  value: selectedExitCode,
                  items: exitCodes.entries
                      .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      '${entry.key} - ${entry.value}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedExitCode = value),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildDateDropdownContainer(
                  label: 'İşe Giriş Tarihi',
                  gun: startGun,
                  ay: startAy,
                  yil: startYil,
                  onGunChanged: (value) => setState(() => startGun = value),
                  onAyChanged: (value) => setState(() => startAy = value),
                  onYilChanged: (value) => setState(() => startYil = value),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildDateDropdownContainer(
                  label: 'İşten Çıkış Tarihi',
                  gun: endGun,
                  ay: endAy,
                  yil: endYil,
                  onGunChanged: (value) => setState(() => endGun = value),
                  onAyChanged: (value) => setState(() => endAy = value),
                  onYilChanged: (value) => setState(() => endYil = value),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildAmountField(
                    'Son Ay Giydirilmiş Brüt Ücret', grossSalaryController),
              ),
            ),
            const SizedBox(height: 20),
            Card(
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
                  onPressed: _calculateCompensation,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Hesapla',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_hesaplamaSonucu != null || _errorMessage != null)
              _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(label, style: _labelStyle),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.indigo[200]!, width: 1),
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.grey[100],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text('Seçiniz'),
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              dropdownColor: Colors.white,
              menuMaxHeight: 300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateDropdownContainer({
    required String label,
    required String? gun,
    required String? ay,
    required String? yil,
    required ValueChanged<String?> onGunChanged,
    required ValueChanged<String?> onAyChanged,
    required ValueChanged<String?> onYilChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(label, style: _labelStyle),
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: gun,
                hint: const Text('Gün',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: List.generate(31, (index) => (index + 1).toString())
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Center(child: Text(e))))
                    .toList(),
                onChanged: onGunChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: ay,
                hint: const Text('Ay',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: aylar
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Center(child: Text(e))))
                    .toList(),
                onChanged: onAyChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: yil,
                hint: const Text('Yıl',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: List.generate(2026 - 1980, (index) => (2025 - index).toString())
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Center(child: Text(e))))
                    .toList(),
                onChanged: onYilChanged,
              ),
            ),
          ],
        ),
      ],
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
}

class CustomCurrencyFormatter extends TextInputFormatter {
  final NumberFormat integerFormat = NumberFormat.decimalPattern('tr_TR');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    if (digitsOnly.length < 5) {
      return newValue.copyWith(
          text: digitsOnly,
          selection: TextSelection.collapsed(offset: digitsOnly.length));
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