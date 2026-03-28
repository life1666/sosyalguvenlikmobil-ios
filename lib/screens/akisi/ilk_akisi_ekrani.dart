import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ana_ekran.dart';
import 'akisi_durum.dart';
import 'akisi_modelleri.dart';
import 'kullanici_adi_ekrani.dart';
import 'onboarding_tanitim_ekrani.dart';
import 'profil_tipi_secim_ekrani.dart';

/// Uygulama açılışı: tanıtım → profil tipi → (push) kullanıcı adı → giriş seçenekleri.
class IlkAkisiEkrani extends StatefulWidget {
  const IlkAkisiEkrani({super.key});

  @override
  State<IlkAkisiEkrani> createState() => _IlkAkisiEkraniState();
}

class _IlkAkisiEkraniState extends State<IlkAkisiEkrani> {
  bool _hazir = false;
  bool _anaEkranaGidildi = false;
  bool _tanitimGoruldu = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('tr');
    _baslangic();
  }

  Future<void> _baslangic() async {
    if (FirebaseAuth.instance.currentUser != null) {
      if (!mounted) return;
      setState(() => _anaEkranaGidildi = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => AnaEkran()),
        );
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final kurulumTamam = prefs.getBool(AkisiDurum.kurulumTamamKey) ?? false;
    if (kurulumTamam) {
      if (!mounted) return;
      setState(() => _anaEkranaGidildi = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => AnaEkran()),
        );
      });
      return;
    }

    _tanitimGoruldu =
        prefs.getBool(AkisiDurum.tanitimGorulduKey) ?? false;

    if (!mounted) return;
    setState(() => _hazir = true);
  }

  Future<void> _tanitimBitir() async {
    await AkisiDurum.tanitimiIsaretle();
    if (!mounted) return;
    setState(() => _tanitimGoruldu = true);
  }

  void _profilSecildiTip(AkisiProfilTipi tip) {
    final nav = Navigator.of(context);
    nav.push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => KullaniciAdiEkrani(
          profilTipi: tip,
          onGeri: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_anaEkranaGidildi) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hazir) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_tanitimGoruldu) {
      return OnboardingTanitimEkrani(
        onComplete: _tanitimBitir,
        onSkip: _tanitimBitir,
      );
    }

    return ProfilTipiSecimEkrani(
      onProfilSecildi: _profilSecildiTip,
    );
  }
}
