import 'dart:math';

import 'bag.dart';
import 'game_events.dart';
import 'scoring.dart';
import 'tetromino.dart';

export 'game_events.dart';
export 'scoring.dart' show GameMode;
export 'tetromino.dart';

enum GameStatus { ready, playing, clearing, over }

/// Pure game logic: no Flutter imports, fully deterministic for a given seed.
///
/// The board has [hiddenRows] buffer rows above the [visibleHeight] rows the
/// player sees; row 0 is the top of the buffer.
class TetrisGame {
  TetrisGame({int? seed, this.startLevel = 1, this.mode = GameMode.classic}) : _bag = PieceBag(seed), _powerRandom = Random(seed) {
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

  static const int energyPerPower = 3;

  /// Most of one power the player can hold.
  static const int maxPerPower = 3;
  static const double slowMotionDuration = 10;
  static const double slowMotionFactor = 2.5;

  /// Rows per second the ghost line sinks.
  static const double ghostLineSpeed = 2.2;

  final int startLevel;
  GameMode mode;
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

  // Süper Küpler state.
  Random _powerRandom;
  int _energy = 0;
  final Map<PowerType, int> _powers = {};

  /// Upcoming powers: every power once, shuffled, so all six turn up and
  /// none repeats before the others have come.
  final List<PowerType> _powerQueue = [];
  double _slowMotion = 0;
  double? _ghostLine;

  // Bulmaca Küpler state.

  // ---------------------------------------------------------------- queries

  Piece? get active => _active;
  PieceType? get held => _held;
  bool get canHold => _canHold;
  int get combo => _combo;
  bool get backToBackActive => _backToBackActive;
  bool get softDropping => _softDrop;
  List<int> get clearingRows => _clearingRows;

  /// Progress of the current line clear animation from 0 to 1.
  double get clearProgress => status == GameStatus.clearing ? (1 - _clearTimer / lineClearDelay).clamp(0.0, 1.0) : 0;

  /// Progress of the lock delay from 0 to 1 while the piece rests on the stack.
  double get lockProgress => (_lockTimer / lockDelay).clamp(0.0, 1.0);

  List<PieceType> get preview => _bag.peek(previewCount);

  bool get powersEnabled => mode.hasPowers;

  /// Energy towards the next power, 0..[energyPerPower].
  int get energy => _energy;

  /// How many of each power the player holds.
  int powerCount(PowerType type) => _powers[type] ?? 0;
  int get totalPowers => _powers.values.fold(0, (a, b) => a + b);

  /// True if [type] can be used right now (gravity only when something
  /// would actually fall).
  bool canUsePower(PowerType type) => powersEnabled && _canAct && powerCount(type) > 0 && (type != PowerType.gravity || hasFloatingBlocks);

  /// Some block has an empty cell under it.
  bool get hasFloatingBlocks {
    for (var x = 0; x < width; x++) {
      var seenGap = false;
      for (var y = height - 1; y >= 0; y--) {
        if (_board[y][x] == null) {
          seenGap = true;
        } else if (seenGap) {
          return true;
        }
      }
    }
    return false;
  }

  /// Seconds of slow motion left.
  double get slowMotion => _slowMotion;

  /// Position of the ghost line in visible rows (0 = top), or null.
  double? get ghostLine => _ghostLine;

  /// Visible row the ghost line would fill if triggered now.
  int? get ghostLineRow => _ghostLine?.floor().clamp(0, visibleHeight - 1);

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
    _energy = 0;
    _powers.clear();
    _powerQueue.clear();
    _slowMotion = 0;
    _ghostLine = null;
  }

  /// Starts a new game. Pass [seed] to make the piece sequence reproducible.
  void start({int? seed, GameMode? mode}) {
    if (mode != null) this.mode = mode;
    final s = seed ?? Random().nextInt(1 << 31);
    _bag = PieceBag(s);
    _powerRandom = Random(s);
    _reset();
    status = GameStatus.playing;
    _spawn(_bag.next());
  }

  /// Abandons the current game and returns to the menu state.
  void abandon() {
    _reset();
    status = GameStatus.ready;
  }

