import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IletisimEkrani extends StatefulWidget {
  @override
  _IletisimEkraniState createState() => _IletisimEkraniState();
}

class _IletisimEkraniState extends State<IletisimEkrani> {
  final _mesajController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _yukleniyor = false;
  bool _gonderildi = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Kullanıcı durumunu dinle
    _auth.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<void> _mesajGonder() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesaj göndermek için giriş yapmalısınız.")),
      );
      return;
    }

    if (_mesajController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesajınızı yazmalısınız.")),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      // Mesajı messages koleksiyonuna ekle
      await _firestore.collection('messages').add({
        'userId': _currentUser!.uid,
        'email': _currentUser!.email,
        'message': _mesajController.text.trim(),
        'timestamp': Timestamp.now(),
      });

      _mesajController.clear();

      setState(() {
        _yukleniyor = false;
        _gonderildi = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesajınız başarıyla gönderildi.")),
      );

      await Future.delayed(Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _gonderildi = false;
        });
      }
    } catch (e) {
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesaj gönderilirken bir hata oluştu. Lütfen tekrar deneyin.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('İletişim')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _currentUser == null
            ? Center(child: Text("Mesaj göndermek için giriş yapmalısınız."))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Bize mesaj gönderin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _mesajController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Mesajınız...",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: SizedBox(
                key: ValueKey("buton_${_yukleniyor}_${_gonderildi}"),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!_yukleniyor && !_gonderildi) ? _mesajGonder : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gonderildi ? Colors.green : Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Builder(
                    builder: (_) {
                      if (_yukleniyor) {
                        return SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      } else if (_gonderildi) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text("Gönderildi", style: TextStyle(fontSize: 16)),
                          ],
                        );
                      } else {
                        return Text("Gönder", style: TextStyle(fontSize: 16));
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mesajController.dispose();
    super.dispose();
  }
}