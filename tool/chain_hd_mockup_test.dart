// Mock-up: Zincir Küpler cubes today next to two HD looks.
//   flutter test tool/chain_hd_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): zincir-hd.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';
const double _w = 1440, _h = 900, _scale = 1.5;

/// Deeper, richer colours for HD.
const _hd = [Color(0xFFFFD000), Color(0xFFF21FD8), Color(0xFF2F5BFF), Color(0xFF12D24E), Color(0xFFFF7A00)];
const _today = [Color(0xFFFFE21F), Color(0xFFFF33EE), Color(0xFF3F6BFF), Color(0xFF1FE85A), Color(0xFFFF8A10)];

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _d(Color c, double t) => Color.lerp(c, Colors.black, t)!;

/// A glossy cube whose face rises to a point: four lit triangles meeting in
/// the middle, a bevel, a gloss and a glint, with a halo in its colour.
void paintPyramidCube(Canvas canvas, Rect r, Color color, {bool halo = true}) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.1));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()
    ..color = Colors.black.withValues(alpha: 0.6)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05));
  if (halo) {
    canvas.drawRRect(rr.inflate(s * 0.02), Paint()
      ..color = color.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.16));
  }
  canvas.save();
  canvas.clipRRect(rr);
  final b = r.deflate(s * 0.07);
  final c = b.center + Offset(-s * 0.02, -s * 0.03);
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [_l(color, 0.6), color, _d(color, 0.32)], const [0, 0.5, 1]));
  void tri(Offset a, Offset b2, Color from, Color to) {
    canvas.drawPath(Path()..addPolygon([a, b2, c], true), Paint()..shader = ui.Gradient.linear((a + b2) / 2, c, [from, to]));
  }

  tri(b.topLeft, b.topRight, _l(color, 0.55), _l(color, 0.2));
  tri(b.topLeft, b.bottomLeft, _l(color, 0.25), _l(color, 0.05));
  tri(b.topRight, b.bottomRight, _d(color, 0.1), color);
  tri(b.bottomLeft, b.bottomRight, _d(color, 0.24), _d(color, 0.06));
  final ridge = Paint()
    ..strokeWidth = s * 0.025
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(b.topLeft, c, ridge..color = _l(color, 0.7).withValues(alpha: 0.8));
  canvas.drawLine(b.topRight, c, ridge..color = _l(color, 0.35).withValues(alpha: 0.6));
  canvas.drawLine(b.bottomLeft, c, ridge..color = _d(color, 0.2).withValues(alpha: 0.6));
  canvas.drawLine(b.bottomRight, c, ridge..color = _d(color, 0.3).withValues(alpha: 0.6));
  canvas.drawPath(
    Path()..addPolygon([b.topLeft, b.topRight, c], true),
    Paint()..shader = ui.Gradient.linear(b.topCenter, c, [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.0)]),
  );
  canvas.drawOval(Rect.fromCenter(center: b.topLeft + Offset(s * 0.2, s * 0.14), width: s * 0.26, height: s * 0.1), Paint()
    ..color = Colors.white.withValues(alpha: 0.85)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02));
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..color = _d(color, 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.025);
}

/// A: a cut gem. Four facets with strong light and shade, a table facet in
/// the middle, a hard specular glint and a rim light.
void gemCube(Canvas canvas, Rect r, Color color) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.12));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.06)), Paint()
    ..color = Colors.black.withValues(alpha: 0.7)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05));
  canvas.drawRRect(rr.inflate(s * 0.03), Paint()
    ..color = color.withValues(alpha: 0.5)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.14));
  canvas.save();
  canvas.clipRRect(rr);
  canvas.drawRect(r, Paint()..color = _d(color, 0.35));
  final b = r.deflate(s * 0.06);
  final t = Rect.fromCenter(center: b.center + Offset(-s * 0.03, -s * 0.04), width: s * 0.42, height: s * 0.42);
  void facet(List<Offset> pts, Color a, Color z) {
    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(path, Paint()..shader = ui.Gradient.linear(pts.first, pts[2], [a, z]));
  }

  facet([b.topLeft, b.topRight, t.topRight, t.topLeft], _l(color, 0.75), _l(color, 0.3));
  facet([b.topLeft, t.topLeft, t.bottomLeft, b.bottomLeft], _l(color, 0.35), color);
  facet([b.topRight, b.bottomRight, t.bottomRight, t.topRight], _d(color, 0.05), _d(color, 0.3));
  facet([b.bottomLeft, t.bottomLeft, t.bottomRight, b.bottomRight], _d(color, 0.2), _d(color, 0.5));
  // The table facet: bright, with a soft inner glow.
  canvas.drawRect(t, Paint()..shader = ui.Gradient.radial(t.center - Offset(s * 0.05, s * 0.06), s * 0.36, [_l(color, 0.65), color, _d(color, 0.1)], const [0, 0.55, 1]));
  // Edges between facets.
  final edge = Paint()
    ..strokeWidth = s * 0.022
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(b.topLeft, t.topLeft, edge..color = Colors.white.withValues(alpha: 0.9));
  canvas.drawLine(b.topRight, t.topRight, edge..color = Colors.white.withValues(alpha: 0.5));
  canvas.drawLine(b.bottomLeft, t.bottomLeft, edge..color = _l(color, 0.3).withValues(alpha: 0.6));
  canvas.drawLine(b.bottomRight, t.bottomRight, edge..color = _d(color, 0.6).withValues(alpha: 0.7));
  canvas.drawRect(t, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.02
    ..color = _l(color, 0.6).withValues(alpha: 0.8));
  // Specular glint and a little star.
  canvas.drawPath(
      Path()
        ..moveTo(t.left + s * 0.03, t.top + s * 0.03)
        ..lineTo(t.left + s * 0.2, t.top + s * 0.03)
        ..lineTo(t.left + s * 0.03, t.top + s * 0.2)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.9));
  canvas.restore();
  // Rim light.
  canvas.drawRRect(rr.deflate(s * 0.012), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.024
    ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [Colors.white.withValues(alpha: 0.95), _l(color, 0.2), _d(color, 0.55)], const [0, 0.45, 1]));
}

