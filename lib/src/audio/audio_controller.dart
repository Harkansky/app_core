import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../settings/settings_controller.dart';

/// Sound effects, looping music and haptics, all honoring [SettingsController].
///
/// Asset paths are relative to `assets/`, e.g. `playSfx('audio/pop.wav')`
/// plays `assets/audio/pop.wav` (declare the folder in the app's pubspec).
/// Players are created lazily, so tests and silent apps never touch audio.
class AudioController {
  AudioController(this._settings, {this.silent = false}) {
    _settings.addListener(_onSettingsChanged);
  }

  static const _sfxPoolSize = 4;

  final SettingsController _settings;

  /// When true (tests), every call is a no-op.
  final bool silent;

  final List<AudioPlayer> _sfxPool = [];
  Future<void>? _poolReady;
  int _nextSfx = 0;
  AudioPlayer? _music;
  String? _musicAsset;

  /// Set by [pauseMusic] (e.g. while an ad plays) so nothing restarts the
  /// track until [resumeMusic].
  bool _musicPaused = false;

  Future<void> playSfx(String asset, {double volume = 1}) async {
    if (silent || !_settings.soundOn) return;
    try {
      await (_poolReady ??= _createPool());
      final player = _sfxPool[_nextSfx];
      _nextSfx = (_nextSfx + 1) % _sfxPool.length;
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (error) {
      debugPrint('[app_core] Could not play $asset: $error');
    }
  }

  /// Built once, even if several sounds are requested at the same moment.
  Future<void> _createPool() async {
    final players = <AudioPlayer>[];
    for (var i = 0; i < _sfxPoolSize; i++) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      players.add(player);
    }
    _sfxPool.addAll(players);
  }

  /// Starts (or switches to) a looping music track.
  Future<void> playMusic(String asset, {double volume = 0.5}) async {
    _musicAsset = asset;
    if (silent || _musicPaused || !_settings.musicOn) return;
    try {
      final music = _music ??= AudioPlayer();
      await music.setReleaseMode(ReleaseMode.loop);
      await music.play(AssetSource(asset), volume: volume);
    } catch (error) {
      debugPrint('[app_core] Could not play music $asset: $error');
    }
  }

  Future<void> stopMusic() async {
    _musicAsset = null;
    await _music?.stop();
  }

  /// Pauses the music without forgetting the track, e.g. while a rewarded
  /// ad plays. Undo with [resumeMusic].
  Future<void> pauseMusic() async {
    if (silent) return;
    _musicPaused = true;
    try {
      await _music?.pause();
    } catch (error) {
      debugPrint('[app_core] Could not pause music: $error');
    }
  }

  /// Restarts the track stopped by [pauseMusic], only if music is on in
  /// settings and a track was playing.
  Future<void> resumeMusic() async {
    if (silent) return;
    _musicPaused = false;
    await _resumeIfWanted();
  }

  /// A light tap of vibration, if the player allows it.
  void haptic() {
    if (silent || !_settings.hapticsOn) return;
    HapticFeedback.lightImpact();
  }

  void _onSettingsChanged() {
    if (silent) return;
    if (!_settings.musicOn) {
      _music?.pause();
    } else {
      _resumeIfWanted();
    }
  }

  Future<void> _resumeIfWanted() async {
    if (_musicPaused || !_settings.musicOn) return;
    final asset = _musicAsset;
    if (asset != null && _music?.state != PlayerState.playing) {
      await playMusic(asset);
    }
  }

  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    for (final player in _sfxPool) {
      player.dispose();
    }
    _music?.dispose();
  }
}
