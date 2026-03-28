import 'package:flutter/material.dart';

import 'akisi_modelleri.dart';
import 'akisi_renkleri.dart';

/// Adım 1: Çalışan veya işveren seçimi.
class ProfilTipiSecimEkrani extends StatelessWidget {
  final void Function(AkisiProfilTipi tip) onProfilSecildi;

  const ProfilTipiSecimEkrani({
    super.key,
    required this.onProfilSecildi,
  });

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
          decoration: BoxDecoration(
            color: AkisiRenkleri.navy.withOpacity(0.85),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🛡️', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sosyal Güvenlik Mobil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sana en uygun deneyimi hazırlayabilmemiz için profilini seç.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade100,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _kart(
                      title: 'Çalışan',
                      desc:
                          'Emeklilik, kıdem ve hak takibi yapmak isteyenler için.',
                      icon: Icons.person_rounded,
                      color: AkisiRenkleri.green,
                      onTap: () =>
                          onProfilSecildi(AkisiProfilTipi.calisan),
                    ),
                    const SizedBox(height: 12),
                    _kart(
                      title: 'İşveren / İK',
                      desc:
                          'Bordro maliyeti ve yasal uyum takibi yapmak isteyenler için.',
                      icon: Icons.business_center_rounded,
                      color: AkisiRenkleri.blue500,
                      onTap: () =>
                          onProfilSecildi(AkisiProfilTipi.isveren),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Güvenli · Şeffaf · Yasal Bilgi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _kart({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border(left: BorderSide(color: color, width: 10)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AkisiRenkleri.slate50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AkisiRenkleri.slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AkisiRenkleri.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AkisiRenkleri.slate300, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
