import 'package:flutter/material.dart';

import '../screens/premium_ekrani.dart';
import 'premium_access_service.dart';

/// Opens the Premium flow before a paid PDF export and retries after activation.
class PremiumPdfAction {
  static Future<void> run(
      BuildContext context, Future<void> Function() export) async {
    try {
      var status = await PremiumAccessService().load();
      if (!status.hasPremium) {
        if (!context.mounted) return;
        await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => const PremiumEkrani(),
        ));
        if (!context.mounted) return;
        status = await PremiumAccessService().load();
      }
      if (!status.hasPremium) return;
      await export();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Premium erişimi veya PDF oluşturma doğrulanamadı. Tekrar deneyin.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
