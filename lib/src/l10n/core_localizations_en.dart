// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CoreLocalizationsEn extends CoreLocalizations {
  CoreLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get storeTitle => 'Store';

  @override
  String get storeTestBanner =>
      'Test store: purchases are free and only saved on this device.';

  @override
  String get storeEmpty => 'Nothing for sale yet.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get storeUnavailable =>
      'The store is unavailable right now. Everything you already own keeps working offline.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get errorUnavailable => 'This item isn\'t available right now.';

  @override
  String get errorFailed =>
      'The purchase didn\'t go through. Please try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get music => 'Music';

  @override
  String get vibration => 'Vibration';

  @override
  String get restoreRequested =>
      'Restore requested. Items you own will reappear in a moment.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacySettings => 'Privacy settings';

  @override
  String get adChoices => 'Ad choices';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get about => 'About';
}
