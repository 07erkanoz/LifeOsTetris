// Mock-ups for stage three: the daily gift calendar, the sugar jar, the
// star chests on the map and the weekly İstanbul events.
//   flutter test tool/rewards_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): odul-gunluk.png,
// odul-kavanoz.png, odul-sandik.png, odul-etkinlik.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';

const _ink = Color(0xFF5A1F7A);
const _muted = Color(0xFF9A5AB5);

void _text(Canvas canvas, String text, Offset at, double size, Color color, {bool centre = true, double width = 400, FontWeight weight = FontWeight.w800, double height = 1.1}) {
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

void _button(Canvas canvas, Rect r, String label, {List<Color> colors = const [Color(0xFF6BF0A0), Color(0xFF1FB85A)], Color shade = const Color(0xFF0E6A32)}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.4));
  canvas.drawRRect(rr.shift(const Offset(0, 5)), Paint()..color = shade);
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 14, r.top + 5, r.width - 28, r.height * 0.26), Radius.circular(r.height)), Paint()..color = Colors.white.withValues(alpha: 0.3));
  _label(canvas, label, r.center, r.height * 0.42, colors: const [Colors.white, Colors.white]);
}

void _bubble(Canvas canvas, Rect r, String text, {double size = 16}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(16));
  canvas.drawRRect(rr.shift(const Offset(0, 3)), Paint()..color = Colors.black.withValues(alpha: 0.25));
  canvas.drawPath(Path()..addPolygon([Offset(r.left + 18, r.bottom - 2), Offset(r.left + 2, r.bottom + 14), Offset(r.left + 36, r.bottom - 2)], true), Paint()..color = Colors.white);
  canvas.drawRRect(rr, Paint()..color = Colors.white);
  _text(canvas, text, r.center, size, _ink, width: r.width - 20);
}

void _backdrop(Canvas canvas, Rect r, List<Color> sky, int seed) {
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, sky, [for (var i = 0; i < sky.length; i++) i / (sky.length - 1)]));
  final rnd = Random(seed);
  for (var i = 0; i < 14; i++) {
    final c = [const Color(0xFFFFB3E6), const Color(0xFF9FD8FF), const Color(0xFFFFE08A)][i % 3];
    canvas.drawCircle(r.topLeft + Offset(rnd.nextDouble() * r.width, rnd.nextDouble() * r.height), 20 + rnd.nextDouble() * 46, Paint()
      ..color = c.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
  }
}

// ------------------------------------------------------------- the icons --

/// The three Şeker boosters as little icons.
void _booster(Canvas canvas, Offset c, double s, String kind) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(s / 68);
  switch (kind) {
    case 'hammer':
      canvas.rotate(-0.6);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 6), width: 7, height: 34), const Radius.circular(3)), Paint()..color = const Color(0xFFB0703A));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -12), width: 32, height: 16), const Radius.circular(5)),
          Paint()..shader = ui.Gradient.linear(const Offset(0, -20), const Offset(0, -4), const [Color(0xFFDDE3EE), Color(0xFF7D879A)]));
    case 'rainbow':
      paintRainbow(canvas, Rect.fromCenter(center: Offset.zero, width: 64, height: 64));
    default:
      paintSugarLabel(canvas, '+3', Offset.zero, 28, Paint()..shader = ui.Gradient.linear(const Offset(0, -14), const Offset(0, 14), const [Color(0xFFFF7AC6), Color(0xFFE0247A)]),
          outline: Colors.white, stroke: 0.18);
  }
  canvas.restore();
}

