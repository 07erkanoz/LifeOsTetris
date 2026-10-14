import 'dart:async';
import 'dart:io';
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
  bomb,
  drill,
  gravity,
  slowmo,
  ghost,
  power,
  poweruse,
}

/// Sound effects and a shuffled background music playlist.
///
/// Every call is fire-and-forget and failures are swallowed: missing audio
/// support on a platform must never break the game.
class AudioService {
  AudioService({this.enabled = true, int? lastTrack, this.onTrackStarted}) : _currentTrack = lastTrack, _random = _makeRandom();

  /// False in widget tests, where no audio plugin is available.
  final bool enabled;

  /// Called with each track index as it starts, so the next launch can avoid
  /// opening with the same song.
  final void Function(int track)? onTrackStarted;

  /// On Linux, audioplayers aborts the whole app if GStreamer's playback
  /// plugin is missing. Check for it first and play silently without it.
  static bool get platformSupported {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) return true;
    final dirs = [
      ...?Platform.environment['GST_PLUGIN_PATH']?.split(':'),
      ...?Platform.environment['GST_PLUGIN_SYSTEM_PATH']?.split(':'),
      '/usr/lib/gstreamer-1.0',
      '/usr/lib64/gstreamer-1.0',
      '/usr/lib/x86_64-linux-gnu/gstreamer-1.0',
      '/usr/lib/aarch64-linux-gnu/gstreamer-1.0',
      '/usr/local/lib/gstreamer-1.0',
    ];
    return dirs.any((d) => d.isNotEmpty && File('$d/libgstplayback.so').existsSync());
  }

  static Random _makeRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random(DateTime.now().microsecondsSinceEpoch);
    }
  }

  static const List<String> tracks = [
    'audio/music/track1.mp3',
    'audio/music/track2.mp3',
    'audio/music/track3.mp3',
    'audio/music/track4.mp3',
  ];

  final Map<Sfx, _SfxChannel> _channels = {};
  final Map<Sfx, DateTime> _lastPlayed = {};
  AudioPlayer? _music;
  StreamSubscription<void>? _musicDone;
  final Random _random;
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
    // On Android short effects go through SoundPool ("low latency" mode),
    // which is built for game sounds. The default MediaPlayer path costs far
    // more per play and heated phones up during long sessions.
    final lowLatency = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    await Future.wait(
      Sfx.values.map((s) async {
        final busy = s == Sfx.move || s == Sfx.soft || s == Sfx.rotate || s == Sfx.lock || s == Sfx.bump;
        try {
          _channels[s] = await _SfxChannel.create(
            'audio/sfx/${s.name}.wav',
            voices: busy ? 3 : 1,
            lowLatency: lowLatency,
            context: _sfxContext,
          );
        } catch (e) {
          debugPrint('sfx ${s.name} init failed: $e');
        }
      }),
    );
  }

  void play(Sfx sfx, {double volume = 1}) {
    if (!enabled || !sfxOn) return;
    final channel = _channels[sfx];
    if (channel == null) return;
    // Avoid machine-gunning the same sample (auto-repeat, soft drop).
    final now = DateTime.now();
    final last = _lastPlayed[sfx];
    if (last != null && now.difference(last).inMilliseconds < 35) return;
    _lastPlayed[sfx] = now;
    channel.play(volume);
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
      if (player.state == PlayerState.completed) {
        _playNext();
      } else {
        player.setVolume(_musicVolume * _duck).catchError((_) {});
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
    final track = _currentTrack = _queue.removeAt(0);
    onTrackStarted?.call(track);
    return track;
  }

  Future<void> _playNext() async {
    final player = _music;
    if (player == null) return;
    try {
      final source = AssetSource(tracks[nextTrackIndex()]);
      if (_musicOn) {
        await player.play(source, volume: _musicVolume * _duck);
      } else {
        // Music is off: load the track silently, so switching music on
        // later resumes it, instead of playing a blip and pausing.
        await player.setSource(source);
      }
    } catch (e) {
      debugPrint('Music track failed: $e');
    }
  }

  Future<void> skipTrack() => _playNext();

  void dispose() {
    _musicDone?.cancel();
    _music?.dispose();
    for (final channel in _channels.values) {
      channel.dispose();
    }
  }
}

/// A fixed set of pre-loaded players for one effect, used round-robin.
/// Unlike AudioPool it never creates players while the game runs.
class _SfxChannel {
  _SfxChannel(this._players);

  final List<AudioPlayer> _players;
  int _next = 0;

  static Future<_SfxChannel> create(String asset, {required int voices, required bool lowLatency, required AudioContext context}) async {
    final players = <AudioPlayer>[];
    for (var i = 0; i < voices; i++) {
      final player = AudioPlayer();
      await player.setAudioContext(context);
      if (lowLatency) await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(asset));
      players.add(player);
    }
    return _SfxChannel(players);
  }

  void play(double volume) {
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    () async {
      try {
        await player.stop();
        await player.setVolume(volume);
        await player.resume();
      } catch (e) {
        debugPrint('sfx play failed: $e');
      }
    }();
  }

  void dispose() {
    for (final p in _players) {
      p.dispose();
    }
  }
}
