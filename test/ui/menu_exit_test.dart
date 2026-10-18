import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';
import 'package:lifeos_kupler/ui/sugar_map_screen.dart';
import 'package:lifeos_kupler/ui/sugar_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 40]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<Settings> pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()
    ..language = AppLanguage.tr
    ..markStorySeen(0);
  await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
  await pumpFor(tester, 4);
  return settings;
}

void main() {
  testWidgets('the home menu has a quit button on desktops only', (tester) async {
    await pumpHome(tester);
    expect(find.byKey(const ValueKey('quit-game')), findsNothing, reason: 'phones leave with the system back or home');
    expect(find.byKey(const ValueKey('open-settings')), findsOneWidget);

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pumpHome(tester);
    expect(find.byKey(const ValueKey('quit-game')), findsOneWidget);
    expect(find.text('Çıkış'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Şeker Küpler pause: settings, map and back to the main menu', (tester) async {
    final settings = await pumpHome(tester);
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    await pumpFor(tester, 10);
    await tester.ensureVisible(find.byKey(const ValueKey('game-sugar'), skipOffstage: false));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byKey(const ValueKey('game-sugar')));
    await pumpFor(tester, 12);

    // The map has its own settings button.
    await tester.tap(find.byKey(const ValueKey('sugar-map-settings')));
    await pumpFor(tester, 8);
    expect(find.byType(SettingsPanel), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await pumpFor(tester, 8);
    expect(find.byType(SettingsPanel), findsNothing);

    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await pumpFor(tester, 12);
    await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
    await tester.tap(find.byKey(const ValueKey('sugar-play')));
    await pumpFor(tester, 30, 33);
    await tester.tap(find.byKey(const ValueKey('sugar-pause')));
    await pumpFor(tester, 8);

    await tester.tap(find.byKey(const ValueKey('sugar-settings')));
    await pumpFor(tester, 8);
    expect(find.byType(SettingsPanel), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await pumpFor(tester, 8);
    expect(find.byType(SettingsPanel), findsNothing);
    expect(find.byType(SugarScreen), findsOneWidget, reason: 'closing the settings keeps the level paused');

    await tester.ensureVisible(find.byKey(const ValueKey('sugar-home')));
    await tester.tap(find.byKey(const ValueKey('sugar-home')));
    await pumpFor(tester, 15);
    expect(find.byType(SugarScreen), findsNothing);
    expect(find.byType(SugarMapScreen), findsNothing);
    expect(find.byKey(const ValueKey('start')), findsOneWidget);
    expect(settings.lastPlay, 'sugar');
    expect(tester.takeException(), isNull);
  });

  testWidgets("the phone's back: pause, home, then out only on a second press", (tester) async {
    final settings = await pumpHome(tester);
    settings.homeTourSeen = false;
    await pumpFor(tester, 4);
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exits++;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    // The first launch's tour closes first.
    expect(find.byKey(const ValueKey('home-tour')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await pumpFor(tester, 8);
    expect(find.byKey(const ValueKey('home-tour')), findsNothing);
    expect(exits, 0);

    final c = (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
    c.start(GameMode.classic);
    await pumpFor(tester, 10);
    await tester.binding.handlePopRoute();
    await pumpFor(tester, 6);
    expect(c.game.paused, isTrue, reason: 'a game pauses, it does not close');
    await tester.binding.handlePopRoute();
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('start')), findsOneWidget);
    expect(find.byKey(const ValueKey('resume-game')), findsOneWidget, reason: 'kept to continue');
    expect(exits, 0);

    // The home screen: a hint first, out on the second press.
    await tester.binding.handlePopRoute();
    await pumpFor(tester, 6);
    expect(find.text('Çıkmak için bir kez daha geri bas'), findsOneWidget);
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 1);

    // Too late for a second press: a hint again.
    await pumpFor(tester, 60, 50);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 1);
    await pumpFor(tester, 60, 50);
    expect(settings.homeTourSeen, isTrue);
    expect(tester.takeException(), isNull);
  });
}
