import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Players are kept alive across screens so the background track never restarts.
class GameAudio {
  final _music = AudioPlayer();
  final _cut = AudioPlayer();
  final _sand = AudioPlayer();
  final _celebration = AudioPlayer();
  Timer? _celebrationLimit;
  bool _hasCelebration = false;
  double musicVolume = .35;
  bool musicEnabled = true;
  double effectsVolume = .65;
  bool _rubbing = false;
  bool _suspended = false;
  bool available = true;
  DateTime _lastCut = DateTime(2000);

  Future<void> start() async {
    try {
      final effectsContext = AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      );
      await _cut.setAudioContext(effectsContext);
      await _sand.setAudioContext(effectsContext);
      await _celebration.setAudioContext(effectsContext);
      final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
      _hasCelebration = assets.listAssets().contains(
        'assets/sound/celebration.wav',
      );
    } catch (_) {
      _hasCelebration = false;
    }
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _sand.setReleaseMode(ReleaseMode.loop);
      await _music.play(
        AssetSource('sound/background.wav'),
        volume: musicEnabled ? musicVolume : 0,
      );
    } catch (_) {
      available = false;
    }
  }

  Future<void> volumes(double music, double effects) async {
    musicVolume = music;
    effectsVolume = effects;
    try {
      await _music.setVolume(musicEnabled ? music : 0);
      await _cut.setVolume(effects);
      await _sand.setVolume(effects * .45);
      await _celebration.setVolume(effects);
    } catch (_) {
      available = false;
    }
  }

  Future<void> cut() async {
    if (_suspended ||
        DateTime.now().difference(_lastCut).inMilliseconds < 160) {
      return;
    }
    _lastCut = DateTime.now();
    try {
      await _cut.stop();
      await _cut.play(
        AssetSource('sound/490114__manuelaurreaf__cutting-fabric.wav'),
        volume: effectsVolume,
      );
    } catch (_) {
      available = false;
    }
  }

  Future<void> rub(bool active) async {
    active = active && !_suspended;
    if (_rubbing == active) return;
    _rubbing = active;
    try {
      if (active) {
        await _sand.play(
          AssetSource('sound/sand.wav'),
          volume: effectsVolume * .45,
        );
        // A pointer may have ended while the decoder was opening the source.
        if (!_rubbing) await _sand.stop();
      } else {
        await _sand.stop();
      }
    } catch (_) {
      available = false;
    }
  }

  Future<void> suspend(bool paused) async {
    _suspended = paused;
    await rub(false);
    try {
      if (paused) {
        await _cut.stop();
        _celebrationLimit?.cancel();
        await _celebration.stop();
      }
    } catch (_) {
      available = false;
    }
  }

  Future<void> celebrate() async {
    if (!_hasCelebration || _suspended) return;
    _celebrationLimit?.cancel();
    try {
      await _celebration.stop();
      await _celebration.play(
        AssetSource('sound/celebration.wav'),
        volume: effectsVolume,
      );
      _celebrationLimit = Timer(
        const Duration(seconds: 3),
        () => _celebration.stop(),
      );
    } catch (_) {
      available = false;
    }
  }

  void dispose() {
    _celebrationLimit?.cancel();
    _celebration.dispose();
    _music.dispose();
    _cut.dispose();
    _sand.dispose();
  }
}
