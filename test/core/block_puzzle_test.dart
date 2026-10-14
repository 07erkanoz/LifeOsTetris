import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/blocks/block_puzzle.dart';
import 'package:lifeos_kupler/core/blocks/level_generator.dart';

const _empty = ['........', '........', '........', '........', '........', '........', '........', '........'];

void main() {
  group('shapes', () {
    test('every shape is unique and fits the board', () {
      final ids = blockShapes.map((s) => s.id).toSet();
      expect(ids, hasLength(blockShapes.length));
      for (final s in blockShapes) {
        expect(s.width, inInclusiveRange(1, 5));
        expect(s.height, inInclusiveRange(1, 5));
        final cells = s.cells.map((c) => (c.x, c.y)).toSet();
        expect(cells, hasLength(s.size), reason: s.id);
      }
    });
  });

  group('placing', () {
    test('a piece goes where it fits and nowhere else', () {
      final game = BlockPuzzleGame()..startEndless(random: Random(1));
      game.debugSetBoard(['T.......', ..._empty.skip(1)]);
      game.debugSetTray(['o2', 'dot', 'i5h']);
      expect(game.place(0, 0, 0), isFalse, reason: 'overlaps a block');
      expect(game.place(2, 4, 0), isFalse, reason: 'sticks out of the board');
      expect(game.place(0, 1, 0), isTrue);
      expect(game.cellAt(1, 0)?.color, isNotNull);
      expect(game.tray[0], isNull);
      expect(game.score, 4);
      expect(game.moves, 1);
    });

    test('full rows and columns blast together and score with the streak', () {
      final game = BlockPuzzleGame()..startEndless(random: Random(2));
      game.debugSetBoard(['.TTTTTTT', 'T.......', 'T.......', 'T.......', 'T.......', 'T.......', 'T.......', 'T.......']);
      game.debugSetTray(['dot', 'o2', 'o2']);
      expect(game.place(0, 0, 0), isTrue);
      final blast = game.drainEvents().whereType<LinesBlasted>().single;
      expect(blast.rows, [0]);
      expect(blast.columns, [0]);
      expect(blast.cells, hasLength(15));
      expect(blast.perfect, isTrue);
      expect(blast.streak, 1);
      // 1 placed cell + 2 lines (10 * 2 * 3 / 2 = 30) + perfect 300.
      expect(game.score, 1 + 30 + 300);
      expect(game.board.every((r) => r.every((c) => c == null)), isTrue);
    });

    test('the streak grows while clears keep coming and resets after three dry moves', () {
      final game = BlockPuzzleGame()..startEndless(random: Random(3));
      game.debugSetBoard(['.TTTTTTT', '.TTTTTTT', ..._empty.skip(2)]);
      game.debugSetTray(['dot', 'dot', 'dot']);
      game.place(0, 0, 0);
      expect(game.streak, 1);
      game.place(1, 0, 1);
      expect(game.streak, 2);
      game.debugSetTray(['dot', 'dot', 'dot']);
      game.place(0, 7, 7);
      game.place(1, 6, 7);
      game.place(2, 5, 7);
      expect(game.streak, 0);
    });

    test('preview reports the lines a placement would complete', () {
      final game = BlockPuzzleGame()..startEndless(random: Random(4));
      game.debugSetBoard(['..TTTTTT', ..._empty.skip(1)]);
      final (rows, columns) = game.clearsFor(shapeById('i2h'), 0, 0);
      expect(rows, [0]);
      expect(columns, isEmpty);
    });

    test('endless trays always offer a piece that fits', () {
      final rng = Random(5);
      for (var i = 0; i < 20; i++) {
        final game = BlockPuzzleGame()..startEndless(random: rng);
        expect(game.tray.whereType<BlockShape>().any(game.fitsAnywhere), isTrue);
      }
    });

    test('the game ends when no piece fits', () {
      final game = BlockPuzzleGame()..startEndless(random: Random(7));
      game.debugSetBoard(['TT.TT.TT', 'T.TT.TT.', '.TT.TT.T', 'TT.TT.TT', 'T.TT.TT.', '.TT.TT.T', 'TT.TT.TT', 'T.TT.TT.']);
      game.debugSetTray(['dot', 'o2', null]);
      expect(game.place(0, 2, 0), isTrue);
      expect(game.status, BlockStatus.lost);
      expect(game.loss, BlockLoss.noRoom);
      expect(game.drainEvents().whereType<BlocksGameOver>(), hasLength(1));
    });
  });

  group('levels', () {
    test('collecting every star wins, with stars for spare moves', () {
      final level = BlockLevel(
        number: 1,
        rows: ['*TTTTTT.', ..._empty.skip(1)],
        pieces: ['dot', 'o2', 'o2', 'o2', 'o2', 'o2'],
        moveLimit: 5,
        par: 1,
      );
      final game = BlockPuzzleGame()..startLevel(level);
      expect(game.gemsLeft, 1);
      expect(game.place(0, 7, 0), isTrue);
      expect(game.status, BlockStatus.won);
      final won = game.drainEvents().whereType<LevelWon>().single;
      expect(won.stars, 3);
      expect(won.movesLeft, 4);
      expect(level.starsFor(2), 3 - 1);
      expect(level.starsFor(5), 1);
    });

    test('running out of moves loses the level', () {
      final level = BlockLevel(number: 1, rows: ['*.......', ..._empty.skip(1)], pieces: ['dot', 'dot', 'dot'], moveLimit: 1, par: 1);
      final game = BlockPuzzleGame()..startLevel(level);
      game.place(0, 5, 5);
      expect(game.status, BlockStatus.lost);
      expect(game.loss, BlockLoss.outOfMoves);
    });

    test('difficulty rises through the levels', () {
      final first = BlockLevels.specFor(1), last = BlockLevels.specFor(100);
      expect(first.gems, lessThan(last.gems));
      expect(first.fill, lessThan(last.fill));
      expect(first.slack, greaterThan(last.slack));
    });

    test('every generated level is solvable and boards differ each time', () {
      final rng = Random(42);
      for (final n in [1, 2, 5, 10, 25, 50, 75, 99, 100]) {
        final a = BlockLevels.generate(n, random: rng);
        final b = BlockLevels.generate(n, random: rng);
        expect(a.rows, isNot(b.rows), reason: 'level $n repeats');
        for (final level in [a, b]) {
          expect(level.gemCount, BlockLevels.specFor(n).gems, reason: 'level $n');
          expect(level.moveLimit, greaterThan(level.par));
          final solution = BlockSolver.solve(level, maxMoves: level.moveLimit);
          expect(solution, isNotNull, reason: 'level $n is not solvable');
          expect(solution!.length, lessThanOrEqualTo(level.par));
          expect(level.pieces.length, greaterThanOrEqualTo(level.moveLimit));
        }
      }
    });
  });
}
