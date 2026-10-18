// Mock-up of a livelier gifts screen: today's gift that bounces and asks to
// be taken, days already taken stamped ALINDI, the time to the next gift, a
// full jar that shakes and shines, and opening a gift as a little show.
//   flutter test tool/gifts_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): hediyeler-yeni.png.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/ui/gift_art.dart';

import 'mock_kit.dart';

const _ink = mockInk;
const _muted = mockMuted;
const _soft = Color(0xFFD9C8F5);

void _hammer(Canvas canvas, Offset c, double s, {double alpha = 1}) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(s / 68);
  canvas.rotate(-0.6);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 6), width: 7, height: 34), const Radius.circular(3)), Paint()..color = const Color(0xFFB0703A).withValues(alpha: alpha));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -12), width: 32, height: 16), const Radius.circular(5)), Paint()..color = const Color(0xFFA8B0C0).withValues(alpha: alpha));
  canvas.restore();
}

void _moves(Canvas canvas, Offset c, double s) => paintSugarLabel(canvas, '+3', c, s * 0.42,
    Paint()..shader = ui.Gradient.linear(c - Offset(0, s * 0.2), c + Offset(0, s * 0.2), const [Color(0xFFFF7AC6), Color(0xFFE0247A)]), outline: Colors.white, stroke: 0.18);

/// A wrapped present: pink box, gold ribbon and bow.
void _present(Canvas canvas, Offset c, double s, {double tilt = 0, double lid = 0}) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(tilt);
  final box = Rect.fromCenter(center: Offset(0, s * 0.12), width: s * 0.8, height: s * 0.56);
  canvas.drawRRect(RRect.fromRectAndRadius(box.shift(Offset(0, s * 0.04)), Radius.circular(s * 0.08)), Paint()..color = Colors.black.withValues(alpha: 0.25));
  canvas.drawRRect(RRect.fromRectAndRadius(box, Radius.circular(s * 0.08)), Paint()..shader = ui.Gradient.linear(box.topCenter, box.bottomCenter, const [Color(0xFFFF7AC6), Color(0xFFD0207A)]));
  final gold = Paint()..shader = ui.Gradient.linear(Offset(-s / 2, 0), Offset(s / 2, 0), chestGold, const [0, 0.5, 1]);
  canvas.drawRect(Rect.fromCenter(center: box.center, width: s * 0.14, height: box.height), gold);
  final top = Rect.fromCenter(center: Offset(0, box.top - s * 0.06 - lid), width: s * 0.9, height: s * 0.18);
  canvas.drawRRect(RRect.fromRectAndRadius(top, Radius.circular(s * 0.06)), Paint()..shader = ui.Gradient.linear(top.topCenter, top.bottomCenter, const [Color(0xFFFF9AD8), Color(0xFFE0247A)]));
  canvas.drawRect(Rect.fromCenter(center: top.center, width: s * 0.14, height: top.height), gold);
  for (final dir in [-1.0, 1.0]) {
    canvas.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.13, top.top - s * 0.07), width: s * 0.26, height: s * 0.16), gold);
  }
  canvas.restore();
}

/// Little arcs beside a thing that bounces or shakes.
void _wiggle(Canvas canvas, Offset c, double r, {Color color = Colors.white}) {
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = color.withValues(alpha: 0.9);
  for (final dir in [-1.0, 1.0]) {
    for (var i = 0; i < 2; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r + i * 8), dir < 0 ? pi - 0.35 : -0.35, 0.7, false, p);
    }
  }
}

void _glow(Canvas canvas, Offset c, double r, Color color) => canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c, r, [color, color.withValues(alpha: 0)]));

void _stamp(Canvas canvas, Rect r) {
  // A diagonal ribbon across the tile: ALINDI.
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(16)));
  canvas.translate(r.center.dx, r.center.dy + 6);
  canvas.rotate(-0.42);
  final band = Rect.fromCenter(center: Offset.zero, width: r.width * 1.6, height: 22);
  canvas.drawRect(band, Paint()..color = const Color(0xFF1FB85A));
  mockText(canvas, 'ALINDI', Offset.zero, 12.5, Colors.white, width: 100);
  canvas.restore();
  canvas.drawCircle(r.bottomRight + const Offset(-14, -14), 11, Paint()..color = const Color(0xFF1FB85A));
  canvas.drawPath(Path()
    ..moveTo(r.right - 19, r.bottom - 14)
    ..lineTo(r.right - 15, r.bottom - 10)
    ..lineTo(r.right - 9, r.bottom - 18), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..color = Colors.white);
}

