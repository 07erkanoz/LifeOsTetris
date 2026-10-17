// Mock-ups for a gold theme: a wooden board under warm lights, hammered
// gold cubes in seven golds (so pieces stay apart), shards of gold when a
// line goes, and the home lobby dressed in it.
//   flutter test tool/gold_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): altin-oyun.png,
// altin-ana-menu.png, altin-kupler.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart' show LokumPose, paintLokum, paintSparkle;

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';
const double _w = 430, _h = 932, _scale = 2.5;

/// Seven golds, one per piece: (light, mid, deep).
const golds = {
  'Sarı altın': (Color(0xFFFFF1A8), Color(0xFFE2B33C), Color(0xFF8A5A12)),
  'Pembe altın': (Color(0xFFFFD9C9), Color(0xFFE39A7E), Color(0xFF8A4632)),
  'Beyaz altın': (Color(0xFFFFFFFF), Color(0xFFCFD3D8), Color(0xFF6E7480)),
  'Yeşil altın': (Color(0xFFF3F7B0), Color(0xFFBFC24A), Color(0xFF5E6418)),
  'Kızıl altın': (Color(0xFFFFC7A0), Color(0xFFD9703A), Color(0xFF7A2E12)),
  'Bronz': (Color(0xFFF1C895), Color(0xFFB07A3E), Color(0xFF5A3614)),
  'Eski altın': (Color(0xFFF4DE9A), Color(0xFFB8913A), Color(0xFF5E4410)),
};
final _goldList = golds.values.toList();

const _ink = Color(0xFFFFE9B0);

// ------------------------------------------------------------------ wood --

void wood(Canvas canvas, Rect r, {int seed = 1, double lightness = 0}) {
  final base = [
    Color.lerp(const Color(0xFF8A5A30), Colors.white, lightness)!,
    Color.lerp(const Color(0xFF6E4424), Colors.white, lightness)!,
    Color.lerp(const Color(0xFF5A361C), Colors.white, lightness)!,
  ];
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, base, const [0, 0.5, 1]));
  final rnd = Random(seed);
  canvas.save();
  canvas.clipRect(r);
  // Grain: long wavy lines, a few darker.
  for (var i = 0; i < (r.height / 3.2).round(); i++) {
    final y0 = r.top + i * 3.2 + rnd.nextDouble() * 2;
    final amp = 1.5 + rnd.nextDouble() * 4;
    final freq = 0.008 + rnd.nextDouble() * 0.01;
    final phase = rnd.nextDouble() * 6;
    final p = Path()..moveTo(r.left, y0);
    for (var x = r.left; x <= r.right; x += 6) {
      p.lineTo(x, y0 + sin(x * freq + phase) * amp + sin(x * 0.05 + phase) * 0.6);
    }
    final dark = rnd.nextDouble() < 0.25;
    canvas.drawPath(p, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = dark ? 1.2 : 0.7
      ..color = (dark ? const Color(0xFF3A200E) : const Color(0xFFB98552)).withValues(alpha: dark ? 0.35 : 0.22));
  }
  // A couple of knots.
  for (var k = 0; k < 2; k++) {
    final c = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height);
    for (var i = 1; i < 6; i++) {
      canvas.drawOval(Rect.fromCenter(center: c, width: i * 9.0, height: i * 3.2), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF3A200E).withValues(alpha: 0.3 - i * 0.04));
    }
  }
  canvas.restore();
}

void spotlights(Canvas canvas, Rect r, int count) {
  canvas.save();
  canvas.clipRect(r);
  final reach = min(r.width / count * 0.75, r.height * 0.5);
  for (var i = 0; i < count; i++) {
    final c = Offset(r.left + r.width * (i + 0.5) / count, r.top);
    canvas.drawCircle(c, reach, Paint()
      ..shader = ui.Gradient.radial(c, reach, [const Color(0xFFFFD9A0).withValues(alpha: 0.42), const Color(0xFFFFC070).withValues(alpha: 0.12), const Color(0x00FFC070)], const [0, 0.45, 1]));
  }
  canvas.restore();
}

