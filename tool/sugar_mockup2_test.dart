// Mock-ups for Şeker Küpler round two: candy shapes per colour, the mascot
// "Lokum", timed bombs and candy boxes, the sugar-rush meter and the show.
//   flutter test tool/sugar_mockup2_test.dart
// Writes MOCKUP_OUT (default build/mockups/): seker2-oyun.png,
// seker2-sov.png, seker2-yenilikler.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';

const double _w = 430, _h = 932, _scale = 2.5;

const _red = Color(0xFFFF2D55);
const _orange = Color(0xFFFF7A1A);
const _yellow = Color(0xFFFFE14A);
const _green = Color(0xFF2BD96B);
const _blue = Color(0xFF2EA8FF);
const _purple = Color(0xFFA44BFF);
const _candy = {'R': _red, 'O': _orange, 'Y': _yellow, 'G': _green, 'B': _blue, 'P': _purple};

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _d(Color c, double t) => Color.lerp(c, Colors.black, t)!;

void _text(Canvas canvas, String text, Offset c, double size, {Color color = Colors.white, Color outline = const Color(0xFF6A0E4A), double stroke = 0.18, List<Color>? colors}) {
  final paint = Paint()..color = color;
  if (colors != null) {
    paint.shader = ui.Gradient.linear(c - Offset(0, size / 2), c + Offset(0, size / 2), colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);
  }
  paintSugarLabel(canvas, text, c, size, paint, outline: outline, stroke: stroke);
}

Paint _grad(Rect r, List<Color> colors, {bool vertical = true}) => Paint()
  ..shader = ui.Gradient.linear(vertical ? r.topCenter : r.centerLeft, vertical ? r.bottomCenter : r.centerRight, colors,
      [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);

// ------------------------------------------------------------ the shapes --

/// A closed shape through [pts] with every corner rounded.
Path _rounded(List<Offset> pts) {
  Offset mid(Offset a, Offset b) => (a + b) / 2;
  final p = Path();
  final n = pts.length;
  final start = mid(pts[n - 1], pts[0]);
  p.moveTo(start.dx, start.dy);
  for (var i = 0; i < n; i++) {
    final m = mid(pts[i], pts[(i + 1) % n]);
    p.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
  }
  return p..close();
}

Path _heart(Rect r) {
  final w = r.width, h = r.height, x = r.left, y = r.top;
  return Path()
    ..moveTo(x + w / 2, y + h * 0.95)
    ..cubicTo(x + w * 0.02, y + h * 0.62, x - w * 0.04, y + h * 0.2, x + w * 0.26, y + h * 0.09)
    ..cubicTo(x + w * 0.42, y + h * 0.04, x + w * 0.5, y + h * 0.16, x + w * 0.5, y + h * 0.24)
    ..cubicTo(x + w * 0.5, y + h * 0.16, x + w * 0.58, y + h * 0.04, x + w * 0.74, y + h * 0.09)
    ..cubicTo(x + w * 1.04, y + h * 0.2, x + w * 0.98, y + h * 0.62, x + w / 2, y + h * 0.95)
    ..close();
}

Path _drop(Rect r) {
  final w = r.width, h = r.height, t = r.top, b = r.bottom, l = r.left + w * 0.08, rr = r.right - w * 0.08, cx = r.center.dx;
  return Path()
    ..moveTo(cx, t)
    ..cubicTo(cx + w * 0.16, t + h * 0.2, rr, t + h * 0.38, rr, t + h * 0.62)
    ..cubicTo(rr, t + h * 0.88, cx + w * 0.22, b, cx, b)
    ..cubicTo(cx - w * 0.22, b, l, t + h * 0.88, l, t + h * 0.62)
    ..cubicTo(l, t + h * 0.38, cx - w * 0.16, t + h * 0.2, cx, t)
    ..close();
}

List<Offset> _poly(Offset c, double r, int n, double turn, {double inner = 1}) => [
  for (var i = 0; i < n * (inner < 1 ? 2 : 1); i++)
    c + Offset(cos(turn + i * pi / (inner < 1 ? n : n / 2)), sin(turn + i * pi / (inner < 1 ? n : n / 2))) * (inner < 1 && i.isOdd ? r * inner : r),
];

/// The shape of each candy colour.
Path candyShape(String k, Rect cell) {
  final r = cell.deflate(cell.width * 0.07);
  final c = r.center, s = r.width;
  return switch (k) {
    'R' => _heart(r),
    'O' => Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.47)),
    'Y' => _rounded(_poly(c + Offset(0, s * 0.04), s * 0.56, 5, -pi / 2, inner: 0.56)),
    'G' => Path()..addRRect(RRect.fromRectAndRadius(r.deflate(s * 0.04), Radius.circular(s * 0.26))),
    'B' => _drop(r),
    _ => _rounded(_poly(c, s * 0.52, 6, pi / 6)),
  };
}

