import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';

/// A background with no matches and no moves among its own colours (G, B,
/// P, O); the tests put red and yellow cubes on it.
List<String> board(Map<int, String> rows) => [
  for (var y = 0; y < 8; y++) rows[y] ?? (y.isEven ? 'GBGBGBGB' : 'POPOPOPO'),
];

void main() {
  test('a level starts full, with no match and a move to make', () {
    for (final level in SugarLevels.all) {
      final g = SugarGame(seed: level.number)..start(level);
      expect(g.board.expand((r) => r).every((p) => p != null), isTrue);
      expect(g.drainEvents(), isEmpty, reason: 'nothing happens before the first move');
      expect(g.hasMove(), isTrue);
      final before = g.debugRows();
      expect(g.advance(), isFalse, reason: 'level ${level.number} has no match on the board');
      expect(g.debugRows(), before);
      expect(g.moves, level.moves);
    }
  });

  test('a swap that makes nothing is undone and costs no move', () {
    final g = SugarGame()..debugSetBoard(board({}));
    expect(g.swap((0, 0), (1, 0)), isFalse);
    expect(g.moves, 20);
    expect(g.debugRows(), board({}));
    expect(g.drainEvents().single, isA<SugarSwapRejected>());
  });

  test('three in a row clear, the column falls and refills', () {
    final g = SugarGame()..debugSetBoard(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}));
    expect(g.swap((2, 6), (2, 7)), isTrue);
    expect(g.moves, 19);
    expect(g.advance(), isTrue);
    expect([for (var x = 0; x < 3; x++) g.board[7][x]], [null, null, null]);
    expect(g.score, 3 * SugarGame.matchPoints);
    expect(g.advance(), isTrue, reason: 'gravity');
    final fell = g.drainEvents().whereType<SugarFell>().single;
    expect(fell.moves.where((m) => m.$3 < 0), hasLength(3), reason: 'three new cubes come in from above');
    g.settle();
    expect(g.board.expand((r) => r).every((p) => p != null), isTrue);
    expect(g.status, isNot(SugarStatus.resolving));
  });

  test('four in a row make a line cube where the cube was moved', () {
    final g = SugarGame()..debugSetBoard(board({6: 'GBRBGBGB', 7: 'RRYRPOPO'}));
    g.swap((2, 6), (2, 7));
    g.advance();
    final p = g.board[7][2]!;
    expect(p.special, Special.lineV);
    expect(p.color, SugarColor.red);
    expect([g.board[7][0], g.board[7][1], g.board[7][3]], [null, null, null]);
    expect(g.drainEvents().whereType<SugarCreated>().single.piece.special, Special.lineV);
  });

  test('an L makes a bomb cube, five in a row a prism', () {
    final l = SugarGame()..debugSetBoard(board({5: 'POROPOPO', 6: 'GBRBGBGB', 7: 'RRYRPOPO'}));
    l.swap((3, 7), (2, 7));
    l.advance();
    expect(l.board[7][2]!.special, Special.bomb);
    expect([l.board[5][2], l.board[6][2], l.board[7][0]], [null, null, null]);

    final five = SugarGame()..debugSetBoard(board({6: 'GBRBGBGB', 7: 'RRYRROPO'}));
    five.swap((2, 6), (2, 7));
    five.advance();
    expect(five.board[7][2]!.special, Special.prism);
  });

  test('a line cube fires along its row when hit', () {
    final g = SugarGame()..debugSetBoard(board({}), specials: {(3, 3): Special.lineH});
    expect(g.hammer(3, 3), isTrue);
    g.drainEvents();
    expect(g.advance(), isTrue);
    final blast = g.drainEvents().whereType<SugarBlast>().single;
    expect(blast.kind, Special.lineH);
    expect(blast.cells, hasLength(8));
    expect(g.board[3].every((p) => p == null), isTrue);
  });

  test('a bomb clears the 3x3 around it', () {
    final g = SugarGame()..debugSetBoard(board({}), specials: {(4, 4): Special.bomb});
    g.hammer(4, 4);
    g.advance();
    for (var y = 3; y <= 5; y++) {
      for (var x = 3; x <= 5; x++) {
        expect(g.board[y][x], isNull);
      }
    }
    expect(g.board[2][4], isNotNull);
  });

  test('a prism swapped with a cube takes every cube of that colour', () {
    final g = SugarGame()..debugSetBoard(board({}), specials: {(3, 3): Special.prism});
    g.goals = [SugarGoal.color(SugarColor.purple, 10)];
    expect(g.swap((3, 3), (4, 3)), isTrue);
    final cleared = g.drainEvents().whereType<SugarCleared>().single;
    expect(cleared.pieces, hasLength(16));
    expect(cleared.pieces.every((c) => c.$3.color == SugarColor.purple), isTrue);
    expect(g.goals.single.done, isTrue);
    expect(g.board.expand((r) => r).where((p) => p?.color == SugarColor.purple), isEmpty);
  });

  test('two specials swapped together combine', () {
    final lines = SugarGame()..debugSetBoard(board({}), specials: {(3, 3): Special.lineH, (4, 3): Special.lineV});
    lines.swap((3, 3), (4, 3));
    final blast = lines.drainEvents().whereType<SugarBlast>().first;
    expect(blast.cells, hasLength(15), reason: 'a row and a column');

    final bombs = SugarGame()..debugSetBoard(board({}), specials: {(3, 3): Special.bomb, (3, 4): Special.bomb});
    bombs.swap((3, 3), (3, 4));
    expect(bombs.drainEvents().whereType<SugarBlast>().first.cells, hasLength(25), reason: 'a 5x5');

    final prisms = SugarGame()..debugSetBoard(board({}), specials: {(3, 3): Special.prism, (3, 4): Special.prism});
    prisms.swap((3, 3), (3, 4));
    expect(prisms.board.expand((r) => r).every((p) => p == null), isTrue, reason: 'two prisms clear the board');
  });

  test('chained cubes do not move; a match frees them', () {
    final g = SugarGame()..debugSetBoard(board({6: 'GBRBGBGB', 7: 'RrYOPOPO'}));
    expect(g.canSwap((1, 7), (1, 6)), isFalse);
    expect(g.swap((2, 6), (2, 7)), isTrue);
    g.advance();
    expect(g.board[7][1], isNotNull);
    expect(g.board[7][1]!.chained, isFalse);
    expect(g.board[7][0], isNull);
    expect(g.drainEvents().whereType<SugarUnchained>(), hasLength(1));
  });

  test('ice cracks under a cleared cube; thick ice takes two', () {
    final g = SugarGame()..debugSetBoard(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), iceAt: {(0, 7): 1, (1, 7): 2});
    g.goals = [SugarGoal.ice(2)];
    g.swap((2, 6), (2, 7));
    g.advance();
    expect(g.ice[7][0], 0);
    expect(g.ice[7][1], 1);
    expect(g.goals.single.progress, 1);
    expect(g.iceLeft, 1);
  });

  test('goals met with moves left: the finale fires a line cube per move', () {
    final g = SugarGame()..debugSetBoard(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), moves: 4);
    g.goals = [SugarGoal.score(1)];
    g.swap((2, 6), (2, 7));
    g.settle();
    final events = g.drainEvents();
    expect(events.whereType<SugarFinale>().single.moves, 3);
    expect(events.whereType<SugarBlast>().where((b) => b.kind == Special.lineH || b.kind == Special.lineV).length, greaterThanOrEqualTo(3));
    expect(g.status, SugarStatus.won);
    expect(g.moves, 0);
    expect(g.board.expand((r) => r).every((p) => p != null && p.special == Special.none), isTrue);
    expect(events.last, isA<SugarWon>());
  });

  test('out of moves with goals left: lost', () {
    final g = SugarGame()..debugSetBoard(board({6: 'GBRBGBGB', 7: 'RRPOPOPO'}), moves: 1);
    g.goals = [SugarGoal.score(1 << 30)];
    g.swap((2, 6), (2, 7));
    g.settle();
    expect(g.status, SugarStatus.lost);
    expect(g.drainEvents().last, isA<SugarLost>());
    expect(g.swap((0, 0), (1, 0)), isFalse);
  });

  test('a board with no move is shuffled into one', () {
    final g = SugarGame()..debugSetBoard(board({}));
    g.goals = [SugarGoal.score(1 << 30)];
    expect(g.hasMove(), isFalse);
    g.colors = 4;
    expect(g.shuffle(), isTrue);
    g.settle();
    expect(g.hasMove(), isTrue);
    expect(g.status, SugarStatus.idle);
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

  test('a saved game comes back as it was, through JSON', () {
    final level = SugarLevels.of(30);
    final g = SugarGame(seed: 5)..start(level);
    for (var i = 0; i < 2; i++) {
      final m = SugarSolver.best(g)!;
      g.swap(m.$1, m.$2);
      g.settle();
    }
    final save = jsonDecode(jsonEncode(g.toSave())) as Map<String, Object?>;
    expect(save['level'], 30);
    final back = SugarGame()..restore(level, save);
    expect(back.debugRows(), g.debugRows());
    expect(back.ice, g.ice);
    expect(back.moves, g.moves);
    expect(back.score, g.score);
    expect([for (final goal in back.goals) goal.progress], [for (final goal in g.goals) goal.progress]);
    expect([for (final r in back.board) for (final p in r) p!.chained], [for (final r in g.board) for (final p in r) p!.chained]);
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

  test('levels: thirty, ice goals match the ice on the board, bosses and chests', () {
    expect(SugarLevels.count, 30);
    for (final level in SugarLevels.all) {
      final ice = level.layout.join().split('').where((c) => c == 'i' || c == 'I' || c == 'C').length;
      for (final goal in level.goals.map((f) => f())) {
        if (goal.kind == GoalKind.ice) expect(goal.target, ice, reason: 'level ${level.number}');
        if (goal.kind == GoalKind.color) expect(goal.color!.index, lessThan(level.colors), reason: 'level ${level.number} asks for a colour it lacks');
      }
      expect(level.stars[0] <= level.stars[1] && level.stars[1] <= level.stars[2], isTrue);
      expect(level.boss, level.number % 10 == 0);
    }
    expect(SugarLevels.chestAt(5), isTrue);
    expect(SugarLevels.chestAt(6), isFalse);
    expect(SugarLevels.chapterOf(10), 0);
    expect(SugarLevels.chapterOf(11), 1);
  });

  test('the solver wins the first levels', () {
    for (final n in [1, 2, 3, 11, 21]) {
      final g = SugarSolver.play(SugarLevels.of(n), 42);
      expect(g.status, SugarStatus.won, reason: 'level $n');
    }
  });
}
