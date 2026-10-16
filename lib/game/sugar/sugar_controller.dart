import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../audio/audio_service.dart';
import '../../audio/haptics.dart';
import '../../core/sugar/sugar_game.dart';
import '../../core/sugar/sugar_levels.dart';
import '../../l10n/strings.dart';
import '../../settings/settings.dart';
import 'sugar_fx.dart';

/// How a cube moves on screen: from one cell to another (a swap, a fall),
/// or out and back (a refused swap).
class SugarMotion {
  SugarMotion(this.from, this.to, this.start, this.duration, {this.fall = false, this.back = false});

  final Offset from, to;
  final double start, duration;
  final bool fall, back;

  bool done(double now) => now >= start + duration;

  /// Position at [now] and a squash for the landing (1 = none).
  (Offset, double) at(double now) {
    final t = ((now - start) / duration).clamp(0.0, 1.0);
    if (back) {
      final k = t < 0.5 ? Curves.easeOut.transform(t * 2) : 1 - Curves.easeIn.transform((t - 0.5) * 2);
      return (Offset.lerp(from, to, k * 0.45)!, 1);
    }
    if (fall) {
      // Falls faster and faster, then lands with a little squash.
      const land = 0.82;
      if (t < land) return (Offset.lerp(from, to, Curves.easeIn.transform(t / land))!, 1);
      final b = (t - land) / (1 - land);
      return (to, 1 - 0.14 * sin(b * pi));
    }
    return (Offset.lerp(from, to, Curves.easeInOutCubic.transform(t))!, 1);
  }
}

/// A cube that has left the board, drawn while it pops.
class SugarGhost {
  SugarGhost(this.piece, this.x, this.y, this.start);

  final SugarPiece piece;
  final double x, y;
  final double start;
  static const double life = 0.24;
}

/// Runs a Şeker Küpler level: plays each phase of a move as an animation,
/// input, boosters, sound, haptics, progress and the saved game.
class SugarController extends ChangeNotifier {
  SugarController({required this.settings, required this.audio, Haptics? haptics, required this.level, int? seed})
    : haptics = haptics ?? Haptics(),
      game = SugarGame(seed: seed ?? DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF) {
    settings.addListener(_applySettings);
    _applySettings();
  }

  final Settings settings;
  final AudioService audio;
  final Haptics haptics;
  SugarGame game;
  SugarLevel level;
  final SugarFx fx = SugarFx();
  AppStrings strings = AppStrings.tr;

  /// Repaints the board.
  final ValueNotifier<int> frame = ValueNotifier(0);

  bool paused = false;
  bool hammerArmed = false;
  bool newBest = false;
  Map<SugarBooster, int> chest = const {};
  double _overAge = -1;
  double _playTime = 0;
  int _lastCallout = 1;
  bool _warnedLastMoves = false;

  /// Board time, which stops while paused.
  double now = 0;
  final Map<int, SugarMotion> motions = {};
  final List<SugarGhost> ghosts = [];
  double _waitUntil = 0;

  /// Cells the player picked (tap one cube, then a neighbour).
  Cell? selected;
  (Cell, Cell)? hint;
  double _idle = 0;

  bool get started => game.status != SugarStatus.ready;
  bool get busy => game.status == SugarStatus.resolving || now < _waitUntil;
  bool get canPlay => game.status == SugarStatus.idle && !paused && !busy;

  /// The result panel waits a moment so the end can be seen.
  bool get showResult => game.isOver && _overAge > (game.status == SugarStatus.won ? 0.6 : 0.8);

  void _applySettings() {
    fx.particlesEnabled = settings.effects;
    fx.shakeEnabled = settings.shake;
    audio.sfxOn = settings.sfx;
    audio.musicOn = settings.music;
    audio.musicVolume = settings.musicVolume;
    haptics.strength = settings.vibrationStrength;
  }

  // ---------------------------------------------------------------- start --

