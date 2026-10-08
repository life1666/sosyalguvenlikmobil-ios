import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/app_design.dart';

class AylikMaasAnalizi {
  final int monthIndex;
  final Map<String, double> deductions;

  const AylikMaasAnalizi({
    required this.monthIndex,
    required this.deductions,
  });

  double get gross => deductions['brut'] ?? 0;
  double get net => deductions['net'] ?? 0;
  double get totalDeductions => deductions['toplam'] ?? 0;
}

class YillikMaasAnaliziEkrani extends StatefulWidget {
  final int year;
  final List<AylikMaasAnalizi> analyses;
  final int initialMonth;
  final Color accentColor;

  const YillikMaasAnaliziEkrani({
    super.key,
    required this.year,
    required this.analyses,
    required this.initialMonth,
    required this.accentColor,
  });

  @override
  State<YillikMaasAnaliziEkrani> createState() =>
      _YillikMaasAnaliziEkraniState();
}

class _YillikMaasAnaliziEkraniState extends State<YillikMaasAnaliziEkrani> {
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final available = widget.analyses
        .where((item) => item.monthIndex <= widget.initialMonth)
        .toList();
    _selectedMonth = available.isNotEmpty
        ? available.last.monthIndex
        : widget.analyses.first.monthIndex;
  }

  AylikMaasAnalizi get _selected => widget.analyses.firstWhere(
        (item) => item.monthIndex == _selectedMonth,
        orElse: () => widget.analyses.first,
      );

  String _money(double value, {int decimals = 0}) => NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '₺',
        decimalDigits: decimals,
      ).format(value);

  String _month(int index) =>
      DateFormat('MMMM', 'tr_TR').format(DateTime(widget.year, index + 1));

  @override
  Widget build(BuildContext context) {
    final totalGross =
        widget.analyses.fold<double>(0, (total, item) => total + item.gross);
    final totalNet =
        widget.analyses.fold<double>(0, (total, item) => total + item.net);
    final totalDeductions = widget.analyses
        .fold<double>(0, (total, item) => total + item.totalDeductions);
    final averageNet = totalNet / widget.analyses.length;
    return Scaffold(
      backgroundColor: AppDesign.activeBackground,
      appBar: AppDesign.appBar('12 Aylık Maaş Analizi'),
      body: AppContent(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            _premiumHeader(),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _summaryCard('Yıllık brüt', _money(totalGross),
                    Icons.payments_outlined, widget.accentColor),
                _summaryCard(
                    'Yıllık net',
                    _money(totalNet),
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFF16A34A)),
                _summaryCard('Toplam kesinti', _money(totalDeductions),
                    Icons.pie_chart_outline_rounded, const Color(0xFFDC2626)),
                _summaryCard('Aylık ortalama', _money(averageNet),
                    Icons.analytics_outlined, const Color(0xFF7C3AED)),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('Net maaş trendi',
                'Vergi dilimi etkisini aylar boyunca izleyin.'),
            const SizedBox(height: 10),
            Container(
              height: 190,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              decoration: _panelDecoration(),
              child: CustomPaint(
                painter: _SalaryTrendPainter(
                  analyses: widget.analyses,
                  color: widget.accentColor,
                  gridColor: AppDesign.activeBorder,
                  labelColor: AppDesign.activeMuted,
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Aylık tablo',
                'Bir aya dokunarak kesintilerin ayrıntısını görün.'),
            const SizedBox(height: 10),
            _monthlyTable(),
            const SizedBox(height: 18),
            _monthDetail(_selected),
            const SizedBox(height: 12),
            Text(
              'Gelecek aylardaki sonuçlar kayıtlı brüt ücretler ve mevcut '
              'yasal parametrelerle tahmini olarak hesaplanır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppDesign.activeMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            widget.accentColor,
            Color.lerp(widget.accentColor, const Color(0xFF7C3AED), .45)!,
          ]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.year} finansal özeti',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                const Text('Premium maaş ve kesinti analizi',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ]),
      );

  Widget _summaryCard(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: _panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppDesign.activeMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppDesign.activeInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(color: AppDesign.activeMuted, fontSize: 11.5)),
        ],
      );

  BoxDecoration _panelDecoration() => BoxDecoration(
        color: AppDesign.activeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppDesign.activeBorder),
      );

  Widget _monthlyTable() => Container(
        decoration: _panelDecoration(),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                MaterialStatePropertyAll(widget.accentColor.withOpacity(.10)),
            headingTextStyle: TextStyle(
                color: AppDesign.activeInk,
                fontSize: 11.5,
                fontWeight: FontWeight.w800),
            dataTextStyle:
                TextStyle(color: AppDesign.activeInk, fontSize: 11.5),
            horizontalMargin: 14,
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('Ay')),
              DataColumn(label: Text('Brüt')),
              DataColumn(label: Text('Net')),
              DataColumn(label: Text('Kesinti')),
              DataColumn(label: Text('Net %')),
            ],
            rows: widget.analyses.map((item) {
              final selected = item.monthIndex == _selectedMonth;
              final future = item.monthIndex + 1 > DateTime.now().month;
              return DataRow(
                selected: selected,
                color: selected
                    ? MaterialStatePropertyAll(
                        widget.accentColor.withOpacity(.08))
                    : null,
                onSelectChanged: (_) =>
                    setState(() => _selectedMonth = item.monthIndex),
                cells: [
                  DataCell(Text(
                      '${toBeginningOfSentenceCase(_month(item.monthIndex))}${future ? ' *' : ''}')),
                  DataCell(Text(_money(item.gross))),
                  DataCell(Text(_money(item.net),
                      style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w700))),
                  DataCell(Text(_money(item.totalDeductions))),
                  DataCell(Text(item.gross <= 0
                      ? '%0'
                      : '%${(item.net / item.gross * 100).toStringAsFixed(1)}')),
                ],
              );
            }).toList(),
          ),
        ),
      );

  Widget _monthDetail(AylikMaasAnalizi item) {
    final d = item.deductions;
    final bracket = d['gelirVergisiDilimPercent']?.round() ?? 0;
    final future = item.monthIndex + 1 > DateTime.now().month;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              '${toBeginningOfSentenceCase(_month(item.monthIndex))} ayı kesintileri',
              style: TextStyle(
                  color: AppDesign.activeInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
            ),
          ),
          if (future)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text('Tahmini',
                  style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
        ]),
        const SizedBox(height: 14),
        _detailRow('SGK işçi payı (%14)', d['sgk'] ?? 0),
        _detailRow('İşsizlik primi (%1)', d['issizlik'] ?? 0),
        _detailRow('Gelir vergisi dilimi (%$bracket)', d['gelirVergisi'] ?? 0),
        _detailRow('Damga vergisi (%0,759)', d['damgaVergisi'] ?? 0),
        Divider(height: 22, color: AppDesign.activeBorder),
        _detailRow('Toplam kesinti', item.totalDeductions,
            color: const Color(0xFFDC2626), bold: true),
        _detailRow('Net ele geçen', item.net,
            color: const Color(0xFF16A34A), bold: true),
      ]),
    );
  }

  Widget _detailRow(String label, double value,
          {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: AppDesign.activeMuted,
                    fontSize: 12.5,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(_money(value, decimals: 2),
              style: TextStyle(
                  color: color ?? AppDesign.activeInk,
                  fontSize: 12.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ]),
      );
}