  /// Everything needed to continue a running game later, as JSON-ready
  /// values. Timers restart from zero and the random sources are re-seeded,
  /// so the pieces after the saved queue may differ.
  Map<String, Object?> toSave() {
    final a = _active;
    return {
      'v': 1,
      'mode': mode.name,
      'board': [
        for (final row in _board) [for (final t in row) t?.name],
      ],
      'active': a == null ? null : [a.type.name, a.rotation.name, a.x, a.y],
      'held': _held?.name,
      'canHold': _canHold,
      'score': score,
      'lines': lines,
      'level': level,
      'combo': _combo,
      'b2b': _backToBackActive,
      'bag': [for (final t in _bag.queued) t.name],
      'energy': _energy,
      'powers': {for (final e in _powers.entries) e.key.name: e.value},
      'powerQueue': [for (final p in _powerQueue) p.name],
      'slowMotion': _slowMotion,
      'clearing': status == GameStatus.clearing ? _clearingRows : null,
    };
  }

  /// Continues a game saved with [toSave]. Throws on malformed data.
  void restore(Map<String, Object?> save) {
    PieceType piece(Object? name) => PieceType.values.byName(name! as String);
    final mode = GameMode.values.byName(save['mode']! as String);
    final rows = (save['board']! as List).cast<List>();
    if (rows.length != height || rows.any((r) => r.length != width)) throw const FormatException('board size');
    this.mode = mode;
    _bag = PieceBag();
    _powerRandom = Random();
    _reset();
    _board = [
      for (final row in rows) [for (final c in row) c == null ? null : piece(c)],
    ];
    final active = save['active'] as List?;
    if (active != null) {
      _active = Piece(piece(active[0]), Rotation.values.byName(active[1] as String), active[2] as int, active[3] as int);
    }
    final held = save['held'];
    _held = held == null ? null : piece(held);
    _canHold = save['canHold'] as bool? ?? true;
    score = save['score']! as int;
    lines = save['lines']! as int;
    level = save['level']! as int;
    _combo = save['combo'] as int? ?? -1;
    _backToBackActive = save['b2b'] as bool? ?? false;
    _bag.restoreQueue([for (final t in (save['bag'] as List? ?? const [])) piece(t)]);
    _energy = save['energy'] as int? ?? 0;
    for (final e in (save['powers'] as Map? ?? const {}).entries) {
      _powers[PowerType.values.byName(e.key as String)] = e.value as int;
    }
    _powerQueue.addAll([for (final p in (save['powerQueue'] as List? ?? const [])) PowerType.values.byName(p as String)]);
    _slowMotion = (save['slowMotion'] as num? ?? 0).toDouble();
    final clearing = save['clearing'] as List?;
    if (clearing != null && clearing.isNotEmpty) {
      _clearingRows = clearing.cast<int>();
      _clearTimer = lineClearDelay;
      status = GameStatus.clearing;
    } else {
      status = GameStatus.playing;
      if (_active == null || !_fits(_active!)) _spawnNext();
    }
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

    if (_ghostLine != null) {
      // The world holds still while the ghost line sinks through the stack.
      _ghostLine = _ghostLine! + ghostLineSpeed * dt;
      if (_ghostLine! >= visibleHeight - 1) triggerGhostLine();
      return;
    }

    if (_slowMotion > 0) {
      _slowMotion = max(0, _slowMotion - dt);
      if (_slowMotion == 0) _events.add(const SlowMotionEnded());
    }

    final piece = _active;
    if (piece == null) return;

    final base = gravityInterval(level, mode) * (_slowMotion > 0 ? slowMotionFactor : 1);
    final interval = _softDrop ? min(base / 20, 0.05) : base;
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

  bool get _canAct => !paused && status == GameStatus.playing && _active != null && _ghostLine == null;

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
    if (on && !_softDrop) _gravityTimer = max(_gravityTimer, min(gravityInterval(level, mode) / 20, 0.05));
    _softDrop = on;
  }

  void hardDrop() {
    if (_ghostLine != null) {
      triggerGhostLine();
      return;
    }
    if (!_canAct) return;
    final piece = _active!;
    final distance = _dropDistance(piece);
    final landed = piece.moved(0, distance);
    _active = landed;
    if (distance > 0) _lastMoveWasRotation = false;
    score += distance * 2;
    _events.add(HardDropped(type: piece.type, fromCells: piece.cells.toList(), toCells: landed.cells.toList(), distance: distance));
    _lock();
  }

  bool hold() {
    if (!_canAct || !_canHold || _active!.type.isSpecial) return false;
    final current = _active!.type;
    final swapIn = _held;
    _held = current;
    _canHold = false;
    _events.add(PieceHeld(current));
    _spawn(swapIn ?? _bag.next());
    return true;
  }

  // ---------------------------------------------------------------- powers

