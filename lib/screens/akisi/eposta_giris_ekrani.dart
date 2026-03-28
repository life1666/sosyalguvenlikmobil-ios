import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'akisi_durum.dart';
import 'akisi_modelleri.dart';
import 'akisi_renkleri.dart';
import 'kayit_ekrani.dart';

/// E-posta + şifre ile giriş (akış görünümü).
class EpostaGirisEkrani extends StatefulWidget {
  final AkisiProfilTipi profilTipi;
  final String takmaAd;

  const EpostaGirisEkrani({
    super.key,
    required this.profilTipi,
    required this.takmaAd,
  });

  @override
  State<EpostaGirisEkrani> createState() => _EpostaGirisEkraniState();
}

class _EpostaGirisEkraniState extends State<EpostaGirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sifre = TextEditingController();
  bool _sifreGizli = true;

  @override
  void dispose() {
    _email.dispose();
    _sifre.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _sifre.text,
      );
      if (!mounted) return;
      await AkisiDurum.tamamlaVeAnaEkranaGit(
        context,
        widget.profilTipi,
        widget.takmaAd,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş hatası: $e')),
        );
      }
    }
  }

  Future<void> _sifremiUnuttum() async {
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce e-posta adresinizi girin'),
        ),
      );
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama bağlantısı gönderildi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=1200',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: AkisiRenkleri.navy.withOpacity(0.88),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'E-posta ile Giriş',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dekor('E-posta', Icons.email_outlined),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'E-posta giriniz' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _sifre,
                            obscureText: _sifreGizli,
                            decoration: _dekor('Şifre', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _sifreGizli
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AkisiRenkleri.navy,
                                ),
                                onPressed: () => setState(
                                    () => _sifreGizli = !_sifreGizli),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Şifre giriniz' : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _sifremiUnuttum,
                              child: const Text(
                                'Şifremi unuttum?',
                                style: TextStyle(
                                  color: AkisiRenkleri.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _girisYap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AkisiRenkleri.navy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => KayitEkrani(
                                      profilTipi: widget.profilTipi,
                                      takmaAd: widget.takmaAd,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Hesabınız yok mu? Kayıt olun',
                                style: TextStyle(
                                  color: AkisiRenkleri.blue500,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dekor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AkisiRenkleri.navy),
      filled: true,
      fillColor: AkisiRenkleri.slate50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AkisiRenkleri.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AkisiRenkleri.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AkisiRenkleri.navy, width: 2),
      ),
    );
  }
}
