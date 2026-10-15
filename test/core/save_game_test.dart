import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/blocks/block_puzzle.dart';
import 'package:lifeos_kupler/core/blocks/level_generator.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';

/// Through JSON text, as the game stores it.
Map<String, Object?> _roundTrip(Map<String, Object?> save) => (jsonDecode(jsonEncode(save)) as Map).cast<String, Object?>();

void main() {
  test('a Süper Küpler game continues exactly where it was saved', () {
    final game = TetrisGame()..start(seed: 7, mode: GameMode.superMode);
    for (var i = 0; i < 6; i++) {
      if (i.isEven) game.moveLeft();
      game.hardDrop();
      game.update(1);
    }
    game.hold();
    game.debugGivePowers([PowerType.bomb, PowerType.drill, PowerType.drill]);
    final save = _roundTrip(game.toSave());

    final again = TetrisGame()..restore(save);
    expect(again.mode, GameMode.superMode);
    expect(again.status, GameStatus.playing);
    expect(again.score, game.score);
    expect(again.lines, game.lines);
    expect(again.level, game.level);
    expect(again.held, game.held);
    expect(again.canHold, game.canHold);
    expect(again.preview, game.preview);
    expect(again.active?.type, game.active?.type);
    expect(again.active?.x, game.active?.x);
    expect(again.powerCount(PowerType.drill), 2);
    expect(again.energy, game.energy);
    for (var y = 0; y < TetrisGame.height; y++) {
      for (var x = 0; x < TetrisGame.width; x++) {
        expect(again.cellAt(x, y), game.cellAt(x, y), reason: '($x, $y)');
      }
    }
    // And it plays on.
    again.hardDrop();
    again.update(1);
    expect(again.status, isNot(GameStatus.over));
  });

  test('a malformed save is rejected', () {
    expect(() => TetrisGame().restore({'mode': 'classic', 'board': []}), throwsA(anything));
  });

  test('an endless Bulmaca game continues with its board and tray', () {
    final game = BlockPuzzleGame()..startEndless();
    game.debugSetBoard(['*.......', 'IIII....', '........', '........', '........', '........', '........', 'LLL.....']);
    game.debugSetTray(['o2', null, 'i3h']);
    game.score = 420;
    final again = BlockPuzzleGame()..restore(_roundTrip(game.toSave()));
    expect(again.isEndless, isTrue);
    expect(again.score, 420);
    expect(again.tray.map((s) => s?.id), ['o2', null, 'i3h']);
    expect(again.cellAt(0, 0)!.gem, isTrue);
    expect(again.cellAt(2, 1)!.color, game.cellAt(2, 1)!.color);
    expect(again.cellAt(5, 5), isNull);
  });

  test('a Bulmaca level continues with its pieces, moves and goal', () {
    final level = BlockLevels.generate(4);
    final game = BlockPuzzleGame()..startLevel(level);
    final shape = game.tray.first!;
    final spot = [
      for (var y = 0; y < BlockPuzzleGame.size; y++)
        for (var x = 0; x < BlockPuzzleGame.size; x++)
          if (game.canPlace(shape, x, y)) (x, y),
    ].first;
    expect(game.place(0, spot.$1, spot.$2), isTrue);

    final again = BlockPuzzleGame()..restore(_roundTrip(game.toSave()));
    expect(again.level!.number, 4);
    expect(again.level!.rows, level.rows);
    expect(again.moves, 1);
    expect(again.movesLeft, game.movesLeft);
    expect(again.gemsLeft, game.gemsLeft);
    expect(again.tray.map((s) => s?.id), game.tray.map((s) => s?.id));
  });
}
