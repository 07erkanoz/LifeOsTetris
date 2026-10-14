import 'dart:math';

import 'bag.dart';
import 'game_events.dart';
import 'scoring.dart';
import 'tetromino.dart';

export 'game_events.dart';
export 'tetromino.dart';

enum GameStatus { ready, playing, clearing, over }

/// Pure game logic: no Flutter imports, fully deterministic for a given seed.
///
/// The board has [hiddenRows] buffer rows above the [visibleHeight] rows the
/// player sees; row 0 is the top of the buffer.
class TetrisGame {
  TetrisGame({int? seed, this.startLevel = 1}) : _bag = PieceBag(seed) {
    _reset();
  }

  static const int width = 10;
  static const int visibleHeight = 20;
  static const int hiddenRows = 2;
  static const int height = visibleHeight + hiddenRows;
  static const int previewCount = 5;

  static const double lockDelay = 0.5;
  static const int maxLockResets = 15;
  static const double lineClearDelay = 0.42;

  final int startLevel;
  PieceBag _bag;

  late List<List<PieceType?>> _board;
  Piece? _active;
  PieceType? _held;
  bool _canHold = true;

  int score = 0;
  int lines = 0;
  late int level;
  int _combo = -1;
  bool _backToBackActive = false;

  GameStatus status = GameStatus.ready;
  bool paused = false;
  bool _softDrop = false;

  double _gravityTimer = 0;
  double _lockTimer = 0;
  int _lockResets = 0;
  int _lowestY = 0;
  bool _lastMoveWasRotation = false;
  int _lastKickIndex = 0;

  List<int> _clearingRows = const [];
  double _clearTimer = 0;

  final List<GameEvent> _events = [];

  // ---------------------------------------------------------------- queries

  Piece? get active => _active;
  PieceType? get held => _held;
  bool get canHold => _canHold;
  int get combo => _combo;
  bool get backToBackActive => _backToBackActive;
  bool get softDropping => _softDrop;
  List<int> get clearingRows => _clearingRows;

  /// Progress of the current line clear animation from 0 to 1.
  double get clearProgress =>
      status == GameStatus.clearing ? (1 - _clearTimer / lineClearDelay).clamp(0.0, 1.0) : 0;

  /// Progress of the lock delay from 0 to 1 while the piece rests on the stack.
  double get lockProgress => (_lockTimer / lockDelay).clamp(0.0, 1.0);

  List<PieceType> get preview => _bag.peek(previewCount);

  PieceType? cellAt(int x, int y) => _board[y][x];

  List<List<PieceType?>> get board => _board;

  /// Where the active piece would land if hard dropped.
  Piece? get ghost {
    final piece = _active;
    if (piece == null) return null;
    return piece.moved(0, _dropDistance(piece));
  }

  bool get isRunning => !paused && (status == GameStatus.playing || status == GameStatus.clearing);

  /// Removes and returns events produced since the last call.
  List<GameEvent> drainEvents() {
    final out = List<GameEvent>.of(_events);
    _events.clear();
    return out;
  }

  // ---------------------------------------------------------------- lifecycle

  void _reset() {
    _board = List.generate(height, (_) => List<PieceType?>.filled(width, null));
    _active = null;
    _held = null;
    _canHold = true;
    score = 0;
    lines = 0;
    level = startLevel;
    _combo = -1;
    _backToBackActive = false;
    paused = false;
    _softDrop = false;
    _gravityTimer = 0;
    _lockTimer = 0;
    _lockResets = 0;
    _clearingRows = const [];
    _clearTimer = 0;
    _events.clear();
  }

  /// Starts a new game. Pass [seed] to make the piece sequence reproducible.
  void start({int? seed}) {
    _bag = PieceBag(seed ?? Random().nextInt(1 << 31));
    _reset();
    status = GameStatus.playing;
    _spawn(_bag.next());
  }

  void togglePause() {
    if (status == GameStatus.playing || status == GameStatus.clearing) {
      paused = !paused;
    }
  }

  // ---------------------------------------------------------------- update

  void update(double dt) {
    if (!isRunning) return;

    if (status == GameStatus.clearing) {
      _clearTimer -= dt;
      if (_clearTimer <= 0) _collapseRows();
      return;
    }

    final piece = _active;
    if (piece == null) return;

    final interval = _softDrop ? min(gravityInterval(level) / 20, 0.05) : gravityInterval(level);
    _gravityTimer += dt;
    while (_gravityTimer >= interval) {
      _gravityTimer -= interval;
      if (!_tryMoveDown()) {
        _gravityTimer = 0;
        break;
      }
      if (_softDrop) {
        score += 1;
        _events.add(const SoftDropped());
      }
    }

    if (_active != null && _isGrounded(_active!)) {
      _lockTimer += dt;
      if (_lockTimer >= lockDelay || _lockResets >= maxLockResets) _lock();
    } else {
      _lockTimer = 0;
    }
  }

