import 'dart:math';

/// Zincir Küpler: swap two neighbouring cubes so three or more of a colour
/// line up; the cleared cubes let the ones above fall, and a fall that makes
/// a new match is a chain. The stack keeps rising from below.
///
/// Pure game logic: no Flutter, time advances only through [ChainGame.update].
/// The board is [ChainGame.height] rows of [ChainGame.width] columns, row 0 at
/// the top.

enum ChainColor { yellow, magenta, blue, green, orange, gray }

enum ChainMode { endless, timeAttack }

/// How forgiving a game is: colours in play, rise speed, the time allowed
/// at the top and how often garbage drops.
enum ChainDifficulty {
  easy(colors: 4, firstRow: 9.0, rowStep: 0.45, fastestRow: 2.2, levelEvery: 50, grace: 4.0, garbage: false, firstGarbage: 0, garbageEvery: 0, stopScale: 1.5),
  normal(colors: 5, firstRow: 6.5, rowStep: 0.5, fastestRow: 0.9, levelEvery: 35, grace: 2.4, garbage: true, firstGarbage: 40, garbageEvery: 34, stopScale: 1),
  hard(colors: 5, firstRow: 4.6, rowStep: 0.45, fastestRow: 0.7, levelEvery: 25, grace: 1.6, garbage: true, firstGarbage: 22, garbageEvery: 24, stopScale: 0.8);

  const ChainDifficulty({
    required this.colors,
    required this.firstRow,
    required this.rowStep,
    required this.fastestRow,
    required this.levelEvery,
    required this.grace,
    required this.garbage,
    required this.firstGarbage,
    required this.garbageEvery,
    required this.stopScale,
  });

  /// Colours in play (gray comes on top, rarely).
  final int colors;

  /// Seconds per row at level 1, the speed-up per level and the limit.
  final double firstRow, rowStep, fastestRow;

  /// Seconds per level in endless (time attack levels up twice as fast).
  final int levelEvery;
  final double grace;
  final bool garbage;
  final double firstGarbage, garbageEvery;

  /// Scales how long combos and chains stop the rise.
  final double stopScale;

  double secondsPerRow(int level) => max(fastestRow, firstRow - (level - 1) * rowStep);

  static ChainDifficulty parse(String? name) => values.firstWhere((d) => d.name == name, orElse: () => ChainDifficulty.easy);
}

enum ChainStatus { ready, playing, over }

enum BlockState { idle, swapping, hovering, falling, clearing }

/// A red garbage slab one row high: it falls as a whole and breaks into
/// cubes when a match happens next to it.
class GarbageSlab {
  GarbageSlab(this.id, this.x, this.y, this.width);

  final int id;
  int x;
  int y;
  final int width;
  bool falling = false;

  /// Progress towards the next row while falling (0..1).
  double fall = 0;
  bool breaking = false;
}

class ChainBlock {
  ChainBlock(this.id, this.color, {this.slab});

  final int id;
  ChainColor color;

  /// Set for the cells of a garbage slab.
  final GarbageSlab? slab;
  bool get isGarbage => slab != null;

  BlockState state = BlockState.idle;
  double timer = 0;

  /// Progress towards the next row while falling (0..1), for drawing.
  double fall = 0;

  /// While swapping: the side it came from (+1 right, -1 left).
  int swapFrom = 0;

  /// Freed by a clear below it: a match it makes when it lands is a chain.
  bool chain = false;

  /// Has already burst while its group clears.
  bool popped = false;
}

sealed class ChainEvent {
  const ChainEvent();
}

class ChainSwapped extends ChainEvent {
  const ChainSwapped(this.x, this.y);
  final int x, y;
}

class ChainMatched extends ChainEvent {
  const ChainMatched({required this.cells, required this.chain, required this.points, required this.grays, required this.garbage});

  /// The matched cubes: column, row and colour.
  final List<(int, int, ChainColor)> cells;

  /// 1 for a plain match, 2+ for a chain step.
  final int chain;
  final int points;
  final int grays;

  /// Garbage cells this match is going to break.
  final int garbage;

  int get combo => cells.length;
}

/// One cube of a clearing group bursts ([index] counts from 0).
class ChainPopped extends ChainEvent {
  const ChainPopped(this.x, this.y, this.color, this.index, this.chain);
  final int x, y, index, chain;
  final ChainColor color;
}

class ChainEnded extends ChainEvent {
  const ChainEnded(this.chain);
  final int chain;
}

