import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../mesaitakip/mesaihesaplama.dart';
import '../utils/emeklilik_statulu_hesap.dart';
import '../utils/app_design.dart';
import '../utils/personal_profile.dart';
import '../services/calisma_hayati_pdf_service.dart';
import '../services/personal_profile_store.dart';
import 'yillik_maas_analizi.dart';

class CalismaHayatimEkrani extends StatefulWidget {
  final bool useScaffold;
  final bool demoMode;
  final VoidCallback? onPremiumTap;

  const CalismaHayatimEkrani({super.key, this.useScaffold = true,
    this.demoMode = false, this.onPremiumTap});

  @override
  State<CalismaHayatimEkrani> createState() => _CalismaHayatimEkraniState();
}

// İçerik widget'ı - Scaffold olmadan (convenience wrapper)
class CalismaHayatimContent extends StatelessWidget {
  const CalismaHayatimContent({super.key, this.demoMode = false,
    this.onPremiumTap});

  final bool demoMode;
  final VoidCallback? onPremiumTap;

  @override
  Widget build(BuildContext context) {
    return CalismaHayatimEkrani(useScaffold: false,
      demoMode: demoMode, onPremiumTap: onPremiumTap);
  }
}

class _CalismaHayatimEkraniState extends State<CalismaHayatimEkrani> {
  String? _adSoyad;
  DateTime? _dogumTarihi;
  DateTime? _ilkIseGirisTarihi;
  int? _toplamPrimGun;
  DateTime? _primGunuReferansTarihi;
  String _cinsiyet = 'Erkek';
  String _sigortaKolu = '4/a (SSK)';
  DateTime? _mevcutIsyeriBaslangic;
  double? _guncelBrutMaas;
  final Map<int, double> _aylikBrutMaaslar = {};
  int _selectedSalaryMonth = DateTime.now().month - 1;
  bool _isLoading = true;
  bool _reportGenerating = false;

  /// Kayıtlı prim günü + referans tarihinden bu yana geçen günler (her gün +1, emeklilik takipteki gibi).
  int? get _effectiveToplamPrimGun {
    if (_toplamPrimGun == null) return null;
    final ref = _primGunuReferansTarihi;
    if (ref == null || ref.isAfter(DateTime.now())) return _toplamPrimGun;
    final days = DateTime.now().difference(ref).inDays;
    return _toplamPrimGun! + days;
  }

  String? get _retirementDataError => PersonalProfile.validateRetirementInputs(
        birthDate: _dogumTarihi,
        insuranceStartDate: _ilkIseGirisTarihi,
        premiumDays: _effectiveToplamPrimGun,
      );

  @override
  void initState() {
    super.initState();
    _loadPersonalInfo();
  }

