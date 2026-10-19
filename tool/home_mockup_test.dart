// Mock-ups for a sweeter home menu: Lokum hosting with suggestions, mode
// cards that show a little of each game (moving), three layouts.
//   flutter test tool/home_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): ana-a-oyuncak.png,
// ana-a-neon.png, ana-b-vitrin.png, ana-c-oneri.png and frames for a GIF
// (ana-a-frames/).
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show paintChainCube;
import 'package:lifeos_kupler/game/render/block_sprites.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';
const double _w = 430, _h = 932;

// ------------------------------------------------------------------ looks --

class Look {
  const Look({
    required this.sky,
    required this.cardTop,
    required this.cardBottom,
    required this.border,
    required this.ink,
    required this.muted,
    required this.neon,
    required this.font,
    this.pixel = false,
  });

  final List<Color> sky;
  final Color cardTop, cardBottom, border, ink, muted;
  final bool neon;
  final String font;
  final bool pixel;
}

const toy = Look(
  sky: [Color(0xFFFFD9EE), Color(0xFFE9D2FF), Color(0xFFC9B6FF)],
  cardTop: Color(0xFFFFFFFF),
  cardBottom: Color(0xFFFFF0F8),
  border: Color(0xFFFFFFFF),
  ink: Color(0xFF5A1F7A),
  muted: Color(0xFF9A6AB5),
  neon: false,
  font: 'Baloo2',
);

const neon = Look(
  sky: [Color(0xFF0B1030), Color(0xFF121A44), Color(0xFF070B22)],
  cardTop: Color(0xE6182352),
  cardBottom: Color(0xE60E1638),
  border: Color(0xFF38BDF8),
  ink: Color(0xFFF1F5FF),
  muted: Color(0xFF93A4D8),
  neon: true,
  font: 'Inter',
);

const pixel = Look(
  sky: [Color(0xFF1B1B44), Color(0xFF23235A), Color(0xFF15153A)],
  cardTop: Color(0xFF2A2F6A),
  cardBottom: Color(0xFF242864),
  border: Color(0xFF5A66C8),
  ink: Color(0xFFFFFFFF),
  muted: Color(0xFFB8C0FF),
  neon: false,
  font: 'Jersey10',
  pixel: true,
);

const _pixelYellow = Color(0xFFFFD23F);

/// Draws [draw] (in canvas coordinates of [r]) at 1/[factor] resolution
/// and blows it up without smoothing: instant pixel art.
void _pixelated(Canvas canvas, Rect r, int factor, void Function(Canvas c) draw) {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder)
    ..scale(1 / factor)
    ..translate(-r.left, -r.top);
  draw(c);
  final image = recorder.endRecording().toImageSync(max(1, (r.width / factor).ceil()), max(1, (r.height / factor).ceil()));
  canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(r.left, r.top, image.width * factor.toDouble(), image.height * factor.toDouble()), Paint()..filterQuality = FilterQuality.none);
}

/// Lokum dressed for the theme: as he is on toy skins, glowing from inside
/// with a neon rim on neon, in 8-bit on pixel.
void themedLokum(Canvas canvas, Offset c, double size, LokumPose pose, Look look, {double hop = 0}) {
  if (look.pixel) {
    final r = Rect.fromCenter(center: c - Offset(0, size * 0.08), width: size * 1.3, height: size * 1.5);
    _pixelated(canvas, r, max(3, (size / 22).round()), (cc) => paintLokum(cc, c, size, pose: pose, hop: hop));
    return;
  }
  if (!look.neon) {
    paintLokum(canvas, c, size, pose: pose, hop: hop);
    return;
  }
  final body = RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, size * 0.04), width: size * 1.02, height: size * 1.0), Radius.circular(size * 0.46));
  // Soft light behind him.
  canvas.drawCircle(c, size * 0.85, Paint()
    ..shader = ui.Gradient.radial(c, size * 0.85, [const Color(0xFFFF4FD8).withValues(alpha: 0.45), const Color(0xFF38BDF8).withValues(alpha: 0.12), const Color(0x00000000)], const [0, 0.6, 1]));
  // Jelly a little see-through, lit from inside.
  final layer = Rect.fromCenter(center: c, width: size * 2, height: size * 2);
  canvas.saveLayer(layer, Paint()..color = Colors.white.withValues(alpha: 0.88));
  paintLokum(canvas, c, size, pose: pose, hop: hop);
  canvas.drawCircle(c + Offset(0, size * 0.12), size * 0.4, Paint()
    ..blendMode = BlendMode.srcATop
    ..shader = ui.Gradient.radial(c + Offset(0, size * 0.12), size * 0.4, [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)]));
  canvas.restore();
  // Neon rim.
  for (final (w, blur, color) in [(6.0, 8.0, const Color(0xFFFF4FD8)), (2.2, 0.0, const Color(0xFFFFB3F2))]) {
    canvas.drawRRect(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = color.withValues(alpha: blur > 0 ? 0.7 : 1)
      ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null);
  }
  canvas.drawArc(body.outerRect.deflate(size * 0.08), pi * 1.1, pi * 0.5, false, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF7DE3FF));
}

