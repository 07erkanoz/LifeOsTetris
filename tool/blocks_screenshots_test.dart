// Screenshots of the real Bulmaca Küpler screens, for review.
//   flutter test tool/blocks_screenshots_test.dart
// Writes SHOTS_OUT (default build/blocks-shots/): <entry>.png, and play
// moments: kombo.png, surukle.png, mucevher.png, kurtar.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/game/blocks/blocks_controller.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/blocks_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/blocks-shots/';
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
    final image = await boundary.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

Future<BlocksController> _open(WidgetTester tester, BlocksEntry entry) async {
  tester.view.physicalSize = const Size(975, 2110);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = AppLanguage.tr;
  await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await _pump(tester, 10);
  BlocksScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings, audio: AudioService(enabled: false), entry: entry);
  await _pump(tester, 30);
  return (tester.state(find.byType(BlocksScreen)) as dynamic).c as BlocksController;
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('a combo blast', (tester) async {
    final c = await _open(tester, BlocksEntry.endless);
    c.game.debugSetBoard(['.TTTTTTT', '.LLLLLLL', 'SS..ZZ..', 'J..IIII.', 'JJ.O..OO', '.....TT.', 'ZZ..SS..', '.JJ...L.']);
    c.game.debugSetTray(['dot', 'i2v', 'o2']);
    c.game.streak = 3;
    c.place(1, 0, 0);
    await _pump(tester, 9);
    await _shot(tester, 'kombo.png');
  });

  testWidgets('dragging a piece', (tester) async {
    final c = await _open(tester, BlocksEntry.endless);
    c.game.debugSetBoard(['PP..YYY.'.replaceAll('P', 'T').replaceAll('Y', 'O'), 'T...O.SS', 'ZZ.JJJ.S', 'ZZZJJ..S', 'SSSLL..I', 'J..L...I', 'JJOOO..I', 'J.OO..II']);
    c.game.debugSetTray(['l2', 't4', 'o2']);
    await _pump(tester, 4);
    final rect = c.boardRect!.call();
    final cell = rect.width / 8;
    final shape = c.game.tray[1]!;
    // Aim the piece's top-left at (5, 3) (the finger sits below it).
    final pointer = rect.topLeft + Offset(5 * cell + shape.width * cell / 2, 3 * cell + shape.height * cell + cell * 1.1);
    c.beginDrag(1, pointer, mouse: false);
    c.updateDrag(pointer);
    await _pump(tester, 8);
    await _shot(tester, 'surukle.png');
    c.abortDrag();
  });

  testWidgets('a jewel level', (tester) async {
    final c = await _open(tester, BlocksEntry.menu);
    c.startLevel(40);
    await _pump(tester, 30);
    await _shot(tester, 'mucevher.png');
  });

  testWidgets('the rescue', (tester) async {
    final c = await _open(tester, BlocksEntry.endless);
    c.game.debugSetBoard(['T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T']);
    c.game.debugSetTray(['dot', 'o2', 'o2']);
    c.place(0, 1, 0);
    await _pump(tester, 50);
    await _shot(tester, 'kurtar.png');
  });

  for (final entry in [BlocksEntry.menu, BlocksEntry.levels, BlocksEntry.endless, BlocksEntry.bombs]) {
    testWidgets(entry.name, (tester) async {
      tester.view.physicalSize = const Size(975, 2110);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      final settings = Settings.memory()..language = AppLanguage.tr;
      await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
      await _pump(tester, 10);
      BlocksScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings, audio: AudioService(enabled: false), entry: entry);
      await _pump(tester, 40);
      final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('$_out${entry.name}.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes!);
    });
  }
}
