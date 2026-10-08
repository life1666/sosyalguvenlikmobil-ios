import 'package:src/utils/app_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// --- Makale listeleri (aynı klasörde) ---
import 'calisan_makaleler.dart';
import 'emeklilik_makaleler.dart';
import 'isveren_makaleler.dart';
import '../utils/analytics_helper.dart';

/// =======================
///  MODEL
/// =======================
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

/// =======================
///  LİSTE + SEKME EKRANI
/// =======================
class MakalelerView extends StatefulWidget {
  const MakalelerView({super.key});

  @override
  State<MakalelerView> createState() => _MakalelerViewState();
}

class _MakalelerViewState extends State<MakalelerView> {
  String? _selectedKategori;

  final List<_MakaleKategori> _kategoriler = [
    _MakaleKategori(
      baslik: 'Çalışan',
      liste: calisanMakaleler,
    ),
    _MakaleKategori(
      baslik: 'Emeklilik',
      liste: emeklilikMakaleler,
    ),
    _MakaleKategori(
      baslik: 'İşveren',
      liste: isverenMakaleler,
    ),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('makaleler_opened');
    _selectedKategori = _kategoriler[0].baslik; // İlk kategoriyi seçili yap
  }

  _MakaleKategori? get _aktifKategori {
    return _kategoriler.firstWhere(
      (k) => k.baslik == _selectedKategori,
      orElse: () => _kategoriler[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppMenuBar(
        title: Text(
          'Makaleler',
          style: TextStyle(color: AppDesign.activeInk, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppDesign.activeInk),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          // Cupertino Segmented Control
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _selectedKategori,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.06),
              thumbColor: AppDesign.activeSurface,
              children: {
                for (final k in _kategoriler)
                  k.baslik: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      '${k.baslik} (${k.liste.length})',
                      style: TextStyle(
                        color: _selectedKategori == k.baslik ? Theme.of(context).primaryColor : AppDesign.activeInk,
                        fontWeight: _selectedKategori == k.baslik ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
              },
              onValueChanged: (value) {
                setState(() {
                  _selectedKategori = value;
                });
              },
            ),
          ),
          const Divider(height: 1, color: Color(0x1F000000)),
          // İÇERİK
          Expanded(
            child: _aktifKategori != null
                ? _MakaleListe(kategori: _aktifKategori!, tt: tt)
                : const Center(child: Text('Kategori seçiniz')),
          ),
        ],
      ),
    );
  }
}

class _MakaleKategori {
  final String baslik;
  final List<Makale> liste;
  _MakaleKategori({
    required this.baslik,
    required this.liste,
  });
}

/// =======================
///  SADE LİSTE (hesaplamalar ekranı gibi)
/// =======================
class _MakaleListe extends StatelessWidget {
  final _MakaleKategori kategori;
  final TextTheme tt;
  const _MakaleListe({required this.kategori, required this.tt});

  @override
  Widget build(BuildContext context) {
    if (kategori.liste.isEmpty) {
      return const Center(child: Text('Bu kategoride henüz içerik yok.'));
    }

    return AppContent(child: ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: kategori.liste.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => AppSurface(padding: EdgeInsets.zero,
        child: AppActionTile(title: kategori.liste[i].title, icon: Icons.article_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MakaleDetailScreen(makale: kategori.liste[i])))),
      ),
    ));
  }
}
class MakaleDetailScreen extends StatefulWidget {
  final Makale makale;

  const MakaleDetailScreen({required this.makale, super.key});

  @override
  State<MakaleDetailScreen> createState() => _MakaleDetailScreenState();
}

class _MakaleDetailScreenState extends State<MakaleDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMenuBar(
        title: Text(
          widget.makale.title,
          style: TextStyle(color: AppDesign.activeInk, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppDesign.activeInk),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlığı sayfa içinde tekrar göstermeyelim; AppBar’da var.
                  ..._buildParagraphs(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildParagraphs() {
    final List<Widget> children = [];
    for (final paragraph in widget.makale.paragraphs) {
      final isTitle = paragraph.length < 50 &&
          (paragraph.startsWith(RegExp(r'\d+\.\s')) ||
              paragraph.startsWith(RegExp(r'\d+\.\d+\s')));

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: isTitle
              ? Text(
            paragraph,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          )
              : RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: [
                const WidgetSpan(child: SizedBox(width: 16.0)),
                TextSpan(
                  text: paragraph,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return children;
  }
}
