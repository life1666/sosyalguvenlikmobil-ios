import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../makaleler/calisan_makaleler.dart';
import '../makaleler/emeklilik_makaleler.dart';
import '../makaleler/isveren_makaleler.dart';
import '../makaleler/makale.dart';
import '../hesaplamalar/brutten_nete.dart';
import '../hesaplamalar/asgari_iscilik.dart';
import '../hesaplamalar/rapor_parasi.dart';
import '../hesaplamalar/askerlik_dogum.dart';
import '../hesaplamalar/yurtdisi_borclanma.dart';
import '../hesaplamalar/issizlik_sorguhesap.dart';
import '../hesaplamalar/kidem_alabilir.dart';
import '../hesaplamalar/kidem_hesap.dart';
import '../hesaplamalar/netten_brute.dart';
import '../hesaplamalar/yillik_izin.dart';
import '../hesaplamalar/4a_hesapla.dart';
import '../hesaplamalar/4b_hesapla.dart';
import '../hesaplamalar/4c_hesapla.dart';

class BilgiKategorileriEkrani extends StatelessWidget {
  final String category;

  const BilgiKategorileriEkrani({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController _scrollController = ScrollController();

    final scrollbarTheme = ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(Colors.indigo),
      trackColor: MaterialStateProperty.all(Colors.indigo.shade100),
      trackBorderColor: MaterialStateProperty.all(Colors.indigo.shade100),
    );

    switch (category) {
      case 'ANASAYFA':
        return ScrollbarTheme(
          data: scrollbarTheme,
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              children: [
                CustomButton(
                  text: "NE ZAMAN EMEKLİ OLABİLİRİM?",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AltMenuEkrani(
                          title: "Ne Zaman Emekli Olabilirim?",
                          altMenuler: [
                            AltMenuItem(
                              title: "4a (SSK) Sorgulama",
                              icon: Icons.calendar_today,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EmeklilikHesaplamaSayfasi()),
                                );
                              },
                            ),
                            AltMenuItem(
                              title: "4b (Bağkur) Sorgulama",
                              icon: Icons.calendar_today,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EmeklilikHesaplama4bSayfasi()),
                                );
                              },
                            ),
                            AltMenuItem(
                              title: "4c (Memur) Sorgulama",
                              icon: Icons.calendar_today,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EmeklilikHesaplama4cSayfasi()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                CustomButton(
                  text: "KIDEM-İHBAR TAZMİNATI İŞLEMLERİ",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AltMenuEkrani(
                          title: "Kıdem-İhbar Tazminatı İşlemleri",
                          altMenuler: [
                            AltMenuItem(
                              title: "Kıdem-İhbar Tazminatı Hesaplama",
                              icon: Icons.calculate,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CompensationCalculatorScreen(),
                                  ),
                                );
                              },
                            ),
                            AltMenuItem(
                              title: "SGK'dan Kıdem Tazminatı Alabilir Yazısı Sorgulama",
                              icon: Icons.info_outline,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const KidemAlabilirScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                CustomButton(
                  text: "İŞSİZLİK MAAŞI İŞLEMLERİ",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AltMenuEkrani(
                          title: "İşsizlik Maaşı İşlemleri",
                          altMenuler: [
                            AltMenuItem(
                              title: "İşsizlik Maaşı Sorgulama ve Hesaplama",
                              icon: Icons.search,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const IsizlikMaasiScreen(),
                                  ),
                                );
                              },
                            ),
                            AltMenuItem(
                              title: "İşsizlik Maaşı Başvurusu",
                              icon: Icons.app_registration,
                              onTap: _acIssizlikBasvuru,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                CustomButton(
                  text: "SGK PRİM BORÇLANMA TUTARI HESAPLAMA",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AltMenuEkrani(
                          title: "SGK Prim Borçlanma Tutarı Hesaplama",
                          altMenuler: [
                            AltMenuItem(
                              title: "Askerlik, Doğum ve Diğer Borçlanma Tutarı Hesaplama",
                              icon: Icons.calculate,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BorclanmaHesaplamaScreen(),
                                  ),
                                );
                              },
                            ),
                            AltMenuItem(
                              title: "Yurt Dışı Borçlanma Hesaplama",
                              icon: Icons.language,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const YurtDisiBorclanmaHesaplamaScreen(),
                                  ),
                                );
                              },
                            ),
                            AltMenuItem(
                              title: "Borçlanma Başvurusu",
                              icon: Icons.app_registration,
                              onTap: _acBorclanmaBasvuru,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                CustomButton(
                  text: "RAPOR PARASI HESAPLAMA",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RaporParasiScreen()),
                    );
                  },
                ),
                CustomButton(
                  text: "BRÜTTEN NETE MAAŞ HESAPLAMA",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SalaryCalculatorScreen()),
                    );
                  },
                ),
                CustomButton(
                  text: "NETTEN BRÜTE MAAŞ HESAPLAMA",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NettenBruteScreen()),
                    );
                  },
                ),
                CustomButton(
                  text: "ASGARİ İŞÇİLİK HESAPLAMA",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HesaplamaSayfasi()),
                    );
                  },
                ),
                CustomButton(
                  text: "YILLIK İZİN SÜRESİ HESAPLAMA",
                  icon: Icons.remove,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const YillikUcretliIzinSayfasi()),
                    );
                  },
                ),
              ],
            ),
          ),
        );

      case 'ÇALIŞAN':
        return ScrollbarTheme(
          data: scrollbarTheme,
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              children: calisanMakaleler
                  .map((makale) => CustomButton(
                text: makale.title.toUpperCase(),
                icon: Icons.remove,
                subtitle: makale.paragraphs.isNotEmpty ? makale.paragraphs[0] : '',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MakaleDetailScreen(makale: makale),
                    ),
                  );
                },
              ))
                  .toList()
                  .cast<Widget>(),
            ),
          ),
        );

      case 'EMEKLİLİK':
        return ScrollbarTheme(
          data: scrollbarTheme,
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              children: emeklilikMakaleler
                  .map((makale) => CustomButton(
                text: makale.title.toUpperCase(),
                icon: Icons.remove,
                subtitle: makale.paragraphs.isNotEmpty ? makale.paragraphs[0] : '',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MakaleDetailScreen(makale: makale),
                    ),
                  );
                },
              ))
                  .toList()
                  .cast<Widget>(),
            ),
          ),
        );

      case 'İŞVEREN':
        return ScrollbarTheme(
          data: scrollbarTheme,
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              children: isverenMakaleler
                  .map((makale) => CustomButton(
                text: makale.title.toUpperCase(),
                icon: Icons.remove,
                subtitle: makale.paragraphs.isNotEmpty ? makale.paragraphs[0] : '',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MakaleDetailScreen(makale: makale),
                    ),
                  );
                },
              ))
                  .toList()
                  .cast<Widget>(),
            ),
          ),
        );

      default:
        return const Center(child: Text('BİLİNMEYEN KATEGORİ'));
    }
  }
}

class CustomButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final String? subtitle;
  final VoidCallback onPressed;

  const CustomButton({
    required this.text,
    required this.icon,
    this.subtitle,
    required this.onPressed,
    super.key,
  });

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isTapped = false;

  void _handleTap() {
    setState(() => _isTapped = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isTapped = false);
        widget.onPressed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isTapped ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.indigo),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold, // Kalın yazı tipi eklendi
                fontSize: 14,
              ),
            ),
            subtitle: widget.subtitle != null
                ? Text(
              widget.subtitle!.length > 100
                  ? '${widget.subtitle!.substring(0, 100)}...'
                  : widget.subtitle!,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.indigo, size: 18),
          ),
        ),
      ),
    );
  }
}

class AltMenuEkrani extends StatelessWidget {
  final String title;
  final List<AltMenuItem> altMenuler;

  const AltMenuEkrani({required this.title, required this.altMenuler, super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController _scrollController = ScrollController();

    final scrollbarTheme = ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(Colors.indigo),
      trackColor: MaterialStateProperty.all(Colors.indigo.shade100),
      trackBorderColor: MaterialStateProperty.all(Colors.indigo.shade100),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.indigo),
      body: ScrollbarTheme(
        data: scrollbarTheme,
        child: Scrollbar(
          controller: _scrollController,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: altMenuler.length,
            itemBuilder: (context, index) {
              final menu = altMenuler[index];
              return _AnimatedMenuItem(menu: menu);
            },
          ),
        ),
      ),
    );
  }
}

class _AnimatedMenuItem extends StatefulWidget {
  final AltMenuItem menu;

  const _AnimatedMenuItem({required this.menu});

  @override
  __AnimatedMenuItemState createState() => __AnimatedMenuItemState();
}

class __AnimatedMenuItemState extends State<_AnimatedMenuItem> {
  bool _isTapped = false;

  void _handleTap() {
    setState(() => _isTapped = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isTapped = false);
        widget.menu.onTap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isTapped ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.indigo),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(widget.menu.icon, color: Colors.indigo),
            title: Text(
              widget.menu.title,
              style: const TextStyle(color: Colors.indigo, fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.indigo),
          ),
        ),
      ),
    );
  }
}

class AltMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  AltMenuItem({required this.title, required this.icon, required this.onTap});
}

void _acIssizlikBasvuru() async {
  final Uri url = Uri.parse('https://www.turkiye.gov.tr/issizlik-odenegi-basvurusu');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    print("Link açılamadı: $url");
  }
}

void _acBorclanmaBasvuru() async {
  final Uri url = Uri.parse('https://www.turkiye.gov.tr/sosyal-guvenlik-kurumu');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    print("Link açılamadı: $url");
  }
}