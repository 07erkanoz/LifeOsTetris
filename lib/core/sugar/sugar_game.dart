import 'dart:math';

/// Şeker Küpler: swap two neighbouring sweets so three or more of a colour
/// line up. Four in a row make a striped sweet, an L or T a wrapped one,
/// five in a row a rainbow ball; specials fire when matched or hit, and two
/// specials swapped together combine. Levels give moves and goals, and may
/// hold ice, chains, candy boxes and timed bombs.
///
/// Pure game logic. Time does not pass here: [SugarGame.advance] runs the
/// next phase of a move (a blast, a clear, the fall and refill) so a screen
/// can animate each one before asking for the next.

enum SugarColor { red, orange, yellow, green, blue, purple }

/// lineH/lineV: striped, bomb: wrapped, prism: rainbow ball.
enum Special { none, lineH, lineV, bomb, prism }

class SugarPiece {
  SugarPiece(this.id, this.color, {this.special = Special.none, this.chained = false, this.timer});

  final int id;
  SugarColor color;
  Special special;

  /// Chained sweets cannot be swapped; a match or blast breaks the chain.
  bool chained;

  /// A timed bomb: moves left before it goes off (null for other sweets).
  int? timer;

  bool get isPrism => special == Special.prism;
  bool get isLine => special == Special.lineH || special == Special.lineV;
  bool get isBomb => timer != null;

  SugarPiece copy() => SugarPiece(id, color, special: special, chained: chained, timer: timer);
}

typedef Cell = (int, int);

enum GoalKind { score, color, ice, box }

class SugarGoal {
  SugarGoal.score(this.target)
      : kind = GoalKind.score,
        color = null;
  SugarGoal.color(SugarColor this.color, this.target) : kind = GoalKind.color;
  SugarGoal.ice(this.target)
      : kind = GoalKind.ice,
        color = null;
  SugarGoal.box(this.target)
      : kind = GoalKind.box,
        color = null;

  final GoalKind kind;
  final SugarColor? color;
  final int target;
  int progress = 0;

  bool get done => progress >= target;
  int get left => max(0, target - progress);

  SugarGoal copy() {
    final g = switch (kind) {
      GoalKind.score => SugarGoal.score(target),
      GoalKind.color => SugarGoal.color(color!, target),
      GoalKind.ice => SugarGoal.ice(target),
      GoalKind.box => SugarGoal.box(target),
    };
    return g..progress = progress;
  }
}

/// A level. Layout rows: '.' plain, 'i' ice, 'I' thick ice, 'c' chained,
/// 'C' chained on ice, 'K' candy box (two layers), 'k' box (one layer),
/// 'T' a timed bomb.
class SugarLevel {
  const SugarLevel({
    required this.number,
    required this.moves,
    required this.colors,
    required this.layout,
    required this.goals,
    required this.stars,
    this.boss = false,
    this.hard = false,
    this.hint,
    this.bombTimer = 9,
    this.bombEvery = 0,
    this.luck = 0,
    this.gifts = 0,
    this.rush = 45,
    this.calm = 55,
  });

  final int number;
  final int moves;
  final int colors;
  final List<String> layout;
  final List<SugarGoal Function()> goals;

  /// Scores for one, two and three stars (one also needs the goals).
  final List<int> stars;
  final bool boss;
  final bool hard;

  /// Introduces something new on its first level (a key into the strings).
  final String? hint;

  /// Moves a timed bomb starts with; a new one drops every [bombEvery]
  /// moves (0: only those in the layout).
  final int bombTimer;
  final int bombEvery;

  /// Out of a thousand new sweets, how many arrive as specials.
  final int luck;

  /// Specials on the board at the start.
  final int gifts;

  /// Sweets cleared to fill the sugar-rush meter.
  final int rush;

  /// Out of a hundred new sweets, how many are kept from matching on
  /// landing (lower: more free cascades).
  final int calm;
}

// ----------------------------------------------------------------- events --

sealed class SugarEvent {
  const SugarEvent();
}

class SugarSwapped extends SugarEvent {
  const SugarSwapped(this.a, this.b);
  final Cell a, b;
}

class SugarSwapRejected extends SugarEvent {
  const SugarSwapRejected(this.a, this.b);
  final Cell a, b;
}

/// Sweets removed: by a match, a blast or the hammer.
class SugarCleared extends SugarEvent {
  const SugarCleared(this.pieces, {required this.cascade, required this.points});
  final List<(int, int, SugarPiece)> pieces;
  final int cascade;
  final int points;
}

class SugarCreated extends SugarEvent {
  const SugarCreated(this.x, this.y, this.piece);
  final int x, y;
  final SugarPiece piece;
}

/// A special fired: [cells] are the cells it hit; [combo] for two specials
/// swapped together.
class SugarBlast extends SugarEvent {
  const SugarBlast(this.kind, this.x, this.y, this.cells, {this.combo = false});
  final Special kind;
  final int x, y;
  final List<Cell> cells;
  final bool combo;
}

class SugarIceCracked extends SugarEvent {
  const SugarIceCracked(this.x, this.y, this.left);
  final int x, y, left;
}

class SugarUnchained extends SugarEvent {
  const SugarUnchained(this.x, this.y);
  final int x, y;
}

