import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../utils/theme_helper.dart';

class TemaAyarlariEkrani extends StatefulWidget {
  const TemaAyarlariEkrani({super.key});

  @override
  State<TemaAyarlariEkrani> createState() => _TemaAyarlariEkraniState();
}

class _TemaAyarlariEkraniState extends State<TemaAyarlariEkrani> {
  final ThemeHelper _themeHelper = ThemeHelper();
  double _fontSize = 14.0; // Varsayılan 14 punto
  Color _selectedThemeColor = Colors.indigo; // Varsayılan indigo (orijinal renk)
  final double _minFontSize = 12.0;
  final double _maxFontSize = 18.0;

  // Tema renkleri
  final List<Color> _themeColors = [
    Colors.indigo,      // Varsayılan
    Colors.blue,
    Colors.pink,
    Colors.grey,
    Colors.green,
    Colors.brown,
    Colors.amber,
    Colors.purple,
    Colors.deepPurple,
    Colors.teal,
    Colors.red,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _themeHelper.loadSettings();
    setState(() {
      _fontSize = _themeHelper.fontSize;
      _selectedThemeColor = _themeHelper.themeColor;
    });
  }

  Future<void> _saveFontSize(double size) async {
    await _themeHelper.setFontSize(size);
    setState(() {
      _fontSize = size;
    });
  }

  Future<void> _saveThemeColor(Color color) async {
    await _themeHelper.setThemeColor(color);
    setState(() {
      _selectedThemeColor = color;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tema rengi değiştirildi'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tema Ayarları',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
        backgroundColor: _selectedThemeColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              _selectedThemeColor.withOpacity(0.02),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yazı Fontunu Büyüt
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Yazı Fontunu Büyüt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_fontSize.toInt()} punto)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Yazı Boyutu'),
                                content: const Text(
                                  'Yazı boyutunu 12 ile 18 punto arasında ayarlayabilirsiniz. '
                                  'Bu ayar uygulamanın tüm ekranlarına uygulanacaktır.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Tamam'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(
                            Icons.help_outline,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Slider
                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _selectedThemeColor,
                              inactiveTrackColor: Colors.grey[300],
                              thumbColor: _selectedThemeColor,
                              overlayColor: _selectedThemeColor.withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                            ),
                            child: Slider(
                              value: _fontSize,
                              min: _minFontSize,
                              max: _maxFontSize,
                              divisions: 6, // 12, 13, 14, 15, 16, 17, 18
                              label: '${_fontSize.toInt()} punto',
                              onChanged: (value) {
                                setState(() {
                                  _fontSize = value;
                                });
                                _saveFontSize(value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Kullanılan Tema
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kullanılan Tema',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Renk grid'i (5 sütun, 3 satır - 12 renk)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _themeColors.length,
                      itemBuilder: (context, index) {
                        final color = _themeColors[index];
                        final isSelected = _selectedThemeColor.value == color.value;
                        
                        return GestureDetector(
                          onTap: () {
                            _saveThemeColor(color);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Bilgilendirme
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedThemeColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _selectedThemeColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Yazı boyutu ve tema ayarları uygulamanın tüm ekranlarına uygulanacaktır. Değişikliklerin etkili olması için uygulamayı yeniden başlatmanız gerekebilir.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedThemeColor.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

