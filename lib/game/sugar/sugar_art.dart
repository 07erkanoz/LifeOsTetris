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
  Paint grad(Rect r, List<Color> colors) =>
      Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);
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

enum LokumPose {
  happy,
  wow,
  cheer,
  wink,

  /// Lost: drooping, with a tear.
  sad,

  /// A bomb about to go: hands over the eyes.
  scared,

  /// The finale: arms out, leaning with [paintLokum]'s beat.
  dance,

  /// Showing a move: one arm pointing to the side.
  point,

  /// Diving into the board: mouth wide open.
  chomp,

  /// Idle for a while: eyes shut, a little "z".
  sleepy,
}

/// What Lokum wears: pieces from Turkish tradition, each unlocked once
/// the player has [stars] Şeker Küpler stars.
enum LokumOutfit {
  none(0),

  /// A red fez with a black tassel.
  fez(3),

  /// A red tulip.
  tulip(9),

  /// A blue evil-eye bead on a string.
  nazar(18),

  /// A grand curled moustache.
  moustache(30),

  /// A simit seller's tray of simits.
  simit(45),

  /// The fur kalpak of the War of Independence.
  kalpak(60),

  /// The tall white börk of the Janissaries.
  janissary(80),

  /// A sultan's white turban with a jewelled plume.
  sultan(110),

  /// Weekly event prizes: a crown of tulips (the Tulip Festival)...
  tulipCrown(0, 'outfitTulipCrown'),

  /// ...a ferry captain's cap (Ferry Week)...
  captain(0, 'outfitCaptain'),

  /// ...a coffee maker's apron (Coffee Week)...
  apron(0, 'outfitApron'),

  /// ...and a simit on a string (Simit Week).
  simitNecklace(0, 'outfitSimitNecklace'),

  /// A tour guide's hat with a little flag, for a full postcard album.
  guide(0, 'outfitGuide');

  const LokumOutfit(this.stars, [this.gift]);

  /// Şeker Küpler stars needed to wear it.
  final int stars;

  /// The gift that unlocks it instead of stars (an Unlock name), if any.
  final String? gift;

  static LokumOutfit parse(String? name) => values.firstWhere((o) => o.name == name, orElse: () => none);

  /// Whether [stars] and the gifts in [unlocks] let Lokum wear it.
  bool open(int stars, Set<String> unlocks) {
    final g = gift;
    return g != null ? unlocks.contains(g) : stars >= this.stars;
  }

  /// The outfit named [name] if it is open, else none.
  static LokumOutfit worn(String? name, int stars, [Set<String> unlocks = const {}]) {
    final o = parse(name);
    return o.open(stars, unlocks) ? o : none;
  }
}

/// Outfits that cover the top of the head (no cherry under them).
bool _hatOn(LokumOutfit o) => const {LokumOutfit.fez, LokumOutfit.kalpak, LokumOutfit.sultan, LokumOutfit.janissary, LokumOutfit.simit, LokumOutfit.captain, LokumOutfit.guide}.contains(o);

