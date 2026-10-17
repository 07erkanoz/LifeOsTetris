// Makes the Zincir Küpler puzzles: random small stacks whose colours come
// in threes, kept when the fewest swaps that clear them is exactly the
// pack's count, and checked on the real game too.
//   flutter test tool/chain_puzzles_gen_test.dart
// Prints the puzzles as Dart for lib/core/chain/chain_puzzles.dart.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/chain/chain_sim.dart';

const _letters = 'YMBGO';

/// [cubes] cubes of [colors] colours (each a multiple of three) dropped
/// into columns no taller than [tall], with no match to start with.
List<String>? board(Random rnd, int cubes, int colors, int tall) {
  final bag = <int>[];
  final groups = cubes ~/ 3;
  for (var i = 0; i < groups; i++) {
    final c = i < colors ? i : rnd.nextInt(colors);
    bag.addAll([c, c, c]);
  }
  bag.shuffle(rnd);
  final columns = List.generate(ChainSim.w, (_) => <int>[]);
  // Columns side by side, a little uneven, mostly in the middle.
  for (final c in bag) {
    final open = [for (var x = 0; x < ChainSim.w; x++) if (columns[x].length < tall) x];
    if (open.isEmpty) return null;
    final x = open[rnd.nextInt(open.length)];
    columns[x].add(c);
  }
  final rows = [
    for (var y = tall - 1; y >= 0; y--) [for (var x = 0; x < ChainSim.w; x++) y < columns[x].length ? _letters[columns[x][y]] : '.'].join(),
  ];
  final sim = ChainSim.rows(rows);
  if (sim.matches().isNotEmpty) return null;
  // No empty column between two stacks (it reads as two boards).
  final filled = [for (var x = 0; x < ChainSim.w; x++) columns[x].isNotEmpty];
  final first = filled.indexOf(true), last = filled.lastIndexOf(true);
  for (var x = first; x <= last; x++) {
    if (!filled[x]) return null;
  }
  return rows;
}

/// Plays [solution] on the real game: does it clear the board?
bool playsOut(List<String> rows, List<(int, int)> solution) {
  final g = ChainGame(random: Random(1))..startPuzzle(rows, solution.length);
  for (final (x, y) in solution) {
    for (var i = 0; i < 900 && !g.settled; i++) {
      g.update(1 / 60);
    }
    if (!g.swap(x, y)) return false;
  }
  for (var i = 0; i < 1800 && !g.isOver; i++) {
    g.update(1 / 60);
  }
  return g.won;
}

void main() {
  test('generate', () {
    // Pack by pack: (how many, swaps, cubes, colours, tallest column).
    const packs = [
      (20, [1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], [6, 9], 2, 4),
      (20, [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [9, 12], 3, 5),
      (20, [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [12, 15], 3, 6),
      (20, [3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4], [15, 18], 4, 7),
    ];
    final rnd = Random(20261017);
    final out = StringBuffer();
    final seen = <String>{};
    var n = 0;
    for (final (count, swaps, sizes, colors, tall) in packs) {
      for (var i = 0; i < count; i++) {
        final want = swaps[i];
        final cubes = sizes[0] + 3 * (i * ((sizes[1] - sizes[0]) ~/ 3 + 1) ~/ count);
        for (var tries = 0; ; tries++) {
          final rows = board(rnd, cubes, colors, tall);
          if (rows == null) continue;
          final sim = ChainSim.rows(rows);
          if (!seen.add(sim.key)) continue;
          if (want > 1 && sim.solve(want - 1) != null) continue;
          final solution = sim.solve(want);
          if (solution == null || !playsOut(rows, solution)) continue;
          n++;
          out.writeln("    ChainPuzzle($want, [${rows.map((r) => "'$r'").join(', ')}]), // $n · $tries tries · ${solution.map((m) => '${m.$1},${m.$2}').join(' ')}");
          break;
        }
      }
    }
    // ignore: avoid_print
    print(out);
  }, timeout: const Timeout(Duration(minutes: 60)));
}
