import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/special_days.dart' show LokumProp;
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
  guide(0, 'outfitGuide'),

  /// A golden crown with a lemon jewel, for beating Ekşi Limon.
  lemonCrown(0, 'outfitLemonCrown'),

  /// A zeybek's tall börk wound with a tasselled yemeni, and his sash.
  zeybek(150),

  /// Nasreddin Hoca's great kavuk and white beard.
  hoca(200),

  /// Weekly event prizes: a mehter's cap, davul and stick...
  mehter(0, 'outfitMehter'),

  /// ...a Black Sea kukulete and a kemençe...
  karadeniz(0, 'outfitKaradeniz'),

  /// ...a towel, a peştamal, nalın and a silver tas...
  hamam(0, 'outfitHamam'),

  /// ...and the Maraş ice-cream seller's vest, fez and long paddle.
  dondurma(0, 'outfitDondurma'),

  /// A red halay handkerchief, from Şeker Bayramı.
  halay(0, 'outfitHalay'),

  /// An oyalı yazma, from Hıdırellez.
  yazma(0, 'outfitYazma');

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

/// A closed shape through [pts] with straight sides and corners rounded by
/// [r].
Path _roundedBy(List<Offset> pts, double r) {
  final p = Path();
  for (var i = 0; i < pts.length; i++) {
    final a = pts[(i - 1 + pts.length) % pts.length], c = pts[i], b = pts[(i + 1) % pts.length];
    final start = c + (a - c) / (a - c).distance * min(r, (a - c).distance / 2);
    final end = c + (b - c) / (b - c).distance * min(r, (b - c).distance / 2);
    i == 0 ? p.moveTo(start.dx, start.dy) : p.lineTo(start.dx, start.dy);
    p.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
  }
  return p..close();
}

/// Lokum's body, which no pose changes: the jelly cube, its pistachios and
/// powdered sugar, [s] tall in [pink]. Recorded once per size and colour
/// and replayed, since he is drawn every frame he moves.
final Map<(double, int), ui.Picture> _bodies = {};

ui.Picture _lokumBody(double s, Color pink) {
  final key = (s, pink.toARGB32());
  final hit = _bodies[key];
  if (hit != null) return hit;
  if (_bodies.length >= 24) _bodies.remove(_bodies.keys.first)?.dispose();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // The cube, seen a little from above: a front face and the sugared top,
  // in the same bounds the round sweet had, so every outfit still sits.
  final body = _roundedBy([
    Offset(-s * 0.37, -s * 0.46),
    Offset(s * 0.37, -s * 0.46),
    Offset(s * 0.5, -s * 0.25),
    Offset(s * 0.48, s * 0.52),
    Offset(-s * 0.48, s * 0.52),
    Offset(-s * 0.5, -s * 0.25),
  ], s * 0.11);
  canvas.drawPath(body, Paint()..shader = ui.Gradient.radial(Offset(-s * 0.12, s * 0.05), s * 0.75, [_l(pink, 0.4), pink, _d(pink, 0.28)], const [0, 0.55, 1]));
  canvas.save();
  canvas.clipPath(body);
  // Light through the jelly; the right side turning away; the bottom.
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-s * 0.34, -s * 0.12, s * 0.3, s * 0.42), Radius.circular(s * 0.12)), Paint()
    ..color = _l(pink, 0.55).withValues(alpha: 0.35)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.07));
  canvas.drawRect(Rect.fromLTRB(s * 0.3, -s * 0.5, s * 0.55, s * 0.6), Paint()
    ..shader = ui.Gradient.linear(Offset(s * 0.3, 0), Offset(s * 0.52, 0), [_d(pink, 0.3).withValues(alpha: 0), _d(pink, 0.3).withValues(alpha: 0.55)]));
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.6), width: s * 1.2, height: s * 0.4), Paint()
    ..color = _d(pink, 0.45).withValues(alpha: 0.35)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.07));
  // Pistachios set in the jelly, purple skin and all.
  for (final (x, y, w, turn) in const [
    (-0.34, 0.34, 0.12, -0.4),
    (-0.2, 0.44, 0.07, 0.9),
    (0.3, 0.38, 0.1, 0.5),
    (0.04, 0.44, 0.08, 0.1),
    (0.18, 0.31, 0.06, 2.0),
    (0.41, -0.1, 0.07, 1.1),
    (0.4, 0.14, 0.06, -0.6),
    (-0.42, -0.08, 0.065, -0.9),
    (-0.42, 0.14, 0.05, 0.4),
  ]) {
    canvas.save();
    canvas.translate(x * s, y * s);
    canvas.rotate(turn);
    final k = w * s;
    final chunk = _roundedBy([Offset(-k * 0.5, -k * 0.05), Offset(-k * 0.2, -k * 0.32), Offset(k * 0.25, -k * 0.28), Offset(k * 0.5, k * 0.02), Offset(k * 0.18, k * 0.3), Offset(-k * 0.3, k * 0.24)], k * 0.12);
    canvas.drawPath(chunk.shift(Offset(k * 0.04, k * 0.06)), Paint()..color = const Color(0xFF8A3A6A).withValues(alpha: 0.5));
    canvas.drawPath(chunk, Paint()..shader = ui.Gradient.radial(Offset(-k * 0.15, -k * 0.1), k * 0.6, const [Color(0xFFDDF3A0), Color(0xFF9CCB5A), Color(0xFF5E9A3A)], const [0, 0.55, 1]));
    canvas.restore();
  }
  // The sugared top, its powder spilling over the front edge.
  final top = _roundedBy([Offset(-s * 0.37, -s * 0.46), Offset(s * 0.37, -s * 0.46), Offset(s * 0.5, -s * 0.25), Offset(-s * 0.5, -s * 0.25)], s * 0.1);
  final drip = Path()..moveTo(-s * 0.52, -s * 0.3);
  for (var i = 0; i <= 12; i++) {
    drip.lineTo(-s * 0.52 + i * s * 1.04 / 12, -s * 0.25 + s * (i.isEven ? 0.015 : 0.05 + 0.02 * sin(i * 1.7)));
  }
  drip
    ..lineTo(s * 0.52, -s * 0.3)
    ..close();
  final sugar = Path.combine(PathOperation.union, top, drip);
  canvas.drawPath(sugar.shift(Offset(0, s * 0.015)), Paint()..color = _d(pink, 0.2).withValues(alpha: 0.35));
  canvas.drawPath(sugar, Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.46), Offset(0, -s * 0.2), const [Colors.white, Color(0xFFFFF0F6), Color(0xFFFFDDEB)], const [0, 0.6, 1]));
  final rnd = Random(7);
  for (var i = 0; i < 90; i++) {
    final p = Offset((rnd.nextDouble() - 0.5) * s * 0.8, -s * 0.44 + rnd.nextDouble() * s * 0.2);
    canvas.drawCircle(p, s * (0.003 + rnd.nextDouble() * 0.005), Paint()..color = const Color(0xFFF2B8D0).withValues(alpha: 0.6));
  }
  // Powder dusted down the front: a haze that thins out, and fine grains.
  canvas.drawRect(Rect.fromLTRB(-s * 0.55, -s * 0.26, s * 0.55, s * 0.55), Paint()
    ..shader = ui.Gradient.linear(Offset(0, -s * 0.24), Offset(0, s * 0.2), [Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0)]));
  for (final dir in [-1.0, 1.0]) {
    canvas.drawRect(Rect.fromLTRB(dir < 0 ? -s * 0.55 : s * 0.4, -s * 0.26, dir < 0 ? -s * 0.4 : s * 0.55, s * 0.55), Paint()
      ..shader = ui.Gradient.linear(Offset(dir * s * 0.52, 0), Offset(dir * s * 0.4, 0), [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0)]));
  }
  for (var i = 0; i < 160; i++) {
    final t = rnd.nextDouble();
    final p = Offset((rnd.nextDouble() - 0.5) * s * 0.96, -s * 0.2 + t * t * s * 0.74);
    canvas.drawCircle(p, s * (0.003 + rnd.nextDouble() * 0.004), Paint()..color = Colors.white.withValues(alpha: 0.4 + 0.5 * (1 - t)));
  }
  // Gloss.
  canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.3, -s * 0.13), width: s * 0.14, height: s * 0.06), Paint()..color = Colors.white.withValues(alpha: 0.55));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-s * 0.46, -s * 0.12, s * 0.035, s * 0.42), Radius.circular(s * 0.02)), Paint()..color = Colors.white.withValues(alpha: 0.28));
  canvas.restore();
  canvas.drawPath(body, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.022
    ..color = _l(pink, 0.55));
  return _bodies[key] = recorder.endRecording();
}

