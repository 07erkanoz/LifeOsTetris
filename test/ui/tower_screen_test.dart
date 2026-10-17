import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/game/tower/tower_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/tower_build_screen.dart';
import 'package:lifeos_kupler/ui/tower_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

/// Opens Kule Küpler's page from the home screen and picks [mode].
Future<Settings> open(WidgetTester tester, String mode, {Settings? settings}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = settings ?? (Settings.memory()..language = AppLanguage.tr);
  await tester.pumpWidget(KuplerApp(settings: s, audio: AudioService(enabled: false)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await pumpFor(tester, 10, 40);
  await tester.tap(find.byKey(const ValueKey('game-tower')));
  await pumpFor(tester, 10, 40);
  await tester.ensureVisible(find.byKey(ValueKey('mode-$mode'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(ValueKey('mode-$mode')));
  await pumpFor(tester, 10, 40);
  return s;
}

TowerController controller(WidgetTester tester) => (tester.state(find.byType(TowerScreen)) as dynamic).c as TowerController;

void main() {
  testWidgets('Kule Küpler: the games page leads to the climb; a tap drops a floor', (tester) async {
    final settings = await open(tester, 'towerClimb');
    expect(find.byType(TowerScreen), findsOneWidget);
    expect(find.text('Dokun, katı bırak'), findsOneWidget);
    final c = controller(tester);
    expect(c.mode, TowerMode.climb);
    // Right on top: a perfect drop.
    c.game.position = 0;
    await tester.tap(find.byKey(const ValueKey('tower-board')));
    await pumpFor(tester, 12);
    expect(c.game.height, 1);
    expect(c.game.streak, 1);
    expect(find.text('Dokun, katı bırak'), findsNothing);
    expect(settings.lastPlay, 'towerClimb');

    // Pause, then back to the menu: the floors count for İstanbul.
    await tester.tap(find.byKey(const ValueKey('tower-pause')));
    await pumpFor(tester, 4);
    expect(find.byKey(const ValueKey('tower-resume')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tower-menu')));
    await pumpFor(tester, 14);
    expect(find.byType(TowerScreen), findsNothing);
    expect(settings.towerTotal, 1);
    expect(settings.towerBest(TowerMode.climb), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a miss ends the run: one more go, then the panel to play again', (tester) async {
    await open(tester, 'towerClimb');
    final c = controller(tester);
    for (var i = 0; i < 3; i++) {
      c.game.position = 0;
      c.tap();
    }
    c.game.position = 3;
    c.tap();
    await pumpFor(tester, 40);
    expect(find.byKey(const ValueKey('tower-revive')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tower-revive')));
    await pumpFor(tester, 6);
    expect(c.playing, isTrue);
    expect(c.game.height, 3);
    c.game.position = 3;
    c.tap();
    await pumpFor(tester, 40);
    expect(find.byKey(const ValueKey('tower-revive')), findsNothing);
    expect(find.text('3 kat'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('tower-again')));
    await pumpFor(tester, 6);
    expect(c.playing, isTrue);
    expect(c.game.height, 0);
    expect(c.settings.towerTotal, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a milestone opens its chest and the run goes on', (tester) async {
    await open(tester, 'towerWind');
    final c = controller(tester);
    for (var i = 0; i < TowerGame.milestones.first; i++) {
      c.game.position = 0;
      c.tap();
    }
    await pumpFor(tester, 8);
    expect(find.byKey(const ValueKey('gift-popup')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gift-collect')));
    await pumpFor(tester, 10);
    expect(c.chestAt, isNull);
    expect(c.playing, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("İstanbul'u İnşa Et shows the landmark being built", (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    settings.recordTowerRun(mode: TowerMode.climb, floors: 640, seconds: 900);
    await open(tester, 'towerBuild', settings: settings);
    await pumpFor(tester, 10);
    expect(find.byType(TowerBuildScreen), findsOneWidget);
    // Galata is finished: its prize first.
    expect(find.byKey(const ValueKey('gift-popup')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gift-collect')));
    await pumpFor(tester, 10);
    expect(find.text('Kız Kulesi'), findsWidgets);
    expect(find.text('Ada ve rıhtım'), findsOneWidget);
    await tester.dragUntilVisible(find.byKey(const ValueKey('landmark-galata')), find.byType(Scrollable).first, const Offset(0, -200));
    await pumpFor(tester, 4);
    await tester.tap(find.byKey(const ValueKey('landmark-galata')));
    await pumpFor(tester, 4);
    expect(find.text('Galata Kulesi'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
