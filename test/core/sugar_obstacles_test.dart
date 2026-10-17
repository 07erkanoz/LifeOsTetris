import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';

/// A background with no matches and no moves among its own colours (G, B,
/// P, O); the tests put red and yellow sweets on it.
List<String> board(Map<int, String> rows) => [
  for (var y = 0; y < 8; y++) rows[y] ?? (y.isEven ? 'GBGBGBGB' : 'POPOPOPO'),
];

const _open = ['........', '........', '........', '........', '........', '........', '........', '........'];

SugarLevel level({List<SugarGoal Function()>? goals, Map<int, int> belts = const {}, int limonEvery = 0, int moves = 20}) => SugarLevel(
  number: 99,
  moves: moves,
  colors: 6,
  layout: _open,
  goals: goals ?? [() => SugarGoal.color(SugarColor.red, 999)],
  stars: const [1 << 29, 1 << 29, 1 << 29],
  rush: 0,
  belts: belts,
  limonEvery: limonEvery,
);

SugarGame game(List<String> rows, {SugarLevel? at, Map<Cell, int> cakeAt = const {}, Map<Cell, SugarColor> doors = const {}}) {
  final g = SugarGame(seed: 7)..start(at ?? level());
  g.debugSetBoard(rows, cakeAt: cakeAt, doors: doors);
  g.drainEvents();
  return g;
}

/// The swap that lines up three reds along the bottom row of [board].
const _bottomA = (2, 6), _bottomB = (2, 7);
const _row6 = 'GBRBGBGB';

