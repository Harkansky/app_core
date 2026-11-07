import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';

/// Player preferences shared by every app: sound, music, vibration.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  static const _soundKey = 'core.settings.sound';
  static const _musicKey = 'core.settings.music';
  static const _hapticsKey = 'core.settings.haptics';

  final KeyValueStore _store;

  bool _soundOn = true;
  bool _musicOn = true;
  bool _hapticsOn = true;

  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  bool get hapticsOn => _hapticsOn;

  void load() {
    _soundOn = _store.getBool(_soundKey) ?? true;
    _musicOn = _store.getBool(_musicKey) ?? true;
    _hapticsOn = _store.getBool(_hapticsKey) ?? true;
  }

  Future<void> setSoundOn(bool value) async {
    _soundOn = value;
    notifyListeners();
    await _store.setBool(_soundKey, value);
  }

  Future<void> setMusicOn(bool value) async {
    _musicOn = value;
    notifyListeners();
    await _store.setBool(_musicKey, value);
  }

  Future<void> setHapticsOn(bool value) async {
    _hapticsOn = value;
    notifyListeners();
    await _store.setBool(_hapticsKey, value);
  }
}