  /// Uses one [type] power. Returns false if it cannot be used right now.
  bool usePower(PowerType type) {
    if (!canUsePower(type)) return false;
    final piece = _active!;
    _powers[type] = powerCount(type) - 1;
    _events.add(PowerActivated(type));
    switch (type) {
      case PowerType.bomb || PowerType.single || PowerType.drill:
        // The current piece comes back right after the power piece.
        if (!piece.type.isSpecial) _bag.pushFront(piece.type);
        _spawn(switch (type) {
          PowerType.bomb => PieceType.bomb,
          PowerType.drill => PieceType.drill,
          _ => PieceType.mono,
        });
      case PowerType.gravity:
        _applyGravity();
      case PowerType.slowMotion:
        _slowMotion = slowMotionDuration;
        _events.add(const SlowMotionStarted(slowMotionDuration));
      case PowerType.ghostLine:
        _ghostLine = 0;
        _events.add(const GhostLineStarted());
    }
    _grantPowers();
    return true;
  }

  /// Stops the ghost line and fills the gaps of the row it is on.
  bool triggerGhostLine() {
    var row = ghostLineRow;
    if (row == null) return false;
    _ghostLine = null;
    // Filling a completely empty row would waste the power: snap down to the
    // first row that has blocks in it (the top of the stack).
    while (row! < visibleHeight - 1 && _board[row + hiddenRows].every((c) => c == null)) {
      row++;
    }
    final y = row + hiddenRows;
    final filled = <Cell>[];
    for (var x = 0; x < width; x++) {
      if (_board[y][x] == null) {
        _board[y][x] = PieceType.mono;
        filled.add(Cell(x, y));
      }
    }
    _events.add(GhostLineFilled(y, filled));
    _resolvePowerClears();
    return true;
  }

  void _addEnergy(int amount) {
    if (!powersEnabled || amount <= 0) return;
    _energy += amount;
    _events.add(EnergyGained(amount));
    _grantPowers();
  }

  void _grantPowers() {
    while (_energy >= energyPerPower) {
      final type = _nextPower();
      if (type == null) {
        // Every power is maxed out: the bar waits, full.
        _energy = energyPerPower;
        return;
      }
      _energy -= energyPerPower;
      _powers[type] = powerCount(type) + 1;
      _events.add(PowerEarned(type));
    }
  }

  PowerType? _nextPower() {
    for (var tries = 0; tries < PowerType.values.length * 2; tries++) {
      if (_powerQueue.isEmpty) _powerQueue.addAll(List.of(PowerType.values)..shuffle(_powerRandom));
      final type = _powerQueue.removeAt(0);
      if (powerCount(type) < maxPerPower) return type;
    }
    return null;
  }

  void _applyGravity() {
    final moves = <FallenCell>[];
    for (var x = 0; x < width; x++) {
      var write = height - 1;
      for (var y = height - 1; y >= 0; y--) {
        final cell = _board[y][x];
        if (cell == null) continue;
        if (write != y) {
          _board[write][x] = cell;
          _board[y][x] = null;
          moves.add((x, y, write));
        }
        write--;
      }
    }
    _events.add(GravityApplied(moves));
    // Blocks may have dropped into the active piece's cells: lift it clear.
    var piece = _active;
    if (piece != null) {
      while (!_fits(piece!) && piece.y > 0) {
        piece = piece.moved(0, -1);
      }
      if (!_fits(piece)) {
        _active = null;
        _gameOver();
        return;
      }
      _active = piece;
    }
    _resolvePowerClears();
  }

  /// Clears rows completed by a power (gravity, ghost line).
  void _resolvePowerClears() {
    final fullRows = _fullRows();
    if (fullRows.isEmpty) return;
    // The piece in play goes back to the queue and returns after the clear.
    final piece = _active;
    if (piece != null) {
      if (!piece.type.isSpecial) _bag.pushFront(piece.type);
      _active = null;
    }
    _combo++;
    final perfect = _isPerfectClear(fullRows);
    final points = clearScore(
      lines: fullRows.length,
      tSpin: TSpin.none,
      level: level,
      backToBack: false,
      combo: max(_combo, 0),
      perfectClear: perfect,
    );
    score += points;
    _beginClear(fullRows, TSpin.none, backToBack: false, perfectClear: perfect, points: points);
  }

  // ---------------------------------------------------------------- internals

  bool _fits(Piece piece) {
    final drill = piece.type == PieceType.drill;
    for (final c in piece.cells) {
      if (c.x < 0 || c.x >= width || c.y < 0 || c.y >= height) return false;
      // The drill passes through blocks.
      if (!drill && _board[c.y][c.x] != null) return false;
    }
    return true;
  }

