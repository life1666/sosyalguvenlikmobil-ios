import '../utils/calculator_design.dart';
import 'emeklilik_motorlari.dart' show emeklilikHesapla4c;
import 'emeklilik_tahmin_notu.dart';
import '../services/hesaplama_pdf_service.dart';
import '../services/premium_pdf_action.dart';
import 'package:src/utils/app_design.dart';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../sonhesaplama/sonhesaplama.dart';
import '../utils/analytics_helper.dart';
import '../utils/theme_helper.dart';

/// =================== GLOBAL KNOB’LAR ===================

const double kPageHPad = 16.0;          // Sol/sağ eşit boşluk
const double kTextScale = 1.00;         // Yazı ölçeği (0.90–1.10)
const Color  kTextColor = Colors.black; // Yazı ana rengi

// Divider (global)
const double kDividerThickness = 0.2;
const double kDividerSpace     = 2.0;

// Form alanı çerçevesi (kalınlık vs.)
const double kFieldBorderWidth   = 1.0; // ← kutu kalınlığı
const double kFieldBorderRadius  = 12.0;
const Color  kFieldBorderColor   = AppDesign.border;
const Color  kFieldFocusColor    = calculatorAccent;

// İkon genel (tema)
const Color  kIconColor = Colors.black87;
const double kIconSize  = 26.0;

/// ========== GLOBAL UYARI / MESAJ KNOB’LARI ==========
const String kMsgSelectGender       = 'Cinsiyetinizi Seçiniz';
const String kMsgSelectBirthDate    = 'Doğum Tarihi Seçiniz';
const String kMsgSelectStartDate    = 'Sigorta Başlangıç Tarihizi Seçiniz';
const String kMsgEnterValidNumber   = 'Prim Gün Sayınızı Giriniz';
const String kMsgFillAllFieldsSnack = 'Lütfen Tüm Alanları Doldurunuz.';
const String kMsgSelectGeneric      = 'Lütfen Seçim Yapınız';
/// =====================================================

/// ===== FINANSAL RAPOR KNOB’LARI =====
const double kReportMaxWidth      = 660.0;
const double kReportSectionGap    = 16.0;
const double kReportChartHeight   = 160.0;
const Color kReportPrimary        = Color(0xFF4F46E5); // indigo-600 benzeri
const Color kReportAccent         = Color(0xFF06B6D4); // cyan-500 benzeri
const Color kReportGood           = Color(0xFF16A34A); // green-600
const Color kReportWarn           = Color(0xFFDC2626); // red-600
/// =====================================

/// ===== SONUÇ EKRANI / GRAFİK / SAYFA KNOB’LARI =====
const Color  kResultSheetBg          = Colors.white;
const double kResultSheetCorner      = 22.0;
const double kResultHeaderScale      = 1.00;
const FontWeight kResultHeaderWeight = FontWeight.w500;

// Halka (Donut) Grafik knob’ları + callout/ok stilleri
const double kRingThickness        = 14.0;                 // halka kalınlığı
const double kRingLabelScale       = 0.95;                 // yüzde yazı ölçeği
const Color  kRingColorCompleted   = Colors.indigoAccent;  // tamamlanan
const Color  kRingColorMissing     = Colors.blueGrey;      // eksik
const Color  kRingColorBg          = Color(0xFFF5F5F5);    // arka boş halka
const double kRingMinSweepRadians  = 0.0001;               // 0 dilimde hata önler
const Color  kCalloutTextColor     = Colors.black87;       // callout metin
const Color  kCalloutBg            = Colors.white;         // callout kutusu
const Color  kCalloutBorder        = Color(0x11000000);    // callout kenar
const double kCalloutRadius        = 8.0;                  // callout köşe
const double kCalloutPaddingH      = 8.0;
const double kCalloutPaddingV      = 4.0;
const double kCalloutLineWidth     = 1.4;                  // çizgi kalınlığı
const Color  kCalloutLineColor     = Color(0x33000000);    // çizgi rengi
const double kCalloutArrowSize     = 6.5;                  // (KULLANILMIYOR) ok ucu boyutu
const double kCalloutOutset        = 18.0;                 // halkanın dışına çıkma
/// ====================================================

/// ===== YAZILI ÖZET MADDE (BULLET) KNOB’LARI =====
/// Sıralamaya dokunmadan, madde başı nokta/ikon YOK.
const double     kSumSectionTitleGap   = 8.0;
const double     kSumBetweenItemsGap   = 6.0;
const double     kSumSectionGap        = 16.0;
const EdgeInsets kSumItemPadding       = EdgeInsets.symmetric(vertical: 4, horizontal: 0);
const FontWeight kSumItemWeight        = FontWeight.w400;
const double     kSumItemFontScale     = 1.00;
const Color      kSumOkColor           = kReportGood;
const Color      kSumWarnColor         = kReportWarn;
/// ================================================

class AppW {
  static const appBarTitle = FontWeight.w700;
  static const heading     = FontWeight.w400;
  static const body        = FontWeight.w300;
  static const minor       = FontWeight.w300;
  static const tableHead   = FontWeight.w600;
}

extension AppText on BuildContext {
  TextStyle get sFormLabel => Theme.of(this).textTheme.titleLarge!;
  TextStyle get sBody      => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get sMinor     => Theme.of(this).textTheme.bodySmall!;
  TextStyle get sTableHead =>
      Theme.of(this).textTheme.bodyMedium!.copyWith(fontWeight: AppW.tableHead);
  TextStyle sEmphasis(Color color) =>
      Theme.of(this).textTheme.titleMedium!.copyWith(
        fontWeight: AppW.heading, color: color,
      );
}

