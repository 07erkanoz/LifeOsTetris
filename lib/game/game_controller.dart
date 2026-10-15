import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Axis, Offset;

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/tetris_game.dart';
import '../settings/settings.dart';
import '../l10n/strings.dart';
import 'fx/effects.dart';
import 'motivation.dart';

/// Glue between the pure game, input, effects, audio and haptics.
///
/// [frame] ticks every frame for the painters; listeners of the controller
/// itself are only notified when HUD values change.
class GameController extends ChangeNotifier {
  GameController({required this.settings, required this.audio, Haptics? haptics}) : haptics = haptics ?? Haptics() {
    _vibrationWasOn = settings.vibration;
    settings.addListener(_applySettings);
    _applySettings();
  }

  final Settings settings;
  final AudioService audio;
  final Haptics haptics;
  bool _vibrationWasOn = true;
  DateTime _lastPreview = DateTime(2000);
  final TetrisGame game = TetrisGame();
  final EffectsEngine fx = EffectsEngine();
  final ValueNotifier<int> frame = ValueNotifier(0);

  /// Repaint signal for the animated background, at half the board's rate.
  final ValueNotifier<int> backgroundFrame = ValueNotifier(0);
  double _sinceRepaint = 0;

  /// Repaint cadence: 60 fps, also on 90/120 Hz screens, unless the player
  /// turned on the high refresh rate (then every frame the screen offers).
  static const double repaintInterval = 1 / 60;
  static const double repaintTolerance = 0.004;
  double get _interval => settings.highRefreshRate ? 0 : repaintInterval;
  int _paintCount = 0;
  final MotivationEngine motivation = MotivationEngine();
  int _lastMotivationId = 0;

  AppStrings _strings = AppStrings.tr;
  AppStrings get strings => _strings;
  set strings(AppStrings value) {
    _strings = value;
    fx.strings = value;
  }

  GameMode mode = GameMode.classic;
  bool newRecord = false;

  /// Seconds of active play in the current game.
  double playTime = 0;

  /// Play time at the last save; the game is saved every few seconds.
  double _lastSave = 0;
  static const double _saveEvery = 5;

  // Delayed auto shift for held left/right keys and buttons.
  static const double das = 0.16;
  static const double arr = 0.035;
  bool _leftHeld = false, _rightHeld = false;
  int _shiftDir = 0;
  double _dasTimer = 0, _arrTimer = 0;

  Duration? _lastTick;
  Object? _hudSnapshot;

  bool get showGameOver => game.status == GameStatus.over && fx.gameOverAge > 1.5;

  void _applySettings() {
    fx.particlesEnabled = settings.effects;
    fx.shakeEnabled = settings.shake;
    audio.sfxOn = settings.sfx;
    audio.musicOn = settings.music;
    audio.musicVolume = settings.musicVolume;
    // A short buzz confirms that vibration was switched on, and lets the
    // player feel a new strength while dragging its slider.
    final strengthChanged = haptics.strength != settings.vibrationStrength;
    haptics.strength = settings.vibrationStrength;
    final now = DateTime.now();
    if (settings.vibration && (!_vibrationWasOn || (strengthChanged && now.difference(_lastPreview).inMilliseconds > 180))) {
      _lastPreview = now;
      haptics.medium();
    }
    _vibrationWasOn = settings.vibration;
  }

  void start([GameMode? mode]) {
    if (mode != null) this.mode = mode;
    if (_demoSuper) this.mode = GameMode.superMode;
    fx.reset();
    motivation.reset(bestScore: settings.bestScore(this.mode));
    newRecord = false;
    playTime = 0;
    _lastSave = 0;
    settings.savedGame = null;
    _leftHeld = _rightHeld = false;
    _shiftDir = 0;
    game.start(mode: this.mode);
    if (_demo) _setUpDemo();
    audio.startMusic();
    audio.duck = 1;
    audio.play(Sfx.start, volume: 0.8);
    _process(game.drainEvents());
    notifyListeners();
  }

  /// Development builds made with `--dart-define=KUPLER_DEMO=true` start
  /// on a nearly full board so effects can be recorded on the first drop.
  static const bool _demo = bool.fromEnvironment('KUPLER_DEMO');
  static const bool _demoSuper = bool.fromEnvironment('KUPLER_DEMO_SUPER');