/// Lokum, the mascot: a pink jelly sweet with a cherry on top, [size] tall
/// around [c]; [hop] 0..1 lifts and squashes it a little, [beat] (0..1,
/// looping) sways the dance, [pointLeft] turns the pointing arm.
void paintLokum(Canvas canvas, Offset c, double size,
    {LokumPose pose = LokumPose.happy, double hop = 0, double beat = 0, bool pointLeft = false, LokumOutfit outfit = LokumOutfit.none}) {
  final s = size;
  canvas.save();
  canvas.translate(c.dx, c.dy - s * 0.12 * sin(hop * pi));
  if (pose == LokumPose.dance) canvas.rotate(sin(beat * pi * 2) * 0.16);
  final droop = pose == LokumPose.sad ? 0.06 : 0.0;
  canvas.scale(1 + 0.05 * sin(hop * pi) + droop, 1 - 0.05 * sin(hop * pi) - droop);
  const pink = Color(0xFFFF6FB5);
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.55), width: s * 0.9, height: s * 0.16), Paint()
    ..color = Colors.black.withValues(alpha: 0.3)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  final arm = Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.2), Offset(0, s * 0.4), [_l(pink, 0.3), _d(pink, 0.15)]);
  void drawArm(double dir, {required double at, required double turn, double reach = 0.34}) {
    canvas.save();
    canvas.translate(dir * s * 0.5, at);
    canvas.rotate(dir * turn);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -s * reach * 0.3), width: s * 0.17, height: s * reach), Radius.circular(s * 0.09)), arm);
    canvas.restore();
  }

  // Arms behind the body (those in front come after the face).
  for (final dir in [-1.0, 1.0]) {
    switch (pose) {
      case LokumPose.cheer:
        drawArm(dir, at: -s * 0.08, turn: -0.7);
      case LokumPose.wink when dir > 0:
        drawArm(dir, at: -s * 0.08, turn: -0.7);
      case LokumPose.dance:
        drawArm(dir, at: s * 0.02, turn: -1.2 + 0.5 * sin(beat * pi * 2 + (dir > 0 ? pi : 0)));
      case LokumPose.point when (dir > 0) != pointLeft:
        break; // drawn in front, after the face
      case LokumPose.scared:
        break;
      case LokumPose.sad:
        drawArm(dir, at: s * 0.2, turn: 0.25);
      default:
        drawArm(dir, at: s * 0.16, turn: 0.6, reach: 0.34);
    }
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
  // Cherry on top (hats sit on it).
  if (!_hatOn(outfit)) {
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
  }
  // Face.
  const ink = Color(0xFF3A0F2A);
  final lid = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.035
    ..strokeCap = StrokeCap.round
    ..color = ink;
  for (final dir in [-1.0, 1.0]) {
    final e = Offset(dir * s * 0.17, -s * 0.06);
    final shut = (pose == LokumPose.wink && dir > 0) || pose == LokumPose.sleepy || pose == LokumPose.chomp;
    if (shut) {
      canvas.drawArc(Rect.fromCenter(center: e, width: s * 0.16, height: s * 0.12), pose == LokumPose.sleepy ? pi * 0.1 : pi * 1.1, pi * 0.8, false, lid);
      continue;
    }
    final big = pose == LokumPose.wow ? 1.15 : 1.0;
    canvas.drawOval(Rect.fromCenter(center: e, width: s * 0.17 * big, height: s * 0.21 * big), Paint()..color = Colors.white);
    final look = pose == LokumPose.point ? Offset((pointLeft ? -1 : 1) * s * 0.03, 0) : Offset.zero;
    canvas.drawOval(Rect.fromCenter(center: e + Offset(s * 0.01, s * 0.015) + look, width: s * 0.11 * big, height: s * 0.14 * big), Paint()..color = const Color(0xFF2A0B30));
    canvas.drawCircle(e + Offset(-s * 0.015, -s * 0.03) + look, s * 0.03, Paint()..color = Colors.white);
    canvas.drawCircle(e + Offset(s * 0.03, s * 0.04) + look, s * 0.012, Paint()..color = Colors.white);
    if (pose == LokumPose.sad) {
      // Heavy lids and a worried brow.
      canvas.drawRect(Rect.fromCenter(center: e - Offset(0, s * 0.07), width: s * 0.2, height: s * 0.08), Paint()..color = _l(pink, 0.15));
      canvas.drawLine(e + Offset(-dir * s * 0.08, -s * 0.16), e + Offset(dir * s * 0.06, -s * 0.12), lid);
    }
  }
  for (final dir in [-1.0, 1.0]) {
    canvas.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.3, s * 0.1), width: s * 0.14, height: s * 0.08), Paint()..color = const Color(0xFFFF3B7A).withValues(alpha: 0.55));
  }
  final mouth = Offset(0, s * 0.15);
  const lips = Color(0xFF6A0E2A);
  switch (pose) {
    case LokumPose.wow || LokumPose.scared:
      canvas.drawOval(Rect.fromCenter(center: mouth, width: s * 0.12, height: s * 0.15), Paint()..color = lips);
    case LokumPose.chomp:
      final m = Rect.fromCenter(center: mouth + Offset(0, s * 0.03), width: s * 0.34, height: s * 0.3);
      canvas.drawOval(m, Paint()..color = lips);
      canvas.drawOval(Rect.fromCenter(center: m.center + Offset(0, s * 0.07), width: s * 0.2, height: s * 0.1), Paint()..color = const Color(0xFFFF6A8A));
      canvas.drawRect(Rect.fromLTWH(m.left + s * 0.08, m.top, s * 0.18, s * 0.04), Paint()..color = Colors.white);
    case LokumPose.sad:
      canvas.drawArc(Rect.fromCenter(center: mouth + Offset(0, s * 0.06), width: s * 0.2, height: s * 0.12), pi * 1.15, pi * 0.7, false, lid);
      // A tear.
      final tear = Path()
        ..moveTo(s * 0.2, s * 0.0)
        ..quadraticBezierTo(s * 0.26, s * 0.1, s * 0.2, s * 0.13)
        ..quadraticBezierTo(s * 0.14, s * 0.1, s * 0.2, s * 0.0);
      canvas.drawPath(tear, Paint()..color = const Color(0xFF8FD8FF));
    case LokumPose.sleepy:
      canvas.drawOval(Rect.fromCenter(center: mouth, width: s * 0.08, height: s * 0.06), Paint()..color = lips);
    default:
      final open = pose == LokumPose.cheer || pose == LokumPose.dance;
      final m = Path()
        ..moveTo(mouth.dx - s * 0.12, mouth.dy - s * 0.02)
        ..quadraticBezierTo(mouth.dx, mouth.dy + s * (open ? 0.2 : 0.1), mouth.dx + s * 0.12, mouth.dy - s * 0.02)
        ..close();
      canvas.drawPath(m, Paint()..color = lips);
      if (open) {
        canvas.save();
        canvas.clipPath(m);
        canvas.drawCircle(mouth + Offset(0, s * 0.12), s * 0.07, Paint()..color = const Color(0xFFFF6A8A));
        canvas.restore();
      }
  }
  if (pose == LokumPose.scared) {
    // Hands over the eyes.
    for (final dir in [-1.0, 1.0]) {
      final hand = Rect.fromCenter(center: Offset(dir * s * 0.17, -s * 0.05), width: s * 0.27, height: s * 0.21);
      canvas.drawOval(hand.shift(Offset(0, s * 0.02)), Paint()..color = _d(pink, 0.35).withValues(alpha: 0.5));
      canvas.drawOval(hand, Paint()..shader = ui.Gradient.linear(hand.topCenter, hand.bottomCenter, [_l(pink, 0.25), _d(pink, 0.1)]));
      canvas.drawOval(hand, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..color = _l(pink, 0.6));
    }
  }
  if (pose == LokumPose.point) {
    // The pointing arm, in front: straight out to the side with a hand.
    final dir = pointLeft ? -1.0 : 1.0;
    final armRect = Rect.fromLTRB(dir > 0 ? s * 0.36 : -s * 0.86, -s * 0.02, dir > 0 ? s * 0.86 : -s * 0.36, s * 0.13);
    canvas.drawRRect(RRect.fromRectAndRadius(armRect, Radius.circular(s * 0.075)), arm);
    canvas.drawCircle(Offset(dir * s * 0.88, s * 0.055), s * 0.085, Paint()..color = _l(pink, 0.2));
    canvas.drawCircle(Offset(dir * s * 0.88, s * 0.055), s * 0.085, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02
      ..color = _l(pink, 0.6));
  }
  _paintOutfit(canvas, s, outfit);
  canvas.restore();
}

