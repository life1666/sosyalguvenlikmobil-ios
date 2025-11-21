import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../sonhesaplama/sonhesaplama.dart';

/// =================== GLOBAL STIL & KNOB'LAR ===================

const double kPageHPad = 12.0;
const double kTextScale = 1.00;
const Color kTextColor = Colors.black;

// Divider (global)
const double kDividerThickness = 0.2;
const double kDividerSpace = 2.0;

// Form alanı çerçevesi
const double kFieldBorderWidth = 0.2;
const double kFieldBorderRadius = 10.0;
const Color kFieldBorderColor = Colors.black87;
const Color kFieldFocusColor = Colors.black87;

class AppW {
  static const appBarTitle = FontWeight.w700;
  static const heading = FontWeight.w500;
  static const body = FontWeight.w400;
  static const minor = FontWeight.w300;
  static const tableHead = FontWeight.w600;
}

extension AppText on BuildContext {
  TextStyle get sFormLabel => Theme.of(this).textTheme.titleLarge!;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NettenBruteApp());
}

/// ----------------------------------------------
///  TEMA
/// ----------------------------------------------
ThemeData get uygulamaTemasi {
  final double sizeTitleLg = 16.5 * kTextScale;
  final double sizeTitleMd = 15 * kTextScale;
  final double sizeBody = 13.5 * kTextScale;
  final double sizeSmall = 12.5 * kTextScale;
  final double sizeAppBar = 20.5 * kTextScale;

  return ThemeData(
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        fontSize: sizeAppBar,
        fontWeight: AppW.appBarTitle,
        color: Colors.white,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: sizeTitleLg,
        fontWeight: AppW.heading,
        color: kTextColor,
        height: 1.25,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodyLarge: TextStyle(
        fontSize: sizeBody,
        fontWeight: AppW.body,
        color: Colors.black87,
        height: 1.45,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      labelLarge: TextStyle(
        fontSize: sizeBody,
        fontWeight: AppW.body,
        color: Colors.black87,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.black,
      thickness: kDividerThickness,
      space: kDividerSpace,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth + 0.2),
      ),
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

class NettenBruteApp extends StatelessWidget {
  const NettenBruteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Netten Brüte Maaş Hesaplama',
      theme: uygulamaTemasi,
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

  static const List<String> monthNames = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateConstants(_selectedYear);
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    for (var controller in _netSalaryControllers) {
      controller.dispose();
    }
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

  /// TL'siz ama aynı nokta/virgül kuralı
  String _formatPlain(double n) {
    final neg = n < 0;
    n = n.abs();
    final fixed = n.toStringAsFixed(2);
    final parts = fixed.split('.');
    String intPart = parts[0];
    final frac = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    return '${neg ? '-' : ''}${buf.toString()},$frac';
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
      String formatted = _formatPlain(value);
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

  Future<void> _hesapla() async {
    setState(() {
      _errorMessage = null;
      _monthlyRows.clear();
    });

    if (!_validateInputs()) {
      return;
    }

    await _showHesaplamaSonucu();
  }

  Future<void> _showHesaplamaSonucu() async {
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
        controller.text = _formatPlain(val); // Giriş alanı TL'siz kalır
      }
    }
    _calculateGrossSalaryForYear();
    
    // Son hesaplamalara kaydet
    try {
      final veriler = <String, dynamic>{
        'yil': _selectedYear,
        'calisanDurumu': _employeeStatus,
        'tesvik': _selectedIncentive,
      };
      
      final sonuclar = <String, String>{
        'Yıl': _selectedYear.toString(),
        'Hesaplama Türü': 'Netten Brüte Maaş Hesaplama',
      };
      
      final sonHesaplama = SonHesaplama(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hesaplamaTuru: 'Netten Brüte Maaş Hesaplama',
        tarihSaat: DateTime.now(),
        veriler: veriler,
        sonuclar: sonuclar,
        ozet: 'Netten brüte maaş hesaplaması tamamlandı',
      );
      
      await SonHesaplamalarDeposu.ekle(sonHesaplama);
    } catch (e) {
      debugPrint('Son hesaplama kaydedilirken hata: $e');
    }
    
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

  Future<T?> _showCupertinoPicker<T>({
    required List<T> items,
    required int initialIndex,
    String okText = 'Tamam',
    String cancelText = 'İptal',
    Widget Function(T)? itemBuilder,
  }) async {
    int sel = initialIndex.clamp(0, items.isNotEmpty ? items.length - 1 : 0);
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.pop(context),
                    child: Text(cancelText, style: const TextStyle(color: Colors.black87)),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.pop(context, items.isNotEmpty ? items[sel] : null),
                    child: Text(okText, style: const TextStyle(color: Colors.black87)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: sel),
                itemExtent: 32,
                onSelectedItemChanged: (int index) {
                  sel = index;
                },
                children: items.map((item) {
                  if (itemBuilder != null) {
                    return Center(child: itemBuilder(item));
                  }
                  return Center(child: Text('$item', style: const TextStyle(color: Colors.black87)));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<int> _years = [2022, 2023, 2024, 2025];
    final String yearLabel = _selectedYear.toString();
    final String statusLabel = _employeeStatus;
    final String incentiveLabel = _selectedIncentive;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Netten Brüte Maaş Hesaplama',
          style: TextStyle(color: Colors.indigo),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        controller: _verticalScrollController,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Seçimler ve aylık alanlar
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CupertinoField(
                    label: 'Yıl Seçiniz',
                    valueText: yearLabel,
                    onTap: () async {
                      final idx = _years.indexOf(_selectedYear);
                      final sel = await _showCupertinoPicker<int>(
                        items: _years,
                        initialIndex: idx < 0 ? 0 : idx,
                        itemBuilder: (y) => Text('$y'),
                      );
                      if (sel != null) {
                        for (var c in _netSalaryControllers) {
                          c.clear();
                        }
                        setState(() {
                          _monthlyRows.clear();
                          _errorMessage = null;
                        });
                        _updateConstants(sel);
                      }
                    },
                  ),
                  _CupertinoField(
                    label: 'Çalışan Statüsü',
                    valueText: statusLabel,
                    onTap: () async {
                      final idx = _employeeStatusOptions.indexOf(_employeeStatus);
                      final sel = await _showCupertinoPicker<String>(
                        items: _employeeStatusOptions,
                        initialIndex: idx < 0 ? 0 : idx,
                      );
                      if (sel != null) {
                        setState(() {
                          _employeeStatus = sel;
                          _updateConstants(_selectedYear);
                        });
                      }
                    },
                  ),
                  _CupertinoField(
                    label: 'Teşvik Seçiniz',
                    valueText: incentiveLabel,
                    onTap: () async {
                      final idx = _incentiveOptions.indexOf(_selectedIncentive);
                      final sel = await _showCupertinoPicker<String>(
                        items: _incentiveOptions,
                        initialIndex: idx < 0 ? 0 : idx,
                      );
                      if (sel != null) {
                        setState(() {
                          _selectedIncentive = sel;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 6),
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
                    itemBuilder: (context, i) => _AmountField(
                      label: monthNames[i],
                      controller: _netSalaryControllers[i],
                      onChangedCascade: () => _autoFillMonths(i),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async => await _hesapla(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Hesapla'),
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

/// ===== Cupertino tarzı başlık+"kutucuk" alan (modal picker açar) =====
class _CupertinoField extends StatelessWidget {
  final String label;
  final String valueText; // boş ise 'Seçiniz' gösterilecek
  final VoidCallback onTap;
  final bool enabled;

  const _CupertinoField({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder = valueText.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.sFormLabel),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: enabled ? onTap : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.6,
              child: InputDecorator(
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                    borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                    borderSide: BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.2),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isPlaceholder ? 'Seçiniz' : valueText,
                        style: TextStyle(
                          color: isPlaceholder ? Colors.grey[700] : Colors.black87,
                          fontWeight: AppW.body,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== Ücret alanı (iç metin TL'siz, sağda sabit 'TL' suffix) =====
class _AmountField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChangedCascade;

  const _AmountField({
    required this.label,
    required this.controller,
    required this.onChangedCascade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 6,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 22, left: 8, right: 8, bottom: 6),
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Net Ücret',
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: InputBorder.none,
                suffix: Text('TL', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              maxLines: 1,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: (_) => onChangedCascade(),
              onEditingComplete: () {
                FocusScope.of(context).unfocus();
                if (controller.text.trim().isNotEmpty) {
                  final val = _parseCurrencyForAmountField(controller.text);
                  controller.text = _formatPlainForAmountField(val);
                }
              },
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _parseCurrencyForAmountField(String text) {
    if (text.trim().isEmpty) return 0.0;
    String t = text.replaceAll(' TL', '').replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(t) ?? 0.0;
  }

  String _formatPlainForAmountField(double n) {
    final neg = n < 0;
    n = n.abs();
    final fixed = n.toStringAsFixed(2);
    final parts = fixed.split('.');
    String intPart = parts[0];
    final frac = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    return '${neg ? '-' : ''}${buf.toString()},$frac';
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
        title: const Text(
          'Hesaplama Sonuçları',
          style: TextStyle(color: Colors.indigo),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
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
            icon: const Icon(Icons.share, color: Colors.indigo),
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