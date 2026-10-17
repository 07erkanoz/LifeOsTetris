import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/rewards.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';
import 'package:lifeos_kupler/game/sugar/sugar_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/sugar_map_screen.dart';
import 'package:lifeos_kupler/ui/sugar_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

/// Opens the Şeker map; the first chapter's story card counts as seen
/// unless [story].
Future<Settings> openSugar(WidgetTester tester, {Settings? settings, bool story = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  settings ??= Settings.memory()..language = AppLanguage.tr;
  if (!story) settings.markStorySeen(0);
  await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await pumpFor(tester, 10, 40);
  await tester.ensureVisible(find.byKey(const ValueKey('game-sugar'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(const ValueKey('game-sugar')));
  await pumpFor(tester, 10, 40);
  return settings;
}

SugarController controller(WidgetTester tester) => (tester.state(find.byType(SugarScreen)) as dynamic).c as SugarController;

/// Plays the solver's move through the screen and waits for the board.
Future<void> playMove(WidgetTester tester, SugarController c) async {
  final m = SugarSolver.best(c.game)!;
  c.trySwap(m.$1, m.$2);
  for (var i = 0; i < 1500 && (c.busy || !c.game.isOver && c.game.status != SugarStatus.idle); i++) {
    await tester.pump(const Duration(milliseconds: 33));
  }
}

void main() {
  testWidgets('Şeker Küpler: the map, a level start, a few moves, pause and leave', (tester) async {
    final settings = await openSugar(tester);
    expect(find.byType(SugarMapScreen), findsOneWidget);
    expect(find.text('Devam: Seviye 1'), findsWidgets);
    expect(find.text('BÖLÜM 1'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await pumpFor(tester, 12, 40);
    expect(find.byType(SugarScreen), findsOneWidget);
    expect(find.text('SEVİYE 1'), findsWidgets);
    expect(find.textContaining('3 tanesini diz'), findsWidgets, reason: 'level 1 explains the swap');

    await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
    await tester.tap(find.byKey(const ValueKey('sugar-play')));
    await pumpFor(tester, 30);
    final c = controller(tester);
    expect(c.started, isTrue);
    expect(settings.lastPlay, 'sugar');
    expect(find.byKey(const ValueKey('sugar-mascot')), findsOneWidget);
    expect(c.mascot.line, isNotNull, reason: 'Lokum greets the player');
    expect(c.canPlay, isTrue);

    final moves = c.game.moves;
    await playMove(tester, c);
    expect(c.game.moves, moves - 1);
    expect(c.game.score, greaterThan(0));
    expect(c.game.board.expand((r) => r).every((p) => p != null), isTrue);

    // A drag across the board swaps too (or bounces back); either way the
    // board stays whole.
    final board = find.byKey(const ValueKey('sugar-board'));
    final box = tester.getRect(board);
    await tester.dragFrom(box.topLeft + Offset(box.width * 0.3, box.height * 0.3), const Offset(40, 0));
    await pumpFor(tester, 40);
    expect(c.game.board.expand((r) => r).every((p) => p != null), isTrue);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('sugar-pause')));
    await pumpFor(tester, 8);
    expect(c.paused, isTrue);
    expect(find.text('Duraklatıldı'), findsWidgets);
    expect(settings.savedSugar, isNotNull, reason: 'a pause keeps the level to continue');

    await tester.tap(find.text('Harita').first);
    await pumpFor(tester, 15, 40);
    expect(find.byType(SugarScreen), findsNothing);
    expect(find.byType(SugarMapScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a level left half way continues where it was', (tester) async {
    final settings = await openSugar(tester);
    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await pumpFor(tester, 12, 40);
    await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
    await tester.tap(find.byKey(const ValueKey('sugar-play')));
    await pumpFor(tester, 30);
    var c = controller(tester);
    c.game.goals = [SugarGoal.color(SugarColor.red, 999)];
    await playMove(tester, c);
    await playMove(tester, c);
    final rows = c.game.debugRows(), score = c.game.score, moves = c.game.moves;

    // The system back gesture pauses; back again leaves.
    await tester.binding.handlePopRoute();
    await pumpFor(tester, 6);
    expect(c.paused, isTrue);
    await tester.binding.handlePopRoute();
    await pumpFor(tester, 15, 40);
    expect(find.byType(SugarMapScreen), findsOneWidget);
    expect(jsonDecode(settings.savedSugar!)['level'], 1);

    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await pumpFor(tester, 20, 40);
    c = controller(tester);
    expect(c.started, isTrue, reason: 'no start panel: straight back into the level');
    expect(c.game.debugRows(), rows);
    expect(c.game.score, score);
    expect(c.game.moves, moves);
    expect(tester.takeException(), isNull);
  });

  testWidgets('winning a level gives stars, the next level, and a chest on level 5', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    for (var n = 1; n <= 4; n++) {
      settings.recordSugarLevel(n, stars: 2, score: 9000, seconds: 30);
    }
    final hammers = settings.sugarBoosters(SugarBooster.hammer);
    await openSugar(tester, settings: settings);
    expect(find.text('Devam: Seviye 5'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await pumpFor(tester, 12, 40);
    await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
    await tester.tap(find.byKey(const ValueKey('sugar-play')));
    await pumpFor(tester, 30);
    final c = controller(tester);
    for (var i = 0; i < 40 && !c.game.isOver; i++) {
      await playMove(tester, c);
    }
    expect(c.game.status, SugarStatus.won);
    await pumpFor(tester, 40);
    expect(c.showResult, isTrue);
    expect(find.text('SEVİYE TAMAM!'), findsWidgets);
    expect(find.text('SANDIK AÇILDI!'), findsWidgets);
    expect(settings.sugarStars(5), greaterThan(0));
    expect(settings.sugarBoosters(SugarBooster.hammer), greaterThan(hammers));
    expect(settings.sugarLevel, 6);
    expect(settings.savedSugar, isNull);
    // The sweets went into the jar, and Lokum brought a surprise.
    expect(settings.jarCount, greaterThan(0));
    expect(c.surprise, isNotNull);
    expect(find.byKey(const ValueKey('sugar-rewards')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sugar-next')));
    await pumpFor(tester, 30);
    expect(c.level.number, 6);
    expect(c.started, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('out of moves: go on with extra moves, or try again', (tester) async {
    final settings = await openSugar(tester);
    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await pumpFor(tester, 12, 40);
    await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
    await tester.tap(find.byKey(const ValueKey('sugar-play')));
    await pumpFor(tester, 30);
    final c = controller(tester);
    c.game.goals = [SugarGoal.score(1 << 30)];
    c.game.moves = 1;
    await playMove(tester, c);
    await pumpFor(tester, 40);
    expect(c.game.status, SugarStatus.lost);
    expect(find.text('HAMLE BİTTİ'), findsWidgets);

    final extra = settings.sugarBoosters(SugarBooster.moves);
    await tester.tap(find.byKey(const ValueKey('sugar-extra')));
    await pumpFor(tester, 20);
    expect(settings.sugarBoosters(SugarBooster.moves), extra - 1);
    expect(c.game.moves, SugarBooster.extraMoves);
    expect(c.game.status, SugarStatus.idle);
    expect(find.text('HAMLE BİTTİ'), findsNothing);

    // The hammer smashes one cube.
    final hammers = settings.sugarBoosters(SugarBooster.hammer);
    await tester.tap(find.byKey(const ValueKey('sugar-hammer')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.hammerArmed, isTrue);
    expect(find.text('Kırmak istediğin şekere dokun'), findsWidgets);
    final box = tester.getRect(find.byKey(const ValueKey('sugar-board')));
    await tester.tapAt(box.center);
    // Wait for the hammer and whatever falls after it.
    for (var i = 0; i < 1500 && !c.canPlay; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(settings.sugarBoosters(SugarBooster.hammer), hammers - 1);
    expect(c.hammerArmed, isFalse);
    expect(c.game.moves, SugarBooster.extraMoves, reason: 'the hammer costs no move');

    // The rainbow turns a sweet into a rainbow ball.
    final rainbows = settings.sugarBoosters(SugarBooster.rainbow);
    await tester.tap(find.byKey(const ValueKey('sugar-rainbow')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.rainbowArmed, isTrue);
    await tester.tapAt(box.center + const Offset(12, 12));
    await pumpFor(tester, 10);
    expect(settings.sugarBoosters(SugarBooster.rainbow), rainbows - 1);
    expect(c.game.board.expand((r) => r).where((p) => p?.isPrism ?? false), isNotEmpty);
    expect(c.armed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chapter opens with its story card, once', (tester) async {
    final settings = await openSugar(tester, story: true);
    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await pumpFor(tester, 20, 40);
    expect(find.byKey(const ValueKey('story-card')), findsOneWidget);
    expect(find.text('Eminönü'), findsWidgets);
    expect(find.textContaining('1777'), findsOneWidget, reason: 'it opens with history');
    expect(find.byKey(const ValueKey('sugar-play')), findsNothing);
    // History, Ekşi Limon, Lokum: three taps.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('story-card')));
      await pumpFor(tester, 10, 40);
      expect(find.byKey(const ValueKey('story-card')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('story-card')));
    await pumpFor(tester, 10, 40);
    expect(find.byKey(const ValueKey('story-card')), findsNothing);
    expect(find.byKey(const ValueKey('sugar-play')), findsOneWidget);
    expect(settings.storySeen(0), isTrue);
    expect(settings.storySeen(1), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets("the map keeps each chapter's postcard by its last level", (tester) async {
    final settings = await openSugar(tester);
    expect(find.byKey(const ValueKey('map-card-0'), skipOffstage: false), findsOneWidget);
    settings.applyGift(const Gift(card: 11));
    await pumpFor(tester, 4);
    // Into the middle of the screen, clear of the continue button.
    Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey('map-card-0'), skipOffstage: false)), alignment: 0.5);
    await pumpFor(tester, 4);
    await tester.tap(find.byKey(const ValueKey('map-card-0')));
    await pumpFor(tester, 10);
    expect(find.text('Mısır Çarşısı'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English strings and a locked level that does not open', (tester) async {
    await openSugar(tester, settings: Settings.memory()..language = AppLanguage.en);
    expect(find.text('Continue: Level 1'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('sugar-level-3')), warnIfMissed: false);
    await pumpFor(tester, 10, 40);
    expect(find.byType(SugarScreen), findsNothing);
    expect(SugarLevels.count, 120);
  });
}