/// Lokum, the mascot: a cube of rose Turkish delight, set with pistachios
/// and dusted with powdered sugar, [size] tall around [c]; [hop] 0..1 lifts
/// and squashes it a little, [beat] (0..1, looping) sways the dance,
/// [pointLeft] turns the pointing arm; [props] are what he carries on a
/// special day; [tone] is the jelly's colour (rose, unless another lokum).
void paintLokum(Canvas canvas, Offset c, double size,
    {LokumPose pose = LokumPose.happy, double hop = 0, double beat = 0, bool pointLeft = false, LokumOutfit outfit = LokumOutfit.none, List<LokumProp> props = const [], Color tone = const Color(0xFFFF5FA6)}) {
  final s = size;
  canvas.save();
  canvas.translate(c.dx, c.dy - s * 0.12 * sin(hop * pi));
  if (pose == LokumPose.dance) canvas.rotate(sin(beat * pi * 2) * 0.16);
  final droop = pose == LokumPose.sad ? 0.06 : 0.0;
  canvas.scale(1 + 0.05 * sin(hop * pi) + droop, 1 - 0.05 * sin(hop * pi) - droop);
  final pink = tone;
  // A shadow, and the little heap of powdered sugar it sits in.
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.56), width: s * 1.0, height: s * 0.16), Paint()
    ..color = Colors.black.withValues(alpha: 0.3)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.53), width: s * 0.92, height: s * 0.1), Paint()
    ..color = Colors.white.withValues(alpha: 0.9)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.012));
  final arm = Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.2), Offset(0, s * 0.4), [_l(pink, 0.3), _d(pink, 0.15)]);
  // Where each hand ends up (-1 left, 1 right), for what he holds.
  final hands = <double, Offset>{};
  void drawArm(double dir, {required double at, required double turn, double reach = 0.34}) {
    final r = s * reach * 0.8;
    hands[dir] = Offset(dir * s * 0.5 + r * sin(dir * turn), at - r * cos(turn));
    canvas.save();
    canvas.translate(dir * s * 0.5, at);
    canvas.rotate(dir * turn);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -s * reach * 0.3), width: s * 0.17, height: s * reach), Radius.circular(s * 0.09)), arm);
    canvas.restore();
  }

  // Arms behind the body (those in front come after the face).
  for (final dir in [-1.0, 1.0]) {
    switch (pose) {
      // Raised arms lean out, clear of the cube's top corners.
      case LokumPose.cheer:
        drawArm(dir, at: -s * 0.04, turn: 0.3);
      case LokumPose.wink when dir > 0:
        drawArm(dir, at: -s * 0.04, turn: 0.3);
      case LokumPose.dance:
        drawArm(dir, at: s * 0.02, turn: 0.45 + 0.45 * sin(beat * pi * 2 + (dir > 0 ? pi : 0)));
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
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(dir * s * 0.22, s * 0.5), width: s * 0.26, height: s * 0.12), Radius.circular(s * 0.06)), Paint()..color = _d(pink, 0.18));
  }
  canvas.drawPicture(_lokumBody(s, pink));
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
    hands[dir] = Offset(dir * s * 0.88, s * 0.055);
  }
  _paintOutfit(canvas, s, outfit);
  _paintHeld(canvas, s, outfit, hands);
  _paintProps(canvas, s, props, hands);
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
    case LokumOutfit.lemonCrown:
      // Ekşi Limon's crown in gold, with a lemon for its jewel.
      final crown = Path()
        ..moveTo(-s * 0.28, -s * 0.42)
        ..lineTo(-s * 0.32, -s * 0.7)
        ..lineTo(-s * 0.14, -s * 0.56)
        ..lineTo(0, -s * 0.78)
        ..lineTo(s * 0.14, -s * 0.56)
        ..lineTo(s * 0.32, -s * 0.7)
        ..lineTo(s * 0.28, -s * 0.42)
        ..close();
      canvas.drawPath(crown.shift(Offset(0, s * 0.02)), Paint()..color = const Color(0xFF7A4A00));
      canvas.drawPath(crown, Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.78), Offset(0, -s * 0.42), const [Color(0xFFFFF4A0), Color(0xFFE2B33C), Color(0xFFB07A1E)], const [0, 0.5, 1]));
      canvas.drawRect(Rect.fromLTRB(-s * 0.28, -s * 0.47, s * 0.28, -s * 0.42), Paint()..color = const Color(0xFFB07A1E));
      final lemon = Rect.fromCenter(center: Offset(0, -s * 0.52), width: s * 0.16, height: s * 0.11);
      canvas.drawOval(lemon, Paint()..shader = ui.Gradient.radial(lemon.center - Offset(s * 0.02, s * 0.02), s * 0.1, const [Color(0xFFFFF7A0), Color(0xFFFFD82A)]));
      for (final dx in [-0.2, 0.2]) {
        canvas.drawCircle(Offset(dx * s, -s * 0.49), s * 0.025, Paint()..color = const Color(0xFF2EA8FF));
      }
      for (final (x, y) in [(-0.32, -0.7), (0.0, -0.78), (0.32, -0.7)]) {
        canvas.drawCircle(Offset(x * s, y * s), s * 0.028, Paint()..color = const Color(0xFFFFF4A0));
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
    case LokumOutfit.zeybek:
      _paintZeybek(canvas, s);
    case LokumOutfit.hoca:
      _paintHoca(canvas, s);
    case LokumOutfit.mehter:
      _paintMehter(canvas, s);
    case LokumOutfit.karadeniz:
      _paintKukulete(canvas, s);
    case LokumOutfit.hamam:
      _paintHamam(canvas, s);
    case LokumOutfit.dondurma:
      _paintVest(canvas, s);
      canvas.save();
      canvas.translate(0, s * 0.03);
      _paintOutfitShape(canvas, s, LokumOutfit.fez);
      canvas.restore();
    case LokumOutfit.yazma:
      _paintYazma(canvas, s);
    case LokumOutfit.halay:
      break; // all in the hand
  }
}

Paint _across(Rect r, List<Color> colors) =>
    Paint()..shader = ui.Gradient.linear(r.centerLeft, r.centerRight, colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);
Paint _down(Rect r, List<Color> colors) =>
    Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);
Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = c;
const _goldTones = [Color(0xFFFFF1A8), Color(0xFFE2B33C), Color(0xFFB07A1E)];

/// A little flower of oya lace.
void _oyaFlower(Canvas canvas, Offset p, double r, Color c) {
  for (var i = 0; i < 5; i++) {
    final a = i * pi * 2 / 5 - pi / 2;
    canvas.drawCircle(p + Offset(cos(a), sin(a)) * r * 0.6, r * 0.45, Paint()..color = c);
  }
  canvas.drawCircle(p, r * 0.35, Paint()..color = const Color(0xFFFFE27A));
}

