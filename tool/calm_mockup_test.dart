// Mock-ups: calmer Zincir Küpler cubes (the crystal ones tire the eyes),
// and stage three's generous gifts that unlock new things.
//   flutter test tool/calm_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): zincir-sakin.png,
// zincir-canli.png, hediye-ozellik.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show paintChainCube;
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';

const _ink = Color(0xFF5A1F7A);
const _muted = Color(0xFF9A5AB5);

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _d(Color c, double t) => Color.lerp(c, Colors.black, t)!;

void _text(Canvas canvas, String text, Offset at, double size, Color color, {bool centre = true, double width = 400, FontWeight weight = FontWeight.w800, double height = 1.15}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, textAlign: centre ? TextAlign.center : TextAlign.left, height: height))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, height: height))
    ..addText(text);
  final p = b.build()..layout(ui.ParagraphConstraints(width: width));
  canvas.drawParagraph(p, centre ? at - Offset(width / 2, p.height / 2) : at);
}

void _label(Canvas canvas, String text, Offset c, double size, {List<Color> colors = const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)]}) {
  paintSugarLabel(canvas, text, c, size,
      Paint()..shader = ui.Gradient.linear(c - Offset(0, size / 2), c + Offset(0, size / 2), colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]),
      outline: const Color(0xFF6A0E4A), stroke: 0.2);
}

void _card(Canvas canvas, RRect r, {List<Color> colors = const [Color(0xFFFFF7FD), Color(0xFFFFE3F4)], Color border = Colors.white, double width = 3}) {
  canvas.drawRRect(r.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.45));
  canvas.drawRRect(r, Paint()..shader = ui.Gradient.linear(r.outerRect.topCenter, r.outerRect.bottomCenter, colors));
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = border);
}

// ------------------------------------------------------------ the cubes --

/// The symbol of colour [i]: star, heart, diamond, leaf, circle. Lets the
/// colours be told apart by shape too.
Path _symbol(int i, Offset c, double r) {
  switch (i) {
    case 0:
      return starPath(c, r, inner: 0.5);
    case 1:
      return Path()
        ..moveTo(c.dx, c.dy + r * 0.9)
        ..cubicTo(c.dx - r * 1.4, c.dy - r * 0.1, c.dx - r * 0.6, c.dy - r * 1.2, c.dx, c.dy - r * 0.4)
        ..cubicTo(c.dx + r * 0.6, c.dy - r * 1.2, c.dx + r * 1.4, c.dy - r * 0.1, c.dx, c.dy + r * 0.9)
        ..close();
    case 2:
      return Path()..addPolygon([c + Offset(0, -r), c + Offset(r * 0.8, 0), c + Offset(0, r), c + Offset(-r * 0.8, 0)], true);
    case 3:
      return Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + r * 1.1, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - r * 1.1, c.dy, c.dx, c.dy - r)
        ..close();
    default:
      return Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.75));
  }
}

/// A: soft matte cube. Muted colour, a gentle gradient, a shaded lower lip,
/// a thin highlight, no glow; a faint symbol in the middle.
void matteCube(Canvas canvas, Rect r, Color color, int i) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.2));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.35));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [_l(color, 0.14), color, _d(color, 0.12)], const [0, 0.55, 1]));
  canvas.save();
  canvas.clipRRect(rr);
  canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - s * 0.14, s, s * 0.14), Paint()..color = _d(color, 0.22));
  canvas.restore();
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + s * 0.14, r.top + s * 0.08, s * 0.72, s * 0.1), Radius.circular(s)), Paint()..color = Colors.white.withValues(alpha: 0.22));
  canvas.drawPath(_symbol(i, r.center + Offset(0, -s * 0.02), s * 0.2), Paint()..color = Colors.white.withValues(alpha: 0.5));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.2, s * 0.025)
    ..color = _d(color, 0.3));
}

