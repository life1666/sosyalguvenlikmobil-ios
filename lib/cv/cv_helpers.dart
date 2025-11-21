// lib/cv/cv_helpers.dart
import 'package:flutter/material.dart';
import 'cv_olustur.dart' show CvData, AppW;

/// Her şablonun imzası
typedef CvTemplateBuilder = Widget Function(BuildContext context, CvData cv);

/// Dışarıdan sadece bu sınıfı kullanacaksın.
class CvTemplates {
  /// Kullanıcıya göstereceğin isimler
  static const List<String> names = [
    'Nexus Pro',
    'Crystal Clear',
    'Crimson Edge',
    'Azure Dream',
    'Midnight Code',
    'Sapphire Line',
    'Violet Elegance',
    'Platinum Executive',
    'Amethyst Sidebar',
    'Navy Command',
    'Scholarly Blue',
    'Portrait Focus',
    'Chronos Timeline',
    'Quantum Blocks',
    'Dual Stream',
    'Monochrome Classic',
    'Prism Edge',
    'Rose Creative',
    'Golden Executive',
    'Compact Elite',
  ];

  /// Önizlemede çağıracağımız fonksiyon listesi
  /// NOT: Bu liste cv_sablon.dart'tan import edilecek
  static List<CvTemplateBuilder> all = [];
}

Widget buildTemplatePreview(BuildContext context, CvData cv, int index) {
  return _TemplatePreviewScope(
    preview: true,
    child: _TemplatePreviewFrame(
      builder: (ctx) => CvTemplates.all[index](ctx, cv),
    ),
  );
}

Widget buildTemplateThumbnail(BuildContext context, CvData cv, int index) {
  return _TemplatePreviewScope(
    preview: true,
    child: _TemplateThumbnailFrame(
      builder: (ctx) => CvTemplates.all[index](ctx, cv),
    ),
  );
}

/// PDF oluşturma için - padding olmadan direkt render
Widget buildTemplateForPdf(BuildContext context, CvData cv, int index) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaleFactor: 1.0, // PDF için normal boyut kullan
    ),
    child: Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.black,
          decoration: TextDecoration.none, // Sarı çizgileri kaldır
        ),
        child: _TemplatePreviewScope(
          preview: false, // PDF modu
          child: CvTemplates.all[index](context, cv),
        ),
      ),
    ),
  );
}

const double _kA4Width = 780.0;
const double _kA4Height = 1104.0;

class _TemplatePreviewScope extends InheritedWidget {
  final bool preview;
  const _TemplatePreviewScope({required this.preview, required super.child});

  static bool of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_TemplatePreviewScope>();
    return scope?.preview ?? false;
  }

  @override
  bool updateShouldNotify(_TemplatePreviewScope oldWidget) =>
      preview != oldWidget.preview;
}

/// Preview modunu kontrol etmek için helper fonksiyon
bool isPreviewMode(BuildContext context) {
  return _TemplatePreviewScope.of(context);
}

