import 'package:shared_preferences/shared_preferences.dart';

/// Minimal synchronous-read / async-write key-value storage.
///
/// Everything app_core persists goes through this, so tests can swap in
/// [MemoryStore] and apps stay fully offline.
abstract interface class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  int? getInt(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
  Future<void> setInt(String key, int value);
  Future<void> remove(String key);
}

/// On-device storage backed by shared_preferences.
class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SharedPrefsStore> create() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return SharedPrefsStore._(prefs);
  }

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  int? getInt(String key) => _prefs.getInt(key);
  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  @override
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// In-memory storage for tests and previews.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, Object>? initial]) : _data = {...?initial};

  final Map<String, Object> _data;

  @override
  String? getString(String key) => _data[key] as String?;
  @override
  bool? getBool(String key) => _data[key] as bool?;
  @override
  int? getInt(String key) => _data[key] as int?;
  @override
  Future<void> setString(String key, String value) async => _data[key] = value;
  @override
  Future<void> setBool(String key, bool value) async => _data[key] = value;
  @override
  Future<void> setInt(String key, int value) async => _data[key] = value;
  @override
  Future<void> remove(String key) async => _data.remove(key);
}
