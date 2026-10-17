import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/tetromino.dart';
import '../../theme/palette.dart';
import '../blocks/jewels.dart';
import '../chain/chain_sprites.dart' show paintChainCube;

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

/// Jelly HD (the neon skin): the glass jelly made calmer and finer. Light
/// enters from the top and glows out of the bottom, a soft wide gloss and
/// one small reflection replace the hard white bar and dot, a faint ground
/// shadow replaces most of the coloured halo, and the edges are crisp. With
/// [bubbles] (a seed) a few faint air bubbles float inside, placed by it.
void paintJellyHd(Canvas canvas, Offset origin, double s, Color color, {required Color shadeTarget, int? bubbles}) {
  final b = Rect.fromLTWH(origin.dx, origin.dy, s, s).deflate(s * 0.055);
  final rr = RRect.fromRectAndRadius(b, Radius.circular(s * 0.24));
  final deep = Color.lerp(color, shadeTarget, 0.55)!;
  canvas.drawRRect(
    rr.shift(Offset(0, s * 0.07)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.09),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..color = color.withValues(alpha: 0.14)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.18),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = ui.Gradient.linear(
        b.topCenter,
        b.bottomCenter,
        [Color.lerp(color, Colors.white, 0.16)!, color, Color.lerp(color, shadeTarget, 0.24)!],
        const [0, 0.45, 1],
      ),
  );
  canvas.save();
  canvas.clipRRect(rr);
  final lip = Rect.fromLTWH(b.left, b.bottom - s * 0.22, b.width, s * 0.22);
  canvas.drawRect(
    lip,
    Paint()..shader = ui.Gradient.linear(lip.topCenter, lip.bottomCenter, [deep.withValues(alpha: 0), deep.withValues(alpha: 0.45)]),
  );
  final glowAt = b.bottomCenter - Offset(0, s * 0.24);
  final inner = Color.lerp(color, Colors.white, 0.4)!;
  canvas.drawCircle(
    glowAt,
    s * 0.42,
    Paint()..shader = ui.Gradient.radial(glowAt, s * 0.42, [inner.withValues(alpha: 0.42), inner.withValues(alpha: 0)]),
  );
  if (bubbles != null) {
    final rnd = Random(bubbles * 7919 + color.toARGB32());
    for (var i = 0; i < 2 + rnd.nextInt(2); i++) {
      final c = Offset(b.left + b.width * (0.22 + rnd.nextDouble() * 0.56), b.top + b.height * (0.45 + rnd.nextDouble() * 0.38));
      final rad = s * (0.03 + rnd.nextDouble() * 0.035);
      canvas.drawCircle(c, rad, Paint()..color = Colors.white.withValues(alpha: 0.1));
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012,
      );
      canvas.drawCircle(c - Offset(rad * 0.35, rad * 0.35), rad * 0.3, Paint()..color = Colors.white.withValues(alpha: 0.55));
    }
  }
  final gloss = RRect.fromRectAndRadius(Rect.fromLTWH(b.left + s * 0.1, b.top + s * 0.06, b.width - s * 0.2, s * 0.34), Radius.circular(s * 0.17));
  canvas.drawRRect(
    gloss,
    Paint()
      ..shader = ui.Gradient.linear(
        gloss.outerRect.topCenter,
        gloss.outerRect.bottomCenter,
        [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0)],
      ),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(b.left + s * 0.17, b.top + s * 0.11, s * 0.24, s * 0.065), Radius.circular(s * 0.04)),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.008),
  );
  canvas.restore();
  canvas.drawRRect(
    rr.deflate(s * 0.02),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..shader = ui.Gradient.linear(
        b.topCenter,
        b.topCenter + Offset(0, s * 0.35),
        [Colors.white.withValues(alpha: 0.38), Colors.white.withValues(alpha: 0)],
      ),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, s * 0.022)
      ..color = deep.withValues(alpha: 0.9),
  );
}

