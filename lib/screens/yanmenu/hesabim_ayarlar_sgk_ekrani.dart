import 'package:flutter/material.dart';

import '../../utils/theme_helper.dart';
import '../sgk_port/sgk_app_colors.dart';
import 'hesabim_ekrani.dart';
import 'profil_duzenle_sgk_ekrani.dart';

/// sgk_app [_buildSettingsPage] ile aynı düzen.
class HesabimAyarlarSgkEkrani extends StatefulWidget {
  final VoidCallback? onProfilKaydi;

  const HesabimAyarlarSgkEkrani({super.key, this.onProfilKaydi});

  @override
  State<HesabimAyarlarSgkEkrani> createState() => _HesabimAyarlarSgkEkraniState();
}

class _HesabimAyarlarSgkEkraniState extends State<HesabimAyarlarSgkEkrani> {
  final ThemeHelper _themeHelper = ThemeHelper();
  bool _darkMode = false;
  double _fontSize = 14;

  @override
  void initState() {
    super.initState();
    _syncFromHelper();
    _themeHelper.addKoyuModListener(_syncFromHelper);
    _themeHelper.addFontSizeChangeListener(_syncFromHelper);
  }

  @override
  void dispose() {
    _themeHelper.removeKoyuModListener(_syncFromHelper);
    _themeHelper.removeFontSizeChangeListener(_syncFromHelper);
    super.dispose();
  }

  void _syncFromHelper() {
    if (!mounted) return;
    setState(() {
      _darkMode = _themeHelper.koyuMod;
      _fontSize = _themeHelper.fontSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _darkMode ? SgkAppColors.slate950 : SgkAppColors.gray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: _darkMode
                          ? SgkAppColors.slate400
                          : SgkAppColors.slate600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ayarlar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _darkMode ? Colors.white : SgkAppColors.slate800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _darkMode ? SgkAppColors.slate800 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _darkMode
                        ? SgkAppColors.slate700
                        : SgkAppColors.slate100,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _darkMode
                                    ? SgkAppColors.blue600.withOpacity(0.3)
                                    : SgkAppColors.blue500.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _darkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: _darkMode
                                    ? SgkAppColors.blue400
                                    : SgkAppColors.blue600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Koyu Mod',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _darkMode
                                        ? Colors.white
                                        : SgkAppColors.slate800,
                                  ),
                                ),
                                Text(
                                  'Gözlerini yormayan görünüm',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _darkMode
                                        ? SgkAppColors.slate400
                                        : SgkAppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _darkMode,
                          onChanged: (v) async {
                            await _themeHelper.setKoyuMod(v);
                          },
                          activeThumbColor: _darkMode
                              ? SgkAppColors.blue500
                              : SgkAppColors.navy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _darkMode
                                    ? SgkAppColors.amber900.withOpacity(0.3)
                                    : SgkAppColors.amber500.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.text_fields_rounded,
                                color: _darkMode
                                    ? SgkAppColors.amber200
                                    : SgkAppColors.amber600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yazı Boyutu',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _darkMode
                                        ? Colors.white
                                        : SgkAppColors.slate800,
                                  ),
                                ),
                                Text(
                                  'Okunabilirliği ayarla',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _darkMode
                                        ? SgkAppColors.slate400
                                        : SgkAppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _darkMode
                                ? SgkAppColors.slate900
                                : SgkAppColors.slate50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _darkMode
                                  ? SgkAppColors.slate800
                                  : SgkAppColors.slate100,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  final n =
                                      (_fontSize - 2).clamp(12.0, 24.0);
                                  await _themeHelper.setFontSize(n);
                                },
                                icon: Icon(
                                  Icons.remove_rounded,
                                  size: 18,
                                  color: _darkMode
                                      ? SgkAppColors.slate400
                                      : SgkAppColors.slate600,
                                ),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  _fontSize.toInt().toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: _darkMode
                                        ? SgkAppColors.slate200
                                        : SgkAppColors.slate700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final n =
                                      (_fontSize + 2).clamp(12.0, 24.0);
                                  await _themeHelper.setFontSize(n);
                                },
                                icon: Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: _darkMode
                                      ? SgkAppColors.slate400
                                      : SgkAppColors.slate600,
                                ),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: _darkMode ? SgkAppColors.slate800 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _darkMode
                        ? SgkAppColors.slate700
                        : SgkAppColors.slate100,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.person_rounded,
                        color: _darkMode
                            ? SgkAppColors.slate400
                            : SgkAppColors.slate600,
                        size: 22,
                      ),
                      title: Text(
                        'Kişisel Bilgiler',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _darkMode
                              ? SgkAppColors.slate200
                              : SgkAppColors.slate700,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: _darkMode
                            ? SgkAppColors.slate600
                            : SgkAppColors.slate300,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilDuzenleSgkEkrani(
                              onKaydedildi: widget.onProfilKaydi,
                            ),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    Divider(
                        height: 1,
                        color: _darkMode
                            ? SgkAppColors.slate700
                            : SgkAppColors.slate50),
                    ListTile(
                      leading: Icon(
                        Icons.notifications_rounded,
                        color: _darkMode
                            ? SgkAppColors.slate400
                            : SgkAppColors.slate600,
                        size: 22,
                      ),
                      title: Text(
                        'Bildirim Ayarları',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _darkMode
                              ? SgkAppColors.slate200
                              : SgkAppColors.slate700,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: _darkMode
                            ? SgkAppColors.slate600
                            : SgkAppColors.slate300,
                      ),
                      onTap: () {},
                    ),
                    Divider(
                        height: 1,
                        color: _darkMode
                            ? SgkAppColors.slate700
                            : SgkAppColors.slate50),
                    ListTile(
                      leading: Icon(
                        Icons.lock_rounded,
                        color: _darkMode
                            ? SgkAppColors.slate400
                            : SgkAppColors.slate600,
                        size: 22,
                      ),
                      title: Text(
                        'Güvenlik ve Şifre',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _darkMode
                              ? SgkAppColors.slate200
                              : SgkAppColors.slate700,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: _darkMode
                            ? SgkAppColors.slate600
                            : SgkAppColors.slate300,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HesabimEkrani()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
