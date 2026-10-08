import '../../utils/app_design.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../ana_ekran.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key, this.returnToCaller = false});

  final bool returnToCaller;

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  void _completeSignIn() {
    if (!mounted) return;
    if (widget.returnToCaller) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => AnaEkran()));
    }
  }

  bool _sifreGizli = true;
  bool _kayitModu = false;
  bool _busy = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('tr');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      if (_kayitModu) {
        final result =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _sifreController.text,
        );
        await result.user?.updateDisplayName(_nameController.text.trim());
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _sifreController.text,
        );
      }
      _completeSignIn();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'email-already-in-use' => 'Bu e-posta adresi zaten kayıtlı.',
        'invalid-email' => 'Geçerli bir e-posta adresi girin.',
        'weak-password' => 'Daha güçlü bir şifre belirleyin.',
        'wrong-password' ||
        'invalid-credential' ||
        'user-not-found' =>
          'E-posta veya şifre hatalı.',
        _ => 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('İşlem tamamlanamadı. Lütfen tekrar deneyin.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- Apple/Firebase için nonce yardımcıları ---
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- Google ile giriş ---
  Future<void> _googleIleGirisYap() async {
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
      _completeSignIn();
    } catch (e) {
      debugPrint('Google giriş hatası: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google giriş hatası: ${e.toString()}')),
        );
      }
    }
  }

// --- Apple ile giriş ---
  Future<void> _appleIleGirisYap() async {
    try {
      // Sadece iOS'ta çalışsın (emniyet için)
      if (!Platform.isIOS) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Apple ile giriş sadece iOS cihazlarda kullanılabilir.')),
        );
        return;
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Güvenlik için null kontrolü
      if (appleCred.identityToken == null) {
        throw Exception('Apple kimlik bilgisi eksik (token/code null).');
      }

      // 🔥 ÖNEMLİ KISIM: accessToken = authorizationCode
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode, // <-- EKLEDİK
        rawNonce: rawNonce,
      );

      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final fullName =
          '${appleCred.givenName ?? ''} ${appleCred.familyName ?? ''}'.trim();
      if (fullName.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(fullName);
      }

      _completeSignIn();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple yetkilendirme hatası: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple giriş hatası: $e')),
      );
    }
  }

  Future<void> _sifremiUnuttum() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen önce e-posta adresinizi girin')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre sıfırlama bağlantısı gönderildi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.activeBackground,
        appBar: AppDesign.appBar(_kayitModu ? 'Kayıt ol' : 'Giriş yap'),
        body: SafeArea(child: AppContent(child: buildLoginBody(context))),
      );
  Widget buildLoginBody(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final ink = AppDesign.activeInk;
    final muted = AppDesign.activeMuted;
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: AppDesign.activeBorder),
      borderRadius: BorderRadius.circular(14),
    );
    final focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: primary, width: 2),
      borderRadius: BorderRadius.circular(14),
    );

    return ColoredBox(
      color: AppDesign.activeBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Modern Header
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _kayitModu
                            ? Icons.person_add_alt_1_rounded
                            : Icons.lock_outline_rounded,
                        size: 36,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _kayitModu ? 'Hesabınızı oluşturun' : 'Hoş geldiniz',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _kayitModu
                          ? 'Çalışma hayatınızı takip etmek için başlayın.'
                          : 'Hesabınızla devam edin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                if (_kayitModu) ...[
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: ink),
                    decoration: InputDecoration(
                      labelText: 'Adınız',
                      prefixIcon:
                          Icon(Icons.person_outline_rounded, color: primary),
                      filled: true,
                      fillColor: AppDesign.activeSurface,
                      border: border,
                      enabledBorder: border,
                      focusedBorder: focusedBorder,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Adınızı girin'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // 📧 E-Posta
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 16, color: ink),
                  decoration: InputDecoration(
                    labelText: 'E-Posta',
                    labelStyle: TextStyle(color: muted),
                    hintText: 'ornek@email.com',
                    hintStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.email_outlined, color: primary),
                    filled: true,
                    fillColor: AppDesign.activeSurface,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: focusedBorder,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: (value) => value == null ||
                          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())
                      ? 'Geçerli bir e-posta adresi girin'
                      : null,
                ),
                const SizedBox(height: 14),

                // 🔐 Şifre
                TextFormField(
                  controller: _sifreController,
                  obscureText: _sifreGizli,
                  style: TextStyle(fontSize: 16, color: ink),
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    labelStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.lock_outline, color: primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _sifreGizli
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _sifreGizli = !_sifreGizli;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppDesign.activeSurface,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: focusedBorder,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Şifre girin'
                      : _kayitModu && value.length < 6
                          ? 'Şifre en az 6 karakter olmalı'
                          : null,
                ),

                if (_kayitModu) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _sifreGizli,
                    style: TextStyle(color: ink),
                    decoration: InputDecoration(
                      labelText: 'Şifre tekrar',
                      prefixIcon:
                          Icon(Icons.verified_user_outlined, color: primary),
                      filled: true,
                      fillColor: AppDesign.activeSurface,
                      border: border,
                      enabledBorder: border,
                      focusedBorder: focusedBorder,
                    ),
                    validator: (value) => value != _sifreController.text
                        ? 'Şifreler eşleşmiyor'
                        : null,
                  ),
                ],

                // ❓ Şifremi unuttum
                const SizedBox(height: 12),
                if (!_kayitModu)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _sifremiUnuttum,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: Text(
                        'Şifremi unuttum?',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // 🔘 Giriş / Kayıt Butonu
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _busy
                        ? 'Lütfen bekleyin…'
                        : _kayitModu
                            ? 'Hesap oluştur'
                            : 'Giriş yap',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Divider with text
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: AppDesign.activeBorder, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'veya',
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: AppDesign.activeBorder, thickness: 1)),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔐 Google Giriş
                ElevatedButton.icon(
                  onPressed: _googleIleGirisYap,
                  icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                  label: const Text('Google ile Giriş Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.activeSurface,
                    foregroundColor: ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppDesign.activeBorder),
                    ),
                    elevation: 0,
                  ),
                ),

                // ⬇️ Apple Giriş (yalnızca iOS)
                if (Platform.isIOS) ...[
                  const SizedBox(height: 12),
                  SignInWithAppleButton(
                    onPressed: _appleIleGirisYap,
                    style: SignInWithAppleButtonStyle.black,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                ],

                const SizedBox(height: 24),

                // 🔁 Kayıt <-> Giriş geçişi
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _kayitModu = !_kayitModu;
                            });
                            _formKey.currentState?.reset();
                          },
                    child: Text(
                      _kayitModu
                          ? 'Zaten hesabınız var mı? Giriş Yap'
                          : 'Hesabınız yok mu? Kayıt Ol',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // 🚪 Üyeliksiz Devam Et
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (widget.returnToCaller) {
                        Navigator.of(context).pop(false);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => AnaEkran()),
                        );
                      }
                    },
                    child: Text(
                      'Üyeliksiz Devam Et',
                      style: TextStyle(
                        color: muted,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
