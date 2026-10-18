// Mock-up of clearer special sweets in Şeker Küpler: specials that glow on
// the board, a spark between two that can be swapped together, and a look
// and a name of its own for every combination.
//   flutter test tool/sugar_combo_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): seker-kombolar.png.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

import 'mock_kit.dart';

const _n = 7;
const _soft = Color(0xFFD9C8F5);

/// A board of [_n]×[_n] sweets at [o], cells [s] wide; [specials] go on
/// top, [skip] cells stay empty (they just went off).
void _board(Canvas canvas, Offset o, double s, {Map<(int, int), (SugarColor, Special)> specials = const {}, Set<(int, int)> skip = const {}, int seed = 0, double dim = 0}) {
  final r = Rect.fromLTWH(o.dx, o.dy, _n * s, _n * s);
  final rr = RRect.fromRectAndRadius(r.inflate(8), const Radius.circular(18));
  canvas.drawRRect(rr.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF12061F));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF5A2A9A), Color(0xFF3A1268)]));
  for (var y = 0; y < _n; y++) {
    for (var x = 0; x < _n; x++) {
      final cell = Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s);
      if ((x + y).isEven) canvas.drawRRect(RRect.fromRectAndRadius(cell.deflate(1), Radius.circular(s * 0.18)), Paint()..color = Colors.white.withValues(alpha: 0.05));
      if (skip.contains((x, y))) continue;
      final sp = specials[(x, y)];
      if (sp != null) continue;
      paintCandy(canvas, cell.deflate(s * 0.06), SugarColor.values[(x * 3 + y * 5 + seed + (x * y) % 3) % 6]);
    }
  }
  if (dim > 0) canvas.drawRRect(rr, Paint()..color = const Color(0xFF12061F).withValues(alpha: dim));
  for (final e in specials.entries) {
    final (x, y) = e.key;
    final (color, special) = e.value;
    paintSugarPiece(canvas, Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(s * 0.06), color, special);
  }
}

/// Only the specials, over a board already painted.
void _specialsOnly(Canvas canvas, Offset o, double s, Map<(int, int), (SugarColor, Special)> specials) {
  for (final e in specials.entries) {
    final (x, y) = e.key;
    paintSugarPiece(canvas, Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(s * 0.06), e.value.$1, e.value.$2);
  }
}

Offset _at(Offset o, double s, int x, int y) => o + Offset((x + 0.5) * s, (y + 0.5) * s);

/// The new look of a special on the board: a soft halo that breathes, a
/// ring around it and a sparkle on top.
void _glowSpecial(Canvas canvas, Offset c, double s, Color tone, {double beat = 1}) {
  canvas.drawCircle(c, s * (0.62 + 0.08 * beat), Paint()
    ..shader = ui.Gradient.radial(c, s * (0.62 + 0.08 * beat), [tone.withValues(alpha: 0.75), tone.withValues(alpha: 0)]));
  canvas.drawCircle(c, s * 0.52, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.05
    ..color = Colors.white.withValues(alpha: 0.75 * beat));
}

void _beam(Canvas canvas, Rect r, {Color tone = const Color(0xFFFF7AD0), double core = 0.35}) {
  final glow = Paint()
    ..shader = ui.Gradient.linear(r.width > r.height ? r.topCenter : r.centerLeft, r.width > r.height ? r.bottomCenter : r.centerRight,
        [tone.withValues(alpha: 0), tone.withValues(alpha: 0.85), tone.withValues(alpha: 0)], const [0, 0.5, 1])
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  canvas.drawRect(r, glow);
  final c = r.center;
  final coreRect = r.width > r.height ? Rect.fromCenter(center: c, width: r.width, height: r.height * core) : Rect.fromCenter(center: c, width: r.width * core, height: r.height);
  canvas.drawRRect(RRect.fromRectAndRadius(coreRect, Radius.circular(coreRect.shortestSide / 2)), Paint()..color = Colors.white);
}

void _sparks(Canvas canvas, Offset c, double radius, int n, {int seed = 1}) {
  final rnd = Random(seed);
  for (var i = 0; i < n; i++) {
    final a = rnd.nextDouble() * 2 * pi;
    final d = radius * (0.5 + rnd.nextDouble() * 0.6);
    paintSparkle(canvas, c + Offset(cos(a) * d, sin(a) * d), 5 + rnd.nextDouble() * 7, i.isEven ? Colors.white : const Color(0xFFFFE066));
  }
}

void _panel(Canvas canvas, Rect r, String title, String line) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(26));
  canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.06));
  mockText(canvas, title, Offset(r.center.dx, r.top + 30), 21, Colors.white, width: r.width - 20);
  mockText(canvas, line, Offset(r.center.dx, r.bottom - 34), 13.5, _soft, width: r.width - 30, weight: FontWeight.w600, lines: 2);
}

