import 'package:flutter/foundation.dart';

/// The one interface apps use for rewarded ads ("watch an ad to continue").
///
/// app_core carries no ads SDK: the real implementation lives in the separate
/// `app_ads` package, which the app adapts to this class and passes to
/// [CoreServices.init]. Apps that don't show ads pass nothing and get
/// [RewardedAds.none].
///
/// Offline rule: nothing ever waits on the network. [init] is started in the
/// background (like purchases) and an ad is loaded only when one can be;
/// until then, and whenever the device is offline, [isReady] is false. Hide
/// or disable "watch an ad" buttons while it is false, and listen to this
/// object to learn when an ad becomes ready.
abstract class RewardedAds extends ChangeNotifier {
  RewardedAds();

  /// Ads turned off: never ready, [show] returns false, no privacy options.
  factory RewardedAds.none() = _NoRewardedAds;

  /// True when an ad is loaded and [show] can play it right away.
  /// Always false offline.
  bool get isReady;

  /// True when the ad network's consent form (GDPR and similar) must stay
  /// reachable from the app; [SettingsScreen] then shows "Privacy settings".
  bool get privacyOptionsRequired;

  /// Gathers consent and starts loading the first ad. Called once by
  /// [CoreServices.init] without awaiting it; must never throw.
  Future<void> init();

  /// Plays a rewarded ad. Completes with true only when the player earned the
  /// reward; false when no ad was ready, it failed, or it was closed early.
  /// Implementations load the next ad afterwards in the background.
  Future<bool> show();

  /// Opens the ad network's privacy options form again.
  Future<void> showPrivacyOptions();
}

class _NoRewardedAds extends RewardedAds {
  @override
  bool get isReady => false;

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> init() async {}

  @override
  Future<bool> show() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}

/// Pretend ads: every ad is "watched" in full after [delay].
///
/// Used in debug builds and tests, like `FakePurchaseService`. Not ready
/// until [init] runs; then stays ready, so a player can watch any number.
class FakeRewardedAds extends RewardedAds {
  FakeRewardedAds({
    this.delay = const Duration(milliseconds: 300),
    this.privacyOptionsRequired = false,
  });

  final Duration delay;

  @override
  final bool privacyOptionsRequired;

  bool _ready = false;

  /// How many times [showPrivacyOptions] was called (for tests).
  int privacyOptionsShown = 0;

  @override
  bool get isReady => _ready;

  @override
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    notifyListeners();
  }

  @override
  Future<bool> show() async {
    if (!_ready) return false;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return true;
  }

  @override
  Future<void> showPrivacyOptions() async {
    privacyOptionsShown++;
  }
}