/// B: lokum. Pastel, powdered with sugar, its cut side showing below.
void lokumCube(Canvas canvas, Rect r, Color color, int i) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.26));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawRRect(rr, Paint()..color = _d(color, 0.12));
  final top = RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, s, s * 0.84), Radius.circular(s * 0.26));
  canvas.drawRRect(top, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [_l(color, 0.2), color]));
  canvas.save();
  canvas.clipRRect(top);
  canvas.drawRect(Rect.fromLTWH(r.left, r.top, s, s * 0.36), Paint()..shader = ui.Gradient.linear(r.topCenter, r.topCenter + Offset(0, s * 0.36), [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)]));
  final rnd = Random(i * 7 + 1);
  for (var k = 0; k < 16; k++) {
    canvas.drawCircle(Offset(r.left + rnd.nextDouble() * s, r.top + rnd.nextDouble() * s * 0.5), s * (0.012 + rnd.nextDouble() * 0.014), Paint()..color = Colors.white.withValues(alpha: 0.85));
  }
  canvas.restore();
  canvas.drawPath(_symbol(i, r.center + Offset(0, s * 0.02), s * 0.17), Paint()..color = _d(color, 0.3).withValues(alpha: 0.45));
}

/// C: İznik tile. A cream glaze, a border and a motif in the colour.
void ciniCube(Canvas canvas, Rect r, Color color, int i) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.12));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.35));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [Color(0xFFFFFBF2), Color(0xFFEDE3D0)]));
  canvas.drawRRect(rr.deflate(s * 0.07), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.08
    ..color = color);
  canvas.drawPath(_symbol(i, r.center, s * 0.22), Paint()..color = color);
  for (final c in [r.topLeft + Offset(s * 0.2, s * 0.2), r.topRight + Offset(-s * 0.2, s * 0.2), r.bottomLeft + Offset(s * 0.2, -s * 0.2), r.bottomRight + Offset(-s * 0.2, -s * 0.2)]) {
    canvas.drawCircle(c, s * 0.035, Paint()..color = color.withValues(alpha: 0.7));
  }
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + s * 0.16, r.top + s * 0.13, s * 0.3, s * 0.06), Radius.circular(s)), Paint()..color = Colors.white.withValues(alpha: 0.7));
}

const _crystal = [Color(0xFFFFD000), Color(0xFFF21FD8), Color(0xFF2F5BFF), Color(0xFF12D24E), Color(0xFFFF7A00)];
const _matte = [Color(0xFFE8B931), Color(0xFFCF4F98), Color(0xFF4C78D6), Color(0xFF3DAE66), Color(0xFFE88A3E)];
const _lokum = [Color(0xFFF3D27A), Color(0xFFF29BC2), Color(0xFFA2B9EE), Color(0xFFAAD58E), Color(0xFFF5B07D)];
const _cini = [Color(0xFFD4A017), Color(0xFFC0392B), Color(0xFF1F4FA8), Color(0xFF2E8B57), Color(0xFF1F9AA0)];

const _rows = ['.....Y', 'M....M', 'G.MMYB', 'G.GMBM', 'BYBYYM', 'GGMYBB', 'BMGBMY'];
const _key = {'Y': 0, 'M': 1, 'B': 2, 'G': 3, 'O': 4};

