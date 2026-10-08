import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'premium_entitlement_service.dart';

/// Listens for purchases for the full app lifetime, including after restore.
class PremiumStoreService extends ChangeNotifier with WidgetsBindingObserver {
  PremiumStoreService._();

  static final instance = PremiumStoreService._();
  static const monthlyId = 'premium_monthly';
  static const yearlyId = 'premium_yearly';
  static const productIds = {monthlyId, yearlyId};

  final _iap = InAppPurchase.instance;
  final _entitlements = PremiumEntitlementService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Timer? _purchaseWatchdog;
  bool _awaitingPurchaseUpdate = false;
  final Map<String, ProductDetails> products = {};

  bool initialized = false;
  bool storeAvailable = false;
  bool verificationAvailable = false;
  bool busy = false;
  PremiumEntitlement entitlement = const PremiumEntitlement(active: false);
  String? error;

  bool get signedIn => FirebaseAuth.instance.currentUser != null;
  String get storeName => Platform.isIOS ? 'App Store' : 'Google Play';

  Future<void> initialize() async {
    if (initialized) return;
    initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _purchaseSubscription = _iap.purchaseStream.listen(_onPurchases,
        onError: (Object failure) {
      _awaitingPurchaseUpdate = false;
      _purchaseWatchdog?.cancel();
      error = 'Satın alma güncellemesi alınamadı. Tekrar deneyin.';
      busy = false;
      notifyListeners();
    });
    await refresh();
  }

  Future<void> refresh() async {
    error = null;
    if (!Platform.isAndroid && !Platform.isIOS) {
      error = 'Abonelik satın alma bu platformda kullanılamıyor.';
      notifyListeners();
      return;
    }
    if (!signedIn) {
      verificationAvailable = false;
      entitlement = const PremiumEntitlement(active: false);
    } else {
      try {
        entitlement = await _entitlements.load();
        verificationAvailable = true;
      } catch (_) {
        verificationAvailable = false;
        entitlement = const PremiumEntitlement(active: false);
        error = 'Güvenli satın alma doğrulaması henüz hazır değil.';
      }
    }
    try {
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        final response = await _iap.queryProductDetails(productIds);
        products
          ..clear()
          ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
        if (response.error != null) {
          error = '$storeName planları alınamadı. Tekrar deneyin.';
        }
      }
    } catch (_) {
      storeAvailable = false;
      error = '$storeName ile bağlantı kurulamadı.';
    }
    notifyListeners();
  }

  Future<void> buy(String productId) async {
    final product = products[productId];
    if (!signedIn || entitlement.active || !verificationAvailable ||
        !storeAvailable || product == null || busy) {
      error = 'Bu plan henüz satın almaya hazır değil.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    _awaitingPurchaseUpdate = true;
    _purchaseWatchdog?.cancel();
    notifyListeners();
    try {
      final launched = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!launched) {
        _awaitingPurchaseUpdate = false;
        busy = false;
        error = '$storeName satın alma işlemini başlatamadı. Mağaza hesabınızı ve test kurulumunu kontrol edin.';
        notifyListeners();
      } else if (_awaitingPurchaseUpdate) {
        _purchaseWatchdog = Timer(const Duration(seconds: 45), _resetUnreportedPurchase);
      }
    } catch (_) {
      _awaitingPurchaseUpdate = false;
      busy = false;
      error = 'Satın alma başlatılamadı. Tekrar deneyin.';
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaitingPurchaseUpdate) return;
    Future<void>.delayed(const Duration(seconds: 3), _resetUnreportedPurchase);
  }

  void _resetUnreportedPurchase() {
    if (!_awaitingPurchaseUpdate) return;
    _awaitingPurchaseUpdate = false;
    _purchaseWatchdog?.cancel();
    busy = false;
    error = '$storeName satın alma işlemini tamamlayamadı. Mağaza hesabınızı ve test kurulumunu kontrol edin.';
    notifyListeners();
  }

  Future<void> restore() async {
    if (!signedIn || !storeAvailable || !verificationAvailable || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
      // Restore can return no purchase events; refresh the server state too.
      entitlement = await _entitlements.load();
    } catch (_) {
      error = 'Satın almalar geri yüklenemedi. Tekrar deneyin.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> updates) async {
    for (final purchase in updates) {
      if (!productIds.contains(purchase.productID)) continue;
      _awaitingPurchaseUpdate = false;
      _purchaseWatchdog?.cancel();
      if (purchase.status == PurchaseStatus.pending) {
        busy = true;
      } else if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        busy = false;
        error = purchase.status == PurchaseStatus.canceled
            ? null
            : 'Satın alma tamamlanamadı. Tekrar deneyin.';
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final verified = await _entitlements.verifyPurchase(
            productId: purchase.productID,
            purchaseToken: purchase.verificationData.serverVerificationData,
            transactionId: purchase.purchaseID,
          );
          if (!verified.active) throw StateError('Abonelik etkin değil.');
          entitlement = verified;
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          busy = false;
          error = null;
        } catch (_) {
          busy = false;
          error = 'Satın alma doğrulanamadı. $storeName hesabınızı ve bağlantınızı kontrol edip geri yükleyin.';
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseWatchdog?.cancel();
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
