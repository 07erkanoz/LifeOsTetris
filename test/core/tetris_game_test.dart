import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/bag.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';

TetrisGame startedGame({int seed = 1}) => TetrisGame()..start(seed: seed);

List<String> rows(int count, String row) => List.filled(count, row);

T lastEvent<T extends GameEvent>(List<GameEvent> events) => events.whereType<T>().last;

void main() {
  group('tetromino', () {
    test('four clockwise rotations return to the spawn shape', () {
      for (final type in PieceType.values) {
        var r = Rotation.spawn;
        for (var i = 0; i < 4; i++) {
          r = r.cw;
        }
        expect(shapeOf(type, r), shapeOf(type, Rotation.spawn), reason: type.name);
      }
    });

    test('T rotates clockwise to point right', () {
      expect(shapeOf(PieceType.t, Rotation.right).toSet(), {const Cell(1, 0), const Cell(1, 1), const Cell(1, 2), const Cell(2, 1)});
    });

    test('I occupies column 2 in the right state', () {
      expect(shapeOf(PieceType.i, Rotation.right).map((c) => c.x).toSet(), {2});
    });
  });

  group('speed', () {
    test('classic mode eases in and caps at level 10', () {
      expect(gravityInterval(1), closeTo(1.0, 1e-9));
      expect(gravityInterval(5), greaterThan(0.45));
      expect(gravityInterval(10), closeTo(0.25, 1e-9));
      expect(gravityInterval(25), closeTo(0.25, 1e-9));
      for (var l = 1; l < 10; l++) {
        expect(gravityInterval(l + 1), lessThan(gravityInterval(l)));
      }
    });

    test('relaxed mode never speeds up', () {
      expect(gravityInterval(1, GameMode.relaxed), gravityInterval(30, GameMode.relaxed));
    });
  });

  group('bag', () {
    test('every group of seven contains each piece once', () {
      final bag = PieceBag(42);
      for (var round = 0; round < 5; round++) {
        final seven = [for (var i = 0; i < 7; i++) bag.next()];
        expect(seven.toSet(), PieceType.values.toSet());
      }
    });

    test('peek does not consume', () {
      final bag = PieceBag(3);
      final peeked = bag.peek(3);
      expect([bag.next(), bag.next(), bag.next()], peeked);
    });
  });

  group('spawning and movement', () {
    test('a new piece spawns centred and drops one row', () {
      final game = startedGame();
      final piece = game.active!;
      expect(piece.x, 3);
      expect(piece.y, 1);
      expect(game.drainEvents().whereType<PieceSpawned>(), hasLength(1));
    });

    test('pieces stop at the walls', () {
      final game = startedGame();
      while (game.moveLeft()) {}
      expect(game.active!.cells.map((c) => c.x).reduce((a, b) => a < b ? a : b), 0);
      while (game.moveRight()) {}
      expect(game.active!.cells.map((c) => c.x).reduce((a, b) => a > b ? a : b), TetrisGame.width - 1);
      expect(game.drainEvents().whereType<PieceMoveBlocked>(), isNotEmpty);
    });

    test('gravity moves the piece down once per interval', () {
      final game = startedGame();
      final y = game.active!.y;
      game.update(gravityInterval(1) + 0.001);
      expect(game.active!.y, y + 1);
    });

    test('I piece kicks off the right wall when rotating', () {
      final game = startedGame();
      game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
      game.drainEvents();
      expect(game.rotateClockwise(), isTrue);
      final piece = game.active!;
      expect(piece.rotation, Rotation.flip);
      expect(piece.cells.every((c) => c.x >= 0 && c.x < TetrisGame.width), isTrue);
      expect(lastEvent<PieceRotated>(game.drainEvents()).kicked, isTrue);
    });

    test('O piece does not rotate', () {
      final game = startedGame();
      game.debugSetActive(const Piece(PieceType.o, Rotation.spawn, 3, 5));
      expect(game.rotateClockwise(), isFalse);
    });
  });

  group('dropping and locking', () {
    test('hard drop scores two points per cell and locks', () {
      final game = startedGame();
      game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 3, 1));
      game.hardDrop();
      expect(game.score, 2 * (TetrisGame.height - 3));
      expect([for (var x = 0; x < 10; x++) game.cellAt(x, TetrisGame.height - 1)].whereType<PieceType>(), hasLength(3));
      final events = game.drainEvents();
      expect(events.whereType<HardDropped>(), hasLength(1));
      expect(events.whereType<PieceLocked>(), hasLength(1));
    });

    test('lock delay waits half a second on the ground', () {
      final game = startedGame();
      game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 3, TetrisGame.height - 2));
      game.drainEvents();
      game.update(0.4);
      expect(game.drainEvents().whereType<PieceLocked>(), isEmpty);
      game.update(0.15);
      expect(game.drainEvents().whereType<PieceLocked>(), hasLength(1));
    });

    test('moving on the ground resets lock delay a limited number of times', () {
      final game = startedGame();
      game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 3, TetrisGame.height - 2));
      game.drainEvents();
      var locked = false;
      for (var i = 0; i < 40 && !locked; i++) {
        game.update(0.3);
        locked = game.drainEvents().whereType<PieceLocked>().isNotEmpty;
        if (!locked) i.isEven ? game.moveLeft() : game.moveRight();
      }
      expect(locked, isTrue);
    });
  });

  group('line clears', () {
    test('single line clear scores and collapses after the delay', () {
      final game = startedGame();
      game.debugSetBoard(['JJJJJJJJJ.']);
      game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
      game.hardDrop();
      final cleared = lastEvent<LinesCleared>(game.drainEvents());
      expect(cleared.count, 1);
      expect(cleared.points, 100);
      expect(game.status, GameStatus.clearing);

      game.update(TetrisGame.lineClearDelay + 0.01);
      expect(game.drainEvents().whereType<RowsCollapsed>(), hasLength(1));
      expect(game.status, GameStatus.playing);
      expect(game.cellAt(9, TetrisGame.height - 1), PieceType.i);
      expect(game.cellAt(0, TetrisGame.height - 1), isNull);
      expect(game.lines, 1);
    });

    test('tetris then back-to-back tetris with combo bonus', () {
      final game = startedGame();
      game.debugSetBoard(['J.........', ...rows(8, 'JJJJJJJJJ.')]);
      game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 2));
      game.hardDrop();
      final first = lastEvent<LinesCleared>(game.drainEvents());
      expect(first.count, 4);
      expect(first.points, 800);
      expect(first.backToBack, isFalse);

      game.update(TetrisGame.lineClearDelay + 0.01);
      game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 2));
      game.hardDrop();
      final second = lastEvent<LinesCleared>(game.drainEvents());
      expect(second.count, 4);
      expect(second.backToBack, isTrue);
      expect(second.combo, 1);
      expect(second.points, 1200 + 50);
    });

    test('perfect clear adds a bonus', () {
      final game = startedGame();
      game.debugSetBoard(['JJJJJJ....']);
      game.debugSetActive(const Piece(PieceType.i, Rotation.spawn, 6, 5));
      game.hardDrop();
      final cleared = lastEvent<LinesCleared>(game.drainEvents());
      expect(cleared.perfectClear, isTrue);
      expect(cleared.points, 100 + 800);
    });

    test('T-spin double is detected', () {
      final game = startedGame();
      game.debugSetBoard(['...J......', 'JJJ...JJJJ', 'JJJJ.JJJJJ']);
      game.debugSetActive(const Piece(PieceType.t, Rotation.right, 3, TetrisGame.height - 3));
      expect(game.rotateClockwise(), isTrue);
      game.hardDrop();
      final cleared = lastEvent<LinesCleared>(game.drainEvents());
      expect(cleared.tSpin, TSpin.full);
      expect(cleared.count, 2);
      expect(cleared.points, 1200);
    });

    test('ten lines raise the level', () {
      final game = startedGame();
      game.lines = 9;
      game.debugSetBoard(['JJJJJJJJJ.']);
      game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 5));
      game.hardDrop();
      expect(lastEvent<LevelUp>(game.drainEvents()).level, 2);
      expect(game.level, 2);
    });
  });

  group('hold', () {
    test('hold stores the piece once per drop', () {
      final game = startedGame();
      final first = game.active!.type;
      final next = game.preview.first;
      expect(game.hold(), isTrue);
      expect(game.held, first);
      expect(game.active!.type, next);
      expect(game.hold(), isFalse);

      game.hardDrop();
      expect(game.canHold, isTrue);
      expect(game.hold(), isTrue);
      expect(game.active!.type, first);
    });
  });

  group('game over', () {
    test('blocked spawn ends the game', () {
      final game = startedGame();
      game.debugSetBoard(['JJJJJJJJJ.', ...rows(TetrisGame.height - 1, '.........J')]);
      game.hold();
      expect(game.status, GameStatus.over);
      expect(game.drainEvents().whereType<GameOver>(), hasLength(1));
    });
  });
}