  Future<void> _loadPersonalInfo() async {
    if (widget.demoMode) {
      final now = DateTime.now();
      _adSoyad = 'Örnek Çalışan';
      _dogumTarihi = DateTime(1985, 6, 15);
      _ilkIseGirisTarihi = DateTime(2006, 9, 1);
      _toplamPrimGun = 5400;
      _primGunuReferansTarihi = now;
      _cinsiyet = 'Kadın';
      _sigortaKolu = '4/a (SSK)';
      _mevcutIsyeriBaslangic = DateTime(2021, 1, 1);
      _guncelBrutMaas = 50000;
      for (var month = 1; month <= 12; month++) {
        _aylikBrutMaaslar[month] = 50000;
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final kisiselBilgilerJson = await PersonalProfileStore().readRaw();

      if (kisiselBilgilerJson != null && kisiselBilgilerJson.isNotEmpty) {
        final map = jsonDecode(kisiselBilgilerJson) as Map<String, dynamic>;

        _adSoyad = map['adSoyad'] as String?;

        if (map['dogumTarihi'] != null) {
          _dogumTarihi =
              DateTime.fromMillisecondsSinceEpoch(map['dogumTarihi'] as int);
        }
        if (map['ilkIseGirisTarihi'] != null) {
          _ilkIseGirisTarihi = DateTime.fromMillisecondsSinceEpoch(
              map['ilkIseGirisTarihi'] as int);
        }
        if (map['toplamPrimGun'] != null) {
          _toplamPrimGun = int.tryParse(map['toplamPrimGun'].toString());
        }
        if (map['primGunuReferansTarihi'] != null) {
          _primGunuReferansTarihi = DateTime.fromMillisecondsSinceEpoch(
              map['primGunuReferansTarihi'] as int);
        }
        if (map['cinsiyet'] != null) {
          _cinsiyet = map['cinsiyet'] as String;
        }
        if (map['sigortaKolu'] != null) {
          _sigortaKolu = map['sigortaKolu'].toString();
        }
        if (map['mevcutIsyeriBaslangic'] != null) {
          _mevcutIsyeriBaslangic = DateTime.fromMillisecondsSinceEpoch(
              map['mevcutIsyeriBaslangic'] as int);
        }
        if (map['guncelBrutMaas'] != null) {
          _guncelBrutMaas = double.tryParse(map['guncelBrutMaas'].toString());
        }
        final rawMonthly = map['aylikBrutMaaslar'];
        if (rawMonthly is Map) {
          final yearPrefix = '${DateTime.now().year}-';
          for (final entry in Map<String, dynamic>.from(rawMonthly).entries) {
            if (!entry.key.startsWith(yearPrefix) || entry.value is! num)
              continue;
            final month = int.tryParse(entry.key.substring(yearPrefix.length));
            if (month != null && month >= 1 && month <= 12) {
              _aylikBrutMaaslar[month] = (entry.value as num).toDouble();
            }
          }
        }
        if (_aylikBrutMaaslar.isEmpty &&
            _guncelBrutMaas != null &&
            _guncelBrutMaas! > 0) {
          final year = DateTime.now().year;
          final firstMonth = _mevcutIsyeriBaslangic?.year == year
              ? _mevcutIsyeriBaslangic!.month
              : 1;
          for (var month = firstMonth; month <= 12; month++) {
            _aylikBrutMaaslar[month] = _guncelBrutMaas!;
          }
        }
      }
    } catch (e) {
      debugPrint('Kişisel bilgiler yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double? value) {
    if (value == null) return '0 ₺';
    final formatter =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    return formatter.format(value);
  }

  /// Para formatı, kuruş dahil (virgülden sonra 2 hane), matematiksel yuvarlama (0,005 ve üzeri yukarı)
  String _formatCurrencyWithKurus(double? value) {
    if (value == null) return '0,00 ₺';
    final rounded = (value * 100).round() / 100;
    final formatter =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    return formatter.format(rounded);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppDesign.activeSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Map<String, dynamic>? _calculateRetirement() {
    if (_dogumTarihi == null ||
        _ilkIseGirisTarihi == null ||
        _toplamPrimGun == null) {
      return null;
    }

    if (_retirementDataError != null) {
      return null;
    }

    try {
      final effective = _effectiveToplamPrimGun!;
      final result = emeklilikHesaplaStatulu(
        sigortaKolu: _sigortaKolu,
        dogumTarihi: _dogumTarihi!,
        cinsiyet: _cinsiyet,
        sigortaBaslangici: _ilkIseGirisTarihi!,
        primGunu: effective,
      );
      if (result == null) return null;

      final reqPrimNormal = result['reqPrimNormal'] as int? ?? 0;
      final reqAgeNormal = result['reqAgeNormal'] as int? ?? 0;
      final reqYearsNormal = result['reqInsuranceYearsNormal'] as int? ?? 0;
      final reqPrimYas = result['reqPrimYas'] as int? ?? 0;
      final reqAgeYas = result['reqAgeYas'] as int? ?? 0;
      final reqYearsYas = result['reqInsuranceYearsYas'] as int? ?? 0;
      final age = result['currentAge'] as int? ?? 0;
      final currentYears = result['currentInsuranceYears'] as int? ??
          DateTime.now().year - _ilkIseGirisTarihi!.year;
      final normalEligible = (result['emekliMi'] as Map?)?['normal'] == true;
      final partialEligible = (result['emekliMi'] as Map?)?['yasHaddi'] == true;

      if (_sigortaKolu.toLowerCase().startsWith('4/a') &&
          reqPrimNormal <= 0 &&
          reqPrimYas <= 0) {
        return _calculateRetirementFallback(age, effective);
      }
      if (reqPrimNormal <= 0 && reqYearsNormal <= 0) return null;

      final tahmini = result['tahminiSonuclar'] as Map<String, dynamic>? ?? {};
      final normalTahmini =
          tahmini['Normal Emeklilik'] as Map<String, dynamic>?;
      final yasTahmini =
          tahmini['Yaş Haddinden Emeklilik'] as Map<String, dynamic>?;

      DateTime? normalEstimatedDate;
      if (normalTahmini != null && normalTahmini['tahminiTarih'] != null) {
        final t = normalTahmini['tahminiTarih'];
        normalEstimatedDate =
            t is DateTime ? t : DateTime.fromMillisecondsSinceEpoch(t as int);
      }

      DateTime? yasEstimatedDate;
      if (yasTahmini != null && yasTahmini['tahminiTarih'] != null) {
        final t = yasTahmini['tahminiTarih'];
        yasEstimatedDate =
            t is DateTime ? t : DateTime.fromMillisecondsSinceEpoch(t as int);
      }
      if (reqYearsNormal > currentYears && !normalEligible) {
        final yearsTarget = DateTime(
          _ilkIseGirisTarihi!.year + reqYearsNormal,
          _ilkIseGirisTarihi!.month,
          _ilkIseGirisTarihi!.day,
        );
        if (normalEstimatedDate == null ||
            normalEstimatedDate.isBefore(yearsTarget)) {
          normalEstimatedDate = yearsTarget;
        }
      }
      if (reqYearsYas > currentYears && !partialEligible) {
        final yearsTarget = DateTime(
          _ilkIseGirisTarihi!.year + reqYearsYas,
          _ilkIseGirisTarihi!.month,
          _ilkIseGirisTarihi!.day,
        );
        if (yasEstimatedDate == null || yasEstimatedDate.isBefore(yearsTarget)) {
          yasEstimatedDate = yearsTarget;
        }
      }

      final normalRemainingDaysTotal =
          (reqPrimNormal - effective).clamp(0, reqPrimNormal);
      final normalRemainingYears = normalRemainingDaysTotal ~/ 360;
      final normalRemainingDaysOnly = normalRemainingDaysTotal % 360;
      final normalProgress = reqPrimNormal > 0
          ? (effective / reqPrimNormal * 100).clamp(0.0, 100.0)
          : reqYearsNormal > 0
              ? (currentYears / reqYearsNormal * 100).clamp(0.0, 100.0)
              : 0.0;

      final yasRemainingDaysTotal =
          reqPrimYas > 0 ? (reqPrimYas - effective).clamp(0, reqPrimYas) : 0;
      final yasRemainingYears = yasRemainingDaysTotal ~/ 360;
      final yasRemainingDaysOnly = yasRemainingDaysTotal % 360;
      final yasProgress = reqPrimYas > 0
          ? (effective / reqPrimYas * 100).clamp(0.0, 100.0)
          : reqYearsYas > 0
              ? (currentYears / reqYearsYas * 100).clamp(0.0, 100.0)
              : 0.0;

      // Kalan Yıl = gerekli yaşa kalan süre (iç halka yaş ile uyumlu)
      final now = DateTime.now();
      final normalYasHedefTarih = DateTime(_dogumTarihi!.year + reqAgeNormal,
          _dogumTarihi!.month, _dogumTarihi!.day);
      final normalKalanYasFark = normalYasHedefTarih.difference(now).inDays;
      final remainingYearsUntilAge =
          normalKalanYasFark <= 0 ? 0 : normalKalanYasFark ~/ 365;
      final remainingDaysUntilAge =
          normalKalanYasFark <= 0 ? 0 : normalKalanYasFark % 365;

      final yasYasHedefTarih = DateTime(_dogumTarihi!.year + reqAgeYas,
          _dogumTarihi!.month, _dogumTarihi!.day);
      final yasKalanYasFark = yasYasHedefTarih.difference(now).inDays;
      final yasRemainingYearsUntilAge =
          yasKalanYasFark <= 0 ? 0 : yasKalanYasFark ~/ 365;
      final yasRemainingDaysUntilAge =
          yasKalanYasFark <= 0 ? 0 : yasKalanYasFark % 365;

      return {
        'normalEmeklilik': {
          'requiredAge': reqAgeNormal,
          'requiredDays': reqPrimNormal,
          'requiredYears': reqYearsNormal,
          'currentYears': currentYears,
          'eligible': normalEligible,
          'currentAge': age,
          'currentDays': _effectiveToplamPrimGun,
          'remainingYears': normalRemainingYears,
          'remainingDays': normalRemainingDaysOnly,
          'remainingYearsUntilAge': remainingYearsUntilAge,
          'remainingDaysUntilAge': remainingDaysUntilAge,
          'progress': normalProgress,
          'estimatedDate': normalEstimatedDate,
        },
        'kismiEmeklilik': {
          'requiredAge': reqAgeYas,
          'requiredDays': reqPrimYas,
          'requiredYears': reqYearsYas,
          'currentYears': currentYears,
          'eligible': partialEligible,
          'currentAge': age,
          'currentDays': _effectiveToplamPrimGun,
          'remainingYears': yasRemainingYears,
          'remainingDays': yasRemainingDaysOnly,
          'remainingYearsUntilAge': yasRemainingYearsUntilAge,
          'remainingDaysUntilAge': yasRemainingDaysUntilAge,
          'progress': yasProgress,
          'estimatedDate': yasEstimatedDate,
        },
      };
    } catch (e) {
      debugPrint('Emeklilik hesaplama hatası: $e');
      if (!_sigortaKolu.toLowerCase().startsWith('4/a')) return null;
      final effective = _effectiveToplamPrimGun;
      if (effective != null && _dogumTarihi != null) {
        int age = DateTime.now().year - _dogumTarihi!.year;
        if (DateTime(
                DateTime.now().year, _dogumTarihi!.month, _dogumTarihi!.day)
            .isAfter(DateTime.now())) age--;
        return _calculateRetirementFallback(age, effective);
      }
      return null;
    }
  }

  /// 4a kriteri belirlenemediğinde basit 7200/5400 fallback
  Map<String, dynamic> _calculateRetirementFallback(int age, int effective) {
    const int normalRequiredDays = 7200;
    int partialRequiredDays = 5400;
    if (_ilkIseGirisTarihi != null &&
        _ilkIseGirisTarihi!.isBefore(DateTime(1999, 9, 9))) {
      partialRequiredDays = 5000;
    }
    final normalRemainingDaysTotal =
        (normalRequiredDays - effective).clamp(0, normalRequiredDays);
    final partialRemainingDaysTotal =
        (partialRequiredDays - effective).clamp(0, partialRequiredDays);
    final now = DateTime.now();
    DateTime? normalEstimatedDate;
    if (normalRemainingDaysTotal > 0) {
      final y = normalRemainingDaysTotal ~/ 360;
      final d = normalRemainingDaysTotal % 360;
      normalEstimatedDate =
          DateTime(now.year + y, now.month, now.day).add(Duration(days: d));
    }
    DateTime? partialEstimatedDate;
    if (partialRemainingDaysTotal > 0) {
      final y = partialRemainingDaysTotal ~/ 360;
      final d = partialRemainingDaysTotal % 360;
      partialEstimatedDate =
          DateTime(now.year + y, now.month, now.day).add(Duration(days: d));
    }
    final normalYasHedef = DateTime(
        _dogumTarihi!.year + 60, _dogumTarihi!.month, _dogumTarihi!.day);
    final normalKalanYas = normalYasHedef.difference(now).inDays;
    final partialYasHedef = DateTime(
        _dogumTarihi!.year + 60, _dogumTarihi!.month, _dogumTarihi!.day);
    final partialKalanYas = partialYasHedef.difference(now).inDays;

    return {
      'normalEmeklilik': {
        'requiredAge': 60,
        'requiredDays': normalRequiredDays,
        'currentAge': age,
        'currentDays': _effectiveToplamPrimGun,
        'remainingYears': normalRemainingDaysTotal ~/ 360,
        'remainingDays': normalRemainingDaysTotal % 360,
        'remainingYearsUntilAge':
            normalKalanYas <= 0 ? 0 : normalKalanYas ~/ 365,
        'remainingDaysUntilAge': normalKalanYas <= 0 ? 0 : normalKalanYas % 365,
        'progress': (effective / normalRequiredDays * 100).clamp(0.0, 100.0),
        'estimatedDate': normalEstimatedDate,
      },
      'kismiEmeklilik': {
        'requiredAge': 60,
        'requiredDays': partialRequiredDays,
        'currentAge': age,
        'currentDays': _effectiveToplamPrimGun,
        'remainingYears': partialRemainingDaysTotal ~/ 360,
        'remainingDays': partialRemainingDaysTotal % 360,
        'remainingYearsUntilAge':
            partialKalanYas <= 0 ? 0 : partialKalanYas ~/ 365,
        'remainingDaysUntilAge':
            partialKalanYas <= 0 ? 0 : partialKalanYas % 365,
        'progress': (effective / partialRequiredDays * 100).clamp(0.0, 100.0),
        'estimatedDate': partialEstimatedDate,
      },
    };
  }

  /// ✅ Profesyonel Kıdem Tazminatı Hesaplama (Tavan + Damga Vergisi)
  /// eligible: false ise 1 yıldan az çalışılmıştır (4857 sayılı İş K. md. 17).
  Map<String, dynamic>? _calculateSeverancePay() {
    if (_mevcutIsyeriBaslangic == null ||
        _guncelBrutMaas == null ||
        _guncelBrutMaas! <= 0) {
      return null;
    }

    try {
      final now = DateTime.now();
      final ceiling = _getKidemTavani(now);

      final daysWorked = now.difference(_mevcutIsyeriBaslangic!).inDays + 1;
      final eligible =
          daysWorked >= 365; // En az 1 yıl aynı işverende çalışma şartı

      final dailySalary = _guncelBrutMaas! / 365; // Yıllık bazda

      double severancePay = dailySalary * daysWorked;

      // Tavan kontrolü
      final dailyCeiling = ceiling / 365;
      final tavanAsildi = dailySalary > dailyCeiling;
      if (tavanAsildi) {
        severancePay = dailyCeiling * daysWorked;
      }

      final stampTax = severancePay * 0.00759; // Damga vergisi
      final netSeverancePay = severancePay - stampTax;

      return {
        'eligible': eligible,
        'daysWorked': daysWorked,
        'brut': severancePay,
        'net': netSeverancePay,
        'stampTax': stampTax,
        'tavanAsildi': tavanAsildi,
      };
    } catch (e) {
      debugPrint('Kıdem tazminatı hesaplama hatası: $e');
      return null;
    }
  }

  /// Kıdem Tazminatı Tavanı (Güncel verilerle)
  double _getKidemTavani(DateTime date) {
    final year = date.year;
    final month = date.month;

    if (year < 2020) return 6379.86;
    if (year == 2020) return month < 7 ? 6730.15 : 7117.17;
    if (year == 2021) return month < 7 ? 7638.96 : 8284.51;
    if (year == 2022) return month < 7 ? 10848.59 : 15371.40;
    if (year == 2023) return month < 7 ? 19982.83 : 23489.83;
    if (year == 2024) return month < 7 ? 35058.58 : 41828.42;
    if (year == 2025) return month < 7 ? 46655.43 : 53919.68;
    if (year == 2026) return month < 7 ? 64948.77 : 73729.87;

    return 73729.87; // Son doğrulanmış tavan
  }

  int? _calculateAnnualLeave() {
    if (_mevcutIsyeriBaslangic == null) return null;

    try {
      final now = DateTime.now();
      final years = now.year - _mevcutIsyeriBaslangic!.year;

      if (years < 1) return 0;
      if (years < 5) return 14;
      if (years < 15) return 20;
      return 26;
    } catch (e) {
      debugPrint('Yıllık izin hesaplama hatası: $e');
      return null;
    }
  }

  /// ✅ Profesyonel Maaş Kesintileri Hesaplama (Mesai Takip SalaryEngine'den)
  /// Kümülatif vergi hesabı ile Ocak'tan şu anki aya kadar
  Map<String, double>? _calculateSalaryDeductions({int? monthIndex}) {
    if (_guncelBrutMaas == null || _guncelBrutMaas! <= 0) return null;

    try {
      final now = DateTime.now();
      final year = now.year;
      final currentMonth = (monthIndex ?? now.month - 1).clamp(0, 11);
      final firstMonth = _mevcutIsyeriBaslangic?.year == year
          ? _mevcutIsyeriBaslangic!.month - 1
          : 0;
      if (currentMonth < firstMonth) return null;

      // SalaryEngine oluştur (Normal çalışan, teşviksiz)
      final engine = SalaryEngine(
        year: year,
        status: EmployeeStatus.normal,
        incentive: Incentive.none,
      );

      // Ocak'tan şu anki aya kadar hesapla (kümülatif vergi için)
      double cumulativeTaxBase = 0.0;
      MonthResult? currentMonthResult;

      for (int m = firstMonth; m <= currentMonth; m++) {
        final monthlyGross = _aylikBrutMaaslar[m + 1] ?? _guncelBrutMaas!;
        final result = engine.calculateNetFromGross(
          grossMonthly: monthlyGross,
          monthIndex: m,
          cumulativeTaxBasePrev: cumulativeTaxBase,
        );

        cumulativeTaxBase = result.cumulativeTaxBase;

        // Son ay sonucunu sakla
        if (m == currentMonth) {
          currentMonthResult = result;
        }
      }

      if (currentMonthResult == null) return null;

      final totalDeductions = currentMonthResult.sgkEmployee +
          currentMonthResult.unemploymentEmployee +
          currentMonthResult.incomeTax +
          currentMonthResult.stampTax;

      return {
        'brut': currentMonthResult.gross,
        'sgk': currentMonthResult.sgkEmployee,
        'issizlik': currentMonthResult.unemploymentEmployee,
        'gelirVergisi': currentMonthResult.incomeTax,
        'gelirVergisiDilimPercent':
            currentMonthResult.incomeTaxBracketPercent.toDouble(),
        'damgaVergisi': currentMonthResult.stampTax,
        'toplam': totalDeductions,
        'net': currentMonthResult.net,
      };
    } catch (e) {
      debugPrint('Maaş kesintileri hesaplama hatası: $e');
      return null;
    }
  }

  Future<void> _createDetailedReport() async {
    if (widget.demoMode) {
      widget.onPremiumTap?.call();
      return;
    }
    if (_reportGenerating) return;
    setState(() => _reportGenerating = true);
    try {
      final analyses = <AylikMaasAnalizi>[];
      for (var month = 0; month < 12; month++) {
        final deductions = _calculateSalaryDeductions(monthIndex: month);
        if (deductions != null) {
          analyses.add(AylikMaasAnalizi(
            monthIndex: month,
            deductions: deductions,
          ));
        }
      }
      await CalismaHayatiPdfService.share(CalismaHayatiRaporVerisi(
        adSoyad: _adSoyad,
        cinsiyet: _cinsiyet,
        sigortaKolu: _sigortaKolu,
        dogumTarihi: _dogumTarihi,
        ilkSigortaTarihi: _ilkIseGirisTarihi,
        mevcutIsBaslangici: _mevcutIsyeriBaslangic,
        primGunu: _effectiveToplamPrimGun,
        guncelBrutMaas: _guncelBrutMaas,
        aylikAnalizler: analyses,
        emeklilik: _calculateRetirement(),
        kidem: _calculateSeverancePay(),
        yillikIzinGunu: _calculateAnnualLeave(),
      ));
    } catch (error, stackTrace) {
      debugPrint('Detaylı rapor oluşturma hatası: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          error.toString().contains('share') ||
                  error.toString().contains('Share')
              ? 'Rapor hazırlandı ancak paylaşım ekranı açılamadı.'
              : 'Detaylı rapor oluşturulamadı. Lütfen tekrar deneyin.',
        ),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _reportGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final retirementInfo = _calculateRetirement();
    final severancePay = _calculateSeverancePay();
    final annualLeave = _calculateAnnualLeave();
    final deductions =
        _calculateSalaryDeductions(monthIndex: _selectedSalaryMonth);

    final contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Üst bilgiler: İlk İşe Başlama + Mevcut İşyeri Başlangıç
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'İlk İşe Başlama Tarihim',
                _formatDate(_ilkIseGirisTarihi),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryItem(
                'Mevcut İş Başlama Tarihim',
                _formatDate(_mevcutIsyeriBaslangic),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Emeklilik Takibi (Tam genişlik)
        if (retirementInfo != null)
          _buildRetirementTracking(retirementInfo, themeColor)
        else
          _buildMissingCard(
            icon: Icons.calendar_month_outlined,
            title: 'Emeklilik Takibim',
            message: _retirementDataError ??
                'Doğum tarihi, ilk sigorta tarihi ve prim gününü ekleyin.',
          ),

        const SizedBox(height: 12),

        // Kıdem Tazminatı + Yıllık İzin (yan yana)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KidemTazminatiAnimatedCard(
                severancePay: severancePay,
                themeColor: themeColor,
                formatCurrencyWithKurus: _formatCurrencyWithKurus,
                cardDecoration: _cardDecoration(),
                onInfoTap: severancePay == null
                    ? null
                    : () => _showSeverancePayDetails(severancePay),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniInfoCardLeftIconCompact(
                icon: Icons.event_available_rounded,
                iconColor: themeColor,
                title: 'Yıllık İznim',
                value: annualLeave != null ? '$annualLeave Gün' : '-',
                subtitle:
                    annualLeave == null ? 'İş başlangıcı gerekli' : 'Bu Yıl',
                onInfoTap: annualLeave == null
                    ? null
                    : () => _showAnnualLeaveDetails(annualLeave),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Maaş ve Kesinti Analizi (Tam genişlik)
        if (deductions != null)
          _buildSalaryAnalysis(deductions, themeColor, _selectedSalaryMonth)
        else
          _buildMissingCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Maaş ve Kesinti Analizi',
            message: 'Güncel brüt maaşınızı ekleyin.',
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _reportGenerating ? null : _createDetailedReport,
            icon: _reportGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.workspace_premium_outlined),
            label: Text(_reportGenerating
                ? 'Premium rapor hazırlanıyor...'
                : 'Premium Detaylı Analiz Raporu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );

    // useScaffold parametresine göre Scaffold ile veya olmadan döndür
    if (widget.useScaffold) {
      return Scaffold(
        backgroundColor: AppDesign.activeBackground,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: contentWidget,
        ),
      );
    } else {
      // Scaffold olmadan, direkt içerik
      return contentWidget;
    }
  }

  Widget _buildMissingCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppDesign.activeBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppDesign.activeMuted, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(message,
                  style: TextStyle(
                      color: AppDesign.activeMuted, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSummaryItem(String label, String value) => Container(
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppDesign.activeSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppDesign.activeBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              style: TextStyle(
                  fontSize: 11, color: AppDesign.activeMuted, height: 1.25),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppDesign.activeInk,
              ),
            ),
          ],
        ),
      );

  // Emeklilik yolculuğu: tarih, prim ve yaş ilerlemesi tek bakışta.
  Widget _buildRetirementTracking(
      Map<String, dynamic>? retirementInfo, Color themeColor) {
    if (retirementInfo == null) return const SizedBox.shrink();

    final normalRetirement =
        retirementInfo['normalEmeklilik'] as Map<String, dynamic>?;
    if (normalRetirement == null) return const SizedBox.shrink();

    final currentDays = normalRetirement['currentDays'] as int? ?? 0;
    final requiredDays = normalRetirement['requiredDays'] as int? ?? 0;
    final currentYears = normalRetirement['currentYears'] as int? ?? 0;
    final requiredYears = normalRetirement['requiredYears'] as int? ?? 0;
    final currentAge = normalRetirement['currentAge'] as int? ?? 0;
    final requiredAge =
        (normalRetirement['requiredAge'] as num?)?.toInt() ?? 60;
    final hasAgeRequirement = requiredAge > 0;
    final estimatedDate = normalRetirement['estimatedDate'] as DateTime?;
    final remainingPremiumDays =
        (requiredDays - currentDays).clamp(0, requiredDays);
    final remainingInsuranceYears =
        (requiredYears - currentYears).clamp(0, requiredYears);
    final dayProgress =
        requiredDays > 0 ? (currentDays / requiredDays).clamp(0.0, 1.0) : 0.0;
    final ageProgress =
        hasAgeRequirement ? (currentAge / requiredAge).clamp(0.0, 1.0) : 1.0;
    final premiumComplete = requiredDays == 0 || remainingPremiumDays == 0;
    final insuranceYearsComplete =
        requiredYears == 0 || remainingInsuranceYears == 0;
    final ageComplete = !hasAgeRequirement || currentAge >= requiredAge;
    final allConditionsComplete = normalRetirement['eligible'] == true &&
        premiumComplete &&
        insuranceYearsComplete &&
        ageComplete;

    final dateText = allConditionsComplete
        ? 'Emeklilik koşullarını tamamladınız'
        : estimatedDate == null
            ? 'Hesaplanıyor'
            : DateFormat('d MMMM yyyy', 'tr_TR')
                .format(estimatedDate)
                .toUpperCase();
    final targetText = !premiumComplete
        ? '${NumberFormat.decimalPattern('tr_TR').format(remainingPremiumDays)} prim günü kaldı'
        : !insuranceYearsComplete
            ? '$remainingInsuranceYears sigortalılık yılı kaldı'
        : !ageComplete
            ? '${requiredAge - currentAge} yaş kaldı'
            : allConditionsComplete
                ? 'Tüm koşullar tamamlandı'
                : 'Koşullar kontrol ediliyor';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Emeklilik Takibim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.activeInk,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showRetirementDetails(retirementInfo, themeColor),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            allConditionsComplete ? 'DURUM' : 'TAHMİNİ EMEKLİLİK',
            style: TextStyle(
              color: AppDesign.activeMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            dateText,
            style: TextStyle(
              color: AppDesign.activeInk,
              fontSize: 18,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -.2,
            ),
          ),
          const SizedBox(height: 8),
          if (requiredDays > 0) ...[
            _buildRetirementProgressRow(
              label: 'Prim günü',
              value:
                  '${NumberFormat.decimalPattern('tr_TR').format(currentDays)} / ${NumberFormat.decimalPattern('tr_TR').format(requiredDays)} gün',
              progress: dayProgress,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 7),
          ],
          if (requiredYears > 0) ...[
            _buildRetirementProgressRow(
              label: 'Sigortalılık',
              value: '$currentYears / $requiredYears yıl',
              progress: (currentYears / requiredYears).clamp(0.0, 1.0),
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 7),
          ],
          _buildRetirementProgressRow(
            label: 'Yaş',
            value: hasAgeRequirement
                ? '$currentAge / $requiredAge yaş'
                : 'Yaş şartı yok',
            progress: ageProgress,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 7),
          Divider(height: 1, color: AppDesign.activeBorder),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                premiumComplete ? Icons.schedule_rounded : Icons.flag_rounded,
                size: 16,
                color: premiumComplete
                    ? const Color(0xFF2196F3)
                    : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 7),
              Text(
                'Öncelikli hedef',
                style: TextStyle(
                  color: AppDesign.activeMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  targetText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppDesign.activeInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementProgressRow({
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppDesign.activeInk,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppDesign.activeMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 7),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: safeProgress),
              duration: const Duration(milliseconds: 50000),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) => Text(
                '%${(animatedValue * 100).round()}',
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: safeProgress),
          duration: const Duration(milliseconds: 50000),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: animatedValue,
              minHeight: 6,
              backgroundColor: AppDesign.isDark
                  ? const Color(0xFF263548)
                  : const Color(0xFFE8EDF3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  /// Kıdem tazminatı kartı: Açılışta bugün → yarın tutarına kısa artış animasyonu
  Widget _KidemTazminatiAnimatedCard({
    required Map<String, dynamic>? severancePay,
    required Color themeColor,
    required String Function(double) formatCurrencyWithKurus,
    required BoxDecoration cardDecoration,
    VoidCallback? onInfoTap,
  }) {
    return _KidemTazminatiAnimatedCardImpl(
      severancePay: severancePay,
      themeColor: themeColor,
      formatCurrencyWithKurus: formatCurrencyWithKurus,
      cardDecoration: cardDecoration,
      onInfoTap: onInfoTap,
    );
  }

  Widget _buildMiniInfoCardLeftIconCompact({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    bool isEstimated = false,
    VoidCallback? onInfoTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.activeInk,
                  ),
                ),
              ),
              if (onInfoTap != null)
                InkWell(
                  onTap: onInfoTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppDesign.activeInk,
            ),
          ),
        ],
      ),
    );
  }

