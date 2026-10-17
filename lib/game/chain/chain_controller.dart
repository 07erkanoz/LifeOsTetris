import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../audio/audio_service.dart';
import '../../audio/haptics.dart';
import '../../core/chain/chain_game.dart';
import '../../core/chain/chain_missions.dart';
import '../../core/chain/chain_puzzles.dart';
import '../../core/chain/chain_sim.dart';
import '../../core/chain/chain_versus.dart';
import '../../core/rewards.dart';
import '../../l10n/strings.dart';
import '../../settings/settings.dart';
import '../lokum_mood.dart';
import '../sugar/sugar_art.dart';
import 'chain_fx.dart';
import 'chain_sprites.dart';

/// Runs a Zincir Küpler game: time, input, sound, haptics and records. A
/// [puzzle] number plays that puzzle; a [mission] plays it on the ferry
/// line (a puzzle mission has both).
class ChainController extends ChangeNotifier {
  ChainController({required this.settings, required this.audio, Haptics? haptics, required ChainMode mode, ChainGame? game, this.puzzle, this.mission})
    : haptics = haptics ?? Haptics(),
      game = game ?? ChainGame(),
      mode = puzzle != null ? ChainMode.puzzle : (mission != null && mode != ChainMode.versus ? ChainMode.mission : mode),
      difficulty = mission?.difficulty ?? settings.chainDifficulty {
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
  final int? puzzle;
  final ChainMission? mission;

  /// Stars the last game won (0 when it was not won).
  int stars = 0;

  /// A prize the last game gave: a pier reached, a pack solved.
  Gift? prize;

  /// A puzzle's hint: the swap to make next, while it shows.
  (int, int)? hint;
  bool _hinted = false;

  /// Endless and time attack keep their game to continue later.
  bool get _keeps => mode == ChainMode.endless || mode == ChainMode.timeAttack;

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

  /// How the cubes look: the chosen look if it is unlocked.
  ChainCubeStyle get cubes {
    final style = ChainCubeStyle.parse(settings.chainCubes);
    return switch (style) {
      ChainCubeStyle.lokum when !settings.unlocked(Unlock.cubesLokum) => ChainCubeStyle.vivid,
      ChainCubeStyle.cini when !settings.unlocked(Unlock.cubesCini) => ChainCubeStyle.vivid,
      _ => style,
    };
  }

  /// Seconds a stop-the-clock booster holds the stack.
  static const double freezeSeconds = 5;

  /// Holds the rising stack with a stop-the-clock booster.
  void useFreeze() {
    if (!playing || paused || !settings.unlocked(Unlock.freeze)) return;
    if (!settings.useChainFreeze()) return;
    game.stopTime = max(game.stopTime, freezeSeconds);
    audio.play(Sfx.slowmo);
    lokum.say(_strings, null, LokumPose.wow, clock);
    notifyListeners();
  }

  /// What Lokum wears.
  LokumOutfit get outfit => LokumOutfit.worn(settings.lokumOutfit, settings.totalSugarStars, settings.unlocks);

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
    if (!started || game.isOver || !_keeps) return;
    settings.savedChain = jsonEncode(game.toSave());
  }