void _board(Canvas canvas, Offset o, double cell, String title, String line, void Function(Canvas, Rect, Color, int) paint, List<Color> colors, {bool pick = false}) {
  final well = Rect.fromLTWH(o.dx, o.dy, 6 * cell, 10 * cell);
  canvas.drawRRect(RRect.fromRectAndRadius(well.inflate(10), const Radius.circular(22)), Paint()..color = const Color(0xFF232A3E));
  canvas.drawRRect(RRect.fromRectAndRadius(well, const Radius.circular(14)), Paint()..color = const Color(0xFF13121E));
  for (var y = 0; y < _rows.length; y++) {
    for (var x = 0; x < 6; x++) {
      final ch = _rows[y][x];
      if (ch == '.') continue;
      final i = _key[ch]!;
      paint(canvas, Rect.fromLTWH(o.dx + x * cell + 2, o.dy + (10 - _rows.length + y) * cell + 2, cell - 4, cell - 4), colors[i], i);
    }
  }
  // The cursor on two cubes.
  final cur = Rect.fromLTWH(o.dx + 4 * cell, o.dy + 5 * cell, 2 * cell, cell).inflate(2);
  final corner = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white.withValues(alpha: 0.9);
  for (final (p, dx, dy) in [(cur.topLeft, 1.0, 1.0), (cur.topRight, -1.0, 1.0), (cur.bottomLeft, 1.0, -1.0), (cur.bottomRight, -1.0, -1.0)]) {
    canvas.drawPath(Path()..moveTo(p.dx + dx * 12, p.dy)..lineTo(p.dx, p.dy)..lineTo(p.dx, p.dy + dy * 12), corner);
  }
  if (pick) {
    canvas.drawRRect(RRect.fromRectAndRadius(well.inflate(16), const Radius.circular(26)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF6BF0A0));
  }
  _text(canvas, title, Offset(well.center.dx, well.bottom + 40), 24, Colors.white, width: well.width + 40);
  _text(canvas, line, Offset(well.center.dx, well.bottom + 72), 15, const Color(0xFFB8B0E0), width: well.width + 40, weight: FontWeight.w700);
}

void calm(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1A1F30));
  _label(canvas, 'ZİNCİR KÜPLERİ · DAHA SAKİN', Offset(size.width / 2, 46), 30);
  const cell = 46.0;
  const gap = 6 * cell + 64;
  _board(canvas, const Offset(40, 96), cell, 'Şimdiki · Kristal', 'parlak, ışıl ışıl: göz yoruyor', (c, r, col, i) => paintChainCube(c, r, col), _crystal);
  _board(canvas, const Offset(40 + gap, 96), cell, 'A · Mat (önerim)', 'yumuşak renk, ışıma yok, sembollü', matteCube, _matte, pick: true);
  _board(canvas, const Offset(40 + gap * 2, 96), cell, 'B · Lokum', 'pastel, pudra şekerli', lokumCube, _lokum);
  _board(canvas, const Offset(40 + gap * 3, 96), cell, 'C · Çini', 'İznik çinisi, krem zemin', ciniCube, _cini);
  _text(canvas, 'Semboller (yıldız, kalp, elmas, yaprak, daire) renkleri şekilden de ayırt ettirir; renk körlüğüne de iyi gelir. A varsayılan olur, B ve C hediyelerle açılır.',
      Offset(size.width / 2, size.height - 34), 16, const Color(0xFFE6E0FF), width: size.width - 80, weight: FontWeight.w700);
}

// --------------------------------------------------------- vivid, calm --

/// Vivid colours, rich but not neon.
const _vivid = [Color(0xFFFFC414), Color(0xFFEE3BA6), Color(0xFF3A6CF0), Color(0xFF1FBF5A), Color(0xFFFF7F1E)];

/// V1: vivid and matte. Full colour, a soft gradient, a darker lip, a thin
/// highlight and the colour's symbol; nothing glows.
void vividMatte(Canvas canvas, Rect r, Color color, int i) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.2));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.4));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [_l(color, 0.2), color, _d(color, 0.1)], const [0, 0.5, 1]));
  canvas.save();
  canvas.clipRRect(rr);
  canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - s * 0.13, s, s * 0.13), Paint()..color = _d(color, 0.25));
  canvas.restore();
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + s * 0.14, r.top + s * 0.08, s * 0.72, s * 0.1), Radius.circular(s)), Paint()..color = Colors.white.withValues(alpha: 0.3));
  canvas.drawPath(_symbol(i, r.center + Offset(0, -s * 0.02), s * 0.2), Paint()..color = Colors.white.withValues(alpha: 0.6));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.2, s * 0.025)
    ..color = _d(color, 0.35));
}

