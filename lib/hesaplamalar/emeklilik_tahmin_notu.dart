import 'package:flutter/material.dart';

import '../utils/app_design.dart';

class EmeklilikTahminNotu extends StatelessWidget {
  const EmeklilikTahminNotu({super.key, required this.mesaj});

  final String mesaj;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppDesign.isDark
              ? const Color(0xFF1C2938)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMEKLİLİK TAHMİNİ',
              style: TextStyle(
                color: AppDesign.activeMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              mesaj.replaceFirst('. ', '.\n'),
              textAlign: TextAlign.start,
              style: TextStyle(
                color: AppDesign.activeInk,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}
