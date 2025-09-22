import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
final TextEditingController _confirmPasswordController = TextEditingController();

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

Future<void> _updateUserInfo() async {
if (!_formKey.currentState!.validate()) return;

final user = _auth.currentUser;

if (user != null) {
try {
if (_emailController.text != user.email) {
await user.updateEmail(_emailController.text);
}

if (_passwordController.text.isNotEmpty) {
await user.updatePassword(_passwordController.text);
}

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Bilgiler başarıyla güncellendi!')),
);
} on FirebaseAuthException catch (e) {
String errorMessage = "Bir hata oluştu.";

if (e.code == 'requires-recent-login') {
errorMessage = "Bu işlemi gerçekleştirmek için yeniden giriş yapmanız gerekiyor.";
// Yeniden giriş ekranına yönlendirme
await Navigator.push(
context,
MaterialPageRoute(builder: (_) => GirisEkrani()),
);
// Kullanıcı giriş yaptıktan sonra tekrar deneme
if (_auth.currentUser != null) {
await _updateUserInfo();
}
} else if (e.code == 'invalid-email') {
errorMessage = "Geçersiz e-posta adresi.";
}

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(errorMessage)),
);
}
}
}

Future<void> _deleteAccount() async {
bool? confirmDelete = await showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
title: Text("Hesabı Sil"),
content: Text("Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz."),
actions: [
TextButton(
onPressed: () => Navigator.of(context).pop(false),
child: Text("İptal"),
),
TextButton(
onPressed: () => Navigator.of(context).pop(true),
child: Text("Sil", style: TextStyle(color: Colors.red)),
),
],
),
);

if (confirmDelete != true) return;

final user = _auth.currentUser;

if (user != null) {
try {
await user.delete();
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Hesap başarıyla silindi.')),
);
// Giriş ekranına yönlendirme
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => GirisEkrani()),
);
} on FirebaseAuthException catch (e) {
String errorMessage = "Hesap silinirken bir hata oluştu.";

if (e.code == 'requires-recent-login') {
errorMessage = "Hesabı silmek için lütfen yeniden giriş yapın.";
// Yeniden giriş ekranına yönlendirme ve sonucu bekleme
await Navigator.push(
context,
MaterialPageRoute(builder: (_) => GirisEkrani()),
);
// Kullanıcı giriş yaptıktan sonra tekrar silmeyi deneme
if (_auth.currentUser != null) {
await _deleteAccount();
}
}

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(errorMessage)),
);
}
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text("Hesabım")),
body: Padding(
padding: const EdgeInsets.all(20),
child: Form(
key: _formKey,
child: Column(
children: [
// 📧 E-posta
TextFormField(
controller: _emailController,
decoration: InputDecoration(
labelText: "E-Posta",
border: OutlineInputBorder(),
),
keyboardType: TextInputType.emailAddress,
validator: (value) {
if (value == null || value.isEmpty) return "E-posta boş olamaz";
if (!value.contains("@")) return "Geçerli bir e-posta girin";
return null;
},
),
const SizedBox(height: 20),

// 🔑 Yeni Şifre
TextFormField(
controller: _passwordController,
obscureText: _obscurePassword,
decoration: InputDecoration(
labelText: "Yeni Şifre",
border: OutlineInputBorder(),
suffixIcon: IconButton(
icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
onPressed: () {
setState(() {
_obscurePassword = !_obscurePassword;
});
},
),
),
validator: (value) {
if (value != null && value.isNotEmpty && value.length < 6) {
return "Şifre en az 6 karakter olmalı";
}
return null;
},
),
const SizedBox(height: 20),

// 🔁 Yeni Şifre Tekrar
TextFormField(
controller: _confirmPasswordController,
obscureText: _obscureConfirm,
decoration: InputDecoration(
labelText: "Yeni Şifreyi Tekrar Yaz",
border: OutlineInputBorder(),
suffixIcon: IconButton(
icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
onPressed: () {
setState(() {
_obscureConfirm = !_obscureConfirm;
});
},
),
),
validator: (value) {
if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
return "Şifreler uyuşmuyor";
}
return null;
},
),
const SizedBox(height: 30),

// 💾 Kaydet
SizedBox(
width: double.infinity,
child: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
onPressed: _updateUserInfo,
child: Text("Kaydet", style: TextStyle(color: Colors.white)),
),
),
const SizedBox(height: 20),

// 🗑️ Hesabı Sil
SizedBox(
width: double.infinity,
child: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
onPressed: _deleteAccount,
child: Text("Hesabı Sil", style: TextStyle(color: Colors.white)),
),
),
],
),
),
),
);
}
}