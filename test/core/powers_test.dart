import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';

TetrisGame superGame() => TetrisGame()..start(seed: 3, mode: GameMode.superMode);

List<String> rows(int count, String row) => List.filled(count, row);

void main() {
  test('clearing three lines earns a power, a quad fills the bar at once', () {
    final game = superGame();
    game.debugSetBoard(rows(3, 'JJJJJJJJJ.'));
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
    game.hardDrop();
    final events = game.drainEvents();
    expect(events.whereType<PowerEarned>(), hasLength(1));
    expect(game.totalPowers, 1);
    expect(game.energy, 0);

    game.update(TetrisGame.lineClearDelay + 0.01);
    game.debugSetBoard(rows(4, 'JJJJJJJJJ.'));
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
    game.hardDrop();
    expect(game.totalPowers, 2);
    expect(game.energy, 1);
  });

  test('classic mode never earns powers', () {
    final game = TetrisGame()..start(seed: 3);
    game.debugSetBoard(rows(4, 'JJJJJJJJJ.'));
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
    game.hardDrop();
    expect(game.totalPowers, 0);
    expect(game.drainEvents().whereType<PowerEarned>(), isEmpty);
  });

  test('every power is capped and the bar waits full when all are maxed', () {
    final game = superGame();
    game.debugGivePowers([for (final p in PowerType.values) ...List.filled(TetrisGame.maxPerPower, p)]);
    game.debugSetBoard(rows(4, 'JJJJJJJJJ.'));
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
    game.hardDrop();
    expect(game.totalPowers, PowerType.values.length * TetrisGame.maxPerPower);
    expect(game.energy, TetrisGame.energyPerPower);
  });

  test('powers come in a shuffled round: all six before any repeats', () {
    final game = superGame();
    final earned = <PowerType>[];
    for (var round = 0; round < 12; round++) {
      game.debugSetBoard(rows(3, 'JJJJJJJJJ.'));
      game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
      game.hardDrop();
      earned.addAll(game.drainEvents().whereType<PowerEarned>().map((e) => e.type));
      game.update(TetrisGame.lineClearDelay + 0.01);
      game.drainEvents();
      // Spend everything so the caps never interfere.
      game.debugGivePowers(const []);
    }
    expect(earned, hasLength(12));
    expect(earned.take(6).toSet(), hasLength(6));
    expect(earned.skip(6).toSet(), hasLength(6));
  });

  test('gravity cannot be used, nor wasted, when nothing would fall', () {
    final game = superGame();
    game.debugSetBoard(['JJJJ......', 'JJJJJ.....']);
    game.debugGivePowers([PowerType.gravity]);
    expect(game.hasFloatingBlocks, isFalse);
    expect(game.canUsePower(PowerType.gravity), isFalse);
    expect(game.usePower(PowerType.gravity), isFalse);
    expect(game.powerCount(PowerType.gravity), 1);
    game.debugSetBoard(['JJJJ......', 'J.JJJ.....']);
    expect(game.hasFloatingBlocks, isTrue);
    expect(game.usePower(PowerType.gravity), isTrue);
    expect(game.powerCount(PowerType.gravity), 0);
  });

  test('bomb blasts a 3×3 area and the swapped piece comes back next', () {
    final game = superGame();
    final current = game.active!.type;
    game.debugSetBoard(rows(4, 'JJJJJJJJJJ'.replaceRange(9, 10, '.')));
    game.debugGivePowers([PowerType.bomb]);
    expect(game.usePower(PowerType.bomb), isTrue);
    expect(game.active!.type, PieceType.bomb);
    expect(game.active!.cells.single.y, greaterThanOrEqualTo(TetrisGame.hiddenRows), reason: 'power pieces spawn visible');
    expect(game.preview.first, current);
    expect(game.hold(), isFalse, reason: 'power pieces cannot be held');

    game.hardDrop();
    final blast = game.drainEvents().whereType<BombExploded>().single;
    // The bomb lands on top of the stack (row 17) above column 4.
    expect(blast.center, const Cell(4, 17));
    expect(blast.removed, hasLength(3), reason: 'only the row under the bomb has blocks');
    expect(game.cellAt(4, 18), isNull);
    expect(game.cellAt(4, 19), PieceType.j);
    expect(game.active!.type, current);
  });

  test('drill passes through blocks and eats its column', () {
    final game = superGame();
    game.debugSetBoard(['....J.....', ...rows(5, 'JJJJJJJJJ.')]);
    game.debugGivePowers([PowerType.drill]);
    game.usePower(PowerType.drill);
    expect(game.ghost!.cells.single.y, TetrisGame.height - 1, reason: 'ghost goes to the floor');
    game.hardDrop();
    final drilled = game.drainEvents().whereType<ColumnDrilled>().single;
    expect(drilled.column, 4);
    expect(drilled.removed, hasLength(6));
    for (var y = 0; y < TetrisGame.height; y++) {
      expect(game.cellAt(4, y), isNull);
    }
  });

  test('single block power gives a one-cell piece that locks normally', () {
    final game = superGame();
    game.debugSetBoard(['JJJJ.JJJJJ']);
    game.debugGivePowers([PowerType.single]);
    game.usePower(PowerType.single);
    expect(game.active!.type, PieceType.mono);
    game.hardDrop();
    final cleared = game.drainEvents().whereType<LinesCleared>().single;
    expect(cleared.count, 1);
  });

  test('gravity drops floating blocks and clears completed rows', () {
    final game = superGame();
    game.debugSetBoard(['J.........', '..........', '.JJJJJJJJJ']);
    game.debugGivePowers([PowerType.gravity]);
    game.usePower(PowerType.gravity);
    final events = game.drainEvents();
    expect(events.whereType<GravityApplied>().single.moves, [(0, 19, 21)]);
    expect(events.whereType<LinesCleared>().single.count, 1);
    expect(game.status, GameStatus.clearing);
  });

  test('slow motion slows gravity for ten seconds', () {
    final game = superGame();
    game.debugGivePowers([PowerType.slowMotion]);
    game.usePower(PowerType.slowMotion);
    final y = game.active!.y;
    game.update(gravityInterval(1) * 1.5);
    expect(game.active!.y, y, reason: 'normal interval is not enough any more');
    game.update(TetrisGame.slowMotionDuration);
    expect(game.slowMotion, 0);
    expect(game.drainEvents().whereType<SlowMotionEnded>(), hasLength(1));
  });

  test('ghost line sinks, freezes the piece and fills its row when triggered', () {
    final game = superGame();
    game.debugSetBoard(['J.J.J.J.J.', 'JJJJJJJJJ.']);
    game.debugGivePowers([PowerType.ghostLine]);
    final piece = game.active!;
    game.usePower(PowerType.ghostLine);
    expect(game.moveLeft(), isFalse, reason: 'piece is frozen');

    // Sink to the second-to-last visible row.
    game.update((TetrisGame.visibleHeight - 2) / TetrisGame.ghostLineSpeed + 0.01);
    expect(game.ghostLineRow, TetrisGame.visibleHeight - 2);
    expect(game.active!.y, piece.y);

    game.hardDrop(); // hard drop triggers the ghost line
    final events = game.drainEvents();
    expect(events.whereType<GhostLineFilled>().single.cells, hasLength(5));
    expect(events.whereType<LinesCleared>().single.rows, [TetrisGame.height - 2]);
    expect(game.ghostLine, isNull);

    game.update(TetrisGame.lineClearDelay + 0.01);
    expect(game.active!.type, piece.type, reason: 'the frozen piece comes back after the clear');
  });

  test('ghost line triggers by itself at the bottom', () {
    final game = superGame();
    game.debugSetBoard(['JJJJJJJJJ.']);
    game.debugGivePowers([PowerType.ghostLine]);
    game.usePower(PowerType.ghostLine);
    game.update(30);
    expect(game.drainEvents().whereType<GhostLineFilled>().single.row, TetrisGame.height - 1);
  });

  test('ghost line triggered over empty rows snaps to the top of the stack', () {
    final game = superGame();
    game.debugSetBoard(['J.J.J.J.J.', 'JJJJJJJJJ.']);
    game.debugGivePowers([PowerType.ghostLine]);
    game.usePower(PowerType.ghostLine);
    game.update(0.5); // still near the top, far above the stack
    game.hardDrop();
    final filled = game.drainEvents().whereType<GhostLineFilled>().single;
    expect(filled.row, TetrisGame.height - 2);
    expect(filled.cells, hasLength(5));
  });
}
