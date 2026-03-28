import 'package:flutter/material.dart';

import 'akisi/akisi_renkleri.dart';

/// sgk_app ana ekran üst şeridi: menü + başlık + isteğe bağlı bildirim + profil avatarı.
class AnaMenuSgkUstMenu extends StatelessWidget {
  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;
  final Widget profilAvatar;
  final Widget? bildirimWidget;

  const AnaMenuSgkUstMenu({
    super.key,
    required this.title,
    required this.onMenuTap,
    required this.onProfileTap,
    required this.profilAvatar,
    this.bildirimWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AkisiRenkleri.gray,
      child: Row(
        children: [
          InkWell(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AkisiRenkleri.slate100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu_rounded,
                color: AkisiRenkleri.slate600,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AkisiRenkleri.slate800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (bildirimWidget != null) ...[
            bildirimWidget!,
            const SizedBox(width: 8),
          ],
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(child: profilAvatar),
            ),
          ),
        ],
      ),
    );
  }
}

/// sgk_app alt menü: Ana Sayfa, Hesapla, ortada sohbet FAB, Topluluk, Rozetler.
class AnaMenuSgkAltMenu extends StatelessWidget {
  final String aktifTab;
  final VoidCallback onAnaSayfa;
  final VoidCallback onHesapla;
  final VoidCallback onSohbet;
  final VoidCallback onTopluluk;
  final VoidCallback onRozetler;

  const AnaMenuSgkAltMenu({
    super.key,
    required this.aktifTab,
    required this.onAnaSayfa,
    required this.onHesapla,
    required this.onSohbet,
    required this.onTopluluk,
    required this.onRozetler,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: AkisiRenkleri.slate100),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AltNavButon(
                aktif: aktifTab == 'home',
                onTap: onAnaSayfa,
                icon: Icons.home_rounded,
                iconOutlined: Icons.home_outlined,
                label: 'Ana Sayfa',
              ),
              _AltNavButon(
                aktif: aktifTab == 'calc',
                onTap: onHesapla,
                icon: Icons.calculate_rounded,
                iconOutlined: Icons.calculate_outlined,
                label: 'Hesapla',
              ),
              Transform.translate(
                offset: const Offset(0, -32),
                child: InkWell(
                  onTap: onSohbet,
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AkisiRenkleri.navy,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AkisiRenkleri.navy.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              _AltNavButon(
                aktif: aktifTab == 'topluluk',
                onTap: onTopluluk,
                icon: Icons.people_rounded,
                iconOutlined: Icons.people_outlined,
                label: 'Topluluk',
              ),
              _AltNavButon(
                aktif: aktifTab == 'rozetler',
                onTap: onRozetler,
                icon: Icons.emoji_events_rounded,
                iconOutlined: Icons.emoji_events_outlined,
                label: 'Rozetler',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AltNavButon extends StatelessWidget {
  final bool aktif;
  final VoidCallback onTap;
  final IconData icon;
  final IconData? iconOutlined;
  final String label;

  const _AltNavButon({
    required this.aktif,
    required this.onTap,
    required this.icon,
    this.iconOutlined,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = aktif ? AkisiRenkleri.navy : AkisiRenkleri.slate400;
    final iconData = aktif ? icon : (iconOutlined ?? icon);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: aktif ? FontWeight.w900 : FontWeight.w500,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