/// A block in the style of [palette]'s skin. [variant] picks the bubbles of
/// the neon Jelly HD block.
void paintSkinBlock(Canvas canvas, Offset origin, double s, Color color, GamePalette palette, {bool? hd, int variant = 0}) => switch (palette.skin) {
  GameSkin.glass =>
    isNeon(palette)
        ? paintJellyHd(canvas, origin, s, color, shadeTarget: palette.shadeTarget, bubbles: variant)
        : paintBlock(canvas, origin, s, color, shadeTarget: palette.shadeTarget, emissive: palette.isDark),
  GameSkin.toy =>
    (hd ?? hdBlocks) ? paintToyBlockHd(canvas, origin, s, color, palette.ink) : paintToyBlock(canvas, origin, s, color, palette.ink),
  GameSkin.pixel => paintPixelBlock(canvas, origin, s, color, palette.ink),
};

/// HD toy brick: the same outlined shape as [paintToyBlock], with a lit face
/// gradient, bevelled rim, curved gloss, a shaded lip and soft side shading.
void paintToyBlockHd(Canvas canvas, Offset origin, double s, Color color, Color ink) {
  final g = s * 0.03, w = s - 2 * g;
  final outline = max(1.2, s * 0.06);
  final x = origin.dx + g, y = origin.dy + g;
  final r = Radius.circular(s * 0.22);
  final body = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, w), r);
  final lip = s * 0.16;
  final faceRect = Rect.fromLTWH(x, y, w, w - lip);
  final face = RRect.fromRectAndRadius(faceRect, r);

  // Lip: darker, shaded towards the bottom edge.
  canvas.drawRRect(
    body,
    Paint()
      ..shader = ui.Gradient.linear(Offset(0, y + w - lip * 1.6), Offset(0, y + w), [
        Color.lerp(color, ink, 0.22)!,
        Color.lerp(color, ink, 0.5)!,
      ]),
  );
  // Face: lit from the top left.
  canvas.drawRRect(
    face,
    Paint()
      ..shader = ui.Gradient.linear(
        faceRect.topLeft,
        faceRect.bottomRight,
        [lighten(color, 0.28), color, Color.lerp(color, ink, 0.1)!],
        const [0, 0.5, 1],
      ),
  );
  // Side shading: a touch of light on the left, shade on the right.
  canvas.drawRRect(
    face,
    Paint()
      ..shader = ui.Gradient.linear(
        faceRect.centerLeft,
        faceRect.centerRight,
        [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0.1),
        ],
        const [0, 0.25, 0.75, 1],
      ),
  );
  // Bevel: a bright rim along the top of the face, fading downwards.
  canvas.drawRRect(
    face.deflate(s * 0.07),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.8, s * 0.035)
      ..shader = ui.Gradient.linear(faceRect.topCenter, faceRect.bottomCenter, [
        Colors.white.withValues(alpha: 0.6),
        Colors.white.withValues(alpha: 0.08),
      ]),
  );
  // Crease where the face meets the lip.
  canvas.drawLine(
    Offset(x + s * 0.12, y + w - lip),
    Offset(x + w - s * 0.12, y + w - lip),
    Paint()
      ..color = Color.lerp(color, ink, 0.55)!.withValues(alpha: 0.6)
      ..strokeWidth = max(0.6, s * 0.025),
  );
  // Curved gloss and a specular point.
  final gloss = Path()
    ..moveTo(x + s * 0.17, y + s * 0.34)
    ..quadraticBezierTo(x + s * 0.17, y + s * 0.13, x + s * 0.4, y + s * 0.13)
    ..lineTo(x + s * 0.62, y + s * 0.13)
    ..quadraticBezierTo(x + s * 0.4, y + s * 0.18, x + s * 0.27, y + s * 0.36)
    ..close();
  canvas.drawPath(
    gloss,
    Paint()
      ..shader = ui.Gradient.linear(Offset(x, y + s * 0.12), Offset(x + s * 0.5, y + s * 0.36), [
        Colors.white.withValues(alpha: 0.85),
        Colors.white.withValues(alpha: 0.15),
      ]),
  );
  canvas.drawCircle(Offset(x + w - s * 0.2, y + s * 0.2), s * 0.04, Paint()..color = Colors.white.withValues(alpha: 0.9));
  canvas.drawCircle(
    Offset(x + w - s * 0.2, y + s * 0.2),
    s * 0.09,
    Paint()
      ..shader = ui.Gradient.radial(Offset(x + w - s * 0.2, y + s * 0.2), s * 0.09, [
        Colors.white.withValues(alpha: 0.35),
        Colors.white.withValues(alpha: 0),
      ]),
  );
  canvas.drawRRect(
    body.deflate(outline / 2),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outline
      ..color = ink,
  );
}

