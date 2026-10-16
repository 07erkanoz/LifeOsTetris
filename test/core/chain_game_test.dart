import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';

const _dt = 1 / 60;

/// Advances [g] by [seconds] in 60 Hz steps and returns the events.
List<ChainEvent> run(ChainGame g, double seconds) {
  final events = <ChainEvent>[];
  for (var t = 0.0; t < seconds; t += _dt) {
    g.update(_dt);
    events.addAll(g.drainEvents());
  }
  return events;
}

/// A game with [rows] at the bottom and the rise held still.
ChainGame game(List<String> rows, {ChainMode mode = ChainMode.endless}) {
  final g = ChainGame(random: Random(1))..start(mode);
  g.debugSetBoard(rows);
  g.stopTime = 1000;
  g.drainEvents();
  return g;
}

String bottom(ChainGame g, [int up = 0]) => g.debugRows()[ChainGame.height - 1 - up];

void main() {
  test('the starting stack has no ready-made matches', () {
    for (var seed = 0; seed < 50; seed++) {
      final g = ChainGame(random: Random(seed))..start(ChainMode.endless);
      g.stopTime = 1000;
      final events = run(g, 0.2);
      expect(events.whereType<ChainMatched>(), isEmpty, reason: 'seed $seed');
    }
  });

  test('three in a row flash, burst one by one and disappear', () {
    final g = game(['YYYBGM']);
    final events = run(g, 0.05);
    final match = events.whereType<ChainMatched>().single;
    expect(match.combo, 3);
    expect(match.chain, 1);
    expect(match.points, 30);
    final later = run(g, 1);
    expect(later.whereType<ChainPopped>().map((e) => e.index), [0, 1, 2]);
    expect(bottom(g), '...BGM');
    expect(g.score, 30);
    expect(g.cleared, 3);
  });

  test('a vertical line matches too', () {
    final g = game(['G.....', 'G.....', 'G.....']);
    run(g, 1);
    expect(g.debugRows().every((r) => r == '......'), isTrue);
  });

  test('an L of five is one combo with a bonus', () {
    final g = game(['Y.....', 'Y.....', 'YYYMB.']);
    final match = run(g, 0.05).whereType<ChainMatched>().single;
    expect(match.combo, 5);
    expect(match.points, 50 + ChainGame.comboBonus(5));
    expect(g.stopTime, greaterThan(0));
  });

  test('a swap that lines up three clears them', () {
    final g = game(['YYBYGM']);
    expect(run(g, 0.05).whereType<ChainMatched>(), isEmpty);
    expect(g.swap(2, ChainGame.height - 1), isTrue);
    expect(bottom(g), 'YYYBGM');
    expect(g.drainEvents().whereType<ChainSwapped>(), hasLength(1));
    final events = run(g, 1);
    expect(events.whereType<ChainMatched>().single.combo, 3);
    expect(bottom(g), '...BGM');
  });

  test('a cube swapped over a gap falls to the bottom', () {
    final g = game(['.Y....', 'GB....']);
    expect(g.swap(1, ChainGame.height - 2), isTrue);
    run(g, 1);
    expect(bottom(g, 1), '......');
    expect(bottom(g), 'GBY...');
  });

  test('swapping a cube with empty space works, two empty cells do not', () {
    final g = game(['Y.....']);
    expect(g.swap(4, ChainGame.height - 1), isFalse);
    expect(g.swap(0, ChainGame.height - 1), isTrue);
    run(g, 0.2);
    expect(bottom(g), '.Y....');
  });

  test('cubes falling after a clear that match again are a chain', () {
    final g = game([
      'Y.....',
      'BBB...',
      'YGM...',
      'YMG...',
    ]);
    final events = run(g, 3);
    final matches = events.whereType<ChainMatched>().toList();
    expect(matches.map((m) => m.chain), [1, 2]);
    expect(matches.last.points, 30 + ChainGame.chainBonus(2));
    expect(events.whereType<ChainEnded>().single.chain, 2);
    expect(g.maxChain, 2);
    expect(g.chainCount, 1);
    expect(bottom(g), '.MG...');
  });

  test('a stack freed by a clear falls together and keeps its chain', () {
    // Clearing the yellows lets G,G drop onto the third G (the B with
    // nothing under it drops at once).
    final g = game([
      'G.....',
      'G.....',
      'YYYB..',
      'GOM...',
    ]);
    final events = run(g, 3);
    expect(events.whereType<ChainMatched>().map((m) => m.chain), [1, 2]);
    expect(bottom(g), '.OMB..');
  });

  test('the stack rises a row at a time and the cursor follows', () {
    final g = game(['YBGMOY']);
    g.stopTime = 0;
    g.debugSetIncoming('MOYBGM');
    final y = g.cursorY;
    final events = run(g, g.secondsPerRow(1) + 0.1);
    expect(events.whereType<ChainRowRaised>().single.manual, isFalse);
    expect(bottom(g), 'MOYBGM');
    expect(bottom(g, 1), 'YBGMOY');
    expect(g.cursorY, y - 1);
  });

  test('holding raise lifts the stack fast and scores a point a row', () {
    final g = game(['YBGMOY']);
    g.raising = true;
    final events = run(g, 0.5);
    final rows = events.whereType<ChainRowRaised>().length;
    expect(rows, greaterThanOrEqualTo(3));
    expect(events.whereType<ChainRowRaised>().every((e) => e.manual), isTrue);
    expect(g.score, rows);
  });

  test('a big clear stops the rise for a while', () {
    final g = game(['Y.....', 'Y.....', 'YYYMB.']);
    g.stopTime = 0;
    run(g, 0.05);
    expect(g.stopTime, greaterThan(0.5));
  });

  test('a stack touching the top ends the game after the grace time', () {
    final rows = [for (var y = 0; y < ChainGame.height; y++) y.isEven ? 'Y.....' : 'B.....'];
    final g = game(rows);
    g.stopTime = 0;
    var events = run(g, g.graceTime - 0.3);
    expect(g.isOver, isFalse);
    expect(g.graceUsed, greaterThan(0.5));
    events = run(g, 0.5);
    expect(g.isOver, isTrue);
    expect(events.whereType<ChainGameOver>().single.timeUp, isFalse);
  });

  test('garbage next to a match breaks into cubes that fall', () {
    final g = game(['###...', 'YYYB..']);
    expect(g.slabs, hasLength(1));
    final events = run(g, 0.05);
    expect(events.whereType<ChainMatched>().single.garbage, 3);
    final later = run(g, 3);
    expect(later.whereType<ChainGarbageBroken>().single.width, 3);
    expect(g.slabs, isEmpty);
    expect(g.debugRows().join().contains('#'), isFalse);
    expect(bottom(g, 1), '......');
    expect(bottom(g).substring(3), 'B..');
  });

  test('garbage falls as a whole and cubes cannot be swapped with it', () {
    final g = game(['###...', '......', 'YBGMOY']);
    run(g, 1);
    expect(bottom(g, 1), '###...');
    expect(g.swap(2, ChainGame.height - 2), isFalse);
  });

  test('cubes that are clearing cannot be swapped', () {
    final g = game(['YYYBGM']);
    run(g, 0.05);
    expect(g.swap(2, ChainGame.height - 1), isFalse);
  });

  test('time attack ends after two minutes', () {
    final g = ChainGame(random: Random(2))..start(ChainMode.timeAttack);
    g.stopTime = 1000;
    final events = run(g, ChainGame.timeAttackLength + 1);
    expect(g.isOver, isTrue);
    expect(g.timeUp, isTrue);
    expect(events.whereType<ChainGameOver>().single.timeUp, isTrue);
  });

  test('easy plays four colours, rises slowly, forgives longer and drops no garbage', () {
    final easy = ChainGame(random: Random(3))..start(ChainMode.endless, difficulty: ChainDifficulty.easy);
    final colours = {for (final row in easy.board) for (final b in row) if (b != null) b.color};
    expect(colours.difference({ChainColor.yellow, ChainColor.magenta, ChainColor.blue, ChainColor.green, ChainColor.gray}), isEmpty);
    final normal = ChainGame()..start(ChainMode.endless);
    final hard = ChainGame()..start(ChainMode.endless, difficulty: ChainDifficulty.hard);
    expect(easy.secondsPerRow(1), greaterThan(normal.secondsPerRow(1)));
    expect(hard.secondsPerRow(1), lessThan(normal.secondsPerRow(1)));
    expect(easy.graceTime, greaterThan(hard.graceTime));
    easy.stopTime = 1000;
    final events = run(easy, 120);
    expect(events.whereType<ChainGarbageDropped>(), isEmpty);
  });

  test('normal drops garbage after a while', () {
    final g = game(['YBGMOY']);
    final events = run(g, ChainDifficulty.normal.firstGarbage + 1);
    expect(events.whereType<ChainGarbageDropped>(), hasLength(1));
  });

  test('the level and the speed grow with time', () {
    final g = game(['YBGMOY']);
    final events = run(g, 36);
    expect(events.whereType<ChainLevelUp>().single.level, 2);
    expect(g.secondsPerRow(2), lessThan(g.secondsPerRow(1)));
    expect(g.secondsPerRow(ChainGame.maxLevel), greaterThanOrEqualTo(0.9));
  });
}
