import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/game/motivation.dart';
import 'package:lifeos_kupler/l10n/strings.dart';

void main() {
  test('crossing a score milestone shows a cheer', () {
    final game = TetrisGame()..start(seed: 1);
    final m = MotivationEngine(seed: 1)..reset(bestScore: 0);
    game.score = 1200;
    m.update(0.016, game);
    expect(m.current?.kind, MotivationKind.scoreMilestone);
    expect(m.current?.value, 1000);
  });

  test('beating the previous best wins over milestones and fires once', () {
    final game = TetrisGame()..start(seed: 1);
    final m = MotivationEngine(seed: 1)..reset(bestScore: 900);
    game.score = 1100;
    m.update(0.016, game);
    expect(m.current?.kind, MotivationKind.newBest);

    m.update(MotivationEngine.showFor + 0.1, game);
    expect(m.visible, isFalse);
    game.score = 1500;
    m.update(0.016, game);
    expect(m.current, isNull);
  });

  test('first quad clear is celebrated', () {
    final game = TetrisGame()..start(seed: 1);
    final m = MotivationEngine(seed: 1)..reset(bestScore: 0);
    game.debugSetBoard(List.filled(4, 'JJJJJJJJJ.'));
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 2));
    game.hardDrop();
    for (final e in game.drainEvents()) {
      m.onEvent(e, game);
    }
    expect(m.current?.kind, MotivationKind.firstQuad);
  });

  test('low priority cheers respect the cooldown', () {
    final game = TetrisGame()..start(seed: 1);
    final m = MotivationEngine(seed: 1)..reset(bestScore: 0);
    const combo = LinesCleared(rows: [21], tSpin: TSpin.none, combo: 3, backToBack: false, perfectClear: false, points: 100);
    m.onEvent(combo, game);
    final first = m.current!.id;
    m.update(MotivationEngine.showFor + 0.1, game);
    m.onEvent(combo, game);
    expect(m.current, isNull, reason: 'still cooling down');
    m.update(MotivationEngine.cooldown, game);
    m.onEvent(combo, game);
    expect(m.current?.id, isNot(first));
  });

  test('every motivation has text in both languages', () {
    for (final kind in MotivationKind.values) {
      final m = Motivation(kind, 1, value: 3);
      expect(m.text(AppStrings.tr), isNotEmpty);
      expect(m.text(AppStrings.en), isNotEmpty);
    }
  });

  test('clear labels avoid trademarked names', () {
    expect(AppStrings.tr.clearLabel(4, TSpin.none), 'DÖRTLÜ!');
    expect(AppStrings.en.clearLabel(4, TSpin.none), 'QUAD!');
    expect(AppStrings.en.clearLabel(2, TSpin.full), 'T-SPIN DOUBLE!');
    expect(AppStrings.en.score(12480), '12,480');
    expect(AppStrings.tr.score(12480), '12.480');
  });
}
