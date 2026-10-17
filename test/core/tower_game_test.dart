import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/rewards.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/core/tower/tower_landmarks.dart';

TowerGame _game() => TowerGame(random: Random(1))..start(TowerMode.climb);

/// Drops the sliding floor [offset] floor units off the top's middle.
List<TowerEvent> _dropAt(TowerGame g, double offset) {
  g.position = offset;
  g.drop();
  return g.drainEvents();
}

void main() {
  test('a drop right on top is perfect: it snaps and keeps its size', () {
    final g = _game()..drainEvents();
    final events = _dropAt(g, 0.03);
    final placed = events.whereType<TowerPlaced>().single;
    expect(placed.perfect, isTrue);
    expect(placed.cut, isNull);
    expect(g.height, 1);
    expect(g.top.a, 1);
    expect(g.top.b, 1);
    expect(g.top.cv, 0);
    expect(g.streak, 1);
  });

  test('a drop off to one side cuts what hangs over', () {
    final g = _game()..drainEvents();
    // The first floor slides along v.
    expect(g.axis, TowerAxis.v);
    final placed = _dropAt(g, 0.5).whereType<TowerPlaced>().single;
    expect(placed.perfect, isFalse);
    expect(g.top.b, closeTo(0.75, 1e-9));
    expect(g.top.cv, closeTo(0.25, 1e-9));
    expect(g.top.a, 1);
    final cut = placed.cut!;
    expect(cut.b, closeTo(0.25, 1e-9));
    expect(cut.cv, closeTo(1.25, 1e-9));
    expect(g.streak, 0);
    // The next floor slides the other way, along u, at the new size.
    expect(g.axis, TowerAxis.u);
    expect(g.slab.b, closeTo(0.75, 1e-9));
  });

  test('missing the tower ends the run; one more go once', () {
    final g = _game()..drainEvents();
    final events = _dropAt(g, 2.5);
    expect(events.whereType<TowerMissed>(), hasLength(1));
    expect(events.whereType<TowerGameOver>(), hasLength(1));
    expect(g.isOver, isTrue);
    expect(g.revive(), isTrue);
    expect(g.isOver, isFalse);
    _dropAt(g, 2.5);
    expect(g.isOver, isTrue);
    expect(g.revive(), isFalse);
  });

  test('four perfect drops in a row give some width back', () {
    final g = _game()..drainEvents();
    _dropAt(g, 0.4); // v: b 0.8
    _dropAt(g, 0.4); // u: a 0.8
    for (var i = 0; i < 3; i++) {
      _dropAt(g, 0);
    }
    expect(g.streak, 3);
    final widthBefore = g.top.half(g.axis);
    final placed = _dropAt(g, 0).whereType<TowerPlaced>().single;
    expect(placed.grew, isTrue);
    expect(g.top.half(placed.axis), closeTo(widthBefore + TowerGame.growBy, 1e-9));
  });

  test('the floor slides back and forth within reach, faster higher up', () {
    final g = _game();
    final slow = g.speed;
    for (var i = 0; i < 600; i++) {
      g.update(1 / 60);
      expect(g.position.abs(), lessThanOrEqualTo(TowerGame.reach + 0.3));
    }
    for (var i = 0; i < 200; i++) {
      _dropAt(g, 0);
    }
    expect(g.speed, greaterThan(slow * 1.3));
  });

  test("chests at the milestones, then every 250 floors", () {
    expect(TowerGame.milestoneAfter(0), 50);
    expect(TowerGame.milestoneAfter(50), 100);
    expect(TowerGame.milestoneAfter(499), 500);
    expect(TowerGame.milestoneAfter(500), 750);
    expect(TowerGame.isMilestone(200), isTrue);
    expect(TowerGame.isMilestone(750), isTrue);
    expect(TowerGame.isMilestone(150), isFalse);
    final g = _game()..drainEvents();
    final milestones = <int>[];
    for (var i = 0; i < 100; i++) {
      milestones.addAll(_dropAt(g, 0).whereType<TowerMilestone>().map((m) => m.height));
    }
    expect(milestones, [50, 100]);
    expect(Rewards.towerChest(100, unlock: Rewards.towerLooks[100]).unlock, Unlock.floorCini);
    expect(Rewards.towerTier(300), ChestTier.gold);
  });

  test("the day's tower is the same for everyone that day", () {
    List<int> flavors(int seed) {
      final g = TowerGame()..start(TowerMode.daily, seed: seed);
      return [
        for (var i = 0; i < 20; i++) ...[
          g.flavor,
          (g.speed * 1000).round(),
          (_dropAt(g, 0), g.height).$2,
        ],
      ];
    }

    final seed = TowerGame.dailySeed(DateTime(2026, 10, 17));
    expect(seed, 20261017);
    expect(flavors(seed), flavors(seed));
    expect(flavors(seed), isNot(flavors(seed + 1)));
  });

  test('İstanbul is built landmark by landmark, five parts each', () {
    expect(Landmark.total, 12000);
    final start = BuildProgress(0);
    expect(start.current, Landmark.galata);
    expect(start.partsDone(Landmark.galata), 0);
    final mid = BuildProgress(650);
    expect(mid.isDone(Landmark.galata), isTrue);
    expect(mid.current, Landmark.maidens);
    expect(mid.into(Landmark.maidens), 150);
    expect(mid.partsDone(Landmark.maidens), 0);
    expect(mid.partFraction(Landmark.maidens), closeTo(0.75, 1e-9));
    expect(BuildProgress(500 + 640).partsDone(Landmark.maidens), 3);
    expect(BuildProgress.partAt(Landmark.maidens, 3), 800);
    final all = BuildProgress(Landmark.total);
    expect(all.current, isNull);
    expect(all.done, Landmark.values.length);
  });
}
