enum ProductKind {
  /// Bought once, owned forever (remove ads, premium, level pack).
  nonConsumable,

  /// Bought repeatedly; each purchase credits a wallet balance (coins, hints).
  consumable,
}

/// Declares one in-app product. Store-side title, description and localized
/// price are fetched at runtime; the fallback values are only used by the fake
/// store (debug builds, tests) and are translated through
/// `CoreConfig.productText` when the app provides it.
class ProductSpec {
  const ProductSpec.nonConsumable(
    this.id, {
    required this.fallbackTitle,
    this.fallbackDescription = '',
    this.debugPrices = const {'USD': 1.99, 'EUR': 1.99},
  }) : kind = ProductKind.nonConsumable,
       walletKey = null,
       walletAmount = 0;

  const ProductSpec.consumable(
    this.id, {
    required String this.walletKey,
    required this.walletAmount,
    required this.fallbackTitle,
    this.fallbackDescription = '',
    this.debugPrices = const {'USD': 0.99, 'EUR': 0.99},
  }) : kind = ProductKind.consumable;

  /// Product ID, identical in App Store Connect and Google Play Console.
  /// Use lowercase letters, digits and underscores only.
  final String id;
  final ProductKind kind;

  /// For consumables: which wallet balance a purchase credits, and by how much.
  final String? walletKey;
  final int walletAmount;

  final String fallbackTitle;
  final String fallbackDescription;

  /// Fake-store prices by ISO currency code. The currency follows the device
  /// region (see `currencyForRegion`), like real stores follow the player's
  /// store country. Keep them equal to the prices set in the consoles.
  final Map<String, double> debugPrices;
}

/// Translated title and description for a product, used when the item
/// doesn't come from the real store (fake store, store offline).
class ProductText {
  const ProductText(this.title, [this.description = '']);

  final String title;
  final String description;
}

/// A product as displayed in the store screen.
class StoreItem {
  const StoreItem({
    required this.spec,
    required this.title,
    required this.description,
    required this.price,
    this.fromStore = false,
  });

  final ProductSpec spec;
  final String title;
  final String description;

  /// Localized price string, e.g. "2,99 €" or "$2.99".
  final String price;

  /// True when title, description and price come from App Store / Google
  /// Play (already in the player's language and currency).
  final bool fromStore;
}
