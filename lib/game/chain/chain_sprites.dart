import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/chain/chain_game.dart';

/// Zincir Küpler's own cube colours: vivid but not neon (the same in
/// every theme).
const Map<ChainColor, Color> chainColors = {
  ChainColor.yellow: Color(0xFFFFC414),
  ChainColor.magenta: Color(0xFFEE3BA6),
  ChainColor.blue: Color(0xFF3A6CF0),
  ChainColor.green: Color(0xFF1FBF5A),
  ChainColor.orange: Color(0xFFFF7F1E),
  ChainColor.gray: Color(0xFFC3CADC),
};

/// How the cubes look: vivid (the default) or one of the looks gifts
/// unlock.
enum ChainCubeStyle {
  vivid,

  /// Pastel lokum, powdered with sugar.
  lokum,

  /// İznik tiles: a cream glaze with a border and a motif.
  cini;

  static ChainCubeStyle parse(String? name) => values.firstWhere((s) => s.name == name, orElse: () => vivid);

  /// The colours of this look.
  Map<ChainColor, Color> get colors => switch (this) {
    vivid => chainColors,
    lokum => const {
      ChainColor.yellow: Color(0xFFF3D27A),
      ChainColor.magenta: Color(0xFFF29BC2),
      ChainColor.blue: Color(0xFFA2B9EE),
      ChainColor.green: Color(0xFFAAD58E),
      ChainColor.orange: Color(0xFFF5B07D),
      ChainColor.gray: Color(0xFFE2DCD8),
    },
    cini => const {
      ChainColor.yellow: Color(0xFFD4A017),
      ChainColor.magenta: Color(0xFFC0392B),
      ChainColor.blue: Color(0xFF1F4FA8),
      ChainColor.green: Color(0xFF2E8B57),
      ChainColor.orange: Color(0xFF1F9AA0),
      ChainColor.gray: Color(0xFF9AA0AE),
    },
  };
}

const Color garbageRed = Color(0xFFD81E24);

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _d(Color c, double t) => Color.lerp(c, Colors.black, t)!;

/// The motif of colour [i] (a ChainColor index): star, heart, diamond,
/// leaf, circle; none for gray. The colours read by shape too.
Path? chainSymbol(int i, Offset c, double r) => switch (i) {
  0 => _star(c, r),
  1 =>
    Path()
      ..moveTo(c.dx, c.dy + r * 0.9)
      ..cubicTo(c.dx - r * 1.4, c.dy - r * 0.1, c.dx - r * 0.6, c.dy - r * 1.2, c.dx, c.dy - r * 0.4)
      ..cubicTo(c.dx + r * 0.6, c.dy - r * 1.2, c.dx + r * 1.4, c.dy - r * 0.1, c.dx, c.dy + r * 0.9)
      ..close(),
  2 => Path()..addPolygon([c + Offset(0, -r), c + Offset(r * 0.8, 0), c + Offset(0, r), c + Offset(-r * 0.8, 0)], true),
  3 =>
    Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 1.1, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 1.1, c.dy, c.dx, c.dy - r)
      ..close(),
  4 => Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.75)),
  _ => null,
};

Path _star(Offset c, double r) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -pi / 2 + i * pi / 5;
    final q = c + Offset(cos(a), sin(a)) * (i.isEven ? r : r * 0.5);
    i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
  }
  return p..close();
}