/// A treasure chest in [tone] (bronze, silver, gold), open or shut.
void _chest(Canvas canvas, Offset c, double s, List<Color> tone, {bool open = false, bool glow = false}) {
  if (glow) {
    canvas.drawCircle(c, s * 0.9, Paint()..shader = ui.Gradient.radial(c, s * 0.9, [const Color(0xFFFFF0A0).withValues(alpha: 0.8), const Color(0xFFFFF0A0).withValues(alpha: 0)]));
  }
  final body = Rect.fromCenter(center: c + Offset(0, s * 0.12), width: s, height: s * 0.5);
  canvas.drawRRect(RRect.fromRectAndRadius(body.shift(Offset(0, s * 0.05)), Radius.circular(s * 0.08)), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(s * 0.08)), Paint()..shader = ui.Gradient.linear(body.topCenter, body.bottomCenter, const [Color(0xFFB0703A), Color(0xFF6A3A1A)]));
  if (open) {
    canvas.drawRect(Rect.fromLTWH(body.left + s * 0.06, body.top - s * 0.02, body.width - s * 0.12, s * 0.1), Paint()..color = const Color(0xFFFFE066));
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i - 2.5) * 0.35;
      canvas.drawLine(c + Offset(0, -s * 0.05), c + Offset(cos(a), sin(a)) * s * 0.75, Paint()
        ..strokeWidth = s * 0.05
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFF0A0).withValues(alpha: 0.7));
    }
  }
  final lid = open
      ? Rect.fromCenter(center: c + Offset(0, -s * 0.36), width: s, height: s * 0.2)
      : Rect.fromCenter(center: c + Offset(0, -s * 0.2), width: s, height: s * 0.3);
  canvas.drawRRect(RRect.fromRectAndCorners(lid, topLeft: Radius.circular(s * 0.3), topRight: Radius.circular(s * 0.3), bottomLeft: Radius.circular(s * 0.04), bottomRight: Radius.circular(s * 0.04)),
      Paint()..shader = ui.Gradient.linear(lid.topCenter, lid.bottomCenter, const [Color(0xFFC0803A), Color(0xFF7A441E)]));
  final band = Paint()..shader = ui.Gradient.linear(Offset(c.dx - s / 2, 0), Offset(c.dx + s / 2, 0), tone, const [0, 0.5, 1]);
  for (final dx in [-0.32, 0.32]) {
    canvas.drawRect(Rect.fromLTWH(c.dx + dx * s - s * 0.06, lid.top, s * 0.12, body.bottom - lid.top), band);
  }
  canvas.drawRect(Rect.fromLTWH(body.left, body.top - s * 0.02, body.width, s * 0.06), band);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, body.top + s * 0.1), width: s * 0.16, height: s * 0.2), Radius.circular(s * 0.04)), band);
}

const _bronze = [Color(0xFFE0A070), Color(0xFFFFD0A0), Color(0xFFB0602A)];
const _silver = [Color(0xFFB8C0D0), Color(0xFFFFFFFF), Color(0xFF8A94A8)];
const _gold = [Color(0xFFE2B33C), Color(0xFFFFF1A8), Color(0xFFB07A1E)];

/// A glass jar of sweets, [fill] 0..1 full.
void _jar(Canvas canvas, Offset c, double s, double fill, {bool shine = false}) {
  final body = RRect.fromRectAndCorners(Rect.fromCenter(center: c + Offset(0, s * 0.08), width: s * 0.8, height: s * 0.9),
      topLeft: Radius.circular(s * 0.2), topRight: Radius.circular(s * 0.2), bottomLeft: Radius.circular(s * 0.16), bottomRight: Radius.circular(s * 0.16));
  if (shine) {
    canvas.drawCircle(c, s * 0.85, Paint()..shader = ui.Gradient.radial(c, s * 0.85, [const Color(0xFFFFF0A0).withValues(alpha: 0.7), const Color(0xFFFFF0A0).withValues(alpha: 0)]));
  }
  canvas.drawRRect(body.shift(Offset(0, s * 0.03)), Paint()..color = Colors.black.withValues(alpha: 0.25));
  canvas.drawRRect(body, Paint()..color = const Color(0xFFE6F6FF).withValues(alpha: 0.35));
  canvas.save();
  canvas.clipRRect(body.deflate(s * 0.03));
  final top = body.bottom - body.height * fill;
  final rnd = Random(9);
  final colors = SugarColor.values;
  final r = s * 0.075;
  for (var y = body.bottom - r; y > top - r * 0.5; y -= r * 1.5) {
    for (var x = body.left + r; x < body.right; x += r * 1.8) {
      final jitter = Offset((rnd.nextDouble() - 0.5) * r * 0.6, (rnd.nextDouble() - 0.5) * r * 0.4);
      paintCandy(canvas, Rect.fromCenter(center: Offset(x + ((y ~/ r).isEven ? r * 0.8 : 0), y) + jitter, width: r * 2, height: r * 2), colors[rnd.nextInt(colors.length)], shadow: false);
    }
  }
  canvas.restore();
  // Glass shine and rim.
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.left + s * 0.08, body.top + s * 0.12, s * 0.08, body.height * 0.6), Radius.circular(s * 0.04)), Paint()..color = Colors.white.withValues(alpha: 0.55));
  canvas.drawRRect(body, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..color = Colors.white.withValues(alpha: 0.9));
  // Lid with a pink cloth tied on.
  final lid = Rect.fromCenter(center: Offset(c.dx, body.top - s * 0.02), width: s * 0.66, height: s * 0.14);
  canvas.drawRRect(RRect.fromRectAndRadius(lid, Radius.circular(s * 0.05)), Paint()..shader = ui.Gradient.linear(lid.topCenter, lid.bottomCenter, const [Color(0xFFFF9AD8), Color(0xFFE0247A)]));
  for (var i = 0; i < 6; i++) {
    canvas.drawCircle(Offset(lid.left + lid.width * (i + 0.5) / 6, lid.bottom), s * 0.03, Paint()..color = const Color(0xFFE0247A));
  }
  canvas.drawLine(Offset(lid.left, lid.center.dy + s * 0.02), Offset(lid.right, lid.center.dy + s * 0.02), Paint()
    ..strokeWidth = s * 0.02
    ..color = Colors.white);
}