/// A glossy candy of colour [k] in [cell].
void candy(Canvas canvas, Rect cell, String k, {bool shadow = true}) {
  final col = _candy[k]!;
  final shape = candyShape(k, cell);
  final s = cell.width;
  final b = shape.getBounds();
  if (shadow) {
    canvas.drawPath(shape.shift(Offset(0, s * 0.06)), Paint()
      ..color = const Color(0xFF1A0730).withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  }
  canvas.drawPath(shape, Paint()
    ..shader = ui.Gradient.radial(b.center - Offset(s * 0.12, s * 0.18), s * 0.72, [_l(col, 0.45), col, _d(col, 0.32)], const [0, 0.5, 1]));
  canvas.save();
  canvas.clipPath(shape);
  canvas.drawOval(Rect.fromCenter(center: b.bottomCenter, width: b.width * 1.1, height: b.height * 0.55), Paint()
    ..color = _d(col, 0.45).withValues(alpha: 0.45)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08));
  switch (k) {
    case 'O':
      // Caramel swirl.
      final sp = Path();
      for (var t = 0.0; t < pi * 4.2; t += 0.12) {
        final rr = s * (0.05 + t * 0.026);
        final p = b.center + Offset(cos(t), sin(t)) * rr;
        t == 0 ? sp.moveTo(p.dx, p.dy) : sp.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(sp, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFF1DD).withValues(alpha: 0.85));
    case 'G':
      // Sugar dust.
      final rnd = Random(7);
      for (var i = 0; i < 16; i++) {
        canvas.drawCircle(b.topLeft + Offset(rnd.nextDouble() * b.width, rnd.nextDouble() * b.height), s * 0.018, Paint()..color = Colors.white.withValues(alpha: 0.7));
      }
    case 'P':
      // Crystal facets.
      final pts = _poly(b.center, s * 0.52, 6, pi / 6);
      for (final p in pts) {
        canvas.drawLine(b.center, p, Paint()
          ..strokeWidth = s * 0.02
          ..color = Colors.white.withValues(alpha: 0.3));
      }
      canvas.drawPath(_rounded(_poly(b.center, s * 0.26, 6, pi / 6)), Paint()..color = _l(col, 0.35).withValues(alpha: 0.6));
    case 'B':
      canvas.drawCircle(b.center + Offset(s * 0.06, s * 0.14), s * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.22));
    default:
      break;
  }
  final g = Rect.fromLTWH(b.left + b.width * 0.16, b.top + b.height * (k == 'B' ? 0.32 : 0.1), b.width * 0.46, b.height * 0.24);
  canvas.drawOval(g, Paint()..shader = ui.Gradient.linear(g.topCenter, g.bottomCenter, [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0)]));
  canvas.restore();
  canvas.drawPath(shape, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = _l(col, 0.55).withValues(alpha: 0.7));
  canvas.drawCircle(g.center + Offset(g.width * 0.25, -g.height * 0.05), s * 0.035, Paint()..color = Colors.white);
}

/// Striped candy: bands across the shape and arrow tips.
void striped(Canvas canvas, Rect cell, String k, {required bool horizontal}) {
  final s = cell.width;
  canvas.drawCircle(cell.center, s * 0.55, Paint()
    ..color = _l(_candy[k]!, 0.3).withValues(alpha: 0.55)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.16));
  candy(canvas, cell, k);
  final shape = candyShape(k, cell);
  canvas.save();
  canvas.clipPath(shape);
  for (var i = 0; i < 3; i++) {
    final t = 0.3 + i * 0.2;
    final band = horizontal ? Rect.fromLTWH(cell.left, cell.top + s * t - s * 0.04, s, s * 0.08) : Rect.fromLTWH(cell.left + s * t - s * 0.04, cell.top, s * 0.08, s);
    canvas.drawRect(band, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }
  canvas.restore();
  final c = cell.center;
  for (final dir in [-1.0, 1.0]) {
    final tip = horizontal ? c + Offset(dir * s * 0.58, 0) : c + Offset(0, dir * s * 0.58);
    final back = horizontal ? Offset(-dir * s * 0.14, 0) : Offset(0, -dir * s * 0.14);
    final side = horizontal ? Offset(0, s * 0.1) : Offset(s * 0.1, 0);
    canvas.drawPath(Path()..addPolygon([tip, tip + back + side, tip + back - side], true), Paint()..color = Colors.white);
  }
}

/// Wrapped (bomb) candy: a glowing wrapper with twisted ends.
void wrapped(Canvas canvas, Rect cell, String k) {
  final s = cell.width, c = cell.center, col = _candy[k]!;
  canvas.drawCircle(c, s * 0.62, Paint()..shader = ui.Gradient.radial(c, s * 0.62, [_l(col, 0.5).withValues(alpha: 0.8), col.withValues(alpha: 0)]));
  for (final dir in [-1.0, 1.0]) {
    final tw = Path()
      ..moveTo(c.dx + dir * s * 0.26, c.dy)
      ..lineTo(c.dx + dir * s * 0.54, c.dy - s * 0.2)
      ..quadraticBezierTo(c.dx + dir * s * 0.46, c.dy, c.dx + dir * s * 0.54, c.dy + s * 0.2)
      ..close();
    canvas.drawPath(tw, Paint()..shader = ui.Gradient.linear(c - Offset(0, s * 0.2), c + Offset(0, s * 0.2), [_l(col, 0.5), _d(col, 0.2)]));
    canvas.drawPath(tw, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..color = Colors.white.withValues(alpha: 0.8));
  }
  candy(canvas, Rect.fromCenter(center: c, width: s * 0.78, height: s * 0.78), k);
  canvas.drawPath(starPath(c, s * 0.15, inner: 0.42), Paint()..color = Colors.white);
}

/// Rainbow ball: a sphere of swirling colours.
void rainbow(Canvas canvas, Rect cell) {
  final s = cell.width, c = cell.center;
  canvas.drawCircle(c, s * 0.66, Paint()..shader = ui.Gradient.radial(c, s * 0.66, [Colors.white.withValues(alpha: 0.7), const Color(0xFFB45BFF).withValues(alpha: 0)]));
  canvas.drawCircle(c + Offset(0, s * 0.05), s * 0.44, Paint()
    ..color = Colors.black.withValues(alpha: 0.4)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05));
  canvas.drawCircle(c, s * 0.44, Paint()
    ..shader = ui.Gradient.sweep(c, const [_red, _orange, _yellow, _green, _blue, _purple, _red], const [0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1]));
  canvas.drawCircle(c, s * 0.44, Paint()..shader = ui.Gradient.radial(c - Offset(s * 0.12, s * 0.14), s * 0.5, [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)]));
  // Sprinkles.
  final rnd = Random(3);
  for (var i = 0; i < 9; i++) {
    final a = rnd.nextDouble() * 2 * pi, d = rnd.nextDouble() * s * 0.32;
    final p = c + Offset(cos(a), sin(a)) * d;
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(rnd.nextDouble() * pi);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 0.12, height: s * 0.04), Radius.circular(s * 0.02)), Paint()..color = Colors.white);
    canvas.restore();
  }
  paintSparkle(canvas, c + Offset(-s * 0.16, -s * 0.16), s * 0.1, Colors.white);
}

