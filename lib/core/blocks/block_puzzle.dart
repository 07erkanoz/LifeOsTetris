import 'dart:math';

import '../tetromino.dart';
import 'shapes.dart';

export 'shapes.dart';

/// One filled square of the board.
class BlockCell {
  const BlockCell(this.color, {this.gem = false});

  final PieceType color;

  /// A golden ★ block: the target of a level.
  final bool gem;
}

/// A level of "Bulmaca Küpler": a starting board with ★ blocks to collect,
/// the exact pieces that will be dealt, and a move limit.
class BlockLevel {
  const BlockLevel({required this.number, required this.rows, required this.pieces, required this.moveLimit, required this.par});

  final int number;

  /// [BlockPuzzleGame.size] strings, top row first: '.' empty, '*' a ★ block,
  /// a tetromino letter (I O T S Z J L) a coloured block.
  final List<String> rows;

  /// Shape ids in the order they are dealt, three at a time.
  final List<String> pieces;

  /// Pieces the player may place before running out of moves.
  final int moveLimit;

  /// Moves a reference solution needed; finishing within it earns ★★★.
  final int par;

  int get gemCount => rows.join().split('').where((c) => c == '*').length;

  int get chapter => (number - 1) ~/ 10 + 1;

  /// Stars for collecting every ★ in [moves] placements.
  int starsFor(int moves) {
    if (moves <= par) return 3;
    if (moves <= par + ((moveLimit - par) / 2).ceil()) return 2;
    return 1;
  }

  /// Most moves that still earn ★★.
  int get twoStarMoves => par + ((moveLimit - par) / 2).ceil();
}

enum BlockStatus { ready, playing, won, lost }

/// Why a game or level ended without success.
enum BlockLoss { noRoom, outOfMoves }

sealed class BlockEvent {
  const BlockEvent();
}

class BlocksPlaced extends BlockEvent {
  const BlocksPlaced(this.shape, this.cells);
  final BlockShape shape;
  final List<Cell> cells;
}

/// Full rows and columns were cleared.
class LinesBlasted extends BlockEvent {
  const LinesBlasted({
    required this.rows,
    required this.columns,
    required this.cells,
    required this.points,
    required this.streak,
    required this.perfect,
  });

  final List<int> rows;
  final List<int> columns;

  /// Every removed cell with what it held.
  final List<(Cell, BlockCell)> cells;
  final int points;

  /// Consecutive clears so far (1 for a lone clear, 2+ is a combo).
  final int streak;

  /// The board is empty after the clear.
  final bool perfect;

  int get lines => rows.length + columns.length;
  Iterable<Cell> get gems => cells.where((c) => c.$2.gem).map((c) => c.$1);
}

class TrayRefilled extends BlockEvent {
  const TrayRefilled();
}

class LevelWon extends BlockEvent {
  const LevelWon({required this.stars, required this.movesLeft, required this.bonus});
  final int stars;
  final int movesLeft;
  final int bonus;
}

class BlocksGameOver extends BlockEvent {
  const BlocksGameOver(this.reason);
  final BlockLoss reason;
}

/// Deals tray pieces.
abstract class PieceSource {
  /// Three shapes for an empty tray. [game] lets a source help out when the
  /// board is crowded.
  List<BlockShape> deal(BlockPuzzleGame game);
}

/// Endless mode: weighted random shapes. A fresh tray always holds at least
/// one piece that fits, so the game ends through tight play, not bad luck
/// on the very first piece.
class RandomSource implements PieceSource {
  RandomSource([Random? random]) : _random = random ?? Random();

  final Random _random;
  static final int _total = blockShapes.fold(0, (s, b) => s + b.weight);

  BlockShape _pick() {
    var r = _random.nextInt(_total);
    for (final s in blockShapes) {
      r -= s.weight;
      if (r < 0) return s;
    }
    return blockShapes.last;
  }

  @override
  List<BlockShape> deal(BlockPuzzleGame game) {
    var tray = [_pick(), _pick(), _pick()];
    for (var attempt = 0; attempt < 30 && !tray.any(game.fitsAnywhere); attempt++) {
      tray = [_pick(), _pick(), _pick()];
    }
    return tray;
  }
}

