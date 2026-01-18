import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class CalismaHayatimEkrani extends StatefulWidget {
  const CalismaHayatimEkrani({super.key});

  @override
  State<CalismaHayatimEkrani> createState() => _CalismaHayatimEkraniState();
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
          _dogumTarihi = DateTime.fromMillisecondsSinceEpoch(map['dogumTarihi'] as int);
        }
        if (map['ilkIseGirisTarihi'] != null) {
          _ilkIseGirisTarihi = DateTime.fromMillisecondsSinceEpoch(map['ilkIseGirisTarihi'] as int);
        }
        if (map['toplamPrimGun'] != null) {
          _toplamPrimGun = int.tryParse(map['toplamPrimGun'].toString());
        }
        if (map['mevcutIsyeriBaslangic'] != null) {
          _mevcutIsyeriBaslangic = DateTime.fromMillisecondsSinceEpoch(map['mevcutIsyeriBaslangic'] as int);
        }
        if (map['guncelBrutMaas'] != null) {
          _guncelBrutMaas = double.tryParse(map['guncelBrutMaas'].toString());
        }
      }
    } catch (e) {
      debugPrint('Kişisel bilgiler yüklenirken hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double? value) {
    if (value == null) return '0 ₺';
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    return formatter.format(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
  }

  // Emeklilik hesaplamaları
  Map<String, dynamic>? _calculateRetirement() {
    if (_dogumTarihi == null || _ilkIseGirisTarihi == null || _toplamPrimGun == null) {
      return null;
    }
    
    try {
      final now = DateTime.now();
      int age = now.year - _dogumTarihi!.year;
      if (DateTime(now.year, _dogumTarihi!.month, _dogumTarihi!.day).isAfter(now)) {
        age--;
      }
      
      // Basitleştirilmiş emeklilik yaşı hesaplama (4/a için)
      int requiredAge = 60;
      int requiredDays = 5400;
      
      if (_ilkIseGirisTarihi!.isBefore(DateTime(2008, 5, 1))) {
        requiredDays = 5000;
      }
      
      final remainingYears = requiredAge - age;
      final remainingDays = requiredDays - _toplamPrimGun!;
      final progress = (_toplamPrimGun! / requiredDays * 100).clamp(0, 100);
      
      // Tahmini emeklilik tarihi
      DateTime? estimatedDate;
      if (remainingYears > 0) {
        estimatedDate = DateTime(now.year + remainingYears, now.month, now.day);
      }
      
      return {
        'normalEmeklilik': {
          'requiredAge': requiredAge,
          'requiredDays': requiredDays,
          'currentAge': age,
          'currentDays': _toplamPrimGun,
          'remainingYears': remainingYears > 0 ? remainingYears : 0,
          'remainingMonths': remainingDays > 0 ? (remainingDays / 30).floor() : 0,
          'progress': progress,
          'estimatedDate': estimatedDate,
        },
      };
    } catch (e) {
      debugPrint('Emeklilik hesaplama hatası: $e');
      return null;
    }
  }

  // Kıdem tazminatı hesaplama
  double? _calculateSeverancePay() {
    if (_mevcutIsyeriBaslangic == null || _guncelBrutMaas == null) {
      return null;
    }
    
    try {
      final now = DateTime.now();
      final years = now.year - _mevcutIsyeriBaslangic!.year;
      final months = now.month - _mevcutIsyeriBaslangic!.month;
      final totalMonths = years * 12 + months;
      
      final dailySalary = _guncelBrutMaas! / 30;
      final severancePay = dailySalary * totalMonths;
      
      // 2026 tavan kontrolü
      final asgariUcret = 33030.0;
      final tavan = asgariUcret * 9.0;
      
      return severancePay > tavan ? tavan : severancePay;
    } catch (e) {
      debugPrint('Kıdem tazminatı hesaplama hatası: $e');
      return null;
    }
  }

  // Yıllık izin süresi hesaplama
  int? _calculateAnnualLeave() {
    if (_mevcutIsyeriBaslangic == null) {
      return null;
    }
    
    try {
      final now = DateTime.now();
      final years = now.year - _mevcutIsyeriBaslangic!.year;
      
      if (years < 1) {
        return 0;
      } else if (years < 5) {
        return 14;
      } else if (years < 15) {
        return 20;
      } else {
        return 26;
      }
    } catch (e) {
      debugPrint('Yıllık izin hesaplama hatası: $e');
      return null;
    }
  }

  // Maaş kesintileri hesaplama
  Map<String, double>? _calculateSalaryDeductions() {
    if (_guncelBrutMaas == null) {
      return null;
    }
    
    try {
      final brutMaas = _guncelBrutMaas!;
      
      // SGK primi işçi payı %14
      final sgkIsci = brutMaas * 0.14;
      
      // İşsizlik sigortası işçi payı %1
      final issizlikIsci = brutMaas * 0.01;
      
      // Gelir vergisi (basitleştirilmiş)
      final gelirVergisiMatrahi = brutMaas - sgkIsci - issizlikIsci;
      double gelirVergisi = 0;
      
      if (gelirVergisiMatrahi > 110000) {
        gelirVergisi = (gelirVergisiMatrahi - 110000) * 0.35 + 110000 * 0.15;
      } else {
        gelirVergisi = gelirVergisiMatrahi * 0.15;
      }
      
      // Damga vergisi %0.759
      final damgaVergisi = brutMaas * 0.00759;
      
      final toplamKesinti = sgkIsci + issizlikIsci + gelirVergisi + damgaVergisi;
      final netMaas = brutMaas - toplamKesinti;
      
      return {
        'brut': brutMaas,
        'sgk': sgkIsci,
        'issizlik': issizlikIsci,
        'gelirVergisi': gelirVergisi,
        'damgaVergisi': damgaVergisi,
        'toplam': toplamKesinti,
        'net': netMaas,
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

    // Kişisel bilgiler eksikse uyarı göster
    if (_dogumTarihi == null || _ilkIseGirisTarihi == null || _toplamPrimGun == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Kişisel Bilgiler Eksik',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Çalışma Hayatım özelliğini kullanmak için Hesabım > Kişisel Bilgiler bölümünden bilgilerinizi doldurun.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final retirementInfo = _calculateRetirement();
    final severancePay = _calculateSeverancePay();
    final annualLeave = _calculateAnnualLeave();
    final deductions = _calculateSalaryDeductions();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kariyer Özeti
            _buildCareerSummary(themeColor),
            const SizedBox(height: 16),
            
            // Emeklilik Takibi ve Yan Kartlar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0, // Tam kare
                    child: _buildRetirementTracking(retirementInfo, themeColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildSmallCard(
                          'Kıdem Tazminatı',
                          severancePay != null ? _formatCurrency(severancePay) : '-',
                          Icons.receipt_long,
                          Colors.orange,
                          isEstimated: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildSmallCard(
                          'Yıllık İzin Hakkı',
                          annualLeave != null ? '$annualLeave Gün' : '-',
                          Icons.beach_access,
                          Colors.blue,
                          subtitle: 'Bu Yıl',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Maaş ve Kesinti Analizi
            if (deductions != null)
              _buildSalaryAnalysis(deductions, themeColor),
            const SizedBox(height: 16),
            
            // Detaylı Analiz Raporu Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Detaylı analiz raporu
                },
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
        ),
      ),
    );

  Widget _buildCareerSummary(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kariyer Özeti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  Icons.calendar_today,
                  'İşe Başlama Tarihi',
                  _formatDate(_ilkIseGirisTarihi),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  Icons.work,
                  'Toplam Prim Gün',
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
                  'Mevcut İşyeri Başlangıç',
                  _formatDate(_mevcutIsyeriBaslangic),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  Icons.account_balance_wallet,
                  'Güncel Maaş',
                  _guncelBrutMaas != null ? '${_formatCurrency(_guncelBrutMaas)} (Brüt)' : '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[400],
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
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
        ),
      ],
    );
  }

  Widget _buildRetirementTracking(Map<String, dynamic>? retirementInfo, Color themeColor) {
    if (retirementInfo == null) {
      return Container();
    }
    
    final normalRetirement = retirementInfo['normalEmeklilik'] as Map<String, dynamic>?;
    if (normalRetirement == null) {
      return Container();
    }
    
    final progress = normalRetirement['progress'] as double? ?? 0.0;
    final remainingYears = normalRetirement['remainingYears'] as int? ?? 0;
    final remainingMonths = normalRetirement['remainingMonths'] as int? ?? 0;
    final currentAge = normalRetirement['currentAge'] as int? ?? 0;
    final estimatedDate = normalRetirement['estimatedDate'] as DateTime?;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emeklilik Takibi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '%${progress.toInt()}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kalan: $remainingYears Yıl${remainingMonths > 0 ? ' $remainingMonths Ay' : ''}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$currentAge Yaşında',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (estimatedDate != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tahmini: ${DateFormat('yyyy', 'tr_TR').format(estimatedDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallCard(String title, String value, IconData icon, Color color, {String? subtitle, bool isEstimated = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
          if (isEstimated) ...[
            const SizedBox(height: 2),
            Text(
              '(Tahmini)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

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
      {'label': 'Net Ele Geçen', 'value': net, 'percent': netPercent, 'color': Colors.blue},
      {'label': 'SGK Primi (İşçi)', 'value': sgk, 'percent': sgkPercent, 'color': Colors.orange},
      {'label': 'Gelir Vergisi', 'value': gelirVergisi, 'percent': gelirVergisiPercent, 'color': Colors.red},
      {'label': 'Damga Vergisi', 'value': damgaVergisi, 'percent': damgaVergisiPercent, 'color': Colors.purple},
    ];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maaş ve Kesinti Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  size: const Size(150, 150),
                  painter: DonutChartPainter(segments),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var segment in segments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: segment['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(segment['percent'] as double? ?? 0.0).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    segment['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(segment['value'] as double),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Toplam Brüt',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          _formatCurrency(brut),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ],
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
    
    double startAngle = -math.pi / 2; // Başlangıç üstten
    
    for (var segment in segments) {
      final percent = segment['percent'] as double;
      final sweepAngle = (percent / 100) * 2 * math.pi;
      final color = segment['color'] as Color;
      
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius;
      
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      
      // Segment ortasına yüzde yazısı ekle
      if (percent > 3) { // Sadece %3'ten büyük segmentlere yazı ekle
        final textAngle = startAngle + sweepAngle / 2;
        // Segment'in tam ortası (donut'un merkez çizgisi) - biraz daha dışarıda
        final textRadius = radius - strokeWidth * 0.35; // Segment'in ortasına yakın, daha dışarıda
        final textX = center.dx + textRadius * math.cos(textAngle);
        final textY = center.dy + textRadius * math.sin(textAngle);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: '%${percent.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
        );
      }
      
      startAngle += sweepAngle;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
