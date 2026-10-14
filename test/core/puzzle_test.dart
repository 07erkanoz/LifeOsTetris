import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/puzzle_generator.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';

void main() {
  test('difficulty grows from one piece to a dozen across 100 levels', () {
    final first = PuzzleGenerator.specFor(1), last = PuzzleGenerator.specFor(PuzzleGenerator.levelCount);
    expect(first.pieces, 1);
    expect(last.pieces, 12);
    for (var n = 2; n <= PuzzleGenerator.levelCount; n++) {
      expect(PuzzleGenerator.specFor(n).pieces, greaterThanOrEqualTo(PuzzleGenerator.specFor(n - 1).pieces));
    }
  });

  test('every level generates a verified, solvable puzzle', () {
    final rng = Random(7);
    for (var n = 1; n <= PuzzleGenerator.levelCount; n++) {
      final level = PuzzleGenerator.generate(n, random: rng);
      expect(level.number, n);
      expect(level.gemCount, greaterThan(0));
      expect(PuzzleGenerator.verify(level), isTrue, reason: 'level $n');
    }
  });

  test('the same level is a different board each time', () {
    final a = PuzzleGenerator.generate(40, random: Random(1));
    final b = PuzzleGenerator.generate(40, random: Random(2));
    expect(a.rows.join(), isNot(b.rows.join()));
  });

  test('solving with two spare pieces left earns three stars', () {
    final level = PuzzleGenerator.generate(5, random: Random(3));
    final game = TetrisGame()..startPuzzle(level);
    for (final (_, rot, x) in level.solution) {
      for (var i = 0; i < rot.index; i++) {
        game.rotateClockwise();
      }
      while (game.active!.x < x) {
        game.moveRight();
      }
      while (game.active!.x > x) {
        game.moveLeft();
      }
      game.hardDrop();
      if (game.status == GameStatus.clearing) game.update(1);
    }
    final solved = game.drainEvents().whereType<PuzzleSolved>().single;
    expect(solved.piecesLeft, 2);
    expect(solved.stars, 3);
  });

  test('running out of pieces fails the puzzle', () {
    const level = PuzzleLevel(number: 1, rows: ['**.....JJJ'], pieces: 'O', solution: []);
    final game = TetrisGame()..startPuzzle(level);
    game.hardDrop();
    expect(game.drainEvents().whereType<PuzzleFailed>(), hasLength(1));
    expect(game.status, GameStatus.over);
    expect(game.puzzleSolved, isFalse);
  });

  test('puzzle pieces never fall by themselves', () {
    final game = TetrisGame()..startPuzzle(PuzzleGenerator.generate(3, random: Random(4)));
    final y = game.active!.y;
    game.update(30);
    expect(game.active!.y, y);
  });
}