void _paintOutfit(Canvas canvas, double s, LokumOutfit outfit) {
  if (outfit == LokumOutfit.none) return;
  // Seat each piece snugly on the head.
  final drop = switch (outfit) {
    LokumOutfit.fez || LokumOutfit.janissary => 0.03,
    LokumOutfit.kalpak => 0.04,
    LokumOutfit.moustache => 0.015,
    LokumOutfit.sultan || LokumOutfit.simit => 0.07,
    _ => 0.0,
  };
  canvas.save();
  canvas.translate(0, s * drop);
  if (outfit == LokumOutfit.janissary) {
    canvas.translate(0, -s * 0.44);
    canvas.scale(0.86);
    canvas.translate(0, s * 0.44);
  }
  _paintOutfitShape(canvas, s, outfit);
  canvas.restore();
}

void _paintOutfitShape(Canvas canvas, double s, LokumOutfit outfit) {
  Paint grad(Rect r, List<Color> colors) =>
      Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);
  Paint across(Rect r, List<Color> colors) =>
      Paint()..shader = ui.Gradient.linear(r.centerLeft, r.centerRight, colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);
  const gold = [Color(0xFFFFF1A8), Color(0xFFE2B33C), Color(0xFFB07A1E)];
  switch (outfit) {
    case LokumOutfit.none:
      return;
    case LokumOutfit.fez:
      canvas.save();
      canvas.translate(0, -s * 0.42);
      canvas.rotate(0.12);
      final fez = Path()
        ..moveTo(-s * 0.23, 0)
        ..lineTo(-s * 0.17, -s * 0.32)
        ..lineTo(s * 0.17, -s * 0.32)
        ..lineTo(s * 0.23, 0)
        ..quadraticBezierTo(0, s * 0.06, -s * 0.23, 0)
        ..close();
      canvas.drawPath(fez, across(fez.getBounds(), const [Color(0xFF9E1220), Color(0xFFE8333C), Color(0xFFB8151F), Color(0xFF7A0C16)]));
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.32), width: s * 0.34, height: s * 0.07), Paint()..color = const Color(0xFF8A0E18));
      // The tassel: a cord from the top, hanging over the side.
      canvas.drawPath(
          Path()
            ..moveTo(0, -s * 0.33)
            ..quadraticBezierTo(s * 0.18, -s * 0.36, s * 0.22, -s * 0.2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.022
            ..color = const Color(0xFF1A1018));
      final tassel = Path()
        ..moveTo(s * 0.2, -s * 0.22)
        ..lineTo(s * 0.25, -s * 0.22)
        ..lineTo(s * 0.29, -s * 0.06)
        ..lineTo(s * 0.17, -s * 0.06)
        ..close();
      canvas.drawPath(tassel, Paint()..color = const Color(0xFF1A1018));
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(Offset(s * (0.19 + i * 0.03), -s * 0.18), Offset(s * (0.18 + i * 0.035), -s * 0.07), Paint()
          ..strokeWidth = s * 0.006
          ..color = Colors.white.withValues(alpha: 0.18));
      }
      canvas.restore();
    case LokumOutfit.kalpak:
      final k = Path()
        ..moveTo(-s * 0.27, -s * 0.38)
        ..lineTo(-s * 0.29, -s * 0.7)
        ..quadraticBezierTo(0, -s * 0.78, s * 0.29, -s * 0.7)
        ..lineTo(s * 0.27, -s * 0.38)
        ..quadraticBezierTo(0, -s * 0.32, -s * 0.27, -s * 0.38)
        ..close();
      canvas.drawPath(k, across(k.getBounds(), const [Color(0xFF3A2C24), Color(0xFF6A5444), Color(0xFF4A382C), Color(0xFF2A1E18)]));
      canvas.save();
      canvas.clipPath(k);
      // Curly lamb's wool.
      final curl = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.014
        ..color = const Color(0xFF8A7262).withValues(alpha: 0.7);
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < 7; col++) {
          final x = -s * 0.3 + col * s * 0.09 + (row.isOdd ? s * 0.045 : 0);
          canvas.drawArc(Rect.fromCircle(center: Offset(x, -s * 0.72 + row * s * 0.065), radius: s * 0.028), 0.4, pi * 1.4, false, curl);
        }
      }
      canvas.restore();
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.72), width: s * 0.58, height: s * 0.1), Paint()..color = const Color(0xFF2A1E18).withValues(alpha: 0.6));
    case LokumOutfit.sultan:
      // Red cap peeking out of the top.
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.74), width: s * 0.26, height: s * 0.16), Paint()..color = const Color(0xFFC0182A));
      final turban = Rect.fromCenter(center: Offset(0, -s * 0.56), width: s * 0.66, height: s * 0.38);
      canvas.drawOval(turban, Paint()..shader = ui.Gradient.radial(turban.center + Offset(-s * 0.1, -s * 0.08), s * 0.4, const [Colors.white, Color(0xFFF2EEE6), Color(0xFFC9C1B4)], const [0, 0.6, 1]));
      canvas.save();
      canvas.clipPath(Path()..addOval(turban));
      final wrap = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.014
        ..color = const Color(0xFFB8AE9E);
      for (var i = 0; i < 4; i++) {
        canvas.drawArc(Rect.fromCenter(center: Offset(-s * 0.1 + i * s * 0.1, -s * 0.5), width: s * 0.5, height: s * 0.34), pi * 1.1, pi * 0.55, false, wrap);
      }
      canvas.restore();
      // The plume and its jewel.
      final plume = Path()
        ..moveTo(0, -s * 0.6)
        ..quadraticBezierTo(s * 0.02, -s * 0.78, s * 0.14, -s * 0.88)
        ..quadraticBezierTo(s * 0.09, -s * 0.74, s * 0.05, -s * 0.6)
        ..close();
      canvas.drawPath(plume, grad(plume.getBounds(), const [Colors.white, Color(0xFFE6DCF5)]));
      final jewel = Rect.fromCenter(center: Offset(s * 0.01, -s * 0.58), width: s * 0.13, height: s * 0.15);
      canvas.drawOval(jewel, grad(jewel, gold));
      canvas.drawOval(jewel.deflate(s * 0.025), Paint()..color = const Color(0xFF12A05A));
      canvas.drawCircle(Offset(-s * 0.005, -s * 0.6), s * 0.015, Paint()..color = Colors.white);
      for (final dx in [-0.18, 0.2]) {
        canvas.drawCircle(Offset(dx * s, -s * 0.5), s * 0.022, Paint()..color = const Color(0xFFE2333C));
      }
    case LokumOutfit.janissary:
      // The felt folds over the top and hangs down the back.
      final flap = Path()
        ..moveTo(-s * 0.02, -s * 0.98)
        ..quadraticBezierTo(-s * 0.36, -s * 0.9, -s * 0.46, -s * 0.28)
        ..lineTo(-s * 0.3, -s * 0.3)
        ..quadraticBezierTo(-s * 0.26, -s * 0.78, -s * 0.06, -s * 0.86)
        ..close();
      canvas.drawPath(flap, across(flap.getBounds(), const [Color(0xFFC8C2D2), Color(0xFFF2F0F6)]));
      final cone = Path()
        ..moveTo(-s * 0.22, -s * 0.44)
        ..quadraticBezierTo(-s * 0.16, -s * 0.8, -s * 0.06, -s * 0.96)
        ..quadraticBezierTo(s * 0.02, -s * 1.02, s * 0.06, -s * 0.94)
        ..quadraticBezierTo(s * 0.16, -s * 0.76, s * 0.22, -s * 0.44)
        ..close();
      canvas.drawPath(cone, across(cone.getBounds(), const [Colors.white, Color(0xFFEDEAF2), Color(0xFFC8C2D2)]));
      // The gilded band and the spoon-shaped ornament in front.
      final band = Rect.fromLTRB(-s * 0.25, -s * 0.5, s * 0.25, -s * 0.4);
      canvas.drawRRect(RRect.fromRectAndRadius(band, Radius.circular(s * 0.03)), grad(band, gold));
      final spoon = Rect.fromCenter(center: Offset(0, -s * 0.62), width: s * 0.09, height: s * 0.22);
      canvas.drawOval(spoon, grad(spoon, gold));
      canvas.drawOval(spoon.deflate(s * 0.02), Paint()..color = const Color(0xFFB07A1E).withValues(alpha: 0.6));
      for (final dx in [-0.15, 0.0, 0.15]) {
        canvas.drawCircle(Offset(dx * s, -s * 0.45), s * 0.016, Paint()..color = const Color(0xFFE2333C));
      }
    case LokumOutfit.tulip:
      canvas.save();
      canvas.translate(-s * 0.28, -s * 0.36);
      canvas.rotate(-0.35);
      canvas.drawLine(Offset.zero, Offset(0, -s * 0.18), Paint()
        ..strokeWidth = s * 0.025
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2F8F3A));
      canvas.drawPath(
          Path()
            ..moveTo(0, -s * 0.02)
            ..quadraticBezierTo(s * 0.14, -s * 0.04, s * 0.12, -s * 0.18)
            ..quadraticBezierTo(s * 0.04, -s * 0.1, 0, -s * 0.02),
          Paint()..color = const Color(0xFF3FBF4A));
      final cup = Path()
        ..moveTo(-s * 0.09, -s * 0.3)
        ..lineTo(-s * 0.05, -s * 0.24)
        ..lineTo(0, -s * 0.33)
        ..lineTo(s * 0.05, -s * 0.24)
        ..lineTo(s * 0.09, -s * 0.3)
        ..quadraticBezierTo(s * 0.1, -s * 0.16, 0, -s * 0.15)
        ..quadraticBezierTo(-s * 0.1, -s * 0.16, -s * 0.09, -s * 0.3)
        ..close();
      canvas.drawPath(cup, across(cup.getBounds(), const [Color(0xFFB0101E), Color(0xFFFF4A52), Color(0xFFC8141F)]));
      canvas.drawLine(Offset(0, -s * 0.3), Offset(0, -s * 0.17), Paint()
        ..strokeWidth = s * 0.01
        ..color = const Color(0xFF8A0A16).withValues(alpha: 0.6));
      canvas.restore();
    case LokumOutfit.nazar:
      canvas.drawPath(
          Path()
            ..moveTo(-s * 0.4, s * 0.18)
            ..quadraticBezierTo(0, s * 0.42, s * 0.4, s * 0.18),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.015
            ..color = const Color(0xFF7A4A10));
      final bead = Offset(0, s * 0.34);
      canvas.drawCircle(bead, s * 0.1, Paint()..shader = ui.Gradient.radial(bead + Offset(-s * 0.03, -s * 0.03), s * 0.12, const [Color(0xFF3A7BFF), Color(0xFF0B2E9E)]));
      canvas.drawCircle(bead, s * 0.066, Paint()..color = Colors.white);
      canvas.drawCircle(bead, s * 0.046, Paint()..color = const Color(0xFF5EC8FF));
      canvas.drawCircle(bead, s * 0.024, Paint()..color = const Color(0xFF0A0A1A));
      canvas.drawCircle(bead + Offset(-s * 0.04, -s * 0.05), s * 0.018, Paint()..color = Colors.white.withValues(alpha: 0.8));
    case LokumOutfit.moustache:
      for (final dir in [-1.0, 1.0]) {
        final m = Path()
          ..moveTo(0, s * 0.06)
          ..cubicTo(dir * s * 0.08, s * 0.02, dir * s * 0.16, s * 0.04, dir * s * 0.22, s * 0.08)
          ..cubicTo(dir * s * 0.27, s * 0.1, dir * s * 0.31, s * 0.06, dir * s * 0.29, s * 0.01)
          ..cubicTo(dir * s * 0.33, s * 0.06, dir * s * 0.3, s * 0.15, dir * s * 0.22, s * 0.14)
          ..cubicTo(dir * s * 0.14, s * 0.13, dir * s * 0.06, s * 0.13, 0, s * 0.11)
          ..close();
        canvas.drawPath(m, Paint()..color = const Color(0xFF2A1A14));
      }
      canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.08, s * 0.06), width: s * 0.1, height: s * 0.025), Paint()..color = Colors.white.withValues(alpha: 0.2));
    case LokumOutfit.tulipCrown:
      // A gilded band round the head with three tulips standing on it.
      final band = Rect.fromCenter(center: Offset(0, -s * 0.36), width: s * 0.62, height: s * 0.3);
      canvas.drawArc(band, pi * 1.08, pi * 0.84, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(band.centerLeft, band.centerRight, gold, const [0, 0.5, 1]));
      for (final (dx, h) in [(-0.2, 0.1), (0.0, 0.16), (0.2, 0.1)]) {
        final base = Offset(dx * s, -s * 0.44 - (dx == 0 ? s * 0.06 : 0));
        canvas.drawLine(base, base - Offset(0, s * h), Paint()
          ..strokeWidth = s * 0.025
          ..color = const Color(0xFF2F8F3A));
        final c = base - Offset(0, s * (h + 0.04));
        final cup = Path()
          ..moveTo(c.dx - s * 0.055, c.dy - s * 0.05)
          ..lineTo(c.dx - s * 0.025, c.dy - s * 0.015)
          ..lineTo(c.dx, c.dy - s * 0.06)
          ..lineTo(c.dx + s * 0.025, c.dy - s * 0.015)
          ..lineTo(c.dx + s * 0.055, c.dy - s * 0.05)
          ..quadraticBezierTo(c.dx + s * 0.06, c.dy + s * 0.04, c.dx, c.dy + s * 0.04)
          ..quadraticBezierTo(c.dx - s * 0.06, c.dy + s * 0.04, c.dx - s * 0.055, c.dy - s * 0.05)
          ..close();
        canvas.drawPath(cup, Paint()..color = dx == 0 ? const Color(0xFFE2333C) : const Color(0xFFFF6A9A));
      }
      for (final dx in [-0.1, 0.1]) {
        canvas.drawCircle(Offset(dx * s, -s * 0.5), s * 0.02, Paint()..color = const Color(0xFF2EA8FF));
      }
    case LokumOutfit.captain:
      // A white cap with a black peak and a gold anchor.
      final crown = Rect.fromCenter(center: Offset(0, -s * 0.5), width: s * 0.66, height: s * 0.24);
      canvas.drawOval(crown, Paint()..shader = ui.Gradient.linear(crown.topCenter, crown.bottomCenter, const [Colors.white, Color(0xFFDADDE6)]));
      final band = Rect.fromLTRB(-s * 0.26, -s * 0.47, s * 0.26, -s * 0.38);
      canvas.drawRect(band, Paint()..color = const Color(0xFF1E2A4A));
      canvas.drawLine(Offset(band.left, band.top), Offset(band.right, band.top), Paint()
        ..strokeWidth = s * 0.015
        ..color = const Color(0xFFE2B33C));
      final peak = Path()
        ..moveTo(-s * 0.26, -s * 0.39)
        ..quadraticBezierTo(0, -s * 0.28, s * 0.26, -s * 0.39)
        ..quadraticBezierTo(0, -s * 0.33, -s * 0.26, -s * 0.39)
        ..close();
      canvas.drawPath(peak, Paint()..color = const Color(0xFF14141E));
      final a = Offset(0, -s * 0.54);
      final anchor = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD4A017);
      canvas.drawLine(a - Offset(0, s * 0.05), a + Offset(0, s * 0.05), anchor);
      canvas.drawLine(a - Offset(s * 0.03, s * 0.025), a + Offset(s * 0.03, -s * 0.025), anchor);
      canvas.drawArc(Rect.fromCircle(center: a + Offset(0, s * 0.015), radius: s * 0.04), 0.3, pi - 0.6, false, anchor);
    case LokumOutfit.apron:
      // A white apron tied at the waist with a coffee cup on it.
      final apron = Path()
        ..moveTo(-s * 0.24, s * 0.2)
        ..lineTo(s * 0.24, s * 0.2)
        ..lineTo(s * 0.3, s * 0.5)
        ..quadraticBezierTo(0, s * 0.56, -s * 0.3, s * 0.5)
        ..close();
      canvas.drawPath(apron, Paint()..shader = ui.Gradient.linear(Offset(0, s * 0.2), Offset(0, s * 0.54), const [Colors.white, Color(0xFFE6E2EE)]));
      canvas.drawLine(Offset(-s * 0.46, s * 0.18), Offset(s * 0.46, s * 0.18), Paint()
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF8A4A2A));
      final cup = Rect.fromCenter(center: Offset(0, s * 0.37), width: s * 0.13, height: s * 0.1);
      canvas.drawRRect(RRect.fromRectAndCorners(cup, bottomLeft: Radius.circular(s * 0.04), bottomRight: Radius.circular(s * 0.04)), Paint()..color = const Color(0xFF6A3418));
      canvas.drawArc(Rect.fromCircle(center: cup.centerRight, radius: s * 0.03), -pi / 2, pi, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.015
        ..color = const Color(0xFF6A3418));
      for (final dx in [-0.025, 0.025]) {
        canvas.drawPath(
            Path()
              ..moveTo(dx * s, s * 0.31)
              ..quadraticBezierTo(dx * s + s * 0.02, s * 0.28, dx * s, s * 0.25),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.012
              ..color = const Color(0xFFB8A8A0));
      }
    case LokumOutfit.guide:
      // A sand-coloured bucket hat with a red band and a little flag.
      final brim = Rect.fromCenter(center: Offset(0, -s * 0.42), width: s * 0.78, height: s * 0.14);
      canvas.drawOval(brim, Paint()..color = const Color(0xFFC8A46A));
      final crown = Path()
        ..moveTo(-s * 0.26, -s * 0.44)
        ..quadraticBezierTo(-s * 0.26, -s * 0.72, 0, -s * 0.72)
        ..quadraticBezierTo(s * 0.26, -s * 0.72, s * 0.26, -s * 0.44)
        ..close();
      canvas.drawPath(crown, Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.72), Offset(0, -s * 0.44), const [Color(0xFFF0D8A8), Color(0xFFC8A46A)]));
      canvas.drawRect(Rect.fromLTRB(-s * 0.26, -s * 0.52, s * 0.26, -s * 0.45), Paint()..color = const Color(0xFFE2333C));
      canvas.drawLine(Offset(s * 0.18, -s * 0.5), Offset(s * 0.3, -s * 0.86), Paint()
        ..strokeWidth = s * 0.018
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6A4A2A));
      final flag = Path()..addPolygon([Offset(s * 0.3, -s * 0.86), Offset(s * 0.46, -s * 0.8), Offset(s * 0.27, -s * 0.74)], true);
      canvas.drawPath(flag, Paint()..color = const Color(0xFFE2333C));
      canvas.drawCircle(Offset(s * 0.34, -s * 0.8), s * 0.022, Paint()..color = Colors.white);
    case LokumOutfit.simitNecklace:
      canvas.drawPath(
          Path()
            ..moveTo(-s * 0.4, s * 0.18)
            ..quadraticBezierTo(0, s * 0.42, s * 0.4, s * 0.18),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.015
            ..color = const Color(0xFF7A4A10));
      final c = Offset(0, s * 0.36);
      canvas.drawCircle(c, s * 0.1, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07
        ..shader = ui.Gradient.radial(c + Offset(-s * 0.03, -s * 0.03), s * 0.15, const [Color(0xFFE8A050), Color(0xFF8A4416)]));
      final rnd = Random(3);
      for (var i = 0; i < 12; i++) {
        final a = rnd.nextDouble() * pi * 2;
        canvas.drawOval(Rect.fromCenter(center: c + Offset(cos(a), sin(a)) * s * (0.08 + rnd.nextDouble() * 0.04), width: s * 0.018, height: s * 0.01), Paint()..color = const Color(0xFFFFF0C8));
      }
    case LokumOutfit.simit:
      // A cloth pad, the round tray, and the simits piled on it.
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.47), width: s * 0.4, height: s * 0.1), Paint()..color = const Color(0xFFE8E2F0));
      final tray = Rect.fromCenter(center: Offset(0, -s * 0.54), width: s * 0.92, height: s * 0.16);
      canvas.drawOval(tray.shift(Offset(0, s * 0.03)), Paint()..color = const Color(0xFF7A4E1E));
      canvas.drawOval(tray, across(tray, const [Color(0xFFB07A3A), Color(0xFFE8B868), Color(0xFFA06A2A)]));
      void simit(Offset c) {
        final ring = Rect.fromCenter(center: c, width: s * 0.3, height: s * 0.13);
        canvas.drawOval(ring, Paint()..shader = ui.Gradient.radial(c + Offset(-s * 0.04, -s * 0.03), s * 0.2, const [Color(0xFFE8A050), Color(0xFFB0601E), Color(0xFF6A3410)], const [0, 0.6, 1]));
        canvas.drawOval(Rect.fromCenter(center: c + Offset(0, s * 0.005), width: s * 0.12, height: s * 0.04), Paint()..color = const Color(0xFF5A2A0C));
        final seed = Paint()..color = const Color(0xFFFFF0C8);
        final r = Random((c.dx * 100).round());
        for (var i = 0; i < 9; i++) {
          final a = r.nextDouble() * pi * 2;
          final d = 0.6 + r.nextDouble() * 0.35;
          canvas.drawOval(Rect.fromCenter(center: c + Offset(cos(a) * s * 0.14 * d, sin(a) * s * 0.06 * d), width: s * 0.018, height: s * 0.01), seed);
        }
      }

      simit(Offset(-s * 0.2, -s * 0.6));
      simit(Offset(s * 0.2, -s * 0.6));
      simit(Offset(0, -s * 0.68));
  }
}