/// ----------------------------------------------
///  TEMA
/// ----------------------------------------------
ThemeData uygulamaTemasi = (() {
  final double sizeTitleLg = 17 * kTextScale;
  final double sizeTitleMd = 15 * kTextScale;
  final double sizeBody    = 13 * kTextScale;
  final double sizeSmall   = 13 * kTextScale;
  final double sizeAppBar  = 22 * kTextScale;

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
        letterSpacing: 0.25,
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
        letterSpacing: 0.25,
        height: 1.22,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodyMedium: TextStyle(
        fontSize: sizeBody,
        color: kTextColor,
        fontWeight: AppW.body,
        height: 1.35,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodySmall: TextStyle(
        fontSize: sizeSmall,
        color: Colors.black87,
        fontWeight: AppW.minor,
        height: 1.4,
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

    iconTheme: const IconThemeData(
      color: kIconColor,
      size: kIconSize,
    ),

    inputDecorationTheme: InputDecorationTheme(
      isDense: false,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kFieldBorderRadius),
        borderSide: BorderSide(color: colorScheme.error, width: kFieldBorderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kFieldBorderRadius),
        borderSide: BorderSide(color: colorScheme.error, width: kFieldBorderWidth + 0.4),
      ),
      hintStyle: TextStyle(fontSize: 13 * kTextScale, color: Colors.grey[700]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 13 * kTextScale,
        fontWeight: AppW.body,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
    ),
  );
})();

/// ========== CENTER NOTICE (GLOBAL KNOB’LAR) ==========
enum AppNoticeType { error, info, success, warning }

const double     kCenterNoticeMaxWidth   = 360.0;
const double     kCenterNoticeRadius     = 16.0;
const double     kCenterNoticeElevation  = 0.0;
const EdgeInsets kCenterNoticePadding    = EdgeInsets.fromLTRB(16, 14, 16, 16);
const Duration   kCenterNoticeAnimDur    = Duration(milliseconds: 220);
const Duration   kCenterNoticeAutoHide   = Duration(seconds: 2);
const bool       kCenterNoticeBarrierDismissible = true;
/// =====================================================

Future<void> showCenterNotice(
    BuildContext context, {
      String? title,
      required String message,
      AppNoticeType type = AppNoticeType.error,
      bool autoHide = true,
    }) async {
  Color bg, border, textMain;
  IconData icon;

  switch (type) {
    case AppNoticeType.success:
      bg = const Color(0xFFEFFBF3);
      border = const Color(0xFF22C55E).withOpacity(.35);
      textMain = const Color(0xFF065F46);
      icon = Icons.check_circle_outline;
      break;
    case AppNoticeType.info:
      bg = const Color(0xFFF1F5FF);
      border = const Color(0xFF3B82F6).withOpacity(.35);
      textMain = const Color(0xFF1E3A8A);
      icon = Icons.info_outline;
      break;
    case AppNoticeType.warning:
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFF59E0B).withOpacity(.35);
      textMain = const Color(0xFF7C2D12);
      icon = Icons.warning_amber_rounded;
      break;
    case AppNoticeType.error:
    default:
      bg = const Color(0xFFFFF3F2);
      border = const Color(0xFFEF4444).withOpacity(.35);
      textMain = const Color(0xFF7F1D1D);
      icon = Icons.error_outline;
  }

  final dialogChild = ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: kCenterNoticeMaxWidth),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: textMain),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.trim().isNotEmpty)
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppW.heading,
                        color: textMain,
                      ),
                    ),
                  if (title != null && title.trim().isNotEmpty)
                    const SizedBox(height: 4),
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
          ],
        ),
      ),
    ),
  );

  final navigator = Navigator.of(context, rootNavigator: true);

  showGeneralDialog(
    context: context,
    barrierDismissible: kCenterNoticeBarrierDismissible,
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
    if (navigator.mounted) {
      navigator.pop();
    }
  }
}

/// =====================
///  GEÇMİŞ KAYIT MODELİ
/// =====================
class HesaplamaKaydi {
  final DateTime tarihSaat;
  final String cinsiyet;
  final DateTime dogumTarihi;
  final DateTime sigortaBaslangicTarihi;
  final int primGunSayisi;
  final String ozet; // kısa özet metni

  HesaplamaKaydi({
    required this.tarihSaat,
    required this.cinsiyet,
    required this.dogumTarihi,
    required this.sigortaBaslangicTarihi,
    required this.primGunSayisi,
    required this.ozet,
  });
}

/// ==================================================
///  GEÇMİŞ KAYIT DEPOSU (Uygulama içi paylaşılan)
///  Not: Kalıcı depolama istenmediği için memory’de.
/// ==================================================
class HesaplamaGecmis {
  static final List<HesaplamaKaydi> kayitlar = <HesaplamaKaydi>[];

  static void ekle(HesaplamaKaydi kayit) {
    // En yeni en başta dursun
    kayitlar.insert(0, kayit);
  }
}

void main() {
  runApp(const EmeklilikHesaplamaApp());
}

