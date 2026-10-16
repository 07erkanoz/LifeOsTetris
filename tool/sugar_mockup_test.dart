// Look mock-ups for the planned "Şeker Küpler" mode: the game screen with
// special cubes, obstacles and a big clear, and the level map.
//   flutter test tool/sugar_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): seker-oyun.png, seker-harita.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/game/render/block_sprites.dart';

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';

const double _w = 430, _h = 932, _scale = 2.5;

const _candy = {
  'R': Color(0xFFFF3B5C),
  'O': Color(0xFFFF9A1F),
  'Y': Color(0xFFFFD23F),
  'G': Color(0xFF2BD96B),
  'B': Color(0xFF2E86FF),
  'P': Color(0xFFB45BFF),
};
const _shadeTarget = Color(0xFF1A0B2E);

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;

// ------------------------------------------------------------------- text --

ui.Paragraph _para(String text, double size, Paint paint, {FontWeight weight = FontWeight.w800, double width = 2000}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, height: 1.0))
    ..pushStyle(ui.TextStyle(foreground: paint, fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, height: 1.0))
    ..addText(text);
  return b.build()..layout(ui.ParagraphConstraints(width: width));
}

/// Outlined text centred on [c] (or starting at it when [centre] is false).
Size _label(Canvas canvas, String text, Offset c, double size, Paint fill,
    {Color outline = const Color(0xFF2A0F45), double stroke = 0.16, bool centre = true, FontWeight weight = FontWeight.w800}) {
  final o = _para(text, size, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * stroke
    ..strokeJoin = StrokeJoin.round
    ..color = outline, weight: weight);
  final at = centre ? c - Offset(o.longestLine / 2, o.height / 2) : c;
  if (stroke > 0) canvas.drawParagraph(o, at);
  final f = _para(text, size, fill, weight: weight);
  canvas.drawParagraph(f, at);
  return Size(o.longestLine, o.height);
}

Paint _grad(Rect r, List<Color> colors, {bool vertical = true}) =>
    Paint()..shader = ui.Gradient.linear(vertical ? r.topCenter : r.centerLeft, vertical ? r.bottomCenter : r.centerRight, colors);

// --------------------------------------------------------------- sparkles --

void _sparkle(Canvas canvas, Offset p, double size, Color color, {double opacity = 1}) {
  final star = Path()
    ..moveTo(p.dx, p.dy - size)
    ..quadraticBezierTo(p.dx, p.dy, p.dx + size, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + size)
    ..quadraticBezierTo(p.dx, p.dy, p.dx - size, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - size);
  canvas.drawCircle(p, size * 0.9, Paint()
    ..color = color.withValues(alpha: 0.35 * opacity)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.6));
  canvas.drawPath(star, Paint()..color = _l(color, 0.5).withValues(alpha: opacity));
  canvas.drawCircle(p, size * 0.18, Paint()..color = Colors.white.withValues(alpha: opacity));
}

Path _star(Offset c, double r, {double inner = 0.45}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -pi / 2 + i * pi / 5;
    final rr = i.isEven ? r : r * inner;
    final pt = c + Offset(cos(a) * rr, sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

void _goldStar(Canvas canvas, Offset c, double r, {bool on = true}) {
  final path = _star(c, r);
  canvas.drawPath(path.shift(Offset(0, r * 0.12)), Paint()..color = const Color(0xFF6B3A00).withValues(alpha: on ? 0.8 : 0.4));
  canvas.drawPath(
      path,
      on
          ? (Paint()..shader = ui.Gradient.linear(c - Offset(0, r), c + Offset(0, r), const [Color(0xFFFFF3A0), Color(0xFFFFC21A), Color(0xFFFF9500)], const [0, 0.5, 1]))
          : (Paint()..color = const Color(0xFF5A4A72)));
  canvas.drawPath(path, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.12
    ..color = on ? const Color(0xFFB86A00) : const Color(0xFF3A2D50));
  if (on) canvas.drawCircle(c + Offset(-r * 0.25, -r * 0.3), r * 0.14, Paint()..color = Colors.white.withValues(alpha: 0.9));
}

// ------------------------------------------------------------ the cubes --

void _cube(Canvas canvas, Rect r, Color color, {int bubbles = 0}) =>
    paintJellyHd(canvas, r.topLeft, r.width, color, shadeTarget: _shadeTarget, bubbles: bubbles);

/// Line cube: light bands across it and glowing arrow tips at both ends.
void _lineCube(Canvas canvas, Rect r, Color color, {required bool horizontal}) {
  final s = r.width;
  canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(s * 0.02), Radius.circular(s * 0.3)), Paint()
    ..color = _l(color, 0.3).withValues(alpha: 0.7)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.18));
  _cube(canvas, r, color);
  final b = r.deflate(s * 0.055);
  final rr = RRect.fromRectAndRadius(b, Radius.circular(s * 0.24));
  canvas.save();
  canvas.clipRRect(rr);
  for (var i = 0; i < 3; i++) {
    final t = 0.27 + i * 0.23;
    final band = horizontal
        ? Rect.fromLTWH(b.left, b.top + b.height * t - s * 0.045, b.width, s * 0.09)
        : Rect.fromLTWH(b.left + b.width * t - s * 0.045, b.top, s * 0.09, b.height);
    canvas.drawRRect(RRect.fromRectAndRadius(band, Radius.circular(s * 0.045)), Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.01));
  }
  canvas.restore();
  // Arrow tips.
  final c = r.center;
  for (final dir in [-1.0, 1.0]) {
    final tip = horizontal ? c + Offset(dir * s * 0.56, 0) : c + Offset(0, dir * s * 0.56);
    final back = horizontal ? Offset(-dir * s * 0.14, 0) : Offset(0, -dir * s * 0.14);
    final side = horizontal ? Offset(0, s * 0.11) : Offset(s * 0.11, 0);
    final arrow = Path()..addPolygon([tip, tip + back + side, tip + back - side], true);
    canvas.drawPath(arrow, Paint()
      ..color = Colors.white
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06));
    canvas.drawPath(arrow, Paint()..color = Colors.white);
  }
}

