import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ✅ Makale model sınıfı
class Makale {
  final String title;
  final String content;
  final String emoji;
  final List<String> paragraphs;

  Makale({
    required this.title,
    required this.content,
    required this.emoji,
    List<String>? paragraphs,
  }) : paragraphs = paragraphs ?? _splitIntoParagraphs(content);

  static List<String> _splitIntoParagraphs(String content) {
    return content
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }
}

// ✅ Makale detay sayfası
class MakaleDetailScreen extends StatefulWidget {
  final Makale makale;

  const MakaleDetailScreen({required this.makale, super.key});

  @override
  State<MakaleDetailScreen> createState() => _MakaleDetailScreenState();
}

class _MakaleDetailScreenState extends State<MakaleDetailScreen> {
  final List<BannerAd> _bannerAds = [];
  final List<bool> _isAdLoadedList = [];

  @override
  void initState() {
    super.initState();
    _loadBannerAds();
  }

  void _loadBannerAds() {
    // Sadece bir reklam oluştur
    int adCount = 1; // Sabit olarak 1 reklam

    for (int i = 0; i < adCount; i++) {
      BannerAd bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-6005798972779145/9282710600', // Test ID
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            setState(() {
              _isAdLoadedList[i] = true;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            ad.dispose();
            print('Banner reklam $i yüklenemedi: $error');
          },
        ),
      )..load();
      _bannerAds.add(bannerAd);
      _isAdLoadedList.add(false);
    }
  }

  @override
  void dispose() {
    for (var ad in _bannerAds) {
      ad.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.makale.title),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      widget.makale.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildParagraphsWithAds(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildParagraphsWithAds() {
    List<Widget> children = [];
    int normalParagraphCounter = 0;
    int adIndex = 0;

    for (int i = 0; i < widget.makale.paragraphs.length; i++) {
      final paragraph = widget.makale.paragraphs[i];
      final isTitle = paragraph.length < 50 && (paragraph.startsWith(RegExp(r'\d+\.\s')) || paragraph.startsWith(RegExp(r'\d+\.\d+\s')));

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: isTitle
              ? Text(
            paragraph,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.left,
          )
              : RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: [
                const WidgetSpan(
                  child: SizedBox(width: 16.0),
                ),
                TextSpan(
                  text: paragraph,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (!isTitle) {
        normalParagraphCounter++;
        if (normalParagraphCounter == 3 && adIndex < _bannerAds.length) { // İlk reklam 3. normal paragraftan sonra
          children.add(
            _isAdLoadedList[adIndex]
                ? Container(
              alignment: Alignment.center,
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: AdWidget(ad: _bannerAds[adIndex]),
            )
                : Container(
              alignment: Alignment.center,
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: const Text(
                'Reklam yükleniyor...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
          children.add(const SizedBox(height: 16));
          adIndex++;
        }
      }
    }
    return children;
  }
}