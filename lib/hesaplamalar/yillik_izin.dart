import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../sonhesaplama/sonhesaplama.dart';
import '../utils/analytics_helper.dart';

/// =================== GLOBAL STIL & KNOB’LAR (Referans) ===================

const double kPageHPad = 16.0;
const double kTextScale = 1.00;
const Color  kTextColor = Colors.black;

// Divider (global)
const double kDividerThickness = 0.2;
const double kDividerSpace     = 2.0;

// Form alanı çerçevesi
const double kFieldBorderWidth   = 0.2;
const double kFieldBorderRadius  = 10.0;
const Color  kFieldBorderColor   = Colors.black87;
const Color  kFieldFocusColor    = Colors.black87;

// İkon genel
const Color  kIconColor = Colors.black87;
const double kIconSize  = 22.0;

/// ===== RAPOR KNOB’LARI =====
const double kReportMaxWidth      = 660.0;
const Color  kResultSheetBg       = Colors.white;
const double kResultSheetCorner   = 22.0;
const double kResultHeaderScale   = 1.00;
const FontWeight kResultHeaderWeight = FontWeight.w400;

const Color kReportGood           = Color(0xFF16A34A);
const Color kReportWarn           = Color(0xFFDC2626);

/// ===== YAZILI ÖZET MADDE KNOB’LARI =====
const EdgeInsets kSumItemPadding  = EdgeInsets.symmetric(vertical: 4, horizontal: 0);
const double     kSumItemFontScale = 1.10;

class AppW {
  static const appBarTitle = FontWeight.w700;
  static const heading     = FontWeight.w500;
  static const body        = FontWeight.w300;
  static const minor       = FontWeight.w300;
  static const tableHead   = FontWeight.w600;
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
  final double sizeBody    = 13.5 * kTextScale;
  final double sizeSmall   = 12.5 * kTextScale;
  final double sizeAppBar  = 20.5 * kTextScale;

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

    iconTheme: const IconThemeData(
      color: kIconColor,
      size: kIconSize,
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

/// ========== CENTER NOTICE ==========
enum AppNoticeType { error, info, success, warning }

const double     kCenterNoticeRadius     = 16.0;
const double     kCenterNoticeElevation  = 0.0;
const EdgeInsets kCenterNoticePadding    = EdgeInsets.fromLTRB(16, 14, 16, 16);
const Duration   kCenterNoticeAnimDur    = Duration(milliseconds: 220);
const Duration   kCenterNoticeAutoHide   = Duration(seconds: 2);

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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
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
    if (navigator.mounted) {
      navigator.pop();
    }
  }
}

/// ======================
///  YILLIK İZİN – MANTIK AYNI
/// ======================

const List<String> months = [
  'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
  'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
];

String formatDateDDMMYYYY(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

void main() {
  runApp(const YillikUcretliIzinApp());
}

class YillikUcretliIzinApp extends StatelessWidget {
  const YillikUcretliIzinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: uygulamaTemasi,
      home: const YillikUcretliIzinSayfasi(),
    );
  }
}

class YillikUcretliIzinSayfasi extends StatefulWidget {
  const YillikUcretliIzinSayfasi({super.key});

  @override
  State<YillikUcretliIzinSayfasi> createState() => _YillikUcretliIzinSayfasiState();
}

