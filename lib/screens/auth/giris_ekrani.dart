import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../ana_ekran.dart';

class GirisEkrani extends StatefulWidget {
  @override
  _GirisEkraniState createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  bool _sifreGizli = true;
  bool _kayitModu = false;
  bool _showDisclaimer = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('tr');
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
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => AnaEkran()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google giriş hatası: ${e.toString()}')),
      );
    }
  }

  // --- Apple ile giriş ---
  Future<void> _appleIleGirisYap() async {
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

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCred.identityToken,
        rawNonce: rawNonce,
      );

      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final fullName =
      '${appleCred.givenName ?? ''} ${appleCred.familyName ?? ''}'.trim();
      if (fullName.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(fullName);
      }

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => AnaEkran()));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return; // kullanıcı iptal etti
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple yetkilendirme hatası: ${e.message}')),
      );
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre sıfırlama bağlantısı gönderildi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = buildLoginBody(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _kayitModu ? 'Kayıt Ol' : 'Giriş Yap',
          style: const TextStyle(color: Colors.indigo),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Stack(
        children: [
          body,
          if (_showDisclaimer)
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.92,
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    minHeight: 200,
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 38),
                      const SizedBox(height: 12),
                      const Text(
                        'Sorumluluk Reddi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      const Padding(
                        padding: EdgeInsets.only(left: 20.0, right: 8.0),
                        child: Text(
                          'Bu uygulama, herhangi bir kamu kurumu, devlet dairesi veya resmi kuruluş tarafından geliştirilmemiştir. SGK, e-Devlet ya da Çalışma ve Sosyal Güvenlik Bakanlığı ile herhangi bir bağlantısı bulunmamaktadır. Uygulama yalnızca bilgi sağlamak amacıyla hazırlanmıştır. Sunulan hesaplamalar resmi belge niteliği taşımaz. Bu nedenle herhangi bir sorumluluk kabul edilmez.',
                          style: TextStyle(
                            fontSize: 15.5,
                            color: Colors.white,
                            height: 1.7,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showDisclaimer = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Okudum, Anladım',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildLoginBody(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.indigo.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(12),
    );
    final focusedBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.indigo, width: 2),
      borderRadius: BorderRadius.circular(12),
    );
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.indigo.withOpacity(0.02),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Modern Header
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _kayitModu ? 'Hesap Oluştur' : 'Hoş Geldiniz',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _kayitModu
                        ? 'Yeni hesabınızı oluşturun'
                        : 'Hesabınıza giriş yapın',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 📧 E-Posta
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'E-Posta',
                  labelStyle: const TextStyle(color: Colors.indigo),
                  hintText: 'ornek@email.com',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.indigo),
                  filled: true,
                  fillColor: Colors.white,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value!.isEmpty ? 'E-posta giriniz' : null,
              ),
              const SizedBox(height: 20),

              // 🔐 Şifre
              TextFormField(
                controller: _sifreController,
                obscureText: _sifreGizli,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  labelStyle: const TextStyle(color: Colors.indigo),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _sifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.indigo,
                    ),
                    onPressed: () {
                      setState(() {
                        _sifreGizli = !_sifreGizli;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value!.isEmpty ? 'Şifre giriniz' : null,
              ),

              // ❓ Şifremi unuttum
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sifremiUnuttum,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'Şifremi unuttum?',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 🔘 Giriş / Kayıt Butonu
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      if (_kayitModu) {
                        await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _sifreController.text,
                        );
                      } else {
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _sifreController.text,
                        );
                      }
                      Navigator.pushReplacement(
                          context, MaterialPageRoute(builder: (_) => AnaEkran()));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: ${e.toString()}')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  _kayitModu ? 'Kayıt Ol' : 'Giriş Yap',
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
                  Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'veya',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                ],
              ),

              const SizedBox(height: 20),

              // 🔐 Google Giriş
              ElevatedButton.icon(
                onPressed: _googleIleGirisYap,
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Google ile Giriş Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
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
                  onPressed: () {
                    setState(() {
                      _kayitModu = !_kayitModu;
                    });
                  },
                  child: Text(
                    _kayitModu
                        ? 'Zaten hesabınız var mı? Giriş Yap'
                        : 'Hesabınız yok mu? Kayıt Ol',
                    style: const TextStyle(
                      color: Colors.indigo,
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => AnaEkran()),
                    );
                  },
                  child: const Text(
                    'Üyeliksiz Devam Et',
                    style: TextStyle(
                      color: Colors.indigo,
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
    );
  }
}