  List<int> _fullRows() => [
    for (var y = 0; y < height; y++)
      if (_board[y].every((c) => c != null)) y,
  ];

  bool _isPerfectClear(List<int> fullRows) => [
    for (var y = 0; y < height; y++)
      if (!fullRows.contains(y)) _board[y],
  ].every((row) => row.every((c) => c == null));

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

  void _spawnNext() => _spawn(_bag.next());

  void _spawn(PieceType type) {
    // One-cell power pieces would sit entirely in the hidden rows at the
    // normal spawn height, so they appear at the top of the visible well.
    final piece = Piece(type, Rotation.spawn, 3, type.isSpecial ? hiddenRows - 1 : 0);
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
    if (piece.type == PieceType.bomb) return _explodeBomb(piece);
    if (piece.type == PieceType.drill) return _drillColumn(piece);
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

    final fullRows = _fullRows();
    final cleared = fullRows.length;

    final difficult = isDifficultClear(cleared, tSpin);
    final backToBack = cleared > 0 && difficult && _backToBackActive;
    if (cleared > 0) {
      _combo++;
      _backToBackActive = difficult;
    } else {
      _combo = -1;
    }

    final perfectClear = cleared > 0 && _isPerfectClear(fullRows);

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
      _beginClear(fullRows, tSpin, backToBack: backToBack, perfectClear: perfectClear, points: points);
    } else {
      if (tSpin != TSpin.none) _events.add(TSpinNoLines(tSpin, points));
      _canHold = true;
      _spawnNext();
    }
  }

  void _beginClear(List<int> fullRows, TSpin tSpin, {required bool backToBack, required bool perfectClear, required int points}) {
    _events.add(
      LinesCleared(rows: fullRows, tSpin: tSpin, combo: _combo, backToBack: backToBack, perfectClear: perfectClear, points: points),
    );
    lines += fullRows.length;
    final newLevel = min(startLevel + lines ~/ 10, maxLevel);
    if (newLevel > level) {
      level = newLevel;
      _events.add(LevelUp(level));
    }
    _addEnergy(fullRows.length);
    _clearingRows = fullRows;
    _clearTimer = lineClearDelay;
    status = GameStatus.clearing;
  }

  void _explodeBomb(Piece piece) {
    final center = piece.cells.first;
    final removed = <RemovedCell>[];
    for (var y = center.y - 1; y <= center.y + 1; y++) {
      for (var x = center.x - 1; x <= center.x + 1; x++) {
        if (x < 0 || x >= width || y < 0 || y >= height) continue;
        final type = _board[y][x];
        if (type == null) continue;
        removed.add((Cell(x, y), type));
        _board[y][x] = null;
      }
    }
    _active = null;
    final points = 25 * removed.length * level;
    score += points;
    _combo = -1;
    _events.add(BombExploded(center, removed, points));
    _canHold = true;
    _spawnNext();
  }

  void _drillColumn(Piece piece) {
    final start = piece.cells.first;
    final removed = <RemovedCell>[];
    for (var y = 0; y < height; y++) {
      final type = _board[y][start.x];
      if (type == null) continue;
      removed.add((Cell(start.x, y), type));
      _board[y][start.x] = null;
    }
    _active = null;
    final points = 20 * removed.length * level;
    score += points;
    _combo = -1;
    _events.add(ColumnDrilled(start.x, start.y, removed, points));
    _canHold = true;
    _spawnNext();
  }

  void _collapseRows() {
    final rows = _clearingRows;
    final remaining = [
      for (var y = 0; y < height; y++)
        if (!rows.contains(y)) _board[y],
    ];
    _board = [for (var i = 0; i < rows.length; i++) List<PieceType?>.filled(width, null), ...remaining];
    _clearingRows = const [];
    status = GameStatus.playing;
    _events.add(RowsCollapsed(rows));
    _canHold = true;
    _spawnNext();
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
      for (final row in rows) [for (final ch in row.split('')) _parseCell(ch)],
    ];
    _board = [for (var i = 0; i < height - parsed.length; i++) List<PieceType?>.filled(width, null), ...parsed];
  }

  static PieceType? _parseCell(String ch) => switch (ch) {
    '.' => null,
    'M' => PieceType.mono,
    _ => PieceType.values.byName(ch.toLowerCase()),
  };

  /// Gives powers directly (testing only).
  void debugGivePowers(List<PowerType> powers) {
    _powers.clear();
    for (final p in powers) {
      _powers[p] = powerCount(p) + 1;
    }
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