class EmeklilikHesaplamaApp extends StatelessWidget {
  const EmeklilikHesaplamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4/c – Memur Emeklilik Hesaplama',
      theme: uygulamaTemasi,
      home: const EmeklilikHesaplamaSayfasi(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// -------------------- Ortak UI: Inline Error Kartı --------------------
class _AppInlineError extends StatelessWidget {
  final String message;
  const _AppInlineError(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: const Color(0xFF7F1D1D),
                fontWeight: AppW.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmeklilikHesaplamaSayfasi extends StatefulWidget {
  final bool embedded;
  const EmeklilikHesaplamaSayfasi({super.key, this.embedded = false});

  @override
  _EmeklilikHesaplamaSayfasiState createState() =>
      _EmeklilikHesaplamaSayfasiState();
}

class _EmeklilikHesaplamaSayfasiState extends State<EmeklilikHesaplamaSayfasi> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('emeklilik_4c_opened');
  }

  final _formKey = GlobalKey<FormState>();

  DateTime? dogumTarihi;
  String? cinsiyet;
  DateTime? sigortaBaslangicTarihi;
  int? primGunSayisi;

  Map<String, dynamic>? hesaplamaSonucu;
  String? _calculationError;

  static const List<String> _trAylar = [
    'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
    'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
  ];

  String _formatDateDot(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  String _formatDateSlash(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  String _formatDateTimeTR(DateTime dt) =>
      '${_formatDateDot(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  int _daysInMonth(int year, int month) {
    if (month == 12) return DateTime(year + 1, 1, 0).day;
    return DateTime(year, month + 1, 0).day;
  }

  Future<void> _showDMYCupertinoPicker({
    required DateTime initial,
    required DateTime min,
    required DateTime max,
    required ValueChanged<DateTime> onConfirm,
  }) async {
    int selYear = initial.year.clamp(min.year, max.year);
    int selMonth = initial.month;
    int selDay = initial.day;

    final years = [for (int y = min.year; y <= max.year; y++) y];

    final yearCtrl = FixedExtentScrollController(initialItem: selYear - min.year);
    final monthCtrl = FixedExtentScrollController(initialItem: selMonth - 1);
    final dayCtrl = FixedExtentScrollController(initialItem: selDay - 1);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) {
        return Container(
          height: 310,
          color: Colors.white,
          child: StatefulBuilder(
            builder: (context, setSB) {
              final maxDay = _daysInMonth(selYear, selMonth);
              if (selDay > maxDay) selDay = maxDay;

              return Column(
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
                          onPressed: () {
                            final chosen = DateTime(selYear, selMonth, selDay);
                            final clamped = chosen.isBefore(min)
                                ? min
                                : (chosen.isAfter(max) ? max : chosen);
                            onConfirm(clamped);
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
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
                            scrollController: dayCtrl,
                            itemExtent: 32,
                            onSelectedItemChanged: (i) {
                              setSB(() => selDay = (i + 1).clamp(1, _daysInMonth(selYear, selMonth)));
                            },
                            children: [
                              for (int d = 1; d <= _daysInMonth(selYear, selMonth); d++)
                                Center(child: Text(d.toString().padLeft(2, '0'))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: monthCtrl,
                            itemExtent: 32,
                            onSelectedItemChanged: (i) {
                              setSB(() {
                                selMonth = i + 1;
                                final newMax = _daysInMonth(selYear, selMonth);
                                if (selDay > newMax) {
                                  selDay = newMax;
                                  dayCtrl.jumpToItem(selDay - 1);
                                }
                              });
                            },
                            children: [for (final m in _trAylar) Center(child: Text(m))],
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: yearCtrl,
                            itemExtent: 32,
                            onSelectedItemChanged: (i) {
                              setSB(() {
                                selYear = years[i];
                                final newMax = _daysInMonth(selYear, selMonth);
                                if (selDay > newMax) {
                                  selDay = newMax;
                                  dayCtrl.jumpToItem(selDay - 1);
                                }
                              });
                            },
                            children: [for (final y in years) Center(child: Text(y.toString()))],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// ======================================================
  /// >>> SWAPLANAN HESAPLAMA MOTORU (4/C mantığı)
  /// ======================================================
  /// =================== HESAPLAMA MOTORU SONU ===================

  Future<void> _hesaplaEmeklilik() async {
    FocusScope.of(context).unfocus();

    if (_calculationError != null) {
      setState(() => _calculationError = null);
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _showResultBottomSheet();
    } else {
      _showCalculationError('Eksik ya da hatalı alanları kontrol edin.');
    }
  }

  void _showCalculationError(String message) {
    if (!mounted) return;
    setState(() => _calculationError = message);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  /// Geçmiş kaydı için kısa özet metni üretir
  String _buildHistorySummary(Map<String, dynamic> sonuc) {
    final detaylar = Map<String, String>.from(sonuc['detaylar']['birlesik'] ?? {});
    final tahmini  = Map<String, dynamic>.from(sonuc['tahminiSonuclar'] ?? {});
    final b = StringBuffer();

    detaylar.forEach((k, v) => b.writeln('$k: $v'));
    tahmini.forEach((k, v) {
      if (v is Map && v['mesaj'] != null) b.writeln(v['mesaj']);
    });

    return b.toString().trim();
  }

  Future<void> _showResultBottomSheet() async {
    if (cinsiyet == null || dogumTarihi == null || sigortaBaslangicTarihi == null || primGunSayisi == null) {
      _showCalculationError(kMsgFillAllFieldsSnack);
      return;
    }

    DateTime today = DateTime.now();
    String? errorMessage;
    if (dogumTarihi!.isAfter(today)) {
      errorMessage = _cap("doğum tarihi günümüzden sonra olamaz.");
    } else if (sigortaBaslangicTarihi!.isBefore(dogumTarihi!)) {
      errorMessage = _cap("sigorta başlangıç tarihi doğum tarihinden önce olamaz.");
    } else if (sigortaBaslangicTarihi!.isBefore(DateTime(
        dogumTarihi!.year + 15, dogumTarihi!.month, dogumTarihi!.day))) {
      errorMessage =
          _cap("sigorta başlangıç tarihinde en az 15 yaşında olmalısınız.");
    } else if (sigortaBaslangicTarihi!.isAfter(today)) {
      errorMessage = _cap("sigorta başlangıç tarihi günümüzden sonra olamaz.");
    } else {
      int totalDays = today.difference(sigortaBaslangicTarihi!).inDays;
      int fullYears = totalDays ~/ 365;
      int remainingDays = totalDays % 365;
      int maxPremiumDays = (fullYears * 360) + remainingDays + 1;
      if ((primGunSayisi ?? 0) > maxPremiumDays) {
        errorMessage = _cap("prim gün sayısı ($primGunSayisi) maksimum olası gün sayısından ($maxPremiumDays) fazla.");
      }
    }
    if (errorMessage != null) {
      _showCalculationError(errorMessage);
      return;
    }

    setState(() {
      hesaplamaSonucu = emeklilikHesapla4c(
        dogumTarihi!, cinsiyet!, sigortaBaslangicTarihi!, primGunSayisi!,
      );
    });

    // === GEÇMİŞE KAYDET ===
    try {
      final ozet = _buildHistorySummary(hesaplamaSonucu!);
      final kayit = HesaplamaKaydi(
        tarihSaat: DateTime.now(),
        cinsiyet: cinsiyet!,
        dogumTarihi: dogumTarihi!,
        sigortaBaslangicTarihi: sigortaBaslangicTarihi!,
        primGunSayisi: primGunSayisi!,
        ozet: ozet,
      );
      HesaplamaGecmis.ekle(kayit);
    } catch (_) {
      // Sessizce geç; kayıt başarısızsa uygulama akışını bozma
    }

    // Son hesaplamalara kaydet
    try {
      final detaylar = Map<String, String>.from(hesaplamaSonucu!['detaylar']['birlesik'] ?? {});
      final tahmini = Map<String, dynamic>.from(hesaplamaSonucu!['tahminiSonuclar'] ?? {});
      
      // Sonuçları hazırla
      final sonuclar = <String, String>{};
      sonuclar.addAll(detaylar);
      
      // Tahmini sonuçları ekle
      tahmini.forEach((key, value) {
        if (value is Map && value['mesaj'] != null) {
          sonuclar[key] = value['mesaj'].toString();
        }
      });
      
      // Verileri hazırla
      final veriler = <String, dynamic>{
        'cinsiyet': cinsiyet,
        'dogumTarihi': dogumTarihi!.toIso8601String(),
        'sigortaBaslangicTarihi': sigortaBaslangicTarihi!.toIso8601String(),
        'primGunSayisi': primGunSayisi,
      };
      
      final sonHesaplama = SonHesaplama(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hesaplamaTuru: '4/c (Memur) Emeklilik Hesaplama',
        tarihSaat: DateTime.now(),
        veriler: veriler,
        sonuclar: sonuclar,
        ozet: _buildHistorySummary(hesaplamaSonucu!),
      );
      
      await SonHesaplamalarDeposu.ekle(sonHesaplama);
      
      // Firebase Analytics: Hesaplama tamamlandı
      AnalyticsHelper.logCalculation('emeklilik_4c', parameters: {
        'hesaplama_turu': '4/c (Memur) Emeklilik',
        'emekli_durumu': hesaplamaSonucu!['emekliMi']['durum'] ?? 'bilinmiyor',
      });
    } catch (e) {
      debugPrint('Son hesaplama kaydedilirken hata: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDesign.activeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kResultSheetCorner)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: FinancialReportSheet(
          sonuc: hesaplamaSonucu!,
          hesaplamaTuru: '4/c (Memur)',
          sigortaBaslangicTarihi: sigortaBaslangicTarihi,
        ),
      ),
    );
  }

  // Bilgilendirme alanı
  Widget _buildEkBilgiArea() {
    const maddeler = [
      'Sosyal Güvenlik Mobil, Herhangi Bir Resmi Kurumun Uygulaması Değilidir!',
      'Yapılan Hesaplamalar Tahmini ve Bilgi Amaçlıdır, Resmi Nitelik Taşımaz ve Herhangi Bir Sorumluluk Doğurmaz!',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Center(
          child: Text(
            'Bilgilendirme',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 6),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.black38, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                maddeler[0],
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: AppW.body,
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.black38, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                maddeler[1],
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: AppW.body,
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _cap(String text) {
    return text
        .split(' ')
        .map((w) {
      if (w.toLowerCase() == 've') return 've';
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCupertinoGenderField(),
                  _buildCupertinoDateFormField(
                    etiket: 'Doğum Tarihiniz',
                    value: dogumTarihi,
                    min: DateTime(1950, 1, 1),
                    max: DateTime(2050, 1, 1),
                    onChanged: (dt) => setState(() => dogumTarihi = dt),
                  ),
                  _buildCupertinoDateFormField(
                    etiket: 'Sigorta Başlangıç Tarihiniz',
                    value: sigortaBaslangicTarihi,
                    min: DateTime(1960, 1, 1),
                    max: DateTime(2050, 1, 1),
                    onChanged: (dt) => setState(() => sigortaBaslangicTarihi = dt),
                  ),
                  _buildNumberField(
                    label: 'Prim Gün Sayınız',
                    initialValue: primGunSayisi?.toString(),
                    onSaved: (val) => primGunSayisi = int.parse(val!),
                    validator: (val) =>
                    val == null || val.isEmpty || int.tryParse(val) == null
                        ? kMsgEnterValidNumber
                        : null,
                  ),
                  if (_calculationError != null) ...[
                    const SizedBox(height: 12),
                    _AppInlineError(_calculationError!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hesaplaEmeklilik,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: calculatorAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      child: Text('Hesapla', style: TextStyle(fontSize: 20 * kTextScale)),
                    ),
                  ),
                  ],
              ),
            );
    if (widget.embedded) return form;
    return CalculatorPage(
      title: '4/c (Memur) Emeklilik',
      icon: Icons.calendar_month_outlined,
      child: form,
    );
  }

  // ---- Alan bileşenleri (gender & date & number) ----
  Widget _buildCupertinoGenderField() {
    return FormField<String>(
      validator: (_) => cinsiyet == null ? kMsgSelectGender : null,
      builder: (field) {
        final bool hasError = field.errorText != null;
        final errorColor = Theme.of(context).colorScheme.error;

        TextStyle styleFor(String option) => TextStyle(
          color: (hasError && cinsiyet == null)
              ? errorColor
              : AppDesign.activeInk,
          fontWeight:
              (cinsiyet == option) ? FontWeight.w600 : FontWeight.w400,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cinsiyetiniz', style: context.sFormLabel),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kFieldBorderRadius),
                      side: BorderSide(
                        color: hasError ? errorColor : Colors.transparent,
                        width: hasError ? (kFieldBorderWidth + 0.2) : 0.0,
                      ),
                    ),
                  ),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: cinsiyet,
                    padding: const EdgeInsets.all(3),
                    backgroundColor: AppDesign.isDark
                        ? const Color(0xFF1C2938)
                        : const Color(0xFFF1F5F9),
                    thumbColor: AppDesign.activeSurface,
                    children: {
                      'Erkek': Center(
                        child: Text('Erkek', style: styleFor('Erkek')),
                      ),
                      'Kadın': Center(
                        child: Text('Kadın', style: styleFor('Kadın')),
                      ),
                    },
                    onValueChanged: (val) {
                      setState(() => cinsiyet = val);
                      field.didChange(val);
                    },
                  ),
                  ),
              ),
              if (hasError) _AppInlineError(field.errorText!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCupertinoDateFormField({
    required String etiket,
    required DateTime? value,
    required void Function(DateTime) onChanged,
    DateTime? min,
    DateTime? max,
  }) {
    final DateTime minDate = min ?? DateTime(1950, 1, 1);
    final DateTime maxDate = max ?? DateTime.now();

    String? _errorForLabel() {
      if (etiket.contains('Doğum')) return kMsgSelectBirthDate;
      if (etiket.contains('Sigorta')) return kMsgSelectStartDate;
      return kMsgSelectGeneric;
    }

    return FormField<DateTime>(
      validator: (_) => value == null ? _errorForLabel() : null,
      builder: (field) {
        final hasError = field.errorText != null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiket, style: context.sFormLabel),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  FocusManager.instance.primaryFocus?.unfocus();

                  final base = DateTime(1990, 1, 1);
                  final initial = (value ?? base).isBefore(minDate)
                      ? minDate
                      : (value ?? base).isAfter(maxDate)
                      ? maxDate
                      : (value ?? base);
                  await _showDMYCupertinoPicker(
                    initial: initial,
                    min: minDate,
                    max: maxDate,
                    onConfirm: (dt) {
                      onChanged(dt);
                      field.didChange(dt);
                      setState(() {});
                    },
                  );
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    errorText: null,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                      borderSide: BorderSide(
                        color: hasError ? Theme.of(context).colorScheme.error : kFieldBorderColor,
                        width: kFieldBorderWidth,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                      borderSide: BorderSide(
                        color: hasError ? Theme.of(context).colorScheme.error : kFieldFocusColor,
                        width: kFieldBorderWidth + 0.2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                        width: kFieldBorderWidth,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                        width: kFieldBorderWidth + 0.2,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  child: Text(
                    value != null ? _formatDateDot(value) : 'Seçiniz (Gün.Ay.Yıl)',
                    style: TextStyle(
                      fontSize: 14 * kTextScale,
                      fontWeight: AppW.body,
                      color: value != null
                          ? AppDesign.activeInk
                          : hasError
                          ? Theme.of(context).colorScheme.error
                          : AppDesign.activeMuted,
                    ),
                  ),
                ),
              ),
              if (hasError) _AppInlineError(field.errorText!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumberField({
    required String label,
    required String? initialValue,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.sFormLabel),
          const SizedBox(height: 6),
          FormField<String>(
            initialValue: initialValue,
            validator: validator,
            onSaved: onSaved,
            builder: (field) {
              final hasError = field.errorText != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: field.value,
                    onChanged: field.didChange,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      hintText: 'Gün Sayısı',
                      errorText: null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                        borderSide: BorderSide(
                          color: hasError ? Theme.of(context).colorScheme.error : kFieldBorderColor,
                          width: kFieldBorderWidth,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                        borderSide: BorderSide(
                          color: hasError ? Theme.of(context).colorScheme.error : kFieldFocusColor,
                          width: kFieldBorderWidth + 0.2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                          width: kFieldBorderWidth,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                          width: kFieldBorderWidth + 0.2,
                        ),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (hasError) _AppInlineError(field.errorText!),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// =============== FINANCIAL REPORT SHEET ================
/// =======================================================

class FinancialReportSheet extends StatefulWidget {
  final Map<String, dynamic> sonuc;
  final String hesaplamaTuru; // 4/a (SSK), 4/b (Bağ-kur), 4/c (Memur)
  final DateTime? sigortaBaslangicTarihi;
  const FinancialReportSheet({
    super.key,
    required this.sonuc,
    required this.hesaplamaTuru,
    this.sigortaBaslangicTarihi,
  });

  @override
  State<FinancialReportSheet> createState() => _FinancialReportSheetState();
}

class _FinancialReportSheetState extends State<FinancialReportSheet> {
  String _tab = 'Hesaplama Sonucu'; // Segmented choice

  @override
  Widget build(BuildContext context) {
    final emekliMi = Map<String, dynamic>.from(widget.sonuc['emekliMi']);
    final detaylar = Map<String, String>.from(widget.sonuc['detaylar']['birlesik']);
    final tahmini  = Map<String, dynamic>.from(widget.sonuc['tahminiSonuclar'] ?? {});

    final parsed = FinancialReportPage._parsePrimFromDetay(detaylar);
    final BarDatum? normal =
    parsed.cast<BarDatum?>().firstWhere((e) => (e?.kategori ?? '').toLowerCase().contains('normal'), orElse: () => null);
    final BarDatum? yasHaddi =
    parsed.cast<BarDatum?>().firstWhere((e) => (e?.kategori ?? '').toLowerCase().contains('yaş'), orElse: () => null);

    final PieInput pieNormal = FinancialReportPage._toPie(normal, fallbackLabel: 'Normal Emeklilik');
    final PieInput pieYas     = FinancialReportPage._toPie(yasHaddi, fallbackLabel: 'Yaş Haddinden Emeklilik');

    // PAYLAŞILACAK ÖZET METNİ
    

    return Theme(data: calculatorTheme(context), child: Stack(
      children: [
        // İçerik
        SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kReportMaxWidth),
              child: Column(
                children: [
 Padding(padding: const EdgeInsets.fromLTRB(20, 12, 8, 4), child: Row(children: [
 Expanded(child: Text('Hesaplama Sonucu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppDesign.activeInk))),
 IconButton(tooltip: 'Kapat', onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: AppDesign.activeMuted)),
 ])),
                  const SizedBox(height: 10),
                  Container(
                    width: 48, height: 5,
                    decoration: BoxDecoration(
                  color: AppDesign.activeBorder, borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // İkonsuz Segmented başlık
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: _tab,
                  backgroundColor: AppDesign.isDark ? const Color(0xFF1C2938) : const Color(0xFFF0FDF4),
                  thumbColor: AppDesign.activeSurface,
                      children: {
                        'Hesaplama Sonucu': Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            'Hesaplama Sonucu',
                            style: TextStyle(
                              fontSize: 14 * kResultHeaderScale,
                              fontWeight: kResultHeaderWeight,
                              color: AppDesign.activeInk,
                            ),
                          ),
                        ),
                        'Grafik': Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            'Grafik',
                            style: TextStyle(
                              fontSize: 14 * kResultHeaderScale,
                              fontWeight: kResultHeaderWeight,
                              color: AppDesign.activeInk,
                            ),
                          ),
                        ),
                      },
                      onValueChanged: (v) => setState(() => _tab = v ?? _tab),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),

                  // İçerik gövdesi
                  Expanded(
                    child: _tab == 'Hesaplama Sonucu'
                        ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), // altta paylaş için boşluk
                      children: [
                        _SummaryBullets(
                          emekliMi: emekliMi,
                          normal: normal,
                          yasHaddi: yasHaddi,
                          tahmini: tahmini,
                          detaylarRaw: detaylar,
                        ),
                      ],
                    )
                        : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      children: [
                        // MODERNİST GRAFİK BÖLÜMÜ (KART YOK)
                        _ModernDonutSection(
                          title: 'Normal Emeklilik',
                          input: pieNormal,
                        ),
                        // Grafik sekmesi için istenen divider
                        Divider(
                          color: AppDesign.activeBorder,
                          thickness: 0.2,
                          height: 22,
                        ),
                        _ModernDonutSection(
                          title: 'Yaş Haddinden Emeklilik',
                          input: pieYas,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ALT ORTA BUTONLAR
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: SafeArea(
            top: false,
            child: SizedBox(width: double.infinity, height: 44, child: OutlinedButton.icon(
                      onPressed: () => PremiumPdfAction.run(context,
                          () => HesaplamaPdfService.shareSummary(
                        title: '4C Emeklilik Hesaplama',
                        details: detaylar,
                      )),
                      icon: const Icon(Icons.workspace_premium_outlined,
                          size: 18),
                      label: const Text('Premium PDF',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    )),
          ),
        ),
      ],
    ));
  }
}

/// Yardımcı: Modernist donut bölüm (başlık + halka, KART YOK)
class _ModernDonutSection extends StatelessWidget {
  final String title;
  final PieInput input;
  const _ModernDonutSection({required this.title, required this.input});

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: th.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
                          color: AppDesign.activeInk,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 10),

        // Kart kaldırıldı; sadece grafik
        SizedBox(
          height: kReportChartHeight,
          width: double.infinity,
          child: DonutChart(
            input: input,
            completed: kRingColorCompleted,
            missing: kRingColorMissing,
            bg: kRingColorBg,
            thickness: kRingThickness,
          ),
        ),

        const SizedBox(height: 12),

        // Açıklamalar ALTLI-ÜSTLÜ
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LegendSwatch(
              color: kRingColorCompleted,
              label: 'Toplam Prim Günü',
            ),
            SizedBox(height: 8),
            _LegendSwatch(
              color: kRingColorMissing,
              label: 'Emeklilik İçin Eksik Prim Günü',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendSwatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black.withOpacity(.08)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Eski yardımcıları tutan sınıf (statik parse/toPie için)
class FinancialReportPage extends StatelessWidget {
  final Map<String, dynamic> sonuc;
  const FinancialReportPage({super.key, required this.sonuc});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  static List<BarDatum> _parsePrimFromDetay(Map<String, String> detaylar) {
    final RegExp gunRe = RegExp(r'(\d+)\s*Gün', caseSensitive: false);
    final List<BarDatum> out = [];
    detaylar.forEach((kategori, metin) {
      final parts = metin.split('|');
      String mevcutS = parts.isNotEmpty ? parts[0] : '';
      String gerekliS = parts.length > 1 ? parts[1] : '';

      int mevcut = 0;
      int gerekli = 0;

      final mevcutMatch = gunRe.allMatches(mevcutS).toList();
      final gerekliMatch = gunRe.allMatches(gerekliS).toList();

      if (mevcutMatch.isNotEmpty) {
        mevcut = int.tryParse(mevcutMatch.first.group(1)!) ?? 0;
      }
      if (gerekliMatch.isNotEmpty) {
        gerekli = int.tryParse(gerekliMatch.last.group(1)!) ?? 0;
      }

      if (gerekli == 0 && mevcut == 0) return;
      out.add(BarDatum(kategori: kategori, mevcutGun: mevcut, gerekliGun: gerekli));
    });
    return out;
  }

  static PieInput _toPie(BarDatum? d, {required String fallbackLabel}) {
    if (d == null) return PieInput(label: '$fallbackLabel (veri yok)', mevcut: 0, eksik: 1);
    final mevcut = d.mevcutGun.clamp(0, d.gerekliGun);
    final eksik  = (d.gerekliGun - mevcut).clamp(0, d.gerekliGun);
    return PieInput(label: '$fallbackLabel (Gerekli: ${d.gerekliGun})', mevcut: mevcut.toDouble(), eksik: eksik.toDouble());
  }
}

class BarDatum {
  final String kategori;
  final int mevcutGun;
  final int gerekliGun;
  BarDatum({required this.kategori, required this.mevcutGun, required this.gerekliGun});
}

/// ---------- Pie/Donut Chart (ok/callout ile)
class PieInput {
  final String label;
  final double mevcut;
  final double eksik;
  const PieInput({required this.label, required this.mevcut, required this.eksik});
}

class DonutChart extends StatelessWidget {
  final PieInput input;
  final Color completed;
  final Color missing;
  final Color bg;
  final double thickness;

  const DonutChart({
    super.key,
    required this.input,
    required this.completed,
    required this.missing,
    required this.bg,
    required this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(
        input: input,
        completed: completed,
        missing: missing,
        bg: bg,
        thickness: thickness,
        textTheme: Theme.of(context).textTheme,
      ),
      size: Size.infinite,
    );
  }
}

class _DonutPainter extends CustomPainter {
  final PieInput input;
  final Color completed;
  final Color missing;
  final Color bg;
  final double thickness;
  final TextTheme textTheme;

  _DonutPainter({
    required this.input,
    required this.completed,
    required this.missing,
    required this.bg,
    required this.thickness,
    required this.textTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = (input.mevcut + input.eksik);
    final double pad = 10;
    final Rect rect = Rect.fromLTWH(pad, pad + 8, size.width - pad * 2, size.height - pad * 2 - 26);
    final Offset center = rect.center;
    final double radius = rect.shortestSide / 2;

    // Arka halka
    final Paint pBg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = kRingColorBg
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, math.pi * 2, false, pBg);

    // Dilim oranları
    double percCompleted = total == 0 ? 0.0 : (input.mevcut / total);
    double percMissing   = total == 0 ? 1.0 : (input.eksik / total);

    double start = -math.pi / 2;

    final Paint pDone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = completed
      ..strokeCap = StrokeCap.round;

    final Paint pMiss = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = missing
      ..strokeCap = StrokeCap.round;

    final double sweepDone = (percCompleted * 2 * math.pi).clamp(kRingMinSweepRadians, 2 * math.pi);
    final double sweepMiss = (percMissing   * 2 * math.pi).clamp(kRingMinSweepRadians, 2 * math.pi);

    // Dilimler
    if (percCompleted > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweepDone, false, pDone);
    }
    if (percMissing > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start + sweepDone, sweepMiss, false, pMiss);
    }

    // Callout/çizgi + yüzde kutusu (ok ucu YOK)
    void drawCallout(double startAngle, double sweepAngle, double percentage, Color color, {bool alignRight = true}) {
      if (percentage <= 0) return;

      final mid = startAngle + sweepAngle / 2;

      // Başlangıç: halkanın dış kenarı
      final double rOuter = radius + 2;
      final Offset p0 = Offset(center.dx + rOuter * math.cos(mid), center.dy + rOuter * math.sin(mid));

      // Dışa doğru kısa çizgi
      final Offset p1 = Offset(center.dx + (rOuter + kCalloutOutset) * math.cos(mid),
          center.dy + (rOuter + kCalloutOutset) * math.sin(mid));

      // Yatay offset yönü
      final bool right = alignRight ? (math.cos(mid) >= 0) : (math.cos(mid) > 0);
      final double hLen = 24;
      final Offset p2 = p1 + Offset(right ? hLen : -hLen, 0);

      final Paint linePaint = Paint()
        ..color = kCalloutLineColor
        ..strokeWidth = kCalloutLineWidth
        ..style = PaintingStyle.stroke;

      // Ana çizgi + yatay
      final Path line = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy);
      canvas.drawPath(line, linePaint);

      // Yüzde metni
      final String text = '${(percentage * 100).toStringAsFixed(1)}%';
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: textTheme.bodySmall!.copyWith(
            color: kCalloutTextColor,
            fontWeight: FontWeight.w700,
            fontSize: (textTheme.bodySmall!.fontSize ?? 12) * kRingLabelScale,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double boxW = tp.width + kCalloutPaddingH * 2;
      final double boxH = tp.height + kCalloutPaddingV * 2;
      final Rect box = Rect.fromLTWH(
        right ? (p2.dx + 6) : (p2.dx - 6 - boxW),
        p2.dy - boxH / 2,
        boxW,
        boxH,
      );

      final RRect rr = RRect.fromRectAndRadius(box, Radius.circular(kCalloutRadius));
      final Paint pBox = Paint()..color = kCalloutBg;
      final Paint pBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = kCalloutBorder;

      canvas.drawRRect(rr, pBox);
      canvas.drawRRect(rr, pBorder);

      tp.paint(canvas, Offset(box.left + kCalloutPaddingH, box.top + kCalloutPaddingV));
    }

    // Sağ/sol yerleşimi otomatik olarak orta açıya göre belirle
    drawCallout(start, sweepDone, percCompleted, completed, alignRight: true);
    drawCallout(start + sweepDone, sweepMiss, percMissing, missing, alignRight: false);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.input != input ||
          old.completed != completed ||
          old.missing != missing ||
          old.bg != bg ||
          old.thickness != thickness ||
          old.textTheme != textTheme;
}

/// ---------- (Yazılı özet) Requirement + _SummaryBullets (noktasız)
class Requirement {
  final int mevcutGun, gerekliGun;
  final int mevcutYas, gerekliYas;
  final int mevcutYil, gerekliYil;
  Requirement({
    required this.mevcutGun,
    required this.gerekliGun,
    required this.mevcutYas,
    required this.gerekliYas,
    required this.mevcutYil,
    required this.gerekliYil,
  });
}

class _SummaryBullets extends StatelessWidget {
  final Map<String, dynamic> emekliMi;
  final BarDatum? normal;
  final BarDatum? yasHaddi;
  final Map<String, dynamic> tahmini;
  final Map<String, String> detaylarRaw;

  const _SummaryBullets({
    required this.emekliMi,
    required this.normal,
    required this.yasHaddi,
    required this.tahmini,
    required this.detaylarRaw,
  });

  Requirement _reqFor(String kategori) {
    final metin = detaylarRaw[kategori] ?? '';
    final parts = metin.split('|');
    final mevcutS = parts.isNotEmpty ? parts[0] : '';
    final gerekliS = parts.length > 1 ? parts[1] : '';

    final gunRe = RegExp(r'(\d+)\s*Gün', caseSensitive: false);
    final yasRe = RegExp(r'(\d+)\s*Yaş', caseSensitive: false);
    final yilRe = RegExp(r'(\d+)\s*Yıl', caseSensitive: false);

    int mGun = int.tryParse(gunRe.firstMatch(mevcutS)?.group(1) ?? '0') ?? 0;
    int gGun = int.tryParse(gunRe.firstMatch(gerekliS)?.group(1) ?? '0') ?? 0;

    int mYas = int.tryParse(yasRe.firstMatch(mevcutS)?.group(1) ?? '0') ?? 0;
    int gYas = int.tryParse(yasRe.firstMatch(gerekliS)?.group(1) ?? '0') ?? 0;

    int mYil = int.tryParse(yilRe.firstMatch(mevcutS)?.group(1) ?? '0') ?? 0;
    int gYil = 0;
    final gyMatches = yilRe.allMatches(gerekliS).toList();
    if (gyMatches.isNotEmpty) {
      gYil = int.tryParse(gyMatches.last.group(1) ?? '0') ?? 0;
    }

    return Requirement(
      mevcutGun: mGun, gerekliGun: gGun,
      mevcutYas: mYas, gerekliYas: gYas,
      mevcutYil: mYil, gerekliYil: gYil,
    );
  }

  Widget _line(BuildContext context, String text, {Color? emphasis}) {
 return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
 decoration: BoxDecoration(color: emphasis != null ? (AppDesign.isDark ? const Color(0xFF12372B) : const Color(0xFFF0FDF4)) : Colors.transparent,
 borderRadius: BorderRadius.circular(12)),
 child: Text(text, style: TextStyle(fontSize: 14, height: 1.5, color: emphasis != null ? (AppDesign.isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534)) : AppDesign.activeInk,
 fontWeight: emphasis != null ? FontWeight.w700 : FontWeight.w400)));
 }

  @override
  Widget build(BuildContext context) {
    final reqNormal   = _reqFor('Normal Emeklilik');
    final reqYasHaddi = _reqFor('Yaş Haddinden Emeklilik');

    Widget section(String title, bool hak, BarDatum? d, Requirement req, String tahminKey) {
      final durumText = hak ? 'Emekliliğe Hak Kazandınız' : 'Emekliliğe Henüz Hak Kazanamadınız';
      final durumColor = hak ? kSumOkColor : kSumWarnColor;
      final eksikGun = (d == null) ? 0 : (d.gerekliGun - d.mevcutGun).clamp(0, d.gerekliGun);
      final tahminMesaj = (tahmini[tahminKey] is Map) ? (tahmini[tahminKey]['mesaj'] as String?) : null;

      final items = <Widget>[
        _line(context, 'Durum: $durumText', emphasis: durumColor),
        _line(context, 'Mevcut Prim Gününüz: ${d?.mevcutGun ?? '-'} gün'),
        _line(context, 'Emeklilik İçin Gerekli Prim Gün Sayısı: ${d?.gerekliGun ?? '-'} gün'),
        if (!hak && d != null && d.gerekliGun > 0)
          _line(context, 'Prim Günü Tamamlanma Oranı: ${(d.mevcutGun / d.gerekliGun * 100).clamp(0, 100).toStringAsFixed(1)}%'),
        _line(context, 'Eksik Prim Gün Sayınız: ${hak ? 0 : eksikGun} gün'),
        if (req.gerekliYas > 0)
          _line(context, 'Emeklilik Yaşınız: ${req.gerekliYas}'),
        if (req.gerekliYil > 0)
          _line(context, 'Sigortalılık Yılı Şartı: ${req.mevcutYil}/${req.gerekliYil}'),
        if (!hak && (tahminMesaj != null && tahminMesaj.trim().isNotEmpty))
          EmeklilikTahminNotu(mesaj: tahminMesaj),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            color: AppDesign.activeInk,
          )),
          SizedBox(height: kSumSectionTitleGap),
          ..._intersperse(items, SizedBox(height: kSumBetweenItemsGap)),
        ],
      );
    }

    // 1 fiziksel piksel kalınlığında divider (her cihazda görünür)
    final hairlineIndigoDivider = Divider(
      color: AppDesign.activeBorder,
      thickness: 0.4 / MediaQuery.of(context).devicePixelRatio,
      height: 16,
    );

    return SingleChildScrollView(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('Normal Emeklilik', emekliMi['normal'] == true, normal, reqNormal, 'Normal Emeklilik'),
        hairlineIndigoDivider,
        section('Yaş Haddinden Emeklilik', emekliMi['yasHaddi'] == true, yasHaddi, reqYasHaddi, 'Yaş Haddinden Emeklilik'),
      ],
    ));
  }

  List<Widget> _intersperse(List<Widget> list, Widget separator) {
    if (list.isEmpty) return list;
    final out = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      out.add(list[i]);
      if (i != list.length - 1) out.add(separator);
    }
    return out;
  }
}