class _YillikUcretliIzinSayfasiState extends State<YillikUcretliIzinSayfasi> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('yillik_izin_opened');
  }

  String? sigortaKolu;
  String? day, month, year;

  // ——— TR Cupertino Tarih Seçici
  static const List<String> _ayAdlariTR = months;

  String _fmtDateLabel() {
    if (day == null || month == null || year == null) return 'Seçiniz';
    final d = day!.padLeft(2, '0');
    final m = (months.indexOf(month!) + 1).toString().padLeft(2, '0');
    return '$d.$m.$year';
  }

  int _daysInMonth(int y, int m) {
    if (m == 12) return DateTime(y + 1, 1, 1).subtract(const Duration(days: 1)).day;
    return DateTime(y, m + 1, 1).subtract(const Duration(days: 1)).day;
  }

  Future<DateTime?> _showTurkceDatePicker({
    required DateTime initial,
    int minYear = 1970,
    int maxYear = 2100,
  }) async {
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (_) {
        int y = initial.year.clamp(minYear, maxYear);
        int m = initial.month;
        int d = initial.day;

        final yearCtrl  = FixedExtentScrollController(initialItem: y - minYear);
        final monthCtrl = FixedExtentScrollController(initialItem: m - 1);
        final dayCtrl   = FixedExtentScrollController(initialItem: d - 1);

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
                      onPressed: () => Navigator.pop(context, DateTime(y, m, d)),
                      child: const Text('Tamam', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    final maxD = _daysInMonth(y, m);
                    if (d > maxD) {
                      d = maxD;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (dayCtrl.selectedItem >= maxD) {
                          dayCtrl.jumpToItem(maxD - 1);
                        }
                      });
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: dayCtrl,
                            onSelectedItemChanged: (i) => d = i + 1,
                            children: List.generate(
                              maxD, (i) => Center(child: Text('${(i + 1).toString().padLeft(2, '0')}')),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: monthCtrl,
                            onSelectedItemChanged: (i) {
                              setModalState(() { m = i + 1; });
                            },
                            children: _ayAdlariTR.map((e) => Center(child: Text(e))).toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: yearCtrl,
                            onSelectedItemChanged: (i) {
                              setModalState(() { y = (minYear + i).toInt(); });
                            },
                            children: List.generate(
                              maxYear - minYear + 1, (i) => Center(child: Text('${minYear + i}')),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ——— Sonuç Sheet'ini aç (mantık aynı, sadece görünüm değişti)
  Future<void> _hesaplaVeGoster() async {
    if (sigortaKolu == null || day == null || month == null || year == null) {
      showCenterNotice(
        context,
        title: 'Eksik Alan',
        message: 'Lütfen tüm seçimleri yapınız.',
        type: AppNoticeType.warning,
      );
      return;
    }

    DateTime iseBaslangic;
    try {
      iseBaslangic = DateTime(
        int.parse(year!),
        months.indexOf(month!) + 1,
        int.parse(day!),
      );
    } catch (_) {
      showCenterNotice(
        context,
        title: 'Tarih Hatası',
        message: 'Geçersiz tarih girdiniz.',
        type: AppNoticeType.error,
      );
      return;
    }

    final bugun = DateTime.now();
    if (iseBaslangic.isAfter(bugun)) {
      showCenterNotice(
        context,
        title: 'Uyarı',
        message: 'İşe başlangıç tarihi gelecekte olamaz.',
        type: AppNoticeType.warning,
      );
      return;
    }

    final fark = bugun.difference(iseBaslangic);
    final yilSayisi = fark.inDays ~/ 365;

    String baslikMesaji; // (UI'da gösterilmeyecek)
    bool isSuccess;
    final Map<String, String> detaylar = {
      'İşe Başlangıç Tarihi':
      '${day!.padLeft(2, '0')}/${(months.indexOf(month!) + 1).toString().padLeft(2, '0')}/$year',
      'Sigorta Kolu': sigortaKolu!,
      'Çalışma Süresi': '$yilSayisi Yıl',
    };

    if (yilSayisi < 1) {
      isSuccess = false;
      baslikMesaji = 'Henüz Yıllık Ücretli İzin Hakkınız Bulunmamaktadır.';
      detaylar['Açıklama'] =
      'Çalışma süreniz 1 yıldan az. Minimum 1 yıl çalışma şartı gerekmektedir.';
    } else {
      isSuccess = true;
      baslikMesaji = 'Yıllık Ücretli İzin Kullanmaya Hak Kazandınız.';
      String izinHakki;
      if (sigortaKolu == '4/C') {
        izinHakki = (yilSayisi <= 10) ? '20 Gün' : '30 Gün';
      } else {
        if (yilSayisi <= 5) {
          izinHakki = '14 Gün';
        } else if (yilSayisi <= 15) {
          izinHakki = '20 Gün';
        } else {
          izinHakki = '26 Gün';
        }
      }
      detaylar['Yıllık Ücretli İzin Hakkı'] = izinHakki;
    }

    final Map<String, String> ekBilgi = {
      'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!': '',
      'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!': '',
      'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!': '',
      'Hesaplama Tarihi': formatDateDDMMYYYY(DateTime.now()),
    };

    // Son hesaplamalara kaydet
    try {
      final veriler = <String, dynamic>{
        'iseBaslangicTarihi': iseBaslangic.toIso8601String(),
        'sigortaKolu': sigortaKolu,
        'yilSayisi': yilSayisi,
      };
      
      final sonHesaplama = SonHesaplama(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hesaplamaTuru: 'Yıllık İzin Süresi Hesaplama',
        tarihSaat: DateTime.now(),
        veriler: veriler,
        sonuclar: detaylar,
        ozet: baslikMesaji,
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
        heightFactor: 0.90,
        child: YillikIzinReportSheet(
          baslikMesaji: baslikMesaji,
          isSuccess: isSuccess,
          detaylar: detaylar,
          ekBilgi: ekBilgi,
        ),
      ),
    );
  }

  Future<void> _pickSigortaKolu() async {
    final items = const ['4/A', '4/C'];
    final init = sigortaKolu != null ? items.indexOf(sigortaKolu!) : 0;
    final secim = await _showCupertinoListPicker(items: items, initialIndex: init < 0 ? 0 : init);
    if (secim != null) setState(() => sigortaKolu = secim);
  }

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
                      onPressed: () => Navigator.pop(context, items.isNotEmpty ? items[selectedIndex] : null),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = (year != null && month != null && day != null)
        ? DateTime(int.parse(year!), months.indexOf(month!) + 1, int.parse(day!))
        : now;

    final picked = await _showTurkceDatePicker(initial: initial);
    if (picked != null) {
      setState(() {
        day = picked.day.toString();
        month = months[picked.month - 1];
        year = picked.year.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yıllık Ücretli İzin Hakkı',
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
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kPageHPad, 12, kPageHPad, 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _CupertinoField(
                    label: 'İşe Başlangıç Tarihi',
                    valueText: _fmtDateLabel(),
                    onTap: _pickDate,
                  ),
                  _CupertinoField(
                    label: 'Sigorta Kolu',
                    valueText: sigortaKolu ?? 'Seçiniz',
                    onTap: _pickSigortaKolu,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async => await _hesaplaVeGoster(),
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
                  const SizedBox(height: 6),
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
}

/// Basit Cupertino tarzı seçim alanı (referans InputDecorator stili)
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
    final bool isPlaceholder = valueText.trim().isEmpty || valueText == 'Seçiniz';
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

/// Bilgilendirme (referans)
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
        ],
      ],
    );
  }
}

/// ================= RAPOR ALT SAYFASI (GÜNCEL: UYARI/KART/EK BILGI YOK) =================

class YillikIzinReportSheet extends StatelessWidget {
  final String baslikMesaji; // (gösterilmeyecek)
  final bool isSuccess;      // (gösterilmeyecek renk vs. için de kullanılmıyor)
  final Map<String, String> detaylar;
  final Map<String, String> ekBilgi; // (tamamen yok sayılacak)

  const YillikIzinReportSheet({
    super.key,
    required this.baslikMesaji,
    required this.isSuccess,
    required this.detaylar,
    required this.ekBilgi,
  });

  String _buildShareText() {
    final b = StringBuffer('Yıllık Ücretli İzin Özeti\n');
    // Durum bilgisini paylaşım metninde tutuyoruz (UI'da gösterilmiyor)
    b.writeln('Durum: ${isSuccess ? "Hak Kazanıldı" : "Henüz Hak Yok"}');
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
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Başlık (ince)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Hesaplama Sonucu',
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

                  // İçerik: kart-sınır yok, direkt sonuç satırları
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      children: [
                        ...detaylar.entries.map(
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

        // Alt orta paylaş
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
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
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Paylaş', style: TextStyle(fontWeight: FontWeight.w400)),
            ),
          ),
        ),
      ],
    );
  }
}