/// A candy box took a hit; [left] layers remain (0: gone).
class SugarBoxHit extends SugarEvent {
  const SugarBoxHit(this.x, this.y, this.left);
  final int x, y, left;
}

/// Sweets moved down (or down a side): new ones come from above the board
/// (a negative from row).
class SugarFell extends SugarEvent {
  const SugarFell(this.moves);
  final List<(int id, int fromX, int fromY, int toX, int toY)> moves;
}

/// A special arrived with the refill.
class SugarLucky extends SugarEvent {
  const SugarLucky(this.x, this.y, this.piece);
  final int x, y;
  final SugarPiece piece;
}

/// Timed bombs counted down after a move.
class SugarBombTick extends SugarEvent {
  const SugarBombTick(this.bombs);
  final List<(int x, int y, int left)> bombs;
}

/// A timed bomb reached zero: the level is lost.
class SugarBombExploded extends SugarEvent {
  const SugarBombExploded(this.x, this.y);
  final int x, y;
}

/// The sugar-rush meter was full: specials appear at [cells] and fire.
class SugarRush extends SugarEvent {
  const SugarRush(this.cells);
  final List<Cell> cells;
}

/// The score passed the step for star [star] (1..3).
class SugarStarReached extends SugarEvent {
  const SugarStarReached(this.star);
  final int star;
}

class SugarShuffled extends SugarEvent {
  const SugarShuffled();
}

/// Goals met with [moves] left: each becomes a striped sweet and fires.
class SugarFinale extends SugarEvent {
  const SugarFinale(this.moves);
  final int moves;
}

/// One move of the finale firing, worth [points].
class SugarFinaleShot extends SugarEvent {
  const SugarFinaleShot(this.x, this.y, this.points, this.index);
  final int x, y, points, index;
}

class SugarWon extends SugarEvent {
  const SugarWon(this.stars, this.score);
  final int stars, score;
}

class SugarLost extends SugarEvent {
  const SugarLost({this.bomb = false});
  final bool bomb;
}

enum SugarStatus { ready, idle, resolving, won, lost }

/// Small, copyable random numbers (xorshift), so a game can be cloned and
/// replayed exactly.
class SugarRandom {
  SugarRandom(int seed) : _s = seed == 0 ? 0x9E3779B9 : seed & 0xFFFFFFFF;

  int _s;

  int next(int max) {
    var x = _s;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _s = x & 0xFFFFFFFF;
    return _s % max;
  }

  SugarRandom copy() => SugarRandom(1).._s = _s;
}

class SugarGame {
  SugarGame({int seed = 1}) : _rnd = SugarRandom(seed);

  static const int size = 8;

  /// Points per sweet in a match (times the cascade).
  static const int matchPoints = 20;
  static const int blastPoints = 40;

  SugarRandom _rnd;
  SugarLevel? level;
  SugarStatus status = SugarStatus.ready;

  List<List<SugarPiece?>> board = [for (var y = 0; y < size; y++) List<SugarPiece?>.filled(size, null)];
  List<List<int>> ice = [for (var y = 0; y < size; y++) List<int>.filled(size, 0)];

  /// Candy box layers per cell (0: no box). A box cell holds no sweet.
  List<List<int>> box = [for (var y = 0; y < size; y++) List<int>.filled(size, 0)];
  List<SugarGoal> goals = [];
  int colors = 5;
  int moves = 0;
  int score = 0;
  int cascade = 0;
  int bestCascade = 0;

  /// 0..1; full sets off a sugar rush.
  double rushMeter = 0;
  int movesMade = 0;
  int _nextId = 1;

  final List<(int, int, SugarPiece)> _fire = [];
  bool _needGravity = false;
  bool _needMatch = false;
  bool _moveDone = false;
  bool _bombDue = false;
  bool _rushing = false;
  bool _comboBlast = false;
  int _blastBoost = 1;
  bool _finaleStarted = false;
  int _finaleLeft = 0;
  int _finaleShots = 0;
  int _finaleRounds = 0;
  int _starsShown = 0;
  Cell? _swapA, _swapB;
  final List<SugarEvent> _events = [];

  bool get isOver => status == SugarStatus.won || status == SugarStatus.lost;
  bool get goalsDone => goals.every((g) => g.done);
  bool get inFinale => _finaleStarted;
  int get iceLeft => ice.fold(0, (n, row) => n + row.where((h) => h > 0).length);
  int get boxesLeft => box.fold(0, (n, row) => n + row.where((h) => h > 0).length);

  /// Only score goals: the level plays every move before it ends.
  bool get playsAllMoves => goals.isNotEmpty && goals.every((g) => g.kind == GoalKind.score);

  int get starCount {
    final s = level?.stars ?? const [0, 0, 0];
    if (!goalsDone) return 0;
    return score >= s[2] ? 3 : (score >= s[1] ? 2 : 1);
  }

  List<SugarEvent> drainEvents() {
    final out = List<SugarEvent>.of(_events);
    _events.clear();
    return out;
  }

  // ---------------------------------------------------------------- start --