/// Timed bomb: a chocolate bonbon with a lit fuse and the moves it has left.
void timedBomb(Canvas canvas, Rect cell, int left, {double pulse = 0.6}) {
  final s = cell.width, c = cell.center + Offset(0, s * 0.04);
  canvas.drawCircle(c, s * (0.5 + 0.06 * pulse), Paint()
    ..color = const Color(0xFFFF3B3B).withValues(alpha: 0.35 + 0.3 * pulse)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.12));
  canvas.drawCircle(c + Offset(0, s * 0.05), s * 0.4, Paint()
    ..color = Colors.black.withValues(alpha: 0.5)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  canvas.drawCircle(c, s * 0.4, Paint()..shader = ui.Gradient.radial(c - Offset(s * 0.12, s * 0.14), s * 0.55, const [Color(0xFF9A5A3A), Color(0xFF5A2E1A), Color(0xFF2E140A)], const [0, 0.5, 1]));
  canvas.drawCircle(c, s * 0.4, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.05
    ..color = const Color(0xFFFF4D4D));
  final fuse = Path()
    ..moveTo(c.dx + s * 0.22, c.dy - s * 0.32)
    ..quadraticBezierTo(c.dx + s * 0.34, c.dy - s * 0.52, c.dx + s * 0.46, c.dy - s * 0.48);
  canvas.drawPath(fuse, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.06
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFE8D2A8));
  paintSparkle(canvas, Offset(c.dx + s * 0.47, c.dy - s * 0.5), s * 0.14, const Color(0xFFFFC21A));
  _text(canvas, '$left', c + Offset(0, s * 0.02), s * 0.5, outline: const Color(0xFF2E140A), stroke: 0.2);
}

/// Candy box: a gift box with a ribbon; one layer left shows it cracked open.
void candyBox(Canvas canvas, Rect cell, {int layers = 2}) {
  final s = cell.width;
  final r = cell.deflate(s * 0.05);
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.14));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.06)), Paint()
    ..color = const Color(0xFF1A0730).withValues(alpha: 0.55)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  final body = layers >= 2 ? const [Color(0xFFFFB8DC), Color(0xFFE85AA6)] : const [Color(0xFFFFD9EC), Color(0xFFF08AC0)];
  canvas.drawRRect(rr, _grad(r, body));
  // Lid.
  final lid = RRect.fromRectAndRadius(Rect.fromLTWH(r.left - s * 0.02, r.top, r.width + s * 0.04, s * 0.26), Radius.circular(s * 0.1));
  canvas.drawRRect(lid, _grad(lid.outerRect, layers >= 2 ? const [Color(0xFFFFD0E8), Color(0xFFFF7AC0)] : const [Color(0xFFFFE6F2), Color(0xFFFFA6D2)]));
  // Ribbon.
  final gold = _grad(r, const [Color(0xFFFFF0A0), Color(0xFFFFB000)]);
  canvas.drawRect(Rect.fromCenter(center: r.center, width: s * 0.14, height: r.height), gold);
  if (layers >= 2) {
    canvas.drawRect(Rect.fromCenter(center: r.center + Offset(0, s * 0.12), width: r.width, height: s * 0.12), gold);
    for (final dir in [-1.0, 1.0]) {
      canvas.drawOval(Rect.fromCenter(center: r.topCenter + Offset(dir * s * 0.13, -s * 0.02), width: s * 0.24, height: s * 0.16), gold);
    }
    canvas.drawCircle(r.topCenter + Offset(0, s * 0.01), s * 0.06, Paint()..color = const Color(0xFFFFE27A));
  } else {
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF9A2A66);
    canvas.drawPath(
        Path()
          ..moveTo(r.left + s * 0.15, r.top + s * 0.36)
          ..lineTo(r.left + s * 0.32, r.top + s * 0.5)
          ..lineTo(r.left + s * 0.26, r.top + s * 0.66)
          ..lineTo(r.left + s * 0.4, r.top + s * 0.82),
        crack);
    canvas.drawPath(
        Path()
          ..moveTo(r.right - s * 0.12, r.top + s * 0.4)
          ..lineTo(r.right - s * 0.28, r.top + s * 0.56)
          ..lineTo(r.right - s * 0.2, r.top + s * 0.72),
        crack);
  }
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = Colors.white.withValues(alpha: 0.8));
}

// ------------------------------------------------------------- the mascot --

enum Pose { happy, wow, cheer, wink }