void _lock(Canvas canvas, Offset c, double s, {Color color = const Color(0xFFB8A8D0)}) {
  canvas.drawArc(Rect.fromCenter(center: c - Offset(0, s * 0.22), width: s * 0.5, height: s * 0.55), pi, pi, false, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.12
    ..color = color);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, s * 0.12), width: s * 0.7, height: s * 0.52), Radius.circular(s * 0.1)), Paint()..color = color);
}

enum _Day { taken, today, next, later }

void _day(Canvas canvas, Rect r, int n, _Day state, void Function(Offset c, double alpha) items, {bool big = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(16));
  final today = state == _Day.today;
  if (today) _glow(canvas, r.center, r.longestSide * 0.9, const Color(0xAAFFE066));
  final colors = switch (state) {
    _Day.today => const [Color(0xFFFFF3C8), Color(0xFFFFC94A)],
    _Day.taken => const [Color(0xFFE6F9EE), Color(0xFFC9F0D8)],
    _Day.next => const [Colors.white, Color(0xFFFFEAF6)],
    _Day.later => const [Color(0xFFF4ECF8), Color(0xFFEADFF0)],
  };
  canvas.drawRRect(rr.shift(const Offset(0, 3)), Paint()..color = const Color(0x33000000));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = today ? 3.5 : 2
    ..color = today ? const Color(0xFFFFB000) : (state == _Day.next ? const Color(0xFFFF9AD8) : Colors.white));
  mockText(canvas, '$n. gün', Offset(r.center.dx, r.top + 15), 13, today ? const Color(0xFF8A4A00) : (state == _Day.later ? const Color(0xFFB8A8D0) : _muted), width: r.width);
  items(r.center + const Offset(0, 4), switch (state) {
    _Day.taken => 0.4,
    _Day.later => 0.55,
    _ => 1,
  });
  switch (state) {
    case _Day.taken:
      _stamp(canvas, r);
    case _Day.today:
      final ribbon = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(r.center.dx, r.bottom - 12), width: 62, height: 18), const Radius.circular(9));
      canvas.drawRRect(ribbon, Paint()..color = const Color(0xFFE0247A));
      mockText(canvas, 'BUGÜN', ribbon.center, 11, Colors.white, width: 62);
    case _Day.next:
      mockText(canvas, 'yarın', Offset(r.center.dx, r.bottom - 12), 11.5, const Color(0xFFE0247A), width: r.width);
    case _Day.later:
      if (!big) _lock(canvas, Offset(r.center.dx, r.bottom - 14), 14);
  }
}

void _gifts(Canvas canvas, Offset c, int day, double alpha) {
  switch (day) {
    case 1:
      _hammer(canvas, c - const Offset(8, 0), 24, alpha: alpha);
      mockText(canvas, '×2', c + const Offset(16, 0), 13, _ink.withValues(alpha: alpha), width: 30);
    case 2:
      _moves(canvas, c - const Offset(8, 0), 30);
      mockText(canvas, '×2', c + const Offset(16, 0), 13, _ink.withValues(alpha: alpha), width: 30);
    case 3:
      _hammer(canvas, c - const Offset(8, 8), 22, alpha: alpha);
      paintRainbow(canvas, Rect.fromCenter(center: c + const Offset(8, 10), width: 18, height: 18));
    default:
      paintRainbow(canvas, Rect.fromCenter(center: c - const Offset(8, 0), width: 18, height: 18));
      mockText(canvas, '×2', c + const Offset(16, 0), 13, _ink.withValues(alpha: alpha), width: 30);
  }
}