/// A tall börk wound with a yemeni and its fringe of tassels, and a sash.
void _paintZeybek(Canvas canvas, double s) {
  final sash = Rect.fromLTRB(-0.5 * s, 0.26 * s, 0.5 * s, 0.42 * s);
  const bands = [Color(0xFFC0182A), Color(0xFFE2B33C), Color(0xFF8A1A4A), Color(0xFFE2B33C)];
  for (var k = 0; k < 4; k++) {
    canvas.drawRect(Rect.fromLTRB(sash.left, sash.top + k * sash.height / 4, sash.right, sash.top + (k + 1) * sash.height / 4), Paint()..color = bands[k]);
  }
  final hat = Path()
    ..moveTo(-0.22 * s, -0.44 * s)
    ..lineTo(-0.19 * s, -0.94 * s)
    ..quadraticBezierTo(0, -1.08 * s, 0.19 * s, -0.94 * s)
    ..lineTo(0.22 * s, -0.44 * s)
    ..close();
  canvas.drawPath(hat, _across(hat.getBounds(), const [Color(0xFF5A1020), Color(0xFF9A2A3A), Color(0xFF5A1020)]));
  final wrap = Rect.fromCenter(center: Offset(0, -0.56 * s), width: 0.54 * s, height: 0.22 * s);
  canvas.drawRRect(RRect.fromRectAndRadius(wrap, Radius.circular(0.08 * s)), _down(wrap, const [Color(0xFFFFD27A), Color(0xFFE88A2A)]));
  const stripes = [Color(0xFFC0182A), Color(0xFF2E7D4A), Color(0xFF2A4AB0), Color(0xFFC0182A)];
  for (var k = 0; k < 4; k++) {
    canvas.drawLine(Offset(wrap.left + 0.02 * s, wrap.top + (0.04 + k * 0.045) * s), Offset(wrap.right - 0.02 * s, wrap.top + (0.02 + k * 0.045) * s), _stroke(stripes[k], 0.012 * s));
  }
  const tassels = [Color(0xFFC0182A), Color(0xFF2E7D4A), Color(0xFFE2B33C), Color(0xFF2A4AB0)];
  for (var k = 0; k < 9; k++) {
    final top = Offset((-0.24 + k * 0.06) * s, -0.46 * s);
    canvas.drawLine(top, top + Offset(0, 0.07 * s), _stroke(const Color(0xFF3A2A1A), 0.008 * s));
    canvas.drawOval(Rect.fromCenter(center: top + Offset(0, 0.09 * s), width: 0.035 * s, height: 0.05 * s), Paint()..color = tassels[k % 4]);
  }
}

/// Nasreddin Hoca: a great kavuk, a white moustache and beard.
void _paintHoca(Canvas canvas, double s) {
  final beard = Path()
    ..moveTo(-0.24 * s, 0.2 * s)
    ..quadraticBezierTo(-0.26 * s, 0.42 * s, 0, 0.56 * s)
    ..quadraticBezierTo(0.26 * s, 0.42 * s, 0.24 * s, 0.2 * s)
    ..quadraticBezierTo(0.12 * s, 0.27 * s, 0.13 * s, 0.24 * s)
    ..quadraticBezierTo(0, 0.3 * s, -0.13 * s, 0.24 * s)
    ..quadraticBezierTo(-0.12 * s, 0.27 * s, -0.24 * s, 0.2 * s)
    ..close();
  canvas.drawPath(beard, _down(beard.getBounds(), const [Colors.white, Color(0xFFDCD6E4)]));
  for (final (x, y) in const [(-0.14, 0.34), (0.0, 0.42), (0.14, 0.34), (-0.06, 0.5), (0.07, 0.48)]) {
    canvas.drawArc(Rect.fromCircle(center: Offset(x * s, y * s), radius: 0.03 * s), 0.3, pi * 1.3, false, _stroke(const Color(0xFFB8B0C4), 0.01 * s));
  }
  for (final dir in [-1.0, 1.0]) {
    canvas.drawPath(
        Path()
          ..moveTo(0, 0.1 * s)
          ..quadraticBezierTo(dir * 0.14 * s, 0.06 * s, dir * 0.2 * s, 0.14 * s)
          ..quadraticBezierTo(dir * 0.12 * s, 0.16 * s, 0, 0.13 * s)
          ..close(),
        Paint()..color = const Color(0xFFF2EEF6));
  }
  canvas.drawOval(Rect.fromCenter(center: Offset(0, -0.92 * s), width: 0.2 * s, height: 0.14 * s), Paint()..color = const Color(0xFF2E7D4A));
  final dome = Rect.fromCenter(center: Offset(0, -0.64 * s), width: 0.96 * s, height: 0.58 * s);
  canvas.drawOval(dome.shift(Offset(0, 0.02 * s)), Paint()..color = Colors.black.withValues(alpha: 0.25));
  canvas.drawOval(dome, Paint()..shader = ui.Gradient.radial(dome.center - Offset(0.15 * s, 0.12 * s), 0.6 * s, const [Colors.white, Color(0xFFF4EEE2), Color(0xFFCFC4B0)], const [0, 0.55, 1]));
  canvas.save();
  canvas.clipPath(Path()..addOval(dome));
  for (var k = 0; k < 6; k++) {
    canvas.drawArc(Rect.fromCenter(center: Offset((-0.35 + k * 0.14) * s, -0.56 * s), width: 0.7 * s, height: 0.5 * s), pi * 1.05, pi * 0.6, false, _stroke(const Color(0xFFBDB09A), 0.014 * s));
  }
  canvas.restore();
}

/// A mehter: his tall red cap with its plume, and the davul on his belly.
void _paintMehter(Canvas canvas, double s) {
  final cap = Path()
    ..moveTo(-0.26 * s, -0.42 * s)
    ..lineTo(-0.2 * s, -0.92 * s)
    ..quadraticBezierTo(0, -1.04 * s, 0.2 * s, -0.92 * s)
    ..lineTo(0.26 * s, -0.42 * s)
    ..quadraticBezierTo(0, -0.36 * s, -0.26 * s, -0.42 * s)
    ..close();
  canvas.drawPath(cap, _across(cap.getBounds(), const [Color(0xFF8E0E1A), Color(0xFFE23440), Color(0xFF9E1220)]));
  // A white wrap at the brim tells it from the fez.
  final wrap = Rect.fromLTRB(-0.28 * s, -0.56 * s, 0.28 * s, -0.42 * s);
  canvas.drawRRect(RRect.fromRectAndRadius(wrap, Radius.circular(0.06 * s)), _down(wrap, const [Colors.white, Color(0xFFDCD6E4)]));
  for (var k = 0; k < 4; k++) {
    canvas.drawArc(Rect.fromCenter(center: Offset((-0.18 + k * 0.12) * s, -0.49 * s), width: 0.16 * s, height: 0.1 * s), pi * 1.1, pi * 0.6, false, _stroke(const Color(0xFFB8B0C4), 0.01 * s));
  }
  final band = Rect.fromLTRB(-0.22 * s, -0.62 * s, 0.22 * s, -0.56 * s);
  canvas.drawRect(band, _down(band, _goldTones));
  canvas.drawPath(
      Path()
        ..moveTo(0.02 * s, -0.98 * s)
        ..quadraticBezierTo(0.2 * s, -1.2 * s, 0.34 * s, -1.12 * s)
        ..quadraticBezierTo(0.18 * s, -1.06 * s, 0.06 * s, -0.96 * s)
        ..close(),
      Paint()..color = Colors.white);
  // The davul: its side with the zigzag rope, heads at both ends, a strap.
  canvas.drawLine(Offset(-0.5 * s, -0.16 * s), Offset(-0.36 * s, 0.22 * s), _stroke(const Color(0xFF6A3A18), 0.04 * s));
  final drum = Rect.fromCenter(center: Offset(0, 0.36 * s), width: 0.7 * s, height: 0.32 * s);
  canvas.drawRect(drum, _down(drum, const [Color(0xFFE84A3A), Color(0xFFB0201A), Color(0xFF7A1010)]));
  final rope = Path()..moveTo(drum.left + 0.05 * s, drum.top + 0.03 * s);
  for (var k = 0; k < 8; k++) {
    rope.lineTo(drum.left + (0.05 + (k + 0.5) * 0.075) * s, k.isEven ? drum.bottom - 0.03 * s : drum.top + 0.03 * s);
  }
  canvas.drawPath(rope, _stroke(const Color(0xFFFFE6A8), 0.014 * s));
  for (final x in [drum.left, drum.right]) {
    final head = Rect.fromCenter(center: Offset(x, drum.center.dy), width: 0.12 * s, height: drum.height);
    canvas.drawOval(head, Paint()..color = const Color(0xFFF6E8C8));
    canvas.drawOval(head, _stroke(const Color(0xFFB07A1E), 0.02 * s));
  }
}

