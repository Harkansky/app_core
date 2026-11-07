enum ProductKind {
  /// Bought once, owned forever (remove ads, premium, level pack).
  nonConsumable,

  /// Bought repeatedly; each purchase credits a wallet balance (coins, hints).
  consumable,
}

/// Declares one in-app product. Store-side title, description and localized
/// price are fetched at runtime; the fallback values are only used by the fake
/// store (debug builds, tests).
class ProductSpec {
  const ProductSpec.nonConsumable(
    this.id, {
    required this.fallbackTitle,
    this.fallbackDescription = '',
    this.debugPrice = '€1.99',
  })  : kind = ProductKind.nonConsumable,
        walletKey = null,
        walletAmount = 0;

  const ProductSpec.consumable(
    this.id, {
    required String this.walletKey,
    required this.walletAmount,
    required this.fallbackTitle,
    this.fallbackDescription = '',
    this.debugPrice = '€0.99',
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
  final String debugPrice;
}

/// A product as displayed in the store screen.
class StoreItem {
  const StoreItem({
    required this.spec,
    required this.title,
    required this.description,
    required this.price,
  });

  final ProductSpec spec;
  final String title;
  final String description;

  /// Localized price string from the store, e.g. "2,99 €".
  final String price;
}