  void _setUpDemo() {
    game.debugSetBoard([
      '..T.......',
      '.TTT...OO.',
      'ZZ.SS..OO.',
      'JZZSSLLL..',
      'JJJSZZOOI.',
      'TTTIISSOI.',
      'LTJJJSSZZ.',
      'LLLJOOZZT.',
      'IIIIOOSTT.',
    ]);
    game.lines = 8;
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 2));
    if (game.powersEnabled) {
      game.debugGivePowers([PowerType.bomb, PowerType.bomb, PowerType.ghostLine, PowerType.drill, PowerType.slowMotion]);
    }
  }

  void togglePause() {
    if (game.status == GameStatus.ready || game.status == GameStatus.over) return;
    game.togglePause();
    audio.duck = game.paused ? 0.35 : 1;
    audio.play(Sfx.click);
    _releaseAll();
    notifyListeners();
  }

  /// Saves a game in progress so it can be continued later (also after the
  /// app is closed).
  void saveProgress() {
    if (_demo || _demoSuper) return;
    if (game.status != GameStatus.playing && game.status != GameStatus.clearing) return;
    settings.savedGame = jsonEncode({'game': game.toSave(), 'playTime': playTime});
    _lastSave = playTime;
  }

  String? _summaryOf;
  ({GameMode mode, int score, int level})? _summary;

  /// Mode, score and level of the saved game, for the continue button.
  ({GameMode mode, int score, int level})? get savedSummary {
    final raw = settings.savedGame;
    if (raw == null) return null;
    if (raw != _summaryOf) {
      _summaryOf = raw;
      try {
        final g = (jsonDecode(raw) as Map)['game'] as Map;
        _summary = (mode: GameMode.values.byName(g['mode'] as String), score: g['score'] as int, level: g['level'] as int);
      } catch (_) {
        _summary = null;
      }
    }
    return _summary;
  }

  /// Continues the saved game, paused so the player can get ready.
  bool resume() {
    final raw = settings.savedGame;
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, Object?>;
      game.restore((data['game']! as Map).cast<String, Object?>());
      playTime = (data['playTime'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      debugPrint('Saved game unreadable: $e');
      settings.savedGame = null;
      game.abandon();
      notifyListeners();
      return false;
    }
    mode = game.mode;
    fx.reset();
    motivation.reset(bestScore: settings.bestScore(mode));
    newRecord = false;
    _lastSave = playTime;
    _leftHeld = _rightHeld = false;
    _shiftDir = 0;
    game.paused = true;
    audio.startMusic();
    audio.duck = 0.35;
    _process(game.drainEvents());
    notifyListeners();
    return true;
  }

  void toMenu() {
    saveProgress();
    game.abandon();
    fx.reset();
    motivation.reset(bestScore: settings.bestScore(mode));
    audio.duck = 1;
    _releaseAll();
    notifyListeners();
  }

  void pauseIfRunning() {
    if (game.isRunning) togglePause();
  }

  // ------------------------------------------------------------ frame loop

  void tick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.05);

    if (game.isRunning) {
      playTime += dt;
      _updateAutoShift(dt);
      game.update(dt);
      if (playTime - _lastSave >= _saveEvery) saveProgress();
    }
    _process(game.drainEvents());
    if (game.isRunning) motivation.update(dt, game);
    final shown = motivation.current;
    if (shown != null && shown.id != _lastMotivationId) {
      _lastMotivationId = shown.id;
      audio.play(Sfx.combo4, volume: 0.35);
    }
    fx.update(game.paused ? 0 : dt, game);
    // Nothing moves behind the pause / menu / results screens, so stop
    // repainting the board and background there: it keeps those screens
    // smooth and saves battery.
    // Repaint at most ~60 times a second even on 90/120 Hz screens; the game
    // logic above still runs every tick. Halves GPU work (and heat) there.
    _sinceRepaint += dt;
    if (!_idle && _sinceRepaint >= _interval - repaintTolerance) {
      // Keep the remainder so the cadence stays even. A strict threshold
      // skipped frames whenever vsync came a hair early on 60 Hz screens,
      // which showed up as random hitches (seen on Windows).
      _sinceRepaint = (_sinceRepaint - _interval).clamp(0.0, repaintInterval);
      frame.value++;
      _paintCount++;
      if (_paintCount.isEven) backgroundFrame.value++;
    }
    _notifyHudIfChanged();
  }

  bool get _idle =>
      game.paused || game.status == GameStatus.ready || (game.status == GameStatus.over && fx.gameOverAge > 3 && fx.particles.isEmpty);

  void _notifyHudIfChanged() {
    final snapshot = (
      game.score,
      game.level,
      game.lines,
      game.held,
      game.canHold,
      game.preview.firstOrNull,
      game.status,
      game.paused,
      motivation.current?.id,
      game.energy,
      Object.hashAll(PowerType.values.map(game.powerCount)),
      Object.hashAll(PowerType.values.map(game.canUsePower)),
      game.ghostLine != null,
      game.slowMotion > 0,
      game.stars,
      game.chaosIn.ceil(),
      game.fog > 0,
      game.rush > 0,
      (fx.energyPulse * 4).round(),
      (fx.powerPulse * 4).round(),
      // Challenge clocks show tenths of a second.
      mode.isChallenge ? (game.time * 10).floor() : playTime.floor(),
      showGameOver,
      (fx.holdPulse * 4).round(),
      (fx.scorePulse * 4).round(),
      (fx.levelPulse * 4).round(),
    );
    if (snapshot != _hudSnapshot) {
      _hudSnapshot = snapshot;
      notifyListeners();
    }
  }

  void _process(List<GameEvent> events) {
    for (final e in events) {
      fx.handle(e, game);
      motivation.onEvent(e, game);
      _sound(e);
      _haptic(e);
      if (e is GameOver) {
        settings.savedGame = null;
        newRecord = settings.recordGame(
          mode: mode,
          score: game.score,
          lines: game.lines,
          seconds: mode.recordsTime ? game.time : playTime,
          won: e.won,
        );
        audio.duck = 0.4;
      }
    }
  }

  void _sound(GameEvent e) {
    switch (e) {
      case PieceMoved():
        audio.play(Sfx.move, volume: 0.6);
      case PieceMoveBlocked():
        audio.play(Sfx.bump, volume: 0.5);
      case PieceRotated():
        audio.play(Sfx.rotate, volume: 0.7);
      case SoftDropped():
        audio.play(Sfx.soft, volume: 0.4);
      case HardDropped():
        audio.play(Sfx.hard);
      case PieceLocked():
        audio.play(Sfx.lock, volume: 0.6);
      case PieceHeld():
        audio.play(Sfx.hold, volume: 0.7);
      case LinesCleared(:final count, :final tSpin, :final perfectClear, :final combo):
        if (perfectClear) {
          audio.play(Sfx.perfect);
        } else if (tSpin != TSpin.none) {
          audio.play(Sfx.tspin);
        } else {
          audio.play(Sfx.values.byName('clear$count'));
        }
        audio.playCombo(combo);
      case TSpinNoLines():
        audio.play(Sfx.tspin, volume: 0.7);
      case LevelUp():
        audio.play(Sfx.levelup);
      case GameOver(won: true):
        audio.play(Sfx.perfect);
      case GameOver():
        audio.play(Sfx.gameover);
      case PowerEarned():
        audio.play(Sfx.power, volume: 0.8);
      case PowerActivated(:final type):
        audio.play(switch (type) {
          PowerType.gravity => Sfx.gravity,
          PowerType.slowMotion => Sfx.slowmo,
          PowerType.ghostLine => Sfx.ghost,
          _ => Sfx.poweruse,
        });
      case BombExploded():
        audio.play(Sfx.bomb);
      case ColumnDrilled():
        audio.play(Sfx.drill);
      case GhostLineFilled():
        audio.play(Sfx.clear2, volume: 0.8);
      case StarsCollected():
        audio.play(Sfx.power);
      case GarbageRaised():
        audio.play(Sfx.hard, volume: 0.7);
      case ChaosStarted(:final type):
        audio.play(switch (type) {
          ChaosEvent.quake => Sfx.gravity,
          ChaosEvent.fog => Sfx.ghost,
          ChaosEvent.rush => Sfx.slowmo,
          ChaosEvent.rise => Sfx.hard,
          ChaosEvent.gift => Sfx.power,
        });
      case PieceSpawned() ||
          ChaosEnded() ||
          RowsCollapsed() ||
          EnergyGained() ||
          GravityApplied() ||
          SlowMotionStarted() ||
          SlowMotionEnded() ||
          GhostLineStarted():
        break;
    }
  }

  void _haptic(GameEvent e) {
    if (!settings.vibration) return;
    switch (e) {
      case HardDropped():
        haptics.light();
      case LinesCleared(:final count, :final perfectClear):
        count >= 4 || perfectClear ? haptics.celebrate() : haptics.medium();
      case LevelUp():
        haptics.celebrate();
      case GameOver(won: true):
        haptics.celebrate();
      case GameOver() || BombExploded():
        haptics.heavy();
      case ColumnDrilled() || GravityApplied() || GhostLineFilled() || GarbageRaised() || StarsCollected():
        haptics.medium();
      case ChaosStarted():
        haptics.heavy();
      case PowerEarned() || PowerActivated():
        haptics.light();
      default:
        break;
    }
  }

  // ------------------------------------------------------------ input

  void pressLeft() {
    _leftHeld = true;
    _beginShift(-1);
  }

  void pressRight() {
    _rightHeld = true;
    _beginShift(1);
  }

  void releaseLeft() {
    _leftHeld = false;
    _endShift();
  }

  void releaseRight() {
    _rightHeld = false;
    _endShift();
  }

  void _beginShift(int dir) {
    _shiftDir = dir;
    _dasTimer = 0;
    _arrTimer = 0;
    dir < 0 ? game.moveLeft() : game.moveRight();
  }

  void _endShift() {
    if (_leftHeld) {
      _beginShift(-1);
    } else if (_rightHeld) {
      _beginShift(1);
    } else {
      _shiftDir = 0;
    }
  }

  void _updateAutoShift(double dt) {
    if (_shiftDir == 0) return;
    _dasTimer += dt;
    if (_dasTimer < das) return;
    _arrTimer += dt;
    while (_arrTimer >= arr) {
      _arrTimer -= arr;
      final moved = _shiftDir < 0 ? game.moveLeft() : game.moveRight();
      if (!moved) {
        _arrTimer = 0;
        break;
      }
    }
  }

  void _releaseAll() {
    _leftHeld = _rightHeld = false;
    _shiftDir = 0;
    game.setSoftDrop(false);
  }

  /// Tapping the board (or rotating) stops the ghost line while it sinks.
  void rotateCw() => game.ghostLine != null ? game.triggerGhostLine() : game.rotateClockwise();

  void usePower(PowerType type) {
    if (!game.usePower(type)) audio.play(Sfx.bump, volume: 0.6);
  }

  void rotateCcw() => game.rotateCounterClockwise();
  void hardDrop() => game.hardDrop();
  void hold() => game.hold();
  void softDrop(bool on) => game.setSoftDrop(on);

  // Touch gestures on the board. A drag commits to one axis once it has
  // moved a little: a fast swipe down never nudges the piece sideways, and
  // a sideways drag never starts a soft drop.
  double _dragX = 0, _dragY = 0;
  double _totalX = 0, _totalY = 0;
  Axis? _dragAxis;
  bool _dragMoved = false;

  /// Movement (logical pixels) before a drag picks its axis.
  static const double axisSlop = 12;

  void dragStart() {
    _dragX = _dragY = _totalX = _totalY = 0;
    _dragAxis = null;
    _dragMoved = false;
  }

  void dragUpdate(Offset delta, double cell) {
    _totalX += delta.dx;
    _totalY += delta.dy;
    if (_dragAxis == null) {
      if (max(_totalX.abs(), _totalY.abs()) < axisSlop) return;
      _dragAxis = _totalY.abs() >= _totalX.abs() ? Axis.vertical : Axis.horizontal;
      if (_dragAxis == Axis.horizontal) {
        _dragX = _totalX;
      } else {
        _dragY = _totalY;
      }
    } else if (_dragAxis == Axis.horizontal) {
      _dragX += delta.dx;
    } else {
      _dragY += delta.dy;
    }
    if (_dragAxis == Axis.vertical) {
      if (_dragY > cell * 1.2) {
        _dragMoved = true;
        game.setSoftDrop(true);
      } else if (_dragY < 0) {
        game.setSoftDrop(false);
      }
      return;
    }
    final step = cell * 0.85;
    while (_dragX.abs() >= step) {
      _dragMoved = true;
      if (_dragX > 0) {
        game.moveRight();
        _dragX -= step;
      } else {
        game.moveLeft();
        _dragX += step;
      }
    }
  }

  void dragEnd(Offset velocity) {
    game.setSoftDrop(false);
    if (velocity.dy > 1400 && velocity.dy.abs() > velocity.dx.abs() * 1.5) {
      game.hardDrop();
    } else if (velocity.dy < -900 && velocity.dy.abs() > velocity.dx.abs() * 1.5) {
      game.hold();
    } else if (!_dragMoved && _totalX.abs() < 6 && _totalY.abs() < 6) {
      game.rotateClockwise();
    }
  }

  @override
  void dispose() {
    settings.removeListener(_applySettings);
    frame.dispose();
    backgroundFrame.dispose();
    super.dispose();
  }
}
