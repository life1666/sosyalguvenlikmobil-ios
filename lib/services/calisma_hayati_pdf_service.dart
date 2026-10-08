import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../screens/yillik_maas_analizi.dart';
import 'hesaplama_pdf_service.dart';
import 'premium_access_service.dart';

class CalismaHayatiRaporVerisi {
  final String? adSoyad;
  final String cinsiyet;
  final String sigortaKolu;
  final DateTime? dogumTarihi;
  final DateTime? ilkSigortaTarihi;
  final DateTime? mevcutIsBaslangici;
  final int? primGunu;
  final double? guncelBrutMaas;
  final List<AylikMaasAnalizi> aylikAnalizler;
  final Map<String, dynamic>? emeklilik;
  final Map<String, dynamic>? kidem;
  final int? yillikIzinGunu;

  const CalismaHayatiRaporVerisi({
    required this.adSoyad,
    required this.cinsiyet,
    required this.sigortaKolu,
    required this.dogumTarihi,
    required this.ilkSigortaTarihi,
    required this.mevcutIsBaslangici,
    required this.primGunu,
    required this.guncelBrutMaas,
    required this.aylikAnalizler,
    required this.emeklilik,
    required this.kidem,
    required this.yillikIzinGunu,
  });
}

class CalismaHayatiPdfService {
  static final _date = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final _money = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '',
    decimalDigits: 2,
  );
  static final _integer = NumberFormat.decimalPattern('tr_TR');
  static const _navy = PdfColor.fromInt(0xFF163A6B);
  static const _blue = PdfColor.fromInt(0xFF2563EB);
  static const _green = PdfColor.fromInt(0xFF16A34A);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _light = PdfColor.fromInt(0xFFF3F6FA);
  static const _muted = PdfColor.fromInt(0xFF64748B);

  static Future<void> share(CalismaHayatiRaporVerisi data) async {
    final status = await PremiumAccessService().load();
    if (!status.hasPremium) {
      throw PremiumAccessRequiredException();
    }
    final bytes = await generate(data);
    final generatedAt = DateTime.now();
    final safeName = (data.adSoyad?.trim().isNotEmpty == true
            ? data.adSoyad!.trim()
            : 'calisma_hayatim')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+'), '_');
    final filename =
        '${safeName}_${DateFormat('yyyyMMdd').format(generatedAt)}.pdf';
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: filename)],
      text: 'Çalışma Hayatım Detaylı Analiz Raporu',
    );
  }

  static Future<Uint8List> generate(CalismaHayatiRaporVerisi data) async {
    final regularData =
        await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/OpenSans-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    final document = pw.Document(
      title: 'Çalışma Hayatım Detaylı Analiz Raporu',
      author: 'İş & SGK Asistan',
      creator: 'İş & SGK Asistan',
    );
    final generatedAt = DateTime.now();
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(22, 18, 22, 18),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox.shrink()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ÇALIŞMA HAYATIM RAPORU',
                      style: pw.TextStyle(
                          color: _navy,
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      data.adSoyad?.trim().isNotEmpty == true
                          ? data.adSoyad!.trim()
                          : 'Kişisel çalışma özeti',
                      style: const pw.TextStyle(color: _muted, fontSize: 6.5)),
                ],
              ),
            ),
      footer: (context) => pw.Padding(
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
      ),
      build: (_) => [
        _cover(data, generatedAt),
        pw.SizedBox(height: 8),
        _sectionTitle('Kişisel ve SGK özeti', '01'),
        pw.SizedBox(height: 4),
        _infoGrid([
          ('Ad soyad', _text(data.adSoyad)),
          ('Cinsiyet', _text(data.cinsiyet)),
          ('Doğum tarihi', _dateText(data.dogumTarihi)),
          ('SGK statüsü', _text(data.sigortaKolu)),
          ('İlk sigorta girişi', _dateText(data.ilkSigortaTarihi)),
          (
            'Toplam prim günü',
            data.primGunu == null
                ? '-'
                : '${_integer.format(data.primGunu)} gün'
          ),
          ('Mevcut işe giriş', _dateText(data.mevcutIsBaslangici)),
          (
            'Güncel brüt maaş',
            data.guncelBrutMaas == null
                ? '-'
                : _formatMoney(data.guncelBrutMaas!)
          ),
        ]),
        pw.SizedBox(height: 8),
        _sectionTitle('12 aylık maaş ve kesinti analizi', '02'),
        pw.SizedBox(height: 4),
        if (data.aylikAnalizler.isEmpty)
          _empty('Aylık maaş verisi bulunmuyor.')
        else ...[
          _salarySummary(data.aylikAnalizler),
          pw.SizedBox(height: 5),
          _salaryTable(data.aylikAnalizler),
        ],
        pw.SizedBox(height: 8),
        _sectionTitle('Emeklilik görünümü', '03'),
        pw.SizedBox(height: 4),
        _retirement(data.emeklilik),
        pw.SizedBox(height: 8),
        _sectionTitle('Kıdem ve izin görünümü', '04'),
        pw.SizedBox(height: 4),
        _severanceAndLeave(data.kidem, data.yillikIzinGunu),
        pw.SizedBox(height: 8),
        _disclaimer(),
      ],
    ));
    return document.save();
  }

  static pw.Widget _cover(
          CalismaHayatiRaporVerisi data, DateTime generatedAt) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: pw.BoxDecoration(
          color: _navy,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Çalışma Hayatım',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text('Detaylı Analiz Raporu',
                style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFD7E7FF), fontSize: 9)),
            pw.SizedBox(height: 6),
            pw.Row(children: [
              pw.Expanded(
                child: pw.Text(
                    data.adSoyad?.trim().isNotEmpty == true
                        ? data.adSoyad!.trim()
                        : 'Kişisel çalışma özeti',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text('Oluşturulma: ${_date.format(generatedAt)}',
                  style: const pw.TextStyle(
                      color: PdfColor.fromInt(0xFFBBD1EE), fontSize: 6.5)),
            ]),
          ],
        ),
      );

  static pw.Widget _sectionTitle(String title, String number) => pw.Row(
        children: [
          pw.Container(
            width: 18,
            height: 18,
            alignment: pw.Alignment.center,
            decoration:
                const pw.BoxDecoration(color: _blue, shape: pw.BoxShape.circle),
            child: pw.Text(number,
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(width: 6),
          pw.Text(title,
              style: pw.TextStyle(
                  color: _navy,
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold)),
        ],
      );

  static pw.Widget _infoGrid(List<(String, String)> entries) => pw.Wrap(
        spacing: 4,
        runSpacing: 4,
        children: entries
            .map((entry) => pw.Container(
                  width: 270,
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _light,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                        color: const PdfColor.fromInt(0xFFE2E8F0)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(entry.$1,
                          style:
                              const pw.TextStyle(color: _muted, fontSize: 6.2)),
                      pw.SizedBox(height: 1.5),
                      pw.Text(entry.$2,
                          style: pw.TextStyle(
                              color: _navy,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ))
            .toList(),
      );

  static pw.Widget _salarySummary(List<AylikMaasAnalizi> rows) {
    final gross = rows.fold<double>(0, (sum, row) => sum + row.gross);
    final net = rows.fold<double>(0, (sum, row) => sum + row.net);
    final cuts = rows.fold<double>(0, (sum, row) => sum + row.totalDeductions);
    return pw.Row(children: [
      _metric('Yıllık brüt', _formatMoney(gross), _blue),
      pw.SizedBox(width: 4),
      _metric('Yıllık net', _formatMoney(net), _green),
      pw.SizedBox(width: 4),
      _metric('Toplam kesinti', _formatMoney(cuts), _red),
    ]);
  }

  static pw.Widget _metric(String label, String value, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(
            color: _light,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(children: [
            pw.Container(
              width: 3,
              height: 28,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(label,
                          style:
                              const pw.TextStyle(color: _muted, fontSize: 6.2)),
                      pw.SizedBox(height: 1.5),
                      pw.Text(value,
                          style: pw.TextStyle(
                              color: _navy,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold)),
                    ]),
              ),
            ),
          ]),
        ),
      );

  static pw.Widget _salaryTable(List<AylikMaasAnalizi> rows) =>
      pw.TableHelper.fromTextArray(
        headers: const ['Ay', 'Brüt', 'SGK + İşsizlik', 'Vergiler', 'Net'],
        data: rows.map((row) {
          final d = row.deductions;
          return [
            DateFormat('MMMM', 'tr_TR')
                .format(DateTime(2024, row.monthIndex + 1)),
            _formatMoney(row.gross),
            _formatMoney((d['sgk'] ?? 0) + (d['issizlik'] ?? 0)),
            _formatMoney((d['gelirVergisi'] ?? 0) + (d['damgaVergisi'] ?? 0)),
            _formatMoney(row.net),
          ];
        }).toList(),
        headerDecoration: const pw.BoxDecoration(color: _navy),
        headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 6.2,
            fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 6, color: _navy),
        cellPadding:
            const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.2),
        rowDecoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0), width: .5))),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(1.4),
          2: const pw.FlexColumnWidth(1.7),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(1.4),
        },
      );

  static pw.Widget _retirement(Map<String, dynamic>? retirement) {
    if (retirement == null) return _empty('Emeklilik verisi bulunmuyor.');
    final normal = retirement['normalEmeklilik'] as Map<String, dynamic>?;
    final partial = retirement['kismiEmeklilik'] as Map<String, dynamic>?;
    return _infoGrid([
      ('Normal emeklilik yaşı', '${normal?['requiredAge'] ?? '-'}'),
      (
        'Normal emeklilik prim hedefi',
        '${_integer.format(normal?['requiredDays'] ?? 0)} gün'
      ),
      (
        'Kalan prim',
        '${_integer.format(((normal?['remainingYears'] ?? 0) as num) * 360 + ((normal?['remainingDays'] ?? 0) as num))} gün'
      ),
      ('Tahmini normal emeklilik', _dynamicDate(normal?['estimatedDate'])),
      ('Kısmi emeklilik yaşı', '${partial?['requiredAge'] ?? '-'}'),
      (
        'Kısmi emeklilik prim hedefi',
        '${_integer.format(partial?['requiredDays'] ?? 0)} gün'
      ),
    ]);
  }

  static pw.Widget _severanceAndLeave(
      Map<String, dynamic>? severance, int? leaveDays) {
    if (severance == null && leaveDays == null) {
      return _empty('Mevcut iş bilgisi bulunmuyor.');
    }
    return _infoGrid([
      (
        'Kıdem süresi durumu',
        severance == null
            ? '-'
            : severance['eligible'] == true
                ? 'Bir yıllık eşik tamamlandı'
                : 'Bir yıllık eşik bekleniyor'
      ),
      (
        'Çalışılan gün',
        severance == null
            ? '-'
            : '${_integer.format(severance['daysWorked'] ?? 0)} gün'
      ),
      (
        'Tahmini brüt kıdem',
        severance == null
            ? '-'
            : _formatMoney((severance['brut'] as num?)?.toDouble() ?? 0)
      ),
      (
        'Tahmini net kıdem',
        severance == null
            ? '-'
            : _formatMoney((severance['net'] as num?)?.toDouble() ?? 0)
      ),
      ('Yıllık izin alt sınırı', leaveDays == null ? '-' : '$leaveDays gün'),
      (
        'Kıdem tavanı etkisi',
        severance == null
            ? '-'
            : severance['tavanAsildi'] == true
                ? 'Tavan uygulandı'
                : 'Tavan aşılmadı'
      ),
    ]);
  }

  static pw.Widget _empty(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
            color: _light, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Text(text,
            style: const pw.TextStyle(color: _muted, fontSize: 7)),
      );

  static pw.Widget _disclaimer() => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFFF7E6),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFF5D58A)),
        ),
        child: pw.Text(
          'Bu rapor, uygulamaya girilen bilgiler ve tahmini hesaplamalar '
          'kullanılarak hazırlanmıştır. Resmî belge, bordro, SGK hizmet '
          'dökümü veya hukuki görüş niteliğinde değildir. Kesin işlemlerde '
          'işveren kayıtları ve ilgili kamu kurumlarının verileri esas alınır.',
          style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF7C5A12), fontSize: 6.2, height: 1.2),
        ),
      );

  static String _text(String? value) =>
      value == null || value.trim().isEmpty ? '-' : value.trim();
  static String _formatMoney(num value) => '${_money.format(value).trim()} TL';
  static String _dateText(DateTime? value) =>
      value == null ? '-' : _date.format(value);
  static String _dynamicDate(dynamic value) {
    if (value is DateTime) return _date.format(value);
    if (value is int)
      return _date.format(DateTime.fromMillisecondsSinceEpoch(value));
    return '-';
  }
}
