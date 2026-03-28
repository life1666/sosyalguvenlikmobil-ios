import 'package:flutter/material.dart';

import 'akisi_renkleri.dart';

/// Tanıtım slaytları (sgk_app OnboardingScreen ile uyumlu içerik).
class OnboardingTanitimEkrani extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const OnboardingTanitimEkrani({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<OnboardingTanitimEkrani> createState() =>
      _OnboardingTanitimEkraniState();
}

class _OnboardingTanitimEkraniState extends State<OnboardingTanitimEkrani> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  static const List<Map<String, dynamic>> _slides = [
    {
      'title': 'Yapay Zeka Destekli Rehberiniz',
      'description':
          'Hak AI, Türkiye iş hukuku ve SGK mevzuatı hakkındaki sorularınıza hızlı yanıt sunar.',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFF2563EB),
      'image':
          'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?auto=format&fit=crop&q=80&w=800',
    },
    {
      'title': 'Çalışanlar İçin: Haklarını Bil!',
      'description':
          'Kıdem, ihbar ve emeklilik planlaması gibi hesaplamalar ve hak takibi.',
      'icon': Icons.calculate_rounded,
      'color': Color(0xFF16A34A),
      'image':
          'https://images.unsplash.com/photo-1505664194779-8beaceb93744?auto=format&fit=crop&q=80&w=800',
    },
    {
      'title': 'İşverenler İçin: Maliyeti Yönet!',
      'description':
          'Bordro maliyeti, SGK ve yasal takvim hatırlatmaları için araçlar.',
      'icon': Icons.business_center_rounded,
      'color': Color(0xFF4F46E5),
      'image':
          'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&q=80&w=800',
    },
    {
      'title': 'Güvenli Bir Topluluk',
      'description':
          'Deneyim paylaşımı ve güvenli bilgi ortamı için topluluk alanı.',
      'icon': Icons.verified_user_rounded,
      'color': Color(0xFFD97706),
      'image':
          'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=800',
    },
    {
      'title': 'Kazanırken Öğrenin',
      'description':
          'Uygulamayı kullandıkça rozetler ve seviyelerle ilerleyin.',
      'icon': Icons.emoji_events_rounded,
      'color': Color(0xFF7C3AED),
      'image':
          'https://images.unsplash.com/photo-1569091791842-7cfb64e04797?auto=format&fit=crop&q=80&w=800',
    },
  ];

  void _next() {
    if (_currentSlide < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentSlide++);
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentSlide = i),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final s = _slides[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final contentHeight =
                          (constraints.maxHeight - 8).clamp(200.0, double.infinity);
                      return SizedBox(
                        height: contentHeight,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height:
                                    (contentHeight * 0.42).clamp(140.0, 280.0),
                                width: double.infinity,
                                child: Image.network(
                                  s['image'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: (s['color'] as Color).withOpacity(0.3),
                                    child: Icon(
                                      s['icon'] as IconData,
                                      size: 80,
                                      color: s['color'] as Color,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                          border: Border.all(
                                              color: AkisiRenkleri.slate100),
                                        ),
                                        child: Icon(
                                          s['icon'] as IconData,
                                          size: 32,
                                          color: s['color'] as Color,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        s['title'] as String,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AkisiRenkleri.slate800,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        s['description'] as String,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AkisiRenkleri.slate500,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: _currentSlide == i ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentSlide == i
                              ? AkisiRenkleri.navy
                              : AkisiRenkleri.slate200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AkisiRenkleri.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentSlide == _slides.length - 1
                                ? 'Hemen Başla'
                                : 'Devam Et',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onSkip,
                    child: const Text(
                      'Tanıtımı Geç',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AkisiRenkleri.slate400,
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
  }
}