  /// Starts [this.level] afresh, or continues its saved game when [resume].
  void start({bool resume = false}) {
    final saved = resume ? _saved() : null;
    game = SugarGame(seed: DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF);
    if (saved != null) {
      game.restore(level, saved);
    } else {
      game.start(level);
    }
    game.drainEvents();
    fx.reset();
    motions.clear();
    ghosts.clear();
    paused = hammerArmed = newBest = false;
    chest = const {};
    selected = hint = null;
    _overAge = -1;
    _playTime = 0;
    _idle = 0;
    _lastCallout = 1;
    _warnedLastMoves = game.moves <= 5;
    // Cubes drop in from above, row by row.
    for (var y = 0; y < SugarGame.size; y++) {
      for (var x = 0; x < SugarGame.size; x++) {
        final p = game.board[y][x];
        if (p != null) motions[p.id] = SugarMotion(Offset(x.toDouble(), y - 9.0), Offset(x.toDouble(), y.toDouble()), now + (7 - y) * 0.03 + x * 0.008, 0.42, fall: true);
      }
    }
    _waitUntil = now + 0.65;
    if (settings.lastPlay != 'sugar') settings.lastPlay = 'sugar';
    audio.startMusic();
    audio.duck = 1;
    audio.play(Sfx.start, volume: 0.8);
    notifyListeners();
  }

  Map<String, Object?>? _saved() {
    final raw = settings.savedSugar;
    if (raw == null) return null;
    try {
      final save = jsonDecode(raw) as Map<String, Object?>;
      return save['level'] == level.number ? save : null;
    } catch (_) {
      return null;
    }
  }

  /// Plays out whatever is moving and stores the level to continue later.
  void saveProgress() {
    if (!started || game.isOver) return;
    if (game.status == SugarStatus.resolving) game.settle();
    game.drainEvents();
    if (game.isOver) {
      _finish();
      return;
    }
    if (game.moves == level.moves && game.score == 0) return;
    settings.savedSugar = jsonEncode(game.toSave());
  }

  void togglePause() {
    if (!started || game.isOver) return;
    paused = !paused;
    hammerArmed = false;
    audio.duck = paused ? 0.35 : 1;
    audio.play(Sfx.click);
    if (paused) saveProgress();
    notifyListeners();
  }

  void pauseIfRunning() {
    if (started && !game.isOver && !paused) togglePause();
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
    final running = started && !paused;
    if (running) {
      now += dt;
      if (!game.isOver) _playTime += dt;
      while (game.status == SugarStatus.resolving && now >= _waitUntil) {
        final more = game.advance();
        _process(game.drainEvents());
        if (!more) break;
      }
      if (game.status == SugarStatus.idle && now >= _waitUntil) {
        _idle += dt;
        if (_idle > 6 && hint == null) hint = game.findMove();
      }
      motions.removeWhere((_, m) => m.done(now));
      ghosts.removeWhere((g) => now > g.start + SugarGhost.life);
    }
    if (_overAge >= 0) _overAge += dt;
    fx.update(running ? dt : 0);
    _sinceRepaint += dt;
    final idle = !started || paused || (game.isOver && _overAge > 3 && !fx.busy);
    final interval = settings.highRefreshRate ? 0.0 : 1 / 60;
    if (!idle && _sinceRepaint >= interval - 0.004) {
      _sinceRepaint = 0;
      frame.value++;
    }
    final hud = (game.status, paused, game.score, game.moves, showResult, hammerArmed, (fx.scorePulse * 4).round(), [for (final g in game.goals) g.progress]);
    if (hud.toString() != _hud) {
      _hud = hud.toString();
      notifyListeners();
    }
  }

  void _wait(double seconds) => _waitUntil = max(_waitUntil, now + seconds);

  // ---------------------------------------------------------------- input --

  void _touched() {
    _idle = 0;
    hint = null;
  }

  /// A tap on cell ([x], [y]).
  void tapCell(int x, int y) {
    _touched();
    if (!canPlay || x < 0 || y < 0 || x >= SugarGame.size || y >= SugarGame.size) return;
    if (hammerArmed) {
      if (settings.useSugarBooster(SugarBooster.hammer) && game.hammer(x, y)) {
        hammerArmed = false;
        audio.play(Sfx.poweruse);
        if (settings.vibration) haptics.heavy();
        _process(game.drainEvents());
      }
      notifyListeners();
      return;
    }
    final s = selected;
    if (s != null && (s.$1 - x).abs() + (s.$2 - y).abs() == 1) {
      selected = null;
      trySwap(s, (x, y));
      return;
    }
    selected = s == (x, y) ? null : (x, y);
    if (selected != null) audio.play(Sfx.move, volume: 0.35);
    notifyListeners();
  }

  /// A drag from cell [from] towards ([dx], [dy]).
  void dragCell(Cell from, int dx, int dy) {
    _touched();
    selected = null;
    trySwap(from, (from.$1 + dx, from.$2 + dy));
  }

