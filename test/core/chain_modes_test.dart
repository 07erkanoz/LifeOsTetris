import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/chain/chain_missions.dart';
import 'package:lifeos_kupler/core/chain/chain_sim.dart';
import 'package:lifeos_kupler/core/chain/chain_versus.dart';

const _dt = 1 / 60;

List<ChainEvent> run(ChainGame g, double seconds) {
  final events = <ChainEvent>[];
  for (var t = 0.0; t < seconds; t += _dt) {
    g.update(_dt);
    events.addAll(g.drainEvents());
  }
  return events;
}

void main() {
  group('the board without time', () {
    test('a swap, a match, the fall and a chain', () {
      // Swapping the yellow in clears the greens' support; the yellows above
      // fall into a second match.
      final sim = ChainSim.rows(['..Y...', '..Y...', 'GGBG..', 'BBYB..']);
      expect(sim.matches(), isEmpty);
      final s = sim.copy()..swap(2, 10);
      final r = s.settle();
      expect(r.chain, 2);
      expect(r.cleared, 6);
    });

    test('solve finds the fewest swaps that clear everything', () {
      final one = ChainSim.rows(['YYBYBB']);
      expect(one.solve(1), [(2, 11)]);
      final none = ChainSim.rows(['YYB...']);
      expect(none.solve(3), isNull);
    });

    test('a snapshot of a game is the same board, still', () {
      final g = ChainGame(random: Random(2))..start(ChainMode.endless);
      final sim = ChainSim.of(g);
      expect(sim.rows(), g.debugRows());
    });
  });

  group('puzzles', () {
    test('a puzzle counts the swaps, holds still and is solved when empty', () {
      final g = ChainGame(random: Random(1))..startPuzzle(['YYBYBB'], 1);
      final before = g.debugRows();
      run(g, 3);
      expect(g.debugRows(), before, reason: 'the stack does not rise');
      expect(g.swap(2, 11), isTrue);
      expect(g.movesLeft, 0);
      run(g, 2);
      expect(g.isOver, isTrue);
      expect(g.won, isTrue);
    });

    test('out of swaps with cubes left: not solved; undo gives the swap back', () {
      final g = ChainGame(random: Random(1))..startPuzzle(['YYBY..', 'BBGB..'], 1);
      g.swap(2, 11);
      run(g, 0.05);
      expect(g.undo(), isFalse, reason: 'not while it moves');
      run(g, 2);
      expect(g.isOver, isTrue);
      expect(g.won, isFalse);

      final h = ChainGame(random: Random(1))..startPuzzle(['YYBY..', 'BBGB..'], 2);
      final start = h.debugRows();
      h.swap(2, 11);
      run(h, 1);
      expect(h.undo(), isTrue);
      expect(h.debugRows(), start);
      expect(h.movesLeft, 2);
    });

    test('a swap of two cubes of one colour does nothing and costs nothing', () {
      final g = ChainGame(random: Random(1))..startPuzzle(['YYBY..'], 1);
      expect(g.swap(0, 11), isFalse);
      expect(g.movesLeft, 1);
    });
  });

  group('missions', () {
    test('every pier has five missions; the puzzles and rivals exist', () {
      expect(ChainMissions.count, ChainMissions.piers.length * 5);
      for (final m in ChainMissions.all) {
        if (m.kind == MissionKind.puzzle) expect(m.target, inInclusiveRange(1, 80));
        if (m.kind == MissionKind.versus) expect(m.target, lessThan(ChainRival.values.length));
      }
      expect(ChainMissions.all.map((m) => m.number), [for (var i = 1; i <= ChainMissions.count; i++) i]);
    });

    test('a chain mission counts chains of its size and ends when done', () {
      final g = ChainGame(random: Random(1))..startMission(const ChainMission(number: 1, kind: MissionKind.chain, target: 2, seconds: 90));
      g.debugSetBoard(['..Y...', '..Y...', 'GGBG..', 'BBYB..']);
      g.stopTime = 1000;
      g.drainEvents();
      g.swap(2, 10);
      final events = run(g, 3);
      expect(events.whereType<ChainMissionProgress>().last.progress, 1);
      expect(g.won, isTrue);
      expect(g.isOver, isTrue);
    });

    test('a mission out of time is missed, unless surviving was the goal', () {
      final g = ChainGame(random: Random(1))..startMission(const ChainMission(number: 2, kind: MissionKind.score, target: 99999, seconds: 2));
      run(g, 2.5);
      expect(g.isOver, isTrue);
      expect(g.won, isFalse);
      final s = ChainGame(random: Random(1))..startMission(const ChainMission(number: 5, kind: MissionKind.survive, target: 0, seconds: 2, difficulty: ChainDifficulty.easy));
      run(s, 2.5);
      expect(s.won, isTrue);
    });

    test('a garbage mission starts with slabs over the stack', () {
      final g = ChainGame(random: Random(3))..startMission(const ChainMission(number: 3, kind: MissionKind.garbage, target: 12, seconds: 100));
      expect(g.slabs, hasLength(2));
      expect(g.slabs.every((s) => s.width == ChainGame.width), isTrue);
    });

    test('stars follow the time left', () {
      const m = ChainMission(number: 1, kind: MissionKind.chain, target: 2, seconds: 100);
      expect(ChainMissions.stars(m, left: 60, chain: 2), 3);
      expect(ChainMissions.stars(m, left: 30, chain: 2), 2);
      expect(ChainMissions.stars(m, left: 5, chain: 2), 1);
    });
  });

  group('against the computer', () {
    test('a chain sends rows of garbage, a combo a slab', () {
      final v = ChainVersus(ChainRival.apprentice, random: Random(4))..startSet();
      v.player.debugSetBoard(['..Y...', '..Y...', 'GGBG..', 'BBYB..']);
      v.player.stopTime = 1000;
      v.cpu.stopTime = 1000;
      v.player.swap(2, 10);
      for (var t = 0.0; t < 3; t += _dt) {
        v.update(_dt);
      }
      expect(v.cpu.pendingGarbage.isNotEmpty || v.cpu.slabs.isNotEmpty, isTrue);
    });

    test('the computer makes a matching swap when it has one', () {
      final g = ChainGame(random: Random(1))..start(ChainMode.versus);
      g.debugSetBoard(['YYBY..', 'BGGBMM']);
      final move = ChainCpu(ChainRival.master, random: Random(1)).pick(g);
      expect(move, isNotNull);
      final sim = ChainSim.of(g)..swap(move!.$1, move.$2);
      expect(sim.settle().cleared, greaterThan(0));
    });

    test('topping out loses the set; two sets win the match', () {
      final v = ChainVersus(ChainRival.apprentice, random: Random(5))..startSet();
      v.cpu.endMatch(won: false);
      v.update(_dt);
      expect(v.playerSets, 1);
      expect(v.player.won, isTrue);
      v.startSet();
      v.cpu.endMatch(won: false);
      v.update(_dt);
      expect(v.matchOver, isTrue);
      expect(v.playerWonMatch, isTrue);
    });
  });
}
