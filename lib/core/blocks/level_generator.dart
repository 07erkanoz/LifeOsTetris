import 'dart:math';

import 'block_puzzle.dart';

/// One placement: tray slot and top-left board position.
typedef BlockMove = (int slot, int x, int y);

/// Builds the 100 levels of "Bulmaca Küpler" on the fly, so a level is a
/// fresh board every time while its difficulty stays the same.
///
/// A candidate level (a board with ★ blocks and the exact list of pieces to
/// be dealt) is only accepted after [BlockSolver] has played it through the
/// real game and collected every ★. Since the pieces are fixed, the player
/// can always do at least as well: every level is solvable.
class BlockLevels {
  static const int count = 100;
  static const int perChapter = 10;
  static const int _n = BlockPuzzleGame.size;

  /// Difficulty of level [n]: ★ count, how full the board starts, how many
  /// spare moves the limit allows over the reference solution, and how often
  /// awkward pieces are dealt (0..1).
  static ({int gems, double fill, int slack, double awkward}) specFor(int n) {
    final k = (n.clamp(1, count) - 1) / (count - 1);
    return (gems: 2 + (k * 10).round(), fill: 0.16 + 0.3 * k, slack: max(2, (8 - k * 6).round()), awkward: 0.05 + 0.6 * k);
  }

  /// Rough number of moves the reference solution should need.
  static (int, int) _targetMoves(int n) {
    final lo = 2 + n ~/ 7;
    return (lo, lo + 6 + n ~/ 12);
  }

  static BlockLevel generate(int number, {Random? random}) {
    final rng = random ?? Random();
    final spec = specFor(number);
    final (lo, hi) = _targetMoves(number);
    BlockLevel? best;
    var bestMiss = 1 << 30;
    for (var attempt = 0; attempt < 24; attempt++) {
      final candidate = _candidate(number, spec, rng);
      if (candidate == null) continue;
      final par = candidate.par;
      final miss = par < lo ? lo - par : (par > hi ? par - hi : 0);
      if (miss < bestMiss) {
        best = candidate;
        bestMiss = miss;
      }
      if (miss == 0) break;
    }
    if (best != null) return best;
    // Practically unreachable: an easy board of the same number.
    for (var i = 0; i < 100; i++) {
      final candidate = _candidate(number, specFor(1), rng);
      if (candidate != null) return candidate;
    }
    throw StateError('Could not build level $number');
  }

  static BlockLevel? _candidate(int number, ({int gems, double fill, int slack, double awkward}) spec, Random rng) {
    final rows = _board(spec.fill, spec.gems, rng);
    if (rows == null) return null;
    final pieces = [for (var i = 0; i < 90; i++) _pickShape(spec.awkward, rng).id];
    final draft = BlockLevel(number: number, rows: rows, pieces: pieces, moveLimit: 80, par: 80);
    final solution = BlockSolver.solve(draft, maxMoves: 70);
    if (solution == null) return null;
    final par = solution.length;
    final limit = par + spec.slack;
    // Deal a little more than the limit can use, in whole trays.
    final dealt = ((limit + 2) ~/ 3 + 1) * 3;
    return BlockLevel(number: number, rows: rows, pieces: pieces.sublist(0, dealt), moveLimit: limit, par: par);
  }

  static BlockShape _pickShape(double awkward, Random rng) {
    final pool = rng.nextDouble() < awkward ? blockShapes : blockShapes.where((s) => s.tier < 2).toList();
    final total = pool.fold(0, (sum, s) => sum + s.weight);
    var r = rng.nextInt(total);
    for (final s in pool) {
      r -= s.weight;
      if (r < 0) return s;
    }
    return pool.last;
  }

  /// A board that looks played: random pieces dropped in, never completing
  /// a line, then ★ blocks on some of the filled cells.
  static List<String>? _board(double fill, int gems, Random rng) {
    final grid = List.generate(_n, (_) => List<String>.filled(_n, '.'));
    final target = (fill * _n * _n).round();
    var filled = 0;
    const letters = {'i': 'I', 'o': 'O', 't': 'T', 's': 'S', 'z': 'Z', 'j': 'J', 'l': 'L'};
    for (var tries = 0; tries < 400 && filled < target; tries++) {
      final shape = blockShapes[rng.nextInt(blockShapes.length)];
      if (filled + shape.size > target + 2) continue;
      final x = rng.nextInt(_n - shape.width + 1), y = rng.nextInt(_n - shape.height + 1);
      if (shape.cells.any((c) => grid[y + c.y][x + c.x] != '.')) continue;
      for (final c in shape.cells) {
        grid[y + c.y][x + c.x] = letters[shape.color.name]!;
      }
      final fullRow = grid.any((r) => r.every((c) => c != '.'));
      final fullColumn = List.generate(_n, (i) => i).any((col) => grid.every((r) => r[col] != '.'));
      if (fullRow || fullColumn) {
        for (final c in shape.cells) {
          grid[y + c.y][x + c.x] = '.';
        }
        continue;
      }
      filled += shape.size;
    }
    final solid = [
      for (var y = 0; y < _n; y++)
        for (var x = 0; x < _n; x++)
          if (grid[y][x] != '.') (x, y),
    ]..shuffle(rng);
    if (solid.length < gems) return null;
    for (final (x, y) in solid.take(gems)) {
      grid[y][x] = '*';
    }
    return [for (final r in grid) r.join()];
  }
}

