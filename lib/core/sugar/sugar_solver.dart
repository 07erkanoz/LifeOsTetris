import 'sugar_game.dart';

/// A one-move-ahead player: tries every swap on a copy and keeps the one
/// that does the most for the goals. Used for the hint and to check that
/// every level can be won.
class SugarSolver {
  /// The best swap now, or null when there is none. A [shallow] player only
  /// sees the match it makes, not what falls after it (like most people).
  static (Cell, Cell)? best(SugarGame game, {double noise = 0, int salt = 0, bool shallow = false}) {
    (Cell, Cell)? pick;
    var top = double.negativeInfinity;
    var i = 0;
    for (final (a, b) in moves(game)) {
      final g = game.copy();
      if (!g.swap(a, b)) continue;
      if (shallow) {
        g.advance();
      } else {
        g.settle();
      }
      var v = value(game, g);
      if (noise > 0 && v.abs() < 1e8) v *= 1 + noise * ((((i++ + salt) * 2654435761) & 0xFFFF) / 0xFFFF - 0.5);
      if (v > top) {
        top = v;
        pick = (a, b);
      }
    }
    return pick;
  }

  static Iterable<(Cell, Cell)> moves(SugarGame game) sync* {
    for (var y = 0; y < SugarGame.size; y++) {
      for (var x = 0; x < SugarGame.size; x++) {
        if (x + 1 < SugarGame.size && game.canSwap((x, y), (x + 1, y))) yield ((x, y), (x + 1, y));
        if (y + 1 < SugarGame.size && game.canSwap((x, y), (x, y + 1))) yield ((x, y), (x, y + 1));
      }
    }
  }

  static ({int chains, int specials, double danger}) _board(SugarGame g) {
    var chains = 0, specials = 0;
    var danger = 0.0;
    for (final row in g.board) {
      for (final p in row) {
        if (p == null) continue;
        if (p.chained) chains++;
        if (p.special != Special.none) specials++;
        final t = p.timer;
        if (t != null) danger += 1 / (t * t);
      }
    }
    return (chains: chains, specials: specials, danger: danger);
  }

  static double value(SugarGame before, SugarGame after) {
    if (after.status == SugarStatus.won) return 1e9 + after.score.toDouble();
    if (after.status == SugarStatus.lost && after.moves > 0) return -1e9;
    var v = 0.0;
    for (var i = 0; i < after.goals.length; i++) {
      final b = before.goals[i], a = after.goals[i];
      final gained = (a.progress.clamp(0, a.target) - b.progress.clamp(0, b.target)).toDouble();
      v += switch (a.kind) {
        GoalKind.score => gained / 40,
        GoalKind.color => gained * 12,
        GoalKind.ice => gained * 30,
        GoalKind.box => gained * 40,
      };
    }
    // Box layers knocked count too, not only boxes gone.
    var layersBefore = 0, layersAfter = 0;
    for (var y = 0; y < SugarGame.size; y++) {
      for (var x = 0; x < SugarGame.size; x++) {
        layersBefore += before.box[y][x];
        layersAfter += after.box[y][x];
      }
    }
    final b = _board(before), a = _board(after);
    return v +
        (after.score - before.score) / 200 +
        (layersBefore - layersAfter) * 14 +
        (b.chains - a.chains) * 6 +
        (a.specials - b.specials) * 8 +
        (b.danger - a.danger) * 400 +
        (after.rushMeter - before.rushMeter).clamp(0, 1) * 10;
  }

  /// Moves left when the last [play] reached its goals.
  static int lastFinale = 0;

  /// Plays a level to the end; a little [noise] makes a less perfect player.
  static SugarGame play(SugarLevel level, int seed, {double noise = 0, bool shallow = false}) {
    final g = SugarGame(seed: seed)..start(level);
    var turn = 0;
    lastFinale = 0;
    while (!g.isOver) {
      final m = best(g, noise: noise, salt: seed * 31 + turn++, shallow: shallow);
      if (m == null) {
        g.shuffle();
      } else {
        g.swap(m.$1, m.$2);
      }
      final left = g.moves;
      g.settle();
      if (g.status == SugarStatus.won && !g.playsAllMoves && lastFinale == 0) lastFinale = left;
    }
    return g;
  }
}