class _TemplatePreviewFrame extends StatelessWidget {
  final WidgetBuilder builder;
  const _TemplatePreviewFrame({required this.builder});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AspectRatio(
          aspectRatio: _kA4Width / _kA4Height,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _kA4Width,
              height: _kA4Height,
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateThumbnailFrame extends StatelessWidget {
  final WidgetBuilder builder;
  const _TemplateThumbnailFrame({required this.builder});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 210 / 297,
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _kA4Width,
              height: _kA4Height,
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  ORTAK: A4 SHELL                                                            */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*  ORTAK: A4 SHELL - PDF UYUMLU VERSİYON                                      */
/* -------------------------------------------------------------------------- */

/// PDF ve ekran önizlemesi için A4 kabuğu
/// • Ekran önizlemesinde scrollable (SingleChildScrollView)
/// • PDF dışa aktarımında sabit boyut (595 × 842 pt) + overflow engelleme
class A4Shell extends StatelessWidget {
  final Widget child;
  final Color? bg;
  const A4Shell({super.key, required this.child, this.bg});

  // PDF için gerçek A4 ölçüleri (point)
  static const double _pdfWidth  = 595.0;   // A4 genişlik
  static const double _pdfHeight = 842.0;   // A4 yükseklik
  // PDF modunda padding yok - içerik tam sayfayı doldurmalı
  // Padding gerekiyorsa her şablon kendi padding'ini ekleyebilir

  @override
  Widget build(BuildContext context) {
    final preview = _TemplatePreviewScope.of(context);
    const previewPadding = EdgeInsets.fromLTRB(28, 28, 28, 32);
    const pdfPadding = EdgeInsets.fromLTRB(28, 28, 28, 32);

    // ------------------- PDF / Gerçek dışa aktarım -------------------
    if (!preview) {
      return Container(
        width: _pdfWidth,
        height: _pdfHeight,
        color: bg ?? Colors.white,
        padding: pdfPadding,
        child: child,
      );
    }

    // ------------------- Ekran önizlemesi -------------------
    // Sadece renk ve padding, boyutlandırma preview frame'de yapılıyor
    return Container(
      color: bg ?? Colors.white,
      padding: previewPadding,
      child: child,
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  ORTAK: BAŞLIK / BLOK YARDIMCILARI                                         */
/* -------------------------------------------------------------------------- */

Widget sectionTitle(BuildContext c, String text, {Color? color, double? fontSize}) {
  return Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: color ?? Colors.black,
        fontSize: fontSize ?? 14.5,
        decoration: TextDecoration.none, // Sarı çizgileri engelle
      ),
    ),
  );
}

Widget expList(BuildContext c, CvData cv, {Color? titleColor, Color? textColor}) {
  if (cv.experiences.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: cv.experiences.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${e.position} · ${e.company}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: titleColor ?? Colors.black87,
                fontSize: 12.5,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              '${e.start} — ${(e.isCurrent || e.end.isEmpty) ? "Güncel" : e.end}',
              style: TextStyle(
                color: textColor ?? Colors.black54,
                fontSize: 11.5,
                decoration: TextDecoration.none,
              ),
            ),
            if (e.desc.trim().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                e.desc,
                style: TextStyle(
                  color: textColor ?? Colors.black87,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ],
        ),
      );
    }).toList(),
  );
}

Widget eduList(BuildContext c, CvData cv, {Color? titleColor, Color? textColor}) {
  if (cv.educations.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: cv.educations.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.level.trim().isNotEmpty 
                  ? '${e.school} · ${e.level} · ${e.department}'
                  : '${e.school} · ${e.department}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: titleColor ?? Colors.black87,
                fontSize: 12.5,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              '${e.start} — ${e.end}',
              style: TextStyle(
                color: textColor ?? Colors.black54,
                fontSize: 11.5,
                decoration: TextDecoration.none,
              ),
            ),
            if (e.note.trim().isNotEmpty)
              Text(
                e.note,
                style: TextStyle(
                  color: textColor ?? Colors.black87,
                  fontSize: 11.5,
                  decoration: TextDecoration.none,
                ),
              ),
          ],
        ),
      );
    }).toList(),
  );
}

Widget skillWrap(BuildContext c, CvData cv, {Color? chipColor, Color? textColor, double? fontSize}) {
  if (cv.skills.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: cv.skills
        .map(
          (s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: chipColor ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [],
        ),
        child: Text(
          s,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize ?? 12.5,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    )
        .toList(),
  );
}

Widget langList(BuildContext c, CvData cv, {Color? textColor, double? fontSize}) {
  if (cv.languages.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: cv.languages
        .map((l) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '${l.name} — ${l.level}',
        style: TextStyle(
          color: textColor,
            fontSize: fontSize ?? 12,
          decoration: TextDecoration.none,
        ),
      ),
    ))
        .toList(),
  );
}

Widget contactBlock(BuildContext c, CvData cv,
    {Color? iconColor, Color? textColor, double? fontSize, double? iconSize}) {
  final tc = textColor ?? Colors.white;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (cv.email.trim().isNotEmpty)
        iconLine(Icons.mail_outline, cv.email, iconColor ?? Colors.white, tc, fontSize: fontSize, iconSize: iconSize),
      if (cv.phone.trim().isNotEmpty)
        iconLine(
            Icons.phone_outlined, cv.phone, iconColor ?? Colors.white, tc, fontSize: fontSize, iconSize: iconSize),
      if (cv.address.trim().isNotEmpty)
        iconLine(Icons.location_on_outlined, cv.address,
            iconColor ?? Colors.white, tc, fontSize: fontSize, iconSize: iconSize),
    ],
  );
}