  // Maaş & Kesinti Analizi (Net ele Geçen (%71) ₺35.746 format)
  void _changeSalaryMonth(int delta) {
    final year = DateTime.now().year;
    final minimum = _mevcutIsyeriBaslangic?.year == year
        ? _mevcutIsyeriBaslangic!.month - 1
        : 0;
    final next = (_selectedSalaryMonth + delta).clamp(minimum, 11);
    if (next != _selectedSalaryMonth) {
      setState(() => _selectedSalaryMonth = next);
    }
  }

  void _openYearlySalaryAnalysis(Color themeColor) {
    if (widget.demoMode) {
      widget.onPremiumTap?.call();
      return;
    }
    final analyses = <AylikMaasAnalizi>[];
    for (var month = 0; month < 12; month++) {
      final deductions = _calculateSalaryDeductions(monthIndex: month);
      if (deductions != null) {
        analyses.add(AylikMaasAnalizi(
          monthIndex: month,
          deductions: deductions,
        ));
      }
    }
    if (analyses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('12 aylık analiz için maaş bilgilerinizi tamamlayın.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => YillikMaasAnaliziEkrani(
        year: DateTime.now().year,
        analyses: analyses,
        initialMonth: _selectedSalaryMonth,
        accentColor: themeColor,
      ),
    ));
  }

  Widget _buildSalaryAnalysis(
      Map<String, double> deductions, Color themeColor, int monthIndex) {
    final brut = deductions['brut']!;
    final net = deductions['net']!;
    final sgk = deductions['sgk']!;
    final issizlik = deductions['issizlik']!;
    final gelirVergisi = deductions['gelirVergisi']!;
    final damgaVergisi = deductions['damgaVergisi']!;

    final netPercent = (net / brut * 100);
    final sgkPercent = (sgk / brut * 100);
    final issizlikPercent = (issizlik / brut * 100);
    final gelirVergisiPercent = (gelirVergisi / brut * 100);
    final damgaVergisiPercent = (damgaVergisi / brut * 100);
    final gelirVergisiDilimPercent =
        deductions['gelirVergisiDilimPercent']?.round() ??
            (gelirVergisiPercent.round());

    final segments = [
      {
        'label': 'Net ele Geçen',
        'value': net,
        'percent': netPercent,
        'color': Colors.blue
      },
      {
        'label': 'SGK Primi',
        'value': sgk,
        'percent': sgkPercent,
        'color': Colors.orange
      },
      {
        'label': 'İşsizlik Primi',
        'value': issizlik,
        'percent': issizlikPercent,
        'color': Colors.teal
      },
      {
        'label': 'Gelir Vergisi',
        'value': gelirVergisi,
        'percent': gelirVergisiPercent,
        'color': Colors.red,
        'bracketPercent': gelirVergisiDilimPercent
      },
      {
        'label': 'Damga Vergisi',
        'value': damgaVergisi,
        'percent': damgaVergisiPercent,
        'color': Colors.purple
      },
    ];

    final monthLabel = DateFormat('MMMM yyyy', 'tr_TR')
        .format(DateTime(DateTime.now().year, monthIndex + 1));
    final isFuture = monthIndex + 1 > DateTime.now().month;
    final minimumMonth = _mevcutIsyeriBaslangic?.year == DateTime.now().year
        ? _mevcutIsyeriBaslangic!.month - 1
        : 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -180) _changeSalaryMonth(1);
        if (velocity > 180) _changeSalaryMonth(-1);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Maaş ve Kesinti Analizi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppDesign.activeInk,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${toBeginningOfSentenceCase(monthLabel) ?? monthLabel}${isFuture ? ' · Tahmini' : ''}',
                    maxLines: 1,
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _openYearlySalaryAnalysis(themeColor),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 116,
                        height: 116,
                        child: _AnimatedDonutChart(
                          key: ValueKey('salary-$monthIndex'),
                          segments: segments,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var seg in segments)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildSalaryLineInline(
                                  color: seg['color'] as Color,
                                  label: seg['label'] as String,
                                  percent: (seg['percent'] as double),
                                  amount: seg['value'] as double,
                                  bracketPercent: seg['bracketPercent'] as int?,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: -8,
                  child: IconButton(
                    tooltip: 'Önceki ay',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 32, height: 40),
                    onPressed: monthIndex > minimumMonth
                        ? () => _changeSalaryMonth(-1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 23),
                  ),
                ),
                Positioned(
                  right: -8,
                  child: IconButton(
                    tooltip: 'Sonraki ay',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 32, height: 40),
                    onPressed:
                        monthIndex < 11 ? () => _changeSalaryMonth(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 23),
                  ),
                ),
              ],
            ),
            const Divider(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Toplam Brüt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppDesign.activeInk,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatCurrency(brut),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryLineInline({
    required Color color,
    required String label,
    required double percent,
    required double amount,
    int? bracketPercent,
  }) {
    final percentText = label == 'Damga Vergisi'
        ? '0,759'
        : bracketPercent?.toString() ?? percent.toStringAsFixed(0);
    final leftText = '$label (%$percentText)';
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              leftText,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppDesign.activeMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppDesign.activeInk,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailDialogTitle({
    required BuildContext dialogContext,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: AppDesign.isDark ? .18 : .11),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppDesign.activeInk,
              fontSize: 17,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Kapat',
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.of(dialogContext).pop(),
          icon: Icon(Icons.close_rounded, color: AppDesign.activeMuted),
        ),
      ],
    );
  }

  /// Yaşa göre kalan süreyi metin olarak döndürür (info ekranı ve kart için).
  String _formatKalanSure(Map<String, dynamic> retirement) {
    final ry = retirement['remainingYearsUntilAge'] as int? ??
        retirement['remainingYears'] as int? ??
        0;
    final rd = retirement['remainingDaysUntilAge'] as int? ??
        retirement['remainingDays'] as int? ??
        0;
    final currentDays = retirement['currentDays'] as int? ?? 0;
    final requiredDays = retirement['requiredDays'] as int? ?? 0;
    if (ry == 0 && rd == 0) {
      final currentYears = retirement['currentYears'] as int? ?? 0;
      final requiredYears = retirement['requiredYears'] as int? ?? 0;
      if (requiredDays > currentDays) {
        return '${requiredDays - currentDays} prim günü kaldı';
      }
      if (requiredYears > currentYears) {
        return '${requiredYears - currentYears} sigortalılık yılı kaldı';
      }
      return (requiredDays > 0 && currentDays >= requiredDays)
          ? 'Gerekli yaşı doldurdunuz'
          : '0 yıl';
    }
    return '$ry yıl${rd > 0 ? ' $rd gün' : ''}';
  }

  // Emeklilik Detayları Dialog
  void _showRetirementDetails(
      Map<String, dynamic> retirementInfo, Color themeColor) {
    final normalRetirement =
        retirementInfo['normalEmeklilik'] as Map<String, dynamic>?;
    final partialRetirement =
        retirementInfo['kismiEmeklilik'] as Map<String, dynamic>?;

    if (normalRetirement == null) return;

    final currentAge = normalRetirement['currentAge'] as int? ?? 0;
    final currentDays = normalRetirement['currentDays'] as int? ?? 0;
    final normalRequiredAge =
        (normalRetirement['requiredAge'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.activeSurface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppDesign.activeBorder),
        ),
        title: _buildDetailDialogTitle(
          dialogContext: context,
          title: 'Emeklilik Detayları',
          icon: Icons.track_changes_rounded,
          color: const Color(0xFFF59E0B),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Mevcut Yaşınız', '$currentAge yaş',
                  isBold: true),
              _buildDetailRow('Toplam Prim Günü', '$currentDays gün',
                  isBold: true),

              const SizedBox(height: 20),

              // Normal Emeklilik
              Text(
                '📋 Normal Emeklilik',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const Divider(height: 16),
              _buildDetailRow(
                  'Gerekli Yaş',
                  normalRequiredAge > 0
                      ? '$normalRequiredAge yaş'
                      : 'Yaş şartı yok'),
              if ((normalRetirement['requiredDays'] as int? ?? 0) > 0)
                _buildDetailRow('Gerekli Prim Günü',
                    '${normalRetirement['requiredDays']} gün'),
              if ((normalRetirement['requiredYears'] as int? ?? 0) > 0)
                _buildDetailRow('Gerekli Sigortalılık',
                    '${normalRetirement['requiredYears']} yıl'),
              _buildDetailRow('İlerleme',
                  '%${((normalRetirement['progress'] as num?) ?? 0).toStringAsFixed(1)}'),
              _buildDetailRow('Kalan Süre', _formatKalanSure(normalRetirement)),
              if (normalRetirement['estimatedDate'] != null)
                _buildDetailRow(
                    'Tahmini Tarih',
                    DateFormat('dd.MM.yyyy', 'tr_TR')
                        .format(normalRetirement['estimatedDate'] as DateTime)),

              if (partialRetirement != null) ...[
                const SizedBox(height: 20),

                // Kısmi Emeklilik
                Text(
                  '📋 Kısmi Emeklilik',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Divider(height: 16),
                _buildDetailRow(
                    'Gerekli Yaş', '${partialRetirement['requiredAge']} yaş'),
                if ((partialRetirement['requiredDays'] as int? ?? 0) > 0)
                  _buildDetailRow('Gerekli Prim Günü',
                      '${partialRetirement['requiredDays']} gün'),
                if ((partialRetirement['requiredYears'] as int? ?? 0) > 0)
                  _buildDetailRow('Gerekli Sigortalılık',
                      '${partialRetirement['requiredYears']} yıl'),
                _buildDetailRow('İlerleme',
                    '%${((partialRetirement['progress'] as num?) ?? 0).toStringAsFixed(1)}'),
                _buildDetailRow(
                    'Kalan Süre', _formatKalanSure(partialRetirement)),
                if (partialRetirement['estimatedDate'] != null)
                  _buildDetailRow(
                      'Tahmini Tarih',
                      DateFormat('dd.MM.yyyy', 'tr_TR').format(
                          partialRetirement['estimatedDate'] as DateTime)),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: themeColor, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ana ekranda normal emeklilik (7200 gün) gösterilir. Veriler her gün otomatik güncellenir.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // Kıdem Tazminatı Detayları Dialog
  void _showSeverancePayDetails(Map<String, dynamic>? severancePay) {
    if (severancePay == null) return;

    final themeColor = Theme.of(context).primaryColor;
    final now = DateTime.now();
    int workYears = 0;
    int workMonths = 0;
    if (_mevcutIsyeriBaslangic != null) {
      int totalMonths = (now.year * 12 + now.month) -
          (_mevcutIsyeriBaslangic!.year * 12 + _mevcutIsyeriBaslangic!.month);
      if (now.day < _mevcutIsyeriBaslangic!.day) totalMonths--;
      if (totalMonths < 0) totalMonths = 0;
      workYears = totalMonths ~/ 12;
      workMonths = totalMonths % 12;
    }

    final eligible = severancePay['eligible'] as bool? ?? false;
    final daysWorked = severancePay['daysWorked'] as int? ?? 0;
    final brutSeverance = (severancePay['brut'] as num?)?.toDouble() ?? 0.0;
    final netSeverance = (severancePay['net'] as num?)?.toDouble() ?? 0.0;
    final stampTax = (severancePay['stampTax'] as num?)?.toDouble() ?? 0.0;
    final tavanAsildi = severancePay['tavanAsildi'] as bool? ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.activeSurface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppDesign.activeBorder),
        ),
        title: _buildDetailDialogTitle(
          dialogContext: context,
          title: 'Kıdem Tazminatı',
          icon: Icons.payments_rounded,
          color: const Color(0xFF169B55),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!eligible) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kıdem tazminatına hak kazanmak için aynı işveren bünyesinde en az 1 yıl (365 gün) çalışmanız gerekir. Şu an $daysWorked gün çalışmış bulunuyorsunuz.',
                          style: TextStyle(
                              fontSize: 13, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (tavanAsildi) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.blue.shade700, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kıdem tazminatınız tavanı aştığından yeni tavan belirlenince tekrar hesaplanacaktır. Şu anki hesaplama mevcut tavan üzerinden yapılmaktadır.',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow(
                  'Başlangıç Tarihi', _formatDate(_mevcutIsyeriBaslangic)),
              _buildDetailRow('Hesaplama Tarihi', _formatDate(now)),
              _buildDetailRow('Çalışma Süresi',
                  '$workYears yıl $workMonths ay ($daysWorked gün)'),
              _buildDetailRow('Kıdem Tazminatı Tavanı',
                  _formatCurrencyWithKurus(_getKidemTavani(now))),
              const SizedBox(height: 6),
              Text(
                'Bu tutar, hesaplama tarihi itibarıyla güncel brüt maaş ve tavan üzerinden hesaplanmıştır.',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic),
              ),
              const Divider(height: 20),
              _buildDetailRow(
                  'Aylık Brüt Maaş', _formatCurrency(_guncelBrutMaas)),
              const Divider(height: 20),
              _buildDetailRow('Brüt Kıdem Tazminatı',
                  _formatCurrencyWithKurus(brutSeverance)),
              _buildDetailRow(
                  'Damga Vergisi (%0.759)', _formatCurrencyWithKurus(stampTax),
                  color: Colors.red),
              _buildDetailRow(
                  'Net Kıdem Tazminatı', _formatCurrencyWithKurus(netSeverance),
                  isBold: true, color: eligible ? Colors.green : Colors.grey),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: themeColor, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Kıdem Tazminatı Nedir?',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'En az 1 yıl çalıştıktan sonra işten ayrılırken, belirli koşullarda işvereninizin size ödemekle yükümlü olduğu tazminattır. Hesaplama günlük brüt maaş × çalışma günü şeklinde yapılır ve tavan ücreti kontrolü ile damga vergisi (%0.759) uygulanır.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // Yıllık İzin Detayları Dialog
  void _showAnnualLeaveDetails(int? annualLeave) {
    if (annualLeave == null) return;

    final themeColor = Theme.of(context).primaryColor;
    final now = DateTime.now();
    final workYears = _mevcutIsyeriBaslangic != null
        ? now.year - _mevcutIsyeriBaslangic!.year
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.activeSurface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppDesign.activeBorder),
        ),
        title: _buildDetailDialogTitle(
          dialogContext: context,
          title: 'Yıllık İzin Detayları',
          icon: Icons.event_available_rounded,
          color: const Color(0xFF2196F3),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  'Başlangıç Tarihi', _formatDate(_mevcutIsyeriBaslangic)),
              _buildDetailRow('Çalışma Süresi', '$workYears yıl'),
              const Divider(height: 20),
              _buildDetailRow('Yıllık İzin Hakkı', '$annualLeave gün',
                  isBold: true),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: themeColor, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Yıllık İzin Süresi',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 1-5 yıl arası: 14 gün\n• 5-15 yıl arası: 20 gün\n• 15 yıl ve üzeri: 26 gün',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // Maaş Analizi Detayları Dialog
  void _showSalaryDetails(Map<String, double> deductions, Color themeColor) {
    final brut = deductions['brut']!;
    final net = deductions['net']!;
    final sgk = deductions['sgk']!;
    final issizlik = deductions['issizlik']!;
    final gelirVergisi = deductions['gelirVergisi']!;
    final damgaVergisi = deductions['damgaVergisi']!;
    final toplam = deductions['toplam']!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.activeSurface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppDesign.activeBorder),
        ),
        title: _buildDetailDialogTitle(
          dialogContext: context,
          title: 'Maaş ve Kesinti Analizi',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF2563EB),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Brüt Maaş', _formatCurrency(brut), isBold: true),
              const Divider(height: 20),
              const Text(
                'Kesintiler:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('SGK Primi (%14)', _formatCurrency(sgk)),
              _buildDetailRow('İşsizlik Primi (%1)', _formatCurrency(issizlik)),
              _buildDetailRow(
                'Gelir Vergisi (${_gelirVergisiDilimLabel(deductions)})',
                _formatCurrency(gelirVergisi),
              ),
              _buildDetailRow(
                  'Damga Vergisi (%0,759)', _formatCurrency(damgaVergisi)),
              const Divider(height: 20),
              _buildDetailRow('Toplam Kesinti', _formatCurrency(toplam),
                  color: Colors.red),
              _buildDetailRow('Net Maaş', _formatCurrency(net),
                  isBold: true, color: Colors.green),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: themeColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Eline geçecek net tutar: ${_formatCurrency(net)} (${((net / brut) * 100).toStringAsFixed(1)}%)',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  String _gelirVergisiDilimLabel(Map<String, double> deductions) {
    final p = deductions['gelirVergisiDilimPercent']?.round();
    if (p == null) return 'Gelir vergisi';
    return '%$p';
  }

  // Detay satırı widget'ı
  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppDesign.activeMuted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppDesign.activeInk,
            ),
          ),
        ],
      ),
    );
  }
}

