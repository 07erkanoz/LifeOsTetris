// Shared bits for the mock-up tools: text, sweet labels, cards, buttons,
// speech bubbles, progress bars and saving a painted canvas to PNG.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

final String mockOut = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';

const mockInk = Color(0xFF5A1F7A);
const mockMuted = Color(0xFF9A5AB5);

void mockText(Canvas canvas, String text, Offset at, double size, Color color,
    {bool centre = true, double width = 400, FontWeight weight = FontWeight.w800, double height = 1.1, int? lines}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, textAlign: centre ? TextAlign.center : TextAlign.left, height: height, maxLines: lines, ellipsis: lines == null ? null : '…'))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, height: height))
    ..addText(text);
  final p = b.build()..layout(ui.ParagraphConstraints(width: width));
  canvas.drawParagraph(p, centre ? at - Offset(width / 2, p.height / 2) : at);
}

void mockLabel(Canvas canvas, String text, Offset c, double size,
    {List<Color> colors = const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], Color outline = const Color(0xFF6A0E4A)}) {
  paintSugarLabel(canvas, text, c, size,
      Paint()..shader = ui.Gradient.linear(c - Offset(0, size / 2), c + Offset(0, size / 2), colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]),
      outline: outline, stroke: 0.2);
}

void mockCard(Canvas canvas, RRect r, {List<Color> colors = const [Color(0xFFFFF7FD), Color(0xFFFFE3F4)], Color border = Colors.white, double width = 3}) {
  canvas.drawRRect(r.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF12061F).withValues(alpha: 0.45));
  canvas.drawRRect(r, Paint()..shader = ui.Gradient.linear(r.outerRect.topCenter, r.outerRect.bottomCenter, colors));
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = border);
}

void mockButton(Canvas canvas, Rect r, String label, {List<Color> colors = const [Color(0xFF6BF0A0), Color(0xFF1FB85A)], Color shade = const Color(0xFF0E6A32)}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.4));
  canvas.drawRRect(rr.shift(const Offset(0, 5)), Paint()..color = shade);
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 14, r.top + 5, r.width - 28, r.height * 0.26), Radius.circular(r.height)), Paint()..color = Colors.white.withValues(alpha: 0.3));
  mockLabel(canvas, label, r.center, r.height * 0.42, colors: const [Colors.white, Colors.white], outline: shade);
}

/// A white speech bubble; the tail points down-left, or down-right with [right].
void mockBubble(Canvas canvas, Rect r, String text, {double size = 15, bool right = false, bool up = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(16));
  canvas.drawRRect(rr.shift(const Offset(0, 3)), Paint()..color = Colors.black.withValues(alpha: 0.25));
  final x = right ? r.right - 26 : r.left + 26;
  final tail = up
      ? [Offset(x - 9, r.top + 2), Offset(x + (right ? 6 : -6), r.top - 14), Offset(x + 9, r.top + 2)]
      : [Offset(x - 9, r.bottom - 2), Offset(x + (right ? 6 : -6), r.bottom + 14), Offset(x + 9, r.bottom - 2)];
  canvas.drawPath(Path()..addPolygon(tail, true), Paint()..color = Colors.white);
  canvas.drawRRect(rr, Paint()..color = Colors.white);
  mockText(canvas, text, r.center, size, mockInk, width: r.width - 20);
}

void mockProgress(Canvas canvas, Rect r, double v, {List<Color> colors = const [Color(0xFFFF9AD8), Color(0xFFE0247A)], Color track = const Color(0xCC2A0B4F)}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
  canvas.drawRRect(rr, Paint()..color = track);
  if (v > 0) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, (r.width * v).clamp(r.height, r.width), r.height), Radius.circular(r.height / 2)),
        Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomLeft, colors));
  }
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.8));
}

/// A rounded phone frame around [r]: paint the screen inside with [screen].
void mockPhone(Canvas canvas, Rect r, void Function(Canvas canvas, Size size) screen) {
  final outer = RRect.fromRectAndRadius(r.inflate(8), const Radius.circular(44));
  canvas.drawRRect(outer.shift(const Offset(0, 10)), Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
  canvas.drawRRect(outer, Paint()..color = const Color(0xFF151019));
  final inner = RRect.fromRectAndRadius(r, const Radius.circular(36));
  canvas.save();
  canvas.clipRRect(inner);
  canvas.translate(r.left, r.top);
  screen(canvas, r.size);
  canvas.restore();
}

Future<void> mockSave(WidgetTester tester, Size size, void Function(Canvas, Size) paint, String name, {double scale = 2.5}) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    paint(canvas, size);
    final image = await recorder.endRecording().toImage((size.width * scale).round(), (size.height * scale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$mockOut$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

Future<void> mockFonts() async {
  final loader = FontLoader('Baloo2');
  for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Baloo2-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}
