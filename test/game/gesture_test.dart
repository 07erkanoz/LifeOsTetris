import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/core/tetromino.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/settings/settings.dart';

GameController _game() => GameController(settings: Settings.memory(), audio: AudioService(enabled: false))..start(GameMode.relaxed);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const cell = 30.0;

  test('a quick swipe down that drifts sideways never shifts the piece', () {
    final c = _game();
    final x = c.game.active!.x;
    final type = c.game.active!.type;
    c.dragStart();
    // 60 px of sideways drift over 240 px down: more than two columns' worth.
    for (var i = 0; i < 12; i++) {
      c.dragUpdate(const Offset(5, 20), cell);
    }
    expect(c.game.active!.x, x);
    expect(c.game.softDropping, isTrue);
    c.dragEnd(const Offset(400, 2600));
    // Hard dropped: the next piece is in play and the board holds the last.
    expect(c.game.board.any((row) => row.contains(type)), isTrue);
  });

  test('a sideways drag moves the piece and does not soft drop', () {
    final c = _game();
    final x = c.game.active!.x;
    c.dragStart();
    for (var i = 0; i < 6; i++) {
      c.dragUpdate(const Offset(10, 4), cell);
    }
    expect(c.game.active!.x, x + 2);
    expect(c.game.softDropping, isFalse);
    c.dragEnd(Offset.zero);
  });

  test('a tap still rotates', () {
    final c = _game();
    // A fixed T piece: a random first piece may be the O, which never turns.
    c.game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 3, 4));
    final rotation = c.game.active!.rotation;
    c.dragStart();
    c.dragUpdate(const Offset(2, 1), cell);
    c.dragEnd(Offset.zero);
    expect(c.game.active!.rotation, isNot(rotation));
  });
}