/// Levels: exactly the pieces the level lists, then random ones.
class SequenceSource implements PieceSource {
  SequenceSource(this.ids, [Random? random]) : _fallback = RandomSource(random);

  final List<String> ids;
  final RandomSource _fallback;
  int _next = 0;

  @override
  List<BlockShape> deal(BlockPuzzleGame game) => [
    for (var i = 0; i < 3; i++) _next < ids.length ? shapeById(ids[_next++]) : _fallback._pick(),
  ];
}

/// "Bulmaca Küpler": drag pieces onto an 8×8 board; full rows and columns
/// blast away. Endless mode is about score, levels about collecting ★ blocks
/// within a move limit.
class BlockPuzzleGame {
  BlockPuzzleGame();

  static const int size = 8;

  final List<List<BlockCell?>> board = List.generate(size, (_) => List<BlockCell?>.filled(size, null));
  final List<BlockShape?> tray = [null, null, null];

  BlockStatus status = BlockStatus.ready;
  BlockLoss? loss;
  BlockLevel? level;
  int score = 0;
  int moves = 0;
  int lines = 0;
  int gemsCollected = 0;

  /// Consecutive placements that cleared something (kept alive while the
  /// player clears at least once every [streakWindow] placements).
  int streak = 0;
  int _sinceClear = 0;
  static const int streakWindow = 3;

  PieceSource _source = RandomSource();
  final List<BlockEvent> _events = [];

  bool get isEndless => level == null;
  bool get isOver => status == BlockStatus.won || status == BlockStatus.lost;

  int get gemsLeft {
    var n = 0;
    for (final row in board) {
      for (final c in row) {
        if (c != null && c.gem) n++;
      }
    }
    return n;
  }

  int get movesLeft => level == null ? 0 : max(0, level!.moveLimit - moves);

  List<BlockEvent> drainEvents() {
    final out = List<BlockEvent>.of(_events);
    _events.clear();
    return out;
  }

  void startEndless({Random? random}) {
    _reset();
    level = null;
    _source = RandomSource(random);
    status = BlockStatus.playing;
    _refill();
  }

