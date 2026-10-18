// The records in the real game: Klasik Küpler's game over with the top
// five, the bar to the record while playing, a game page's records sheet,
// and Kule Küpler's climb ending.
//   flutter test tool/records_screenshots_test.dart
// Writes SHOTS_OUT (default build/records/): over.png, playing.png,
// sheet.png, tower.png.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/game/tower/tower_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';
import 'package:lifeos_kupler/ui/tower_screen.dart';

import 'store_kit.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/records/';
const _size = Size(390, 844);
const _dpr = 2.5;

Future<Settings> _app(WidgetTester tester) async {
  tester.view.physicalSize = _size * _dpr;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
  var day = 6;
  final settings = Settings.memory()
    ..language = AppLanguage.tr
    ..clock = () => DateTime(2026, 10, day, 12);
  for (final score in [15398, 9210, 8770, 6105, 5940, 4320]) {
    settings.recordGame(mode: GameMode.classic, score: score, lines: 40, seconds: 300);
    day++;
  }
  for (final floors in [212, 160, 140, 96]) {
    settings.recordTowerRun(mode: TowerMode.climb, floors: floors, seconds: 300);
    day++;
  }
  settings.clock = () => DateTime(2026, 10, 18, 12);
  await tester.pumpWidget(RepaintBoundary(key: storeRoot, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await pumpFrames(tester, 10);
  return settings;
}

void main() {
  setUpAll(loadStoreFonts);

  testWidgets('falling blocks: the bar, then the game over', (tester) async {
    await _app(tester);
    await startMode(tester, 'normal');
    final c = (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
    c.game.score = 13062;
    await pumpFrames(tester, 10);
    await storeShot(tester, '${_out}playing.png', _dpr);
    // Stack the board up to the top: the next pieces end the game.
    tallStack(c.game);
    for (var i = 0; i < 40 && c.game.status != GameStatus.over; i++) {
      c.game.score = 12480;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpFrames(tester, 4);
    }
    await pumpFrames(tester, 150);
    await storeShot(tester, '${_out}over.png', _dpr);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a game page's records", (tester) async {
    await _app(tester);
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    await pumpFrames(tester, 10, 40);
    await tester.tap(find.byKey(const ValueKey('game-classic')));
    await pumpFrames(tester, 10, 40);
    await tester.tap(find.byKey(const ValueKey('records-open')));
    await pumpFrames(tester, 12, 40);
    await storeShot(tester, '${_out}sheet.png', _dpr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kule Küpler: a climb ends', (tester) async {
    await _app(tester);
    await startMode(tester, 'towerClimb');
    final c = (tester.state(find.byType(TowerScreen)) as dynamic).c as TowerController;
    buildTower(c, 150);
    // Far off the tower: it misses, the climb ends at 150.
    for (var i = 0; i < 20 && c.playing; i++) {
      c.game.position = 6;
      c.tap();
      await pumpFrames(tester, 6);
    }
    await pumpFrames(tester, 60);
    await storeShot(tester, '${_out}tower.png', _dpr);
    expect(tester.takeException(), isNull);
  });
}
