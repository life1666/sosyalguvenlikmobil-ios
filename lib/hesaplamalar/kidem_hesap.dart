import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../sonhesaplama/sonhesaplama.dart';
import '../utils/analytics_helper.dart';

/// =================== GLOBAL STIL & KNOB’LAR (Referans) ===================

const double kPageHPad = 16.0;
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

/// ===== RAPOR KNOB’LARI =====
const double kReportMaxWidth = 660.0;
const Color kResultSheetBg = Colors.white;
const double kResultSheetCorner = 22.0;
const double kResultHeaderScale = 1.00;
const FontWeight kResultHeaderWeight = FontWeight.w400;

/// ===== YAZILI ÖZET MADDE KNOB’LARI =====
const EdgeInsets kSumItemPadding =
EdgeInsets.symmetric(vertical: 4, horizontal: 0);
const double kSumItemFontScale = 1.10;

class AppW {
  static const appBarTitle = FontWeight.w700;
  static const heading = FontWeight.w500;
  static const body = FontWeight.w300;
  static const minor = FontWeight.w300;
  static const tableHead = FontWeight.w600;
}

extension AppText on BuildContext {
  TextStyle get sFormLabel => Theme.of(this).textTheme.titleLarge!;
}

/// ----------------------------------------------
///  TEMA (Referansla birebir)
/// ----------------------------------------------
ThemeData uygulamaTemasi = (() {
  final double sizeTitleLg = 16.5 * kTextScale;
  final double sizeTitleMd = 15 * kTextScale;
  final double sizeBody = 13.5 * kTextScale;
  final double sizeSmall = 12.5 * kTextScale;
  final double sizeAppBar = 20.5 * kTextScale;

  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.indigo[500],
      foregroundColor: Colors.white,
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
        borderSide:
        BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide:
        BorderSide(color: Colors.red, width: kFieldBorderWidth + 0.2),
      ),
      hintStyle: TextStyle(fontSize: 13 * kTextScale, color: Colors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
})();

/// ========== CENTER NOTICE (İKONSUZ) ==========
enum AppNoticeType { error, info, success, warning }

const double kCenterNoticeRadius = 16.0;
const double kCenterNoticeElevation = 0.0;
const EdgeInsets kCenterNoticePadding = EdgeInsets.fromLTRB(16, 14, 16, 16);
const Duration kCenterNoticeAnimDur = Duration(milliseconds: 220);
const Duration kCenterNoticeAutoHide = Duration(seconds: 2);

Future<void> showCenterNotice(
    BuildContext context, {
      String? title,
      required String message,
      AppNoticeType type = AppNoticeType.error,
      bool autoHide = true,
    }) async {
  Color bg, border, textMain;

  switch (type) {
    case AppNoticeType.success:
      bg = const Color(0xFFEFFBF3);
      border = const Color(0xFF22C55E).withOpacity(.35);
      textMain = const Color(0xFF065F46);
      break;
    case AppNoticeType.info:
      bg = const Color(0xFFF1F5FF);
      border = const Color(0xFF3B82F6).withOpacity(.35);
      textMain = const Color(0xFF1E3A8A);
      break;
    case AppNoticeType.warning:
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFF59E0B).withOpacity(.35);
      textMain = const Color(0xFF7C2D12);
      break;
    case AppNoticeType.error:
    default:
      bg = const Color(0xFFFFF3F2);
      border = const Color(0xFFEF4444).withOpacity(.35);
      textMain = const Color(0xFF7F1D1D);
  }

  final dialogChild = ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Material(
      color: bg,
      elevation: kCenterNoticeElevation,
      borderRadius: BorderRadius.circular(kCenterNoticeRadius),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCenterNoticeRadius),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: kCenterNoticePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && title.trim().isNotEmpty)
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: textMain,
                ),
              ),
            if (title != null && title.trim().isNotEmpty) const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMain,
                fontWeight: AppW.body,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final navigator = Navigator.of(context, rootNavigator: true);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'center-notice',
    barrierColor: Colors.black.withOpacity(0.25),
    transitionDuration: kCenterNoticeAnimDur,
    pageBuilder: (_, __, ___) => Center(child: dialogChild),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .98, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );

  if (autoHide) {
    await Future.delayed(kCenterNoticeAutoHide);
    if (navigator.mounted) navigator.pop();
  }
}

