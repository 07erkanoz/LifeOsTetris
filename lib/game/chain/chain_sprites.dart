import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/chain/chain_game.dart';

/// Zincir Küpler's own cube colours, deep and rich for the crystal cubes
/// (the same in every theme).
const Map<ChainColor, Color> chainColors = {
  ChainColor.yellow: Color(0xFFFFD000),
  ChainColor.magenta: Color(0xFFF21FD8),
  ChainColor.blue: Color(0xFF2F5BFF),
  ChainColor.green: Color(0xFF12D24E),
  ChainColor.orange: Color(0xFFFF7A00),
  ChainColor.gray: Color(0xFFCDD3E6),
};

const Color garbageRed = Color(0xFFD81E24);

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _d(Color c, double t) => Color.lerp(c, Colors.black, t)!;

/// A clear crystal cube lit from inside: deep colour, light glowing
/// through to the lower right, an inner bevel, a glass gloss across the top
/// and a bright rim, with a halo in its colour.
void paintChainCube(Canvas canvas, Rect r, Color color, {bool halo = true}) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.18));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.06)), Paint()
    ..color = Colors.black.withValues(alpha: 0.65)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05));
  if (halo) {
    canvas.drawRRect(rr.inflate(s * 0.03), Paint()
      ..color = color.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.16));
  }
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [_l(color, 0.35), color, _d(color, 0.45)], const [0, 0.5, 1]));
  canvas.save();
  canvas.clipRRect(rr);
  // Light inside, refracted towards the lower right.
  final glow = r.center + Offset(s * 0.12, s * 0.14);
  canvas.drawCircle(glow, s * 0.42, Paint()
    ..shader = ui.Gradient.radial(glow, s * 0.42, [_l(color, 0.75), _l(color, 0.2).withValues(alpha: 0.4), color.withValues(alpha: 0)], const [0, 0.5, 1]));
  // Inner bevel: lit at the top left, shaded at the bottom right.
  canvas.drawRRect(rr.deflate(s * 0.1), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.05
    ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0), _d(color, 0.4).withValues(alpha: 0.6)], const [0, 0.5, 1]));
  // Glass gloss sweeping across the top.
  canvas.drawPath(
    Path()
      ..moveTo(r.left, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + s * 0.18)
      ..quadraticBezierTo(r.center.dx, r.top + s * 0.5, r.left, r.top + s * 0.32)
      ..close(),
    Paint()..shader = ui.Gradient.linear(r.topCenter, r.topCenter + Offset(0, s * 0.45), [Colors.white.withValues(alpha: 0.65), Colors.white.withValues(alpha: 0.05)]),
  );
  canvas.drawCircle(r.topLeft + Offset(s * 0.26, s * 0.22), s * 0.06, Paint()..color = Colors.white);
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = _l(color, 0.55));
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
    paintChainCube(canvas, Rect.fromLTWH(cell * pad + 2, cell * pad + 2, cell - 4, cell - 4), color);
    final px = max(1, (side * dpr).ceil());
    return recorder.endRecording().toImageSync(px, px);
  }

  /// Draws a cube with its top-left corner at [origin].
  void draw(Canvas canvas, ChainColor color, Offset origin, {bool bright = false, double opacity = 1, double scale = 1}) {
    final image = (bright ? _bright : _normal)[color]!;
    final side = cell * (1 + 2 * pad) * scale;
    final centre = origin + Offset(cell / 2, cell / 2);
    final dst = Rect.fromCenter(center: centre, width: side, height: side);
    // Bilinear: mipmapped filtering is costly on some Windows GPUs.
    final paint = Paint()..filterQuality = FilterQuality.low;
    if (opacity < 1) paint.color = Colors.white.withValues(alpha: opacity);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), dst, paint);
  }

  void dispose() {
    for (final i in [..._normal.values, ..._bright.values]) {
      i.dispose();
    }
  }
}
