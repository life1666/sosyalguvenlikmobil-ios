import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../mesaitakip/mesaihesaplama.dart';
import '../mesaitakip/mesaitakip.dart';
import '../mesaitakip/mesai_takip_gross_helper.dart';
import '../hesaplamalar/emeklilik_4a_helper.dart';

class CalismaHayatimEkrani extends StatefulWidget {
  final bool useScaffold;
  
  const CalismaHayatimEkrani({super.key, this.useScaffold = true});

  @override
  State<CalismaHayatimEkrani> createState() => _CalismaHayatimEkraniState();
}

// İçerik widget'ı - Scaffold olmadan (convenience wrapper)
class CalismaHayatimContent extends StatelessWidget {
  const CalismaHayatimContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const CalismaHayatimEkrani(useScaffold: false);
  }
}

class _CalismaHayatimEkraniState extends State<CalismaHayatimEkrani> {
  DateTime? _dogumTarihi;
  DateTime? _ilkIseGirisTarihi;
  int? _toplamPrimGun;
  DateTime? _primGunuReferansTarihi;
  String _cinsiyet = 'Erkek';
  DateTime? _mevcutIsyeriBaslangic;
  double? _guncelBrutMaas;
  bool _isLoading = true;

  /// Kayıtlı prim günü + referans tarihinden bu yana geçen günler (her gün +1, emeklilik takipteki gibi).
  int? get _effectiveToplamPrimGun {
    if (_toplamPrimGun == null) return null;
    final ref = _primGunuReferansTarihi;
    if (ref == null || ref.isAfter(DateTime.now())) return _toplamPrimGun;
    final days = DateTime.now().difference(ref).inDays;
    return _toplamPrimGun! + days;
  }


  @override
  void initState() {
    super.initState();
    _loadPersonalInfo();
  }

  Future<void> _loadPersonalInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kisiselBilgilerJson = prefs.getString('kisisel_bilgiler');

