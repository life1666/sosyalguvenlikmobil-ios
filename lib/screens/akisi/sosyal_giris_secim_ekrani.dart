import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'akisi_auth_yardimci.dart';
import 'akisi_durum.dart';
import 'akisi_modelleri.dart';
import 'akisi_renkleri.dart';
import 'eposta_giris_ekrani.dart';

/// Adım 3: Google / Apple / e-posta (sgk_app profil akışı 3. adım ile aynı düzen).
class SosyalGirisSecimEkrani extends StatelessWidget {
  final AkisiProfilTipi profilTipi;
  final String takmaAd;

  const SosyalGirisSecimEkrani({
    super.key,
    required this.profilTipi,
    required this.takmaAd,
  });

  Future<void> _uyeliksizDevam(BuildContext context) async {
    await AkisiDurum.tamamlaVeAnaEkranaGit(context, profilTipi, takmaAd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkisiRenkleri.navy,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                          ),
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: Colors.blue.shade200),
                          label: Text(
                            'Geri Dön',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade200,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Son Adım',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hesabını güvene almak için bir giriş yöntemi seç.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade100,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _girisButonu(
                                label: 'Google ile Devam Et',
                                bg: Colors.white,
                                fg: AkisiRenkleri.slate800,
                                onTap: () => AkisiAuthYardimci.googleIleGiris(
                                  context,
                                  profilTipi: profilTipi,
                                  takmaAd: takmaAd,
                                ),
                                iconWidget: const FaIcon(
                                  FontAwesomeIcons.google,
                                  size: 22,
                                  color: AkisiRenkleri.slate800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _girisButonu(
                                label: 'Apple ile Devam Et',
                                bg: Colors.black,
                                fg: Colors.white,
                                icon: Icons.apple_rounded,
                                onTap: () => AkisiAuthYardimci.appleIleGiris(
                                  context,
                                  profilTipi: profilTipi,
                                  takmaAd: takmaAd,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _girisButonu(
                                label: 'E-posta ile Devam Et',
                                bg: AkisiRenkleri.blue500,
                                fg: Colors.white,
                                icon: Icons.email_rounded,
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => EpostaGirisEkrani(
                                        profilTipi: profilTipi,
                                        takmaAd: takmaAd,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () => _uyeliksizDevam(context),
                                child: Text(
                                  'Kayıt olmadan devam et',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _girisButonu({
    required String label,
    required Color bg,
    required Color fg,
    IconData? icon,
    Widget? iconWidget,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ?? Icon(icon, size: 22),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
