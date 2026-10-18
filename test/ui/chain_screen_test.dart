import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<Settings> openChain(WidgetTester tester, String mode, {AppLanguage language = AppLanguage.tr}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = language;
  await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await pumpFor(tester, 10, 40);
  await tester.tap(find.byKey(const ValueKey('game-chain')));
  await pumpFor(tester, 10, 40);
  final card = find.byKey(ValueKey('mode-$mode'));
  await tester.ensureVisible(find.byKey(ValueKey('mode-$mode'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(card);
  await pumpFor(tester, 10, 40);
  return settings;
}

ChainController controller(WidgetTester tester) => (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;

void main() {
  testWidgets('Zincir Küpler: pick a difficulty, play with the keyboard, pause and leave', (tester) async {
    final settings = await openChain(tester, 'chainEndless');
    expect(find.byType(ChainScreen), findsOneWidget);
    expect(find.text('Zincir Küpler'), findsWidgets);
    final c = controller(tester);
    expect(c.started, isFalse);
    expect(c.difficulty, ChainDifficulty.easy, reason: 'easy for a first game');

    await tester.tap(find.byKey(const ValueKey('chain-difficulty-normal')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.difficulty, ChainDifficulty.normal);
    expect(settings.chainDifficulty, ChainDifficulty.normal);

    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFor(tester, 10);
    expect(c.playing, isTrue);
    expect(c.game.difficulty, ChainDifficulty.normal);
    expect(settings.lastPlay, 'chainEndless');

    // A known board: one swap lines up three yellows.
    c.game.debugSetBoard(['YYBYGM']);
    c.game.setCursor(2, ChainGame.height - 1);
    c.game.stopTime = 100;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await pumpFor(tester, 40);
    expect(c.game.score, greaterThan(0));
    expect(c.game.debugRows().last, '...BGM');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 33));
    expect(c.game.cursorX, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.paused, isTrue);
    expect(find.text('Duraklatıldı'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('chain-menu')));
    await pumpFor(tester, 15, 40);
    expect(find.byType(ChainScreen), findsNothing);
    expect(find.byKey(const ValueKey('start')), findsOneWidget);
  });

  testWidgets('dragging a cube sideways swaps it along', (tester) async {
    await openChain(tester, 'chainEndless');
    final c = controller(tester);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFor(tester, 5);
    c.game.debugSetBoard(['GBYMOB']);
    c.game.stopTime = 100;
    await tester.pump(const Duration(milliseconds: 33));

    final board = find.byKey(const ValueKey('chain-board'));
    final box = tester.getRect(board);
    // The well starts after the side margin; find the cell size from it.
    final cell = box.width / (ChainGame.width + 1.1);
    final y = box.top + (0.16 + ChainGame.height - 0.5) * cell;
    final start = Offset(box.left + (0.55 + 0.5) * cell, y);
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(start + Offset(cell * 2, 0));
    await pumpFor(tester, 10);
    await gesture.up();
    await pumpFor(tester, 10);
    expect(c.game.debugRows().last, 'BYGMOB');
    expect(tester.takeException(), isNull);
  });

  testWidgets('time attack shows the result when the time is up', (tester) async {
    final settings = await openChain(tester, 'chainTime', language: AppLanguage.en);
    expect(find.text('Time Attack'), findsWidgets);
    final c = controller(tester);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFor(tester, 5);
    c.game.score = 1234;
    c.game.time = ChainGame.timeAttackLength - 0.05;
    await pumpFor(tester, 50);
    expect(c.game.isOver, isTrue);
    expect(find.byKey(const ValueKey('chain-again')), findsOneWidget);
    expect(find.text("Time's up!"), findsOneWidget);
    expect(settings.chainBest(ChainMode.timeAttack, ChainDifficulty.easy), 1234);
    expect(c.newRecord, isTrue);

    await tester.tap(find.byKey(const ValueKey('chain-again')));
    await pumpFor(tester, 5);
    expect(c.playing, isTrue);
    expect(c.game.score, 0);
    expect(tester.takeException(), isNull);
  });
}
