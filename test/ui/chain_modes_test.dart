import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/chain/chain_puzzles.dart';
import 'package:lifeos_kupler/core/chain/chain_sim.dart';
import 'package:lifeos_kupler/core/chain/chain_versus.dart';
import 'package:lifeos_kupler/core/rewards.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_hub.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<Settings> open(WidgetTester tester, String mode, {Settings? settings}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = settings ?? (Settings.memory()..language = AppLanguage.tr);
  await tester.pumpWidget(KuplerApp(settings: s, audio: AudioService(enabled: false)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await pumpFor(tester, 10, 40);
  await tester.tap(find.byKey(const ValueKey('game-chain')));
  await pumpFor(tester, 10, 40);
  await tester.ensureVisible(find.byKey(ValueKey('mode-$mode'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(ValueKey('mode-$mode')));
  await pumpFor(tester, 10, 40);
  return s;
}

ChainController controllerOf(WidgetTester tester, Type screen) => (tester.state(find.byType(screen)) as dynamic).c as ChainController;

/// Plays the puzzle on screen to its end with its solution.
Future<void> solve(WidgetTester tester, ChainController c) async {
  final moves = ChainSim.of(c.game).solve(c.game.movesLeft)!;
  for (final (x, y) in moves) {
    for (var i = 0; i < 120 && !c.game.settled; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(c.game.swap(x, y), isTrue);
  }
  await pumpFor(tester, 90);
}

void main() {
  test('the puzzles: no match to start with, colours in threes, a solution in their swaps', () {
    for (var n = 1; n <= ChainPuzzles.count; n++) {
      final p = ChainPuzzles.of(n);
      final sim = ChainSim.rows(p.rows);
      expect(sim.matches(), isEmpty, reason: 'puzzle $n');
      final counts = <int, int>{};
      for (final c in sim.cells.where((c) => c >= 0)) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
      expect(counts.values.every((k) => k % 3 == 0), isTrue, reason: 'puzzle $n');
      if (n <= 30) expect(sim.solve(p.moves), isNotNull, reason: 'puzzle $n');
    }
  });

  testWidgets('a puzzle: hint, undo, solve it and go to the next', (tester) async {
    final settings = await open(tester, 'chainPuzzles');
    expect(find.byType(ChainPuzzlesScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('puzzle-2')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('puzzle-2')));
    await pumpFor(tester, 10, 40);
    expect(find.byType(ChainScreen), findsNothing, reason: 'puzzle 2 waits for puzzle 1');

    await tester.tap(find.byKey(const ValueKey('puzzle-1')));
    await pumpFor(tester, 15, 40);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFor(tester, 10);
    final c = controllerOf(tester, ChainScreen);
    expect(c.game.isPuzzle, isTrue);
    expect(c.game.movesLeft, ChainPuzzles.of(1).moves);

    await tester.tap(find.byKey(const ValueKey('puzzle-hint')));
    await pumpFor(tester, 5);
    expect(c.hint, isNotNull);
    await solve(tester, c);
    expect(c.game.won, isTrue);
    expect(find.byKey(const ValueKey('chain-goal-result')), findsOneWidget);
    expect(settings.puzzleStars(1), 2, reason: 'a hint costs a star');

    await tester.tap(find.byKey(const ValueKey('chain-next')));
    await pumpFor(tester, 10);
    final next = controllerOf(tester, ChainScreen);
    expect(next.puzzle, 2);
    expect(next.playing, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the ferry line: the first mission, played and recorded', (tester) async {
    final settings = await open(tester, 'chainMissions');
    expect(find.byType(ChainMissionsScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('pier-card')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mission-1')));
    await pumpFor(tester, 15, 40);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFor(tester, 10);
    final c = controllerOf(tester, ChainScreen);
    expect(c.mode, ChainMode.mission);
    expect(c.game.mission!.kind, MissionKind.chain);
    // A known board where one swap makes a ×2 chain.
    c.game.debugSetBoard(['..Y...', '..Y...', 'GGBG..', 'BBYB..']);
    c.game.stopTime = 100;
    c.game.swap(2, ChainGame.height - 2);
    await pumpFor(tester, 120);
    expect(c.game.won, isTrue);
    expect(settings.missionStars(1), 3);
    expect(find.byKey(const ValueKey('chain-goal-result')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a match against Limon: pick a rival, win a set, the prize at the end', (tester) async {
    final settings = await open(tester, 'chainVersus');
    expect(find.byType(ChainVersusScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rival-journeyman')));
    await pumpFor(tester, 5);
    await tester.tap(find.byKey(const ValueKey('versus-start')));
    await pumpFor(tester, 10);
    final c = controllerOf(tester, ChainVersusScreen) as ChainVersusController;
    expect(c.rival, ChainRival.journeyman);
    expect(c.playing, isTrue);
    for (var set = 0; set < 2; set++) {
      c.cpu.endMatch(won: false);
      await pumpFor(tester, 50);
      expect(find.byKey(const ValueKey('versus-result')), findsOneWidget);
      if (set == 0) {
        await tester.tap(find.byKey(const ValueKey('versus-next-set')));
        await pumpFor(tester, 10);
      }
    }
    expect(c.matchOver, isTrue);
    expect(settings.rivalWins(ChainRival.journeyman.index), 1);
    expect(settings.unlocked(Unlock.cubesCini), isTrue);
    expect(c.stars, 3);
    expect(tester.takeException(), isNull);
  });
}