/// V2: vivid and glossy, without the glare: a domed gradient, an inner
/// bevel and a small soft gloss; no halo, no inner light.
void vividGloss(Canvas canvas, Rect r, Color color, int i) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.2));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.4));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.radial(r.topLeft + Offset(s * 0.35, s * 0.3), s * 0.95, [_l(color, 0.25), color, _d(color, 0.28)], const [0, 0.5, 1]));
  canvas.drawRRect(rr.deflate(s * 0.07), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.04
    ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [Colors.white.withValues(alpha: 0.32), Colors.white.withValues(alpha: 0), _d(color, 0.35).withValues(alpha: 0.5)], const [0, 0.5, 1]));
  canvas.drawOval(Rect.fromLTWH(r.left + s * 0.16, r.top + s * 0.11, s * 0.4, s * 0.16), Paint()..color = Colors.white.withValues(alpha: 0.28));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.2, s * 0.022)
    ..color = _d(color, 0.3));
}

/// V3: vivid jelly: a rounded candy with a curved gloss line and a lit
/// rim, the symbol pressed in; bright but soft.
void vividJelly(Canvas canvas, Rect r, Color color, int i) {
  final s = r.width;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.28));
  canvas.drawRRect(rr.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.4));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [_l(color, 0.12), color, _d(color, 0.2)], const [0, 0.55, 1]));
  canvas.save();
  canvas.clipRRect(rr);
  canvas.drawPath(
      Path()
        ..moveTo(r.left + s * 0.2, r.top + s * 0.3)
        ..quadraticBezierTo(r.left + s * 0.24, r.top + s * 0.14, r.left + s * 0.44, r.top + s * 0.13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.42));
  canvas.restore();
  canvas.drawPath(_symbol(i, r.center + Offset(s * 0.04, s * 0.04), s * 0.17), Paint()..color = _d(color, 0.28).withValues(alpha: 0.55));
  canvas.drawRRect(rr.deflate(s * 0.02), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = _l(color, 0.35).withValues(alpha: 0.6));
}

void vivid(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1A1F30));
  _label(canvas, 'ZİNCİR KÜPLERİ · CANLI, AZ PARLAK', Offset(size.width / 2, 46), 30);
  const cell = 46.0;
  const gap = 6 * cell + 64;
  _board(canvas, const Offset(40, 96), cell, 'Şimdiki · Kristal', 'ışıma ve içten ışık göz yoruyor', (c, r, col, i) => paintChainCube(c, r, col), _crystal);
  _board(canvas, const Offset(40 + gap, 96), cell, 'D · Canlı mat', 'tam renk, ışımasız, sembollü', vividMatte, _vivid);
  _board(canvas, const Offset(40 + gap * 2, 96), cell, 'E · Canlı parlak (önerim)', 'kristale en yakın, parlama yumuşak', vividGloss, _vivid, pick: true);
  _board(canvas, const Offset(40 + gap * 3, 96), cell, 'F · Canlı jöle', 'yuvarlak şeker, kabartma sembol', vividJelly, _vivid);
  _text(canvas, 'Hepsinde ışıma halesi ve içten parlayan ışık kalktı; renkler canlı kaldı. Renkler aynı kalabilir, sadece biçim değişir.',
      Offset(size.width / 2, size.height - 34), 16, const Color(0xFFE6E0FF), width: size.width - 80, weight: FontWeight.w700);
}

// ---------------------------------------------------------------- gifts --

