import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../sonhesaplama/sonhesaplama.dart';
import '../utils/analytics_helper.dart';

/// =================== GLOBAL STIL & KNOB’LAR ===================

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
// Başlıklar ince (hiçbiri kalın değil)
const FontWeight kResultHeaderWeight = FontWeight.w400;

const Color kReportGood           = Color(0xFF16A34A);
const Color kReportWarn           = Color(0xFFDC2626);

/// ===== YAZILI ÖZET MADDE (BULLET) KNOB’LARI =====
const double     kSumSectionTitleGap   = 8.0;
const double     kSumBetweenItemsGap   = 8.0;
const EdgeInsets kSumItemPadding       = EdgeInsets.symmetric(vertical: 4, horizontal: 0);
const FontWeight kSumItemWeight        = FontWeight.w400;
const double     kSumItemFontScale     = 1.10; // sonuç ekranını biraz büyük göster
const Color      kSumOkColor           = kReportGood;
const Color      kSumWarnColor         = kReportWarn;

class AppW {
  static const appBarTitle = FontWeight.w700;
  static const heading     = FontWeight.w500;
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
ThemeData get uygulamaTemasi {
  // ===== KNOB AÇIKLAMALARI =====
  // sizeTitleLg: Form başlıkları (İnşaat Başlangıç Tarihi, Sınıf, Grup, vb.) için punto
  //              16.5 değerini değiştirerek form başlık puntolarını kontrol edebilirsiniz
  final double sizeTitleLg = 16.5 * kTextScale;
  
  // sizeTitleMd: Orta boy başlıklar için punto (context.sEmphasis() ile kullanılır)
  final double sizeTitleMd = 15 * kTextScale;
  
  // sizeBody: Normal metin içeriği için punto (context.sBody ile kullanılır)
  final double sizeBody    = 13.5 * kTextScale;
  
  // sizeSmall: Küçük metinler için punto (context.sMinor ile kullanılır)
  final double sizeSmall   = 12.5 * kTextScale;
  
  // sizeAppBar: AppBar başlık puntoları için
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
      isDense: true, // daha kompakt
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
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth), // ince kırmızı
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth + 0.2),
      ),
      hintStyle: TextStyle(fontSize: 13 * kTextScale, color: Colors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

/// ========== CENTER NOTICE ==========
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

/// ======================
///  TARIFE YILI – MODEL & FONKSİYON
/// ======================

class TarifeYiliSonucu {
  final int tarifeYili;                // Birim maliyet tarifesi için baz yıl
  final int sinifGrupReferansYili;     // Sınıf/grup referansı (başlangıç yılı)
  final bool ozelDurum;
  final String aciklama;
  const TarifeYiliSonucu({
    required this.tarifeYili,
    required this.sinifGrupReferansYili,
    required this.ozelDurum,
    required this.aciklama,
  });
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
final DateTime _ozelEsik = DateTime(2004, 5, 1);
final DateTime _may1_2004 = DateTime(2004, 5, 1);

TarifeYiliSonucu hesaplaTarifeYili({
  required DateTime baslangicTarihi,
  required DateTime bitisTarihi,
  bool yapiSinifiGrubuDegistiMi = false, // UI'da yok; varsayılan false
}) {
  final b = _dateOnly(baslangicTarihi);
  final e = _dateOnly(bitisTarihi);

  if (e.isBefore(b)) {
    throw ArgumentError('bitisTarihi, baslangicTarihi\'nden önce olamaz.');
  }

  // Sınıf/grup referansı her zaman başlangıç yılı
  final int sinifGrupReferansYili = b.year;
  final bool ozelDurum = (b.year <= 2003) && e.isAfter(_ozelEsik);

  int tarifeYili;
  String kuralNotu;

  if (b.year == e.year) {
    // Aynı yıl içinde bitmişse: o yılın tarifesi
    final bool kenar2004 =
        (b.year == 2004) && b.isBefore(_may1_2004) && e.isAfter(_may1_2004);
    if (kenar2004) {
      tarifeYili = 2003;
      kuralNotu =
      '2004 içinde 01.05 eşiğini aşan işler için kenar kuralı: tarife yılı 2003.';
    } else {
      tarifeYili = b.year;
      kuralNotu = 'Başlangıç ve bitiş aynı yıl: tarife yılı $tarifeYili.';
    }
  } else {
    // Birden fazla yılı kapsıyorsa: BİTİŞ YILININ BİR ÖNCESİ
    tarifeYili = e.year - 1; // Örn: 2020..2025 => 2024
    kuralNotu =
    'Başlangıç ve bitiş farklı yıl: bitiş yılının bir öncesi ($tarifeYili) baz alınır.';
  }

  final parts = <String>[
    kuralNotu,
    'Sınıf/grup, başlangıç yılına ($sinifGrupReferansYili) göre seçilir.',
  ];
  if (ozelDurum) {
    parts.add('2003 ve öncesi başlangıç + 01.05.2004 sonrası bitiş: özel yöntem notu eklendi.');
  }

  return TarifeYiliSonucu(
    tarifeYili: tarifeYili,
    sinifGrupReferansYili: sinifGrupReferansYili,
    ozelDurum: ozelDurum,
    aciklama: parts.join(' '),
  );
}

/// ======================
///  UYGULAMA GİRİŞ NOKTASI
/// ======================
void main() {
  runApp(MyApp()); // const kaldırıldı - hot reload için gerekli
}

class MyApp extends StatelessWidget {
  MyApp({super.key}); // const kaldırıldı - hot reload için gerekli
  
  @override
  Widget build(BuildContext context) {
    // Theme'i her build'de yeniden oluştur (hot reload için)
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asgari İşçilik Hesaplama',
      theme: uygulamaTemasi, // getter her çağrıldığında yeni ThemeData oluşturur
      home: HesaplamaSayfasi(), // const kaldırıldı - hot reload için gerekli
    );
  }
}

class HesaplamaSayfasi extends StatefulWidget {
  const HesaplamaSayfasi({super.key});
  @override
  _HesaplamaSayfasiState createState() => _HesaplamaSayfasiState();
}

class _HesaplamaSayfasiState extends State<HesaplamaSayfasi> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('asgari_iscilik_opened');
  }

  // ==== HESAPLAMA MANTIĞI – ENTEGRE ====
  DateTime? baslangicTarihi;
  DateTime? bitisTarihi;

  String? secilenSinif;
  String? secilenGrup;
  String? secilenInsTuru;
  final TextEditingController alanController = TextEditingController();

  // ---- Alan doğrulama hata metinleri ----
  final Map<String, String?> _errors = {
    'baslangic': null,
    'bitis': null,
    'sinif': null,
    'grup': null,
    'tur': null,
    'alan': null,
    'tarife': null, // tarife yılı destek dışı ise üst seviye hata
  };

  // 2024 Birim Maliyetler (TL/m²)
  final Map<String, Map<String, double>> birimMaliyetler2024 = {
    'I': {'A': 1450.0, 'B': 2100.0},
    'II': {'A': 3500.0, 'B': 5250.0, 'C': 7750.0},
    'III': {'A': 12250.0, 'B': 14400.0},
    'IV': {'A': 15300.0, 'B': 17400.0, 'C': 18700.0},
    'V': {'A': 21300.0, 'B': 22250.0, 'C': 24300.0, 'D': 26800.0},
  };

  // 2025 Birim Maliyetler (TL/m²)
  final Map<String, Map<String, double>> birimMaliyetler2025 = {
    'I': {'A': 2100.0, 'B': 3050.0, 'C': 3300.0, 'D': 3900.0},
    'II': {'A': 6600.0, 'B': 10200.0, 'C': 12400.0},
    'III': {'A': 17100.0, 'B': 18200.0, 'C': 19150.0},
    'IV': {'A': 21500.0, 'B': 27500.0, 'C': 32600.0},
    'V': {'A': 34400.0, 'B': 35600.0, 'C': 39500.0, 'D': 43400.0, 'E': 86250.0},
  };

  @override
  void dispose() {
    alanController.dispose();
    super.dispose();
  }

  // ——— Türkçe tarihler
  static const List<String> _ayAdlariTR = [
    'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
    'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
  ];

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Seçiniz';
    final day = d.day.toString().padLeft(2, '0');
    final mon = d.month.toString().padLeft(2, '0');
    return '$day.$mon.${d.year}';
  }

  int _daysInMonth(int year, int month) {
    if (month == 12) return DateTime(year + 1, 1, 1).subtract(const Duration(days: 1)).day;
    return DateTime(year, month + 1, 1).subtract(const Duration(days: 1)).day;
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
                        Expanded( // Gün
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: dayCtrl,
                            onSelectedItemChanged: (i) => d = i + 1,
                            children: List.generate(
                              maxD, (i) => Center(child: Text('${(i + 1).toString().padLeft(2, '0')}')),
                            ),
                          ),
                        ),
                        Expanded( // Ay (TR)
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: monthCtrl,
                            onSelectedItemChanged: (i) {
                              setModalState(() {
                                m = i + 1;
                              });
                            },
                            children: _ayAdlariTR.map((e) => Center(child: Text(e))).toList(),
                          ),
                        ),
                        Expanded( // Yıl
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: yearCtrl,
                            onSelectedItemChanged: (i) {
                              setModalState(() {
                                y = minYear + i;
                              });
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

  /// Yalnız 2024 ve 2025 desteklenir; diğer yıllar için StateError fırlatır
  Map<String, Map<String, double>> _mapForYear(int y) {
    if (y == 2024) return birimMaliyetler2024;
    if (y >= 2025) return birimMaliyetler2025; // 2025 ve sonrası için şimdilik 2025 tablosu kullanılıyor
    throw StateError('Desteklenmeyen tarife yılı: $y');
  }

  double getAsgariIscilikOrani() {
    switch (secilenInsTuru) {
      case 'Yığma (Kargir) İnşaat':
        return 0.12;
      case 'Karkas İnşaat':
        return 0.09;
      case 'Bina İnşaatı':
        return 0.13;
      case 'Prefabrik':
        return 0.08;
      default:
        return 0.0;
    }
  }

  double getUygulanabilirAsgariIscilikOrani() {
    switch (secilenInsTuru) {
      case 'Yığma (Kargir) İnşaat':
        return 0.09;
      case 'Karkas İnşaat':
        return 0.0675;
      case 'Bina İnşaatı':
        return 0.0975;
      case 'Prefabrik':
        return 0.06;
      default:
        return 0.0;
    }
  }

  List<String> getGrupSecenekleri() {
    // Sınıf/grup referansı: her zaman başlangıç yılına göre (değişmedi)
    final refYear = baslangicTarihi?.year ?? 2025;
    final map = (refYear <= 2024) ? birimMaliyetler2024 : birimMaliyetler2025;
    if (secilenSinif == null || !map.containsKey(secilenSinif)) {
      return map['I']!.keys.toList(); // default I sınıfı grupları
    }
    return map[secilenSinif]!.keys.toList();
  }

  double birimMaliyetHesapla() {
    if (secilenSinif != null &&
        secilenGrup != null &&
        baslangicTarihi != null &&
        bitisTarihi != null) {
      final t = hesaplaTarifeYili(
        baslangicTarihi: baslangicTarihi!,
        bitisTarihi: bitisTarihi!,
      );

      // 2023 ve altı desteklenmiyor
      if (t.tarifeYili <= 2023) {
        throw StateError('Desteklenmeyen tarife yılı: ${t.tarifeYili}');
      }

      final currentMap = _mapForYear(t.tarifeYili);
      return currentMap[secilenSinif]?[secilenGrup] ?? 0.0;
    }
    return 0.0;
  }

  double insaatMaliyetiHesapla() {
    double alan = double.tryParse(alanController.text) ?? 0.0;
    if (alan <= 0) return 0.0;
    double birimMaliyet;
    try {
      birimMaliyet = birimMaliyetHesapla();
    } on StateError {
      return 0.0;
    }
    return alan * birimMaliyet;
  }

  double asgariIscilikMatrahiHesapla() {
    final maliyet = insaatMaliyetiHesapla();
    final oran = getUygulanabilirAsgariIscilikOrani();
    return maliyet * oran;
  }

  double odenmesiGerekenPrimHesapla() {
    final matrah = asgariIscilikMatrahiHesapla();
    return matrah * 0.3475;
  }

  // Intl'siz TL format
  String formatSayi(double value) {
    final isNeg = value < 0;
    value = value.abs();
    final intPart = value.floor();
    final frac = ((value - intPart) * 100).round().toString().padLeft(2, '0');
    final s = intPart.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[s.length - 1 - i]);
      if (i % 3 == 2 && i != s.length - 1) buf.write('.');
    }
    final rev = buf.toString().split('').reversed.join();
    return '${isNeg ? '-' : ''}$rev,$frac TL';
  }

  void _clearErrors() {
    _errors.updateAll((key, value) => null);
  }

  bool _validateInputs() {
    _clearErrors();

    bool ok = true;

    if (baslangicTarihi == null) {
      _errors['baslangic'] = 'Lütfen İnşaat Başlangıç Tarihini Seçiniz';
      ok = false;
    }
    if (bitisTarihi == null) {
      _errors['bitis'] = 'Lütfen İnşaat Bitiş Tarihini Seçiniz';
      ok = false;
    }
    if (baslangicTarihi != null && bitisTarihi != null) {
      if (_dateOnly(bitisTarihi!).isBefore(_dateOnly(baslangicTarihi!))) {
        _errors['bitis'] = 'Bitiş tarihi başlangıçtan önce olamaz';
        ok = false;
      } else {
        // Tarife yılı kontrolü (2024-2025 dışında ise hesap yok)
        final t = hesaplaTarifeYili(
          baslangicTarihi: baslangicTarihi!,
          bitisTarihi: bitisTarihi!,
        );
        if (t.tarifeYili <= 2023) {
          _errors['tarife'] =
          'Bu Bilgilerle Hesaplanan Referans Yıl ${t.tarifeYili}. '
              'Uygulamada 2024 ve 2025 Tarifeleriyle Hesap Yapılmaktadır.';
          ok = false;
        }
      }
    }

    if (secilenSinif == null) {
      _errors['sinif'] = 'Lütfen Sınıfı Seçiniz';
      ok = false;
    }
    if (secilenGrup == null) {
      _errors['grup'] = 'Lütfen Grubu Seçiniz';
      ok = false;
    }
    if (secilenInsTuru == null) {
      _errors['tur'] = 'Lütfen İnşaat Türünü Seçiniz';
      ok = false;
    }

    final alan = double.tryParse(alanController.text);
    if (alan == null || alan <= 0) {
      _errors['alan'] = 'Lütfen Metrekare Değerini Giriniz';
      ok = false;
    }

    if (!ok) {
      setState(() {});
      if (_errors['tarife'] != null) {
        showCenterNotice(
          context,
          title: 'Desteklenmeyen Yıl',
          message: _errors['tarife']!,
          type: AppNoticeType.warning,
        );
      }
    }
    return ok;
  }

  Future<void> _hesaplaVeGoster() async {
    if (!_validateInputs()) return;

    // Tarife yılı (hesap için kullanılır; 2024/2025 dışında gelmeyecek)
    final t = hesaplaTarifeYili(
      baslangicTarihi: baslangicTarihi!,
      bitisTarihi: bitisTarihi!,
    );

    // SONUÇLAR
    final double birimMaliyet = birimMaliyetHesapla();
    final double insaatMaliyeti = insaatMaliyetiHesapla();
    final double asgariIscilikMatrahi = asgariIscilikMatrahiHesapla();
    final double odenmesiGerekenPrim = odenmesiGerekenPrimHesapla();

    final sonuc = {
      'basarili': true,
      'detaylar': {
        'Birim Maliyet (${t.tarifeYili})': '${formatSayi(birimMaliyet)}/m²',
        'İnşaat Maliyeti': formatSayi(insaatMaliyeti),
        'Asgari İşçilik Matrahı': formatSayi(asgariIscilikMatrahi),
        'Ödenmesi Gereken Prim': formatSayi(odenmesiGerekenPrim),
      },
      'ham': {
        'birim': birimMaliyet,
        'maliyet': insaatMaliyeti,
        'matrah': asgariIscilikMatrahi,
        'prim': odenmesiGerekenPrim,
      },
      // Ek bilgiler (UI'da Tarife Yılı / Özel Durum / Açıklama gösterilmiyor)
      'ekBilgi': {
        'Asgari İşçilik Oranı': secilenInsTuru == null
            ? 'Seçilmedi'
            : '%${(getAsgariIscilikOrani() * 100).toStringAsFixed(2)} - Uygulanabilir: %${(getUygulanabilirAsgariIscilikOrani() * 100).toStringAsFixed(2)}',
        'Tarife Yılı': '${t.tarifeYili}',
        'Özel Durum': t.ozelDurum ? 'Evet' : 'Hayır',
        'Açıklama': t.aciklama,
      },
    };

    // Son hesaplamalara kaydet
    try {
      final veriler = <String, dynamic>{
        'baslangicTarihi': baslangicTarihi?.toIso8601String(),
        'bitisTarihi': bitisTarihi?.toIso8601String(),
        'sinif': secilenSinif,
        'grup': secilenGrup,
        'insaatTuru': secilenInsTuru,
        'alan': double.tryParse(alanController.text),
        'tarifeYili': t.tarifeYili,
      };
      
      final detaylar = sonuc['detaylar'] as Map<dynamic, dynamic>?;
      final sonHesaplama = SonHesaplama(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hesaplamaTuru: 'Asgari İşçilik Hesaplama',
        tarihSaat: DateTime.now(),
        veriler: veriler,
        sonuclar: detaylar != null 
            ? Map<String, String>.from(detaylar.map((k, v) => MapEntry(k.toString(), v.toString())))
            : <String, String>{},
        ozet: 'Asgari işçilik hesaplaması tamamlandı',
      );
      
      await SonHesaplamalarDeposu.ekle(sonHesaplama);
      
      // Firebase Analytics: Hesaplama tamamlandı
      AnalyticsHelper.logCalculation('asgari_iscilik', parameters: {
        'hesaplama_turu': 'Asgari İşçilik',
      });
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
        child: IscilikReportSheet(sonuc: sonuc),
      ),
    );
  }

  // ---------- Seçiciler ----------
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
                  itemExtent: 30, // kompakt
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

  Future<void> _pickSinif() async {
    final items = const ['I', 'II', 'III', 'IV', 'V'];
    final init = secilenSinif != null ? items.indexOf(secilenSinif!) : 0;
    final secim = await _showCupertinoListPicker(items: items, initialIndex: init < 0 ? 0 : init);
    if (secim != null) {
      setState(() {
        secilenSinif = secim;
        secilenGrup = null;
        _errors['sinif'] = null;
        _errors['grup'] = null;
      });
    }
  }

  Future<void> _pickGrup() async {
    final items = getGrupSecenekleri();
    final init = secilenGrup != null ? items.indexOf(secilenGrup!) : 0;
    final secim = await _showCupertinoListPicker(items: items, initialIndex: init < 0 ? 0 : init);
    if (secim != null) {
      setState(() {
        secilenGrup = secim;
        _errors['grup'] = null;
      });
    }
  }

  Future<void> _pickTur() async {
    final items = const ['Yığma (Kargir) İnşaat', 'Karkas İnşaat', 'Bina İnşaatı', 'Prefabrik'];
    final init = secilenInsTuru != null ? items.indexOf(secilenInsTuru!) : 0;
    final secim = await _showCupertinoListPicker(items: items, initialIndex: init < 0 ? 0 : init);
    if (secim != null) {
      setState(() {
        secilenInsTuru = secim;
        _errors['tur'] = null;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    DateTime init = isStart
        ? (baslangicTarihi ?? DateTime.now())
        : (bitisTarihi ?? baslangicTarihi ?? DateTime.now());
    final result = await _showTurkceDatePicker(initial: init);
    if (result != null) {
      setState(() {
        if (isStart) {
          baslangicTarihi = result;
          secilenGrup = null; // referans yılı değişebilir
          _errors['baslangic'] = null;
          _errors['grup'] = null;
        } else {
          bitisTarihi = result;
          _errors['bitis'] = null;
        }
      });
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // klavye açılınca ekran zıplamasın
      appBar: AppBar(
        title: const Text(
          'Asgari İşçilik Hesaplama',
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
            // Üst form içeriği (scroll edilebilir)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kPageHPad, 12, kPageHPad, 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  if (_errors['tarife'] != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _errors['tarife']!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                  _CupertinoDateField(
                    label: 'İnşaat Başlangıç Tarihi',
                    valueText: _fmtDate(baslangicTarihi),
                    onTap: () => _pickDate(isStart: true),
                    errorText: _errors['baslangic'],
                  ),
                  _CupertinoDateField(
                    label: 'İnşaat Bitiş Tarihi',
                    valueText: _fmtDate(bitisTarihi),
                    onTap: () => _pickDate(isStart: false),
                    errorText: _errors['bitis'],
                  ),
                  _CupertinoSelectField(
                    label: 'Sınıf',
                    valueText: secilenSinif != null ? '${secilenSinif!}. Sınıf' : 'Seçiniz',
                    onTap: _pickSinif,
                    errorText: _errors['sinif'],
                  ),
                  _CupertinoSelectField(
                    label: 'Grup',
                    valueText: secilenGrup != null ? '$secilenGrup Grubu' : 'Seçiniz',
                    onTap: _pickGrup,
                    errorText: _errors['grup'],
                  ),
                  _CupertinoSelectField(
                    label: 'İnşaat Türü',
                    valueText: secilenInsTuru ?? 'Seçiniz',
                    onTap: _pickTur,
                    errorText: _errors['tur'],
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('İnşaat Alanı (m²)', style: context.sFormLabel),
                        const SizedBox(height: 4),
                      TextFormField(
                        controller: alanController,
                        decoration: InputDecoration(
                          hintText: 'm²',
                            hintStyle: context.sBody.copyWith(
                              color: Colors.grey[700],
                              fontWeight: AppW.body,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                              borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                              borderSide: BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.2),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                              borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                              borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth + 0.2),
                            ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          errorText: _errors['alan'],
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (_) {
                          if (_errors['alan'] != null) {
                            setState(() => _errors['alan'] = null);
                          }
                        },
                      ),
                    ],
                    ),
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

            // Alt blok: yer varsa dibine yapışır; yoksa listeyle birlikte kayar
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

class _CupertinoSelectField extends StatelessWidget {
  final String label;
  final String valueText;
  final VoidCallback onTap;
  final String? errorText;
  const _CupertinoSelectField({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.errorText,
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
            onTap: onTap,
            child: InputDecorator(
              decoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.2),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth + 0.2),
                ),
                errorText: errorText, // kırmızı çerçeve + alt yazı
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isPlaceholder ? 'Seçiniz' : valueText,
                      style: context.sBody.copyWith(
                        color: isPlaceholder ? Colors.grey[700] : kTextColor,
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

class _CupertinoDateField extends StatelessWidget {
  final String label;
  final String valueText;
  final VoidCallback onTap;
  final String? errorText;
  const _CupertinoDateField({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.errorText,
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
            onTap: onTap,
            child: InputDecorator(
              decoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.2),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
                  borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth + 0.2),
                ),
                errorText: errorText, // kırmızı çerçeve + alt yazı
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isPlaceholder ? 'Seçiniz' : valueText,
                      style: context.sBody.copyWith(
                        color: isPlaceholder ? Colors.grey[700] : kTextColor,
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

/// =======================================================
/// ================= RAPOR ALT SAYFASI ===================
/// =======================================================

class IscilikReportSheet extends StatelessWidget {
  final Map<String, dynamic> sonuc;
  const IscilikReportSheet({super.key, required this.sonuc});

  String _buildShareText(Map<String, String> detaylar, Map<String, String> ek) {
    final b = StringBuffer('Asgari İşçilik Özeti\n');
    if (ek['Asgari İşçilik Oranı'] != null) {
      b.writeln('Asgari İşçilik Oranı: ${ek['Asgari İşçilik Oranı']}');
    }
    // Tarife Yılı / Özel Durum / Açıklama paylaşım metninden çıkarılmıştı
    if (ek['Sınıf/Grup Referans Yılı'] != null) {
      b.writeln('Sınıf/Grup Referans Yılı: ${ek['Sınıf/Grup Referans Yılı']}');
    }

    detaylar.forEach((k, v) => b.writeln('$k: $v'));
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> detaylar =
    Map<String, String>.from(sonuc['detaylar'] ?? {});
    final Map<String, String> ek =
    Map<String, String>.from(sonuc['ekBilgi'] ?? {});

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

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      children: [
                        // Ek Bilgiler — üstte (Tarife Yılı / Özel Durum / Açıklama gösterilmiyor)
                        if (ek.isNotEmpty) ...[
                          if (ek['Asgari İşçilik Oranı'] != null)
                            Padding(
                              padding: kSumItemPadding,
                              child: Text(
                                'Asgari İşçilik Oranı: ${ek['Asgari İşçilik Oranı']}',
                                style: lineStyle.copyWith(
                                  fontSize: lineStyle.fontSize! * 1.05,
                                ),
                              ),
                            ),
                          if (ek['Sınıf/Grup Referans Yılı'] != null)
                            Padding(
                              padding: kSumItemPadding,
                              child: Text(
                                'Sınıf/Grup Referans Yılı: ${ek['Sınıf/Grup Referans Yılı']}',
                                style: lineStyle,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Divider(color: Colors.black.withOpacity(.35), height: 16),
                          const SizedBox(height: 2),
                        ],

                        // Detaylar
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
                await Clipboard.setData(
                  ClipboardData(text: _buildShareText(detaylar, ek)),
                );
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