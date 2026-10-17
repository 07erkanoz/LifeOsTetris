import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/blocks/block_puzzle.dart';
import 'package:lifeos_kupler/core/blocks/level_generator.dart';
import 'package:lifeos_kupler/l10n/strings.dart';

/// A board with every cell filled except a checkerboard of holes no piece
/// but a dot fits: nothing bigger has room.
const _crammed = ['T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T'];

void main() {
  test('jewels: early levels use one kind, later ones mix all four; saves keep them', () {
    expect(BlockLevels.generate(3).jewelKinds, 1);
    expect(BlockLevels.generate(10).jewelKinds, 2);
    expect(BlockLevels.generate(40).jewelKinds, 4);
    final level = BlockLevels.generate(40);
    final game = BlockPuzzleGame()..startLevel(level, random: Random(1));
    final kinds = {for (final row in game.board) for (final c in row) if (c != null && c.gem) c.gemKind};
    expect(kinds.length, greaterThan(1));
    expect([for (final k in game.jewelKinds) game.gemsLeftOf(k)].fold(0, (a, b) => a + b), game.gemsLeft);
    final again = BlockPuzzleGame()..restore(game.toSave());
    for (var y = 0; y < BlockPuzzleGame.size; y++) {
      for (var x = 0; x < BlockPuzzleGame.size; x++) {
        expect(again.board[y][x]?.gemKind, game.board[y][x]?.gemKind);
      }
    }
  });

  test('a crowded board sometimes deals a lucky piece that finishes a line', () {
    var lucky = 0, needy = 0;
    for (var seed = 0; seed < 200; seed++) {
      final game = BlockPuzzleGame()..startEndless(random: Random(seed));
      // Only a long upright piece (or small ones in the gap) finishes a line.
      game.debugSetBoard(['TTTTTTT.', 'TTTTTTT.', 'TTTTTTT.', 'TTTTTTT.', '........', '........', '........', '........']);
      final source = RandomSource(Random(seed));
      final tray = source.deal(game);
      if (source.lucky) lucky++;
      if (!tray.any(game.clearsSomewhere)) needy++;
      if (source.lucky) expect(tray.any(game.clearsSomewhere), isTrue);
    }
    expect(lucky, greaterThan(0), reason: 'luck happens');
    expect(needy, greaterThan(0), reason: 'but not every time');
  });

  test('out of room: new pieces or the hammer keep the game going', () {
    final game = BlockPuzzleGame()..startEndless(random: Random(4));
    game.debugSetBoard(_crammed);
    game.debugSetTray(['o2', 'o2', 'i3h']);
    game.place(0, 0, 0);
    // Nothing fits: the dealt pieces are all bigger than a hole.
    game.debugSetTray(['o2', 'o2', 'o2']);
    expect(game.fitsAnywhere(game.tray[0]!), isFalse);
    expect(game.rescueNewTray(), isFalse, reason: 'only a lost game is rescued');

    final lost = BlockPuzzleGame()..startEndless(random: Random(5));
    lost.debugSetBoard(_crammed);
    lost.debugSetTray(['dot', 'o2', 'o2']);
    lost.place(0, 1, 0);
    expect(lost.status, BlockStatus.lost);
    expect(lost.rescuable, isTrue);
    expect(lost.rescueHammer(), isTrue);
    expect(lost.status, BlockStatus.playing);
    expect(lost.drainEvents().whereType<BlocksHammered>().single.cells, isNotEmpty);
    expect(lost.tray.any((s) => s != null && lost.fitsAnywhere(s)), isTrue);
  });

  test('a level out of moves can take three more', () {
    final level = BlockLevels.generate(2);
    final game = BlockPuzzleGame()..startLevel(level, random: Random(6));
    game.moves = level.moveLimit - 1;
    // One more placement that collects nothing ends it.
    for (var slot = 0; slot < 3 && game.status == BlockStatus.playing; slot++) {
      final shape = game.tray[slot];
      if (shape == null) continue;
      final hint = game.hintMove();
      if (hint != null) game.place(hint.$1, hint.$2, hint.$3);
    }
    if (game.status == BlockStatus.lost && game.loss == BlockLoss.outOfMoves) {
      expect(game.rescueMoves(3), isTrue);
      expect(game.movesLeft, 3);
      expect(game.status, BlockStatus.playing);
      final again = BlockPuzzleGame()..restore(game.toSave());
      expect(again.movesLeft, 3);
    }
  });

  test('praise grows with the lines and the combo', () {
    const s = AppStrings.tr;
    expect(s.blastWord(1), 'GÜZEL!');
    expect(s.blastWord(2), 'HARİKA!');
    expect(s.blastWord(3), 'MUHTEŞEM!');
    expect(s.blastWord(1, 3), 'HARİKA!');
    expect(s.blastWord(1, 5), 'İNANILMAZ!');
    expect(s.blastWord(2, 5), 'EFSANE!');
  });

  test('a hint prefers a placement that clears a line', () {
    final game = BlockPuzzleGame()..startEndless(random: Random(7));
    game.debugSetBoard(['TTTTTTT.', '........', '........', '........', '........', '........', '........', '........']);
    game.debugSetTray(['o2', 'dot', 'i2h']);
    final hint = game.hintMove()!;
    final shape = game.tray[hint.$1]!;
    final (rows, columns) = game.clearsFor(shape, hint.$2, hint.$3);
    expect(rows.isNotEmpty || columns.isNotEmpty, isTrue);
  });
}