// ---------------------------------------- the pieces of chapters 7 to 12 --

/// Chocolate spreading over a cell: Ekşi Limon's bitter cocoa.
void paintChocolate(Canvas canvas, Rect cell) {
  final s = cell.width;
  final r = cell.deflate(s * 0.04);
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.18));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.35));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.radial(r.topLeft + Offset(s * 0.3, s * 0.3), s, const [Color(0xFF9A5A3A), Color(0xFF5A2A14), Color(0xFF3A1808)], const [0, 0.55, 1]));
  // Squares pressed in, like a bar.
  for (var i = 0; i < 2; i++) {
    for (var k = 0; k < 2; k++) {
      final q = Rect.fromLTWH(r.left + s * (0.14 + i * 0.38), r.top + s * (0.14 + k * 0.38), s * 0.3, s * 0.3);
      canvas.drawRRect(RRect.fromRectAndRadius(q, Radius.circular(s * 0.05)), Paint()..color = const Color(0xFF6A3418));
      canvas.drawLine(q.topLeft + Offset(s * 0.04, s * 0.03), q.topRight + Offset(-s * 0.04, s * 0.03), Paint()
        ..strokeWidth = s * 0.03
        ..color = const Color(0xFFB07A50).withValues(alpha: 0.7));
    }
  }
  // Drips over the bottom edge.
  for (final (dx, len) in [(0.25, 0.14), (0.62, 0.2)]) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + s * dx, r.bottom - s * 0.06, s * 0.1, s * len), Radius.circular(s * 0.05)), Paint()..color = const Color(0xFF4A2010));
  }
}