/// ======================
///  YARDIMCI FORMAT (intl yok)
/// ======================
String formatTL(double n) {
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

String formatPlain(double n) {
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

String formatDateDDMMYYYY(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

double parseTL(String input) {
  final normalized = input.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0.0;
}

/// CustomCurrencyFormatter — REFERANS KOD DAVRANIŞI
class CustomCurrencyFormatter extends TextInputFormatter {
  String _thousands(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buf.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    if (digitsOnly.length < 5) {
      return TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    }

    if (digitsOnly.length == 1) digitsOnly = '0$digitsOnly';

    final integerPart = digitsOnly.substring(0, digitsOnly.length - 2);
    final fractionalPart = digitsOnly.substring(digitsOnly.length - 2);
    final formattedInteger = _thousands(integerPart);
    final newText = '$formattedInteger,$fractionalPart';

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// =====================
///  APP
/// =====================
void main() {
  runApp(const CompensationApp());
}

class CompensationApp extends StatelessWidget {
  const CompensationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kıdem ve İhbar Tazminatı Hesaplama',
      theme: uygulamaTemasi,
      home: const CompensationCalculatorScreen(),
    );
  }
}

/// Basit Cupertino alan görünümü
class _CupertinoField extends StatelessWidget {
  final String label;
  final String valueText; // 'Seçiniz' vb.
  final VoidCallback onTap;

  const _CupertinoField({
    required this.label,
    required this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder = valueText.trim().isEmpty || valueText == 'Seçiniz';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.sFormLabel),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: InputDecorator(
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(
                    color: kFieldBorderColor,
                    width: kFieldBorderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(
                    color: kFieldFocusColor,
                    width: kFieldBorderWidth + 0.2,
                  ),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valueText.isEmpty ? 'Seçiniz' : valueText,
                      style: TextStyle(
                        color: isPlaceholder ? Colors.grey[700] : Colors.black,
                        fontWeight: AppW.body,
                      ),
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 18, color: Colors.indigo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================
///  HESAP EKRANI
/// =====================
class CompensationCalculatorScreen extends StatefulWidget {
  const CompensationCalculatorScreen({super.key});

  @override
  State<CompensationCalculatorScreen> createState() =>
      _CompensationCalculatorScreenState();
}

class _CompensationCalculatorScreenState extends State<CompensationCalculatorScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('kidem_hesap_opened');
  }

  String? selectedExitCode;
  String? startGun;
  String? startAy;
  String? startYil;
  String? endGun;
  String? endAy;
  String? endYil;
  final TextEditingController grossSalaryController = TextEditingController();

  Map<String, dynamic>? _hesaplamaSonucu;

  final List<String> aylar = const [
    'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
  ];

  final Map<String, String> exitCodes = const {
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
    '16': 'Sözleşme Sona Ermeden Aynı İşverene Ait Diğer İşyerine Nakil',
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
  void dispose() {
    _scrollController.dispose();
    grossSalaryController.dispose();
    super.dispose();
  }

  /// ✅ İhbar GV: kademeli tarife (kümülatif bilinmediği için yaklaşık)
  double _calcProgressiveTax(double base, List<double> brackets, List<double> rates) {
    double total = 0.0;
    double prev = 0.0;

    for (int i = 0; i < brackets.length; i++) {
      final limit = brackets[i];
      if (base <= prev) break;

      final slice = (base > limit) ? (limit - prev) : (base - prev);
      if (slice > 0) total += slice * rates[i];

      prev = limit;
    }

    if (base > prev) {
      total += (base - prev) * rates[brackets.length];
    }

    return total;
  }

  /// Tavan ücreti
  double getTavanUcreti(DateTime exitDate) {
    final year = exitDate.year;
    final month = exitDate.month;

    if (year < 2020) return 6379.86;
    if (year == 2020) return month < 7 ? 6379.86 : 6730.15;
    if (year == 2021) return month < 7 ? 7117.17 : 8284.51;
    if (year == 2022) return month < 7 ? 10848.59 : 15371.40;
    if (year == 2023) return month < 7 ? 19982.31 : 23489.83;
    if (year == 2024) return month < 7 ? 35058.58 : 41828.42;
    if (year == 2025) return month < 7 ? 46655.43 : 53919.68;

    // ✅ 2026 ilk 6 ay tavan (temmuz sonrası bilinmiyorsa aynı bırakıldı)
    if (year == 2026) return month < 7 ? 64948.77 : 64948.77;

    return 64948.77;
  }

  String formatSayi(double sayi) => formatTL(sayi);
  double parseSayi(String input) => parseTL(input);

  Map<String, dynamic> calculateSeverancePay(double salary, DateTime start, DateTime end) {
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

  Map<String, double> calculateNoticePay(double salary, DateTime start, DateTime end) {
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

    // ✅ Kademeli tarife (yıla göre) — kümülatif matrah bilinmediği için yaklaşık
    final int y = end.year;

    late final List<double> brackets;
    late final List<double> rates;

    if (y >= 2026) {
      brackets = [190000, 400000, 1500000, 5300000];
      rates = [0.15, 0.20, 0.27, 0.35, 0.40];
    } else if (y == 2025) {
      brackets = [158000, 330000, 1200000, 4300000];
      rates = [0.15, 0.20, 0.27, 0.35, 0.40];
    } else if (y == 2024) {
      brackets = [110000, 230000, 870000, 3000000];
      rates = [0.15, 0.20, 0.27, 0.35, 0.40];
    } else if (y == 2023) {
      brackets = [70000, 150000, 550000, 1900000];
      rates = [0.15, 0.20, 0.27, 0.35, 0.40];
    } else if (y == 2022) {
      brackets = [32000, 70000, 250000, 880000];
      rates = [0.15, 0.20, 0.27, 0.35, 0.40];
    } else {
      brackets = [190000, 400000, 1500000, 5300000];
      rates = [0.15, 0.20, 0.27, 0.35, 0.40];
    }

    final double incomeTax = _calcProgressiveTax(noticePay, brackets, rates);

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
      '4','5','8','9','10','11','12','13','14','15','17',
      '18','19','20','23','24','25','31','32','33','34',
      '35','36','39','40'
    ].contains(code);
  }

  Future<void> _calculateCompensation() async {
    try {
      await _showHesaplamaSonucu();
    } catch (e) {
      showCenterNotice(
        context,
        title: 'Hata',
        message: 'Beklenmeyen bir sorun oluştu: $e',
        type: AppNoticeType.error,
      );
    }
  }

  Future<void> _showHesaplamaSonucu() async {
    if (selectedExitCode == null) {
      showCenterNotice(
        context,
        title: 'Uyarı',
        message: 'İşten çıkış kodu seçiniz!',
        type: AppNoticeType.warning,
      );
      return;
    }

    if (!isEligibleForSeverance(selectedExitCode!) && !isEligibleForNotice(selectedExitCode!)) {
      _hesaplamaSonucu = {
        'basarili': false,
        'mesaj': 'Bu Şartlar Altında Kıdem Tazminatına Hak Kazanamıyorsunuz.',
        'detaylar': {
          'İşten Çıkış': '$selectedExitCode - ${exitCodes[selectedExitCode]}',
          'Kıdem Tazminatı': 'Hak Kazanılmadı.',
          'İhbar Tazminatı': 'Hak Kazanılmadı.',
        },
        'ekBilgi': {
          'Not': 'İşten Çıkış Kodundan Dolayı Kıdem Ve İhbar Tazminatına Hak Kazanamıyorsunuz.',
          'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
        },
      };
      await _openResultSheet();
      return;
    }

    if (startGun == null ||
        startAy == null ||
        startYil == null ||
        endGun == null ||
        endAy == null ||
        endYil == null ||
        grossSalaryController.text.isEmpty) {
      showCenterNotice(
        context,
        title: 'Uyarı',
        message:
        'Tüm alanları doldurmanız gerekiyor! İşten çıkış kodunuz kıdem ve ihbar tazminatı almaya uygundur.',
        type: AppNoticeType.warning,
      );
      return;
    }

    DateTime startDate;
    DateTime endDate;
    try {
      int startAyIndex = aylar.indexOf(startAy!) + 1;
      int endAyIndex = aylar.indexOf(endAy!) + 1;
      startDate = DateTime(int.parse(startYil!), startAyIndex, int.parse(startGun!));
      endDate = DateTime(int.parse(endYil!), endAyIndex, int.parse(endGun!));
      if (endDate.isBefore(startDate)) {
        showCenterNotice(
          context,
          title: 'Hata',
          message: 'Çıkış tarihi giriş tarihinden önce olamaz!',
          type: AppNoticeType.error,
        );
        return;
      }
      if (startDate.isAfter(DateTime.now()) || endDate.isAfter(DateTime.now())) {
        showCenterNotice(
          context,
          title: 'Hata',
          message: 'Tarihler gelecekte olamaz!',
          type: AppNoticeType.error,
        );
        return;
      }
    } catch (_) {
      showCenterNotice(
        context,
        title: 'Hata',
        message: 'Geçersiz tarih (ör. 31 Şubat)!',
        type: AppNoticeType.error,
      );
      return;
    }

    double grossSalary = parseSayi(grossSalaryController.text);
    if (grossSalary <= 0) {
      showCenterNotice(
        context,
        title: 'Hata',
        message: 'Brüt maaş sıfır veya negatif olamaz!',
        type: AppNoticeType.error,
      );
      return;
    }

    final severance = calculateSeverancePay(grossSalary, startDate, endDate);
    final notice = calculateNoticePay(grossSalary, startDate, endDate);

    bool severanceEligible = isEligibleForSeverance(selectedExitCode!);
    bool noticeEligible = isEligibleForNotice(selectedExitCode!);

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
      detaylar['Damga Vergisi (Kıdem)'] = formatSayi(severance['stampTax']);
      detaylar['Kıdem Tazminatı (Net)'] = formatSayi(severance['net']);
      if (severance['exceedsCeiling']) {
        detaylar['Not'] = 'Ücret tavanı aşıyor, tavan üzerinden hesaplandı.';
      }
    } else {
      detaylar['İşten Çıkış'] = '$selectedExitCode - ${exitCodes[selectedExitCode]}';
      detaylar['Kıdem Tazminatı'] = 'Hak Kazanılmadı.';
    }

    if (noticeEligible) {
      totalBrut += notice['brut']!;
      totalNet += notice['net']!;
      detaylar['İhbar Tazminatı (Brüt)'] = formatSayi(notice['brut']!);
      detaylar['Gelir Vergisi (İhbar)'] = formatSayi(notice['incomeTax']!);
      detaylar['Damga Vergisi (İhbar)'] = formatSayi(notice['stampTax']!);
      detaylar['İhbar Tazminatı (Net)'] = formatSayi(notice['net']!);
      // ✅ uyarı
      detaylar['İhbar GV Uyarısı'] =
      'Gelir vergisi, kümülatif matrah bilgisi alınamadığı için kademeli tarife üzerinden yaklaşık hesaplanmıştır.';
    } else {
      detaylar['İhbar Tazminatı'] = 'Hak Kazanılmadı.';
    }

    detaylar['Toplam Hak Edilen (Brüt)'] = formatSayi(totalBrut);
    detaylar['Toplam Hak Edilen (Net)'] = formatSayi(totalNet);

    Map<String, String> ekBilgi = {
      'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
      'Not': severance['daysWorked'] < 365
          ? 'Kıdem için aynı işveren bünyesinde en az 1 yıl çalışma şartı aranır.'
          : 'Hesaplama tamamlandı. Detayları kontrol ediniz.',
    };

    _hesaplamaSonucu = {
      'basarili': (severanceEligible || noticeEligible),
      'mesaj': (severanceEligible || noticeEligible)
          ? 'Hesaplama Başarıyla Tamamlandı!'
          : 'Bu Şartlar Altında Kıdem Tazminatına Hak Kazanamıyorsunuz.',
      'detaylar': detaylar,
      'ekBilgi': ekBilgi,
    };

    await _openResultSheet();
  }

  Future<void> _openResultSheet() async {
    final detaylar = Map<String, String>.from(_hesaplamaSonucu?['detaylar'] ?? {});

    if (_hesaplamaSonucu != null) {
      try {
        final veriler = <String, dynamic>{
          'isCikisKodu': selectedExitCode,
          'baslangicTarihi': startGun != null && startAy != null && startYil != null
              ? DateTime(int.parse(startYil!), aylar.indexOf(startAy!) + 1, int.parse(startGun!)).toIso8601String()
              : null,
          'cikisTarihi': endGun != null && endAy != null && endYil != null
              ? DateTime(int.parse(endYil!), aylar.indexOf(endAy!) + 1, int.parse(endGun!)).toIso8601String()
              : null,
          'brutMaas': grossSalaryController.text.isNotEmpty ? parseSayi(grossSalaryController.text) : null,
        };

        final sonHesaplama = SonHesaplama(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          hesaplamaTuru: 'Kıdem ve İhbar Tazminatı Hesaplama',
          tarihSaat: DateTime.now(),
          veriler: veriler,
          sonuclar: detaylar,
          ozet: (_hesaplamaSonucu!['mesaj'] ?? 'Hesaplama tamamlandı').toString(),
        );

        await SonHesaplamalarDeposu.ekle(sonHesaplama);

        AnalyticsHelper.logCalculation('kidem_ihbar_tazminati', parameters: {
          'hesaplama_turu': 'Kıdem - İhbar Tazminatı',
        });
      } catch (e) {
        debugPrint('Son hesaplama kaydedilirken hata: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kResultSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kResultSheetCorner)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: ResultSheet(
          title: 'Hesaplama Sonucu',
          detaylar: detaylar,
        ),
      ),
    );
  }

  // ------------ Cupertino Picker Yardımcıları ------------
  Future<String?> _showCupertinoListPicker({
    required List<String> items,
    required int initialIndex,
    String okText = 'Tamam',
    String cancelText = 'İptal',
  }) async {
    int selectedIndex = initialIndex.clamp(0, items.isNotEmpty ? items.length - 1 : 0);
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) {
        return Container(
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
                      child: const Text('İptal', style: TextStyle(color: Colors.black87)),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () =>
                          Navigator.pop(context, items.isNotEmpty ? items[selectedIndex] : null),
                      child: const Text('Tamam', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 30,
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  onSelectedItemChanged: (i) => selectedIndex = i,
                  children: [for (final s in items) Center(child: Text(s))],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>?> _showCupertinoDateTriplePicker({
    required String? gun,
    required String? ay,
    required String? yil,
  }) async {
    final days = [for (int i = 1; i <= 31; i++) '$i'];
    final months = aylar;
    final years = [for (int y = 2026; y >= 1980; y--) '$y'];

    int idxD = (gun != null) ? days.indexOf(gun) : 0;
    int idxM = (ay != null) ? months.indexOf(ay) : 0;
    int idxY = (yil != null) ? years.indexOf(yil) : 0;
    if (idxD < 0) idxD = 0;
    if (idxM < 0) idxM = 0;
    if (idxY < 0) idxY = 0;

    int selD = idxD, selM = idxM, selY = idxY;

    return showCupertinoModalPopup<Map<String, String>>(
      context: context,
      builder: (context) {
        return Container(
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
                      child: const Text('İptal', style: TextStyle(color: Colors.black87)),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.pop(context, {
                        'gun': days[selD],
                        'ay': months[selM],
                        'yil': years[selY],
                      }),
                      child: const Text('Tamam', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 30,
                        scrollController: FixedExtentScrollController(initialItem: idxD),
                        onSelectedItemChanged: (i) => selD = i,
                        children: [for (final d in days) Center(child: Text(d))],
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 30,
                        scrollController: FixedExtentScrollController(initialItem: idxM),
                        onSelectedItemChanged: (i) => selM = i,
                        children: [for (final m in months) Center(child: Text(m))],
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 30,
                        scrollController: FixedExtentScrollController(initialItem: idxY),
                        onSelectedItemChanged: (i) => selY = i,
                        children: [for (final y in years) Center(child: Text(y))],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _composeDateText(String? gun, String? ay, String? yil) {
    if (gun == null || ay == null || yil == null) return 'Seçiniz';
    final d = gun.padLeft(2, '0');
    final mIndex = aylar.indexOf(ay) + 1;
    final m = (mIndex <= 0 ? 1 : mIndex).toString().padLeft(2, '0');
    return '$d.$m.$yil';
  }

  /// ======= SADELEŞTİRİLMİŞ ÇIKIŞ KODU PICKER’I =======
  Future<void> _pickExitCode() async {
    final entries = exitCodes.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    int init = 0;
    if (selectedExitCode != null) {
      final idx = entries.indexWhere((e) => e.key == selectedExitCode);
      init = idx >= 0 ? idx : 0;
    }
    int selectedIndex = init;

    final pickedKey = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) {
        return Container(
          height: 320,
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
                      child: const Text('İptal', style: TextStyle(color: Colors.black87)),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.pop(context, entries[selectedIndex].key),
                      child: const Text('Tamam', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 48,
                  scrollController: FixedExtentScrollController(initialItem: init),
                  onSelectedItemChanged: (i) => selectedIndex = i,
                  children: [
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black54,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (pickedKey != null) {
      setState(() => selectedExitCode = pickedKey);
    }
  }

  Future<void> _pickStartDate() async {
    final sel = await _showCupertinoDateTriplePicker(gun: startGun, ay: startAy, yil: startYil);
    if (sel != null) {
      setState(() {
        startGun = sel['gun'];
        startAy = sel['ay'];
        startYil = sel['yil'];
      });
    }
  }

  Future<void> _pickEndDate() async {
    final sel = await _showCupertinoDateTriplePicker(gun: endGun, ay: endAy, yil: endYil);
    if (sel != null) {
      setState(() {
        endGun = sel['gun'];
        endAy = sel['ay'];
        endYil = sel['yil'];
      });
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kıdem ve İhbar Tazminatı Hesaplama',
          style: TextStyle(color: Colors.indigo),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kPageHPad, 12, kPageHPad, 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _CupertinoField(
                    label: 'İşten Çıkış Kodunuz',
                    valueText: selectedExitCode == null
                        ? 'Seçiniz'
                        : '${selectedExitCode!} - ${exitCodes[selectedExitCode]!}',
                    onTap: _pickExitCode,
                  ),
                  const SizedBox(height: 8),
                  _CupertinoField(
                    label: 'İşe Giriş Tarihi',
                    valueText: _composeDateText(startGun, startAy, startYil),
                    onTap: _pickStartDate,
                  ),
                  const SizedBox(height: 8),
                  _CupertinoField(
                    label: 'İşten Çıkış Tarihi',
                    valueText: _composeDateText(endGun, endAy, endYil),
                    onTap: _pickEndDate,
                  ),
                  const SizedBox(height: 8),
                  _buildAmountField('Son Ay Giydirilmiş Brüt Ücret', grossSalaryController),
                  const SizedBox(height: 12),
                  _buildHesaplaButton(),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(kPageHPad, 0, kPageHPad, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Divider(),
                    _InfoNotice(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// HESAPLA BUTONU — Odak kapat + mikro gecikme → hesapla
  Widget _buildHesaplaButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: () async {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 10));
          await _calculateCompensation();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(46),
        ),
        child: Text('Hesapla', style: TextStyle(fontSize: 17 * kTextScale)),
      ),
    );
  }

  Widget _buildAmountField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.sFormLabel),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Brüt Ücret',
            suffix: Text('TL', style: TextStyle(color: Colors.indigo, fontSize: 14)),
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black, fontWeight: AppW.body),
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

/// Bilgilendirme (ikon ve metin AYNI SATIRDA)
class _InfoNotice extends StatelessWidget {
  const _InfoNotice();

  @override
  Widget build(BuildContext context) {
    const maddeler = [
      'Sosyal Güvenlik Mobil, Herhangi Bir Resmi Kurumun Uygulaması Değildir!',
      'Yapılan Hesaplamalar Tahmini ve Bilgi Amaçlıdır, Resmi Nitelik Taşımaz ve Herhangi Bir Sorumluluk Doğurmaz!',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Bilgilendirme',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w300,
              color: Colors.black87,
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
                child: Text(
                  m,
                  style: const TextStyle(
                    fontWeight: AppW.body,
                    color: Colors.black,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

/// ================= SONUÇ SHEET (REFERANS GÖRÜNÜM) =================
class ResultSheet extends StatelessWidget {
  final String title;
  final Map<String, String> detaylar;
  const ResultSheet({super.key, required this.title, required this.detaylar});

  String _buildShareText() {
    final b = StringBuffer('$title\n');
    detaylar.forEach((k, v) => b.writeln('$k: $v'));
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final baseSmall = Theme.of(context).textTheme.bodySmall!;
    final lineStyle = baseSmall.copyWith(
      fontSize: (baseSmall.fontSize ?? 12) * kSumItemFontScale,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: Colors.black87,
    );

    final entries = detaylar.entries.toList();

    return Stack(
      children: [
        SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kReportMaxWidth),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 48,
                    height: 5,
                    decoration:
                    BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16 * kResultHeaderScale,
                        fontWeight: kResultHeaderWeight,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      children: [
                        ...entries.map(
                              (e) => Padding(
                            padding: kSumItemPadding,
                            child: Text('${e.key}: ${e.value}', style: lineStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                elevation: 0,
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _buildShareText()));
                if (context.mounted) {
                  showCenterNotice(
                    context,
                    title: 'Paylaş',
                    message: 'Özet panoya kopyalandı.',
                    type: AppNoticeType.success,
                  );
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.share, size: 18),
                  SizedBox(width: 8),
                  Text('Paylaş', style: TextStyle(fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
