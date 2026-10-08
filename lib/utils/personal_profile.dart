import 'package:flutter/material.dart';

/// Parsing and backward-compatible updates for the existing personal profile.
class PersonalProfile {
  static String? validateRetirementInputs({
    required DateTime? birthDate,
    required DateTime? insuranceStartDate,
    required int? premiumDays,
    DateTime? referenceDate,
  }) {
    if (birthDate == null || insuranceStartDate == null || premiumDays == null) {
      return 'Doğum tarihi, ilk sigorta tarihi ve toplam prim günü zorunludur.';
    }

    final today = DateUtils.dateOnly(referenceDate ?? DateTime.now());
    final birth = DateUtils.dateOnly(birthDate);
    final insurance = DateUtils.dateOnly(insuranceStartDate);
    if (birth.isAfter(today)) return 'Doğum tarihi günümüzden sonra olamaz.';
    if (insurance.isBefore(birth)) {
      return 'İlk sigorta giriş tarihi doğum tarihinden önce olamaz.';
    }
    final minimumStart = DateTime(birth.year + 15, birth.month, birth.day);
    if (insurance.isBefore(minimumStart)) {
      return 'İlk sigorta giriş tarihinde en az 15 yaşında olmalısınız.';
    }
    if (insurance.isAfter(today)) {
      return 'İlk sigorta giriş tarihi günümüzden sonra olamaz.';
    }
    if (premiumDays < 0) return 'Toplam prim günü sıfırdan küçük olamaz.';

    final totalDays = today.difference(insurance).inDays;
    final fullYears = totalDays ~/ 365;
    final remainingDays = totalDays % 365;
    final maximumPremiumDays = (fullYears * 360) + remainingDays + 1;
    if (premiumDays > maximumPremiumDays) {
      return 'Toplam prim günü ($premiumDays), ilk sigorta girişinize göre mümkün olan en fazla $maximumPremiumDays günü aşamaz.';
    }
    return null;
  }

  static double? parseMoney(String value) {
    var raw = value.replaceAll('₺', '').replaceAll('TL', '').replaceAll(' ', '').trim();
    if (raw.isEmpty) return null;
    if (raw.contains(',')) {
      if (!RegExp(r'^\d+(?:\.\d{3})*,\d{1,2}$').hasMatch(raw)) return null;
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(raw)) {
      raw = raw.replaceAll('.', '');
    } else if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(raw)) {
      return null;
    }
    final amount = double.tryParse(raw);
    return amount != null && amount.isFinite && amount > 0 ? amount : null;
  }

  static Map<String, dynamic> merge(Map<String, dynamic> existing,
      Map<String, dynamic> values, DateTime now) {
    final unchangedPrim = int.tryParse('${existing['toplamPrimGun']}') == values['toplamPrimGun'];
    return {
      ...existing,
      ...values,
      'kayitTarihi': now.millisecondsSinceEpoch,
      'primGunuReferansTarihi': unchangedPrim && existing['primGunuReferansTarihi'] is int
          ? existing['primGunuReferansTarihi'] : now.millisecondsSinceEpoch,
    };
  }
}
