import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'premium_access_service.dart';

class PremiumAccessRequiredException implements Exception {}

class HesaplamaPdfService {
  static const _navy = PdfColor.fromInt(0xFF163A6B);
  static const _blue = PdfColor.fromInt(0xFF2563EB);
  static const _green = PdfColor.fromInt(0xFF16A34A);
  static const _light = PdfColor.fromInt(0xFFF3F6FA);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static final _date = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  static Future<void> shareSummary({
    required String title,
    required Map<String, String> details,
    String? highlightKey,
  }) async {
    await _requirePremium();
    final fonts = await _fonts();
    final document = pw.Document(
      title: '$title - Hesaplama Sonucu',
      author: 'İş & SGK Asistan',
      creator: 'İş & SGK Asistan',
    );
    final generatedAt = DateTime.now();
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(22, 18, 22, 18),
      theme: pw.ThemeData.withFont(base: fonts.$1, bold: fonts.$2),
      footer: _footer,
      build: (_) => [
        _header(title, 'Hesaplama Sonucu', generatedAt),
        pw.SizedBox(height: 10),
        if (highlightKey != null && details.containsKey(highlightKey)) ...[
          _highlight(highlightKey, details[highlightKey]!),
          pw.SizedBox(height: 8),
        ],
        _sectionTitle('Hesaplama ayrıntıları'),
        pw.SizedBox(height: 5),
        _detailGrid(details.entries
            .where((entry) => entry.key != highlightKey)
            .toList()),
        pw.SizedBox(height: 10),
        _disclaimer(),
      ],
    ));
    await _share(await document.save(), title);
  }

  static Future<void> shareTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String> summary = const {},
  }) async {
    await _requirePremium();
    final fonts = await _fonts();
    final document = pw.Document(
      title: '$title - Hesaplama Sonucu',
      author: 'İş & SGK Asistan',
      creator: 'İş & SGK Asistan',
    );
    final generatedAt = DateTime.now();
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
      theme: pw.ThemeData.withFont(base: fonts.$1, bold: fonts.$2),
      footer: _footer,
      build: (_) => [
        _header(title, '12 Aylık Hesaplama Sonucu', generatedAt),
        if (summary.isNotEmpty) ...[
          pw.SizedBox(height: 7),
          pw.Row(
            children: summary.entries
                .map((entry) => pw.Expanded(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.only(right: 4),
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 7, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: _light,
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(entry.key,
                                style: const pw.TextStyle(
                                    color: _muted, fontSize: 5.8)),
                            pw.SizedBox(height: 1.5),
                            pw.Text(entry.value,
                                style: pw.TextStyle(
                                    color: _navy,
                                    fontSize: 7.2,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
        pw.SizedBox(height: 7),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerDecoration: const pw.BoxDecoration(color: _navy),
          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 4.8,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(color: _navy, fontSize: 4.6),
          headerAlignment: pw.Alignment.center,
          cellAlignment: pw.Alignment.center,
          headerPadding:
              const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2.5),
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _border, width: .4),
            bottom: pw.BorderSide(color: _border, width: .6),
          ),
        ),
        pw.SizedBox(height: 8),
        _disclaimer(compact: true),
      ],
    ));
    await _share(await document.save(), title);
  }

  static Future<(pw.Font, pw.Font)> _fonts() async {
    final regularData =
        await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/OpenSans-Bold.ttf');
    return (pw.Font.ttf(regularData), pw.Font.ttf(boldData));
  }

  static Future<void> _requirePremium() async {
    final status = await PremiumAccessService().load();
    if (!status.hasPremium) {
      throw PremiumAccessRequiredException();
    }
  }

  static pw.Widget _header(
    String title,
    String subtitle,
    DateTime generatedAt,
  ) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: pw.BoxDecoration(
          color: _navy,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title,
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(subtitle,
                      style: const pw.TextStyle(
                          color: PdfColor.fromInt(0xFFD7E7FF), fontSize: 8)),
                ],
              ),
            ),
            pw.Text('Oluşturulma: ${_date.format(generatedAt)}',
                style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFBBD1EE), fontSize: 6)),
          ],
        ),
      );

  static pw.Widget _highlight(String label, String value) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF0FDF4),
          borderRadius: pw.BorderRadius.circular(7),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFBBF7D0)),
        ),
        child: pw.Row(children: [
          pw.Expanded(
            child: pw.Text(label,
                style: const pw.TextStyle(color: _muted, fontSize: 7)),
          ),
          pw.Text(value,
              style: pw.TextStyle(
                  color: _green, fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ]),
      );

  static pw.Widget _sectionTitle(String title) => pw.Row(children: [
        pw.Container(
          width: 4,
          height: 13,
          decoration: pw.BoxDecoration(
            color: _blue,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(title,
            style: pw.TextStyle(
                color: _navy, fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
      ]);

  static pw.Widget _detailGrid(List<MapEntry<String, String>> entries) =>
      pw.Wrap(
        spacing: 4,
        runSpacing: 4,
        children: entries
            .map((entry) => pw.Container(
                  width: 270,
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: _light,
                    borderRadius: pw.BorderRadius.circular(5),
                    border: pw.Border.all(color: _border),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(entry.key,
                          style:
                              const pw.TextStyle(color: _muted, fontSize: 6.2)),
                      pw.SizedBox(height: 1.5),
                      pw.Text(entry.value,
                          style: pw.TextStyle(
                              color: _navy,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ))
            .toList(),
      );

  static pw.Widget _disclaimer({bool compact = false}) => pw.Container(
        width: double.infinity,
        padding:
            pw.EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 4 : 6),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFFF7E6),
          borderRadius: pw.BorderRadius.circular(5),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFF5D58A)),
        ),
        child: pw.Text(
          'Bu hesaplama uygulamaya girilen bilgilerle hazırlanmıştır. '
          'Bilgilendirme amaçlıdır ve resmî belge niteliği taşımaz.',
          style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF7C5A12),
              fontSize: compact ? 5.2 : 6.2,
              height: 1.2),
        ),
      );

  static pw.Widget _footer(pw.Context context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('İş & SGK Asistan · Bilgilendirme amaçlıdır',
                style: const pw.TextStyle(color: _muted, fontSize: 6)),
            pw.Text('${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(color: _muted, fontSize: 6)),
          ],
        ),
      );

  static Future<void> _share(Uint8List bytes, String title) async {
    final safeName = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final filename = '${safeName.isEmpty ? 'hesaplama' : safeName}_sonucu.pdf';
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: filename)],
      text: '$title hesaplama sonucu',
    );
  }
}
