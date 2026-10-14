import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/audio_service.dart';
import '../core/tetris_game.dart';
import '../settings/settings.dart';
import 'fx/effects.dart';

/// Glue between the pure game, input, effects, audio and haptics.
///
/// [frame] ticks every frame for the painters; listeners of the controller
/// itself are only notified when HUD values change.
class GameController extends ChangeNotifier {
  GameController({required this.settings, required this.audio}) {
    settings.addListener(_applySettings);
    _applySettings();
  }

  final Settings settings;
  final AudioService audio;
  final TetrisGame game = TetrisGame();
  final EffectsEngine fx = EffectsEngine();
  final ValueNotifier<int> frame = ValueNotifier(0);

  GameMode mode = GameMode.classic;
  bool newRecord = false;

  /// Seconds of active play in the current game.
  double playTime = 0;

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
  }

  void start([GameMode? mode]) {
    if (mode != null) this.mode = mode;
    fx.reset();
    newRecord = false;
    playTime = 0;
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
  }

  void togglePause() {
    if (game.status == GameStatus.ready || game.status == GameStatus.over) return;
    game.togglePause();
    audio.duck = game.paused ? 0.35 : 1;
    audio.play(Sfx.click);
    _releaseAll();
    notifyListeners();
  }

  void toMenu() {
    game.abandon();
    fx.reset();
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
    }
    _process(game.drainEvents());
    fx.update(game.paused ? 0 : dt, game);
    frame.value++;
    _notifyHudIfChanged();
  }

  void _notifyHudIfChanged() {
    final snapshot = (
      game.score,
      game.level,
      game.lines,
      game.held,
      game.canHold,
      game.preview.first,
      game.status,
      game.paused,
      playTime.floor(),
      showGameOver,
      (fx.holdPulse * 10).round(),
      (fx.scorePulse * 10).round(),
      (fx.levelPulse * 10).round(),
    );
    if (snapshot != _hudSnapshot) {
      _hudSnapshot = snapshot;
      notifyListeners();
    }
  }

  void _process(List<GameEvent> events) {
    for (final e in events) {
      fx.handle(e, game);
      _sound(e);
      _haptic(e);
      if (e is GameOver) {
        newRecord = settings.submitScore(game.score);
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
      case GameOver():
        audio.play(Sfx.gameover);
      case PieceSpawned() || RowsCollapsed():
        break;
    }
  }

  void _haptic(GameEvent e) {
    if (!settings.vibration) return;
    switch (e) {
      case HardDropped():
        HapticFeedback.lightImpact();
      case LinesCleared(:final count, :final perfectClear):
        count >= 4 || perfectClear ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
      case LevelUp() || GameOver():
        HapticFeedback.heavyImpact();
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

  void rotateCw() => game.rotateClockwise();
  void rotateCcw() => game.rotateCounterClockwise();
  void hardDrop() => game.hardDrop();
  void hold() => game.hold();
  void softDrop(bool on) => game.setSoftDrop(on);

  // Touch gestures on the board.
  double _dragX = 0, _dragY = 0;
  bool _dragMoved = false;

  void dragStart() {
    _dragX = 0;
    _dragY = 0;
    _dragMoved = false;
  }

  void dragUpdate(Offset delta, double cell) {
    _dragX += delta.dx;
    _dragY += delta.dy;
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
    if (_dragY > cell * 1.2) {
      _dragMoved = true;
      game.setSoftDrop(true);
    } else if (_dragY < 0) {
      game.setSoftDrop(false);
    }
  }

  void dragEnd(Offset velocity) {
    game.setSoftDrop(false);
    if (velocity.dy > 1400 && velocity.dy.abs() > velocity.dx.abs() * 1.5) {
      game.hardDrop();
    } else if (velocity.dy < -900 && velocity.dy.abs() > velocity.dx.abs() * 1.5) {
      game.hold();
    } else if (!_dragMoved && _dragX.abs() < 6 && _dragY.abs() < 6) {
      game.rotateClockwise();
    }
  }

  @override
  void dispose() {
    settings.removeListener(_applySettings);
    frame.dispose();
    super.dispose();
  }
}