class _SalaryTrendPainter extends CustomPainter {
  final List<AylikMaasAnalizi> analyses;
  final Color color;
  final Color gridColor;
  final Color labelColor;

  const _SalaryTrendPainter({
    required this.analyses,
    required this.color,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (analyses.isEmpty) return;
    const left = 8.0, right = 8.0, top = 8.0, bottom = 26.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(
          Offset(left, y), Offset(size.width - right, y), gridPaint);
    }
    final values = analyses.map((item) => item.net).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 1 ? 1.0 : maxValue - minValue;
    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < analyses.length; i++) {
      final x = analyses.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * i / (analyses.length - 1);
      final y = top + chartHeight * (1 - (analyses[i].net - minValue) / range);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath
          ..moveTo(x, top + chartHeight)
          ..lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
      final label = DateFormat('MMM', 'tr_TR')
          .format(DateTime(2024, analyses[i].monthIndex + 1))
          .substring(0, 1)
          .toUpperCase();
      final textPainter = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
                color: labelColor, fontSize: 9, fontWeight: FontWeight.w700)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, size.height - textPainter.height));
    }
    fillPath
      ..lineTo(
          analyses.length == 1 ? left + chartWidth / 2 : size.width - right,
          top + chartHeight)
      ..close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, top),
            Offset(0, top + chartHeight),
            [color.withOpacity(.22), color.withOpacity(.02)],
          ));
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _SalaryTrendPainter oldDelegate) =>
      oldDelegate.analyses != analyses || oldDelegate.color != color;
}