void _screen(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF7A3AC8), Color(0xFFB0307A), Color(0xFF4A1A7A)], const [0, 0.5, 1]));
  canvas.drawCircle(const Offset(40, 80), 26, Paint()..color = Colors.white);
  final arrow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _ink;
  canvas.drawLine(const Offset(30, 80), const Offset(51, 80), arrow);
  canvas.drawPath(Path()
    ..moveTo(39, 71)
    ..lineTo(30, 80)
    ..lineTo(39, 89), arrow);
  mockLabel(canvas, 'HEDİYELER', Offset(size.width / 2 + 10, 80), 34);
}

/// The daily calendar: [taken] days taken, today's ready or not.
void _calendar(Canvas canvas, Rect r, {required int taken, required bool ready}) {
  mockCard(canvas, RRect.fromRectAndRadius(r, const Radius.circular(28)));
  mockText(canvas, 'Günlük hediye', Offset(r.center.dx, r.top + 30), 24, _ink, width: r.width);
  const gap = 8.0;
  final w = (r.width - 28 - gap * 3) / 4;
  const h = 96.0;
  for (var d = 0; d < 7; d++) {
    final x = r.left + 14 + (d % 4) * (w + gap);
    final y = r.top + 58 + (d ~/ 4) * (h + gap);
    final big = d == 6;
    final tile = Rect.fromLTWH(x, y, big ? w * 2 + gap : w, h);
    final state = d < taken
        ? _Day.taken
        : d == taken
        ? (ready ? _Day.today : _Day.next)
        : (d == taken + 1 && ready ? _Day.next : _Day.later);
    if (big) {
      _day(canvas, tile, d + 1, state, (c, a) {
        paintChest(canvas, c - const Offset(34, -2), 50, chestGold, glow: true);
        mockText(canvas, 'Büyük\nsandık', c + const Offset(34, 0), 14, _ink, width: 90);
      }, big: true);
      for (final (dx, dy) in [(-62.0, -26.0), (-12.0, -30.0)]) {
        paintSparkle(canvas, tile.center + Offset(dx, dy), 6, const Color(0xFFFFE066));
      }
    } else if (state == _Day.today) {
      // Today's gift sits in a present that hops.
      _day(canvas, tile, d + 1, state, (c, a) {});
      _present(canvas, tile.center + const Offset(0, -2), 50, tilt: -0.12);
      _wiggle(canvas, tile.center + const Offset(0, -4), 28, color: const Color(0xFFFFB000));
    } else {
      _day(canvas, tile, d + 1, state, (c, a) => _gifts(canvas, c, d + 1, a));
    }
  }
  final bottom = r.top + 58 + 2 * (h + gap) + 6;
  if (ready) {
    final b = Rect.fromLTWH(r.left + 14, bottom, r.width - 28, 52);
    _glow(canvas, b.center, b.width * 0.55, const Color(0x66FFFFFF));
    mockButton(canvas, b, 'HEDİYENİ AL');
  } else {
    final pill = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 14, bottom, r.width - 28, 46), const Radius.circular(23));
    canvas.drawRRect(pill, Paint()..color = const Color(0xFFF3E6FA));
    canvas.drawCircle(pill.outerRect.centerLeft + const Offset(28, 0), 13, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFE0247A));
    canvas.drawLine(pill.outerRect.centerLeft + const Offset(28, 0), pill.outerRect.centerLeft + const Offset(28, -8), Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE0247A));
    canvas.drawLine(pill.outerRect.centerLeft + const Offset(28, 0), pill.outerRect.centerLeft + const Offset(34, 3), Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE0247A));
    mockText(canvas, 'Sıradaki hediye: 9 sa 12 dk sonra', pill.center + const Offset(14, 0), 15, _ink, width: r.width - 80);
  }
}