class ChainRowRaised extends ChainEvent {
  const ChainRowRaised({required this.manual});
  final bool manual;
}

class ChainGarbageDropped extends ChainEvent {
  const ChainGarbageDropped(this.slab);
  final GarbageSlab slab;
}

class ChainGarbageBroken extends ChainEvent {
  const ChainGarbageBroken(this.x, this.y, this.width);
  final int x, y, width;
}

class ChainLevelUp extends ChainEvent {
  const ChainLevelUp(this.level);
  final int level;
}

class ChainDanger extends ChainEvent {
  const ChainDanger(this.on);
  final bool on;
}

class ChainGameOver extends ChainEvent {
  const ChainGameOver({required this.timeUp});
  final bool timeUp;
}

class _ClearGroup {
  _ClearGroup(this.blocks, this.chain, this.slabs);

  /// In bursting order: top to bottom, left to right.
  final List<ChainBlock> blocks;
  final int chain;
  final Set<GarbageSlab> slabs;
  double t = 0;
  int popped = 0;
}

class ChainGame {
  ChainGame({Random? random}) : _random = random ?? Random();

  static const int width = 6;
  static const int height = 12;

  /// Seconds for a swap, a hover before falling, one row of falling.
  static const double swapTime = 0.07;
  static const double hoverTime = 0.08;
  static const double chainHoverTime = 0.16;
  static const double fallSpeed = 18;

  /// A clear flashes, then its cubes burst one after another.
  static const double flashTime = 0.42;
  static const double popInterval = 0.07;
  static const double popTail = 0.08;

  static const double manualRaiseSpeed = 7;
  static const double timeAttackLength = 120;
  static const int maxLevel = 12;

  final Random _random;
  ChainMode mode = ChainMode.endless;
  ChainDifficulty difficulty = ChainDifficulty.normal;
  ChainStatus status = ChainStatus.ready;

  final List<List<ChainBlock?>> board = [for (var y = 0; y < height; y++) List<ChainBlock?>.filled(width, null)];
  List<ChainBlock> incoming = [];
  final List<GarbageSlab> slabs = [];
  final List<_ClearGroup> _groups = [];
  final List<ChainEvent> _events = [];

  /// How far the stack has risen towards the next row (0..1).
  double rise = 0;
  int score = 0;
  int level = 1;
  int cleared = 0;
  int maxChain = 1;
  double time = 0;

  /// The chain in progress: 1 until a fall makes a match.
  int chainCount = 1;

  /// The rise pauses after combos and chains.
  double stopTime = 0;
  double grace = 0;
  bool danger = false;
  bool raising = false;
  bool timeUp = false;

  int cursorX = 2;
  int cursorY = 8;

  int _nextId = 0;
  double _garbageIn = 0;

  bool get isOver => status == ChainStatus.over;
  bool get isTimeAttack => mode == ChainMode.timeAttack;
  double get remaining => isTimeAttack ? max(0, timeAttackLength - time) : 0;

  /// How long the stack may touch the top before the game ends.
  double get graceTime => difficulty.grace;

  /// Share of the grace period used up while the stack touches the top.
  double get graceUsed => grace / graceTime;

  double secondsPerRow(int level) => difficulty.secondsPerRow(level);

  bool get busy => _groups.isNotEmpty || slabs.any((s) => s.breaking);

  List<ChainEvent> drainEvents() {
    final out = List<ChainEvent>.of(_events);
    _events.clear();
    return out;
  }

  // ---------------------------------------------------------------- start --

  void start(ChainMode mode, {ChainDifficulty difficulty = ChainDifficulty.normal}) {
    this.mode = mode;
    this.difficulty = difficulty;
    for (final row in board) {
      row.fillRange(0, width, null);
    }
    slabs.clear();
    _groups.clear();
    _events.clear();
    rise = 0;
    score = cleared = 0;
    level = 1;
    maxChain = chainCount = 1;
    time = stopTime = grace = 0;
    danger = raising = timeUp = false;
    cursorX = 2;
    cursorY = 8;
    _garbageIn = difficulty.firstGarbage;
    // Uneven starting stack, 4 to 6 high, without ready-made matches.
    final heights = [for (var x = 0; x < width; x++) 4 + _random.nextInt(3)];
    for (var y = height - 1; y >= 0; y--) {
      for (var x = 0; x < width; x++) {
        if (height - y <= heights[x]) board[y][x] = ChainBlock(_nextId++, _pick(x, y));
      }
    }
    incoming = _newRow();
    status = ChainStatus.playing;
  }

