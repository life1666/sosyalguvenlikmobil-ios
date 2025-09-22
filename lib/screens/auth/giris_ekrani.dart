import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> _googleIleGirisYap() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AnaEkran()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google giriş hatası: ${e.toString()}')),
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
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
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
        title: Text(_kayitModu ? 'Kayıt Ol' : 'Giriş Yap'),
        centerTitle: true,
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
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.indigo, // Şeffaf değil, düz indigo
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 38),
                      SizedBox(height: 12),
                      Text(
                        'Sorumluluk Reddi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 8.0),
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
                      SizedBox(height: 28),
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
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Okudum, Anladım',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      borderSide: BorderSide(color: Colors.indigo),
      borderRadius: BorderRadius.circular(8),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.indigo),
            SizedBox(height: 16),

            // 📧 E-Posta
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-Posta',
                labelStyle: TextStyle(color: Colors.indigo),
                prefixIcon: Icon(Icons.email_outlined, color: Colors.indigo),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
              ),
              validator: (value) => value!.isEmpty ? 'E-posta giriniz' : null,
            ),
            SizedBox(height: 16),

            // 🔐 Şifre
            TextFormField(
              controller: _sifreController,
              obscureText: _sifreGizli,
              decoration: InputDecoration(
                labelText: 'Şifre',
                labelStyle: TextStyle(color: Colors.indigo),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.indigo),
                suffixIcon: IconButton(
                  icon: Icon(
                    _sifreGizli ? Icons.visibility : Icons.visibility_off,
                    color: Colors.indigo,
                  ),
                  onPressed: () {
                    setState(() {
                      _sifreGizli = !_sifreGizli;
                    });
                  },
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
              ),
              validator: (value) => value!.isEmpty ? 'Şifre giriniz' : null,
            ),

            // ❓ Şifremi unuttum
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _sifremiUnuttum,
                child: Text('Şifremi unuttum?', style: TextStyle(color: Colors.indigo)),
              ),
            ),

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
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AnaEkran()));
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
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _kayitModu ? 'Kayıt Ol' : 'Giriş Yap',
                style: TextStyle(fontSize: 16),
              ),
            ),

            SizedBox(height: 20),
            Divider(thickness: 1),
            SizedBox(height: 10),

            // 🔐 Google Giriş
            ElevatedButton.icon(
              onPressed: _googleIleGirisYap,
              icon: Icon(Icons.login),
              label: Text('Google ile Giriş Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            SizedBox(height: 20),

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
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
            ),

            // 🚪 Üyeliksiz Devam Et
            SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => AnaEkran()),
                  );
                },
                child: Text(
                  'Üyeliksiz Devam Et',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