void main() {
  test('chocolate beside a match is cleared and counts for its goal', () {
    final g = game(board({6: _row6, 7: 'RRP%POPO'}), at: level(goals: [() => SugarGoal.choco(5)]));
    expect(g.swap(_bottomA, _bottomB), isTrue);
    g.settle();
    expect(g.choco[7][3], 0);
    expect(g.goals.single.progress, 1);
    expect(g.drainEvents().whereType<SugarChocoSpread>(), isEmpty, reason: 'it was hit this move, so it does not spread');
  });

  test('chocolate nobody touches spreads onto a plain neighbour', () {
    final g = game(board({0: 'GBGBGBG%', 6: _row6, 7: 'RRPOPOPO'}));
    expect(g.chocoLeft, 1);
    g.swap(_bottomA, _bottomB);
    g.settle();
    expect(g.chocoLeft, 2);
    expect(g.choco[0][6] + g.choco[1][7], 1);
    expect(g.drainEvents().whereType<SugarChocoSpread>(), hasLength(1));
  });

  test('a pomegranate never matches, falls with the sweets and is collected at the bottom', () {
    final g = game(board({6: '*BRBGBGB', 7: 'RRPOPOPO'}), at: level(goals: [() => SugarGoal.fruit(1), () => SugarGoal.color(SugarColor.red, 999)]));
    expect(g.board[6][0]!.fruit, isTrue);
    g.swap(_bottomA, _bottomB);
    g.settle();
    expect(g.goals.first.progress, 1);
    expect(g.fruitsOnBoard, 0, reason: 'the goal had one, so no more drop in');
    expect(g.drainEvents().whereType<SugarFruitDone>().single.x, 0);
  });

  test('more pomegranates drop in until the goal has its count', () {
    final g = game(board({6: '*BRBGBGB', 7: 'RRPOPOPO'}), at: level(goals: [() => SugarGoal.fruit(3)]));
    g.swap(_bottomA, _bottomB);
    g.settle();
    expect(g.goals.single.progress, 1);
    expect(g.fruitsOnBoard, 2, reason: 'two at once, one per refill');
  });

  test('a belt row moves one cell along after a move, round the end', () {
    final g = game(board({0: 'RRPBGBGB', 1: 'POROPOPO'}), at: level(belts: {7: 1}));
    final before = [for (final p in g.board[7]) p!.id];
    expect(g.swap((2, 0), (2, 1)), isTrue);
    g.settle();
    expect([for (var x = 0; x < 8; x++) g.board[7][(x + 1) % 8]!.id], before);
    final belted = g.drainEvents().whereType<SugarBelted>().single;
    expect(belted.moves, hasLength(8));
  });

  test('a cake loses one layer per match beside it, and leaves a wrapped sweet', () {
    final rows = board({6: 'GBR==BGB', 7: 'RRP==OPO'});
    final g = game(rows, cakeAt: {(3, 6): 3});
    expect(g.blocked(4, 7), isTrue);
    g.swap(_bottomA, _bottomB);
    g.settle();
    expect(g.cake[6][3], 2, reason: 'two of its cells were beside the match, still one bite');
    for (var i = 0; i < 2; i++) {
      expect(g.hammer(3, 6), isTrue);
      g.settle();
    }
    expect(g.cakes, isEmpty);
    expect(g.cake[7][4], 0);
    expect([for (var y = 0; y < 8; y++) g.board[y][3]?.special].contains(Special.bomb), isTrue);
  });

  test('a door opens only to a match of its own colour, with a striped sweet behind', () {
    final yellow = game(board({6: 'GBYBGBGB', 7: 'YYP|POPO'}), doors: {(3, 7): SugarColor.red});
    yellow.swap(_bottomA, _bottomB);
    yellow.settle();
    expect(yellow.door[7][3], SugarColor.red.index + 1);

    final red = game(board({6: _row6, 7: 'RRP|POPO'}), at: level(goals: [() => SugarGoal.door(2)]), doors: {(3, 7): SugarColor.red});
    red.swap(_bottomA, _bottomB);
    red.settle();
    expect(red.door[7][3], 0);
    expect(red.goals.single.progress, 1);
    expect(red.drainEvents().whereType<SugarDoorOpened>().single.color, SugarColor.red);
    expect([for (final row in red.board) for (final p in row) p?.isLine ?? false].contains(true), isTrue);
  });

  test('Ekşi Limon loses sourness to matches and throws lemon slices every few moves', () {
    final g = SugarGame(seed: 3)..start(level(goals: [() => SugarGoal.limon(400)], limonEvery: 2));
    int slices() => g.slice.fold(0, (n, row) => n + row.where((s) => s > 0).length);
    for (var move = 1; move <= 2; move++) {
      final m = SugarSolver.best(g)!;
      g.swap(m.$1, m.$2);
      g.settle();
      if (move == 1) expect(slices(), 0);
    }
    expect(g.goals.single.progress, greaterThan(0));
    expect(slices(), greaterThan(0));
    expect(g.drainEvents().whereType<SugarSliceThrown>().single.cells, hasLength(3));
  });

  test('a third of Ekşi Limon gone: he shuffles the board and throws more often', () {
    final g = SugarGame(seed: 5)..start(level(goals: [() => SugarGoal.limon(400)], limonEvery: 4));
    g.goals.single.progress = 140;
    final m = SugarSolver.best(g)!;
    g.swap(m.$1, m.$2);
    g.settle();
    expect(g.limonPhase, 1);
    final events = g.drainEvents();
    expect(events.whereType<SugarLimonPhase>().single.phase, 1);
    expect(events.whereType<SugarShuffled>(), isNotEmpty);
  });

  test('the hammer opens a door and breaks chocolate, but not a pomegranate', () {
    final g = game(board({3: 'GBG%GBGB', 5: 'POP|POPO', 6: '*BGBGBGB'}), doors: {(3, 5): SugarColor.blue});
    expect(g.canHammer(0, 6), isFalse);
    expect(g.hammer(3, 5), isTrue);
    g.settle();
    expect(g.door[5][3], 0);
    expect(g.hammer(3, 3), isTrue);
    g.settle();
    expect(g.choco[3][3], 0);
  });

  test('a saved game keeps the chocolate, cakes, doors, slices and pomegranates', () {
    final rows = board({0: 'GB%BGBGB', 2: 'GB~BGBGB', 4: 'GBG==BGB', 5: 'POP==OPO', 6: '*BGB|BGB'});
    final g = game(rows, cakeAt: {(3, 4): 2}, doors: {(4, 6): SugarColor.purple});
    final copy = SugarGame()..restore(g.level!, jsonDecode(jsonEncode(g.toSave())) as Map<String, Object?>);
    expect(copy.debugRows(), g.debugRows());
    expect(copy.cakes, g.cakes);
    expect(copy.cake[5][4], 2);
    expect(copy.door[6][4], SugarColor.purple.index + 1);
    expect(copy.board[6][0]!.fruit, isTrue);
    expect(g.copy().debugRows(), g.debugRows());
  });
}