/// The Black Sea: a black kukulete wound round the head, its ends hanging.
void _paintKukulete(Canvas canvas, double s) {
  for (final (x, turn) in const [(0.42, 0.25), (0.5, 0.1)]) {
    canvas.save();
    canvas.translate(x * s, -0.2 * s);
    canvas.rotate(turn);
    final tail = Rect.fromLTWH(-0.05 * s, 0, 0.1 * s, 0.5 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(tail, Radius.circular(0.03 * s)), _across(tail, const [Color(0xFF1A1420), Color(0xFF3A3040)]));
    for (var k = 0; k < 5; k++) {
      canvas.drawLine(Offset((-0.04 + k * 0.02) * s, 0.5 * s), Offset((-0.04 + k * 0.02) * s, 0.56 * s), _stroke(const Color(0xFF1A1420), 0.01 * s));
    }
    canvas.drawLine(Offset(-0.05 * s, 0.42 * s), Offset(0.05 * s, 0.42 * s), _stroke(const Color(0xFFE2B33C), 0.012 * s));
    canvas.restore();
  }
  final hood = Path()
    ..moveTo(-0.52 * s, -0.12 * s)
    ..quadraticBezierTo(-0.52 * s, -0.58 * s, 0, -0.6 * s)
    ..quadraticBezierTo(0.52 * s, -0.58 * s, 0.52 * s, -0.12 * s)
    ..quadraticBezierTo(0, -0.3 * s, -0.52 * s, -0.12 * s)
    ..close();
  canvas.drawPath(hood, _down(hood.getBounds(), const [Color(0xFF3A3040), Color(0xFF1A1420)]));
  final band = Path()
    ..moveTo(-0.5 * s, -0.2 * s)
    ..quadraticBezierTo(0, -0.38 * s, 0.5 * s, -0.2 * s);
  canvas.drawPath(band, _stroke(const Color(0xFF4A4050), 0.07 * s));
  for (final m in band.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += 0.05 * s) {
      canvas.drawCircle(m.getTangentForOffset(d)!.position, 0.01 * s, Paint()..color = const Color(0xFFE2B33C));
    }
  }
}

/// Hamam: a towel wound on the head, a striped peştamal and nalın clogs.
void _paintHamam(Canvas canvas, double s) {
  final cloth = Rect.fromLTRB(-0.52 * s, 0.12 * s, 0.52 * s, 0.5 * s);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndCorners(cloth, bottomLeft: Radius.circular(0.1 * s), bottomRight: Radius.circular(0.1 * s)));
  canvas.drawRect(cloth, Paint()..color = const Color(0xFFC8202C));
  for (var k = 0; k < 9; k++) {
    final x = cloth.left + (k + 0.5) * cloth.width / 9;
    canvas.drawLine(Offset(x, cloth.top), Offset(x, cloth.bottom), _stroke(Colors.white.withValues(alpha: 0.85), 0.018 * s));
    canvas.drawLine(Offset(x + 0.03 * s, cloth.top), Offset(x + 0.03 * s, cloth.bottom), _stroke(const Color(0xFF2A4AB0).withValues(alpha: 0.7), 0.008 * s));
  }
  canvas.restore();
  canvas.drawLine(cloth.topLeft, cloth.topRight, _stroke(const Color(0xFF8A0E18), 0.03 * s));
  for (var k = 0; k < 16; k++) {
    final x = cloth.left + 0.06 * s + k * 0.058 * s;
    canvas.drawLine(Offset(x, cloth.bottom - 0.01 * s), Offset(x, cloth.bottom + 0.04 * s), _stroke(Colors.white, 0.01 * s));
  }
  for (final dir in [-1.0, 1.0]) {
    final sole = Rect.fromCenter(center: Offset(dir * 0.22 * s, 0.6 * s), width: 0.3 * s, height: 0.07 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(sole, Radius.circular(0.02 * s)), Paint()..color = const Color(0xFF8A5A2A));
    for (final x in [sole.left + 0.03 * s, sole.right - 0.08 * s]) {
      canvas.drawRect(Rect.fromLTWH(x, sole.bottom, 0.05 * s, 0.06 * s), Paint()..color = const Color(0xFF6A4018));
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: sole.center - Offset(0, 0.05 * s), width: 0.24 * s, height: 0.05 * s), Radius.circular(0.02 * s)), Paint()..color = const Color(0xFFE2B33C));
  }
  final towel = Rect.fromCenter(center: Offset(0, -0.56 * s), width: 0.8 * s, height: 0.34 * s);
  canvas.drawOval(towel.shift(Offset(0, 0.02 * s)), Paint()..color = Colors.black.withValues(alpha: 0.2));
  canvas.drawOval(towel, Paint()..shader = ui.Gradient.radial(towel.center - Offset(0.1 * s, 0.06 * s), 0.5 * s, const [Colors.white, Color(0xFFE4ECF4)]));
  canvas.save();
  canvas.clipPath(Path()..addOval(towel));
  for (var k = 0; k < 5; k++) {
    canvas.drawArc(Rect.fromCenter(center: Offset((-0.3 + k * 0.15) * s, -0.5 * s), width: 0.6 * s, height: 0.4 * s), pi * 1.1, pi * 0.55, false, _stroke(const Color(0xFF8FB8E0), 0.016 * s));
  }
  canvas.restore();
  canvas.drawCircle(Offset(0.22 * s, -0.7 * s), 0.08 * s, Paint()..color = Colors.white);
}

/// The Maraş ice-cream seller's embroidered vest.
void _paintVest(Canvas canvas, double s) {
  for (final dir in [-1.0, 1.0]) {
    final vest = Path()
      ..moveTo(dir * 0.5 * s, -0.2 * s)
      ..lineTo(dir * 0.4 * s, -0.2 * s)
      ..quadraticBezierTo(dir * 0.42 * s, 0.2 * s, dir * 0.18 * s, 0.5 * s)
      ..lineTo(dir * 0.48 * s, 0.52 * s)
      ..close();
    canvas.drawPath(vest, Paint()..shader = ui.Gradient.linear(Offset(dir * 0.5 * s, 0), Offset(dir * 0.2 * s, 0), const [Color(0xFF5A0A1A), Color(0xFF9A1A2E)]));
    for (var k = 0; k < 4; k++) {
      canvas.drawArc(Rect.fromCircle(center: Offset(dir * (0.42 - k * 0.04) * s, k * 0.12 * s), radius: 0.035 * s), 0.2, pi * 1.5, false, _stroke(const Color(0xFFE2B33C), 0.012 * s));
    }
    canvas.drawPath(
        Path()
          ..moveTo(dir * 0.4 * s, -0.2 * s)
          ..quadraticBezierTo(dir * 0.42 * s, 0.2 * s, dir * 0.18 * s, 0.5 * s),
        _stroke(const Color(0xFFE2B33C), 0.014 * s));
  }
}