void _progress(Canvas canvas, Rect r, double v, {List<Color> colors = const [Color(0xFFFF9AD8), Color(0xFFE0247A)]}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
  canvas.drawRRect(rr, Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.6));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, max(r.height, r.width * v), r.height), Radius.circular(r.height / 2)),
      Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomLeft, colors));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.8));
}

// --------------------------------------------------------------- screens --

/// 1. The daily gift: seven days, today's ready, Lokum hands it over.
void daily(Canvas canvas, Size size) {
  _backdrop(canvas, Offset.zero & size, const [Color(0xFF6A1FA8), Color(0xFFB0307E), Color(0xFF3A1470)], 3);
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1A0838).withValues(alpha: 0.35));
  final panel = RRect.fromRectAndRadius(Rect.fromLTWH(20, 70, size.width - 40, 740), const Radius.circular(30));
  _card(canvas, panel);
  _label(canvas, 'GÜNLÜK HEDİYE', Offset(size.width / 2, 116), 30);
  _text(canvas, 'Her gün bir hediye. Bir gün kaçırırsan kaldığın yerden devam.', Offset(size.width / 2, 156), 14, _muted, width: 330, weight: FontWeight.w700);
  const gifts = [
    ('1. gün', ['hammer'], 'ALINDI'),
    ('2. gün', ['moves'], 'ALINDI'),
    ('3. gün', ['hammer', 'hammer'], 'BUGÜN'),
    ('4. gün', ['rainbow'], ''),
    ('5. gün', ['moves', 'moves'], ''),
    ('6. gün', ['hammer', 'rainbow'], ''),
  ];
  final cw = (size.width - 72) / 3;
  for (var i = 0; i < gifts.length; i++) {
    final (day, items, state) = gifts[i];
    final x = 36 + (i % 3) * cw, y = 192.0 + (i ~/ 3) * 156;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x + 4, y, cw - 8, 142), const Radius.circular(20));
    final today = state == 'BUGÜN';
    final done = state == 'ALINDI';
    _card(canvas, r,
        colors: today ? const [Color(0xFFFFF3C8), Color(0xFFFFD36B)] : done ? const [Color(0xFFE6F9EE), Color(0xFFC9F0D8)] : const [Colors.white, Color(0xFFFFEAF6)],
        border: today ? const Color(0xFFFFB000) : Colors.white,
        width: today ? 4 : 2);
    _text(canvas, day, Offset(r.outerRect.center.dx, y + 20), 15, today ? const Color(0xFF8A4A00) : _muted, width: cw);
    for (var k = 0; k < items.length; k++) {
      final dx = items.length == 1 ? 0.0 : (k == 0 ? -20.0 : 20.0);
      _booster(canvas, Offset(r.outerRect.center.dx + dx, y + 72), 46, items[k]);
    }
    if (done) {
      canvas.drawCircle(Offset(r.outerRect.right - 20, y + 20), 13, Paint()..color = const Color(0xFF1FB85A));
      final tick = Offset(r.outerRect.right - 20, y + 20);
      canvas.drawPath(
          Path()
            ..moveTo(tick.dx - 6, tick.dy)
            ..lineTo(tick.dx - 1.5, tick.dy + 5)
            ..lineTo(tick.dx + 6, tick.dy - 5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white);
    }
    _text(canvas, state.isEmpty ? '' : state, Offset(r.outerRect.center.dx, y + 120), 14, done ? const Color(0xFF0E6A32) : const Color(0xFFE0247A), width: cw);
  }
  // Day seven: the big chest.
  final big = RRect.fromRectAndRadius(Rect.fromLTWH(40, 512, size.width - 80, 128), const Radius.circular(22));
  _card(canvas, big, colors: const [Color(0xFFFFE9F5), Color(0xFFFFC6E6)], border: const Color(0xFFFF9AD8));
  _chest(canvas, Offset(big.left + 74, big.center.dy + 6), 78, _gold);
  _text(canvas, '7. gün · Büyük sandık', Offset(big.left + 140, big.top + 26), 18, _ink, centre: false, width: 220);
  _text(canvas, '3 çekiç, 2 gökkuşağı, 2 ek hamle', Offset(big.left + 140, big.top + 56), 14, _muted, centre: false, width: 220, weight: FontWeight.w700);
  _text(canvas, '4 gün sonra', Offset(big.left + 140, big.top + 84), 14, const Color(0xFFE0247A), centre: false, width: 220);
  paintLokum(canvas, Offset(84, 712), 92, pose: LokumPose.cheer, outfit: LokumOutfit.fez);
  _bubble(canvas, Rect.fromLTWH(140, 664, 240, 48), 'Bugünkü hediyen hazır!');
  _button(canvas, Rect.fromLTWH(140, 726, 240, 58), 'AL');
  _text(canvas, 'Uygulama günün ilk açılışında gösterir', Offset(size.width / 2, size.height - 40), 15, Colors.white, width: 400);
}

