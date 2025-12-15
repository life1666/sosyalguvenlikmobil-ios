import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../emeklilik_takip/emeklilik_takip.dart';
import '../sonhesaplama/sonhesaplama.dart';
import '../utils/analytics_helper.dart';

/// =================== GLOBAL KNOB’LAR ===================

const double kPageHPad = 16.0;          // Sol/sağ eşit boşluk
const double kTextScale = 1.00;         // Yazı ölçeği (0.90–1.10)
const Color  kTextColor = Colors.black; // Yazı ana rengi

// Divider (global)
const double kDividerThickness = 0.2;
const double kDividerSpace     = 2.0;

// Form alanı çerçevesi (kalınlık vs.)
const double kFieldBorderWidth   = 0.2; // ← kutu kalınlığı
const double kFieldBorderRadius  = 8.0;
const Color  kFieldBorderColor   = Colors.black87;
const Color  kFieldFocusColor    = Colors.black87;

// İkon genel (tema)
const Color  kIconColor = Colors.black87;
const double kIconSize  = 26.0;

/// ========== GLOBAL UYARI / MESAJ KNOB’LARI ==========
const String kMsgSelectGender       = 'Lütfen Cinsiyetinizi Seçiniz';
const String kMsgSelectBirthDate    = 'Lütfen Doğum Tarihizi Seçiniz';
const String kMsgSelectStartDate    = 'Lütfen Sigorta Başlangıç Tarihinizi Seçiniz';
const String kMsgEnterValidNumber   = 'Lütfen Prim Gün Sayınızı Giriniz';
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
const double kCalloutOutset        = 18.0;                 // halkanın dışına çıkma
/// ====================================================

/// ===== YAZILI ÖZET MADDE (BULLET) KNOB’LARI =====
const double     kSumSectionTitleGap   = 8.0;
const double     kSumBetweenItemsGap   = 5.0; // hafif sıkıştırma (taşma riskini azaltır)
const double     kSumSectionGap        = 16.0;
const EdgeInsets kSumItemPadding       = EdgeInsets.symmetric(vertical: 3, horizontal: 0);
const FontWeight kSumItemWeight        = FontWeight.w400;
const double     kSumItemFontScale     = 0.98; // küçük ayar (taşma riskini azaltır)
const Color      kSumOkColor           = kReportGood;
const Color      kSumWarnColor         = kReportWarn;

/// Doğum tarihi InputDecorator yüksekliği
const double kFieldMinHeight = 48.0;

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
      title: '4/A – SSK Emeklilik Hesaplama',
      theme: uygulamaTemasi,
      home: const EmeklilikHesaplama4aSayfasi(),
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

class EmeklilikHesaplama4aSayfasi extends StatefulWidget {
  const EmeklilikHesaplama4aSayfasi({super.key});

  @override
  _EmeklilikHesaplama4aSayfasiState createState() =>
      _EmeklilikHesaplama4aSayfasiState();
}