void _jar(Canvas canvas, Rect r, {required bool full}) {
  mockCard(canvas, RRect.fromRectAndRadius(r, const Radius.circular(28)));
  mockText(canvas, 'Şeker kavanozu', Offset(r.center.dx, r.top + 30), 24, _ink, width: r.width);
  final c = Offset(r.center.dx, r.top + 130);
  if (full) {
    _glow(canvas, c, 110, const Color(0x99FFE066));
    // Rays turning behind it.
    final ray = Paint()..color = const Color(0x33FFC21A);
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6 + 0.1;
      canvas.drawPath(Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.1) * 120, c.dy + sin(a - 0.1) * 120)
        ..lineTo(c.dx + cos(a + 0.1) * 120, c.dy + sin(a + 0.1) * 120)
        ..close(), ray);
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.08);
    paintJar(canvas, Offset.zero, 120, 1, shine: true);
    canvas.restore();
    _wiggle(canvas, c, 74, color: const Color(0xFFFFB000));
    for (final (dx, dy, k) in [(-70.0, -50.0, 9.0), (66.0, -64.0, 11.0), (78.0, 30.0, 7.0), (-60.0, 50.0, 8.0)]) {
      paintSparkle(canvas, c + Offset(dx, dy), k, dx < 0 ? Colors.white : const Color(0xFFFFE066));
    }
    // A sweet popping out of the lid.
    paintCandy(canvas, Rect.fromCenter(center: c + const Offset(26, -80), width: 22, height: 22), SugarColor.red);
    paintCandy(canvas, Rect.fromCenter(center: c + const Offset(-20, -86), width: 18, height: 18), SugarColor.yellow);
    mockProgress(canvas, Rect.fromLTWH(r.left + 20, r.top + 226, r.width - 40, 16), 1, colors: const [Color(0xFFFFF06A), Color(0xFFFF8A10)], track: const Color(0x33E0247A));
    mockText(canvas, 'Kavanoz doldu! İçinde ne var?', Offset(r.center.dx, r.top + 262), 17, const Color(0xFF8A4A00), width: r.width);
    final b = Rect.fromLTWH(r.left + 20, r.top + 284, r.width - 40, 50);
    _glow(canvas, b.center, b.width * 0.6, const Color(0x88FF9AD8));
    mockButton(canvas, b, 'KAVANOZU AÇ', colors: const [Color(0xFFFF9AD8), Color(0xFFE0247A)], shade: const Color(0xFF8A1A4A));
  } else {
    paintJar(canvas, c, 120, 0.04);
    mockProgress(canvas, Rect.fromLTWH(r.left + 20, r.top + 226, r.width - 40, 16), 0.02, track: const Color(0x33E0247A));
    mockText(canvas, '12 / 500 şeker', Offset(r.center.dx, r.top + 262), 17, _ink, width: r.width);
    mockText(canvas, 'Şeker Küpler\'de patlattığın şekerler buraya dolar.', Offset(r.center.dx, r.top + 300), 14, _muted, width: r.width - 30, weight: FontWeight.w600);
  }
}

void _ready(Canvas canvas, Size size) {
  _screen(canvas, size);
  _calendar(canvas, Rect.fromLTWH(16, 120, size.width - 32, 336), taken: 1, ready: true);
  _jar(canvas, Rect.fromLTWH(16, 476, size.width - 32, 360), full: true);
}

void _after(Canvas canvas, Size size) {
  _screen(canvas, size);
  _calendar(canvas, Rect.fromLTWH(16, 120, size.width - 32, 330), taken: 2, ready: false);
  _jar(canvas, Rect.fromLTWH(16, 470, size.width - 32, 340), full: false);
}

