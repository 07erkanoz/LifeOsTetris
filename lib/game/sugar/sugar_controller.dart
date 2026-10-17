import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../audio/audio_service.dart';
import '../../audio/haptics.dart';
import '../../core/rewards.dart';
import '../../core/sugar/sugar_game.dart';
import '../../core/sugar/sugar_levels.dart';
import '../../l10n/strings.dart';
import '../../settings/settings.dart';
import 'sugar_art.dart';
import 'sugar_fx.dart';

/// How a sweet moves on screen: from one cell to another (a swap, a fall),
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

/// A sweet that has left the board, drawn while it pops.
class SugarGhost {
  SugarGhost(this.piece, this.x, this.y, this.start);

  final SugarPiece piece;
  final double x, y;
  final double start;
  static const double life = 0.24;
}

/// Lokum, the mascot: how it looks and what it says right now.
class SugarMascot {
  LokumPose pose = LokumPose.happy;
  String? line;
  double lineUntil = 0;
  int priority = 0;

  /// When the pose last changed (for the hop).
  double changed = -10;
}

/// Runs a Şeker Küpler level: plays each phase of a move as an animation,
/// input, boosters, sound, haptics, the mascot, progress and the saved game.
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
  final SugarMascot mascot = SugarMascot();
  AppStrings strings = AppStrings.tr;

  /// Repaints the board.
  final ValueNotifier<int> frame = ValueNotifier(0);

  bool paused = false;

  /// A booster waiting for the player to pick a sweet.
  SugarBooster? armed;
  bool get hammerArmed => armed == SugarBooster.hammer;
  bool get rainbowArmed => armed == SugarBooster.rainbow;
  bool newBest = false;
  bool lostToBomb = false;
  Map<SugarBooster, int> chest = const {};
  double _overAge = -1;
  double _playTime = 0;
  int _lastCallout = 1;
  bool _warnedLastMoves = false;
  bool _warnedBomb = false;
  int _lineCount = 0;

  /// The score as shown: it counts up to the real one.
  double shownScore = 0;

  /// Board time, which stops while paused.
  double now = 0;
  final Map<int, SugarMotion> motions = {};
  final List<SugarGhost> ghosts = [];
  double _waitUntil = 0;

  /// Cells the player picked (tap one sweet, then a neighbour).
  Cell? selected;
  (Cell, Cell)? hint;
  double _idle = 0;

  /// When Lokum dived into the board for a sugar rush (board time).
  double? diveStart;
  static const double diveLength = 1.1;

  /// Lokum is in the board, gobbling a row, not in his corner.
  bool get diving => diveStart != null && now - diveStart! < diveLength;

  /// The row Lokum gobbles on his dive.
  int diveRow = 4;

  /// Sweets popped this level, by colour (for the jar and the event).
  final Map<SugarColor, int> popped = {};

  /// Lokum's little pack for a level won.
  Gift? surprise;

  /// The postcard a chapter's last level gave, if it did.
  int? newCard;

  /// When Ekşi Limon last threw slices or lost his temper (board time).
  double limonThrew = -10;

  /// Ekşi Limon beaten for the first time: the story's end and its prize.
  bool finaleWon = false;

  /// Ekşi Limon is in this level.
  bool get hasLimon => level.limonEvery > 0;

  /// What Lokum wears.
  LokumOutfit get outfit => LokumOutfit.worn(settings.lokumOutfit, settings.totalSugarStars, settings.unlocks);

  bool get started => game.status != SugarStatus.ready;
  bool get busy => game.status == SugarStatus.resolving || now < _waitUntil;
  bool get canPlay => game.status == SugarStatus.idle && !paused && !busy;

  /// The result panel waits a moment so the end can be seen.
  bool get showResult => game.isOver && _overAge > (game.status == SugarStatus.won ? 0.9 : 1.0);

  void _applySettings() {
    fx.particlesEnabled = settings.effects;
    fx.shakeEnabled = settings.shake;
    audio.sfxOn = settings.sfx;
    audio.musicOn = settings.music;
    audio.musicVolume = settings.musicVolume;
    haptics.strength = settings.vibrationStrength;
  }

  // --------------------------------------------------------------- mascot --

  /// Lokum strikes [pose] and, unless a more important line is showing,
  /// says the line for [key].
  void say(String? key, LokumPose pose, {int priority = 1, double hold = 2.2}) {
    if (mascot.line != null && now < mascot.lineUntil && priority < mascot.priority) return;
    if (pose != mascot.pose || key != null) mascot.changed = now;
    mascot.pose = pose;
    if (key != null) {
      mascot.line = strings.lokum(key, _lineCount++);
      mascot.lineUntil = now + hold;
      mascot.priority = priority;
    }
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
    paused = newBest = lostToBomb = false;
    armed = null;
    chest = const {};
    selected = hint = null;
    diveStart = null;
    popped.clear();
    surprise = null;
    newCard = null;
    limonThrew = -10;
    finaleWon = false;
    _overAge = -1;
    _playTime = 0;
    _idle = 0;
    _lastCallout = 1;
    _warnedLastMoves = game.moves <= 5;
    _warnedBomb = false;
    shownScore = game.score.toDouble();
    mascot
      ..line = null
      ..priority = 0;
    // Sweets drop in from above, row by row.
    for (var y = 0; y < SugarGame.size; y++) {
      for (var x = 0; x < SugarGame.size; x++) {
        final p = game.board[y][x];
        if (p != null) motions[p.id] = SugarMotion(Offset(x.toDouble(), y - 9.0), Offset(x.toDouble(), y.toDouble()), now + (7 - y) * 0.03 + x * 0.008, 0.42, fall: true);
      }
    }
    _waitUntil = now + 0.65;
    say('start', LokumPose.happy);
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
    armed = null;
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
        if (_idle > 6 && hint == null) {
          hint = game.findMove();
          // Lokum points the way.
          if (hint != null) say('hint', LokumPose.point, hold: 2.6);
        }
        if (_idle > 16 && mascot.pose != LokumPose.sleepy && mascot.line == null) say('sleepy', LokumPose.sleepy, priority: 0, hold: 3);
      }
      motions.removeWhere((_, m) => m.done(now));
      ghosts.removeWhere((g) => now > g.start + SugarGhost.life);
      if (mascot.line != null && now > mascot.lineUntil) {
        mascot.line = null;
        mascot.priority = 0;
        if (mascot.pose != LokumPose.happy && mascot.pose != LokumPose.sleepy && !game.isOver) {
          mascot
            ..pose = LokumPose.happy
            ..changed = now;
        }
      }
    }
    // The score counts up, quickly for small gains, a roll for big ones.
    final target = game.score.toDouble();
    if (shownScore != target) {
      shownScore = min(target, shownScore + max(dt * 600, (target - shownScore) * min(1, dt * 6)));
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
    final hud = (game.status, paused, shownScore.round(), game.moves, showResult, armed, (fx.scorePulse * 4).round(), (game.rushMeter * 40).round(),
        [for (final g in game.goals) g.progress], mascot.line, mascot.pose);
    final key = hud.toString();
    if (key != _hud) {
      _hud = key;
      notifyListeners();
    }
  }

  void _wait(double seconds) => _waitUntil = max(_waitUntil, now + seconds);

  // ---------------------------------------------------------------- input --

  void _touched() {
    _idle = 0;
    hint = null;
    if (mascot.pose == LokumPose.sleepy || mascot.pose == LokumPose.point) {
      mascot
        ..pose = LokumPose.happy
        ..line = null
        ..priority = 0
        ..changed = now;
    }
  }

  /// A tap on cell ([x], [y]).
  void tapCell(int x, int y) {
    _touched();
    if (!canPlay || x < 0 || y < 0 || x >= SugarGame.size || y >= SugarGame.size) return;
    final booster = armed;
    if (booster != null) {
      final ok = switch (booster) {
        SugarBooster.hammer => game.canHammer(x, y),
        SugarBooster.rainbow => game.board[y][x] != null && !game.board[y][x]!.chained && !game.board[y][x]!.isPrism && !game.board[y][x]!.fruit,
        SugarBooster.moves || SugarBooster.shuffle => false,
      };
      if (ok && settings.useSugarBooster(booster)) {
        booster == SugarBooster.hammer ? game.hammer(x, y) : game.rainbow(x, y);
        armed = null;
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
    if (!canPlay || armed != null) return;
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

  /// Arms (or disarms) the hammer or the rainbow; the next tap uses it.
  void toggleBooster(SugarBooster b) {
    if (armed == b) {
      armed = null;
    } else {
      if (!canPlay || settings.sugarBoosters(b) <= 0) return;
      armed = b;
      selected = null;
    }
    audio.play(Sfx.click);
    notifyListeners();
  }

  /// Shuffles the board with a shuffle booster.
  void useShuffle() {
    if (!canPlay || settings.sugarBoosters(SugarBooster.shuffle) <= 0) return;
    if (!game.shuffle()) return;
    settings.useSugarBooster(SugarBooster.shuffle);
    _touched();
    audio.play(Sfx.poweruse);
    _process(game.drainEvents());
    notifyListeners();
  }

  void useExtraMoves() {
    if (settings.sugarBoosters(SugarBooster.moves) <= 0) return;
    final lost = game.status == SugarStatus.lost;
    if (!lost && !canPlay) return;
    if (!settings.useSugarBooster(SugarBooster.moves)) return;
    if (lost) {
      game.extraMoves(SugarBooster.extraMoves);
      _overAge = -1;
      lostToBomb = false;
      audio.duck = 1;
    } else {
      game.addMoves(SugarBooster.extraMoves);
    }
    _warnedLastMoves = game.moves <= 5;
    audio.play(Sfx.power);
    fx.callout(strings.sugarExtraMoves(SugarBooster.extraMoves), size: 1.0);
    say('start', LokumPose.cheer, priority: 2);
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
            popped[p.color] = (popped[p.color] ?? 0) + 1;
            ghosts.add(SugarGhost(p, x.toDouble(), y.toDouble(), start));
            fx.burst(x + 0.5, y + 0.5, SugarFx.colourOf(p), delay: start - now, count: e.pieces.length > 12 ? 3 : 6);
            sx += x + 0.5;
            sy += y + 0.5;
          }
          if (e.pieces.isNotEmpty) {
            final cx = sx / e.pieces.length, cy = sy / e.pieces.length;
            fx.points(e.points, cx, cy, delay: start - now);
            if (e.cascade >= 2) fx.multiplier(e.cascade, min(7.2, cx + 0.9), max(0.8, cy - 0.7), delay: start - now);
          }
          if (e.cascade >= 2 && e.cascade > _lastCallout) {
            _lastCallout = e.cascade;
            fx.callout(strings.sugarCallout(e.cascade), delay: start - now);
            audio.playCombo(min(8, e.cascade - 1));
            if (e.cascade >= 3) say(e.cascade >= 4 ? 'great' : 'nice', e.cascade >= 4 ? LokumPose.cheer : LokumPose.wink);
          }
          final n = e.pieces.length;
          if (n > 0) audio.play(Sfx.values.byName('clear${n >= 12 ? 4 : n >= 7 ? 3 : n >= 4 ? 2 : 1}'), volume: 0.8);
          if (settings.vibration && n > 0) e.cascade >= 3 || n >= 8 ? haptics.medium() : haptics.light();
          _wait(start - now + SugarGhost.life);
        case SugarCreated():
          // A special made from a match pops in; one made by the finale, a
          // rush or a rainbow combo is off the board until it fires.
          final on = game.board[e.y][e.x];
          if (on == null || on.id != e.piece.id) {
            ghosts.add(SugarGhost(e.piece.copy(), e.x.toDouble(), e.y.toDouble(), at + 0.25));
          } else {
            motions[e.piece.id] = SugarMotion(_cell((e.x, e.y)), _cell((e.x, e.y)), now, 0.3, fall: true);
          }
          audio.play(Sfx.power, volume: 0.55);
        case SugarBlast():
          final start = at;
          fx.beam(e, e.kind == Special.prism ? const Color(0xFFFFFFFF) : const Color(0xFFFFB3E6), delay: start - now);
          audio.play(switch (e.kind) {
            Special.lineH || Special.lineV => Sfx.drill,
            Special.bomb => Sfx.bomb,
            Special.prism => Sfx.power,
            Special.none => Sfx.hard,
          });
          if (e.combo) {
            fx.callout(strings.sugarCombo, size: 1.0, delay: start - now);
            fx.flash = 0.7;
            fx.confetti(count: 40, delay: start - now);
            say('great', LokumPose.wow, priority: 2);
          }
          if (settings.vibration && e.kind != Special.none) haptics.heavy();
          _wait(start - now + 0.3);
        case SugarIceCracked():
          fx.chips(e.x + 0.5, e.y + 0.5, const Color(0xFFE6F6FF));
          audio.play(Sfx.hard, volume: 0.4);
        case SugarUnchained():
          fx.chips(e.x + 0.5, e.y + 0.5, const Color(0xFFC9CED8), count: 9);
          audio.play(Sfx.lock, volume: 0.6);
        case SugarBoxHit():
          fx.chips(e.x + 0.5, e.y + 0.5, e.left > 0 ? const Color(0xFFFF9AD8) : const Color(0xFFFFC21A), count: e.left > 0 ? 7 : 14);
          audio.play(e.left > 0 ? Sfx.hard : Sfx.bomb, volume: e.left > 0 ? 0.5 : 0.6);
          if (e.left == 0) fx.kick(0.15);
        case SugarFell():
          var longest = 0.0;
          for (final (id, fx0, fy, tx, ty) in e.moves) {
            final d = (Offset(tx.toDouble(), ty.toDouble()) - Offset(fx0.toDouble(), fy.toDouble())).distance;
            final dur = min(0.5, 0.14 + 0.05 * d);
            motions[id] = SugarMotion(Offset(fx0.toDouble(), fy.toDouble()), Offset(tx.toDouble(), ty.toDouble()), now, dur, fall: true);
            longest = max(longest, dur);
          }
          _wait(longest);
        case SugarLucky():
          fx.floaters.add(SugarFloater(strings.sugarLucky, e.x + 0.5, e.y + 0.2, 0.5, const [Color(0xFFFFFFFF), Color(0xFF9FFFC8)], duration: 1.2, delay: 0.3));
          say('lucky', LokumPose.wink);
          audio.play(Sfx.power, volume: 0.6);
        case SugarBombTick():
          final low = e.bombs.map((b) => b.$3).fold(99, min);
          if (low <= 3) {
            audio.play(Sfx.bump, volume: 0.6);
            if (!_warnedBomb || low <= 1) say('bomb', LokumPose.scared, priority: 3);
            _warnedBomb = true;
          }
        case SugarBombExploded():
          fx.beam(SugarBlast(Special.bomb, e.x, e.y, [for (var dy = -1; dy <= 1; dy++) for (var dx = -1; dx <= 1; dx++) (e.x + dx, e.y + dy)]), const Color(0xFFFF6A3A));
          fx.kick(1);
          fx.flash = 1;
          audio.play(Sfx.bomb);
          lostToBomb = true;
        case SugarRush():
          fx.callout(strings.sugarRush, size: 1.2);
          fx.flash = 1;
          fx.confetti();
          audio.play(Sfx.perfect);
          if (settings.vibration) haptics.celebrate();
          say('rush', LokumPose.chomp, priority: 2);
          // Lokum dives in and gobbles a row on the way.
          diveStart = now;
          diveRow = 2 + Random(game.score).nextInt(SugarGame.size - 4);
          _wait(0.9);
        case SugarStarReached():
          fx.starPulse[e.star - 1] = 1;
          fx.floaters.add(SugarFloater(strings.sugarStar(e.star), SugarGame.size - 1.4, 0.6, 0.55, const [Color(0xFFFFF6B0), Color(0xFFFFB000)], duration: 1.3));
          audio.play(Sfx.levelup, volume: 0.6);
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
          fx.confetti(count: 30);
          audio.play(Sfx.perfect);
          if (settings.vibration) haptics.celebrate();
          say('finale', LokumPose.cheer, priority: 3);
          _wait(1.0);
        case SugarFinaleShot():
          fx.floaters.add(SugarFloater('+${e.points}', e.x + 0.5, e.y + 0.5, 0.55 + min(0.35, e.index * 0.03), const [Color(0xFFFFFFFF), Color(0xFFFFE066)], duration: 1.0, delay: 0.25));
          audio.playCombo(min(8, e.index + 1));
          _wait(0.32);
        case SugarChocoCleared():
          fx.chips(e.x + 0.5, e.y + 0.5, const Color(0xFF8A4A2A), count: 10);
          audio.play(Sfx.hard, volume: 0.5);
        case SugarChocoSpread():
          ghosts.add(SugarGhost(e.piece, e.x.toDouble(), e.y.toDouble(), at));
          fx.chips(e.x + 0.5, e.y + 0.5, const Color(0xFF6A3418), count: 8);
          audio.play(Sfx.bump, volume: 0.45);
          say('choco', LokumPose.wow);
          _wait(at - now + 0.3);
        case SugarFruitDone():
          ghosts.add(SugarGhost(e.piece, e.x.toDouble(), e.y.toDouble(), at));
          fx.burst(e.x + 0.5, e.y + 0.5, const Color(0xFFFF4A6A), delay: at - now, count: 12);
          fx.floaters.add(SugarFloater('+1000', e.x + 0.5, e.y + 0.1, 0.5, const [Color(0xFFFFFFFF), Color(0xFFFF9AAE)], duration: 1.1, delay: max(0, at - now)));
          audio.play(Sfx.levelup, volume: 0.55);
          say('fruit', LokumPose.cheer);
          _wait(at - now + 0.3);
        case SugarCakeHit():
          fx.chips(e.x + 1, e.y + 1, e.left > 0 ? const Color(0xFFFFB0D0) : const Color(0xFFFFE066), count: e.left > 0 ? 10 : 22);
          audio.play(e.left > 0 ? Sfx.hard : Sfx.bomb, volume: 0.55);
          if (e.left == 0) {
            fx.kick(0.2);
            fx.confetti(count: 24, delay: at - now);
            say('cake', LokumPose.cheer, priority: 2);
          }
        case SugarDoorOpened():
          fx.chips(e.x + 0.5, e.y + 0.5, sugarColors[e.color]!, count: 14);
          audio.play(Sfx.lock, volume: 0.7);
          say('door', LokumPose.wink);
        case SugarBelted():
          var longest = 0.0;
          for (final (id, fromX, toX, y) in e.moves) {
            final dir = level.belts[y] ?? 1;
            // Round the end: in from the far edge.
            final from = (toX - fromX).sign == dir ? fromX.toDouble() : (toX - dir).toDouble();
            motions[id] = SugarMotion(Offset(from, y.toDouble()), Offset(toX.toDouble(), y.toDouble()), at, 0.32);
            longest = 0.32;
          }
          audio.play(Sfx.gravity, volume: 0.45);
          _wait(at - now + longest);
        case SugarSliceThrown():
          for (var i = 0; i < e.cells.length; i++) {
            final (x, y) = e.cells[i];
            ghosts.add(SugarGhost(e.pieces[i], x.toDouble(), y.toDouble(), at + 0.25 + i * 0.08));
            fx.chips(x + 0.5, y + 0.5, const Color(0xFFFFE04A), count: 8);
          }
          limonThrew = now;
          audio.play(Sfx.bump, volume: 0.7);
          say('limon', LokumPose.scared, priority: 2);
          _wait(0.7);
        case SugarSliceCleared():
          fx.chips(e.x + 0.5, e.y + 0.5, const Color(0xFFFFF06A), count: 9);
          audio.play(Sfx.hard, volume: 0.4);
        case SugarLimonPhase():
          fx.callout(strings.sugarLimonAngry, size: 1.1);
          fx.kick(0.8);
          fx.flash = 0.6;
          limonThrew = now;
          audio.play(Sfx.bomb);
          if (settings.vibration) haptics.heavy();
          say('limonAngry', LokumPose.wow, priority: 3);
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
      say('last', LokumPose.wow, priority: 2);
      if (settings.vibration) haptics.light();
    }
  }

  void _finish() {
    if (_overAge >= 0) return;
    _overAge = 0;
    settings.savedSugar = null;
    settings.addSugarCandies(popped);
    final won = game.status == SugarStatus.won;
    final before = settings.sugarBest(level.number);
    if (won) {
      chest = settings.recordSugarLevel(level.number, stars: game.starCount, score: game.score, seconds: _playTime);
      newBest = before > 0 && game.score > before;
      settings.applyGift(surprise = Rewards.surprise(level.number * 7919 + game.score));
      if (level.number % SugarLevels.perChapter == 0) {
        final card = Rewards.chapterCard(SugarLevels.chapterOf(level.number));
        if (card != null && !settings.hasCard(card)) {
          settings.applyGift(Gift(card: card));
          newCard = card;
        }
      }
      if (hasLimon && !settings.unlocked(Unlock.sceneCamlica)) {
        settings.applyGift(Rewards.finale);
        finaleWon = true;
      }
      fx.confetti(count: 80);
      audio.play(Sfx.levelup);
      say('win', LokumPose.dance, priority: 5, hold: 99);
      if (settings.vibration) haptics.celebrate();
    } else {
      // A loss counts towards play time only; the level stays as it was.
      settings.recordSugarLevel(level.number, stars: 0, score: game.score, seconds: _playTime);
      audio.play(Sfx.gameover);
      audio.duck = 0.4;
      say('lose', LokumPose.sad, priority: 5, hold: 99);
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
