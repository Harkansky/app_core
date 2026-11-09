import 'package:intl/intl.dart';

/// Countries and territories whose App Store / Google Play storefront
/// charges in euros (euro area, plus the microstates and French overseas
/// regions that use the euro and may report their own region code).
const euroRegions = {
  'AT', 'BE', 'BG', 'CY', 'DE', 'EE', 'ES', 'FI', 'FR', 'GR', 'HR', 'IE', //
  'IT', 'LT', 'LU', 'LV', 'MT', 'NL', 'PT', 'SI', 'SK',
  'AD', 'MC', 'ME', 'SM', 'VA', 'XK',
  'BL', 'GF', 'GP', 'MF', 'MQ', 'PM', 'RE', 'YT',
};

/// Currency the fake store uses for a device region: euros in [euroRegions],
/// otherwise [fallback]. Real stores pick the currency from the player's
/// store account; this only mirrors it for debug builds and tests.
///
/// To support another currency, add its region rule here and a price for it
/// in each product's `debugPrices`.
String currencyForRegion(String? countryCode, {String fallback = 'USD'}) {
  if (countryCode != null && euroRegions.contains(countryCode.toUpperCase())) {
    return 'EUR';
  }
  return fallback;
}

/// Formats [amount] in [currency] the way [locale] writes prices:
/// "$2.99" (en_US), "2,99 €" (fr_FR), "€2.99" (en_IE).
String formatPrice(double amount, String currency, String locale) {
  for (final candidate in [locale, locale.split(RegExp('[_-]')).first, 'en']) {
    try {
      return NumberFormat.simpleCurrency(
        locale: candidate,
        name: currency,
      ).format(amount);
    } on ArgumentError {
      // Unknown locale to intl: try a broader one.
    }
  }
  return '$currency ${amount.toStringAsFixed(2)}';
}