const _modeColors = {
  'super': [Color(0xFFB45BFF), Color(0xFFFF5FB8)],
  'classic': [Color(0xFF3B82F6), Color(0xFF38BDF8)],
  'puzzle': [Color(0xFF14B8A6), Color(0xFF6EE7B7)],
  'chain': [Color(0xFFFF33EE), Color(0xFF1FE85A)],
  'sugar': [Color(0xFFFF4D8D), Color(0xFFFFD23F)],
  'daily': [Color(0xFF22C55E), Color(0xFF86EFAC)],
};

const _shade = Color(0xFF1A0B2E);
const _cubes = [Color(0xFFB45BFF), Color(0xFF3CC4DC), Color(0xFFFFC93C), Color(0xFF4ADE80), Color(0xFFFF5A5F), Color(0xFF4F7CFF), Color(0xFFFF9A3C)];

// ------------------------------------------------------------------- text --

void _text(Canvas canvas, String text, Offset at, double size, Color color,
    {String font = 'Baloo2', FontWeight weight = FontWeight.w800, bool centre = false, double width = 400, double height = 1.1}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: font, fontSize: size, fontWeight: weight, height: height, textAlign: centre ? TextAlign.center : TextAlign.left))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: font, fontSize: size, fontWeight: weight, height: height))
    ..addText(text);
  final p = b.build()..layout(ui.ParagraphConstraints(width: width));
  canvas.drawParagraph(p, centre ? at - Offset(width / 2, p.height / 2) : at);
}

Paint _grad(Rect r, List<Color> colors, {bool vertical = true}) => Paint()
  ..shader = ui.Gradient.linear(vertical ? r.topCenter : r.centerLeft, vertical ? r.bottomCenter : r.centerRight, colors,
      [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);

// ------------------------------------------------------------- the pieces --

void _cube(Canvas canvas, Offset o, double s, Color c) => paintJellyHd(canvas, o, s, c, shadeTarget: _shade, bubbles: 1);

void _card(Canvas canvas, RRect r, Look look, {Color? glow}) {
  if (look.pixel) {
    final q = r.outerRect;
    canvas.drawRect(q.shift(const Offset(4, 4)), Paint()..color = const Color(0xFF0A0A22));
    canvas.drawRect(q, _grad(q, [look.cardTop, look.cardBottom]));
    canvas.drawRect(q.deflate(1.5), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = glow == null ? look.border : Color.lerp(glow, look.border, 0.3)!);
    return;
  }
  if (look.neon) {
    canvas.drawRRect(r, Paint()
      ..color = (glow ?? look.border).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawRRect(r, _grad(r.outerRect, [look.cardTop, look.cardBottom]));
    canvas.drawRRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = (glow ?? look.border).withValues(alpha: 0.85));
  } else {
    canvas.drawRRect(r.shift(const Offset(0, 6)), Paint()..color = const Color(0xFFB27BD8).withValues(alpha: 0.45));
    canvas.drawRRect(r, _grad(r.outerRect, [look.cardTop, look.cardBottom]));
    canvas.drawRRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = look.border);
  }
}

void _pill(Canvas canvas, Offset at, String text, List<Color> colors, {Color ink = Colors.white, double size = 12, String font = 'Baloo2'}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: font, fontSize: size, fontWeight: FontWeight.w800))
    ..pushStyle(ui.TextStyle(color: ink, fontFamily: font, fontSize: size, fontWeight: FontWeight.w800))
    ..addText(text);
  final p = b.build()..layout(const ui.ParagraphConstraints(width: 300));
  final r = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, p.longestLine + 18, p.height + 6), Radius.circular(p.height));
  canvas.drawRRect(r, _grad(r.outerRect, colors));
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.white.withValues(alpha: 0.9));
  canvas.drawParagraph(p, at + const Offset(9, 3));
}

void _button(Canvas canvas, Rect r, String text, List<Color> colors, Look look, {double size = 20, IconData? icon}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(look.pixel ? 0 : r.height * 0.42));
  if (!look.neon) canvas.drawRRect(rr.shift(look.pixel ? const Offset(4, 4) : const Offset(0, 5)), Paint()..color = Color.lerp(colors.last, Colors.black, look.pixel ? 0.6 : 0.35)!);
  if (look.neon) {
    canvas.drawRRect(rr, Paint()
      ..color = colors.last.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  }
  canvas.drawRRect(rr, _grad(r, colors));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 12, r.top + 4, r.width - 24, r.height * 0.28), Radius.circular(r.height)),
      Paint()..color = Colors.white.withValues(alpha: 0.28));
  if (!look.neon) {
    canvas.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white);
  }
  if (icon != null) {
    _icon(canvas, icon, r.centerLeft + Offset(r.width / 2 - size * 2.6, 0), size * 1.2, Colors.white);
  }
  _text(canvas, text, r.center + Offset(icon == null ? 0 : size * 0.4, 0), size, Colors.white, font: look.font, centre: true, width: r.width);
}

void _icon(Canvas canvas, IconData icon, Offset c, double size, Color color) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: icon.fontFamily, fontSize: size))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: icon.fontFamily, fontSize: size))
    ..addText(String.fromCharCode(icon.codePoint));
  final p = b.build()..layout(const ui.ParagraphConstraints(width: 200));
  canvas.drawParagraph(p, c - Offset(p.longestLine / 2, p.height / 2));
}

