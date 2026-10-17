// Screenshots of the real Şeker Küpler screens, for review.
//   flutter test tool/sugar_screenshots_test.dart
// Writes SHOTS_OUT (default build/sugar-shots/): harita.png, baslangic.png, manzara-*.png,
// oyun.png, sov.png, final.png, kazandin.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/rewards.dart';
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

  Future<void> settle(WidgetTester tester, SugarController c) async {
    for (var k = 0; k < 300 && (c.busy || !c.game.isOver && c.game.status != SugarStatus.idle); k++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
  }

  testWidgets('map', (tester) async {
    final settings = await _openMap(tester, 33);
    // The first three chapters' postcards, earned.
    for (final card in [11, 10, 4]) {
      settings.applyGift(Gift(card: card));
    }
    await _pump(tester, 6);
    // Down to the third chapter's end and its postcard.
    Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey('map-card-2'), skipOffstage: false)), alignment: 0.5);
    await _pump(tester, 10);
    await _shot(tester, 'harita.png');
  });

  testWidgets('start panel', (tester) async {
    await _openMap(tester, 40);
    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    await _pump(tester, 15, 40);
    await _shot(tester, 'baslangic.png');
  });

  testWidgets('playing: boxes, a timed bomb, specials, Lokum', (tester) async {
    await _openMap(tester, 43);
    final c = await _play(tester);
    final g = c.game;
    for (var i = 0; i < 2; i++) {
      final m = SugarSolver.best(g)!;
      c.trySwap(m.$1, m.$2);
      await settle(tester, c);
    }
    SugarPiece? at(int x, int y) => g.board[y][x];
    at(0, 1)?.special = Special.lineV;
    at(5, 6)?.special = Special.lineH;
    at(7, 3)?.special = Special.bomb;
    at(1, 6)?.special = Special.prism;
    g.rushMeter = 0.7;
    await _pump(tester, 50);
    await _shot(tester, 'oyun.png');
  });

  for (final scene in [Unlock.sceneGalata, Unlock.sceneSnow, Unlock.sceneIslands]) {
    testWidgets('playing over the ${scene.name} scene', (tester) async {
      final settings = await _openMap(tester, 43);
      settings.applyGift(Gift(unlock: scene));
      settings.sugarScene = scene.name;
      await _play(tester);
      await _pump(tester, 30);
      await _shot(tester, 'manzara-${scene.name}.png');
    });
  }

  testWidgets('sugar rush show', (tester) async {
    await _openMap(tester, 43);
    final c = await _play(tester);
    final g = c.game;
    g.rushMeter = 0.99;
    final m = SugarSolver.best(g)!;
    c.trySwap(m.$1, m.$2);
    var shot = false;
    for (var k = 0; k < 300 && !shot; k++) {
      await tester.pump(const Duration(milliseconds: 33));
      if (c.fx.floaters.any((f) => f.text == c.strings.sugarRush && f.age > 0.3)) {
        await _shot(tester, 'sov.png');
        shot = true;
      }
    }
    expect(shot, isTrue);
  });

  testWidgets('finale and the win panel', (tester) async {
    await _openMap(tester, 4);
    final c = await _play(tester);
    var finale = false;
    for (var i = 0; i < 40 && !c.game.isOver; i++) {
      final m = SugarSolver.best(c.game);
      if (m != null) c.trySwap(m.$1, m.$2);
      for (var k = 0; k < 400 && (c.busy || !c.game.isOver && c.game.status != SugarStatus.idle); k++) {
        await tester.pump(const Duration(milliseconds: 33));
        if (!finale && c.fx.floaters.any((f) => f.text.startsWith('+') && f.size > 0.6)) {
          await _shot(tester, 'final.png');
          finale = true;
        }
      }
    }
    await _pump(tester, 60);
    await _shot(tester, 'kazandin.png');
  });
}
