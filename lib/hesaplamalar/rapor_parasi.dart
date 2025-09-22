import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// CustomCurrencyFormatter:
/// - Girilen rakam sayısı 5'ten azsa hiçbir formatlama yapmaz.
/// - 5 veya daha fazla rakam girildiğinde, son iki rakam ondalık kısım olarak ayrılır.
///   Ör: "1234" -> "1234", "12345" -> "123,45", "123456" -> "1.234,56"
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

/// toTitleCase fonksiyonu:
/// Her kelimenin ilk harfini büyük yapar; "ve" her zaman küçük kalır.
/// "tl", "icin" gibi özel kelimeleri istenilen biçime dönüştürür.
String toTitleCase(String text) {
  if (text.isEmpty) return text;
  List<String> words = text.split(' ');
  List<String> titleCasedWords = [];
  for (String originalWord in words) {
    if (originalWord.isEmpty) {
      titleCasedWords.add(originalWord);
      continue;
    }
    String lower = originalWord.toLowerCase();
    if (lower == 've') {
      titleCasedWords.add('ve');
    } else if (lower == 'tl') {
      titleCasedWords.add('TL');
    } else if (lower == 'icin' || lower == 'için') {
      titleCasedWords.add('İçin');
    } else {
      titleCasedWords.add(originalWord[0].toUpperCase() + originalWord.substring(1).toLowerCase());
    }
  }
  return titleCasedWords.join(' ');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const RaporParasiHesaplamaApp());
}

class RaporParasiHesaplamaApp extends StatelessWidget {
  const RaporParasiHesaplamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rapor Parası Hesaplama',
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
      home: const RaporParasiScreen(),
    );
  }
}

class RaporParasiScreen extends StatefulWidget {
  const RaporParasiScreen({super.key});

  @override
  State<RaporParasiScreen> createState() => _RaporParasiScreenState();
}

class _RaporParasiScreenState extends State<RaporParasiScreen> {
  String? selectedReason;
  String? has90DaysInsurance; // Sadece "Hastalık" için: "Evet" veya "Hayır"
  String? gebelikTuru; // Sadece "Doğum" için: "Tekil" veya "Çoğul"
  String? has90DaysInsuranceForBirth; // Sadece "Doğum" için: "Evet" veya "Hayır"

  final TextEditingController yatarakDaysController = TextEditingController();
  final TextEditingController ayaktanDaysController = TextEditingController();

  // Brüt ücret ve çalışma günleri girişleri
  final TextEditingController grossSalary1 = TextEditingController();
  final TextEditingController grossSalary2 = TextEditingController();
  final TextEditingController grossSalary3 = TextEditingController();
  final TextEditingController workDays1 = TextEditingController();
  final TextEditingController workDays2 = TextEditingController();
  final TextEditingController workDays3 = TextEditingController();

  Map<String, dynamic>? _hesaplamaSonucu;

  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  final Map<String, String> raporNedenleri = {
    'İş Kazası': 'İş Kazası',
    'Meslek Hastalığı': 'Meslek Hastalığı',
    'Hastalık': 'Hastalık',
    'Doğum': 'Doğum',
  };

  final Map<String, IconData> _raporIconMap = {
    'İş Kazası': Icons.report_problem,
    'Meslek Hastalığı': Icons.health_and_safety,
    'Hastalık': Icons.sick,
    'Doğum': Icons.child_care,
  };

  final List<String> insuranceOptions = ['Evet', 'Hayır'];
  final List<String> gebelikTuruOptions = ['Tekil', 'Çoğul'];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    yatarakDaysController.dispose();
    ayaktanDaysController.dispose();
    grossSalary1.dispose();
    grossSalary2.dispose();
    grossSalary3.dispose();
    workDays1.dispose();
    workDays2.dispose();
    workDays3.dispose();
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