void _bubble(Canvas canvas, Rect r, Look look, {bool tailLeft = true}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(look.pixel ? 0 : 20));
  final tail = Path()
    ..addPolygon(tailLeft ? [Offset(r.left + 2, r.bottom - 34), Offset(r.left - 16, r.bottom - 12), Offset(r.left + 6, r.bottom - 16)] : [Offset(r.right - 30, r.bottom - 2), Offset(r.right - 10, r.bottom + 16), Offset(r.right - 14, r.bottom - 2)], true);
  final fill = look.neon ? const Color(0xFF1B2A66) : (look.pixel ? look.cardTop : Colors.white);
  if (!look.neon) canvas.drawRRect(rr.shift(look.pixel ? const Offset(4, 4) : const Offset(0, 5)), Paint()..color = look.pixel ? const Color(0xFF0A0A22) : const Color(0xFFB27BD8).withValues(alpha: 0.4));
  if (look.neon) {
    canvas.drawRRect(rr, Paint()
      ..color = const Color(0xFFFF4FD8).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  }
  canvas.drawPath(tail, Paint()..color = fill);
  canvas.drawRRect(rr, Paint()..color = fill);
  if (look.neon || look.pixel) {
    canvas.drawRRect(look.pixel ? rr.deflate(1.5) : rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = look.pixel ? 3 : 1.5
      ..color = look.pixel ? _pixelYellow : const Color(0xFFFF4FD8));
  }
}

void _backdrop(Canvas canvas, Look look, int seed) {
  final screen = Offset.zero & const Size(_w, _h);
  canvas.drawRect(screen, _grad(screen, look.sky));
  final rnd = Random(seed);
  if (look.pixel) {
    for (var i = 0; i < 70; i++) {
      final s = rnd.nextDouble() < 0.3 ? 3.0 : 2.0;
      canvas.drawRect(Rect.fromLTWH((rnd.nextDouble() * _w / 3).roundToDouble() * 3, (rnd.nextDouble() * _h / 3).roundToDouble() * 3, s, s),
          Paint()..color = Colors.white.withValues(alpha: 0.3 + rnd.nextDouble() * 0.4));
    }
    return;
  }
  if (look.neon) {
    for (var i = 0; i < 80; i++) {
      canvas.drawCircle(Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h), 0.6 + rnd.nextDouble() * 1.4, Paint()..color = Colors.white.withValues(alpha: 0.2 + rnd.nextDouble() * 0.5));
    }
  } else {
    for (var i = 0; i < 14; i++) {
      final c = [const Color(0xFFFFB3E6), const Color(0xFF9FD8FF), const Color(0xFFFFE08A)][i % 3];
      canvas.drawCircle(Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h), 30 + rnd.nextDouble() * 50, Paint()
        ..color = c.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));
    }
  }
  // Drifting cubes and sweets.
  for (var i = 0; i < 9; i++) {
    final p = Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h);
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(rnd.nextDouble() - 0.5);
    canvas.saveLayer(const Rect.fromLTWH(-30, -30, 60, 60), Paint()..color = Colors.white.withValues(alpha: look.neon ? 0.16 : 0.32));
    if (i.isEven) {
      _cube(canvas, const Offset(-14, -14), 28, _cubes[i % _cubes.length]);
    } else {
      paintCandy(canvas, const Rect.fromLTWH(-15, -15, 30, 30), SugarColor.values[i % 6]);
    }
    canvas.restore();
    canvas.restore();
  }
}

void _logo(Canvas canvas, Offset at, Look look) {
  for (final (dx, dy, c) in [(0.0, 8.0, 0), (9.0, 8.0, 1), (18.0, 8.0, 2), (9.0, -1.0, 3)]) {
    _cube(canvas, at + Offset(dx, dy), 9, _cubes[c]);
  }
  final size = look.pixel ? 30.0 : 24.0;
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: look.font, fontSize: size, fontWeight: FontWeight.w800))
    ..pushStyle(ui.TextStyle(fontFamily: look.font, fontSize: size, fontWeight: FontWeight.w800))
    ..addText('LifeOS ');
  final first = (b.build()..layout(const ui.ParagraphConstraints(width: 400))).longestLine;
  _text(canvas, 'LifeOS', at + Offset(34, look.pixel ? -10 : -6), size, look.ink, font: look.font);
  _text(canvas, 'Küpler', at + Offset(34 + first + 4, look.pixel ? -10 : -6), size,
      look.neon ? const Color(0xFF38BDF8) : (look.pixel ? _pixelYellow : const Color(0xFFFF4D8D)), font: look.font);
}

void _roundIcon(Canvas canvas, Offset c, IconData icon, Look look) {
  if (look.pixel) {
    final q = Rect.fromCenter(center: c, width: 40, height: 40);
    canvas.drawRect(q.shift(const Offset(3, 3)), Paint()..color = const Color(0xFF0A0A22));
    canvas.drawRect(q, Paint()..color = look.cardTop);
    canvas.drawRect(q.deflate(1.5), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = look.border);
    _icon(canvas, icon, c, 22, _pixelYellow);
    return;
  }
  if (look.neon) {
    canvas.drawCircle(c, 20, Paint()..color = const Color(0xFF182352));
    canvas.drawCircle(c, 20, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF38BDF8));
  } else {
    canvas.drawCircle(c + const Offset(0, 3), 20, Paint()..color = const Color(0xFFB27BD8).withValues(alpha: 0.5));
    canvas.drawCircle(c, 20, Paint()..color = Colors.white);
  }
  _icon(canvas, icon, c, 22, look.neon ? const Color(0xFF38BDF8) : look.ink);
}

