import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/analytics_helper.dart';

class IletisimEkrani extends StatefulWidget {
  @override
  _IletisimEkraniState createState() => _IletisimEkraniState();
}

class _IletisimEkraniState extends State<IletisimEkrani> {
  final _mesajController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _yukleniyor = false;
  User? _currentUser;
  bool _sorumlulukKabulEdildi = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
    _sorumlulukDurumunuKontrolEt();
    _mesajController.addListener(() {
      setState(() {});
    });
    AnalyticsHelper.logScreenOpen('iletisim_ekrani_opened');
  }

  Future<void> _sorumlulukDurumunuKontrolEt() async {
    final prefs = await SharedPreferences.getInstance();
    final kabulEdildi = prefs.getBool('_sorumlulukKabulEdildi') ?? false;
    setState(() {
      _sorumlulukKabulEdildi = kabulEdildi;
    });
  }

  Future<void> _sorumlulukKabulEt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('_sorumlulukKabulEdildi', true);
    setState(() {
      _sorumlulukKabulEdildi = true;
    });
    AnalyticsHelper.logCustomEvent('disclaimer_accepted');
  }

  Future<void> _mesajGonder() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesaj göndermek için giriş yapmalısınız.")),
      );
      return;
    }

    if (!_sorumlulukKabulEdildi) {
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
      await _firestore.collection('messages').add({
        'userId': _currentUser!.uid,
        'email': _currentUser!.email,
        'message': _mesajController.text.trim(),
        'timestamp': Timestamp.now(),
        'read': false,
      });

      _mesajController.clear();

      setState(() {
        _yukleniyor = false;
      });

      AnalyticsHelper.logCustomEvent('message_sent');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mesajınız başarıyla gönderildi."),
          backgroundColor: Colors.green,
        ),
      );

      // Listeyi en alta kaydır
      if (_scrollController.hasClients) {
        Future.delayed(Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesaj gönderilirken bir hata oluştu.")),
      );
    }
  }

  Future<void> _mesajSil(String messageId) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mesajı Sil'),
        content: Text('Bu mesajı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await _firestore.collection('messages').doc(messageId).delete();
        AnalyticsHelper.logCustomEvent('message_deleted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mesaj silindi.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mesaj silinirken bir hata oluştu.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'İletişim',
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
      body: SafeArea(
        child: _currentUser == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        "Mesaj göndermek için giriş yapmalısınız.",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // Mesaj listesi
                  Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('messages')
                        .where('userId', isEqualTo: _currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 64, color: Colors.red),
                                SizedBox(height: 16),
                                Text(
                                  "Hata oluştu",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mail_outline, size: 80, color: Colors.grey[300]),
                                SizedBox(height: 16),
                                Text(
                                  "Henüz mesajınız yok",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Aşağıdaki alandan ilk mesajınızı gönderin",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Client-side sorting: eskiden yeniye
                      final sortedDocs = List.from(docs);
                      sortedDocs.sort((a, b) {
                        final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return aTime.compareTo(bTime);
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedDocs.length,
                        itemBuilder: (context, index) {
                          final mesaj = sortedDocs[index];
                          final mesajData = mesaj.data() as Map<String, dynamic>;
                          final icerik = mesajData['message'] ?? "";
                          final zaman = (mesajData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                          final response = mesajData['response'] as String?;
                          final responses = mesajData['responses'] as List<dynamic>?;

                          final allResponses = <Map<String, dynamic>>[];
                          if (response != null && response.isNotEmpty) {
                            allResponses.add({
                              'text': response,
                              'timestamp': mesajData['responseTimestamp'] as Timestamp?,
                              'adminName': mesajData['adminName'] as String? ?? 'Admin',
                            });
                          }
                          if (responses != null) {
                            for (var r in responses) {
                              if (r is Map<String, dynamic>) {
                                allResponses.add(r);
                              }
                            }
                          }
                          allResponses.sort((a, b) {
                            final aTime = a['timestamp'] as Timestamp?;
                            final bTime = b['timestamp'] as Timestamp?;
                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return aTime.compareTo(bTime);
                          });

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Kullanıcı mesajı (solda)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              icerik,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                                height: 1.4,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "${zaman.day}.${zaman.month}.${zaman.year} ${zaman.hour}:${zaman.minute.toString().padLeft(2, '0')}",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _mesajSil(mesaj.id),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ],
                                ),
                                // Admin cevapları (sağda)
                                if (allResponses.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  ...allResponses.map((r) {
                                    final rText = r['text'] as String? ?? '';
                                    final rTime = (r['timestamp'] as Timestamp?)?.toDate();
                                    final rAdmin = r['adminName'] as String? ?? 'Admin';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8, left: 40),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                                height: 1.4,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  rAdmin,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                                if (rTime != null) ...[
                                                  SizedBox(width: 8),
                                                  Text(
                                                    "${rTime.day}.${rTime.month}.${rTime.year} ${rTime.hour}:${rTime.minute.toString().padLeft(2, '0')}",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Mesaj gönderme alanı (sabit, altta)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: 50,
                            maxHeight: 120,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _sorumlulukKabulEdildi
                              ? TextField(
                                  controller: _mesajController,
                                  maxLines: null,
                                  minLines: 1,
                                  textInputAction: TextInputAction.newline,
                                  decoration: InputDecoration(
                                    hintText: "Mesajınızı yazın...",
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange[700],
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Bu uygulama resmi bir kurum (SGK, İşkur vs.) uygulaması değildir. Gönderdiğiniz mesajlar resmi bir kurum tarafından değil, uygulama geliştiricileri tarafından alınmaktadır.",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800],
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _sorumlulukKabulEt,
                                          icon: Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          label: Text(
                                            "Okudum, Anladım",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange[700],
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: (_sorumlulukKabulEdildi && _mesajController.text.trim().isNotEmpty && !_yukleniyor)
                              ? Colors.indigo
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: _yukleniyor
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          onPressed: (_sorumlulukKabulEdildi && _mesajController.text.trim().isNotEmpty && !_yukleniyor)
                              ? _mesajGonder
                              : null,
                          padding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
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
    _scrollController.dispose();
    super.dispose();
  }
}

