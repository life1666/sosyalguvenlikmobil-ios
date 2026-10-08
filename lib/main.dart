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
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mesaitakip/mesaitakip.dart'; // OvertimeCalendarPage burada
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui'; // PointerDeviceKind için (eğer scrollBehavior kullanacaksan)
import 'cv/cv_sablon.dart'; // CV şablonları için
import 'utils/theme_helper.dart';
import 'utils/app_design.dart';
import 'services/notification_service.dart';
import 'services/premium_store_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CV şablonlarını kaydet
  registerTemplates();
  debugPrint('✅ CV şablonları yüklendi');

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('✅ Firebase initialized');

    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttestWithDeviceCheckFallback,
      );
      debugPrint('✅ Firebase App Check initialized');
    } catch (e) {
      debugPrint('⚠️ Firebase App Check init hatası: $e');
    }

    try {
      await FirebaseInAppMessaging.instance.setMessagesSuppressed(false);
      await FirebaseInAppMessaging.instance.triggerEvent('app_open');
      debugPrint('✅ Firebase In-App Messaging initialized');
    } catch (e) {
      debugPrint('⚠️ Firebase In-App Messaging init hatası: $e');
    }

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

  try {
    await NotificationService.instance
        .initialize(firebaseAvailable: firebaseReady);
    debugPrint('✅ Bildirim servisi hazır');
  } catch (e) {
    debugPrint('⚠️ Bildirim servisi başlatılamadı: $e');
  }

  // Attach the purchase listener before showing any screen so resumed
  // transactions are never lost when the Premium page is closed.
  PremiumStoreService.instance.initialize();

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
  Color _themeColor =
      Colors.indigo; // Varsayılan tema (app bar alt bar ile beyaz)
  double _fontSize = 14.0; // Varsayılan 14 punto
  ThemeMode _themeMode = ThemeMode.light;

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
        _themeMode = _themeHelper.darkMode ? ThemeMode.dark : ThemeMode.light;
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
        _themeMode = _themeHelper.darkMode ? ThemeMode.dark : ThemeMode.light;
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
            textScaleFactor:
                textScaleFactor.clamp(0.85, 1.3), // 12-18 punto arası
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        primaryColor: _themeColor,
        colorScheme: ColorScheme.fromSeed(seedColor: _themeColor),
        scaffoldBackgroundColor: AppDesign.background,
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppDesign.border)),
          textStyle: const TextStyle(color: AppDesign.ink, fontSize: 14),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: AppDesign.ink,
          iconColor: AppDesign.muted,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppDesign.background,
          titleTextStyle: const TextStyle(
              color: AppDesign.ink, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: const IconThemeData(color: AppDesign.ink),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          labelLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: _themeColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        canvasColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        dividerColor: const Color(0xFF334155),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF1E293B),
          surfaceTintColor: Colors.transparent,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          textStyle: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFFF1F5F9),
          iconColor: Color(0xFF94A3B8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Color(0xFFF1F5F9),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 20,
              fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
          labelLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF475569)),
          ),
        ),
      ),
      themeMode: _themeMode,

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