  void startLevel(BlockLevel level, {Random? random}) {
    _reset();
    this.level = level;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        board[y][x] = parseCell(level.rows[y][x]);
      }
    }
    _source = SequenceSource(level.pieces, random);
    status = BlockStatus.playing;
    _refill();
  }

  void _reset() {
    for (final row in board) {
      row.fillRange(0, size, null);
    }
    tray.fillRange(0, 3, null);
    score = moves = lines = gemsCollected = streak = _sinceClear = 0;
    loss = null;
    _events.clear();
  }

  static BlockCell? parseCell(String c) => switch (c) {
    '.' => null,
    '*' => const BlockCell(PieceType.o, gem: true),
    'I' => const BlockCell(PieceType.i),
    'O' => const BlockCell(PieceType.o),
    'T' => const BlockCell(PieceType.t),
    'S' => const BlockCell(PieceType.s),
    'Z' => const BlockCell(PieceType.z),
    'J' => const BlockCell(PieceType.j),
    'L' => const BlockCell(PieceType.l),
    _ => throw ArgumentError('Unknown cell "$c"'),
  };

  // ------------------------------------------------------------ queries

  BlockCell? cellAt(int x, int y) => board[y][x];

  bool canPlace(BlockShape shape, int x, int y) {
    for (final c in shape.cells) {
      final cx = x + c.x, cy = y + c.y;
      if (cx < 0 || cy < 0 || cx >= size || cy >= size) return false;
      if (board[cy][cx] != null) return false;
    }
    return true;
  }

  bool fitsAnywhere(BlockShape shape) {
    for (var y = 0; y <= size - shape.height; y++) {
      for (var x = 0; x <= size - shape.width; x++) {
        if (canPlace(shape, x, y)) return true;
      }
    }
    return false;
  }

  /// Rows and columns that placing [shape] at ([x], [y]) would complete.
  (List<int> rows, List<int> columns) clearsFor(BlockShape shape, int x, int y) {
    final placed = {for (final c in shape.cells) Cell(x + c.x, y + c.y)};
    bool filled(int cx, int cy) => board[cy][cx] != null || placed.contains(Cell(cx, cy));
    final rows = <int>[], columns = <int>[];
    for (final r in placed.map((c) => c.y).toSet()) {
      if (List.generate(size, (i) => i).every((i) => filled(i, r))) rows.add(r);
    }
    for (final col in placed.map((c) => c.x).toSet()) {
      if (List.generate(size, (i) => i).every((i) => filled(col, i))) columns.add(col);
    }
    return (rows..sort(), columns..sort());
  }

  // ------------------------------------------------------------ actions

  /// Places the piece in tray [slot] with its top-left corner at ([x], [y]).
  /// Returns false (and changes nothing) when it does not fit.
  bool place(int slot, int x, int y) {
    if (status != BlockStatus.playing) return false;
    final shape = tray[slot];
    if (shape == null || !canPlace(shape, x, y)) return false;

    final cells = [for (final c in shape.cells) Cell(x + c.x, y + c.y)];
    for (final c in cells) {
      board[c.y][c.x] = BlockCell(shape.color);
    }
    tray[slot] = null;
    moves++;
    score += cells.length;
    _events.add(BlocksPlaced(shape, cells));

    final (rows, columns) = _fullLines();
    if (rows.isNotEmpty || columns.isNotEmpty) {
      _blast(rows, columns);
    } else {
      _sinceClear++;
      if (_sinceClear >= streakWindow) streak = 0;
    }

    if (level != null && gemsLeft == 0) {
      final left = movesLeft;
      final bonus = left * 50;
      score += bonus;
      status = BlockStatus.won;
      _events.add(LevelWon(stars: level!.starsFor(moves), movesLeft: left, bonus: bonus));
      return true;
    }
    if (level != null && movesLeft == 0) return _lose(BlockLoss.outOfMoves);
    if (tray.every((s) => s == null)) _refill();
    if (!tray.any((s) => s != null && fitsAnywhere(s))) return _lose(BlockLoss.noRoom);
    return true;
  }

  bool _lose(BlockLoss reason) {
    status = BlockStatus.lost;
    loss = reason;
    _events.add(BlocksGameOver(reason));
    return true;
  }

  void _refill() {
    final shapes = _source.deal(this);
    for (var i = 0; i < 3; i++) {
      tray[i] = shapes[i];
    }
    _events.add(const TrayRefilled());
  }

  (List<int>, List<int>) _fullLines() {
    final rows = [
      for (var y = 0; y < size; y++)
        if (board[y].every((c) => c != null)) y,
    ];
    final columns = [
      for (var x = 0; x < size; x++)
        if (board.every((row) => row[x] != null)) x,
    ];
    return (rows, columns);
  }

  void _blast(List<int> rows, List<int> columns) {
    final removed = <Cell, BlockCell>{};
    for (final y in rows) {
      for (var x = 0; x < size; x++) {
        removed[Cell(x, y)] = board[y][x]!;
      }
    }
    for (final x in columns) {
      for (var y = 0; y < size; y++) {
        removed[Cell(x, y)] = board[y][x]!;
      }
    }
    for (final c in removed.keys) {
      board[c.y][c.x] = null;
    }
    streak = _sinceClear < streakWindow && streak > 0 ? streak + 1 : 1;
    _sinceClear = 0;

    final n = rows.length + columns.length;
    lines += n;
    final gems = removed.values.where((c) => c.gem).length;
    gemsCollected += gems;
    final perfect = board.every((row) => row.every((c) => c == null));
    var points = 10 * n * (n + 1) ~/ 2 * streak + gems * 20;
    if (perfect) points += 300;
    score += points;
    _events.add(
      LinesBlasted(
        rows: rows,
        columns: columns,
        cells: [for (final e in removed.entries) (e.key, e.value)],
        points: points,
        streak: streak,
        perfect: perfect,
      ),
    );
  }

  /// Test helper: sets the board from strings like [BlockLevel.rows].
  void debugSetBoard(List<String> rows) {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        board[y][x] = parseCell(rows[y][x]);
      }
    }
  }

  /// Test helper: puts specific shapes in the tray.
  void debugSetTray(List<String?> ids) {
    for (var i = 0; i < 3; i++) {
      tray[i] = ids[i] == null ? null : shapeById(ids[i]!);
    }
  }
}