/// A pomegranate to bring down to the bottom.
void paintPomegranate(Canvas canvas, Rect cell) {
  final s = cell.width;
  final c = cell.center + Offset(0, s * 0.04);
  canvas.drawOval(Rect.fromCenter(center: c + Offset(0, s * 0.34), width: s * 0.6, height: s * 0.12), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawCircle(c, s * 0.34, Paint()..shader = ui.Gradient.radial(c - Offset(s * 0.12, s * 0.12), s * 0.5, const [Color(0xFFFF8A8A), Color(0xFFD81E3C), Color(0xFF8A0A1E)], const [0, 0.55, 1]));
  final crown = Path()
    ..moveTo(c.dx - s * 0.12, c.dy - s * 0.3)
    ..lineTo(c.dx - s * 0.14, c.dy - s * 0.44)
    ..lineTo(c.dx - s * 0.05, c.dy - s * 0.36)
    ..lineTo(c.dx, c.dy - s * 0.46)
    ..lineTo(c.dx + s * 0.05, c.dy - s * 0.36)
    ..lineTo(c.dx + s * 0.14, c.dy - s * 0.44)
    ..lineTo(c.dx + s * 0.12, c.dy - s * 0.3)
    ..close();
  canvas.drawPath(crown, Paint()..color = const Color(0xFF9A0A22));
  canvas.drawOval(Rect.fromCenter(center: c - Offset(s * 0.13, s * 0.12), width: s * 0.16, height: s * 0.1), Paint()..color = Colors.white.withValues(alpha: 0.5));
  final seeds = Random(2);
  for (var i = 0; i < 4; i++) {
    canvas.drawCircle(c + Offset((seeds.nextDouble() - 0.3) * s * 0.3, (seeds.nextDouble() - 0.2) * s * 0.3), s * 0.025, Paint()..color = const Color(0xFFFFC0C8).withValues(alpha: 0.8));
  }
}

/// A conveyor tile: a dark belt with chevrons pointing [dir] (+1 right).
void paintBelt(Canvas canvas, Rect cell, {double dir = 1}) {
  final s = cell.width;
  canvas.drawRect(cell, Paint()..shader = ui.Gradient.linear(cell.topCenter, cell.bottomCenter, const [Color(0xFF3A3A50), Color(0xFF22222E), Color(0xFF3A3A50)], const [0, 0.5, 1]));
  for (final y in [cell.top + s * 0.05, cell.bottom - s * 0.05]) {
    canvas.drawLine(Offset(cell.left, y), Offset(cell.right, y), Paint()
      ..strokeWidth = s * 0.06
      ..color = const Color(0xFFFFC21A));
  }
  for (final x in [0.3, 0.7]) {
    final cx = cell.left + s * x;
    canvas.drawPath(Path()
      ..moveTo(cx - dir * s * 0.08, cell.center.dy - s * 0.16)
      ..lineTo(cx + dir * s * 0.08, cell.center.dy)
      ..lineTo(cx - dir * s * 0.08, cell.center.dy + s * 0.16), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8A8AA8));
  }
}

