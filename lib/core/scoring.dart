import 'dart:math';

import 'game_events.dart';

const int maxLevel = 20;

/// Seconds per row of gravity at [level] (Tetris guideline curve).
double gravityInterval(int level) {
  final l = level.clamp(1, maxLevel);
  return pow(0.8 - (l - 1) * 0.007, l - 1).toDouble();
}

int _baseClearPoints(int lines, TSpin tSpin) => switch (tSpin) {
      TSpin.none => const [0, 100, 300, 500, 800][lines],
      TSpin.mini => const [100, 200, 400, 400, 400][lines],
      TSpin.full => const [400, 800, 1200, 1600, 1600][lines],
    };

/// A "difficult" clear keeps the back-to-back chain alive.
bool isDifficultClear(int lines, TSpin tSpin) => lines == 4 || (lines > 0 && tSpin != TSpin.none);

/// Points for locking a piece that cleared [lines] (possibly zero).
int clearScore({
  required int lines,
  required TSpin tSpin,
  required int level,
  required bool backToBack,
  required int combo,
  required bool perfectClear,
}) {
  var base = _baseClearPoints(lines, tSpin).toDouble();
  if (backToBack) base *= 1.5;
  var points = base.round() * level;
  if (lines > 0 && combo > 0) points += 50 * combo * level;
  if (perfectClear) points += const [0, 800, 1200, 1800, 2000][lines] * level;
  return points;
}