// ---------------------------------------------------------- the game art --

/// A tiny live scene of [mode] in [r]; [t] runs 0..1 and loops.
void modeArt(Canvas canvas, Rect r, String mode, Look look, double t) {
  if (look.pixel) {
    _pixelated(canvas, r, 3, (c) => _modeArt(c, r, mode, look, t));
    return;
  }
  _modeArt(canvas, r, mode, look, t);
}

void _modeArt(Canvas canvas, Rect r, String mode, Look look, double t) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(look.pixel ? 0 : 16));
  canvas.save();
  canvas.clipRRect(rr);
  final dark = mode == 'sugar' ? const [Color(0xFF5B1FA8), Color(0xFF3A1270)] : const [Color(0xFF1E1A3A), Color(0xFF0F0C22)];
  canvas.drawRRect(rr, _grad(r, dark));
  final grid = Paint()..color = Colors.white.withValues(alpha: 0.05);
  switch (mode) {
    case 'super' || 'classic':
      final s = r.height / 7;
      final cols = (r.width / s).floor();
      final x0 = r.left + (r.width - cols * s) / 2;
      for (var x = 0; x <= cols; x++) {
        canvas.drawLine(Offset(x0 + x * s, r.top), Offset(x0 + x * s, r.bottom), grid);
      }
      // A stack with a gap the falling piece will fill.
      final rnd = Random(mode.length);
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < cols; x++) {
          if (y == 1 && (x == cols ~/ 2 || x == cols ~/ 2 - 1)) continue;
          if (y == 0 && rnd.nextDouble() < 0.4) continue;
          _cube(canvas, Offset(x0 + x * s, r.bottom - (2 - y) * s), s, _cubes[rnd.nextInt(_cubes.length)]);
        }
      }
      final fall = Curves.easeIn.transform(t);
      final py = r.top - s + (r.height - 1.0 * s) * fall;
      if (mode == 'super') {
        // A T piece, and a power glow.
        for (final (dx, dy) in [(0, 0), (1, 0), (2, 0), (1, -1)]) {
          _cube(canvas, Offset(x0 + (cols ~/ 2 - 2 + dx) * s, py - s + dy * s), s, const Color(0xFFB45BFF));
        }
        paintSparkle(canvas, Offset(x0 + (cols ~/ 2 + 1.5) * s, py - s * 1.6), s * 0.45, const Color(0xFFFFE066));
      } else {
        for (final dx in [0, 1]) {
          _cube(canvas, Offset(x0 + (cols ~/ 2 - 1 + dx) * s, py - s), s, const Color(0xFF3CC4DC));
        }
      }
      if (t > 0.86) {
        final k = (t - 0.86) / 0.14;
        canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - s * 1.05, r.width, s * 1.1), Paint()..color = Colors.white.withValues(alpha: 0.75 * (1 - k)));
      }
    case 'puzzle':
      const n = 6;
      final s = min(r.width, r.height) / (n + 1.2);
      final o = Offset(r.center.dx - n * s / 2, r.center.dy - n * s / 2 + s * 0.3);
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(1), const Radius.circular(4)),
              Paint()..color = Colors.white.withValues(alpha: 0.07));
        }
      }
      final rnd = Random(4);
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          if (y >= 3 && x < 4 && !(y == 4 && x >= 1 && x <= 3) && rnd.nextDouble() < 0.9) {
            _cube(canvas, Offset(o.dx + x * s, o.dy + y * s), s, _cubes[(x + y) % 4 + 1]);
          }
        }
      }
      // An L piece glides into its slot.
      final k = Curves.easeInOut.transform(min(1, t * 1.25));
      final from = o + Offset(s * 4.5, -s * 1.4), to = o + Offset(s * 1, s * 4);
      final at = Offset.lerp(from, to, k)!;
      for (final (dx, dy) in [(0, 0), (1, 0), (2, 0)]) {
        _cube(canvas, at + Offset(dx * s, dy * s), s, const Color(0xFFFF9A3C));
      }
    case 'chain':
      final s = r.height / 5.2;
      final cols = (r.width / s).floor();
      final x0 = r.left + (r.width - cols * s) / 2;
      const colors = [Color(0xFFFF33EE), Color(0xFF3F6BFF), Color(0xFF1FE85A), Color(0xFFFFD23F)];
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < cols; x++) {
          final c = colors[(x * 3 + y * 2) % colors.length];
          var pos = Offset(x0 + x * s, r.bottom - (y + 1) * s);
          // Two cubes swapping on the bottom row.
          if (y == 0 && (x == 1 || x == 2)) {
            final k = Curves.easeInOut.transform(min(1, t * 2));
            pos += Offset((x == 1 ? 1 : -1) * s * k, 0);
          }
          paintChainCube(canvas, Rect.fromLTWH(pos.dx + 1, pos.dy + 1, s - 2, s - 2), c);
        }
      }
      if (t > 0.5) {
        final k = (t - 0.5) / 0.5;
        paintSugarLabel(canvas, 'ZİNCİR ×2', Offset(r.center.dx, r.top + r.height * 0.5 - k * 8), 18 + 4 * Curves.easeOutBack.transform(min(1, k * 2)),
            Paint()..shader = ui.Gradient.linear(Offset(0, r.top), Offset(0, r.top + 40), const [Color(0xFFFFF6B0), Color(0xFFFF8A10)]),
            outline: const Color(0xFF3A0F2A), stroke: 0.2);
      }
    case 'sugar':
      final s = r.height / 3.4;
      final cols = (r.width / s).floor();
      final x0 = r.left + (r.width - cols * s) / 2;
      const pattern = 'RBYGPOBYGRPOYB';
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < cols; x++) {
          final k = pattern[(x * 2 + y * 3) % pattern.length];
          final color = SugarColor.values['ROYGBP'.indexOf(k)];
          final popping = y == 1 && x >= 1 && x <= 3;
          final cell = Rect.fromLTWH(x0 + x * s, r.top + r.height * 0.06 + y * s, s, s);
          if (popping) {
            if (t < 0.55) {
              final pulse = 1 + 0.12 * sin(t * pi * 6);
              paintCandy(canvas, Rect.fromCenter(center: cell.center, width: s * pulse, height: s * pulse), SugarColor.yellow);
            } else {
              final k = (t - 0.55) / 0.45;
              paintSparkle(canvas, cell.center + Offset(0, -k * 8), s * 0.3 * (1 - k * 0.5), const Color(0xFFFFE066), opacity: 1 - k);
            }
            continue;
          }
          paintCandy(canvas, cell, color);
        }
      }
      if (t >= 0.55) {
        final k = (t - 0.55) / 0.45;
        paintSugarLabel(canvas, '+360', Offset(r.center.dx, r.top + r.height * 0.42 - k * 14), 18, Paint()..color = Colors.white.withValues(alpha: 1 - k * 0.6),
            outline: const Color(0xFF6A0E4A), stroke: 0.2);
      }
    case 'daily':
      final c = r.center;
      final cal = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r.height * 0.8, height: r.height * 0.74), const Radius.circular(12));
      canvas.drawRRect(cal, Paint()..color = Colors.white);
      canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(cal.left, cal.top, cal.width, cal.height * 0.3), topLeft: const Radius.circular(12), topRight: const Radius.circular(12)),
          Paint()..color = const Color(0xFF22C55E));
      _text(canvas, '17', Offset(c.dx, c.dy + cal.height * 0.12), cal.height * 0.42, const Color(0xFF14532D), centre: true, width: cal.width);
      _text(canvas, 'EKİM', Offset(c.dx, cal.top + cal.height * 0.15), cal.height * 0.14, Colors.white, centre: true, width: cal.width);
      paintGoldStar(canvas, cal.outerRect.topRight + Offset(-6, 8 - 4 * sin(t * pi * 2)), 13);
  }
  canvas.restore();
}

