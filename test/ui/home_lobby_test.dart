import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';
import 'package:lifeos_kupler/ui/sugar_map_screen.dart';
import 'package:lifeos_kupler/ui/tower_screen.dart';
import 'package:lifeos_kupler/ui/sugar_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<Settings> pumpLobby(WidgetTester tester, {Size size = const Size(390, 844), Settings? settings, double text = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  settings ??= Settings.memory()..language = AppLanguage.tr;
  await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
  await pumpFor(tester, 6);
  return settings;
}

void main() {
  for (final theme in [VisualTheme.toyHd, VisualTheme.neon, VisualTheme.pixel]) {
    for (final size in const [Size(390, 844), Size(360, 640), Size(844, 390), Size(820, 1180), Size(1024, 768), Size(1920, 1080)]) {
      for (final text in [1.0, 1.3]) {
        testWidgets('${theme.name} ${size.width.round()}×${size.height.round()} text ×$text: the lobby fits', (tester) async {
          final settings = Settings.memory()
            ..language = AppLanguage.tr
            ..visualTheme = theme;
          await pumpLobby(tester, size: size, settings: settings, text: text);
          expect(tester.takeException(), isNull);
          for (final key in ['showcase', 'game-tiles', 'change-mode', 'open-settings', 'lokum', 'tip-action', 'daily-puzzle']) {
            expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
          }
          // The games are on screen without scrolling: the showcase and the
          // first tiles.
          final screen = Offset.zero & size;
          for (final key in ['show-tower', 'tile-tower', 'tile-sugar', 'lobby-settings']) {
            expect(screen.contains(tester.getCenter(find.byKey(ValueKey(key)))), isTrue, reason: '$key in view');
          }
          // A new player has nothing to continue.
          expect(find.byKey(const ValueKey('play')), findsNothing);
          await pumpFor(tester, 10);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Lokum offers today\'s gift, the daily puzzle, then a mode never played; tapping him changes the idea', (tester) async {
    await pumpLobby(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('lokum')));
    await pumpFor(tester, 2);
    expect(find.byKey(const ValueKey('tip-gift')), findsOneWidget, reason: 'today\'s gift is waiting');
    expect(find.byKey(const ValueKey('gifts-badge')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lokum')));
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('tip-daily')), findsOneWidget, reason: 'today\'s puzzle is not solved');
    await tester.tap(find.byKey(const ValueKey('lokum')));
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('tip-towerClimb')), findsOneWidget);
    expect(find.text('Buna hiç bakmadın, bence bayılırsın!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tip-action')));
    await pumpFor(tester, 15, 40);
    expect(find.byType(TowerScreen), findsOneWidget);
  });

  testWidgets('a Şeker Küpler level left half way comes first: the bar on top, the bubble and its tile', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    settings.savedSugar = jsonEncode({'level': 7});
    await pumpLobby(tester, settings: settings);
    expect(find.byKey(const ValueKey('resume-sugar')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('resume-sugar')), matching: find.text('Seviye 7')), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-sugar')), findsOneWidget);
    expect(find.text('7. seviyede kalmıştık!'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('tile-sugar')), matching: find.text('DEVAM')), findsOneWidget);
    // The bar is above the showcase.
    expect(tester.getRect(find.byKey(const ValueKey('resume-sugar'))).bottom, lessThanOrEqualTo(tester.getRect(find.byKey(const ValueKey('showcase'))).top));
  });

  testWidgets('one bar however many games wait: the last one played; the others go back in from their tiles', (tester) async {
    final settings = Settings.memory()
      ..language = AppLanguage.tr
      ..lastPlay = 'sugar';
    settings.savedSugar = jsonEncode({'level': 7});
    final chain = ChainGame()..start(ChainMode.endless);
    chain.score = 321;
    settings.savedChain = jsonEncode(chain.toSave());
    await pumpLobby(tester, settings: settings);
    expect(find.byKey(const ValueKey('resume-sugar')), findsOneWidget);
    expect(find.byKey(const ValueKey('resume-chain')), findsNothing);
    expect(find.descendant(of: find.byKey(const ValueKey('tile-chain')), matching: find.text('DEVAM')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tile-chain')));
    await pumpFor(tester, 20, 40);
    final c = (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;
    expect(c.game.score, 321, reason: 'straight back into the game left');
  });

  testWidgets('the showcase slides on by itself, and OYNA starts the game shown', (tester) async {
    await pumpLobby(tester);
    expect(find.text('1 / 6'), findsOneWidget);
    await pumpFor(tester, 160, 30);
    expect(find.text('2 / 6'), findsOneWidget, reason: 'the next game after a few seconds');
    await tester.tap(find.byKey(const ValueKey('show-sugar')));
    await pumpFor(tester, 15, 40);
    expect(find.byType(SugarMapScreen), findsOneWidget);
  });

  testWidgets('a game tile opens its own page; a game of one mode starts', (tester) async {
    await pumpLobby(tester);
    await tester.tap(find.byKey(const ValueKey('tile-chain')));
    await pumpFor(tester, 12, 40);
    expect(find.byKey(const ValueKey('game-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode-chainMissions')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('game-back')));
    await pumpFor(tester, 12, 40);
    await tester.tap(find.byKey(const ValueKey('tile-tower')));
    await pumpFor(tester, 12, 40);
    expect(find.byKey(const ValueKey('mode-towerClimb')), findsOneWidget);
  });

  testWidgets('the first time, Lokum shows there are six games; once', (tester) async {
    final settings = Settings.memory()
      ..language = AppLanguage.tr
      ..homeTourSeen = false;
    await pumpLobby(tester, settings: settings);
    await pumpFor(tester, 4);
    expect(find.byKey(const ValueKey('home-tour')), findsOneWidget);
    expect(find.text('Burada tam 6 oyun var!'), findsOneWidget);
    // It takes the tap: nothing starts behind it.
    await tester.tap(find.byKey(const ValueKey('home-tour-ok')));
    await pumpFor(tester, 6);
    expect(find.byKey(const ValueKey('home-tour')), findsNothing);
    expect(find.byType(SugarMapScreen), findsNothing);
    expect(settings.homeTourSeen, isTrue);
  });

  testWidgets('the last game played comes back from the bar on top', (tester) async {
    final settings = Settings.memory()
      ..language = AppLanguage.tr
      ..lastPlay = 'towerClimb';
    await pumpLobby(tester, settings: settings);
    expect(find.descendant(of: find.byKey(const ValueKey('play')), matching: find.textContaining('SON OYNADIĞIN', findRichText: true)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('play')));
    await pumpFor(tester, 15, 40);
    expect(find.byType(TowerScreen), findsOneWidget);
  });

  testWidgets('a new player sees no NEW badges; for the others a game played is no longer new', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    await pumpLobby(tester, settings: settings);
    expect(find.text('YENİ'), findsNothing, reason: 'to a new player everything is new');
    // Once they have played something, the games they have not tried are new.
    settings.lastPlay = 'normal';
    await pumpFor(tester, 4);
    expect(find.descendant(of: find.byKey(const ValueKey('tile-chain')), matching: find.text('YENİ')), findsOneWidget);
    settings.recordChainGame(mode: ChainMode.endless, difficulty: ChainDifficulty.easy, score: 900, seconds: 30);
    await pumpLobby(tester, settings: settings);
    await tester.ensureVisible(find.byKey(const ValueKey('lokum')));
    await tester.tap(find.byKey(const ValueKey('lokum')));
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('tip-chainEndless')), findsNothing);
    expect(find.descendant(of: find.byKey(const ValueKey('tile-chain')), matching: find.text('YENİ')), findsNothing);
  });

  testWidgets('with visual effects off the scenes hold still', (tester) async {
    final settings = Settings.memory()
      ..language = AppLanguage.tr
      ..effects = false;
    await pumpLobby(tester, settings: settings);
    bool moving() => (tester.state(find.byKey(const ValueKey('start'))) as dynamic).moving as bool;
    expect(moving(), isFalse);
    settings.effects = true;
    await tester.pump(const Duration(milliseconds: 33));
    expect(moving(), isTrue);
  });

  testWidgets('a Zincir Küpler game left half way continues from the home, paused', (tester) async {
    final settings = await pumpLobby(tester);
    expect(find.byKey(const ValueKey('resume-chain')), findsNothing);
    ChainScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings, audio: AudioService(enabled: false), mode: ChainMode.timeAttack);
    await pumpFor(tester, 12, 40);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFor(tester, 20);
    var c = (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;
    c.game.score = 4321;
    // Back pauses (and saves), back again leaves.
    await tester.binding.handlePopRoute();
    await pumpFor(tester, 6);
    expect(c.paused, isTrue);
    expect(settings.savedChain, isNotNull);
    await tester.binding.handlePopRoute();
    await pumpFor(tester, 15, 40);
    expect(find.byType(ChainScreen), findsNothing);

    expect(find.byKey(const ValueKey('resume-chain')), findsOneWidget);
    expect(find.textContaining('4.321'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resume-chain')));
    await pumpFor(tester, 15, 40);
    c = (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;
    expect(c.game.score, 4321);
    expect(c.game.mode, ChainMode.timeAttack);
    expect(c.paused, isTrue, reason: 'it waits for the player');
    expect(tester.takeException(), isNull);

    // A new game drops the saved one.
    c.start();
    expect(settings.savedChain, isNull);
  });

  testWidgets('a Şeker Küpler level left half way has its own continue button', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    await pumpLobby(tester, settings: settings);
    expect(find.byKey(const ValueKey('resume-sugar')), findsNothing);
    settings.savedSugar = jsonEncode({'level': 3});
    await pumpFor(tester, 4);
    expect(find.byKey(const ValueKey('resume-sugar')), findsOneWidget);
    expect(find.textContaining('Seviye 3'), findsWidgets);
  });

  testWidgets('the Şeker Küpler continue button goes straight into the level', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    await pumpLobby(tester, settings: settings);
    // Play a level a little, then leave it from the pause menu.
    SugarScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings, audio: AudioService(enabled: false), level: 2);
    await pumpFor(tester, 12, 40);
    await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
    await tester.tap(find.byKey(const ValueKey('sugar-play')));
    await pumpFor(tester, 30);
    final sugar = (tester.state(find.byType(SugarScreen)) as dynamic).c;
    sugar.game.score = 500;
    await tester.tap(find.byKey(const ValueKey('sugar-pause')));
    await pumpFor(tester, 8);
    await tester.ensureVisible(find.byKey(const ValueKey('sugar-home')));
    await tester.tap(find.byKey(const ValueKey('sugar-home')));
    await pumpFor(tester, 15, 40);
    expect(find.byKey(const ValueKey('resume-sugar')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('resume-sugar')));
    await pumpFor(tester, 20, 40);
    final back = (tester.state(find.byType(SugarScreen)) as dynamic).c;
    expect(back.started, isTrue, reason: 'no start panel: straight into the level');
    expect(back.level.number, 2);
    expect(back.game.score, 500);
  });
}
