import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/sugar/sugar_game.dart';

/// The Şeker Küpler look: a sweet shape per colour, the specials, ice,
/// chains, candy boxes and timed bombs, the mascot Lokum, stars and
/// sparkles. Board pieces are drawn into images once per size
/// ([SugarSprites]); a frame only copies them.

const sugarColors = {
  SugarColor.red: Color(0xFFFF2D55),
  SugarColor.orange: Color(0xFFFF7A1A),
  SugarColor.yellow: Color(0xFFFFE14A),
  SugarColor.green: Color(0xFF2BD96B),
  SugarColor.blue: Color(0xFF2EA8FF),
  SugarColor.purple: Color(0xFFA44BFF),
};

const _shadeTarget = Color(0xFF1A0B2E);

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;

// ------------------------------------------------------------------ text --

ui.Paragraph _para(String text, double size, Paint paint, FontWeight weight) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, height: 1.0))
    ..pushStyle(ui.TextStyle(foreground: paint, fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, height: 1.0))
    ..addText(text);
  return b.build()..layout(const ui.ParagraphConstraints(width: 4000));
}

/// Width of [text] as [paintSugarLabel] draws it at [size].
double sugarLabelWidth(String text, double size) => _para(text, size, Paint(), FontWeight.w800).longestLine * (1 + 0.16);

/// Candy-style outlined text centred on [c].
void paintSugarLabel(Canvas canvas, String text, Offset c, double size, Paint fill,
    {Color outline = const Color(0xFF2A0F45), double stroke = 0.16, FontWeight weight = FontWeight.w800}) {
  final o = _para(text, size, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * stroke
    ..strokeJoin = StrokeJoin.round
    ..color = outline, weight);
  final at = c - Offset(o.longestLine / 2, o.height / 2);
  if (stroke > 0) canvas.drawParagraph(o, at);
  canvas.drawParagraph(_para(text, size, fill, weight), at);
}

// ---------------------------------------------------------- stars, sparks --

void paintSparkle(Canvas canvas, Offset p, double size, Color color, {double opacity = 1}) {
  final star = Path()
    ..moveTo(p.dx, p.dy - size)
    ..quadraticBezierTo(p.dx, p.dy, p.dx + size, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + size)
    ..quadraticBezierTo(p.dx, p.dy, p.dx - size, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - size);
  canvas.drawCircle(p, size * 0.9, Paint()..color = color.withValues(alpha: 0.3 * opacity));
  canvas.drawPath(star, Paint()..color = _l(color, 0.5).withValues(alpha: opacity));
  canvas.drawCircle(p, size * 0.18, Paint()..color = Colors.white.withValues(alpha: opacity));
}

Path starPath(Offset c, double r, {double inner = 0.45}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -pi / 2 + i * pi / 5;
    final rr = i.isEven ? r : r * inner;
    final pt = c + Offset(cos(a) * rr, sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

void paintGoldStar(Canvas canvas, Offset c, double r, {bool on = true}) {
  final path = starPath(c, r);
  canvas.drawPath(path.shift(Offset(0, r * 0.12)), Paint()..color = const Color(0xFF6B3A00).withValues(alpha: on ? 0.8 : 0.4));
  canvas.drawPath(
    path,
    on
        ? (Paint()
          ..shader = ui.Gradient.linear(c - Offset(0, r), c + Offset(0, r), const [Color(0xFFFFF3A0), Color(0xFFFFC21A), Color(0xFFFF9500)], const [0, 0.5, 1]))
        : (Paint()..color = const Color(0xFF5A4A72)),
  );
  canvas.drawPath(path, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.12
    ..strokeJoin = StrokeJoin.round
    ..color = on ? const Color(0xFFB86A00) : const Color(0xFF3A2D50));
  if (on) canvas.drawCircle(c + Offset(-r * 0.25, -r * 0.3), r * 0.14, Paint()..color = Colors.white.withValues(alpha: 0.9));
}

// ------------------------------------------------------------ the sweets --

Color _d(Color c, double t) => Color.lerp(c, Colors.black, t)!;

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

List<Offset> _polygon(Offset c, double r, int n, double turn) => [for (var i = 0; i < n; i++) c + Offset(cos(turn + i * 2 * pi / n), sin(turn + i * 2 * pi / n)) * r];

List<Offset> _starPoints(Offset c, double r, double inner) => [
  for (var i = 0; i < 10; i++) c + Offset(cos(-pi / 2 + i * pi / 5), sin(-pi / 2 + i * pi / 5)) * (i.isOdd ? r * inner : r),
];

/// The shape of a sweet of colour [color] in [cell]: heart, caramel round,
/// star, sugared square, drop, crystal.
Path candyShape(SugarColor color, Rect cell) {
  final r = cell.deflate(cell.width * 0.07);
  final c = r.center, s = r.width;
  return switch (color) {
    SugarColor.red => _heart(r),
    SugarColor.orange => Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.47)),
    SugarColor.yellow => _rounded(_starPoints(c + Offset(0, s * 0.04), s * 0.56, 0.56)),
    SugarColor.green => Path()..addRRect(RRect.fromRectAndRadius(r.deflate(s * 0.04), Radius.circular(s * 0.26))),
    SugarColor.blue => _drop(r),
    SugarColor.purple => _rounded(_polygon(c, s * 0.52, 6, pi / 6)),
  };
}

