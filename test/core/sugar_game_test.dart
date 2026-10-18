import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';

/// A background with no matches and no moves among its own colours (G, B,
/// P, O); the tests put red and yellow sweets on it.
List<String> board(Map<int, String> rows) => [
  for (var y = 0; y < 8; y++) rows[y] ?? (y.isEven ? 'GBGBGBGB' : 'POPOPOPO'),
];

const _open = ['........', '........', '........', '........', '........', '........', '........', '........'];

/// A level for rule tests: no luck, no gifts, no rush unless asked.
SugarLevel testLevel({
  int moves = 20,
  List<SugarGoal Function()>? goals,
  List<int> stars = const [1 << 29, 1 << 29, 1 << 29],
  int luck = 0,
  int gifts = 0,
  int rush = 0,
  int bombTimer = 9,
  int bombEvery = 0,
}) => SugarLevel(
  number: 99,
  moves: moves,
  colors: 6,
  layout: _open,
  goals: goals ?? [() => SugarGoal.color(SugarColor.red, 999)],
  stars: stars,
  luck: luck,
  gifts: gifts,
  rush: rush,
  bombTimer: bombTimer,
  bombEvery: bombEvery,
);

/// A game on [rows] for rule tests.
SugarGame game(List<String> rows, {SugarLevel? level, Map<Cell, Special> specials = const {}, Map<Cell, int> iceAt = const {}, Map<Cell, int> timers = const {}, int moves = 20}) {
  final g = SugarGame()..start(level ?? testLevel(moves: moves));
  g.debugSetBoard(rows, specials: specials, iceAt: iceAt, timers: timers, moves: moves);
  g.drainEvents();
  return g;
}