Widget iconLine(IconData ic, String text, Color icColor, Color txColor, {double? fontSize, double? iconSize}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ic, size: iconSize ?? 14, color: icColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: txColor,
              height: 1.3,
              fontSize: fontSize ?? 11.5,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SkillMeterData {
  final String label;
  final double value;
  final String? levelLabel;

  const _SkillMeterData({
    required this.label,
    required this.value,
    this.levelLabel,
  });
}

const int _kSkillMeterDotCount = 5;
const double _kDefaultSkillLevel = 0.78;

double? _normalizeSkillLevel(String source) {
  final raw = source.trim();
  if (raw.isEmpty) return null;

  final normalized = raw.replaceAll(',', '.');

  final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(normalized);
  if (percentMatch != null) {
    final value = double.tryParse(percentMatch.group(1)!);
    if (value != null) {
      return (value.clamp(0, 100) / 100).toDouble();
    }
  }

  final fractionMatch =
      RegExp(r'(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)').firstMatch(normalized);
  if (fractionMatch != null) {
    final numerator = double.tryParse(fractionMatch.group(1)!);
    final denominator = double.tryParse(fractionMatch.group(2)!);
    if (numerator != null && denominator != null && denominator > 0) {
      return (numerator / denominator).clamp(0, 1).toDouble();
    }
  }

  final numeric = double.tryParse(normalized);
  if (numeric != null) {
    if (numeric > 5) {
      return (numeric.clamp(0, 100) / 100).toDouble();
    }
    return (numeric.clamp(0, 5) / 5).toDouble();
  }

  final lower = raw.toLowerCase();
  const keywordLevels = <String, double>{
    'başlangıç': 0.35,
    'temel': 0.35,
    'beginner': 0.35,
    'orta': 0.6,
    'intermediate': 0.6,
    'iyi': 0.7,
    'good': 0.7,
    'ileri': 0.85,
    'advanced': 0.85,
    'çok iyi': 0.9,
    'expert': 1.0,
    'uzman': 1.0,
    'ana dil': 1.0,
    'native': 1.0,
  };
  for (final entry in keywordLevels.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

_SkillMeterData parseSkillMeter(String input) {
  var label = input.trim();
  if (label.isEmpty) {
    return const _SkillMeterData(label: 'Yetenek', value: _kDefaultSkillLevel);
  }

  double? value;
  String? levelLabel;

  void extract(String candidate) {
    final parsed = _normalizeSkillLevel(candidate);
    if (parsed != null) {
      value = parsed;
    } else if (candidate.trim().isNotEmpty && levelLabel == null) {
      levelLabel = candidate.trim();
    }
  }

  if (label.contains('|')) {
    final parts = label.split('|');
    if (parts.length >= 2) {
      final trailing = parts.removeLast();
      label = parts.join('|').trim();
      extract(trailing);
    }
  }

  final parenMatch = RegExp(r'\(([^)]*)\)\s*$').firstMatch(label);
  if (parenMatch != null) {
    extract(parenMatch.group(1)!);
    label = label.substring(0, parenMatch.start).trim();
  }

  final dashMatch = RegExp(r'(.*?)[\-–:]\s*([^-–:]*)$').firstMatch(label);
  if (dashMatch != null) {
    final trailing = dashMatch.group(2)!.trim();
    if (trailing.isNotEmpty && value == null && levelLabel == null) {
      extract(trailing);
      if (value != null || levelLabel != null) {
        label = dashMatch.group(1)!.trim();
      }
    }
  }

  if (value == null) {
    final numberMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*$').firstMatch(label);
    if (numberMatch != null) {
      extract(numberMatch.group(1)!);
      if (value != null) {
        label = label.substring(0, numberMatch.start).trim();
      }
    }
  }

  final normalizedValue = (value ?? _kDefaultSkillLevel).clamp(0.0, 1.0).toDouble();
  return _SkillMeterData(
    label: label.isEmpty ? input.trim() : label,
    value: normalizedValue,
    levelLabel: levelLabel,
  );
}

Widget skillMeterList(
  BuildContext c,
  CvData cv, {
  Color activeColor = Colors.black87,
  Color inactiveColor = const Color(0xFFDADFEA),
  TextStyle? labelStyle,
}) {
  if (cv.skills.isEmpty) return const SizedBox.shrink();
  final baseStyle = labelStyle ?? Theme.of(c).textTheme.bodyMedium!;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: cv.skills.map((raw) {
      final data = parseSkillMeter(raw);
      final scaled = data.value * _kSkillMeterDotCount;
      int filledDots = scaled.floor();
      if (scaled - filledDots >= 0.5) filledDots++;
      if (filledDots < 0) filledDots = 0;
      if (filledDots > _kSkillMeterDotCount) filledDots = _kSkillMeterDotCount;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    data.label,
                    style: baseStyle.copyWith(fontWeight: AppW.heading),
                  ),
                ),
                Row(
                  children: List.generate(_kSkillMeterDotCount, (index) {
                    final isFilled = index < filledDots;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? activeColor : inactiveColor,
                      ),
                    );
                  }),
                ),
              ],
            ),
            if (data.levelLabel != null && data.levelLabel!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data.levelLabel!,
                  style: Theme.of(c)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: (baseStyle.color ?? Colors.black87).withOpacity(0.7)),
                ),
              ),
          ],
        ),
      );
    }).toList(),
  );
}

