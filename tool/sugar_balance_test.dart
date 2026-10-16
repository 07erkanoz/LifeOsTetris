// Prints how the solver does on every level: flutter test tool/sugar_balance_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';

void main() {
  test('balance', () {
    final only = const String.fromEnvironment('LEVELS');
    for (final level in SugarLevels.all) {
      if (only.isNotEmpty && !only.split(',').contains('${level.number}')) continue;
      final line = StringBuffer('L${level.number}${level.boss ? 'B' : level.hard ? 'H' : ''} m${level.moves}');
      final meds = <int>[];
      for (final noise in [0.0, 1.5]) {
        var wins = 0;
        final scores = <int>[], left = <int>[];
        for (var seed = 1; seed <= 16; seed++) {
          final g = SugarSolver.play(level, seed * 7919 + level.number, noise: noise);
          if (g.status == SugarStatus.won) {
            wins++;
            scores.add(g.score);
            left.add(SugarSolver.lastFinale);
          }
        }
        scores.sort();
        left.sort();
        final med = scores.isEmpty ? 0 : scores[scores.length ~/ 2];
        meds.add(med);
        line.write(' | n$noise win $wins/16 left ${left.isEmpty ? '-' : left[left.length ~/ 2]} (${left.isEmpty ? '' : '${left.first}..${left.last}'}) med $med');
      }
      line.write(' stars ${level.stars}');
      int r(num v) => (v / 500).round() * 500;
      final goalScore = level.goals.map((f) => f()).where((g) => g.kind == GoalKind.score).fold(0, (n, g) => g.target);
      final s1 = goalScore > 0 ? goalScore : r(meds[1] * 0.5);
      final s2 = max(s1 + 500, r(meds[1] * 0.95));
      final s3 = max(s2 + 1000, r(meds[0] * 1.15));
      line.write(' SUGGEST ${level.number}: [$s1, $s2, $s3]');
      // ignore: avoid_print
      print(line);
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