  // ---------------------------------------------------------------- input

  bool get _canAct => !paused && status == GameStatus.playing && _active != null;

  bool moveLeft() => _shift(-1);
  bool moveRight() => _shift(1);

  bool _shift(int dx) {
    if (!_canAct) return false;
    final moved = _active!.moved(dx, 0);
    if (!_fits(moved)) {
      _events.add(PieceMoveBlocked(dx));
      return false;
    }
    _active = moved;
    _lastMoveWasRotation = false;
    _onManipulated();
    _events.add(PieceMoved(dx));
    return true;
  }

  bool rotateClockwise() => _rotate(true);
  bool rotateCounterClockwise() => _rotate(false);

  bool _rotate(bool clockwise) {
    if (!_canAct) return false;
    final piece = _active!;
    if (piece.type == PieceType.o) return false;
    final to = clockwise ? piece.rotation.cw : piece.rotation.ccw;
    final kicks = kicksFor(piece.type, piece.rotation, to);
    for (var i = 0; i < kicks.length; i++) {
      final candidate = piece.copyWith(rotation: to, x: piece.x + kicks[i].x, y: piece.y + kicks[i].y);
      if (_fits(candidate)) {
        _active = candidate;
        _lastMoveWasRotation = true;
        _lastKickIndex = i;
        _trackLowest();
        _onManipulated();
        _events.add(PieceRotated(clockwise: clockwise, kicked: i > 0));
        return true;
      }
    }
    return false;
  }

  void setSoftDrop(bool on) {
    if (on && !_softDrop) _gravityTimer = max(_gravityTimer, min(gravityInterval(level) / 20, 0.05));
    _softDrop = on;
  }

  void hardDrop() {
    if (!_canAct) return;
    final piece = _active!;
    final distance = _dropDistance(piece);
    final landed = piece.moved(0, distance);
    _active = landed;
    if (distance > 0) _lastMoveWasRotation = false;
    score += distance * 2;
    _events.add(HardDropped(
      type: piece.type,
      fromCells: piece.cells.toList(),
      toCells: landed.cells.toList(),
      distance: distance,
    ));
    _lock();
  }

  bool hold() {
    if (!_canAct || !_canHold) return false;
    final current = _active!.type;
    final swapIn = _held;
    _held = current;
    _canHold = false;
    _events.add(PieceHeld(current));
    _spawn(swapIn ?? _bag.next());
    return true;
  }

  // ---------------------------------------------------------------- internals

  bool _fits(Piece piece) {
    for (final c in piece.cells) {
      if (c.x < 0 || c.x >= width || c.y < 0 || c.y >= height) return false;
      if (_board[c.y][c.x] != null) return false;
    }
    return true;
  }

  bool _isGrounded(Piece piece) => !_fits(piece.moved(0, 1));

  int _dropDistance(Piece piece) {
    var d = 0;
    while (_fits(piece.moved(0, d + 1))) {
      d++;
    }
    return d;
  }

  bool _tryMoveDown() {
    final piece = _active!;
    final moved = piece.moved(0, 1);
    if (!_fits(moved)) return false;
    _active = moved;
    _lastMoveWasRotation = false;
    _trackLowest();
    return true;
  }

  void _trackLowest() {
    final y = _active!.y;
    if (y > _lowestY) {
      _lowestY = y;
      _lockResets = 0;
    }
  }

  void _onManipulated() {
    if (_lockTimer > 0 || _isGrounded(_active!)) {
      if (_lockResets < maxLockResets) {
        _lockTimer = 0;
        _lockResets++;
      }
    }
  }

  void _spawn(PieceType type) {
    final piece = Piece(type, Rotation.spawn, 3, 0);
    if (!_fits(piece)) {
      _active = null;
      _gameOver();
      return;
    }
    _active = piece;
    _gravityTimer = 0;
    _lockTimer = 0;
    _lockResets = 0;
    _lowestY = piece.y;
    _lastMoveWasRotation = false;
    // Guideline: a new piece immediately drops one row if it can.
    if (_fits(piece.moved(0, 1))) {
      _active = piece.moved(0, 1);
      _lowestY = piece.y + 1;
    }
    _events.add(PieceSpawned(type));
  }