/// B: clear crystal lit from inside, with a bright rim.
void crystalCube(Canvas canvas, Rect r, Color color) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.18));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.06)), Paint()
    ..color = Colors.black.withValues(alpha: 0.65)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05));
  canvas.drawRRect(rr.inflate(s * 0.04), Paint()
    ..color = color.withValues(alpha: 0.6)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.18));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [_l(color, 0.35), color, _d(color, 0.45)], const [0, 0.5, 1]));
  canvas.save();
  canvas.clipRRect(rr);
  // Light inside, refracted to the lower right.
  canvas.drawCircle(r.center + Offset(s * 0.12, s * 0.14), s * 0.42, Paint()
    ..shader = ui.Gradient.radial(r.center + Offset(s * 0.12, s * 0.14), s * 0.42, [_l(color, 0.75), _l(color, 0.2).withValues(alpha: 0.4), color.withValues(alpha: 0)], const [0, 0.5, 1]));
  // Inner bevel.
  canvas.drawRRect(rr.deflate(s * 0.1), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.05
    ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0), _d(color, 0.4).withValues(alpha: 0.6)], const [0, 0.5, 1]));
  // Glass gloss: a sweep across the top.
  canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.top + s * 0.18)
        ..quadraticBezierTo(r.center.dx, r.top + s * 0.5, r.left, r.top + s * 0.32)
        ..close(),
      Paint()..shader = ui.Gradient.linear(r.topCenter, r.topCenter + Offset(0, s * 0.45), [Colors.white.withValues(alpha: 0.65), Colors.white.withValues(alpha: 0.05)]));
  canvas.drawCircle(r.topLeft + Offset(s * 0.26, s * 0.22), s * 0.06, Paint()..color = Colors.white);
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = _l(color, 0.55));
}

const _rows = ['....Y.', 'G...BM', 'GMY.GB', 'MBGYMY', 'YGBMBG'];
const _key = {'Y': 0, 'M': 1, 'B': 2, 'G': 3, 'O': 4};

void _board(Canvas canvas, Offset o, double cell, String title, String line, void Function(Canvas, Rect, Color) paint, List<Color> colors) {
  final well = Rect.fromLTWH(o.dx, o.dy, 6 * cell, 9 * cell);
  canvas.drawRRect(RRect.fromRectAndRadius(well.inflate(14), const Radius.circular(26)), Paint()..color = const Color(0xFF2A2342));
  canvas.drawRRect(RRect.fromRectAndRadius(well, const Radius.circular(16)), Paint()..shader = ui.Gradient.linear(well.topCenter, well.bottomCenter, const [Color(0xFF161124), Color(0xFF0C0914)]));
  for (var y = 0; y < _rows.length; y++) {
    for (var x = 0; x < 6; x++) {
      final ch = _rows[y][x];
      if (ch == '.') continue;
      paint(canvas, Rect.fromLTWH(o.dx + x * cell + 2, o.dy + (9 - _rows.length + y) * cell + 2, cell - 4, cell - 4), colors[_key[ch]!]);
    }
  }
  // A big one to see the detail.
  paint(canvas, Rect.fromLTWH(o.dx + cell * 1.5, o.dy + cell * 0.7, cell * 3, cell * 3), colors[1]);
  final p = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Baloo2', fontSize: 30, fontWeight: FontWeight.w800, textAlign: TextAlign.center))
    ..pushStyle(ui.TextStyle(color: Colors.white, fontFamily: 'Baloo2', fontSize: 30, fontWeight: FontWeight.w800))
    ..addText('$title\n')
    ..pushStyle(ui.TextStyle(color: const Color(0xFFB8B0E0), fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700))
    ..addText(line);
  canvas.drawParagraph(p.build()..layout(ui.ParagraphConstraints(width: well.width + 40)), Offset(well.left - 20, well.bottom + 26));
}

void screen(Canvas canvas) {
  canvas.drawRect(const Rect.fromLTWH(0, 0, _w, _h), Paint()..color = const Color(0xFF1C1730));
  final rnd = Random(2);
  for (var i = 0; i < 120; i++) {
    canvas.drawCircle(Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h), 2, Paint()..color = Colors.white.withValues(alpha: 0.04));
  }
  const cell = 64.0;
  _board(canvas, const Offset(60, 50), cell, 'Bugün', 'soluk, mat', (c, r, col) => paintPyramidCube(c, r, col), _today);
  _board(canvas, const Offset(60 + 6 * cell + 70, 50), cell, 'A · Mücevher', 'kesme taş, keskin parlama', gemCube, _hd);
  _board(canvas, const Offset(60 + 12 * cell + 140, 50), cell, 'B · Kristal', 'içten ışıklı cam', crystalCube, _hd);
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Baloo2');
    for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Baloo2-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
  });
  testWidgets('zincir hd', (tester) async {
    final bytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(_scale);
      screen(canvas);
      final image = await recorder.endRecording().toImage((_w * _scale).round(), (_h * _scale).round());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File('${_out}zincir-hd.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  });
}