/// Greedy player used to prove a level can be solved. It plays through the
/// real game engine, so whatever it manages the player can repeat.
class BlockSolver {
  static const int _n = BlockPuzzleGame.size;

  /// Moves that collect every ★ of [level], or null if the solver fails
  /// within [maxMoves].
  static List<BlockMove>? solve(BlockLevel level, {int maxMoves = 70}) {
    final game = BlockPuzzleGame()..startLevel(level);
    final moves = <BlockMove>[];
    while (game.status == BlockStatus.playing && moves.length < maxMoves) {
      final move = bestMove(game);
      if (move == null) return null;
      game.place(move.$1, move.$2, move.$3);
      moves.add(move);
    }
    return game.status == BlockStatus.won ? moves : null;
  }

  /// The placement the greedy heuristic likes most, or null if nothing fits.
  static BlockMove? bestMove(BlockPuzzleGame game) {
    final scored = <(double, BlockMove)>[];
    for (var slot = 0; slot < 3; slot++) {
      final shape = game.tray[slot];
      if (shape == null) continue;
      for (var y = 0; y <= _n - shape.height; y++) {
        for (var x = 0; x <= _n - shape.width; x++) {
          if (!game.canPlace(shape, x, y)) continue;
          scored.add((_score(game, shape, x, y), (slot, x, y)));
        }
      }
    }
    if (scored.isEmpty) return null;
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    // The expensive check (do the other pieces still fit?) only for the
    // most promising few.
    for (final (_, move) in scored.take(8)) {
      if (_othersStillFit(game, move)) return move;
    }
    return scored.first.$2;
  }

  static double _score(BlockPuzzleGame game, BlockShape shape, int x, int y) {
    final grid = [
      for (var r = 0; r < _n; r++)
        for (var c = 0; c < _n; c++) game.board[r][c] != null,
    ];
    final gem = [
      for (var r = 0; r < _n; r++)
        for (var c = 0; c < _n; c++) game.board[r][c]?.gem ?? false,
    ];
    var contact = 0;
    for (final c in shape.cells) {
      grid[(y + c.y) * _n + x + c.x] = true;
    }
    bool at(int cx, int cy) => cx < 0 || cy < 0 || cx >= _n || cy >= _n || grid[cy * _n + cx];
    for (final c in shape.cells) {
      final cx = x + c.x, cy = y + c.y;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = cx + dx, ny = cy + dy;
        if (nx < 0 || ny < 0 || nx >= _n || ny >= _n) {
          contact++;
        } else if (grid[ny * _n + nx] && !shape.cells.any((o) => o.x + x == nx && o.y + y == ny)) {
          contact++;
        }
      }
    }
    final fullRows = [
      for (var r = 0; r < _n; r++)
        if (List.generate(_n, (c) => grid[r * _n + c]).every((v) => v)) r,
    ];
    final fullCols = [
      for (var c = 0; c < _n; c++)
        if (List.generate(_n, (r) => grid[r * _n + c]).every((v) => v)) c,
    ];
    var gemsHit = 0;
    for (var i = 0; i < _n * _n; i++) {
      if (gem[i] && (fullRows.contains(i ~/ _n) || fullCols.contains(i % _n))) gemsHit++;
    }
    for (final r in fullRows) {
      for (var c = 0; c < _n; c++) {
        grid[r * _n + c] = false;
        gem[r * _n + c] = false;
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < _n; r++) {
        grid[r * _n + c] = false;
        gem[r * _n + c] = false;
      }
    }
    // Lines with a ★ that are nearly full are worth building towards.
    var gemLines = 0.0;
    for (var r = 0; r < _n; r++) {
      if (!List.generate(_n, (c) => gem[r * _n + c]).any((v) => v)) continue;
      final f = List.generate(_n, (c) => grid[r * _n + c]).where((v) => v).length;
      gemLines += f * f;
    }
    for (var c = 0; c < _n; c++) {
      if (!List.generate(_n, (r) => gem[r * _n + c]).any((v) => v)) continue;
      final f = List.generate(_n, (r) => grid[r * _n + c]).where((v) => v).length;
      gemLines += f * f;
    }
    var holes = 0;
    for (var cy = 0; cy < _n; cy++) {
      for (var cx = 0; cx < _n; cx++) {
        if (grid[cy * _n + cx]) continue;
        if (at(cx + 1, cy) && at(cx - 1, cy) && at(cx, cy + 1) && at(cx, cy - 1)) holes++;
      }
    }
    final empty = grid.where((v) => !v).length;
    return gemsHit * 400 + (fullRows.length + fullCols.length) * 40 + gemLines * 0.6 + contact * 2 - holes * 12 + empty * 0.5;
  }

  static bool _othersStillFit(BlockPuzzleGame game, BlockMove move) {
    final others = [
      for (var s = 0; s < 3; s++)
        if (s != move.$1 && game.tray[s] != null) game.tray[s]!,
    ];
    if (others.isEmpty) return true;
    final copy = BlockPuzzleGame()..debugCopyFrom(game);
    copy.place(move.$1, move.$2, move.$3);
    if (copy.status == BlockStatus.won) return true;
    return others.any(copy.fitsAnywhere);
  }
}