/// Lokum, the mascot: a pink jelly sweet with a cherry on top.
void lokum(Canvas canvas, Offset c, double size, {Pose pose = Pose.happy, bool flip = false}) {
  final s = size;
  canvas.save();
  canvas.translate(c.dx, c.dy);
  if (flip) canvas.scale(-1, 1);
  const pink = Color(0xFFFF6FB5);
  // Shadow.
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.55), width: s * 0.9, height: s * 0.16), Paint()
    ..color = Colors.black.withValues(alpha: 0.3)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  // Arms.
  final arm = Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.2), Offset(0, s * 0.4), [_l(pink, 0.3), _d(pink, 0.15)]);
  for (final dir in [-1.0, 1.0]) {
    canvas.save();
    final up = pose == Pose.cheer || (pose == Pose.wink && dir > 0);
    canvas.translate(dir * s * 0.5, up ? -s * 0.08 : s * 0.16);
    canvas.rotate(dir * (up ? -0.7 : 0.6));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, up ? -s * 0.1 : s * 0.08), width: s * 0.17, height: s * 0.34), Radius.circular(s * 0.09)), arm);
    canvas.restore();
  }
  // Feet.
  for (final dir in [-1.0, 1.0]) {
    canvas.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.2, s * 0.5), width: s * 0.28, height: s * 0.14), Paint()..color = _d(pink, 0.2));
  }
  // Body: a soft jelly drop shape.
  final body = Path()
    ..moveTo(0, -s * 0.46)
    ..cubicTo(s * 0.36, -s * 0.46, s * 0.5, -s * 0.2, s * 0.5, s * 0.12)
    ..cubicTo(s * 0.5, s * 0.42, s * 0.3, s * 0.52, 0, s * 0.52)
    ..cubicTo(-s * 0.3, s * 0.52, -s * 0.5, s * 0.42, -s * 0.5, s * 0.12)
    ..cubicTo(-s * 0.5, -s * 0.2, -s * 0.36, -s * 0.46, 0, -s * 0.46)
    ..close();
  canvas.drawPath(body, Paint()..shader = ui.Gradient.radial(Offset(-s * 0.14, -s * 0.2), s * 0.8, [_l(pink, 0.5), pink, _d(pink, 0.3)], const [0, 0.5, 1]));
  canvas.save();
  canvas.clipPath(body);
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.55), width: s * 1.2, height: s * 0.5), Paint()
    ..color = _d(pink, 0.4).withValues(alpha: 0.4)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08));
  canvas.drawOval(Rect.fromLTWH(-s * 0.32, -s * 0.4, s * 0.38, s * 0.18), Paint()
    ..shader = ui.Gradient.linear(Offset(0, -s * 0.4), Offset(0, -s * 0.22), [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)]));
  // Sugar sparkles on the jelly.
  final rnd = Random(5);
  for (var i = 0; i < 10; i++) {
    canvas.drawCircle(Offset((rnd.nextDouble() - 0.5) * s * 0.8, (rnd.nextDouble() - 0.3) * s * 0.7), s * 0.012, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }
  canvas.restore();
  canvas.drawPath(body, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.025
    ..color = _l(pink, 0.6));
  // Cherry on top.
  canvas.drawPath(
      Path()
        ..moveTo(0, -s * 0.5)
        ..quadraticBezierTo(s * 0.04, -s * 0.66, s * 0.16, -s * 0.72),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2F8F3A));
  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.2, -s * 0.74), width: s * 0.16, height: s * 0.08), Paint()..color = const Color(0xFF3FBF4A));
  canvas.drawCircle(Offset(0, -s * 0.52), s * 0.11, Paint()..shader = ui.Gradient.radial(Offset(-s * 0.03, -s * 0.56), s * 0.14, const [Color(0xFFFF7A8A), Color(0xFFD0102A)]));
  canvas.drawCircle(Offset(-s * 0.035, -s * 0.56), s * 0.025, Paint()..color = Colors.white);
  // Face.
  final eyeY = -s * 0.06;
  for (final dir in [-1.0, 1.0]) {
    final e = Offset(dir * s * 0.17, eyeY);
    if (pose == Pose.wink && dir > 0) {
      canvas.drawArc(Rect.fromCenter(center: e, width: s * 0.16, height: s * 0.12), pi * 1.1, pi * 0.8, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3A0F2A));
      continue;
    }
    final big = pose == Pose.wow ? 1.15 : 1.0;
    canvas.drawOval(Rect.fromCenter(center: e, width: s * 0.17 * big, height: s * 0.21 * big), Paint()..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: e + Offset(s * 0.01, s * 0.015), width: s * 0.11 * big, height: s * 0.14 * big), Paint()..color = const Color(0xFF2A0B30));
    canvas.drawCircle(e + Offset(-s * 0.015, -s * 0.03), s * 0.03, Paint()..color = Colors.white);
    canvas.drawCircle(e + Offset(s * 0.03, s * 0.04), s * 0.012, Paint()..color = Colors.white);
  }
  for (final dir in [-1.0, 1.0]) {
    canvas.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.3, s * 0.1), width: s * 0.14, height: s * 0.08), Paint()..color = const Color(0xFFFF3B7A).withValues(alpha: 0.55));
  }
  final mouth = Offset(0, s * 0.15);
  if (pose == Pose.wow) {
    canvas.drawOval(Rect.fromCenter(center: mouth, width: s * 0.12, height: s * 0.15), Paint()..color = const Color(0xFF6A0E2A));
  } else {
    final open = pose == Pose.cheer;
    final m = Path()
      ..moveTo(mouth.dx - s * 0.12, mouth.dy - s * 0.02)
      ..quadraticBezierTo(mouth.dx, mouth.dy + s * (open ? 0.2 : 0.1), mouth.dx + s * 0.12, mouth.dy - s * 0.02)
      ..close();
    canvas.drawPath(m, Paint()..color = const Color(0xFF6A0E2A));
    if (open) {
      canvas.save();
      canvas.clipPath(m);
      canvas.drawCircle(mouth + Offset(0, s * 0.12), s * 0.07, Paint()..color = const Color(0xFFFF6A8A));
      canvas.restore();
    }
  }
  canvas.restore();
}

