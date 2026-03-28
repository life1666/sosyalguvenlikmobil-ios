import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../sonhesaplama/sonhesaplama.dart';
import '../utils/analytics_helper.dart';
import '../utils/theme_helper.dart';

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
///  YARDIMCI FORMAT FONKSİYONLAR (intl yok)
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

/// CustomCurrencyFormatter (intl’siz)
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
      return newValue.copyWith(text: '');
    }
    if (digitsOnly.length < 5) {
      return newValue.copyWith(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    }
    String integerPart = digitsOnly.substring(0, digitsOnly.length - 2);
    String fractionalPart = digitsOnly.substring(digitsOnly.length - 2);
    String formattedInteger = _thousands(integerPart);
    String newText = '$formattedInteger,$fractionalPart';
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// toTitleCase:
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

void main() {
  runApp(const RaporParasiHesaplamaApp());
}

class RaporParasiHesaplamaApp extends StatelessWidget {
  const RaporParasiHesaplamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rapor Parası Hesaplama',
      theme: uygulamaTemasi,
      home: const RaporParasiScreen(),
    );
  }
}

/// Basit Cupertino alan görünümü
class _CupertinoField extends StatelessWidget {
  final String label;
  final String valueText; // 'Seçiniz' vb.
  final VoidCallback onTap;
  final bool showErrorBorder;

