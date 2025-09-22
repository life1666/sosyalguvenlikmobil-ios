import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MesajlarEkrani extends StatelessWidget {
  final String adminUID = 'yicHOHSjaPXH6sLwyc48ulCnai32'; // 🔐 Kendi UID’ini buraya ekle

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.uid != adminUID) {
      return Scaffold(
        appBar: AppBar(title: Text("Erişim Reddedildi")),
        body: Center(child: Text("Bu ekrana erişiminiz yok.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Gelen Mesajlar")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Hata oluştu"));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text("Hiç mesaj yok"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final mesaj = docs[index];
              final email = mesaj['email'] ?? "Bilinmiyor";
              final icerik = mesaj['message'] ?? "";
              final zaman = (mesaj['timestamp'] as Timestamp).toDate();

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(email),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(icerik),
                      SizedBox(height: 6),
                      Text(
                        "${zaman.day}.${zaman.month}.${zaman.year} ${zaman.hour}:${zaman.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await mesaj.reference.delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
