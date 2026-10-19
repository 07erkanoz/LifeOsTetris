import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'istanbul_art.dart' show paintEksiLimon;
import 'sugar_art.dart';

// Scenes from Turkish custom around Lokum: the coffee he is served with,
// the bayram sweet bowl, the fortune in the cup, the rose bush of
// Hıdırellez, the elder's hand kissed at the bayram, and the Karagöz
// screen.

Paint _lin(Offset a, Offset b, List<Color> cs) => Paint()..shader = ui.Gradient.linear(a, b, cs, [for (var i = 0; i < cs.length; i++) i / (cs.length - 1)]);
Paint _line(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..color = c;

const _iznikBlue = Color(0xFF2A5AC0);
const _iznikRed = Color(0xFFE2333C);

/// A little flower of the İznik border.
void _flower(Canvas canvas, Offset p, double r, Color c) {
  for (var i = 0; i < 5; i++) {
    final a = i * pi * 2 / 5 - pi / 2;
    canvas.drawCircle(p + Offset(cos(a), sin(a)) * r * 0.6, r * 0.45, Paint()..color = c);
  }
  canvas.drawCircle(p, r * 0.35, Paint()..color = const Color(0xFFFFE27A));
}

/// A white saucer with an İznik rim, [w] wide, centred on [c].
void paintSaucer(Canvas canvas, Offset c, double w) {
  final r = Rect.fromCenter(center: c, width: w, height: w * 0.24);
  canvas.drawOval(r.shift(Offset(0, w * 0.03)), Paint()..color = const Color(0xFF8A90B8));
  canvas.drawOval(r, _lin(r.topCenter, r.bottomCenter, const [Colors.white, Color(0xFFE6E8F4)]));
  canvas.drawOval(r.deflate(w * 0.05), _line(_iznikBlue, w * 0.016));
  for (var k = 0; k < 12; k++) {
    final a = k * pi * 2 / 12;
    canvas.drawCircle(c + Offset(cos(a) * w * 0.46, sin(a) * w * 0.1), w * 0.014, Paint()..color = k.isEven ? _iznikRed : _iznikBlue);
  }
}

/// A Turkish coffee cup with its foam and a curl of steam, [h] tall, its
/// bottom at [bottom].
void paintCoffeeCup(Canvas canvas, Offset bottom, double h, {bool steam = true}) {
  final w = h * 1.1;
  final top = bottom.dy - h;
  final cup = Path()
    ..moveTo(bottom.dx - w / 2, top)
    ..quadraticBezierTo(bottom.dx - w * 0.47, bottom.dy - h * 0.1, bottom.dx, bottom.dy)
    ..quadraticBezierTo(bottom.dx + w * 0.47, bottom.dy - h * 0.1, bottom.dx + w / 2, top)
    ..close();
  canvas.drawArc(Rect.fromCircle(center: Offset(bottom.dx + w / 2, top + h * 0.38), radius: h * 0.22), -pi / 2, pi, false, _line(const Color(0xFFE6E8F4), h * 0.09));
  canvas.drawPath(cup, _lin(Offset(bottom.dx - w / 2, 0), Offset(bottom.dx + w / 2, 0), const [Color(0xFFDCE0F0), Colors.white, Color(0xFFD0D6EA)]));
  canvas.save();
  canvas.clipPath(cup);
  canvas.drawRect(Rect.fromLTRB(bottom.dx - w, top + h * 0.3, bottom.dx + w, top + h * 0.52), Paint()..color = _iznikBlue);
  for (var k = 0; k < 6; k++) {
    _flower(canvas, Offset(bottom.dx - w * 0.4 + k * w * 0.16, top + h * 0.41), h * 0.06, _iznikRed);
  }
  canvas.restore();
  canvas.drawOval(Rect.fromCenter(center: Offset(bottom.dx, top), width: w, height: h * 0.24), Paint()..color = const Color(0xFF3A1E0C));
  canvas.drawOval(Rect.fromCenter(center: Offset(bottom.dx, top), width: w * 0.78, height: h * 0.15), Paint()..color = const Color(0xFFB07A4A));
  if (steam) {
    for (final dx in [-0.15, 0.1]) {
      final x = bottom.dx + dx * w;
      canvas.drawPath(
          Path()
            ..moveTo(x, top - h * 0.15)
            ..cubicTo(x - h * 0.15, top - h * 0.35, x + h * 0.15, top - h * 0.5, x, top - h * 0.75),
          _line(Colors.white.withValues(alpha: 0.5), h * 0.05));
    }
  }
}

/// The coffee cup turned up after the fortune: grounds inside showing a
/// road, a bird and three stars. Fills [r].
void paintFortuneCup(Canvas canvas, Rect r) {
  final w = r.width;
  paintSaucer(canvas, Offset(r.center.dx, r.bottom - w * 0.12), w);
  final cc = Offset(r.center.dx - w * 0.04, r.bottom - w * 0.42);
  final cw = w * 0.62;
  final cup = Path()
    ..moveTo(cc.dx - cw / 2, cc.dy - cw * 0.16)
    ..quadraticBezierTo(cc.dx - cw * 0.47, cc.dy + cw * 0.38, cc.dx, cc.dy + cw * 0.44)
    ..quadraticBezierTo(cc.dx + cw * 0.47, cc.dy + cw * 0.38, cc.dx + cw / 2, cc.dy - cw * 0.16)
    ..close();
  canvas.drawArc(Rect.fromCircle(center: cc + Offset(cw * 0.48, cw * 0.04), radius: cw * 0.14), -pi / 2, pi, false, _line(const Color(0xFFE6E8F4), cw * 0.055));
  canvas.drawPath(cup, _lin(Offset(cc.dx - cw / 2, 0), Offset(cc.dx + cw / 2, 0), const [Color(0xFFD6DCF0), Colors.white, Color(0xFFCCD2EA)]));
  canvas.save();
  canvas.clipPath(cup);
  canvas.drawRect(Rect.fromLTRB(cc.dx - cw, cc.dy + cw * 0.06, cc.dx + cw, cc.dy + cw * 0.17), Paint()..color = _iznikBlue);
  for (var k = 0; k < 7; k++) {
    _flower(canvas, Offset(cc.dx - cw * 0.4 + k * cw * 0.13, cc.dy + cw * 0.115), cw * 0.03, _iznikRed);
  }
  canvas.restore();
  final mouth = Rect.fromCenter(center: cc - Offset(0, cw * 0.16), width: cw, height: cw * 0.45);
  canvas.drawOval(mouth, Paint()..color = const Color(0xFFF6EEE4));
  canvas.save();
  canvas.clipPath(Path()..addOval(mouth.deflate(cw * 0.03)));
  canvas.drawOval(mouth, Paint()..color = const Color(0xFF4A2810));
  final rnd = Random(2);
  for (var k = 0; k < 30; k++) {
    canvas.drawCircle(mouth.center + Offset((rnd.nextDouble() - 0.5) * cw, (rnd.nextDouble() - 0.5) * cw * 0.4), cw * (0.015 + rnd.nextDouble() * 0.035), Paint()..color = const Color(0xFF7A4A24));
  }
  final cream = const Color(0xFFF6EEE4);
  canvas.drawPath(
      Path()
        ..moveTo(mouth.left + cw * 0.13, mouth.bottom - cw * 0.1)
        ..cubicTo(mouth.left + cw * 0.32, mouth.center.dy, mouth.right - cw * 0.45, mouth.bottom - cw * 0.05, mouth.right - cw * 0.18, mouth.top + cw * 0.11),
      _line(cream, cw * 0.05));
  for (var k = 0; k < 3; k++) {
    paintSparkle(canvas, Offset(mouth.left + cw * (0.27 + k * 0.145), mouth.top + cw * (0.13 - (k == 1 ? 0.04 : 0))), cw * 0.055, const Color(0xFFFFE27A));
  }
  canvas.drawPath(
      Path()
        ..moveTo(mouth.right - cw * 0.35, mouth.center.dy + cw * 0.06)
        ..quadraticBezierTo(mouth.right - cw * 0.3, mouth.center.dy, mouth.right - cw * 0.25, mouth.center.dy + cw * 0.06)
        ..quadraticBezierTo(mouth.right - cw * 0.2, mouth.center.dy, mouth.right - cw * 0.15, mouth.center.dy + cw * 0.06),
      _line(cream, cw * 0.028));
  canvas.restore();
  canvas.drawOval(mouth, _line(_iznikBlue, cw * 0.024));
}

/// The crystal bayram sweet bowl, behind Lokum: its back and the glass
/// floor. [c] is the centre of its rim, [w] its width.
void paintSweetBowlBack(Canvas canvas, Offset c, double w) {
  canvas.drawRect(Rect.fromCenter(center: c + Offset(0, w * 0.45), width: w * 0.11, height: w * 0.09), Paint()..color = const Color(0xFFBFE6FF).withValues(alpha: 0.6));
  canvas.drawOval(Rect.fromCenter(center: c + Offset(0, w * 0.5), width: w * 0.5, height: w * 0.09), Paint()..color = const Color(0xFFBFE6FF).withValues(alpha: 0.7));
  canvas.drawOval(Rect.fromCenter(center: c, width: w, height: w * 0.18), Paint()..color = const Color(0xFF6A9ACC).withValues(alpha: 0.5));
}

/// The bowl's front glass and the wrapped sweets in it, over Lokum.
void paintSweetBowlFront(Canvas canvas, Offset c, double w) {
  final bowl = Path()
    ..moveTo(c.dx - w / 2, c.dy)
    ..cubicTo(c.dx - w * 0.48, c.dy + w * 0.31, c.dx - w * 0.27, c.dy + w * 0.41, c.dx, c.dy + w * 0.41)
    ..cubicTo(c.dx + w * 0.27, c.dy + w * 0.41, c.dx + w * 0.48, c.dy + w * 0.31, c.dx + w / 2, c.dy)
    ..close();
  canvas.drawPath(bowl, _lin(c, c + Offset(0, w * 0.41), [const Color(0xFFBFE6FF).withValues(alpha: 0.55), const Color(0xFF8AC0F0).withValues(alpha: 0.75)]));
  for (var k = -3; k <= 3; k++) {
    canvas.drawLine(Offset(c.dx + k * w * 0.125, c.dy + w * 0.03), Offset(c.dx + k * w * 0.09, c.dy + w * (0.37 - k.abs() * 0.027)), _line(Colors.white.withValues(alpha: 0.35), w * 0.009));
  }
  void sweet(Offset p, Color col, double turn) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(turn);
    final k = w / 224;
    for (final dir in [-1.0, 1.0]) {
      canvas.drawPath(Path()..addPolygon([Offset(dir * 10 * k, 0), Offset(dir * 22 * k, -8 * k), Offset(dir * 22 * k, 8 * k)], true), Paint()..color = Color.lerp(col, Colors.white, 0.3)!);
    }
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 26 * k, height: 18 * k), Paint()..color = col);
    canvas.drawLine(Offset(-6 * k, -7 * k), Offset(-2 * k, 7 * k), _line(Colors.white.withValues(alpha: 0.8), 2.5 * k));
    canvas.drawLine(Offset(3 * k, -7 * k), Offset(7 * k, 7 * k), _line(Colors.white.withValues(alpha: 0.8), 2.5 * k));
    canvas.restore();
  }

  sweet(c + Offset(-w * 0.32, w * 0.1), _iznikRed, 0.3);
  sweet(c + Offset(w * 0.31, w * 0.12), const Color(0xFF3FAF4A), -0.4);
  sweet(c + Offset(-w * 0.15, w * 0.24), const Color(0xFFFFC21A), 0.1);
  sweet(c + Offset(w * 0.15, w * 0.25), const Color(0xFF8A4AD8), -0.2);
  canvas.drawOval(Rect.fromCenter(center: c, width: w, height: w * 0.18), _line(Colors.white.withValues(alpha: 0.8), w * 0.013));
}

