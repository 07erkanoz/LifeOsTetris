import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/tetromino.dart';
import '../../theme/palette.dart';

/// Paints one 2.5D "keycap" block: darker front face, gradient top face,
/// glossy highlight and a soft drop shadow (or coloured glow in dark mode).
void paintBlock(Canvas canvas, Offset origin, double s, Color color, {required Color shadeTarget, required bool emissive}) {
  final g = s * 0.06, w = s - 2 * g, depth = s * 0.17, r = Radius.circular(s * 0.2);
  final x = origin.dx + g, y = origin.dy + g;
  final full = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, w), r);

  final shadow = Paint()
    ..color = emissive ? color.withValues(alpha: 0.5) : const Color(0x401E2846)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * (emissive ? 0.22 : 0.16));
  canvas.drawRRect(full.shift(Offset(0, s * (emissive ? 0.04 : 0.14))), shadow);

  canvas.drawRRect(full, Paint()..color = shade(color, shadeTarget, 0.35));
  canvas.drawRRect(
    full,
    Paint()
      ..shader = ui.Gradient.linear(Offset(0, y + w - depth), Offset(0, y + w), [
        shade(color, shadeTarget, 0.2),
        shade(color, shadeTarget, 0.45),
      ]),
  );

  final top = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, w - depth), r);
  canvas.drawRRect(
    top,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(x, y),
        Offset(x + w, y + w),
        [lighten(color, 0.35), color, shade(color, shadeTarget, 0.1)],
        const [0, 0.55, 1],
      ),
  );

  final inset = s * 0.05;
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x + inset, y + inset, w - 2 * inset, w - depth - 2 * inset), Radius.circular(s * 0.15)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.035).clamp(0.8, 4)
      ..color = Colors.white.withValues(alpha: 0.38),
  );

  final glossTop = y + s * 0.1;
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x + s * 0.16, glossTop, w * 0.56, s * 0.2), Radius.circular(s * 0.1)),
    Paint()
      ..shader = ui.Gradient.linear(Offset(0, glossTop), Offset(0, glossTop + s * 0.22), [
        Colors.white.withValues(alpha: 0.7),
        Colors.white.withValues(alpha: 0),
      ]),
  );
  canvas.drawCircle(Offset(x + w * 0.8, y + s * 0.2), s * 0.045, Paint()..color = Colors.white.withValues(alpha: 0.9));
}

/// Pre-rendered block images for one cell size. Drawing cached images is far
/// cheaper than re-running gradients and blurs for every cell every frame.
class BlockSprites {
  BlockSprites._(this.cell, this.dpr, this.palette) : pad = cell * 0.45 {
    for (final type in PieceType.values) {
      _normal[type] = _render(
        (c, o) => paintBlock(c, o, cell, blockColors[type]!, shadeTarget: palette.shadeTarget, emissive: palette.isDark),
      );
      _ghost[type] = _render((c, o) => _paintGhost(c, o, blockColors[type]!));
    }
    gray = _render(
      (c, o) => paintBlock(
        c,
        o,
        cell,
        palette.isDark ? const Color(0xFF475069) : const Color(0xFF9AA3B8),
        shadeTarget: palette.shadeTarget,
        emissive: false,
      ),
    );
    white = _render(_paintWhite);
  }

  final double cell;
  final double dpr;
  final GamePalette palette;
  final double pad;

  final Map<PieceType, ui.Image> _normal = {};
  final Map<PieceType, ui.Image> _ghost = {};
  late final ui.Image gray;
  late final ui.Image white;

  ui.Image block(PieceType type) => _normal[type]!;
  ui.Image ghost(PieceType type) => _ghost[type]!;

  static final Map<String, BlockSprites> _cache = {};

  /// Shared sprites for a cell size; a handful of sizes are kept alive.
  static BlockSprites of(double cell, double dpr, GamePalette palette) {
    final rounded = (cell * 2).roundToDouble() / 2;
    final key = '$rounded@$dpr/${palette.isDark}';
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    if (_cache.length >= 8) {
      _cache.remove(_cache.keys.first);
    }
    return _cache[key] = BlockSprites._(rounded, dpr, palette);
  }

  ui.Image _render(void Function(Canvas canvas, Offset origin) paint) {
    final size = cell + 2 * pad;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paint(canvas, Offset(pad, pad));
    final picture = recorder.endRecording();
    final px = (size * dpr).ceil();
    final image = picture.toImageSync(px, px);
    picture.dispose();
    return image;
  }

  void _paintGhost(Canvas canvas, Offset o, Color color) {
    final g = cell * 0.1, w = cell - 2 * g;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + g, o.dy + g, w, w), Radius.circular(cell * 0.2));
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: palette.isDark ? 0.13 : 0.15));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (cell * 0.06).clamp(1.2, 4)
      ..color = (palette.isDark ? lighten(color, 0.2) : color).withValues(alpha: palette.isDark ? 0.7 : 0.85);
    final path = Path()..addRRect(rrect);
    final dash = cell * 0.16, gap = cell * 0.1;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), stroke);
      }
    }
  }

  void _paintWhite(Canvas canvas, Offset o) {
    final g = cell * 0.06, w = cell - 2 * g;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + g, o.dy + g, w, w), Radius.circular(cell * 0.2));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.25),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
  }

  /// Draws [image] so its block (without padding) covers the cell whose
  /// top-left corner is ([x], [y]), optionally scaled around its centre.
  void draw(Canvas canvas, ui.Image image, double x, double y, {double scale = 1, double opacity = 1, double rotation = 0}) {
    final extent = (cell + 2 * pad) * scale;
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    if (rotation == 0) {
      final cx = x + cell / 2, cy = y + cell / 2;
      canvas.drawImageRect(image, src, Rect.fromCenter(center: Offset(cx, cy), width: extent, height: extent), paint);
      return;
    }
    canvas.save();
    canvas.translate(x + cell / 2, y + cell / 2);
    canvas.rotate(rotation);
    canvas.drawImageRect(image, src, Rect.fromCenter(center: Offset.zero, width: extent, height: extent), paint);
    canvas.restore();
  }
}