// ------------------------------------------------------------------ gold --

/// A hammered gold cube.
void goldCube(Canvas canvas, Rect cell, (Color, Color, Color) g, {int seed = 0}) {
  final (light, mid, deep) = g;
  final s = cell.width;
  final r = cell.deflate(s * 0.04);
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.1));
  canvas.drawRRect(rr.shift(Offset(s * 0.05, s * 0.08)), Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06));
  // Bevel sides.
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [light, mid, deep], const [0, 0.45, 1]));
  final face = RRect.fromRectAndRadius(r.deflate(s * 0.1), Radius.circular(s * 0.06));
  canvas.drawRRect(face, Paint()..shader = ui.Gradient.linear(face.outerRect.topLeft, face.outerRect.bottomRight, [Color.lerp(light, mid, 0.35)!, mid, Color.lerp(mid, deep, 0.45)!], const [0, 0.5, 1]));
  // Hammer dimples.
  canvas.save();
  canvas.clipRRect(face);
  final rnd = Random(seed * 31 + 7);
  // Hammer marks: shallow facets, lit on one side, shaded on the other.
  for (var i = 0; i < 26; i++) {
    final c = face.outerRect.topLeft + Offset(rnd.nextDouble() * face.width, rnd.nextDouble() * face.height);
    final d = s * (0.06 + rnd.nextDouble() * 0.06);
    final box = Rect.fromCircle(center: c, radius: d);
    canvas.drawArc(box, pi * 0.75, pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..color = light.withValues(alpha: 0.55));
    canvas.drawArc(box, -pi * 0.25, pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..color = deep.withValues(alpha: 0.35));
  }
  // A mirror streak and a hot spot: what makes it read as metal.
  final f = face.outerRect;
  canvas.drawPath(
      Path()
        ..moveTo(f.left, f.top + f.height * 0.55)
        ..lineTo(f.left + f.width * 0.55, f.top)
        ..lineTo(f.left + f.width * 0.8, f.top)
        ..lineTo(f.left, f.top + f.height * 0.85)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.22));
  canvas.drawCircle(f.topLeft + Offset(f.width * 0.28, f.height * 0.24), s * 0.16, Paint()
    ..shader = ui.Gradient.radial(f.topLeft + Offset(f.width * 0.28, f.height * 0.24), s * 0.16, [Colors.white.withValues(alpha: 0.7), Colors.white.withValues(alpha: 0)]));
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.025
    ..color = deep.withValues(alpha: 0.8));
  canvas.drawLine(r.topLeft + Offset(s * 0.12, s * 0.05), r.topRight + Offset(-s * 0.12, s * 0.05), Paint()
    ..strokeWidth = s * 0.03
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.7));
}

/// A gold shard flying off.
void shard(Canvas canvas, Offset c, double size, double turn, (Color, Color, Color) g, int seed) {
  final (light, mid, deep) = g;
  final rnd = Random(seed);
  final n = 4 + rnd.nextInt(3);
  final pts = [
    for (var i = 0; i < n; i++)
      c + Offset(cos(turn + i * 2 * pi / n + rnd.nextDouble() * 0.6), sin(turn + i * 2 * pi / n + rnd.nextDouble() * 0.6)) * size * (0.6 + rnd.nextDouble() * 0.5),
  ];
  final path = Path()..addPolygon(pts, true);
  canvas.drawPath(path, Paint()..shader = ui.Gradient.linear(pts.first, pts[n ~/ 2], [light, mid, deep], const [0, 0.5, 1]));
  canvas.drawPath(path, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..color = light.withValues(alpha: 0.9));
}

// ------------------------------------------------------------------ text --

void _text(Canvas canvas, String text, Offset at, double size, Color color, {FontWeight weight = FontWeight.w800, bool centre = false, double width = 400, double spacing = 0}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Inter', fontSize: size, fontWeight: weight, textAlign: centre ? TextAlign.center : TextAlign.left))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Inter', fontSize: size, fontWeight: weight, letterSpacing: spacing, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.6), offset: const Offset(0, 1.5), blurRadius: 2)]))
    ..addText(text);
  final p = b.build()..layout(ui.ParagraphConstraints(width: width));
  canvas.drawParagraph(p, centre ? at - Offset(width / 2, p.height / 2) : at);
}