/// A glossy sweet of [color] in [cell].
void paintCandy(Canvas canvas, Rect cell, SugarColor color, {bool shadow = true}) {
  final col = sugarColors[color]!;
  final shape = candyShape(color, cell);
  final s = cell.width;
  final b = shape.getBounds();
  if (shadow) {
    canvas.drawPath(shape.shift(Offset(0, s * 0.06)), Paint()
      ..color = _shadeTarget.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  }
  canvas.drawPath(shape, Paint()
    ..shader = ui.Gradient.radial(b.center - Offset(s * 0.12, s * 0.18), s * 0.72, [_l(col, 0.45), col, _d(col, 0.32)], const [0, 0.5, 1]));
  canvas.save();
  canvas.clipPath(shape);
  canvas.drawOval(Rect.fromCenter(center: b.bottomCenter, width: b.width * 1.1, height: b.height * 0.55), Paint()
    ..color = _d(col, 0.45).withValues(alpha: 0.45)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08));
  switch (color) {
    case SugarColor.orange:
      // Caramel swirl.
      final sp = Path();
      for (var t = 0.0; t < pi * 4.2; t += 0.12) {
        final p = b.center + Offset(cos(t), sin(t)) * (s * (0.05 + t * 0.026));
        t == 0 ? sp.moveTo(p.dx, p.dy) : sp.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(sp, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFF1DD).withValues(alpha: 0.85));
    case SugarColor.green:
      // Sugar dust.
      final rnd = Random(7);
      for (var i = 0; i < 16; i++) {
        canvas.drawCircle(b.topLeft + Offset(rnd.nextDouble() * b.width, rnd.nextDouble() * b.height), s * 0.018, Paint()..color = Colors.white.withValues(alpha: 0.7));
      }
    case SugarColor.purple:
      // Crystal facets.
      for (final p in _polygon(b.center, s * 0.52, 6, pi / 6)) {
        canvas.drawLine(b.center, p, Paint()
          ..strokeWidth = s * 0.02
          ..color = Colors.white.withValues(alpha: 0.3));
      }
      canvas.drawPath(_rounded(_polygon(b.center, s * 0.26, 6, pi / 6)), Paint()..color = _l(col, 0.35).withValues(alpha: 0.6));
    case SugarColor.blue:
      canvas.drawCircle(b.center + Offset(s * 0.06, s * 0.14), s * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.22));
    default:
      break;
  }
  final g = Rect.fromLTWH(b.left + b.width * 0.16, b.top + b.height * (color == SugarColor.blue ? 0.32 : 0.1), b.width * 0.46, b.height * 0.24);
  canvas.drawOval(g, Paint()..shader = ui.Gradient.linear(g.topCenter, g.bottomCenter, [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0)]));
  canvas.restore();
  canvas.drawPath(shape, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = _l(col, 0.55).withValues(alpha: 0.7));
  canvas.drawCircle(g.center + Offset(g.width * 0.25, -g.height * 0.05), s * 0.035, Paint()..color = Colors.white);
}

/// Striped sweet: bands across the shape and arrow tips.
void paintStriped(Canvas canvas, Rect cell, SugarColor color, {required bool horizontal}) {
  final s = cell.width;
  canvas.drawCircle(cell.center, s * 0.55, Paint()
    ..color = _l(sugarColors[color]!, 0.3).withValues(alpha: 0.55)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.16));
  paintCandy(canvas, cell, color);
  canvas.save();
  canvas.clipPath(candyShape(color, cell));
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
    final arrow = Path()..addPolygon([tip, tip + back + side, tip + back - side], true);
    canvas.drawPath(arrow, Paint()
      ..color = Colors.white
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05));
    canvas.drawPath(arrow, Paint()..color = Colors.white);
  }
}

