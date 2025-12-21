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
const EdgeInsets kSumItemPadding = EdgeInsets.symmetric(vertical: 4, horizontal: 0);
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
  runApp(const IsizlikMaasiApp());
}

class IsizlikMaasiApp extends StatelessWidget {
  const IsizlikMaasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İşsizlik Maaşı Hesaplama',
      theme: uygulamaTemasi,
      home: const IsizlikMaasiScreen(),
    );
  }
}

/// Basit Cupertino alan görünümü (ikonsuz)
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
                  // İKON YOK
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
///  HESAP EKRANI (İşsizlik Maaşı)
/// =====================
class IsizlikMaasiScreen extends StatefulWidget {
  const IsizlikMaasiScreen({super.key});

  @override
  State<IsizlikMaasiScreen> createState() => _IsizlikMaasiScreenState();
}

class _IsizlikMaasiScreenState extends State<IsizlikMaasiScreen> {
  String? hizmetAkdi;
  String? primGunAraligi;
  String? istenCikisKodu;

  // Ücret girişleri
  final TextEditingController kazanc1 = TextEditingController();
  final TextEditingController kazanc2 = TextEditingController();
  final TextEditingController kazanc3 = TextEditingController();
  final TextEditingController kazanc4 = TextEditingController();

  Map<String, dynamic>? _hesaplamaSonucu;

  final ScrollController _scrollController = ScrollController();

  // 2025 sabitleri
  final double asgariUcretBrut = 26005;
  final double maxOran = 0.80;
  final double damgaVergisiOrani = 0.00759;
  final double tabanMaas = 10402.20;
  final double tavanMaas = 20804.40;
  final double aylikAsgariBrut = 20002.50;

  final List<String> issizlikMaasiHakKazanilanKodlar = [
    '4', '5', '12', '15', '17', '18', '23', '24', '25', '27', '28', '31', '32', '33', '34', '40'
  ];

  final Map<String, String> istenCikisKodlari = const {
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
    AnalyticsHelper.logScreenOpen('issizlik_maasi_opened');

    // --- Otomatik kopyalama: 1. Ay -> 2,3,4. Ay (formatlanmış metinle) ---
    kazanc1.addListener(() {
      final v = kazanc1.text;
      if (kazanc2.text != v) {
        kazanc2.value = TextEditingValue(text: v, selection: TextSelection.collapsed(offset: v.length));
      }
      if (kazanc3.text != v) {
        kazanc3.value = TextEditingValue(text: v, selection: TextSelection.collapsed(offset: v.length));
      }
      if (kazanc4.text != v) {
        kazanc4.value = TextEditingValue(text: v, selection: TextSelection.collapsed(offset: v.length));
      }
    });
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

  String formatSayi(double n) => formatTL(n);
  double parseSayi(String s) => parseTL(s);

  // ---------- Hesap akışı ----------
  Future<void> _hesapla() async {
    FocusScope.of(context).unfocus();
    await _showHesaplamaSonucu();
  }

  Future<void> _showHesaplamaSonucu() async {
    // Validasyonlar (referans tarzı: uyarıyı merkezden ver, sheet açma)
    if (istenCikisKodu == null) {
      showCenterNotice(context, title: 'Uyarı', message: 'İşten çıkış kodu seçiniz!', type: AppNoticeType.warning);
      return;
    }
    if (hizmetAkdi == null) {
      showCenterNotice(context, title: 'Uyarı', message: 'Son 120 gün hizmet akdi ile çalıştınız mı?', type: AppNoticeType.warning);
      return;
    }
    if (primGunAraligi == null) {
      showCenterNotice(context, title: 'Uyarı', message: 'Prim gün aralığınızı seçiniz!', type: AppNoticeType.warning);
      return;
    }

    if (!issizlikMaasiHakKazanilanKodlar.contains(istenCikisKodu)) {
      _hesaplamaSonucu = {
        'basarili': false,
        'mesaj': 'Bu Şartlarda İşsizlik Ödeneğine Hak Kazanılmıyor.',
        'detaylar': {
          'İşten Çıkış': '$istenCikisKodu - ${istenCikisKodlari[istenCikisKodu]}',
        },
        'ekBilgi': {
          // "Kontrol Tarihi" gösterilmeyecek
          'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
          // >>> Daha net açıklama
          'Açıklama':
          'Seçtiğiniz çıkış kodu İŞKUR kriterlerine göre işsizlik ödeneğine uygun değildir. '
              'Kodunuzu işten ayrılış bildirgenizden (SGK çıkış kodu) kontrol ediniz.',
        },
      };
      await _openResultSheet();
      return;
    }

    if (hizmetAkdi == "Hayır") {
      _hesaplamaSonucu = {
        'basarili': false,
        'mesaj': 'Bu Şartlarda İşsizlik Ödeneğine Hak Kazanılmıyor.',
        'detaylar': {'Hizmet Akdi': 'Son 120 gün kesintisiz çalışma şartı sağlanmadı.'},
        'ekBilgi': {
          'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
          'Açıklama':
          'İşsizlik ödeneği için son 120 gün hizmet akdiyle çalışmış olma şartı aranır. '
              'Bu şart sağlanmadığı için başvuru uygun değildir.',
        },
      };
      await _openResultSheet();
      return;
    }

    if (primGunAraligi == "600 günden az") {
      _hesaplamaSonucu = {
        'basarili': false,
        'mesaj': 'Bu Şartlarda İşsizlik Ödeneğine Hak Kazanılmıyor.',
        'detaylar': {'Prim Gün Aralığı': primGunAraligi!},
        'ekBilgi': {
          'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
          'Açıklama':
          'Son 3 yılda en az 600 gün sigortalı çalışma ve işsizlik sigortası primi şartı vardır. '
              'Girdiğiniz aralık bu şartı karşılamıyor.',
        },
      };
      await _openResultSheet();
      return;
    }

    if (kazanc1.text.trim().isEmpty &&
        kazanc2.text.trim().isEmpty &&
        kazanc3.text.trim().isEmpty &&
        kazanc4.text.trim().isEmpty) {
      showCenterNotice(context, title: 'Uyarı', message: 'Lütfen son 4 aylık brüt kazançlarınızı giriniz!', type: AppNoticeType.warning);
      return;
    }

    // Asgari kontrol
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
      _hesaplamaSonucu = {
        'basarili': false,
        'mesaj': 'Bu Şartlarda İşsizlik Ödeneğine Hak Kazanılmıyor.',
        'detaylar': {},
        'ekBilgi': {
          'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
          'Açıklama':
          'Brüt kazanç alanları asgari brüt ücretin (${formatSayi(aylikAsgariBrut)}) altında olamaz. '
              'Düşük görülen ay(lar): ${eksikAylar.join(", ")}.',
        },
      };
      await _openResultSheet();
      return;
    }

    await hesaplaIsizlikMaasi();
  }

