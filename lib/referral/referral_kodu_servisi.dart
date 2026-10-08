import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Referans kodu + mağaza linkleri (Android referrer ile sgk_app uyumu).
class ReferralKoduServisi {
  ReferralKoduServisi._();

  static const _misafirAnahtar = 'referral_kodu_misafir';

  /// Oturum açıksa UID’den türetilen sabit kod; misafirde cihaza özel saklanan kod.
  static Future<String> koduAl() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null && u.uid.isNotEmpty) {
      return _kodFromUid(u.uid);
    }
    final p = await SharedPreferences.getInstance();
    var kod = p.getString(_misafirAnahtar);
    if (kod == null || kod.isEmpty) {
      kod = _rastgeleKod();
      await p.setString(_misafirAnahtar, kod);
    }
    return kod;
  }

  static String _kodFromUid(String uid) {
    final d = sha256.convert(utf8.encode(uid));
    return d.toString().substring(0, 8).toUpperCase();
  }

  static String _rastgeleKod() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// play.google.com ...?id= paket parametresinden paket adı.
  static String paketIdCoz(String playStoreLink) {
    try {
      final u = Uri.parse(playStoreLink);
      final id = u.queryParameters['id'];
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return 'com.sosyalguvenlik.mobil';
  }

  /// Android: Play Console referrer — utm_content = referans kodu.
  static String androidDavetLinki({
    required String playStoreLink,
    required String referansKodu,
  }) {
    final paket = paketIdCoz(playStoreLink);
    final ref = Uri.encodeComponent(
      'utm_source=referral&utm_medium=invite&utm_content=$referansKodu',
    );
    return 'https://play.google.com/store/apps/details?id=$paket&referrer=$ref';
  }

  static Future<void> paylas({
    required String referansKodu,
    required String playStoreLink,
    required String appStoreLink,
  }) async {
    final android = androidDavetLinki(
      playStoreLink: playStoreLink,
      referansKodu: referansKodu,
    );
    final metin = StringBuffer()
      ..writeln('Sosyal Güvenlik Mobil — seni davet ediyorum!')
      ..writeln()
      ..writeln('Referans kodum: $referansKodu')
      ..writeln()
      ..writeln('Android (referanslı indirme):')
      ..writeln(android)
      ..writeln()
      ..writeln('iOS:')
      ..writeln(appStoreLink)
      ..writeln()
      ..writeln('Kodu uygulamada girerek veya yukarıdaki linkle indirerek bana destek olabilirsin.');

    await Share.share(
      metin.toString(),
      subject: 'Sosyal Güvenlik Mobil daveti',
    );
  }
}
