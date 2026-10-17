import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/core/tower/tower_landmarks.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Kule Küpler runs keep the best per mode and add up for İstanbul', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await Settings.load();
    expect(s.recordTowerRun(mode: TowerMode.climb, floors: 120, seconds: 300), isTrue);
    expect(s.recordTowerRun(mode: TowerMode.climb, floors: 80, seconds: 200), isFalse);
    expect(s.recordTowerRun(mode: TowerMode.wind, floors: 40, seconds: 90), isTrue);
    expect(s.towerBest(TowerMode.climb), 120);
    expect(s.towerTotal, 240);
    expect(s.gamesPlayed, 3);
    s.towerLook = 'cini';

    final again = await Settings.load();
    expect(again.towerBest(TowerMode.climb), 120);
    expect(again.towerBest(TowerMode.wind), 40);
    expect(again.towerTotal, 240);
    expect(again.towerLook, 'cini');
  });

  test("the day's tower gives three tries a day", () {
    var now = DateTime(2026, 10, 17, 9);
    final s = Settings.memory()..clock = () => now;
    expect(s.towerTriesLeft(now), TowerGame.dailyTries);
    for (final floors in [30, 55, 41]) {
      s.recordTowerRun(mode: TowerMode.daily, floors: floors, seconds: 60);
    }
    expect(s.towerTriesLeft(now), 0);
    expect(s.towerDayBest(now), 55);
    now = DateTime(2026, 10, 18, 9);
    expect(s.towerTriesLeft(now), TowerGame.dailyTries);
    expect(s.towerDayBest(now), 0);
  });

  test('a finished landmark gives its prize once', () {
    final s = Settings.memory();
    expect(s.claimLandmarks(), isEmpty);
    s.recordTowerRun(mode: TowerMode.climb, floors: 520, seconds: 600);
    final prizes = s.claimLandmarks();
    expect(prizes.map((p) => p.$1), [Landmark.galata]);
    expect(s.claimLandmarks(), isEmpty);
    expect(s.towerBuild.current, Landmark.maidens);
  });
}
