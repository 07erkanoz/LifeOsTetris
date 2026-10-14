import 'dart:math';

/// Power-ups of the "Süper Küpler" mode.
enum PowerType {
  /// Next piece becomes a bomb that blasts a 3×3 area.
  bomb(20),

  /// Next piece becomes a single block for filling holes.
  single(22),

  /// Next piece becomes a drill that eats its whole column.
  drill(18),

  /// Every floating block falls down and fills the gaps below it.
  gravity(16),

  /// Pieces fall much slower for a while.
  slowMotion(14),

  /// A phantom line sinks through the stack; when triggered it fills the
  /// gaps of the row it is on so that row clears.
  ghostLine(10);

  const PowerType(this.weight);

  /// Relative chance of being earned. The ghost line is the strongest power,
  /// so it is the rarest.
  final int weight;

  static PowerType pick(Random random) {
    final total = values.fold<int>(0, (sum, p) => sum + p.weight);
    var roll = random.nextInt(total);
    for (final p in values) {
      if (roll < p.weight) return p;
      roll -= p.weight;
    }
    return values.last;
  }
}
