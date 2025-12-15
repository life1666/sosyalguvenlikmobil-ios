import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screens/hesaplamalar_ekrani.dart';
import '../utils/analytics_helper.dart';

void main() {
  runApp(const EmeklilikTakipApp());
}

class EmeklilikTakipApp extends StatelessWidget {
  const EmeklilikTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      child: const EmeklilikTakipPage(),
    );
  }
}

class EmeklilikTakipPage extends StatefulWidget {
  const EmeklilikTakipPage({super.key});

  @override
  State<EmeklilikTakipPage> createState() => _EmeklilikTakipPageState();
}

class _EmeklilikTakipPageState extends State<EmeklilikTakipPage> {
  // Veriler
  DateTime? emeklilikTarihi;
  DateTime? sigortaBaslangicTarihi;
  bool hasData = false;
  String emeklilikTipi = ''; // Normal/Yaş Haddi vs.
  String hesaplamaTuru = ''; // 4/a (SSK), 4/b (Bağ-kur), 4/c (Memur)
  
  // Normal Emeklilik bilgileri
  Map<String, dynamic> normalEmeklilik = {};
  
  // Yaş Haddinden Emeklilik bilgileri
  Map<String, dynamic> yasHaddindenEmeklilik = {};

  // Günlük takip değişkenleri
  int gecmisGunler = 0;
  int kalanGunler = 0; // Kalan günler (0-29 arası, ay çıkarıldıktan sonra)
  int toplamKalanGunler = 0; // Toplam kalan gün sayısı (ilerleme çubuğu için)
  int kalanAy = 0;
  int kalanYil = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('emeklilik_takip_opened');
    _loadRetirementData();
  }

  Future<void> _loadRetirementData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('emeklilik_takip_data');
    
    if (savedData != null && savedData.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(savedData);
        final timestamp = data['emeklilikTarihi'] as int?;
        if (timestamp != null) {
          setState(() {
            emeklilikTarihi = DateTime.fromMillisecondsSinceEpoch(timestamp);
            emeklilikTipi = data['emeklilikTipi'] ?? '';
            hesaplamaTuru = data['hesaplamaTuru'] ?? '';
            
            // Sigorta başlangıç tarihi
            final sigortaBaslangicTimestamp = data['sigortaBaslangicTarihi'] as int?;
            if (sigortaBaslangicTimestamp != null) {
              sigortaBaslangicTarihi = DateTime.fromMillisecondsSinceEpoch(sigortaBaslangicTimestamp);
            }
            
            // Normal Emeklilik bilgileri (eski format için geriye dönük uyumluluk)
            if (data.containsKey('normalEmeklilik')) {
              normalEmeklilik = Map<String, dynamic>.from(data['normalEmeklilik'] ?? {});
            } else {
              // Eski format için geriye dönük uyumluluk
              normalEmeklilik = {
                'tahminiYas': data['tahminiYas'] as int? ?? 0,
                'eksikPrim': data['eksikPrim'] as int? ?? 0,
                'eksikYil': (data['eksikYil'] as num?)?.toDouble() ?? 0.0,
                'mevcutPrim': data['mevcutPrim'] as String? ?? '',
                'gerekliPrim': data['gerekliPrim'] as String? ?? '',
                'mevcutYas': data['mevcutYas'] as String? ?? '',
                'gerekliYas': data['gerekliYas'] as String? ?? '',
              };
            }
            
            // Yaş Haddinden Emeklilik bilgileri
            if (data.containsKey('yasHaddindenEmeklilik')) {
              yasHaddindenEmeklilik = Map<String, dynamic>.from(data['yasHaddindenEmeklilik'] ?? {});
            }
            
            hasData = true;
          });
          _calculateCountdown();
          _updateCountdown();
        }
      } catch (e) {
        // Parse hatası - veriyi sil
        await prefs.remove('emeklilik_takip_data');
      }
    }
  }

  Future<void> _saveRetirementData(DateTime tarih, String tip) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'emeklilikTarihi': tarih.millisecondsSinceEpoch,
      'emeklilikTipi': tip,
      'kayitTarihi': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString('emeklilik_takip_data', jsonEncode(data));
    
    setState(() {
      emeklilikTarihi = tarih;
      emeklilikTipi = tip;
      hasData = true;
    });
    _calculateCountdown();
    _updateCountdown();
  }

  Future<void> _deleteRetirementData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('emeklilik_takip_data');
    setState(() {
      hasData = false;
      emeklilikTarihi = null;
      emeklilikTipi = '';
    });
  }

  void _calculateCountdown() {
    if (emeklilikTarihi == null) return;
    
    final now = DateTime.now();
    final difference = emeklilikTarihi!.difference(now);
    
    final hesaplananToplamKalanGunler = difference.inDays.clamp(0, double.infinity).toInt();
    
    // Yıl, ay, gün hesaplaması
    int yillar = 0;
    int aylar = 0;
    int gunler = 0;
    
    if (hesaplananToplamKalanGunler > 0) {
      // Yıl hesaplaması (yaklaşık olarak)
      yillar = hesaplananToplamKalanGunler ~/ 365;
      int yilCikarildiktanSonraKalanGunler = hesaplananToplamKalanGunler % 365;
      
      // Ay hesaplaması (ortalama 30 gün)
      aylar = yilCikarildiktanSonraKalanGunler ~/ 30;
      
      // Kalan günler (ay çıkarıldıktan sonra)
      gunler = yilCikarildiktanSonraKalanGunler % 30;
    }
    
    // Geçmiş günleri hesapla: Sigorta başlangıç tarihinden bugüne kadar
    int hesaplananGecmisGunler = 0;
    
    if (sigortaBaslangicTarihi != null) {
      // Sigorta başlangıç tarihinden bugüne kadar geçen günler
      final gecmisFark = now.difference(sigortaBaslangicTarihi!);
      hesaplananGecmisGunler = gecmisFark.inDays.clamp(0, double.infinity).toInt();
    } else {
      // Sigorta başlangıç tarihi yoksa, mevcut prim gün sayısından tahmin et
      String mevcutPrimStr = '';
      
      if (normalEmeklilik.isNotEmpty) {
        mevcutPrimStr = normalEmeklilik['mevcutPrim'] as String? ?? '';
      } else if (yasHaddindenEmeklilik.isNotEmpty) {
        mevcutPrimStr = yasHaddindenEmeklilik['mevcutPrim'] as String? ?? '';
      }
      
      if (mevcutPrimStr.isNotEmpty) {
        final mevcutPrimInt = int.tryParse(mevcutPrimStr) ?? 0;
        if (mevcutPrimInt > 0) {
          // Mevcut prim gün sayısından geçen yıl sayısını hesapla
          // 1 yıl = 360 prim günü (ortalama)
          final gecenYilSayisi = mevcutPrimInt / 360;
          // Geçen günler = geçen yıl sayısı * 365 (gerçek gün sayısı)
          hesaplananGecmisGunler = (gecenYilSayisi * 365).round();
        }
      }
      
      // Eğer prim bilgisi de yoksa, emeklilik tarihine göre tahmin yap
      if (hesaplananGecmisGunler == 0 && hesaplananToplamKalanGunler > 0) {
        // Emeklilik tarihine göre toplam süreyi tahmin et
        // Ortalama emeklilik süresi 20-30 yıl arası, ortalama 25 yıl = 9125 gün
        final ortalamaEmeklilikSuresi = 9125; // ~25 yıl
        hesaplananGecmisGunler = ortalamaEmeklilikSuresi - hesaplananToplamKalanGunler;
        if (hesaplananGecmisGunler < 0) hesaplananGecmisGunler = 0;
      }
    }
    
    setState(() {
      kalanYil = yillar;
      kalanAy = aylar;
      kalanGunler = gunler;
      toplamKalanGunler = hesaplananToplamKalanGunler;
      gecmisGunler = hesaplananGecmisGunler;
    });
  }

  void _updateCountdown() {
    // Her saniye güncelle
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _calculateCountdown();
        _updateCountdown();
      }
    });
  }

  void _showAddRetirementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emeklilik Tarihi Ekle'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Emeklilik hesaplama yaparak takip başlatabilirsiniz. Hesaplamalar ekranına yönlendirileceksiniz.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HesaplamalarEkrani(autoOpenEmeklilik: true),
                ),
              );
            },
            child: const Text('Hesaplama Yap'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Emeklilik Takip',
            style: TextStyle(
              color: Colors.indigo,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 120,
                  color: Colors.indigo.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Emeklilik Takibiniz Yok',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Emeklilik hesaplama yaparak takip başlatın',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HesaplamalarEkrani(autoOpenEmeklilik: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Emeklilik Hesabı Ekle'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // İlerleme hesaplaması: Geçen günler / (Geçen günler + Kalan günler)
    double progress = 0.0;
    final toplamGunler = gecmisGunler + toplamKalanGunler;
    if (toplamGunler > 0) {
      progress = (gecmisGunler / toplamGunler * 100).clamp(0, 100).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emeklilik Takip',
          style: TextStyle(
            color: Colors.indigo,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
            onPressed: _showAddRetirementDialog,
            tooltip: 'Düzenle',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Birleşik takip kartı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Kalan Süre
                  const Text(
                    'KALAN SÜRE',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TimeUnit(value: kalanYil, label: 'YIL', isDark: true),
                      _TimeSeparator(isDark: true),
                      _TimeUnit(value: kalanAy, label: 'AY', isDark: true),
                      _TimeSeparator(isDark: true),
                      _TimeUnit(value: kalanGunler, label: 'GÜN', isDark: true),
                ],
              ),
                  
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  
                  // İlerleme
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'İlerleme',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            '${value.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress / 100),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  
                  // Geçen ve Kalan Günler
                  Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_down,
                      iconColor: Colors.orange,
                          title: 'İlk işe giriş tarihinizden itibaren geçen günler',
                      value: '${gecmisGunler}',
                      subtitle: 'Gün',
                    ),
                  ),
                      const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.flag,
                      iconColor: Colors.green,
                          title: 'Emekli olmanıza kalan gün',
                      value: '${toplamKalanGunler}',
                      subtitle: 'Gün',
                    ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Hesaplama detayları kartı
            if (hesaplamaTuru.isNotEmpty || normalEmeklilik.isNotEmpty || yasHaddindenEmeklilik.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calculate, color: Colors.indigo, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hesaplama Detayları',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (hesaplamaTuru.isNotEmpty)
                                Text(
                                  hesaplamaTuru,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (emeklilikTipi.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: Colors.indigo, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ana Emeklilik Tipi: $emeklilikTipi',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Normal Emeklilik bilgileri
                    if (normalEmeklilik.isNotEmpty && normalEmeklilik.containsKey('tahminiTarih')) ...[
                      const SizedBox(height: 20),
                      _EmeklilikTipiKarti(
                        title: 'Normal Emeklilik',
                        bilgiler: normalEmeklilik,
                        color: Colors.blue,
                      ),
                    ],
                    
                    // Yaş Haddinden Emeklilik bilgileri
                    if (yasHaddindenEmeklilik.isNotEmpty && yasHaddindenEmeklilik.containsKey('tahminiTarih')) ...[
                      const SizedBox(height: 16),
                      _EmeklilikTipiKarti(
                        title: 'Yaş Haddinden Emeklilik',
                        bilgiler: yasHaddindenEmeklilik,
                        color: Colors.purple,
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Önemli bilgiler
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Önemli Bilgiler',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    text: 'Emeklilik Tarihi: ${emeklilikTarihi != null ? _formatDate(emeklilikTarihi!) : "Belirtilmemiş"}',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.today,
                    text: 'Bugün: ${_formatDate(DateTime.now())}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Motivasyon kartı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.pink.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hayallerin Gerçeğe Dönüşüyor! 💫',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Her geçen gün emekliliğine bir adım daha yaklaşıyorsun',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TimeUnit extends StatefulWidget {
  final int value;
  final String label;
  final bool isDark;

  const _TimeUnit({required this.value, required this.label, this.isDark = false});

  @override
  State<_TimeUnit> createState() => _TimeUnitState();
}

class _TimeUnitState extends State<_TimeUnit> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(_TimeUnit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _controller.forward(from: 0.0).then((_) {
        _controller.reverse(from: 1.0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isDark 
                        ? Colors.indigo.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.indigo.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: _controller.value > 0
                        ? [
                            BoxShadow(
                              color: widget.isDark
                                  ? Colors.indigo.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    widget.value.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.indigo : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.grey[700] : Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _TimeSeparator extends StatefulWidget {
  final bool isDark;
  const _TimeSeparator({this.isDark = false});

  @override
  State<_TimeSeparator> createState() => _TimeSeparatorState();
}

class _TimeSeparatorState extends State<_TimeSeparator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.indigo.withValues(alpha: _pulseAnimation.value)
                  : Colors.white.withValues(alpha: _pulseAnimation.value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.isDark
                      ? Colors.indigo.withValues(alpha: _pulseAnimation.value * 0.5)
                      : Colors.white.withValues(alpha: _pulseAnimation.value * 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.amber.shade800),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.amber.shade900,
                ),
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String prim;
  final String yas;
  final Color color;

  const _DetailCard({
    required this.title,
    required this.prim,
    required this.yas,
    required this.color,
  });

  Color _getDarkColor(Color baseColor) {
    // Renkleri daha koyu yapmak için basit bir yöntem
    return Color.fromRGBO(
      ((baseColor.r * 255.0) * 0.7).round().clamp(0, 255),
      ((baseColor.g * 255.0) * 0.7).round().clamp(0, 255),
      ((baseColor.b * 255.0) * 0.7).round().clamp(0, 255),
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkColor = _getDarkColor(color);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: darkColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (prim.isNotEmpty)
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  '$prim gün',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                ),
              ],
            ),
          if (yas.isNotEmpty && prim.isNotEmpty) const SizedBox(height: 4),
          if (yas.isNotEmpty)
            Row(
              children: [
                Icon(Icons.cake, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  '$yas yaş',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmeklilikTipiKarti extends StatelessWidget {
  final String title;
  final Map<String, dynamic> bilgiler;
  final Color color;

  const _EmeklilikTipiKarti({
    required this.title,
    required this.bilgiler,
    required this.color,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tahminiTarih = bilgiler['tahminiTarih'] as int?;
    final tahminiYas = bilgiler['tahminiYas'] as int? ?? 0;
    final eksikPrim = bilgiler['eksikPrim'] as int? ?? 0;
    final eksikYil = (bilgiler['eksikYil'] as num?)?.toDouble() ?? 0.0;
    final mevcutPrim = bilgiler['mevcutPrim'] as String? ?? '';
    final gerekliPrim = bilgiler['gerekliPrim'] as String? ?? '';
    final mevcutYas = bilgiler['mevcutYas'] as String? ?? '';
    final gerekliYas = bilgiler['gerekliYas'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
          if (tahminiTarih != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  'Tahmini Tarih: ${_formatDate(tahminiTarih)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
          if (tahminiYas > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cake, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  'Tahmini Yaş: $tahminiYas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
          if (mevcutPrim.isNotEmpty || gerekliPrim.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailCard(
                    title: 'Mevcut',
                    prim: mevcutPrim,
                    yas: mevcutYas,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DetailCard(
                    title: 'Gerekli',
                    prim: gerekliPrim,
                    yas: gerekliYas,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
          if (eksikPrim > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_down, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Eksik: $eksikPrim gün (${eksikYil.toStringAsFixed(1)} yıl)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

