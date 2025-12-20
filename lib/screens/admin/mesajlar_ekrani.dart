import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/analytics_helper.dart';

class MesajlarEkrani extends StatefulWidget {
  const MesajlarEkrani({super.key});
  
  @override
  State<MesajlarEkrani> createState() => _MesajlarEkraniState();
}

class _MesajlarEkraniState extends State<MesajlarEkrani> {
  final String adminUID = 'yicHOHSjaPXH6sLwyc48ulCnai32';
  final String mevzuatUzmaniUID = 'jBEoEbfgjJUHklmfmrJqsrIBETF2';
  
  final List<String> adminUIDs = [
    'yicHOHSjaPXH6sLwyc48ulCnai32',
    'jBEoEbfgjJUHklmfmrJqsrIBETF2',
  ];
  
  final Map<String, String> adminNames = {
    'yicHOHSjaPXH6sLwyc48ulCnai32': 'Admin',
    'jBEoEbfgjJUHklmfmrJqsrIBETF2': 'Mevzuat Uzmanı',
  };

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('mesajlar_ekrani_opened');
  }

  bool _isAdmin(User? user) {
    if (user == null) return false;
    return adminUIDs.contains(user.uid);
  }

  String _getAdminName(String uid) {
    return adminNames[uid] ?? 'Admin';
  }

  Future<void> _cevapGonder(String messageId, String cevap, BuildContext context) async {
    if (cevap.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cevap yazmalısınız.")),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !_isAdmin(currentUser)) return;

    try {
      final messageRef = _firestore.collection('messages').doc(messageId);
      final messageDoc = await messageRef.get();
      
      if (!messageDoc.exists) return;

      final messageData = messageDoc.data()!;
      final existingResponses = messageData['responses'] as List<dynamic>? ?? [];
      
      final newResponse = {
        'text': cevap.trim(),
        'timestamp': Timestamp.now(),
        'adminUID': currentUser.uid,
        'adminName': _getAdminName(currentUser.uid),
      };

      final updatedResponses = List<dynamic>.from(existingResponses)..add(newResponse);

      await messageRef.update({
        'responses': updatedResponses,
        'read': false,
        // Backward compatibility: Eğer eski response field'ı varsa, ilk response'u oraya da kopyala
        'response': updatedResponses.isNotEmpty ? (updatedResponses.first as Map)['text'] : null,
        'responseTimestamp': updatedResponses.isNotEmpty ? (updatedResponses.first as Map)['timestamp'] : null,
        'adminName': _getAdminName(currentUser.uid),
      });

      AnalyticsHelper.logCustomEvent('admin_reply_sent');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cevap gönderildi.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cevap gönderilirken bir hata oluştu.")),
      );
    }
  }

  Future<void> _mesajlariOkunduIsaretle(List<QueryDocumentSnapshot> messages) async {
    try {
      final batch = _firestore.batch();
      for (var doc in messages) {
        final data = doc.data() as Map<String, dynamic>;
        final read = data['read'] as bool? ?? false;
        if (!read) {
          batch.update(doc.reference, {'read': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Mesaj okundu işaretleme hatası: $e');
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
        AnalyticsHelper.logCustomEvent('admin_message_deleted');
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

  void _showThreadDetail(String email, List<QueryDocumentSnapshot> messages) {
    final cevapController = TextEditingController();
    
    // Mesaj detayı açıldığında okunmamış mesajları okundu işaretle
    _mesajlariOkunduIsaretle(messages);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mesajları sırala: eskiden yeniye
                      ...(() {
                        final sortedMessages = List<QueryDocumentSnapshot>.from(messages);
                        sortedMessages.sort((a, b) {
                          final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          if (aTime == null && bTime == null) return 0;
                          if (aTime == null) return 1;
                          if (bTime == null) return -1;
                          return aTime.compareTo(bTime); // Eskiden yeniye
                        });
                        return sortedMessages;
                      }()).map((mesaj) {
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kullanıcı mesajı
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
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
                                ],
                              ),
                            ),
                            // Admin cevapları
                            if (allResponses.isNotEmpty)
                              ...allResponses.map((r) {
                                final rText = r['text'] as String? ?? '';
                                final rTime = (r['timestamp'] as Timestamp?)?.toDate();
                                final rAdmin = r['adminName'] as String? ?? 'Admin';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12, left: 32),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                                  SizedBox(width: 8),
                                                  if (rTime != null)
                                                    Text(
                                                      "${rTime.day}.${rTime.month}.${rTime.year} ${rTime.hour}:${rTime.minute.toString().padLeft(2, '0')}",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            SizedBox(height: 16),
                            Divider(),
                            SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cevapController,
                      maxLines: null,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: "Cevap yazın...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (messages.isNotEmpty) {
                            _cevapGonder(messages.first.id, cevapController.text, context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("Gönder"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || !_isAdmin(currentUser)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Erişim Reddedildi",
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
                Colors.indigo.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Erişim Reddedildi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bu ekrana erişiminiz yok.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gelen Mesajlar",
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
              Colors.indigo.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('messages').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        "Hata oluştu",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Henüz Mesaj Yok',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gelen mesajlar burada görünecek',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Group by email
            final Map<String, List<QueryDocumentSnapshot>> grouped = {};
            for (var doc in docs) {
              final email = doc['email'] as String? ?? "Bilinmiyor";
              grouped.putIfAbsent(email, () => []).add(doc);
            }

            final sortedEmails = grouped.keys.toList()..sort();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sortedEmails.length,
              itemBuilder: (context, index) {
                final email = sortedEmails[index];
                final messages = grouped[email]!;
                
                // En son mesajı al
                messages.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime); // Yeniye göre sırala (en son mesaj için)
                });
                
                final lastMessage = messages.first;
                final lastMessageData = lastMessage.data() as Map<String, dynamic>;
                final lastIcerik = lastMessageData['message'] ?? "";
                final lastZaman = (lastMessageData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                final hasResponse = (lastMessageData['response'] != null && (lastMessageData['response'] as String).isNotEmpty) ||
                    (lastMessageData['responses'] != null && (lastMessageData['responses'] as List).isNotEmpty);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showThreadDetail(email, messages),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.indigo,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  ),
                                ),
                              ),
                              if (hasResponse)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Cevaplandı",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                ),
                              ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _mesajSil(lastMessage.id),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                            lastIcerik.length > 100 ? "${lastIcerik.substring(0, 100)}..." : lastIcerik,
                          style: TextStyle(
                              fontSize: 14,
                            color: Colors.grey[800],
                              height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                                "${lastZaman.day}.${lastZaman.month}.${lastZaman.year} ${lastZaman.hour}:${lastZaman.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                              if (messages.length > 1) ...[
                                SizedBox(width: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${messages.length} mesaj",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                          ],
                        ),
                      ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