  Future<void> hesaplaIsizlikMaasi() async {
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

    final detaylar = <String, String>{
      'Hak Kazanılan Süre': '${(hakEdilenGun / 30).toStringAsFixed(0)} Ay ($hakEdilenGun Gün)',
      'Günlük Brüt Kazanç': formatSayi(gunlukBrutKazanc),
      'Aylık Brüt İşsizlik Maaşı': formatSayi(isizlikBrutMaasi),
      'Damga Vergisi Kesintisi': formatSayi(damgaVergisi),
      'Aylık Net İşsizlik Maaşı': formatSayi(netIsizlikMaasi),
    };

    final ekBilgi = <String, String>{
      'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
      'Not': istenCikisKodu == '12'
          ? 'Askerlikten Sonra Alınabilir.'
          : 'Hesaplama 2025 Yılı Verilerine Göre Yapılmıştır.',
      '2025 Yılı Taban Brüt Ücret': formatSayi(tabanMaas),
      '2025 Yılı Tavan Brüt Ücret': formatSayi(tavanMaas),
    };

    _hesaplamaSonucu = {
      'basarili': true,
      'mesaj': 'Hesaplama Başarıyla Tamamlandı!',
      'detaylar': detaylar,
      'ekBilgi': ekBilgi,
    };

    await _openResultSheet();
  }