/// Flat toy brick: ink outline, a darker lip at the bottom and one short
/// shine stroke. No gradients or glow.
void paintToyBlock(Canvas canvas, Offset origin, double s, Color color, Color ink) {
  final g = s * 0.03, w = s - 2 * g;
  final outline = max(1.4, s * 0.075);
  final x = origin.dx + g, y = origin.dy + g;
  final r = Radius.circular(s * 0.22);
  final body = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, w), r);
  final lip = s * 0.17;
  canvas.drawRRect(body, Paint()..color = Color.lerp(color, ink, 0.32)!);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, w - lip), r), Paint()..color = color);
  final shine = Paint()
    ..color = Colors.white.withValues(alpha: 0.75)
    ..strokeWidth = s * 0.085
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(x + s * 0.24, y + s * 0.21), Offset(x + s * 0.44, y + s * 0.21), shine);
  canvas.drawCircle(Offset(x + s * 0.2, y + s * 0.36), s * 0.042, Paint()..color = Colors.white.withValues(alpha: 0.75));
  canvas.drawRRect(
    body.deflate(outline / 2),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outline
      ..color = ink,
  );
}

/// Bevelled pixel-art block on an 8×8 grid: light top/left edges, dark
/// bottom/right edges, one highlight pixel, black border.
void paintPixelBlock(Canvas canvas, Offset origin, double s, Color color, Color ink) {
  final u = s / 8;
  final o = origin;
  Rect px(double x, double y, double w, double h) => Rect.fromLTWH(o.dx + x * u, o.dy + y * u, w * u, h * u);
  canvas.drawRect(px(0, 0, 8, 8), Paint()..color = ink);
  canvas.drawRect(px(0.5, 0.5, 7, 7), Paint()..color = color);
  final light = Paint()..color = Color.lerp(color, Colors.white, 0.5)!;
  final dark = Paint()..color = Color.lerp(color, Colors.black, 0.38)!;
  canvas.drawRect(px(0.5, 0.5, 7, 1), light);
  canvas.drawRect(px(0.5, 0.5, 1, 7), light);
  canvas.drawRect(px(0.5, 6.5, 7, 1), dark);
  canvas.drawRect(px(6.5, 0.5, 1, 7), dark);
  canvas.drawRect(px(1.5, 1.5, 1, 1), Paint()..color = Colors.white);
}

/// Round black bomb with a red glow, a fuse and a spark.
void paintBomb(Canvas canvas, Offset origin, double s) {
  final c = origin + Offset(s * 0.48, s * 0.56);
  final r = s * 0.36;
  canvas.drawCircle(
    c,
    r * 1.25,
    Paint()
      ..color = const Color(0xFFF43F5E).withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.2),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()..shader = ui.Gradient.radial(c - Offset(r * 0.35, r * 0.35), r * 1.3, [const Color(0xFF5B6478), const Color(0xFF151824)]),
  );
  canvas.drawCircle(c - Offset(r * 0.38, r * 0.4), r * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.55));
  // Fuse cap and fuse.
  final cap = Rect.fromCenter(center: c + Offset(r * 0.55, -r * 0.78), width: r * 0.5, height: r * 0.34);
  canvas.save();
  canvas.translate(cap.center.dx, cap.center.dy);
  canvas.rotate(0.6);
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: cap.width, height: cap.height), Radius.circular(s * 0.04)),
    Paint()..color = const Color(0xFF8B93A7),
  );
  canvas.restore();
  final fuseEnd = c + Offset(r * 1.05, -r * 1.25);
  canvas.drawPath(
    Path()
      ..moveTo(cap.center.dx, cap.center.dy)
      ..quadraticBezierTo(c.dx + r * 1.1, c.dy - r * 0.9, fuseEnd.dx, fuseEnd.dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD6B57A),
  );
  canvas.drawCircle(
    fuseEnd,
    s * 0.11,
    Paint()
      ..color = const Color(0xFFFDE047)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06),
  );
  canvas.drawCircle(fuseEnd, s * 0.05, Paint()..color = Colors.white);
}

