// Renders the App Store screenshots with the real game screens.
//   flutter test tool/store_screenshots_test.dart
// Writes ios/metadata/screenshots/<locale>/<device>-<n>-<scene>.png at the
// exact pixel sizes App Store Connect asks for (iPhone 6.9", iPad 13").
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/game/blocks/blocks_controller.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/ui/blocks_screen.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';

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

/// Opens the modes page from the home screen and picks [name].
Future<void> _startMode(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await _pump(tester, 10, 40);
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

final Map<String, _Scene> _scenes = {
  'menu': (tester, settings) async {},
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
  // The bomb power aiming at the stack (its 3×3 area is shown).
  'bomb': (tester, settings) async {
    await _startMode(tester, 'superMode');
    final game = _game(tester).game;
    _stack(game);
    game.debugGivePowers([PowerType.bomb, PowerType.bomb, PowerType.drill, PowerType.single, PowerType.gravity]);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await _pump(tester, 2);
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 33));
    }
    await _pump(tester, 12);
  },
  // Block puzzle: a piece dragged over the board, the lines it clears glow.
  'puzzle': (tester, settings) async {
    await _startMode(tester, 'blocksEndless');
    final c = _blocks(tester);
    c.game.debugSetBoard([
      'JJ...SS.',
      'J..TTT..',
      'LL.OO.II',
      'L..OO.I.',
      'ZZZZZZ..',
      'TT.TTTTT',
      'SSSSSS..',
      'IIIIII..',
    ]);
    c.game.debugSetTray(['o2', 'l4', 't1']);
    await _pump(tester, 3);
    final board = c.boardRect!();
    final cell = board.width / 8;
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('tray-0'))), kind: PointerDeviceKind.mouse);
    // With a mouse the piece is centred on the pointer: aim at cells 6-7.
    await gesture.moveTo(board.topLeft + Offset(7 * cell, 7 * cell) - const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 33));
    await gesture.moveTo(board.topLeft + Offset(7 * cell, 7 * cell));
    await _pump(tester, 12);
    addTearDown(gesture.up);
  },
  // Puzzle bombs: numbered bombs count down with every move.
  'bombs': (tester, settings) async {
    await _startMode(tester, 'bomb');
    final c = _blocks(tester);
    c.game.debugSetBoard([
      '........',
      '..3.....',
      'OO....JJ',
      'OOLL..J.',
      '.SL5..ZZ',
      'SS.TTTIZ',
      'IIII2TIZ',
      'LLL.ZZI.',
    ]);
    c.game.debugSetTray(['i3h', 'c4', 'o2']);
    await _pump(tester, 20);
  },
  // Another look: the pixel theme mid-game, powers in the bar.
  'pixel': (tester, settings) async {
    settings.visualTheme = VisualTheme.pixel;
    await _pump(tester, 5);
    await _startMode(tester, 'superMode');
    final game = _game(tester).game;
    _stack(game);
    game.debugGivePowers([PowerType.ghostLine, PowerType.drill, PowerType.slowMotion, PowerType.single]);
    game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 4, 3));
    await _pump(tester, 20);
  },
  // Zincir Küpler: a chain bursting, garbage on the stack.
  'chain': (tester, settings) async {
    settings.chainDifficulty = ChainDifficulty.normal;
    await _startMode(tester, 'chainEndless');
    final c = (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await _pump(tester, 10);
    c.game.debugSetBoard([
      '......',
      '......',
      '###...',
      '......',
      '......',
      '......',
      'G.....',
      'BBB.Y.',
      'GMY.BM',
      'GYM.GB',
      'MBGYMY',
      'YGBMBG',
    ]);
    c.game.debugSetIncoming('BMYGBY');
    c.game.stopTime = 100;
    c.game.score = 1480;
    c.game.setCursor(3, 7);
    await _pump(tester, 36);
  },
};

void main() {
  setUpAll(_loadFonts);

  for (final (device, size, dpr) in _devices) {
    for (final (locale, language) in _locales) {
      var n = 0;
      for (final MapEntry(key: name, value: scene) in _scenes.entries) {
        final index = ++n;
        testWidgets('$device $locale $name', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = dpr;
          addTearDown(tester.view.reset);
          final settings = Settings.memory()..language = language;
          await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
          await _pump(tester, 30);
          await scene(tester, settings);
          await _shot(tester, '$_out$locale/$device-$index-$name.png', dpr);
        });
      }
    }
  }
}