// Çift donut: dış = prim günü, iç = yaş (yüzde etiketleri halka üzerinde)
class _DualDonutProgressWidget extends StatefulWidget {
  final double dayProgress01;
  final double ageProgress01;

  const _DualDonutProgressWidget({
    required this.dayProgress01,
    required this.ageProgress01,
  });

  @override
  State<_DualDonutProgressWidget> createState() =>
      _DualDonutProgressWidgetState();
}

class _DualDonutProgressWidgetState extends State<_DualDonutProgressWidget>
    with SingleTickerProviderStateMixin {
  // Maaş kesinti donutu ile aynı dolma süresi (50 s)
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 50000),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant _DualDonutProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayProgress01 != widget.dayProgress01 ||
        oldWidget.ageProgress01 != widget.ageProgress01) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const Color _outerTeal = Color(0xFF009688);
  static const Color _innerBlue = Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    final dayTarget = widget.dayProgress01.clamp(0.0, 1.0);
    final ageTarget = widget.ageProgress01.clamp(0.0, 1.0);

    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) {
          return CustomPaint(
            size: const Size(140, 140),
            painter: _DualDonutPainter(
              dayProgress01: dayTarget * _a.value,
              ageProgress01: ageTarget * _a.value,
              outerColor: _outerTeal,
              innerColor: _innerBlue,
              bgColor: Colors.grey.shade200,
            ),
          );
        },
      ),
    );
  }
}