Paint _goldText(Rect r) => Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFFFFF4C2), Color(0xFFF2C14E), Color(0xFFB07A1E)], const [0, 0.5, 1]);

void _goldTitle(Canvas canvas, String text, Offset c, double size) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Inter', fontSize: size, fontWeight: FontWeight.w900, textAlign: TextAlign.center))
    ..pushStyle(ui.TextStyle(foreground: _goldText(Rect.fromCenter(center: c, width: 10, height: size)), fontFamily: 'Inter', fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 1,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.7), offset: const Offset(0, 2), blurRadius: 3)]))
    ..addText(text);
  final p = b.build()..layout(const ui.ParagraphConstraints(width: 420));
  canvas.drawParagraph(p, c - Offset(210, p.height / 2));
}

/// A dark lacquered panel with a thin gold frame.
void panel(Canvas canvas, RRect r, {bool glow = false}) {
  canvas.drawRRect(r.shift(const Offset(0, 5)), Paint()..color = Colors.black.withValues(alpha: 0.5));
  if (glow) {
    canvas.drawRRect(r, Paint()
      ..color = const Color(0xFFFFC94A).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
  }
  canvas.drawRRect(r, Paint()..shader = ui.Gradient.linear(r.outerRect.topCenter, r.outerRect.bottomCenter, const [Color(0xFF3E2716), Color(0xFF24150B)]));
  canvas.drawRRect(r.deflate(1.5), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..shader = ui.Gradient.linear(r.outerRect.topLeft, r.outerRect.bottomRight, const [Color(0xFFFFE7A0), Color(0xFFB98A2E), Color(0xFFFFD36B), Color(0xFF8A5A12)], const [0, 0.35, 0.65, 1]));
}

void goldButton(Canvas canvas, Rect r, String label, {double size = 20}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.3));
  canvas.drawRRect(rr.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF5A3A10));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFFFFEFA8), Color(0xFFE2B33C), Color(0xFFB07A1E)], const [0, 0.5, 1]));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 10, r.top + 4, r.width - 20, r.height * 0.3), Radius.circular(r.height)), Paint()..color = Colors.white.withValues(alpha: 0.4));
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Inter', fontSize: size, fontWeight: FontWeight.w900, textAlign: TextAlign.center))
    ..pushStyle(ui.TextStyle(color: const Color(0xFF3A2208), fontFamily: 'Inter', fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 0.8))
    ..addText(label);
  final p = b.build()..layout(ui.ParagraphConstraints(width: r.width));
  canvas.drawParagraph(p, Offset(r.left, r.center.dy - p.height / 2));
}

/// Lokum in his gold best: a little crown.
void crownedLokum(Canvas canvas, Offset c, double size, LokumPose pose) {
  paintLokum(canvas, c, size, pose: pose);
  final k = c - Offset(0, size * 0.62);
  final crown = Path()
    ..moveTo(k.dx - size * 0.2, k.dy + size * 0.1)
    ..lineTo(k.dx - size * 0.22, k.dy - size * 0.1)
    ..lineTo(k.dx - size * 0.1, k.dy)
    ..lineTo(k.dx, k.dy - size * 0.16)
    ..lineTo(k.dx + size * 0.1, k.dy)
    ..lineTo(k.dx + size * 0.22, k.dy - size * 0.1)
    ..lineTo(k.dx + size * 0.2, k.dy + size * 0.1)
    ..close();
  canvas.drawPath(crown.shift(Offset(0, size * 0.03)), Paint()..color = const Color(0xFF5A3A10));
  canvas.drawPath(crown, Paint()..shader = ui.Gradient.linear(k - Offset(0, size * 0.16), k + Offset(0, size * 0.1), const [Color(0xFFFFF1A8), Color(0xFFE2B33C), Color(0xFFB07A1E)], const [0, 0.5, 1]));
  for (final dx in [-0.1, 0.0, 0.1]) {
    canvas.drawCircle(k + Offset(dx * size, size * 0.04), size * 0.025, Paint()..color = const Color(0xFFE0245A));
  }
}