  // ------------ Cupertino Picker Yardımcıları ------------
  Future<String?> _showCupertinoListPicker({
    required List<String> items,
    required int initialIndex,
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

  Future<void> _pickExitCode() async {
    final entries = istenCikisKodlari.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    int init = 0;
    if (istenCikisKodu != null) {
      final idx = entries.indexWhere((e) => e.key == istenCikisKodu);
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
                              e.key, // sadece sayı
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
      setState(() => istenCikisKodu = pickedKey);
    }
  }

  Future<void> _pickHizmetAkdi() async {
    final items = ['Evet', 'Hayır'];
    final current = hizmetAkdi == null ? 0 : items.indexOf(hizmetAkdi!).clamp(0, items.length - 1);
    final picked = await _showCupertinoListPicker(items: items, initialIndex: current);
    if (picked != null) setState(() => hizmetAkdi = picked);
  }

  Future<void> _pickPrimGun() async {
    final items = ['600 günden az', '600 - 899 gün', '900 - 1079 gün', '1080 gün ve üzeri'];
    final current = primGunAraligi == null ? 0 : items.indexOf(primGunAraligi!).clamp(0, items.length - 1);
    final picked = await _showCupertinoListPicker(items: items, initialIndex: current);
    if (picked != null) setState(() => primGunAraligi = picked);
  }

  Future<void> _openResultSheet() async {
    final Map<String, String> detaylar = {};
    final det = Map<String, String>.from(_hesaplamaSonucu?['detaylar'] ?? {});
    detaylar.addAll(det);

    // ekBilgi'yi alt satırlara ekleyelim ama "Kontrol Tarihi"ni GÖSTERMEYELİM
    final ek = Map<String, String>.from(_hesaplamaSonucu?['ekBilgi'] ?? {});
    for (final e in ek.entries) {
      if (e.key == 'Kontrol Tarihi') continue; // Görünmesin
      detaylar[e.key] = e.value;
    }

    // Son hesaplamalara kaydet
    if (_hesaplamaSonucu != null) {
      try {
        final veriler = <String, dynamic>{
          'isCikisKodu': istenCikisKodu,
          'hizmetAkdi': hizmetAkdi,
          'primGunAraligi': primGunAraligi,
          'kazanc1': kazanc1.text.isNotEmpty ? parseSayi(kazanc1.text) : null,
          'kazanc2': kazanc2.text.isNotEmpty ? parseSayi(kazanc2.text) : null,
          'kazanc3': kazanc3.text.isNotEmpty ? parseSayi(kazanc3.text) : null,
          'kazanc4': kazanc4.text.isNotEmpty ? parseSayi(kazanc4.text) : null,
        };
        
        final sonHesaplama = SonHesaplama(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          hesaplamaTuru: 'İşsizlik Maaşı Hesaplama',
          tarihSaat: DateTime.now(),
          veriler: veriler,
          sonuclar: detaylar,
          ozet: _hesaplamaSonucu!['mesaj'] ?? 'Hesaplama tamamlandı',
        );
        
        await SonHesaplamalarDeposu.ekle(sonHesaplama);
        
        // Firebase Analytics: Hesaplama tamamlandı
        AnalyticsHelper.logCalculation('issizlik_maasi', parameters: {
          'hesaplama_turu': 'İşsizlik Maaşı',
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

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'İşsizlik Maaşı Hesaplama',
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
                    valueText: istenCikisKodu == null
                        ? 'Seçiniz'
                        : '${istenCikisKodu!} - ${istenCikisKodlari[istenCikisKodu]!}',
                    onTap: _pickExitCode,
                  ),
                  const SizedBox(height: 8),

                  _CupertinoField(
                    label: 'Son 120 Gün Hizmet Akdi ile Çalıştınız mı ?',
                    valueText: hizmetAkdi ?? 'Seçiniz',
                    onTap: _pickHizmetAkdi,
                  ),
                  const SizedBox(height: 8),

                  _CupertinoField(
                    label: 'Son 3 Yıldaki Toplam Prim Gün Sayınız',
                    valueText: primGunAraligi ?? 'Seçiniz',
                    onTap: _pickPrimGun,
                  ),
                  const SizedBox(height: 8),

                  Text('Son 4 Aylık Brüt Kazançlarınız', style: context.sFormLabel),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildAmountField('1. Ay', kazanc1)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildAmountField('2. Ay', kazanc2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildAmountField('3. Ay', kazanc3)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildAmountField('4. Ay', kazanc4)),
                    ],
                  ),

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

  /// HESAPLA BUTONU — referans stil
  Widget _buildHesaplaButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: () async => await _hesapla(),
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
          decoration: InputDecoration(
            hintText: 'Brüt Ücret',
            suffix: const Text('TL', style: TextStyle(color: Colors.indigo, fontSize: 14)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kFieldBorderRadius),
              borderSide: const BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kFieldBorderRadius),
              borderSide: const BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kFieldBorderRadius),
              borderSide: const BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.4),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

/// Bilgilendirme (ikonsuz)
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
              const Text('•  '),
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
                  // Tutma çubuğu
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      title, // Üstte sabit "Hesaplama Sonucu"
                      style: TextStyle(
                        fontSize: 16 * kResultHeaderScale,
                        fontWeight: kResultHeaderWeight,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1), // Açıklamaların üstünde divider
                  Expanded(
                    child: ListView(
                      key: const ValueKey('result-list'),
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
              // >>> Apple tarzı paylaşma ikonu geri eklendi
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