class _DualDonutPainter extends CustomPainter {
  final double dayProgress01;
  final double ageProgress01;
  final Color outerColor;
  final Color innerColor;
  final Color bgColor;

  _DualDonutPainter({
    required this.dayProgress01,
    required this.ageProgress01,
    required this.outerColor,
    required this.innerColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final startAngle = -math.pi / 2;

    final outerRadius = size.width / 2 - 12;
    final innerRadius = outerRadius * 0.62;

    final outerStroke = outerRadius * 0.32;
    final innerStroke = outerRadius * 0.30;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    bgPaint.strokeWidth = outerStroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      2 * math.pi,
      false,
      bgPaint,
    );

    final outerSweep = 2 * math.pi * dayProgress01.clamp(0.0, 1.0);
    outerPaint.strokeWidth = outerStroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      outerSweep,
      false,
      outerPaint,
    );

    bgPaint.strokeWidth = innerStroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      2 * math.pi,
      false,
      bgPaint,
    );

    final innerSweep = 2 * math.pi * ageProgress01.clamp(0.0, 1.0);
    innerPaint.strokeWidth = innerStroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      innerSweep,
      false,
      innerPaint,
    );

    _drawProgressLabel(
      canvas: canvas,
      center: center,
      startAngle: startAngle,
      sweepAngle: outerSweep,
      radius: outerRadius,
      strokeWidth: outerStroke,
      text: '%${(dayProgress01 * 100).toInt()}',
    );

    _drawProgressLabel(
      canvas: canvas,
      center: center,
      startAngle: startAngle,
      sweepAngle: innerSweep,
      radius: innerRadius,
      strokeWidth: innerStroke,
      text: '%${(ageProgress01 * 100).toInt()}',
    );
  }

  void _drawProgressLabel({
    required Canvas canvas,
    required Offset center,
    required double startAngle,
    required double sweepAngle,
    required double radius,
    required double strokeWidth,
    required String text,
  }) {
    if (sweepAngle < 0.60) return;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.0,
          shadows: [
            Shadow(
                blurRadius: 3.5, color: Colors.black54, offset: Offset(1, 1.5)),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    if (tp.width + 20 > sweepAngle * radius * 0.92) return;

    final textRadius = radius - strokeWidth * 0.05;

    double fraction = 0.72;
    if (sweepAngle > 5.0) {
      fraction = 0.55;
    } else if (sweepAngle < 2.2) {
      fraction = 0.84;
    }

    final angle = startAngle + sweepAngle * fraction;

    final pos = Offset(
      center.dx + textRadius * math.cos(angle),
      center.dy + textRadius * math.sin(angle),
    );

    tp.paint(
      canvas,
      Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DualDonutPainter oldDelegate) {
    return oldDelegate.dayProgress01 != dayProgress01 ||
        oldDelegate.ageProgress01 != ageProgress01 ||
        oldDelegate.outerColor != outerColor ||
        oldDelegate.innerColor != innerColor ||
        oldDelegate.bgColor != bgColor;
  }
}

/// Donut grafiği dolma animasyonu – ilk göründüğünde 0'dan 1'e dolar
class _AnimatedDonutChart extends StatefulWidget {
  final List<Map<String, dynamic>> segments;

  const _AnimatedDonutChart({super.key, required this.segments});

  @override
  State<_AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<_AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Emeklilik gauge ile aynı hız: gauge süresi = progress*500 ms (100% → 50 s)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50000),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // İlk frame sonrası animasyonu başlat (ekran açıldığında garanti)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => CustomPaint(
        painter: DonutChartPainter(widget.segments, progress: _animation.value),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;
  final double progress;

  DonutChartPainter(this.segments, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: outerRadius);

    // progress kadar toplam açı (0..2π) – tek parça dolma
    double remainingAngle = 2 * math.pi * progress;
    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      if (remainingAngle <= 0) break;

      final percent = (segment['percent'] as num).toDouble();
      final fullSweep = (percent / 100) * 2 * math.pi;
      final sweep = remainingAngle >= fullSweep ? fullSweep : remainingAngle;

      final paint = Paint()
        ..color = segment['color'] as Color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweep, true, paint);

      startAngle += fullSweep;
      remainingAngle -= sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Kıdem tazminatı kartı – açılışta bugün → yarın tutarına kısa artış animasyonu (state dışında tanımlı)