  /// A colour that does not complete three in a row with what is already
  /// placed left of and below ([x], [y]).
  ChainColor _pick(int x, int y, {List<ChainBlock?>? row, List<ChainBlock?>? above1, List<ChainBlock?>? above2}) {
    ChainColor? left1 = x > 0 ? (row ?? board[y])[x - 1]?.color : null;
    ChainColor? left2 = x > 1 ? (row ?? board[y])[x - 2]?.color : null;
    ChainColor? down1 = row == null && y + 1 < height ? board[y + 1][x]?.color : above1?[x]?.color;
    ChainColor? down2 = row == null && y + 2 < height ? board[y + 2][x]?.color : above2?[x]?.color;
    for (var i = 0; i < 20; i++) {
      final c = _random.nextInt(30) == 0 ? ChainColor.gray : ChainColor.values[_random.nextInt(difficulty.colors)];
      if (left1 == c && left2 == c) continue;
      if (down1 == c && down2 == c) continue;
      return c;
    }
    return ChainColor.values[_random.nextInt(difficulty.colors)];
  }

  /// The next row to rise in from below, matching nothing it will touch.
  List<ChainBlock> _newRow() {
    final row = List<ChainBlock?>.filled(width, null);
    for (var x = 0; x < width; x++) {
      // Above it, once it rises, are today's two bottom rows.
      final c = _pick(x, height, row: row, above1: board[height - 1], above2: board[height - 2]);
      row[x] = ChainBlock(_nextId++, c);
    }
    return row.cast<ChainBlock>();
  }

  // ---------------------------------------------------------------- input --

  void moveCursor(int dx, int dy) {
    cursorX = (cursorX + dx).clamp(0, width - 2);
    cursorY = (cursorY + dy).clamp(0, height - 1);
  }

  void setCursor(int x, int y) {
    cursorX = x.clamp(0, width - 2);
    cursorY = y.clamp(0, height - 1);
  }

  bool swapAtCursor() => swap(cursorX, cursorY);

  bool _swappable(ChainBlock? b) => b == null || (!b.isGarbage && b.state == BlockState.idle);

  /// Swaps the cells at ([x], [y]) and ([x] + 1, [y]).
  bool swap(int x, int y) {
    if (status != ChainStatus.playing || x < 0 || x >= width - 1 || y < 0 || y >= height) return false;
    final a = board[y][x], b = board[y][x + 1];
    if (a == null && b == null) return false;
    if (!_swappable(a) || !_swappable(b)) return false;
    // A cube cannot slide in right under one that is about to fall.
    if (y > 0) {
      for (final (cell, arriving) in [(x, b), (x + 1, a)]) {
        final above = board[y - 1][cell];
        if (arriving != null && above != null && !above.isGarbage && (above.state == BlockState.hovering || above.state == BlockState.falling)) {
          return false;
        }
      }
    }
    board[y][x] = b;
    board[y][x + 1] = a;
    for (final (block, from) in [(b, 1), (a, -1)]) {
      if (block == null) continue;
      block
        ..state = BlockState.swapping
        ..timer = swapTime
        ..swapFrom = from;
    }
    _events.add(ChainSwapped(x, y));
    return true;
  }

  // --------------------------------------------------------------- update --

  void update(double dt) {
    if (status != ChainStatus.playing || dt <= 0) return;
    time += dt;
    if (isTimeAttack && time >= timeAttackLength) {
      timeUp = true;
      _end(timeUp: true);
      return;
    }
    final newLevel = min(maxLevel, 1 + time ~/ (isTimeAttack ? difficulty.levelEvery / 2 : difficulty.levelEvery));
    if (newLevel != level) {
      level = newLevel;
      _events.add(ChainLevelUp(level));
    }
    _updateSwaps(dt);
    _updateClears(dt);
    _updateGravity(dt);
    _findMatches();
    _settleChains();
    _updateRise(dt);
    if (status != ChainStatus.playing) return;
    if (!isTimeAttack && difficulty.garbage) _updateGarbage(dt);
    _updateDanger();
  }

  void _updateSwaps(double dt) {
    for (final row in board) {
      for (final b in row) {
        if (b == null || b.state != BlockState.swapping) continue;
        b.timer -= dt;
        if (b.timer <= 0) {
          b
            ..state = BlockState.idle
            ..timer = 0
            ..swapFrom = 0;
        }
      }
    }
  }