/// A mode card: the live scene on top, title, line and a badge.
void modeCard(Canvas canvas, Rect r, String mode, String title, String line, Look look, double t, {String? badge, List<Color>? badgeColors, double? progress}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(look.pixel ? 0 : 22));
  _card(canvas, rr, look, glow: _modeColors[mode]!.first);
  final art = Rect.fromLTWH(r.left + 9, r.top + 9, r.width - 18, r.height * 0.56);
  modeArt(canvas, art, mode, look, t);
  _text(canvas, title, Offset(r.left + 14, art.bottom + 8), 18, look.ink, font: look.font, width: r.width - 20);
  _text(canvas, line, Offset(r.left + 14, art.bottom + 32), 12.5, look.muted, font: look.font, weight: FontWeight.w700, width: r.width - 24, height: 1.15);
  if (progress != null) {
    final bar = Rect.fromLTWH(r.left + 14, r.bottom - 18, r.width - 28, 7);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(4)), Paint()..color = look.neon || look.pixel ? const Color(0xFF26315F) : const Color(0xFFF1D7EC));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * progress, bar.height), const Radius.circular(4)), _grad(bar, _modeColors[mode]!, vertical: false));
  }
  if (badge != null) _pill(canvas, Offset(r.left + 16, r.top + 16), badge, badgeColors ?? const [Color(0xFFFF7AC6), Color(0xFFE0247A)], font: look.font);
}

void _shortcuts(Canvas canvas, double y, Look look, {double h = 68}) {
  final items = [(Icons.grid_view_rounded, 'Modlar'), (Icons.palette_rounded, 'Tema'), (Icons.settings_rounded, 'Ayarlar'), (Icons.info_outline_rounded, 'Hakkında')];
  final w = (_w - 32 - 3 * 10) / 4;
  for (var i = 0; i < items.length; i++) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(16 + i * (w + 10), y, w, h), const Radius.circular(18));
    _card(canvas, r, look);
    _icon(canvas, items[i].$1, r.center - Offset(0, h * 0.14), 24, look.neon ? const Color(0xFF38BDF8) : (look.pixel ? _pixelYellow : const Color(0xFFE0247A)));
    _text(canvas, items[i].$2, r.center + Offset(0, h * 0.22), 13, look.ink, font: look.font, centre: true, width: w);
  }
}

