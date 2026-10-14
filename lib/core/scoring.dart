import 'dart:math';

import 'game_events.dart';

const int maxLevel = 99;

enum GameMode {
  /// Speed rises gently until [speedCapLevel], then stays put.
  classic,

  /// Constant, calm speed for endless play.
  relaxed,

  /// "Süper Küpler": classic speed plus the energy bar and power-ups.
  superMode;

  bool get hasPowers => this == GameMode.superMode;
  bool get speedsUp => this != GameMode.relaxed;
}

/// Level at which classic mode reaches its top speed.
const int speedCapLevel = 10;

/// Seconds per row of gravity. Unlike the official curve (which becomes
/// near-instant after level 10), classic mode eases from 1 s/row at level 1
/// to 0.25 s/row (4 rows per second) at level 10 and never goes faster.
double gravityInterval(int level, [GameMode mode = GameMode.classic]) {
  if (mode == GameMode.relaxed) return 0.8;
  final l = level.clamp(1, speedCapLevel);
  return pow(0.25, (l - 1) / (speedCapLevel - 1)).toDouble();
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
