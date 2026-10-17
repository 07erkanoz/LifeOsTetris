import 'dart:math';

/// Kule Küpler: a floor slides above the tower, a tap drops it, whatever
/// hangs over the floor below is cut off. Plain Dart, no Flutter.
///
/// Sizes are in floor units: the first floor is 2 × 2 (half-sizes 1). The
/// two axes are the isometric ones: [TowerAxis.u] runs to the lower right of
/// the screen, [TowerAxis.v] to the lower left.
enum TowerMode {
  /// The long climb: floors without end, a chest at each milestone.
  climb,

  /// The wind: the floor slides in gusts, faster and slower.
  wind,

  /// The day's tower: the same for everyone that day, three tries.
  daily,
}

enum TowerAxis { u, v }

enum TowerStatus { playing, over }

/// One floor of the tower: its centre and half-sizes, in floor units.
class TowerFloor {
  const TowerFloor({required this.cu, required this.cv, required this.a, required this.b, required this.flavor, this.perfect = false});

  final double cu, cv;

  /// Half-size along u and along v.
  final double a, b;

  /// Which of the six lokum flavours it is.
  final int flavor;

  /// Dropped right on the floor below.
  final bool perfect;

  double half(TowerAxis axis) => axis == TowerAxis.u ? a : b;
  double centre(TowerAxis axis) => axis == TowerAxis.u ? cu : cv;
}

class TowerEvent {
  const TowerEvent();
}

/// A floor landed: [cut] is the piece cut off, if any.
class TowerPlaced extends TowerEvent {
  const TowerPlaced({required this.floor, required this.height, required this.perfect, required this.streak, required this.grew, this.cut, required this.axis});

  final TowerFloor floor;
  final int height;
  final bool perfect;
  final int streak;

  /// A run of perfect drops gave the floor some width back.
  final bool grew;
  final TowerFloor? cut;
  final TowerAxis axis;
}

/// A milestone floor was reached: a chest waits.
class TowerMilestone extends TowerEvent {
  const TowerMilestone(this.height);

  final int height;
}

/// The floor missed the tower altogether and fell.
class TowerMissed extends TowerEvent {
  const TowerMissed(this.slab);

  final TowerFloor slab;
}

class TowerGameOver extends TowerEvent {
  const TowerGameOver(this.height);

  final int height;
}

class TowerGame {
  TowerGame({Random? random}) : _random = random ?? Random();

  Random _random;

  /// How far the floor slides either side of the tower's middle.
  static const double reach = 1.7;

  /// Off by no more than this, the drop counts as perfect and snaps.
  static const double perfectTolerance = 0.07;

  /// Every this many perfect drops in a row the floor grows back a little.
  static const int growEvery = 4;
  static const double growBy = 0.1;

  /// The floors with a chest: these, then every 250 floors.
  static const List<int> milestones = [50, 100, 200, 300, 500];

  /// The day's tower: three tries.
  static const int dailyTries = 3;

  static int milestoneAfter(int height) {
    for (final m in milestones) {
      if (m > height) return m;
    }
    return (height ~/ 250 + 1) * 250;
  }

  static bool isMilestone(int height) => milestones.contains(height) || (height > milestones.last && height % 250 == 0);

  /// The seed of [day]'s tower: the same for everyone that day.
  static int dailySeed(DateTime day) => day.year * 10000 + day.month * 100 + day.day;

  TowerMode mode = TowerMode.climb;
  TowerStatus status = TowerStatus.over;

  /// The tower from the bottom; the first is the base, not a placed floor.
  final List<TowerFloor> floors = [];

  /// Floors placed in this run.
  int get height => max(0, floors.length - 1);

  int streak = 0;
  int bestStreak = 0;
  int perfects = 0;

  /// One more go after a miss, once a run.
  bool revived = false;

  /// The sliding floor: which axis, where along it, which way it goes.
  TowerAxis axis = TowerAxis.v;
  double position = -reach;
  double direction = 1;
  double _speedJitter = 1;
  double time = 0;

  /// The sliding floor's flavour.
  int flavor = 0;

  final List<TowerEvent> _events = [];

  List<TowerEvent> drainEvents() {
    final out = List<TowerEvent>.of(_events);
    _events.clear();
    return out;
  }

  bool get isOver => status == TowerStatus.over;

  TowerFloor get top => floors.last;