void _bubble(Canvas canvas, Rect r, String text, {bool tailRight = true, double size = 17}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(18));
  final tail = Path()
    ..addPolygon(
        tailRight
            ? [Offset(r.right - 34, r.bottom - 2), Offset(r.right - 8, r.bottom + 16), Offset(r.right - 16, r.bottom - 2)]
            : [Offset(r.left + 16, r.bottom - 2), Offset(r.left + 8, r.bottom + 16), Offset(r.left + 34, r.bottom - 2)],
        true);
  canvas.drawRRect(rr.shift(const Offset(0, 4)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.4));
  canvas.drawPath(tail, Paint()..color = Colors.white);
  canvas.drawRRect(rr, Paint()..color = Colors.white);
  _text(canvas, text, r.center, size, color: const Color(0xFF7A2A9E), stroke: 0);
}

// -------------------------------------------------------- screen pieces --

void _backdrop(Canvas canvas, List<Color> sky, int seed) {
  final screen = Offset.zero & const Size(_w, _h);
  canvas.drawRect(screen, _grad(screen, sky));
  final rnd = Random(seed);
  for (var i = 0; i < 16; i++) {
    final c = [const Color(0xFFFFB3E6), const Color(0xFF9FD8FF), const Color(0xFFFFE08A)][i % 3];
    canvas.drawCircle(Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h), 20 + rnd.nextDouble() * 50, Paint()
      ..color = c.withValues(alpha: 0.12 + rnd.nextDouble() * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
  }
}

void _topBar(Canvas canvas, {required int moves, required String level, required List<(void Function(Rect), String, double)> goals}) {
  final top = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 38, _w - 28, 104), const Radius.circular(26));
  canvas.drawRRect(top.shift(const Offset(0, 6)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
  canvas.drawRRect(top, _grad(top.outerRect, const [Color(0xFFFFF7FD), Color(0xFFFFE3F4)]));
  canvas.drawRRect(top, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white);
  const mc = Offset(70, 90);
  canvas.drawCircle(mc + const Offset(0, 4), 40, Paint()..color = const Color(0xFF7A1C5B));
  canvas.drawCircle(mc, 40, Paint()..shader = ui.Gradient.radial(mc - const Offset(10, 14), 52, const [Color(0xFFFF7AC6), Color(0xFFE0247A)]));
  canvas.drawCircle(mc, 40, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..color = Colors.white);
  _text(canvas, '$moves', mc - const Offset(0, 6), 36, outline: const Color(0xFF8A1550), stroke: 0.12);
  _text(canvas, 'HAMLE', mc + const Offset(0, 22), 13, outline: const Color(0xFF8A1550), stroke: 0.2);
  final lp = Paint()..color = const Color(0xFF7A2A9E);
  paintSugarLabel(canvas, level, const Offset(205, 58), 18, lp, stroke: 0);
  var x = 124.0;
  for (final (icon, text, share) in goals) {
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(x, 76, 136, 52), const Radius.circular(16));
    canvas.drawRRect(box, Paint()..color = const Color(0xFFF3D9F0));
    icon(Rect.fromLTWH(x + 6, 82, 40, 40));
    _text(canvas, text, Offset(x + 90, 92), 18, color: const Color(0xFF5A1F7A), stroke: 0);
    final bar = Rect.fromLTWH(x + 54, 110, 72, 9);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(5)), Paint()..color = const Color(0xFFE2BCE0));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * share, bar.height), const Radius.circular(5)),
        _grad(bar, const [Color(0xFF6BE3FF), Color(0xFF2E86FF)], vertical: false));
    x += 146;
  }
}

void _scoreBar(Canvas canvas, double share, List<bool> on, {double y = 158}) {
  final bar = RRect.fromRectAndRadius(Rect.fromLTWH(30, y, _w - 60, 20), const Radius.circular(10));
  canvas.drawRRect(bar.shift(const Offset(0, 3)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.6));
  canvas.drawRRect(bar, Paint()..color = const Color(0xFF3B1466));
  final fill = RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * share, bar.height), const Radius.circular(10));
  canvas.drawRRect(fill, _grad(fill.outerRect, const [Color(0xFFFFE066), Color(0xFFFF8A00)], vertical: false));
  for (var k = 0; k < 3; k++) {
    paintGoldStar(canvas, Offset(bar.left + bar.width * const [0.3, 0.6, 0.92][k], bar.center.dy), 15, on: on[k]);
  }
}

/// The sugar-rush meter: fills with every match; full sets off a rush.
void _rushMeter(Canvas canvas, Rect r, double share, {bool full = false}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
  if (full) {
    canvas.drawRRect(rr.inflate(4), Paint()
      ..color = const Color(0xFFFF7AC6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  }
  canvas.drawRRect(rr, Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.75));
  final fill = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 3, r.top + 3, (r.width - 6) * share, r.height - 6), Radius.circular(r.height / 2));
  canvas.drawRRect(fill, Paint()..shader = ui.Gradient.linear(fill.outerRect.centerLeft, fill.outerRect.centerRight, const [_red, _orange, _yellow, _green, _blue, _purple], const [0, 0.2, 0.4, 0.6, 0.8, 1]));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(fill.left + 6, fill.top + 3, max(0, fill.width - 12), 4), const Radius.circular(2)), Paint()..color = Colors.white.withValues(alpha: 0.45));
  _text(canvas, full ? 'ŞEKER ÇILGINLIĞI DOLDU!' : 'ŞEKER ÇILGINLIĞI', r.center, 13, outline: const Color(0xFF3A0F60), stroke: 0.25);
}

const _board = [
  'RBYGPOBY',
  'GOkKRGYP',
  'P|YKBG*O',
  'ORPYRBGB',
  'YB@GTYRG',
  'RPGyOBPY',
  'GYB-gYRB',
  'BOYRBPGO',
];
const _special = {(1, 2): 'B', (6, 2): 'P', (3, 6): 'O'};

