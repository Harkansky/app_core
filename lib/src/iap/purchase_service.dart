import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';
import 'entitlements.dart';
import 'fake_purchase_service.dart';
import 'product_spec.dart';
import 'store_purchase_service.dart';

/// What went wrong with the store, for a translated message. The raw
/// platform text stays in [PurchaseService.lastError] for logs.
enum PurchaseErrorKind {
  /// The product or the store can't be reached right now.
  unavailable,

  /// A purchase was started but didn't complete.
  failed,
}

/// The one interface apps use for in-app purchases.
///
/// Purchases are delivered into [Entitlements]; listen to this object for
/// store state (loading, availability, pending purchases, errors) and to
/// [Entitlements] for what the player owns.
abstract class PurchaseService extends ChangeNotifier {
  PurchaseService({required this.specs, required this.entitlements});

  /// Real store on Android/iOS; fake store elsewhere or when [forceFake].
  static PurchaseService create({
    required List<ProductSpec> specs,
    required Entitlements entitlements,
    required KeyValueStore store,
    bool forceFake = false,
    Duration fakeDelay = const Duration(milliseconds: 300),
    String defaultCurrency = 'USD',
  }) {
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (forceFake || !supported) {
      return FakePurchaseService(
        specs: specs,
        entitlements: entitlements,
        delay: fakeDelay,
        defaultCurrency: defaultCurrency,
      );
    }
    return StorePurchaseService(
      specs: specs,
      entitlements: entitlements,
      store: store,
    );
  }

  final List<ProductSpec> specs;
  final Entitlements entitlements;

  bool _ready = false;
  bool _available = false;
  List<StoreItem> _items = const [];
  final Set<String> _pending = {};
  String? _lastError;
  PurchaseErrorKind? _errorKind;

  /// True once [init] finished (successfully or not).
  bool get isReady => _ready;

  /// False when the store can't be reached (offline, no Play Services...).
  /// Already-owned content keeps working regardless.
  bool get isAvailable => _available;

  /// True for the fake store used in debug builds and tests.
  bool get isFake => false;

  List<StoreItem> get items => _items;
  Set<String> get pending => Set.unmodifiable(_pending);

  /// Raw error text (platform message), for logs.
  String? get lastError => _lastError;

  /// Kind of the last error, for a translated message; null when none.
  PurchaseErrorKind? get errorKind => _errorKind;

  /// Connects to the store and loads product details. Safe to call again
  /// (e.g. a "Retry" button after being offline).
  Future<void> init();

  /// Starts a purchase. Returns false if it could not be started; the result
  /// of a started purchase arrives asynchronously into [entitlements].
  Future<bool> buy(String productId);

  /// Re-delivers non-consumables owned by this store account.
  Future<void> restore();

  void clearError() {
    if (_lastError == null && _errorKind == null) return;
    _lastError = null;
    _errorKind = null;
    notifyListeners();
  }

  ProductSpec? specOf(String productId) {
    for (final spec in specs) {
      if (spec.id == productId) return spec;
    }
    return null;
  }

  @protected
  void setState({
    bool? ready,
    bool? available,
    List<StoreItem>? items,
    String? error,
    PurchaseErrorKind? errorKind,
  }) {
    if (ready != null) _ready = ready;
    if (available != null) _available = available;
    if (items != null) _items = List.unmodifiable(items);
    if (error != null || errorKind != null) {
      _lastError = error;
      _errorKind = errorKind ?? PurchaseErrorKind.failed;
    }
    notifyListeners();
  }

  @protected
  void markPending(String productId) {
    if (_pending.add(productId)) notifyListeners();
  }

  @protected
  void clearPending(String productId) {
    if (_pending.remove(productId)) notifyListeners();
  }
}