  void trySwap(Cell a, Cell b) {
    if (!canPlay || hammerArmed) return;
    if (!game.canSwap(a, b)) {
      final pa = game.board[a.$2][a.$1];
      if (pa != null && pa.chained) {
        audio.play(Sfx.bump, volume: 0.5);
        fx.kick(0.1);
      }
      return;
    }
    game.swap(a, b);
    _process(game.drainEvents());
    notifyListeners();
  }

  // ------------------------------------------------------------- boosters --

  void toggleHammer() {
    if (!canPlay && !hammerArmed) return;
    if (!hammerArmed && settings.sugarBoosters(SugarBooster.hammer) <= 0) return;
    hammerArmed = !hammerArmed;
    selected = null;
    audio.play(Sfx.click);
    notifyListeners();
  }

  void useShuffle() {
    if (!canPlay || settings.sugarBoosters(SugarBooster.shuffle) <= 0) return;
    if (settings.useSugarBooster(SugarBooster.shuffle) && game.shuffle()) {
      audio.play(Sfx.poweruse);
      _process(game.drainEvents());
      notifyListeners();
    }
  }

  void useExtraMoves() {
    if (settings.sugarBoosters(SugarBooster.moves) <= 0) return;
    final lost = game.status == SugarStatus.lost;
    if (!lost && !canPlay) return;
    if (!settings.useSugarBooster(SugarBooster.moves)) return;
    if (lost) {
      game.extraMoves(SugarBooster.extraMoves);
      _overAge = -1;
      audio.duck = 1;
    } else {
      game.addMoves(SugarBooster.extraMoves);
    }
    _warnedLastMoves = game.moves <= 5;
    audio.play(Sfx.power);
    fx.callout(strings.sugarExtraMoves(SugarBooster.extraMoves), size: 1.0);
    notifyListeners();
  }

  // --------------------------------------------------------------- events --

  Offset _cell(Cell c) => Offset(c.$1.toDouble(), c.$2.toDouble());

