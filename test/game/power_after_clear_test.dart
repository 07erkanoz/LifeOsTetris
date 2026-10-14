import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/settings/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a power can be used right after a line clear', () {
    final c = GameController(settings: Settings.memory(), audio: AudioService(enabled: false));
    c.start(GameMode.superMode);
    c.game.debugSetBoard(List.filled(4, 'JJJJJJJJJ.'));
    c.game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 2));
    c.game.debugGivePowers([PowerType.bomb, PowerType.ghostLine, PowerType.gravity]);
    var t = Duration.zero;
    void run(double seconds) {
      for (var i = 0; i < seconds * 60; i++) {
        t += const Duration(microseconds: 16667);
        c.tick(t);
      }
    }

    run(0.1);
    c.hardDrop();
    run(2.6);
    expect(c.game.status, GameStatus.playing);
    c.usePower(PowerType.bomb);
    expect(c.game.active!.type, PieceType.bomb);
  });
}
