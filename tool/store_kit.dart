// Shared by the store screenshot and video tools: fonts, the way into a
// game through the games page, and the scenes' set-ups.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/game/blocks/blocks_controller.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/game/sugar/sugar_controller.dart';
import 'package:lifeos_kupler/game/tower/tower_controller.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/blocks_screen.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';
import 'package:lifeos_kupler/ui/sugar_screen.dart';

/// Wraps the app; what [storeShot] captures.
final storeRoot = GlobalKey();

Future<void> loadStoreFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Inter', [for (final w in ['Regular', 'SemiBold', 'ExtraBold', 'Black']) 'assets/fonts/Inter-$w.otf']);
  await family('Baloo2', [for (final w in ['SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/Baloo2-$w.ttf']);
  await family('Jersey10', ['assets/fonts/Jersey10-Regular.ttf']);
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  // MaterialIcons-Regular.otf; the name's case matters on Linux.
  final fonts = Directory('$sdk/bin/cache/artifacts/material_fonts');
  final icons = fonts.listSync().whereType<File>().firstWhere((f) => f.path.toLowerCase().endsWith('materialicons-regular.otf'));
  await family('MaterialIcons', [icons.path]);
}

Future<void> pumpFrames(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<void> storeShot(WidgetTester tester, String path, double dpr) async {
  final boundary = storeRoot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

/// The card on the games page that leads to [mode].
String gameOf(String mode) => switch (mode) {
  'sugar' => 'sugar',
  'superMode' => 'superGame',
  'blocksLevels' || 'blocksEndless' || 'adventure' || 'bomb' => 'puzzle',
  _ when mode.startsWith('chain') => 'chain',
  _ when mode.startsWith('tower') => 'tower',
  _ => 'classic',
};

/// Opens the games page from the home screen, then [name]'s game and [name].
Future<void> startMode(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await pumpFrames(tester, 10, 40);
  final game = ValueKey('game-${gameOf(name)}');
  await tester.ensureVisible(find.byKey(game, skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(game));
  await pumpFrames(tester, 10, 40);
  // A game of one mode starts at once.
  if (name == 'sugar' || name == 'superMode') return;
  final card = find.byKey(ValueKey('mode-$name'));
  await tester.ensureVisible(find.byKey(ValueKey('mode-$name'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(card);
  await pumpFrames(tester, 10, 40);
}

GameController fallingGame(WidgetTester tester) => (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;

BlocksController blocksOf(WidgetTester tester) => (tester.state(find.byType(BlocksScreen)) as dynamic).c as BlocksController;

/// A tall, colourful stack with the right column open for a four-line clear.
void tallStack(TetrisGame game) {
  game.debugSetBoard([
    '..T.......',
    '.TTT...OO.',
    'ZZ.SS..OO.',
    'JZZSSLLL..',
    'JJJSZZOOI.',
    'TTTIISSOI.',
    'LTJJJSSZZ.',
    'LLLJOOZZT.',
    'IIIIOOSTT.',
  ]);
  game.lines = 8;
}

typedef StoreScene = Future<void> Function(WidgetTester tester, Settings settings);

/// A Kule Küpler tower [height] floors tall, built straight in (no chests on
/// the way): a few cuts, the width grown back now and then.
void buildTower(TowerController c, int height) {
  final g = c.game;
  final rnd = Random(height);
  var cu = 0.0, cv = 0.0, a = 1.0, b = 1.0;
  for (var i = 1; i <= height; i++) {
    final cut = rnd.nextDouble() < 0.18 ? (rnd.nextDouble() - 0.5) * 0.16 : 0.0;
    if (i.isEven) {
      a = max(0.6, a - cut.abs() / 2);
      cu += cut / 2;
    } else {
      b = max(0.6, b - cut.abs() / 2);
      cv += cut / 2;
    }
    if (i % 9 == 0) {
      a = min(1, a + 0.1);
      b = min(1, b + 0.1);
    }
    g.floors.add(TowerFloor(cu: cu, cv: cv, a: a, b: b, flavor: (i * 5 + rnd.nextInt(2)) % 6));
  }
  g.axis = height.isEven ? TowerAxis.v : TowerAxis.u;
  c.dropped = true;
  c.camera = max(0, g.height - 5.5);
}

/// Şeker Küpler with levels 1..[done] passed and the stories read (but
/// [unseen]'s), up to the start panel of the next level.
Future<SugarController?> sugarUpTo(WidgetTester tester, Settings settings, int done, {int? unseen, bool play = true}) async {
  for (var n = 1; n <= done; n++) {
    settings.recordSugarLevel(n, stars: const [3, 2, 3, 3, 2][n % 5], score: 15000, seconds: 60);
  }
  for (var ch = 0; ch < SugarLevels.chapters; ch++) {
    if (ch != unseen) settings.markStorySeen(ch);
  }
  await startMode(tester, 'sugar');
  await tester.tap(find.byKey(const ValueKey('sugar-continue')));
  await pumpFrames(tester, 20, 40);
  if (!play) return null;
  await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
  await tester.tap(find.byKey(const ValueKey('sugar-play')));
  await pumpFrames(tester, 40);
  return (tester.state(find.byType(SugarScreen)) as dynamic).c as SugarController;
}

/// Plays [moves] good swaps on a Şeker board.
Future<void> sugarMoves(WidgetTester tester, SugarController c, int moves) async {
  for (var i = 0; i < moves && !c.game.isOver; i++) {
    final m = SugarSolver.best(c.game);
    if (m == null) break;
    c.trySwap(m.$1, m.$2);
    for (var k = 0; k < 300 && (c.busy || !c.game.isOver && c.game.status != SugarStatus.idle); k++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
  }
}

