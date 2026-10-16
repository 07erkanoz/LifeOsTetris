import 'sugar_game.dart';

/// A one-move-ahead player: tries every swap on a copy and keeps the one
/// that does the most for the goals. Used for the hint and to check that
/// every level can be won.
class SugarSolver {
  /// The best swap now, or null when there is none.
  static (Cell, Cell)? best(SugarGame game, {double noise = 0, int salt = 0}) {
    (Cell, Cell)? pick;
    var top = double.negativeInfinity;
    var i = 0;
    for (final (a, b) in moves(game)) {
      final g = game.copy();
      if (!g.swap(a, b)) continue;
      g.settle();
      var v = value(game, g);
      if (noise > 0) v *= 1 + noise * ((((i++ + salt) * 2654435761) & 0xFFFF) / 0xFFFF - 0.5);
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

  static double value(SugarGame before, SugarGame after) {
    if (after.status == SugarStatus.won) return 1e9 + after.score.toDouble();
    var v = 0.0;
    for (var i = 0; i < after.goals.length; i++) {
      final b = before.goals[i], a = after.goals[i];
      final gained = (a.progress.clamp(0, a.target) - b.progress.clamp(0, b.target)).toDouble();
      v += switch (a.kind) {
        GoalKind.score => gained / 40,
        GoalKind.color => gained * 12,
        GoalKind.ice => gained * 30,
      };
    }
    var chains = 0, specials = 0;
    for (final row in after.board) {
      for (final p in row) {
        if (p == null) continue;
        if (p.chained) chains++;
        if (p.special != Special.none) specials++;
      }
    }
    var chainsBefore = 0, specialsBefore = 0;
    for (final row in before.board) {
      for (final p in row) {
        if (p == null) continue;
        if (p.chained) chainsBefore++;
        if (p.special != Special.none) specialsBefore++;
      }
    }
    return v + (after.score - before.score) / 200 + (chainsBefore - chains) * 6 + (specials - specialsBefore) * 8;
  }

  /// Moves left when the last [play] reached its goals.
  static int lastFinale = 0;

  /// Plays a level to the end; a little [noise] makes a less perfect player.
  static SugarGame play(SugarLevel level, int seed, {double noise = 0}) {
    final g = SugarGame(seed: seed)..start(level);
    var turn = 0;
    lastFinale = 0;
    while (!g.isOver) {
      if (g.goalsDone) lastFinale = g.moves;
      final m = best(g, noise: noise, salt: seed * 31 + turn++);
      if (m == null) {
        g.shuffle();
      } else {
        g.swap(m.$1, m.$2);
      }
      final before = g.moves;
      g.settle();
      if (g.goalsDone && g.moves == 0 && lastFinale == 0) lastFinale = before;
    }
    return g;
  }
}