void _icon(Canvas canvas, IconData icon, Offset c, double size) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: icon.fontFamily, fontSize: size))
    ..pushStyle(ui.TextStyle(foreground: _goldText(Rect.fromCenter(center: c, width: size, height: size)), fontFamily: icon.fontFamily, fontSize: size))
    ..addText(String.fromCharCode(icon.codePoint));
  final p = b.build()..layout(const ui.ParagraphConstraints(width: 100));
  canvas.drawParagraph(p, c - Offset(p.longestLine / 2, p.height / 2));
}

// --------------------------------------------------------------- screens --

void gameScreen(Canvas canvas) {
  final screen = Offset.zero & const Size(_w, _h);
  canvas.drawRect(screen, Paint()..color = const Color(0xFF1A100A));
  wood(canvas, screen, seed: 3, lightness: -0.25);
  canvas.drawRect(screen, Paint()..color = Colors.black.withValues(alpha: 0.35));

  // HUD: hold, score, next.
  final hold = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 40, 96, 92), const Radius.circular(18));
  final score = RRect.fromRectAndRadius(const Rect.fromLTWH(118, 40, 194, 92), const Radius.circular(18));
  final next = RRect.fromRectAndRadius(const Rect.fromLTWH(320, 40, 96, 92), const Radius.circular(18));
  for (final p in [hold, score, next]) {
    panel(canvas, p);
  }
  _text(canvas, 'TUT', hold.outerRect.topLeft + const Offset(14, 10), 12, _ink.withValues(alpha: 0.8), spacing: 2);
  _text(canvas, 'SKOR', score.outerRect.topLeft + const Offset(16, 10), 12, _ink.withValues(alpha: 0.8), spacing: 2);
  _goldTitle(canvas, '15.398', score.outerRect.center + const Offset(0, 4), 32);
  _text(canvas, 'SEVİYE 4 · SATIR 36', score.outerRect.bottomLeft + const Offset(16, -24), 11.5, _ink.withValues(alpha: 0.75), spacing: 1);
  _text(canvas, 'SIRADAKİ', next.outerRect.topLeft + const Offset(12, 10), 12, _ink.withValues(alpha: 0.8), spacing: 1.5);
  for (final (dx, dy) in [(0, 0), (1, 0), (1, -1), (2, -1)]) {
    goldCube(canvas, Rect.fromLTWH(hold.left + 22 + dx * 17.0, hold.top + 58 + dy * 17.0, 17, 17), _goldList[4], seed: dx + dy);
  }
  for (final (dx, dy) in [(0, 0), (1, 0), (2, 0), (1, -1)]) {
    goldCube(canvas, Rect.fromLTWH(next.left + 22 + dx * 17.0, next.top + 58 + dy * 17.0, 17, 17), _goldList[1], seed: dx * 3 + dy);
  }

  // The board: a wooden box under lights.
  const cols = 10, rows = 18;
  const cell = 38.0;
  const o = Offset((_w - cols * cell) / 2, 156);
  final well = Rect.fromLTWH(o.dx, o.dy, cols * cell, rows * cell);
  final frame = RRect.fromRectAndRadius(well.inflate(10), const Radius.circular(14));
  canvas.drawRRect(frame.shift(const Offset(0, 8)), Paint()
    ..color = Colors.black.withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  wood(canvas, frame.outerRect, seed: 9, lightness: -0.1);
  canvas.drawRRect(frame, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFF2A170A));
  wood(canvas, well, seed: 5, lightness: 0.05);
  // Inner shadow and lights.
  canvas.drawRect(well, Paint()
    ..shader = ui.Gradient.linear(well.topCenter, well.bottomCenter, [Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.2)], const [0, 0.25, 1]));
  spotlights(canvas, well, 4);

  // The stack.
  final stack = <String>[
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '......AAAA',
    '......AAAA',
    '.BB.CCCAAA',
    'BBBCCCCDDA',
    'BBBEEEEDDD',
    '..........', // clearing
    'FFFGGG.DDD',
    'FFGGGBBDDD',
    'FEEEBBBCCC',
    'EEEEBBCCCC',
  ];
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      final ch = stack[y][x];
      if (ch == '.') continue;
      goldCube(canvas, Rect.fromLTWH(o.dx + x * cell, o.dy + y * cell, cell, cell), _goldList[ch.codeUnitAt(0) - 65], seed: x * 7 + y);
    }
  }
  // The falling piece and its ghost.
  for (final (dx, dy) in [(0, 0), (1, 0), (2, 0), (1, -1)]) {
    goldCube(canvas, Rect.fromLTWH(o.dx + (3 + dx) * cell, o.dy + (3 + dy) * cell, cell, cell), _goldList[1], seed: dx + 40);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + (3 + dx) * cell, o.dy + (9 + dy) * cell, cell, cell).deflate(3), const Radius.circular(5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFD36B).withValues(alpha: 0.55));
  }
  // The line going: a flash and shards everywhere.
  final line = Rect.fromLTWH(well.left, o.dy + 13 * cell, well.width, cell);
  canvas.drawRect(line.inflate(6), Paint()
    ..color = const Color(0xFFFFE6A0).withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
  canvas.drawRect(line.deflate(cell * 0.3), Paint()..color = Colors.white.withValues(alpha: 0.85));
  final rnd = Random(11);
  for (var i = 0; i < 90; i++) {
    final x = well.left + rnd.nextDouble() * well.width * 1.15 - well.width * 0.07;
    final y = line.center.dy + (rnd.nextDouble() - 0.4) * cell * 6;
    final size = 3.0 + rnd.nextDouble() * 9;
    shard(canvas, Offset(x, y), size, rnd.nextDouble() * pi, _goldList[rnd.nextInt(_goldList.length)], i);
  }
  for (var i = 0; i < 18; i++) {
    paintSparkle(canvas, Offset(well.left + rnd.nextDouble() * well.width, line.center.dy + (rnd.nextDouble() - 0.5) * cell * 4), 3 + rnd.nextDouble() * 5, const Color(0xFFFFE6A0));
  }
  _goldTitle(canvas, 'ÇİFTE!', Offset(_w / 2, o.dy + 6.2 * cell), 46);
  _text(canvas, '+800', Offset(_w / 2, o.dy + 7.6 * cell), 22, _ink, centre: true);
}

