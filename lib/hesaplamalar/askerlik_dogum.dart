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
///  BASIT FORMAT / ARAÇLAR (intl yok)
/// ======================

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  final punctuationChars = [',', '.', ')', '!', '?', ';', ':', '(', '[', ']', '{', '}', '“', '”', '"', '\''];

  List<String> words = text.split(' ');
  List<String> titleCasedWords = [];

  for (String originalWord in words) {
    if (originalWord.isEmpty) {
      titleCasedWords.add(originalWord);
      continue;
    }
    String leadingPunct = '';
    while (originalWord.isNotEmpty && punctuationChars.contains(originalWord[0])) {
      leadingPunct += originalWord[0];
      originalWord = originalWord.substring(1);
    }
    String trailingPunct = '';
    while (originalWord.isNotEmpty && punctuationChars.contains(originalWord[originalWord.length - 1])) {
      trailingPunct = originalWord[originalWord.length - 1] + trailingPunct;
      originalWord = originalWord.substring(0, originalWord.length - 1);
    }

    final lower = originalWord.toLowerCase();
    if (lower == 'tl') {
      originalWord = 'TL';
    } else if (lower == 'icin' || lower == 'için') {
      originalWord = 'İçin';
    } else if (originalWord.isNotEmpty) {
      originalWord = originalWord[0].toUpperCase() + originalWord.substring(1).toLowerCase();
    }

    String finalWord = leadingPunct + originalWord + trailingPunct;
    titleCasedWords.add(finalWord);
  }
  return titleCasedWords.join(' ');
}

String formatDateDDMMYYYY(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

/// 1234567.8 -> 1.234.567,80 TL
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

/// 1234567.8 -> 1.234.567,80 (TL’siz)
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

/// =====================
///  APP
/// =====================
void main() {
  runApp(const BorclanmaHesaplamaApp());
}

class BorclanmaHesaplamaApp extends StatelessWidget {
  const BorclanmaHesaplamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Borçlanma Hesaplama',
      theme: uygulamaTemasi,
      home: const BorclanmaHesaplamaScreen(),
    );
  }
}

/// Basit Cupertino alan (dokununca modal picker açar)
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

/// Sadece gösterim amaçlı okunur alan (başlık + kutucuk)
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String valueText;

  const _ReadOnlyField({
    required this.label,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.sFormLabel),
          const SizedBox(height: 4),
          InputDecorator(
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
              filled: true,
              fillColor: Colors.white,
            ),
            child: Text(
              valueText,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: AppW.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek satır sayısal alan (referans stilde)
class _NumberRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLen;

  const _NumberRow({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLen = 5,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder _border() => const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
      borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
    );
    OutlineInputBorder _focusBorder() => const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
      borderSide: BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.sFormLabel),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            enabledBorder: _border(),
            focusedBorder: _focusBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(maxLen)],
          style: const TextStyle(color: Colors.black, fontWeight: AppW.body),
        ),
      ],
    );
  }
}

class BorclanmaHesaplamaScreen extends StatefulWidget {
  const BorclanmaHesaplamaScreen({super.key});

  @override
  _BorclanmaHesaplamaScreenState createState() => _BorclanmaHesaplamaScreenState();
}