/// 2. The sugar jar: every sweet popped drops in; a full jar opens.
void jar(Canvas canvas, Size size) {
  _backdrop(canvas, Offset.zero & size, const [Color(0xFFFFB6D9), Color(0xFFC9A0FF), Color(0xFF6A3AC8)], 6);
  _label(canvas, 'ŞEKER KAVANOZU', Offset(size.width / 2, 52), 30);
  _text(canvas, 'Patlattığın her şeker kavanoza düşer', Offset(size.width / 2, 92), 16, Colors.white, width: 400);
  // Filling.
  final a = RRect.fromRectAndRadius(Rect.fromLTWH(24, 124, size.width / 2 - 32, 360), const Radius.circular(24));
  _card(canvas, a);
  _jar(canvas, Offset(a.outerRect.center.dx, 260), 150, 0.7);
  _progress(canvas, Rect.fromLTWH(a.left + 18, 380, a.width - 36, 20), 0.7);
  _text(canvas, '212 / 300', Offset(a.outerRect.center.dx, 420), 20, _ink, width: 180);
  _text(canvas, 'Doluyor', Offset(a.outerRect.center.dx, 452), 15, _muted, width: 180, weight: FontWeight.w700);
  // Full: open it.
  final b = RRect.fromRectAndRadius(Rect.fromLTWH(size.width / 2 + 8, 124, size.width / 2 - 32, 360), const Radius.circular(24));
  _card(canvas, b, colors: const [Color(0xFFFFF3C8), Color(0xFFFFD36B)], border: const Color(0xFFFFB000), width: 4);
  _jar(canvas, Offset(b.outerRect.center.dx, 260), 150, 1, shine: true);
  for (var i = 0; i < 8; i++) {
    final ang = i * pi / 4;
    paintSparkle(canvas, Offset(b.outerRect.center.dx, 250) + Offset(cos(ang), sin(ang)) * 96, 7, const Color(0xFFFFE066));
  }
  _text(canvas, 'Kavanoz doldu!', Offset(b.outerRect.center.dx, 392), 20, const Color(0xFF8A4A00), width: 180);
  _button(canvas, Rect.fromLTWH(b.left + 22, 418, b.width - 44, 50), 'AÇ', colors: const [Color(0xFFFF9AD8), Color(0xFFE0247A)], shade: const Color(0xFF8A1550));
  // After a level: the sweets fly into the jar.
  final c = RRect.fromRectAndRadius(Rect.fromLTWH(24, 504, size.width - 48, 220), const Radius.circular(24));
  _card(canvas, c);
  _text(canvas, 'Seviye sonunda', Offset(c.outerRect.center.dx, c.top + 26), 17, _muted, width: 300);
  _jar(canvas, Offset(c.right - 76, c.top + 128), 104, 0.82);
  final colors = SugarColor.values;
  for (var i = 0; i < 7; i++) {
    final t = i / 6;
    final p = Offset(c.left + 60 + t * 180, c.top + 150 - sin(t * pi) * 80);
    paintCandy(canvas, Rect.fromCenter(center: p, width: 30 - i * 1.5, height: 30 - i * 1.5), colors[i % colors.length]);
  }
  _label(canvas, '+48 şeker', Offset(c.left + 110, c.top + 196), 26);
  _text(canvas, 'Dolu kavanozdan: 2 çekiç, 1 gökkuşağı, 1 ek hamle', Offset(size.width / 2, 770), 16, Colors.white, width: 400);
  _text(canvas, 'Her dolumda kavanoz biraz büyür', Offset(size.width / 2, 800), 15, const Color(0xFFFFF0B8), width: 400, weight: FontWeight.w700);
}