  TSpin _detectTSpin(Piece piece) {
    if (piece.type != PieceType.t || !_lastMoveWasRotation) return TSpin.none;
    final cx = piece.x + 1, cy = piece.y + 1;
    bool filled(int x, int y) => x < 0 || x >= width || y >= height || y < 0 || _board[y][x] != null;
    final tl = filled(cx - 1, cy - 1), tr = filled(cx + 1, cy - 1);
    final bl = filled(cx - 1, cy + 1), br = filled(cx + 1, cy + 1);
    final corners = [tl, tr, bl, br].where((c) => c).length;
    if (corners < 3) return TSpin.none;
    final (front1, front2) = switch (piece.rotation) {
      Rotation.spawn => (tl, tr),
      Rotation.right => (tr, br),
      Rotation.flip => (bl, br),
      Rotation.left => (tl, bl),
    };
    return (front1 && front2) || _lastKickIndex == 4 ? TSpin.full : TSpin.mini;
  }

  void _lock() {
    final piece = _active!;
    final tSpin = _detectTSpin(piece);
    final cells = piece.cells.toList();
    for (final c in cells) {
      _board[c.y][c.x] = piece.type;
    }
    _active = null;
    _events.add(PieceLocked(piece.type, cells));

    // Lock out: the whole piece stayed inside the hidden buffer.
    if (cells.every((c) => c.y < hiddenRows)) {
      _gameOver();
      return;
    }

    final fullRows = [
      for (var y = 0; y < height; y++)
        if (_board[y].every((c) => c != null)) y,
    ];
    final cleared = fullRows.length;

    final difficult = isDifficultClear(cleared, tSpin);
    final backToBack = cleared > 0 && difficult && _backToBackActive;
    if (cleared > 0) {
      _combo++;
      _backToBackActive = difficult;
    } else {
      _combo = -1;
    }

    final perfectClear = cleared > 0 &&
        [
          for (var y = 0; y < height; y++)
            if (!fullRows.contains(y)) _board[y],
        ].every((row) => row.every((c) => c == null));

    final points = clearScore(
      lines: cleared,
      tSpin: tSpin,
      level: level,
      backToBack: backToBack,
      combo: max(_combo, 0),
      perfectClear: perfectClear,
    );
    score += points;

    if (cleared > 0) {
      _events.add(LinesCleared(
        rows: fullRows,
        tSpin: tSpin,
        combo: _combo,
        backToBack: backToBack,
        perfectClear: perfectClear,
        points: points,
      ));
      lines += cleared;
      final newLevel = min(startLevel + lines ~/ 10, maxLevel);
      if (newLevel > level) {
        level = newLevel;
        _events.add(LevelUp(level));
      }
      _clearingRows = fullRows;
      _clearTimer = lineClearDelay;
      status = GameStatus.clearing;
    } else {
      if (tSpin != TSpin.none) _events.add(TSpinNoLines(tSpin, points));
      _canHold = true;
      _spawn(_bag.next());
    }
  }

  void _collapseRows() {
    final rows = _clearingRows;
    final remaining = [
      for (var y = 0; y < height; y++)
        if (!rows.contains(y)) _board[y],
    ];
    _board = [
      for (var i = 0; i < rows.length; i++) List<PieceType?>.filled(width, null),
      ...remaining,
    ];
    _clearingRows = const [];
    status = GameStatus.playing;
    _events.add(RowsCollapsed(rows));
    _canHold = true;
    _spawn(_bag.next());
  }

  void _gameOver() {
    status = GameStatus.over;
    _softDrop = false;
    _events.add(const GameOver());
  }

  // ---------------------------------------------------------------- testing

  /// Replaces the board contents. Rows are given top to bottom using one
  /// character per cell: '.' for empty, any piece letter (IOTSZJL) otherwise.
  /// Missing top rows are filled with empty cells.
  void debugSetBoard(List<String> rows) {
    final parsed = [
      for (final row in rows)
        [for (final ch in row.split('')) ch == '.' ? null : PieceType.values.byName(ch.toLowerCase())],
    ];
    _board = [
      for (var i = 0; i < height - parsed.length; i++) List<PieceType?>.filled(width, null),
      ...parsed,
    ];
  }

  /// Puts a specific piece in play (testing only).
  void debugSetActive(Piece piece) {
    _active = piece;
    _lowestY = piece.y;
    _lockTimer = 0;
    _lockResets = 0;
    _lastMoveWasRotation = false;
  }
}