  (int, int)? _find(ChainBlock block) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (identical(board[y][x], block)) return (x, y);
      }
    }
    return null;
  }

  void _updateClears(double dt) {
    for (final g in List.of(_groups)) {
      g.t += dt;
      while (g.popped < g.blocks.length && g.t >= flashTime + g.popped * popInterval) {
        final b = g.blocks[g.popped];
        b.popped = true;
        final at = _find(b);
        if (at != null) _events.add(ChainPopped(at.$1, at.$2, b.color, g.popped, g.chain));
        g.popped++;
      }
      if (g.t < flashTime + g.blocks.length * popInterval + popTail) continue;
      _groups.remove(g);
      final emptied = <(int, int)>[];
      for (final b in g.blocks) {
        final at = _find(b);
        if (at == null) continue;
        board[at.$2][at.$1] = null;
        emptied.add(at);
      }
      for (final slab in g.slabs) {
        _breakSlab(slab);
      }
      // Everything resting above the gap falls, and may chain.
      for (final (x, y) in emptied) {
        for (var yy = y - 1; yy >= 0; yy--) {
          final b = board[yy][x];
          if (b == null || b.isGarbage || b.state == BlockState.clearing) break;
          if (b.state == BlockState.idle || b.state == BlockState.hovering) {
            b
              ..chain = true
              ..state = BlockState.hovering
              ..timer = chainHoverTime;
          }
        }
      }
    }
  }

  void _breakSlab(GarbageSlab slab) {
    slabs.remove(slab);
    for (var i = 0; i < slab.width; i++) {
      final x = slab.x + i;
      if (slab.y < 0 || slab.y >= height) continue;
      final cube = ChainBlock(_nextId++, ChainColor.values[_random.nextInt(difficulty.colors)])..chain = true;
      board[slab.y][x] = cube;
    }
    score += slab.width * 5;
    _events.add(ChainGarbageBroken(slab.x, slab.y, slab.width));
  }

  bool _emptyBelow(int x, int y) => y + 1 < height && board[y + 1][x] == null;

  void _updateGravity(double dt) {
    // Cubes with nothing under them hover for a moment, together with
    // everything stacked on them, then fall.
    for (var y = height - 2; y >= 0; y--) {
      for (var x = 0; x < width; x++) {
        final b = board[y][x];
        if (b == null || b.isGarbage || b.state != BlockState.idle || !_emptyBelow(x, y)) continue;
        for (var yy = y; yy >= 0; yy--) {
          final above = board[yy][x];
          if (above == null || above.isGarbage || above.state != BlockState.idle) break;
          above
            ..state = BlockState.hovering
            ..timer = hoverTime;
        }
      }
    }
    for (var y = height - 1; y >= 0; y--) {
      for (var x = 0; x < width; x++) {
        final b = board[y][x];
        if (b == null || b.isGarbage) continue;
        if (b.state == BlockState.hovering) {
          b.timer -= dt;
          if (b.timer > 0) continue;
          final below = y + 1 < height ? board[y + 1][x] : null;
          // A stack hovers and falls together: the cube under this one may
          // have just started falling.
          if (_emptyBelow(x, y) || (below != null && !below.isGarbage && below.state == BlockState.falling)) {
            b
              ..state = BlockState.falling
              ..fall = 0;
          } else {
            b.state = BlockState.idle;
          }
        }
        if (b.state != BlockState.falling) continue;
        b.fall += dt * fallSpeed;
        var row = y;
        while (true) {
          if (!_emptyBelow(x, row)) {
            final below = row + 1 < height ? board[row + 1][x] : null;
            // Keep pace with a cube falling right below; land otherwise.
            if (below != null && below.state == BlockState.falling && !below.isGarbage) break;
            b
              ..state = BlockState.idle
              ..fall = 0;
            break;
          }
          if (b.fall < 1) break;
          board[row + 1][x] = b;
          board[row][x] = null;
          row++;
          b.fall -= 1;
        }
      }
    }
    // Slabs fall as a whole, lowest first.
    final order = List.of(slabs)..sort((a, b) => b.y.compareTo(a.y));
    for (final s in order) {
      if (s.breaking) continue;
      bool canDrop() {
        if (s.y + 1 >= height) return false;
        for (var i = 0; i < s.width; i++) {
          if (board[s.y + 1][s.x + i] != null) return false;
        }
        return true;
      }

      if (!s.falling) {
        if (!canDrop()) continue;
        s
          ..falling = true
          ..fall = 0;
      }
      s.fall += dt * fallSpeed;
      while (s.falling) {
        if (!canDrop()) {
          s
            ..falling = false
            ..fall = 0;
          break;
        }
        if (s.fall < 1) break;
        for (var i = 0; i < s.width; i++) {
          board[s.y + 1][s.x + i] = board[s.y][s.x + i];
          board[s.y][s.x + i] = null;
        }
        s.y++;
        s.fall -= 1;
      }
    }
  }

  bool _matchable(ChainBlock? b) => b != null && !b.isGarbage && b.state == BlockState.idle;

  void _findMatches() {
    final hits = <(int, int)>{};
    for (var y = 0; y < height; y++) {
      var x = 0;
      while (x < width) {
        final b = board[y][x];
        var end = x + 1;
        if (_matchable(b)) {
          while (end < width && _matchable(board[y][end]) && board[y][end]!.color == b!.color) {
            end++;
          }
          if (end - x >= 3) {
            for (var i = x; i < end; i++) {
              hits.add((i, y));
            }
          }
        }
        x = end;
      }
    }
    for (var x = 0; x < width; x++) {
      var y = 0;
      while (y < height) {
        final b = board[y][x];
        var end = y + 1;
        if (_matchable(b)) {
          while (end < height && _matchable(board[end][x]) && board[end][x]!.color == b!.color) {
            end++;
          }
          if (end - y >= 3) {
            for (var i = y; i < end; i++) {
              hits.add((x, i));
            }
          }
        }
        y = end;
      }
    }
    if (hits.isEmpty) return;
    final cells = hits.toList()..sort((a, b) => a.$2 != b.$2 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));
    final blocks = [for (final (x, y) in cells) board[y][x]!];
    final chained = blocks.any((b) => b.chain);
    if (chained) chainCount++;
    final chain = chained ? chainCount : 1;
    maxChain = max(maxChain, chain);
    for (final b in blocks) {
      b
        ..state = BlockState.clearing
        ..chain = false
        ..popped = false;
    }
    // Garbage touching the match, and garbage touching that, breaks too.
    final broken = <GarbageSlab>{};
    void touch(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final s = board[y][x]?.slab;
      if (s == null || s.breaking || broken.contains(s)) return;
      broken.add(s);
      for (var i = 0; i < s.width; i++) {
        touch(s.x + i, s.y - 1);
        touch(s.x + i, s.y + 1);
      }
      touch(s.x - 1, s.y);
      touch(s.x + s.width, s.y);
    }

    for (final (x, y) in cells) {
      touch(x - 1, y);
      touch(x + 1, y);
      touch(x, y - 1);
      touch(x, y + 1);
    }
    for (final s in broken) {
      s.breaking = true;
    }
    final grays = blocks.where((b) => b.color == ChainColor.gray).length;
    final points = 10 * blocks.length + comboBonus(blocks.length) + chainBonus(chain) + grays * 30;
    score += points;
    cleared += blocks.length;
    // Big clears buy time: the stack waits before it rises again.
    if (blocks.length >= 4) stopTime += (0.8 + 0.25 * (blocks.length - 4)) * difficulty.stopScale;
    if (chain >= 2) stopTime += (1.2 + 0.4 * (chain - 2)) * difficulty.stopScale;
    stopTime = min(stopTime, 6 * difficulty.stopScale);
    _groups.add(_ClearGroup(blocks, chain, broken));
    _events.add(ChainMatched(
      cells: [for (var i = 0; i < cells.length; i++) (cells[i].$1, cells[i].$2, blocks[i].color)],
      chain: chain,
      points: points,
      grays: grays,
      garbage: broken.fold(0, (n, s) => n + s.width),
    ));
  }

  static int comboBonus(int size) => size < 4 ? 0 : (size - 3) * 20 + (size >= 7 ? (size - 6) * 30 : 0);

  static int chainBonus(int chain) => chain < 2 ? 0 : const [50, 80, 150, 300, 400, 500, 700, 900, 1100, 1300, 1500][min(chain - 2, 10)];

  void _settleChains() {
    var flagged = false;
    for (final row in board) {
      for (final b in row) {
        if (b == null) continue;
        // Came to rest without matching (matches were checked this tick):
        // it can no longer extend a chain.
        if (b.chain && b.state == BlockState.idle) b.chain = false;
        if (b.chain) flagged = true;
      }
    }
    if (!flagged && _groups.isEmpty && chainCount > 1) {
      _events.add(ChainEnded(chainCount));
      chainCount = 1;
    }
  }

  bool get _topOccupied => board[0].any((b) => b != null);

  void _updateRise(double dt) {
    if (busy) return;
    if (_topOccupied) {
      // Touching the top: the game ends unless something clears in time.
      final settled = board[0].any((b) => b != null && (b.isGarbage ? !b.slab!.falling : b.state == BlockState.idle));
      if (settled) {
        grace += dt;
        if (grace >= graceTime) _end(timeUp: false);
      }
      return;
    }
    grace = 0;
    if (raising) {
      stopTime = 0;
    } else if (stopTime > 0) {
      stopTime = max(0, stopTime - dt);
      return;
    }
    rise += dt * (raising ? manualRaiseSpeed : 1 / secondsPerRow(level));
    if (rise < 1) return;
    rise -= 1;
    for (var y = 0; y < height - 1; y++) {
      board[y] = board[y + 1];
    }
    board[height - 1] = List<ChainBlock?>.of(incoming);
    for (final s in slabs) {
      s.y--;
    }
    if (cursorY > 0) cursorY--;
    incoming = _newRow();
    if (raising) score += 1;
    _events.add(ChainRowRaised(manual: raising));
    if (_topOccupied) rise = 0;
  }

  void _updateGarbage(double dt) {
    _garbageIn -= dt;
    if (_garbageIn > 0) return;
    final w = 3 + _random.nextInt(4);
    final x = _random.nextInt(width - w + 1);
    for (var i = 0; i < w; i++) {
      if (board[0][x + i] != null || board[1][x + i] != null) {
        _garbageIn = 1;
        return;
      }
    }
    final slab = GarbageSlab(_nextId++, x, 0, w);
    slabs.add(slab);
    for (var i = 0; i < w; i++) {
      board[0][x + i] = ChainBlock(_nextId++, ChainColor.gray, slab: slab);
    }
    _events.add(ChainGarbageDropped(slab));
    _garbageIn = max(difficulty.garbageEvery * 0.45, difficulty.garbageEvery - level * 2);
  }

  void _updateDanger() {
    final now = board.take(3).any((row) => row.any((b) => b != null && !b.isGarbage));
    if (now != danger) {
      danger = now;
      _events.add(ChainDanger(now));
    }
  }

  void _end({required bool timeUp}) {
    status = ChainStatus.over;
    raising = false;
    _events.add(ChainGameOver(timeUp: timeUp));
  }

  // ---------------------------------------------------------------- tests --

  static const _letters = {
    'Y': ChainColor.yellow,
    'M': ChainColor.magenta,
    'B': ChainColor.blue,
    'G': ChainColor.green,
    'O': ChainColor.orange,
    'W': ChainColor.gray,
  };

  /// Test helper: rows top to bottom ('.' empty, YMBGOW colours, '#' a
  /// garbage cell; neighbouring '#' in a row make one slab). Missing top rows
  /// are empty.
  void debugSetBoard(List<String> rows) {
    slabs.clear();
    _groups.clear();
    final offset = height - rows.length;
    for (var y = 0; y < height; y++) {
      board[y] = List<ChainBlock?>.filled(width, null);
      if (y < offset) continue;
      final line = rows[y - offset];
      var x = 0;
      while (x < width) {
        final ch = line[x];
        if (ch == '#') {
          var end = x;
          while (end < width && line[end] == '#') {
            end++;
          }
          final slab = GarbageSlab(_nextId++, x, y, end - x);
          slabs.add(slab);
          for (var i = x; i < end; i++) {
            board[y][i] = ChainBlock(_nextId++, ChainColor.gray, slab: slab);
          }
          x = end;
          continue;
        }
        if (ch != '.') board[y][x] = ChainBlock(_nextId++, _letters[ch]!);
        x++;
      }
    }
    rise = 0;
  }

  void debugSetIncoming(String row) {
    incoming = [for (final ch in row.split('')) ChainBlock(_nextId++, _letters[ch]!)];
  }

  /// Test helper: the board as letters, like [debugSetBoard] takes it.
  List<String> debugRows() => [
    for (final row in board)
      row.map((b) => b == null ? '.' : (b.isGarbage ? '#' : _letters.entries.firstWhere((e) => e.value == b.color).key)).join(),
  ];
}