/// A layered cake filling [r] (two cells square on the board); [layers]
/// tiers left (1..3).
void paintCake(Canvas canvas, Rect r, {int layers = 3}) {
  final s = r.width;
  canvas.drawOval(Rect.fromCenter(center: Offset(r.center.dx, r.bottom - s * 0.08), width: s * 0.96, height: s * 0.16), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawOval(Rect.fromCenter(center: Offset(r.center.dx, r.bottom - s * 0.1), width: s * 0.92, height: s * 0.14), Paint()..color = const Color(0xFFE6E6F0));
  const sponge = [Color(0xFFFFD8A0), Color(0xFFFFB0D0), Color(0xFFE8C090)];
  const cream = [Color(0xFFFFFFFF), Color(0xFFFF7AB8), Color(0xFF8A4A2A)];
  const icing = [Color(0xFFFF7AB8), Color(0xFFFFFFFF), Color(0xFFFFFFFF)];
  for (var i = 0; i < layers; i++) {
    final tw = s * (0.84 - i * 0.2);
    final th = s * 0.24;
    final tier = Rect.fromCenter(center: Offset(r.center.dx, r.bottom - s * 0.2 - i * th), width: tw, height: th);
    canvas.drawRRect(RRect.fromRectAndRadius(tier, Radius.circular(s * 0.04)), Paint()..color = sponge[i]);
    canvas.drawRect(Rect.fromLTWH(tier.left, tier.center.dy - s * 0.015, tier.width, s * 0.03), Paint()..color = cream[i].withValues(alpha: 0.7));
    final drip = Path()..moveTo(tier.left, tier.top);
    for (var k = 0; k <= 6; k++) {
      final x = tier.left + tier.width * k / 6;
      drip.lineTo(x, tier.top + (k.isEven ? s * 0.07 : s * 0.035));
    }
    drip
      ..lineTo(tier.right, tier.top - s * 0.01)
      ..lineTo(tier.left, tier.top - s * 0.01)
      ..close();
    canvas.drawPath(drip, Paint()..color = icing[i]);
  }
  final top = r.bottom - s * 0.2 - (layers - 1) * s * 0.24 - s * 0.12;
  canvas.drawCircle(Offset(r.center.dx, top - s * 0.04), s * 0.06, Paint()..color = const Color(0xFFE2333C));
  canvas.drawCircle(Offset(r.center.dx - s * 0.02, top - s * 0.06), s * 0.018, Paint()..color = Colors.white.withValues(alpha: 0.7));
}

/// A Balat door painted [color]: only a match of that colour beside it
/// opens it.
void paintDoor(Canvas canvas, Rect cell, Color color, {bool open = false}) {
  final s = cell.width;
  final r = cell.deflate(s * 0.06);
  final arch = RRect.fromRectAndCorners(r, topLeft: Radius.circular(s * 0.4), topRight: Radius.circular(s * 0.4), bottomLeft: Radius.circular(s * 0.06), bottomRight: Radius.circular(s * 0.06));
  canvas.drawRRect(arch.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.35));
  canvas.drawRRect(arch, Paint()..color = const Color(0xFFF2E6D8));
  final leaf = arch.deflate(s * 0.07);
  if (open) {
    canvas.drawRRect(leaf, Paint()..color = const Color(0xFF2A1438));
    canvas.drawPath(Path()..addPolygon([leaf.outerRect.topLeft + Offset(0, s * 0.1), leaf.outerRect.topLeft + Offset(s * 0.2, s * 0.18), leaf.outerRect.bottomLeft + Offset(s * 0.2, -s * 0.04), leaf.outerRect.bottomLeft], true),
        Paint()..color = color);
    paintSparkle(canvas, leaf.outerRect.center + Offset(s * 0.08, 0), s * 0.14, const Color(0xFFFFE066));
    return;
  }
  canvas.drawRRect(leaf, Paint()..shader = ui.Gradient.linear(leaf.outerRect.topLeft, leaf.outerRect.bottomRight, [Color.lerp(color, Colors.white, 0.25)!, Color.lerp(color, Colors.black, 0.2)!]));
  final panel = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = Color.lerp(color, Colors.black, 0.35)!;
  canvas.drawLine(Offset(leaf.outerRect.center.dx, leaf.top + s * 0.1), Offset(leaf.outerRect.center.dx, leaf.bottom), panel);
  for (final dx in [-1.0, 1.0]) {
    canvas.drawRect(Rect.fromCenter(center: leaf.outerRect.center + Offset(dx * s * 0.15, s * 0.14), width: s * 0.18, height: s * 0.26), panel);
  }
  canvas.drawCircle(leaf.outerRect.center + Offset(s * 0.06, s * 0.0), s * 0.035, Paint()..color = const Color(0xFFFFE27A));
}