/// Opening a present, in three steps.
void _opening(Canvas canvas, Rect r, int step) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(26));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF4A1A7A), Color(0xFF2A0E4A)]));
  final c = Offset(r.center.dx, r.top + r.height * 0.42);
  switch (step) {
    case 0:
      _glow(canvas, c, 90, const Color(0x66FFE066));
      _present(canvas, c, 110, tilt: 0.14);
      _wiggle(canvas, c, 64, color: const Color(0xFFFFE066));
      mockLabel(canvas, '!', c + const Offset(56, -60), 34);
      mockText(canvas, 'Kutu sallanır', Offset(r.center.dx, r.bottom - 40), 17, Colors.white, width: r.width);
    case 1:
      _glow(canvas, c, 130, const Color(0xCCFFF0A0));
      final ray = Paint()..color = const Color(0x66FFFFFF);
      for (var i = 0; i < 14; i++) {
        final a = i * 2 * pi / 14;
        canvas.drawPath(Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + cos(a - 0.08) * 140, c.dy + sin(a - 0.08) * 140)
          ..lineTo(c.dx + cos(a + 0.08) * 140, c.dy + sin(a + 0.08) * 140)
          ..close(), ray);
      }
      _present(canvas, c + const Offset(0, 30), 100, lid: 46);
      final rnd = Random(3);
      for (var i = 0; i < 22; i++) {
        final a = rnd.nextDouble() * 2 * pi;
        final d = 50 + rnd.nextDouble() * 80;
        final p = c + Offset(cos(a) * d, sin(a) * d - 20);
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(a);
        canvas.drawRect(const Rect.fromLTWH(-5, -2.5, 10, 5), Paint()..color = [const Color(0xFFFF5FB8), const Color(0xFFFFE066), const Color(0xFF6BF0A0), const Color(0xFF7AC8FF)][i % 4]);
        canvas.restore();
      }
      _hammer(canvas, c + const Offset(-50, -70), 40);
      paintRainbow(canvas, Rect.fromCenter(center: c + const Offset(48, -76), width: 34, height: 34));
      mockText(canvas, 'Patlar, hediyeler fırlar', Offset(r.center.dx, r.bottom - 40), 17, Colors.white, width: r.width);
    case 2:
      mockLabel(canvas, 'HEPSİ SENİN!', Offset(r.center.dx, r.top + 60), 30);
      for (final (i, (draw, label)) in [
        ((Offset p) => _hammer(canvas, p, 44), 'Çekiç ×2'),
        ((Offset p) => paintRainbow(canvas, Rect.fromCenter(center: p, width: 38, height: 38)), 'Gökkuşağı ×1'),
        ((Offset p) => _moves(canvas, p, 50), '+3 hamle ×2'),
      ].indexed) {
        final card = Rect.fromCenter(center: Offset(r.left + r.width * (i + 0.5) / 3, r.top + 138), width: 92, height: 100);
        canvas.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(16)), Paint()..color = Colors.white);
        draw(card.center - const Offset(0, 14));
        mockText(canvas, label, Offset(card.center.dx, card.bottom - 20), 12, _ink, width: 90);
      }
      mockButton(canvas, Rect.fromLTWH(r.left + 30, r.top + 198, r.width - 60, 44), 'TOPLA');
      mockText(canvas, 'Ödüller kart kart döner', Offset(r.center.dx, r.bottom - 14), 15, Colors.white, width: r.width);
  }
}

void _sheet(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));
  const phones = [
    ('1 · Bugünkü hediye hazır', 'Bugünün kutusu parlar ve zıplar; alınan günlerin üstünde ALINDI şeridi var. Dolu kavanoz sallanır, ışık saçar.'),
    ('2 · Hediye alındıktan sonra', 'Bugün de ALINDI olur, sıradaki gün "yarın" diye işaretlenir. Altta bir sonraki hediyeye kalan süre yazar.'),
  ];
  for (var i = 0; i < 2; i++) {
    final left = 40 + i * 450.0;
    mockText(canvas, phones[i].$1, Offset(left + 195, 44), 25, Colors.white, width: 420);
    mockText(canvas, phones[i].$2, Offset(left + 195, 96), 14.5, _soft, width: 410, weight: FontWeight.w600, lines: 3);
    mockPhone(canvas, Rect.fromLTWH(left, 150, 390, 844), i == 0 ? _ready : _after);
  }
  const x = 940.0;
  mockText(canvas, '3 · Açılış bir gösteri', const Offset(x + 200, 44), 25, Colors.white, width: 420);
  mockText(canvas, 'Hediye, kavanoz ya da sandık: hepsi aynı küçük gösteriyle açılır. Ses ve titreşim de var.',
      const Offset(x + 200, 96), 14.5, _soft, width: 400, weight: FontWeight.w600, lines: 3);
  for (var i = 0; i < 3; i++) {
    _opening(canvas, Rect.fromLTWH(x, 150 + i * 286.0, 400, 270), i);
  }
}

void main() {
  setUpAll(mockFonts);

  testWidgets('gifts', (tester) async {
    await mockSave(tester, const Size(940 + 400 + 40, 150 + 844 + 40), _sheet, 'hediyeler-yeni.png', scale: 2);
  });
}
