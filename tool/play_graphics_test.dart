// Google Play's graphics: the 1024×500 feature graphic in each language and
// the 512×512 icon (the app icon, scaled).
//   flutter test tool/play_graphics_test.dart
// Writes android/metadata/<locale>/feature-graphic.png and
// android/metadata/icon-512.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/game/sugar/tradition_art.dart' show paintCoffeeCup, paintSaucer;
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/ui/game_screen.dart' show paintHomeGameArt;

import 'mock_kit.dart';

const _out = 'android/metadata/';

void _feature(Canvas canvas, Size size, AppStrings s, String tagline) {
  final r = Offset.zero & size;
  paintDusk(canvas, r);
  final horizon = size.height * 0.78;
  paintSkyline(canvas, size.width, horizon, size.height * 0.72, const Color(0xFF4A2A6A));
  paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height - horizon), ferryAt: 0.62, tower: 0);
  paintGulls(canvas, [Offset(size.width * 0.36, size.height * 0.1), Offset(size.width * 0.39, size.height * 0.14)], const Color(0xFF3A1E5A));

  // The stone quay on the left, where Lokum stands on his saucer.
  final quay = Rect.fromLTRB(-20, size.height * 0.84, 420, size.height + 20);
  canvas.drawRRect(RRect.fromRectAndRadius(quay.shift(const Offset(0, 6)), const Radius.circular(18)), Paint()..color = const Color(0x66200A3A));
  canvas.drawRRect(RRect.fromRectAndRadius(quay, const Radius.circular(18)),
      Paint()..shader = ui.Gradient.linear(quay.topCenter, quay.bottomCenter, const [Color(0xFFE8D9C8), Color(0xFFB8A08C)]));
  for (var x = 20.0; x < 420; x += 64) {
    canvas.drawLine(Offset(x, quay.top + 10), Offset(x, quay.bottom), Paint()
      ..color = const Color(0x339A7A64)
      ..strokeWidth = 2);
  }
  const lokumAt = Offset(200, 365);
  paintCoffeeCup(canvas, const Offset(318, 438), 40);
  paintSaucer(canvas, lokumAt + const Offset(0, 80), 170);
  paintLokum(canvas, lokumAt, 150, pose: LokumPose.cheer);

  // The name and what it is.
  mockLabel(canvas, AppStrings.appTitle, const Offset(205, 92), 100,
      colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], outline: const Color(0xFF4A0E3A));
  mockText(canvas, tagline, const Offset(207, 175), 30, const Color(0xAA2A0B3F), width: 400);
  mockText(canvas, tagline, const Offset(205, 172), 30, Colors.white, width: 400);

  // Every game, as the home shows it.
  const games = ['tower', 'sugar', 'chain', 'puzzle', 'superGame', 'classic'];
  const w = 186.0, art = 158.0, h = art + 40;
  for (var i = 0; i < games.length; i++) {
    final card = Rect.fromLTWH(420 + (i % 3) * (w + 10), 36 + (i ~/ 3) * (h + 22), w, h);
    final rr = RRect.fromRectAndRadius(card, const Radius.circular(18));
    canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()..color = const Color(0x88200A3A));
    canvas.drawRRect(rr, Paint()..color = Colors.white);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndCorners(Rect.fromLTWH(card.left + 4, card.top + 4, w - 8, art), topLeft: const Radius.circular(15), topRight: const Radius.circular(15)));
    canvas.translate(card.left + 4, card.top + 4);
    final title = paintHomeGameArt(canvas, Size(w - 8, art), games[i], s, t: const [0.45, 0.45, 0.55, 0.62, 0.65, 0.2][i]).title;
    canvas.restore();
    mockText(canvas, title, Offset(card.center.dx, card.bottom - 20), 19, const Color(0xFF4A1A6A), width: w - 12);
  }
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

  for (final (locale, strings) in [('tr', AppStrings.tr), ('en-US', AppStrings.en)]) {
    testWidgets('feature graphic $locale', (tester) async {
      await _save(tester, '$_out$locale/feature-graphic.png', const Size(1024, 500), (c, size) => _feature(c, size, strings, strings.appTagline));
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