class _BorclanmaHesaplamaScreenState extends State<BorclanmaHesaplamaScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('askerlik_dogum_borclanma_opened');
  }

  // Sabitler
  final double _asgariAylikGelir = 26005.50;
  final double _ustLimitGelir = 169035.75;
  final String _basvuruTarihi = 'Güncel asgari ücret üzerinden hesaplanmaktadır.';

  final TextEditingController _gunController = TextEditingController();

  String? _secilenBorclanma;
  final List<String> _borclanmaSureleri = const [
    'Askerlik Borçlanması',
    'Ücretsiz Doğum veya Analık İzni Süreleri',
    'Aylıksız İzin Süreleri (4/c Kapsamında)',
    'Doktora veya Uzmanlık Eğitimi Süreleri',
    'Avukatlık Staj Süreleri',
    'Tutukluluk veya Gözaltı Süreleri',
    'Grev ve Lokavt Süreleri',
    'Hekimlerin Fahri Asistanlıkta Geçen Süreleri',
    'Seçim Kanunları Gereği Görevden Uzaklaşma Süreleri',
  ];

  final Map<String, IconData> _borclanmaIconMap = const {
    'Askerlik Borçlanması': Icons.military_tech,
    'Ücretsiz Doğum veya Analık İzni Süreleri': Icons.child_care,
    'Aylıksız İzin Süreleri (4/c Kapsamında)': Icons.no_accounts,
    'Doktora veya Uzmanlık Eğitimi Süreleri': Icons.school,
    'Avukatlık Staj Süreleri': Icons.gavel,
    'Tutukluluk veya Gözaltı Süreleri': Icons.lock,
    'Grev ve Lokavt Süreleri': Icons.campaign,
    'Hekimlerin Fahri Asistanlıkta Geçen Süreleri': Icons.medical_information,
    'Seçim Kanunları Gereği Görevden Uzaklaşma Süreleri': Icons.how_to_vote,
  };

  Map<String, dynamic>? _hesaplamaSonucu;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  @override
  void dispose() {
    _gunController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ---------- Cupertino Tekli Liste Picker ----------
  Future<String?> _showCupertinoListPicker({
    required List<String> items,
    required int initialIndex,
  }) async {
    int sel = initialIndex.clamp(0, items.isNotEmpty ? items.length - 1 : 0);
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
                      onPressed: () => Navigator.pop(context, items.isNotEmpty ? items[sel] : null),
                      child: const Text('Tamam', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 30,
                  scrollController: FixedExtentScrollController(initialItem: initialIndex.clamp(0, items.length - 1)),
                  onSelectedItemChanged: (i) => sel = i,
                  children: [
                    for (final s in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // İKONLAR KALDIRILDI — sadece metin
                            Flexible(child: Text(s, overflow: TextOverflow.ellipsis)),
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
  }

  // ---------- Hesaplama ----------
  Future<void> _hesapla() async {
    // Doğrulamalar
    if (_secilenBorclanma == null) {
      showCenterNotice(context, title: 'Uyarı', message: 'Lütfen borçlanma türünü seçiniz!', type: AppNoticeType.warning);
      return;
    }
    final gunSayisi = int.tryParse(_gunController.text.trim()) ?? 0;
    if (gunSayisi <= 0) {
      showCenterNotice(context, title: 'Uyarı', message: 'Lütfen geçerli bir gün sayısı giriniz!', type: AppNoticeType.warning);
      return;
    }
    if (_secilenBorclanma == 'Askerlik Borçlanması' && gunSayisi > 720) {
      showCenterNotice(context, title: 'Uyarı', message: 'Askerlik borçlanması için gün sayısı 720’yi aşamaz!', type: AppNoticeType.warning);
      return;
    }

    // Hesaplar
    final gunlukAsgariGelir = _asgariAylikGelir / 30.0;
    final altLimitGunlukBedel = gunlukAsgariGelir * 0.32;
    final altLimit = gunSayisi * altLimitGunlukBedel;

    final gunlukUstGelir = _ustLimitGelir / 30.0;
    final ustLimitGunlukBedel = gunlukUstGelir * 0.32;
    final ustLimit = gunSayisi * ustLimitGunlukBedel;

    setState(() {
      _hesaplamaSonucu = {
        'basarili': true,
        'mesaj': toTitleCase('Borçlanma hesaplaması başarıyla tamamlandı!'),
        'detaylar': {
          'Başvuru Tarihi': _basvuruTarihi,
          'Borçlanma Türü': _secilenBorclanma ?? '',
          'Borçlanılacak Gün Sayısı': '$gunSayisi gün',
          'Borçlanma Alt Limiti': '${formatTL(altLimit)} (Beyan: ${formatPlain(_asgariAylikGelir)} TL)',
          'Borçlanma Üst Limiti': '${formatTL(ustLimit)} (Beyan: ${formatPlain(_ustLimitGelir)} TL)',
        },
        'ekBilgi': {
          'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
          'Not':
          '$_basvuruTarihi tarihleri arasında $gunSayisi gün borçlanması için en az ${formatTL(altLimit)} en çok ${formatTL(ustLimit)} prim ödeyebilirsiniz.',
        },
      };
    });

    await _openResultSheet();
  }

  Future<void> _openResultSheet() async {
    final detaylar = Map<String, String>.from(_hesaplamaSonucu?['detaylar'] ?? {});
    final durumText = (_hesaplamaSonucu?['mesaj'] as String?) ?? 'Sonuç';
    
    // Son hesaplamalara kaydet
    if (_hesaplamaSonucu != null) {
      try {
        final veriler = <String, dynamic>{
          'borclanmaTuru': _secilenBorclanma,
          'gunSayisi': int.tryParse(_gunController.text.trim()) ?? 0,
        };
        
        final sonHesaplama = SonHesaplama(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          hesaplamaTuru: 'Askerlik Borçlanması Hesaplama',
          tarihSaat: DateTime.now(),
          veriler: veriler,
          sonuclar: detaylar,
          ozet: durumText,
        );
        
        await SonHesaplamalarDeposu.ekle(sonHesaplama);
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
          statusDescription: toTitleCase(durumText),
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
          'Borçlanma Hesaplama',
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
                  // Başvuru Tarihi — başlık + kutucuk (okunur, seçim yok)
                  _ReadOnlyField(
                    label: 'Hesaplama Tutarı',
                    valueText: _basvuruTarihi,
                  ),

                  // Borçlanma türü — Cupertino picker ile (ikonlar kaldırıldı)
                  _CupertinoField(
                    label: 'Borçlanma Türü',
                    valueText: _secilenBorclanma ?? 'Seçiniz',
                    onTap: () async {
                      final init = _secilenBorclanma != null ? _borclanmaSureleri.indexOf(_secilenBorclanma!) : 0;
                      final sel = await _showCupertinoListPicker(items: _borclanmaSureleri, initialIndex: init < 0 ? 0 : init);
                      if (sel != null) {
                        setState(() => _secilenBorclanma = sel);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Gün sayısı
                  _NumberRow(
                    label: 'Borçlanılacak Gün Sayısı',
                    controller: _gunController,
                    hint: 'Örn. 360',
                    maxLen: 4,
                  ),

                  const SizedBox(height: 12),

                  // Hesapla butonu
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await _hesapla();
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
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),

            // Alt bilgilendirme
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
  final String title; // başlık sabit
  final Map<String, String> detaylar;
  final String statusDescription; // sonda gösterilmeyecek (UI’dan kaldırıldı)

  const ResultSheet({
    super.key,
    required this.title,
    required this.detaylar,
    required this.statusDescription,
  });

  String _buildShareText() {
    final b = StringBuffer('Borçlanma Hesaplama Özeti\n');
    detaylar.forEach((k, v) => b.writeln('$k: $v'));
    b.writeln('\nDurum: $statusDescription');
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
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 12),

                  // Başlık — sabit ve yalın
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

                  // İçerik: tüm kalemler satır satır
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
                        // Durum Açıklaması bölümü UI'dan kaldırıldı.
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Alt orta paylaş — Apple paylaş ikonlu
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