/// 3. Star chests on the map: milestones along a track.
void chests(Canvas canvas, Size size) {
  _backdrop(canvas, Offset.zero & size, const [Color(0xFF3A1470), Color(0xFF6A1FA8), Color(0xFF2A0B4F)], 9);
  _label(canvas, 'YILDIZ SANDIKLARI', Offset(size.width / 2, 52), 30);
  _text(canvas, 'Haritanın üstünde, yıldızların yanında', Offset(size.width / 2, 92), 16, Colors.white, width: 400);
  // The map's top bar with the track.
  final bar = RRect.fromRectAndRadius(Rect.fromLTWH(16, 120, size.width - 32, 150), const Radius.circular(24));
  _card(canvas, bar, colors: const [Color(0xFF4A1A85), Color(0xFF2A0B4F)], border: const Color(0xFFFF9AD8), width: 2);
  paintGoldStar(canvas, Offset(bar.left + 30, bar.top + 30), 12);
  _text(canvas, '24 yıldız', Offset(bar.left + 48, bar.top + 18), 18, Colors.white, centre: false, width: 160);
  _text(canvas, 'sonraki sandık: 30', Offset(bar.right - 16 - 180, bar.top + 20), 15, const Color(0xFFFFD36B), centre: false, width: 180, weight: FontWeight.w700);
  const marks = [(10, _bronze), (20, _bronze), (30, _silver), (45, _silver), (60, _gold)];
  final track = Rect.fromLTWH(bar.left + 30, bar.top + 98, bar.width - 60, 14);
  _progress(canvas, track, 24 / 60, colors: const [Color(0xFFFFE066), Color(0xFFFFB000)]);
  for (final (n, tone) in marks) {
    final x = track.left + track.width * n / 60;
    final opened = n <= 20;
    _chest(canvas, Offset(x, track.top - 14), 40, tone, open: opened, glow: n == 30);
    _text(canvas, '$n', Offset(x, track.bottom + 14), 14, opened ? const Color(0xFFB8F0C8) : Colors.white, width: 40);
  }
  // Opening one.
  final pop = RRect.fromRectAndRadius(Rect.fromLTWH(30, 300, size.width - 60, 400), const Radius.circular(30));
  _card(canvas, pop);
  _label(canvas, 'GÜMÜŞ SANDIK!', Offset(size.width / 2, 344), 28, colors: const [Colors.white, Color(0xFFD6DEEC), Color(0xFF8A94A8)]);
  _chest(canvas, Offset(size.width / 2, 470), 150, _silver, open: true, glow: true);
  final items = [('hammer', '×2'), ('rainbow', '×1'), ('moves', '×1')];
  for (var i = 0; i < items.length; i++) {
    final (k, n) = items[i];
    final x = size.width / 2 + (i - 1) * 96.0;
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 590), width: 80, height: 80), const Radius.circular(18));
    _card(canvas, r, colors: const [Colors.white, Color(0xFFFFEAF6)], width: 2);
    _booster(canvas, Offset(x, 584), 50, k);
    _text(canvas, n, Offset(x + 24, 616), 16, _ink, width: 40);
  }
  _button(canvas, Rect.fromLTWH(70, 640, size.width - 140, 50), 'TOPLA');
  _text(canvas, '10 · 20 bronz, 30 · 45 gümüş, 60 altın; sonra her 30 yıldızda bir altın', Offset(size.width / 2, 760), 15, Colors.white, width: 380, weight: FontWeight.w700);
}

