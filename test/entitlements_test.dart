import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

const premium = ProductSpec.nonConsumable('premium', fallbackTitle: 'Premium');
const coins = ProductSpec.consumable(
  'coins_100',
  walletKey: 'coins',
  walletAmount: 100,
  fallbackTitle: '100 coins',
);

void main() {
  test('non-consumables are granted once and survive a reload', () async {
    final store = MemoryStore();
    final entitlements = Entitlements(store)..load();

    await entitlements.grant(premium);
    await entitlements.grant(premium);
    expect(entitlements.owns('premium'), isTrue);
    expect(entitlements.owned, {'premium'});

    final reloaded = Entitlements(store)..load();
    expect(reloaded.owns('premium'), isTrue);
  });

  test('consumables credit the wallet; spend refuses overdrafts', () async {
    final entitlements = Entitlements(MemoryStore())..load();

    await entitlements.grant(coins);
    await entitlements.credit('coins', 5);
    expect(entitlements.balance('coins'), 105);

    expect(await entitlements.spend('coins', 200), isFalse);
    expect(await entitlements.spend('coins', 50), isTrue);
    expect(entitlements.balance('coins'), 55);
  });

  test('corrupt saved data is ignored instead of crashing', () {
    final store = MemoryStore({
      'core.entitlements.owned': 'not json',
      'core.entitlements.wallet': '[1,2]',
    });
    final entitlements = Entitlements(store)..load();
    expect(entitlements.owned, isEmpty);
    expect(entitlements.wallet, isEmpty);
  });

  test('fake store grants purchases into entitlements', () async {
    final entitlements = Entitlements(MemoryStore())..load();
    final purchases = PurchaseService.create(
      specs: const [premium, coins],
      entitlements: entitlements,
      store: MemoryStore(),
      forceFake: true,
      fakeDelay: Duration.zero,
    );
    await purchases.init();

    expect(purchases.isFake, isTrue);
    expect(purchases.items.map((i) => i.spec.id), ['premium', 'coins_100']);

    expect(await purchases.buy('coins_100'), isTrue);
    expect(await purchases.buy('premium'), isTrue);
    expect(entitlements.balance('coins'), 100);
    expect(entitlements.owns('premium'), isTrue);
    expect(await purchases.buy('nope'), isFalse);
    expect(purchases.lastError, isNotNull);
  });
}
