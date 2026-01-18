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

  final GlobalKey _careerKey = GlobalKey();
  double _careerHeight = 0;

  final double _retirementScale = 1.15;

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

      int requiredAge = 60;
      int requiredDays = 5400;

      if (_ilkIseGirisTarihi!.isBefore(DateTime(2008, 5, 1))) {
        requiredDays = 5000;
      }

      final remainingYears = requiredAge - age;
      final remainingDays = requiredDays - _toplamPrimGun!;
      final progress = (_toplamPrimGun! / requiredDays * 100).clamp(0, 100);

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

      final asgariUcret = 33030.0;
      final tavan = asgariUcret * 9.0;

      return severancePay > tavan ? tavan : severancePay;
    } catch (e) {
      debugPrint('Kıdem tazminatı hesaplama hatası: $e');
      return null;
    }
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

  Map<String, double>? _calculateSalaryDeductions() {
    if (_guncelBrutMaas == null) return null;

    try {
      final brutMaas = _guncelBrutMaas!;
      final sgkIsci = brutMaas * 0.14;
      final issizlikIsci = brutMaas * 0.01;

      final gelirVergisiMatrahi = brutMaas - sgkIsci - issizlikIsci;
      double gelirVergisi = 0;

      if (gelirVergisiMatrahi > 110000) {
        gelirVergisi =
            (gelirVergisiMatrahi - 110000) * 0.35 + 110000 * 0.15;
      } else {
        gelirVergisi = gelirVergisiMatrahi * 0.15;
      }

      final damgaVergisi = brutMaas * 0.00759;
      final toplamKesinti =
          sgkIsci + issizlikIsci + gelirVergisi + damgaVergisi;
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

    if (_dogumTarihi == null ||
        _ilkIseGirisTarihi == null ||
        _toplamPrimGun == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
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
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _careerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        final h = box.size.height;
        if ((h - _careerHeight).abs() > 0.5) {
          setState(() => _careerHeight = h);
        }
      }
    });

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
            _buildCareerSummary(themeColor),
            const SizedBox(height: 16),

            if (_careerHeight > 0)
              SizedBox(
                height: _careerHeight * _retirementScale,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRetirementTracking(retirementInfo, themeColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildMiniInfoCardLeftIconCompact(
                              icon: Icons.payments_rounded,
                              iconColor: Colors.orange,
                              title: 'Kıdem Tazminatı',
                              value: severancePay != null
                                  ? _formatCurrency(severancePay)
                                  : '-',
                              isEstimated: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildMiniInfoCardLeftIconCompact(
                              icon: Icons.event_available_rounded,
                              iconColor: Colors.blue,
                              title: 'Yıllık İzin',
                              value: annualLeave != null
                                  ? '$annualLeave Gün'
                                  : '-',
                              subtitle: 'Bu Yıl',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            if (deductions != null) _buildSalaryAnalysis(deductions, themeColor),

            const SizedBox(height: 16),

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
        ),
      ),
    );
  }

  Widget _buildCareerSummary(Color themeColor) {
    return Container(
      key: _careerKey,
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
                  _guncelBrutMaas != null
                      ? '${_formatCurrency(_guncelBrutMaas)} (Brüt)'
                      : '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    final remainingMonths = normalRetirement['remainingMonths'] as int? ?? 0;
    final currentAge = normalRetirement['currentAge'] as int? ?? 0;
    final estimatedDate = normalRetirement['estimatedDate'] as DateTime?;

    const double donutSize = 80.0; // ✅ daha küçük
    const double donutStroke = 9.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emeklilik Takibi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),

          Center(
            child: SizedBox(
              width: donutSize,
              height: donutSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: donutSize,
                    height: donutSize,
                    child: CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: donutStroke,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '%${progress.toInt()}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$currentAge Yaş',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              'Kalan: $remainingYears Yıl${remainingMonths > 0 ? ' $remainingMonths Ay' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Center(
            child: Text(
              '$currentAge Yaşında',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),

          const Spacer(),

          if (estimatedDate != null)
            Center(
              child: Text(
                'Tahmini: ${DateFormat('yyyy', 'tr_TR').format(estimatedDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ BOŞLUK AZALTILDI: başlık-tutar arası 8 -> 4, subtitle arası 4 -> 2
  Widget _buildMiniInfoCardLeftIconCompact({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    bool isEstimated = false,
  }) {
    const double leftIndent = 32; // ikon hizası

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4), // ✅ azaltıldı

          Padding(
            padding: const EdgeInsets.only(left: leftIndent),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 2), // ✅ azaltıldı
            Padding(
              padding: const EdgeInsets.only(left: leftIndent),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
          ],

          if (isEstimated) ...[
            const SizedBox(height: 2), // ✅ azaltıldı
            Padding(
              padding: const EdgeInsets.only(left: leftIndent),
              child: Text(
                '(Tahmini)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
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
          const SizedBox(height: 10),
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