/// Bomb cube: a ring of light, a glowing star core and spark rays.
void _bombCube(Canvas canvas, Rect r, Color color) {
  final s = r.width;
  final c = r.center;
  canvas.drawCircle(c, s * 0.62, Paint()
    ..shader = ui.Gradient.radial(c, s * 0.62, [_l(color, 0.5).withValues(alpha: 0.75), color.withValues(alpha: 0)]));
  for (var i = 0; i < 8; i++) {
    final a = i * pi / 4 + pi / 8;
    canvas.drawLine(c + Offset(cos(a), sin(a)) * s * 0.36, c + Offset(cos(a), sin(a)) * s * 0.6, Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round);
  }
  _cube(canvas, r, color);
  final b = r.deflate(s * 0.055);
  final rr = RRect.fromRectAndRadius(b, Radius.circular(s * 0.24));
  canvas.drawRRect(rr.deflate(s * 0.05), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.07
    ..color = Colors.white.withValues(alpha: 0.85));
  canvas.drawRRect(rr.deflate(s * 0.05), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = _l(color, 0.2));
  canvas.drawCircle(c, s * 0.22, Paint()
    ..shader = ui.Gradient.radial(c, s * 0.22, [Colors.white, _l(color, 0.55).withValues(alpha: 0.8), color.withValues(alpha: 0)], const [0, 0.5, 1]));
  canvas.drawPath(_star(c, s * 0.17, inner: 0.42), Paint()..color = Colors.white);
}

/// Prism cube: rainbow light swirling inside clear glass.
void _prismCube(Canvas canvas, Rect r) {
  final s = r.width;
  final c = r.center;
  canvas.drawCircle(c, s * 0.66, Paint()
    ..shader = ui.Gradient.radial(c, s * 0.66, [Colors.white.withValues(alpha: 0.6), const Color(0xFFB45BFF).withValues(alpha: 0)]));
  final b = r.deflate(s * 0.05);
  final rr = RRect.fromRectAndRadius(b, Radius.circular(s * 0.26));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.07)), Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.09));
  canvas.drawRRect(rr, Paint()
    ..shader = ui.Gradient.sweep(c, const [
      Color(0xFFFF3B5C),
      Color(0xFFFF9A1F),
      Color(0xFFFFD23F),
      Color(0xFF2BD96B),
      Color(0xFF2E86FF),
      Color(0xFFB45BFF),
      Color(0xFFFF3B5C),
    ], const [0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1], TileMode.clamp, 0.6, 0.6 + 2 * pi));
  canvas.save();
  canvas.clipRRect(rr);
  canvas.drawCircle(c, s * 0.5, Paint()
    ..shader = ui.Gradient.radial(c, s * 0.5, [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0.0)], const [0, 1]));
  final gloss = Rect.fromLTWH(b.left + s * 0.08, b.top + s * 0.05, b.width - s * 0.16, s * 0.3);
  canvas.drawOval(gloss, Paint()..shader = ui.Gradient.linear(gloss.topCenter, gloss.bottomCenter, [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0)]));
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.035
    ..color = Colors.white.withValues(alpha: 0.9));
  _sparkle(canvas, c + Offset(-s * 0.16, -s * 0.12), s * 0.12, Colors.white);
  _sparkle(canvas, c + Offset(s * 0.18, s * 0.14), s * 0.08, Colors.white);
}