// --------------------------------------------------------------- screens --

/// A: Lokum hosts, the big play card, then mode cards to swipe.
void screenA(Canvas canvas, Look look, double t) {
  _backdrop(canvas, look, 3);
  _logo(canvas, const Offset(20, 48), look);
  _roundIcon(canvas, const Offset(_w - 36, 56), Icons.settings_rounded, look);

  // Lokum and his suggestion.
  final hop = sin(t * pi * 2).abs() * 6;
  themedLokum(canvas, Offset(74, 178 - hop), 104, LokumPose.wink, look);
  final bubble = Rect.fromLTWH(150, 104, _w - 166, 112);
  _bubble(canvas, bubble, look);
  _text(canvas, 'Zincir Küpler\'i hiç denemedin!', bubble.topLeft + const Offset(16, 14), look.neon ? 14.5 : 17, look.ink, font: look.font, width: bubble.width - 24);
  _text(canvas, 'Küpleri kaydır, zinciri kur.', bubble.topLeft + const Offset(16, 40), 13, look.muted, font: look.font, weight: FontWeight.w700, width: bubble.width - 24);
  _pill(canvas, bubble.topLeft + const Offset(16, 72), 'Hemen dene  ›', _modeColors['chain']!, font: look.font, size: 13);

  // Play card.
  final play = Rect.fromLTWH(16, 240, _w - 32, 150);
  final pr = RRect.fromRectAndRadius(play, const Radius.circular(26));
  if (look.pixel) {
    canvas.drawRect(play.shift(const Offset(5, 5)), Paint()..color = const Color(0xFF0A0A22));
    canvas.drawRect(play, _grad(play, const [Color(0xFFFF5FA8), Color(0xFFD0246E)]));
    canvas.drawRect(play.deflate(1.5), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _pixelYellow);
  } else if (look.neon) {
    _card(canvas, pr, look, glow: const Color(0xFFFF4FD8));
  } else {
    canvas.drawRRect(pr.shift(const Offset(0, 6)), Paint()..color = const Color(0xFFC0287A));
    canvas.drawRRect(pr, _grad(play, const [Color(0xFFFF9AD8), Color(0xFFE0247A)]));
    canvas.drawRRect(pr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white);
  }
  modeArt(canvas, Rect.fromLTWH(play.right - 150, play.top + 12, 136, play.height - 24), 'super', look, t);
  _text(canvas, 'OYNA', play.topLeft + const Offset(22, 22), 46, Colors.white, font: look.font);
  _text(canvas, 'Süper Küpler', play.topLeft + const Offset(24, 80), 18, Colors.white.withValues(alpha: 0.95), font: look.font);
  _text(canvas, 'Rekor 15.398 · Seviye 4', play.topLeft + const Offset(24, 104), 13, Colors.white.withValues(alpha: 0.8), font: look.font, weight: FontWeight.w700);

  // Cards.
  _text(canvas, 'SENİN İÇİN', const Offset(22, 410), 14, look.muted, font: look.font);
  const cw = 172.0, ch = 236.0, cy = 434.0;
  modeCard(canvas, const Rect.fromLTWH(16, cy, cw, ch), 'sugar', 'Şeker Küpler', 'Seviye 12\'de kaldın', look, t,
      badge: 'DEVAM', badgeColors: _modeColors['sugar'], progress: 12 / 60);
  modeCard(canvas, const Rect.fromLTWH(16 + cw + 12, cy, cw, ch), 'chain', 'Zincir Küpler', 'Zincir kur, çöp blokları kır', look, (t + 0.3) % 1,
      badge: 'YENİ');
  modeCard(canvas, const Rect.fromLTWH(16 + 2 * (cw + 12), cy, cw, ch), 'puzzle', 'Bulmaca', '21 / 90 yıldız', look, (t + 0.6) % 1, progress: 21 / 90);
  for (var i = 0; i < 5; i++) {
    canvas.drawCircle(Offset(_w / 2 - 32 + i * 16, cy + ch + 16), i == 0 ? 5 : 4,
        Paint()..color = i == 0 ? (look.neon ? const Color(0xFF38BDF8) : (look.pixel ? _pixelYellow : const Color(0xFFE0247A))) : look.muted.withValues(alpha: 0.4));
  }

  // Daily puzzle.
  final daily = RRect.fromRectAndRadius(const Rect.fromLTWH(16, 706, _w - 32, 70), const Radius.circular(22));
  _card(canvas, daily, look, glow: const Color(0xFF22C55E));
  modeArt(canvas, Rect.fromLTWH(daily.left + 10, daily.top + 8, 64, 54), 'daily', look, t);
  _text(canvas, 'Günlük Görev', Offset(daily.left + 88, daily.top + 12), 18, look.ink, font: look.font);
  _text(canvas, '17 Ekim bulmacası · 3 günlük seri', Offset(daily.left + 88, daily.top + 38), 12.5, look.muted, font: look.font, weight: FontWeight.w700);
  _pill(canvas, Offset(daily.right - 74, daily.top + 24), 'Oyna ›', _modeColors['daily']!, font: look.font, size: 13);

  _shortcuts(canvas, 796, look);
}