/// An oyalı yazma: a printed muslin scarf with needle-lace flowers along
/// its edge, its ends tied at the side.
void _paintYazma(Canvas canvas, double s) {
  const cloth = Colors.white;
  final knot = Color.lerp(cloth, Colors.black, 0.15)!;
  for (final turn in [0.5, 0.15]) {
    canvas.save();
    canvas.translate(-0.53 * s, 0.2 * s);
    canvas.rotate(turn);
    canvas.drawPath(Path()..addPolygon([Offset(-0.04 * s, 0), Offset(-0.1 * s, 0.24 * s), Offset(0.06 * s, 0.22 * s), Offset(0.04 * s, 0)], true), Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, 0.22 * s), [cloth, knot]));
    canvas.restore();
  }
  final scarf = Path()
    ..moveTo(-0.55 * s, 0.22 * s)
    ..lineTo(-0.54 * s, -0.24 * s)
    ..quadraticBezierTo(-0.5 * s, -0.56 * s, 0, -0.56 * s)
    ..quadraticBezierTo(0.5 * s, -0.56 * s, 0.54 * s, -0.24 * s)
    ..lineTo(0.55 * s, 0.22 * s)
    ..quadraticBezierTo(0.48 * s, 0.24 * s, 0.43 * s, 0.18 * s)
    ..lineTo(0.41 * s, -0.16 * s)
    ..quadraticBezierTo(0, -0.3 * s, -0.41 * s, -0.16 * s)
    ..lineTo(-0.43 * s, 0.18 * s)
    ..quadraticBezierTo(-0.48 * s, 0.24 * s, -0.55 * s, 0.22 * s)
    ..close();
  canvas.drawPath(scarf.shift(Offset(0, 0.015 * s)), Paint()..color = Colors.black.withValues(alpha: 0.2));
  canvas.drawPath(scarf, _down(scarf.getBounds(), const [cloth, Color(0xFFF0E8F2)]));
  canvas.drawCircle(Offset(-0.53 * s, 0.2 * s), 0.05 * s, Paint()..color = Color.lerp(cloth, Colors.black, 0.08)!);
  canvas.save();
  canvas.clipPath(scarf);
  final rnd = Random(4);
  for (var i = 0; i < 26; i++) {
    final q = Offset((rnd.nextDouble() - 0.5) * 1.1 * s, (-0.56 + rnd.nextDouble() * 0.8) * s);
    canvas.drawCircle(q, s * 0.022, Paint()..color = const Color(0xFFE2333C).withValues(alpha: 0.8));
    canvas.drawCircle(q + Offset(0.025 * s, 0.012 * s), s * 0.01, Paint()..color = const Color(0xFF3FAF4A));
  }
  canvas.restore();
  final edge = Path()
    ..moveTo(-0.43 * s, 0.18 * s)
    ..lineTo(-0.41 * s, -0.16 * s)
    ..quadraticBezierTo(0, -0.3 * s, 0.41 * s, -0.16 * s)
    ..lineTo(0.43 * s, 0.18 * s);
  const colors = [Color(0xFFE2333C), Color(0xFF8A4AD8), Color(0xFFFF8A2A), Color(0xFF2EA8FF)];
  var i = 0;
  for (final m in edge.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += s * 0.075) {
      _oyaFlower(canvas, m.getTangentForOffset(d)!.position, s * 0.03, colors[i++ % colors.length]);
    }
  }
}

/// What an outfit puts in Lokum's hands, wherever his pose has put them:
/// [hands] maps -1 (left) and 1 (right) to where each hand is.
void _paintHeld(Canvas canvas, double s, LokumOutfit outfit, Map<double, Offset> hands) {
  final right = hands[1.0] ?? hands[-1.0];
  final left = hands[-1.0] ?? hands[1.0];
  if (right == null || left == null) return; // hands over his eyes
  switch (outfit) {
    case LokumOutfit.halay:
      // A red handkerchief with a lace edge, waving up from the hand.
      canvas.save();
      canvas.translate(right.dx, right.dy);
      final k = s / 132;
      final hanky = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-16 * k, -26 * k, -8 * k, -56 * k)
        ..quadraticBezierTo(12 * k, -46 * k, 32 * k, -66 * k)
        ..quadraticBezierTo(30 * k, -32 * k, 26 * k, -6 * k)
        ..quadraticBezierTo(12 * k, 6 * k, 0, 0)
        ..close();
      canvas.drawPath(hanky, Paint()..shader = ui.Gradient.linear(Offset(0, -60 * k), Offset.zero, const [Color(0xFFC0182A), Color(0xFFFF4A52)]));
      for (final m in hanky.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 9 * k) {
          canvas.drawCircle(m.getTangentForOffset(d)!.position, 2.4 * k, Paint()..color = Colors.white);
        }
      }
      canvas.restore();
    case LokumOutfit.mehter:
      // The davul stick, from the hand down towards the drum.
      final end = right + Offset(-0.2 * s, 0.2 * s);
      canvas.drawLine(right, end, _stroke(const Color(0xFF8A5A2A), 0.035 * s));
      canvas.drawCircle(end, 0.05 * s, Paint()..color = const Color(0xFFF2E2C0));
    case LokumOutfit.karadeniz:
      // The kemençe upright in the left hand, the bow in the right.
      canvas.save();
      canvas.translate(left.dx, left.dy + 0.06 * s);
      canvas.rotate(-0.12);
      final body = Path()
        ..moveTo(0, -0.12 * s)
        ..quadraticBezierTo(0.11 * s, -0.08 * s, 0.1 * s, 0.14 * s)
        ..quadraticBezierTo(0.08 * s, 0.3 * s, 0, 0.32 * s)
        ..quadraticBezierTo(-0.08 * s, 0.3 * s, -0.1 * s, 0.14 * s)
        ..quadraticBezierTo(-0.11 * s, -0.08 * s, 0, -0.12 * s)
        ..close();
      canvas.drawPath(body, _across(body.getBounds(), const [Color(0xFF6A3410), Color(0xFFB0662A), Color(0xFF6A3410)]));
      canvas.drawRect(Rect.fromLTRB(-0.025 * s, -0.36 * s, 0.025 * s, -0.1 * s), Paint()..color = const Color(0xFF5A2A0C));
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -0.38 * s), width: 0.09 * s, height: 0.06 * s), Paint()..color = const Color(0xFF5A2A0C));
      for (final dx in [-0.012, 0.0, 0.012]) {
        canvas.drawLine(Offset(dx * s, -0.36 * s), Offset(dx * s, 0.28 * s), _stroke(const Color(0xFFF2E2C0), 0.004 * s));
      }
      for (final dx in [-0.04, 0.04]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(dx * s, 0.08 * s), width: 0.025 * s, height: 0.06 * s), Paint()..color = const Color(0xFF2A1408));
      }
      canvas.restore();
      final tip = right + Offset(-0.3 * s, -0.12 * s);
      canvas.drawLine(right, tip, _stroke(const Color(0xFF6A3410), 0.018 * s));
      canvas.drawLine(right + Offset(0, 0.022 * s), tip + Offset(0, 0.022 * s), _stroke(const Color(0xFFF2EEE0), 0.006 * s));
    case LokumOutfit.hamam:
      // A silver tas, engraved.
      final tas = Rect.fromCenter(center: right + Offset(0.04 * s, -0.04 * s), width: 0.3 * s, height: 0.14 * s);
      canvas.drawArc(tas.inflate(0.01 * s), 0, pi, true, _down(tas, const [Color(0xFFF2F4F8), Color(0xFF9AA2B4)]));
      canvas.drawOval(Rect.fromCenter(center: tas.center, width: tas.width, height: tas.height * 0.4), Paint()..color = const Color(0xFFDCE2EC));
      for (var k = 0; k < 5; k++) {
        canvas.drawCircle(tas.center + Offset((-0.1 + k * 0.05) * s, 0.04 * s), 0.008 * s, Paint()..color = const Color(0xFF7A8294));
      }
    case LokumOutfit.dondurma:
      // The long paddle and its stretchy, pistachio-studded ice cream.
      final end = right + Offset(-0.12 * s, -0.6 * s);
      final grip = right + Offset(0.03 * s, 0.1 * s);
      canvas.drawLine(grip, end, _stroke(const Color(0xFF9AA2B4), 0.03 * s));
      canvas.drawLine(grip, end, _stroke(Colors.white.withValues(alpha: 0.5), 0.01 * s));
      final cream = Path()
        ..moveTo(end.dx - 0.1 * s, end.dy)
        ..quadraticBezierTo(end.dx - 0.12 * s, end.dy - 0.14 * s, end.dx, end.dy - 0.13 * s)
        ..quadraticBezierTo(end.dx + 0.13 * s, end.dy - 0.12 * s, end.dx + 0.1 * s, end.dy + 0.02 * s)
        ..quadraticBezierTo(end.dx + 0.06 * s, end.dy + 0.2 * s, end.dx + 0.02 * s, end.dy + 0.22 * s)
        ..quadraticBezierTo(end.dx - 0.02 * s, end.dy + 0.1 * s, end.dx - 0.1 * s, end.dy)
        ..close();
      canvas.drawPath(cream, _down(cream.getBounds(), const [Colors.white, Color(0xFFF2EAD8)]));
      for (final (x, y) in const [(-0.04, -0.06), (0.04, -0.02), (0.0, 0.06), (0.05, 0.12)]) {
        canvas.drawCircle(end + Offset(x * s, y * s), 0.016 * s, Paint()..color = const Color(0xFF8CC84A));
      }
    default:
      break;
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

