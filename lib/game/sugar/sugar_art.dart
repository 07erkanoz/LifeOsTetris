import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/sugar/sugar_game.dart';
import '../render/block_sprites.dart';

/// The Şeker Küpler look: candy colours, the special cubes, ice and chains,
/// stars and sparkles. The cubes are drawn into images once per size
/// ([SugarSprites]); a frame only copies them.

const sugarColors = {
  SugarColor.red: Color(0xFFFF3B5C),
  SugarColor.orange: Color(0xFFFF9A1F),
  SugarColor.yellow: Color(0xFFFFD23F),
  SugarColor.green: Color(0xFF2BD96B),
  SugarColor.blue: Color(0xFF2E86FF),
  SugarColor.purple: Color(0xFFB45BFF),
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

// ------------------------------------------------------------- the cubes --

void paintSugarCube(Canvas canvas, Rect r, Color color, {int bubbles = 0}) =>
    paintJellyHd(canvas, r.topLeft, r.width, color, shadeTarget: _shadeTarget, bubbles: bubbles);

/// Line cube: light bands across it and glowing arrow tips at both ends.
void paintLineCube(Canvas canvas, Rect r, Color color, {required bool horizontal}) {
  final s = r.width;
  canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(s * 0.02), Radius.circular(s * 0.3)), Paint()
    ..color = _l(color, 0.3).withValues(alpha: 0.7)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.18));
  paintSugarCube(canvas, r, color);
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
void paintBombCube(Canvas canvas, Rect r, Color color) {
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
  paintSugarCube(canvas, r, color);
  final rr = RRect.fromRectAndRadius(r.deflate(s * 0.055), Radius.circular(s * 0.24));
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
  canvas.drawPath(starPath(c, s * 0.17, inner: 0.42), Paint()..color = Colors.white);
}

/// Prism cube: rainbow light swirling inside clear glass.
void paintPrismCube(Canvas canvas, Rect r, {double turn = 0}) {
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
    ], const [0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1], TileMode.clamp, 0.6 + turn, 0.6 + turn + 2 * pi));
  canvas.save();
  canvas.clipRRect(rr);
  canvas.drawCircle(c, s * 0.5, Paint()
    ..shader = ui.Gradient.radial(c, s * 0.5, [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0.0)], const [0, 1]));
  final gloss = Rect.fromLTWH(b.left + s * 0.08, b.top + s * 0.05, b.width - s * 0.16, s * 0.3);
  canvas.drawOval(gloss, Paint()
    ..shader = ui.Gradient.linear(gloss.topCenter, gloss.bottomCenter, [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0)]));
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.035
    ..color = Colors.white.withValues(alpha: 0.9));
  paintSparkle(canvas, c + Offset(-s * 0.16, -s * 0.12), s * 0.12, Colors.white);
  paintSparkle(canvas, c + Offset(s * 0.18, s * 0.14), s * 0.08, Colors.white);
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

/// Paints one piece the way the board shows it.
void paintSugarPiece(Canvas canvas, Rect r, SugarColor color, Special special, {int bubbles = 0}) {
  final c = sugarColors[color]!;
  switch (special) {
    case Special.none:
      paintSugarCube(canvas, r, c, bubbles: bubbles);
    case Special.lineH:
      paintLineCube(canvas, r, c, horizontal: true);
    case Special.lineV:
      paintLineCube(canvas, r, c, horizontal: false);
    case Special.bomb:
      paintBombCube(canvas, r, c);
    case Special.prism:
      paintPrismCube(canvas, r);
  }
}

// --------------------------------------------------------------- sprites --

/// The cubes, ice and chains drawn once per cell size into images.
class SugarSprites {
  SugarSprites._(this.cell, this.dpr);

  static SugarSprites? _cache;

  static SugarSprites of(double cell, double dpr) {
    final c = _cache;
    if (c != null && c.cell == cell && c.dpr == dpr) return c;
    c?.dispose();
    return _cache = SugarSprites._(cell, dpr);
  }

  /// Room around a cube for its glow, as a share of the cell.
  static const double pad = 0.25;
  static const int variants = 3;

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

  ui.Image piece(SugarColor color, Special special, [int variant = 0]) {
    final v = special == Special.none ? variant % variants : 0;
    final key = special == Special.prism ? (Special.prism, null, 0) : (special, color, v);
    return _images[key] ??= _render((canvas, r) => paintSugarPiece(canvas, r, color, special, bubbles: v));
  }

  ui.Image ice(int layers, int variant) => _images[('ice', layers.clamp(1, 2), variant % 2)] ??= _render((canvas, r) => paintIce(canvas, r, layers: layers, seed: variant % 2));

  ui.Image get chains => _images['chains'] ??= _render(paintChains);

  /// Draws [image] over the cell whose top-left is [origin].
  void draw(Canvas canvas, ui.Image image, Offset origin, {double opacity = 1, double scale = 1, double scaleY = 1}) {
    final side = cell * (1 + 2 * pad) * scale;
    final centre = origin + Offset(cell / 2, cell / 2);
    final dst = Rect.fromCenter(center: centre + Offset(0, side * (1 - scaleY) / 2 * 0.8), width: side * (2 - scaleY), height: side * scaleY);
    final paint = Paint()..filterQuality = FilterQuality.medium;
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
