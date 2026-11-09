# app_core

Shared code every app depends on. Fix a bug here once, tag a release, and every app picks it up by bumping one line.

| Area | What you get |
|---|---|
| `CoreServices` / `CoreScope` | One object holding everything below, created in `main()` and reachable with `CoreServices.of(context)` |
| Purchases | `PurchaseService` over the official `in_app_purchase` plugin (StoreKit / Play Billing), plus a fake store for debug builds and tests |
| `RewardedAds` | Contract for "watch an ad to continue": `isReady`, `show()`, ad privacy options. No ads SDK here; defaults to `RewardedAds.none()`, `FakeRewardedAds` for debug builds and tests. `CoreServices.showRewardedAd()` pauses the music around the ad |
| `Entitlements` | Offline cache of owned products and wallet balances (coins, hints…) |
| `SaveStore` | Versioned JSON save data with migrations, stored on the device (see "Account sync") |
| `SettingsController` | Sound, music, vibration toggles |
| `AudioController` | SFX pool, looping music (with pause/resume), haptics, all honoring settings |
| `ReviewPrompter` | Native "rate this app" prompt after N good moments, once |
| `CoreLocalizations` | English and French texts of the store and settings screens (add `CoreLocalizations.delegate` to the app's `MaterialApp`) |
| Currencies | The fake store shows each product's `debugPrices` in the device region's currency (EUR in the euro area, USD elsewhere), formatted for the device language. Real stores already return prices in the player's currency |
| `StoreScreen`, `SettingsScreen` | Drop-in screens (restore purchases, privacy policy, ad privacy settings when required, support email, about) |

## Account sync

By default, every app saves on the device first, so it works offline. The same data also follows the player's own Apple or Google account, with no sign-in screen and no server of ours.

| Platform | How | Status |
|---|---|---|
| Android | Google's automatic backup (Android Auto Backup) copies all of the app's data (saves, settings, owned items, wallet) to the player's Google account. That happens about once a day, when the phone is idle, charging and on Wi-Fi, up to 25 MB per app. The data comes back when the app is reinstalled or a new phone is restored from backup. | **Works today**, nothing to build. Never set `android:allowBackup="false"` and never exclude `shared_prefs` in backup rules. |
| iPhone / iPad | iCloud key-value storage (`NSUbiquitousKeyValueStore`) mirrors saves to the player's iCloud. It syncs live between their devices, and changes made offline upload when the device reconnects. Limit: 1 MB and 1024 keys per app. | **Not built yet** (plan below). |
| Purchases | The store itself: "Restore purchases" brings back everything bought, on any device signed in to the same account. | **Works today.** |

On iPhone, the device backup (iCloud Backup, or moving to a new iPhone) already carries the app's data when the player restores a whole phone. It does not cover deleting and reinstalling the app. The iCloud key-value sync closes that gap.

Plan for the iCloud part:

- The copy on the device stays the source of truth: the app never waits for iCloud.
- `SaveStore` gets an optional cloud mirror. Every save is written on the device, then to iCloud. At startup, and whenever iCloud reports a change from another device, the two copies are merged.
- Each app gives a merge rule per save (for example "keep the copy with the most progress"). The default keeps the most recently written copy.
- It needs a small iOS-only native part over `NSUbiquitousKeyValueStore`. That means either app_core becomes a Flutter plugin package with Swift code, or it uses a well-maintained pub.dev plugin if one exists.
- Each app must have the **iCloud** capability with **Key-value storage** on its App ID. That requires the paid Apple Developer Program (free Personal Teams can't use iCloud), so this part can only be tested after enrolling.
- Wallet balances (coins) are an edge case decided per app, not by app_core. See below.
- When it ships, update the iPhone lines in `apps_site/_app-template/` (privacy and support pages) and in each live app's pages: today they describe device backups only.

### Edge case: wallet balances (coins, hints…)

Balances don't sync cleanly, whatever the method:

- **Live sync (iCloud):** if a player spends coins offline on two devices, merging the two balances can duplicate coins or lose them. No merge rule is right in every case.
- **Daily backup (Android):** a restored balance can be up to a day old, so recent purchases or spending can be undone.
- **No sync:** coins bought on one iPhone never reach a new one, because Apple doesn't restore consumables. Only the player's synced or backed-up save can bring them back.

So each app decides whether its wallet is synced, and with which merge rule. The design rule that keeps any mistake harmless: **coins buy only ephemeral benefits** (revives, continues, a hint for the current level). They never buy persistent perks or unlocks. Anything permanent is either a non-consumable purchase, which the store always restores, or progress earned in play and kept in `SaveStore`. A bad merge then costs a player a few revives at most, never something they paid to keep.

The template follows this: coins pay for a "Continue" after a game over, and the permanent extra life is the non-consumable `premium`.

## Languages

Texts live in `lib/src/l10n/core_<lang>.arb` (English is the reference). After editing them, run `flutter gen-l10n` and commit the generated Dart files: apps can't generate them for a dependency, and CI fails if they're stale. A test checks every language has the same keys as English.

To add a language: copy `core_en.arb` to `core_<lang>.arb`, translate, run `flutter gen-l10n`. To add a currency: add its region rule to `currencyForRegion` (`lib/src/iap/currency.dart`) and a price for it in each product's `debugPrices`.

## Releasing a change

```bash
flutter test
# set version: in pubspec.yaml to the tag you are about to create (0.2.0 for v0.2.0)
git commit -am "Describe the change"
git push                              # CI runs analyze + tests; wait for it to pass
git tag v0.2.0 && git push --tags
```

Then in each app that should get it, bump `ref:` under `app_core` in `pubspec.yaml` and run `flutter pub get`.

Keep this repo **public** (it holds no secrets) so app CI can fetch it without tokens. If you make it private, CI needs a token with read access.

## Not included on purpose

- **Receipt validation server.** Fine for cheap unlocks. If you ever sell something expensive or account-based, add server validation or RevenueCat behind `PurchaseService`.
- **Analytics, app accounts.** Each one adds privacy-label and consent work. Add them per app only when needed.
- **An ads SDK.** app_core only defines the `RewardedAds` contract; the AdMob code comes from the separate `app_ads` package, so apps with ads turned off carry nothing.
- **Live sync on Android** (Play Games saved games). It needs setup in Play Console for each app and a Play Games profile for the player, and it adds items to the Data safety form. Add it per app if the daily Google backup isn't enough.