/// 4. The weekly İstanbul events: a card in the home and its page.
void weekly(Canvas canvas, Size size) {
  final r0 = Offset.zero & size;
  canvas.drawRect(r0, Paint()..color = const Color(0xFF2A1A4A));
  _label(canvas, 'HAFTANIN ETKİNLİĞİ', Offset(size.width / 2, 46), 28);
  // The home card.
  final card = RRect.fromRectAndRadius(Rect.fromLTWH(18, 78, size.width - 36, 120), const Radius.circular(22));
  canvas.save();
  canvas.clipRRect(card);
  paintDusk(canvas, card.outerRect);
  paintSkyline(canvas, card.right, card.bottom, 70, const Color(0xFF3A1F5A).withValues(alpha: 0.8));
  // Shade behind the words so they read over the sunset.
  canvas.drawRect(card.outerRect, Paint()..shader = ui.Gradient.linear(card.outerRect.centerLeft, card.outerRect.centerRight, [const Color(0xFF2A0B4F).withValues(alpha: 0.75), const Color(0xFF2A0B4F).withValues(alpha: 0.1)]));
  canvas.restore();
  canvas.drawRRect(card, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white);
  _tulip(canvas, Offset(card.left + 50, card.center.dy + 4), 54);
  _text(canvas, 'Lale Festivali', Offset(card.left + 92, card.top + 20), 22, Colors.white, centre: false, width: 240);
  _text(canvas, 'Kırmızı kalpleri topla · 3 gün kaldı', Offset(card.left + 92, card.top + 52), 15, const Color(0xFFFFE3F4), centre: false, width: 260, weight: FontWeight.w700);
  _progress(canvas, Rect.fromLTWH(card.left + 92, card.top + 84, card.width - 120, 14), 0.46, colors: const [Color(0xFFFF7A8A), Color(0xFFD0102A)]);
  _text(canvas, 'Ana menüde, "Senin için" kartlarının üstünde', Offset(size.width / 2, 216), 13, const Color(0xFFC9B8E6), width: 400, weight: FontWeight.w700);
  // The event page.
  final page = RRect.fromRectAndRadius(Rect.fromLTWH(18, 240, size.width - 36, 470), const Radius.circular(26));
  _card(canvas, page);
  _tulip(canvas, Offset(size.width / 2, 300), 74);
  _label(canvas, 'LALE FESTİVALİ', Offset(size.width / 2, 362), 26, colors: const [Color(0xFFFFB0B8), Color(0xFFE2333C), Color(0xFF8A0A16)]);
  final fact = RRect.fromRectAndRadius(Rect.fromLTWH(page.left + 18, 388, page.width - 36, 88), const Radius.circular(14));
  canvas.drawRRect(fact, Paint()..color = const Color(0xFF1E0E33).withValues(alpha: 0.88));
  _text(canvas, 'LALE DEVRİ · 1718–1730', Offset(fact.left + 14, fact.top + 10), 13, const Color(0xFFFFD36B), centre: false, width: 300);
  _text(canvas, "İstanbul'da lale bahçeleri, Sadabad köşkleri ve helva sohbetleri moda oldu; tek bir lale soğanı servet değerindeydi.",
      Offset(fact.left + 14, fact.top + 30), 13.5, Colors.white, centre: false, width: fact.width - 28, weight: FontWeight.w600, height: 1.25);
  _text(canvas, 'Herhangi bir seviyede kırmızı kalp patlat', Offset(size.width / 2, 496), 15, _muted, width: 380, weight: FontWeight.w700);
  const tiers = [(100, 'hammer', true), (250, 'rainbow', false), (500, 'chest', false)];
  for (var i = 0; i < tiers.length; i++) {
    final (n, k, done) = tiers[i];
    final x = page.left + 26 + i * (page.width - 52) / 3;
    final w = (page.width - 52) / 3 - 10;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, 516, w, 110), const Radius.circular(18));
    _card(canvas, r, colors: done ? const [Color(0xFFE6F9EE), Color(0xFFC9F0D8)] : const [Colors.white, Color(0xFFFFEAF6)], width: 2);
    if (k == 'chest') {
      _chest(canvas, Offset(r.outerRect.center.dx, 560), 54, _gold);
    } else {
      _booster(canvas, Offset(r.outerRect.center.dx, 556), 46, k);
    }
    _text(canvas, done ? 'ALINDI' : '$n kalp', Offset(r.outerRect.center.dx, 606), 15, done ? const Color(0xFF0E6A32) : _ink, width: w);
  }
  _progress(canvas, Rect.fromLTWH(page.left + 26, 644, page.width - 52, 16), 0.46, colors: const [Color(0xFFFF7A8A), Color(0xFFD0102A)]);
  _text(canvas, '230 / 500 kalp · Pazar gece biter', Offset(size.width / 2, 684), 15, _ink, width: 380);
  // The rotation.
  _text(canvas, 'Her hafta başka bir İstanbul hikâyesi', Offset(size.width / 2, 742), 17, Colors.white, width: 400);
  const others = [
    ('Vapur Haftası', 'Şirket-i Hayriye, 1851', 'mavi damlalar'),
    ('Kahve Haftası', 'Tahtakale kahvehaneleri, 1554', 'turuncu girdaplar'),
    ('Simit Haftası', 'Üsküdar kadı sicili, 1593', 'sarı yıldızlar'),
  ];
  for (var i = 0; i < others.length; i++) {
    final (name, date, goal) = others[i];
    final y = 770.0 + i * 36;
    _text(canvas, name, Offset(30, y), 15, const Color(0xFFFFD36B), centre: false, width: 130);
    _text(canvas, '$date · $goal', Offset(150, y + 1), 13.5, const Color(0xFFE6D6FF), centre: false, width: 270, weight: FontWeight.w700);
  }
}