/// Two specials side by side, before the swap: the formula of the combo.
void _formula(Canvas canvas, Offset c, (SugarColor, Special) a, (SugarColor, Special) b) {
  const s = 34.0;
  paintSugarPiece(canvas, Rect.fromCenter(center: c - const Offset(34, 0), width: s, height: s), a.$1, a.$2);
  mockText(canvas, '+', c, 22, Colors.white, width: 30);
  paintSugarPiece(canvas, Rect.fromCenter(center: c + const Offset(34, 0), width: s, height: s), b.$1, b.$2);
}

void _sheet(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));
  mockText(canvas, 'Şeker Küpler · özel şekerler ve kombolar', Offset(size.width / 2, 44), 30, Colors.white, width: size.width);
  mockText(canvas, 'Özel şekerler tahtada hemen göze çarpar; iki özel şeker birleşince her birleşimin kendi efekti ve adı olur.',
      Offset(size.width / 2, 86), 16, _soft, width: size.width - 80, weight: FontWeight.w600);

  const s = 40.0;
  const boardW = _n * s;
  const panelW = boardW + 60, panelH = boardW + 150;
  const gap = 24.0;
  double left(int i) => 40 + i * (panelW + gap);
  const top1 = 130.0;

  // ---- 1 · today
  final specials = {
    (1, 2): (SugarColor.red, Special.lineH),
    (4, 1): (SugarColor.blue, Special.bomb),
    (5, 5): (SugarColor.yellow, Special.prism),
    (2, 5): (SugarColor.green, Special.lineV),
    (3, 5): (SugarColor.purple, Special.bomb),
  };
  {
    final r = Rect.fromLTWH(left(0), top1, panelW, panelH);
    _panel(canvas, r, '1 · Şimdi', 'Özel şekerler sıradan şekerlerin arasında kayboluyor.');
    _board(canvas, Offset(r.left + 30, r.top + 62), s, specials: specials);
  }
  // ---- 2 · glowing specials
  {
    final r = Rect.fromLTWH(left(1), top1, panelW, panelH);
    _panel(canvas, r, '2 · Parlayan özel şekerler', 'Hafif bir ışık ve halka; nabız gibi atar. Sıradan şekerler biraz sönük kalır.');
    final o = Offset(r.left + 30, r.top + 62);
    _board(canvas, o, s, specials: specials, dim: 0.18);
    for (final e in specials.entries) {
      final (x, y) = e.key;
      final tone = e.value.$2 == Special.prism ? const Color(0xFFFFFFFF) : sugarColors[e.value.$1]!;
      _glowSpecial(canvas, _at(o, s, x, y), s, tone);
    }
    _specialsOnly(canvas, o, s, specials);
    for (final e in specials.keys) {
      paintSparkle(canvas, _at(o, s, e.$1, e.$2) + Offset(s * 0.34, -s * 0.34), 7, Colors.white);
    }
  }
  // ---- 3 · two specials side by side: a spark between them
  {
    final r = Rect.fromLTWH(left(2), top1, panelW, panelH);
    _panel(canvas, r, '3 · Birleştirilebilir!', 'Yan yana iki özel şekerin arasında kıvılcım çakar: "bunları birleştir" der.');
    final o = Offset(r.left + 30, r.top + 62);
    _board(canvas, o, s, specials: specials, dim: 0.3);
    final a = _at(o, s, 2, 5), b = _at(o, s, 3, 5);
    _glowSpecial(canvas, a, s, sugarColors[SugarColor.green]!);
    _glowSpecial(canvas, b, s, sugarColors[SugarColor.purple]!);
    _specialsOnly(canvas, o, s, {(2, 5): specials[(2, 5)]!, (3, 5): specials[(3, 5)]!});
    // The spark: a little lightning between them.
    final path = Path()..moveTo(a.dx + s * 0.3, a.dy);
    for (var i = 1; i <= 4; i++) {
      path.lineTo(a.dx + s * 0.3 + (b.dx - a.dx - s * 0.6) * i / 4, a.dy + (i.isOdd ? -6 : 6) * (i == 4 ? 0 : 1));
    }
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xFFFFE066).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white);
    paintSparkle(canvas, (a + b) / 2 - const Offset(0, 16), 9, const Color(0xFFFFE066));
    mockBubble(canvas, Rect.fromLTWH(o.dx + 40, o.dy + s * 3.6, 190, 44), 'Bunları birleştir!', size: 15);
  }

  // ---- the combos
  const top2 = top1 + panelH + 30;
  final combos = [
    (
      'ÇAPRAZ!',
      'Çizgili + çizgili',
      'Satır ve sütun birlikte: artı şeklinde iki ışın.',
      (SugarColor.red, Special.lineH),
      (SugarColor.blue, Special.lineV),
    ),
    (
      'DEV IŞIN!',
      'Çizgili + paketli',
      'Üç satır, üç sütun: kalın bir artı. Şeker büyüyüp öyle patlar.',
      (SugarColor.green, Special.lineV),
      (SugarColor.purple, Special.bomb),
    ),
    (
      'MEGA PATLAMA!',
      'Paketli + paketli',
      '5×5 dev patlama, bir de ikinci dalga. Tahta sarsılır.',
      (SugarColor.orange, Special.bomb),
      (SugarColor.blue, Special.bomb),
    ),
    (
      'GÖKKUŞAĞI!',
      'Gökkuşağı topu + şeker',
      'O renkteki bütün şekerlere şimşek çakar.',
      (SugarColor.yellow, Special.prism),
      (SugarColor.red, Special.none),
    ),
  ];
  for (final (i, (name, formula, line, a, b)) in combos.indexed) {
    final r = Rect.fromLTWH(left(0) + i * ((size.width - 80 - 3 * gap) / 4 + gap), top2, (size.width - 80 - 3 * gap) / 4, panelH - 20);
    _panel(canvas, r, formula, line);
    _formula(canvas, Offset(r.center.dx, r.top + 70), a, b);
    const s = 31.0;
    const boardW = _n * s;
    final o = Offset(r.center.dx - boardW / 2, r.top + 108);
    const mid = (3, 3);
    switch (i) {
      case 0:
        _board(canvas, o, s, skip: {for (var k = 0; k < _n; k++) (k, 3), for (var k = 0; k < _n; k++) (3, k)});
        _beam(canvas, Rect.fromLTWH(o.dx - 10, o.dy + 3 * s, boardW + 20, s));
        _beam(canvas, Rect.fromLTWH(o.dx + 3 * s, o.dy - 10, s, boardW + 20));
        _sparks(canvas, _at(o, s, mid.$1, mid.$2), 30, 6);
      case 1:
        _board(canvas, o, s, skip: {for (var k = 0; k < _n; k++) for (var w = 2; w <= 4; w++) ...{(k, w), (w, k)}});
        _beam(canvas, Rect.fromLTWH(o.dx - 10, o.dy + 2 * s, boardW + 20, 3 * s), tone: const Color(0xFFB46CFF), core: 0.28);
        _beam(canvas, Rect.fromLTWH(o.dx + 2 * s, o.dy - 10, 3 * s, boardW + 20), tone: const Color(0xFFB46CFF), core: 0.28);
        _sparks(canvas, _at(o, s, mid.$1, mid.$2), 60, 8, seed: 3);
      case 2:
        final c = _at(o, s, mid.$1, mid.$2);
        _board(canvas, o, s, skip: {for (var y = 1; y <= 5; y++) for (var x = 1; x <= 5; x++) (x, y)});
        canvas.drawCircle(c, s * 2.9, Paint()..shader = ui.Gradient.radial(c, s * 2.9, const [Color(0xFFFFFFFF), Color(0xFFFFD36A), Color(0x00FF7A2A)], const [0, 0.45, 1]));
        for (final (rad, w) in [(s * 3.0, 6.0), (s * 3.7, 3.0)]) {
          canvas.drawCircle(c, rad, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..color = Colors.white.withValues(alpha: 0.8));
        }
        _sparks(canvas, c, s * 3.2, 12, seed: 5);
      case 3:
        final ball = _at(o, s, 3, 3);
        final targets = <(int, int)>[for (var y = 0; y < _n; y++) for (var x = 0; x < _n; x++) if ((x * 3 + y * 5 + (x * y) % 3) % 6 == 0) (x, y)];
        _board(canvas, o, s, dim: 0.35);
        for (final (x, y) in targets) {
          final t = _at(o, s, x, y);
          final path = Path()..moveTo(ball.dx, ball.dy);
          const steps = 5;
          for (var k = 1; k <= steps; k++) {
            final p = Offset.lerp(ball, t, k / steps)!;
            final n = Offset(-(t - ball).dy, (t - ball).dx) / max(1, (t - ball).distance);
            path.lineTo(p.dx + n.dx * (k == steps ? 0 : (k.isOdd ? 6 : -6)), p.dy + n.dy * (k == steps ? 0 : (k.isOdd ? 6 : -6)));
          }
          canvas.drawPath(path, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = const Color(0xFFFF9AD8).withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
          canvas.drawPath(path, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white);
          canvas.drawCircle(t, s * 0.45, Paint()..color = Colors.white.withValues(alpha: 0.5));
          paintCandy(canvas, Rect.fromCenter(center: t, width: s * 0.88, height: s * 0.88), SugarColor.red);
        }
        canvas.drawCircle(ball, s * 0.9, Paint()..shader = ui.Gradient.radial(ball, s * 0.9, const [Color(0xFFFFFFFF), Color(0x00FFFFFF)]));
        paintRainbow(canvas, Rect.fromCenter(center: ball, width: s * 1.1, height: s * 1.1));
    }
    mockLabel(canvas, name, Offset(r.center.dx, o.dy + boardW / 2), 28);
  }
}

void main() {
  setUpAll(mockFonts);

  testWidgets('sugar combos', (tester) async {
    await mockSave(tester, const Size(40 * 2 + (_n * 40 + 60) * 3 + 24 * 2, 130 + (_n * 40 + 150) * 2 + 30 + 20), _sheet, 'seker-kombolar.png', scale: 2);
  });
}