/// B: a showcase of every mode as big live tiles.
void screenB(Canvas canvas, Look look, double t) {
  _backdrop(canvas, look, 8);
  _logo(canvas, const Offset(20, 48), look);
  _roundIcon(canvas, const Offset(_w - 36, 56), Icons.settings_rounded, look);

  // Suggestion ribbon with Lokum peeking.
  final rib = Rect.fromLTWH(16, 92, _w - 32, 92);
  final rr = RRect.fromRectAndRadius(rib, const Radius.circular(24));
  canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()..color = const Color(0xFFC0287A));
  canvas.drawRRect(rr, _grad(rib, const [Color(0xFFFFE08A), Color(0xFFFF9AD8)]));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white);
  paintLokum(canvas, Offset(rib.left + 52, rib.top + 50), 78, pose: LokumPose.cheer);
  _text(canvas, 'Bunu denedin mi?', Offset(rib.left + 100, rib.top + 14), 19, const Color(0xFF6A0E4A));
  _text(canvas, 'Şeker Küpler: 60 seviye, kutular ve süreli bombalar', Offset(rib.left + 100, rib.top + 42), 12.5, const Color(0xFF8A2A6A),
      weight: FontWeight.w700, width: rib.width - 190, height: 1.15);
  _button(canvas, Rect.fromLTWH(rib.right - 84, rib.top + 26, 70, 40), 'Dene', const [Color(0xFF6BF0A0), Color(0xFF1FB85A)], look, size: 16);

  // Continue strip.
  final cont = RRect.fromRectAndRadius(const Rect.fromLTWH(16, 198, _w - 32, 58), const Radius.circular(20));
  _card(canvas, cont, look);
  _icon(canvas, Icons.play_circle_fill_rounded, cont.outerRect.centerLeft + const Offset(30, 0), 32, const Color(0xFFE0247A));
  _text(canvas, 'Devam et · Süper Küpler', Offset(cont.left + 56, cont.top + 10), 16, look.ink);
  _text(canvas, 'Seviye 4 · 15.398 puan', Offset(cont.left + 56, cont.top + 32), 12, look.muted, weight: FontWeight.w700);
  _icon(canvas, Icons.chevron_right_rounded, cont.outerRect.centerRight - const Offset(24, 0), 28, look.muted);

  // Tiles.
  const tw = (_w - 32 - 12) / 2, th = 196.0;
  final tiles = [
    ('super', 'Süper Küpler', 'Güçlerle dolu', 'ÖNERİLEN', const [Color(0xFFFFD23F), Color(0xFFFF9A1F)]),
    ('classic', 'Klasik', 'Saf Küpler keyfi', null, null),
    ('puzzle', 'Bulmaca', '21 / 90 yıldız', null, null),
    ('chain', 'Zincir Küpler', 'Kaydır, zincir kur', 'YENİ', null),
    ('sugar', 'Şeker Küpler', 'Seviye 12 / 60', 'YENİ', null),
    ('daily', 'Günlük Görev', '3 günlük seri', null, null),
  ];
  for (var i = 0; i < tiles.length; i++) {
    final (mode, title, line, badge, colors) = tiles[i];
    final r = Rect.fromLTWH(16 + (i % 2) * (tw + 12), 270 + (i ~/ 2) * (th + 12), tw, th);
    modeCard(canvas, r, mode, title, line, look, (t + i * 0.17) % 1, badge: badge, badgeColors: colors);
  }
}

