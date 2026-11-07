import 'purchase_service.dart';
import 'product_spec.dart';

/// Pretend store: every purchase succeeds after [delay].
///
/// Used in debug builds (unless run with `--dart-define=FAKE_STORE=false`),
/// in tests, and on platforms without a store. The store screen shows a
/// "Test store" banner while it is active.
class FakePurchaseService extends PurchaseService {
  FakePurchaseService({
    required super.specs,
    required super.entitlements,
    this.delay = const Duration(milliseconds: 300),
  });

  final Duration delay;

  @override
  bool get isFake => true;

  @override
  Future<void> init() async {
    setState(
      ready: true,
      available: true,
      items: [
        for (final spec in specs)
          StoreItem(
            spec: spec,
            title: spec.fallbackTitle,
            description: spec.fallbackDescription,
            price: spec.debugPrice,
          ),
      ],
    );
  }

  @override
  Future<bool> buy(String productId) async {
    final spec = specOf(productId);
    if (spec == null) {
      setState(error: 'Unknown product: $productId');
      return false;
    }
    if (spec.kind == ProductKind.nonConsumable && entitlements.owns(spec.id)) {
      return true;
    }
    markPending(productId);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    await entitlements.grant(spec);
    clearPending(productId);
    return true;
  }

  @override
  Future<void> restore() async {
    // Nothing to do: the fake store has no account to restore from.
    notifyListeners();
  }
}