void lobby(Canvas canvas) {
  final screen = Offset.zero & const Size(_w, _h);
  wood(canvas, screen, seed: 21, lightness: -0.12);
  canvas.drawRect(screen, Paint()..shader = ui.Gradient.radial(const Offset(_w / 2, 120), 520, [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.55)]));
  spotlights(canvas, screen, 3);

  // Header.
  for (final (dx, dy, g) in [(0.0, 8.0, 0), (11.0, 8.0, 1), (22.0, 8.0, 2), (11.0, -3.0, 4)]) {
    goldCube(canvas, Rect.fromLTWH(20 + dx, 46 + dy, 11, 11), _goldList[g], seed: g);
  }
  _text(canvas, 'LifeOS', const Offset(58, 38), 26, _ink, weight: FontWeight.w900);
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Inter', fontSize: 26, fontWeight: FontWeight.w900))
    ..pushStyle(ui.TextStyle(foreground: _goldText(const Rect.fromLTWH(0, 38, 10, 30)), fontFamily: 'Inter', fontSize: 26, fontWeight: FontWeight.w900))
    ..addText('Küpler');
  canvas.drawParagraph(b.build()..layout(const ui.ParagraphConstraints(width: 200)), const Offset(150, 38));
  panel(canvas, RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(_w - 36, 56), width: 42, height: 42), const Radius.circular(14)));
  _icon(canvas, Icons.settings_rounded, const Offset(_w - 36, 56), 24);

  // Lokum with his crown and the suggestion.
  crownedLokum(canvas, const Offset(72, 186), 96, LokumPose.cheer);
  final bubble = RRect.fromRectAndRadius(const Rect.fromLTWH(140, 116, _w - 156, 112), const Radius.circular(20));
  panel(canvas, bubble, glow: true);
  _text(canvas, 'Altın tema açıldı!', bubble.outerRect.topLeft + const Offset(16, 14), 17, _ink, weight: FontWeight.w900);
  _text(canvas, 'Her küp başka bir altından.', bubble.outerRect.topLeft + const Offset(16, 40), 13, _ink.withValues(alpha: 0.8), weight: FontWeight.w700);
  goldButton(canvas, Rect.fromLTWH(bubble.left + 16, bubble.top + 66, 132, 34), 'DENE  ›', size: 14);

  // Play card.
  final play = RRect.fromRectAndRadius(const Rect.fromLTWH(16, 246, _w - 32, 140), const Radius.circular(24));
  canvas.drawRRect(play.shift(const Offset(0, 6)), Paint()..color = const Color(0xFF5A3A10));
  canvas.drawRRect(play, Paint()..shader = ui.Gradient.linear(play.outerRect.topLeft, play.outerRect.bottomRight, const [Color(0xFFFFEFA8), Color(0xFFE2B33C), Color(0xFFB07A1E)], const [0, 0.5, 1]));
  canvas.drawRRect(play.deflate(2), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.6));
  _text(canvas, 'OYNA', play.outerRect.topLeft + const Offset(22, 22), 42, const Color(0xFF3A2208), weight: FontWeight.w900);
  _text(canvas, 'Süper Küpler', play.outerRect.topLeft + const Offset(24, 76), 17, const Color(0xFF3A2208), weight: FontWeight.w800);
  _text(canvas, 'Rekor 15.398', play.outerRect.topLeft + const Offset(24, 100), 13, const Color(0xFF5A3A10), weight: FontWeight.w700);
  final art = Rect.fromLTWH(play.right - 146, play.top + 12, 132, play.height - 24);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(art, const Radius.circular(14)));
  wood(canvas, art, seed: 2);
  spotlights(canvas, art, 2);
  const s = 16.0;
  for (var x = 0; x < 8; x++) {
    for (var y = 0; y < 2; y++) {
      if (y == 1 && (x == 3 || x == 4)) continue;
      goldCube(canvas, Rect.fromLTWH(art.left + 2 + x * s, art.bottom - (2 - y) * s - 2, s, s), _goldList[(x + y * 3) % 7], seed: x + y);
    }
  }
  for (final (dx, dy) in [(0, 0), (1, 0), (2, 0), (1, -1)]) {
    goldCube(canvas, Rect.fromLTWH(art.left + 2 + (2 + dx) * s, art.top + 30 + dy * s, s, s), _goldList[1], seed: dx);
  }
  canvas.restore();

  // Cards.
  _text(canvas, 'SENİN İÇİN', const Offset(22, 404), 13, _ink.withValues(alpha: 0.75), spacing: 1.5);
  for (var i = 0; i < 3; i++) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(16 + i * 174.0, 428, 162, 228), const Radius.circular(20));
    panel(canvas, r);
    final a = Rect.fromLTWH(r.left + 9, r.top + 9, r.width - 18, 108);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(a, const Radius.circular(12)));
    wood(canvas, a, seed: 30 + i);
    spotlights(canvas, a, 2);
    final rnd = Random(i);
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 7; x++) {
        if (rnd.nextDouble() < 0.25) continue;
        goldCube(canvas, Rect.fromLTWH(a.left + 4 + x * 19.0, a.bottom - (3 - y) * 19.0 - 4, 19, 19), _goldList[rnd.nextInt(7)], seed: x + y * 7);
      }
    }
    canvas.restore();
    final (title, line) = [('Bulmaca', '21 / 300 yıldız'), ('Zincir Küpler', 'Kaydır, zincir kur'), ('Klasik', 'Rekor 9.120')][i];
    _text(canvas, title, Offset(r.left + 14, r.top + 126), 16, _ink, weight: FontWeight.w900, width: 140);
    _text(canvas, line, Offset(r.left + 14, r.top + 150), 12.5, _ink.withValues(alpha: 0.78), weight: FontWeight.w700, width: 140);
  }

  // Daily and shortcuts.
  final daily = RRect.fromRectAndRadius(const Rect.fromLTWH(16, 676, _w - 32, 70), const Radius.circular(20));
  panel(canvas, daily, glow: true);
  _text(canvas, 'Günlük Görev', daily.outerRect.topLeft + const Offset(20, 14), 18, _ink, weight: FontWeight.w900);
  _text(canvas, '17 Ekim bulmacası', daily.outerRect.topLeft + const Offset(20, 40), 13, _ink.withValues(alpha: 0.8), weight: FontWeight.w700);
  goldButton(canvas, Rect.fromLTWH(daily.right - 96, daily.top + 18, 80, 34), 'OYNA', size: 14);
  const labels = ['Modlar', 'Tema', 'Ayarlar', 'Hakkında'];
  const tw = (_w - 32 - 30) / 4;
  for (var i = 0; i < 4; i++) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(16 + i * (tw + 10), 846, tw, 62), const Radius.circular(16));
    panel(canvas, r);
    _text(canvas, labels[i], r.outerRect.center + const Offset(0, 10), 13, _ink, centre: true, width: tw);
    _icon(canvas, const [Icons.grid_view_rounded, Icons.palette_rounded, Icons.settings_rounded, Icons.info_outline_rounded][i], r.outerRect.center - const Offset(0, 12), 22);
  }
}

