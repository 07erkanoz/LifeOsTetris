import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/settings/settings.dart';

void main() {
  test('best scores are kept per mode and stats accumulate', () {
    final s = Settings.memory();
    expect(s.recordGame(mode: GameMode.classic, score: 500, lines: 4, seconds: 61), isTrue);
    expect(s.recordGame(mode: GameMode.classic, score: 300, lines: 2, seconds: 30), isFalse);
    expect(s.recordGame(mode: GameMode.relaxed, score: 400, lines: 3, seconds: 20), isTrue);
    expect(s.bestScore(GameMode.classic), 500);
    expect(s.bestScore(GameMode.relaxed), 400);
    expect(s.topScore, 500);
    expect(s.gamesPlayed, 3);
    expect(s.totalLines, 9);
    expect(s.totalSeconds, 111);
  });
}
