import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';
import 'product_spec.dart';

/// What the player owns, cached on the device so the app works offline.
///
/// - Non-consumables: a set of owned product IDs.
/// - Wallet: named balances (coins, hints...) credited by consumable purchases
///   and by gameplay rewards, spent by the app.
///
/// The store is the source of truth for non-consumables; "Restore purchases"
/// re-syncs this cache after a reinstall or on a new device.
class Entitlements extends ChangeNotifier {
  Entitlements(this._store);

  static const _ownedKey = 'core.entitlements.owned';
  static const _walletKey = 'core.entitlements.wallet';

  final KeyValueStore _store;
  final Set<String> _owned = {};
  final Map<String, int> _wallet = {};

  void load() {
    _owned
      ..clear()
      ..addAll(_decodeList(_store.getString(_ownedKey)));
    _wallet
      ..clear()
      ..addAll(_decodeMap(_store.getString(_walletKey)));
  }

  bool owns(String productId) => _owned.contains(productId);

  Set<String> get owned => Set.unmodifiable(_owned);

  int balance(String walletKey) => _wallet[walletKey] ?? 0;

  Map<String, int> get wallet => Map.unmodifiable(_wallet);

  /// Delivers a purchase.
  Future<void> grant(ProductSpec spec) async {
    switch (spec.kind) {
      case ProductKind.nonConsumable:
        if (_owned.add(spec.id)) {
          await _persist();
          notifyListeners();
        }
      case ProductKind.consumable:
        await credit(spec.walletKey!, spec.walletAmount);
    }
  }

  /// Adds to a wallet balance (purchase or gameplay reward).
  Future<void> credit(String walletKey, int amount) async {
    if (amount <= 0) return;
    _wallet[walletKey] = balance(walletKey) + amount;
    await _persist();
    notifyListeners();
  }

  /// Spends from a wallet balance. Returns false if the balance is too low.
  Future<bool> spend(String walletKey, int amount) async {
    if (amount <= 0) return true;
    if (balance(walletKey) < amount) return false;
    _wallet[walletKey] = balance(walletKey) - amount;
    await _persist();
    notifyListeners();
    return true;
  }

  /// Wipes everything. Meant for debug menus and tests only.
  Future<void> resetForDebug() async {
    _owned.clear();
    _wallet.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.setString(_ownedKey, jsonEncode(_owned.toList()));
    await _store.setString(_walletKey, jsonEncode(_wallet));
  }

  static Iterable<String> _decodeList(String? raw) {
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).whereType<String>();
    } catch (_) {
      return const [];
    }
  }

  static Map<String, int> _decodeMap(String? raw) {
    if (raw == null) return const {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in map.entries)
          if (entry.value is int) entry.key: entry.value as int,
      };
    } catch (_) {
      return const {};
    }
  }
}
