import 'dart:async';

import 'package:flutter/widgets.dart';

import 'ads/rewarded_ads.dart';
import 'audio/audio_controller.dart';
import 'config/core_config.dart';
import 'iap/entitlements.dart';
import 'iap/purchase_service.dart';
import 'review/review_prompter.dart';
import 'settings/settings_controller.dart';
import 'storage/key_value_store.dart';

/// All shared services for one app, created once at startup.
class CoreServices {
  CoreServices._({
    required this.config,
    required this.store,
    required this.settings,
    required this.entitlements,
    required this.purchases,
    required this.audio,
    required this.review,
    required this.ads,
  });

  /// Builds everything. Startup never waits on the network: the store
  /// connects in the background and owned content is read from the device.
  ///
  /// - [store]: defaults to on-device storage; pass [MemoryStore] in tests.
  /// - [fakePurchases]: use the fake store (debug builds, tests).
  /// - [silentAudio]: disable all audio (tests).
  /// - [ads]: rewarded ads (an `app_ads` adapter, or [FakeRewardedAds] in
  ///   debug builds and tests); defaults to [RewardedAds.none]. Like
  ///   purchases, it initializes in the background.
  static Future<CoreServices> init(
    CoreConfig config, {
    KeyValueStore? store,
    bool fakePurchases = false,
    bool silentAudio = false,
    Duration fakePurchaseDelay = const Duration(milliseconds: 300),
    RewardedAds? ads,
  }) async {
    final kv = store ?? await SharedPrefsStore.create();
    final settings = SettingsController(kv)..load();
    final entitlements = Entitlements(kv)..load();
    final purchases = PurchaseService.create(
      specs: config.products,
      entitlements: entitlements,
      store: kv,
      forceFake: fakePurchases,
      fakeDelay: fakePurchaseDelay,
      defaultCurrency: config.defaultCurrency,
    );
    unawaited(purchases.init());
    final rewardedAds = ads ?? RewardedAds.none();
    unawaited(rewardedAds.init());

    return CoreServices._(
      config: config,
      store: kv,
      settings: settings,
      entitlements: entitlements,
      purchases: purchases,
      audio: AudioController(settings, silent: silentAudio),
      review: ReviewPrompter(kv, threshold: config.reviewAfterPositiveEvents),
      ads: rewardedAds,
    );
  }

  final CoreConfig config;
  final KeyValueStore store;
  final SettingsController settings;
  final Entitlements entitlements;
  final PurchaseService purchases;
  final AudioController audio;
  final ReviewPrompter review;
  final RewardedAds ads;

  static CoreServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CoreScope>();
    assert(
      scope != null,
      'No CoreScope above this widget. Wrap your app in CoreScope.',
    );
    return scope!.services;
  }

  /// Plays a rewarded ad with the music paused, then resumes it. Completes
  /// with true only when the player earned the reward. Returns false at once
  /// (music untouched) when no ad is ready, e.g. offline.
  Future<bool> showRewardedAd() async {
    if (!ads.isReady) return false;
    await audio.pauseMusic();
    try {
      return await ads.show();
    } finally {
      await audio.resumeMusic();
    }
  }

  void dispose() {
    purchases.dispose();
    ads.dispose();
    audio.dispose();
    settings.dispose();
    entitlements.dispose();
  }
}

/// Makes [CoreServices] available to the widget tree via [CoreServices.of].
class CoreScope extends InheritedWidget {
  const CoreScope({super.key, required this.services, required super.child});

  final CoreServices services;

  @override
  bool updateShouldNotify(CoreScope oldWidget) =>
      services != oldWidget.services;
}
