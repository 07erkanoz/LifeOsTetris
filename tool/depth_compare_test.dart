// Before/after shots of the falling-block board's depth effects (wall
// shadow, light, contact shadows, holes) on the same stack.
//   flutter test tool/depth_compare_test.dart
// Writes SHOTS_OUT (default build/depth/): <theme>-before.png, -after.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/core/tetromino.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/game/render/board_painter.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/depth/';
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
  await family('MaterialIcons', [Directory('$sdk/bin/cache/artifacts/material_fonts').listSync().whereType<File>().firstWhere((f) => f.path.toLowerCase().endsWith('materialicons-regular.otf')).path]);
}

Future<void> _pump(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(_loadFonts);

  for (final theme in [VisualTheme.toyHd, VisualTheme.pixel, VisualTheme.neon]) {
    testWidgets('depth ${theme.name}', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      addTearDown(() => BoardPainter.depth = true);
      final settings = Settings.memory()
        ..language = AppLanguage.tr
        ..visualTheme = theme;
      await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
      await _pump(tester, 20);
      await tester.tap(find.byKey(const ValueKey('change-mode')));
      await _pump(tester, 10, 40);
      await tester.ensureVisible(find.byKey(const ValueKey('mode-normal'), skipOffstage: false));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(const ValueKey('mode-normal')));
      await _pump(tester, 10, 40);
      final game = ((tester.state(find.byType(GameScreen)) as dynamic).controller as GameController).game;
      // A worn stack: overhangs, a few closed-off holes, a tower.
      game.debugSetBoard([
        '.......L..',
        '.....LLL..',
        '..TTT.....',
        '...T..OO..',
        'ZZ....OO.I',
        '.ZZ.LLL..I',
        'J...L.SS.I',
        'JJJ..SS..I',
        'IIII.OOTTT',
        'SS.ZZOOJT.',
        '.SSJZZJJTL',
      ]);
      game.lines = 6;
      game.debugSetActive(const Piece(PieceType.t, Rotation.spawn, 4, 3));
      await _pump(tester, 6);
      BoardPainter.depth = false;
      await _pump(tester, 2);
      await _shot(tester, '${theme.name}-before.png');
      BoardPainter.depth = true;
      await _pump(tester, 2);
      await _shot(tester, '${theme.name}-after.png');
    });
  }
}
