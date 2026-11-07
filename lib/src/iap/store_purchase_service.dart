import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../storage/key_value_store.dart';
import 'product_spec.dart';
import 'purchase_service.dart';

/// Real App Store / Google Play purchases via the official in_app_purchase
/// plugin (StoreKit on iOS, Play Billing on Android). No server needed:
/// entitlements are cached on the device and re-synced by "Restore".
class StorePurchaseService extends PurchaseService {
  StorePurchaseService({
    required super.specs,
    required super.entitlements,
    required this._store,
  });

  static const _deliveredKey = 'core.iap.delivered';
  static const _maxDeliveredIds = 200;

  final KeyValueStore _store;
  final InAppPurchase _iap = InAppPurchase.instance;
  final Map<String, ProductDetails> _details = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  Future<void> init() async {
    // Listen first: transactions left unfinished in a previous session are
    // redelivered as soon as the stream has a listener.
    _subscription ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) => setState(error: '$error'),
    );

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        setState(ready: true, available: false);
        return;
      }

      final response =
          await _iap.queryProductDetails(specs.map((s) => s.id).toSet());
      for (final details in response.productDetails) {
        _details[details.id] = details;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[app_core] Products missing from the store: '
            '${response.notFoundIDs.join(', ')}');
      }

      setState(
        ready: true,
        available: true,
        error: response.error?.message,
        items: [
          for (final spec in specs)
            if (_details[spec.id] case final details?)
              StoreItem(
                spec: spec,
                title: _cleanTitle(details.title),
                description: details.description,
                price: details.price,
              ),
        ],
      );
    } catch (error) {
      setState(ready: true, available: false, error: '$error');
      return;
    }

    // Google Play doesn't push owned items on start; a silent restore
    // re-syncs them (no sign-in prompt on Android, unlike iOS). It also
    // surfaces consumables that were paid but never consumed. A failure here
    // must not mark the store unavailable: products are already loaded.
    if (_isAndroid) {
      try {
        await _iap.restorePurchases();
      } catch (error) {
        debugPrint('[app_core] Silent restore failed: $error');
      }
    }
  }

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> buy(String productId) async {
    final spec = specOf(productId);
    final details = _details[productId];
    if (spec == null || details == null) {
      setState(error: 'This item is not available right now.');
      return false;
    }

    markPending(productId);
    final param = PurchaseParam(productDetails: details);
    try {
      final started = spec.kind == ProductKind.consumable
          ? await _iap.buyConsumable(purchaseParam: param)
          : await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) clearPending(productId);
      return started;
    } catch (error) {
      clearPending(productId);
      setState(error: '$error');
      return false;
    }
  }

  @override
  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (error) {
      setState(error: '$error');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final spec = specOf(purchase.productID);
      switch (purchase.status) {
        case PurchaseStatus.pending:
          markPending(purchase.productID);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (spec != null) {
            final restoredConsumable =
                purchase.status == PurchaseStatus.restored &&
                    spec.kind == ProductKind.consumable;
            if (!restoredConsumable) {
              await _deliver(purchase, spec);
            } else if (_isAndroid) {
              // Paid but never consumed (consume failed, or a pending payment
              // completed while the app was closed). Deliver it if it wasn't
              // already, then consume it so it can be bought again.
              // iOS never restores consumables, so this is Android only.
              await _deliver(purchase, spec);
              await _consumeOnAndroid(purchase);
            }
          }
          clearPending(purchase.productID);
        case PurchaseStatus.error:
          clearPending(purchase.productID);
          setState(error: purchase.error?.message ?? 'The purchase failed.');
        case PurchaseStatus.canceled:
          clearPending(purchase.productID);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Grants a purchase. Consumables are credited once per transaction, even
  /// if the store redelivers them; non-consumables are idempotent anyway.
  Future<void> _deliver(PurchaseDetails purchase, ProductSpec spec) async {
    if (spec.kind == ProductKind.nonConsumable) {
      await entitlements.grant(spec);
      return;
    }

    final transactionId = purchase.purchaseID;
    final delivered = _loadDelivered();
    if (transactionId != null && delivered.contains(transactionId)) return;

    await entitlements.grant(spec);
    if (transactionId != null) {
      delivered.add(transactionId);
      final trimmed = delivered.length > _maxDeliveredIds
          ? delivered.sublist(delivered.length - _maxDeliveredIds)
          : delivered;
      await _store.setString(_deliveredKey, jsonEncode(trimmed));
    }
  }

  Future<void> _consumeOnAndroid(PurchaseDetails purchase) async {
    try {
      final android =
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await android.consumePurchase(purchase);
    } catch (error) {
      debugPrint('[app_core] Could not consume ${purchase.productID}: $error');
    }
  }

  List<String> _loadDelivered() {
    final raw = _store.getString(_deliveredKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }

  /// Google Play appends " (App Name)" to product titles.
  static String _cleanTitle(String title) =>
      title.replaceFirst(RegExp(r'\s*\([^)]*\)$'), '');

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
