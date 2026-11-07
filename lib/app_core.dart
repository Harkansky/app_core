/// Shared building blocks for every app.
///
/// Typical use in an app's `main.dart`:
///
/// ```dart
/// final core = await CoreServices.init(appConfig);
/// runApp(CoreScope(services: core, child: const App()));
/// ```
library;

export 'src/audio/audio_controller.dart';
export 'src/config/core_config.dart';
export 'src/core_services.dart';
export 'src/iap/entitlements.dart';
export 'src/iap/fake_purchase_service.dart';
export 'src/iap/product_spec.dart';
export 'src/iap/purchase_service.dart';
export 'src/iap/store_purchase_service.dart';
export 'src/review/review_prompter.dart';
export 'src/settings/settings_controller.dart';
export 'src/storage/key_value_store.dart';
export 'src/storage/save_store.dart';
export 'src/ui/links.dart';
export 'src/ui/settings_screen.dart';
export 'src/ui/store_screen.dart';
