import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/blocks/block_puzzle.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/game/blocks/blocks_controller.dart';
import 'package:lifeos_kupler/settings/settings.dart';

/// Drops a vertical I into the gap of the bottom row and lets it clear.
void _clearBottomRow(TetrisGame game) {
  game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
  game.hardDrop();
  game.update(TetrisGame.lineClearDelay + 0.01);
}

void main() {
  test('Hız Koşusu ends, won, on the 40th line', () {
    final game = TetrisGame()..start(seed: 1, mode: GameMode.sprint);
    game.update(12.5);
    game.lines = GameMode.sprintLines - 1;
    game.debugSetBoard(['JJJJJJJJJ.']);
    expect(game.sprintLinesLeft, 1);
    _clearBottomRow(game);
    expect(game.status, GameStatus.over);
    expect(game.won, isTrue);
    expect(game.drainEvents().whereType<GameOver>().single.won, isTrue);
    expect(game.time, greaterThan(12));
  });

  test('3 Dakika stops at three minutes with the score kept', () {
    final game = TetrisGame()..start(seed: 2, mode: GameMode.ultra);
    game.update(0.5);
    expect(game.ultraTimeLeft, closeTo(179.5, 1e-9));
    game.time = 179.8;
    game.update(0.1);
    expect(game.status, GameStatus.playing);
    game.update(0.2);
    expect(game.status, GameStatus.over);
    expect(game.won, isTrue);
    expect(game.time, GameMode.ultraSeconds);
    expect(game.ultraTimeLeft, 0);
  });

  test('Kazı starts on ten grey rows with one hole each and ends when they are gone', () {
    final game = TetrisGame()..start(seed: 3, mode: GameMode.dig);
    expect(game.garbageLeft, GameMode.digRows);
    for (var i = 0; i < GameMode.digRows; i++) {
      final row = game.board[TetrisGame.height - 1 - i];
      expect(row.where((c) => c == null), hasLength(1));
    }

    // One grey row left, its hole in the last column.
    final save = game.toSave();
    final board = [
      for (var y = 0; y < TetrisGame.height; y++)
        [for (var x = 0; x < TetrisGame.width; x++) y == TetrisGame.height - 1 && x < 9 ? 'mono' : null],
    ];
    game.restore({...save, 'board': board});
    expect(game.garbageLeft, 1);
    _clearBottomRow(game);
    expect(game.garbageLeft, 0);
    expect(game.won, isTrue);
    expect(game.status, GameStatus.over);
  });

  test('a challenge lost by topping out is not won', () {
    final game = TetrisGame()..start(seed: 4, mode: GameMode.sprint);
    for (var i = 0; i < 400 && game.status != GameStatus.over; i++) {
      game.hardDrop();
      game.update(1);
    }
    expect(game.status, GameStatus.over);
    expect(game.won, isFalse);
  });

  test('timed records keep the fastest finished run only', () {
    final s = Settings.memory();
    expect(s.recordGame(mode: GameMode.sprint, score: 900, lines: 12, seconds: 50, won: false), isFalse);
    expect(s.bestTime(GameMode.sprint), isNull);
    expect(s.recordGame(mode: GameMode.sprint, score: 900, lines: 40, seconds: 95.4, won: true), isTrue);
    expect(s.recordGame(mode: GameMode.sprint, score: 900, lines: 40, seconds: 101, won: true), isFalse);
    expect(s.recordGame(mode: GameMode.sprint, score: 900, lines: 40, seconds: 88.2, won: true), isTrue);
    expect(s.bestTime(GameMode.sprint), 88.2);
    expect(s.recordGame(mode: GameMode.ultra, score: 5000, lines: 20, seconds: 180, won: true), isTrue);
    expect(s.bestScore(GameMode.ultra), 5000);
  });

  test('the daily puzzle is the same board for everyone on a day', () {
    final day = DateTime(2026, 10, 15);
    final a = BlocksController.dailyLevel(day), b = BlocksController.dailyLevel(day);
    expect(a.rows, b.rows);
    expect(a.pieces, b.pieces);
    expect(a.moveLimit, b.moveLimit);
    final other = BlocksController.dailyLevel(DateTime(2026, 10, 16));
    expect(other.rows, isNot(a.rows));
    // And it is solvable like every level.
    final game = BlockPuzzleGame()..startLevel(a);
    expect(game.gemsLeft, a.gemCount);
  });

  test('the daily streak counts solved days in a row', () {
    final s = Settings.memory();
    final today = DateTime(2026, 10, 15);
    expect(s.dailyStreak(today), 0);
    s.recordDaily(DateTime(2026, 10, 13), 2);
    s.recordDaily(DateTime(2026, 10, 14), 3);
    // Today's is still open: yesterday's streak counts.
    expect(s.dailyStreak(today), 2);
    s.recordDaily(today, 1);
    expect(s.dailyStreak(today), 3);
    expect(s.dailyStars(today), 1);
    s.recordDaily(today, 3);
    expect(s.dailyStars(today), 3);
    // A gap breaks it.
    expect(s.dailyStreak(DateTime(2026, 10, 17)), 0);
  });
}
