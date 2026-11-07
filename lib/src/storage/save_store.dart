import 'dart:convert';

import 'key_value_store.dart';

/// Upgrades save data from version `n` to version `n + 1`.
typedef SaveMigration = Map<String, Object?> Function(Map<String, Object?> data);

/// A versioned JSON document (game progress, app state) stored under one key.
///
/// When the shape of your save data changes, bump [version] and add a
/// migration keyed by the *old* version number:
///
/// ```dart
/// SaveStore(store, key: 'progress', version: 2, migrations: {
///   1: (data) => {...data, 'stars': <int>[]},
/// });
/// ```
class SaveStore {
  SaveStore(
    this._store, {
    required this.key,
    this.version = 1,
    this.migrations = const {},
  });

  final KeyValueStore _store;
  final String key;
  final int version;
  final Map<int, SaveMigration> migrations;

  /// Returns the saved data, migrated to [version], or an empty map.
  Map<String, Object?> load() {
    final raw = _store.getString(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      var from = (decoded['v'] as int?) ?? 1;
      var data = Map<String, Object?>.from(
        (decoded['data'] as Map?) ?? const <String, Object?>{},
      );
      while (from < version) {
        final migrate = migrations[from];
        if (migrate != null) data = migrate(data);
        from++;
      }
      return data;
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  Future<void> save(Map<String, Object?> data) =>
      _store.setString(key, jsonEncode({'v': version, 'data': data}));

  Future<void> clear() => _store.remove(key);
}
