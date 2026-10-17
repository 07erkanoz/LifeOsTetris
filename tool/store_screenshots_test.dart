// Renders the App Store screenshots with the real game screens.
//   flutter test tool/store_screenshots_test.dart
// Writes ios/metadata/screenshots/<locale>/<device>-<nn>-<scene>.png at the
// exact pixel sizes App Store Connect asks for (iPhone 6.9", iPad 13"); the
// two-digit number keeps them in order (App Store Connect takes ten).
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_versus.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/game/blocks/blocks_controller.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/game/sugar/sugar_controller.dart';
import 'package:lifeos_kupler/game/tower/tower_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/blocks_screen.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';
import 'package:lifeos_kupler/ui/sugar_screen.dart';
import 'package:lifeos_kupler/ui/tower_screen.dart';

/// Output folder (`SHOTS_OUT`).
final String _out = Platform.environment['SHOTS_OUT'] ?? 'ios/metadata/screenshots/';

/// App Store sizes: iPhone 6.9" (1320×2868 @3x) and iPad 13" (2064×2752 @2x).
const _devices = [('iphone', Size(1320, 2868), 3.0), ('ipad', Size(2064, 2752), 2.0)];

const _locales = [('tr', AppLanguage.tr), ('en-US', AppLanguage.en)];

final _root = GlobalKey();