void _tray(Canvas canvas, Offset o, double cell) {
  final tray = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 8 * cell, 8 * cell).inflate(10), const Radius.circular(26));
  canvas.drawRRect(tray.shift(const Offset(0, 8)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
  canvas.drawRRect(tray, Paint()..color = const Color(0xFF3A1270).withValues(alpha: 0.9));
  canvas.drawRRect(tray, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFFF9AD8).withValues(alpha: 0.7));
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + x * cell, o.dy + y * cell, cell, cell).deflate(1.5), const Radius.circular(10)),
          Paint()..color = ((x + y).isEven ? const Color(0xFF4A1A85) : const Color(0xFF41167A)).withValues(alpha: 0.9));
    }
  }
}

void _piece(Canvas canvas, String ch, int x, int y, Rect r) {
  final sp = _special[(x, y)];
  switch (ch) {
    case '|':
      striped(canvas, r, sp!, horizontal: false);
    case '-':
      striped(canvas, r, sp!, horizontal: true);
    case '*':
      wrapped(canvas, r, sp!);
    case '@':
      rainbow(canvas, r);
    case 'T':
      timedBomb(canvas, r, 4);
    case 'K':
      candyBox(canvas, r);
    case 'k':
      candyBox(canvas, r, layers: 1);
    default:
      if (ch.toLowerCase() == ch) {
        candy(canvas, r, ch.toUpperCase());
        paintIce(canvas, r, seed: x + y);
      } else {
        candy(canvas, r, ch);
      }
  }
}

void _boosters(Canvas canvas, double by) {
  void booster(Offset c, void Function(Offset c) icon, String count, String name) {
    canvas.drawCircle(c + const Offset(0, 5), 32, Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
    canvas.drawCircle(c, 32, Paint()..shader = ui.Gradient.radial(c - const Offset(8, 10), 42, const [Color(0xFFFFFFFF), Color(0xFFFFD6F0)]));
    canvas.drawCircle(c, 32, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF7AC6));
    icon(c);
    final badge = c + const Offset(23, -23);
    canvas.drawCircle(badge, 12, Paint()..color = const Color(0xFF2BD96B));
    canvas.drawCircle(badge, 12, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white);
    _text(canvas, count, badge, 14, stroke: 0);
    _text(canvas, name, c + const Offset(0, 48), 14, outline: const Color(0xFF3A0F60), stroke: 0.22);
  }

  booster(Offset(_w / 2 - 120, by), (c) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.6);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 6), width: 7, height: 32), const Radius.circular(3)), Paint()..color = const Color(0xFFB0703A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -11), width: 30, height: 15), const Radius.circular(5)),
        Paint()..shader = ui.Gradient.linear(const Offset(0, -19), const Offset(0, -4), const [Color(0xFFDDE3EE), Color(0xFF7D879A)]));
    canvas.restore();
  }, '3', 'Çekiç');
  booster(Offset(_w / 2, by), (c) => rainbow(canvas, Rect.fromCenter(center: c, width: 40, height: 40)), '1', 'Gökkuşağı');
  booster(Offset(_w / 2 + 120, by), (c) {
    _text(canvas, '+3', c, 26, colors: const [Color(0xFFFF7AC6), Color(0xFFE0247A)], outline: Colors.white);
  }, '2', '+3 Hamle');
}

// ------------------------------------------------------------- screens --

void _gameScreen(Canvas canvas) {
  _backdrop(canvas, const [Color(0xFF4A1F8A), Color(0xFF9A2F7E), Color(0xFF2A1060)], 4);
  _topBar(canvas, moves: 12, level: 'SEVİYE 34', goals: [
    ((r) => candyBox(canvas, r), '3/8', 0.38),
    ((r) => candy(canvas, r, 'O'), '18/30', 0.6),
  ]);
  _scoreBar(canvas, 0.5, [true, false, false]);
  _text(canvas, '15.840', const Offset(110, 205), 24);
  _rushMeter(canvas, const Rect.fromLTWH(170, 192, 180, 26), 0.72);

  const cell = 48.0;
  const o = Offset((_w - 8 * cell) / 2, 250);
  _tray(canvas, o, cell);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      _piece(canvas, _board[y][x], x, y, Rect.fromLTWH(o.dx + x * cell, o.dy + y * cell, cell, cell));
    }
  }
  // Lokum peeks over the tray, winking.
  lokum(canvas, const Offset(392, 222), 58, pose: Pose.wink);
  // Callouts that explain the new pieces.
  void note(Offset from, Offset at, String text) {
    canvas.drawLine(from, at, Paint()
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(from, 4, Paint()..color = Colors.white);
    final p = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Baloo2', fontSize: 14, fontWeight: FontWeight.w800))
      ..pushStyle(ui.TextStyle(color: const Color(0xFF5A1F7A), fontFamily: 'Baloo2', fontSize: 14, fontWeight: FontWeight.w800))
      ..addText(text);
    final para = p.build()..layout(const ui.ParagraphConstraints(width: 150));
    final box = Rect.fromLTWH(at.dx - para.longestLine / 2 - 10, at.dy - 6, para.longestLine + 20, para.height + 12);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(12)), Paint()..color = Colors.white);
    canvas.drawParagraph(para, Offset(box.left + 10, box.top + 6));
  }

  note(o + const Offset(4.5 * cell, 4.5 * cell), Offset(o.dx + 4.5 * cell + 40, o.dy + 8 * cell + 32), '4 hamlede patlat!');
  note(o + const Offset(3.5 * cell, 1.5 * cell), const Offset(120, 676), 'Yanında eşleştir, kutu açılsın');
  _boosters(canvas, _h - 130);
}

