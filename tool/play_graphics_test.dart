// Google Play's graphics: the 1024×500 feature graphic in each language and
// the 512×512 icon (the app icon, scaled).
//   flutter test tool/play_graphics_test.dart
// Writes android/metadata/<locale>/feature-graphic.png and
// android/metadata/icon-512.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/tower/tower_landmarks.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show chainColors, paintChainCube;
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/game/tower/landmark_art.dart';
import 'package:lifeos_kupler/game/tower/tower_art.dart';

import 'mock_kit.dart';

const _out = 'android/metadata/';

void _feature(Canvas canvas, Size size, String tagline) {
  final r = Offset.zero & size;
  paintDusk(canvas, r);
  final horizon = size.height * 0.8;
  paintSkyline(canvas, size.width, horizon, size.height * 0.75, const Color(0xFF4A2A6A));
  paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height - horizon), ferryAt: 0.08, tower: 0);
  paintGulls(canvas, [Offset(size.width * 0.52, size.height * 0.16), Offset(size.width * 0.55, size.height * 0.2)], const Color(0xFF3A1E5A));

  // Kız Kulesi on the right, on the water.
  paintLandmark(canvas, Landmark.maidens, Offset(size.width * 0.9, horizon + 8), 0.78);

  // A lokum tower, the next floor sliding in.
  const h = 24.0, a = 46.0;
  final base = Offset(size.width * 0.66, horizon + 4);
  for (var i = 0; i < 9; i++) {
    final c = base + towerU * (sin(i * 1.3) * 3) - Offset(0, (i + 1) * h);
    if (i > 0) paintFloorShadow(canvas, c, a, a, h);
    paintTowerFloor(canvas, c, a, a, h, flavor: i, seed: i);
  }
  final top = base - const Offset(0, 9 * h);
  for (var i = 3; i >= 1; i--) {
    paintTowerFloor(canvas, top - Offset(0, h * 1.6) - towerV * (a * 1.3 + i * 9), a, a, h, flavor: 9, seed: 30 + i, alpha: 0.12 * (4 - i));
  }
  paintTowerFloor(canvas, top - Offset(0, h * 1.6) - towerV * (a * 1.3), a, a, h, flavor: 9, seed: 30);
  paintSparkle(canvas, top + const Offset(-64, -30), 12, const Color(0xFFFFE066));

  // Sweets and cubes around the title.
  final rnd = Random(3);
  for (final (x, y, s) in [(0.06, 0.14, 46.0), (0.43, 0.12, 40.0), (0.52, 0.47, 42.0), (0.03, 0.7, 38.0)]) {
    paintCandy(canvas, Rect.fromCenter(center: Offset(size.width * x, size.height * y), width: s, height: s), SugarColor.values[rnd.nextInt(6)]);
  }
  for (final (x, y, c) in [(0.38, 0.8, ChainColor.magenta), (0.42, 0.8, ChainColor.yellow), (0.4, 0.73, ChainColor.blue)]) {
    paintChainCube(canvas, Rect.fromCenter(center: Offset(size.width * x, size.height * y), width: 36, height: 36), chainColors[c]!);
  }

  // Lokum and the name.
  paintLokum(canvas, Offset(size.width * 0.12, size.height * 0.46), 120, pose: LokumPose.cheer);
  mockLabel(canvas, 'Lokum', Offset(size.width * 0.33, size.height * 0.38), 92,
      colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], outline: const Color(0xFF4A0E3A));
  mockText(canvas, tagline, Offset(size.width * 0.33 + 2, size.height * 0.6 + 3), 32, const Color(0xAA2A0B3F), width: 440);
  mockText(canvas, tagline, Offset(size.width * 0.33, size.height * 0.6), 32, Colors.white, width: 440);
}

Future<void> _save(WidgetTester tester, String path, Size size, void Function(Canvas, Size) paint) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), size);
    final image = await recorder.endRecording().toImage(size.width.round(), size.height.round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(mockFonts);

  for (final (locale, tagline) in [('tr', 'Şeker ve Blok Oyunları'), ('en-US', 'Sweets & Block Games')]) {
    testWidgets('feature graphic $locale', (tester) async {
      await _save(tester, '$_out$locale/feature-graphic.png', const Size(1024, 500), (c, s) => _feature(c, s, tagline));
    });
  }

  testWidgets('icon', (tester) async {
    final bytes = File('assets/icon/icon.png').readAsBytesSync();
    final out = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 512, targetHeight: 512);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File('${_out}icon-512.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(out!);
  });
}