/// A slice of lemon Ekşi Limon threw: match beside it to wash it away.
void paintLemonSlice(Canvas canvas, Rect cell, {double turn = 0}) {
  final s = cell.width;
  final c = cell.center;
  canvas.drawCircle(c + Offset(0, s * 0.05), s * 0.4, Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawCircle(c, s * 0.4, Paint()..color = const Color(0xFFFFC414));
  canvas.drawCircle(c, s * 0.35, Paint()..color = const Color(0xFFFFF6C8));
  for (var i = 0; i < 8; i++) {
    final a = turn + i * pi / 4;
    final seg = Path()
      ..moveTo(c.dx + cos(a + 0.08) * s * 0.04, c.dy + sin(a + 0.08) * s * 0.04)
      ..arcTo(Rect.fromCircle(center: c, radius: s * 0.31), a + 0.1, pi / 4 - 0.2, false)
      ..close();
    canvas.drawPath(seg, Paint()..color = const Color(0xFFFFE04A));
  }
  canvas.drawCircle(c, s * 0.05, Paint()..color = const Color(0xFFFFF6C8));
  canvas.drawArc(Rect.fromCircle(center: c, radius: s * 0.38), pi * 1.1, pi * 0.5, false, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = Colors.white.withValues(alpha: 0.6));
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

  ui.Image _render(void Function(Canvas canvas, Rect r) paint, {int cells = 1}) {
    final side = cell * (cells + 2 * pad);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paint(canvas, Rect.fromLTWH(cell * pad + 1, cell * pad + 1, cell - 2, cell - 2));
    final px = max(1, (side * dpr).ceil());
    return recorder.endRecording().toImageSync(px, px);
  }

  ui.Image piece(SugarPiece p) {
    if (p.fruit) return _images['fruit'] ??= _render(paintPomegranate);
    if (p.isBomb && p.special == Special.none) return _images[('bomb', p.color)] ??= _render((canvas, r) => paintTimedBomb(canvas, r, p.color));
    final key = p.isPrism ? (Special.prism, null) : (p.special, p.color);
    return _images[key] ??= _render((canvas, r) => paintSugarPiece(canvas, r, p.color, p.special));
  }

  ui.Image ice(int layers, int variant) => _images[('ice', layers.clamp(1, 2), variant % 2)] ??= _render((canvas, r) => paintIce(canvas, r, layers: layers, seed: variant % 2));

  ui.Image box(int layers) => _images[('box', layers.clamp(1, 2))] ??= _render((canvas, r) => paintCandyBox(canvas, r, layers: layers));

  ui.Image get chains => _images['chains'] ??= _render(paintChains);

  ui.Image get chocolate => _images['choco'] ??= _render(paintChocolate);

  ui.Image get lemonSlice => _images['slice'] ??= _render(paintLemonSlice);

  ui.Image door(SugarColor color) => _images[('door', color)] ??= _render((canvas, r) => paintDoor(canvas, r, sugarColors[color]!));

  ui.Image belt(int dir) => _images[('belt', dir)] ??= _render((canvas, r) => paintBelt(canvas, r.inflate(1), dir: dir.toDouble()));

  /// A cake two cells square: draw it with [drawCake].
  ui.Image cake(int layers) => _images[('cake', layers.clamp(1, 3))] ??= _render((canvas, r) => paintCake(canvas, Rect.fromLTWH(r.left, r.top, r.width * 2 + 2, r.height * 2 + 2), layers: layers), cells: 2);

  /// Draws a two-cell cake whose top-left cell starts at [origin].
  void drawCake(Canvas canvas, int layers, Offset origin) {
    final img = cake(layers);
    final side = cell * (2 + 2 * pad);
    final dst = Rect.fromLTWH(origin.dx - cell * pad, origin.dy - cell * pad, side, side);
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), dst, Paint()..filterQuality = FilterQuality.low);
  }

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