void _showScreen(Canvas canvas) {
  _backdrop(canvas, const [Color(0xFF6A1FA8), Color(0xFFD0307E), Color(0xFF3A1470)], 9);
  _topBar(canvas, moves: 9, level: 'SEVİYE 34', goals: [
    ((r) => candyBox(canvas, r), '7/8', 0.88),
    ((r) => candy(canvas, r, 'O'), '30/30', 1),
  ]);
  _scoreBar(canvas, 0.68, [true, true, false]);
  _text(canvas, '28.460', const Offset(110, 205), 24);
  _rushMeter(canvas, const Rect.fromLTWH(160, 192, 196, 26), 1, full: true);

  const cell = 48.0;
  const o = Offset((_w - 8 * cell) / 2, 250);
  _tray(canvas, o, cell);
  // The board flashes; three specials fall in with trails.
  final rnd = Random(2);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final ch = _board[y][x];
      final r = Rect.fromLTWH(o.dx + x * cell, o.dy + y * cell, cell, cell);
      if ((x == 2 && y < 6) || (y == 4)) continue; // being cleared
      final k = 'RBYGPO'.contains(ch) ? ch : 'RBYGPO'[rnd.nextInt(6)];
      candy(canvas, r, k);
    }
  }
  // Beams of the rush: a row and a column.
  for (final beam in [Rect.fromLTWH(o.dx - 12, o.dy + 4.2 * cell, 8 * cell + 24, cell * 0.6), Rect.fromLTWH(o.dx + 2.2 * cell, o.dy - 12, cell * 0.6, 8 * cell + 24)]) {
    canvas.drawRRect(RRect.fromRectAndRadius(beam.inflate(cell * 0.35), Radius.circular(cell)), Paint()
      ..color = const Color(0xFFFFB3E6).withValues(alpha: 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.4));
    canvas.drawRRect(RRect.fromRectAndRadius(beam, Radius.circular(cell)), Paint()..color = Colors.white.withValues(alpha: 0.95));
  }
  // Falling specials with trails.
  for (final (x, y, k) in [(5, 1.2, 'wrapped'), (6, 2.6, 'striped'), (1, 1.8, 'rainbow')]) {
    final c = o + Offset((x + 0.5) * cell, (y + 0.5) * cell);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c - Offset(0, cell * 1.1), width: cell * 0.5, height: cell * 2), Radius.circular(cell)), Paint()
      ..shader = ui.Gradient.linear(c - Offset(0, cell * 2.1), c, [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.75)]));
    final r = Rect.fromCenter(center: c, width: cell, height: cell);
    switch (k) {
      case 'wrapped':
        wrapped(canvas, r, 'G');
      case 'striped':
        striped(canvas, r, 'R', horizontal: true);
      default:
        rainbow(canvas, r);
    }
  }
  // Confetti and sparkles over everything.
  for (var i = 0; i < 70; i++) {
    final p = Offset(rnd.nextDouble() * _w, 120 + rnd.nextDouble() * 620);
    if (i % 3 == 0) {
      paintSparkle(canvas, p, 4 + rnd.nextDouble() * 6, [Colors.white, const Color(0xFFFFE066), const Color(0xFF9FD8FF)][i % 3]);
    } else {
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(rnd.nextDouble() * pi);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 10, height: 5), const Radius.circular(2)),
          Paint()..color = _candy.values.elementAt(i % 6));
      canvas.restore();
    }
  }
  // The big callout, multiplier and score roll.
  canvas.save();
  canvas.translate(_w / 2, o.dy + 2.6 * cell);
  canvas.rotate(-0.07);
  _text(canvas, 'ŞEKER', const Offset(0, -34), 62, colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], stroke: 0.2);
  _text(canvas, 'ÇILGINLIĞI!', const Offset(0, 30), 54, colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], stroke: 0.2);
  canvas.restore();
  final mult = o + Offset(6.9 * cell, 5.3 * cell);
  canvas.drawCircle(mult, 34, Paint()..shader = ui.Gradient.radial(mult - const Offset(8, 10), 42, const [Color(0xFF8AF0FF), Color(0xFF2E86FF)]));
  canvas.drawCircle(mult, 34, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..color = Colors.white);
  _text(canvas, '×4', mult, 30, outline: const Color(0xFF0E4A9A));
  _text(canvas, '+12.400', o + Offset(3.2 * cell, 6.2 * cell), 40, colors: const [Colors.white, Color(0xFFFFE066)], stroke: 0.2);
  // A star flies off the bar.
  canvas.drawPath(
      Path()
        ..moveTo(262, 168)
        ..quadraticBezierTo(330, 160, 384, 206),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFE066).withValues(alpha: 0.6));
  paintGoldStar(canvas, const Offset(390, 212), 22);
  _text(canvas, '2. YILDIZ!', const Offset(372, 244), 17, outline: const Color(0xFF8A4A00));
  // Lokum cheers.
  lokum(canvas, Offset(84, o.dy + 8 * cell + 70), 96, pose: Pose.cheer);
  _bubble(canvas, Rect.fromLTWH(150, o.dy + 8 * cell + 22, 220, 50), 'Bu muhteşem!!', tailRight: false, size: 22);
  _boosters(canvas, _h - 110);
}

