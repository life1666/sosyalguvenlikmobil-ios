import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../sonhesaplama/sonhesaplama.dart';
import '../utils/analytics_helper.dart';
import '../utils/theme_helper.dart';

/// =================== GLOBAL STIL & KNOB’LAR (Referans) ===================

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

/// ===== YAZILI ÖZET MADDE KNOB’LARI =====
const EdgeInsets kSumItemPadding = EdgeInsets.symmetric(vertical: 4, horizontal: 0);
const double kSumItemFontScale = 1.10;

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

/// ----------------------------------------------
///  TEMA
/// ----------------------------------------------
ThemeData uygulamaTemasi = (() {
  final double sizeTitleLg = 16.5 * kTextScale;
  final double sizeTitleMd = 15 * kTextScale;
  final double sizeBody = 13.5 * kTextScale;
  final double sizeSmall = 12.5 * kTextScale;
  final double sizeAppBar = 20.5 * kTextScale;

  // ThemeHelper'dan tema rengini al
  final themeHelper = ThemeHelper();
  final themeColor = themeHelper.themeColor;

  final colorScheme = ColorScheme.fromSeed(seedColor: themeColor);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: themeColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: sizeAppBar,
        fontWeight: AppW.appBarTitle,
        color: Colors.white,
        letterSpacing: 0.15,
        height: 1.22,
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
      titleMedium: TextStyle(
        fontSize: sizeTitleMd,
        fontWeight: AppW.heading,
        color: kTextColor,
        letterSpacing: 0.2,
        height: 1.22,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodyMedium: TextStyle(
        fontSize: sizeBody,
        color: kTextColor,
        fontWeight: AppW.body,
        height: 1.4,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodySmall: TextStyle(
        fontSize: sizeSmall,
        color: Colors.black87,
        fontWeight: AppW.minor,
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
      hintStyle: TextStyle(fontSize: 13 * kTextScale, color: Colors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
})();

/// ======================
///  BASIT FORMAT / ARAÇLAR
/// ======================

double _parseCurrency(String text) {
  if (text.trim().isEmpty) return 0.0;
  String t = text.replaceAll(' TL', '').replaceAll('.', '').replaceAll(',', '.').trim();
  return double.tryParse(t) ?? 0.0;
}

String _formatCurrency(double n) {
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
  return '${neg ? '-' : ''}${buf.toString()},$frac TL';
}

/// TL’siz ama aynı nokta/virgül kuralı
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

/// ======================
///  ✅ KURUŞ (INT) MOTOR YARDIMCILARI  (KURUŞ HATASINI KÖKTEN BİTİRİR)
/// ======================
int _toKurus(double tl) => (tl * 100).round();
double _fromKurus(int kurus) => kurus / 100.0;

int _parseCurrencyToKurus(String text) {
  if (text.trim().isEmpty) return 0;
  final t = text
      .replaceAll(' TL', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();
  final d = double.tryParse(t) ?? 0.0;
  return _toKurus(d);
}

String _formatCurrencyFromKurus(int kurus) => _formatCurrency(_fromKurus(kurus));

int _mulRateKurus(int baseKurus, double rate) => (baseKurus * rate).round();
int _minInt(int a, int b) => a < b ? a : b;
int _maxInt(int a, int b) => a > b ? a : b;

/// ===== CENTER NOTICE (mini) =====
enum AppNoticeType { error, info, success, warning }

Future<void> showCenterNotice(
    BuildContext context, {
      required String message,
      AppNoticeType type = AppNoticeType.info,
    }) async {
  final snack = SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.black.withOpacity(.85),
    content: Text(message, style: const TextStyle(color: Colors.white)),
    duration: const Duration(seconds: 2),
  );
  ScaffoldMessenger.of(context).showSnackBar(snack);
}

/// ===== Cupertino tarzı başlık+“kutucuk” alan (modal picker açar) =====
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
                hintText: 'Brüt Ücret',
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
                  final val = _parseCurrency(controller.text);
                  controller.text = _formatPlain(val);
                }
              },
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: .2, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const SalaryCalculatorApp());
}

class SalaryCalculatorApp extends StatelessWidget {
  const SalaryCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brütten Nete Maaş Hesaplama',
      theme: uygulamaTemasi,
      home: const SalaryCalculatorScreen(),
    );
  }
}

class SalaryCalculatorScreen extends StatefulWidget {
  const SalaryCalculatorScreen({super.key});

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  final List<TextEditingController> _gross = List.generate(12, (_) => TextEditingController());

  final List<int> _years = const [2022, 2023, 2024, 2025, 2026];
  int _selectedYearInternal = 2026;
  bool _pickedYear = false;

  final List<String> _employeeStatusOptions = const ["Normal Çalışan", "SGDP Kapsamında Çalışan"];
  String _employeeStatusInternal = "Normal Çalışan";
  bool _pickedStatus = false;

  List<String> _incentiveOptions = const ["Teşvik Yok", "2 Puan", "4 Puan", "5 Puan"];
  String _selectedIncentiveInternal = "Teşvik Yok";
  bool _pickedIncentive = false;

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

  List<DataRow> _monthlyRows = [];
  String? _errorMessage;

  static const List<String> monthNames = [
    'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('brutten_nete_opened');
    _updateConstants(_selectedYearInternal);
  }