class _KidemTazminatiAnimatedCardImpl extends StatefulWidget {
  final Map<String, dynamic>? severancePay;
  final Color themeColor;
  final String Function(double) formatCurrencyWithKurus;
  final BoxDecoration cardDecoration;
  final VoidCallback? onInfoTap;

  const _KidemTazminatiAnimatedCardImpl({
    required this.severancePay,
    required this.themeColor,
    required this.formatCurrencyWithKurus,
    required this.cardDecoration,
    this.onInfoTap,
  });

  @override
  State<_KidemTazminatiAnimatedCardImpl> createState() =>
      _KidemTazminatiAnimatedCardImplState();
}

class _KidemTazminatiAnimatedCardImplState
    extends State<_KidemTazminatiAnimatedCardImpl>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final sp = widget.severancePay;
    final eligible = sp != null && (sp['eligible'] == true);
    final daysWorked = (sp?['daysWorked'] as int?) ?? 0;
    final todayNet = (sp?['net'] as num?)?.toDouble() ?? 0.0;

    if (!eligible || daysWorked < 1) {
      _controller = AnimationController(vsync: this, duration: Duration.zero);
      _animation = AlwaysStoppedAnimation<double>(todayNet);
      return;
    }

    final brut = (sp!['brut'] as num?)?.toDouble() ?? 0.0;
    // Dünden bugüne artış: animasyon bitince ekranda bugünün tutarı kalsın
    final brutYesterday = brut * (daysWorked - 1) / daysWorked;
    final netYesterday = brutYesterday * (1 - 0.00759);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _animation = Tween<double>(begin: netYesterday, end: todayNet).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() => setState(() {}));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = widget.severancePay;
    final eligible = sp != null && (sp['eligible'] == true);
    final themeColor = widget.themeColor;
    final format = widget.formatCurrencyWithKurus;

    String valueStr;
    if (sp == null)
      valueStr = 'Bilgi eksik';
    else if (!eligible)
      valueStr = 'En az 1 yıl gerekli';
    else
      valueStr = format(_animation.value);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: widget.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kıdem Tazminatım',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.activeInk,
                  ),
                ),
              ),
              if (widget.onInfoTap != null)
                InkWell(
                  onTap: widget.onInfoTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.info_outline, size: 16, color: themeColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valueStr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppDesign.activeInk,
            ),
          ),
        ],
      ),
    );
  }
}
