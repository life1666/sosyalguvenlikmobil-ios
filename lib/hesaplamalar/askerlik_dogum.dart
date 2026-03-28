import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
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
              child: Text(
                valueText.isEmpty ? 'Seçiniz' : valueText,
                style: TextStyle(
                  color: isPlaceholder ? Colors.grey[700] : Colors.black,
                  fontWeight: AppW.body,
                ),
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
  final bool inline;
  final VoidCallback? onBack;
  const BorclanmaHesaplamaScreen({super.key, this.inline = false, this.onBack});

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
  final double _asgariAylikGelir = 33030.00;
  double get _ustLimitGelir => _asgariAylikGelir * 9.0;
  final String _basvuruTarihi = 'Güncel asgari ücret üzerinden hesaplanmaktadır.';

  // ✅ Prim oranları
  final double _oranDogum = 0.32; // Doğum borçlanması
  final double _oranDiger = 0.45; // Diğer tüm borçlanmalar

  bool get _isDogumBorclanmasi =>
      _secilenBorclanma == 'Ücretsiz Doğum veya Analık İzni Süreleri';

  double get _primOrani => _isDogumBorclanmasi ? _oranDogum : _oranDiger;


  final TextEditingController _gunController = TextEditingController();

  String? _secilenBorclanma;
  final List<String> _borclanmaSureleri = const [
    'Askerlik Borçlanması',
    'Yurt Dışı Borçlanması',
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
    'Yurt Dışı Borçlanması': Icons.public,
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

  bool _showingResult = false;

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
    final altLimitGunlukBedel = gunlukAsgariGelir * _primOrani;
    final altLimit = gunSayisi * altLimitGunlukBedel;

    final gunlukUstGelir = _ustLimitGelir / 30.0;
    final ustLimitGunlukBedel = gunlukUstGelir * _primOrani;
    final ustLimit = gunSayisi * ustLimitGunlukBedel;

    setState(() {
      _hesaplamaSonucu = {
        'basarili': true,
        'mesaj': toTitleCase('Borçlanma hesaplaması başarıyla tamamlandı!'),
        'detaylar': {
          'Başvuru Tarihi': _basvuruTarihi,
          'Borçlanma Türü': _secilenBorclanma ?? '',
          'Borçlanılacak Gün Sayısı': '$gunSayisi gün',
          'Prim Oranı': _isDogumBorclanmasi ? '%32 (Doğum)' : '%45 (Diğer)',
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
        
        // Firebase Analytics: Hesaplama tamamlandı
        AnalyticsHelper.logCalculation('askerlik_dogum_borclanma', parameters: {
          'hesaplama_turu': 'Askerlik/Doğum Borçlanma',
        });
      } catch (e) {
        debugPrint('Son hesaplama kaydedilirken hata: $e');
      }
    }
    
    if (mounted) setState(() => _showingResult = true);
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2ECC71);
    const gray = Color(0xFFF8FAFC);
    const slate100 = Color(0xFFF1F5F9);
    const slate400 = Color(0xFF94A3B8);

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
                        child: const Icon(Icons.military_tech_rounded, color: green, size: 28),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SGK Prim Borçlanması',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _ReadOnlyField(
                        label: 'Hesaplama Tutarı',
                        valueText: _basvuruTarihi,
                      ),
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
                      _NumberRow(
                        label: 'Borçlanılacak Gün Sayısı',
                        controller: _gunController,
                        hint: 'Örn. 360',
                        maxLen: 4,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            await _hesapla();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Hesapla',
                            style: TextStyle(color: Colors.white, fontSize: 16 * kTextScale, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const _InfoNotice(),
                const SizedBox(height: 100),
              ],
            ),
          );

    if (widget.inline) return body;

    return Scaffold(
      backgroundColor: gray,
      appBar: AppBar(
        title: const Text(
          'SGK Prim Borçlanma Tutarı Hesaplama',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        titleSpacing: 16,
        centerTitle: false,
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
      ),
      body: body,
    );
  }

  Widget _buildResultView() {
    if (_hesaplamaSonucu == null) return const SizedBox.shrink();

    final basarili = (_hesaplamaSonucu?['basarili'] as bool?) ?? true;
    final mesaj = (_hesaplamaSonucu?['mesaj'] as String?) ?? 'Sonuç';
    final detaylar = Map<String, String>.from(_hesaplamaSonucu?['detaylar'] as Map? ?? {});
    final ekBilgi = (_hesaplamaSonucu?['ekBilgi'] as Map?)?.cast<String, String>() ?? <String, String>{};

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
              border: Border.all(color: basarili ? green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hesaplama Sonuçları',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: slate800),
                  ),
                  const SizedBox(height: 16),
                  for (final e in detaylar.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              e.key,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              e.value,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: slate800),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12, color: slate500)),
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