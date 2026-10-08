import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/app_design.dart';
import '../utils/calculator_design.dart';
import '4a_hesapla.dart';
import '4b_hesapla.dart';
import '4c_hesapla.dart';

class EmeklilikHesaplamaBirlesik extends StatefulWidget {
  final int initialIndex;
  const EmeklilikHesaplamaBirlesik({super.key, this.initialIndex = 0});

  @override
  State<EmeklilikHesaplamaBirlesik> createState() =>
      _EmeklilikHesaplamaBirlesikState();
}

class _EmeklilikHesaplamaBirlesikState
    extends State<EmeklilikHesaplamaBirlesik> {
  late int _selectedIndex;

  static const _labels = ['4/a', '4/b', '4/c'];
  static const _descriptions = [
    'SSK kapsamında çalışanlar',
    'Bağ-Kur kapsamında çalışanlar',
    'Emekli Sandığı kapsamındaki memurlar',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 2);
  }

  Widget _selectedForm() {
    switch (_selectedIndex) {
      case 1:
        return const EmeklilikHesaplama4bSayfasi(
          key: ValueKey('retirement-4b'),
          embedded: true,
        );
      case 2:
        return const EmeklilikHesaplamaSayfasi(
          key: ValueKey('retirement-4c'),
          embedded: true,
        );
      default:
        return const EmeklilikHesaplama4aSayfasi(
          key: ValueKey('retirement-4a'),
          embedded: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorPage(
      title: 'Emeklilik Hesaplama',
      icon: Icons.calendar_month_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sigorta statünüz',
            style: TextStyle(
              color: AppDesign.activeInk,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedIndex,
              padding: const EdgeInsets.all(3),
              backgroundColor: AppDesign.isDark
                  ? const Color(0xFF1C2938)
                  : const Color(0xFFF1F5F9),
              thumbColor: AppDesign.activeSurface,
              children: {
                for (var index = 0; index < _labels.length; index++)
                  index: Center(
                    child: Text(
                      _labels[index],
                      style: TextStyle(
                        color: AppDesign.activeInk,
                        fontSize: 14,
                        fontWeight: _selectedIndex == index
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
              },
              onValueChanged: (value) {
                if (value == null || value == _selectedIndex) return;
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _selectedIndex = value);
              },
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _descriptions[_selectedIndex],
              key: ValueKey(_selectedIndex),
              style: TextStyle(
                color: AppDesign.activeMuted,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Divider(height: 1, color: AppDesign.activeBorder),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _selectedForm(),
          ),
        ],
      ),
    );
  }
}
