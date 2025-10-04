import 'package:flutter/material.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
    List<Widget> children = [];

    for (int i = 0; i < widget.makale.paragraphs.length; i++) {
      final paragraph = widget.makale.paragraphs[i];
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
    }
    return children;
  }
}