/// C: today's pick on top, where you left off, then every mode in a list.
void screenC(Canvas canvas, Look look, double t) {
  _backdrop(canvas, look, 12);
  _text(canvas, 'Merhaba!', const Offset(20, 38), 30, look.ink);
  _pill(canvas, const Offset(22, 78), '     3 günlük seri', const [Color(0xFFFF9A1F), Color(0xFFFF4D4D)], size: 13);
  _icon(canvas, Icons.local_fire_department_rounded, const Offset(38, 91), 16, Colors.white);
  _roundIcon(canvas, const Offset(_w - 36, 56), Icons.settings_rounded, look);

  // Hero.
  final hero = Rect.fromLTWH(16, 118, _w - 32, 300);
  final hr = RRect.fromRectAndRadius(hero, const Radius.circular(28));
  _card(canvas, hr, look, glow: const Color(0xFFFF33EE));
  modeArt(canvas, Rect.fromLTWH(hero.left + 10, hero.top + 10, hero.width - 20, 150), 'chain', look, t);
  _pill(canvas, Offset(hero.left + 20, hero.top + 20), 'BUGÜNÜN ÖNERİSİ', const [Color(0xFFFFD23F), Color(0xFFFF9A1F)], ink: const Color(0xFF6A3A00));
  _text(canvas, 'Zincir Küpler · Zamana Karşı', Offset(hero.left + 20, hero.top + 172), 21, look.ink);
  _text(canvas, '2 dakikada 10.000 puanı geç, sandığı kap!', Offset(hero.left + 20, hero.top + 202), 13.5, look.muted, weight: FontWeight.w700);
  _button(canvas, Rect.fromLTWH(hero.left + 20, hero.bottom - 70, hero.width - 40, 54), 'OYNA', const [Color(0xFF6BF0A0), Color(0xFF1FB85A)], look, size: 22, icon: Icons.play_arrow_rounded);
  paintLokum(canvas, Offset(hero.right - 40, hero.top + 150), 70, pose: LokumPose.happy);
  _bubble(canvas, Rect.fromLTWH(hero.right - 210, hero.top + 92, 140, 40), look, tailLeft: false);
  _text(canvas, 'Ben de geliyorum!', Offset(hero.right - 140, hero.top + 112), 13, look.ink, centre: true, width: 140);

  // Where you left off.
  _text(canvas, 'KALDIĞIN YERLER', const Offset(22, 432), 14, look.muted);
  for (final (i, mode, title, line, share) in [(0, 'sugar', 'Şeker Küpler', 'Seviye 12 / 60', 0.2), (1, 'puzzle', 'Bulmaca', 'Seviye 7 / 30', 0.23)]) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(16 + i * ((_w - 44) / 2 + 12), 456, (_w - 44) / 2, 84), const Radius.circular(20));
    _card(canvas, r, look, glow: _modeColors[mode]!.first);
    modeArt(canvas, Rect.fromLTWH(r.left + 8, r.top + 8, 64, 68), mode, look, (t + i * 0.4) % 1);
    _text(canvas, title, Offset(r.left + 80, r.top + 12), 15, look.ink, width: r.width - 84);
    _text(canvas, line, Offset(r.left + 80, r.top + 34), 12, look.muted, weight: FontWeight.w700, width: r.width - 84);
    final bar = Rect.fromLTWH(r.left + 80, r.top + 60, r.width - 94, 7);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(4)), Paint()..color = const Color(0xFFF1D7EC));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * share, bar.height), const Radius.circular(4)), _grad(bar, _modeColors[mode]!, vertical: false));
  }

  // Every mode.
  _text(canvas, 'TÜM MODLAR', const Offset(22, 556), 14, look.muted);
  final rows = [
    ('super', 'Süper Küpler', 'Güçlerle dolu Küpler', 'Rekor 15.398'),
    ('classic', 'Klasik', 'Normal ve Rahat', null),
    ('chain', 'Zincir Küpler', 'Sonsuz · Zamana Karşı', 'YENİ'),
    ('sugar', 'Şeker Küpler', '60 seviye, 6 bölüm', 'YENİ'),
    ('daily', 'Meydan okumalar', 'Sprint, Ultra, Kazı…', null),
  ];
  for (var i = 0; i < rows.length; i++) {
    final (mode, title, line, badge) = rows[i];
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(16, 580 + i * 66.0, _w - 32, 58), const Radius.circular(18));
    _card(canvas, r, look);
    modeArt(canvas, Rect.fromLTWH(r.left + 6, r.top + 6, 70, 46), mode, look, (t + i * 0.2) % 1);
    _text(canvas, title, Offset(r.left + 88, r.top + 9), 16, look.ink);
    _text(canvas, line, Offset(r.left + 88, r.top + 31), 12, look.muted, weight: FontWeight.w700);
    if (badge != null) {
      _pill(canvas, Offset(r.right - (badge == 'YENİ' ? 92 : 128), r.top + 18), badge,
          badge == 'YENİ' ? const [Color(0xFFFF7AC6), Color(0xFFE0247A)] : const [Color(0xFFFFD23F), Color(0xFFFF9A1F)],
          ink: badge == 'YENİ' ? Colors.white : const Color(0xFF6A3A00));
    }
    _icon(canvas, Icons.chevron_right_rounded, r.outerRect.centerRight - const Offset(20, 0), 26, look.muted);
  }
}

// --------------------------------------------------------------- output --

Future<void> _save(WidgetTester tester, void Function(Canvas) paint, String name, {double scale = 2.5}) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    paint(canvas);
    final image = await recorder.endRecording().toImage((_w * scale).round(), (_h * scale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Baloo2', [for (final w in ['SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/Baloo2-$w.ttf']);
  await family('Inter', [for (final w in ['Regular', 'SemiBold', 'ExtraBold', 'Black']) 'assets/fonts/Inter-$w.otf']);
  await family('Jersey10', ['assets/fonts/Jersey10-Regular.ttf']);
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  await family('MaterialIcons', [Directory('$sdk/bin/cache/artifacts/material_fonts').listSync().whereType<File>().firstWhere((f) => f.path.toLowerCase().endsWith('materialicons-regular.otf')).path]);
}

void main() {
  setUpAll(_loadFonts);
  testWidgets('A toy', (tester) => _save(tester, (c) => screenA(c, toy, 0.62), 'ana-a-oyuncak.png'));
  testWidgets('A neon', (tester) => _save(tester, (c) => screenA(c, neon, 0.62), 'ana-a-neon.png'));
  testWidgets('A pixel', (tester) => _save(tester, (c) => screenA(c, pixel, 0.62), 'ana-a-piksel.png'));
  testWidgets('B showcase', (tester) => _save(tester, (c) => screenB(c, toy, 0.62), 'ana-b-vitrin.png'));
  testWidgets('C today', (tester) => _save(tester, (c) => screenC(c, toy, 0.62), 'ana-c-oneri.png'));
  testWidgets('A frames', (tester) async {
    for (var i = 0; i < 24; i++) {
      await _save(tester, (c) => screenA(c, toy, i / 24), 'ana-a-frames/${i.toString().padLeft(2, '0')}.png', scale: 1.1);
    }
  });
}