/// Wrapped sweet: a glowing wrapper with twisted ends.
void paintWrapped(Canvas canvas, Rect cell, SugarColor color) {
  final s = cell.width, c = cell.center, col = sugarColors[color]!;
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
  paintCandy(canvas, Rect.fromCenter(center: c, width: s * 0.78, height: s * 0.78), color);
  canvas.drawPath(starPath(c, s * 0.15, inner: 0.42), Paint()..color = Colors.white);
}

/// Rainbow ball: a sphere of swirling colours with sprinkles.
void paintRainbow(Canvas canvas, Rect cell) {
  final s = cell.width, c = cell.center;
  canvas.drawCircle(c, s * 0.66, Paint()..shader = ui.Gradient.radial(c, s * 0.66, [Colors.white.withValues(alpha: 0.7), const Color(0xFFB45BFF).withValues(alpha: 0)]));
  canvas.drawCircle(c + Offset(0, s * 0.05), s * 0.44, Paint()
    ..color = Colors.black.withValues(alpha: 0.4)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05));
  canvas.drawCircle(c, s * 0.44, Paint()
    ..shader = ui.Gradient.sweep(c, [...sugarColors.values, sugarColors[SugarColor.red]!], const [0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1]));
  canvas.drawCircle(c, s * 0.44, Paint()..shader = ui.Gradient.radial(c - Offset(s * 0.12, s * 0.14), s * 0.5, [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)]));
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

/// Timed bomb: a chocolate bonbon ringed with its colour and a lit fuse
/// (the count is drawn over it each frame).
void paintTimedBomb(Canvas canvas, Rect cell, SugarColor color) {
  final s = cell.width, c = cell.center + Offset(0, s * 0.04), col = sugarColors[color]!;
  canvas.drawCircle(c + Offset(0, s * 0.05), s * 0.42, Paint()
    ..color = Colors.black.withValues(alpha: 0.5)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  canvas.drawCircle(c, s * 0.42, Paint()..shader = ui.Gradient.radial(c - Offset(s * 0.1, s * 0.12), s * 0.5, [_l(col, 0.4), col, _d(col, 0.35)], const [0, 0.5, 1]));
  canvas.drawCircle(c, s * 0.32, Paint()..shader = ui.Gradient.radial(c - Offset(s * 0.1, s * 0.12), s * 0.42, const [Color(0xFF9A5A3A), Color(0xFF5A2E1A), Color(0xFF2E140A)], const [0, 0.5, 1]));
  canvas.drawCircle(c - Offset(s * 0.12, s * 0.14), s * 0.05, Paint()..color = Colors.white.withValues(alpha: 0.5));
  final fuse = Path()
    ..moveTo(c.dx + s * 0.24, c.dy - s * 0.34)
    ..quadraticBezierTo(c.dx + s * 0.34, c.dy - s * 0.52, c.dx + s * 0.46, c.dy - s * 0.48);
  canvas.drawPath(fuse, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.06
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFE8D2A8));
  paintSparkle(canvas, Offset(c.dx + s * 0.47, c.dy - s * 0.5), s * 0.13, const Color(0xFFFFC21A));
}

