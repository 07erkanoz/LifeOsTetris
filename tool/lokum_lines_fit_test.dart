// Lokum's longest new lines in his real bubble, on the Şeker Küpler board
// and on the home screen, in Turkish and English, on a small phone, a phone
// and a tablet: do they fit?
//   flutter test tool/lokum_lines_fit_test.dart
// Writes MOCKUP_OUT (default build/mockups/): lokum-balon.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/sugar_screen.dart';

import 'mock_kit.dart';
import 'store_kit.dart';

const _lines = {
  AppLanguage.tr: ['Uyumadım, gözümü dinlendirdim!', 'Bugün şansımız yaver gidiyor!', 'Bakalım arkasından ne çıkacak!', 'Mola! Bir çay koyayım mı?'],
  AppLanguage.en: ['I was only resting my eyes!', 'Chocolate\'s spreading, hurry!', 'He\'s sweetening, nearly there!', 'Break time! Kettle on?'],
};

const _devices = [('Küçük telefon', Size(360, 640)), ('Telefon', Size(390, 844)), ('Tablet', Size(820, 1180))];

/// Crops of the screen around Lokum, by device and language.
final List<(String, AppLanguage, String, ui.Image)> _shots = [];

Future<ui.Image> _grab(WidgetTester tester, Rect area) async => (await tester.runAsync(() async {
  final boundary = storeRoot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final whole = await boundary.toImage(pixelRatio: 2);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final src = Rect.fromLTRB(area.left * 2, area.top * 2, area.right * 2, area.bottom * 2);
  canvas.drawImageRect(whole, src, Offset.zero & src.size, Paint());
  final crop = await recorder.endRecording().toImage(src.width.round(), src.height.round());
  whole.dispose();
  return crop;
}))!;

void main() {
  setUpAll(() async {
    await loadStoreFonts();
    await mockFonts();
  });

  for (final (name, size) in _devices) {
    for (final language in [AppLanguage.tr, AppLanguage.en]) {
      testWidgets('$name ${language.name}', (tester) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final settings = Settings.memory()..language = language;
        await tester.pumpWidget(RepaintBoundary(key: storeRoot, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
        await pumpFrames(tester, 10);
        final c = (await sugarUpTo(tester, settings, 30))!;
        for (final line in _lines[language]!) {
          c.mascot
            ..line = line
            ..lineUntil = c.now + 100
            ..priority = 9;
          await pumpFrames(tester, 3);
          final lokum = tester.getRect(find.byKey(const ValueKey('sugar-mascot')));
          final screen = Offset.zero & size;
          final area = Rect.fromLTRB(0, lokum.top - 30, size.width, lokum.bottom + 60).intersect(screen);
          _shots.add((name, language, line, await _grab(tester, area)));
        }
        expect(find.byType(SugarScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  tearDownAll(() async {
    // One sheet: a column per device, Turkish then English down it.
    const pad = 30.0, gapY = 14.0;
    final columns = [for (final (name, _) in _devices) [for (final s in _shots) if (s.$1 == name) s]];
    final colWidth = [for (final col in columns) col.map((s) => s.$4.width / 2).fold(0.0, (a, b) => a > b ? a : b)];
    final height = pad * 2 + 70 + columns.map((col) => col.fold(0.0, (a, s) => a + s.$4.height / 2 + gapY + 22)).fold(0.0, (a, b) => a > b ? a : b);
    final width = pad * (columns.length + 1) + colWidth.fold(0.0, (a, b) => a + b);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(2);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = const Color(0xFF1B1530));
    var x = pad;
    for (final (i, col) in columns.indexed) {
      mockText(canvas, _devices[i].$1, Offset(x + colWidth[i] / 2, pad + 14), 22, Colors.white, width: colWidth[i]);
      var y = pad + 50;
      for (final (_, language, line, image) in col) {
        mockText(canvas, '${language == AppLanguage.tr ? 'TR' : 'EN'} · "$line"', Offset(x, y), 13, const Color(0xFFD9C8F5), centre: false, width: colWidth[i]);
        y += 20;
        canvas.save();
        canvas.translate(x, y);
        canvas.scale(0.5);
        canvas.drawImage(image, Offset.zero, Paint());
        canvas.restore();
        y += image.height / 2 + gapY;
      }
      x += colWidth[i] + pad;
    }
    final sheet = await recorder.endRecording().toImage((width * 2).round(), (height * 2).round());
    final data = await sheet.toByteData(format: ui.ImageByteFormat.png);
    File('${mockOut}lokum-balon.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}