/// Şeker Bayramı: Lokum kissing the hand of an elder, a white lokum in a
/// yazma and glasses, with harçlık in the air. Fills [r].
void paintBayramScene(Canvas canvas, Rect r) {
  final es = r.height * 0.5;
  final ec = Offset(r.right - es * 0.75, r.bottom - es * 0.58);
  paintLokum(canvas, ec, es, tone: const Color(0xFFF4E2E8), outfit: LokumOutfit.yazma, pose: LokumPose.happy);
  for (final dir in [-1.0, 1.0]) {
    canvas.drawCircle(ec + Offset(dir * 0.17 * es, -0.03 * es), 0.12 * es, _line(const Color(0xFFB07A1E), es * 0.02));
  }
  canvas.drawLine(ec + Offset(-0.05 * es, -0.05 * es), ec + Offset(0.05 * es, -0.05 * es), _line(const Color(0xFFB07A1E), es * 0.02));
  final ls = es * 0.8;
  final lc = Offset(r.left + ls * 0.8, r.bottom - ls * 0.62);
  canvas.save();
  canvas.translate(lc.dx, lc.dy + 0.5 * ls);
  canvas.rotate(0.22);
  canvas.translate(-lc.dx, -lc.dy - 0.5 * ls);
  paintLokum(canvas, lc, ls, pose: LokumPose.sleepy);
  canvas.restore();
  // Harçlık in a little envelope.
  final env = Rect.fromCenter(center: Offset(r.center.dx, r.top + r.height * 0.18), width: es * 0.46, height: es * 0.3);
  canvas.save();
  canvas.translate(env.center.dx, env.center.dy);
  canvas.rotate(-0.12);
  canvas.translate(-env.center.dx, -env.center.dy);
  canvas.drawRRect(RRect.fromRectAndRadius(env, Radius.circular(es * 0.03)), Paint()..color = const Color(0xFFFFF0F6));
  canvas.drawPath(Path()..addPolygon([env.topLeft, env.center + Offset(0, es * 0.04), env.topRight], false), _line(_iznikRed, es * 0.016));
  canvas.drawCircle(env.center + Offset(0, es * 0.04), es * 0.045, Paint()..color = _iznikRed);
  canvas.restore();
  for (var k = 0; k < 5; k++) {
    paintSparkle(canvas, env.center + Offset(cos(k * 1.3) * es * 0.4, sin(k * 1.3) * es * 0.22), es * (0.035 + k % 2 * 0.02), const Color(0xFFFFE27A));
  }
}