Future<void> _loadFonts() async {
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
  await family('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
}

Future<void> _pump(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<void> _shot(WidgetTester tester, String path, double dpr) async {
  final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
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
String _gameOf(String mode) => switch (mode) {
  'sugar' => 'sugar',
  'superMode' => 'superGame',
  'blocksLevels' || 'blocksEndless' || 'adventure' || 'bomb' => 'puzzle',
  _ when mode.startsWith('chain') => 'chain',
  _ when mode.startsWith('tower') => 'tower',
  _ => 'classic',
};

/// Opens the games page from the home screen, then [name]'s game and [name].
Future<void> _startMode(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await _pump(tester, 10, 40);
  final game = ValueKey('game-${_gameOf(name)}');
  await tester.ensureVisible(find.byKey(game, skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(game));
  await _pump(tester, 10, 40);
  // A game of one mode starts at once.
  if (name == 'sugar' || name == 'superMode') return;
  final card = find.byKey(ValueKey('mode-$name'));
  await tester.ensureVisible(find.byKey(ValueKey('mode-$name'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(card);
  await _pump(tester, 10, 40);
}

GameController _game(WidgetTester tester) => (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;

BlocksController _blocks(WidgetTester tester) => (tester.state(find.byType(BlocksScreen)) as dynamic).c as BlocksController;

/// A tall, colourful stack with the right column open for a four-line clear.
void _stack(TetrisGame game) {
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

typedef _Scene = Future<void> Function(WidgetTester tester, Settings settings);

/// A Kule Küpler tower [height] floors tall, built straight in (no chests on
/// the way): a few cuts, the width grown back now and then.
void _tower(TowerController c, int height) {
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
Future<SugarController?> _sugar(WidgetTester tester, Settings settings, int done, {int? unseen, bool play = true}) async {
  for (var n = 1; n <= done; n++) {
    settings.recordSugarLevel(n, stars: const [3, 2, 3, 3, 2][n % 5], score: 15000, seconds: 60);
  }
  for (var ch = 0; ch < SugarLevels.chapters; ch++) {
    if (ch != unseen) settings.markStorySeen(ch);
  }
  await _startMode(tester, 'sugar');
  await tester.tap(find.byKey(const ValueKey('sugar-continue')));
  await _pump(tester, 20, 40);
  if (!play) return null;
  await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
  await tester.tap(find.byKey(const ValueKey('sugar-play')));
  await _pump(tester, 40);
  return (tester.state(find.byType(SugarScreen)) as dynamic).c as SugarController;
}

/// Plays [moves] good swaps on a Şeker board.
Future<void> _sugarMoves(WidgetTester tester, SugarController c, int moves) async {
  for (var i = 0; i < moves && !c.game.isOver; i++) {
    final m = SugarSolver.best(c.game);
    if (m == null) break;
    c.trySwap(m.$1, m.$2);
    for (var k = 0; k < 300 && (c.busy || !c.game.isOver && c.game.status != SugarStatus.idle); k++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
  }
}

final Map<String, _Scene> _scenes = {
  // The home screen, Kule Küpler on the play card.
  'menu': (tester, settings) async {
    settings.lastPlay = 'towerClimb';
    settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
    await _pump(tester, 30);
  },
  // Kule Küpler in the clouds: a perfect run, stars bursting off the top.
  'tower': (tester, settings) async {
    settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
    await _startMode(tester, 'towerClimb');
    final c = (tester.state(find.byType(TowerScreen)) as dynamic).c as TowerController;
    _tower(c, 124);
    for (var i = 0; i < 4; i++) {
      c.game.position = 0;
      c.tap();
      await _pump(tester, i < 3 ? 14 : 4);
    }
    c.game.position = -0.9;
  },
  // İstanbul'u İnşa Et: Kız Kulesi rising.
  'build': (tester, settings) async {
    settings.recordTowerRun(mode: TowerMode.climb, floors: 1140, seconds: 3000);
    settings.claimLandmarks();
    await _startMode(tester, 'towerBuild');
    await _pump(tester, 30);
  },
  // Şeker Küpler mid-level: specials on the board, the rush meter filling.
  'sugar': (tester, settings) async {
    final c = (await _sugar(tester, settings, 51))!;
    await _sugarMoves(tester, c, 1);
    SugarPiece? at(int x, int y) => c.game.board[y][x];
    at(0, 1)?.special = Special.lineV;
    at(5, 6)?.special = Special.lineH;
    at(7, 3)?.special = Special.bomb;
    at(1, 6)?.special = Special.prism;
    c.game.rushMeter = 0.7;
    await _pump(tester, 50);
  },
  // The final on Çamlıca: Ekşi Limon throwing lemon slices.
  'limon': (tester, settings) async {
    final c = (await _sugar(tester, settings, 119))!;
    await _sugarMoves(tester, c, 4);
    await _pump(tester, 40);
  },
  // The games page: every game with its scene, its modes, the last played.
  'games': (tester, settings) async {
    settings.lastPlay = 'chainMissions';
    settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
    for (var n = 1; n <= 30; n++) {
      settings.recordSugarLevel(n, stars: 3, score: 15000, seconds: 60);
    }
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    await _pump(tester, 30, 40);
  },
  // Bulmaca: two lines blasting at once in the jewel colours, a streak on.
  'puzzle': (tester, settings) async {
    await _startMode(tester, 'blocksEndless');
    final c = _blocks(tester);
    c.game.debugSetBoard(['.TTTTTTT', '.LLLLLLL', 'SS..ZZ..', 'J..IIII.', 'JJ.O..OO', '.....TT.', 'ZZ..SS..', '.JJ...L.']);
    c.game.debugSetTray(['dot', 'i2v', 'o2']);
    c.game.streak = 3;
    c.place(1, 0, 0);
    await _pump(tester, 9);
  },
  // A match against Ekşi Limon: garbage crossing between the boards.
  'versus': (tester, settings) async {
    await _startMode(tester, 'chainVersus');
    await tester.tap(find.byKey(const ValueKey('versus-start')));
    await _pump(tester, 10);
    final c = (tester.state(find.byType(ChainVersusScreen)) as dynamic).c as ChainVersusController;
    for (var i = 0; i < 420; i++) {
      await tester.pump(const Duration(milliseconds: 33));
      if (i % 25 == 0 && c.game.settled) {
        final move = ChainCpu(ChainRival.master).pick(c.game);
        if (move != null) c.game.swap(move.$1, move.$2);
      }
      if (c.game.isOver) break;
    }
  },
  // Vapur Hattı: the missions along the Bosphorus piers.
  'ferry': (tester, settings) async {
    for (var n = 1; n <= 23; n++) {
      settings.recordMission(n, const [3, 2, 3, 3, 2][n % 5]);
    }
    await _startMode(tester, 'chainMissions');
    await _pump(tester, 10);
  },
  // A four-line clear caught mid-explosion.
  'tetris': (tester, settings) async {
    await _startMode(tester, 'normal');
    final game = _game(tester).game;
    _stack(game);
    game.lines = 0;
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 2));
    await _pump(tester, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pump(tester, 7);
  },
};

/// The order on the store page.
const _order = ['menu', 'tower', 'build', 'sugar', 'limon', 'games', 'ferry', 'versus', 'puzzle', 'tetris'];

void main() {
  setUpAll(_loadFonts);
  assert(_order.length == _scenes.length && _order.every(_scenes.containsKey));

  for (final (device, size, dpr) in _devices) {
    for (final (locale, language) in _locales) {
      var n = 0;
      for (final name in _order) {
        final scene = _scenes[name]!;
        final index = ++n;
        testWidgets('$device $locale $name', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = dpr;
          addTearDown(tester.view.reset);
          final settings = Settings.memory()..language = language;
          await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
          await _pump(tester, 30);
          await scene(tester, settings);
          await _shot(tester, '$_out$locale/$device-${index.toString().padLeft(2, '0')}-$name.png', dpr);
        });
      }
    }
  }
}