/// A cube frozen in ice: frosted glass over it, with cracks.
void _ice(Canvas canvas, Rect r, {int cracks = 2}) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r.deflate(s * 0.02), Radius.circular(s * 0.2));
  canvas.drawRRect(rr, Paint()
    ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [const Color(0xF0F2FBFF), const Color(0xD9B9E4FF), const Color(0xE6DDF2FF)], const [0, 0.5, 1]));
  canvas.save();
  canvas.clipRRect(rr);
  final frost = Random((r.left * 13 + r.top * 7).round());
  for (var i = 0; i < 14; i++) {
    canvas.drawCircle(r.topLeft + Offset(frost.nextDouble() * s, frost.nextDouble() * s), s * (0.02 + frost.nextDouble() * 0.04),
        Paint()..color = Colors.white.withValues(alpha: 0.55));
  }
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.045
    ..color = Colors.white.withValues(alpha: 0.95));
  final crack = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.025
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFF5AA8E0).withValues(alpha: 0.85);
  final p = Path()
    ..moveTo(r.left + s * 0.15, r.top + s * 0.3)
    ..lineTo(r.left + s * 0.38, r.top + s * 0.42)
    ..lineTo(r.left + s * 0.33, r.top + s * 0.62)
    ..lineTo(r.left + s * 0.55, r.top + s * 0.78);
  if (cracks > 1) {
    p
      ..moveTo(r.left + s * 0.38, r.top + s * 0.42)
      ..lineTo(r.left + s * 0.7, r.top + s * 0.32)
      ..lineTo(r.left + s * 0.84, r.top + s * 0.42);
  }
  canvas.drawPath(p, crack);
  canvas.drawLine(r.topLeft + Offset(s * 0.18, s * 0.12), r.topLeft + Offset(s * 0.5, s * 0.12), Paint()
    ..color = Colors.white
    ..strokeWidth = s * 0.05
    ..strokeCap = StrokeCap.round);
}

/// Chains locking a cube in place.
void _chains(Canvas canvas, Rect r) {
  final s = r.width;
  void chain(Offset a, Offset b) {
    final d = b - a;
    final n = 5;
    for (var i = 0; i < n; i++) {
      final c = a + d * ((i + 0.5) / n);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(atan2(d.dy, d.dx) + (i.isEven ? 0 : pi / 2));
      final link = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 0.22, height: s * 0.13), Radius.circular(s * 0.065));
      canvas.drawRRect(link.shift(Offset(0, s * 0.02)), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.05
        ..color = Colors.black.withValues(alpha: 0.45));
      canvas.drawRRect(link, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.05
        ..shader = ui.Gradient.linear(link.outerRect.topCenter, link.outerRect.bottomCenter, const [Color(0xFFF4F6FA), Color(0xFF8E97A8)]));
      canvas.restore();
    }
  }

  chain(r.topLeft + Offset(s * 0.05, s * 0.05), r.bottomRight - Offset(s * 0.05, s * 0.05));
  chain(r.topRight + Offset(-s * 0.05, s * 0.05), r.bottomLeft + Offset(s * 0.05, -s * 0.05));
  final lock = r.center;
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lock + Offset(0, s * 0.05), width: s * 0.3, height: s * 0.24), Radius.circular(s * 0.05)),
      Paint()..shader = ui.Gradient.linear(lock - Offset(0, s * 0.1), lock + Offset(0, s * 0.18), const [Color(0xFFFFE27A), Color(0xFFD99400)]));
  canvas.drawArc(Rect.fromCenter(center: lock - Offset(0, s * 0.06), width: s * 0.2, height: s * 0.2), pi, pi, false, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.045
    ..color = const Color(0xFFD99400));
}

// -------------------------------------------------------------- the game --

// 8×8 board. Letters are colours; lower case: frozen in ice; '-'/'|' line
// cubes (colour after), '*' bomb cube, '@' prism cube, '#' chained cube.
const _board = [
  'BRYGPOBY',
  'GoYbRGYP',
  'P|RYBG*O',
  'OGPRrRGB',
  'YBGGPYRG',
  'R@GyOB#Y',
  'GY-PgYRB',
  'BOYRBPGO',
];
const _special = {
  (1, 2): 'B', // vertical line cube, blue
  (6, 2): 'P', // bomb, purple
  (2, 6): 'O', // horizontal line cube, orange
  (6, 5): 'G', // chained green
};

