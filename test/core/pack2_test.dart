import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/blocks/adventure.dart';
import 'package:lifeos_kupler/core/blocks/block_puzzle.dart';
import 'package:lifeos_kupler/core/blocks/level_generator.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';

const _empty = '........';

void main() {
  group('Bomba', () {
    test('the first bomb appears on the second placement with a full fuse', () {
      final game = BlockPuzzleGame()..startBombs(random: Random(3));
      game.debugSetTray(['dot', 'dot', 'dot']);
      game.place(0, 0, 0);
      expect(game.bombCells, isEmpty);
      game.place(1, 2, 0);
      expect(game.bombCells.single.$2, 9);
      expect(game.drainEvents().whereType<BombPlanted>(), hasLength(1));
    });

    test('a bomb burns down one step per placement and ends the game', () {
      final game = BlockPuzzleGame()..startEndless(random: Random(1));
      game.debugSetBoard(['2.......', for (var i = 0; i < 7; i++) _empty]);
      game.debugSetTray(['dot', 'dot', 'dot']);
      game.place(0, 7, 7);
      expect(game.bombCells.single.$2, 1);
      expect(game.status, BlockStatus.playing);
      game.place(1, 6, 7);
      expect(game.status, BlockStatus.lost);
      expect(game.loss, BlockLoss.bomb);
      expect(game.drainEvents().whereType<BombWentOff>().single.cell, const Cell(0, 0));
    });

    test('clearing its line defuses a bomb', () {
      final game = BlockPuzzleGame()..startEndless(random: Random(1));
      game.debugSetBoard(['3TTTTTT.', for (var i = 0; i < 7; i++) _empty]);
      game.debugSetTray(['dot', 'dot', 'dot']);
      game.place(0, 7, 0);
      expect(game.bombCells, isEmpty);
      expect(game.bombsDefused, 1);
      final blast = game.drainEvents().whereType<LinesBlasted>().single;
      expect(blast.bombs.single, const Cell(0, 0));
      expect(game.status, BlockStatus.playing);
    });

    test('bombs and their fuses survive saving', () {
      final game = BlockPuzzleGame()..startBombs(random: Random(4));
      game.debugSetBoard(['7.......', '...4....', for (var i = 0; i < 6; i++) _empty]);
      final copy = BlockPuzzleGame()..restore(game.toSave());
      expect(copy.bombs, isTrue);
      expect(copy.bombCells.map((b) => (b.$1, b.$2)), [(const Cell(0, 0), 7), (const Cell(3, 1), 4)]);
    });
  });

  group('Macera', () {
    test('levels are the same every time and solvable, bombs from chapter 3', () {
      for (final n in [1, 14, 25, 62, 97]) {
        final a = Adventure.level(n), b = Adventure.level(n);
        expect(a.rows, b.rows, reason: 'level $n');
        expect(a.pieces, b.pieces);
        expect(BlockSolver.solve(a), isNotNull, reason: 'level $n');
        final bombs = a.rows.join().split('').where((c) => '123456789'.contains(c)).length;
        expect(bombs, Adventure.specFor(n).bombs, reason: 'level $n');
      }
      expect(Adventure.specFor(15).bombs, 0);
      expect(Adventure.specFor(95).bombs, 2);
    });

    test('the ten levels of a chapter uncover ten different tiles', () {
      for (var chapter = 1; chapter <= Adventure.chapters; chapter++) {
        final tiles = {for (var step = 0; step < Adventure.perChapter; step++) Adventure.tileFor(chapter, step)};
        expect(tiles, hasLength(10));
      }
      for (final picture in Adventure.pictures) {
        expect(picture, hasLength(Adventure.pictureSize));
        for (final row in picture) {
          expect(row, hasLength(Adventure.pictureSize));
          expect(row, matches(RegExp(r'^[.IOTSZJLM]+$')));
        }
      }
    });
  });

  group('Hedef', () {
    test('starts with grey rows holding three stars and a minute', () {
      final game = TetrisGame()..start(seed: 5, mode: GameMode.target);
      expect(game.starsOnBoard, GameMode.targetStars);
      expect(game.targetTimeLeft, GameMode.targetSeconds);
      game.update(1);
      expect(game.targetTimeLeft, closeTo(59, 1e-9));
    });

    test('clearing stars adds time and new star rows rise', () {
      final game = TetrisGame()..start(seed: 6, mode: GameMode.target);
      game.debugSetBoard(['MMMM*MMMM.', 'MM*MMMMMM.', 'MMMMMMMMM.', 'MMMMMMM*M.']);
      game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
      game.hardDrop();
      final collected = game.drainEvents().whereType<StarsCollected>().single;
      expect(collected.cells, hasLength(3));
      expect(collected.seconds, 3 * GameMode.targetBonus);
      expect(game.stars, 3);
      game.update(TetrisGame.lineClearDelay + 0.01);
      expect(game.starsOnBoard, GameMode.targetStars);
      expect(game.targetTimeLeft, closeTo(GameMode.targetSeconds + 15 - game.time, 1e-9));
      expect(game.status, GameStatus.playing);
    });

    test('the run ends when the clock runs out', () {
      final game = TetrisGame()..start(seed: 7, mode: GameMode.target);
      game.time = GameMode.targetSeconds - 0.05;
      game.update(0.1);
      expect(game.status, GameStatus.over);
      expect(game.won, isTrue);
      expect(game.targetTimeLeft, 0);
    });
  });

  group('Kaos', () {
    test('a surprise strikes every twenty seconds, never the same twice', () {
      final game = TetrisGame()..start(seed: 8, mode: GameMode.chaos);
      final seen = <ChaosEvent>[];
      for (var i = 0; i < 6 && game.status != GameStatus.over; i++) {
        game.debugSetBoard(const []);
        game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 3, 2));
        game.update(0.01);
        // Sit on the floor of an empty board without locking.
        while (game.chaosIn > 0.05) {
          game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 3, 2));
          game.update(0.04);
        }
        game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 3, 2));
        game.update(0.06);
        seen.addAll(game.drainEvents().whereType<ChaosStarted>().map((e) => e.type));
      }
      expect(seen, hasLength(greaterThanOrEqualTo(5)));
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], isNot(seen[i - 1]));
      }
    });

    test('each surprise does its thing', () {
      final game = TetrisGame()..start(seed: 9, mode: GameMode.chaos);
      game.debugSetBoard(['....T.....', '..........', 'JJJJJ.JJJJ']);
      game.triggerChaos(ChaosEvent.quake);
      expect(game.cellAt(4, TetrisGame.height - 2), PieceType.t, reason: 'the floating block dropped');

      game.triggerChaos(ChaosEvent.rise);
      expect(game.cellAt(0, TetrisGame.height - 1), anyOf(PieceType.mono, isNull));
      expect(game.board.last.where((c) => c == null), hasLength(1));

      game.triggerChaos(ChaosEvent.fog);
      expect(game.fog, ChaosEvent.fogSeconds);
      game.triggerChaos(ChaosEvent.rush);
      expect(game.rush, ChaosEvent.rushSeconds);

      game.triggerChaos(ChaosEvent.gift);
      expect(game.active!.type, PieceType.bomb);
    });

    test('fog, rush and the countdown are saved', () {
      final game = TetrisGame()..start(seed: 10, mode: GameMode.chaos);
      game.triggerChaos(ChaosEvent.fog);
      game.update(2);
      final copy = TetrisGame()..restore(game.toSave());
      expect(copy.fog, closeTo(game.fog, 1e-9));
      expect(copy.chaosIn, closeTo(game.chaosIn, 1e-9));
      expect(copy.lastChaos, ChaosEvent.fog);
    });
  });
}