// ------------------------------------------------------ the second season --

/// Morning fog over a cell: soft white puffs, a hint of the sweet beneath.
void paintFog(Canvas canvas, Rect cell, {double drift = 0}) {
  final s = cell.width, c = cell.center;
  canvas.drawRRect(RRect.fromRectAndRadius(cell.deflate(s * 0.02), Radius.circular(s * 0.22)), Paint()..color = const Color(0xFFE8EEF8).withValues(alpha: 0.82));
  final puff = Paint()
    ..color = Colors.white
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06);
  for (final (dx, dy, r) in const [(-0.2, 0.06, 0.26), (0.16, -0.12, 0.28), (0.04, 0.2, 0.24), (0.24, 0.14, 0.2), (-0.18, -0.18, 0.18)]) {
    canvas.drawCircle(c + Offset((dx + drift * 0.04) * s, dy * s), r * s, puff);
  }
  canvas.drawRRect(RRect.fromRectAndRadius(cell.deflate(s * 0.04), Radius.circular(s * 0.2)), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.04
    ..color = Colors.white.withValues(alpha: 0.9));
}

/// A gull sitting on a cell, wings folded, an eye on the sweets.
void paintGull(Canvas canvas, Rect cell, {double flap = 0}) {
  final s = cell.width, c = cell.center + Offset(0, s * 0.06);
  canvas.drawOval(Rect.fromCenter(center: c + Offset(0, s * 0.34), width: s * 0.6, height: s * 0.12), Paint()..color = Colors.black.withValues(alpha: 0.25));
  final white = Paint()..shader = ui.Gradient.linear(c - Offset(0, s * 0.3), c + Offset(0, s * 0.3), const [Colors.white, Color(0xFFD8DEE8)]);
  canvas.drawOval(Rect.fromCenter(center: c + Offset(s * 0.04, s * 0.08), width: s * 0.66, height: s * 0.42), white);
  canvas.drawCircle(c + Offset(-s * 0.2, -s * 0.14), s * 0.17, white);
  // The grey wing, lifting a little now and then.
  final wing = Path()
    ..moveTo(c.dx - s * 0.06, c.dy - s * 0.02)
    ..quadraticBezierTo(c.dx + s * 0.22, c.dy - s * (0.2 + 0.18 * flap), c.dx + s * 0.4, c.dy + s * 0.02)
    ..quadraticBezierTo(c.dx + s * 0.18, c.dy + s * 0.14, c.dx - s * 0.06, c.dy - s * 0.02)
    ..close();
  canvas.drawPath(wing, Paint()..color = const Color(0xFF9AA6B8));
  canvas.drawPath(Path()..addPolygon([c + Offset(-s * 0.34, -s * 0.15), c + Offset(-s * 0.5, -s * 0.1), c + Offset(-s * 0.34, -s * 0.08)], true), Paint()..color = const Color(0xFFFFB020));
  canvas.drawCircle(c + Offset(-s * 0.24, -s * 0.17), s * 0.035, Paint()..color = const Color(0xFF1A1020));
  final ink = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = const Color(0xFF5A6478);
  canvas.drawOval(Rect.fromCenter(center: c + Offset(s * 0.04, s * 0.08), width: s * 0.66, height: s * 0.42), ink);
  for (final dx in [-0.06, 0.12]) {
    canvas.drawLine(c + Offset(dx * s, s * 0.28), c + Offset(dx * s, s * 0.38), Paint()
      ..strokeWidth = s * 0.04
      ..color = const Color(0xFFFFB020));
  }
}

/// Rose jam under a cell: glossy, with a few drips.
void paintJam(Canvas canvas, Rect cell) {
  final s = cell.width;
  final r = RRect.fromRectAndRadius(cell.deflate(s * 0.02), Radius.circular(s * 0.2));
  canvas.drawRRect(r, Paint()..shader = ui.Gradient.linear(cell.topLeft, cell.bottomRight, const [Color(0xDDFF5A8A), Color(0xDDC0164E)]));
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.04
    ..color = const Color(0xFFFF9AB8));
  for (final (dx, dy, k) in const [(0.22, 0.2, 0.07), (0.7, 0.26, 0.05), (0.4, 0.78, 0.06)]) {
    canvas.drawCircle(cell.topLeft + Offset(dx * s, dy * s), k * s, Paint()..color = Colors.white.withValues(alpha: 0.55));
  }
}

/// A palace garden lantern: dark until three hits light it; [left] hits to
/// go, shown as three little lamps under it.
void paintLantern(Canvas canvas, Rect cell, int left, {double glow = 0}) {
  final s = cell.width, c = cell.center;
  final lit = 3 - left;
  if (glow > 0) canvas.drawCircle(c, s * 0.7, Paint()..shader = ui.Gradient.radial(c, s * 0.7, [Color.fromRGBO(255, 224, 122, 0.8 * glow), const Color(0x00FFE07A)]));
  final body = Rect.fromCenter(center: c + Offset(0, s * 0.02), width: s * 0.5, height: s * 0.6);
  canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(s * 0.12)), Paint()
    ..shader = ui.Gradient.linear(body.topCenter, body.bottomCenter, lit >= 2 ? const [Color(0xFFFFE07A), Color(0xFFE09A20)] : const [Color(0xFF6A5A8A), Color(0xFF3A2A5A)]));
  canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(s * 0.12)), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.06
    ..color = const Color(0xFF8A5A10));
  canvas.drawLine(body.topCenter + Offset(0, s * 0.12), body.bottomCenter - Offset(0, s * 0.12), Paint()
    ..strokeWidth = s * 0.04
    ..color = const Color(0xFF8A5A10));
  canvas.drawRect(Rect.fromCenter(center: body.topCenter - Offset(0, s * 0.05), width: s * 0.34, height: s * 0.1), Paint()..color = const Color(0xFF8A5A10));
  for (var i = 0; i < 3; i++) {
    canvas.drawCircle(body.bottomCenter + Offset((i - 1) * s * 0.17, s * 0.13), s * 0.055, Paint()..color = i < lit ? const Color(0xFFFFE07A) : Colors.white.withValues(alpha: 0.35));
  }
}

/// A tunnel cell: a dark mouth with a ring, arrows pointing down through it.
void paintTunnel(Canvas canvas, Rect cell, {required bool top, required bool bottom, double t = 0}) {
  final s = cell.width;
  canvas.drawRect(cell, Paint()..shader = ui.Gradient.linear(cell.centerLeft, cell.centerRight, const [Color(0xFF1A0A30), Color(0xFF3A1A60), Color(0xFF1A0A30)], const [0, 0.5, 1]));
  final arrow = Paint()
    ..color = const Color(0xFF7AC8FF).withValues(alpha: 0.7)
    ..strokeWidth = s * 0.06
    ..strokeCap = StrokeCap.round;
  final y = cell.top + s * ((0.25 + t) % 1);
  canvas.drawLine(Offset(cell.center.dx, y - s * 0.18), Offset(cell.center.dx, y + s * 0.12), arrow);
  canvas.drawLine(Offset(cell.center.dx - s * 0.12, y), Offset(cell.center.dx, y + s * 0.12), arrow);
  canvas.drawLine(Offset(cell.center.dx + s * 0.12, y), Offset(cell.center.dx, y + s * 0.12), arrow);
  for (final (on, edge) in [(top, cell.top), (bottom, cell.bottom)]) {
    if (!on) continue;
    final mouth = Rect.fromCenter(center: Offset(cell.center.dx, edge), width: s * 0.94, height: s * 0.34);
    canvas.drawOval(mouth, Paint()..color = const Color(0xFF0A0418));
    canvas.drawOval(mouth, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..color = edge == cell.top ? const Color(0xFF8A6AF0) : const Color(0xFF2AC0E0));
  }
}