class _EmeklilikHesaplama4aSayfasiState extends State<EmeklilikHesaplama4aSayfasi> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('emeklilik_4a_opened');
  }

  final _formKey = GlobalKey<FormState>();

  DateTime? dogumTarihi;
  String? cinsiyet;
  DateTime? sigortaBaslangicTarihi;
  int? primGunSayisi;

  Map<String, dynamic>? hesaplamaSonucu;

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

  Map<String, dynamic> emeklilikHesapla(
      DateTime dogumTarihi,
      String cinsiyet,
      DateTime sigortaBaslangic,
      int primGun,
      ) {
    DateTime today = DateTime.now();

    int age = today.year - dogumTarihi.year;
    if (DateTime(today.year, dogumTarihi.month, dogumTarihi.day).isAfter(today)) {
      age--;
    }

    int insuranceYears = today.year - sigortaBaslangic.year;
    if (DateTime(today.year, sigortaBaslangic.month, sigortaBaslangic.day).isAfter(today)) {
      insuranceYears--;
    }

    bool normalEligible = false;
    bool ageLimitEligible = false;
    String message = "";
    Map<String, String> details = {};
    Map<String, Map<String, dynamic>> tahminiSonuclar = {};

    DateTime cat1Upper = DateTime(1999, 9, 9);
    DateTime cat2Upper = DateTime(2008, 5, 1);
    DateTime cat3Lower = DateTime(2008, 5, 1);

    int reqInsuranceYearsNormal = 0;
    int reqPrimNormal = 0;
    int reqAgeNormal = 0;

    int reqInsuranceYearsYas = 0;
    int reqPrimYas = 0;
    int reqAgeYas = 0;

    if (sigortaBaslangic.isBefore(cat1Upper)) {
      if (cinsiyet == "Erkek") {
        reqInsuranceYearsNormal = 25;
        if (sigortaBaslangic.isBefore(DateTime(1976, 9, 9))) {
          reqPrimNormal = 5000;
        } else if (sigortaBaslangic.isBefore(DateTime(1979, 5, 24))) {
          reqPrimNormal = 5000;
        } else if (sigortaBaslangic.isBefore(DateTime(1980, 11, 24))) {
          reqPrimNormal = 5000;
        } else if (sigortaBaslangic.isBefore(DateTime(1982, 5, 24))) {
          reqPrimNormal = 5075;
        } else if (sigortaBaslangic.isBefore(DateTime(1983, 11, 24))) {
          reqPrimNormal = 5150;
        } else if (sigortaBaslangic.isBefore(DateTime(1985, 5, 24))) {
          reqPrimNormal = 5225;
        } else if (sigortaBaslangic.isBefore(DateTime(1986, 11, 24))) {
          reqPrimNormal = 5300;
        } else if (sigortaBaslangic.isBefore(DateTime(1988, 5, 24))) {
          reqPrimNormal = 5375;
        } else if (sigortaBaslangic.isBefore(DateTime(1989, 11, 24))) {
          reqPrimNormal = 5450;
        } else if (sigortaBaslangic.isBefore(DateTime(1991, 5, 24))) {
          reqPrimNormal = 5525;
        } else if (sigortaBaslangic.isBefore(DateTime(1992, 11, 24))) {
          reqPrimNormal = 5600;
        } else if (sigortaBaslangic.isBefore(DateTime(1994, 5, 24))) {
          reqPrimNormal = 5675;
        } else if (sigortaBaslangic.isBefore(DateTime(1995, 11, 24))) {
          reqPrimNormal = 5750;
        } else if (sigortaBaslangic.isBefore(DateTime(1997, 5, 24))) {
          reqPrimNormal = 5825;
        } else if (sigortaBaslangic.isBefore(DateTime(1998, 11, 24))) {
          reqPrimNormal = 5900;
        } else {
          reqPrimNormal = 5975;
        }
        reqAgeNormal = 0;

        reqInsuranceYearsYas = 15;
        reqPrimYas = 3600;
        reqAgeYas = 60;

        normalEligible = (primGun >= reqPrimNormal && insuranceYears >= reqInsuranceYearsNormal);
        ageLimitEligible = today.isAfter(DateTime(2014, 5, 24)) &&
            age >= 60 &&
            primGun >= 3600 &&
            insuranceYears >= 15;

        details["Normal Emeklilik"] =
        "Mevcut: $primGun Gün, $insuranceYears Yıl | Gerekli: $reqPrimNormal Gün, $reqInsuranceYearsNormal Yıl";
        details["Yaş Haddinden Emeklilik"] =
        "Mevcut: $age Yaş, $primGun Gün, $insuranceYears Yıl | Gerekli: 60 Yaş, 3600 Gün, 15 Yıl";
      } else {
        reqInsuranceYearsNormal = 20;
        if (sigortaBaslangic.isBefore(DateTime(1981, 9, 9))) {
          reqPrimNormal = 5000;
        } else if (sigortaBaslangic.isBefore(DateTime(1984, 5, 24))) {
          reqPrimNormal = 5000;
        } else if (sigortaBaslangic.isBefore(DateTime(1985, 5, 24))) {
          reqPrimNormal = 5000;
        } else if (sigortaBaslangic.isBefore(DateTime(1986, 5, 24))) {
          reqPrimNormal = 5075;
        } else if (sigortaBaslangic.isBefore(DateTime(1987, 5, 24))) {
          reqPrimNormal = 5150;
        } else if (sigortaBaslangic.isBefore(DateTime(1988, 5, 24))) {
          reqPrimNormal = 5225;
        } else if (sigortaBaslangic.isBefore(DateTime(1989, 5, 24))) {
          reqPrimNormal = 5300;
        } else if (sigortaBaslangic.isBefore(DateTime(1990, 5, 24))) {
          reqPrimNormal = 5375;
        } else if (sigortaBaslangic.isBefore(DateTime(1991, 5, 24))) {
          reqPrimNormal = 5450;
        } else if (sigortaBaslangic.isBefore(DateTime(1992, 5, 24))) {
          reqPrimNormal = 5525;
        } else if (sigortaBaslangic.isBefore(DateTime(1993, 5, 24))) {
          reqPrimNormal = 5600;
        } else if (sigortaBaslangic.isBefore(DateTime(1994, 5, 24))) {
          reqPrimNormal = 5675;
        } else if (sigortaBaslangic.isBefore(DateTime(1995, 5, 24))) {
          reqPrimNormal = 5750;
        } else if (sigortaBaslangic.isBefore(DateTime(1996, 5, 24))) {
          reqPrimNormal = 5825;
        } else if (sigortaBaslangic.isBefore(DateTime(1997, 5, 24))) {
          reqPrimNormal = 5900;
        } else {
          reqPrimNormal = 5975;
        }
        reqAgeNormal = 0;

        reqInsuranceYearsYas = 15;
        reqPrimYas = 3600;
        reqAgeYas = 58;

        normalEligible = (primGun >= reqPrimNormal && insuranceYears >= reqInsuranceYearsNormal);
        ageLimitEligible = today.isAfter(DateTime(2011, 5, 24)) &&
            age >= 58 &&
            primGun >= 3600 &&
            insuranceYears >= 15;

        details["Normal Emeklilik"] =
        "Mevcut: $primGun Gün, $insuranceYears Yıl | Gerekli: $reqPrimNormal Gün, $reqInsuranceYearsNormal Yıl";
        details["Yaş Haddinden Emeklilik"] =
        "Mevcut: $age Yaş, $primGun Gün, $insuranceYears Yıl | Gerekli: 58 Yaş, 3600 Gün, 15 Yıl";
      }
    } else if (sigortaBaslangic.isBefore(cat2Upper) &&
        sigortaBaslangic.isAfter(cat1Upper.subtract(const Duration(days: 1)))) {
      if (cinsiyet == "Erkek") {
        reqInsuranceYearsNormal = 0;
        reqPrimNormal = 7000;
        reqAgeNormal = 60;

        reqInsuranceYearsYas = 25;
        reqPrimYas = 4500;
        reqAgeYas = 60;

        normalEligible = (primGun >= 7000 && age >= 60);
        ageLimitEligible = (primGun >= 4500 && age >= 60 && insuranceYears >= 25);

        details["Normal Emeklilik"] =
        "Mevcut: $age Yaş, $primGun Gün | Gerekli: 60 Yaş, 7000 Gün";
        details["Yaş Haddinden Emeklilik"] =
        "Mevcut: $age Yaş, $primGun Gün, $insuranceYears Yıl | Gerekli: 60 Yaş, 4500 Gün, 25 Yıl";
      } else {
        reqInsuranceYearsNormal = 0;
        reqPrimNormal = 7000;
        reqAgeNormal = 58;

        reqInsuranceYearsYas = 25;
        reqPrimYas = 4500;
        reqAgeYas = 58;

        normalEligible = (primGun >= 7000 && age >= 58);
        ageLimitEligible = (primGun >= 4500 && age >= 58 && insuranceYears >= 25);

        details["Normal Emeklilik"] =
        "Mevcut: $age Yaş, $primGun Gün | Gerekli: 58 Yaş, 7000 Gün";
        details["Yaş Haddinden Emeklilik"] =
        "Mevcut: $age Yaş, $primGun Gün, $insuranceYears Yıl | Gerekli: 58 Yaş, 4500 Gün, 25 Yıl";
      }
    } else if (sigortaBaslangic.isAfter(cat3Lower.subtract(const Duration(days: 1)))) {
      final int normalReqPrim = 7200;
      reqPrimNormal = normalReqPrim;

      int eksikPrimGunu = normalReqPrim - primGun;
      int eksikTamYil = eksikPrimGunu ~/ 360;
      int eksikGunKalan = eksikPrimGunu % 360;
      DateTime araTarih = DateTime(DateTime.now().year + eksikTamYil, DateTime.now().month, DateTime.now().day);
      DateTime primCompletion = araTarih.add(Duration(days: eksikGunKalan));

      if (primCompletion.isBefore(DateTime(2036, 1, 1))) {
        reqAgeNormal = (cinsiyet == "Erkek") ? 60 : 58;
      } else if (primCompletion.isBefore(DateTime(2038, 1, 1))) {
        reqAgeNormal = (cinsiyet == "Erkek") ? 61 : 59;
      } else if (primCompletion.isBefore(DateTime(2040, 1, 1))) {
        reqAgeNormal = (cinsiyet == "Erkek") ? 62 : 60;
      } else if (primCompletion.isBefore(DateTime(2042, 1, 1))) {
        reqAgeNormal = (cinsiyet == "Erkek") ? 63 : 61;
      } else if (primCompletion.isBefore(DateTime(2044, 1, 1))) {
        reqAgeNormal = (cinsiyet == "Erkek") ? 64 : 62;
      } else if (primCompletion.isBefore(DateTime(2046, 1, 1))) {
        reqAgeNormal = (cinsiyet == "Erkek") ? 65 : 63;
      } else if (primCompletion.isBefore(DateTime(2048, 1, 1))) {
        reqAgeNormal = (cinsiyet == "Erkek") ? 65 : 64;
      } else {
        reqAgeNormal = 65;
      }

      if (sigortaBaslangic.isBefore(DateTime(2009, 1, 1))) {
        reqPrimYas = 4600;
      } else if (sigortaBaslangic.isBefore(DateTime(2010, 1, 1))) {
        reqPrimYas = 4700;
      } else if (sigortaBaslangic.isBefore(DateTime(2011, 1, 1))) {
        reqPrimYas = 4800;
      } else if (sigortaBaslangic.isBefore(DateTime(2012, 1, 1))) {
        reqPrimYas = 4900;
      } else if (sigortaBaslangic.isBefore(DateTime(2013, 1, 1))) {
        reqPrimYas = 5000;
      } else if (sigortaBaslangic.isBefore(DateTime(2014, 1, 1))) {
        reqPrimYas = 5100;
      } else if (sigortaBaslangic.isBefore(DateTime(2015, 1, 1))) {
        reqPrimYas = 5200;
      } else if (sigortaBaslangic.isBefore(DateTime(2016, 1, 1))) {
        reqPrimYas = 5300;
      } else {
        reqPrimYas = 5400;
      }

      int eksikPrimYas = reqPrimYas - primGun;
      int eksikTamYilYas = eksikPrimYas ~/ 360;
      int eksikGunKalanYas = eksikPrimYas % 360;
      DateTime araTarihYas = DateTime(DateTime.now().year + eksikTamYilYas, DateTime.now().month, DateTime.now().day);
      DateTime ageLimitPrimCompletion = araTarihYas.add(Duration(days: eksikGunKalanYas));

      if (ageLimitPrimCompletion.isBefore(DateTime(2036, 1, 1))) {
        reqAgeYas = (cinsiyet == "Erkek") ? 63 : 61;
      } else if (ageLimitPrimCompletion.isBefore(DateTime(2038, 1, 1))) {
        reqAgeYas = (cinsiyet == "Erkek") ? 64 : 62;
      } else if (ageLimitPrimCompletion.isBefore(DateTime(2040, 1, 1))) {
        reqAgeYas = (cinsiyet == "Erkek") ? 65 : 63;
      } else if (ageLimitPrimCompletion.isBefore(DateTime(2042, 1, 1))) {
        reqAgeYas = (cinsiyet == "Erkek") ? 65 : 64;
      } else {
        reqAgeYas = 65;
      }

      normalEligible = (primGun >= reqPrimNormal && age >= reqAgeNormal);
      ageLimitEligible = (primGun >= reqPrimYas && age >= reqAgeYas);

      details["Normal Emeklilik"] =
      "Mevcut: $primGun Gün, $age Yaş | Gerekli: $reqPrimNormal Gün, $reqAgeNormal Yaş";
      details["Yaş Haddinden Emeklilik"] =
      "Mevcut: $primGun Gün, $age Yaş | Gerekli: $reqPrimYas Gün, $reqAgeYas Yaş";
    } else {
      message = "Sistem uygun emeklilik kriterini belirleyemedi.";
    }

    if (!normalEligible && reqPrimNormal > 0) {
      int eksikPrim = reqPrimNormal - primGun;
      int eksikTamYil = eksikPrim ~/ 360;
      int eksikGunKalan = eksikPrim % 360;
      DateTime araTarih = DateTime(DateTime.now().year + eksikTamYil, DateTime.now().month, DateTime.now().day);
      DateTime primDolma = araTarih.add(Duration(days: eksikGunKalan));

      int olasiYas = primDolma.year - dogumTarihi.year;
      if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day).isAfter(primDolma)) {
        olasiYas--;
      }

      if (reqAgeNormal > 0 && olasiYas < reqAgeNormal) {
        primDolma = DateTime(dogumTarihi.year + reqAgeNormal, dogumTarihi.month, dogumTarihi.day);
        olasiYas = reqAgeNormal;
      }

      tahminiSonuclar["Normal Emeklilik"] = {
        "tahminiTarih": primDolma,
        "tahminiYas": olasiYas,
        "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
        "eksikYil": eksikPrim > 0 ? eksikPrim / 360 : 0.0,
        "mesaj":
        "Hesaplama Tarihi İtibarıyla Sigorta Bildirimleriniz Kesintisiz Devam Ederse, ${_formatDateDot(primDolma)} Tarihinde Normal Emeklilik Hakkı Kazanabilirsiniz."
      };
    }

    if (!ageLimitEligible && reqPrimYas > 0) {
      final int eksikPrim = reqPrimYas - primGun;
      final int eksikTamYilYas = eksikPrim ~/ 360;
      final int eksikGunKalanYas = eksikPrim % 360;
      final DateTime araTarihYas = DateTime(
        DateTime.now().year + eksikTamYilYas,
        DateTime.now().month,
        DateTime.now().day,
      );
      DateTime primDolma = araTarihYas.add(Duration(days: eksikGunKalanYas));

      final DateTime yasEsigiTarihi = (reqAgeYas > 0)
          ? DateTime(dogumTarihi.year + reqAgeYas, dogumTarihi.month, dogumTarihi.day)
          : primDolma;

      DateTime emeklilikTarihi =
      primDolma.isAfter(yasEsigiTarihi) ? primDolma : yasEsigiTarihi;

      int olasiYas = emeklilikTarihi.year - dogumTarihi.year;
      if (DateTime(emeklilikTarihi.year, dogumTarihi.month, dogumTarihi.day).isAfter(emeklilikTarihi)) {
        olasiYas--;
      }

      tahminiSonuclar["Yaş Haddinden Emeklilik"] = {
        "tahminiTarih": emeklilikTarihi,
        "tahminiYas": olasiYas,
        "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
        "eksikYil": eksikPrim > 0 ? eksikPrim / 360 : 0.0,
        "mesaj":
        "Hesaplama Tarihi İtibarıyla Sigorta Bildirimleriniz Kesintisiz Devam Ederse, ${_formatDateDot(emeklilikTarihi)} Tarihinde Yaş Haddinden Emeklilik Hakkı Kazanabilirsiniz."
      };
    }

    return {
      'emekliMi': {'normal': normalEligible, 'yasHaddi': ageLimitEligible},
      'mesaj': {'birlesik': message},
      'detaylar': {'birlesik': details},
      'tahminiSonuclar': tahminiSonuclar,
      'ekBilgi': {'Kontrol Tarihi': _formatDateSlash(DateTime.now())},
    };
  }

  void _hesaplaEmeklilik() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _showResultBottomSheet();
    } else {
      showCenterNotice(
        context,
        title: 'Eksik Alanlar',
        message: 'Eksik ya da hatalı alanları kontrol edin.',
        type: AppNoticeType.info,
      );
    }
  }

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
      showCenterNotice(
        context,
        title: 'Uyarı',
        message: kMsgFillAllFieldsSnack,
        type: AppNoticeType.error,
      );
      return;
    }

    DateTime today = DateTime.now();
    String? errorMessage;
    if (dogumTarihi!.isAfter(today)) {
      errorMessage = _cap("doğum tarihi günümüzden sonra olamaz.");
    } else if (sigortaBaslangicTarihi!.isBefore(dogumTarihi!)) {
      errorMessage = _cap("sigorta başlangıç tarihi doğum tarihinden önce olamaz.");
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
      showCenterNotice(
        context,
        title: 'Hatalı Veri',
        message: errorMessage,
        type: AppNoticeType.error,
      );
      return;
    }

    setState(() {
      hesaplamaSonucu = emeklilikHesapla(
        dogumTarihi!, cinsiyet!, sigortaBaslangicTarihi!, primGunSayisi!,
      );
    });

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
    } catch (_) {}

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
        hesaplamaTuru: '4/a (SSK) Emeklilik Hesaplama',
        tarihSaat: DateTime.now(),
        veriler: veriler,
        sonuclar: sonuclar,
        ozet: _buildHistorySummary(hesaplamaSonucu!),
      );
      
      await SonHesaplamalarDeposu.ekle(sonHesaplama);
    } catch (e) {
      debugPrint('Son hesaplama kaydedilirken hata: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kResultSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kResultSheetCorner)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.96,
        child: FinancialReportSheet(
          sonuc: hesaplamaSonucu!,
          hesaplamaTuru: '4/a (SSK)',
          sigortaBaslangicTarihi: sigortaBaslangicTarihi,
        ),
      ),
    );
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '4/a (SSK) Emeklilik Hesaplama',
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPageHPad, vertical: 16),
            child: Form(
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
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hesaplaEmeklilik,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      child: Text('Hesapla', style: TextStyle(fontSize: 20 * kTextScale)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildEkBilgiArea(),
                ],
              ),
            ),
          ),
        ),
      ),
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
          color: (hasError && cinsiyet == null) ? errorColor : Colors.black87,
          fontWeight: (cinsiyet == option) ? FontWeight.w400 : FontWeight.w300,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cinsiyetiniz', style: context.sFormLabel),
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kFieldBorderRadius),
                    side: BorderSide(
                      color: hasError ? errorColor : Colors.transparent,
                      width: hasError ? (kFieldBorderWidth + 0.2) : 0.0,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: cinsiyet,
                    backgroundColor: Colors.indigo.withOpacity(0.06),
                    thumbColor: Colors.white,
                    children: {
                      'Erkek': Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                        child: Text('Erkek', style: styleFor('Erkek')),
                      ),
                      'Kadın': Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kFieldBorderRadius),
                      borderSide: BorderSide(
                        color: hasError ? Theme.of(context).colorScheme.error : kFieldBorderColor,
                        width: hasError ? kFieldBorderWidth + 0.2 : kFieldBorderWidth,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kFieldBorderRadius),
                      borderSide: BorderSide(
                        color: hasError ? Theme.of(context).colorScheme.error : kFieldBorderColor,
                        width: hasError ? kFieldBorderWidth + 0.2 : kFieldBorderWidth,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kFieldBorderRadius),
                      borderSide: BorderSide(
                        color: hasError ? Theme.of(context).colorScheme.error : kFieldFocusColor,
                        width: kFieldBorderWidth + 0.4,
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
                          ? Colors.black
                          : hasError
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey[700],
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kFieldBorderRadius),
                        borderSide: BorderSide(
                          color: hasError ? Theme.of(context).colorScheme.error : kFieldBorderColor,
                          width: hasError ? kFieldBorderWidth + 0.2 : kFieldBorderWidth,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kFieldBorderRadius),
                        borderSide: BorderSide(
                          color: hasError ? Theme.of(context).colorScheme.error : kFieldBorderColor,
                          width: hasError ? kFieldBorderWidth + 0.2 : kFieldBorderWidth,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kFieldBorderRadius),
                        borderSide: BorderSide(
                          color: hasError ? Theme.of(context).colorScheme.error : kFieldFocusColor,
                          width: kFieldBorderWidth + 0.4,
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
  String _tab = 'Hesaplama Sonucu';

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
    final PieInput pieYas    = FinancialReportPage._toPie(yasHaddi, fallbackLabel: 'Yaş Haddinden Emeklilik');

    String _buildShareText() {
      final b = StringBuffer('Emeklilik Özeti\n');
      detaylar.forEach((k, v) => b.writeln('$k: $v'));
      tahmini.forEach((k, v) {
        if (v is Map && v['mesaj'] != null) b.writeln(v['mesaj']);
      });
      return b.toString().trim();
    }

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kReportMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 48, height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12, borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _tab,
                  backgroundColor: Colors.indigo.withOpacity(0.06),
                  thumbColor: Colors.white,
                  children: {
                    'Hesaplama Sonucu': Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'Hesaplama Sonucu',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 14 * kResultHeaderScale,
                          fontWeight: kResultHeaderWeight,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    'Grafik': Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'Grafik',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 14 * kResultHeaderScale,
                          fontWeight: kResultHeaderWeight,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (v) => setState(() => _tab = v ?? _tab),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _tab == 'Hesaplama Sonucu'
                      ? LayoutBuilder(
                    builder: (context, c) {
                      return _SummaryBullets(
                        emekliMi: emekliMi,
                        normal: normal,
                        yasHaddi: yasHaddi,
                        tahmini: tahmini,
                        detaylarRaw: detaylar,
                      );
                    },
                  )
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      const double perSectionExtras = 84;
                      const double dividerH = 20;
                      double avail = constraints.maxHeight - dividerH - (perSectionExtras * 2);
                      double chartH = (avail / 2).clamp(100, 210);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ModernDonutSection(title: 'Normal Emeklilik', input: pieNormal, chartHeight: chartH),
                          const Divider(color: Colors.black87, thickness: 0.2, height: 20),
                          _ModernDonutSection(title: 'Yaş Haddinden Emeklilik', input: pieYas, chartHeight: chartH),
                        ],
                      );
                    },
                  ),
                ),
              ),

              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Takibe Aktar butonu sadece emeklilik koşulları sağlanmadığında göster
                        if (!(emekliMi['normal'] == true || emekliMi['yasHaddi'] == true))
                          Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                // Her iki emeklilik tipini de kaydet
                                Map<String, dynamic>? normalTahmini;
                                Map<String, dynamic>? yasTahmini;
                                
                                if (tahmini.containsKey('Normal Emeklilik')) {
                                  final normal = tahmini['Normal Emeklilik'] as Map<String, dynamic>?;
                                  if (normal != null && normal['tahminiTarih'] != null) {
                                    normalTahmini = normal;
                                  }
                                }
                                
                                if (tahmini.containsKey('Yaş Haddinden Emeklilik')) {
                                  final yas = tahmini['Yaş Haddinden Emeklilik'] as Map<String, dynamic>?;
                                  if (yas != null && yas['tahminiTarih'] != null) {
                                    yasTahmini = yas;
                                  }
                                }
                                
                                // En erken tarihi ana emeklilik tarihi olarak seç
                                DateTime? emeklilikTarihi;
                                String emeklilikTipi = '';
                                
                                if (normalTahmini != null && yasTahmini != null) {
                                  final normalTarih = normalTahmini['tahminiTarih'] as DateTime;
                                  final yasTarih = yasTahmini['tahminiTarih'] as DateTime;
                                  if (normalTarih.isBefore(yasTarih)) {
                                    emeklilikTarihi = normalTarih;
                                    emeklilikTipi = 'Normal Emeklilik';
                                  } else {
                                    emeklilikTarihi = yasTarih;
                                    emeklilikTipi = 'Yaş Haddinden Emeklilik';
                                  }
                                } else if (normalTahmini != null) {
                                  emeklilikTarihi = normalTahmini['tahminiTarih'] as DateTime;
                                  emeklilikTipi = 'Normal Emeklilik';
                                } else if (yasTahmini != null) {
                                  emeklilikTarihi = yasTahmini['tahminiTarih'] as DateTime;
                                  emeklilikTipi = 'Yaş Haddinden Emeklilik';
                                }
                                
                                if (emeklilikTarihi != null) {
                                  try {
                                    final prefs = await SharedPreferences.getInstance();
                                    
                                    // Normal Emeklilik bilgilerini çıkar
                                    Map<String, dynamic> normalBilgiler = {};
                                    if (normalTahmini != null) {
                                      normalBilgiler = {
                                        'tahminiTarih': (normalTahmini['tahminiTarih'] as DateTime).millisecondsSinceEpoch,
                                        'tahminiYas': normalTahmini['tahminiYas'] as int? ?? 0,
                                        'eksikPrim': normalTahmini['eksikPrim'] as int? ?? 0,
                                        'eksikYil': (normalTahmini['eksikYil'] as num?)?.toDouble() ?? 0.0,
                                      };
                                      
                                      if (detaylar.containsKey('Normal Emeklilik')) {
                                        final detay = detaylar['Normal Emeklilik'] ?? '';
                                        final parts = detay.split('|');
                                        if (parts.length == 2) {
                                          final mevcutPart = parts[0].trim();
                                          final gerekliPart = parts[1].trim();
                                          final mevcutMatch = RegExp(r'Mevcut:\s*(\d+)\s*Gün,\s*(\d+)\s*Yaş').firstMatch(mevcutPart);
                                          final gerekliMatch = RegExp(r'Gerekli:\s*(\d+)\s*Gün,\s*(\d+)\s*Yaş').firstMatch(gerekliPart);
                                          if (mevcutMatch != null) {
                                            normalBilgiler['mevcutPrim'] = mevcutMatch.group(1) ?? '';
                                            normalBilgiler['mevcutYas'] = mevcutMatch.group(2) ?? '';
                                          }
                                          if (gerekliMatch != null) {
                                            normalBilgiler['gerekliPrim'] = gerekliMatch.group(1) ?? '';
                                            normalBilgiler['gerekliYas'] = gerekliMatch.group(2) ?? '';
                                          }
                                        }
                                      }
                                    }
                                    
                                    // Yaş Haddinden Emeklilik bilgilerini çıkar
                                    Map<String, dynamic> yasBilgiler = {};
                                    if (yasTahmini != null) {
                                      yasBilgiler = {
                                        'tahminiTarih': (yasTahmini['tahminiTarih'] as DateTime).millisecondsSinceEpoch,
                                        'tahminiYas': yasTahmini['tahminiYas'] as int? ?? 0,
                                        'eksikPrim': yasTahmini['eksikPrim'] as int? ?? 0,
                                        'eksikYil': (yasTahmini['eksikYil'] as num?)?.toDouble() ?? 0.0,
                                      };
                                      
                                      if (detaylar.containsKey('Yaş Haddinden Emeklilik')) {
                                        final detay = detaylar['Yaş Haddinden Emeklilik'] ?? '';
                                        final parts = detay.split('|');
                                        if (parts.length == 2) {
                                          final mevcutPart = parts[0].trim();
                                          final gerekliPart = parts[1].trim();
                                          final mevcutMatch = RegExp(r'Mevcut:\s*(\d+)\s*Gün,\s*(\d+)\s*Yaş').firstMatch(mevcutPart);
                                          final gerekliMatch = RegExp(r'Gerekli:\s*(\d+)\s*Gün,\s*(\d+)\s*Yaş').firstMatch(gerekliPart);
                                          if (mevcutMatch != null) {
                                            yasBilgiler['mevcutPrim'] = mevcutMatch.group(1) ?? '';
                                            yasBilgiler['mevcutYas'] = mevcutMatch.group(2) ?? '';
                                          }
                                          if (gerekliMatch != null) {
                                            yasBilgiler['gerekliPrim'] = gerekliMatch.group(1) ?? '';
                                            yasBilgiler['gerekliYas'] = gerekliMatch.group(2) ?? '';
                                          }
                                        }
                                      }
                                    }
                                    
                                    final data = {
                                      'emeklilikTarihi': emeklilikTarihi.millisecondsSinceEpoch,
                                      'emeklilikTipi': emeklilikTipi,
                                      'hesaplamaTuru': widget.hesaplamaTuru,
                                      'normalEmeklilik': normalBilgiler,
                                      'yasHaddindenEmeklilik': yasBilgiler,
                                      'sigortaBaslangicTarihi': widget.sigortaBaslangicTarihi?.millisecondsSinceEpoch,
                                      'kayitTarihi': DateTime.now().millisecondsSinceEpoch,
                                    };
                                    await prefs.setString('emeklilik_takip_data', jsonEncode(data));
                                    
                                    if (mounted) {
                                      Navigator.pop(context); // Bottom sheet'i kapat
                                      // Emeklilik takip ekranına yönlendir
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const EmeklilikTakipApp(),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      showCenterNotice(
                                        context,
                                        title: 'Hata',
                                        message: 'Emeklilik tarihi kaydedilemedi.',
                                        type: AppNoticeType.error,
                                      );
                                    }
                                  }
                                } else {
                                  if (mounted) {
                                    showCenterNotice(
                                      context,
                                      title: 'Uyarı',
                                      message: 'Emeklilik tarihi bulunamadı.',
                                      type: AppNoticeType.warning,
                                    );
                                  }
                                }
                              },
                                icon: const Icon(Icons.track_changes, size: 18),
                                label: const Text('Takibe Aktar', style: TextStyle(fontWeight: FontWeight.w400)),
                              ),
                            ),
                          ),
                        if (!(emekliMi['normal'] == true || emekliMi['yasHaddi'] == true))
                          const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final text = _buildShareText();
                        await Clipboard.setData(ClipboardData(text: text));
                        if (mounted) {
                          showCenterNotice(
                            context,
                            title: 'Paylaş',
                            message: 'Özet panoya kopyalandı. Uygulamalarda yapıştırarak paylaşabilirsiniz.',
                            type: AppNoticeType.success,
                          );
                        }
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Paylaş', style: TextStyle(fontWeight: FontWeight.w400)),
                    ),
                  ),
                ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernDonutSection extends StatelessWidget {
  final String title;
  final PieInput input;
  final double? chartHeight;
  const _ModernDonutSection({required this.title, required this.input, this.chartHeight});

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
            color: Colors.black87,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: chartHeight ?? kReportChartHeight,
          width: double.infinity,
          child: DonutChart(
            input: input,
            completed: kRingColorCompleted,
            missing: kRingColorMissing,
            bg: kRingColorBg,
            thickness: kRingThickness,
          ),
        ),

        const SizedBox(height: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LegendSwatch(color: kRingColorCompleted, label: 'Toplam Prim Günü'),
            SizedBox(height: 6),
            _LegendSwatch(color: kRingColorMissing, label: 'Emeklilik İçin Eksik Prim Günü'),
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

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
    final Rect rect = Rect.fromLTWH(pad, pad + 8, size.width - pad * 2, size.height - pad * 2 - 24);
    final Offset center = rect.center;
    final double radius = rect.shortestSide / 2;

    final Paint pBg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = kRingColorBg
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, math.pi * 2, false, pBg);

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

    if (percCompleted > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweepDone, false, pDone);
    }
    if (percMissing > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start + sweepDone, sweepMiss, false, pMiss);
    }

    void drawCallout(double startAngle, double sweepAngle, double percentage, {bool alignRight = true}) {
      if (percentage <= 0) return;

      final mid = startAngle + sweepAngle / 2;

      final double rOuter = radius + 2;
      final Offset p0 = Offset(center.dx + rOuter * math.cos(mid), center.dy + rOuter * math.sin(mid));
      final Offset p1 = Offset(center.dx + (rOuter + kCalloutOutset) * math.cos(mid),
          center.dy + (rOuter + kCalloutOutset) * math.sin(mid));

      final bool right = alignRight ? (math.cos(mid) >= 0) : (math.cos(mid) > 0);
      final double hLen = 22;
      final Offset p2 = p1 + Offset(right ? hLen : -hLen, 0);

      final Paint linePaint = Paint()
        ..color = kCalloutLineColor
        ..strokeWidth = kCalloutLineWidth
        ..style = PaintingStyle.stroke;

      final Path line = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy);
      canvas.drawPath(line, linePaint);

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
      final Paint pBox = Paint()..color = Colors.white;
      final Paint pBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = kCalloutBorder;

      canvas.drawRRect(rr, pBox);
      canvas.drawRRect(rr, pBorder);

      tp.paint(canvas, Offset(box.left + kCalloutPaddingH, box.top + kCalloutPaddingV));
    }

    drawCallout(start, sweepDone, percCompleted, alignRight: true);
    drawCallout(start + sweepDone, sweepMiss, percMissing, alignRight: false);
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
    final style = Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Colors.black87,
      fontWeight: emphasis != null ? FontWeight.w600 : kSumItemWeight,
      fontSize: (Theme.of(context).textTheme.bodySmall!.fontSize ?? 12) * kSumItemFontScale,
    );
    return Padding(
      padding: kSumItemPadding,
      child: Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
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
          _line(context, tahminMesaj),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          )),
          SizedBox(height: kSumSectionTitleGap),
          ..._intersperse(items, SizedBox(height: kSumBetweenItemsGap)),
        ],
      );
    }

    final hairlineIndigoDivider = Divider(
      color: Colors.black87,
      thickness: 0.4 / MediaQuery.of(context).devicePixelRatio,
      height: 14,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('Normal Emeklilik', emekliMi['normal'] == true, normal, reqNormal, 'Normal Emeklilik'),
        hairlineIndigoDivider,
        section('Yaş Haddinden Emeklilik', emekliMi['yasHaddi'] == true, yasHaddi, reqYasHaddi, 'Yaş Haddinden Emeklilik'),
      ],
    );
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
