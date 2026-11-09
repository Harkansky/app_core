import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = CoreConfig(appName: 'Test');

Future<CoreServices> _core({RewardedAds? ads}) => CoreServices.init(
  _config,
  store: MemoryStore(),
  fakePurchases: true,
  silentAudio: true,
  ads: ads,
);

/// Ads whose privacy requirement can change after startup, like a real
/// consent flow finishing in the background.
class _SwitchableAds extends FakeRewardedAds {
  _SwitchableAds() : super(delay: Duration.zero);

  bool _required = false;

  @override
  bool get privacyOptionsRequired => _required;

  void requirePrivacyOptions() {
    _required = true;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RewardedAds.none', () {
    test('is never ready and never rewards', () async {
      final ads = RewardedAds.none();
      await ads.init();
      expect(ads.isReady, isFalse);
      expect(ads.privacyOptionsRequired, isFalse);
      expect(await ads.show(), isFalse);
      await ads.showPrivacyOptions();
      ads.dispose();
    });
  });

  group('FakeRewardedAds', () {
    test('is ready only after init, then rewards every time', () async {
      final ads = FakeRewardedAds(delay: Duration.zero);
      var notified = 0;
      ads.addListener(() => notified++);

      expect(ads.isReady, isFalse);
      expect(await ads.show(), isFalse);

      await ads.init();
      expect(ads.isReady, isTrue);
      expect(notified, 1);

      expect(await ads.show(), isTrue);
      expect(await ads.show(), isTrue);
      expect(ads.isReady, isTrue);
      ads.dispose();
    });

    test('waits for the delay before rewarding', () async {
      final ads = FakeRewardedAds(delay: const Duration(milliseconds: 20));
      await ads.init();
      final watch = Stopwatch()..start();
      expect(await ads.show(), isTrue);
      expect(
        watch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 20)),
      );
      ads.dispose();
    });

    test('reports privacy options as configured', () async {
      final ads = FakeRewardedAds(privacyOptionsRequired: true);
      expect(ads.privacyOptionsRequired, isTrue);
      await ads.showPrivacyOptions();
      expect(ads.privacyOptionsShown, 1);
      ads.dispose();
    });
  });

  group('CoreServices', () {
    test('defaults to no ads', () async {
      final core = await _core();
      expect(core.ads.isReady, isFalse);
      expect(await core.showRewardedAd(), isFalse);
      core.dispose();
    });

    test(
      'initializes the injected ads without waiting and shows them',
      () async {
        final ads = FakeRewardedAds(delay: Duration.zero);
        final core = await _core(ads: ads);
        expect(core.ads, same(ads));
        await pumpEventQueue();
        expect(ads.isReady, isTrue);
        expect(await core.showRewardedAd(), isTrue);
        core.dispose();
      },
    );

    test('music pause and resume are safe when audio is silent', () async {
      final core = await _core();
      await core.audio.pauseMusic();
      await core.audio.resumeMusic();
      core.dispose();
    });
  });

  group('SettingsScreen', () {
    Future<void> pumpSettings(WidgetTester tester, CoreServices core) =>
        tester.pumpWidget(
          CoreScope(
            services: core,
            child: const MaterialApp(
              localizationsDelegates: CoreLocalizations.localizationsDelegates,
              supportedLocales: CoreLocalizations.supportedLocales,
              home: SettingsScreen(),
            ),
          ),
        );

    testWidgets('hides Privacy settings when ads do not require it', (
      tester,
    ) async {
      final core = await _core(ads: FakeRewardedAds(delay: Duration.zero));
      await pumpSettings(tester, core);
      expect(find.text('Privacy settings'), findsNothing);
      core.dispose();
    });

    testWidgets('shows Privacy settings when required and opens the form', (
      tester,
    ) async {
      final ads = FakeRewardedAds(
        delay: Duration.zero,
        privacyOptionsRequired: true,
      );
      final core = await _core(ads: ads);
      await pumpSettings(tester, core);

      expect(find.text('Privacy settings'), findsOneWidget);
      expect(find.text('Ad choices'), findsOneWidget);
      await tester.tap(find.text('Privacy settings'));
      expect(ads.privacyOptionsShown, 1);
      core.dispose();
    });

    testWidgets('rebuilds when the ads requirement changes', (tester) async {
      final ads = _SwitchableAds();
      final core = await _core(ads: ads);
      await pumpSettings(tester, core);
      expect(find.text('Privacy settings'), findsNothing);

      ads.requirePrivacyOptions();
      await tester.pump();
      expect(find.text('Privacy settings'), findsOneWidget);
      core.dispose();
    });
  });
}
