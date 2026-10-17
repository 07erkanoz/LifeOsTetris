import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/blocks/block_puzzle.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/game/blocks/blocks_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/blocks_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

const _crammed = ['T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T'];

Future<(Settings, BlocksController)> openEndless(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = AppLanguage.tr;
  await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
  await pumpFor(tester, 6);
  BlocksScreen.open(tester.element(find.byKey(const ValueKey('play'))), settings: settings, audio: AudioService(enabled: false), entry: BlocksEntry.endless);
  await pumpFor(tester, 20);
  final c = (tester.state(find.byType(BlocksScreen)) as dynamic).c as BlocksController;
  return (settings, c);
}

void main() {
  testWidgets('out of room with boosters: the rescue panel saves the game', (tester) async {
    final (settings, c) = await openEndless(tester);
    expect(find.byKey(const ValueKey('blocks-lokum')), findsOneWidget);
    final hammers = settings.sugarBoosters(SugarBooster.hammer);
    expect(hammers, greaterThan(0));
    c.game.debugSetBoard(_crammed);
    c.game.debugSetTray(['dot', 'o2', 'o2']);
    c.place(0, 1, 0);
    expect(c.game.status, BlockStatus.lost);
    expect(c.rescuing, isTrue);
    await pumpFor(tester, 40);
    expect(find.byKey(const ValueKey('rescue')), findsOneWidget);
    expect(settings.savedBlocks, isNull, reason: 'nothing saved while lost');
    await tester.tap(find.byKey(const ValueKey('rescue-hammer')));
    await pumpFor(tester, 20);
    expect(c.game.status, BlockStatus.playing);
    expect(settings.sugarBoosters(SugarBooster.hammer), hammers - 1);
    expect(find.byKey(const ValueKey('rescue')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('declining the rescue ends the game as before', (tester) async {
    final (settings, c) = await openEndless(tester);
    c.game.debugSetBoard(_crammed);
    c.game.debugSetTray(['dot', 'o2', 'o2']);
    c.place(0, 1, 0);
    await pumpFor(tester, 40);
    await tester.tap(find.byKey(const ValueKey('rescue-decline')));
    await pumpFor(tester, 50);
    expect(c.rescuing, isFalse);
    expect(find.byKey(const ValueKey('blocks-again')), findsOneWidget);
    expect(settings.blocksBest, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a while without a move: Lokum points at one', (tester) async {
    final (_, c) = await openEndless(tester);
    expect(c.hint, isNull);
    await pumpFor(tester, 300, 33);
    expect(c.hint, isNotNull);
    expect(find.text(AppStrings.tr.lokum('hint', 0)), findsOneWidget);
    // Picking up a piece puts the hint away.
    c.beginDrag(c.hint!.$1, const Offset(100, 700), mouse: false);
    expect(c.hint, isNull);
    c.abortDrag();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a combo shows on the score card', (tester) async {
    final (_, c) = await openEndless(tester);
    c.game.debugSetBoard(['.TTTTTTT', '.TTTTTTT', '........', '........', '........', '........', '........', '........']);
    c.game.debugSetTray(['dot', 'dot', 'dot']);
    c.place(0, 0, 0);
    c.place(1, 0, 1);
    await pumpFor(tester, 10);
    expect(c.game.streak, 2);
    expect(find.byKey(const ValueKey('blocks-combo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