/// Hıdırellez: a rose bush hung with wishes under a new moon, Lokum
/// tying one on. Fills [r].
void paintHidirellezScene(Canvas canvas, Rect r) {
  final h = r.height;
  canvas.drawCircle(Offset(r.left + h * 0.14, r.top + h * 0.16), h * 0.06, Paint()..color = const Color(0xFFFFF4C8));
  canvas.drawCircle(Offset(r.left + h * 0.165, r.top + h * 0.14), h * 0.052, Paint()..color = const Color(0xFF1C1652));
  final tc = Offset(r.right - h * 0.42, r.top + h * 0.42);
  canvas.drawLine(tc + Offset(0, h * 0.5), tc, _line(const Color(0xFF6A4018), h * 0.035));
  for (final (dx, dy, rad) in const [(0.0, -0.04, 0.2), (-0.15, 0.03, 0.14), (0.15, 0.02, 0.15), (0.0, -0.2, 0.13)]) {
    canvas.drawCircle(tc + Offset(dx * h, dy * h), rad * h, Paint()..color = const Color(0xFF2E7D4A));
  }
  final rnd = Random(11);
  for (var k = 0; k < 9; k++) {
    final p = tc + Offset((rnd.nextDouble() - 0.5) * h * 0.4, (-0.24 + rnd.nextDouble() * 0.32) * h);
    canvas.drawCircle(p, h * 0.024, Paint()..color = const Color(0xFFE8335A));
    canvas.drawCircle(p, h * 0.01, Paint()..color = const Color(0xFFFF8AA8));
  }
  const ribbons = [Color(0xFFFFD82A), Color(0xFF5EC8FF), Colors.white, _iznikRed];
  for (var k = 0; k < 4; k++) {
    final p = tc + Offset((-0.2 + k * 0.13) * h, (0.12 + (k.isOdd ? -0.05 : 0)) * h);
    canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(p.dx + h * 0.024, p.dy + h * 0.07, p.dx - h * 0.008, p.dy + h * 0.13),
        _line(ribbons[k], h * 0.02));
  }
  final s = h * 0.46;
  paintLokum(canvas, Offset(r.left + s * 0.75, r.bottom - s * 0.58), s, pose: LokumPose.cheer);
}

