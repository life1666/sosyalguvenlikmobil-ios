import 'package:flutter/material.dart';

import 'akisi_modelleri.dart';
import 'akisi_renkleri.dart';
import 'sosyal_giris_secim_ekrani.dart';

/// Adım 2: Takma ad / nasıl çağıralım.
class KullaniciAdiEkrani extends StatefulWidget {
  final AkisiProfilTipi profilTipi;
  final VoidCallback onGeri;

  const KullaniciAdiEkrani({
    super.key,
    required this.profilTipi,
    required this.onGeri,
  });

  @override
  State<KullaniciAdiEkrani> createState() => _KullaniciAdiEkraniState();
}

class _KullaniciAdiEkraniState extends State<KullaniciAdiEkrani> {
  final _controller = TextEditingController();
  bool _hata = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _devam(VoidCallback onBasarili) {
    if (_controller.text.trim().isEmpty) {
      setState(() => _hata = true);
      return;
    }
    setState(() => _hata = false);
    onBasarili();
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
          decoration: BoxDecoration(
            color: AkisiRenkleri.navy.withOpacity(0.85),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton.icon(
                    onPressed: widget.onGeri,
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
                    'Harika!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seni nasıl çağırmamızı istersin?',
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade100),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KULLANICI ADI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue.shade200,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          onChanged: (_) => setState(() => _hata = false),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Kullanıcı adınızı girin...',
                            hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.4)),
                            prefixIcon: Icon(Icons.person_rounded,
                                color: Colors.blue.shade300, size: 22),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _hata
                                    ? Colors.red
                                    : Colors.white.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _hata
                                    ? Colors.red
                                    : Colors.white.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _hata
                                    ? Colors.red
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        if (_hata)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Lütfen bir kullanıcı adı girin.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade300,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _devam(() {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => SosyalGirisSecimEkrani(
                                    profilTipi: widget.profilTipi,
                                    takmaAd: _controller.text.trim(),
                                  ),
                                ),
                              );
                            }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AkisiRenkleri.navy,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Devam Et',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w900)),
                                SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, size: 22),
                              ],
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
    );
  }
}