      if (kisiselBilgilerJson != null && kisiselBilgilerJson.isNotEmpty) {
        final map = jsonDecode(kisiselBilgilerJson) as Map<String, dynamic>;

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
          _primGunuReferansTarihi = DateTime.fromMillisecondsSinceEpoch(map['primGunuReferansTarihi'] as int);
        }
        if (map['cinsiyet'] != null) {
          _cinsiyet = map['cinsiyet'] as String;
        }
        if (map['mevcutIsyeriBaslangic'] != null) {
          _mevcutIsyeriBaslangic = DateTime.fromMillisecondsSinceEpoch(
              map['mevcutIsyeriBaslangic'] as int);
        }
      }
      // Güncel brüt: Maaş Mesai Ayarları (mesai takip) verisinden alınır
      final gross = await getCurrentMonthGrossFromMesaiTakip();
      if (mounted) {
        setState(() {
          _guncelBrutMaas = gross;
          _isLoading = false;
        });
      } else {
        _isLoading = false;
      }
    } catch (e) {
      debugPrint('Kişisel bilgiler yüklenirken hata: $e');
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
      color: Colors.white,
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

    try {
      final effective = _effectiveToplamPrimGun!;
      final result = emeklilikHesapla4a(
        _dogumTarihi!,
        _cinsiyet,
        _ilkIseGirisTarihi!,
        effective,
      );

      final reqPrimNormal = result['reqPrimNormal'] as int? ?? 0;
      final reqAgeNormal = result['reqAgeNormal'] as int? ?? 60;
      final reqPrimYas = result['reqPrimYas'] as int? ?? 0;
      final reqAgeYas = result['reqAgeYas'] as int? ?? 60;
      final age = result['currentAge'] as int? ?? 0;

      if (reqPrimNormal <= 0 && reqPrimYas <= 0) {
        return _calculateRetirementFallback(age, effective);
      }

      final tahmini = result['tahminiSonuclar'] as Map<String, dynamic>? ?? {};
      final normalTahmini = tahmini['Normal Emeklilik'] as Map<String, dynamic>?;
      final yasTahmini = tahmini['Yaş Haddinden Emeklilik'] as Map<String, dynamic>?;

      DateTime? normalEstimatedDate;
      if (normalTahmini != null && normalTahmini['tahminiTarih'] != null) {
        final t = normalTahmini['tahminiTarih'];
        normalEstimatedDate = t is DateTime ? t : DateTime.fromMillisecondsSinceEpoch(t as int);
      }

      DateTime? yasEstimatedDate;
      if (yasTahmini != null && yasTahmini['tahminiTarih'] != null) {
        final t = yasTahmini['tahminiTarih'];
        yasEstimatedDate = t is DateTime ? t : DateTime.fromMillisecondsSinceEpoch(t as int);
      }

      final normalRemainingDaysTotal = (reqPrimNormal - effective).clamp(0, reqPrimNormal);
      final normalRemainingYears = normalRemainingDaysTotal ~/ 360;
      final normalRemainingDaysOnly = normalRemainingDaysTotal % 360;
      final normalProgress = reqPrimNormal > 0 ? (effective / reqPrimNormal * 100).clamp(0.0, 100.0) : 0.0;

      final yasRemainingDaysTotal = reqPrimYas > 0 ? (reqPrimYas - effective).clamp(0, reqPrimYas) : 0;
      final yasRemainingYears = yasRemainingDaysTotal ~/ 360;
      final yasRemainingDaysOnly = yasRemainingDaysTotal % 360;
      final yasProgress = reqPrimYas > 0 ? (effective / reqPrimYas * 100).clamp(0.0, 100.0) : 0.0;

      // Kalan Yıl = gerekli yaşa kalan süre (iç halka yaş ile uyumlu)
      final now = DateTime.now();
      final normalYasHedefTarih = DateTime(_dogumTarihi!.year + reqAgeNormal, _dogumTarihi!.month, _dogumTarihi!.day);
      final normalKalanYasFark = normalYasHedefTarih.difference(now).inDays;
      final remainingYearsUntilAge = normalKalanYasFark <= 0 ? 0 : normalKalanYasFark ~/ 365;
      final remainingDaysUntilAge = normalKalanYasFark <= 0 ? 0 : normalKalanYasFark % 365;

      final yasYasHedefTarih = DateTime(_dogumTarihi!.year + reqAgeYas, _dogumTarihi!.month, _dogumTarihi!.day);
      final yasKalanYasFark = yasYasHedefTarih.difference(now).inDays;
      final yasRemainingYearsUntilAge = yasKalanYasFark <= 0 ? 0 : yasKalanYasFark ~/ 365;
      final yasRemainingDaysUntilAge = yasKalanYasFark <= 0 ? 0 : yasKalanYasFark % 365;

      return {
        'normalEmeklilik': {
          'requiredAge': reqAgeNormal,
          'requiredDays': reqPrimNormal,
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
      final effective = _effectiveToplamPrimGun;
      if (effective != null && _dogumTarihi != null) {
        int age = DateTime.now().year - _dogumTarihi!.year;
        if (DateTime(DateTime.now().year, _dogumTarihi!.month, _dogumTarihi!.day).isAfter(DateTime.now())) age--;
        return _calculateRetirementFallback(age, effective);
      }
      return null;
    }
  }

  /// 4a kriteri belirlenemediğinde basit 7200/5400 fallback
  Map<String, dynamic> _calculateRetirementFallback(int age, int effective) {
    const int normalRequiredDays = 7200;
    int partialRequiredDays = 5400;
    if (_ilkIseGirisTarihi != null && _ilkIseGirisTarihi!.isBefore(DateTime(1999, 9, 9))) {
      partialRequiredDays = 5000;
    }
    final normalRemainingDaysTotal = (normalRequiredDays - effective).clamp(0, normalRequiredDays);
    final partialRemainingDaysTotal = (partialRequiredDays - effective).clamp(0, partialRequiredDays);
    final now = DateTime.now();
    DateTime? normalEstimatedDate;
    if (normalRemainingDaysTotal > 0) {
      final y = normalRemainingDaysTotal ~/ 360;
      final d = normalRemainingDaysTotal % 360;
      normalEstimatedDate = DateTime(now.year + y, now.month, now.day).add(Duration(days: d));
    }
    DateTime? partialEstimatedDate;
    if (partialRemainingDaysTotal > 0) {
      final y = partialRemainingDaysTotal ~/ 360;
      final d = partialRemainingDaysTotal % 360;
      partialEstimatedDate = DateTime(now.year + y, now.month, now.day).add(Duration(days: d));
    }
    final normalYasHedef = DateTime(_dogumTarihi!.year + 60, _dogumTarihi!.month, _dogumTarihi!.day);
    final normalKalanYas = normalYasHedef.difference(now).inDays;
    final partialYasHedef = DateTime(_dogumTarihi!.year + 60, _dogumTarihi!.month, _dogumTarihi!.day);
    final partialKalanYas = partialYasHedef.difference(now).inDays;

    return {
      'normalEmeklilik': {
        'requiredAge': 60,
        'requiredDays': normalRequiredDays,
        'currentAge': age,
        'currentDays': _effectiveToplamPrimGun,
        'remainingYears': normalRemainingDaysTotal ~/ 360,
        'remainingDays': normalRemainingDaysTotal % 360,
        'remainingYearsUntilAge': normalKalanYas <= 0 ? 0 : normalKalanYas ~/ 365,
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
        'remainingYearsUntilAge': partialKalanYas <= 0 ? 0 : partialKalanYas ~/ 365,
        'remainingDaysUntilAge': partialKalanYas <= 0 ? 0 : partialKalanYas % 365,
        'progress': (effective / partialRequiredDays * 100).clamp(0.0, 100.0),
        'estimatedDate': partialEstimatedDate,
      },
    };
  }

  // Demo veriler - Kişisel bilgiler yoksa göster
  Map<String, dynamic> _getDemoRetirementInfo() {
    final bugun = DateTime.now();
    final demoYas = 35;
    final demoPrimGun = 4320; // 12 yıl * 360 gün
    final normalGerekliYas = 60;
    final normalGerekliGun = 7200; // Normal emeklilik
    final kismiGerekliYas = 60;
    final kismiGerekliGun = 5400; // Kısmi emeklilik
    
    final normalKalanGunToplam = normalGerekliGun - demoPrimGun;
    final normalKalanYil = normalKalanGunToplam ~/ 360; // SGK standardı: 1 yıl = 360 gün
    final normalKalanGun = normalKalanGunToplam % 360;
    
    final kismiKalanGunToplam = kismiGerekliGun - demoPrimGun;
    final kismiKalanYil = kismiKalanGunToplam ~/ 360;
    final kismiKalanGun = kismiKalanGunToplam % 360;
    
    final normalYilKadarYas = (normalGerekliYas - demoYas).clamp(0, 99);
    final kismiYilKadarYas = (kismiGerekliYas - demoYas).clamp(0, 99);

    return {
      'normalEmeklilik': {
        'requiredAge': normalGerekliYas,
        'requiredDays': normalGerekliGun,
        'currentAge': demoYas,
        'currentDays': demoPrimGun,
        'remainingYears': normalKalanYil,
        'remainingDays': normalKalanGun,
        'remainingYearsUntilAge': normalYilKadarYas,
        'remainingDaysUntilAge': 0,
        'progress': (demoPrimGun / normalGerekliGun * 100).clamp(0, 100),
        'estimatedDate': DateTime(bugun.year + normalKalanYil, bugun.month, bugun.day).add(Duration(days: normalKalanGun)),
      },
      'kismiEmeklilik': {
        'requiredAge': kismiGerekliYas,
        'requiredDays': kismiGerekliGun,
        'currentAge': demoYas,
        'currentDays': demoPrimGun,
        'remainingYears': kismiKalanYil,
        'remainingDays': kismiKalanGun,
        'remainingYearsUntilAge': kismiYilKadarYas,
        'remainingDaysUntilAge': 0,
        'progress': (demoPrimGun / kismiGerekliGun * 100).clamp(0, 100),
        'estimatedDate': DateTime(bugun.year + kismiKalanYil, bugun.month, bugun.day).add(Duration(days: kismiKalanGun)),
      },
    };
  }

  Map<String, dynamic> _getDemoSeverancePay() {
    return {
      'eligible': true,
      'daysWorked': 7300,
      'brut': 125000.0,
      'stampTax': 948.75,
      'net': 124051.25,
      'tavanAsildi': true,
    };
  }

  int _getDemoAnnualLeave() {
    return 20; // 5-15 yıl arası çalışma için
  }

  Map<String, double> _getDemoSalaryDeductions() {
    return {
      'brut': 50000.0,
      'sgk': 7000.0,
      'issizlik': 500.0,
      'gelirVergisi': 1792.0,
      'gelirVergisiDilimPercent': 27.0,
      'damgaVergisi': 500.0,
      'net': 40208.0,
    };
  }

  /// ✅ Profesyonel Kıdem Tazminatı Hesaplama (Tavan + Damga Vergisi)
  /// eligible: false ise 1 yıldan az çalışılmıştır (4857 sayılı İş K. md. 17).
  Map<String, dynamic>? _calculateSeverancePay() {
    if (_mevcutIsyeriBaslangic == null || _guncelBrutMaas == null) {
      return null;
    }

    try {
      final now = DateTime.now();
      final ceiling = _getKidemTavani(now);
      
      final daysWorked = now.difference(_mevcutIsyeriBaslangic!).inDays + 1;
      final eligible = daysWorked >= 365; // En az 1 yıl aynı işverende çalışma şartı
      
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
    if (year == 2020) return month < 7 ? 6379.86 : 6730.15;
    if (year == 2021) return month < 7 ? 7117.17 : 8284.51;
    if (year == 2022) return month < 7 ? 10848.59 : 15371.40;
    if (year == 2023) return month < 7 ? 19982.31 : 23489.83;
    if (year == 2024) return month < 7 ? 35058.58 : 41828.42;
    if (year == 2025) return month < 7 ? 46655.43 : 53919.68;
    if (year == 2026) return month < 7 ? 64948.77 : 64948.77;
    
    return 64948.77; // Varsayılan
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
  Map<String, double>? _calculateSalaryDeductions() {
    if (_guncelBrutMaas == null) return null;

    try {
      final now = DateTime.now();
      final year = now.year;
      final currentMonth = now.month - 1; // 0-based (Ocak=0, Şubat=1, ...)
      
      // SalaryEngine oluştur (Normal çalışan, teşviksiz)
      final engine = SalaryEngine(
        year: year,
        status: EmployeeStatus.normal,
        incentive: Incentive.none,
      );
      
      // Ocak'tan şu anki aya kadar hesapla (kümülatif vergi için)
      double cumulativeTaxBase = 0.0;
      MonthResult? currentMonthResult;
      
      for (int m = 0; m <= currentMonth; m++) {
        final result = engine.calculateNetFromGross(
          grossMonthly: _guncelBrutMaas!,
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
        'gelirVergisiDilimPercent': currentMonthResult.incomeTaxBracketPercent.toDouble(),
        'damgaVergisi': currentMonthResult.stampTax,
        'toplam': totalDeductions,
        'net': currentMonthResult.net,
      };
    } catch (e) {
      debugPrint('Maaş kesintileri hesaplama hatası: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Kişisel bilgiler eksikse demo veriler kullan
    final bool usingDemoData = _dogumTarihi == null ||
        _ilkIseGirisTarihi == null ||
        _toplamPrimGun == null;

    final retirementInfo = usingDemoData ? _getDemoRetirementInfo() : _calculateRetirement();
    final severancePay = usingDemoData ? _getDemoSeverancePay() : _calculateSeverancePay();
    final annualLeave = usingDemoData ? _getDemoAnnualLeave() : _calculateAnnualLeave();
    final deductions = usingDemoData ? _getDemoSalaryDeductions() : _calculateSalaryDeductions();

    final contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo veri uyarısı
            if (usingDemoData)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bunlar örnek verilerdir. Gerçek verilerinizi görmek için Ayarlar > Hesabım > Kişisel Bilgiler\'den bilgilerinizi girin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Üst bilgiler: İlk İşe Başlama + Mevcut İşyeri Başlangıç
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    Icons.calendar_today,
                    'İlk İşe Başlama Tarihim',
                    _formatDate(_ilkIseGirisTarihi),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    Icons.business,
                    'Mevcut İş Başlama Tarihim',
                    _formatDate(_mevcutIsyeriBaslangic),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Emeklilik Takibi (Tam genişlik)
            _buildRetirementTracking(retirementInfo, themeColor),
            
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
                    onInfoTap: () => _showSeverancePayDetails(severancePay),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniInfoCardLeftIconCompact(
                    icon: Icons.event_available_rounded,
                    iconColor: themeColor,
                    title: 'Yıllık İznim',
                    value: annualLeave != null
                        ? '$annualLeave Gün'
                        : '-',
                    subtitle: 'Bu Yıl',
                    onInfoTap: () => _showAnnualLeaveDetails(annualLeave),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Maaş ve Kesinti Analizi (Tam genişlik)
            if (deductions != null) _buildSalaryAnalysis(deductions, themeColor),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.assessment),
                label: const Text('Detaylı Analiz Raporu Oluştur'),
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
        backgroundColor: Colors.grey[100],
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


  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Emeklilik: Sol tarafta animasyonlu gauge göstergesi, sağ tarafta detaylar
  Widget _buildRetirementTracking(
      Map<String, dynamic>? retirementInfo, Color themeColor) {
    if (retirementInfo == null) return const SizedBox.shrink();

    final normalRetirement =
    retirementInfo['normalEmeklilik'] as Map<String, dynamic>?;
    if (normalRetirement == null) return const SizedBox.shrink();

    final progress = (normalRetirement['progress'] as num?)?.toDouble() ?? 0.0;
    final remainingYears = normalRetirement['remainingYearsUntilAge'] as int? ?? normalRetirement['remainingYears'] as int? ?? 0;
    final remainingDaysOnly = normalRetirement['remainingDaysUntilAge'] as int? ?? normalRetirement['remainingDays'] as int? ?? 0;
    final currentDays = normalRetirement['currentDays'] as int? ?? 0;
    final requiredDays = normalRetirement['requiredDays'] as int? ?? 7200;
    final totalRemainingDays = (requiredDays - currentDays).clamp(0, requiredDays);
    final gerekliGunDolu = currentDays >= requiredDays;
    final currentAge = normalRetirement['currentAge'] as int?;
    final requiredAge = (normalRetirement['requiredAge'] as num?)?.toInt() ?? 60;
    final dayProgress01 = (progress / 100.0).clamp(0.0, 1.0);
    final ageProgress01 = (currentAge != null && requiredAge > 0)
        ? (currentAge / requiredAge).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Emeklilik Takibim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
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
          const SizedBox(height: 16),

          // Sol: Çift donut (dış = prim, iç = yaş), Sağ: Detaylar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DualDonutProgressWidget(
                dayProgress01: dayProgress01,
                ageProgress01: ageProgress01,
              ),
              const SizedBox(width: 12),
              
              // Sağ: Detay Bilgileri (nokta renkleri gauge ile eşleşir: gün = yeşil, yıl = mavi)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRetirementDetailRow(
                      iconColor: const Color(0xFF76B900), // Dış gauge (gün) — NVIDIA yeşili
                      label: 'Tamamlanan Gün',
                      value: currentDays.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'),
                    ),
                    const SizedBox(height: 10),
                    _buildRetirementDetailRow(
                      iconColor: Colors.grey[200]!, // Gauge boş kısmı ile aynı gri
                      label: 'Kalan Gün',
                      value: gerekliGunDolu ? 'Gerekli günü doldurdunuz' : totalRemainingDays.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'),
                    ),
                    const SizedBox(height: 10),
                    _buildRetirementDetailRow(
                      iconColor: const Color(0xFF2196F3), // İç gauge (yaş) — donut mavisi
                      label: 'Kalan Yıl',
                      value: remainingYears == 0 && remainingDaysOnly == 0
                          ? (currentDays >= requiredDays ? 'Gerekli yaşı doldurdunuz' : '0 yıl')
                          : '$remainingYears yıl${remainingDaysOnly > 0 ? ' $remainingDaysOnly gün' : ''}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementDetailRow({
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
                    color: Colors.grey[800],
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Maaş & Kesinti Analizi (Net ele Geçen (%71) ₺35.746 format)
  Widget _buildSalaryAnalysis(Map<String, double> deductions, Color themeColor) {
    final brut = deductions['brut']!;
    final net = deductions['net']!;
    final sgk = deductions['sgk']!;
    final gelirVergisi = deductions['gelirVergisi']!;
    final damgaVergisi = deductions['damgaVergisi']!;

    final netPercent = (net / brut * 100);
    final sgkPercent = (sgk / brut * 100);
    final gelirVergisiPercent = (gelirVergisi / brut * 100);
    final damgaVergisiPercent = (damgaVergisi / brut * 100);
    final gelirVergisiDilimPercent = deductions['gelirVergisiDilimPercent']?.round() ?? (gelirVergisiPercent.round());

    final segments = [
      {'label': 'Net ele Geçen', 'value': net, 'percent': netPercent, 'color': Colors.blue},
      {'label': 'SGK Primi', 'value': sgk, 'percent': sgkPercent, 'color': Colors.orange},
      {'label': 'Gelir Vergisi', 'value': gelirVergisi, 'percent': gelirVergisiPercent, 'color': Colors.red, 'bracketPercent': gelirVergisiDilimPercent},
      {'label': 'Damga Vergisi', 'value': damgaVergisi, 'percent': damgaVergisiPercent, 'color': Colors.purple},
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Maaş ve Kesinti Analizi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showSalaryDetails(deductions, themeColor),
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
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -6),
                child: SizedBox(
                  width: 135,
                  height: 135,
                  child: _AnimatedDonutChart(segments: segments),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
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
                      const Divider(height: 18),
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
                                color: Colors.grey[800],
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
              ),
            ],
          ),
        ],
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
    final leftText = bracketPercent != null
        ? '$label (%$bracketPercent)'
        : '$label (%${percent.toStringAsFixed(0)})';
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            leftText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
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
              color: Colors.grey[900],
            ),
          ),
        ),
      ],
    );
  }

  /// Yaşa göre kalan süreyi metin olarak döndürür (info ekranı ve kart için).
  String _formatKalanSure(Map<String, dynamic> retirement) {
    final ry = retirement['remainingYearsUntilAge'] as int? ?? retirement['remainingYears'] as int? ?? 0;
    final rd = retirement['remainingDaysUntilAge'] as int? ?? retirement['remainingDays'] as int? ?? 0;
    final currentDays = retirement['currentDays'] as int? ?? 0;
    final requiredDays = retirement['requiredDays'] as int? ?? 0;
    if (ry == 0 && rd == 0) {
      return (requiredDays > 0 && currentDays >= requiredDays) ? 'Gerekli yaşı doldurdunuz' : '0 yıl';
    }
    return '$ry yıl${rd > 0 ? ' $rd gün' : ''}';
  }

  // Emeklilik Detayları Dialog
  void _showRetirementDetails(Map<String, dynamic> retirementInfo, Color themeColor) {
    final normalRetirement = retirementInfo['normalEmeklilik'] as Map<String, dynamic>?;
    final partialRetirement = retirementInfo['kismiEmeklilik'] as Map<String, dynamic>?;
    
    if (normalRetirement == null) return;

    final currentAge = normalRetirement['currentAge'] as int? ?? 0;
    final currentDays = normalRetirement['currentDays'] as int? ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.track_changes, color: themeColor, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Emeklilik Detayları',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Mevcut Yaşınız', '$currentAge yaş', isBold: true),
              _buildDetailRow('Toplam Prim Günü', '$currentDays gün', isBold: true),
              
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
              _buildDetailRow('Gerekli Yaş', '${normalRetirement['requiredAge']} yaş'),
              _buildDetailRow('Gerekli Prim Günü', '${normalRetirement['requiredDays']} gün'),
              _buildDetailRow('İlerleme', '%${((normalRetirement['progress'] as num?) ?? 0).toStringAsFixed(1)}'),
              _buildDetailRow('Kalan Süre', _formatKalanSure(normalRetirement)),
              if (normalRetirement['estimatedDate'] != null)
                _buildDetailRow('Tahmini Tarih', DateFormat('dd.MM.yyyy', 'tr_TR').format(normalRetirement['estimatedDate'] as DateTime)),
              
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
                _buildDetailRow('Gerekli Yaş', '${partialRetirement['requiredAge']} yaş'),
                _buildDetailRow('Gerekli Prim Günü', '${partialRetirement['requiredDays']} gün'),
                _buildDetailRow('İlerleme', '%${((partialRetirement['progress'] as num?) ?? 0).toStringAsFixed(1)}'),
                _buildDetailRow('Kalan Süre', _formatKalanSure(partialRetirement)),
                if (partialRetirement['estimatedDate'] != null)
                  _buildDetailRow('Tahmini Tarih', DateFormat('dd.MM.yyyy', 'tr_TR').format(partialRetirement['estimatedDate'] as DateTime)),
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
      int totalMonths = (now.year * 12 + now.month) - (_mevcutIsyeriBaslangic!.year * 12 + _mevcutIsyeriBaslangic!.month);
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
        title: Row(
          children: [
            Icon(Icons.payments_rounded, color: themeColor, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Kıdem Tazminatı Detayları',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kıdem tazminatına hak kazanmak için aynı işveren bünyesinde en az 1 yıl (365 gün) çalışmanız gerekir. Şu an $daysWorked gün çalışmış bulunuyorsunuz.',
                          style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
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
                      Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kıdem tazminatınız tavanı aştığından yeni tavan belirlenince tekrar hesaplanacaktır. Şu anki hesaplama mevcut tavan üzerinden yapılmaktadır.',
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade900, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Başlangıç Tarihi', _formatDate(_mevcutIsyeriBaslangic)),
              _buildDetailRow('Hesaplama Tarihi', _formatDate(now)),
              _buildDetailRow('Çalışma Süresi', '$workYears yıl $workMonths ay ($daysWorked gün)'),
              _buildDetailRow('Kıdem Tazminatı Tavanı', _formatCurrencyWithKurus(_getKidemTavani(now))),
              const SizedBox(height: 6),
              Text(
                'Bu tutar, hesaplama tarihi itibarıyla güncel brüt maaş ve tavan üzerinden hesaplanmıştır.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 20),
              _buildDetailRow('Aylık Brüt Maaş', _formatCurrency(_guncelBrutMaas)),
              const Divider(height: 20),
              _buildDetailRow('Brüt Kıdem Tazminatı', _formatCurrencyWithKurus(brutSeverance)),
              _buildDetailRow('Damga Vergisi (%0.759)', _formatCurrencyWithKurus(stampTax), color: Colors.red),
              _buildDetailRow('Net Kıdem Tazminatı', _formatCurrencyWithKurus(netSeverance), isBold: true, color: eligible ? Colors.green : Colors.grey),
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
        title: Row(
          children: [
            Icon(Icons.event_available_rounded, color: themeColor, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Yıllık İzin Detayları',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Başlangıç Tarihi', _formatDate(_mevcutIsyeriBaslangic)),
              _buildDetailRow('Çalışma Süresi', '$workYears yıl'),
              const Divider(height: 20),
              _buildDetailRow('Yıllık İzin Hakkı', '$annualLeave gün', isBold: true),
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  // Maaş, Mesai ve Kesinti Analizi: Maaş ve Kesinti verileri + Aylık/Yıllık Özet, takvim/sonuçlar
  void _showSalaryDetails(Map<String, double> deductions, Color themeColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.4,
        maxChildSize: 1.0,
        expand: true,
        builder: (context, scrollController) => Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: themeColor, size: 28),
                  const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Maaş, Mesai ve Kesinti Analizi',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(6, 16, 6, 0),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: const MesaiTakipContent(calendarOnly: true),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _gelirVergisiDilimLabel(Map<String, double> deductions) {
    final p = deductions['gelirVergisiDilimPercent']?.round();
    if (p == null) return 'Gelir vergisi';
    return '%$p';
  }

  // Detay satırı widget'ı
  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
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
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
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
  State<_DualDonutProgressWidget> createState() => _DualDonutProgressWidgetState();
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

  static const Color _outerGreen = Color(0xFF76B900);
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
              outerColor: _outerGreen,
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
            Shadow(blurRadius: 3.5, color: Colors.black54, offset: Offset(1, 1.5)),
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

  const _AnimatedDonutChart({required this.segments});

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
        size: const Size(135, 135),
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
    final radius = size.width / 2 - 10;
    final strokeWidth = radius * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);

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
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweep, false, paint);

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
  State<_KidemTazminatiAnimatedCardImpl> createState() => _KidemTazminatiAnimatedCardImplState();
}

class _KidemTazminatiAnimatedCardImplState extends State<_KidemTazminatiAnimatedCardImpl>
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
      valueStr = '-';
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
                    color: Colors.grey[800],
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
                    child: Icon(Icons.info_outline, size: 16, color: themeColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valueStr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