void swatches(Canvas canvas) {
  final screen = Offset.zero & const Size(_w, _h);
  wood(canvas, screen, seed: 44, lightness: -0.18);
  canvas.drawRect(screen, Paint()..color = Colors.black.withValues(alpha: 0.25));
  _goldTitle(canvas, 'ALTIN TEMA', const Offset(_w / 2, 56), 34);
  _text(canvas, 'Her parça başka bir altından: oyunda karışmazlar.', const Offset(_w / 2, 96), 13.5, _ink, centre: true, width: 400, weight: FontWeight.w700);
  final names = golds.keys.toList();
  for (var i = 0; i < names.length; i++) {
    final y = 130.0 + i * 82;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(20, y, _w - 40, 72), const Radius.circular(16));
    panel(canvas, r);
    for (var k = 0; k < 4; k++) {
      goldCube(canvas, Rect.fromLTWH(r.left + 14 + k * 46.0, y + 13, 46, 46), _goldList[i], seed: i * 5 + k);
    }
    _text(canvas, names[i], Offset(r.left + 210, y + 24), 17, _ink, weight: FontWeight.w900);
  }
  // Shards.
  final rnd = Random(3);
  _text(canvas, 'Satır silinince saçılan altın parçaları', const Offset(_w / 2, 724), 13.5, _ink, centre: true, width: 400, weight: FontWeight.w700);
  for (var i = 0; i < 46; i++) {
    shard(canvas, Offset(40 + rnd.nextDouble() * (_w - 80), 760 + rnd.nextDouble() * 140), 4 + rnd.nextDouble() * 10, rnd.nextDouble() * pi, _goldList[rnd.nextInt(7)], i);
  }
}

Future<void> _save(WidgetTester tester, void Function(Canvas) paint, String name) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_scale);
    paint(canvas);
    final image = await recorder.endRecording().toImage((_w * _scale).round(), (_h * _scale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

Future<void> _loadFonts() async {
  final loader = FontLoader('Inter');
  for (final w in ['Regular', 'SemiBold', 'ExtraBold', 'Black']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Inter-$w.otf').readAsBytesSync())));
  }
  await loader.load();
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf').readAsBytesSync())));
  await icons.load();
}

void main() {
  setUpAll(_loadFonts);
  testWidgets('game', (tester) => _save(tester, gameScreen, 'altin-oyun.png'));
  testWidgets('lobby', (tester) => _save(tester, lobby, 'altin-ana-menu.png'));
  testWidgets('swatches', (tester) => _save(tester, swatches, 'altin-kupler.png'));
}