void main() {
  test('a level starts full, with no match and a move to make', () {
    for (final level in SugarLevels.all) {
      final g = SugarGame(seed: level.number)..start(level);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          expect(g.board[y][x] != null || g.blocked(x, y) || g.hole[y][x] > 0, isTrue, reason: 'level ${level.number} ($x, $y)');
        }
      }
      expect(g.drainEvents(), isEmpty, reason: 'nothing happens before the first move');
      expect(g.hasMove(), isTrue);
      final before = g.debugRows();
      expect(g.advance(), isFalse, reason: 'level ${level.number} has no match on the board');
      expect(g.debugRows(), before);
      expect(g.moves, level.moves);
    }
  });

  test('a swap that makes nothing is undone and costs no move', () {
    final g = game(board({}));
    expect(g.swap((0, 0), (1, 0)), isFalse);
    expect(g.moves, 20);
    expect(g.debugRows(), board({}));
    expect(g.drainEvents().single, isA<SugarSwapRejected>());
  });

  test('three in a row clear, the column falls and refills', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}));
    expect(g.swap((2, 6), (2, 7)), isTrue);
    expect(g.moves, 19);
    expect(g.advance(), isTrue);
    expect([for (var x = 0; x < 3; x++) g.board[7][x]], [null, null, null]);
    expect(g.score, 3 * SugarGame.matchPoints);
    expect(g.advance(), isTrue, reason: 'gravity');
    final fell = g.drainEvents().whereType<SugarFell>().single;
    expect(fell.moves.where((m) => m.$3 < 0), hasLength(3), reason: 'three new sweets come in from above');
    expect(fell.moves.every((m) => m.$2 == m.$4), isTrue, reason: 'straight down');
    g.settle();
    expect(g.board.expand((r) => r).every((p) => p != null), isTrue);
    expect(g.status, isNot(SugarStatus.resolving));
  });

  test('four in a row make a striped sweet where it was moved; bigger matches score more', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRYRPOPO'}));
    g.swap((2, 6), (2, 7));
    g.advance();
    final p = g.board[7][2]!;
    expect(p.special, Special.lineV);
    expect(p.color, SugarColor.red);
    expect([g.board[7][0], g.board[7][1], g.board[7][3]], [null, null, null]);
    expect(g.drainEvents().whereType<SugarCreated>().single.piece.special, Special.lineV);
    expect(g.score, 4 * SugarGame.matchPoints + 60, reason: 'a striped sweet is worth a bonus');
  });

  test('an L makes a wrapped sweet, five in a row a rainbow ball', () {
    final l = game(board({5: 'POROPOPO', 6: 'GBRBGBGB', 7: 'RRYRPOPO'}));
    l.swap((3, 7), (2, 7));
    l.advance();
    expect(l.board[7][2]!.special, Special.bomb);
    expect([l.board[5][2], l.board[6][2], l.board[7][0]], [null, null, null]);

    final five = game(board({6: 'GBRBGBGB', 7: 'RRYRROPO'}));
    five.swap((2, 6), (2, 7));
    five.advance();
    expect(five.board[7][2]!.special, Special.prism);
  });

  test('a striped sweet fires along its row when hit', () {
    final g = game(board({}), specials: {(3, 3): Special.lineH});
    expect(g.hammer(3, 3), isTrue);
    g.drainEvents();
    expect(g.advance(), isTrue);
    final blast = g.drainEvents().whereType<SugarBlast>().single;
    expect(blast.kind, Special.lineH);
    expect(blast.cells, hasLength(8));
    expect(g.board[3].every((p) => p == null), isTrue);
  });

  test('a wrapped sweet clears the 3x3 around it', () {
    final g = game(board({}), specials: {(4, 4): Special.bomb});
    g.hammer(4, 4);
    g.advance();
    for (var y = 3; y <= 5; y++) {
      for (var x = 3; x <= 5; x++) {
        expect(g.board[y][x], isNull);
      }
    }
    expect(g.board[2][4], isNotNull);
  });

  test('a rainbow ball swapped with a sweet takes every sweet of that colour', () {
    final g = game(board({}), specials: {(3, 3): Special.prism});
    g.goals = [SugarGoal.color(SugarColor.purple, 10)];
    expect(g.swap((3, 3), (4, 3)), isTrue);
    final cleared = g.drainEvents().whereType<SugarCleared>().single;
    expect(cleared.pieces, hasLength(16));
    expect(cleared.pieces.every((c) => c.$3.color == SugarColor.purple), isTrue);
    expect(g.goals.single.done, isTrue);
    expect(g.board.expand((r) => r).where((p) => p?.color == SugarColor.purple), isEmpty);
  });

  test('two specials side by side are a pair; each combination has its name', () {
    final pair = game(board({}), specials: {(3, 3): Special.lineH, (4, 3): Special.bomb});
    expect(pair.comboPairs, [((3, 3), (4, 3))]);
    pair.swap((3, 3), (4, 3));
    expect(pair.drainEvents().whereType<SugarComboFired>().single.combo, SugarCombo.bigCross);
    for (final (a, b, combo) in [(Special.lineH, Special.lineV, SugarCombo.cross), (Special.bomb, Special.bomb, SugarCombo.mega), (Special.prism, Special.none, SugarCombo.rainbow), (Special.prism, Special.prism, SugarCombo.wipe)]) {
      final g = game(board({}), specials: {(3, 3): a, if (b != Special.none) (4, 3): b});
      g.swap((3, 3), (4, 3));
      expect(g.drainEvents().whereType<SugarComboFired>().single.combo, combo);
    }
  });

  test('two specials swapped together combine, and score double', () {
    final lines = game(board({}), specials: {(3, 3): Special.lineH, (4, 3): Special.lineV});
    lines.swap((3, 3), (4, 3));
    final blast = lines.drainEvents().whereType<SugarBlast>().first;
    expect(blast.cells, hasLength(15), reason: 'a row and a column');
    expect(blast.combo, isTrue);
    expect(lines.score, 15 * SugarGame.blastPoints * 2);

    final bombs = game(board({}), specials: {(3, 3): Special.bomb, (3, 4): Special.bomb});
    bombs.swap((3, 3), (3, 4));
    expect(bombs.drainEvents().whereType<SugarBlast>().first.cells, hasLength(25), reason: 'a 5x5');

    final prisms = game(board({}), specials: {(3, 3): Special.prism, (3, 4): Special.prism});
    prisms.swap((3, 3), (3, 4));
    expect(prisms.board.expand((r) => r).every((p) => p == null), isTrue, reason: 'two rainbow balls clear the board');
  });

  test('chained sweets do not move; a match frees them', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RrYOPOPO'}));
    expect(g.canSwap((1, 7), (1, 6)), isFalse);
    expect(g.swap((2, 6), (2, 7)), isTrue);
    g.advance();
    expect(g.board[7][1], isNotNull);
    expect(g.board[7][1]!.chained, isFalse);
    expect(g.board[7][0], isNull);
    expect(g.drainEvents().whereType<SugarUnchained>(), hasLength(1));
  });

  test('ice cracks under a cleared sweet; thick ice takes two', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), iceAt: {(0, 7): 1, (1, 7): 2});
    g.goals = [SugarGoal.ice(2)];
    g.swap((2, 6), (2, 7));
    g.advance();
    expect(g.ice[7][0], 0);
    expect(g.ice[7][1], 1);
    expect(g.goals.single.progress, 1);
    expect(g.iceLeft, 1);
  });

  test('a candy box next to a match loses a layer; the last layer opens it', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRP#POPO'}));
    expect(g.box[7][3], 2);
    expect(g.board[7][3], isNull);
    g.goals = [SugarGoal.box(1)];
    g.swap((2, 6), (2, 7));
    g.advance();
    expect(g.box[7][3], 1);
    expect(g.drainEvents().whereType<SugarBoxHit>().single.left, 1);
    expect(g.goals.single.progress, 0);

    final one = game(board({6: 'GBRBGBGB', 7: 'RRP+POPO'}));
    one.goals = [SugarGoal.box(1)];
    one.swap((2, 6), (2, 7));
    one.advance();
    expect(one.box[7][3], 0);
    expect(one.goals.single.done, isTrue);
    one.advance();
    expect(one.board[7][3], isNotNull, reason: 'the opened cell fills from above');
  });

  test('blasts knock boxes; boxes cannot be swapped', () {
    final g = game(board({3: 'POP#POPO'}), specials: {(0, 3): Special.lineH});
    expect(g.canSwap((3, 3), (4, 3)), isFalse);
    g.hammer(0, 3);
    g.advance();
    expect(g.box[3][3], 1);
  });

  test('sweets slide in from the side to fill under a box', () {
    final rows = board({2: 'GBG#GBGB', 3: 'POP.POPO', 4: 'GBG.GBGB', 5: 'POP.POPO', 6: 'GBG.GBGB', 7: 'POP.POPO'});
    final g = game(rows);
    g.hammer(0, 0);
    g.settle();
    for (var y = 3; y < 8; y++) {
      expect(g.board[y][3], isNotNull, reason: 'row $y under the box');
    }
    expect(g.box[2][3], greaterThan(0));
    final fell = g.drainEvents().whereType<SugarFell>().expand((f) => f.moves);
    expect(fell.any((m) => m.$2 != m.$4), isTrue, reason: 'some sweet moved sideways');
  });

  test('a timed bomb counts down each move and goes off at zero', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), timers: {(7, 0): 2});
    expect(g.board[0][7]!.isBomb, isTrue);
    g.swap((2, 6), (2, 7));
    g.settle();
    expect(g.board.expand((r) => r).whereType<SugarPiece>().where((p) => p.isBomb).single.timer, 1);
    expect(g.drainEvents().whereType<SugarBombTick>().single.bombs.single.$3, 1);
    expect(g.status, SugarStatus.idle);

    final last = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), timers: {(7, 0): 1});
    last.swap((2, 6), (2, 7));
    last.settle();
    expect(last.status, SugarStatus.lost);
    final events = last.drainEvents();
    expect(events.whereType<SugarBombExploded>(), hasLength(1));
    expect(events.whereType<SugarLost>().single.bomb, isTrue);
    expect(last.moves, greaterThan(0));

    // Extra moves give the bomb more time too.
    expect(last.extraMoves(3), isTrue);
    last.settle();
    expect(last.status, SugarStatus.idle);
    expect(last.board.expand((r) => r).whereType<SugarPiece>().where((p) => p.isBomb).single.timer, 3);
  });

  test('matching a timed bomb defuses it', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), timers: {(0, 7): 1});
    g.swap((2, 6), (2, 7));
    g.settle();
    expect(g.status, SugarStatus.idle);
    expect(g.board.expand((r) => r).whereType<SugarPiece>().where((p) => p.isBomb), isEmpty);
  });

  test('new timed bombs drop in every few moves', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), level: testLevel(bombEvery: 1, bombTimer: 7));
    g.swap((2, 6), (2, 7));
    g.settle();
    final bombs = g.board.expand((r) => r).whereType<SugarPiece>().where((p) => p.isBomb).toList();
    expect(bombs, hasLength(1));
    expect(bombs.single.timer, 6, reason: 'it arrives with 7 and counts this move');
  });

  test('a full sugar-rush meter sets off three specials worth double', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), level: testLevel(rush: 3));
    g.swap((2, 6), (2, 7));
    var rush = <SugarRush>[];
    var blasts = <SugarBlast>[];
    while (g.advance()) {
      final events = g.drainEvents();
      rush.addAll(events.whereType<SugarRush>());
      if (rush.isNotEmpty) blasts.addAll(events.whereType<SugarBlast>());
    }
    expect(rush.single.cells, hasLength(3));
    expect(blasts.length, greaterThanOrEqualTo(3));
    expect(g.rushMeter, lessThan(1));
    expect(g.status, SugarStatus.idle);
  });

  test('lucky refills bring specials; gifts start the board with some', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), level: testLevel(luck: 1000));
    g.swap((2, 6), (2, 7));
    g.advance();
    g.advance();
    final lucky = g.drainEvents().whereType<SugarLucky>().single;
    expect(g.board[lucky.y][lucky.x]!.special, isNot(Special.none));

    final gifts = SugarGame(seed: 4)..start(testLevel(gifts: 3));
    expect(gifts.board.expand((r) => r).whereType<SugarPiece>().where((p) => p.special != Special.none).length, greaterThanOrEqualTo(3));
  });

  test('a score-only level plays every move', () {
    final g = SugarGame(seed: 2)..start(testLevel(moves: 3, goals: [() => SugarGoal.score(10)]));
    expect(g.playsAllMoves, isTrue);
    final m = SugarSolver.best(g)!;
    g.swap(m.$1, m.$2);
    g.settle();
    expect(g.goalsDone, isTrue);
    expect(g.status, SugarStatus.idle, reason: 'goal met but moves remain');
    while (!g.isOver) {
      final m = SugarSolver.best(g);
      m == null ? g.shuffle() : g.swap(m.$1, m.$2);
      g.settle();
    }
    expect(g.status, SugarStatus.won);
    expect(g.moves, 0);
  });

  test('a score-only level goes on for its stars, then its finale fires the moves left', () {
    final g = SugarGame(seed: 2)..start(testLevel(moves: 12, goals: [() => SugarGoal.score(10)], stars: const [10, 20, 600]));
    final m = SugarSolver.best(g)!;
    g.swap(m.$1, m.$2);
    g.settle();
    expect(g.goalsDone, isTrue);
    expect(g.drainEvents().whereType<SugarGoalMet>(), hasLength(1), reason: 'the goal is in: on for the stars');
    var finale = false;
    while (!g.isOver) {
      final m = SugarSolver.best(g);
      m == null ? g.shuffle() : g.swap(m.$1, m.$2);
      g.settle();
      finale |= g.drainEvents().any((e) => e is SugarFinale);
    }
    expect(g.status, SugarStatus.won);
    expect(finale, isTrue, reason: 'the three stars came before the last move');
    expect(g.starCount, 3);
  });

  test('goals met with moves left: the finale fires them two at a time, each worth more', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), moves: 6);
    g.goals = [SugarGoal.color(SugarColor.red, 3)];
    g.swap((2, 6), (2, 7));
    final shots = <SugarFinaleShot>[];
    var finale = 0;
    var phases = 0;
    while (g.advance()) {
      final events = g.drainEvents();
      finale += events.whereType<SugarFinale>().length;
      final now = events.whereType<SugarFinaleShot>();
      expect(now.length, lessThanOrEqualTo(2));
      shots.addAll(now);
      phases++;
    }
    expect(finale, 1);
    expect(shots.map((s) => s.points), [500, 650, 800, 950, 1100]);
    expect(phases, greaterThan(5));
    expect(g.status, SugarStatus.won);
    expect(g.moves, 0);
    expect(g.board.expand((r) => r).every((p) => p == null || p.special == Special.none), isTrue);
    expect(g.drainEvents().last, isA<SugarWon>());
  });

  test('stars are announced as the score passes each step', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), level: testLevel(stars: [30, 50, 1 << 29]));
    g.swap((2, 6), (2, 7));
    g.advance();
    expect(g.drainEvents().whereType<SugarStarReached>().map((e) => e.star), [1, 2]);
  });

  test('out of moves with goals left: lost', () {
    final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), moves: 1);
    g.swap((2, 6), (2, 7));
    g.settle();
    expect(g.status, SugarStatus.lost);
    expect(g.drainEvents().last, isA<SugarLost>());
    expect(g.swap((0, 0), (1, 0)), isFalse);
  });

  test('a board with no move is shuffled into one', () {
    final g = game(board({}));
    g.colors = 4;
    expect(g.hasMove(), isFalse);
    expect(g.shuffle(), isTrue);
    g.settle();
    expect(g.hasMove(), isTrue);
    expect(g.status, SugarStatus.idle);
  });

  test('boosters: the rainbow turns a sweet into a rainbow ball; the hammer knocks a box', () {
    final g = game(board({3: 'POP#POPO'}));
    expect(g.rainbow(0, 0), isTrue);
    expect(g.board[0][0]!.isPrism, isTrue);
    expect(g.rainbow(3, 3), isFalse, reason: 'a box is not a sweet');
    expect(g.hammer(3, 3), isTrue);
    expect(g.box[3][3], 1);
    g.settle();
    expect(g.moves, 20, reason: 'boosters cost no move');
  });

  test('stars follow the level score steps once the goals are met', () {
    final level = SugarLevels.of(1);
    final g = SugarGame()..start(level);
    expect(g.starCount, 0);
    g.score = level.stars[0];
    g.goals.single.progress = g.score;
    expect(g.starCount, 1);
    g.score = level.stars[1];
    expect(g.starCount, 2);
    g.score = level.stars[2];
    expect(g.starCount, 3);
  });

  test('a saved game comes back as it was, through JSON, with boxes and bombs', () {
    final level = SugarLevels.of(50);
    final g = SugarGame(seed: 5)..start(level);
    for (var i = 0; i < 2; i++) {
      final m = SugarSolver.best(g)!;
      g.swap(m.$1, m.$2);
      g.settle();
    }
    final save = jsonDecode(jsonEncode(g.toSave())) as Map<String, Object?>;
    expect(save['level'], 50);
    final back = SugarGame()..restore(level, save);
    expect(back.debugRows(), g.debugRows());
    expect(back.ice, g.ice);
    expect(back.box, g.box);
    expect(back.moves, g.moves);
    expect(back.score, g.score);
    expect(back.rushMeter, g.rushMeter);
    expect([for (final goal in back.goals) goal.progress], [for (final goal in g.goals) goal.progress]);
    List<Object?> marks(SugarGame g) => [for (final r in g.board) for (final p in r) p == null ? null : (p.chained, p.timer, p.special)];
    expect(marks(back), marks(g));
    // The same move plays out the same way after the restore.
    final m = SugarSolver.best(g)!;
    g.swap(m.$1, m.$2);
    back.swap(m.$1, m.$2);
    g.settle();
    back.settle();
    expect(back.debugRows(), g.debugRows());
  });

  test('a copy does not share state', () {
    final g = SugarGame(seed: 3)..start(SugarLevels.of(1));
    final c = g.copy();
    final m = SugarSolver.best(c)!;
    c.swap(m.$1, m.$2);
    c.settle();
    expect(g.moves, SugarLevels.of(1).moves);
    expect(g.score, 0);
    expect(c.score, greaterThan(0));
  });

  test('levels: 180 in eighteen chapters, goals match the board, bosses and chests', () {
    expect(SugarLevels.count, 180);
    expect(SugarLevels.chapters * SugarLevels.perChapter, SugarLevels.count);
    for (final level in SugarLevels.all) {
      final cells = level.layout.join().split('');
      final ice = cells.where((c) => c == 'i' || c == 'I' || c == 'C').length;
      final boxes = cells.where((c) => c == 'K' || c == 'k').length;
      final chocolate = cells.where((c) => c == 'H').length;
      final cakes = cells.where((c) => c == 'W').length;
      final doors = cells.where((c) => '123456'.contains(c)).length;
      final fog = cells.where((c) => c == 'F').length;
      final lanterns = cells.where((c) => c == 'Q').length;
      final tunnels = cells.where((c) => c == 'X').length;
      for (final goal in level.goals.map((f) => f())) {
        if (goal.kind == GoalKind.ice) expect(goal.target, ice, reason: 'level ${level.number}');
        if (goal.kind == GoalKind.box) expect(goal.target, boxes, reason: 'level ${level.number}');
        if (goal.kind == GoalKind.color) expect(goal.color!.index, lessThan(level.colors), reason: 'level ${level.number} asks for a colour it lacks');
        // Chocolate may spread, but there must be enough to start with.
        if (goal.kind == GoalKind.choco) expect(goal.target, inInclusiveRange(1, chocolate), reason: 'level ${level.number}');
        if (goal.kind == GoalKind.cake) expect(goal.target, cakes, reason: 'level ${level.number}');
        if (goal.kind == GoalKind.door) expect(goal.target, doors, reason: 'level ${level.number}');
        if (goal.kind == GoalKind.fog) expect(goal.target, fog, reason: 'level ${level.number}');
        if (goal.kind == GoalKind.lantern) expect(goal.target, lanterns, reason: 'level ${level.number}');
        if (goal.kind == GoalKind.jam) expect(goal.target, 64 - tunnels, reason: 'level ${level.number}');
      }
      // Doors in colours the level has, and every cake whole.
      for (final c in cells.where((c) => '123456'.contains(c))) {
        expect(int.parse(c), lessThanOrEqualTo(level.colors), reason: 'level ${level.number}');
      }
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          if (level.layout[y][x] != 'W') continue;
          expect([level.layout[y][x + 1], level.layout[y + 1][x], level.layout[y + 1][x + 1]], ['w', 'w', 'w'], reason: 'level ${level.number} cake at ($x, $y)');
        }
      }
      expect(level.goals.any((f) => f().kind == GoalKind.limon), level.number == 120, reason: 'Ekşi Limon waits at the end of the first season');
      expect(level.goals.any((f) => f().kind == GoalKind.pepper), level.number > 170, reason: 'Acı Biber at the end of the second');
      // No tunnel on the top row: every column fills from the top.
      expect(level.layout[0].contains('X'), isFalse, reason: 'level ${level.number}');
      expect(level.stars[0] <= level.stars[1] && level.stars[1] <= level.stars[2], isTrue, reason: 'level ${level.number}');
      expect(level.boss, level.number % 10 == 0);
      // Every column under a box can be reached from the side.
      for (var y = 0; y < 8; y++) {
        expect(level.layout[y].replaceAll(RegExp('[^Kk]'), '').length, lessThan(8), reason: 'level ${level.number} row $y is all boxes');
      }
    }
    expect(SugarLevels.chestAt(5), isTrue);
    expect(SugarLevels.chestAt(6), isFalse);
    expect(SugarLevels.chapterOf(10), 0);
    expect(SugarLevels.chapterOf(11), 1);
    expect(SugarLevels.chapterOf(60), 5);
    expect(SugarLevels.chapterOf(120), 11);
  });

  test('the solver wins the first levels', () {
    for (final n in [1, 2, 3, 11, 31, 61, 71, 81, 91, 101]) {
      final g = SugarSolver.play(SugarLevels.of(n), 42);
      expect(g.status, SugarStatus.won, reason: 'level $n');
    }
  });

  group('the second season', () {
    // Swapping (2, 6) and (2, 7) lines up three reds on the bottom row.
    SugarGame bottomRed(void Function(SugarGame g) setUp, {List<SugarGoal>? goals}) {
      final g = game(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}));
      if (goals != null) g.goals = goals;
      setUp(g);
      expect(g.swap((2, 6), (2, 7)), isTrue);
      g.settle();
      return g;
    }

    test('fog lifts after a match beside it, a sweet under it', () {
      final g = bottomRed((g) {
        g.fog[6][0] = 1;
        g.board[6][0] = null;
      }, goals: [SugarGoal.fog(1)]);
      expect(g.fog[6][0], 0);
      expect(g.goals.single.done, isTrue);
      expect(g.board[6][0], isNotNull);
    });

    test('a gull beside a match flies off; gulls land every few moves', () {
      final g = bottomRed((g) {
        g.gull[6][1] = 1;
        g.board[6][1] = null;
      }, goals: [SugarGoal.gull(5)]);
      expect(g.gull[6][1], 0);
      expect(g.goals.single.progress, 1);
      final landing = SugarGame(seed: 3)..start(SugarLevels.of(141));
      final m = SugarSolver.best(landing)!;
      for (var i = 0; i < 3; i++) {
        final move = SugarSolver.best(landing) ?? m;
        landing.swap(move.$1, move.$2);
        landing.settle();
      }
      expect(landing.drainEvents().whereType<SugarGullsLanded>(), isNotEmpty, reason: 'every third move');
    });

    test('a lantern takes three hits to light', () {
      final g = bottomRed((g) {
        g.lantern[6][0] = 3;
        g.board[6][0] = null;
      }, goals: [SugarGoal.lantern(1)]);
      expect(g.lantern[6][0], 2);
      expect(g.goals.single.done, isFalse);
    });

    test('a match on jam spreads it over the match', () {
      final g = bottomRed((g) => g.jam[7][0] = 1, goals: [SugarGoal.jam(64)]);
      expect([for (var x = 0; x < 3; x++) g.jam[7][x]], [1, 1, 1]);
      expect(g.goals.single.progress, 3);
    });

    test('sweets fall through a tunnel and it stays empty', () {
      final g = bottomRed((g) {
        g.hole[4][0] = 1;
        g.board[4][0] = null;
      });
      expect(g.board[4][0], isNull);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          if (g.hole[y][x] == 0) expect(g.board[y][x], isNotNull, reason: '($x, $y)');
        }
      }
    });

    test('Acı Biber makes sweets hot; matches cool him down', () {
      final g = SugarGame(seed: 5)..start(SugarLevels.of(171));
      expect(g.goals.single.kind, GoalKind.pepper);
      var hot = false;
      // He throws every sixth move.
      for (var i = 0; i < 6; i++) {
        final m = SugarSolver.best(g)!;
        g.swap(m.$1, m.$2);
        g.settle();
        hot |= g.drainEvents().any((e) => e is SugarPepperThrew);
      }
      expect(hot, isTrue);
      expect(g.board.expand((r) => r).any((p) => p?.timer != null), isTrue);
      expect(g.goals.single.progress, greaterThan(0));
    });

    test('a saved game keeps the second season\'s grids', () {
      final g = SugarGame(seed: 2)..start(SugarLevels.of(151));
      final save = jsonDecode(jsonEncode(g.toSave())) as Map<String, Object?>;
      final back = SugarGame(seed: 9)..restore(SugarLevels.of(151), save);
      expect(back.jam, g.jam);
      expect(back.hole, g.hole);
    });

    test('every level lets new sweets in at the top', () {
      for (final level in SugarLevels.all) {
        final g = SugarGame(seed: 1)..start(level);
        final open = [for (var x = 0; x < SugarGame.size; x++) if (g.holds(x, 0)) x];
        expect(open.length, greaterThanOrEqualTo(2), reason: 'level ${level.number}: the top row is shut, the board would drain');
      }
    });

    test('a board too empty for any move ends, it does not shuffle for ever', () {
      final g = bottomRed((g) {
        for (var y = 0; y < 6; y++) {
          for (var x = 0; x < SugarGame.size; x++) {
            g.board[y][x] = null;
            if (y == 0) g.fog[y][x] = 1;
          }
        }
      }, goals: [SugarGoal.fog(8)]);
      expect(g.isOver || g.hasMove(), isTrue);
    });
  });
}