void _icon(Canvas canvas, Offset c, double s, String kind) {
  switch (kind) {
    case 'cubes':
      lokumCube(canvas, Rect.fromCenter(center: c + Offset(-s * 0.2, s * 0.08), width: s * 0.5, height: s * 0.5), _lokum[1], 1);
      ciniCube(canvas, Rect.fromCenter(center: c + Offset(s * 0.22, -s * 0.08), width: s * 0.5, height: s * 0.5), _cini[2], 2);
    case 'scene':
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: s * 0.9, height: s * 0.66), Radius.circular(s * 0.1));
      canvas.save();
      canvas.clipRRect(r);
      canvas.translate(r.left, r.top);
      paintStoryScene(canvas, r.outerRect.size, 4);
      canvas.restore();
      canvas.drawRRect(r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white);
    case 'power':
      canvas.drawCircle(c, s * 0.36, Paint()..shader = ui.Gradient.linear(c - Offset(0, s * 0.36), c + Offset(0, s * 0.36), const [Color(0xFF7FD8FF), Color(0xFF2E6ACF)]));
      for (var k = 0; k < 3; k++) {
        final a = k * pi * 2 / 3 - pi / 2;
        canvas.drawArc(Rect.fromCircle(center: c, radius: s * 0.22), a, 1.4, false, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.06
          ..strokeCap = StrokeCap.round
          ..color = Colors.white);
      }
    case 'outfit':
      paintLokum(canvas, c + Offset(0, s * 0.06), s * 0.72, outfit: LokumOutfit.tulip, pose: LokumPose.wink);
    case 'card':
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.12);
      final r = Rect.fromCenter(center: Offset.zero, width: s * 0.86, height: s * 0.6);
      canvas.drawRect(r.shift(const Offset(2, 3)), Paint()..color = Colors.black.withValues(alpha: 0.3));
      canvas.drawRect(r, Paint()..color = const Color(0xFFFFF8EC));
      canvas.save();
      canvas.clipRect(r.deflate(s * 0.05));
      canvas.translate(r.left + s * 0.05, r.top + s * 0.05);
      paintStoryScene(canvas, r.deflate(s * 0.05).size, 0);
      canvas.restore();
      canvas.restore();
    default:
      paintLokum(canvas, c, s * 0.7, pose: LokumPose.dance, beat: 0.2);
  }
}

