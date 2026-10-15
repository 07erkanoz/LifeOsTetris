import 'dart:math';

import '../tetromino.dart';
import 'shapes.dart';

export 'shapes.dart';

/// One filled square of the board.
class BlockCell {
  const BlockCell(this.color, {this.gem = false, this.fuse});

  /// A bomb that goes off after [fuse] more placements unless its row or
  /// column is cleared first.
  const BlockCell.bomb(int this.fuse) : color = PieceType.bomb, gem = false;

  final PieceType color;

  /// A golden ★ block: the target of a level.
  final bool gem;

  /// Placements left before this bomb goes off; null for normal blocks.
  final int? fuse;

  bool get isBomb => fuse != null;

  /// One character of a board string (see [BlockLevel.rows]).
  String get code => isBomb ? '$fuse' : (gem ? '*' : color.name.toUpperCase());
}

/// A level of "Bulmaca Küpler": a starting board with ★ blocks to collect,
/// the exact pieces that will be dealt, and a move limit.
class BlockLevel {
  const BlockLevel({required this.number, required this.rows, required this.pieces, required this.moveLimit, required this.par});

  final int number;

  /// [BlockPuzzleGame.size] strings, top row first: '.' empty, '*' a ★ block,
  /// a digit a bomb with that many placements left, a tetromino letter
  /// (I O T S Z J L) a coloured block.
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
enum BlockLoss { noRoom, outOfMoves, bomb }

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
  Iterable<Cell> get bombs => cells.where((c) => c.$2.isBomb).map((c) => c.$1);
}

/// "Bomba": a new bomb appeared on the board.
class BombPlanted extends BlockEvent {
  const BombPlanted(this.cell, this.fuse);
  final Cell cell;
  final int fuse;
}

/// A bomb's fuse ran out: the game is lost.
class BombWentOff extends BlockEvent {
  const BombWentOff(this.cell);
  final Cell cell;
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

  /// How many listed pieces were dealt (for saving a level in progress).
  int get dealt => _next;

  @override
  List<BlockShape> deal(BlockPuzzleGame game) => [
    for (var i = 0; i < 3; i++) _next < ids.length ? shapeById(ids[_next++]) : _fallback._pick(),
  ];
}