/// The Turkish flag in [r] (its height is the flag's width, G), drawn to
/// the Türk Bayrağı Tüzüğü: 1.5 G long; the crescent's outer circle 0.5 G
/// across with its centre 0.5 G from the hoist; the inner circle 0.4 G
/// across, 0.0625 G further on; the star in a circle 0.25 G across, one
/// point on the axis 1/3 G from where the inner circle crosses it.
void paintTurkishFlag(Canvas canvas, Rect r) {
  final g = r.height;
  canvas.drawRect(r, Paint()..color = const Color(0xFFE30A17));
  final y = r.center.dy;
  final outer = Offset(r.left + 0.5 * g, y);
  final inner = outer + Offset(0.0625 * g, 0);
  final crescent = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: outer, radius: 0.25 * g)),
    Path()..addOval(Rect.fromCircle(center: inner, radius: 0.2 * g)),
  );
  final white = Paint()..color = Colors.white;
  canvas.drawPath(crescent, white);
  // The star's point towards the hoist lies on the axis.
  final tip = inner.dx - 0.2 * g + g / 3;
  final radius = 0.125 * g;
  final centre = Offset(tip + radius, y);
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = pi + i * pi / 5;
    final d = i.isEven ? radius : radius * 0.381966;
    final p = centre + Offset(cos(a), sin(a)) * d;
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(star..close(), white);
}