Widget skillProgressList(
  BuildContext c,
  CvData cv, {
  Color barColor = Colors.black87,
  Color backgroundColor = const Color(0xFFE5E9FA),
  TextStyle? labelStyle,
  TextStyle? levelStyle,
}) {
  if (cv.skills.isEmpty) return const SizedBox.shrink();
  final theme = Theme.of(c);
  final baseStyle =
      labelStyle ?? theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600);
  final minorStyle =
      levelStyle ?? theme.textTheme.bodySmall!.copyWith(color: Colors.black54);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: cv.skills.map((raw) {
      final data = parseSkillMeter(raw);
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.label, style: baseStyle),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: data.value,
                minHeight: 6,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            if (data.levelLabel != null && data.levelLabel!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(data.levelLabel!, style: minorStyle),
              ),
          ],
        ),
      );
    }).toList(),
  );
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double gap;
  final double thickness;

  const _DottedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.gap,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    final centerY = size.height / 2;
    while (startX < size.width) {
      final endX = (startX + dashWidth).clamp(0.0, size.width).toDouble();
      canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), paint);
      startX += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.thickness != thickness;
  }
}

Widget dottedDivider({
  required Color color,
  double? width,
  double dashWidth = 6,
  double gap = 4,
  double thickness = 1,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final actualWidth = width ?? 
          (constraints.maxWidth.isFinite ? constraints.maxWidth : 600.0);
      return SizedBox(
        height: thickness,
        width: actualWidth,
        child: CustomPaint(
          size: Size(actualWidth, thickness),
          painter: _DottedLinePainter(
            color: color,
            dashWidth: dashWidth,
            gap: gap,
            thickness: thickness,
          ),
        ),
      );
    },
  );
}

List<Widget> buildExperienceEntries(
  BuildContext c,
  CvData cv, {
  Color? accent,
  Color? bulletColor,
}) {
  if (cv.experiences.isEmpty) return const <Widget>[];
  final accentColor = accent ?? const Color(0xFF5E35B1);
  final bullet = bulletColor ?? accentColor.withOpacity(0.85);

  return cv.experiences.map((e) {
    final period =
        '${e.start} — ${(e.isCurrent || e.end.isEmpty) ? "Güncel" : e.end}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(color: bullet, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.position,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  '${e.company} • $period',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (e.desc.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      e.desc,
                      style: const TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }).toList();
}