void _overview(Canvas canvas) {
  _backdrop(canvas, const [Color(0xFF3B2A8F), Color(0xFF8A3AA8), Color(0xFF2A1060)], 21);
  _text(canvas, 'ŞEKER KÜPLER · YENİLİKLER', const Offset(_w / 2, 46), 26, colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A)], stroke: 0.2);

  RRect card(double y, double h, String title) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(16, y, _w - 32, h), const Radius.circular(24));
    canvas.drawRRect(r.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.6));
    canvas.drawRRect(r, _grad(r.outerRect, const [Color(0xFFFFF7FD), Color(0xFFFFE3F4)]));
    paintSugarLabel(canvas, title, Offset(_w / 2, y + 20), 17, Paint()..color = const Color(0xFF9A3AB5), stroke: 0);
    return r;
  }

  void caption(String text, Offset c, {double size = 13}) => paintSugarLabel(canvas, text, c, size, Paint()..color = const Color(0xFF5A1F7A), stroke: 0);

  // Mascot.
  card(76, 196, 'MASKOT: LOKUM');
  for (final (i, pose, name) in [(0, Pose.happy, 'Mutlu'), (1, Pose.wow, 'Şaşkın'), (2, Pose.cheer, 'Coşkulu'), (3, Pose.wink, 'Göz kırpan')]) {
    final x = 66.0 + i * 100;
    lokum(canvas, Offset(x, 170), 74, pose: pose);
    caption(name, Offset(x, 250));
  }

  // Candies.
  card(286, 124, 'HER RENK AYRI ŞEKİL');
  for (final (i, k, name) in [(0, 'R', 'Kalp'), (1, 'O', 'Karamel'), (2, 'Y', 'Yıldız'), (3, 'G', 'Sakız'), (4, 'B', 'Damla'), (5, 'P', 'Kristal')]) {
    final x = 48.0 + i * 67;
    candy(canvas, Rect.fromCenter(center: Offset(x, 344), width: 52, height: 52), k);
    caption(name, Offset(x, 390));
  }

  // Specials.
  card(424, 118, 'ÖZEL ŞEKERLER');
  striped(canvas, Rect.fromCenter(center: const Offset(84, 476), width: 50, height: 50), 'R', horizontal: true);
  caption('4\'lü: Çizgili', const Offset(84, 522));
  wrapped(canvas, Rect.fromCenter(center: const Offset(_w / 2, 476), width: 50, height: 50), 'Y');
  caption('L/T: Paketli bomba', const Offset(_w / 2, 522));
  rainbow(canvas, Rect.fromCenter(center: const Offset(_w - 84, 476), width: 50, height: 50));
  caption('5\'li: Gökkuşağı', const Offset(_w - 84, 522));

  // Obstacles.
  card(556, 132, 'YENİ ENGELLER');
  timedBomb(canvas, Rect.fromCenter(center: const Offset(66, 610), width: 50, height: 50), 4);
  caption('Süreli bomba', const Offset(66, 654));
  caption('sıfıra inmeden patlat', const Offset(72, 670), size: 11);
  candyBox(canvas, Rect.fromCenter(center: const Offset(166, 610), width: 50, height: 50));
  caption('Şeker kutusu', const Offset(166, 654));
  caption('yanında eşleştir', const Offset(166, 670), size: 11);
  candyBox(canvas, Rect.fromCenter(center: const Offset(266, 610), width: 50, height: 50), layers: 1);
  caption('1 kat kaldı', const Offset(266, 654));
  candy(canvas, Rect.fromCenter(center: const Offset(364, 610), width: 50, height: 50), 'B');
  paintChains(canvas, Rect.fromCenter(center: const Offset(364, 610), width: 50, height: 50));
  caption('Buz · Zincir', const Offset(364, 654));

  // Chapters.
  card(702, 214, '60 SEVİYE · 6 BÖLÜM');
  const chapters = [
    ('1', 'Şeker Kasabası', 'temel', Color(0xFFFF7AC6)),
    ('2', 'Buzlu Vadi', 'buz', Color(0xFF2EA8FF)),
    ('3', 'Zincir Kalesi', 'zincir', Color(0xFF8A5AD8)),
    ('4', 'Kutu Fabrikası', 'şeker kutusu', Color(0xFFFF9A1F)),
    ('5', 'Bomba Kanyonu', 'süreli bomba', Color(0xFFFF2D55)),
    ('6', 'Gökkuşağı Adası', 'hepsi bir arada', Color(0xFF2BD96B)),
  ];
  for (var i = 0; i < chapters.length; i++) {
    final (n, name, what, col) = chapters[i];
    final x = 30.0 + (i % 2) * 190, y = 738.0 + (i ~/ 2) * 58;
    final chip = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 180, 50), const Radius.circular(16));
    canvas.drawRRect(chip, Paint()..color = col.withValues(alpha: 0.18));
    canvas.drawCircle(Offset(x + 24, y + 25), 17, Paint()..color = col);
    _text(canvas, n, Offset(x + 24, y + 25), 18, outline: _d(col, 0.4), stroke: 0.16);
    final p = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Baloo2', fontSize: 15, fontWeight: FontWeight.w800, height: 1.05))
      ..pushStyle(ui.TextStyle(color: const Color(0xFF5A1F7A), fontFamily: 'Baloo2', fontSize: 15, fontWeight: FontWeight.w800))
      ..addText('$name\n')
      ..pushStyle(ui.TextStyle(color: const Color(0xFF9A5AB5), fontFamily: 'Baloo2', fontSize: 12, fontWeight: FontWeight.w700))
      ..addText('yeni: $what');
    final para = p.build()..layout(const ui.ParagraphConstraints(width: 135));
    canvas.drawParagraph(para, Offset(x + 48, y + 25 - para.height / 2));
  }
}

Future<void> _save(WidgetTester tester, void Function(Canvas) paint, String name) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_scale);
    paint(canvas);
    final image = await recorder.endRecording().toImage((_w * _scale).round(), (_h * _scale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

Future<void> _loadFonts() async {
  final loader = FontLoader('Baloo2');
  for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Baloo2-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);
  testWidgets('game screen', (tester) => _save(tester, _gameScreen, 'seker2-oyun.png'));
  testWidgets('show moment', (tester) => _save(tester, _showScreen, 'seker2-sov.png'));
  testWidgets('overview', (tester) => _save(tester, _overview, 'seker2-yenilikler.png'));
}
