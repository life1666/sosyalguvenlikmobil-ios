import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'akisi_durum.dart';
import 'akisi_modelleri.dart';

/// Google / Apple girişi — [GirisEkrani] ile aynı mantık, akış parametreleriyle.
class AkisiAuthYardimci {
  AkisiAuthYardimci._();

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> googleIleGiris(
    BuildContext context, {
    required AkisiProfilTipi profilTipi,
    required String takmaAd,
  }) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!context.mounted) return;
      await AkisiDurum.tamamlaVeAnaEkranaGit(context, profilTipi, takmaAd);
    } catch (e, st) {
      debugPrint('Google giriş hatası: $e');
      FirebaseCrashlytics.instance.recordError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google giriş hatası: $e')),
        );
      }
    }
  }

  static Future<void> appleIleGiris(
    BuildContext context, {
    required AkisiProfilTipi profilTipi,
    required String takmaAd,
  }) async {
    if (!Platform.isIOS) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple ile giriş sadece iOS cihazlarda kullanılabilir.'),
          ),
        );
      }
      return;
    }

    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCred.identityToken == null ||
          appleCred.authorizationCode == null) {
        throw Exception('Apple kimlik bilgisi eksik (token/code null).');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
        rawNonce: rawNonce,
      );

      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final fullName =
          '${appleCred.givenName ?? ''} ${appleCred.familyName ?? ''}'.trim();
      if (fullName.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(fullName);
      }

      if (!context.mounted) return;
      await AkisiDurum.tamamlaVeAnaEkranaGit(context, profilTipi, takmaAd);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple yetkilendirme hatası: ${e.message}')),
        );
      }
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple giriş hatası: $e')),
        );
      }
    }
  }
}
