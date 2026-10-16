import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/core/blocks/level_generator.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/game/blocks/blocks_controller.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/blocks_screen.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';
import 'package:lifeos_kupler/ui/power_bar.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/ui/widgets.dart';

Settings settings(WidgetTester tester) => (tester.widget(find.byType(KuplerApp)) as KuplerApp).settings;

/// Opens the modes page from the home screen and picks [name].
Future<void> startMode(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
  final card = find.byKey(ValueKey('mode-$name'));
  // Cards far down the modes page count as offstage until scrolled to.
  await tester.ensureVisible(find.byKey(ValueKey('mode-$name'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(card);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  Future<void> pumpApp(WidgetTester tester, Size size, {AppLanguage language = AppLanguage.tr}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KuplerApp(settings: Settings.memory()..language = language, audio: AudioService(enabled: false)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final (name, size) in [('phone', const Size(390, 844)), ('desktop', const Size(1440, 900))]) {
    testWidgets('$name: start a game, play, pause and quit to menu', (tester) async {
      await pumpApp(tester, size);
      expect(find.byKey(const ValueKey('play')), findsOneWidget);

      await startMode(tester, 'normal');
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      expect(find.byKey(const ValueKey('play')), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Duraklatıldı'), findsOneWidget);

      await tester.tap(find.text('Menü'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('play')), findsOneWidget);
    });
  }

  testWidgets('every theme can be picked from the menu and played', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = Settings.memory()..language = AppLanguage.tr;
    await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
    await tester.pump(const Duration(milliseconds: 100));

    for (final theme in [VisualTheme.pixel, VisualTheme.neon, VisualTheme.toy, VisualTheme.toyHd]) {
      await tester.tap(find.byKey(const ValueKey('open-themes')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(ValueKey('theme-${theme.name}')).last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(settings.visualTheme, theme);
      expect(activeSkin, theme.skin);
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 300));

      await startMode(tester, 'normal');
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Menü'));
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  testWidgets('a game left for the menu continues from the menu, paused', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('resume-game')), findsNothing);

    await startMode(tester, 'normal');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 33));
    final c = (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
    final score = c.game.score;
    expect(score, greaterThan(0));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Menü'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.savedGame, isNotNull);
    expect(find.byKey(const ValueKey('resume-game')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('resume-game')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.game.score, score);
    expect(c.game.paused, isTrue);
    expect(find.text('Duraklatıldı'), findsOneWidget);
  });

  testWidgets('challenge modes start from the menu with their own HUD', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    for (final (mode, label) in [
      (GameMode.sprint, 'KALAN'),
      (GameMode.ultra, 'SÜRE'),
      (GameMode.dig, 'SATIR'),
      (GameMode.target, 'YILDIZ'),
      (GameMode.chaos, 'SÜRPRİZ'),
    ]) {
      await startMode(tester, mode.name);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      final c = (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
      expect(c.mode, mode);
      expect(find.text(label), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Menü'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(settings(tester).savedGame, isNotNull);
    }
  });

  testWidgets('the daily puzzle opens from the main menu', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('daily-puzzle')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Günlük Görev'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the play button starts the last mode picked on the modes page', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    expect(find.text('Süper Küpler'), findsOneWidget);
    await startMode(tester, 'relaxed');
    final c = (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
    expect(c.mode, GameMode.relaxed);
    expect(settings(tester).lastPlay, 'relaxed');

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Menü'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Klasik Küpler · Rahat'), findsOneWidget);

    // The modes page closes with its back button too.
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.tap(find.byKey(const ValueKey('modes-back')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.byKey(const ValueKey('play')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('play')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(c.mode, GameMode.relaxed);
    expect(find.byKey(const ValueKey('play')), findsNothing);
  });

  testWidgets('about page shows the developer', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await tester.tap(find.text('Hakkında'));
    // The About hero animates forever, so pump a fixed time instead of settling.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.scrollUntilVisible(find.text('Erkan ÖZ'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Erkan ÖZ'), findsOneWidget);
    expect(find.text('erkanoz.com'), findsOneWidget);
    expect(find.text('lifeos.com.tr'), findsOneWidget);
  });

  testWidgets('English UI and switching language from the menu', (tester) async {
    await pumpApp(tester, const Size(390, 844), language: AppLanguage.en);
    expect(find.text('Super Blocks'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    // The language lives in the settings now.
    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Türkçe'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Süper Küpler'), findsOneWidget);
    expect(find.text('Hakkında'), findsOneWidget);
  });

  testWidgets('buttons can be hidden and the hold card holds a piece', (tester) async {
    final settings = Settings.memory()
      ..language = AppLanguage.tr
      ..showButtons = false;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
    await tester.pump(const Duration(milliseconds: 100));
    await startMode(tester, 'normal');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(find.byType(ControlButton), findsNothing);

    // The hold card itself holds too.
    await tester.tap(find.text('TUT').first);
    await tester.pump(const Duration(milliseconds: 33));
    final state = tester.state(find.byType(GameScreen)) as dynamic;
    expect((state.controller as GameController).game.held, isNotNull);
  });

  testWidgets('Süper Küpler shows the power bar and uses powers with number keys', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await startMode(tester, 'superMode');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(find.byType(PowerBar), findsOneWidget);

    final state = tester.state(find.byType(GameScreen)) as dynamic;
    final game = (state.controller as GameController).game;
    game.debugGivePowers([PowerType.bomb]);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump(const Duration(milliseconds: 33));
    expect(game.active!.type, PieceType.bomb);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(tester.takeException(), isNull);
  });

  Future<BlocksController> openBlocks(WidgetTester tester, Settings settings) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
    await tester.pump(const Duration(milliseconds: 100));
    // The Levels card opens the next level; its menu is one step back.
    await startMode(tester, 'blocksLevels');
    final state = tester.state(find.byType(BlocksScreen)) as dynamic;
    final c = state.c as BlocksController;
    c.openMenu();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(find.byKey(const ValueKey('blocks-continue')), findsOneWidget);
    return c;
  }

  testWidgets('Bulmaca Küpler: continue, solve level 1, earn stars, go on', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    final c = await openBlocks(tester, settings);
    expect(find.text('Devam et: Seviye 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('blocks-continue')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(c.view, BlocksView.playing);
    expect(find.text('Seviye 1'), findsOneWidget);

    final solution = BlockSolver.solve(c.level!)!;
    for (final (slot, x, y) in solution) {
      expect(c.place(slot, x, y), isTrue);
      await tester.pump(const Duration(milliseconds: 33));
    }
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(find.text('Seviye tamamlandı!'), findsOneWidget);
    expect(settings.blockStars(1), 3);
    expect(settings.unlockedBlockLevel, 2);

    await tester.tap(find.byKey(const ValueKey('blocks-next')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.level!.number, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Macera: chapters page, solve the first level, uncover a piece', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = Settings.memory()..language = AppLanguage.tr;
    await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
    await tester.pump(const Duration(milliseconds: 100));
    await startMode(tester, 'adventure');
    final c = (tester.state(find.byType(BlocksScreen)) as dynamic).c as BlocksController;
    expect(c.view, BlocksView.adventure);
    expect(find.text('Kalp'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('adventure-play')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(c.isAdventure, isTrue);
    expect(find.text('Bölüm 1 · 1'), findsOneWidget);
    for (final (slot, x, y) in BlockSolver.solve(c.level!)!) {
      expect(c.place(slot, x, y), isTrue);
      await tester.pump(const Duration(milliseconds: 33));
    }
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(find.text('Resmin yeni parçası açıldı!'), findsOneWidget);
    expect(find.byType(AdventurePicture), findsOneWidget);
    expect(settings.adventureStars(1), greaterThan(0));
    expect(settings.unlockedAdventure, 2);

    await tester.tap(find.text('Macera'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(c.view, BlocksView.adventure);
    expect(find.text('Oyna: Bölüm 1 · 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bomba: bombs appear, count down and can end the game', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = Settings.memory()..language = AppLanguage.tr;
    await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
    await tester.pump(const Duration(milliseconds: 100));
    await startMode(tester, 'bomb');
    final c = (tester.state(find.byType(BlocksScreen)) as dynamic).c as BlocksController;
    expect(c.isBombs, isTrue);
    expect(find.text('Bomba'), findsWidgets);

    c.game.debugSetBoard(['1.......', '........', '........', '........', '........', '........', '........', '........']);
    c.game.debugSetTray(['dot', 'dot', 'dot']);
    expect(c.place(0, 7, 7), isTrue);
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(find.text('Bomba patladı!'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bulmaca Küpler: drag a piece from the tray onto the board', (tester) async {
    final c = await openBlocks(tester, Settings.memory()..language = AppLanguage.tr);
    await tester.tap(find.byKey(const ValueKey('blocks-endless')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    c.game.debugSetBoard(['........', '........', '........', '........', '........', '........', 'TTTTTT..', 'TTTTTT..']);
    c.game.debugSetTray(['o2', 'dot', 'dot']);
    await tester.pump(const Duration(milliseconds: 33));

    final board = c.boardRect!();
    final cell = board.width / 8;
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('tray-0'))), kind: PointerDeviceKind.mouse);
    // With a mouse the piece is centred on the pointer: aim at cells 6-7.
    await gesture.moveTo(board.topLeft + Offset(7 * cell, 7 * cell) - const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 33));
    await gesture.moveTo(board.topLeft + Offset(7 * cell, 7 * cell));
    await tester.pump(const Duration(milliseconds: 33));
    expect(c.target, (6, 6));
    expect(c.targetRows, [6, 7]);
    await gesture.up();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(c.game.lines, 2);
    expect(c.game.score, greaterThan(4));
    expect(c.game.tray[0], isNull);
    expect(tester.takeException(), isNull);
  });
}
