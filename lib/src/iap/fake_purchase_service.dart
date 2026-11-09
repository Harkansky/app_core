import 'dart:ui' show Locale, PlatformDispatcher;

import 'currency.dart';
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
    this.defaultCurrency = 'USD',
    this._locale,
  });

  final Duration delay;

  /// Currency used outside the regions listed in `currencyForRegion`.
  final String defaultCurrency;

  /// Device locale: picks the currency (region) and the price format.
  final Locale? _locale;

  /// Currency the prices are shown in, e.g. 'EUR' on a French device.
  String get currency => currencyForRegion(
    (_locale ?? PlatformDispatcher.instance.locale).countryCode,
    fallback: defaultCurrency,
  );

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
            price: _price(spec),
          ),
      ],
    );
  }

  @override
  Future<bool> buy(String productId) async {
    final spec = specOf(productId);
    if (spec == null) {
      setState(
        error: 'Unknown product: $productId',
        errorKind: PurchaseErrorKind.unavailable,
      );
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

  String _price(ProductSpec spec) {
    final locale = (_locale ?? PlatformDispatcher.instance.locale).toString();
    var code = currency;
    var amount = spec.debugPrices[code];
    if (amount == null) {
      code = defaultCurrency;
      amount = spec.debugPrices[code] ?? spec.debugPrices.values.firstOrNull;
    }
    if (amount == null) return '';
    return formatPrice(amount, code, locale);
  }
}