  void start(SugarLevel level) {
    this.level = level;
    colors = level.colors;
    moves = level.moves;
    score = cascade = bestCascade = movesMade = 0;
    rushMeter = 0;
    _fire.clear();
    _needGravity = _needMatch = _moveDone = _bombDue = _rushing = _finaleStarted = false;
    _finaleLeft = _finaleShots = _finaleRounds = _starsShown = 0;
    _events.clear();
    goals = [for (final g in level.goals) g()];
    for (var y = 0; y < size; y++) {
      board[y].fillRange(0, size, null);
      box[y].fillRange(0, size, 0);
    }
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final ch = level.layout[y][x];
        ice[y][x] = switch (ch) {
          'i' || 'C' => 1,
          'I' => 2,
          _ => 0,
        };
        box[y][x] = switch (ch) {
          'K' => 2,
          'k' => 1,
          _ => 0,
        };
        if (box[y][x] > 0) continue;
        final p = _newPiece(avoidAt: (x, y))..chained = ch == 'c' || ch == 'C';
        if (ch == 'T') p.timer = level.bombTimer;
        board[y][x] = p;
      }
    }
    // Gifts: a few specials to start with.
    final plain = _plainCells();
    for (var i = 0; i < level.gifts && plain.isNotEmpty; i++) {
      final (x, y) = plain.removeAt(_rnd.next(plain.length));
      board[y][x]!.special = const [Special.lineH, Special.lineV, Special.bomb][_rnd.next(3)];
    }
    if (!hasMove()) _shuffle();
    _needMatch = false;
    _events.clear();
    status = SugarStatus.idle;
  }

  List<Cell> _plainCells() => [
    for (var y = 0; y < size; y++)
      for (var x = 0; x < size; x++)
        if (board[y][x] case final p? when p.special == Special.none && !p.chained && !p.isBomb) (x, y),
  ];

  SugarPiece _newPiece({Cell? avoidAt}) {
    for (var i = 0; i < 12; i++) {
      final c = SugarColor.values[_rnd.next(colors)];
      if (avoidAt != null && _wouldMatch(avoidAt.$1, avoidAt.$2, c)) continue;
      return SugarPiece(_nextId++, c);
    }
    return SugarPiece(_nextId++, SugarColor.values[_rnd.next(colors)]);
  }

  /// Would colour [c] at ([x], [y]) line up three with its neighbours.
  bool _wouldMatch(int x, int y, SugarColor c) {
    bool same(int x, int y) => x >= 0 && y >= 0 && x < size && y < size && board[y][x] != null && !board[y][x]!.isPrism && board[y][x]!.color == c;
    return (same(x - 1, y) && (same(x - 2, y) || same(x + 1, y))) ||
        (same(x + 1, y) && same(x + 2, y)) ||
        (same(x, y - 1) && (same(x, y - 2) || same(x, y + 1))) ||
        (same(x, y + 1) && same(x, y + 2));
  }

  // ---------------------------------------------------------------- moves --

  bool _inside(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

  bool canSwap(Cell a, Cell b) {
    if (status != SugarStatus.idle || moves <= 0) return false;
    final (ax, ay) = a;
    final (bx, by) = b;
    if (!_inside(ax, ay) || !_inside(bx, by) || (ax - bx).abs() + (ay - by).abs() != 1) return false;
    final pa = board[ay][ax], pb = board[by][bx];
    if (pa == null || pb == null || pa.chained || pb.chained) return false;
    return true;
  }

  /// Swaps two neighbours. A swap that makes no match (and involves no
  /// special pair or rainbow ball) is undone.
  bool swap(Cell a, Cell b) {
    if (!canSwap(a, b)) return false;
    final (ax, ay) = a;
    final (bx, by) = b;
    final pa = board[ay][ax]!, pb = board[by][bx]!;
    final combo = (pa.special != Special.none && pb.special != Special.none) || pa.isPrism || pb.isPrism;
    board[ay][ax] = pb;
    board[by][bx] = pa;
    if (!combo && _groups().isEmpty) {
      board[ay][ax] = pa;
      board[by][bx] = pb;
      _events.add(SugarSwapRejected(a, b));
      return false;
    }
    _events.add(SugarSwapped(a, b));
    moves--;
    movesMade++;
    cascade = 0;
    _moveDone = true;
    _rushing = false;
    final every = level?.bombEvery ?? 0;
    if (every > 0 && movesMade % every == 0) _bombDue = true;
    _swapA = a;
    _swapB = b;
    status = SugarStatus.resolving;
    if (combo) {
      _combine(b, a, pa, pb);
    } else {
      _needMatch = true;
    }
    return true;
  }

  /// [pa] moved to [at], [pb] to [from].
  void _combine(Cell at, Cell from, SugarPiece pa, SugarPiece pb) {
    final (x, y) = at;
    final specials = {pa.special, pb.special};
    for (final (c, p) in [(at, pa), (from, pb)]) {
      if (p.isPrism) {
        board[c.$2][c.$1] = null;
      } else if (!(pa.isPrism || pb.isPrism)) {
        p.special = Special.none;
      }
    }
    _comboBlast = true;
    if (pa.isPrism && pb.isPrism) {
      _blast(Special.prism, x, y, [for (var yy = 0; yy < size; yy++) for (var xx = 0; xx < size; xx++) (xx, yy)]);
    } else if (pa.isPrism || pb.isPrism) {
      final other = pa.isPrism ? pb : pa;
      final targets = [
        for (var yy = 0; yy < size; yy++)
          for (var xx = 0; xx < size; xx++)
            if (board[yy][xx] != null && !board[yy][xx]!.isPrism && board[yy][xx]!.color == other.color) (xx, yy),
      ];
      if (other.special != Special.none) {
        // Every sweet of that colour turns into the other special and fires.
        for (final (xx, yy) in targets) {
          final p = board[yy][xx]!;
          p.special = other.special == Special.bomb ? Special.bomb : (_rnd.next(2) == 0 ? Special.lineH : Special.lineV);
          _events.add(SugarCreated(xx, yy, p));
        }
      }
      _blast(Special.prism, x, y, targets);
    } else if (specials.contains(Special.bomb) && specials.length == 1) {
      _blast(Special.bomb, x, y, _area(x, y, 2));
    } else if (specials.contains(Special.bomb)) {
      _blast(Special.bomb, x, y, [
        for (var d = -1; d <= 1; d++) ...[for (var xx = 0; xx < size; xx++) (xx, y + d), for (var yy = 0; yy < size; yy++) (x + d, yy)],
      ]);
    } else {
      _blast(Special.lineH, x, y, [for (var xx = 0; xx < size; xx++) (xx, y), for (var yy = 0; yy < size; yy++) (x, yy)]);
    }
    _comboBlast = false;
  }

  List<Cell> _area(int x, int y, int r) => [
    for (var yy = y - r; yy <= y + r; yy++)
      for (var xx = x - r; xx <= x + r; xx++) (xx, yy),
  ];

  List<Cell> _reach(Special s, int x, int y) => switch (s) {
    Special.lineH => [for (var xx = 0; xx < size; xx++) (xx, y)],
    Special.lineV => [for (var yy = 0; yy < size; yy++) (x, yy)],
    Special.bomb => _area(x, y, 1),
    Special.prism => _prismTargets(),
    Special.none => [(x, y)],
  };

  /// A rainbow ball hit by a blast takes the most common colour with it.
  List<Cell> _prismTargets() {
    final count = <SugarColor, int>{};
    for (final row in board) {
      for (final p in row) {
        if (p != null && !p.isPrism) count[p.color] = (count[p.color] ?? 0) + 1;
      }
    }
    if (count.isEmpty) return const [];
    final c = count.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    return [
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++)
          if (board[y][x] != null && !board[y][x]!.isPrism && board[y][x]!.color == c) (x, y),
    ];
  }

  /// Hits [cells]: removes sweets (chained ones lose their chain instead),
  /// cracks ice, knocks boxes, queues the specials it hits.
  void _blast(Special kind, int x, int y, List<Cell> cells) {
    final hit = {for (final c in cells) if (_inside(c.$1, c.$2)) c}.toList();
    _events.add(SugarBlast(kind, x, y, hit, combo: _comboBlast));
    final removed = <(int, int, SugarPiece)>[];
    var points = 0;
    final each = blastPoints * (_comboBlast ? 2 : 1) * _blastBoost;
    for (final (cx, cy) in hit) {
      if (box[cy][cx] > 0) {
        points += _knock(cx, cy);
        continue;
      }
      final p = board[cy][cx];
      if (p != null) {
        if (p.chained) {
          p.chained = false;
          points += 60;
          _events.add(SugarUnchained(cx, cy));
        } else {
          board[cy][cx] = null;
          removed.add((cx, cy, p));
          points += each;
          if (p.special != Special.none) _fire.add((cx, cy, p));
        }
      }
      points += _crack(cx, cy);
    }
    score += points;
    _count(removed);
    if (removed.isNotEmpty || points > 0) _events.add(SugarCleared(removed, cascade: cascade, points: points));
    _needGravity = true;
    _checkStars();
  }

  int _crack(int x, int y) {
    if (ice[y][x] <= 0) return 0;
    ice[y][x]--;
    _events.add(SugarIceCracked(x, y, ice[y][x]));
    if (ice[y][x] == 0) {
      for (final g in goals) {
        if (g.kind == GoalKind.ice) g.progress++;
      }
    }
    return 100;
  }

  /// One hit on the box at ([x], [y]).
  int _knock(int x, int y) {
    if (box[y][x] <= 0) return 0;
    box[y][x]--;
    _events.add(SugarBoxHit(x, y, box[y][x]));
    if (box[y][x] > 0) return 80;
    for (final g in goals) {
      if (g.kind == GoalKind.box) g.progress++;
    }
    return 200;
  }

  void _count(List<(int, int, SugarPiece)> removed) {
    for (final g in goals) {
      if (g.kind == GoalKind.color) g.progress += removed.where((r) => r.$3.color == g.color && !r.$3.isPrism).length;
      if (g.kind == GoalKind.score) g.progress = score;
    }
    final fill = level?.rush ?? 0;
    if (fill > 0 && !_rushing && !_finaleStarted) rushMeter = min(1, rushMeter + removed.length / fill);
  }

  void _checkStars() {
    for (final g in goals) {
      if (g.kind == GoalKind.score) g.progress = score;
    }
    final s = level?.stars;
    if (s == null) return;
    while (_starsShown < 3 && score >= s[_starsShown]) {
      _starsShown++;
      _events.add(SugarStarReached(_starsShown));
    }
  }

  // ------------------------------------------------------------- matching --

  /// Matches on the board: connected runs of one colour, with the special
  /// each makes (and where).
  List<({List<Cell> cells, Special make, Cell at, SugarColor color})> _groups() {
    final runs = <(List<Cell>, bool)>[];
    bool matchable(SugarPiece? p) => p != null && !p.isPrism;
    for (var y = 0; y < size; y++) {
      var x = 0;
      while (x < size) {
        final p = board[y][x];
        var end = x + 1;
        if (matchable(p)) {
          while (end < size && matchable(board[y][end]) && board[y][end]!.color == p!.color) {
            end++;
          }
          if (end - x >= 3) runs.add(([for (var i = x; i < end; i++) (i, y)], true));
        }
        x = end;
      }
    }
    for (var x = 0; x < size; x++) {
      var y = 0;
      while (y < size) {
        final p = board[y][x];
        var end = y + 1;
        if (matchable(p)) {
          while (end < size && matchable(board[end][x]) && board[end][x]!.color == p!.color) {
            end++;
          }
          if (end - y >= 3) runs.add(([for (var i = y; i < end; i++) (x, i)], false));
        }
        y = end;
      }
    }
    // Runs sharing a cell form one group (an L, a T, a cross).
    final groups = <({List<Cell> cells, Special make, Cell at, SugarColor color})>[];
    final used = List<bool>.filled(runs.length, false);
    for (var i = 0; i < runs.length; i++) {
      if (used[i]) continue;
      used[i] = true;
      final members = [runs[i]];
      var grew = true;
      while (grew) {
        grew = false;
        for (var j = 0; j < runs.length; j++) {
          if (used[j]) continue;
          final cells = {for (final m in members) ...m.$1};
          if (runs[j].$1.any(cells.contains)) {
            used[j] = true;
            members.add(runs[j]);
            grew = true;
          }
        }
      }
      final cells = {for (final m in members) ...m.$1}.toList();
      final longest = members.map((m) => m.$1.length).reduce(max);
      final crossed = members.any((m) => m.$2) && members.any((m) => !m.$2);
      final make = longest >= 5
          ? Special.prism
          : crossed
              ? Special.bomb
              : longest == 4
                  ? (members.first.$2 ? Special.lineV : Special.lineH)
                  : Special.none;
      // The special appears where the player moved, else in the middle.
      Cell at = cells[cells.length ~/ 2];
      for (final s in [_swapA, _swapB]) {
        if (s != null && cells.contains(s)) at = s;
      }
      if (crossed && make == Special.bomb) {
        final h = members.firstWhere((m) => m.$2).$1.toSet();
        final shared = members.where((m) => !m.$2).expand((m) => m.$1).where(h.contains);
        if (shared.isNotEmpty && !(cells.contains(_swapA) || cells.contains(_swapB))) at = shared.first;
      }
      groups.add((cells: cells, make: make, at: at, color: board[cells.first.$2][cells.first.$1]!.color));
    }
    return groups;
  }

  void _clearMatches(List<({List<Cell> cells, Special make, Cell at, SugarColor color})> groups) {
    cascade++;
    bestCascade = max(bestCascade, cascade);
    final removed = <(int, int, SugarPiece)>[];
    final knocked = <Cell>{};
    var points = 0;
    for (var g in groups) {
      if (g.make != Special.none && ((board[g.at.$2][g.at.$1]?.chained ?? false) || (board[g.at.$2][g.at.$1]?.isBomb ?? false))) {
        g = (cells: g.cells, make: Special.none, at: g.at, color: g.color);
      }
      points += (g.cells.length * matchPoints + switch (g.make) {
        Special.prism => 200,
        Special.bomb => 100,
        Special.lineH || Special.lineV => 60,
        Special.none => 0,
      }) * cascade;
      for (final (x, y) in g.cells) {
        // Boxes next to a match take a knock (once each per clear).
        for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final n = (x + dx, y + dy);
          if (_inside(n.$1, n.$2) && box[n.$2][n.$1] > 0 && knocked.add(n)) points += _knock(n.$1, n.$2);
        }
        final p = board[y][x];
        if (p == null) continue;
        if (p.chained) {
          p.chained = false;
          points += 60;
          _events.add(SugarUnchained(x, y));
          continue;
        }
        if ((x, y) == g.at && g.make != Special.none) continue;
        board[y][x] = null;
        removed.add((x, y, p));
        if (p.special != Special.none) _fire.add((x, y, p));
        points += _crack(x, y);
      }
      if (g.make != Special.none) {
        final (x, y) = g.at;
        final keep = board[y][x];
        final made = SugarPiece(_nextId++, g.color, special: g.make);
        if (keep != null) {
          // A special already there fires; the new one takes its place.
          if (keep.special != Special.none) _fire.add((x, y, keep));
          removed.add((x, y, keep));
          points += _crack(x, y);
        }
        board[y][x] = made;
        _events.add(SugarCreated(x, y, made));
      }
    }
    score += points;
    _count(removed);
    _events.add(SugarCleared(removed, cascade: cascade, points: points));
    _swapA = _swapB = null;
    _needGravity = true;
    _checkStars();
  }

  // -------------------------------------------------------------- gravity --

  bool _open(int x, int y) => box[y][x] == 0;

  /// Sweets fall straight down; under a box they slide in from the side.
  /// New ones come in at the top of each column that is open to the top.
  void _gravity() {
    final from = <int, (int, int)>{};
    final to = <int, (int, int)>{};
    void move(int fx, int fy, int tx, int ty) {
      final p = board[fy][fx]!;
      from.putIfAbsent(p.id, () => (fx, fy));
      to[p.id] = (tx, ty);
      board[ty][tx] = p;
      board[fy][fx] = null;
    }

    var lucky = false;
    final luck = _finaleStarted ? 0 : (level?.luck ?? 0);
    final calm = level?.calm ?? 55;
    for (var guard = 0; guard < 200; guard++) {
      var changed = false;
      // Straight down.
      for (var x = 0; x < size; x++) {
        for (var y = size - 1; y >= 0; y--) {
          if (board[y][x] != null || !_open(x, y)) continue;
          for (var k = y - 1; k >= 0 && _open(x, k); k--) {
            if (board[k][x] != null) {
              move(x, k, x, y);
              changed = true;
              break;
            }
          }
        }
      }
      // New sweets into the open top of each column.
      for (var x = 0; x < size; x++) {
        var count = 0;
        for (var y = 0; y < size && _open(x, y) && board[y][x] == null; y++) {
          count++;
        }
        for (var y = count - 1; y >= 0; y--) {
          // Some new sweets match on landing (cascades are fun), most do not.
          final p = _newPiece(avoidAt: _rnd.next(100) < calm ? (x, y) : null);
          if (_bombDue) {
            _bombDue = false;
            p.timer = level?.bombTimer ?? 9;
          } else if (!lucky && luck > 0 && _rnd.next(1000) < luck) {
            lucky = true;
            p.special = const [Special.lineH, Special.lineV, Special.bomb][_rnd.next(3)];
            _events.add(SugarLucky(x, y, p));
          }
          board[y][x] = p;
          from[p.id] = (x, y - count);
          to[p.id] = (x, y);
          changed = true;
        }
      }
      if (changed) continue;
      // Gaps under boxes: a sweet slides down from a side.
      var slid = false;
      for (var y = size - 1; y > 0 && !slid; y--) {
        for (var x = 0; x < size && !slid; x++) {
          if (board[y][x] != null || !_open(x, y)) continue;
          for (final dx in const [-1, 1]) {
            final sx = x + dx;
            if (sx < 0 || sx >= size || board[y - 1][sx] == null) continue;
            move(sx, y - 1, x, y);
            slid = true;
            break;
          }
        }
      }
      if (!slid) break;
    }
    _events.add(SugarFell([
      for (final e in to.entries) (e.key, from[e.key]!.$1, from[e.key]!.$2, e.value.$1, e.value.$2),
    ]));
  }

  // -------------------------------------------------------------- advance --

  /// Runs the next phase of the move in progress. Returns false once the
  /// board is settled and waits for the player (or the game is over).
  bool advance() {
    if (status != SugarStatus.resolving) return false;
    if (_fire.isNotEmpty) {
      final wave = List.of(_fire);
      _fire.clear();
      for (final (x, y, p) in wave) {
        _blast(p.special, x, y, _reach(p.special, x, y));
      }
      return true;
    }
    if (_needGravity) {
      _needGravity = false;
      _gravity();
      _needMatch = true;
      return true;
    }
    if (_needMatch) {
      final groups = _groups();
      if (groups.isNotEmpty) {
        _clearMatches(groups);
        return true;
      }
      _needMatch = false;
    }
    // The board is still.
    _blastBoost = 1;
    final early = goalsDone && !playsAllMoves;
    if (early || _finaleStarted) {
      if (_finaleStep()) return true;
      return _end(won: true);
    }
    if (moves <= 0) return _end(won: goalsDone);
    if (_moveDone) {
      _moveDone = false;
      if (_tickBombs()) return false;
    }
    if (rushMeter >= 1 && !_rushing) {
      _rush();
      return true;
    }
    if (!hasMove()) {
      _shuffle();
      return true;
    }
    status = SugarStatus.idle;
    return false;
  }

  bool _end({required bool won}) {
    if (won) {
      status = SugarStatus.won;
      _events.add(SugarWon(starCount, score));
    } else {
      status = SugarStatus.lost;
      _events.add(const SugarLost());
    }
    return false;
  }

  /// Runs every phase at once (tests, the solver).
  void settle() {
    while (advance()) {}
  }

  /// Counts the timed bombs down; true when one went off (level lost).
  bool _tickBombs() {
    final ticked = <(int, int, int)>[];
    Cell? boom;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final p = board[y][x];
        if (p == null || p.timer == null) continue;
        p.timer = p.timer! - 1;
        ticked.add((x, y, p.timer!));
        if (p.timer! <= 0) boom ??= (x, y);
      }
    }
    if (ticked.isNotEmpty) _events.add(SugarBombTick(ticked));
    if (boom == null) return false;
    status = SugarStatus.lost;
    _events.add(SugarBombExploded(boom.$1, boom.$2));
    _events.add(const SugarLost(bomb: true));
    return true;
  }

  /// The meter is full: two striped sweets and a wrapped one appear on the
  /// board and fire, worth double.
  void _rush() {
    _rushing = true;
    rushMeter = 0;
    _blastBoost = 2;
    final plain = _plainCells();
    final cells = <Cell>[];
    for (final kind in const [Special.lineH, Special.bomb, Special.lineV]) {
      if (plain.isEmpty) break;
      final (x, y) = plain.removeAt(_rnd.next(plain.length));
      final p = board[y][x]!..special = kind;
      _events.add(SugarCreated(x, y, p));
      board[y][x] = null;
      _fire.add((x, y, p));
      cells.add((x, y));
    }
    _events.add(SugarRush(cells));
    cascade = 0;
  }

  /// Goals met with moves left: each move left becomes a striped sweet that
  /// fires, two at a time, each worth more than the last; then every
  /// special left on the board fires. False when it has nothing left to do.
  bool _finaleStep() {
    if (!_finaleStarted) {
      _finaleStarted = true;
      _finaleLeft = moves;
      if (moves > 0) _events.add(SugarFinale(moves));
      moves = 0;
      if (_finaleLeft > 0) return true;
    }
    if (_finaleLeft > 0) {
      final plain = _plainCells();
      for (var i = 0, n = _finaleLeft > 8 ? 3 : 2; i < n && _finaleLeft > 0 && plain.isNotEmpty; i++) {
        _finaleLeft--;
        final (x, y) = plain.removeAt(_rnd.next(plain.length));
        final p = board[y][x]!..special = _rnd.next(2) == 0 ? Special.lineH : Special.lineV;
        _events.add(SugarCreated(x, y, p));
        board[y][x] = null;
        _fire.add((x, y, p));
        final points = 500 + 150 * _finaleShots;
        _events.add(SugarFinaleShot(x, y, points, _finaleShots));
        _finaleShots++;
        score += points;
      }
      if (plain.isEmpty) _finaleLeft = 0;
      _checkStars();
      return true;
    }
    if (_finaleRounds++ < 12) {
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          final p = board[y][x];
          if (p != null && p.special != Special.none && !p.chained) {
            _fire.add((x, y, p));
            board[y][x] = null;
          }
        }
      }
      if (_fire.isNotEmpty) return true;
    }
    return false;
  }

  // ------------------------------------------------------------ shuffling --

  /// Is there any swap that makes a match (or uses a special pair or ball)?
  bool hasMove() => findMove() != null;

  (Cell, Cell)? findMove() {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        for (final (dx, dy) in const [(1, 0), (0, 1)]) {
          final a = (x, y), b = (x + dx, y + dy);
          if (!_inside(b.$1, b.$2)) continue;
          final pa = board[y][x], pb = board[b.$2][b.$1];
          if (pa == null || pb == null || pa.chained || pb.chained) continue;
          if (pa.isPrism || pb.isPrism || (pa.special != Special.none && pb.special != Special.none)) return (a, b);
          board[y][x] = pb;
          board[b.$2][b.$1] = pa;
          final ok = _groups().isNotEmpty;
          board[y][x] = pa;
          board[b.$2][b.$1] = pb;
          if (ok) return (a, b);
        }
      }
    }
    return null;
  }

  void _shuffle() {
    final free = [
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++)
          if (board[y][x] != null && !board[y][x]!.chained) (x, y),
    ];
    for (var attempt = 0; attempt < 50; attempt++) {
      final pieces = [for (final (x, y) in free) board[y][x]!];
      for (var i = pieces.length - 1; i > 0; i--) {
        final j = _rnd.next(i + 1);
        final t = pieces[i];
        pieces[i] = pieces[j];
        pieces[j] = t;
      }
      for (var i = 0; i < free.length; i++) {
        board[free[i].$2][free[i].$1] = pieces[i];
      }
      if (attempt >= 25) {
        for (final p in pieces) {
          if (p.special == Special.none) p.color = SugarColor.values[_rnd.next(colors)];
        }
      }
      if (attempt == 49) {
        for (final row in board) {
          for (final p in row) {
            p?.chained = false;
          }
        }
      }
      if (_groups().isEmpty && hasMove()) break;
    }
    _events.add(const SugarShuffled());
    _needMatch = true;
    status = SugarStatus.resolving;
  }

  // ------------------------------------------------------------- boosters --

  /// The hammer: smashes one sweet (or a chain, a layer of ice, a box layer).
  bool hammer(int x, int y) {
    if (status != SugarStatus.idle || !_inside(x, y)) return false;
    if (board[y][x] == null && box[y][x] == 0) return false;
    cascade = 0;
    status = SugarStatus.resolving;
    _blast(Special.none, x, y, [(x, y)]);
    return true;
  }

  /// The rainbow booster: the sweet at ([x], [y]) becomes a rainbow ball.
  bool rainbow(int x, int y) {
    if (status != SugarStatus.idle || !_inside(x, y)) return false;
    final p = board[y][x];
    if (p == null || p.chained || p.isPrism) return false;
    p
      ..special = Special.prism
      ..timer = null;
    _events.add(SugarCreated(x, y, p));
    return true;
  }

  /// Shuffles the board (used when no move is left).
  bool shuffle() {
    if (status != SugarStatus.idle) return false;
    _shuffle();
    return true;
  }

  void addMoves(int n) {
    if (isOver) return;
    moves += n;
  }

  /// Out of moves (or a bomb went off): [n] more moves and play on; bombs
  /// get [n] more moves too.
  bool extraMoves(int n) {
    if (status != SugarStatus.lost) return false;
    moves += n;
    for (final row in board) {
      for (final p in row) {
        if (p?.timer != null) p!.timer = max(p.timer!, 0) + n;
      }
    }
    status = SugarStatus.resolving;
    _needMatch = true;
    return true;
  }

  // -------------------------------------------------------- saving, copies --

  Map<String, Object?> toSave() => {
    'v': 2,
    'level': level?.number,
    'moves': moves,
    'made': movesMade,
    'score': score,
    'rush': rushMeter,
    'rnd': _rnd._s,
    'next': _nextId,
    'board': [
      for (final row in board)
        [for (final p in row) p == null ? null : [p.color.index, p.special.index, p.chained ? 1 : 0, p.timer ?? -1]],
    ],
    'ice': ice,
    'box': box,
    'goals': [for (final g in goals) g.progress],
  };

  /// Continues a saved game of [level] (which must be the saved one).
  void restore(SugarLevel level, Map<String, Object?> save) {
    start(level);
    moves = save['moves'] as int;
    movesMade = (save['made'] as int?) ?? 0;
    score = save['score'] as int;
    rushMeter = ((save['rush'] as num?) ?? 0).toDouble();
    _rnd._s = save['rnd'] as int;
    _nextId = save['next'] as int;
    final rows = save['board'] as List;
    for (var y = 0; y < size; y++) {
      final row = rows[y] as List;
      for (var x = 0; x < size; x++) {
        final p = row[x] as List?;
        final timer = p != null && p.length > 3 ? p[3] as int : -1;
        board[y][x] = p == null
            ? null
            : SugarPiece(_nextId++, SugarColor.values[p[0] as int], special: Special.values[p[1] as int], chained: p[2] == 1, timer: timer < 0 ? null : timer);
      }
    }
    final iceRows = save['ice'] as List;
    final boxRows = save['box'] as List?;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        ice[y][x] = ((iceRows[y] as List)[x] as num).toInt();
        box[y][x] = boxRows == null ? 0 : ((boxRows[y] as List)[x] as num).toInt();
      }
    }
    final progress = save['goals'] as List;
    for (var i = 0; i < goals.length && i < progress.length; i++) {
      goals[i].progress = progress[i] as int;
    }
    final s = level.stars;
    while (_starsShown < 3 && score >= s[_starsShown]) {
      _starsShown++;
    }
    status = SugarStatus.idle;
  }

  SugarGame copy() {
    final g = SugarGame()
      .._rnd = _rnd.copy()
      ..level = level
      ..status = status
      ..board = [for (final row in board) [for (final p in row) p?.copy()]]
      ..ice = [for (final row in ice) List.of(row)]
      ..box = [for (final row in box) List.of(row)]
      ..goals = [for (final goal in goals) goal.copy()]
      ..colors = colors
      ..moves = moves
      ..score = score
      ..cascade = cascade
      ..bestCascade = bestCascade
      ..rushMeter = rushMeter
      ..movesMade = movesMade
      .._nextId = _nextId
      .._needGravity = _needGravity
      .._needMatch = _needMatch
      .._moveDone = _moveDone
      .._bombDue = _bombDue
      .._rushing = _rushing
      .._blastBoost = _blastBoost
      .._finaleStarted = _finaleStarted
      .._finaleLeft = _finaleLeft
      .._finaleShots = _finaleShots
      .._finaleRounds = _finaleRounds
      .._starsShown = _starsShown;
    g._fire.addAll(_fire.map((f) => (f.$1, f.$2, f.$3.copy())));
    return g;
  }

  // ---------------------------------------------------------------- tests --

  static const _letters = {'R': SugarColor.red, 'O': SugarColor.orange, 'Y': SugarColor.yellow, 'G': SugarColor.green, 'B': SugarColor.blue, 'P': SugarColor.purple};

  /// Test helper: rows of colour letters; lower case is chained, '#' a
  /// two-layer box, '+' a one-layer box, '.' empty.
  void debugSetBoard(
    List<String> rows, {
    Map<Cell, Special> specials = const {},
    Map<Cell, int> iceAt = const {},
    Map<Cell, int> timers = const {},
    int moves = 20,
  }) {
    this.moves = moves;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final ch = rows[y][x];
        box[y][x] = ch == '#' ? 2 : (ch == '+' ? 1 : 0);
        ice[y][x] = iceAt[(x, y)] ?? 0;
        if (ch == '.' || box[y][x] > 0) {
          board[y][x] = null;
          continue;
        }
        board[y][x] = SugarPiece(_nextId++, _letters[ch.toUpperCase()]!,
            special: specials[(x, y)] ?? Special.none, chained: ch.toLowerCase() == ch, timer: timers[(x, y)]);
      }
    }
    status = SugarStatus.idle;
  }

  List<String> debugRows() => [
    for (var y = 0; y < size; y++)
      [
        for (var x = 0; x < size; x++)
          box[y][x] > 0
              ? (box[y][x] > 1 ? '#' : '+')
              : board[y][x] == null
                  ? '.'
                  : (board[y][x]!.isPrism ? '@' : _letters.entries.firstWhere((e) => e.value == board[y][x]!.color).key),
      ].join(),
  ];
}
