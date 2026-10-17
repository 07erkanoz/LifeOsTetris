import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../audio/audio_service.dart';
import '../../audio/haptics.dart';
import '../../core/chain/chain_game.dart';
import '../../l10n/strings.dart';
import '../../settings/settings.dart';
import '../lokum_mood.dart';
import '../sugar/sugar_art.dart';
import 'chain_fx.dart';

/// Runs a Zincir Küpler game: time, input, sound, haptics and records.
class ChainController extends ChangeNotifier {
  ChainController({required this.settings, required this.audio, Haptics? haptics, required this.mode, ChainGame? game})
    : haptics = haptics ?? Haptics(),
      game = game ?? ChainGame(),
      difficulty = settings.chainDifficulty {
    settings.addListener(_applySettings);
    _applySettings();
  }

  final Settings settings;
  final AudioService audio;
  final Haptics haptics;
  final ChainGame game;
  final ChainFx fx = ChainFx();
  ChainMode mode;
  ChainDifficulty difficulty;

  /// Repaints the board.
  final ValueNotifier<int> frame = ValueNotifier(0);

  bool paused = false;
  bool newRecord = false;
  double _overAge = -1;

  AppStrings _strings = AppStrings.tr;
  set strings(AppStrings value) => fx.strings = _strings = value;

  /// Lokum cheering by the Yükselt button, on the game's own clock.
  final LokumMood lokum = LokumMood();
  double clock = 0;
  bool _warnedDanger = false;

  /// What Lokum wears.
  LokumOutfit get outfit => LokumOutfit.worn(settings.lokumOutfit, settings.totalSugarStars);

  bool get started => game.status != ChainStatus.ready;
  bool get playing => game.status == ChainStatus.playing;

  /// The game-over panel waits a moment so the end can be seen.
  bool get showResult => game.isOver && _overAge > 0.9;

  int get best => settings.chainBest(mode, difficulty);

  void _applySettings() {
    fx.particlesEnabled = settings.effects;
    fx.shakeEnabled = settings.shake;
    audio.sfxOn = settings.sfx;
    audio.musicOn = settings.music;
    audio.musicVolume = settings.musicVolume;
    haptics.strength = settings.vibrationStrength;
  }

  void setDifficulty(ChainDifficulty d) {
    difficulty = d;
    settings.chainDifficulty = d;
    audio.play(Sfx.click);
    notifyListeners();
  }

