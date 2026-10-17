// Screenshots of Şeker Küpler's chapters 7–12 in the real app, for review.
//   flutter test tool/stage4_screenshots_test.dart
// Writes SHOTS_OUT (default build/stage4-shots/): oyun-<level>.png for the
// first level of each new chapter, hikaye-<chapter>.png, harita.png,
// limon.png and kazandin.png.
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
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';
import 'package:lifeos_kupler/game/sugar/sugar_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/sugar_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/stage4-shots/';
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

/// Opens the map with levels 1..[done] passed; the stories of chapters
/// before [unseen] already read.
Future<Settings> _openMap(WidgetTester tester, int done, {int? unseen}) async {
  tester.view.physicalSize = const Size(1100, 2390);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = Platform.environment['SHOTS_EN'] == '1' ? AppLanguage.en : AppLanguage.tr;
  for (var n = 1; n <= done; n++) {
    settings.recordSugarLevel(n, stars: const [3, 2, 3, 1, 3, 2, 2, 3, 1, 2][(n - 1) % 10], score: 12000, seconds: 40);
  }
  for (var ch = 0; ch < SugarLevels.chapters; ch++) {
    if (ch != unseen) settings.markStorySeen(ch);
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

Future<void> _settle(WidgetTester tester, SugarController c) async {
  for (var k = 0; k < 300 && (c.busy || !c.game.isOver && c.game.status != SugarStatus.idle); k++) {
    await tester.pump(const Duration(milliseconds: 33));
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final level in [61, 71, 81, 91, 101, 111, 120]) {
    testWidgets('level $level after a few moves', (tester) async {
      await _openMap(tester, level - 1);
      final c = await _play(tester);
      for (var i = 0; i < (level == 120 ? 4 : 1) && !c.game.isOver; i++) {
        final m = SugarSolver.best(c.game);
        if (m == null) break;
        c.trySwap(m.$1, m.$2);
        await _settle(tester, c);
      }
      await _pump(tester, 30);
      await _shot(tester, level == 120 ? 'limon.png' : 'oyun-$level.png');
    });
  }

  for (var ch = 6; ch < 12; ch++) {
    testWidgets('story card of chapter ${ch + 1}', (tester) async {
      await _openMap(tester, ch * 10, unseen: ch);
      await tester.tap(find.byKey(const ValueKey('sugar-continue')));
      await _pump(tester, 40, 40);
      await _shot(tester, 'hikaye-${ch + 1}.png');
    });
  }

  testWidgets('the map of the new chapters', (tester) async {
    final settings = await _openMap(tester, 96);
    for (final card in [15, 17, 18]) {
      settings.applyGift(Gift(card: card));
    }
    await _pump(tester, 6);
    Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey('map-card-8'), skipOffstage: false)), alignment: 0.5);
    await _pump(tester, 10);
    await _shot(tester, 'harita.png');
  });

  testWidgets('beating Ekşi Limon', (tester) async {
    await _openMap(tester, 119);
    final c = await _play(tester);
    final goal = c.game.goals.single;
    goal.progress = goal.target - 2;
    for (var i = 0; i < 6 && !c.game.isOver; i++) {
      final m = SugarSolver.best(c.game);
      if (m == null) break;
      c.trySwap(m.$1, m.$2);
      await _settle(tester, c);
    }
    for (var k = 0; k < 600 && !c.showResult; k++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await _pump(tester, 40);
    await _shot(tester, 'kazandin.png');
  });
}
