import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ana_ekran.dart';
import 'akisi_modelleri.dart';

/// İlk kurulum / tanıtım akışı için kalıcı tercihler.
class AkisiDurum {
  AkisiDurum._();

  static const String tanitimGorulduKey = 'akisi_tanitim_goruldu';
  static const String kurulumTamamKey = 'akisi_kurulum_tamam';
  static const String profilTipiKey = 'akisi_profil_tipi';
  static const String takmaAdKey = 'akisi_takma_ad';

  static Future<void> tanitimiIsaretle() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(tanitimGorulduKey, true);
  }

  static Future<void> tamamlaVeAnaEkranaGit(
    BuildContext context,
    AkisiProfilTipi profilTipi,
    String takmaAd,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kurulumTamamKey, true);
    await prefs.setString(profilTipiKey, profilTipi.name);
    await prefs.setString(takmaAdKey, takmaAd);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && takmaAd.isNotEmpty) {
      try {
        await user.updateDisplayName(takmaAd);
      } catch (_) {}
    }

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => AnaEkran()),
      (route) => false,
    );
  }
}