  void _process(List<SugarEvent> events) {
    // Everything one phase did plays at once, after what is still running
    // (and after the swap when the phase began with one).
    var at = max(now, _waitUntil);
    for (final e in events) {
      switch (e) {
        case SugarSwapped():
          final pa = game.board[e.a.$2][e.a.$1], pb = game.board[e.b.$2][e.b.$1];
          if (pa != null) motions[pa.id] = SugarMotion(_cell(e.b), _cell(e.a), now, 0.17);
          if (pb != null) motions[pb.id] = SugarMotion(_cell(e.a), _cell(e.b), now, 0.17);
          audio.play(Sfx.rotate, volume: 0.5);
          _wait(0.17);
          at = now + 0.17;
        case SugarSwapRejected():
          final pa = game.board[e.a.$2][e.a.$1], pb = game.board[e.b.$2][e.b.$1];
          if (pa != null) motions[pa.id] = SugarMotion(_cell(e.a), _cell(e.b), now, 0.3, back: true);
          if (pb != null) motions[pb.id] = SugarMotion(_cell(e.b), _cell(e.a), now, 0.3, back: true);
          audio.play(Sfx.bump, volume: 0.5);
        case SugarCleared():
          final start = at;
          var sx = 0.0, sy = 0.0;
          for (final (x, y, p) in e.pieces) {
            ghosts.add(SugarGhost(p, x.toDouble(), y.toDouble(), start));
            fx.burst(x + 0.5, y + 0.5, SugarFx.colourOf(p), delay: start - now, count: e.pieces.length > 12 ? 3 : 6);
            sx += x + 0.5;
            sy += y + 0.5;
          }
          if (e.pieces.isNotEmpty) {
            fx.points(e.points, sx / e.pieces.length, sy / e.pieces.length, delay: start - now);
          }
          if (e.cascade >= 2 && e.cascade > _lastCallout) {
            _lastCallout = e.cascade;
            fx.callout(strings.sugarCallout(e.cascade), delay: start - now);
            audio.playCombo(min(8, e.cascade - 1));
          }
          final n = e.pieces.length;
          audio.play(Sfx.values.byName('clear${n >= 12 ? 4 : n >= 7 ? 3 : n >= 4 ? 2 : 1}'), volume: 0.8);
          if (settings.vibration) e.cascade >= 3 || n >= 8 ? haptics.medium() : haptics.light();
          _wait(start - now + SugarGhost.life);
        case SugarCreated():
          // A special made from a match pops in; one made by the finale or a
          // prism is off the board until it fires.
          final on = game.board[e.y][e.x];
          if (on == null || on.id != e.piece.id) {
            ghosts.add(SugarGhost(e.piece.copy(), e.x.toDouble(), e.y.toDouble(), at + 0.25));
          } else {
            motions[e.piece.id] = SugarMotion(_cell((e.x, e.y)), _cell((e.x, e.y)), now, 0.3, fall: true);
          }
          audio.play(Sfx.power, volume: 0.55);
        case SugarBlast():
          final start = at;
          final colour = switch (e.kind) {
            Special.prism => const Color(0xFFFFFFFF),
            _ => const Color(0xFFFFB3E6),
          };
          fx.beam(e, colour, delay: start - now);
          audio.play(switch (e.kind) {
            Special.lineH || Special.lineV => Sfx.drill,
            Special.bomb => Sfx.bomb,
            Special.prism => Sfx.power,
            Special.none => Sfx.hard,
          });
          if (settings.vibration && e.kind != Special.none) haptics.heavy();
          _wait(start - now + 0.3);
        case SugarIceCracked():
          fx.chips(e.x + 0.5, e.y + 0.5, const Color(0xFFE6F6FF));
          audio.play(Sfx.hard, volume: 0.4);
        case SugarUnchained():
          fx.chips(e.x + 0.5, e.y + 0.5, const Color(0xFFC9CED8), count: 9);
          audio.play(Sfx.lock, volume: 0.6);
        case SugarFell():
          var longest = 0.0;
          for (final (id, x, fromY, toY) in e.moves) {
            final d = (toY - fromY).toDouble();
            final dur = min(0.5, 0.14 + 0.05 * d);
            motions[id] = SugarMotion(Offset(x.toDouble(), fromY.toDouble()), Offset(x.toDouble(), toY.toDouble()), now, dur, fall: true);
            longest = max(longest, dur);
          }
          _wait(longest);
        case SugarShuffled():
          for (var y = 0; y < SugarGame.size; y++) {
            for (var x = 0; x < SugarGame.size; x++) {
              final p = game.board[y][x];
              if (p != null && !p.chained) motions[p.id] = SugarMotion(const Offset(3.5, 3.5), _cell((x, y)), now, 0.45);
            }
          }
          fx.callout(strings.sugarShuffled, size: 0.9);
          audio.play(Sfx.gravity);
          _wait(0.5);
        case SugarFinale():
          fx.callout(strings.sugarFinale, size: 1.15);
          audio.play(Sfx.perfect);
          if (settings.vibration) haptics.celebrate();
          _wait(1.0);
        case SugarWon():
          _finish();
        case SugarLost():
          _finish();
      }
    }
    if (!_warnedLastMoves && game.moves <= 5 && game.moves > 0 && !game.goalsDone) {
      _warnedLastMoves = true;
      fx.floaters.add(SugarFloater(strings.sugarLastMoves, SugarGame.size / 2, 3.8, 0.75, const [Color(0xFFFFE0F0), Color(0xFFFF4D8D)], duration: 1.4, delay: max(0, _waitUntil - now)));
      if (settings.vibration) haptics.light();
    }
  }

  void _finish() {
    if (_overAge >= 0) return;
    _overAge = 0;
    settings.savedSugar = null;
    final won = game.status == SugarStatus.won;
    final before = settings.sugarBest(level.number);
    if (won) {
      chest = settings.recordSugarLevel(level.number, stars: game.starCount, score: game.score, seconds: _playTime);
      newBest = before > 0 && game.score > before;
      audio.play(Sfx.levelup);
      if (settings.vibration) haptics.celebrate();
    } else {
      // A loss counts towards play time only; the level stays as it was.
      settings.recordSugarLevel(level.number, stars: 0, score: game.score, seconds: _playTime);
      audio.play(Sfx.gameover);
      audio.duck = 0.4;
      if (settings.vibration) haptics.heavy();
    }
    notifyListeners();
  }

  /// Another level (the next one from the result panel, or a retry).
  void play(SugarLevel next) {
    level = next;
    start();
  }

  @override
  void dispose() {
    settings.removeListener(_applySettings);
    frame.dispose();
    super.dispose();
  }
}