/// A red tulip, the festival's emblem.
void _tulip(Canvas canvas, Offset c, double s) {
  canvas.drawLine(c + Offset(0, s * 0.1), c + Offset(0, s * 0.5), Paint()
    ..strokeWidth = s * 0.07
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF2F8F3A));
  canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy + s * 0.46)
        ..quadraticBezierTo(c.dx + s * 0.34, c.dy + s * 0.36, c.dx + s * 0.3, c.dy + s * 0.04)
        ..quadraticBezierTo(c.dx + s * 0.1, c.dy + s * 0.26, c.dx, c.dy + s * 0.46),
      Paint()..color = const Color(0xFF3FBF4A));
  final cup = Path()
    ..moveTo(c.dx - s * 0.24, c.dy - s * 0.36)
    ..lineTo(c.dx - s * 0.12, c.dy - s * 0.2)
    ..lineTo(c.dx, c.dy - s * 0.42)
    ..lineTo(c.dx + s * 0.12, c.dy - s * 0.2)
    ..lineTo(c.dx + s * 0.24, c.dy - s * 0.36)
    ..quadraticBezierTo(c.dx + s * 0.26, c.dy + s * 0.12, c.dx, c.dy + s * 0.12)
    ..quadraticBezierTo(c.dx - s * 0.26, c.dy + s * 0.12, c.dx - s * 0.24, c.dy - s * 0.36)
    ..close();
  canvas.drawPath(cup, Paint()..shader = ui.Gradient.linear(c - Offset(s * 0.26, 0), c + Offset(s * 0.26, 0), const [Color(0xFFB0101E), Color(0xFFFF4A52), Color(0xFFC8141F)], const [0, 0.5, 1]));
}

Future<void> _save(WidgetTester tester, Size size, void Function(Canvas, Size) paint, String name) async {
  const scale = 2.5;
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
  testWidgets('daily', (tester) => _save(tester, const Size(430, 900), daily, 'odul-gunluk.png'));
  testWidgets('jar', (tester) => _save(tester, const Size(430, 840), jar, 'odul-kavanoz.png'));
  testWidgets('chests', (tester) => _save(tester, const Size(430, 800), chests, 'odul-sandik.png'));
  testWidgets('weekly', (tester) => _save(tester, const Size(430, 900), weekly, 'odul-etkinlik.png'));
}
