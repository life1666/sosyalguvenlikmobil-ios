import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const NettenBruteApp());
}

class NettenBruteApp extends StatelessWidget {
  const NettenBruteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Netten Brüte Maaş Hesaplama',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 14, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 12, color: Colors.black54),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
      ),
      home: const NettenBruteScreen(),
    );
  }
}

class NettenBruteScreen extends StatefulWidget {
  const NettenBruteScreen({super.key});

  @override
  State<NettenBruteScreen> createState() => _NettenBruteScreenState();
}

class _NettenBruteScreenState extends State<NettenBruteScreen> {
  List<TextEditingController> _netSalaryControllers = List.generate(12, (index) => TextEditingController(text: ''));
  List<DataRow> _monthlyRows = [];
  int _selectedYear = 2025;
  String _selectedIncentive = "Teşvik Yok";
  String _employeeStatus = "Normal Çalışan";
  String? _errorMessage;
  List<String> _incentiveOptions = [];
  List<String> _employeeStatusOptions = ["Normal Çalışan", "SGDP Kapsamında Çalışan"];

  late double sgkEmployeeRate;
  late double sgkEmployerBaseRate;
  late double unemploymentEmployeeRate;
  late double sgkEmployerRate;
  late double unemploymentEmployerRate;
  late double stampTaxRate;
  late double minWage;
  late double minWageTaxableBase;
  late List<double> taxBrackets;
  late List<double> taxRates;

  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  static const List<String> monthNames = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateConstants(_selectedYear);
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-6005798972779145/4051383467',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          setState(() {
            _interstitialAd = ad;
            _isAdReady = true;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          setState(() {
            _isAdReady = false;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    for (var controller in _netSalaryControllers) {
      controller.dispose();
    }
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _updateConstants(int year) {
    setState(() {
      _selectedYear = year;

      if (_employeeStatus == "SGDP Kapsamında Çalışan") {
        sgkEmployeeRate = 0.075;
        unemploymentEmployeeRate = 0.0;
        unemploymentEmployerRate = 0.0;
        sgkEmployerBaseRate = 0.225;
      } else {
        sgkEmployeeRate = 0.14;
        unemploymentEmployeeRate = 0.01;
        unemploymentEmployerRate = 0.02;
        sgkEmployerBaseRate = 0.185;
      }

      stampTaxRate = 0.00759;

      if (_employeeStatus == "SGDP Kapsamında Çalışan") {
        if (year == 2023 || year == 2024) {
          _incentiveOptions = ["Teşvik Yok", "5 Puan"];
        } else {
          _incentiveOptions = ["Teşvik Yok"];
        }
      } else {
        if (year == 2025) {
          _incentiveOptions = ["Teşvik Yok", "4 Puan", "5 Puan"];
        } else {
          _incentiveOptions = ["Teşvik Yok", "5 Puan"];
        }
      }
      if (!_incentiveOptions.contains(_selectedIncentive)) {
        _selectedIncentive = _incentiveOptions.isNotEmpty ? _incentiveOptions[0] : "Teşvik Yok";
      }

      if (year == 2022) {
        minWage = 5004.00;
        taxBrackets = [32000, 70000, 250000, 880000];
        taxRates = [0.15, 0.20, 0.27, 0.35, 0.40];
      } else if (year == 2023) {
        minWage = 10008.00;
        taxBrackets = [70000, 150000, 550000, 1900000];
        taxRates = [0.15, 0.20, 0.27, 0.35, 0.40];
      } else if (year == 2024) {
        minWage = 20002.50;
        taxBrackets = [110000, 230000, 870000, 3000000];
        taxRates = [0.15, 0.20, 0.27, 0.35, 0.40];
      } else {
        minWage = 26005.50;
        taxBrackets = [158000, 330000, 1200000, 4300000];
        taxRates = [0.15, 0.20, 0.27, 0.35, 0.40];
      }
      minWageTaxableBase = roundTo2(minWage * (1 - sgkEmployeeRate - unemploymentEmployeeRate));
    });
  }

  void updateMonthlyConstants(int month, int year) {
    double shortTermRate = (year < 2024 || (year == 2024 && month < 8)) ? 0.02 : 0.0225;
    sgkEmployerRate = sgkEmployerBaseRate + shortTermRate;

    if (year == 2022) {
      minWage = month < 6 ? 5004.00 : 6471.00;
    } else if (year == 2023) {
      minWage = month < 6 ? 10008.00 : 13414.50;
    } else if (year == 2024) {
      minWage = 20002.50;
    } else {
      minWage = 26005.50;
    }
  }

  double getExemptionTaxAmount(int monthIndex) {
    if (_selectedYear == 2022) {
      if (monthIndex < 6) return 638.01;
      if (monthIndex == 6) return 825.05;
      if (monthIndex == 7) return 1051.11;
      return 1100.07;
    } else if (_selectedYear == 2023) {
      if (monthIndex < 6) return 1276.02;
      if (monthIndex == 6) return 1710.35;
      if (monthIndex == 7) return 1902.62;
      return 2280.46;
    } else if (_selectedYear == 2024) {
      if (monthIndex < 6) return 2550.32;
      if (monthIndex == 6) return 3001.06;
      return 3400.42;
    } else {
      if (monthIndex < 7) return 3315.70;
      if (monthIndex == 7) return 4257.57;
      return 4420.93;
    }
  }

  double _parseCurrency(String text) {
    if (text.trim().isEmpty) return 0.0;
    String withoutTL = text.replaceAll(' TL', '').trim();
    String justNumber = withoutTL.replaceAll('.', '').replaceAll(',', '.');
    double value = double.tryParse(justNumber) ?? 0.0;
    return value;
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat("#,##0.00", "tr_TR");
    return '${formatter.format(value)} TL';
  }

  double roundTo2(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  void _autoFillMonths(int startIndex) {
    if (_netSalaryControllers[startIndex].text.trim().isEmpty) {
      for (int i = startIndex + 1; i < 12; i++) {
        _netSalaryControllers[i].clear();
      }
    } else {
      double value = _parseCurrency(_netSalaryControllers[startIndex].text);
      String formatted = _formatCurrency(value);
      for (int i = startIndex + 1; i < 12; i++) {
        _netSalaryControllers[i].text = formatted;
      }
    }
  }

  Map<String, double> calculateIncomeTax(
      double monthlyTaxableIncomeDbl,
      double cumulativeTaxableIncomeBeforeExemptionDbl,
      double cumulativeTaxableIncomeBeforeExemptionPreviousDbl,
      int monthIndex,
      List<double> roundedCumulativeTaxes) {
    double monthlyTI = roundTo2(monthlyTaxableIncomeDbl);
    double cumTotal = roundTo2(cumulativeTaxableIncomeBeforeExemptionDbl);
    double cumPrev = roundTo2(cumulativeTaxableIncomeBeforeExemptionPreviousDbl);
    double minBase = roundTo2(minWageTaxableBase);

    if (monthlyTI <= 0) {
      return {
        'tax': 0,
        'exemption': 0,
        'taxableIncomeAfterExemption': 0,
        'taxBeforeExemption': 0,
      };
    }

    double exemption = monthlyTI >= minBase ? minBase : monthlyTI;
    double taxableAfter = roundTo2(monthlyTI - exemption);

    double totalTax = 0;
    double rem = cumTotal;
    double prevLimit = 0;
    for (int i = 0; i < taxBrackets.length + 1; i++) {
      if (rem <= 0) break;
      double limit = i < taxBrackets.length ? taxBrackets[i] : rem;
      double slice = rem > (limit - prevLimit) ? (limit - prevLimit) : rem;
      totalTax += roundTo2(slice * taxRates[i]);
      prevLimit = limit;
      rem -= slice;
    }

    double prevTax = 0;
    rem = cumPrev;
    prevLimit = 0;
    for (int i = 0; i < taxBrackets.length + 1; i++) {
      if (rem <= 0) break;
      double limit = i < taxBrackets.length ? taxBrackets[i] : rem;
      double slice = rem > (limit - prevLimit) ? (limit - prevLimit) : rem;
      prevTax += roundTo2(slice * taxRates[i]);
      prevLimit = limit;
      rem -= slice;
    }

    double monthlyTaxBefore = roundTo2(totalTax - prevTax);
    double exemptionTax = roundTo2(getExemptionTaxAmount(monthIndex));
    double monthlyTax = roundTo2(monthlyTaxBefore - exemptionTax);
    if (monthlyTax < 0) monthlyTax = 0;

    return {
      'tax': monthlyTax,
      'exemption': exemptionTax,
      'taxableIncomeAfterExemption': taxableAfter,
      'taxBeforeExemption': monthlyTaxBefore,
    };
  }

  double calculateNetFromGross(
      double grossSalaryParsed,
      int month,
      double cumulativeTaxableIncomeBeforeExemption,
      double cumulativeTaxableIncomeBeforeExemptionPrevious,
      List<double> roundedCumulativeTaxes) {
    updateMonthlyConstants(month, _selectedYear);
    double sgkCeiling = minWage * 7.5;
    minWageTaxableBase = roundTo2(minWage * (1 - sgkEmployeeRate - unemploymentEmployeeRate));

    if (_employeeStatus == "SGDP Kapsamında Çalışan" && _selectedYear == 2024) {
      sgkEmployerRate = month < 8 ? 0.245 : 0.2475;
    }

    double originalSgkEmployerRate = sgkEmployerRate;
    double incentiveRate = 0.0;
    if (_employeeStatus == "SGDP Kapsamında Çalışan") {
      if (_selectedIncentive == "5 Puan" && (_selectedYear == 2023 || _selectedYear == 2024)) {
        incentiveRate = 0.05;
      }
    } else {
      if (_selectedIncentive == "5 Puan") {
        incentiveRate = 0.05;
      } else if (_selectedIncentive == "4 Puan" && _selectedYear == 2025) {
        incentiveRate = 0.04;
      }
    }
    double effectiveSgkEmployerRate = originalSgkEmployerRate - incentiveRate;

    double sgkBase = grossSalaryParsed > sgkCeiling ? sgkCeiling : grossSalaryParsed;
    double sgkEmployeeDeduction = roundTo2(sgkBase * sgkEmployeeRate);
    double rawUnemployment = sgkBase * unemploymentEmployeeRate;
    double unemploymentEmployeeDeduction = roundTo2(rawUnemployment);
    double totalEmployeeDeduction = roundTo2(sgkEmployeeDeduction + unemploymentEmployeeDeduction);

    double sgkEmployerDeduction = roundTo2(sgkBase * effectiveSgkEmployerRate);
    double unemploymentEmployerDeduction = roundTo2(grossSalaryParsed * unemploymentEmployerRate);
    double totalEmployerDeduction = roundTo2(sgkEmployerDeduction + unemploymentEmployerDeduction);

    double taxableIncomeBase = roundTo2(grossSalaryParsed - totalEmployeeDeduction);

    Map<String, double> incomeTaxResult = calculateIncomeTax(
      taxableIncomeBase,
      cumulativeTaxableIncomeBeforeExemption + taxableIncomeBase,
      cumulativeTaxableIncomeBeforeExemption,
      month,
      roundedCumulativeTaxes,
    );

    double stampTaxExemption = roundTo2(minWage * stampTaxRate);
    double stampTaxBeforeExemption = roundTo2(grossSalaryParsed * stampTaxRate);
    double stampTax = roundTo2(stampTaxBeforeExemption - stampTaxExemption);
    if (stampTax < 0) stampTax = 0;

    double totalDeductions = roundTo2(totalEmployeeDeduction + incomeTaxResult['tax']! + stampTax);
    double netSalary = roundTo2(grossSalaryParsed - totalDeductions);

    return netSalary;
  }

  double findGrossForNet(
      double targetNetSalary,
      int month,
      double cumulativeTaxableIncomeBeforeExemption,
      double cumulativeTaxableIncomeBeforeExemptionPrevious,
      List<double> roundedCumulativeTaxes) {
    if (targetNetSalary <= 0) return 0.0;

    double lowerBound = targetNetSalary;
    double upperBound = targetNetSalary * 2;
    double tolerance = 0.00001;
    int maxIterations = 300;

    for (int i = 0; i < maxIterations; i++) {
      double mid = (lowerBound + upperBound) / 2;
      double calculatedNet = calculateNetFromGross(
        mid,
        month,
        cumulativeTaxableIncomeBeforeExemption,
        cumulativeTaxableIncomeBeforeExemptionPrevious,
        roundedCumulativeTaxes,
      );

      if ((calculatedNet - targetNetSalary).abs() < tolerance) {
        double result = roundTo2(mid);
        if ((result - minWage).abs() < 0.01) {
          result = minWage;
        }
        return result;
      }

      if (calculatedNet < targetNetSalary) {
        lowerBound = mid;
      } else {
        upperBound = mid;
      }
    }

    double result = roundTo2(lowerBound);
    if ((result - minWage).abs() < 0.01) {
      result = minWage;
    }
    return result;
  }

  bool _validateInputs() {
    bool hasValidInput = false;
    for (int i = 0; i < _netSalaryControllers.length; i++) {
      final String rawText = _netSalaryControllers[i].text.trim();
      double netSalaryParsed = _parseCurrency(rawText);
      if (netSalaryParsed > 0) {
        hasValidInput = true;
      } else if (rawText.isNotEmpty && netSalaryParsed <= 0) {
        setState(() {
          _errorMessage = 'Lütfen ${monthNames[i]} ayı için geçerli bir net maaş giriniz (sıfır veya negatif olamaz)!';
          _monthlyRows = [];
        });
        return false;
      }
    }

    if (!hasValidInput) {
      setState(() {
        _errorMessage = 'Lütfen en az bir ay için geçerli bir net maaş giriniz!';
        _monthlyRows = [];
      });
      return false;
    }

    return true;
  }

  void _hesapla() {
    setState(() {
      _errorMessage = null;
      _monthlyRows.clear();
    });

    if (!_validateInputs()) {
      return;
    }

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
    for (var controller in _netSalaryControllers) {
      if (controller.text.trim().isNotEmpty) {
        double val = _parseCurrency(controller.text);
        if (val <= 0) {
          setState(() {
            _errorMessage = 'Net maaş sıfır veya negatif olamaz!';
            _monthlyRows = [];
          });
          return;
        }
        controller.text = _formatCurrency(val);
      }
    }
    _calculateGrossSalaryForYear();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          selectedYear: _selectedYear,
          monthlyRows: _monthlyRows,
          monthNames: monthNames,
        ),
      ),
    );
  }

