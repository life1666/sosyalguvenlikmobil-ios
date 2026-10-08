import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_design.dart';

/// New in-app messages are paused; older conversations remain readable.
class IletisimEkrani extends StatelessWidget {
  const IletisimEkrani({super.key});

  static const _email = 'Sosyalguvenlikcepte@gmail.com';

  Future<void> _emailGonder(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _email);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('E-posta uygulaması açılamadı. Adresi kopyalayabilirsiniz.'),
      ));
    }
  }

  Future<void> _adresiKopyala(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('E-posta adresi kopyalandı.'),
      ));
    }
  }

  String _date(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate().toLocal();
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _notice(BuildContext context) => AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.mark_email_read_outlined,
                color: Theme.of(context).primaryColor, size: 25),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Uygulama içi mesajlar geçici olarak kapalı',
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            'Bilgi almak veya bize ulaşmak için $_email adresine e-posta gönderebilirsiniz.',
            style: TextStyle(color: AppDesign.activeMuted, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text('Bu adres resmi SGK iletişim kanalı değildir.',
              style: TextStyle(color: AppDesign.activeMuted, fontSize: 12)),
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              onPressed: () => _emailGonder(context),
              icon: const Icon(Icons.mail_outline_rounded, size: 19),
              label: const Text('E-posta gönder'),
            ),
            TextButton.icon(
              onPressed: () => _adresiKopyala(context),
              icon: const Icon(Icons.copy_rounded, size: 17),
              label: const Text('Adresi kopyala'),
            ),
          ]),
        ]),
      );

  Widget _history(String uid) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Eski mesajlar şu anda yüklenemiyor.',
                style: TextStyle(color: AppDesign.activeMuted));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ));
          }
          final docs = [...snapshot.data!.docs]..sort((a, b) {
              final aTime = (a.data()['timestamp'] as Timestamp?)
                      ?.millisecondsSinceEpoch ??
                  0;
              final bTime = (b.data()['timestamp'] as Timestamp?)
                      ?.millisecondsSinceEpoch ??
                  0;
              return bTime.compareTo(aTime);
            });
          if (docs.isEmpty) {
            return Text('Henüz geçmiş mesajınız yok.',
                style: TextStyle(color: AppDesign.activeMuted));
          }
          return Column(children: [
            for (final doc in docs) ...[
              _messageCard(context, doc.data()),
              const SizedBox(height: 10),
            ],
          ]);
        },
      );

  Widget _messageCard(BuildContext context, Map<String, dynamic> data) {
    final replies = <Map<String, dynamic>>[];
    final first = data['response'];
    if (first is String && first.trim().isNotEmpty) {
      replies.add({
        'text': first,
        'timestamp': data['responseTimestamp'],
        'adminName': data['adminName'],
      });
    }
    final additional = data['responses'];
    if (additional is List) {
      for (final reply in additional) {
        if (reply is Map) {
          replies.add(Map<String, dynamic>.from(reply));
        }
      }
    }
    replies.sort((a, b) {
      final aTime = (a['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final bTime = (b['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return aTime.compareTo(bTime);
    });
    return AppSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${data['message'] ?? ''}',
            style: TextStyle(color: AppDesign.activeInk, height: 1.45)),
        const SizedBox(height: 6),
        Text(_date(data['timestamp'] as Timestamp?),
            style: TextStyle(color: AppDesign.activeMuted, fontSize: 11)),
        for (final reply in replies) ...[
          const SizedBox(height: 14),
          Divider(color: AppDesign.activeBorder, height: 1),
          const SizedBox(height: 10),
          Text('${reply['adminName'] ?? 'Yanıt'}',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${reply['text'] ?? ''}',
              style: TextStyle(color: AppDesign.activeInk, height: 1.45)),
          const SizedBox(height: 4),
          Text(_date(reply['timestamp'] as Timestamp?),
              style: TextStyle(color: AppDesign.activeMuted, fontSize: 11)),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.activeBackground,
      appBar: AppDesign.appBar('İletişim'),
      body: SafeArea(
        child: AppContent(
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            initialData: FirebaseAuth.instance.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _notice(context),
                  if (user != null) ...[
                    const SizedBox(height: 26),
                    Text('Geçmiş mesajlarınız',
                        style: TextStyle(
                            color: AppDesign.activeInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _history(user.uid),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