/// Candy box: a gift box with a ribbon; one layer left shows it cracked.
void paintCandyBox(Canvas canvas, Rect cell, {int layers = 2}) {
  final s = cell.width;
  final r = cell.deflate(s * 0.05);
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.14));
  Paint grad(Rect r, List<Color> colors) => Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors);
  canvas.drawRRect(rr.shift(Offset(0, s * 0.06)), Paint()
    ..color = _shadeTarget.withValues(alpha: 0.55)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  canvas.drawRRect(rr, grad(r, layers >= 2 ? const [Color(0xFFFFB8DC), Color(0xFFE85AA6)] : const [Color(0xFFFFD9EC), Color(0xFFF08AC0)]));
  final lid = RRect.fromRectAndRadius(Rect.fromLTWH(r.left - s * 0.02, r.top, r.width + s * 0.04, s * 0.26), Radius.circular(s * 0.1));
  canvas.drawRRect(lid, grad(lid.outerRect, layers >= 2 ? const [Color(0xFFFFD0E8), Color(0xFFFF7AC0)] : const [Color(0xFFFFE6F2), Color(0xFFFFA6D2)]));
  final gold = grad(r, const [Color(0xFFFFF0A0), Color(0xFFFFB000)]);
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

/// Ice on a cell: frosted glass with cracks; [layers] 2 is thick ice.
void paintIce(Canvas canvas, Rect r, {int layers = 1, int seed = 0}) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r.deflate(s * 0.02), Radius.circular(s * 0.2));
  final thick = layers >= 2;
  canvas.drawRRect(rr, Paint()
    ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [
      Color(thick ? 0xF2F4FBFF : 0xD9EEF8FF),
      Color(thick ? 0xE6BCDFFF : 0xC2BCE3FF),
      Color(thick ? 0xEEDDEFFF : 0xCCDCEEFF),
    ], const [0, 0.5, 1]));
  canvas.save();
  canvas.clipRRect(rr);
  final frost = Random(seed);
  for (var i = 0; i < (thick ? 18 : 11); i++) {
    canvas.drawCircle(r.topLeft + Offset(frost.nextDouble() * s, frost.nextDouble() * s), s * (0.02 + frost.nextDouble() * 0.04),
        Paint()..color = Colors.white.withValues(alpha: 0.5));
  }
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * (thick ? 0.07 : 0.045)
    ..color = Colors.white.withValues(alpha: 0.95));
  if (thick) {
    canvas.drawRRect(rr.deflate(s * 0.1), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..color = Colors.white.withValues(alpha: 0.6));
  }
  final crack = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.025
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFF5AA8E0).withValues(alpha: 0.85);
  final flip = seed.isOdd;
  double fx(double v) => flip ? r.right - s * v : r.left + s * v;
  final p = Path()
    ..moveTo(fx(0.15), r.top + s * 0.3)
    ..lineTo(fx(0.38), r.top + s * 0.42)
    ..lineTo(fx(0.33), r.top + s * 0.62)
    ..lineTo(fx(0.55), r.top + s * 0.78);
  if (thick) {
    p
      ..moveTo(fx(0.38), r.top + s * 0.42)
      ..lineTo(fx(0.7), r.top + s * 0.32)
      ..lineTo(fx(0.84), r.top + s * 0.42);
  }
  canvas.drawPath(p, crack);
  canvas.drawLine(r.topLeft + Offset(s * 0.18, s * 0.12), r.topLeft + Offset(s * 0.5, s * 0.12), Paint()
    ..color = Colors.white
    ..strokeWidth = s * 0.05
    ..strokeCap = StrokeCap.round);
}