  /// Continues the saved game, paused, so the player picks it up when
  /// ready. False when there is none (or it cannot be read).
  bool resumeSaved() {
    final raw = settings.savedChain;
    if (raw == null) return false;
    try {
      game.restore(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      settings.savedChain = null;
      return false;
    }
    mode = game.mode;
    difficulty = game.difficulty;
    fx.reset();
    paused = true;
    newRecord = false;
    _overAge = -1;
    _grab = null;
    audio.duck = 0.35;
    _process(game.drainEvents());
    notifyListeners();
    return true;
  }

  /// Keeps a game in progress to continue later.
  void saveProgress() {
    if (!started || game.isOver) return;
    settings.savedChain = jsonEncode(game.toSave());
  }

  void start() {
    if (settings.savedChain != null) settings.savedChain = null;
    game.start(mode, difficulty: difficulty);
    fx.reset();
    paused = false;
    newRecord = false;
    _overAge = -1;
    _grab = null;
    lokum.reset();
    _warnedDanger = false;
    final last = mode == ChainMode.timeAttack ? 'chainTime' : 'chainEndless';
    if (settings.lastPlay != last) settings.lastPlay = last;
    audio.startMusic();
    audio.duck = 1;
    audio.play(Sfx.start, volume: 0.8);
    _process(game.drainEvents());
    notifyListeners();
  }

  /// Back to the start panel (to pick another difficulty).
  void backToStart() {
    game.status = ChainStatus.ready;
    fx.reset();
    audio.duck = 1;
    notifyListeners();
  }

  void togglePause() {
    if (!playing) return;
    paused = !paused;
    game.raising = false;
    _grab = null;
    audio.duck = paused ? 0.35 : 1;
    audio.play(Sfx.click);
    if (paused) saveProgress();
    notifyListeners();
  }

  void pauseIfRunning() {
    if (playing && !paused) togglePause();
  }

  // ----------------------------------------------------------------- time --

  Duration? _lastTick;
  double _sinceRepaint = 0;
  Object? _hud;

  void tick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    final running = playing && !paused;
    if (running) {
      game.update(dt);
      _followGrab();
    }
    if (_overAge >= 0) _overAge += dt;
    if (running || game.isOver) clock += dt;
    lokum.settle(clock, keep: game.isOver);
    if (running) {
      if (game.grace > 0 && !_warnedDanger) {
        _warnedDanger = true;
        lokum.say(_strings, 'danger', LokumPose.scared, clock, priority: 3);
      } else if (game.grace <= 0) {
        _warnedDanger = false;
      }
    }
    fx.danger = game.grace > 0 ? 1 : 0;
    fx.update(running || game.isOver ? dt : 0);
    _process(game.drainEvents());
    _sinceRepaint += dt;
    final idle = !started || paused || (game.isOver && _overAge > 3 && !fx.busy);
    final interval = settings.highRefreshRate ? 0.0 : 1 / 60;
    if (!idle && _sinceRepaint >= interval - 0.004) {
      _sinceRepaint = 0;
      frame.value++;
    }
    final hud = (
      game.status,
      paused,
      game.score,
      game.chainCount,
      game.level,
      game.remaining.ceil(),
      showResult,
      (fx.scorePulse * 4).round(),
      (fx.chainPulse * 4).round(),
    );
    if (hud != _hud) {
      _hud = hud;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- input --

  /// The cube being dragged: column and row on the board, and the column
  /// the finger is over (it keeps moving there as swaps finish).
  (int, int)? _grab;
  int _grabTarget = 0;

  /// Board cell under [local], a point relative to the well.
  (int, int) cellAt(Offset local, double cell) => ((local.dx / cell).floor(), (local.dy / cell + game.rise).floor());

  void touchDown(Offset local, double cell) {
    if (!playing || paused) return;
    final (x, y) = cellAt(local, cell);
    if (x < 0 || x >= ChainGame.width || y < 0 || y >= ChainGame.height) return;
    game.setCursor(min(x, ChainGame.width - 2), y);
    final b = game.board[y][x];
    _grab = b != null && !b.isGarbage ? (x, y) : null;
    _grabTarget = x;
    notifyListeners();
  }

  /// Dragging sideways swaps the held cube along, one cell at a time.
  void touchMove(Offset local, double cell) {
    if (_grab == null || !playing || paused) return;
    _grabTarget = (local.dx / cell).floor().clamp(0, ChainGame.width - 1);
    _followGrab();
  }

  void _followGrab() {
    final grab = _grab;
    if (grab == null) return;
    var (x, y) = grab;
    final b = game.board[y][x];
    if (b == null || b.isGarbage) {
      _grab = null;
      return;
    }
    // One step at a time: the next waits until this swap has finished.
    if (_grabTarget != x && b.state == BlockState.idle) {
      final dir = _grabTarget > x ? 1 : -1;
      final left = dir > 0 ? x : x - 1;
      if (game.swap(left, y)) {
        x += dir;
        game.setCursor(left, y);
      }
    }
    _grab = (x, y);
  }

  void touchUp() => _grab = null;

  void moveCursor(int dx, int dy) {
    if (!playing || paused) return;
    game.moveCursor(dx, dy);
    audio.play(Sfx.move, volume: 0.4);
    notifyListeners();
  }

  void swapAtCursor() {
    if (!playing || paused) return;
    game.swapAtCursor();
  }

  set raising(bool on) {
    if (on && (!playing || paused)) return;
    game.raising = on;
  }

  // --------------------------------------------------------------- events --

  void _process(List<ChainEvent> events) {
    for (final e in events) {
      fx.handle(e, game);
      switch (e) {
        case ChainSwapped():
          audio.play(Sfx.rotate, volume: 0.5);
        case ChainMatched():
          final size = e.combo >= 7 ? 4 : (e.combo >= 5 ? 3 : (e.combo == 4 ? 2 : 1));
          audio.play(Sfx.values.byName('clear$size'));
          if (e.chain >= 2) audio.playCombo(e.chain - 1);
          if (e.chain >= 2) lokum.say(_strings, 'chain', e.chain >= 3 ? LokumPose.wow : LokumPose.cheer, clock, priority: 2);
          if (settings.vibration) e.chain >= 3 || e.combo >= 6 ? haptics.celebrate() : haptics.medium();
        case ChainPopped():
          if (e.index % 2 == 0) audio.play(Sfx.soft, volume: 0.35);
        case ChainRowRaised():
          if (e.manual) audio.play(Sfx.move, volume: 0.25);
          final grab = _grab;
          if (grab != null) _grab = grab.$2 > 0 ? (grab.$1, grab.$2 - 1) : null;
        case ChainGarbageDropped():
          audio.play(Sfx.hard);
          if (settings.vibration) haptics.heavy();
        case ChainGarbageBroken():
          audio.play(Sfx.bomb, volume: 0.7);
          if (settings.vibration) haptics.medium();
        case ChainLevelUp():
          audio.play(Sfx.levelup, volume: 0.7);
          lokum.say(_strings, 'level', LokumPose.wink, clock);
        case ChainGameOver():
          _overAge = 0;
          game.raising = false;
          audio.play(e.timeUp ? Sfx.perfect : Sfx.gameover);
          audio.duck = 0.4;
          if (settings.vibration) haptics.heavy();
          newRecord = settings.recordChainGame(mode: mode, difficulty: difficulty, score: game.score, seconds: game.time);
          lokum.say(_strings, newRecord ? 'record' : 'over', newRecord ? LokumPose.dance : LokumPose.sad, clock, priority: 5, hold: 99);
          if (settings.savedChain != null) settings.savedChain = null;
        default:
          break;
      }
    }
  }

  @override
  void dispose() {
    settings.removeListener(_applySettings);
    frame.dispose();
    super.dispose();
  }
}
