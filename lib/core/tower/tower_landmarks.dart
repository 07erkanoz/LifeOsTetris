/// İstanbul'u İnşa Et: every floor of every Kule Küpler run counts towards
/// the landmark in hand. Each landmark takes [Landmark.floors] floors and
/// rises in five parts, one every fifth of the way.
enum Landmark {
  galata(500),
  maidens(1000),
  rumeli(1200),
  beyazit(1400),
  dolmabahce(1600),
  haydarpasa(1800),
  selimiye(2000),
  camlica(2500);

  const Landmark(this.floors);

  /// Floors it takes, on top of the landmarks before it.
  final int floors;

  static const int parts = 5;

  /// Floors all the landmarks before this one take.
  int get start => Landmark.values.take(index).fold(0, (sum, l) => sum + l.floors);

  static int get total => Landmark.values.fold(0, (sum, l) => sum + l.floors);
}

/// Where İstanbul'u İnşa Et stands after [total] floors.
class BuildProgress {
  BuildProgress(this.total);

  final int total;

  /// The landmark being built, or null once all are done.
  Landmark? get current {
    for (final l in Landmark.values) {
      if (total < l.start + l.floors) return l;
    }
    return null;
  }

  /// Landmarks finished.
  int get done => current?.index ?? Landmark.values.length;

  bool isDone(Landmark l) => total >= l.start + l.floors;

  /// Floors laid into [l] so far, 0 to [Landmark.floors].
  int into(Landmark l) => (total - l.start).clamp(0, l.floors);

  /// 0 to 1 for [l].
  double fraction(Landmark l) => into(l) / l.floors;

  /// Parts of [l] finished.
  int partsDone(Landmark l) => (fraction(l) * Landmark.parts + 1e-9).floor().clamp(0, Landmark.parts);

  /// 0 to 1 within the part being built.
  double partFraction(Landmark l) {
    final f = fraction(l) * Landmark.parts;
    return isDone(l) ? 1 : f - f.floor();
  }

  /// The floors at which part [part] (0-based) of [l] is done.
  static int partAt(Landmark l, int part) => (l.floors * (part + 1) / Landmark.parts).round();
}
