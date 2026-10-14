import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx {
  move,
  bump,
  rotate,
  soft,
  hard,
  lock,
  hold,
  clear1,
  clear2,
  clear3,
  clear4,
  tspin,
  levelup,
  gameover,
  perfect,
  click,
  start,
  combo1,
  combo2,
  combo3,
  combo4,
  combo5,
  combo6,
  combo7,
  combo8,
}

/// Sound effects and a shuffled background music playlist.
///
/// Every call is fire-and-forget and failures are swallowed: missing audio
/// support on a platform must never break the game.
class AudioService {
  AudioService({this.enabled = true});

  /// False in widget tests, where no audio plugin is available.
  final bool enabled;

  static const List<String> tracks = [
    'audio/music/track1.mp3',
    'audio/music/track2.mp3',
    'audio/music/track3.mp3',
    'audio/music/track4.mp3',
  ];

  final Map<Sfx, AudioPool> _pools = {};
  final Map<Sfx, DateTime> _lastPlayed = {};
  AudioPlayer? _music;
  StreamSubscription<void>? _musicDone;
  final Random _random = Random();
  int? _currentTrack;
  final List<int> _queue = [];

  bool sfxOn = true;
  bool _musicOn = true;
  double _musicVolume = 0.6;
  double _duck = 1;
  bool _musicStarted = false;

  /// Sound effects must never take Android audio focus: if they did, every
  /// effect would make the music player lose focus and stop. They mix with
  /// whatever is playing instead (on iOS the shared session mixes too).
  static final AudioContext _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).buildIOS(),
  );

  /// Only the music holds focus, so other apps' music pauses while we play.
  static final AudioContext _musicContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).buildIOS(),
  );

  Future<void> init() async {
    if (!enabled) return;
    try {
      await AudioPlayer.global.setAudioContext(_sfxContext);
    } catch (e) {
      debugPrint('Audio context failed: $e');
    }
    try {
      await Future.wait(
        Sfx.values.map((s) async {
          final busy = s == Sfx.move || s == Sfx.soft || s == Sfx.rotate || s == Sfx.lock;
          _pools[s] = await AudioPool.create(
            source: AssetSource('audio/sfx/${s.name}.wav'),
            maxPlayers: busy ? 4 : 2,
            audioContext: _sfxContext,
          );
        }),
      );
    } catch (e) {
      debugPrint('Audio init failed: $e');
    }
  }

  void play(Sfx sfx, {double volume = 1}) {
    if (!enabled || !sfxOn) return;
    final pool = _pools[sfx];
    if (pool == null) return;
    // Avoid machine-gunning the same sample (auto-repeat, soft drop).
    final now = DateTime.now();
    final last = _lastPlayed[sfx];
    if (last != null && now.difference(last).inMilliseconds < 35) return;
    _lastPlayed[sfx] = now;
    pool.start(volume: volume).catchError((Object e) {
      debugPrint('sfx $sfx failed: $e');
      return () async {};
    });
  }

  void playCombo(int combo) {
    if (combo < 1) return;
    play(Sfx.values.byName('combo${min(combo, 8)}'), volume: 0.8);
  }

  // ------------------------------------------------------------ music

  set musicOn(bool on) {
    _musicOn = on;
    if (!on) {
      _music?.pause().catchError((_) {});
    } else if (_musicStarted) {
      final player = _music;
      if (player == null) return;
      if (player.state == PlayerState.completed || player.state == PlayerState.stopped) {
        _playNext();
      } else {
        player.resume().catchError((_) {});
      }
    }
  }

  set musicVolume(double v) {
    _musicVolume = v;
    _applyVolume();
  }

  /// Lowers the music, e.g. while paused (0..1 multiplier).
  set duck(double v) {
    _duck = v;
    _applyVolume();
  }

  void _applyVolume() => _music?.setVolume(_musicVolume * _duck).catchError((_) {});

  /// Starts the shuffled playlist. Browsers only allow audio after a user
  /// gesture, so call this from a button press.
  Future<void> startMusic() async {
    if (!enabled || _musicStarted) return;
    _musicStarted = true;
    try {
      _music = AudioPlayer();
      await _music!.setAudioContext(_musicContext);
      await _music!.setReleaseMode(ReleaseMode.stop);
      _musicDone = _music!.onPlayerComplete.listen((_) => _playNext());
      await _playNext();
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  /// Picks a random track, never the one that just played, cycling through
  /// all tracks before any repeats.
  int nextTrackIndex() {
    if (_queue.isEmpty) {
      _queue.addAll(List.generate(tracks.length, (i) => i)..shuffle(_random));
      if (_queue.length > 1 && _queue.first == _currentTrack) {
        _queue.add(_queue.removeAt(0));
      }
    }
    return _currentTrack = _queue.removeAt(0);
  }

  Future<void> _playNext() async {
    final player = _music;
    if (player == null) return;
    try {
      await player.play(AssetSource(tracks[nextTrackIndex()]), volume: _musicVolume * _duck);
      if (!_musicOn) await player.pause();
    } catch (e) {
      debugPrint('Music track failed: $e');
    }
  }

  Future<void> skipTrack() => _playNext();

  void dispose() {
    _musicDone?.cancel();
    _music?.dispose();
    for (final pool in _pools.values) {
      pool.dispose();
    }
  }
}