/// A cube in [style]. Vivid: rich colour, glossy without glare (a domed
/// gradient, an inner bevel, a small soft gloss and nothing that glows).
/// Lokum and çini show the colour's motif; [symbol] is its index.
void paintChainCube(Canvas canvas, Rect r, Color color, {ChainCubeStyle style = ChainCubeStyle.vivid, int symbol = -1}) {
  final s = r.width;
  switch (style) {
    case ChainCubeStyle.vivid:
      final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.2));
      canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.4));
      canvas.drawRRect(
        rr,
        Paint()..shader = ui.Gradient.radial(r.topLeft + Offset(s * 0.35, s * 0.3), s * 0.95, [_l(color, 0.25), color, _d(color, 0.28)], const [0, 0.5, 1]),
      );
      canvas.drawRRect(
        rr.deflate(s * 0.07),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.04
          ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0),
            _d(color, 0.35).withValues(alpha: 0.5),
          ], const [0, 0.5, 1]),
      );
      canvas.drawOval(Rect.fromLTWH(r.left + s * 0.16, r.top + s * 0.11, s * 0.4, s * 0.16), Paint()..color = Colors.white.withValues(alpha: 0.28));
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.2, s * 0.022)
          ..color = _d(color, 0.3),
      );
    case ChainCubeStyle.lokum:
      final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.26));
      canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.3));
      canvas.drawRRect(rr, Paint()..color = _d(color, 0.12));
      final top = RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, s, s * 0.84), Radius.circular(s * 0.26));
      canvas.drawRRect(top, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [_l(color, 0.2), color]));
      canvas.save();
      canvas.clipRRect(top);
      canvas.drawRect(
        Rect.fromLTWH(r.left, r.top, s, s * 0.36),
        Paint()..shader = ui.Gradient.linear(r.topCenter, r.topCenter + Offset(0, s * 0.36), [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)]),
      );
      final rnd = Random(symbol * 7 + 1);
      for (var k = 0; k < 16; k++) {
        canvas.drawCircle(
          Offset(r.left + rnd.nextDouble() * s, r.top + rnd.nextDouble() * s * 0.5),
          s * (0.012 + rnd.nextDouble() * 0.014),
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
      }
      canvas.restore();
      final mark = chainSymbol(symbol, r.center + Offset(0, s * 0.02), s * 0.17);
      if (mark != null) canvas.drawPath(mark, Paint()..color = _d(color, 0.3).withValues(alpha: 0.45));
    case ChainCubeStyle.cini:
      final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.12));
      canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.35));
      canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [Color(0xFFFFFBF2), Color(0xFFEDE3D0)]));
      canvas.drawRRect(
        rr.deflate(s * 0.07),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.08
          ..color = color,
      );
      final mark = chainSymbol(symbol, r.center, s * 0.22);
      if (mark != null) canvas.drawPath(mark, Paint()..color = color);
      for (final c in [
        r.topLeft + Offset(s * 0.2, s * 0.2),
        r.topRight + Offset(-s * 0.2, s * 0.2),
        r.bottomLeft + Offset(s * 0.2, -s * 0.2),
        r.bottomRight + Offset(-s * 0.2, -s * 0.2),
      ]) {
        canvas.drawCircle(c, s * 0.035, Paint()..color = color.withValues(alpha: 0.7));
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.left + s * 0.16, r.top + s * 0.13, s * 0.3, s * 0.06), Radius.circular(s)),
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
  }
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

/// The cubes drawn once per size and look into images, so a frame only
/// copies them: the gradients are too slow to paint 80 times a frame.
class ChainSprites {
  ChainSprites._(this.cell, this.dpr, this.style, this._normal, this._bright);

  static ChainSprites? _cache;

  static ChainSprites of(double cell, double dpr, [ChainCubeStyle style = ChainCubeStyle.vivid]) {
    final c = _cache;
    if (c != null && c.cell == cell && c.dpr == dpr && c.style == style) return c;
    c?.dispose();
    final colors = style.colors;
    final normal = {for (final e in colors.entries) e.key: _render(cell, dpr, e.value, style, e.key.index)};
    final bright = {for (final e in colors.entries) e.key: _render(cell, dpr, _l(e.value, 0.45), style, e.key.index)};
    return _cache = ChainSprites._(cell, dpr, style, normal, bright);
  }

  /// Room around a cube for its shadow, as a share of the cell.
  static const double pad = 0.25;

  final double cell;
  final double dpr;
  final ChainCubeStyle style;
  final Map<ChainColor, ui.Image> _normal;
  final Map<ChainColor, ui.Image> _bright;

  static ui.Image _render(double cell, double dpr, Color color, ChainCubeStyle style, int symbol) {
    final side = cell * (1 + 2 * pad);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paintChainCube(canvas, Rect.fromLTWH(cell * pad + 2, cell * pad + 2, cell - 4, cell - 4), color, style: style, symbol: symbol);
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