/// Chains locking a cube in place.
void paintChains(Canvas canvas, Rect r) {
  final s = r.width;
  void chain(Offset a, Offset b) {
    final d = b - a;
    const n = 5;
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


// ------------------------------------------------------------- the mascot --

enum LokumPose { happy, wow, cheer, wink }

/// Lokum, the mascot: a pink jelly sweet with a cherry on top, [size] tall
/// around [c]; [hop] 0..1 lifts and squashes it a little.
void paintLokum(Canvas canvas, Offset c, double size, {LokumPose pose = LokumPose.happy, double hop = 0}) {
  final s = size;
  canvas.save();
  canvas.translate(c.dx, c.dy - s * 0.12 * sin(hop * pi));
  canvas.scale(1 + 0.05 * sin(hop * pi), 1 - 0.05 * sin(hop * pi));
  const pink = Color(0xFFFF6FB5);
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.55), width: s * 0.9, height: s * 0.16), Paint()
    ..color = Colors.black.withValues(alpha: 0.3)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  final arm = Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.2), Offset(0, s * 0.4), [_l(pink, 0.3), _d(pink, 0.15)]);
  for (final dir in [-1.0, 1.0]) {
    canvas.save();
    final up = pose == LokumPose.cheer || (pose == LokumPose.wink && dir > 0);
    canvas.translate(dir * s * 0.5, up ? -s * 0.08 : s * 0.16);
    canvas.rotate(dir * (up ? -0.7 : 0.6));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, up ? -s * 0.1 : s * 0.08), width: s * 0.17, height: s * 0.34), Radius.circular(s * 0.09)), arm);
    canvas.restore();
  }
  for (final dir in [-1.0, 1.0]) {
    canvas.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.2, s * 0.5), width: s * 0.28, height: s * 0.14), Paint()..color = _d(pink, 0.2));
  }
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
  for (final dir in [-1.0, 1.0]) {
    final e = Offset(dir * s * 0.17, -s * 0.06);
    if (pose == LokumPose.wink && dir > 0) {
      canvas.drawArc(Rect.fromCenter(center: e, width: s * 0.16, height: s * 0.12), pi * 1.1, pi * 0.8, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3A0F2A));
      continue;
    }
    final big = pose == LokumPose.wow ? 1.15 : 1.0;
    canvas.drawOval(Rect.fromCenter(center: e, width: s * 0.17 * big, height: s * 0.21 * big), Paint()..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: e + Offset(s * 0.01, s * 0.015), width: s * 0.11 * big, height: s * 0.14 * big), Paint()..color = const Color(0xFF2A0B30));
    canvas.drawCircle(e + Offset(-s * 0.015, -s * 0.03), s * 0.03, Paint()..color = Colors.white);
    canvas.drawCircle(e + Offset(s * 0.03, s * 0.04), s * 0.012, Paint()..color = Colors.white);
  }
  for (final dir in [-1.0, 1.0]) {
    canvas.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.3, s * 0.1), width: s * 0.14, height: s * 0.08), Paint()..color = const Color(0xFFFF3B7A).withValues(alpha: 0.55));
  }
  final mouth = Offset(0, s * 0.15);
  if (pose == LokumPose.wow) {
    canvas.drawOval(Rect.fromCenter(center: mouth, width: s * 0.12, height: s * 0.15), Paint()..color = const Color(0xFF6A0E2A));
  } else {
    final open = pose == LokumPose.cheer;
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

/// Paints one piece the way the board shows it.
void paintSugarPiece(Canvas canvas, Rect r, SugarColor color, Special special) {
  switch (special) {
    case Special.none:
      paintCandy(canvas, r, color);
    case Special.lineH:
      paintStriped(canvas, r, color, horizontal: true);
    case Special.lineV:
      paintStriped(canvas, r, color, horizontal: false);
    case Special.bomb:
      paintWrapped(canvas, r, color);
    case Special.prism:
      paintRainbow(canvas, r);
  }
}

// --------------------------------------------------------------- sprites --

/// The sweets, ice, chains and boxes drawn once per cell size into images.
class SugarSprites {
  SugarSprites._(this.cell, this.dpr);

  static SugarSprites? _cache;

  static SugarSprites of(double cell, double dpr) {
    final c = _cache;
    if (c != null && c.cell == cell && c.dpr == dpr) return c;
    c?.dispose();
    return _cache = SugarSprites._(cell, dpr);
  }

  /// Room around a sweet for its glow, as a share of the cell.
  static const double pad = 0.25;

  final double cell;
  final double dpr;
  final Map<Object, ui.Image> _images = {};

  ui.Image _render(void Function(Canvas canvas, Rect r) paint) {
    final side = cell * (1 + 2 * pad);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paint(canvas, Rect.fromLTWH(cell * pad + 1, cell * pad + 1, cell - 2, cell - 2));
    final px = max(1, (side * dpr).ceil());
    return recorder.endRecording().toImageSync(px, px);
  }

  ui.Image piece(SugarPiece p) {
    if (p.isBomb && p.special == Special.none) return _images[('bomb', p.color)] ??= _render((canvas, r) => paintTimedBomb(canvas, r, p.color));
    final key = p.isPrism ? (Special.prism, null) : (p.special, p.color);
    return _images[key] ??= _render((canvas, r) => paintSugarPiece(canvas, r, p.color, p.special));
  }

  ui.Image ice(int layers, int variant) => _images[('ice', layers.clamp(1, 2), variant % 2)] ??= _render((canvas, r) => paintIce(canvas, r, layers: layers, seed: variant % 2));

  ui.Image box(int layers) => _images[('box', layers.clamp(1, 2))] ??= _render((canvas, r) => paintCandyBox(canvas, r, layers: layers));

  ui.Image get chains => _images['chains'] ??= _render(paintChains);

  /// Draws [image] over the cell whose top-left is [origin].
  void draw(Canvas canvas, ui.Image image, Offset origin, {double opacity = 1, double scale = 1, double scaleY = 1}) {
    final side = cell * (1 + 2 * pad) * scale;
    final centre = origin + Offset(cell / 2, cell / 2);
    final dst = Rect.fromCenter(center: centre + Offset(0, side * (1 - scaleY) / 2 * 0.8), width: side * (2 - scaleY), height: side * scaleY);
    // Sprites are drawn at their own size; a cheaper filter keeps Windows
    // (Skia on integrated GPUs) smooth.
    final paint = Paint()..filterQuality = FilterQuality.low;
    if (opacity < 1) paint.color = Colors.white.withValues(alpha: opacity.clamp(0, 1));
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), dst, paint);
  }

  void dispose() {
    for (final i in _images.values) {
      i.dispose();
    }
    _images.clear();
  }
}
