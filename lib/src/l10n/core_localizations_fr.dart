// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class CoreLocalizationsFr extends CoreLocalizations {
  CoreLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get storeTitle => 'Boutique';

  @override
  String get storeTestBanner =>
      'Boutique de test : les achats sont gratuits et enregistrés uniquement sur cet appareil.';

  @override
  String get storeEmpty => 'Rien à vendre pour le moment.';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get storeUnavailable =>
      'La boutique est indisponible pour le moment. Tout ce que vous possédez déjà continue de fonctionner hors ligne.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get dismiss => 'Fermer';

  @override
  String get errorUnavailable =>
      'Cet article n\'est pas disponible pour le moment.';

  @override
  String get errorFailed => 'L\'achat n\'a pas abouti. Veuillez réessayer.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get soundEffects => 'Effets sonores';

  @override
  String get music => 'Musique';

  @override
  String get vibration => 'Vibrations';

  @override
  String get restoreRequested =>
      'Restauration demandée. Vos achats réapparaîtront dans un instant.';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get privacySettings => 'Paramètres de confidentialité';

  @override
  String get adChoices => 'Choix publicitaires';

  @override
  String get contactSupport => 'Contacter l\'assistance';

  @override
  String get about => 'À propos';
}