void _gameScreen(Canvas canvas) {
  final screen = Offset.zero & const Size(_w, _h);
  // Sweet dusk backdrop with soft lights.
  canvas.drawRect(screen, Paint()
    ..shader = ui.Gradient.linear(screen.topCenter, screen.bottomCenter, const [Color(0xFF5B1FA8), Color(0xFFB0307E), Color(0xFF3A1470)], const [0, 0.55, 1]));
  final rnd = Random(4);
  for (var i = 0; i < 16; i++) {
    final c = [const Color(0xFFFFB3E6), const Color(0xFF9FD8FF), const Color(0xFFFFE08A)][i % 3];
    canvas.drawCircle(Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h), 20 + rnd.nextDouble() * 50, Paint()
      ..color = c.withValues(alpha: 0.12 + rnd.nextDouble() * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
  }

  // ---- top bar: level, moves, goals
  final top = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 38, _w - 28, 112), const Radius.circular(26));
  canvas.drawRRect(top.shift(const Offset(0, 6)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
  canvas.drawRRect(top, _grad(top.outerRect, const [Color(0xFFFFF7FD), Color(0xFFFFE3F4)]));
  canvas.drawRRect(top, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white);
  // Moves bubble.
  const mc = Offset(72, 94);
  canvas.drawCircle(mc + const Offset(0, 4), 44, Paint()..color = const Color(0xFF7A1C5B));
  canvas.drawCircle(mc, 44, Paint()..shader = ui.Gradient.radial(mc - const Offset(10, 14), 56, const [Color(0xFFFF7AC6), Color(0xFFE0247A)]));
  canvas.drawCircle(mc, 44, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..color = Colors.white);
  _label(canvas, '18', mc - const Offset(0, 6), 40, Paint()..color = Colors.white, outline: const Color(0xFF8A1550), stroke: 0.12);
  _label(canvas, 'HAMLE', mc + const Offset(0, 24), 14, Paint()..color = Colors.white, outline: const Color(0xFF8A1550), stroke: 0.2);
  // Level and goals.
  _label(canvas, 'SEVİYE 12', const Offset(130, 50), 20, Paint()..color = const Color(0xFF7A2A9E), stroke: 0, centre: false);
  void goal(Offset at, void Function(Rect r) icon, String text, double progress) {
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, 128, 50), const Radius.circular(16));
    canvas.drawRRect(box, Paint()..color = const Color(0xFFF3D9F0));
    icon(Rect.fromLTWH(at.dx + 6, at.dy + 6, 38, 38));
    _label(canvas, text, Offset(at.dx + 50, at.dy + 6), 18, Paint()..color = const Color(0xFF5A1F7A), stroke: 0, centre: false);
    final bar = Rect.fromLTWH(at.dx + 52, at.dy + 33, 66, 9);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(5)), Paint()..color = const Color(0xFFE2BCE0));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * progress, bar.height), const Radius.circular(5)),
        _grad(bar, const [Color(0xFF6BE3FF), Color(0xFF2E86FF)], vertical: false));
  }

  goal(const Offset(130, 82), (r) {
    _cube(canvas, r, _candy['B']!);
    _ice(canvas, r, cracks: 1);
  }, '6/12', 0.5);
  goal(const Offset(270, 82), (r) => _cube(canvas, r, _candy['B']!, bubbles: 1), '18/30', 0.6);
  _goldStar(canvas, const Offset(281, 62), 9);
  _label(canvas, '×3 için 24.000', const Offset(294, 52), 15, Paint()..color = const Color(0xFF9A5AB5), stroke: 0, centre: false, weight: FontWeight.w700);

  // ---- score bar with three stars
  final bar = RRect.fromRectAndRadius(const Rect.fromLTWH(40, 166, _w - 80, 22), const Radius.circular(11));
  canvas.drawRRect(bar.shift(const Offset(0, 3)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.6));
  canvas.drawRRect(bar, Paint()..color = const Color(0xFF3B1466));
  final fill = RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * 0.62, bar.height), const Radius.circular(11));
  canvas.drawRRect(fill, _grad(fill.outerRect, const [Color(0xFFFFE066), Color(0xFFFF8A00)], vertical: false));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.left + 6, bar.top + 4, bar.width * 0.62 - 12, 6), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.5));
  for (final (t, on) in [(0.35, true), (0.62, true), (0.92, false)]) {
    _goldStar(canvas, Offset(bar.left + bar.width * t, bar.center.dy), 17, on: on);
  }
  _label(canvas, '15.840', Offset(_w / 2, 206), 22, Paint()..color = Colors.white, stroke: 0.18);

  // ---- the board
  const cell = 50.0;
  final origin = Offset((_w - 8 * cell) / 2, 244);
  final tray = Rect.fromLTWH(origin.dx, origin.dy, 8 * cell, 8 * cell);
  final trayR = RRect.fromRectAndRadius(tray.inflate(10), const Radius.circular(26));
  canvas.drawRRect(trayR.shift(const Offset(0, 8)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
  canvas.drawRRect(trayR, Paint()..color = const Color(0xFF3A1270).withValues(alpha: 0.88));
  canvas.drawRRect(trayR, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFFF9AD8).withValues(alpha: 0.7));
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final r = Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell).deflate(1.5);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)),
          Paint()..color = ((x + y).isEven ? const Color(0xFF4A1A85) : const Color(0xFF41167A)).withValues(alpha: 0.9));
    }
  }
  // The clear in progress: column 5 is being swept by a vertical line cube.
  const beamX = 5;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final ch = _board[y][x];
      final r = Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell);
      if (x == beamX && y != 6) continue; // already burst by the beam
      final sp = _special[(x, y)];
      if (ch == '|') {
        _lineCube(canvas, r, _candy[sp]!, horizontal: false);
      } else if (ch == '-') {
        _lineCube(canvas, r, _candy[sp]!, horizontal: true);
      } else if (ch == '*') {
        _bombCube(canvas, r, _candy[sp]!);
      } else if (ch == '@') {
        _prismCube(canvas, r);
      } else if (ch == '#') {
        _cube(canvas, r, _candy[sp]!, bubbles: x + y);
        _chains(canvas, r);
      } else if (ch.toLowerCase() == ch) {
        _cube(canvas, r, _candy[ch.toUpperCase()]!, bubbles: x * 3 + y);
        _ice(canvas, r);
      } else {
        _cube(canvas, r, _candy[ch]!, bubbles: x * 3 + y);
      }
    }
  }
  // The beam.
  final beam = Rect.fromLTWH(origin.dx + beamX * cell + cell * 0.2, origin.dy - 14, cell * 0.6, 8 * cell + 28);
  canvas.drawRRect(RRect.fromRectAndRadius(beam.inflate(cell * 0.35), Radius.circular(cell)), Paint()
    ..color = const Color(0xFFFFB3E6).withValues(alpha: 0.55)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.4));
  canvas.drawRRect(RRect.fromRectAndRadius(beam, Radius.circular(cell)), Paint()
    ..shader = ui.Gradient.linear(beam.centerLeft, beam.centerRight, [Colors.white.withValues(alpha: 0.2), Colors.white, Colors.white.withValues(alpha: 0.2)], const [0, 0.5, 1]));
  final sp = Random(9);
  for (var i = 0; i < 46; i++) {
    final y = origin.dy + sp.nextDouble() * 8 * cell;
    final x = origin.dx + (beamX + 0.5) * cell + (sp.nextDouble() - 0.5) * cell * 2.4;
    final col = [Colors.white, const Color(0xFFFFE066), const Color(0xFFFF9AD8), const Color(0xFF9FD8FF)][i % 4];
    if (i % 3 == 0) {
      final s = 4.0 + sp.nextDouble() * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(sp.nextDouble() * pi);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s, height: s), Radius.circular(s * 0.3)),
          Paint()..color = _candy.values.elementAt(i % 6));
      canvas.restore();
    } else {
      _sparkle(canvas, Offset(x, y), 3 + sp.nextDouble() * 6, col);
    }
  }
  // Floating score and the callout.
  _label(canvas, '+1.200', origin + Offset((beamX + 0.5) * cell, 2.4 * cell), 22, Paint()..color = Colors.white, stroke: 0.2);
  canvas.save();
  canvas.translate(_w / 2, origin.dy + 4.0 * cell);
  canvas.rotate(-0.08);
  _label(canvas, 'HARİKA!', Offset.zero, 64, Paint()
    ..shader = ui.Gradient.linear(const Offset(0, -30), const Offset(0, 30), const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], const [0, 0.5, 1]),
      outline: const Color(0xFF6A0E4A), stroke: 0.2);
  canvas.restore();
  _label(canvas, 'ZİNCİR ×3', origin + Offset(4 * cell, 5.05 * cell), 26, Paint()..color = Colors.white, outline: const Color(0xFF6A0E4A), stroke: 0.22);

  // ---- boosters
  void booster(Offset c, void Function(Offset c) icon, String count, String name) {
    canvas.drawCircle(c + const Offset(0, 5), 34, Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
    canvas.drawCircle(c, 34, Paint()..shader = ui.Gradient.radial(c - const Offset(8, 10), 44, const [Color(0xFFFFFFFF), Color(0xFFFFD6F0)]));
    canvas.drawCircle(c, 34, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF7AC6));
    icon(c);
    final badge = c + const Offset(24, -24);
    canvas.drawCircle(badge, 13, Paint()..color = const Color(0xFF2BD96B));
    canvas.drawCircle(badge, 13, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white);
    _label(canvas, count, badge, 15, Paint()..color = Colors.white, stroke: 0);
    _label(canvas, name, c + const Offset(0, 50), 15, Paint()..color = Colors.white, outline: const Color(0xFF3A0F60), stroke: 0.22);
  }

  final by = _h - 132;
  booster(Offset(_w / 2 - 120, by), (c) {
    // Hammer.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.6);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 6), width: 7, height: 34), const Radius.circular(3)),
        Paint()..color = const Color(0xFFB0703A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -12), width: 32, height: 16), const Radius.circular(5)),
        Paint()..shader = ui.Gradient.linear(const Offset(0, -20), const Offset(0, -4), const [Color(0xFFDDE3EE), Color(0xFF7D879A)]));
    canvas.restore();
  }, '2', 'Çekiç');
  booster(Offset(_w / 2, by), (c) {
    // Shuffle: two swirl arrows.
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB45BFF);
    canvas.drawArc(Rect.fromCircle(center: c, radius: 15), -pi * 0.95, pi * 0.8, false, p);
    canvas.drawArc(Rect.fromCircle(center: c, radius: 15), pi * 0.05, pi * 0.8, false, p..color = const Color(0xFFFF3B5C));
    canvas.drawPath(Path()..addPolygon([c + const Offset(14, -10), c + const Offset(20, -2), c + const Offset(8, -2)], true), Paint()..color = const Color(0xFFB45BFF));
    canvas.drawPath(Path()..addPolygon([c + const Offset(-14, 10), c + const Offset(-20, 2), c + const Offset(-8, 2)], true), Paint()..color = const Color(0xFFFF3B5C));
  }, '1', 'Karıştır');
  booster(Offset(_w / 2 + 120, by), (c) {
    _label(canvas, '+3', c, 28, Paint()
      ..shader = ui.Gradient.linear(c - const Offset(0, 14), c + const Offset(0, 14), const [Color(0xFFFF7AC6), Color(0xFFE0247A)]),
        outline: Colors.white, stroke: 0.18);
  }, '1', '+3 Hamle');
}

