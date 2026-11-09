import 'package:flutter/widgets.dart';

import '../iap/product_spec.dart';

/// Name of a wallet balance in the player's language ("Coins", "Pièces").
typedef WalletName = String Function(BuildContext context, String walletKey);

/// Translated fallback text for a product (fake store, store offline).
typedef ProductTextBuilder = ProductText Function(
  BuildContext context,
  ProductSpec spec,
);

/// Everything app_core needs to know about one app.
///
/// Each app declares a single `const CoreConfig` (see `lib/config.dart` in the
/// template) and passes it to [CoreServices.init].
class CoreConfig {
  const CoreConfig({
    required this.appName,
    this.products = const [],
    this.privacyPolicyUrl,
    this.privacyPolicyUrlsByLanguage = const {},
    this.supportEmail,
    this.reviewAfterPositiveEvents = 5,
    this.defaultCurrency = 'USD',
    this.walletName,
    this.productText,
  });

  /// Name shown in the About dialog and support emails.
  final String appName;

  /// In-app products. IDs must match the ones created in App Store Connect
  /// and Google Play Console.
  final List<ProductSpec> products;

  /// Public URL of the privacy policy (both stores require one).
  final String? privacyPolicyUrl;

  /// Translated privacy policy pages by language code, e.g.
  /// `{'fr': '.../fr/privacy/'}`. Other languages use [privacyPolicyUrl].
  final Map<String, String> privacyPolicyUrlsByLanguage;

  /// Address used by the "Contact support" entry in the settings screen.
  final String? supportEmail;

  /// After this many "good moments" (see [ReviewPrompter]) the OS review
  /// prompt is requested once. Set to 0 to disable.
  final int reviewAfterPositiveEvents;

  /// Fake-store currency outside the euro regions (see `currencyForRegion`).
  final String defaultCurrency;

  /// Translated wallet names for the store screen; a top-level function so
  /// the config stays const. Without it, the wallet key is shown capitalized.
  final WalletName? walletName;

  /// Translated product titles and descriptions for items that don't come
  /// from the real store. Without it, [ProductSpec.fallbackTitle] is used.
  final ProductTextBuilder? productText;

  /// The privacy policy page for [locale]'s language, if any.
  String? privacyPolicyUrlFor(Locale locale) =>
      privacyPolicyUrlsByLanguage[locale.languageCode] ?? privacyPolicyUrl;

  ProductSpec? product(String id) {
    for (final spec in products) {
      if (spec.id == id) return spec;
    }
    return null;
  }
}