/// Golden puzzle target: a gold block with a white star.
void paintGem(Canvas canvas, Offset origin, double s, {required Color shadeTarget, GamePalette? palette}) {
  if (palette != null && palette.flat) {
    paintSkinBlock(canvas, origin, s, blockColors[PieceType.gem]!, palette);
    final c = origin + Offset(s * 0.5, s * (palette.skin == GameSkin.toy ? 0.43 : 0.5));
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final r = i.isEven ? s * 0.24 : s * 0.1;
      final p = c + Offset(cos(a) * r, sin(a) * r);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, Paint()..color = Colors.white);
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, s * 0.05)
        ..strokeJoin = palette.skin == GameSkin.pixel ? StrokeJoin.miter : StrokeJoin.round
        ..color = palette.ink,
    );
    return;
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(origin.dx + s * 0.02, origin.dy + s * 0.02, s * 0.96, s * 0.96), Radius.circular(s * 0.26)),
    Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.18),
  );
  paintBlock(canvas, origin, s, const Color(0xFFFBBF24), shadeTarget: shadeTarget, emissive: false);
  final c = origin + Offset(s * 0.5, s * 0.44);
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = -pi / 2 + i * pi / 5;
    final r = i.isEven ? s * 0.25 : s * 0.11;
    final p = c + Offset(cos(a) * r, sin(a) * r);
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  star.close();
  canvas.drawPath(star.shift(Offset(0, s * 0.03)), Paint()..color = const Color(0x66B45309));
  canvas.drawPath(star, Paint()..color = Colors.white);
}

/// Golden drill bit pointing down.
void paintDrill(Canvas canvas, Offset origin, double s) {
  final cx = origin.dx + s / 2, top = origin.dy + s * 0.08, bottom = origin.dy + s * 0.94;
  final half = s * 0.3;
  canvas.drawRect(
    Rect.fromLTRB(cx - half, top, cx + half, bottom),
    Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.18),
  );
  final body = Path()
    ..moveTo(cx - half, top)
    ..lineTo(cx + half, top)
    ..lineTo(cx + half, top + s * 0.32)
    ..lineTo(cx, bottom)
    ..lineTo(cx - half, top + s * 0.32)
    ..close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - half, 0),
        Offset(cx + half, 0),
        [const Color(0xFFFDE68A), const Color(0xFFF59E0B), const Color(0xFFB45309)],
        const [0, 0.5, 1],
      ),
  );
  // Spiral grooves.
  final groove = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.05
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF92400E).withValues(alpha: 0.8);
  for (var i = 0; i < 3; i++) {
    final y = top + s * (0.38 + i * 0.15);
    final w = half * (1 - (y - top - s * 0.32) / (bottom - top - s * 0.32)).clamp(0.15, 1.0);
    canvas.drawLine(Offset(cx - w, y), Offset(cx + w, y - s * 0.08), groove);
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTRB(cx - half, top, cx + half, top + s * 0.14), Radius.circular(s * 0.04)),
    Paint()..color = const Color(0xFF78350F),
  );
}