  double parseGrossSalary(String input) {
    String normalized = input.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  String formatSayi(double sayi) {
    final formatter = NumberFormat("#,##0.00", "tr_TR");
    return "${formatter.format(sayi)} TL";
  }

  bool _validateInputs() {
    // 1) Rapor nedeni seçildi mi?
    if (selectedReason == null) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase('Lütfen rapor nedenini seçiniz!'),
          'detaylar': {},
          'ekBilgi': {
            'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          },
        };
      });
      return false;
    }

    // 2) Hastalık raporu için sigorta kontrolü
    if (selectedReason == 'Hastalık' && has90DaysInsurance == null) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase('Lütfen sigorta bildirimi durumunu seçiniz!'),
          'detaylar': {},
          'ekBilgi': {
            'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          },
        };
      });
      return false;
    }

    // 3) Eğer "Hastalık" raporuysa ve dropdown cevabı "Hayır" ise, diğer alanlara gerek kalmadan negatif sonuç.
    if (selectedReason == 'Hastalık' && has90DaysInsurance == 'Hayır') {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase('Bu Şartlar Altında Rapor Parası Almaya Hak Kazanamıyorsunuz.'),
          'detaylar': {
            'Rapor Nedeni': toTitleCase(selectedReason!)
          },
          'ekBilgi': {
            'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Not': 'Rapor Süreniz 2 Günden Az Olduğu İçin ve/veya Rapor Tarihinden Önceki 1 Yıl İçinde 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Olmadığı İçin Rapor Parası Almaya Hak Kazanamıyorsunuz.'
          },
        };
      });
      return false;
    }

    // 4) Doğum raporu için ek kontroller
    if (selectedReason == 'Doğum') {
      if (has90DaysInsuranceForBirth == null) {
        setState(() {
          _hesaplamaSonucu = {
            'basarili': false,
            'mesaj': toTitleCase('Lütfen Doğum Tarihinden Önce 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Var Mı? seçiniz!'),
            'detaylar': {},
            'ekBilgi': {
              'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            },
          };
        });
        return false;
      } else if (has90DaysInsuranceForBirth == 'Hayır') {
        setState(() {
          _hesaplamaSonucu = {
            'basarili': false,
            'mesaj': toTitleCase('Bu Şartlar Altında Rapor Parası Almaya Hak Kazanamıyorsunuz.'),
            'detaylar': {
              'Rapor Nedeni': toTitleCase(selectedReason!)
            },
            'ekBilgi': {
              'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
              'Not': 'Doğum Tarihinden Önce 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Olmadığı İçin Rapor Parası Almaya Hak Kazanamadınız.'
            },
          };
        });
        return false;
      }
      if (gebelikTuru == null) {
        setState(() {
          _hesaplamaSonucu = {
            'basarili': false,
            'mesaj': toTitleCase('Lütfen gebelik türünü seçiniz!'),
            'detaylar': {},
            'ekBilgi': {
              'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            },
          };
        });
        return false;
      }
    }

    // 5) Rapor süresi kontrolü (Doğum hariç)
    if (selectedReason != 'Doğum') {
      int yDays = int.tryParse(yatarakDaysController.text) ?? 0;
      int aDays = int.tryParse(ayaktanDaysController.text) ?? 0;
      if ((yDays + aDays) <= 0) {
        setState(() {
          _hesaplamaSonucu = {
            'basarili': false,
            'mesaj': toTitleCase('Lütfen yatarak veya ayaktan rapor gün sayısını giriniz!'),
            'detaylar': {},
            'ekBilgi': {
              'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            },
          };
        });
        return false;
      }
    }

    // 6) Brüt ücret ve çalışma günleri kontrolü
    final earnings1 = parseGrossSalary(grossSalary1.text);
    final earnings2 = parseGrossSalary(grossSalary2.text);
    final earnings3 = parseGrossSalary(grossSalary3.text);
    final totalEarnings = earnings1 + earnings2 + earnings3;
    final workDays1Value = double.tryParse(workDays1.text) ?? 0;
    final workDays2Value = double.tryParse(workDays2.text) ?? 0;
    final workDays3Value = double.tryParse(workDays3.text) ?? 0;
    final totalWorkDays = workDays1Value + workDays2Value + workDays3Value;

    if (totalWorkDays <= 0 || totalEarnings <= 0) {
      setState(() {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase('Son 3 ay kazanç ve çalışılan gün sayıları geçerli olmalıdır!'),
          'detaylar': {},
          'ekBilgi': {
            'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          },
        };
      });
      return false;
    }

    return true;
  }

  void _hesapla() {
    // Önce gerekli alanları kontrol et
    if (!_validateInputs()) {
      _scrollToResult();
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
    print("showHesaplamaSonucu çağrıldı");

    // Eğer hesaplama sonucu zaten set edilmişse (doğrulama hatası nedeniyle), sadece scroll et
    if (_hesaplamaSonucu != null && !_hesaplamaSonucu!['basarili']) {
      _scrollToResult();
      return;
    }

    // Normal hesaplama işlemleri
    double days;
    int yDays = 0;
    int aDays = 0;

    if (selectedReason == 'Doğum') {
      days = (gebelikTuru == 'Çoğul') ? 126 : 112;
    } else {
      yDays = int.tryParse(yatarakDaysController.text) ?? 0;
      aDays = int.tryParse(ayaktanDaysController.text) ?? 0;
      days = (yDays + aDays).toDouble();
    }

    // Hastalık için ek kontrol
    if (selectedReason == 'Hastalık' && has90DaysInsurance == 'Evet') {
      final totalRaporGunu = yDays + aDays;
      if (totalRaporGunu < 3) {
        setState(() {
          _hesaplamaSonucu = {
            'basarili': false,
            'mesaj': toTitleCase('Bu Şartlar Altında Rapor Parası Almaya Hak Kazanamıyorsunuz.'),
            'detaylar': {
              'Rapor Nedeni': toTitleCase(selectedReason!)
            },
            'ekBilgi': {
              'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
              'Not': 'Rapor Süreniz 2 Günden Az Olduğu İçin ve/veya Rapor Tarihinden Önceki 1 Yıl İçinde 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Olmadığı İçin Rapor Parası Almaya Hak Kazanamıyorsunuz.'
            },
          };
        });
        _scrollToResult();
        return;
      }
    }

    // Hesaplama işlemleri
    final earnings1 = parseGrossSalary(grossSalary1.text);
    final earnings2 = parseGrossSalary(grossSalary2.text);
    final earnings3 = parseGrossSalary(grossSalary3.text);
    final totalEarnings = earnings1 + earnings2 + earnings3;
    final workDays1Value = double.tryParse(workDays1.text) ?? 0;
    final workDays2Value = double.tryParse(workDays2.text) ?? 0;
    final workDays3Value = double.tryParse(workDays3.text) ?? 0;
    final totalWorkDays = workDays1Value + workDays2Value + workDays3Value;

    final dailyEarnings = totalEarnings / totalWorkDays;
    double totalPayment;

    if (selectedReason == 'Doğum') {
      totalPayment = days * dailyEarnings * 2 / 3;
    } else if (selectedReason == 'Hastalık') {
      double totalDays = yDays + aDays.toDouble();
      double effectiveYDays = yDays - ((yDays / totalDays) * 2);
      double effectiveADays = aDays - ((aDays / totalDays) * 2);
      totalPayment = (effectiveYDays * dailyEarnings * 0.5) + (effectiveADays * dailyEarnings * 2 / 3);
    } else {
      totalPayment = (yDays * dailyEarnings * 0.5) + (aDays * dailyEarnings * 2 / 3);
    }

    Map<String, String> resultDetails = {};
    if (selectedReason == 'Doğum') {
      resultDetails['Raporlu Gün Sayısı'] = '$days gün';
      resultDetails['Rapor Nedeni'] = (gebelikTuru == 'Çoğul') ? 'Çoklu Doğum' : 'Doğum';
    } else {
      resultDetails['Yatarak Raporlu Gün Sayısı'] = '$yDays gün';
      resultDetails['Ayaktan Raporlu Gün Sayısı'] = '$aDays gün';
      resultDetails['Toplam Raporlu Gün Sayısı'] = '${(yDays + aDays).toString()} gün';
      resultDetails['Rapor Nedeni'] = toTitleCase(selectedReason!);
    }
    resultDetails['Günlük Ödeme'] = formatSayi(dailyEarnings);
    resultDetails['Toplam Net Ödeme'] = formatSayi(totalPayment);

    setState(() {
      _hesaplamaSonucu = {
        'basarili': true,
        'mesaj': toTitleCase('Hesaplama başarıyla tamamlandı!'),
        'detaylar': resultDetails,
        'ekBilgi': {
          'Sorgu Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
          'Not': 'Hesaplama 4-A Sigorta Kolu Kapsamında Yapılmıştır.'
        },
      };
    });

    _scrollToResult();
    print("Hesaplama Sonucu: ${resultDetails.length} detay");
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text('Hesapla', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildRaporNedeniCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rapor Nedeni', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              iconEnabledColor: Colors.indigo,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              isExpanded: true,
              hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
              value: selectedReason,
              items: raporNedenleri.keys.map((key) {
                final icon = _raporIconMap[key] ?? Icons.info_outline;
                return DropdownMenuItem(
                  value: key,
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.indigo, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        key == 'Doğum' ? 'Analık (Doğum)' : key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedReason = value;
                  _hesaplamaSonucu = null;
                  has90DaysInsurance = null;
                  gebelikTuru = null;
                  has90DaysInsuranceForBirth = null;
                  yatarakDaysController.clear();
                  ayaktanDaysController.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthInsuranceCard() {
    if (selectedReason != 'Doğum') return Container();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doğum Tarihinden Önce 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Var Mı?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              iconEnabledColor: Colors.indigo,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              isExpanded: true,
              hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
              value: has90DaysInsuranceForBirth,
              items: insuranceOptions.map((option) {
                Icon icon;
                if (option == 'Evet') {
                  icon = const Icon(Icons.check_circle, color: Colors.indigo, size: 18);
                } else {
                  icon = const Icon(Icons.cancel, color: Colors.indigo, size: 18);
                }
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 8),
                      Text(option, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  has90DaysInsuranceForBirth = value;
                  _hesaplamaSonucu = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGebelikTuruCard() {
    if (selectedReason != 'Doğum') return Container();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gebelik Türü', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              iconEnabledColor: Colors.indigo,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              isExpanded: true,
              hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
              value: gebelikTuru,
              items: gebelikTuruOptions.map((option) {
                Icon icon;
                if (option == 'Tekil') {
                  icon = const Icon(Icons.person, color: Colors.indigo, size: 18);
                } else {
                  icon = const Icon(Icons.people, color: Colors.indigo, size: 18);
                }
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 8),
                      Text(option, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  gebelikTuru = value;
                  _hesaplamaSonucu = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSigortaBildirimiCard() {
    if (selectedReason != 'Hastalık') return Container();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rapor Süreniz 2 Günden Fazla Mı ve Son 1 Yıl İçinde 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Var Mı?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              iconEnabledColor: Colors.indigo,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              isExpanded: true,
              hint: const Text('Seçiniz', style: TextStyle(fontSize: 14)),
              value: has90DaysInsurance,
              items: insuranceOptions.map((option) {
                Icon icon;
                if (option == 'Evet') {
                  icon = const Icon(Icons.check_circle, color: Colors.indigo, size: 18);
                } else {
                  icon = const Icon(Icons.cancel, color: Colors.indigo, size: 18);
                }
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 8),
                      Text(option, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  has90DaysInsurance = value;
                  _hesaplamaSonucu = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRaporSuresiCard() {
    if (selectedReason == 'Doğum') return Container();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('İş Göremezlik (Rapor) Süresi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 6),
            TextFormField(
              controller: yatarakDaysController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today, color: Colors.indigo),
                border: OutlineInputBorder(),
                hintText: 'Yatarak Raporlu Gün Sayısı',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: ayaktanDaysController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today, color: Colors.indigo),
                border: OutlineInputBorder(),
                hintText: 'Ayaktan Raporlu Gün Sayısı',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrutUcretCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Son 3 Ay İçindeki Brüt Ücretleriniz ve Prim Gün Sayılarınız', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 6),
            const Text('1. Ay', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: grossSalary1,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Brüt Ücret',
                      suffix: Text('TL', style: TextStyle(color: Colors.indigo, fontSize: 14)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      CustomCurrencyFormatter(),
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: workDays1,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Gün',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('2. Ay', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: grossSalary2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Brüt Ücret',
                      suffix: Text('TL', style: TextStyle(color: Colors.indigo, fontSize: 14)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      CustomCurrencyFormatter(),
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: workDays2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Gün',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('3. Ay', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: grossSalary3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Brüt Ücret',
                      suffix: Text('TL', style: TextStyle(color: Colors.indigo, fontSize: 14)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      CustomCurrencyFormatter(),
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: workDays3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Gün',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
              ],
            ),
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
      'Sorgu Tarihi',
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
              // "Sorgu Tarihi" ve "Not" için dinamik veri gösteriyoruz
              if (key == 'Sorgu Tarihi' || key == 'Not') {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '$key: ${ekBilgi[key] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  basarili ? Icons.check_circle : Icons.error_outline,
                  color: basarili ? Colors.green : Colors.red,
                  size: 40,
                ),
                const SizedBox(width: 8),
                Expanded(
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (basarili) _buildResultDetails(detaylar),
        const SizedBox(height: 6),
        _buildEkBilgiCard(ekBilgi),
      ],
    );
  }

  Widget _buildResultDetails(Map<String, String> detaylar) {
    final iconMap = {
      'Rapor Nedeni': Icons.info_outline,
      'Raporlu Gün Sayısı': Icons.calendar_today,
      'Yatarak Raporlu Gün Sayısı': Icons.calendar_today,
      'Ayaktan Raporlu Gün Sayısı': Icons.calendar_today,
      'Toplam Raporlu Gün Sayısı': Icons.calendar_today,
      'Günlük Ödeme': Icons.paid,
      'Toplam Net Ödeme': Icons.account_balance_wallet,
    };

    List<MapEntry<String, String>> entries = detaylar.entries.toList();
    entries.sort((a, b) {
      if (a.key == 'Rapor Nedeni') return -1;
      if (b.key == 'Rapor Nedeni') return 1;
      return 0;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Detaylar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ),
            const Divider(),
            const SizedBox(height: 4),
            ...entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildStaticContent() {
    return Column(
      children: [
        _buildSigortaBildirimiCard(),
        _buildRaporSuresiCard(),
        _buildBrutUcretCard(),
        _buildHesaplaButtonCard(),
        _buildResultSection(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapor Parası Hesaplama'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildRaporNedeniCard(),
            if (selectedReason == 'Doğum') _buildBirthInsuranceCard(),
            if (selectedReason == 'Doğum') _buildGebelikTuruCard(),
            if (selectedReason != null) _buildStaticContent(),
          ],
        ),
      ),
    );
  }
}