  void start(TowerMode mode, {int? seed}) {
    this.mode = mode;
    if (seed != null) _random = Random(seed);
    floors
      ..clear()
      ..add(TowerFloor(cu: 0, cv: 0, a: 1, b: 1, flavor: _random.nextInt(6)));
    streak = 0;
    bestStreak = 0;
    perfects = 0;
    revived = false;
    time = 0;
    status = TowerStatus.playing;
    _events.clear();
    _nextSlab();
  }

  /// Floor units a second: slow at first, quicker the higher the tower,
  /// levelling off.
  double get speed {
    final base = 1.25 + 1.15 * (1 - exp(-height / 110));
    final gust = mode == TowerMode.wind ? 1 + 0.5 * sin(time * 2.4) * (0.6 + 0.4 * sin(time * 0.7)) : 1;
    return base * _speedJitter * gust;
  }

  void update(double dt) {
    if (status != TowerStatus.playing) return;
    time += dt;
    position += direction * speed * dt;
    final limit = reach + top.half(axis) * 0.2;
    if (position > limit) {
      position = limit - (position - limit);
      direction = -1;
    } else if (position < -limit) {
      position = -limit + (-limit - position);
      direction = 1;
    }
  }

  /// The sliding floor as it is now.
  TowerFloor get slab {
    final t = top;
    return TowerFloor(
      cu: axis == TowerAxis.u ? t.cu + position : t.cu,
      cv: axis == TowerAxis.v ? t.cv + position : t.cv,
      a: t.a,
      b: t.b,
      flavor: flavor,
    );
  }

  /// Drops the sliding floor.
  void drop() {
    if (status != TowerStatus.playing) return;
    final t = top;
    final half = t.half(axis);
    final offset = position;
    final overlap = 2 * half - offset.abs();
    if (overlap <= 0.02) {
      _events.add(TowerMissed(slab));
      streak = 0;
      status = TowerStatus.over;
      _events.add(TowerGameOver(height));
      return;
    }
    TowerFloor? cut;
    TowerFloor placed;
    final perfect = offset.abs() <= perfectTolerance;
    var grew = false;
    if (perfect) {
      streak++;
      perfects++;
      bestStreak = max(bestStreak, streak);
      var a = t.a, b = t.b;
      if (streak % growEvery == 0) {
        grew = axis == TowerAxis.u ? a < 1 : b < 1;
        if (axis == TowerAxis.u) {
          a = min(1, a + growBy);
        } else {
          b = min(1, b + growBy);
        }
      }
      placed = TowerFloor(cu: t.cu, cv: t.cv, a: a, b: b, flavor: flavor, perfect: true);
    } else {
      streak = 0;
      final c = t.centre(axis);
      final newHalf = overlap / 2;
      final newCentre = c + offset / 2;
      final cutHalf = offset.abs() / 2;
      final cutCentre = c + offset.sign * (half + offset.abs() - cutHalf);
      placed = axis == TowerAxis.u
          ? TowerFloor(cu: newCentre, cv: t.cv, a: newHalf, b: t.b, flavor: flavor)
          : TowerFloor(cu: t.cu, cv: newCentre, a: t.a, b: newHalf, flavor: flavor);
      cut = axis == TowerAxis.u
          ? TowerFloor(cu: cutCentre, cv: t.cv, a: cutHalf, b: t.b, flavor: flavor)
          : TowerFloor(cu: t.cu, cv: cutCentre, a: t.a, b: cutHalf, flavor: flavor);
    }
    floors.add(placed);
    _events.add(TowerPlaced(floor: placed, height: height, perfect: perfect, streak: streak, grew: grew, cut: cut, axis: axis));
    if (isMilestone(height)) _events.add(TowerMilestone(height));
    _nextSlab();
  }

  /// After a miss: one more go, the tower as it was. Once a run.
  bool revive() {
    if (status != TowerStatus.over || revived) return false;
    revived = true;
    status = TowerStatus.playing;
    _nextSlab();
    return true;
  }

  void _nextSlab() {
    axis = height.isEven ? TowerAxis.v : TowerAxis.u;
    // It comes in from the back, the far end of its axis.
    position = -(reach + top.half(axis) * 0.2);
    direction = 1;
    _speedJitter = 0.92 + _random.nextDouble() * 0.16;
    flavor = (top.flavor + 1 + _random.nextInt(2)) % 6;
  }
}
