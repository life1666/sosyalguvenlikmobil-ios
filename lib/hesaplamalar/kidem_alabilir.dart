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
      border = const Color(0xFF22C55E).withOpacity(.0);
      textMain = const Color(0xFF065F46);
      break;
    case AppNoticeType.info:
      bg = const Color(0xFFF1F5FF);
      border = const Color(0xFF3B82F6).withOpacity(.0);
      textMain = const Color(0xFF1E3A8A);
      break;
    case AppNoticeType.warning:
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFF59E0B).withOpacity(.0);
      textMain = const Color(0xFF7C2D12);
      break;
    case AppNoticeType.error:
    default:
      bg = const Color(0xFFFFF3F2);
      border = const Color(0xFFEF4444).withOpacity(.0);
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
String formatDateDDMMYYYY(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');
}

String customTitleCase(String text) {
  return text.split(' ').map((word) {
    if (word.toLowerCase() == 'veya') return 'veya';
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

/// =====================
///  APP
/// =====================
void main() {
  runApp(const KidemTazminatiApp());
}

class KidemTazminatiApp extends StatelessWidget {
  const KidemTazminatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kıdem Tazminatı Kontrol',
      debugShowCheckedModeBanner: false,
      theme: uygulamaTemasi,
      home: const KidemTazminatiScreen(),
    );
  }
}

/// Basit Cupertino alan görünümü (referans ile aynı yaklaşım)
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
///  EKRAN
/// =====================
class KidemTazminatiScreen extends StatefulWidget {
  const KidemTazminatiScreen({super.key});

  @override
  _KidemTazminatiScreenState createState() => _KidemTazminatiScreenState();
}

class _KidemTazminatiScreenState extends State<KidemTazminatiScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('kidem_tazminati_opened');
  }

  // Tarih
  String? _gun;
  String? _ay; // Türkçe ad
  String? _yil;

  DateTime? sigortaBaslangicTarihi;

  // Sayısal alanlar
  final TextEditingController primGunController = TextEditingController();
  final TextEditingController calismaYilController = TextEditingController();

  Map<String, dynamic>? hesaplamaSonucu;
  String? _errorMessage;

  final List<String> aylar = const [
    'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
  ];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  @override
  void dispose() {
    primGunController.dispose();
    calismaYilController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ---------- Cupertino Triple Date Picker ----------
  Future<Map<String, String>?> _showCupertinoDateTriplePicker({
    required String? gun,
    required String? ay,
    required String? yil,
  }) async {
    final days = [for (int i = 1; i <= 31; i++) '$i'];
    final months = aylar;
    final years = [for (int y = DateTime.now().year; y >= 1980; y--) '$y'];

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

  /// ---------- Hesaplama Mantığı (intl/ads yok) ----------
  Map<String, dynamic> kidemTazminatiHesapla(DateTime baslangic, int primGun, int calismaYil) {
    final int gunFarki = DateTime.now().difference(baslangic).inDays;
    final int yilFarki = gunFarki ~/ 365;

    if (gunFarki < primGun) {
      return {
        'hakKazandi': false,
        'mesaj':
        'Hesaplama hatası: Başlangıç tarihi ile güncel tarih arasındaki gün farkı, girilen prim gün sayısından az.',
        'detaylar': {},
        'ekBilgi': {'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now())},
      };
    }

    // Ortak alanlar: ekran çıktısında sadece şu 5 satır gösterilecek
    int gerekenPrim = 0;
    int eksikPrim = 0;
    const int gerekenCalismaYilMin = 1; // Son iş yerinde asgari süre
    int eksikCalismaYil = (calismaYil >= gerekenCalismaYilMin) ? 0 : (gerekenCalismaYilMin - calismaYil);

    bool kosullarSaglandi = false;
    String finalMsg = '';

    // ---- Rejimlere göre gereklilikler ----
    if (baslangic.isBefore(DateTime(1999, 9, 8))) {
      // 15 yıl sigortalılık + 3600 prim + son işyerinde 1 yıl
      final bool sigortalilikOK = (yilFarki >= 15);
      gerekenPrim = 3600;
      eksikPrim = (primGun >= gerekenPrim) ? 0 : (gerekenPrim - primGun);

      kosullarSaglandi = sigortalilikOK && eksikPrim == 0 && eksikCalismaYil == 0;
      finalMsg = kosullarSaglandi
          ? 'Kıdem tazminatı almaya bu koşullarda hak kazanıyorsunuz.'
          : 'Kıdem tazminatı almaya bu koşullarda hak kazanamıyorsunuz.';
    } else if (baslangic.isAfter(DateTime(1999, 9, 7)) &&
        baslangic.isBefore(DateTime(2008, 5, 1))) {
      // 25 yıl + (4500 prim + 25 yıl) veya 7000 prim + son işyerinde 1 yıl
      final bool sigortalilikOK = (yilFarki >= 25);
      final bool prim4500OK = primGun >= 4500;
      final bool prim7000OK = primGun >= 7000;

      // Ekranda tek “Gereken Prim Gün Sayısı” göstereceğiz: Asgari bariyeri mantıklı seçelim.
      // Eğer 7000 sağlanıyorsa gerekenPrim=7000, değilse 4500’e göre eksik gösterelim.
      if (prim7000OK) {
        gerekenPrim = 7000;
        eksikPrim = 0;
      } else {
        gerekenPrim = 4500;
        eksikPrim = (primGun >= gerekenPrim) ? 0 : (gerekenPrim - primGun);
      }

      kosullarSaglandi = ((prim4500OK && sigortalilikOK) || prim7000OK) && eksikCalismaYil == 0;
      finalMsg = kosullarSaglandi
          ? 'Kıdem tazminatı almaya bu koşullarda hak kazanıyorsunuz.'
          : 'Kıdem tazminatı almaya bu koşullarda hak kazanamıyorsunuz.';
    } else {
      // 01.05.2008 sonrası: kademeli prim (>=5400’e kadar) + son iş yerinde 1 yıl
      final int year = baslangic.year;
      if (year < 2009) {
        gerekenPrim = 4600;
      } else if (year < 2010) {
        gerekenPrim = 4700;
      } else if (year < 2011) {
        gerekenPrim = 4800;
      } else if (year < 2012) {
        gerekenPrim = 4900;
      } else if (year < 2013) {
        gerekenPrim = 5000;
      } else if (year < 2014) {
        gerekenPrim = 5100;
      } else if (year < 2015) {
        gerekenPrim = 5200;
      } else if (year < 2016) {
        gerekenPrim = 5300;
      } else {
        gerekenPrim = 5400;
      }
      eksikPrim = (primGun >= gerekenPrim) ? 0 : (gerekenPrim - primGun);

      kosullarSaglandi = eksikPrim == 0 && eksikCalismaYil == 0;
      finalMsg = kosullarSaglandi
          ? 'Kıdem tazminatı almaya bu koşullarda hak kazanıyorsunuz.'
          : 'Kıdem tazminatı almaya bu koşullarda hak kazanamıyorsunuz.';
    }

    // SONUÇ EKRANI — yalnızca istenen beş satır
    final Map<String, String> detayMap = {
      'Prim Gün Sayınız': '$primGun gün',
      'Gereken Prim Gün Sayısı': '$gerekenPrim gün',
      'Eksik Gün Sayısı': '${eksikPrim < 0 ? 0 : eksikPrim} gün',
      'Son İş Yerindeki Çalışma Süreniz': '$calismaYil yıl',
      'Gereken Minimum Süre': '$gerekenCalismaYilMin yıl',
    };

    return {
      'hakKazandi': kosullarSaglandi,
      'mesaj': toTitleCase(finalMsg),
      'detaylar': detayMap,
      'ekBilgi': {
        'Kontrol Tarihi': formatDateDDMMYYYY(DateTime.now()),
        'Not': kosullarSaglandi
            ? toTitleCase('Kıdem tazminatına esas yazı için SGK’ya başvurabilirsiniz.')
            : customTitleCase(
            'Belirtilen eksik şart veya şartların tamamlanması halinde kıdem tazminatı almaya hak kazanabilirsiniz.'),
      },
    };
  }

  Future<void> _kontrolEt() async {
    // Alan kontrolleri
    if (_gun == null || _ay == null || _yil == null) {
      showCenterNotice(context,
          title: 'Uyarı',
          message: 'Lütfen sigorta başlangıç tarihini seçiniz!',
          type: AppNoticeType.warning);
      return;
    }

    sigortaBaslangicTarihi = DateTime(int.parse(_yil!), aylar.indexOf(_ay!) + 1, int.parse(_gun!));

    final primGun = int.tryParse(primGunController.text.trim()) ?? 0;
    final calismaYil = int.tryParse(calismaYilController.text.trim()) ?? 0;

    if (primGun <= 0) {
      showCenterNotice(context,
          title: 'Uyarı',
          message: 'Prim gün sayısı sıfır veya negatif olamaz!',
          type: AppNoticeType.warning);
      return;
    }
    if (calismaYil <= 0) {
      showCenterNotice(context,
          title: 'Uyarı',
          message: 'Son iş yerinde çalışma yılı sıfır veya negatif olamaz!',
          type: AppNoticeType.warning);
      return;
    }
    if (sigortaBaslangicTarihi!.isAfter(DateTime.now())) {
      showCenterNotice(context,
          title: 'Uyarı',
          message: 'Sigorta başlangıç tarihi gelecekte olamaz!',
          type: AppNoticeType.warning);
      return;
    }

    setState(() {
      hesaplamaSonucu =
          kidemTazminatiHesapla(sigortaBaslangicTarihi!, primGun, calismaYil);
      _errorMessage = hesaplamaSonucu!['mesaj'];
    });

    await _openResultSheet();
  }

  Future<void> _openResultSheet() async {
    final detaylar = Map<String, String>.from(hesaplamaSonucu?['detaylar'] ?? {});
    final durumText = (hesaplamaSonucu?['mesaj'] as String?) ?? 'Sonuç';
    
    // Son hesaplamalara kaydet
    if (hesaplamaSonucu != null && sigortaBaslangicTarihi != null) {
      try {
        final veriler = <String, dynamic>{
          'sigortaBaslangicTarihi': sigortaBaslangicTarihi!.toIso8601String(),
          'primGunSayisi': int.tryParse(primGunController.text.trim()) ?? 0,
          'calismaYili': int.tryParse(calismaYilController.text.trim()) ?? 0,
        };
        
        final sonHesaplama = SonHesaplama(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          hesaplamaTuru: 'SGK\'dan Kıdem Tazminatı Alabilir Yazısı Sorgulama',
          tarihSaat: DateTime.now(),
          veriler: veriler,
          sonuclar: detaylar,
          ozet: durumText,
        );
        
        await SonHesaplamalarDeposu.ekle(sonHesaplama);
        
        // Firebase Analytics: Hesaplama tamamlandı
        AnalyticsHelper.logCalculation('kidem_tazminati_alabilir', parameters: {
          'hesaplama_turu': 'Kıdem Tazminatı Alabilir Yazısı',
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
          statusDescription: toTitleCase(durumText),
        ),
      ),
    );
  }

  /// ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Referans app bar görünümü
      appBar: AppBar(
        title: const Text(
          'Kıdem Tazminatı Kontrol',
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
                  // Tarih (Cupertino triple)
                  _CupertinoField(
                    label: 'Sigorta Başlangıç Tarihi',
                    valueText: _composeDateText(_gun, _ay, _yil),
                    onTap: () async {
                      final sel = await _showCupertinoDateTriplePicker(gun: _gun, ay: _ay, yil: _yil);
                      if (sel != null) {
                        setState(() {
                          _gun = sel['gun'];
                          _ay = sel['ay'];
                          _yil = sel['yil'];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Prim Gün Sayısı
                  _NumberRow(
                    label: 'Prim Gün Sayısı',
                    controller: primGunController,
                    hint: 'Örn. 3600',
                  ),
                  const SizedBox(height: 8),

                  // Son İş Yerinde Çalışma Yılı
                  _NumberRow(
                    label: 'Son İş Yerinde Çalışma Yılı',
                    controller: calismaYilController,
                    hint: 'Örn. 1',
                  ),
                  const SizedBox(height: 12),

                  // Kontrol Et Butonu
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await Future.delayed(const Duration(milliseconds: 10));
                        await _kontrolEt();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text('Kontrol Et', style: TextStyle(fontSize: 17 * kTextScale)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            // Alt bilgi
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

/// Tek satır sayısal alan bileşeni (referans stilde)
class _NumberRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _NumberRow({
    required this.label,
    required this.controller,
    required this.hint,
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
        // BAŞLIK STİLİ GÜNCELLENDİ: Sigorta Başlangıç Tarihi ile aynı
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
          style: const TextStyle(color: Colors.black, fontWeight: AppW.body),
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

/// ================= SONUÇ SHEET (KIDEM TAZMİNATI GÖRÜNÜMÜNE BENZER) =================
class ResultSheet extends StatelessWidget {
  final String title; // başlık sabit
  final Map<String, String> detaylar;
  final String statusDescription; // sonda gösterilecek durum açıklaması

  const ResultSheet({
    super.key,
    required this.title,
    required this.detaylar,
    required this.statusDescription,
  });

  String _buildShareText() {
    final b = StringBuffer('Hesaplama Sonucu\n');
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
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Durum Açıklaması', style: lineStyle.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(statusDescription, style: lineStyle),
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