/// The Karagöz screen: a lit curtain in a wooden frame, with Lokum and
/// Ekşi Limon cut from coloured leather and held up on their rods. Fills
/// [r]; [laugh] gives Limon his grin.
void paintKaragozScreen(Canvas canvas, Rect r, {bool laugh = true}) {
  canvas.drawRect(r, Paint()..color = const Color(0xFF8A4A1A));
  final screen = r.deflate(r.shortestSide * 0.04);
  canvas.drawRect(screen, Paint()..shader = ui.Gradient.radial(screen.center, screen.longestSide * 0.7, const [Color(0xFFFFF4D6), Color(0xFFF2C878), Color(0xFFC08030)], const [0, 0.6, 1]));
  canvas.save();
  canvas.clipRect(screen);
  // Coloured leather, warmed by the lamp behind the curtain.
  canvas.saveLayer(
    screen,
    Paint()
      ..colorFilter = const ColorFilter.matrix([
        0.55, 0.45, 0.1, 0, 10, //
        0.3, 0.55, 0.1, 0, 0, //
        0.15, 0.3, 0.3, 0, 0, //
        0, 0, 0, 0.88, 0,
      ]),
  );
  final s = screen.height * 0.42;
  final lc = Offset(screen.left + screen.width * 0.27, screen.bottom - s * 0.62);
  final kc = Offset(screen.right - screen.width * 0.27, screen.bottom - s * 0.62);
  paintLokum(canvas, lc, s, pose: LokumPose.cheer);
  paintEksiLimon(canvas, kc, s * 0.92, laugh: laugh);
  canvas.restore();
  for (final x in [lc.dx, kc.dx]) {
    canvas.drawLine(Offset(x + s * 0.1, screen.bottom - s * 0.4), Offset(x + s * 0.3, screen.bottom), _line(const Color(0xFF3A1E0C).withValues(alpha: 0.6), s * 0.03));
  }
  canvas.restore();
}