void gifts(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF6A1FA8), Color(0xFFB0307E), Color(0xFF3A1470)], const [0, 0.5, 1]));
  _label(canvas, 'BOL HEDİYE, YENİ ÖZELLİKLER', Offset(size.width / 2, 46), 30);
  // Left: a gift that unlocks something.
  final pop = RRect.fromRectAndRadius(Rect.fromLTWH(30, 90, 400, 600), const Radius.circular(30));
  _card(canvas, pop);
  _label(canvas, 'YENİ ÖZELLİK AÇILDI!', Offset(pop.outerRect.center.dx, 136), 26);
  final glowC = Offset(pop.outerRect.center.dx, 290);
  canvas.drawCircle(glowC, 150, Paint()..shader = ui.Gradient.radial(glowC, 150, [const Color(0xFFFFF0A0).withValues(alpha: 0.9), const Color(0xFFFFF0A0).withValues(alpha: 0)]));
  const cell = 56.0;
  final o = glowC - const Offset(cell * 1.5, cell * 1.5);
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 3; x++) {
      final i = (x + y * 2) % 5;
      ciniCube(canvas, Rect.fromLTWH(o.dx + x * cell + 2, o.dy + y * cell + 2, cell - 4, cell - 4), _cini[i], i);
    }
  }
  _text(canvas, 'Çini küpler', Offset(pop.outerRect.center.dx, 440), 26, _ink, width: 360);
  _text(canvas, "Zincir Küpler'de İznik çinisi görünümü.\nAyarlar > Küp görünümü'nden seç.", Offset(pop.outerRect.center.dx, 486), 15, _muted, width: 340, weight: FontWeight.w700);
  final btn = RRect.fromRectAndRadius(Rect.fromLTWH(pop.left + 50, 540, pop.width - 100, 56), const Radius.circular(22));
  canvas.drawRRect(btn.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF0E6A32));
  canvas.drawRRect(btn, Paint()..shader = ui.Gradient.linear(btn.outerRect.topCenter, btn.outerRect.bottomCenter, const [Color(0xFF6BF0A0), Color(0xFF1FB85A)]));
  _label(canvas, 'HEMEN DENE', btn.outerRect.center, 22, colors: const [Colors.white, Colors.white]);
  _text(canvas, 'Gümüş sandıktan çıktı', Offset(pop.outerRect.center.dx, 630), 15, _muted, width: 340);
  paintLokum(canvas, Offset(pop.right - 30, pop.bottom - 30), 80, pose: LokumPose.cheer, outfit: LokumOutfit.fez);

  // Right: what the gifts open.
  final list = RRect.fromRectAndRadius(Rect.fromLTWH(460, 90, size.width - 490, 600), const Radius.circular(30));
  _card(canvas, list);
  _text(canvas, 'Hediyelerle açılanlar', Offset(list.outerRect.center.dx, 128), 24, _ink, width: list.width);
  const rows = [
    ('cubes', 'Küp görünümleri', 'Zincir için Lokum ve Çini küpler', '7. gün hediyesi · gümüş sandık'),
    ('scene', 'Tahta manzaraları', 'Şeker tahtasının arkasında Galata gecesi, karlı Kız Kulesi', 'yıldız sandıkları'),
    ('power', 'Yeni güçlendiriciler', "Şeker'de Karıştır, Zincir'de Zamanı Durdur", 'kavanozun ilk dolumu · altın sandık'),
    ('outfit', 'Etkinlik kostümleri', 'Lale tacı, vapur kaptanı şapkası, kahveci önlüğü', 'haftalık etkinliğin son ödülü'),
    ('card', 'İstanbul kartpostalları', 'Gerçek tarihle 24 kartlık albüm', 'her sandıktan bir kart'),
  ];
  for (var i = 0; i < rows.length; i++) {
    final (kind, title, what, from) = rows[i];
    final y = 160.0 + i * 104;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(list.left + 18, y, list.width - 36, 92), const Radius.circular(18));
    _card(canvas, r, colors: const [Colors.white, Color(0xFFFFEAF6)], width: 2);
    _icon(canvas, Offset(r.left + 48, r.center.dy), 70, kind);
    _text(canvas, title, Offset(r.left + 96, y + 10), 18, _ink, centre: false, width: r.width - 110);
    _text(canvas, what, Offset(r.left + 96, y + 36), 14, _muted, centre: false, width: r.width - 110, weight: FontWeight.w700);
    _text(canvas, from, Offset(r.left + 96, y + 62), 13.5, const Color(0xFFE0247A), centre: false, width: r.width - 110);
  }
  // The generosity, in numbers.
  const more = [
    ('Her gün', 'günlük hediye, 2 kat büyük'),
    ('Her 5 yıldız', 'bir sandık (önce 10\'du)'),
    ('Her 150 şeker', 'kavanoz dolar (önce 300)'),
    ('Her kazanılan seviye', 'Lokum\'un sürpriz paketi'),
  ];
  final w = (size.width - 60) / more.length;
  for (var i = 0; i < more.length; i++) {
    final (a, b) = more[i];
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(30 + i * w + 6, 716, w - 12, 86), const Radius.circular(18));
    _card(canvas, r, colors: const [Color(0xFFFFF3C8), Color(0xFFFFD36B)], border: const Color(0xFFFFB000), width: 2);
    _text(canvas, a, Offset(r.outerRect.center.dx, 744), 18, const Color(0xFF8A4A00), width: w - 20);
    _text(canvas, b, Offset(r.outerRect.center.dx, 776), 14, const Color(0xFF6A3A00), width: w - 20, weight: FontWeight.w700);
  }
}

Future<void> _save(WidgetTester tester, Size size, void Function(Canvas, Size) paint, String name, {double scale = 1.5}) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    paint(canvas, size);
    final image = await recorder.endRecording().toImage((size.width * scale).round(), (size.height * scale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Baloo2');
    for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Baloo2-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
  });
  testWidgets('calm cubes', (tester) => _save(tester, const Size(1440, 760), calm, 'zincir-sakin.png'));
  testWidgets('vivid cubes', (tester) => _save(tester, const Size(1440, 760), vivid, 'zincir-canli.png'));
  testWidgets('gifts', (tester) => _save(tester, const Size(1000, 830), gifts, 'hediye-ozellik.png'));
}
