import '../iap/product_spec.dart';

/// Everything app_core needs to know about one app.
///
/// Each app declares a single `const CoreConfig` (see `lib/config.dart` in the
/// template) and passes it to [CoreServices.init].
class CoreConfig {
  const CoreConfig({
    required this.appName,
    this.products = const [],
    this.privacyPolicyUrl,
    this.supportEmail,
    this.reviewAfterPositiveEvents = 5,
  });

  /// Name shown in the About dialog and support emails.
  final String appName;

  /// In-app products. IDs must match the ones created in App Store Connect
  /// and Google Play Console.
  final List<ProductSpec> products;

  /// Public URL of the privacy policy (both stores require one).
  final String? privacyPolicyUrl;

  /// Address used by the "Contact support" entry in the settings screen.
  final String? supportEmail;

  /// After this many "good moments" (see [ReviewPrompter]) the OS review
  /// prompt is requested once. Set to 0 to disable.
  final int reviewAfterPositiveEvents;

  ProductSpec? product(String id) {
    for (final spec in products) {
      if (spec.id == id) return spec;
    }
    return null;
  }
}