  const _CupertinoField({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.showErrorBorder = false,
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
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(
                    color: showErrorBorder ? Colors.red : kFieldBorderColor,
                    width: kFieldBorderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(
                    color: showErrorBorder ? Colors.red : kFieldFocusColor,
                    width: kFieldBorderWidth + 0.2,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RaporParasiScreen extends StatefulWidget {
  final bool inline;
  final VoidCallback? onBack;
  const RaporParasiScreen({super.key, this.inline = false, this.onBack});

  @override
  State<RaporParasiScreen> createState() => _RaporParasiScreenState();
}

class _RaporParasiScreenState extends State<RaporParasiScreen> {
  String? selectedReason;
  String? has90DaysInsurance; // Hastalık E/H
  String? gebelikTuru; // Doğum: Tekil/Çoğul
  String? has90DaysInsuranceForBirth; // Doğum E/H

  final TextEditingController yatarakDaysController = TextEditingController();
  final TextEditingController ayaktanDaysController = TextEditingController();

  final TextEditingController grossSalary1 = TextEditingController();
  final TextEditingController grossSalary2 = TextEditingController();
  final TextEditingController grossSalary3 = TextEditingController();
  final TextEditingController workDays1 = TextEditingController();
  final TextEditingController workDays2 = TextEditingController();
  final TextEditingController workDays3 = TextEditingController();

  Map<String, dynamic>? _hesaplamaSonucu;

  bool _showingResult = false;

  final List<String> reasonOptions = const ['İş Kazası', 'Meslek Hastalığı', 'Hastalık', 'Doğum'];
  final List<String> insuranceOptions = const ['Evet', 'Hayır'];
  final List<String> gebelikTuruOptions = const ['Tekil', 'Çoğul'];

  final ScrollController _scrollController = ScrollController();

  // ---- Hata çerçevesi bayrakları (seçimler)
  bool errReason = false;
  bool errHas90 = false;
  bool errBirth90 = false;
  bool errGebelik = false;

  // ---- Hata çerçevesi bayrakları (Son 3 Ay alanları)
  bool errSal1 = false, errSal2 = false, errSal3 = false;
  bool errDay1 = false, errDay2 = false, errDay3 = false;

  bool _syncing = false; // otomatik kopyalama sırasında döngüyü önlemek için

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('rapor_parasi_opened');
    // 1. ay brüt ve gün değerlerini diğerlerine aynen yansıt
    grossSalary1.addListener(_syncFromFirstMonthSalary);
    workDays1.addListener(_syncFromFirstMonthDays);
  }

  void _syncFromFirstMonthSalary() {
    if (_syncing) return;
    _syncing = true;
    // Tüm TextEditingValue'yu kopyalamak seçim imlecini de korur
    grossSalary2.value = grossSalary1.value;
    grossSalary3.value = grossSalary1.value;
    _syncing = false;
  }

  void _syncFromFirstMonthDays() {
    if (_syncing) return;
    _syncing = true;
    workDays2.value = workDays1.value;
    workDays3.value = workDays1.value;
    _syncing = false;
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
    super.dispose();
  }

  // ---------- Cupertino List Picker ----------
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

  // ---------- Yardımcılar ----------
  double parseGrossSalary(String input) {
    String normalized = input.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  String formatSayi(double sayi) => formatTL(sayi);

  // ---------- Doğrulama ----------
  bool _validateInputs() {
    // Önceki hata objesini temizle
    _hesaplamaSonucu = null;

    bool _errReason = false;
    bool _errHas90 = false;
    bool _errBirth90 = false;
    bool _errGebelik = false;

    // Son 3 Ay alan hataları başlangıç
    bool _errSal1 = false, _errSal2 = false, _errSal3 = false;
    bool _errDay1 = false, _errDay2 = false, _errDay3 = false;

    if (selectedReason == null) {
      _errReason = true;
      _hesaplamaSonucu = {
        'basarili': false,
        'mesaj': toTitleCase('Lütfen rapor nedenini seçiniz!'),
        'detaylar': {},
        'ekBilgi': {'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now())},
      };
    }

    if (selectedReason == 'Hastalık' && has90DaysInsurance == null) {
      _errHas90 = true;
      _hesaplamaSonucu ??= {
        'basarili': false,
        'mesaj': toTitleCase('Lütfen sigorta bildirimi durumunu seçiniz!'),
        'detaylar': {},
        'ekBilgi': {'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now())},
      };
    }

    if (selectedReason == 'Hastalık' && has90DaysInsurance == 'Hayır') {
      _hesaplamaSonucu = {
        'basarili': false,
        'mesaj': toTitleCase('Bu Şartlar Altında Rapor Parası Almaya Hak Kazanamıyorsunuz.'),
        'detaylar': {'Rapor Nedeni': toTitleCase(selectedReason ?? '')},
        'ekBilgi': {
          'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now()),
          'Not':
          'Rapor Süreniz 2 Günden Az Olduğu İçin ve/veya Rapor Tarihinden Önceki 1 Yıl İçinde 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Olmadığı İçin Rapor Parası Almaya Hak Kazanamıyorsunuz.'
        },
      };
    }

    if (selectedReason == 'Doğum') {
      if (has90DaysInsuranceForBirth == null) {
        _errBirth90 = true;
        _hesaplamaSonucu ??= {
          'basarili': false,
          'mesaj': toTitleCase(
              'Lütfen Doğum Tarihinden Önce 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Var Mı? seçiniz!'),
          'detaylar': {},
          'ekBilgi': {'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now())},
        };
      } else if (has90DaysInsuranceForBirth == 'Hayır') {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase('Bu Şartlar Altında Rapor Parası Almaya Hak Kazanamıyorsunuz.'),
          'detaylar': {'Rapor Nedeni': toTitleCase(selectedReason ?? '')},
          'ekBilgi': {
            'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now()),
            'Not':
            'Doğum Tarihinden Önce 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Olmadığı İçin Rapor Parası Almaya Hak Kazanamadınız.'
          },
        };
      }
      if (gebelikTuru == null) {
        _errGebelik = true;
        _hesaplamaSonucu ??= {
          'basarili': false,
          'mesaj': toTitleCase('Lütfen gebelik türünü seçiniz!'),
          'detaylar': {},
          'ekBilgi': {'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now())},
        };
      }
    }

    // Yatarak/Ayaktan (Doğum dışı)
    if (selectedReason != 'Doğum' && selectedReason != null) {
      int yDays = int.tryParse(yatarakDaysController.text) ?? 0;
      int aDays = int.tryParse(ayaktanDaysController.text) ?? 0;
      if ((yDays + aDays) <= 0) {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase('Lütfen yatarak veya ayaktan rapor gün sayısını giriniz!'),
          'detaylar': {},
          'ekBilgi': {'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now())},
        };
      }
    }

    // Son 3 ay alanlarının kontrolü VE bayrakları
    double e1 = parseGrossSalary(grossSalary1.text);
    double e2 = parseGrossSalary(grossSalary2.text);
    double e3 = parseGrossSalary(grossSalary3.text);
    int d1 = int.tryParse(workDays1.text) ?? 0;
    int d2 = int.tryParse(workDays2.text) ?? 0;
    int d3 = int.tryParse(workDays3.text) ?? 0;

    _errSal1 = e1 <= 0;
    _errSal2 = e2 <= 0;
    _errSal3 = e3 <= 0;
    _errDay1 = d1 <= 0;
    _errDay2 = d2 <= 0;
    _errDay3 = d3 <= 0;

    final totalEarnings = e1 + e2 + e3;
    final totalWorkDays = (d1 + d2 + d3).toDouble();

    if (selectedReason != null && (totalWorkDays <= 0 || totalEarnings <= 0)) {
      _hesaplamaSonucu = {
        'basarili': false,
        'mesaj': toTitleCase('Son 3 ay kazanç ve çalışılan gün sayıları geçerli olmalıdır!'),
        'detaylar': {},
        'ekBilgi': {'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now())},
      };
    }

    setState(() {
      errReason = _errReason;
      errHas90 = _errHas90;
      errBirth90 = _errBirth90;
      errGebelik = _errGebelik;

      errSal1 = _errSal1;
      errSal2 = _errSal2;
      errSal3 = _errSal3;
      errDay1 = _errDay1;
      errDay2 = _errDay2;
      errDay3 = _errDay3;
    });

    final hasSelectionError = (errReason || errHas90 || errBirth90 || errGebelik);
    final hasS3Error = (errSal1 || errSal2 || errSal3 || errDay1 || errDay2 || errDay3);

    return !hasSelectionError && !hasS3Error && (_hesaplamaSonucu == null || _hesaplamaSonucu!['basarili'] != false);
  }

  Future<void> _hesapla() async {
    // Anlık kırmızı çerçeveleme
    setState(() {
      errReason = selectedReason == null;
      errHas90 = selectedReason == 'Hastalık' && has90DaysInsurance == null;
      errBirth90 = selectedReason == 'Doğum' && has90DaysInsuranceForBirth == null;
      errGebelik = selectedReason == 'Doğum' && gebelikTuru == null;

      errSal1 = parseGrossSalary(grossSalary1.text) <= 0;
      errSal2 = parseGrossSalary(grossSalary2.text) <= 0;
      errSal3 = parseGrossSalary(grossSalary3.text) <= 0;
      errDay1 = (int.tryParse(workDays1.text) ?? 0) <= 0;
      errDay2 = (int.tryParse(workDays2.text) ?? 0) <= 0;
      errDay3 = (int.tryParse(workDays3.text) ?? 0) <= 0;
    });

    if (!_validateInputs()) {
      showCenterNotice(
        context,
        title: 'Uyarı',
        message: _hesaplamaSonucu?['mesaj'] ?? 'Eksik alanlar var',
        type: AppNoticeType.warning,
      );
      return;
    }

    double days;
    int yDays = 0;
    int aDays = 0;

    if (selectedReason == 'Doğum') {
      days = (gebelikTuru == 'Çoğul') ? 126 : 112;
    } else {
      yatarakDaysController.text = yatarakDaysController.text.trim();
      ayaktanDaysController.text = ayaktanDaysController.text.trim();
      yDays = int.tryParse(yatarakDaysController.text) ?? 0;
      aDays = int.tryParse(ayaktanDaysController.text) ?? 0;
      days = (yDays + aDays).toDouble();
    }

    if (selectedReason == 'Hastalık' && has90DaysInsurance == 'Evet') {
      final totalRaporGunu = yDays + aDays;
      if (totalRaporGunu < 3) {
        _hesaplamaSonucu = {
          'basarili': false,
          'mesaj': toTitleCase('Bu Şartlar Altında Rapor Parası Almaya Hak Kazanamıyorsunuz.'),
          'detaylar': {'Rapor Nedeni': toTitleCase(selectedReason ?? '')},
          'ekBilgi': {
            'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now()),
            'Not':
            'Rapor Süreniz 2 Günden Az Olduğu İçin ve/veya Rapor Tarihinden Önceki 1 Yıl İçinde 90 Gün Kısa Vadeli Sigorta Kolu Bildiriminiz Olmadığı İçin Rapor Parası Almaya Hak Kazanamıyorsunuz.'
          },
        };
        showCenterNotice(context, title: 'Sonuç', message: _hesaplamaSonucu!['mesaj'], type: AppNoticeType.info);
        return;
      }
    }

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
      resultDetails['Raporlu Gün Sayısı'] = '${days.toStringAsFixed(0)} gün';
      resultDetails['Rapor Nedeni'] = (gebelikTuru == 'Çoğul') ? 'Çoklu Doğum' : 'Doğum';
    } else {
      resultDetails['Yatarak Raporlu Gün Sayısı'] = '$yDays gün';
      resultDetails['Ayaktan Raporlu Gün Sayısı'] = '$aDays gün';
      resultDetails['Toplam Raporlu Gün Sayısı'] = '${(yDays + aDays).toString()} gün';
      resultDetails['Rapor Nedeni'] = toTitleCase(selectedReason ?? '');
    }
    resultDetails['Günlük Ödeme'] = formatSayi(dailyEarnings);
    resultDetails['Toplam Net Ödeme'] = formatSayi(totalPayment);

    _hesaplamaSonucu = {
      'basarili': true,
      'mesaj': toTitleCase('Hesaplama başarıyla tamamlandı!'), // sheet'te GÖSTERİLMEYECEK
      'detaylar': resultDetails,
      'ekBilgi': {
        'Sorgu Tarihi': formatDateDDMMYYYY(DateTime.now()),
        'Not': 'Hesaplama 4-A Sigorta Kolu Kapsamında Yapılmıştır.'
      },
    };

    // Son hesaplamalara kaydet
    try {
      final veriler = <String, dynamic>{
        'raporNedeni': selectedReason,
        'gunSayisi': days,
        'yatarakGun': yDays,
        'ayaktanGun': aDays,
        'gunlukKazanc': dailyEarnings,
        'toplamOdeme': totalPayment,
      };
      
      final sonHesaplama = SonHesaplama(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hesaplamaTuru: 'Rapor Parası Hesaplama',
        tarihSaat: DateTime.now(),
        veriler: veriler,
        sonuclar: resultDetails,
        ozet: 'Rapor parası hesaplaması tamamlandı',
      );
      
      await SonHesaplamalarDeposu.ekle(sonHesaplama);
      
      // Firebase Analytics: Hesaplama tamamlandı
      AnalyticsHelper.logCalculation('rapor_parasi', parameters: {
        'hesaplama_turu': 'Rapor Parası',
      });
    } catch (e) {
      debugPrint('Son hesaplama kaydedilirken hata: $e');
    }

    if (mounted) setState(() => _showingResult = true);
  }

  // ---------- Cupertino seçim alanları ----------
  Future<void> _pickReason() async {
    final init = selectedReason != null ? reasonOptions.indexOf(selectedReason!) : 0;
    final sel = await _showCupertinoListPicker(items: reasonOptions, initialIndex: init < 0 ? 0 : init);
    if (sel != null) {
      setState(() {
        selectedReason = sel;
        has90DaysInsurance = null;
        has90DaysInsuranceForBirth = null;
        gebelikTuru = null;
        yatarakDaysController.clear();
        ayaktanDaysController.clear();
        _hesaplamaSonucu = null;
        errReason = false;
      });
    }
  }

  Future<void> _pickHas90ForIllness() async {
    final init = has90DaysInsurance != null ? insuranceOptions.indexOf(has90DaysInsurance!) : 0;
    final sel = await _showCupertinoListPicker(items: insuranceOptions, initialIndex: init < 0 ? 0 : init);
    if (sel != null) {
      setState(() {
        has90DaysInsurance = sel;
        _hesaplamaSonucu = null;
        errHas90 = false;
      });
    }
  }

  Future<void> _pickHas90ForBirth() async {
    final init =
    has90DaysInsuranceForBirth != null ? insuranceOptions.indexOf(has90DaysInsuranceForBirth!) : 0;
    final sel = await _showCupertinoListPicker(items: insuranceOptions, initialIndex: init < 0 ? 0 : init);
    if (sel != null) {
      setState(() {
        has90DaysInsuranceForBirth = sel;
        _hesaplamaSonucu = null;
        errBirth90 = false;
      });
    }
  }

  Future<void> _pickGebelikTuru() async {
    final init = gebelikTuru != null ? gebelikTuruOptions.indexOf(gebelikTuru!) : 0;
    final sel = await _showCupertinoListPicker(items: gebelikTuruOptions, initialIndex: init < 0 ? 0 : init);
    if (sel != null) {
      setState(() {
        gebelikTuru = sel;
        _hesaplamaSonucu = null;
        errGebelik = false;
      });
    }
  }

  Widget _buildRaporNedeniField() {
    return _CupertinoField(
      label: 'Rapor Nedeni',
      valueText: selectedReason ?? 'Seçiniz',
      onTap: _pickReason,
      showErrorBorder: errReason,
    );
  }

  Widget _buildBirthInsuranceField() {
    if (selectedReason != 'Doğum') return const SizedBox.shrink();
    return _CupertinoField(
      label: 'Doğum Öncesi 90 Gün Kısa Vadeli Sigorta Bildiriminiz Var mı?',
      valueText: has90DaysInsuranceForBirth ?? 'Seçiniz',
      onTap: _pickHas90ForBirth,
      showErrorBorder: errBirth90,
    );
  }

  Widget _buildGebelikTuruField() {
    if (selectedReason != 'Doğum') return const SizedBox.shrink();
    return _CupertinoField(
      label: 'Gebelik Türü',
      valueText: gebelikTuru ?? 'Seçiniz',
      onTap: _pickGebelikTuru,
      showErrorBorder: errGebelik,
    );
  }

  Widget _buildHas90IllnessField() {
    if (selectedReason != 'Hastalık') return const SizedBox.shrink();
    return _CupertinoField(
      label: 'Rapor 2+ Gün mü ve Son 1 Yılda 90 Gün Kısa Vadeli Sigorta Bildiriminiz Var mı?',
      valueText: has90DaysInsurance ?? 'Seçiniz',
      onTap: _pickHas90ForIllness,
      showErrorBorder: errHas90,
    );
  }

  Widget _buildRaporSuresiCard() {
    if (selectedReason == 'Doğum') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İş Göremezlik (Rapor) Süresi', style: context.sFormLabel),
          const SizedBox(height: 4),
          TextFormField(
            controller: yatarakDaysController,
            decoration: const InputDecoration(
              hintText: 'Yatarak Raporlu Gün Sayısı',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ayaktanDaysController,
            decoration: const InputDecoration(
              hintText: 'Ayaktan Raporlu Gün Sayısı',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          ),
        ],
      ),
    );
  }

  Widget _buildBrutUcretCard() {
    // HATA ÇERÇEVESİ UYGULANAN TEK SATIR BİLEŞENİ
    Widget _row(
        String label,
        TextEditingController salary,
        TextEditingController days, {
          required bool errSalary,
          required bool errDays,
        }) {
      OutlineInputBorder _border(bool isError) => OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: isError ? Colors.red : kFieldBorderColor, width: kFieldBorderWidth),
      );
      OutlineInputBorder _focusBorder(bool isError) => OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: isError ? Colors.red : kFieldFocusColor, width: kFieldBorderWidth + 0.2),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: salary,
                  decoration: InputDecoration(
                    hintText: 'Brüt Ücret',
                    suffix: const Text('TL', style: TextStyle(color: Colors.indigo, fontSize: 14)),
                    enabledBorder: _border(errSalary),
                    focusedBorder: _focusBorder(errSalary),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    CustomCurrencyFormatter(),
                    LengthLimitingTextInputFormatter(15),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: days,
                  decoration: InputDecoration(
                    hintText: 'Gün',
                    enabledBorder: _border(errDays),
                    focusedBorder: _focusBorder(errDays),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Son 3 Ay İçindeki Brüt Ücretleriniz ve Prim Gün Sayılarınız', style: context.sFormLabel),
          const SizedBox(height: 6),
          _row('1. Ay', grossSalary1, workDays1, errSalary: errSal1, errDays: errDay1),
          const SizedBox(height: 8),
          _row('2. Ay', grossSalary2, workDays2, errSalary: errSal2, errDays: errDay2),
          const SizedBox(height: 8),
          _row('3. Ay', grossSalary3, workDays3, errSalary: errSal3, errDays: errDay3),
        ],
      ),
    );
  }

  Future<void> _onHesaplaPressed() async {
    setState(() {
      errReason = selectedReason == null;
      errHas90 = selectedReason == 'Hastalık' && has90DaysInsurance == null;
      errBirth90 = selectedReason == 'Doğum' && has90DaysInsuranceForBirth == null;
      errGebelik = selectedReason == 'Doğum' && gebelikTuru == null;

      errSal1 = parseGrossSalary(grossSalary1.text) <= 0;
      errSal2 = parseGrossSalary(grossSalary2.text) <= 0;
      errSal3 = parseGrossSalary(grossSalary3.text) <= 0;
      errDay1 = (int.tryParse(workDays1.text) ?? 0) <= 0;
      errDay2 = (int.tryParse(workDays2.text) ?? 0) <= 0;
      errDay3 = (int.tryParse(workDays3.text) ?? 0) <= 0;
    });
    await _hesapla();
  }

  List<Widget> _buildRaporDetayRows(Map<String, String> detaylar) {
    const green = Color(0xFF2ECC71);
    const slate400 = Color(0xFF94A3B8);
    const slate800 = Color(0xFF1E293B);
    final widgets = <Widget>[];
    final entries = detaylar.entries.toList();
    entries.sort((a, b) {
      if (a.key == 'Rapor Nedeni') return -1;
      if (b.key == 'Rapor Nedeni') return 1;
      return 0;
    });
    for (final e in entries) {
      final highlight = e.key == 'Toplam Net Ödeme' || e.key == 'Günlük Ödeme';
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                e.key,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: slate400),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                  color: highlight ? green : slate800,
                ),
              ),
            ),
          ],
        ),
      ));
    }
    return widgets;
  }

  Widget _buildResultView() {
    if (_hesaplamaSonucu == null) return const SizedBox.shrink();
    final basarili = _hesaplamaSonucu!['basarili'] as bool? ?? false;
    final mesaj = _hesaplamaSonucu!['mesaj'] as String? ?? '';
    final detaylar = (_hesaplamaSonucu!['detaylar'] as Map?)?.cast<String, String>() ?? {};
    final ekBilgi = (_hesaplamaSonucu!['ekBilgi'] as Map?)?.cast<String, String>() ?? {};

    const green = Color(0xFF2ECC71);
    const slate50 = Color(0xFFF8FAFC);
    const slate100 = Color(0xFFF1F5F9);
    const slate200 = Color(0xFFE2E8F0);
    const slate500 = Color(0xFF64748B);
    const slate800 = Color(0xFF1E293B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: basarili ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: basarili ? green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  basarili ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: basarili ? green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mesaj,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: basarili ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (detaylar.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: slate100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hesaplama Sonuçları',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: slate800),
                  ),
                  const SizedBox(height: 16),
                  ..._buildRaporDetayRows(detaylar),
                ],
              ),
            ),
          ],
          if (ekBilgi.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in ekBilgi.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 12, color: slate500),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showingResult = false),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Geri Dön', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                side: const BorderSide(color: green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _showingResult = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Yeniden Hesapla',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2ECC71);
    const gray = Color(0xFFF8FAFC);
    const slate100 = Color(0xFFF1F5F9);
    const slate400 = Color(0xFF94A3B8);
    const slate800 = Color(0xFF1E293B);

    final body = _showingResult
        ? _buildResultView()
        : SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (widget.inline)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        if (widget.onBack != null) widget.onBack!();
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: const Text('Geri', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: slate400),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: slate100),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.medical_services_rounded, color: green, size: 28),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rapor Parası Hesaplama',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: slate800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildRaporNedeniField(),
                      if (selectedReason == 'Doğum') _buildBirthInsuranceField(),
                      if (selectedReason == 'Doğum') _buildGebelikTuruField(),
                      if (selectedReason == 'Hastalık') _buildHas90IllnessField(),
                      if (selectedReason != 'Doğum') _buildRaporSuresiCard(),
                      _buildBrutUcretCard(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            await Future.delayed(const Duration(milliseconds: 10));
                            await _onHesaplaPressed();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Hesapla',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const _InfoNotice(),
                const SizedBox(height: 100),
              ],
            ),
          );

    if (widget.inline) return body;

    return Scaffold(
      backgroundColor: gray,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (_showingResult) {
              setState(() => _showingResult = false);
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text(
          'Rapor Parası Hesaplama',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: body,
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
                  m, // runtime değer -> const kullanmıyoruz
                  style: const TextStyle(
                    fontWeight: AppW.body,
                    color: Colors.black,
                    fontSize: 12,
                    height: 1.3, // ikonla hizayı dengeler
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