/// "Bulmaca Küpler": drag pieces onto an 8×8 board; full rows and columns
/// blast away. Endless mode is about score, levels about collecting ★ blocks
/// within a move limit. "Bomba" is endless with bombs that must be cleared
/// before their fuses run out; levels may start with bombs too.
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

  /// "Bomba" mode: new bombs keep appearing.
  bool bombs = false;
  int bombsDefused = 0;
  int _sinceBomb = 0;
  Random _bombRandom = Random();

  /// Most bombs on the board at once in "Bomba".
  static const int maxBombs = 3;

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

  /// Bombs on the board with their fuses.
  List<(Cell, int)> get bombCells => [
    for (var y = 0; y < size; y++)
      for (var x = 0; x < size; x++)
        if (board[y][x]?.fuse case final fuse?) (Cell(x, y), fuse),
  ];

  /// Shortest fuse on the board, if any bomb is there.
  int? get shortestFuse => bombCells.fold<int?>(null, (m, b) => m == null || b.$2 < m ? b.$2 : m);

  List<BlockEvent> drainEvents() {
    final out = List<BlockEvent>.of(_events);
    _events.clear();
    return out;
  }

  void startEndless({Random? random}) {
    _reset();
    level = null;
    bombs = false;
    _source = RandomSource(random);
    status = BlockStatus.playing;
    _refill();
  }

  /// "Bomba": endless play with bombs.
  void startBombs({Random? random}) {
    _reset();
    level = null;
    bombs = true;
    _bombRandom = random ?? Random();
    _source = RandomSource(_bombRandom);
    status = BlockStatus.playing;
    _refill();
  }

  void startLevel(BlockLevel level, {Random? random}) {
    _reset();
    this.level = level;
    bombs = false;
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
    score = moves = lines = gemsCollected = streak = _sinceClear = bombsDefused = _sinceBomb = 0;
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
    _ when c.length == 1 && '123456789'.contains(c) => BlockCell.bomb(int.parse(c)),
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
    if (_tickBombs()) return true;
    if (level != null && movesLeft == 0) return _lose(BlockLoss.outOfMoves);
    if (bombs) _maybePlantBomb();
    if (tray.every((s) => s == null)) _refill();
    if (!tray.any((s) => s != null && fitsAnywhere(s))) return _lose(BlockLoss.noRoom);
    return true;
  }

  /// Every bomb left on the board burns one step. Returns true when one went
  /// off (the game is lost).
  bool _tickBombs() {
    Cell? blew;
    for (final (cell, fuse) in bombCells) {
      board[cell.y][cell.x] = BlockCell.bomb(fuse - 1);
      if (fuse - 1 <= 0) blew ??= cell;
    }
    if (blew == null) return false;
    _events.add(BombWentOff(blew));
    _lose(BlockLoss.bomb);
    return true;
  }

  /// "Bomba": a new bomb every few placements, faster and with shorter fuses
  /// as the game goes on.
  void _maybePlantBomb() {
    _sinceBomb++;
    final every = moves < 40 ? 5 : (moves < 100 ? 4 : 3);
    if (moves != 2 && _sinceBomb < every) return;
    if (bombCells.length >= maxBombs) return;
    final fuse = moves < 40 ? 9 : (moves < 100 ? 8 : 7);
    // Never on a cell that would finish a line by itself.
    final spots = [
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++)
          if (board[y][x] == null &&
              board[y].where((c) => c != null).length < size - 1 &&
              board.where((row) => row[x] != null).length < size - 1)
            Cell(x, y),
    ];
    if (spots.isEmpty) return;
    final spot = spots[_bombRandom.nextInt(spots.length)];
    board[spot.y][spot.x] = BlockCell.bomb(fuse);
    _sinceBomb = 0;
    _events.add(BombPlanted(spot, fuse));
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
    final defused = removed.values.where((c) => c.isBomb).length;
    bombsDefused += defused;
    final perfect = board.every((row) => row.every((c) => c == null));
    var points = 10 * n * (n + 1) ~/ 2 * streak + gems * 20 + defused * 40;
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

  /// Everything needed to continue a game in progress later.
  Map<String, Object?> toSave() {
    final level = this.level;
    final source = _source;
    return {
      'v': 1,
      'board': [
        for (final row in board) [for (final c in row) c?.code ?? '.'].join(),
      ],
      if (bombs) 'bombs': true,
      'defused': bombsDefused,
      'sinceBomb': _sinceBomb,
      'tray': [for (final s in tray) s?.id],
      'score': score,
      'moves': moves,
      'lines': lines,
      'gems': gemsCollected,
      'streak': streak,
      'sinceClear': _sinceClear,
      if (level != null)
        'level': {
          'number': level.number,
          'rows': level.rows,
          'pieces': level.pieces,
          'moveLimit': level.moveLimit,
          'par': level.par,
          'dealt': source is SequenceSource ? source.dealt : level.pieces.length,
        },
    };
  }

  /// Continues a game saved with [toSave]. Throws on malformed data.
  void restore(Map<String, Object?> save) {
    _reset();
    final rows = (save['board']! as List).cast<String>();
    if (rows.length != size || rows.any((r) => r.length != size)) throw const FormatException('board size');
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        board[y][x] = parseCell(rows[y][x]);
      }
    }
    final trayIds = (save['tray']! as List).cast<String?>();
    for (var i = 0; i < 3; i++) {
      tray[i] = trayIds[i] == null ? null : shapeById(trayIds[i]!);
    }
    score = save['score']! as int;
    moves = save['moves']! as int;
    lines = save['lines'] as int? ?? 0;
    gemsCollected = save['gems'] as int? ?? 0;
    streak = save['streak'] as int? ?? 0;
    _sinceClear = save['sinceClear'] as int? ?? 0;
    bombs = save['bombs'] as bool? ?? false;
    bombsDefused = save['defused'] as int? ?? 0;
    _sinceBomb = save['sinceBomb'] as int? ?? 0;
    _bombRandom = Random();
    final lv = save['level'] as Map?;
    if (lv == null) {
      level = null;
      _source = RandomSource();
    } else {
      final restored = BlockLevel(
        number: lv['number'] as int,
        rows: (lv['rows'] as List).cast<String>(),
        pieces: (lv['pieces'] as List).cast<String>(),
        moveLimit: lv['moveLimit'] as int,
        par: lv['par'] as int,
      );
      level = restored;
      _source = SequenceSource(restored.pieces).._next = lv['dealt'] as int? ?? 0;
    }
    status = BlockStatus.playing;
    if (tray.every((s) => s == null)) _refill();
  }

  /// Copies the state of [other] (not its piece source) for look-ahead.
  void debugCopyFrom(BlockPuzzleGame other) {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        board[y][x] = other.board[y][x];
      }
    }
    for (var i = 0; i < 3; i++) {
      tray[i] = other.tray[i];
    }
    status = other.status;
    level = other.level;
    bombs = other.bombs;
    score = other.score;
    moves = other.moves;
    lines = other.lines;
    streak = other.streak;
    _sinceClear = other._sinceClear;
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