  void start() {
    if (_keeps && settings.savedChain != null) settings.savedChain = null;
    final m = mission;
    final p = puzzle;
    if (p != null) {
      final data = ChainPuzzles.of(p);
      game.startPuzzle(data.rows, data.moves);
    } else if (m != null) {
      game.startMission(m);
    } else {
      game.start(mode, difficulty: difficulty);
    }
    fx.reset();
    paused = false;
    newRecord = false;
    stars = 0;
    prize = null;
    hint = null;
    _hinted = false;
    _overAge = -1;
    _grab = null;
    lokum.reset();
    _warnedDanger = false;
    if (_keeps) {
      final last = mode == ChainMode.timeAttack ? 'chainTime' : 'chainEndless';
      if (settings.lastPlay != last) settings.lastPlay = last;
    }
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

  // -------------------------------------------------------------- puzzles --

  /// Shows the next swap of a solution (a hinted puzzle earns two stars).
  void showHint() {
    if (!playing || paused || !game.isPuzzle || !game.settled) return;
    final solution = ChainSim.of(game).solve(game.movesLeft);
    if (solution == null || solution.isEmpty) {
      // Off the solution: back to the start shows the way again.
      lokum.say(_strings, 'puzzleStuck', LokumPose.wow, clock, priority: 2);
      notifyListeners();
      return;
    }
    hint = solution.first;
    _hinted = true;
    game.setCursor(hint!.$1, hint!.$2);
    audio.play(Sfx.power, volume: 0.6);
    lokum.say(_strings, 'hint', LokumPose.point, clock, priority: 2);
    notifyListeners();
  }

  void undo() {
    if (!playing || paused) return;
    if (game.undo()) {
      hint = null;
      audio.play(Sfx.click);
      notifyListeners();
    }
  }

  void restartPuzzle() {
    if (!game.isPuzzle) return;
    if (game.isOver) {
      start();
      return;
    }
    game.restartPuzzle();
    hint = null;
    audio.play(Sfx.click);
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
    final events = <ChainEvent>[];
    if (running) {
      events.addAll(advance(dt));
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
    events.addAll(game.drainEvents());
    _process(events);
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

  /// Runs the game for [dt] seconds and returns what happened.
  @protected
  List<ChainEvent> advance(double dt) {
    game.update(dt);
    return game.drainEvents();
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
    // One step at a time: the next waits until this swap has finished. A
    // puzzle takes one swap per drag.
    if (_grabTarget != x && b.state == BlockState.idle) {
      final dir = _grabTarget > x ? 1 : -1;
      final left = dir > 0 ? x : x - 1;
      if (game.swap(left, y)) {
        x += dir;
        game.setCursor(left, y);
        hint = null;
        if (game.isPuzzle) {
          _grab = null;
          return;
        }
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
    if (game.swapAtCursor()) hint = null;
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
          audio.duck = 0.4;
          if (_keeps) {
            audio.play(e.timeUp ? Sfx.perfect : Sfx.gameover);
            if (settings.vibration) haptics.heavy();
            newRecord = settings.recordChainGame(mode: mode, difficulty: difficulty, score: game.score, seconds: game.time);
            lokum.say(_strings, newRecord ? 'record' : 'over', newRecord ? LokumPose.dance : LokumPose.sad, clock, priority: 5, hold: 99);
            if (settings.savedChain != null) settings.savedChain = null;
          } else {
            finishGoal(e.won);
          }
        case ChainMissionProgress():
          audio.play(Sfx.levelup, volume: 0.6);
          fx.callout(_strings.missionProgress(e.progress, e.target));
        default:
          break;
      }
    }
  }

  /// A puzzle or a mission ended: stars, records and prizes.
  @protected
  void finishGoal(bool won) {
    audio.play(won ? Sfx.perfect : Sfx.gameover);
    if (settings.vibration) won ? haptics.celebrate() : haptics.heavy();
    if (won) {
      fx.confetti();
      final m = mission;
      final p = puzzle;
      if (m != null) {
        stars = ChainMissions.stars(m, left: game.missionLeft, chain: game.maxChain);
        if (p != null && _hinted) stars = 2;
        final first = settings.recordMission(m.number, stars);
        prize = first ? pierPrizeFor(settings, m.number) : null;
      } else if (p != null) {
        stars = _hinted ? 2 : 3;
        final had = settings.puzzleStars(p) > 0;
        settings.recordPuzzle(p, stars);
        final pack = ChainPuzzles.packOf(p);
        final all = [for (var i = 1; i <= ChainPuzzles.perPack; i++) pack * ChainPuzzles.perPack + i].every((n) => settings.puzzleStars(n) > 0);
        if (!had && all) prize = Rewards.puzzlePackPrize(pack);
      }
      final g = prize;
      if (g != null) settings.applyGift(g);
    }
    lokum.say(_strings, won ? 'win' : 'lose', won ? LokumPose.dance : LokumPose.sad, clock, priority: 5, hold: 99);
  }

  @override
  void dispose() {
    settings.removeListener(_applySettings);
    frame.dispose();
    super.dispose();
  }
}

/// The prize for mission [number] when it completes its pier for the first
/// time; null otherwise.
Gift? pierPrizeFor(Settings settings, int number) {
  final pier = ChainMissions.pierOf(number);
  for (var i = 1; i <= ChainMissions.perPier; i++) {
    if (settings.missionStars(pier * ChainMissions.perPier + i) == 0) return null;
  }
  return Rewards.pierPrize(pier, last: pier == ChainMissions.piers.length - 1);
}

/// A match against Ekşi Limon: the player's board is [game], the
/// computer's [cpu]; garbage goes across, best of three sets.
class ChainVersusController extends ChainController {
  factory ChainVersusController({required Settings settings, required AudioService audio, Haptics? haptics, required ChainRival rival, ChainMission? mission, Random? random}) =>
      ChainVersusController._(ChainVersus(rival, random: random), settings: settings, audio: audio, haptics: haptics, mission: mission);

  ChainVersusController._(this.versus, {required super.settings, required super.audio, super.haptics, super.mission})
    : super(mode: ChainMode.versus, game: versus.player);

  final ChainVersus versus;

  /// Bursts and shards on the computer's board.
  final ChainFx cpuFx = ChainFx();

  ChainGame get cpu => versus.cpu;
  ChainRival get rival => versus.rival;

  /// The set is over: who took it shows until the next starts.
  bool get setOver => versus.setOver;
  bool get matchOver => versus.matchOver;

  /// Garbage cells waiting to fall on the player's board.
  int get incoming => game.pendingGarbage.fold(0, (n, w) => n + w);

  @override
  void start() {
    versus
      ..playerSets = 0
      ..cpuSets = 0;
    nextSet();
  }

  /// Starts the next set (or the first).
  void nextSet() {
    versus.startSet();
    game.drainEvents();
    cpu.drainEvents();
    fx.reset();
    cpuFx.reset();
    paused = false;
    stars = 0;
    prize = null;
    _overAge = -1;
    _grab = null;
    lokum.reset();
    _warnedDanger = false;
    audio.startMusic();
    audio.duck = 1;
    audio.play(Sfx.start, volume: 0.8);
    notifyListeners();
  }

  @override
  List<ChainEvent> advance(double dt) {
    final mine = versus.update(dt);
    for (final e in versus.cpuEvents) {
      cpuFx.handle(e, cpu);
    }
    for (final e in mine) {
      if (e is ChainAttack) {
        audio.play(Sfx.power, volume: 0.6);
        lokum.say(_strings, 'attack', LokumPose.cheer, clock, priority: 2);
      }
    }
    return mine;
  }

  @override
  void tick(Duration elapsed) {
    final last = _lastTick;
    super.tick(elapsed);
    if (last != null) cpuFx.update(((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.05));
  }

  @override
  void finishGoal(bool won) {
    audio.play(won ? Sfx.perfect : Sfx.gameover);
    if (settings.vibration) won ? haptics.celebrate() : haptics.heavy();
    if (won) fx.confetti();
    if (versus.matchOver) {
      final mineWon = versus.playerWonMatch;
      if (mineWon) {
        stars = versus.cpuSets == 0 ? 3 : 2;
        final first = settings.recordRivalWin(rival.index);
        final m = mission;
        Gift? pier;
        if (m != null) {
          final firstMission = settings.recordMission(m.number, stars);
          if (firstMission) pier = pierPrizeFor(settings, m.number);
        }
        prize = first ? Rewards.rivalPrize(rival.index) : pier;
        final g = prize;
        if (g != null) settings.applyGift(g);
      }
      lokum.say(_strings, mineWon ? 'win' : 'lose', mineWon ? LokumPose.dance : LokumPose.sad, clock, priority: 5, hold: 99);
    } else {
      lokum.say(_strings, won ? 'nice' : 'lose', won ? LokumPose.cheer : LokumPose.sad, clock, priority: 4, hold: 99);
    }
  }
}
