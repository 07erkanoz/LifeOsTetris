import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/settings/score_board.dart';
import 'package:lifeos_kupler/settings/settings.dart';

void main() {
  test('a board keeps the best ten, in order, and says where a score went', () {
    final b = ScoreBoard();
    final day = DateTime(2026, 10, 18);
    for (final v in [500, 900, 100, 700]) {
      b.add('k', v, day);
    }
    expect(b.of('k').map((e) => e.value), [900, 700, 500, 100]);
    expect(b.add('k', 800, day), 2);
    for (var i = 0; i < 10; i++) {
      b.add('k', 1000 + i, day);
    }
    expect(b.of('k'), hasLength(ScoreBoard.keep));
    expect(b.add('k', 50, day), 0, reason: 'off the list');
    expect(b.placeFor('k', 5000), 1);
    final back = ScoreBoard.decode(b.encode());
    expect(back.of('k').map((e) => e.value), b.of('k').map((e) => e.value));
  });

  test('timed runs: the fastest first', () {
    final b = ScoreBoard();
    final day = DateTime(2026, 10, 18);
    b.add('t', 9000, day, lower: true);
    expect(b.add('t', 8000, day, lower: true), 1);
    expect(b.of('t').map((e) => e.value), [8000, 9000]);
  });

  test('a best from before the lists comes onto the list with the next game', () {
    final s = Settings.memory()..clock = () => DateTime(2026, 10, 18, 12);
    s.recordGame(mode: GameMode.classic, score: 15000, lines: 40, seconds: 300);
    expect(s.records(Settings.gameRecords(GameMode.classic)).map((e) => e.value), [15000]);
    s.recordGame(mode: GameMode.classic, score: 9000, lines: 20, seconds: 200);
    expect(s.lastRecordPlace, 2);
    expect(s.records(Settings.gameRecords(GameMode.classic)).map((e) => e.value), [15000, 9000]);
    expect(s.recordPlaceFor(Settings.gameRecords(GameMode.classic), 20000), 1);
  });

  test('Kule Küpler keeps the floors of each climb', () {
    final s = Settings.memory()..clock = () => DateTime(2026, 10, 18, 12);
    s.recordTowerRun(mode: TowerMode.climb, floors: 40, seconds: 60);
    s.recordTowerRun(mode: TowerMode.climb, floors: 64, seconds: 90);
    expect(s.lastRecordPlace, 1);
    expect(s.records(Settings.towerRecords(TowerMode.climb)).map((e) => e.value), [64, 40]);
    s.recordTowerRun(mode: TowerMode.daily, floors: 30, seconds: 60);
    expect(s.lastRecordPlace, 0, reason: "today's tower keeps its own best, not a list");
  });
}
