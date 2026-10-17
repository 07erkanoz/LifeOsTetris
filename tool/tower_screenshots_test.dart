// Screenshots of the real Kule Küpler: the climb at a few heights (day,
// clouds, dusk, night), a floor look, the end of a run, İstanbul'u İnşa Et,
// and its place on the games page.
//   flutter test tool/tower_screenshots_test.dart
// Writes SHOTS_OUT (default build/tower-shots/): NN-<name>.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/rewards.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/game/tower/tower_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/ui/tower_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/tower-shots/';
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

Future<void> _pump(WidgetTester tester, [int frames = 14]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

Settings _settings() => Settings.memory()
  ..language = AppLanguage.tr
  ..visualTheme = VisualTheme.toyHd;

Future<void> _app(WidgetTester tester, Settings settings) async {
  tester.view.physicalSize = const Size(390, 844) * 2.5;
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await _pump(tester);
}

Future<TowerController> _climb(WidgetTester tester, Settings settings, {TowerMode mode = TowerMode.climb}) async {
  await _app(tester, settings);
  TowerScreen.open(tester.element(find.byKey(const ValueKey('play'))), settings: settings, audio: AudioService(enabled: false), mode: mode);
  await _pump(tester);
  return (tester.state(find.byType(TowerScreen)) as dynamic).c as TowerController;
}

/// A tower [height] floors tall, built straight in (no chests on the way),
/// a few cuts and perfect runs, the camera in place.
void _build(TowerController c, int height, {int streak = 0}) {
  final g = c.game;
  final rnd = Random(height);
  var cu = 0.0, cv = 0.0, a = 1.0, b = 1.0;
  for (var i = 1; i <= height; i++) {
    final cut = rnd.nextDouble() < 0.18 ? (rnd.nextDouble() - 0.5) * 0.16 : 0.0;
    if (i.isEven) {
      a = max(0.55, a - cut.abs() / 2);
      cu += cut / 2;
    } else {
      b = max(0.55, b - cut.abs() / 2);
      cv += cut / 2;
    }
    if (i % 9 == 0) {
      a = min(1, a + 0.1);
      b = min(1, b + 0.1);
    }
    g.floors.add(TowerFloor(cu: cu, cv: cv, a: a, b: b, flavor: (i * 5 + rnd.nextInt(2)) % 6));
  }
  g.streak = streak;
  g.axis = height.isEven ? TowerAxis.v : TowerAxis.u;
  g.position = -0.9;
  c.dropped = true;
  c.camera = max(0, g.height - 5.5);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('climb', (tester) async {
    final settings = _settings();
    settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
    final c = await _climb(tester, settings);
    for (var i = 0; i < 3; i++) {
      c.game.position = i == 1 ? 0.18 : 0;
      c.tap();
    }
    c.dropped = false;
    await _pump(tester, 30);
    await _shot(tester, '01-baslangic');

    for (final (name, height, streak) in [('02-bulutlar', 128, 7), ('03-gunbatimi', 205, 3), ('04-gece', 352, 5), ('05-uzay', 540, 2)]) {
      _build(c, height - c.game.height, streak: streak);
      c.game.position = -0.6;
      await _pump(tester, 20);
      await _shot(tester, name);
    }
  });

  testWidgets('floor looks', (tester) async {
    final settings = _settings();
    for (final u in [Unlock.floorCini, Unlock.floorMarble, Unlock.floorGlass, Unlock.floorGold]) {
      settings.applyGift(Gift(unlock: u));
    }
    for (final (i, look) in ['cini', 'marble', 'glass', 'gold'].indexed) {
      settings.towerLook = look;
      final c = await _climb(tester, settings);
      _build(c, 60 + i * 40, streak: 4);
      await _pump(tester, 20);
      await _shot(tester, '0${6 + i}-kat-$look');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('end of a run', (tester) async {
    final settings = _settings();
    settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
    final c = await _climb(tester, settings);
    _build(c, 186);
    c.game.position = 3;
    c.tap();
    await _pump(tester, 50);
    await _shot(tester, '10-bitti');
  });

  testWidgets('build Istanbul', (tester) async {
    final settings = _settings();
    settings.recordTowerRun(mode: TowerMode.climb, floors: 1140, seconds: 3000);
    settings.claimLandmarks();
    await _app(tester, settings);
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    await _pump(tester);
    await _shot(tester, '11-oyunlar');
    await tester.tap(find.byKey(const ValueKey('game-tower')));
    await _pump(tester);
    await _shot(tester, '12-kule-modlari');
    await tester.tap(find.byKey(const ValueKey('mode-towerBuild')));
    await _pump(tester, 30);
    await _shot(tester, '13-insa-et');
  });

  testWidgets('effects', (tester) async {
    final settings = _settings();
    final c = await _climb(tester, settings);
    _build(c, 120);
    c.game.floors.add(TowerFloor(cu: c.game.top.cu, cv: c.game.top.cv, a: 0.8, b: 0.8, flavor: 2));
    c.camera = c.game.height - 5.5;
    for (var i = 0; i < 4; i++) {
      c.game.position = 0;
      c.tap();
      await _pump(tester, i < 3 ? 12 : 3);
    }
    await _shot(tester, '14-efekt-mukemmel');
    await _pump(tester, 20);
    c.game.position = 0.55;
    c.tap();
    await _pump(tester, 4);
    await _shot(tester, '15-efekt-kesik');
    _build(c, 199 - c.game.height);
    await _pump(tester, 10);
    c.game.position = 0;
    c.tap();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
    await _shot(tester, '16-efekt-sandik');
    await _pump(tester, 20);
  });

  testWidgets('english', (tester) async {
    final settings = _settings()..language = AppLanguage.en;
    settings.recordTowerRun(mode: TowerMode.climb, floors: 1140, seconds: 3000);
    settings.claimLandmarks();
    final c = await _climb(tester, settings);
    _build(c, 128, streak: 6);
    await _pump(tester, 20);
    await _shot(tester, '17-en-oyun');
    c.game.position = 3;
    c.tap();
    await _pump(tester, 50);
    await _shot(tester, '18-en-bitti');
    await tester.pumpWidget(const SizedBox());
    await _app(tester, settings);
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('game-tower')));
    await _pump(tester);
    await _shot(tester, '19-en-modlar');
    await tester.tap(find.byKey(const ValueKey('mode-towerBuild')));
    await _pump(tester, 30);
    await _shot(tester, '20-en-insa');
  });
}
