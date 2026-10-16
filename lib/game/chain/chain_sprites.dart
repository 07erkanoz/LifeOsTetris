import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/chain/chain_game.dart';

/// Zincir Küpler's own, bright cube colours (the same in every theme).
const Map<ChainColor, Color> chainColors = {
  ChainColor.yellow: Color(0xFFFFE21F),
  ChainColor.magenta: Color(0xFFFF33EE),
  ChainColor.blue: Color(0xFF3F6BFF),
  ChainColor.green: Color(0xFF1FE85A),
  ChainColor.orange: Color(0xFFFF8A10),
  ChainColor.gray: Color(0xFFCDD3E6),
};

const Color garbageRed = Color(0xFFD81E24);

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

/// A red garbage slab: rounded, glossy, lit from the top.
void paintGarbageSlab(Canvas canvas, Rect r, {double flash = 0}) {
  final color = Color.lerp(garbageRed, Colors.white, flash * 0.6)!;
  final s = r.height;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.16));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.08)), Paint()
    ..color = Colors.black.withValues(alpha: 0.6)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [_l(color, 0.35), color, _d(color, 0.45)], const [0, 0.35, 1]));
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(r.left + s * 0.1, r.top + s * 0.08, r.width - s * 0.2, s * 0.3), Radius.circular(s * 0.12)),
    Paint()..shader = ui.Gradient.linear(r.topCenter, r.topCenter + Offset(0, s * 0.38), [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0)]),
  );
  canvas.drawRRect(rr, Paint()
    ..color = _d(color, 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03);
}

/// A four-pointed sparkle with a soft glow.
void paintSparkle(Canvas canvas, Offset p, double size, Color color, {double opacity = 1}) {
  final star = Path()
    ..moveTo(p.dx, p.dy - size)
    ..quadraticBezierTo(p.dx, p.dy, p.dx + size, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + size)
    ..quadraticBezierTo(p.dx, p.dy, p.dx - size, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - size);
  canvas.drawCircle(p, size * 0.9, Paint()..color = color.withValues(alpha: 0.35 * opacity));
  canvas.drawPath(star, Paint()..color = _l(color, 0.4).withValues(alpha: opacity));
  canvas.drawCircle(p, size * 0.18, Paint()..color = Colors.white.withValues(alpha: opacity));
}

/// The cubes drawn once per size into images, so a frame only copies them:
/// the blurred halo and gradients are too slow to paint 80 times a frame.
class ChainSprites {
  ChainSprites._(this.cell, this.dpr, this._normal, this._bright);

  static ChainSprites? _cache;

  static ChainSprites of(double cell, double dpr) {
    final c = _cache;
    if (c != null && c.cell == cell && c.dpr == dpr) return c;
    c?.dispose();
    final normal = {for (final e in chainColors.entries) e.key: _render(cell, dpr, e.value)};
    final bright = {for (final e in chainColors.entries) e.key: _render(cell, dpr, _l(e.value, 0.45))};
    return _cache = ChainSprites._(cell, dpr, normal, bright);
  }

  /// Room around a cube for its halo and shadow, as a share of the cell.
  static const double pad = 0.25;

  final double cell;
  final double dpr;
  final Map<ChainColor, ui.Image> _normal;
  final Map<ChainColor, ui.Image> _bright;

  static ui.Image _render(double cell, double dpr, Color color) {
    final side = cell * (1 + 2 * pad);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paintPyramidCube(canvas, Rect.fromLTWH(cell * pad + 2, cell * pad + 2, cell - 4, cell - 4), color);
    final px = max(1, (side * dpr).ceil());
    return recorder.endRecording().toImageSync(px, px);
  }

  /// Draws a cube with its top-left corner at [origin].
  void draw(Canvas canvas, ChainColor color, Offset origin, {bool bright = false, double opacity = 1, double scale = 1}) {
    final image = (bright ? _bright : _normal)[color]!;
    final side = cell * (1 + 2 * pad) * scale;
    final centre = origin + Offset(cell / 2, cell / 2);
    final dst = Rect.fromCenter(center: centre, width: side, height: side);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (opacity < 1) paint.color = Colors.white.withValues(alpha: opacity);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), dst, paint);
  }

  void dispose() {
    for (final i in [..._normal.values, ..._bright.values]) {
      i.dispose();
    }
  }
}
