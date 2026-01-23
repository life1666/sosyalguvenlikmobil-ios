import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../mesaitakip/mesaihesaplama.dart';

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
  DateTime? _mevcutIsyeriBaslangic;
  double? _guncelBrutMaas;
  bool _isLoading = true;


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
        if (map['mevcutIsyeriBaslangic'] != null) {
          _mevcutIsyeriBaslangic = DateTime.fromMillisecondsSinceEpoch(
              map['mevcutIsyeriBaslangic'] as int);
        }
        if (map['guncelBrutMaas'] != null) {
          _guncelBrutMaas =
              double.tryParse(map['guncelBrutMaas'].toString());
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
      final now = DateTime.now();
      int age = now.year - _dogumTarihi!.year;
      if (DateTime(now.year, _dogumTarihi!.month, _dogumTarihi!.day)
          .isAfter(now)) {
        age--;
      }

      // Normal emeklilik (7200 gün, 60 yaş)
      int normalRequiredAge = 60;
      int normalRequiredDays = 7200;

      final normalRemainingDaysTotal = (normalRequiredDays - _toplamPrimGun!).clamp(0, normalRequiredDays);
      final normalRemainingYears = normalRemainingDaysTotal ~/ 360; // SGK standardı: 1 yıl = 360 gün
      final normalRemainingDaysOnly = normalRemainingDaysTotal % 360; // Kalan günler
      final normalProgress = (_toplamPrimGun! / normalRequiredDays * 100).clamp(0, 100);

      DateTime? normalEstimatedDate;
      if (normalRemainingDaysTotal > 0) {
        final araTarih = DateTime(now.year + normalRemainingYears, now.month, now.day);
        normalEstimatedDate = araTarih.add(Duration(days: normalRemainingDaysOnly));
      }

      // Kısmi emeklilik (5400 gün, 60 yaş) - 2008 öncesi başlayanlar için
      int partialRequiredAge = 60;
      int partialRequiredDays = 5400;
      
      if (_ilkIseGirisTarihi!.isBefore(DateTime(1999, 4, 23))) {
        partialRequiredDays = 5000; // 1999 öncesi
      }

      final partialRemainingDaysTotal = (partialRequiredDays - _toplamPrimGun!).clamp(0, partialRequiredDays);
      final partialRemainingYears = partialRemainingDaysTotal ~/ 360; // SGK standardı: 1 yıl = 360 gün
      final partialRemainingDaysOnly = partialRemainingDaysTotal % 360; // Kalan günler
      final partialProgress = (_toplamPrimGun! / partialRequiredDays * 100).clamp(0, 100);

      DateTime? partialEstimatedDate;
      if (partialRemainingDaysTotal > 0) {
        final araTarih = DateTime(now.year + partialRemainingYears, now.month, now.day);
        partialEstimatedDate = araTarih.add(Duration(days: partialRemainingDaysOnly));
      }

      return {
        'normalEmeklilik': {
          'requiredAge': normalRequiredAge,
          'requiredDays': normalRequiredDays,
          'currentAge': age,
          'currentDays': _toplamPrimGun,
          'remainingYears': normalRemainingYears,
          'remainingDays': normalRemainingDaysOnly,
          'progress': normalProgress,
          'estimatedDate': normalEstimatedDate,
        },
        'kismiEmeklilik': {
          'requiredAge': partialRequiredAge,
          'requiredDays': partialRequiredDays,
          'currentAge': age,
          'currentDays': _toplamPrimGun,
          'remainingYears': partialRemainingYears,
          'remainingDays': partialRemainingDaysOnly,
          'progress': partialProgress,
          'estimatedDate': partialEstimatedDate,
        },
      };
    } catch (e) {
      debugPrint('Emeklilik hesaplama hatası: $e');
      return null;
    }
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
    
    return {
      'normalEmeklilik': {
        'requiredAge': normalGerekliYas,
        'requiredDays': normalGerekliGun,
        'currentAge': demoYas,
        'currentDays': demoPrimGun,
        'remainingYears': normalKalanYil,
        'remainingDays': normalKalanGun,
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
        'progress': (demoPrimGun / kismiGerekliGun * 100).clamp(0, 100),
        'estimatedDate': DateTime(bugun.year + kismiKalanYil, bugun.month, bugun.day).add(Duration(days: kismiKalanGun)),
      },
    };
  }

  Map<String, double> _getDemoSeverancePay() {
    return {
      'brut': 125000.0,
      'damga': 948.75,
      'net': 124051.25,
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
      'damgaVergisi': 500.0,
      'net': 40208.0,
    };
  }

  /// ✅ Profesyonel Kıdem Tazminatı Hesaplama (Tavan + Damga Vergisi)
  Map<String, double>? _calculateSeverancePay() {
    if (_mevcutIsyeriBaslangic == null || _guncelBrutMaas == null) {
      return null;
    }

    try {
      final now = DateTime.now();
      final ceiling = _getKidemTavani(now);
      
      final daysWorked = now.difference(_mevcutIsyeriBaslangic!).inDays + 1;
      final dailySalary = _guncelBrutMaas! / 365; // Yıllık bazda
      
      double severancePay = dailySalary * daysWorked;
      
      // Tavan kontrolü
      final dailyCeiling = ceiling / 365;
      if (dailySalary > dailyCeiling) {
        severancePay = dailyCeiling * daysWorked;
      }
      
      final stampTax = severancePay * 0.00759; // Damga vergisi
      final netSeverancePay = severancePay - stampTax;
      
      return {
        'brut': severancePay,
        'net': netSeverancePay,
        'stampTax': stampTax,
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
            
            // Kariyer Özeti Container - diğer tüm kutuları sarar (resimdeki gibi)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kariyer Özeti bilgileri (başlık kaldırıldı)
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
                          Icons.work,
                          'Toplam Prim Günüm',
                          _toplamPrimGun != null ? '$_toplamPrimGun Gün' : '-',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          Icons.business,
                          'Mevcut İşyeri Başlangıç Tarihi',
                          _formatDate(_mevcutIsyeriBaslangic),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryItem(
                          Icons.account_balance_wallet,
                          'Güncel Maaşım',
                          _guncelBrutMaas != null
                              ? '${_formatCurrency(_guncelBrutMaas)} (Brüt)'
                              : '-',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Emeklilik Takibi + Kıdem/Yıllık İzin (başlık kaldırıldı)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRetirementTracking(retirementInfo, themeColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMiniInfoCardLeftIconCompact(
                              icon: Icons.payments_rounded,
                              iconColor: Colors.orange,
                              title: 'Kıdem Tazminatım',
                              value: severancePay != null
                                  ? _formatCurrency(severancePay['net']!)
                                  : '-',
                              isEstimated: true,
                              onInfoTap: () => _showSeverancePayDetails(severancePay),
                            ),
                            const SizedBox(height: 12),
                            _buildMiniInfoCardLeftIconCompact(
                              icon: Icons.event_available_rounded,
                              iconColor: Colors.blue,
                              title: 'Yıllık İzin',
                              value: annualLeave != null
                                  ? '$annualLeave Gün'
                                  : '-',
                              subtitle: 'Bu Yıl',
                              onInfoTap: () => _showAnnualLeaveDetails(annualLeave),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Maaş ve Kesinti Analizi
                  if (deductions != null) _buildSalaryAnalysis(deductions, themeColor),
                ],
              ),
            ),

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
        Icon(icon, color: Colors.grey[400], size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Emeklilik: donut + alt yazılar sığsın diye alan optimize
  Widget _buildRetirementTracking(
      Map<String, dynamic>? retirementInfo, Color themeColor) {
    if (retirementInfo == null) return const SizedBox.shrink();

    final normalRetirement =
    retirementInfo['normalEmeklilik'] as Map<String, dynamic>?;
    if (normalRetirement == null) return const SizedBox.shrink();

    final progress = (normalRetirement['progress'] as num?)?.toDouble() ?? 0.0;
    final remainingYears = normalRetirement['remainingYears'] as int? ?? 0;
    final remainingDaysOnly = normalRetirement['remainingDays'] as int? ?? 0;
    final currentDays = normalRetirement['currentDays'] as int? ?? 0;
    final requiredDays = normalRetirement['requiredDays'] as int? ?? 7200;
    final totalRemainingDays = requiredDays - currentDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Emeklilik Takibi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
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
          const SizedBox(height: 10),

          // İki sütunlu gösterim
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'TAMAMLANAN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '%${progress.toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currentDays.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} gün',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'KALAN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '%${(100 - progress).toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${totalRemainingDays.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} gün',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),

          const SizedBox(height: 8),

          // Kalan süre
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '~$remainingYears yıl ${remainingDaysOnly > 0 ? '$remainingDaysOnly gün' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
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

    final segments = [
      {'label': 'Net ele Geçen', 'value': net, 'percent': netPercent, 'color': Colors.blue},
      {'label': 'SGK Primi', 'value': sgk, 'percent': sgkPercent, 'color': Colors.orange},
      {'label': 'Gelir Vergisi', 'value': gelirVergisi, 'percent': gelirVergisiPercent, 'color': Colors.red},
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
                  child: CustomPaint(
                    size: const Size(135, 135),
                    painter: DonutChartPainter(segments),
                  ),
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
  }) {
    final leftText = '$label (%${percent.toStringAsFixed(0)})';

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
              _buildDetailRow('İlerleme', '%${(normalRetirement['progress'] as num).toStringAsFixed(1)}'),
              _buildDetailRow('Kalan Süre', '${normalRetirement['remainingYears']} yıl ${(normalRetirement['remainingDays'] as int) > 0 ? '${normalRetirement['remainingDays']} gün' : ''}'),
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
                _buildDetailRow('İlerleme', '%${(partialRetirement['progress'] as num).toStringAsFixed(1)}'),
                _buildDetailRow('Kalan Süre', '${partialRetirement['remainingYears']} yıl ${(partialRetirement['remainingDays'] as int) > 0 ? '${partialRetirement['remainingDays']} gün' : ''}'),
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
  void _showSeverancePayDetails(Map<String, double>? severancePay) {
    if (severancePay == null) return;

    final now = DateTime.now();
    final workYears = _mevcutIsyeriBaslangic != null 
        ? now.year - _mevcutIsyeriBaslangic!.year 
        : 0;
    final workMonths = _mevcutIsyeriBaslangic != null
        ? now.month - _mevcutIsyeriBaslangic!.month + (workYears * 12)
        : 0;

    final brutSeverance = severancePay['brut'] ?? 0;
    final netSeverance = severancePay['net'] ?? 0;
    final stampTax = severancePay['stampTax'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payments_rounded, color: Colors.orange, size: 28),
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
              _buildDetailRow('Başlangıç Tarihi', _formatDate(_mevcutIsyeriBaslangic)),
              _buildDetailRow('Çalışma Süresi', '$workYears yıl $workMonths ay'),
              const Divider(height: 20),
              _buildDetailRow('Aylık Brüt Maaş', _formatCurrency(_guncelBrutMaas)),
              const Divider(height: 20),
              _buildDetailRow('Brüt Kıdem Tazminatı', _formatCurrency(brutSeverance)),
              _buildDetailRow('Damga Vergisi (%0.759)', _formatCurrency(stampTax), color: Colors.red),
              _buildDetailRow('Net Kıdem Tazminatı', _formatCurrency(netSeverance), isBold: true, color: Colors.green),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kıdem Tazminatı Nedir?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
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

    final now = DateTime.now();
    final workYears = _mevcutIsyeriBaslangic != null 
        ? now.year - _mevcutIsyeriBaslangic!.year 
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event_available_rounded, color: Colors.blue, size: 28),
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Yıllık İzin Süresi',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
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
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: themeColor, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Maaş Analizi Detayları',
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
              _buildDetailRow('Brüt Maaş', _formatCurrency(brut), isBold: true),
              const Divider(height: 20),
              const Text(
                'Kesintiler:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('SGK Primi (%14)', _formatCurrency(sgk)),
              _buildDetailRow('İşsizlik Primi (%1)', _formatCurrency(issizlik)),
              _buildDetailRow('Gelir Vergisi', _formatCurrency(gelirVergisi)),
              _buildDetailRow('Damga Vergisi (%0.759)', _formatCurrency(damgaVergisi)),
              const Divider(height: 20),
              _buildDetailRow('Toplam Kesinti', _formatCurrency(toplam), color: Colors.red),
              _buildDetailRow('Net Maaş', _formatCurrency(net), isBold: true, color: Colors.green),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;

  DonutChartPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final innerRadius = radius * 0.6;
    final strokeWidth = radius - innerRadius;

    double startAngle = -math.pi / 2;

    for (var segment in segments) {
      final percent = (segment['percent'] as num).toDouble();
      final sweepAngle = (percent / 100) * 2 * math.pi;
      final color = segment['color'] as Color;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