/// What Lokum carries on a special day, in the hands his pose has put
/// where [hands] says.
void _paintProps(Canvas canvas, double s, List<LokumProp> props, Map<double, Offset> hands) {
  final left = hands[-1.0] ?? hands[1.0];
  final right = hands[1.0] ?? hands[-1.0];
  for (final prop in props) {
    switch (prop) {
      case LokumProp.flag:
        if (left == null) break;
        // A pole from the left hand, the flag flying over his head.
        // The pole reaches the same height whatever the pose, clear of his head.
        final top = Offset(left.dx, -0.88 * s);
        canvas.drawLine(left + Offset(0, 0.1 * s), top, _stroke(const Color(0xFF8A6A3A), 0.03 * s));
        canvas.drawCircle(top - Offset(0, 0.02 * s), 0.035 * s, Paint()..shader = ui.Gradient.radial(top, 0.04 * s, _goldTones, const [0, 0.5, 1]));
        final g = 0.3 * s;
        final flag = Rect.fromLTWH(top.dx + 0.015 * s, top.dy + 0.01 * s, 1.5 * g, g);
        canvas.drawRect(flag.shift(Offset(0.01 * s, 0.015 * s)), Paint()..color = Colors.black.withValues(alpha: 0.2));
        paintTurkishFlag(canvas, flag);
      case LokumProp.kite:
        if (left == null) break;
        // A kite high on the left, its string down to his hand.
        final k = left + Offset(0.08 * s, -0.62 * s);
        canvas.drawPath(
            Path()
              ..moveTo(left.dx, left.dy)
              ..quadraticBezierTo(left.dx - 0.12 * s, k.dy + 0.3 * s, k.dx, k.dy + 0.13 * s),
            _stroke(Colors.white.withValues(alpha: 0.8), 0.008 * s));
        final quarters = [const Color(0xFFE2333C), const Color(0xFFFFC21A), const Color(0xFF2EA8FF), const Color(0xFF3FBF4A)];
        final pts = [k + Offset(0, -0.15 * s), k + Offset(0.11 * s, 0), k + Offset(0, 0.13 * s), k + Offset(-0.11 * s, 0)];
        for (var i = 0; i < 4; i++) {
          canvas.drawPath(Path()..addPolygon([k, pts[i], pts[(i + 1) % 4]], true), Paint()..color = quarters[i]);
        }
        canvas.drawPath(Path()..addPolygon(pts, true), _stroke(Colors.white, 0.012 * s));
        final tail = Path()..moveTo(pts[2].dx, pts[2].dy);
        for (var i = 1; i <= 3; i++) {
          tail.quadraticBezierTo(pts[2].dx + (i.isOdd ? 0.06 : -0.06) * s, pts[2].dy + (i - 0.5) * 0.08 * s, pts[2].dx, pts[2].dy + i * 0.08 * s);
        }
        canvas.drawPath(tail, _stroke(Colors.white.withValues(alpha: 0.8), 0.008 * s));
        for (var i = 1; i <= 3; i++) {
          final b = pts[2] + Offset(0, i * 0.08 * s);
          canvas.drawPath(Path()..addPolygon([b + Offset(-0.035 * s, -0.02 * s), b + Offset(0.035 * s, 0.02 * s), b + Offset(0.035 * s, -0.02 * s), b + Offset(-0.035 * s, 0.02 * s)], true), Paint()..color = quarters[i % 4]);
        }
      case LokumProp.torch:
        if (right == null) break;
        // The youth torch: a gilded handle and its flame.
        final cup = right + Offset(0.04 * s, -0.24 * s);
        final handle = Path()
          ..moveTo(right.dx - 0.025 * s, right.dy + 0.08 * s)
          ..lineTo(cup.dx - 0.07 * s, cup.dy)
          ..lineTo(cup.dx + 0.07 * s, cup.dy)
          ..lineTo(right.dx + 0.025 * s, right.dy + 0.08 * s)
          ..close();
        canvas.drawPath(handle, _across(handle.getBounds(), _goldTones));
        canvas.drawOval(Rect.fromCenter(center: cup, width: 0.16 * s, height: 0.05 * s), Paint()..color = const Color(0xFFB07A1E));
        final flame = Path()
          ..moveTo(cup.dx - 0.07 * s, cup.dy)
          ..quadraticBezierTo(cup.dx - 0.1 * s, cup.dy - 0.16 * s, cup.dx + 0.01 * s, cup.dy - 0.3 * s)
          ..quadraticBezierTo(cup.dx + 0.02 * s, cup.dy - 0.18 * s, cup.dx + 0.08 * s, cup.dy - 0.16 * s)
          ..quadraticBezierTo(cup.dx + 0.1 * s, cup.dy - 0.06 * s, cup.dx + 0.07 * s, cup.dy)
          ..close();
        canvas.drawPath(flame, _down(flame.getBounds(), const [Color(0xFFFFE27A), Color(0xFFFF8A2A), Color(0xFFE2333C)]));
        canvas.drawOval(Rect.fromCenter(center: cup - Offset(0, 0.07 * s), width: 0.06 * s, height: 0.1 * s), Paint()..color = const Color(0xFFFFF6C8));
      case LokumProp.laurel:
        // A laurel wreath round the top of his head, tied with red.
        final ring = Rect.fromCenter(center: Offset(0, -0.42 * s), width: 0.78 * s, height: 0.26 * s);
        canvas.drawArc(ring, pi * 0.98, pi * 1.04, false, _stroke(const Color(0xFF3A7A2A), 0.025 * s));
        for (var i = 0; i <= 12; i++) {
          final a = pi * 0.98 + i * pi * 1.04 / 12;
          final p = ring.center + Offset(cos(a) * ring.width / 2, sin(a) * ring.height / 2);
          for (final side in [-1.0, 1.0]) {
            canvas.save();
            canvas.translate(p.dx, p.dy);
            canvas.rotate(a + pi / 2 + side * 0.7);
            canvas.drawOval(Rect.fromCenter(center: Offset(0, -0.04 * s), width: 0.035 * s, height: 0.08 * s), Paint()..color = i.isEven ? const Color(0xFF4E9A3A) : const Color(0xFF6DB848));
            canvas.restore();
          }
        }
        canvas.drawCircle(Offset(-0.39 * s, -0.42 * s), 0.03 * s, Paint()..color = const Color(0xFFE30A17));
        canvas.drawCircle(Offset(0.39 * s, -0.42 * s), 0.03 * s, Paint()..color = const Color(0xFFE30A17));
      case LokumProp.cologne:
        if (right == null) break;
        // A bottle of lemon cologne, tipped to pour into your hands.
        canvas.save();
        canvas.translate(right.dx + 0.06 * s, right.dy - 0.04 * s);
        canvas.rotate(1.05);
        final k = s / 124;
        final bottle = RRect.fromRectAndRadius(Rect.fromLTWH(-17 * k, -30 * k, 34 * k, 58 * k), Radius.circular(8 * k));
        canvas.drawRRect(bottle, Paint()..color = const Color(0xFFEFF8FF).withValues(alpha: 0.9));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-14 * k, -6 * k, 28 * k, 31 * k), Radius.circular(6 * k)), Paint()..color = const Color(0xFFF7E06A).withValues(alpha: 0.85));
        canvas.drawRect(Rect.fromLTWH(-12 * k, -22 * k, 24 * k, 18 * k), Paint()..color = Colors.white);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, -13 * k), width: 13 * k, height: 9 * k), Paint()..color = const Color(0xFFFFD82A));
        canvas.drawOval(Rect.fromCenter(center: Offset(5 * k, -17 * k), width: 6 * k, height: 3 * k), Paint()..color = const Color(0xFF3FAF4A));
        canvas.drawRect(Rect.fromLTWH(-6 * k, -42 * k, 12 * k, 12 * k), Paint()..color = const Color(0xFFEFF8FF).withValues(alpha: 0.9));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-8 * k, -50 * k, 16 * k, 9 * k), Radius.circular(3 * k)), _down(Rect.fromLTWH(-8 * k, -50 * k, 16 * k, 9 * k), _goldTones));
        canvas.drawRRect(bottle, _stroke(Colors.white, 2 * k));
        canvas.restore();
        final from = right + Offset(0.42 * s, -0.2 * s);
        for (var i = 0; i < 4; i++) {
          final d = from + Offset((0.02 + i * 0.03) * s, (0.08 + i * 0.13) * s);
          canvas.drawPath(
              Path()
                ..moveTo(d.dx, d.dy - 0.05 * s)
                ..quadraticBezierTo(d.dx + 0.035 * s, d.dy + 0.01 * s, d.dx, d.dy + 0.03 * s)
                ..quadraticBezierTo(d.dx - 0.035 * s, d.dy + 0.01 * s, d.dx, d.dy - 0.05 * s),
              Paint()..color = const Color(0xFFFFF4A8));
        }
      case LokumProp.pine:
        // A small pine at his left, hung with baubles, a star on top.
        final base = Offset(-0.62 * s, 0.52 * s);
        canvas.drawRect(Rect.fromCenter(center: base - Offset(0, 0.04 * s), width: 0.07 * s, height: 0.1 * s), Paint()..color = const Color(0xFF6A4018));
        for (var i = 0; i < 3; i++) {
          final y = base.dy - (0.08 + i * 0.22) * s;
          final w = (0.36 - i * 0.09) * s;
          final tier = Path()
            ..moveTo(base.dx - w / 2, y)
            ..lineTo(base.dx, y - 0.32 * s)
            ..lineTo(base.dx + w / 2, y)
            ..close();
          canvas.drawPath(tier, _down(tier.getBounds(), const [Color(0xFF3FAF4A), Color(0xFF1E6A2E)]));
        }
        const baubles = [Color(0xFFE2333C), Color(0xFFFFC21A), Color(0xFF2EA8FF), Color(0xFFFF6FB5)];
        for (final (i, (x, y)) in const [(-0.1, -0.16), (0.08, -0.22), (-0.05, -0.38), (0.06, -0.48), (-0.02, -0.62), (0.12, -0.12)].indexed) {
          canvas.drawCircle(base + Offset(x * s, y * s), 0.025 * s, Paint()..color = baubles[i % baubles.length]);
        }
        final starAt = base - Offset(0, 0.84 * s);
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = -pi / 2 + i * pi / 5;
          final p = starAt + Offset(cos(a), sin(a)) * (i.isEven ? 0.06 : 0.025) * s;
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(star..close(), Paint()..color = const Color(0xFFFFD82A));
      case LokumProp.dove:
        if (right == null) break;
        // A white dove perched on the raised hand, wings half open.
        final d = right + Offset(0.02 * s, -0.1 * s);
        final k = s;
        final wing = Paint()..color = const Color(0xFFE6ECF4);
        canvas.drawPath(
            Path()
              ..moveTo(d.dx - 0.02 * k, d.dy - 0.02 * k)
              ..quadraticBezierTo(d.dx - 0.1 * k, d.dy - 0.2 * k, d.dx - 0.2 * k, d.dy - 0.18 * k)
              ..quadraticBezierTo(d.dx - 0.1 * k, d.dy - 0.1 * k, d.dx - 0.06 * k, d.dy + 0.02 * k)
              ..close(),
            wing);
        final body = Path()
          ..moveTo(d.dx - 0.14 * k, d.dy + 0.03 * k)
          ..quadraticBezierTo(d.dx - 0.04 * k, d.dy + 0.09 * k, d.dx + 0.08 * k, d.dy + 0.0 * k)
          ..quadraticBezierTo(d.dx + 0.1 * k, d.dy - 0.06 * k, d.dx + 0.06 * k, d.dy - 0.08 * k)
          ..quadraticBezierTo(d.dx + 0.0 * k, d.dy - 0.06 * k, d.dx - 0.04 * k, d.dy - 0.02 * k)
          ..lineTo(d.dx - 0.18 * k, d.dy - 0.04 * k)
          ..close();
        canvas.drawPath(body, Paint()..color = Colors.white);
        canvas.drawPath(
            Path()
              ..moveTo(d.dx - 0.0 * k, d.dy - 0.03 * k)
              ..quadraticBezierTo(d.dx + 0.02 * k, d.dy - 0.2 * k, d.dx + 0.14 * k, d.dy - 0.22 * k)
              ..quadraticBezierTo(d.dx + 0.06 * k, d.dy - 0.1 * k, d.dx + 0.03 * k, d.dy + 0.0 * k)
              ..close(),
            Paint()..color = Colors.white);
        canvas.drawCircle(d + Offset(0.07 * k, -0.055 * k), 0.008 * k, Paint()..color = const Color(0xFF2A1A30));
        canvas.drawPath(Path()..addPolygon([d + Offset(0.095 * k, -0.06 * k), d + Offset(0.125 * k, -0.045 * k), d + Offset(0.09 * k, -0.04 * k)], true), Paint()..color = const Color(0xFFFFA23A));
      case LokumProp.ribbon:
        // A black mourning ribbon, looped, on his chest.
        canvas.save();
        canvas.translate(0.3 * s, 0.3 * s);
        final k = 0.16 * s;
        final ribbon = Path()
          ..moveTo(-0.35 * k, 0.9 * k)
          ..lineTo(0.18 * k, -0.1 * k)
          ..cubicTo(0.45 * k, -0.6 * k, 0.15 * k, -1.0 * k, 0, -1.0 * k)
          ..cubicTo(-0.15 * k, -1.0 * k, -0.45 * k, -0.6 * k, -0.18 * k, -0.1 * k)
          ..lineTo(0.35 * k, 0.9 * k);
        canvas.drawPath(ribbon, _stroke(const Color(0xFF16121A), 0.16 * k));
        canvas.drawPath(ribbon, _stroke(Colors.white.withValues(alpha: 0.12), 0.04 * k));
        canvas.restore();
    }
  }
}