/// Pre-rendered block images for one cell size. Drawing cached images is far
/// cheaper than re-running gradients and blurs for every cell every frame.
/// Bulmaca Küpler's vivid block colours.
const Map<PieceType, Color> vividBlockColors = {
  PieceType.i: Color(0xFF1FB8E0),
  PieceType.o: Color(0xFFFFC414),
  PieceType.t: Color(0xFFA24CF0),
  PieceType.s: Color(0xFF1FBF5A),
  PieceType.z: Color(0xFFF2425A),
  PieceType.j: Color(0xFF3A6CF0),
  PieceType.l: Color(0xFFFF8A1E),
  PieceType.mono: Color(0xFFC3CADC),
  PieceType.bomb: Color(0xFFF2425A),
  PieceType.drill: Color(0xFFFFB238),
  PieceType.gem: Color(0xFFFFC414),
};

class BlockSprites {
  BlockSprites._(this.cell, this.dpr, this.palette) : pad = cell * 0.45, variants = palette.vividBlocks ? 1 : (isNeon(palette) ? 3 : 1) {
    if (palette.vividBlocks) {
      _vivid();
      return;
    }
    for (final type in PieceType.values) {
      _normal[type] = _render(
        (c, o) => switch (type) {
          PieceType.bomb => paintBomb(c, o, cell),
          PieceType.drill => paintDrill(c, o, cell),
          PieceType.gem => paintGem(c, o, cell, shadeTarget: palette.shadeTarget, palette: palette),
          _ => paintSkinBlock(c, o, cell, blockColors[type]!, palette),
        },
      );
      if (type != PieceType.bomb && type != PieceType.drill) {
        _shaded[type] = _render((c, o) {
          if (type == PieceType.gem) {
            paintGem(c, o, cell, shadeTarget: palette.shadeTarget, palette: palette);
          } else {
            paintSkinBlock(c, o, cell, blockColors[type]!, palette);
          }
          _paintContactShadow(c, o);
        });
      }
      // Neon jelly cubes come in a few bubble patterns, picked per cell.
      if (variants > 1 && type != PieceType.bomb && type != PieceType.drill && type != PieceType.gem) {
        for (var v = 1; v < variants; v++) {
          _normalVariants.putIfAbsent(type, () => []).add(_render((c, o) => paintSkinBlock(c, o, cell, blockColors[type]!, palette, variant: v)));
          _shadedVariants.putIfAbsent(type, () => []).add(
            _render((c, o) {
              paintSkinBlock(c, o, cell, blockColors[type]!, palette, variant: v);
              _paintContactShadow(c, o);
            }),
          );
        }
      }
      _ghost[type] = _render((c, o) => _paintGhost(c, o, blockColors[type]!));
      _aura[type] = _render((c, o) => _paintAura(c, o, blockColors[type]!));
    }
    gray = _render(
      (c, o) => palette.flat
          ? paintSkinBlock(c, o, cell, palette.isDark ? const Color(0xFF6A6080) : const Color(0xFFB7AEC2), palette)
          : paintBlock(
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

  /// Vivid look: glossy cubes in [vividBlockColors] and the four jewels.
  void _vivid() {
    Rect box(Offset o) => Rect.fromLTWH(o.dx, o.dy, cell, cell).deflate(cell * 0.04);
    for (final type in PieceType.values) {
      final color = vividBlockColors[type]!;
      _normal[type] = _render(
        (c, o) => switch (type) {
          PieceType.bomb => paintBomb(c, o, cell),
          PieceType.drill => paintDrill(c, o, cell),
          PieceType.gem => paintJewelBlock(c, box(o), 0),
          _ => paintChainCube(c, box(o), color),
        },
      );
      _ghost[type] = _render((c, o) => _paintGhost(c, o, color));
      _aura[type] = _render((c, o) => _paintAura(c, o, color));
    }
    for (var k = 0; k < jewelTones.length; k++) {
      _jewels.add(_render((c, o) => paintJewelBlock(c, box(o), k)));
    }
    gray = _render((c, o) => paintChainCube(c, box(o), const Color(0xFF6A6490)));
    white = _render(_paintWhite);
  }

  final List<ui.Image> _jewels = [];

  /// The block with jewel [kind] in it.
  ui.Image jewel(int kind) => _jewels.isEmpty ? _normal[PieceType.gem]! : _jewels[kind % _jewels.length];

  final Map<PieceType, ui.Image> _normal = {};
  final Map<PieceType, ui.Image> _shaded = {};
  final Map<PieceType, List<ui.Image>> _normalVariants = {};
  final Map<PieceType, List<ui.Image>> _shadedVariants = {};

  /// Looks per block type (neon: bubble patterns); 1 for the other skins.
  final int variants;

  /// A stable look for the cell at ([x], [y]).
  static int variantAt(int x, int y) => (x * 7 + y * 13) % 3;
  final Map<PieceType, ui.Image> _ghost = {};
  final Map<PieceType, ui.Image> _aura = {};
  late final ui.Image gray;
  late final ui.Image white;

  ui.Image block(PieceType type, [int variant = 0]) =>
      variant % variants == 0 ? _normal[type]! : (_normalVariants[type]?[variant % variants - 1] ?? _normal[type]!);
  ui.Image ghost(PieceType type) => _ghost[type]!;

  /// The block with the shadow of one resting on it (falls back to the
  /// plain block for bombs and drills).
  ui.Image shaded(PieceType type, [int variant = 0]) =>
      (variant % variants == 0 ? null : _shadedVariants[type]?[variant % variants - 1]) ?? _shaded[type] ?? _normal[type]!;

  /// Soft coloured glow behind the active piece (pre-blurred, so drawing it
  /// costs no per-frame blur).
  ui.Image aura(PieceType type) => _aura[type]!;

  static final Map<String, BlockSprites> _cache = {};

  /// Shared sprites for a cell size; a handful of sizes are kept alive.
  static BlockSprites of(double cell, double dpr, GamePalette palette) {
    final rounded = (cell * 2).roundToDouble() / 2;
    final key = '$rounded@$dpr/${palette.vividBlocks ? 'vivid' : palette.skin.name}/$hdBlocks/${palette.isDark}/$neonStyle';
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    if (_cache.length >= 16) {
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

  /// Darkens the top of a block just drawn (only where it is opaque).
  void _paintContactShadow(Canvas canvas, Offset o) {
    final shade = palette.shadeTarget;
    switch (palette.skin) {
      case GameSkin.pixel:
        canvas.drawRect(
          Rect.fromLTWH(o.dx, o.dy, cell, cell * 0.125),
          Paint()
            ..color = shade.withValues(alpha: 0.24)
            ..blendMode = BlendMode.srcATop,
        );
      case GameSkin.toy || GameSkin.glass:
        final strength = palette.skin == GameSkin.glass ? 0.16 : 0.24;
        final band = Rect.fromLTWH(o.dx, o.dy, cell, cell * 0.24);
        canvas.drawRect(
          band,
          Paint()
            ..blendMode = BlendMode.srcATop
            ..shader = ui.Gradient.linear(band.topCenter, band.bottomCenter, [shade.withValues(alpha: strength), shade.withValues(alpha: 0)]),
        );
    }
  }

  void _paintGhost(Canvas canvas, Offset o, Color color) {
    final g = cell * 0.1, w = cell - 2 * g;
    final radius = switch (palette.skin) {
      GameSkin.pixel => 0.0,
      GameSkin.toy => cell * 0.22,
      GameSkin.glass => cell * 0.2,
    };
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + g, o.dy + g, w, w), Radius.circular(radius));
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

  void _paintAura(Canvas canvas, Offset o, Color color) {
    // Flat skins keep pieces crisp: no glow.
    if (palette.flat) return;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(o.dx + cell * 0.1, o.dy + cell * 0.1, cell * 0.8, cell * 0.8),
      Radius.circular(cell * 0.25),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.17),
    );
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
    // The sprites are drawn at their own size: plain bilinear filtering is
    // enough, and mipmapped filtering made each draw a costly copy on some
    // Windows GPUs (a frame took 35 ms instead of 9).
    final paint = Paint()
      ..filterQuality = FilterQuality.low
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
