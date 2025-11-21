import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../auth/giris_ekrani.dart';

class HesabimEkrani extends StatefulWidget {
  const HesabimEkrani({super.key});

  @override
  State<HesabimEkrani> createState() => _HesabimEkraniState();
}

class _HesabimEkraniState extends State<HesabimEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
  }

  // ---------- Apple/Firebase için nonce ----------
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  // ---------- Re-auth seçenek alt sayfası ----------
  Future<void> _promptReauth() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 12,
              children: [
                const Text(
                  'Güvenlik için yeniden giriş yapın',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _reauthWithPassword();
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('E-posta ve şifre ile'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _reauthWithGoogle();
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Google ile'),
                ),
                if (Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _reauthWithApple();
                    },
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple ile'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Sağlayıcı bazlı re-auth ----------
  Future<void> _reauthWithPassword() async {
    final email = _auth.currentUser?.email ?? '';
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Şifreyi girin'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Şifre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Onayla')),
        ],
      ),
    );

    if (ok != true) return;

    final cred =
    EmailAuthProvider.credential(email: email, password: ctrl.text);
    await _auth.currentUser?.reauthenticateWithCredential(cred);
  }

  Future<void> _reauthWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.currentUser?.reauthenticateWithCredential(cred);
  }

  Future<void> _reauthWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final cred = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
    );

    await _auth.currentUser?.reauthenticateWithCredential(cred);
  }

  // ---------- Bilgi güncelle ----------
  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // E-posta değiştiyse: updateEmail() DEPRECATED → verifyBeforeUpdateEmail()
      if (_emailController.text.trim() != (user.email ?? '').trim()) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Yeni e-posta için doğrulama bağlantısı gönderildi. Lütfen e-postandaki linki onayla.'),
          ),
        );
      }

      // Şifre değişimi varsa
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İstek(ler) başarıyla gönderildi.')),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _promptReauth();        // yeniden doğrula
        return _updateUserInfo();     // sonra işlemi tekrar dene
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Bir hata oluştu.')),
      );
    }
  }

  // ---------- Hesap sil ----------
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
            'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _auth.currentUser?.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap başarıyla silindi.')),
      );

      // const KALDIRILDI: GirisEkrani const constructor değil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GirisEkrani()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _promptReauth();
        return _deleteAccount();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Hesap silinirken bir hata oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.indigo.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(12),
    );
    final focusedBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.indigo, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hesabım',
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
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 64,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Hesap Ayarları',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 📧 E-posta
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta boş olamaz';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 🔑 Yeni Şifre
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    labelStyle: const TextStyle(color: Colors.indigo),
                    hintText: 'En az 6 karakter',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.indigo,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
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
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 🔁 Yeni Şifre Tekrar
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifreyi Tekrar Yaz',
                    labelStyle: const TextStyle(color: Colors.indigo),
                    hintText: 'Şifreyi tekrar girin',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.indigo,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
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
                  validator: (value) {
                    if (_passwordController.text.isNotEmpty &&
                        value != _passwordController.text) {
                      return 'Şifreler uyuşmuyor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 💾 Kaydet
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _updateUserInfo,
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🗑️ Hesabı Sil
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _deleteAccount,
                    child: const Text(
                      'Hesabı Sil',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
