import 'dart:math';

import 'tetris_game.dart';

/// Builds "Bulmaca Küpler" levels on the fly, so a level is a different
/// board every time it is played while its difficulty stays the same.
///
/// Boards are made backwards ("carving"): start from full rows and cut out
/// tetrominoes that could have been hard-dropped into their spots. Replaying
/// the cuts in reverse is a solution. Every candidate is then replayed
/// through the real game engine with player-like inputs and only accepted if
/// it clears every gem, so a generated puzzle is always solvable.
class PuzzleGenerator {
  static const int levelCount = 100;
  static const int levelsPerChapter = 10;

  static const int _w = TetrisGame.width;
  static const int _h = TetrisGame.height;

  /// Difficulty of [level] (1..[levelCount]): rows, pieces and gems.
  static ({int rows, int pieces, int gems}) specFor(int level) {
    final n = level.clamp(1, levelCount);
    final pieces = 1 + ((n - 1) * 11 / (levelCount - 1)).round();
    final rows = max(1, ((4 * pieces + 2 + n / 10) / 10).ceil());
    final free = rows * _w - 4 * pieces;
    final gems = min(free, 2 + n ~/ 9);
    return (rows: rows, pieces: pieces, gems: gems);
  }

  /// A fresh, verified-solvable board for [level].
  static PuzzleLevel generate(int level, {Random? random}) {
    final rng = random ?? Random();
    final spec = specFor(level);
    for (var attempt = 0; attempt < 400; attempt++) {
      final candidate = _build(level, spec.rows, spec.pieces, spec.gems, rng);
      if (candidate != null && verify(candidate)) return candidate;
    }
    // Practically unreachable; fall back to an easier board of the same level.
    for (var pieces = spec.pieces - 1; pieces >= 1; pieces--) {
      final rows = max(1, ((4 * pieces + 2) / 10).ceil());
      final candidate = _build(level, rows, pieces, 2, rng);
      if (candidate != null && verify(candidate)) return candidate;
    }
    throw StateError('Could not build puzzle $level');
  }

  static PuzzleLevel? _build(int number, int rowCount, int pieceCount, int gemCount, Random rng) {
    final top = _h - rowCount;
    final board = List.generate(_h, (y) => List<String?>.generate(_w, (_) => y >= top ? 'IOTSZJL'[rng.nextInt(7)] : null));
    final cuts = <(PieceType, Rotation, int, List<Cell>)>[];

    for (var k = 0; k < pieceCount; k++) {
      final options = <(PieceType, Rotation, int, List<Cell>)>[];
      for (final type in standardPieces) {
        for (final rot in Rotation.values) {
          // O looks the same in every rotation; one is enough.
          if (type == PieceType.o && rot != Rotation.spawn) continue;
          for (var x = -3; x < _w; x++) {
            for (var y = top - 3; y < _h; y++) {
              final cells = [for (final c in shapeOf(type, rot)) Cell(x + c.x, y + c.y)];
              if (cells.any((c) => c.x < 0 || c.x >= _w || c.y < top || c.y >= _h)) continue;
              if (cells.any((c) => board[c.y][c.x] == null)) continue;
              if (_droppable(board, cells)) options.add((type, rot, x, cells));
            }
          }
        }
      }
      if (options.isEmpty) return null;
      final varied = cuts.isEmpty ? options : options.where((o) => o.$1 != cuts.last.$1).toList();
      final pool = varied.isEmpty ? options : varied;
      final pick = pool[rng.nextInt(pool.length)];
      for (final c in pick.$4) {
        board[c.y][c.x] = null;
      }
      cuts.add(pick);
    }

    // Gems go on blocks that stay on the board, never on carved cells.
    final solid = [
      for (var y = top; y < _h; y++)
        for (var x = 0; x < _w; x++)
          if (board[y][x] != null) Cell(x, y),
    ]..shuffle(rng);
    if (solid.length < gemCount) return null;
    for (final c in solid.take(gemCount)) {
      board[c.y][c.x] = '*';
    }

    final moves = [for (final cut in cuts.reversed) (cut.$1, cut.$2, cut.$3)];
    // Two spare pieces after the solution earn the extra stars.
    final spares = [for (var s = 0; s < 2; s++) standardPieces[rng.nextInt(standardPieces.length)]];
    final pieces = [...moves.map((m) => m.$1), ...spares].map((t) => t.name.toUpperCase()).join();
    return PuzzleLevel(
      number: number,
      rows: [for (var y = top; y < _h; y++) board[y].map((c) => c ?? '.').join()],
      pieces: pieces,
      solution: moves,
    );
  }

  /// True if a piece occupying [cells] could have been hard-dropped there:
  /// nothing above it in its columns, and something (or the floor) under it.
  static bool _droppable(List<List<String?>> board, List<Cell> cells) {
    final own = cells.toSet();
    for (final c in cells) {
      for (var y = 0; y < c.y; y++) {
        if (board[y][c.x] != null && !own.contains(Cell(c.x, y))) return false;
      }
    }
    return cells.any((c) => c.y == _h - 1 || (board[c.y + 1][c.x] != null && !own.contains(Cell(c.x, c.y + 1))));
  }

  /// Plays [level]'s solution like a player (rotate, shift, hard drop) and
  /// reports whether every gem was cleared.
  static bool verify(PuzzleLevel level) {
    final game = TetrisGame()..startPuzzle(level);
    for (final (type, rot, x) in level.solution) {
      if (game.status != GameStatus.playing || game.active?.type != type) return false;
      for (var i = 0; i < rot.index; i++) {
        if (!game.rotateClockwise()) return false;
      }
      var guard = 0;
      while (game.active!.x < x && guard++ < 12) {
        if (!game.moveRight()) return false;
      }
      while (game.active!.x > x && guard++ < 24) {
        if (!game.moveLeft()) return false;
      }
      if (game.active!.x != x) return false;
      game.hardDrop();
      if (game.status == GameStatus.clearing) game.update(TetrisGame.lineClearDelay + 0.01);
    }
    return game.puzzleSolved;
  }
}