  @override
  void dispose() {
    for (final c in _gross) { c.dispose(); }
    super.dispose();
  }

  void _autoFillMonths(int startIndex) {
    if (_gross[startIndex].text.trim().isEmpty) {
      for (int i = startIndex + 1; i < 12; i++) {
        _gross[i].clear();
      }
    } else {
      final value = _parseCurrency(_gross[startIndex].text);
      final formatted = _formatPlain(value);
      for (int i = startIndex + 1; i < 12; i++) {
        _gross[i].text = formatted;
      }
    }
  }

  void _updateConstants(int year) {
    if (_employeeStatusInternal == "SGDP Kapsamında Çalışan") {
      sgkEmployeeRate = 0.075;
      unemploymentEmployeeRate = 0.0;
      unemploymentEmployerRate = 0.0;

      sgkEmployerBaseRate = 0.225;

      _incentiveOptions = (year == 2023 || year == 2024)
          ? ["Teşvik Yok", "5 Puan"]
          : ["Teşvik Yok"];
    } else {
      sgkEmployeeRate = 0.14;
      unemploymentEmployeeRate = 0.01;
      unemploymentEmployerRate = 0.02;

      sgkEmployerBaseRate = (year >= 2026) ? 0.195 : 0.185;

      if (year >= 2026) {
        _incentiveOptions = ["Teşvik Yok", "2 Puan", "5 Puan"];
        if (_selectedIncentiveInternal == "4 Puan") {
          _selectedIncentiveInternal = "2 Puan";
        }
      } else if (year == 2025) {
        _incentiveOptions = ["Teşvik Yok", "4 Puan", "5 Puan"];
      } else {
        _incentiveOptions = ["Teşvik Yok", "5 Puan"];
      }
    }

    if (!_incentiveOptions.contains(_selectedIncentiveInternal)) {
      _selectedIncentiveInternal = _incentiveOptions.first;
    }

    stampTaxRate = 0.00759;

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
    } else if (year == 2025) {
      minWage = 26005.50;
      taxBrackets = [158000, 330000, 1200000, 4300000];
      taxRates = [0.15, 0.20, 0.27, 0.35, 0.40];
    } else if (year == 2026) {
      minWage = 33030.00;
      taxBrackets = [190000, 400000, 1500000, 5300000];
      taxRates = [0.15, 0.20, 0.27, 0.35, 0.40];
    } else {
      minWage = 33030.00;
      taxBrackets = [190000, 400000, 1500000, 5300000];
      taxRates = [0.15, 0.20, 0.27, 0.35, 0.40];
    }

    minWageTaxableBase = minWage * (1 - sgkEmployeeRate - unemploymentEmployeeRate);