  void _calculateGrossSalaryForYear() {
    List<double> roundedCumulativeTaxes = List.filled(12, 0.0);
    List<DataRow> monthlyRows = [];
    double cumulativeTaxableIncomeBeforeExemption = 0;
    double totalNetSalary = 0;
    double totalEmployerCost = 0;
    double totalIncomeTaxExemption = 0;
    double totalStampTaxExemption = 0;
    double totalGrossSalary = 0;
    double totalSgkEmployeeDeduction = 0;
    double totalUnemploymentEmployeeDeduction = 0;
    double totalStampTax = 0;
    double totalSgkEmployerDeduction = 0;
    double totalUnemploymentEmployerDeduction = 0;
    double totalIncomeTax = 0;
    double totalTaxBeforeExemption = 0;
    double totalStampTaxBeforeExemption = 0;

    for (int month = 0; month < 12; month++) {
      updateMonthlyConstants(month, _selectedYear);
      double sgkCeiling = minWage * 7.5;
      minWageTaxableBase = roundTo2(minWage * (1 - sgkEmployeeRate - unemploymentEmployeeRate));

      final String rawText = _netSalaryControllers[month].text.trim();
      double netSalaryParsed = _parseCurrency(rawText);

      if (netSalaryParsed <= 0) {
        continue;
      }

      if (_employeeStatus == "SGDP Kapsamında Çalışan" && _selectedYear == 2024) {
        sgkEmployerRate = month < 8 ? 0.245 : 0.2475;
      }

      double originalSgkEmployerRate = sgkEmployerRate;
      double incentiveRate = 0.0;
      if (_employeeStatus == "SGDP Kapsamında Çalışan") {
        if (_selectedIncentive == "5 Puan" && (_selectedYear == 2023 || _selectedYear == 2024)) {
          incentiveRate = 0.05;
        }
      } else {
        if (_selectedIncentive == "5 Puan") {
          incentiveRate = 0.05;
        } else if (_selectedIncentive == "4 Puan" && _selectedYear == 2025) {
          incentiveRate = 0.04;
        }
      }
      double effectiveSgkEmployerRate = originalSgkEmployerRate - incentiveRate;

      double grossSalaryParsed = findGrossForNet(
        netSalaryParsed,
        month,
        cumulativeTaxableIncomeBeforeExemption,
        cumulativeTaxableIncomeBeforeExemption,
        roundedCumulativeTaxes,
      );

      double sgkBase = grossSalaryParsed > sgkCeiling ? sgkCeiling : grossSalaryParsed;
      double sgkEmployeeDeduction = roundTo2(sgkBase * sgkEmployeeRate);
      double unemploymentEmployeeDeduction = roundTo2(sgkBase * unemploymentEmployeeRate);
      double totalEmployeeDeduction = roundTo2(sgkEmployeeDeduction + unemploymentEmployeeDeduction);

      double sgkEmployerDeduction = roundTo2(sgkBase * effectiveSgkEmployerRate);
      double unemploymentEmployerDeduction = roundTo2(grossSalaryParsed * unemploymentEmployerRate);
      double totalEmployerDeduction = roundTo2(sgkEmployerDeduction + unemploymentEmployerDeduction);

      double taxableIncomeBase = roundTo2(grossSalaryParsed - totalEmployeeDeduction);
      double cumulativeTaxableIncomeBeforeExemptionPrevious = cumulativeTaxableIncomeBeforeExemption;
      cumulativeTaxableIncomeBeforeExemption = roundTo2(cumulativeTaxableIncomeBeforeExemption + taxableIncomeBase);

      Map<String, double> incomeTaxResult = calculateIncomeTax(
        taxableIncomeBase,
        cumulativeTaxableIncomeBeforeExemption,
        cumulativeTaxableIncomeBeforeExemptionPrevious,
        month,
        roundedCumulativeTaxes,
      );
      if (month == 0) {
        roundedCumulativeTaxes[0] = incomeTaxResult['taxBeforeExemption']!;
      } else {
        roundedCumulativeTaxes[month] = roundTo2(roundedCumulativeTaxes[month - 1] + incomeTaxResult['taxBeforeExemption']!);
      }

      double stampTaxExemption = roundTo2(minWage * stampTaxRate);
      double stampTaxBeforeExemption = roundTo2(grossSalaryParsed * stampTaxRate);
      double stampTax = roundTo2(stampTaxBeforeExemption - stampTaxExemption);
      if (stampTax < 0) stampTax = 0;

      double monthlyEmployerCost = roundTo2(grossSalaryParsed + totalEmployerDeduction);

      monthlyRows.add(DataRow(cells: [
        DataCell(Text(monthNames[month])),
        DataCell(Text(_formatCurrency(netSalaryParsed))),
        DataCell(Text(_formatCurrency(grossSalaryParsed))),
        DataCell(Text(_formatCurrency(sgkEmployeeDeduction))),
        DataCell(Text(_formatCurrency(unemploymentEmployeeDeduction))),
        DataCell(Text(_formatCurrency(sgkEmployerDeduction))),
        DataCell(Text(_formatCurrency(unemploymentEmployerDeduction))),
        DataCell(Text(_formatCurrency(incomeTaxResult['tax']!))),
        DataCell(Text(_formatCurrency(cumulativeTaxableIncomeBeforeExemption))),
        DataCell(Text(_formatCurrency(incomeTaxResult['taxBeforeExemption']!))),
        DataCell(Text(_formatCurrency(incomeTaxResult['exemption']!))),
        DataCell(Text(_formatCurrency(stampTax))),
        DataCell(Text(_formatCurrency(stampTaxBeforeExemption))),
        DataCell(Text(_formatCurrency(stampTaxExemption))),
        DataCell(Text(_formatCurrency(monthlyEmployerCost))),
      ]));

      totalNetSalary += netSalaryParsed;
      totalGrossSalary += grossSalaryParsed;
      totalSgkEmployeeDeduction += sgkEmployeeDeduction;
      totalUnemploymentEmployeeDeduction += unemploymentEmployeeDeduction;
      totalIncomeTax += incomeTaxResult['tax']!;
      totalStampTax += stampTax;
      totalSgkEmployerDeduction += sgkEmployerDeduction;
      totalUnemploymentEmployerDeduction += unemploymentEmployerDeduction;
      totalEmployerCost += monthlyEmployerCost;
      totalIncomeTaxExemption += incomeTaxResult['exemption']!;
      totalStampTaxExemption += stampTaxExemption;
      totalTaxBeforeExemption += incomeTaxResult['taxBeforeExemption']!;
      totalStampTaxBeforeExemption += stampTaxBeforeExemption;
    }

    if (monthlyRows.isEmpty) {
      setState(() {
        _errorMessage = 'Geçerli bir net maaş girilmedi!';
        _monthlyRows = [];
      });
      return;
    }

    monthlyRows.add(DataRow(cells: [
      const DataCell(Text('Toplam', style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(_formatCurrency(totalNetSalary))),
      DataCell(Text(_formatCurrency(totalGrossSalary))),
      DataCell(Text(_formatCurrency(totalSgkEmployeeDeduction))),
      DataCell(Text(_formatCurrency(totalUnemploymentEmployeeDeduction))),
      DataCell(Text(_formatCurrency(totalSgkEmployerDeduction))),
      DataCell(Text(_formatCurrency(totalUnemploymentEmployerDeduction))),
      DataCell(Text(_formatCurrency(totalIncomeTax))),
      DataCell(Text(_formatCurrency(cumulativeTaxableIncomeBeforeExemption))),
      DataCell(Text(_formatCurrency(totalTaxBeforeExemption))),
      DataCell(Text(_formatCurrency(totalIncomeTaxExemption))),
      DataCell(Text(_formatCurrency(totalStampTax))),
      DataCell(Text(_formatCurrency(totalStampTaxBeforeExemption))),
      DataCell(Text(_formatCurrency(totalStampTaxExemption))),
      DataCell(Text(_formatCurrency(totalEmployerCost))),
    ]));

    setState(() {
      _monthlyRows = monthlyRows;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(color: Colors.indigo.withOpacity(0.18), width: 1.5);

    return Scaffold(
      appBar: AppBar(
        title: Text('Netten Brüte Maaş Hesaplama $_selectedYear'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        controller: _verticalScrollController,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderSide.color, width: borderSide.width),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Yıl Seçiniz
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSide.color, width: borderSide.width),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Yıl Seçiniz', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
                        DropdownButtonFormField<int>(
                          value: _selectedYear,
                          iconEnabledColor: Colors.indigo,
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.indigo),
                          ),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: [2022, 2023, 2024, 2025].map((year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text('$year', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 15)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              for (var c in _netSalaryControllers) {
                                c.clear();
                              }
                              setState(() {
                                _monthlyRows.clear();
                                _errorMessage = null;
                              });
                              _updateConstants(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // Çalışan Statüsü
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSide.color, width: borderSide.width),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Çalışan Statüsü', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
                        DropdownButtonFormField<String>(
                          value: _employeeStatus,
                          iconEnabledColor: Colors.indigo,
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: Icon(Icons.person, color: Colors.indigo),
                          ),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: _employeeStatusOptions.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 15)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _employeeStatus = value;
                                _updateConstants(_selectedYear);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // Teşvik Seçiniz
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSide.color, width: borderSide.width),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Teşvik Seçiniz', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
                        DropdownButtonFormField<String>(
                          value: _selectedIncentive,
                          iconEnabledColor: Colors.indigo,
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: Icon(Icons.trending_up, color: Colors.indigo),
                          ),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: _incentiveOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 15)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedIncentive = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Ay kutuları
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderSide.color, width: borderSide.width),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 8,
                              top: 6,
                              child: Text(
                                monthNames[index],
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 22, left: 8, right: 8, bottom: 8),
                              child: TextFormField(
                                controller: _netSalaryControllers[index],
                                decoration: const InputDecoration(
                                  hintText: 'Net Ücret',
                                  suffix: Text('TL', style: TextStyle(color: Colors.indigo, fontSize: 13)),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                                ],
                                onChanged: (value) {
                                  _autoFillMonths(index);
                                },
                                onEditingComplete: () {
                                  FocusScope.of(context).unfocus();
                                  if (_netSalaryControllers[index].text.trim().isNotEmpty) {
                                    double val = _parseCurrency(_netSalaryControllers[index].text);
                                    _netSalaryControllers[index].text = _formatCurrency(val);
                                  }
                                },
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ElevatedButton(
                      onPressed: _hesapla,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text(
                        'Hesapla',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  final int selectedYear;
  final List<DataRow> monthlyRows;
  final List<String> monthNames;

  const ResultsScreen({
    super.key,
    required this.selectedYear,
    required this.monthlyRows,
    required this.monthNames,
  });

  Future<void> _shareAsPdf(BuildContext context) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final List<String> pdfHeaders = [
      'Ay', 'Net Ücret', 'Brüt Ücret', 'SGK İşçi Payı', 'İşsizlik İşçi Payı',
      'SGK İşveren Payı', 'İşsizlik İşveren Payı', 'Gelir Vergisi',
      'Kümülatif GV Matrahı', 'İstisna Öncesi GV', 'Asgari Ücret GV İstisnası',
      'Damga Vergisi', 'İstisna Öncesi DV', 'D.V. İstisnası', 'Toplam Maliyet',
    ];
    final List<List<String>> pdfTableRows = [];
    for (var row in monthlyRows) {
      final rowData = row.cells.map((cell) {
        if (cell.child is Text) {
          return (cell.child as Text).data?.replaceAll(' TL', '') ?? '';
        }
        return '';
      }).toList();
      if (rowData.length == 15) {
        pdfTableRows.add(rowData);
      }
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(20, 12, 20, 20),
        build: (pw.Context context) => [
          pw.Text(
            'Hesaplama Sonuçları - $selectedYear',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, font: ttf),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: pdfHeaders,
            data: pdfTableRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf, fontSize: 8),
            cellStyle: pw.TextStyle(font: ttf, fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: PdfColors.indigo100),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(),
            headerPadding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            columnWidths: {
              0: pw.FixedColumnWidth(54),
              1: pw.FixedColumnWidth(70),
              2: pw.FixedColumnWidth(70),
              3: pw.FixedColumnWidth(60),
              4: pw.FixedColumnWidth(60),
              5: pw.FixedColumnWidth(70),
              6: pw.FixedColumnWidth(70),
              7: pw.FixedColumnWidth(65),
              8: pw.FixedColumnWidth(75),
              9: pw.FixedColumnWidth(65),
              10: pw.FixedColumnWidth(75),
              11: pw.FixedColumnWidth(60),
              12: pw.FixedColumnWidth(65),
              13: pw.FixedColumnWidth(65),
              14: pw.FixedColumnWidth(75),
            },
          ),
        ],
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/salary_calculation_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Hesaplama Sonuçları');
  }

  Future<void> _shareAsExcel(BuildContext context) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow([
      'Ay', 'Net Ücret', 'Brüt Ücret', 'SGK İşçi Payı', 'İşsizlik İşçi Payı', 'SGK İşveren Payı',
      'İşsizlik İşveren Payı', 'Gelir Vergisi', 'Kümülatif G.V. Matrahı', 'İstisna Öncesi G.V.',
      'Asgari Ücret G.V. İstisnası', 'Damga Vergisi', 'İstisna Öncesi D.V.', 'Damga Vergisi İstisnası',
      'Toplam Maliyet'
    ]);
    for (var row in monthlyRows) {
      sheet.appendRow(row.cells.map((cell) => (cell.child as Text).data?.replaceAll(' TL', '') ?? '').toList());
    }
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/salary_calculation_${DateTime.now().millisecondsSinceEpoch}.xlsx");
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)], text: 'Hesaplama Sonuçları');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesaplama Sonuçları'),
        backgroundColor: Colors.indigo,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'pdf') {
                await _shareAsPdf(context);
              } else if (value == 'excel') {
                await _shareAsExcel(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Paylaş PDF olarak'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'excel',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Paylaş Excel olarak'),
                ),
              ),
            ],
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            dataRowHeight: 50,
            headingRowHeight: 56,
            headingRowColor: MaterialStateProperty.all(Colors.indigo),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            columns: const [
              DataColumn(label: Text('Ay')),
              DataColumn(label: Text('Net Ücret')),
              DataColumn(label: Text('Brüt Ücret')),
              DataColumn(label: Text('SGK İşçi Payı')),
              DataColumn(label: Text('İşsizlik İşçi Payı')),
              DataColumn(label: Text('SGK İşveren Payı')),
              DataColumn(label: Text('İşsizlik İşveren Payı')),
              DataColumn(label: Text('Gelir Vergisi')),
              DataColumn(label: Text('Kümülatif G.V. Matrahı')),
              DataColumn(label: Text('İstisna Öncesi G.V.')),
              DataColumn(label: Text('Asgari Ücret G.V. İstisnası')),
              DataColumn(label: Text('Damga Vergisi')),
              DataColumn(label: Text('İstisna Öncesi D.V.')),
              DataColumn(label: Text('Damga Vergisi İstisnası')),
              DataColumn(label: Text('Toplam Maliyet')),
            ],
            rows: monthlyRows,
          ),
        ),
      ),
    );
  }
}