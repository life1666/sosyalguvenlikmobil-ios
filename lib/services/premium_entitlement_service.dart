import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.active,
    this.productId,
    this.expiresAt,
  });

  final bool active;
  final String? productId;
  final DateTime? expiresAt;
}

/// Paid access is returned only by the server after checking the platform store.
/// A local purchase event is never sufficient to unlock Premium.
class PremiumEntitlementService {
  PremiumEntitlementService({FirebaseAuth? auth, FirebaseFunctions? functions})
      : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  Future<PremiumEntitlement> load() async {
    if (_auth.currentUser == null) return const PremiumEntitlement(active: false);
    final primaryFunction = Platform.isIOS
        ? 'getApplePremiumEntitlement'
        : 'getPremiumEntitlement';
    final otherFunction = Platform.isIOS
        ? 'getPremiumEntitlement'
        : 'getApplePremiumEntitlement';
    final primary = _parse(
        (await _functions.httpsCallable(primaryFunction).call()).data);
    if (primary.active) return primary;
    try {
      final other = _parse(
          (await _functions.httpsCallable(otherFunction).call()).data);
      return other.active ? other : primary;
    } catch (_) {
      // The other store may not be configured yet. Its failure must not hide
      // a successful check of this device's store.
      return primary;
    }
  }

  Future<PremiumEntitlement> verifyPurchase({
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    if (_auth.currentUser == null) throw StateError('Oturum açılmalı.');
    final response = Platform.isIOS
        ? await _functions.httpsCallable('verifyApplePurchase').call({
            'productId': productId,
            'transactionId': transactionId,
          })
        : await _functions.httpsCallable('verifyPlayPurchase').call({
            'productId': productId,
            'purchaseToken': purchaseToken,
          });
    return _parse(response.data);
  }

  PremiumEntitlement _parse(dynamic raw) {
    if (raw is! Map) throw StateError('Premium yanıtı okunamadı.');
    final data = Map<String, dynamic>.from(raw);
    final expiresAt = DateTime.tryParse('${data['expiresAt'] ?? ''}');
    return PremiumEntitlement(
      active: data['active'] == true &&
          expiresAt != null &&
          expiresAt.isAfter(DateTime.now()),
      productId: data['productId'] as String?,
      expiresAt: expiresAt,
    );
  }
}
