import 'dart:math';

import 'chain_game.dart';

/// A Zincir Küpler board without time: a swap, then everything falls and
/// clears at once, step after step, until it is still. Fast enough to try
/// every swap, so it finds puzzle solutions and the computer player's
/// moves. Garbage stays where it is and only counts when a match touches
/// it.
class ChainSim {
  ChainSim(this.cells);

  static const int w = ChainGame.width;
  static const int h = ChainGame.height;
  static const int empty = -1;
  static const int garbage = 6;

  /// Row by row from the top: [empty], a colour index, or [garbage].
  final List<int> cells;

  static const _letters = 'YMBGOW';

  /// From rows of letters, top to bottom, like [ChainGame.debugSetBoard]
  /// ('.' empty, '#' garbage); missing top rows are empty.
  factory ChainSim.rows(List<String> rows) {
    final cells = List<int>.filled(w * h, empty);
    final offset = h - rows.length;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < w; x++) {
        final ch = rows[y][x];
        cells[(y + offset) * w + x] = ch == '.' ? empty : (ch == '#' ? garbage : _letters.indexOf(ch));
      }
    }
    return ChainSim(cells);
  }

  /// A still copy of [game]'s board: bursting cubes are gone, falling ones
  /// land.
  factory ChainSim.of(ChainGame game) {
    final cells = List<int>.filled(w * h, empty);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final b = game.board[y][x];
        if (b == null || b.state == BlockState.clearing) continue;
        cells[y * w + x] = b.isGarbage ? garbage : b.color.index;
      }
    }
    return ChainSim(cells)..fall();
  }

  ChainSim copy() => ChainSim(List.of(cells));

  int at(int x, int y) => cells[y * w + x];

  bool get isEmpty => cells.every((c) => c == empty || c == garbage);

  int get cubes => cells.where((c) => c != empty && c != garbage).length;

  /// Rows from the top of the highest cube down to the floor.
  int get height {
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (cells[y * w + x] != empty) return h - y;
      }
    }
    return 0;
  }

  /// The board as rows of letters, top to bottom.
  List<String> rows() => [
    for (var y = 0; y < h; y++) [for (var x = 0; x < w; x++) switch (cells[y * w + x]) { empty => '.', garbage => '#', final c => _letters[c] }].join(),
  ];

  String get key => cells.join(',');

  /// Swaps ([x], [y]) with its right neighbour; false when there is
  /// nothing to swap or one of them is garbage.
  bool swap(int x, int y) {
    final i = y * w + x;
    final a = cells[i], b = cells[i + 1];
    if ((a == empty && b == empty) || a == garbage || b == garbage || a == b) return false;
    cells[i] = b;
    cells[i + 1] = a;
    return true;
  }

  /// Every cube drops onto what is below it (garbage holds still).
  /// Returns whether anything moved.
  bool fall() {
    var moved = false;
    for (var x = 0; x < w; x++) {
      var write = h - 1;
      for (var y = h - 1; y >= 0; y--) {
        final c = cells[y * w + x];
        if (c == empty) continue;
        if (c == garbage) {
          write = y - 1;
          continue;
        }
        if (write != y) {
          cells[write * w + x] = c;
          cells[y * w + x] = empty;
          moved = true;
        }
        write--;
      }
    }
    return moved;
  }

  /// Cells in a run of three or more of one colour.
  Set<int> matches() {
    final hits = <int>{};
    void run(int start, int step, int count) {
      var i = 0;
      while (i < count) {
        final c = cells[start + i * step];
        var end = i + 1;
        if (c != empty && c != garbage) {
          while (end < count && cells[start + end * step] == c) {
            end++;
          }
          if (end - i >= 3) {
            for (var k = i; k < end; k++) {
              hits.add(start + k * step);
            }
          }
        }
        i = end;
      }
    }

    for (var y = 0; y < h; y++) {
      run(y * w, 1, w);
    }
    for (var x = 0; x < w; x++) {
      run(x, w, h);
    }
    return hits;
  }

  /// Falls and clears until the board is still: cubes cleared, the longest
  /// chain (1 for a plain match, 0 for none) and garbage cells touched.
  ({int cleared, int chain, int garbage}) settle() {
    fall();
    var cleared = 0, chain = 0, touched = 0;
    while (true) {
      final hits = matches();
      if (hits.isEmpty) break;
      chain++;
      cleared += hits.length;
      final near = <int>{};
      for (final i in hits) {
        final x = i % w, y = i ~/ w;
        for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nx = x + dx, ny = y + dy;
          if (nx >= 0 && nx < w && ny >= 0 && ny < h && cells[ny * w + nx] == garbage) near.add(ny * w + nx);
        }
      }
      touched += near.length;
      for (final i in hits) {
        cells[i] = empty;
      }
      fall();
    }
    return (cleared: cleared, chain: chain, garbage: touched);
  }

  /// The swaps worth trying: at least one cube, no garbage, two different
  /// cells.
  Iterable<(int, int)> swaps() sync* {
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w - 1; x++) {
        final a = cells[y * w + x], b = cells[y * w + x + 1];
        if (a == b || a == garbage || b == garbage) continue;
        yield (x, y);
      }
    }
  }

  /// The fewest swaps (up to [depth]) that clear the whole board, as the
  /// swaps to make; null when it cannot be done in [depth].
  List<(int, int)>? solve(int depth) {
    var level = <(ChainSim, List<(int, int)>)>[(copy()..settle(), const [])];
    if (level.first.$1.isEmpty) return const [];
    final seen = {level.first.$1.key};
    for (var d = 0; d < depth; d++) {
      final next = <(ChainSim, List<(int, int)>)>[];
      for (final (sim, path) in level) {
        for (final (x, y) in sim.swaps()) {
          final s = sim.copy()..swap(x, y);
          s.settle();
          if (!seen.add(s.key)) continue;
          final p = [...path, (x, y)];
          if (s.isEmpty) return p;
          // A colour with fewer than three cubes left can never clear.
          if (!s._clearable) continue;
          next.add((s, p));
        }
      }
      level = next;
    }
    return null;
  }

  bool get _clearable {
    final counts = List<int>.filled(6, 0);
    for (final c in cells) {
      if (c >= 0 && c < 6) counts[c]++;
    }
    return counts.every((n) => n == 0 || n >= 3);
  }
}

/// How good a swap is for a player who wants combos and chains: the
/// computer rivals rank their moves with it.
double chainMoveValue(ChainSim before, ChainSim after, ({int cleared, int chain, int garbage}) r) {
  if (r.cleared == 0) return 0;
  final lower = max(0, before.height - after.height);
  return r.cleared * 1.0 + (r.chain - 1) * (r.chain - 1) * 9.0 + (r.cleared >= 4 ? (r.cleared - 3) * 2.0 : 0) + r.garbage * 1.5 + lower * 0.8;
}