List<Widget> buildReferenceEntries(
  BuildContext c,
  CvData cv, {
  Color? bulletColor,
  bool showBullet = false,
  Color? textColor,
}) {
  if (cv.references.isEmpty) return const <Widget>[];
  final bullet = bulletColor ?? Colors.black26;

  return cv.references.map((r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBullet)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Text(
                '•',
                style: TextStyle(
                  color: bullet,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 12.5,
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (r.position.trim().isNotEmpty)
                  Text(
                    r.position,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textColor ?? Colors.black54,
                      decoration: TextDecoration.none,
                    ),
                  ),
                if (r.contact.trim().isNotEmpty)
                  Text(
                    r.contact,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textColor ?? Colors.black54,
                      decoration: TextDecoration.none,
                    ),
                  ),
                if (r.note.trim().isNotEmpty)
                  Text(
                    r.note,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textColor ?? Colors.black54,
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }).toList();
}

List<Widget> buildCertificateEntries(BuildContext c, CvData cv, {Color? textColor}) {
  if (cv.certificates.isEmpty) return const <Widget>[];
  return cv.certificates.map((cert) {
    final info = [cert.org, cert.year].where((el) => el.trim().isNotEmpty).join(' • ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cert.title,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12.5,
              color: textColor,
              decoration: TextDecoration.none,
            ),
          ),
          if (info.isNotEmpty)
            Text(
              info,
              style: TextStyle(
                fontSize: 11.5,
                color: textColor ?? Colors.black54,
                decoration: TextDecoration.none,
              ),
            ),
        ],
      ),
    );
  }).toList();
}

List<Widget> buildProjectEntries(BuildContext c, CvData cv, {Color? accent, Color? textColor}) {
  if (cv.projects.isEmpty) return const <Widget>[];
  final accentColor = accent ?? const Color(0xFF5E35B1);

  return cv.projects.map((p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.name,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: textColor ?? accentColor,
              fontSize: 12.5,
              decoration: TextDecoration.none,
            ),
          ),
          if (p.description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                p.description,
                style: TextStyle(
                  color: textColor ?? Colors.black87,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          if (p.link.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                p.link,
                  style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
        ],
      ),
    );
  }).toList();
}

Widget languageChipWrap(
  BuildContext c,
  CvData cv, {
  Color? bgColor,
  Color? textColor,
  Color? borderColor,
}) {
  if (cv.languages.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: cv.languages.map((lang) {
      final label =
          [lang.name, lang.level].where((el) => el.trim().isNotEmpty).join(' • ');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontSize: 11.5,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }).toList(),
  );
}

Widget hobbyChipWrap(
  BuildContext c,
  CvData cv, {
  Color? bgColor,
  Color? textColor,
  Color? borderColor,
}) {
  if (cv.hobbies.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: cv.hobbies.map((hobby) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Text(
          hobby,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontSize: 11.5,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }).toList(),
  );
}

List<Widget> buildLicenseEntries(BuildContext c, CvData cv) {
  if (cv.licenses.isEmpty) return const <Widget>[];
  return cv.licenses.map((license) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        license,
        style: const TextStyle(
          fontSize: 12,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }).toList();
}

List<Widget> buildVolunteeringEntries(BuildContext c, CvData cv, {Color? accent, Color? textColor}) {
  if (cv.volunteering.isEmpty) return const <Widget>[];
  final accentColor = accent ?? const Color(0xFF5E35B1);

  return cv.volunteering.map((v) {
    final period = [v.start, v.end].where((el) => el.trim().isNotEmpty).join(' — ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v.role,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor ?? accentColor,
              fontSize: 12.5,
              decoration: TextDecoration.none,
            ),
          ),
          if (v.organization.trim().isNotEmpty)
            Text(
              v.organization,
              style: TextStyle(
                color: textColor ?? Colors.black87,
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          if (period.isNotEmpty)
            Text(
              period,
              style: TextStyle(
                color: textColor ?? Colors.black54,
                fontSize: 11.5,
                decoration: TextDecoration.none,
              ),
            ),
          if (v.description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                v.description,
                style: TextStyle(
                  color: textColor ?? Colors.black54,
                  fontSize: 11.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
        ],
      ),
    );
  }).toList();
}