    setState(() {});
  }

  double getExemptionTaxAmount(int monthIndex) {
    if (_selectedYearInternal == 2022) {
      if (monthIndex < 6) return 638.01;
      if (monthIndex == 6) return 825.05;
      if (monthIndex == 7) return 1051.11;
      return 1100.07;
    } else if (_selectedYearInternal == 2023) {
      if (monthIndex < 6) return 1276.02;
      if (monthIndex == 6) return 1710.35;
      if (monthIndex == 7) return 1902.62;
      return 2280.46;
    } else if (_selectedYearInternal == 2024) {
      if (monthIndex < 6) return 2550.32;
      if (monthIndex == 6) return 3001.06;
      return 3400.42;
    } else if (_selectedYearInternal == 2025) {
      if (monthIndex < 7) return 3315.70;
      if (monthIndex == 7) return 4257.57;
      return 4420.93;
    } else if (_selectedYearInternal == 2026) {
      if (monthIndex < 6) return 4211.33;
      if (monthIndex == 6) return 4537.75;
      return 5615.10;
    }
    return 0.0;
  }

  int _getExemptionTaxAmountK(int monthIndex) => _toKurus(getExemptionTaxAmount(monthIndex));

  /// ✅ KURUŞ bazlı gelir vergisi (double drift yok)
  Map<String, int> _incomeTaxCalcKurus({
    required int monthlyTaxableIncomeK,
    required int cumulativeTaxableIncomeBeforeExemptionK,
    required int cumulativeTaxableIncomeBeforeExemptionPrevK,
    required int monthIndex,
    required int minWageTaxableBaseK,
    required List<int> taxBracketsK,
  }) {
    if (monthlyTaxableIncomeK <= 0) {
      return {
        'taxK': 0,
        'exemptionK': 0,
        'taxableIncomeAfterExemptionK': 0,
        'taxBeforeExemptionK': 0,
      };
    }

    final exemptionBaseK = monthlyTaxableIncomeK >= minWageTaxableBaseK
        ? minWageTaxableBaseK
        : monthlyTaxableIncomeK;

    final taxableAfterExemptionMatrahK = monthlyTaxableIncomeK - exemptionBaseK;

    int totalBP = 0;
    int rem = cumulativeTaxableIncomeBeforeExemptionK;
    int prevLimit = 0;

    for (int i = 0; i < taxBracketsK.length + 1; i++) {
      if (rem <= 0) break;

      final limitK = i < taxBracketsK.length ? taxBracketsK[i] : rem;
      final sliceK = rem > (limitK - prevLimit) ? (limitK - prevLimit) : rem;

      final ratePercent = (taxRates[i] * 100).round(); // 0.15 -> 15
      totalBP += sliceK * ratePercent;

      prevLimit = limitK;
      rem -= sliceK;
    }

    int prevBP = 0;
    rem = cumulativeTaxableIncomeBeforeExemptionPrevK;
    prevLimit = 0;

    for (int i = 0; i < taxBracketsK.length + 1; i++) {
      if (rem <= 0) break;

      final limitK = i < taxBracketsK.length ? taxBracketsK[i] : rem;
      final sliceK = rem > (limitK - prevLimit) ? (limitK - prevLimit) : rem;

      final ratePercent = (taxRates[i] * 100).round();
      prevBP += sliceK * ratePercent;

      prevLimit = limitK;
      rem -= sliceK;
    }

    final monthlyBPdiff = totalBP - prevBP;

    // (kuruş * yüzde)/100 => kuruş; half-up için +50
    final taxBeforeExemptionK = (monthlyBPdiff + 50) ~/ 100;

    final exemptionTaxK = _getExemptionTaxAmountK(monthIndex);
    int monthlyTaxK = taxBeforeExemptionK - exemptionTaxK;
    if (monthlyTaxK < 0) monthlyTaxK = 0;

    return {
      'taxK': monthlyTaxK,
      'exemptionK': exemptionTaxK,
      'taxableIncomeAfterExemptionK': taxableAfterExemptionMatrahK,
      'taxBeforeExemptionK': taxBeforeExemptionK,
    };
  }

  bool _validateInputs() {
    for (final c in _gross) {
      if (c.text.trim().isNotEmpty && _parseCurrency(c.text) > 0) return true;
    }
    setState(() {
      _monthlyRows = [];
      _errorMessage = 'Lütfen en az bir ay için geçerli bir brüt maaş giriniz!';
    });
    return false;
  }

  Future<void> _hesapla() async {
    setState(() {
      _errorMessage = null;
      _monthlyRows.clear();
    });

    if (!_validateInputs()) return;

    for (final c in _gross) {
      if (c.text.trim().isNotEmpty) {
        final v = _parseCurrency(c.text);
        if (v <= 0) {
          setState(() {
            _monthlyRows = [];
            _errorMessage = 'Brüt maaş sıfır veya negatif olamaz!';
          });
          return;
        }
        c.text = _formatPlain(v);
      }
    }

    _calculateNetSalaryForYear();

    try {
      final monthlyNetSalaries = _getNetSalaries(_monthlyRows);
      final avgNet = _calcAverageNet(_monthlyRows);
      final yearlyNet = _calcSumNet(_monthlyRows);

      final veriler = <String, dynamic>{
        'yil': _selectedYearInternal,
        'calisanDurumu': _employeeStatusInternal,
        'tesvik': _selectedIncentiveInternal,
      };

      final sonuclar = <String, String>{
        'Yıl': _selectedYearInternal.toString(),
        'Ortalama Net Maaş': _formatCurrency(avgNet),
        'Yıllık Toplam Net Maaş': _formatCurrency(yearlyNet),
      };

      final sonHesaplama = SonHesaplama(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hesaplamaTuru: 'Brütten Nete Maaş Hesaplama',
        tarihSaat: DateTime.now(),
        veriler: veriler,
        sonuclar: sonuclar,
        ozet: 'Brütten nete maaş hesaplaması tamamlandı',
      );

      await SonHesaplamalarDeposu.ekle(sonHesaplama);

      AnalyticsHelper.logCalculation('brutten_nete', parameters: {
        'hesaplama_turu': 'Brütten Nete Maaş',
      });
    } catch (e) {
      debugPrint('Son hesaplama kaydedilirken hata: $e');
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          selectedYear: _selectedYearInternal,
          monthlyRows: _monthlyRows,
          monthNames: monthNames,
          monthlyNetSalaries: _getNetSalaries(_monthlyRows),
          firstMonthNet: _monthlyRows.length > 1 ? _getCellNet(_monthlyRows[0]) : 0,
          lastMonthNet: _monthlyRows.length > 1 ? _getCellNet(_monthlyRows[_monthlyRows.length - 2]) : 0,
          avgNet: _calcAverageNet(_monthlyRows),
          yearlyNet: _calcSumNet(_monthlyRows),
          avgEmployerCost: _calcAverageEmployerCost(_monthlyRows),
          yearlyEmployerCost: _calcSumEmployerCost(_monthlyRows),
        ),
      ),
    );
  }

  /// ✅ KURUŞ MOTORLU NET HESAP (1 kuruş farkları biter)
  void _calculateNetSalaryForYear() {
    List<DataRow> monthlyRows = [];

    int cumulativeTaxableIncomeBeforeExemptionK = 0;

    int cumulativeIncomeTaxK = 0;
    int totalNetSalaryK = 0;
    int totalEmployerCostK = 0;
    int totalIncomeTaxExemptionK = 0;
    int totalStampTaxExemptionK = 0;
    int totalGrossSalaryK = 0;

    int totalSgkEmployeeDeductionK = 0;
    int totalUnemploymentEmployeeDeductionK = 0;
    int totalStampTaxK = 0;

    int totalSgkEmployerDeductionK = 0;
    int totalUnemploymentEmployerDeductionK = 0;

    int totalTaxBeforeExemptionK = 0;
    int totalStampTaxBeforeExemptionK = 0;

    final taxBracketsK = taxBrackets.map((x) => _toKurus(x)).toList();

    for (int month = 0; month < 12; month++) {
      final double shortTermRate =
      (_selectedYearInternal < 2024 || (_selectedYearInternal == 2024 && month < 8))
          ? 0.02
          : 0.0225;

      sgkEmployerRate = sgkEmployerBaseRate + shortTermRate;

      final raw = _gross[month].text.trim();
      final grossK = _parseCurrencyToKurus(raw);
      if (grossK <= 0) continue;

      // Asgari (ay bazlı)
      if (_selectedYearInternal == 2022) {
        minWage = month < 6 ? 5004.00 : 6471.00;
      } else if (_selectedYearInternal == 2023) {
        minWage = month < 6 ? 10008.00 : 13414.50;
      } else if (_selectedYearInternal == 2024) {
        minWage = 20002.50;
      } else if (_selectedYearInternal == 2025) {
        minWage = 26005.50;
      } else if (_selectedYearInternal == 2026) {
        minWage = 33030.00;
      }

      final minWageKLocal = _toKurus(minWage);

      // Asgari vergi matrahı (kuruş)
      final sgkMinEmpK = _mulRateKurus(minWageKLocal, sgkEmployeeRate);
      final unempMinEmpK = _mulRateKurus(minWageKLocal, unemploymentEmployeeRate);
      final minWageTaxableBaseKLocal = minWageKLocal - sgkMinEmpK - unempMinEmpK;

      // SGK tavan
      final double sgkCeilingMultiplier = (_selectedYearInternal >= 2026) ? 9.0 : 7.5;
      final sgkCeilingK = (minWageKLocal * sgkCeilingMultiplier).round();
      final sgkBaseK = _minInt(grossK, sgkCeilingK);

      // SGDP 2024 özel işveren oranı
      if (_employeeStatusInternal == "SGDP Kapsamında Çalışan" && _selectedYearInternal == 2024) {
        sgkEmployerRate = month < 8 ? 0.245 : 0.2475;
      }

      // Teşvik
      final originalEmployerRate = sgkEmployerRate;
      double incentiveRate = 0.0;

      if (_employeeStatusInternal == "SGDP Kapsamında Çalışan") {
        if (_selectedIncentiveInternal == "5 Puan" &&
            (_selectedYearInternal == 2023 || _selectedYearInternal == 2024)) {
          incentiveRate = 0.05;
        }
      } else {
        if (_selectedIncentiveInternal == "5 Puan") {
          incentiveRate = 0.05;
        } else if (_selectedIncentiveInternal == "4 Puan" && _selectedYearInternal == 2025) {
          incentiveRate = 0.04;
        } else if (_selectedIncentiveInternal == "2 Puan" && _selectedYearInternal >= 2026) {
          incentiveRate = 0.02;
        }
      }

      final effEmployerRate = originalEmployerRate - incentiveRate;

      // Kesintiler
      final sgkEmployeeDedK = _mulRateKurus(sgkBaseK, sgkEmployeeRate);
      final unemploymentEmployeeDedK = _mulRateKurus(sgkBaseK, unemploymentEmployeeRate);
      final totalEmployeeDedK = sgkEmployeeDedK + unemploymentEmployeeDedK;

      final sgkEmployerDedK = _mulRateKurus(sgkBaseK, effEmployerRate);

      // ✅ işveren işsizlik de SGK base üzerinden (tavanlı)
      final unemploymentEmployerDedK = _mulRateKurus(sgkBaseK, unemploymentEmployerRate);

      final totalEmployerDedK = sgkEmployerDedK + unemploymentEmployerDedK;

      // Vergi matrahı
      final taxableBaseK = grossK - totalEmployeeDedK;

      final prevCumK = cumulativeTaxableIncomeBeforeExemptionK;
      cumulativeTaxableIncomeBeforeExemptionK += taxableBaseK;

      final taxResK = _incomeTaxCalcKurus(
        monthlyTaxableIncomeK: taxableBaseK,
        cumulativeTaxableIncomeBeforeExemptionK: cumulativeTaxableIncomeBeforeExemptionK,
        cumulativeTaxableIncomeBeforeExemptionPrevK: prevCumK,
        monthIndex: month,
        minWageTaxableBaseK: minWageTaxableBaseKLocal,
        taxBracketsK: taxBracketsK,
      );

      // Damga
      final stampBeforeK = _mulRateKurus(grossK, stampTaxRate);
      final stampExK = _mulRateKurus(minWageKLocal, stampTaxRate);
      final stampK = _maxInt(0, stampBeforeK - stampExK);

      // Net & maliyet
      final totalDeductionsK = totalEmployeeDedK + taxResK['taxK']! + stampK;
      final netK = grossK - totalDeductionsK;
      final employerCostK = grossK + totalEmployerDedK;

      monthlyRows.add(DataRow(cells: [
        DataCell(Text(monthNames[month])),
        DataCell(Text(_formatCurrencyFromKurus(grossK))),
        DataCell(Text(_formatCurrencyFromKurus(netK))),
        DataCell(Text(_formatCurrencyFromKurus(sgkEmployeeDedK))),
        DataCell(Text(_formatCurrencyFromKurus(unemploymentEmployeeDedK))),
        DataCell(Text(_formatCurrencyFromKurus(sgkEmployerDedK))),
        DataCell(Text(_formatCurrencyFromKurus(unemploymentEmployerDedK))),
        DataCell(Text(_formatCurrencyFromKurus(taxResK['taxK']!))),
        DataCell(Text(_formatCurrencyFromKurus(cumulativeTaxableIncomeBeforeExemptionK))),
        DataCell(Text(_formatCurrencyFromKurus(taxResK['taxBeforeExemptionK']!))),
        DataCell(Text(_formatCurrencyFromKurus(taxResK['exemptionK']!))),
        DataCell(Text(_formatCurrencyFromKurus(stampK))),
        DataCell(Text(_formatCurrencyFromKurus(stampBeforeK))),
        DataCell(Text(_formatCurrencyFromKurus(stampExK))),
        DataCell(Text(_formatCurrencyFromKurus(employerCostK))),
      ]));

      // Toplamlar
      totalGrossSalaryK += grossK;
      totalNetSalaryK += netK;

      totalSgkEmployeeDeductionK += sgkEmployeeDedK;
      totalUnemploymentEmployeeDeductionK += unemploymentEmployeeDedK;

      cumulativeIncomeTaxK += taxResK['taxK']!;
      totalStampTaxK += stampK;

      totalSgkEmployerDeductionK += sgkEmployerDedK;
      totalUnemploymentEmployerDeductionK += unemploymentEmployerDedK;

      totalEmployerCostK += employerCostK;

      totalIncomeTaxExemptionK += taxResK['exemptionK']!;
      totalStampTaxExemptionK += stampExK;

      totalTaxBeforeExemptionK += taxResK['taxBeforeExemptionK']!;
      totalStampTaxBeforeExemptionK += stampBeforeK;
    }

    monthlyRows.add(DataRow(cells: [
      const DataCell(Text('Toplam', style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(_formatCurrencyFromKurus(totalGrossSalaryK))),
      DataCell(Text(_formatCurrencyFromKurus(totalNetSalaryK))),
      DataCell(Text(_formatCurrencyFromKurus(totalSgkEmployeeDeductionK))),
      DataCell(Text(_formatCurrencyFromKurus(totalUnemploymentEmployeeDeductionK))),
      DataCell(Text(_formatCurrencyFromKurus(totalSgkEmployerDeductionK))),
      DataCell(Text(_formatCurrencyFromKurus(totalUnemploymentEmployerDeductionK))),
      DataCell(Text(_formatCurrencyFromKurus(cumulativeIncomeTaxK))),
      DataCell(Text(_formatCurrencyFromKurus(cumulativeTaxableIncomeBeforeExemptionK))),
      DataCell(Text(_formatCurrencyFromKurus(totalTaxBeforeExemptionK))),
      DataCell(Text(_formatCurrencyFromKurus(totalIncomeTaxExemptionK))),
      DataCell(Text(_formatCurrencyFromKurus(totalStampTaxK))),
      DataCell(Text(_formatCurrencyFromKurus(totalStampTaxBeforeExemptionK))),
      DataCell(Text(_formatCurrencyFromKurus(totalStampTaxExemptionK))),
      DataCell(Text(_formatCurrencyFromKurus(totalEmployerCostK))),
    ]));

    setState(() {
      _monthlyRows = monthlyRows;
      _errorMessage = monthlyRows.isNotEmpty ? '' : 'Hesaplama yapılamadı!';
    });
  }

  // --- Sonuç ekranına hazırlık ---
  List<double> _getNetSalaries(List<DataRow> rows) {
    final nets = <double>[];
    for (int i = 0; i < 12 && i < rows.length - 1; i++) {
      nets.add(_cellToDouble(rows[i].cells[2]));
    }
    return nets;
  }

  double _cellToDouble(DataCell cell) {
    final text = cell.child is Text ? (cell.child as Text).data ?? '' : '';
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.').replaceAll(' TL', '')) ?? 0;
  }

  double _getCellNet(DataRow row) => _cellToDouble(row.cells[2]);

  double _calcAverageNet(List<DataRow> rows) {
    double sum = 0;
    int n = 0;
    for (int i = 0; i < 12 && i < rows.length - 1; i++) {
      sum += _cellToDouble(rows[i].cells[2]); n++;
    }
    return n == 0 ? 0 : (sum / n);
  }

  double _calcSumNet(List<DataRow> rows) {
    double sum = 0;
    for (int i = 0; i < 12 && i < rows.length - 1; i++) {
      sum += _cellToDouble(rows[i].cells[2]);
    }
    return sum;
  }

  double _calcAverageEmployerCost(List<DataRow> rows) {
    double sum = 0; int n = 0;
    for (int i = 0; i < 12 && i < rows.length - 1; i++) {
      sum += _cellToDouble(rows[i].cells.last); n++;
    }
    return n == 0 ? 0 : (sum / n);
  }

  double _calcSumEmployerCost(List<DataRow> rows) {
    double sum = 0;
    for (int i = 0; i < 12 && i < rows.length - 1; i++) {
      sum += _cellToDouble(rows[i].cells.last);
    }
    return sum;
  }

  // === Cupertino Picker ===
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
            const Divider(height: 0),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 30,
                scrollController: FixedExtentScrollController(initialItem: sel),
                onSelectedItemChanged: (i) => sel = i,
                children: [
                  for (final s in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(child: itemBuilder?.call(s) ?? Text('$s')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === UI ===
  @override
  Widget build(BuildContext context) {
    final yearLabel = _pickedYear ? '$_selectedYearInternal' : '';
    final statusLabel = _pickedStatus ? _employeeStatusInternal : '';
    final incentiveLabel = _pickedIncentive ? _selectedIncentiveInternal : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Brütten Nete Maaş Hesaplama',
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
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CupertinoField(
                    label: 'Yıl Seçiniz',
                    valueText: yearLabel,
                    onTap: () async {
                      final idx = _years.indexOf(_selectedYearInternal);
                      final sel = await _showCupertinoPicker<int>(
                        items: _years, initialIndex: idx < 0 ? 0 : idx,
                        itemBuilder: (y) => Text('$y'),
                      );
                      if (sel != null) {
                        for (final c in _gross) { c.clear(); }
                        setState(() {
                          _pickedYear = true;
                          _selectedYearInternal = sel;
                          _monthlyRows.clear(); _errorMessage = null;
                        });
                        _updateConstants(sel);
                      }
                    },
                  ),

                  _CupertinoField(
                    label: 'Çalışan Statüsü',
                    valueText: statusLabel,
                    onTap: () async {
                      final idx = _employeeStatusOptions.indexOf(_employeeStatusInternal);
                      final sel = await _showCupertinoPicker<String>(
                        items: _employeeStatusOptions, initialIndex: idx < 0 ? 0 : idx,
                      );
                      if (sel != null) {
                        setState(() {
                          _pickedStatus = true;
                          _employeeStatusInternal = sel;
                        });
                        _updateConstants(_selectedYearInternal);
                      }
                    },
                  ),

                  _CupertinoField(
                    label: 'Teşvik Seçiniz',
                    valueText: incentiveLabel,
                    onTap: () async {
                      final idx = _incentiveOptions.indexOf(_selectedIncentiveInternal);
                      final sel = await _showCupertinoPicker<String>(
                        items: _incentiveOptions, initialIndex: idx < 0 ? 0 : idx,
                      );
                      if (sel != null) {
                        setState(() {
                          _pickedIncentive = true;
                          _selectedIncentiveInternal = sel;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 6),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, childAspectRatio: 1.7, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, i) => _AmountField(
                      label: monthNames[i],
                      controller: _gross[i],
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
                  if ((_errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),

            const Divider(thickness: 0.2, height: 12),
            const _InfoNotice(),
          ],
        ),
      ),
    );
  }
}

// --- Bilgilendirme bloğu ---
class _InfoNotice extends StatelessWidget {
  const _InfoNotice();

  @override
  Widget build(BuildContext context) {
    const maddeler = [
      'Sosyal Güvenlik Mobil, Herhangi Bir Resmi Kurumun Uygulaması Değildir!',
      'Yapılan Hesaplamalar Tahmini ve Bilgi Amaçlıdır, Resmi Nitelik Taşımaz ve Herhangi Bir Sorumluluk Doğurmaz!',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('Bilgilendirme',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w300, color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (final m in maddeler) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.black26, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m, style: const TextStyle(
                    fontWeight: AppW.body, color: Colors.black, fontSize: 12, height: 1.3,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// =====================
/// AŞAĞISI: Senin projende zaten var olan ResultsScreen, Tabs, Chart painter…
///// (BUNLARI DEĞİŞTİRMEDİM - SENİN GÖNDERDİĞİN GİBİ KALACAK)
/// =====================

class ResultsScreen extends StatelessWidget {
  final int selectedYear;
  final List<DataRow> monthlyRows;
  final List<String> monthNames;
  final List<double> monthlyNetSalaries;
  final double firstMonthNet;
  final double lastMonthNet;
  final double avgNet;
  final double yearlyNet;
  final double avgEmployerCost;
  final double yearlyEmployerCost;

  const ResultsScreen({
    super.key,
    required this.selectedYear,
    required this.monthlyRows,
    required this.monthNames,
    required this.monthlyNetSalaries,
    required this.firstMonthNet,
    required this.lastMonthNet,
    required this.avgNet,
    required this.yearlyNet,
    required this.avgEmployerCost,
    required this.yearlyEmployerCost,
  });

  Future<void> _shareAsPdf(BuildContext context) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final List<String> pdfHeaders = [
      'Ay', 'Brüt Ücret', 'Net Ücret', 'SGK İşçi Payı', 'İşsizlik İşçi Payı',
      'SGK İşveren Payı', 'İşsizlik İşveren Payı', 'Gelir Vergisi',
      'Kümülatif G.V. Matrahı', 'İstisna Öncesi G.V.', 'Asgari Ücret G.V. İstisnası',
      'Damga Vergisi', 'İstisna Öncesi D.V.', 'Damga Vergisi İstisnası',
      'Toplam Maliyet',
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
            'Brütten Nete Maaş Hesaplama Sonuçları - $selectedYear',
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
    final file = File("${output.path}/brutten_nete_hesaplama_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Brütten Nete Maaş Hesaplama Sonuçları');
  }

  Future<void> _shareAsExcel(BuildContext context) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow([
      'Ay', 'Brüt Ücret', 'Net Ücret', 'SGK İşçi Payı', 'İşsizlik İşçi Payı',
      'SGK İşveren Payı', 'İşsizlik İşveren Payı', 'Gelir Vergisi',
      'Kümülatif G.V. Matrahı', 'İstisna Öncesi G.V.', 'Asgari Ücret G.V. İstisnası',
      'Damga Vergisi', 'İstisna Öncesi D.V.', 'Damga Vergisi İstisnası',
      'Toplam Maliyet'
    ]);
    for (var row in monthlyRows) {
      sheet.appendRow(row.cells.map((cell) {
        if (cell.child is Text) {
          return (cell.child as Text).data?.replaceAll(' TL', '') ?? '';
        }
        return '';
      }).toList());
    }
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/brutten_nete_hesaplama_${DateTime.now().millisecondsSinceEpoch}.xlsx");
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)], text: 'Brütten Nete Maaş Hesaplama Sonuçları');
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
        child: Column(
          children: [
            CalculationResultTabs(
              monthlyRows: monthlyRows,
              monthNames: monthNames,
              monthlyNetSalaries: monthlyNetSalaries,
              firstMonthNet: firstMonthNet,
              lastMonthNet: lastMonthNet,
              avgNet: avgNet,
              yearlyNet: yearlyNet,
              avgEmployerCost: avgEmployerCost,
              yearlyEmployerCost: yearlyEmployerCost,
            ),
          ],
        ),
      ),
    );
  }
}

// --- TABLI-LİSTE-GRAFİK SEKMELERİ ---
// (Aşağısı senin attığın gibi aynı; değiştirmedim.)
class CalculationResultTabs extends StatefulWidget {
  final List<DataRow> monthlyRows;
  final List<String> monthNames;
  final List<double> monthlyNetSalaries;
  final double firstMonthNet;
  final double lastMonthNet;
  final double avgNet;
  final double yearlyNet;
  final double avgEmployerCost;
  final double yearlyEmployerCost;

  const CalculationResultTabs({
    Key? key,
    required this.monthlyRows,
    required this.monthNames,
    required this.monthlyNetSalaries,
    required this.firstMonthNet,
    required this.lastMonthNet,
    required this.avgNet,
    required this.yearlyNet,
    required this.avgEmployerCost,
    required this.yearlyEmployerCost,
  }) : super(key: key);

  @override
  State<CalculationResultTabs> createState() => _CalculationResultTabsState();
}

class _CalculationResultTabsState extends State<CalculationResultTabs> {
  int _selectedTab = 1;

  static const double _rowHeight = 50;
  static const double _headHeight = 56;
  static const double _tableDivider = 1.0;
  static const Color _tableDividerColor = Colors.black26;

  final ScrollController _leftVController = ScrollController();
  final ScrollController _rightVController = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _rightVController.addListener(() {
      if (_syncing) return;
      _syncing = true;
      _leftVController.jumpTo(_rightVController.position.pixels);
      _syncing = false;
    });
    _leftVController.addListener(() {
      if (_syncing) return;
      _syncing = true;
      _rightVController.jumpTo(_leftVController.position.pixels);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _leftVController.dispose();
    _rightVController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              backgroundColor: Colors.black12.withOpacity(.08),
              thumbColor: Colors.black12.withOpacity(.20),
              groupValue: _selectedTab,
              children: const {
                0: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Liste', style: TextStyle(color: Colors.black87))),
                1: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tablo', style: TextStyle(color: Colors.black87))),
                2: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Grafik', style: TextStyle(color: Colors.black87))),
              },
              onValueChanged: (v) => setState(() => _selectedTab = v ?? 1),
            ),
          ),
        ),
        if (_selectedTab == 0) _buildListTab()
        else if (_selectedTab == 1) _buildTableTabFrozenFirstColumn()
        else _buildChartTab(),
      ],
    );
  }

  Widget _buildTableTabFrozenFirstColumn() {
    if (widget.monthlyRows.isEmpty) {
      return const SizedBox.shrink();
    }

    final leftHeader = const Text('Ay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14));
    final rightColumns = const [
      DataColumn(label: Text('Brüt Ücret')),
      DataColumn(label: Text('Net Ücret')),
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
    ];

    final leftRows = <Widget>[];
    for (int i = 0; i < widget.monthlyRows.length; i++) {
      final monthCell = widget.monthlyRows[i].cells.first;
      final isLast = i == widget.monthlyRows.length - 1;

      leftRows.add(Container(
        height: _rowHeight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: !isLast
                ? const BorderSide(color: _tableDividerColor, width: _tableDivider)
                : BorderSide.none,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.black87),
          child: monthCell.child,
        ),
      ));
    }

    final rightRows = widget.monthlyRows.map((r) => DataRow(cells: r.cells.sublist(1))).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: _headHeight,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.indigo,
              child: leftHeader,
            ),
            SizedBox(
              height: _rowHeight * leftRows.length,
              child: SingleChildScrollView(
                controller: _leftVController,
                child: Column(children: leftRows),
              ),
            ),
          ],
        ),

        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              controller: _rightVController,
              scrollDirection: Axis.vertical,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: _tableDividerColor,
                  dividerTheme: const DividerThemeData(
                    color: _tableDividerColor,
                    thickness: _tableDivider,
                  ),
                ),
                child: DataTable(
                  horizontalMargin: 12,
                  columnSpacing: 16,
                  dataRowHeight: _rowHeight,
                  headingRowHeight: _headHeight,
                  headingRowColor: const MaterialStatePropertyAll(Colors.indigo),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  columns: rightColumns,
                  rows: rightRows,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTab() {
    final rows = <Widget>[];
    for (int i = 0; i < 12 && i < widget.monthlyRows.length - 1; i++) {
      final row = widget.monthlyRows[i];
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                alignment: Alignment.center,
                child: Text('${i+1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text(widget.monthNames[i], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ]),
            const SizedBox(height: 6),
            _infoRow("Net Ücret", row.cells[2]),
            _infoRow("Brüt Ücret", row.cells[1]),
            _infoRow("İşveren Toplam Maliyet", row.cells.last),
            const Divider(height: 18),
          ],
        ),
      ));
    }
    final totalRow = widget.monthlyRows.isNotEmpty ? widget.monthlyRows.last : null;
    if (totalRow != null) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.summarize_rounded, color: Colors.black87, size: 28),
              SizedBox(width: 8),
              Text("YILLIK TOPLAM ve ORTALAMA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ]),
            const SizedBox(height: 6),
            _summaryRow("Yıllık Net Ücret", totalRow.cells[2]),
            _summaryRow("Aylık Ortalama Net", DataCell(Text(_formatCurrency(widget.avgNet)))),
            _summaryRow("Yıllık Toplam Maliyet", totalRow.cells.last),
            _summaryRow("Aylık Ortalama Maliyet", DataCell(Text(_formatCurrency(widget.avgEmployerCost)))),
          ],
        ),
      ));
    }
    return ListView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: rows);
  }

  Widget _infoRow(String label, DataCell cell) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
          Flexible(child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.black87), child: cell.child)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, DataCell cell) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          Flexible(child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.black87), child: cell.child)),
        ],
      ),
    );
  }

  Widget _buildChartTab() {
    final data = widget.monthlyNetSalaries;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Aylık Net Ücret Trend Grafiği',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(data, labels: monthlyNamesShort),
            ),
          ),
          const SizedBox(height: 10),
          _statLine("İlk Ay Net Ücret", widget.firstMonthNet),
          _statLine("Son Ay Net Ücret", widget.lastMonthNet),
          _statLine("Ortalama Net Ücret", widget.avgNet),
          _statLine("Yıllık Toplam Net Ücret", widget.yearlyNet),
        ],
      ),
    );
  }

  Widget _statLine(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
          ),
          Text(_formatCurrency(value),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }

  List<String> get monthlyNamesShort => const ['O','Ş','M','N','M','H','T','A','E','E','K','A'];
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;

  _LineChartPainter(this.data, {required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    if (data.isEmpty) return;

    final steps = 4;
    final minVal = data.reduce((a,b)=>a<b?a:b);
    final maxVal = data.reduce((a,b)=>a>b?a:b);
    final span = (maxVal - minVal).abs();
    final safeSpan = span == 0 ? 1 : span;

    TextPainter tp(String s, {TextStyle? style}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: style ?? const TextStyle(fontSize: 10, color: Colors.black87)),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    }

    double maxLabelW = 0;
    for (int i=0;i<=steps;i++) {
      final val = (minVal + (i/steps)*safeSpan);
      final painter = tp(_formatPlain(val));
      if (painter.width > maxLabelW) maxLabelW = painter.width;
    }

    final double leftPad = maxLabelW + 10;
    final double topPad = 16;
    final double rightPad = 10;
    final double bottomPad = 26;

    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );

    final axis = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    canvas.drawLine(chartRect.bottomLeft, chartRect.topLeft, axis);
    canvas.drawLine(chartRect.bottomLeft, chartRect.bottomRight, axis);

    final line = Paint()
      ..color = Colors.black54
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = chartRect.width / (data.length - 1).clamp(1, 999);
    Offset pointAt(int i) {
      final x = chartRect.left + i * stepX;
      final t = (data[i] - minVal) / safeSpan;
      final y = chartRect.bottom - t * chartRect.height;
      return Offset(x, y);
    }

    final first = pointAt(0);
    path.moveTo(first.dx, first.dy);
    fillPath.moveTo(chartRect.left, chartRect.bottom);
    fillPath.lineTo(first.dx, first.dy);

    for (int i=1;i<data.length;i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(chartRect.right, chartRect.bottom);
    fillPath.close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);

    final dot = Paint()..color = Colors.black87;
    for (int i=0;i<data.length;i++) {
      final p = pointAt(i);
      canvas.drawCircle(p, 3, dot);
    }

    for (int i=0;i<data.length;i++) {
      final p = pointAt(i);
      final t = tp(labels[i % labels.length]);
      t.paint(canvas, Offset(p.dx - t.width/2, chartRect.bottom + 4));
    }

    for (int i=0;i<=steps;i++) {
      final y = chartRect.bottom - (i/steps) * chartRect.height;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        Paint()..color = Colors.grey.withOpacity(0.25)..strokeWidth = 1,
      );
      final val = (minVal + (i/steps)*safeSpan);
      final labelPainter = tp(_formatPlain(val));
      labelPainter.paint(canvas, Offset(chartRect.left - 6 - labelPainter.width, y - labelPainter.height/2));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
