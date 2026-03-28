import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/sgk_sosyal_linkler.dart';

/// Yan menü ve Topluluk ekranında aynı sosyal ikon şeridi.
class SgkSosyalMedyaWrap extends StatelessWidget {
  final Color temaRengi;
  final void Function(String url) onUrlTap;

  const SgkSosyalMedyaWrap({
    super.key,
    required this.temaRengi,
    required this.onUrlTap,
  });

  @override
  Widget build(BuildContext context) {
    const ikonBoy = 16.0;
    const kutu = 34.0;
    const ara = 6.0;

    final ogeler = <({Widget icon, String url})>[
      (
        icon: const FaIcon(FontAwesomeIcons.instagram,
            size: ikonBoy, color: Color(0xFFE4405F)),
        url: SgkSosyalLinkler.instagram
      ),
      (
        icon: const FaIcon(FontAwesomeIcons.facebook,
            size: ikonBoy, color: Color(0xFF1877F2)),
        url: SgkSosyalLinkler.facebook
      ),
      (
        icon: const FaIcon(FontAwesomeIcons.linkedin,
            size: ikonBoy, color: Color(0xFF0A66C2)),
        url: SgkSosyalLinkler.linkedin
      ),
      (
        icon: const FaIcon(FontAwesomeIcons.youtube,
            size: ikonBoy, color: Color(0xFFFF0000)),
        url: SgkSosyalLinkler.youtube
      ),
      (
        icon: const FaIcon(FontAwesomeIcons.xTwitter,
            size: ikonBoy, color: Color(0xFF0F1419)),
        url: SgkSosyalLinkler.xTwitter
      ),
      (
        icon: const FaIcon(FontAwesomeIcons.tiktok,
            size: ikonBoy, color: Color(0xFF000000)),
        url: SgkSosyalLinkler.tiktok
      ),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: ara,
      runSpacing: ara,
      children: ogeler
          .map(
            (e) => Material(
              color: temaRengi.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: () => onUrlTap(e.url),
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: kutu,
                  height: kutu,
                  child: Center(child: e.icon),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
