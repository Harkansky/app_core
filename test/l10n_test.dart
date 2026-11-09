import 'dart:convert';
import 'dart:io';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const premium = ProductSpec.nonConsumable(
  'premium',
  fallbackTitle: 'Premium',
  debugPrices: {'USD': 2.99, 'EUR': 2.99},
);

/// Removes the narrow/no-break spaces some locales put before "€".
String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Future<List<StoreItem>> fakeItems(Locale locale) async {
  final purchases = FakePurchaseService(
    specs: const [premium],
    entitlements: Entitlements(MemoryStore()),
    locale: locale,
  );
  await purchases.init();
  return purchases.items;
}

Widget app(CoreServices core, Widget home, {Locale? locale}) => CoreScope(
  services: core,
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: CoreLocalizations.localizationsDelegates,
    supportedLocales: CoreLocalizations.supportedLocales,
    home: home,
  ),
);

Future<CoreServices> services(CoreConfig config) => CoreServices.init(
  config,
  store: MemoryStore(),
  fakePurchases: true,
  silentAudio: true,
  fakePurchaseDelay: Duration.zero,
);

void main() {
  test('every translation has exactly the English keys', () {
    Set<String> keys(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>).keys
            .where((k) => !k.startsWith('@'))
            .toSet();
    final english = keys('lib/src/l10n/core_en.arb');
    final others = Directory('lib/src/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb') && !f.path.endsWith('_en.arb'));
    expect(others, isNotEmpty);
    for (final file in others) {
      expect(keys(file.path), english, reason: file.path);
    }
  });

  group('currency', () {
    test('euro regions pay in EUR, others in the default', () {
      for (final region in ['FR', 'DE', 'IE', 'BG', 'fr']) {
        expect(currencyForRegion(region), 'EUR', reason: region);
      }
      for (final region in ['US', 'GB', 'CA', null]) {
        expect(currencyForRegion(region), 'USD', reason: '$region');
      }
      expect(currencyForRegion('JP', fallback: 'EUR'), 'EUR');
    });

    test('fake prices follow region and language', () async {
      expect(
        (await fakeItems(const Locale('en', 'US'))).single.price,
        r'$2.99',
      );
      expect(
        plain((await fakeItems(const Locale('fr', 'FR'))).single.price),
        '2,99 €',
      );
      expect((await fakeItems(const Locale('en', 'IE'))).single.price, '€2.99');
    });

    test(
      'a currency missing from debugPrices falls back to the default',
      () async {
        final purchases = FakePurchaseService(
          specs: const [
            ProductSpec.nonConsumable(
              'x',
              fallbackTitle: 'X',
              debugPrices: {'USD': 1.0},
            ),
          ],
          entitlements: Entitlements(MemoryStore()),
          locale: const Locale('fr', 'FR'),
        );
        await purchases.init();
        expect(plain(purchases.items.single.price), contains(r'$'));
      },
    );
  });

  testWidgets('settings screen in French', (tester) async {
    final core = await services(
      const CoreConfig(
        appName: 'Test',
        privacyPolicyUrl: 'https://example.com/privacy/',
        privacyPolicyUrlsByLanguage: {'fr': 'https://example.com/fr/privacy/'},
      ),
    );
    await tester.pumpWidget(
      app(core, const SettingsScreen(), locale: const Locale('fr')),
    );
    await tester.pump();
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Effets sonores'), findsOneWidget);
    expect(find.text('Restaurer les achats'), findsOneWidget);
    expect(find.text('Politique de confidentialité'), findsOneWidget);
  });

  test('privacy page per language', () {
    const config = CoreConfig(
      appName: 'Test',
      privacyPolicyUrl: 'https://example.com/privacy/',
      privacyPolicyUrlsByLanguage: {'fr': 'https://example.com/fr/privacy/'},
    );
    expect(
      config.privacyPolicyUrlFor(const Locale('fr', 'CA')),
      'https://example.com/fr/privacy/',
    );
    expect(
      config.privacyPolicyUrlFor(const Locale('de')),
      'https://example.com/privacy/',
    );
  });

  testWidgets('store screen uses translated fallback text and wallet names', (
    tester,
  ) async {
    final core = await services(
      CoreConfig(
        appName: 'Test',
        products: const [premium],
        walletName: (context, key) => 'Pièces',
        productText: (context, spec) =>
            const ProductText('Premium FR', 'Une vie en plus'),
      ),
    );
    await core.entitlements.credit('coins', 1500);
    await tester.pumpWidget(
      app(core, const StoreScreen(), locale: const Locale('fr')),
    );
    await tester.pump();
    expect(find.text('Boutique'), findsOneWidget);
    expect(find.text('Pièces'), findsOneWidget);
    expect(find.text('Premium FR'), findsOneWidget);
    expect(find.text('Une vie en plus'), findsOneWidget);
    expect(find.textContaining(RegExp('1[   ]500')), findsOneWidget);
  });

  testWidgets('store errors show a translated message', (tester) async {
    final core = await services(
      const CoreConfig(appName: 'Test', products: [premium]),
    );
    await tester.pumpWidget(
      app(core, const StoreScreen(), locale: const Locale('fr')),
    );
    await tester.pump();
    await core.purchases.buy('unknown');
    await tester.pump();
    expect(
      find.text("Cet article n'est pas disponible pour le moment."),
      findsOneWidget,
    );
    expect(core.purchases.errorKind, PurchaseErrorKind.unavailable);
  });
}
