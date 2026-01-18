import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/ana_ekran.dart';
import 'screens/auth/giris_ekrani.dart';
import 'screens/yanmenu/iletisim_ekrani.dart';
import 'screens/admin/mesajlar_ekrani.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mesaitakip/mesaitakip.dart'; // OvertimeCalendarPage burada
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui'; // PointerDeviceKind için (eğer scrollBehavior kullanacaksan)
import 'cv/cv_sablon.dart'; // CV şablonları için
import 'utils/theme_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CV şablonlarını kaydet
  registerTemplates();
  debugPrint('✅ CV şablonları yüklendi');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
    
    // Crashlytics setup
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Crashlytics'i sadece release modda aktif et
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  } catch (e) {
    debugPrint('❌ Firebase init hatası: $e');
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
  }

  try {
    await initializeDateFormatting('tr_TR', null);
    debugPrint('✅ Tarih formatı yüklendi');
  } catch (e) {
    debugPrint('❌ Date format hatası: $e');
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
  }

  runApp(SgkBilgiPlatformu());
}

class SgkBilgiPlatformu extends StatefulWidget {
  const SgkBilgiPlatformu({super.key});

  @override
  State<SgkBilgiPlatformu> createState() => _SgkBilgiPlatformuState();
}

class _SgkBilgiPlatformuState extends State<SgkBilgiPlatformu> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final ThemeHelper _themeHelper = ThemeHelper();
  Color _themeColor = Colors.indigo; // Varsayılan indigo (orijinal renk)
  double _fontSize = 14.0; // Varsayılan 14 punto

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
    _themeHelper.addThemeChangeListener(_onThemeChanged);
    _themeHelper.addFontSizeChangeListener(_onFontSizeChanged);
  }

  @override
  void dispose() {
    _themeHelper.removeThemeChangeListener(_onThemeChanged);
    _themeHelper.removeFontSizeChangeListener(_onFontSizeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _themeColor = _themeHelper.themeColor;
      });
    }
  }

  void _onFontSizeChanged() {
    if (mounted) {
      setState(() {
        _fontSize = _themeHelper.fontSize;
      });
    }
  }

  Future<void> _loadThemeSettings() async {
    await _themeHelper.loadSettings();
    if (mounted) {
      setState(() {
        _themeColor = _themeHelper.themeColor;
        _fontSize = _themeHelper.fontSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema rengine göre text scale factor hesapla (14 punto = 1.0)
    final textScaleFactor = _fontSize / 14.0;
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sosyal Güvenlik Mobil',
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: textScaleFactor.clamp(0.85, 1.3), // 12-18 punto arası
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        primaryColor: _themeColor,
        colorScheme: ColorScheme.fromSeed(seedColor: _themeColor),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: _themeColor,
          titleTextStyle: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          labelLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // >>>>> BURASI ÖNEMLİ: önce delegates, sonra supportedLocales; ikisi de kapanıyor
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],

      // İstersen kullan; "const" KALMAYACAK!
      scrollBehavior: MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),

      home: AnaEkran(),
      routes: {
        '/giris': (context) => GirisEkrani(),
        '/iletisim': (context) => IletisimEkrani(),
        '/mesajlar': (context) => MesajlarEkrani(),
        '/mesai': (_) => const OvertimeCalendarPage(),
      },
    );
  }
}

// IlkYuklemeKontrolEkrani removed - app now opens directly to AnaEkran
/*
class IlkYuklemeKontrolEkrani extends StatefulWidget {
  @override
  State<IlkYuklemeKontrolEkrani> createState() => _IlkYuklemeKontrolEkraniState();
}

class _IlkYuklemeKontrolEkraniState extends State<IlkYuklemeKontrolEkrani> {
  bool _kontrolYapildi = false;

  @override
  void initState() {
    super.initState();
    _kontrolVeYonlendir();
  }

  Future<void> _kontrolVeYonlendir() async {
    final prefs = await SharedPreferences.getInstance();
    bool dahaOnceGosterildi = prefs.getBool('kayit_ekrani_gosterildi') ?? false;
    final _kullanici = FirebaseAuth.instance.currentUser;

    if (!dahaOnceGosterildi) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GirisEkrani()),
        );
        setState(() {
          _kontrolYapildi = true;
        });
      });
      await prefs.setBool('kayit_ekrani_gosterildi', true);
    } else {
      setState(() {
        _kontrolYapildi = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _kullanici = FirebaseAuth.instance.currentUser;
    if (!_kontrolYapildi) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _kullanici == null ? AnaEkran() : AnaEkran();
  }
}
*/