// ------------------------------------------------------------------ map --

void _map(Canvas canvas) {
  final screen = Offset.zero & const Size(_w, _h);
  // Icy valley at dusk.
  canvas.drawRect(screen, Paint()
    ..shader = ui.Gradient.linear(screen.topCenter, screen.bottomCenter, const [Color(0xFF3B2A8F), Color(0xFF8A5AD8), Color(0xFFF2A6D8)], const [0, 0.45, 1]));
  final rnd = Random(12);
  for (var i = 0; i < 60; i++) {
    canvas.drawCircle(Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h * 0.45), 0.8 + rnd.nextDouble() * 1.6,
        Paint()..color = Colors.white.withValues(alpha: 0.4 + rnd.nextDouble() * 0.5));
  }
  // Snowy hills, back to front.
  void hill(double y, double amp, double phase, List<Color> colors) {
    final p = Path()..moveTo(0, _h);
    for (var x = 0.0; x <= _w; x += 8) {
      p.lineTo(x, y + sin(x / _w * pi * 2 + phase) * amp + sin(x / 60 + phase) * amp * 0.25);
    }
    p
      ..lineTo(_w, _h)
      ..close();
    canvas.drawPath(p, Paint()..shader = ui.Gradient.linear(Offset(0, y - amp), Offset(0, _h), colors));
  }

  hill(330, 40, 0.4, const [Color(0xFFE9E1FF), Color(0xFFB9A6F0)]);
  hill(470, 50, 2.0, const [Color(0xFFFFFFFF), Color(0xFFCFC2F7)]);
  hill(640, 46, 3.6, const [Color(0xFFF6F2FF), Color(0xFFD9CCF9)]);
  hill(800, 40, 1.2, const [Color(0xFFFFFFFF), Color(0xFFE6DBFB)]);
  // Pines.
  void pine(Offset base, double h) {
    for (var i = 0; i < 3; i++) {
      final w = h * (0.55 - i * 0.12), top = base.dy - h * (0.35 + i * 0.28);
      canvas.drawPath(Path()..addPolygon([Offset(base.dx, top - h * 0.3), Offset(base.dx + w, top + h * 0.12), Offset(base.dx - w, top + h * 0.12)], true),
          Paint()..color = Color.lerp(const Color(0xFF2F8F7A), const Color(0xFF1E6B5C), i / 2)!);
      canvas.drawPath(Path()..addPolygon([Offset(base.dx, top - h * 0.3), Offset(base.dx + w * 0.5, top - h * 0.08), Offset(base.dx - w * 0.5, top - h * 0.08)], true),
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    }
  }

  for (final (x, y, h) in [(40.0, 520.0, 60.0), (390.0, 470.0, 70.0), (360.0, 700.0, 56.0), (60.0, 760.0, 64.0), (30.0, 360.0, 44.0), (400.0, 860.0, 50.0)]) {
    pine(Offset(x, y), h);
  }

  // The path, winding up from the bottom.
  const pts = [
    Offset(300, 790),
    Offset(325, 690),
    Offset(225, 605),
    Offset(125, 505),
    Offset(215, 395),
    Offset(320, 315),
    Offset(250, 222),
    Offset(140, 160),
  ];
  final road = Path()..moveTo(pts.first.dx - 40, pts.first.dy + 120);
  road.cubicTo(pts.first.dx - 40, pts.first.dy + 60, pts.first.dx, pts.first.dy + 60, pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1], b = pts[i];
    road.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
  }
  canvas.drawPath(road, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 34
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF6E4AB8).withValues(alpha: 0.35));
  canvas.drawPath(road, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 24
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.85));
  for (final metric in road.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += 22) {
      final pos = metric.getTangentForOffset(d)!.position;
      canvas.drawCircle(pos, 3, Paint()..color = const Color(0xFFFF9AD8));
    }
  }

  // Levels along it: 8–11 done, 12 current, 13 hard, 15 boss, then locked.
  const levels = [9, 10, 11, 12, 13, 14, 15, 16];
  const stars = {9: 2, 10: 3, 11: 1};
  for (var i = 0; i < pts.length; i++) {
    final n = levels[i];
    final c = pts[i];
    final done = n < 12, current = n == 12, boss = n == 15, hard = n == 13;
    final r = current ? 36.0 : (boss ? 34.0 : 27.0);
    if (current) {
      canvas.drawCircle(c, r + 18, Paint()
        ..color = const Color(0xFFFF7AC6).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
      canvas.drawCircle(c, r + 9, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.85));
    }
    canvas.drawCircle(c + const Offset(0, 6), r, Paint()..color = const Color(0xFF3A1A6A).withValues(alpha: 0.55));
    final colors = done
        ? const [Color(0xFFFFF0A0), Color(0xFFFFB800)]
        : current
            ? const [Color(0xFFFF9AD8), Color(0xFFE0247A)]
            : boss
                ? const [Color(0xFFFF8A8A), Color(0xFFC81E3A)]
                : const [Color(0xFFD7D2E6), Color(0xFF8E86A8)];
    canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c - Offset(r * 0.3, r * 0.4), r * 1.5, colors));
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: c - Offset(0, r * 0.45), width: r * 1.1, height: r * 0.45), Paint()..color = Colors.white.withValues(alpha: 0.35));
    final locked = !done && !current && !boss && !hard;
    if (locked) {
      // Padlock.
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + const Offset(0, 5), width: 22, height: 17), const Radius.circular(4)),
          Paint()..color = const Color(0xFF5E5778));
      canvas.drawArc(Rect.fromCenter(center: c - const Offset(0, 4), width: 15, height: 16), pi, pi, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF5E5778));
    } else {
      _label(canvas, '$n', c + const Offset(0, 2), current ? 34 : 26, Paint()..color = Colors.white,
          outline: done ? const Color(0xFFB06A00) : (boss ? const Color(0xFF7A0E22) : const Color(0xFF8A1550)), stroke: 0.16);
    }
    if (done) {
      for (var k = 0; k < 3; k++) {
        final a = -pi / 2 + (k - 1) * 0.55;
        _goldStar(canvas, c + Offset(cos(a), sin(a)) * (r + 12), k == 1 ? 12 : 10, on: k < stars[n]!);
      }
    }
    if (current) {
      // A pin with a little cube on it, and the play label.
      final pin = c - Offset(0, r + 46);
      canvas.drawPath(Path()..addPolygon([pin + const Offset(-14, 10), pin + const Offset(14, 10), pin + const Offset(0, 34)], true), Paint()..color = Colors.white);
      canvas.drawCircle(pin, 24, Paint()..color = Colors.white);
      _cube(canvas, Rect.fromCenter(center: pin, width: 34, height: 34), _candy['P']!, bubbles: 1);
      final tag = RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, r + 26), width: 92, height: 32), const Radius.circular(16));
      canvas.drawRRect(tag.shift(const Offset(0, 4)), Paint()..color = const Color(0xFF8A1550));
      canvas.drawRRect(tag, _grad(tag.outerRect, const [Color(0xFF6BF0A0), Color(0xFF1FB85A)]));
      _label(canvas, 'OYNA', tag.center, 20, Paint()..color = Colors.white, outline: const Color(0xFF0E6A32), stroke: 0.16);
    }
    if (hard) {
      final tag = RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(r + 26, -r + 2), width: 54, height: 24), const Radius.circular(12));
      canvas.drawRRect(tag, _grad(tag.outerRect, const [Color(0xFFFF7A3D), Color(0xFFE02424)]));
      canvas.drawRRect(tag, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white);
      _label(canvas, 'ZOR', tag.center, 15, Paint()..color = Colors.white, outline: const Color(0xFF7A0E0E), stroke: 0.16);
      _label(canvas, '$n', c + const Offset(0, 2), 26, Paint()..color = Colors.white, outline: const Color(0xFF5E5778), stroke: 0.16);
    }
    if (boss) {
      // Crown.
      final k = c - Offset(0, r + 14);
      final crown = Path()
        ..moveTo(k.dx - 20, k.dy + 10)
        ..lineTo(k.dx - 22, k.dy - 10)
        ..lineTo(k.dx - 10, k.dy)
        ..lineTo(k.dx, k.dy - 16)
        ..lineTo(k.dx + 10, k.dy)
        ..lineTo(k.dx + 22, k.dy - 10)
        ..lineTo(k.dx + 20, k.dy + 10)
        ..close();
      canvas.drawPath(crown.shift(const Offset(0, 3)), Paint()..color = const Color(0xFF7A3A00));
      canvas.drawPath(crown, Paint()..shader = ui.Gradient.linear(k - const Offset(0, 16), k + const Offset(0, 10), const [Color(0xFFFFF0A0), Color(0xFFFFB000)]));
      for (final dx in [-10.0, 0.0, 10.0]) {
        canvas.drawCircle(k + Offset(dx, 4), 3, Paint()..color = const Color(0xFFFF3B5C));
      }
    }
  }
  // Treasure chest by level 14.
  final chest = pts[5] + const Offset(-130, -10);
  final body = RRect.fromRectAndRadius(Rect.fromCenter(center: chest, width: 54, height: 36), const Radius.circular(6));
  canvas.drawRRect(body.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF3A1A0A).withValues(alpha: 0.5));
  canvas.drawRRect(body, _grad(body.outerRect, const [Color(0xFFC9772E), Color(0xFF7E3F12)]));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: chest - const Offset(0, 16), width: 58, height: 18), const Radius.circular(9)),
      _grad(Rect.fromCenter(center: chest - const Offset(0, 16), width: 58, height: 18), const [Color(0xFFE08E3E), Color(0xFF9A4E18)]));
  for (final dx in [-16.0, 16.0]) {
    canvas.drawRect(Rect.fromCenter(center: chest + Offset(dx, -6), width: 6, height: 40), Paint()..color = const Color(0xFFFFC21A));
  }
  canvas.drawCircle(chest - const Offset(0, 4), 6, Paint()..color = const Color(0xFFFFE27A));
  for (var i = 0; i < 5; i++) {
    _sparkle(canvas, chest + Offset(-26.0 + i * 13, -34.0 - (i.isEven ? 6 : 0)), 5, const Color(0xFFFFE066));
  }

  // Top: chapter ribbon and the star count.
  final ribbon = RRect.fromRectAndRadius(const Rect.fromLTWH(70, 40, _w - 140, 54), const Radius.circular(18));
  canvas.drawRRect(ribbon.shift(const Offset(0, 6)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.6));
  canvas.drawRRect(ribbon, _grad(ribbon.outerRect, const [Color(0xFF7AD8FF), Color(0xFF2E86FF)]));
  canvas.drawRRect(ribbon, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white);
  _label(canvas, 'BÖLÜM 2', ribbon.center - const Offset(0, 12), 15, Paint()..color = Colors.white.withValues(alpha: 0.9), outline: const Color(0xFF0E4A9A), stroke: 0.18);
  _label(canvas, 'Buzlu Vadi', ribbon.center + const Offset(0, 9), 24, Paint()..color = Colors.white, outline: const Color(0xFF0E4A9A), stroke: 0.18);
  final pill = RRect.fromRectAndRadius(const Rect.fromLTWH(_w - 112, 108, 98, 36), const Radius.circular(18));
  canvas.drawRRect(pill, Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
  _goldStar(canvas, pill.outerRect.centerLeft + const Offset(20, 0), 12);
  _label(canvas, '34/90', pill.outerRect.centerLeft + const Offset(36, -11), 20, Paint()..color = Colors.white, stroke: 0, centre: false);

  // Bottom: continue.
  final btn = RRect.fromRectAndRadius(const Rect.fromLTWH(46, _h - 104, _w - 92, 70), const Radius.circular(26));
  canvas.drawRRect(btn.shift(const Offset(0, 7)), Paint()..color = const Color(0xFF8A1550));
  canvas.drawRRect(btn, _grad(btn.outerRect, const [Color(0xFFFF9AD8), Color(0xFFE0247A)]));
  canvas.drawRRect(btn, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(btn.left + 18, btn.top + 8, btn.width - 36, 18), const Radius.circular(9)),
      Paint()..color = Colors.white.withValues(alpha: 0.3));
  canvas.drawPath(Path()..addPolygon([btn.outerRect.centerLeft + const Offset(36, -14), btn.outerRect.centerLeft + const Offset(36, 14), btn.outerRect.centerLeft + const Offset(60, 0)], true),
      Paint()..color = Colors.white);
  _label(canvas, 'Devam: Seviye 12', btn.center + const Offset(20, 0), 26, Paint()..color = Colors.white, outline: const Color(0xFF8A1550), stroke: 0.14);
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
  testWidgets('game screen', (tester) => _save(tester, _gameScreen, 'seker-oyun.png'));
  testWidgets('level map', (tester) => _save(tester, _map, 'seker-harita.png'));
}
