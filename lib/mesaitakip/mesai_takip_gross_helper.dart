// Maaş Mesai Ayarları (mesai_takip_v1) verisinden güncel aylık brüt ücreti okur.
// Kişisel bilgilerdeki "güncel brüt" artık bu kaynaktan alınır.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mesaihesaplama.dart';

const String _kStore = 'mesai_takip_v1';

double? _parseMoney(String s) {
  if (s.trim().isEmpty) return null;
  final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
  final v = double.tryParse(cleaned);
  return v != null && v >= 1000000 ? v / 100.0 : v;
}

int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

double? _proratedMonthlyAmount(
  DateTime month,
  double? baseAmount,
  DateTime? startDate,
) {
  if (baseAmount == null) return null;
  if (startDate == null) return baseAmount;

  if (startDate.year == month.year && startDate.month == month.month) {
    final lastDayOfMonth = _daysInMonth(month.year, month.month);
    final remainingDays =
        (lastDayOfMonth - startDate.day + 1).clamp(0, lastDayOfMonth);
    final ratio = (remainingDays / 30.0).clamp(0.0, 1.0);
    return baseAmount * ratio;
  }

  final endOfMonth =
      DateTime(month.year, month.month, _daysInMonth(month.year, month.month));
  if (startDate.isAfter(endOfMonth)) return 0.0;
  return baseAmount;
}

/// Maaş Mesai Ayarları (Hesabım > Maaş ve Mesai Ayarları / Mesai Takip) içinde
/// girilen brüt veya net ücretten, şu anki ay için brüt ücreti hesaplar.
/// Veri yoksa veya boşsa null döner.
Future<double?> getCurrentMonthGrossFromMesaiTakip() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStore);
    if (raw == null || raw.isEmpty) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final salaryYear = (map['salaryYear'] as num?)?.toInt() ?? DateTime.now().year;
    final salaryKindIndex = (map['salaryKind'] as num?)?.toInt() ?? 0;
    final isRetired = map['isRetired'] as bool? ?? false;
    final startDateStr = map['startDate'] as String?;
    final startDate =
        startDateStr != null ? DateTime.tryParse(startDateStr) : null;

    final grossTexts = map['grossTexts'] as List?;
    final netTexts = map['netTexts'] as List?;
    if (grossTexts == null || netTexts == null) return null;

    final now = DateTime.now();
    if (now.year != salaryYear) return null;
    final monthIndex = now.month - 1;
    final month = DateTime(now.year, now.month, 1);

    final status =
        isRetired ? EmployeeStatus.sgdp : EmployeeStatus.normal;
    final engine = SalaryEngine(
      year: salaryYear,
      status: status,
      incentive: Incentive.none,
    );

    if (salaryKindIndex == 0) {
      final gStr = monthIndex < grossTexts.length
          ? grossTexts[monthIndex]?.toString() ?? ''
          : '';
      final g = _parseMoney(gStr);
      return _proratedMonthlyAmount(month, g, startDate);
    } else {
      final nStr = monthIndex < netTexts.length
          ? netTexts[monthIndex]?.toString() ?? ''
          : '';
      final n = _parseMoney(nStr);
      final nProrated = _proratedMonthlyAmount(month, n, startDate);
      if (nProrated == null || nProrated <= 0) return null;

      double cumTaxBase = 0.0;
      for (int m = 0; m < monthIndex; m++) {
        final mDate = DateTime(salaryYear, m + 1, 1);
        final gStr = m < grossTexts.length ? grossTexts[m]?.toString() ?? '' : '';
        final nStrM = m < netTexts.length ? netTexts[m]?.toString() ?? '' : '';
        final gVal = _parseMoney(gStr);
        final nVal = _parseMoney(nStrM);
        final gProrated = _proratedMonthlyAmount(mDate, gVal, startDate);
        final nProratedM = _proratedMonthlyAmount(mDate, nVal, startDate);

        if (gProrated != null && gProrated > 0) {
          final res = engine.calculateNetFromGross(
            grossMonthly: gProrated,
            monthIndex: m,
            cumulativeTaxBasePrev: cumTaxBase,
          );
          cumTaxBase = res.cumulativeTaxBase;
        } else if (nProratedM != null && nProratedM > 0) {
          final res = engine.calculateGrossFromNet(
            targetNetMonthly: nProratedM,
            monthIndex: m,
            cumulativeTaxBasePrev: cumTaxBase,
          );
          cumTaxBase = res.cumulativeTaxBase;
        }
      }

      final res = engine.calculateGrossFromNet(
        targetNetMonthly: nProrated,
        monthIndex: monthIndex,
        cumulativeTaxBasePrev: cumTaxBase,
      );
      return res.gross;
    }
  } catch (_) {
    return null;
  }
}
