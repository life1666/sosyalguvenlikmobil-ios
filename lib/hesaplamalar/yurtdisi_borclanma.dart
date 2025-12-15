import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

// İkon genel
const Color kIconColor = Colors.black87;
const double kIconSize = 22.0;

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
///  UYGULAMA – MANTIK AYNI (DartPad için: reklam ve intl kaldırıldı)
/// ======================

void main() {
  runApp(const YurtDisiBorclanmaHesaplamaApp());
}

class YurtDisiBorclanmaHesaplamaApp extends StatelessWidget {
  const YurtDisiBorclanmaHesaplamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yurt Dışı Borçlanma Hesaplama',
      theme: uygulamaTemasi,
      home: const YurtDisiBorclanmaHesaplamaScreen(),
    );
  }
}

class YurtDisiBorclanmaHesaplamaScreen extends StatefulWidget {
  const YurtDisiBorclanmaHesaplamaScreen({super.key});

  @override
  _YurtDisiBorclanmaHesaplamaScreenState createState() => _YurtDisiBorclanmaHesaplamaScreenState();
}

class _YurtDisiBorclanmaHesaplamaScreenState extends State<YurtDisiBorclanmaHesaplamaScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('yurtdisi_borclanma_opened');
  }

  final TextEditingController _gunController = TextEditingController();

  // Hesaplama parametreleri (AYNEN KORUNDU)
  final double _asgariAylikGelir = 26005.50;
  final double _ustLimitGelir = 169035.75;
  final double _borclanmaOrani = 0.45;
  final String _borclanmaTuru = 'Yurt Dışı Borçlanma';
  final String _basvuruTarihi = 'Güncel asgari ücret üzerinden hesaplanmaktadır.';

  @override
  void dispose() {
    _gunController.dispose();
    super.dispose();
  }

  // Kelimelerin ilk harfini büyük yap
  String toTitleCase(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word)
        .join(' ');
  }

  // intl olmadan TR benzeri para formatı (binlik nokta, ondalık virgül)
  String formatTL(double n) {
    final neg = n < 0;
    n = n.abs();
    final fixed = n.toStringAsFixed(2); // 2 ondalık
    final parts = fixed.split('.');
    String intPart = parts[0];
    final frac = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buf.write('.');
      }
    }
    final s = '${neg ? '-' : ''}${buf.toString()},$frac TL';
    return s;
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
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buf.write('.');
      }
    }
    return '${neg ? '-' : ''}${buf.toString()},$frac';
  }

  Future<void> _hesapla() async {
    if (_gunController.text.isEmpty) {
      showCenterNotice(
        context,
        title: 'Eksik Alan',
        message: 'Lütfen gün sayısını giriniz.',
        type: AppNoticeType.warning,
      );
      return;
    }

    final int gunSayisi = int.tryParse(_gunController.text) ?? 0;
    if (gunSayisi <= 0) {
      showCenterNotice(
        context,
        title: 'Geçersiz Değer',
        message: 'Gün sayısı pozitif bir tam sayı olmalıdır.',
        type: AppNoticeType.error,
      );
      return;
    }

    // Hesaplama (AYNEN KORUNDU)
    final double gunlukAsgariUcret = _asgariAylikGelir / 30;
    final double altLimitGunlukBedel = gunlukAsgariUcret * _borclanmaOrani;
    final double altLimit = gunSayisi * altLimitGunlukBedel;

    final double gunlukUstLimitGelir = _ustLimitGelir / 30;
    final double ustLimitGunlukBedel = gunlukUstLimitGelir * _borclanmaOrani;
    final double ustLimit = gunSayisi * ustLimitGunlukBedel;

    final Map<String, String> detaylar = {
      'Başvuru Tarih Aralığı': _basvuruTarihi,
      'Borçlanılacak Gün Sayısı': '$gunSayisi gün',
      'Borçlanma Alt Limiti': '${formatTL(altLimit)} (Beyan Edilen Aylık Gelir ${formatPlain(_asgariAylikGelir)} TL)',
      'Borçlanma Üst Limiti': '${formatTL(ustLimit)} (Beyan Edilen Aylık Gelir ${formatPlain(_ustLimitGelir)} TL)',
      'Bilgi Notu':
      'Güncel olarak $gunSayisi gün $_borclanmaTuru için en az ${formatTL(altLimit)}, en çok ${formatTL(ustLimit)} prim ödeyebilirsiniz.',
    };

    // Son hesaplamalara kaydet
    try {
      final veriler = <String, dynamic>{
        'borclanmaTuru': _borclanmaTuru,
        'gunSayisi': gunSayisi,
      };
      
      final sonHesaplama = SonHesaplama(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hesaplamaTuru: 'Yurt Dışı Borçlanma Prim Tutarı Hesaplama',
        tarihSaat: DateTime.now(),
        veriler: veriler,
        sonuclar: detaylar,
        ozet: 'Borçlanma hesaplaması tamamlandı',
      );
      
      await SonHesaplamalarDeposu.ekle(sonHesaplama);
    } catch (e) {
      debugPrint('Son hesaplama kaydedilirken hata: $e');
    }

    // DartPad: reklam yok → direkt sonuç sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kResultSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kResultSheetCorner)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: BorclanmaReportSheet(detaylar: detaylar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yurt Dışı Borçlanma Hesaplama',
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

      // Gövde: referans sayfa düzeni
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kPageHPad, 12, kPageHPad, 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  // Başvuru tarih aralığı etiketi
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hesaplama Tutarı', style: context.sFormLabel),
                        const SizedBox(height: 4),
                        InputDecorator(
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
                          child: Text(
                            _basvuruTarihi,
                            style: const TextStyle(
                              fontWeight: AppW.body,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gün sayısı alanı (referans InputDecorator stili)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Borçlanılacak Gün Sayısı', style: context.sFormLabel),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _gunController,
                          decoration: const InputDecoration(
                            hintText: 'Gün sayısını giriniz (ör. 360)',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
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
                  ),
                  const SizedBox(height: 6),
                ]),
              ),
            ),

            // Alt bilgi (referans)
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

/// ================= RAPOR ALT SAYFASI (REFERANS GÖRÜNÜM) =================

class BorclanmaReportSheet extends StatelessWidget {
  final Map<String, String> detaylar;
  const BorclanmaReportSheet({super.key, required this.detaylar});

  String _buildShareText() {
    final b = StringBuffer('Borçlanma Hesaplama Özeti\n');
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

                  // İçerik: kart yok, doğrudan satırlar
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