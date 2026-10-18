// Tunes every Şeker Küpler level with the solver as a casual player:
//   flutter test tool/sugar_tune_test.dart [--dart-define=LEVELS=1,2,3]
// For each level it finds the fewest moves that the casual player still wins
// often enough (the target falls through the chapters; hard and boss levels
// lower), or for score-only levels the score target that it reaches often
// enough; then sets the stars from the winning scores. Prints one line per
// level: "TUNE n moves=m target=t stars=[a, b, c] win=w".
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';

const _seeds = 12;
const _noise = 1.0;

double targetWin(SugarLevel l) {
  final ch = (l.number - 1) ~/ 10, i = (l.number - 1) % 10;
  var w = 0.97 - 0.05 * ch - 0.01 * i;
  if (l.hard) w -= 0.12;
  if (l.boss) w -= 0.18;
  return max(0.55, w);
}

SugarLevel withMoves(SugarLevel l, int moves, {List<SugarGoal Function()>? goals}) => SugarLevel(
  number: l.number,
  moves: moves,
  colors: l.colors,
  layout: l.layout,
  goals: goals ?? l.goals,
  stars: const [1 << 29, 1 << 29, 1 << 29],
  boss: l.boss,
  hard: l.hard,
  hint: l.hint,
  bombTimer: l.bombTimer,
  bombEvery: l.bombEvery,
  luck: l.luck,
  gifts: l.gifts,
  rush: l.rush,
  calm: l.calm,
  belts: l.belts,
  fruitsAtOnce: l.fruitsAtOnce,
  limonEvery: l.limonEvery,
  limonThrow: l.limonThrow,
  gullEvery: l.gullEvery,
  gullCount: l.gullCount,
  pepperEvery: l.pepperEvery,
  pepperThrow: l.pepperThrow,
);

({double win, List<int> scores}) evaluate(SugarLevel l) {
  var wins = 0;
  final scores = <int>[];
  for (var s = 1; s <= _seeds; s++) {
    final g = SugarSolver.play(l, s * 7919 + l.number * 31, noise: _noise, shallow: true);
    if (g.status == SugarStatus.won) {
      wins++;
      scores.add(g.score);
    }
  }
  scores.sort();
  return (win: wins / _seeds, scores: scores);
}

/// Fewer moves than this feels stingy, however easy the level.
int minMoves(SugarLevel l) => l.layout.join().replaceAll('.', '').isEmpty ? 12 : 14;

int pct(List<int> sorted, double p) => sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * p).round()];
int round500(num v) => max(500, (v / 500).round() * 500);

void main() {
  test('tune', () {
    final only = const String.fromEnvironment('LEVELS');
    for (final level in SugarLevels.all) {
      if (only.isNotEmpty && !only.split(',').contains('${level.number}')) continue;
      final want = targetWin(level);
      final goals = level.goals.map((f) => f()).toList();
      if (goals.every((g) => g.kind == GoalKind.score)) {
        // Score-only: every game plays all its moves; pick the score the
        // casual player reaches in [want] of its games.
        final r = evaluate(withMoves(level, level.moves, goals: [() => SugarGoal.score(1)]));
        final target = round500(pct(r.scores, 1 - want));
        final above = r.scores.where((s) => s >= target).toList();
        final s2 = max(target + 500, round500(pct(above, 0.3)));
        final s3 = max(s2 + 500, round500(pct(above, 0.62)));
        // ignore: avoid_print
        print('TUNE ${level.number} moves=${level.moves} target=$target stars=[$target, $s2, $s3] win=${want.toStringAsFixed(2)}');
        continue;
      }
      var moves = level.moves;
      var r = evaluate(withMoves(level, moves));
      if (r.win < want) {
        for (var k = 0; k < 8 && r.win < want; k++) {
          moves += 2;
          r = evaluate(withMoves(level, moves));
        }
      } else {
        for (var k = 0; k < 6 && moves - 2 >= minMoves(level); k++) {
          final tighter = evaluate(withMoves(level, moves - 2));
          if (tighter.win < want) break;
          moves -= 2;
          r = tighter;
        }
      }
      // Still too easy at the fewest moves: ask for more sweets of a colour.
      var scale = 1.0;
      List<SugarGoal Function()> scaled(double k) => [
        for (final g in goals)
          g.kind == GoalKind.color ? () => SugarGoal.color(g.color!, (g.target * k).round()) : () => g.copy()..progress = 0,
      ];
      if (goals.any((g) => g.kind == GoalKind.color)) {
        for (var k = 0; k < 5 && r.win >= min(1.0, want + 0.08); k++) {
          final harder = evaluate(withMoves(level, moves, goals: scaled(scale * 1.2)));
          if (harder.win < want) break;
          scale *= 1.2;
          r = harder;
        }
      }
      final colorTargets = [for (final g in goals) if (g.kind == GoalKind.color) (g.target * scale).round()];
      final s = r.scores;
      final s1 = round500(pct(s, 0.05) * 0.8);
      final s2 = max(s1 + 500, round500(pct(s, 0.3)));
      final s3 = max(s2 + 500, round500(pct(s, 0.62)));
      // ignore: avoid_print
      print('TUNE ${level.number} moves=$moves target=0 colors=${colorTargets.join('/')} stars=[$s1, $s2, $s3] win=${r.win.toStringAsFixed(2)} want=${want.toStringAsFixed(2)}');
    }
  }, timeout: const Timeout(Duration(minutes: 600)));
}
