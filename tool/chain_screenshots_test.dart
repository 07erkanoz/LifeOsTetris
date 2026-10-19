// Screenshots of the real Zincir Küpler screen, for review.
//   flutter test tool/chain_screenshots_test.dart
// Writes SHOTS_OUT (default build/chain-shots/): start.png, chain.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/chain-shots/';
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
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

Future<ChainController> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = AppLanguage.tr;
  await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await _pump(tester, 20);
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await _pump(tester, 10, 40);
  // The games page, then Zincir Küpler's modes.
  await tester.ensureVisible(find.byKey(const ValueKey('game-chain'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(const ValueKey('game-chain')));
  await _pump(tester, 10, 40);
  final card = find.byKey(const ValueKey('mode-chainEndless'));
  await tester.ensureVisible(find.byKey(const ValueKey('mode-chainEndless'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(card);
  await _pump(tester, 15, 40);
  return (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('start panel', (tester) async {
    await _open(tester);
    await _shot(tester, 'start.png');
  });

  testWidgets('a chain with garbage', (tester) async {
    final c = await _open(tester);
    await tester.tap(find.byKey(const ValueKey('chain-difficulty-normal')));
    await tester.pump(const Duration(milliseconds: 200));
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
    await _shot(tester, 'chain.png');
  });
}
