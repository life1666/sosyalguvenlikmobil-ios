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
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase init hatası: $e');
  }

  try {
    await initializeDateFormatting('tr_TR', null);
    print('✅ Tarih formatı yüklendi');
  } catch (e) {
    print('❌ Date format hatası: $e');
  }

  runApp(SgkBilgiPlatformu());
}

class SgkBilgiPlatformu extends StatelessWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sosyal Güvenlik Cepte',
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      theme: ThemeData(
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          labelLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      home: IlkYuklemeKontrolEkrani(),
      routes: {
        '/giris': (context) => GirisEkrani(),
        '/iletisim': (context) => IletisimEkrani(),
        '/mesajlar': (context) => MesajlarEkrani(),
      },
    );
  }
}

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