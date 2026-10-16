// Screenshots of the real Şeker Küpler screens, for review.
//   flutter test tool/sugar_screenshots_test.dart
// Writes SHOTS_OUT (default build/sugar-shots/): harita.png, baslangic.png,
// oyun.png, patlama.png, kazandin.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';
import 'package:lifeos_kupler/game/sugar/sugar_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/sugar_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/sugar-shots/';
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
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  await family('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
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

/// Opens the map with levels 1..[done] passed.
Future<Settings> _openMap(WidgetTester tester, int done) async {
  tester.view.physicalSize = const Size(1100, 2390);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = AppLanguage.tr;
  for (var n = 1; n <= done; n++) {
    settings.recordSugarLevel(n, stars: const [3, 2, 3, 1, 3, 2, 2, 3, 1, 2][(n - 1) % 10], score: 12000, seconds: 40);
  }
  await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await _pump(tester, 20);
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await _pump(tester, 10, 40);
  await tester.ensureVisible(find.byKey(const ValueKey('mode-sugar'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(const ValueKey('mode-sugar')));
  await _pump(tester, 15, 40);
  return settings;
}

SugarController _c(WidgetTester tester) => (tester.state(find.byType(SugarScreen)) as dynamic).c as SugarController;

Future<SugarController> _play(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('sugar-continue')));
  await _pump(tester, 15, 40);
  await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
  await tester.tap(find.byKey(const ValueKey('sugar-play')));
  await _pump(tester, 40);
  return _c(tester);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('map', (tester) async {
    await _openMap(tester, 10);
    await _shot(tester, 'harita.png');
  });

  testWidgets('start panel', (tester) async {
    await _openMap(tester, 10);
    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await _pump(tester, 15, 40);
    await _shot(tester, 'baslangic.png');
  });

  testWidgets('playing, with specials and obstacles', (tester) async {
    await _openMap(tester, 10);
    final c = await _play(tester);
    final g = c.game;
    // A few moves in, then specials and chains where they show well.
    for (var i = 0; i < 3; i++) {
      final m = SugarSolver.best(g)!;
      c.trySwap(m.$1, m.$2);
      for (var k = 0; k < 200 && (c.busy || g.status != SugarStatus.idle); k++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
    }
    g.board[2][1]!.special = Special.lineV;
    g.board[6][2]!.special = Special.lineH;
    g.board[2][6]!.special = Special.bomb;
    g.board[5][1]!.special = Special.prism;
    g.board[5][6]!.chained = true;
    g.board[0][3]!.chained = true;
    await _pump(tester, 8);
    await _shot(tester, 'oyun.png');

    // Fire the vertical line cube with the hammer, mid-blast.
    c.toggleHammer();
    c.tapCell(1, 2);
    c.fx.callout(c.strings.sugarCallout(4));
    await _pump(tester, 13);
    await _shot(tester, 'patlama.png');
  });

  testWidgets('level won, chest opened', (tester) async {
    await _openMap(tester, 4);
    final c = await _play(tester);
    for (var i = 0; i < 40 && !c.game.isOver; i++) {
      final m = SugarSolver.best(c.game);
      if (m != null) c.trySwap(m.$1, m.$2);
      for (var k = 0; k < 300 && (c.busy || !c.game.isOver && c.game.status != SugarStatus.idle); k++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
    }
    await _pump(tester, 60);
    await _shot(tester, 'kazandin.png');
  });
}
