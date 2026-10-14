/// Power-ups of the "Süper Küpler" mode. They are earned in a shuffled
/// order: all six come round before any of them repeats.
enum PowerType {
  /// Next piece becomes a bomb that blasts a 3×3 area.
  bomb,

  /// Next piece becomes a single block for filling holes.
  single,

  /// Next piece becomes a drill that eats its whole column.
  drill,

  /// Every floating block falls down and fills the gaps below it.
  gravity,

  /// Pieces fall much slower for a while.
  slowMotion,

  /// A phantom line sinks through the stack; when triggered it fills the
  /// gaps of the row it is on so that row clears.
  ghostLine,
}
