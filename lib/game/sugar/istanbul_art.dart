// İstanbul for Şeker Küpler's story: Ekşi Limon, the villain, and the
// city scenes behind each chapter's story card.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ------------------------------------------------------------ Ekşi Limon --

/// The villain: a sour lemon with a frown, an ice-blue cape and a grin.
void paintEksiLimon(Canvas canvas, Offset c, double s, {bool laugh = true}) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, s * 0.56), width: s * 0.9, height: s * 0.14),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04),
  );
  // Cape.
  final cape = Path()
    ..moveTo(-s * 0.3, -s * 0.2)
    ..quadraticBezierTo(-s * 0.7, s * 0.3, -s * 0.5, s * 0.55)
    ..lineTo(s * 0.5, s * 0.55)
    ..quadraticBezierTo(s * 0.7, s * 0.3, s * 0.3, -s * 0.2)
    ..close();
  canvas.drawPath(cape, Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.2), Offset(0, s * 0.55), const [Color(0xFF7FD8FF), Color(0xFF2E6ACF)]));
  // Lemon body with pointy ends.
  final body = Path()
    ..moveTo(-s * 0.66, -s * 0.04)
    ..cubicTo(-s * 0.56, -s * 0.16, -s * 0.46, -s * 0.42, 0, -s * 0.42)
    ..cubicTo(s * 0.46, -s * 0.42, s * 0.56, -s * 0.16, s * 0.66, -s * 0.04)
    ..cubicTo(s * 0.56, s * 0.08, s * 0.46, s * 0.4, 0, s * 0.4)
    ..cubicTo(-s * 0.46, s * 0.4, -s * 0.56, s * 0.08, -s * 0.66, -s * 0.04)
    ..close();
  canvas.drawPath(body, Paint()..shader = ui.Gradient.radial(Offset(-s * 0.15, -s * 0.2), s * 0.8, const [Color(0xFFFFF7A0), Color(0xFFFFD82A), Color(0xFFC9A400)], const [0, 0.5, 1]));
  for (final dir in [-1.0, 1.0]) {
    canvas.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.66, -s * 0.04), width: s * 0.1, height: s * 0.07), Paint()..color = const Color(0xFFB89A00));
  }
  final rnd = Random(4);
  for (var i = 0; i < 18; i++) {
    canvas.drawCircle(Offset((rnd.nextDouble() - 0.5) * s * 0.8, (rnd.nextDouble() - 0.5) * s * 0.7), s * 0.012, Paint()..color = const Color(0xFFC9A400).withValues(alpha: 0.6));
  }
  canvas.drawOval(Rect.fromLTWH(-s * 0.3, -s * 0.42, s * 0.34, s * 0.14), Paint()..color = Colors.white.withValues(alpha: 0.45));
  // Angry brows, narrow eyes, a sour grin.
  const ink = Color(0xFF3A2A00);
  for (final dir in [-1.0, 1.0]) {
    canvas.drawLine(
      Offset(dir * s * 0.28, -s * 0.2),
      Offset(dir * s * 0.06, -s * 0.12),
      Paint()
        ..strokeWidth = s * 0.05
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.16, -s * 0.04), width: s * 0.13, height: s * 0.09), Paint()..color = Colors.white);
    canvas.drawCircle(Offset(dir * s * 0.14, -s * 0.03), s * 0.035, Paint()..color = ink);
  }
  final grin = Path()
    ..moveTo(-s * 0.16, s * 0.14)
    ..quadraticBezierTo(0, s * (laugh ? 0.32 : 0.22), s * 0.18, s * 0.1)
    ..quadraticBezierTo(0, s * 0.18, -s * 0.16, s * 0.14)
    ..close();
  canvas.drawPath(grin, Paint()..color = const Color(0xFF5A2A00));
  if (laugh) canvas.drawRect(Rect.fromLTWH(-s * 0.08, s * 0.14, s * 0.16, s * 0.04), Paint()..color = Colors.white);
  // Icy crown.
  final crown = Path()
    ..moveTo(-s * 0.16, -s * 0.46)
    ..lineTo(-s * 0.2, -s * 0.66)
    ..lineTo(-s * 0.07, -s * 0.55)
    ..lineTo(0, -s * 0.72)
    ..lineTo(s * 0.07, -s * 0.55)
    ..lineTo(s * 0.2, -s * 0.66)
    ..lineTo(s * 0.16, -s * 0.46)
    ..close();
  canvas.drawPath(crown, Paint()..shader = ui.Gradient.linear(Offset(0, -s * 0.72), Offset(0, -s * 0.46), const [Color(0xFFE6F6FF), Color(0xFF7FD8FF)]));
  canvas.restore();
}

// --------------------------------------------------------------- İstanbul --

/// The İstanbul skyline as a silhouette standing on [horizon]: Galata
/// Tower, domes and minarets, the Bosphorus bridge.
void paintSkyline(Canvas canvas, double width, double horizon, double h, Color fill) {
  final paint = Paint()..color = fill;
  // Low houses all along.
  final rnd = Random(12);
  for (var x = 0.0; x < width; x += 18 + rnd.nextDouble() * 16) {
    final bh = h * (0.08 + rnd.nextDouble() * 0.12);
    canvas.drawRect(Rect.fromLTWH(x, horizon - bh, 20 + rnd.nextDouble() * 14, bh), paint);
  }
  // Galata Tower.
  final gx = width * 0.13;
  canvas.drawRect(Rect.fromLTWH(gx - h * 0.07, horizon - h * 0.62, h * 0.14, h * 0.62), paint);
  canvas.drawRect(Rect.fromLTWH(gx - h * 0.09, horizon - h * 0.66, h * 0.18, h * 0.05), paint);
  canvas.drawPath(Path()..addPolygon([Offset(gx - h * 0.085, horizon - h * 0.66), Offset(gx, horizon - h * 0.9), Offset(gx + h * 0.085, horizon - h * 0.66)], true), paint);
  // A great mosque: domes stepping up to the main one, four minarets.
  void mosque(double cx, double scale, int minarets) {
    final d = h * 0.2 * scale;
    canvas.drawRect(Rect.fromLTWH(cx - d * 1.6, horizon - d * 0.9, d * 3.2, d * 0.9), paint);
    for (final dx in [-1.0, 1.0]) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx + dx * d * 0.95, horizon - d * 0.9), radius: d * 0.55), pi, pi, true, paint);
    }
    canvas.drawRect(Rect.fromLTWH(cx - d * 0.9, horizon - d * 1.3, d * 1.8, d * 0.4), paint);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, horizon - d * 1.3), radius: d * 0.9), pi, pi, true, paint);
    canvas.drawRect(Rect.fromLTWH(cx - d * 0.04, horizon - d * 2.45, d * 0.08, d * 0.3), paint);
    for (var i = 0; i < minarets; i++) {
      final mx = cx + (i < minarets / 2 ? -1 : 1) * d * (i.isEven ? 2.0 : 2.5);
      final mh = d * (i.isEven ? 3.1 : 2.7);
      canvas.drawRect(Rect.fromLTWH(mx - d * 0.07, horizon - mh, d * 0.14, mh), paint);
      canvas.drawRect(Rect.fromLTWH(mx - d * 0.12, horizon - mh * 0.72, d * 0.24, d * 0.06), paint);
      canvas.drawPath(Path()..addPolygon([Offset(mx - d * 0.08, horizon - mh), Offset(mx, horizon - mh - d * 0.55), Offset(mx + d * 0.08, horizon - mh)], true), paint);
    }
  }

  mosque(width * 0.42, 1.0, 4);
  mosque(width * 0.66, 0.65, 2);
  // The bridge, running off the right edge.
  final b0 = width * 0.8, b1 = width * 1.25;
  for (final x in [b0 + h * 0.05, b0 + (b1 - b0) * 0.62]) {
    canvas.drawRect(Rect.fromLTWH(x - h * 0.02, horizon - h * 0.6, h * 0.04, h * 0.6), paint);
  }
  canvas.drawRect(Rect.fromLTWH(b0 - h * 0.1, horizon - h * 0.2, b1 - b0, h * 0.03), paint);
  final cable = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = fill;
  canvas.drawPath(
    Path()
      ..moveTo(b0 + h * 0.05, horizon - h * 0.6)
      ..quadraticBezierTo(b0 + (b1 - b0) * 0.33, horizon - h * 0.1, b0 + (b1 - b0) * 0.62, horizon - h * 0.6),
    cable,
  );
}

/// The Bosphorus under the skyline: a dusk-lit strip of water with
/// glints, Kız Kulesi on its rock and a ferry crossing.
void paintBosphorus(Canvas canvas, Rect water, {double ferryAt = 0.55, List<Color> colors = const [Color(0xFF6A4AA0), Color(0xFF2A1A5A)], double tower = 1}) {
  canvas.drawRect(water, Paint()..shader = ui.Gradient.linear(water.topCenter, water.bottomCenter, colors));
  final glint = Paint()..color = const Color(0xFFFFC08A).withValues(alpha: 0.5);
  final rnd = Random(3);
  for (var i = 0; i < 26; i++) {
    final x = water.left + rnd.nextDouble() * water.width, y = water.top + 6 + rnd.nextDouble() * (water.height - 12);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 12 + rnd.nextDouble() * 22, height: 2.4), const Radius.circular(2)), glint);
  }
  // Kız Kulesi, [tower] times its usual size.
  final k = Offset(water.left + water.width * 0.84, water.top + min(water.height * 0.45, 40));
  if (tower > 0) {
    canvas.save();
    canvas.translate(k.dx, k.dy);
    canvas.scale(tower);
    canvas.translate(-k.dx, -k.dy);
    canvas.drawOval(Rect.fromCenter(center: k + const Offset(0, 6), width: 64, height: 14), Paint()..color = const Color(0xFF3A2A50));
    final stone = Paint()..color = const Color(0xFFF2E6D8);
    canvas.drawRect(Rect.fromLTWH(k.dx - 22, k.dy - 16, 44, 18), stone);
    canvas.drawRect(Rect.fromLTWH(k.dx - 8, k.dy - 48, 16, 34), stone);
    canvas.drawPath(Path()..addPolygon([Offset(k.dx - 10, k.dy - 48), Offset(k.dx, k.dy - 66), Offset(k.dx + 10, k.dy - 48)], true), Paint()..color = const Color(0xFF5A8A9A));
    canvas.drawLine(
      Offset(k.dx, k.dy - 66),
      Offset(k.dx, k.dy - 76),
      Paint()
        ..strokeWidth = 1.5
        ..color = const Color(0xFF3A2A50),
    );
    canvas.drawPath(Path()..addPolygon([Offset(k.dx, k.dy - 76), Offset(k.dx + 10, k.dy - 73), Offset(k.dx, k.dy - 70)], true), Paint()..color = const Color(0xFFE2333C));
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(k.dx - 3, k.dy - 42 + i * 9, 6, 5), Paint()..color = const Color(0xFFFFD27A));
    }
    canvas.restore();
  }
  // A ferry.
  final f = Offset(water.left + water.width * ferryAt, water.top + min(water.height * 0.62, 70));
  final hull = Path()..addPolygon([f + const Offset(-56, 0), f + const Offset(56, 0), f + const Offset(46, 14), f + const Offset(-46, 14)], true);
  canvas.drawPath(hull, Paint()..color = Colors.white);
  canvas.drawRect(Rect.fromLTWH(f.dx - 52, f.dy + 4, 104, 3), Paint()..color = const Color(0xFF2A3A6A));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(f.dx - 36, f.dy - 14, 72, 14), const Radius.circular(3)), Paint()..color = Colors.white);
  for (var i = 0; i < 6; i++) {
    canvas.drawRect(Rect.fromLTWH(f.dx - 31 + i * 11, f.dy - 10, 6, 5), Paint()..color = const Color(0xFF6A8ACA));
  }
  canvas.drawRect(Rect.fromLTWH(f.dx - 4, f.dy - 28, 9, 14), Paint()..color = const Color(0xFFFFD000));
  canvas.drawRect(Rect.fromLTWH(f.dx - 4, f.dy - 28, 9, 4), Paint()..color = const Color(0xFF1A1018));
}

void paintGulls(Canvas canvas, List<Offset> at, Color color) {
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..color = color;
  for (final g in at) {
    canvas.drawPath(
      Path()
        ..moveTo(g.dx - 10, g.dy)
        ..quadraticBezierTo(g.dx - 5, g.dy - 6, g.dx, g.dy)
        ..quadraticBezierTo(g.dx + 5, g.dy - 6, g.dx + 10, g.dy),
      p,
    );
  }
}

void paintDusk(Canvas canvas, Rect r) {
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF6A3AB0), Color(0xFFE0608A), Color(0xFFFFB070)], const [0, 0.55, 1]));
  final sun = Offset(r.left + r.width * 0.3, r.bottom - 30);
  canvas.drawCircle(sun, 90, Paint()..shader = ui.Gradient.radial(sun, 90, [const Color(0xFFFFE8A0).withValues(alpha: 0.9), const Color(0xFFFFB070).withValues(alpha: 0)]));
  canvas.drawCircle(sun, 34, Paint()..color = const Color(0xFFFFF0B0));
}

// ------------------------------------------------------------ the scenes --

/// The backdrop of chapter [chapter]'s story card (0-based), filling
/// [size]; [t] (seconds) drifts the snow, gulls and lights.
void paintStoryScene(Canvas canvas, Size size, int chapter, {double t = 0}) {
  final w = size.width, h = size.height;
  final horizon = h * 0.62;
  switch (chapter % 6) {
    case 0:
      // Eminönü at dusk: the skyline, the ferries, the quay.
      paintDusk(canvas, Rect.fromLTWH(0, 0, w, horizon));
      paintSkyline(canvas, w, horizon, h * 0.36, const Color(0xFF3A1F5A));
      paintBosphorus(canvas, Rect.fromLTWH(0, horizon, w, h * 0.2), ferryAt: 0.42 + 0.04 * sin(t * 0.3));
      _quay(canvas, Rect.fromLTWH(0, h * 0.82, w, h * 0.18));
      paintGulls(canvas, [Offset(w * 0.55 + 10 * sin(t), h * 0.2), Offset(w * 0.62 + 10 * sin(t + 1), h * 0.17), Offset(w * 0.25, h * 0.26 + 4 * sin(t * 1.3))], const Color(0xFF3A1F5A));
    case 1:
      // Kız Kulesi in winter: a pale sky, snow, ice on the water.
      final sky = Rect.fromLTWH(0, 0, w, horizon);
      canvas.drawRect(sky, Paint()..shader = ui.Gradient.linear(sky.topCenter, sky.bottomCenter, const [Color(0xFF6A8ACF), Color(0xFFB8D8F2), Color(0xFFE6F2FF)], const [0, 0.6, 1]));
      paintSkyline(canvas, w, horizon, h * 0.3, const Color(0xFF5A6A9A));
      paintBosphorus(canvas, Rect.fromLTWH(0, horizon, w, h * 0.38), ferryAt: 0.3, colors: const [Color(0xFF7A9ACF), Color(0xFF3A5A9A)], tower: 1.8);
      final ice = Paint()..color = Colors.white.withValues(alpha: 0.75);
      final r = Random(2);
      for (var i = 0; i < 7; i++) {
        canvas.drawOval(Rect.fromCenter(center: Offset(r.nextDouble() * w, horizon + h * (0.24 + r.nextDouble() * 0.12)), width: 30 + r.nextDouble() * 40, height: 8), ice);
      }
      _snow(canvas, size, t);
    case 2:
      // Rumeli Hisarı: the fortress towers on the green hill, a chain across.
      final sky = Rect.fromLTWH(0, 0, w, horizon);
      canvas.drawRect(sky, Paint()..shader = ui.Gradient.linear(sky.topCenter, sky.bottomCenter, const [Color(0xFF4A8AD8), Color(0xFFA8DCF2)]));
      _hill(canvas, size, horizon, const Color(0xFF3F9A4A));
      _fortress(canvas, Offset(w * 0.5, horizon - h * 0.04), min(h * 0.22, w * 0.4));
      paintBosphorus(canvas, Rect.fromLTWH(0, horizon, w, h * 0.38), ferryAt: 0.7, colors: const [Color(0xFF3A7ACF), Color(0xFF1A3A7A)], tower: 0);
      final link = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.012
        ..color = const Color(0xFFC9CED8);
      for (var x = 0.0; x < w; x += h * 0.05) {
        final y = horizon + h * 0.06 + sin(x / w * pi) * h * 0.04;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: h * 0.05, height: h * 0.025), link);
      }
    case 3:
      // Kapalıçarşı: arched halls, hanging lamps, warm light.
      canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), const [Color(0xFF6A2A1A), Color(0xFFC0702A), Color(0xFF5A2A10)], const [0, 0.55, 1]));
      _arches(canvas, size);
      final lamp = [const Color(0xFFFF4A6A), const Color(0xFF2EA8FF), const Color(0xFF12D24E), const Color(0xFFFFD000), const Color(0xFFB04CFF)];
      for (var i = 0; i < 7; i++) {
        final x = w * (0.08 + i * 0.14);
        final y = h * (0.22 + 0.04 * (i % 2)) + 3 * sin(t * 1.5 + i);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, y - h * 0.03),
          Paint()
            ..strokeWidth = 1.5
            ..color = const Color(0xFF3A1A0A),
        );
        canvas.drawCircle(
          Offset(x, y),
          h * 0.07,
          Paint()..shader = ui.Gradient.radial(Offset(x, y), h * 0.07, [lamp[i % lamp.length].withValues(alpha: 0.5), lamp[i % lamp.length].withValues(alpha: 0)]),
        );
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: h * 0.04, height: h * 0.05), Paint()..color = lamp[i % lamp.length]);
      }
      // Boxes of goods stacked along the floor.
      final r = Random(6);
      for (var i = 0; i < 9; i++) {
        final bw = h * (0.06 + r.nextDouble() * 0.04);
        final box = Rect.fromLTWH(w * (i / 9) + 4, h * 0.86 - bw, bw * 1.2, bw);
        canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = [const Color(0xFFFF9AD8), const Color(0xFFFFC21A), const Color(0xFF8A4A2A)][i % 3]);
        canvas.drawRect(Rect.fromLTWH(box.center.dx - 2, box.top, 4, box.height), Paint()..color = Colors.white.withValues(alpha: 0.7));
      }
      canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), Paint()..color = const Color(0xFF3A1A0A));
    case 4:
      // Galata at night: the tower up close, stars and city lights.
      final sky = Rect.fromLTWH(0, 0, w, horizon);
      canvas.drawRect(sky, Paint()..shader = ui.Gradient.linear(sky.topCenter, sky.bottomCenter, const [Color(0xFF0E0A2A), Color(0xFF2A1A5A), Color(0xFF5A2A6A)], const [0, 0.6, 1]));
      final r = Random(8);
      for (var i = 0; i < 40; i++) {
        canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * horizon * 0.7), 0.8 + r.nextDouble(), Paint()..color = Colors.white.withValues(alpha: 0.4 + 0.4 * (0.5 + 0.5 * sin(t * 2 + i))));
      }
      paintSkyline(canvas, w, horizon, h * 0.26, const Color(0xFF1A0E3A));
      _galata(canvas, Offset(w * 0.5, horizon + h * 0.02), h * 0.62);
      paintBosphorus(canvas, Rect.fromLTWH(0, horizon, w, h * 0.38), ferryAt: 0.8, colors: const [Color(0xFF2A1A5A), Color(0xFF0E0A2A)], tower: 0);
      for (var i = 0; i < 30; i++) {
        canvas.drawRect(Rect.fromLTWH(r.nextDouble() * w, horizon - r.nextDouble() * h * 0.12, 3, 3), Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.8));
      }
    default:
      // Adalar: a sunny sea, an island with pines and a rainbow.
      final sky = Rect.fromLTWH(0, 0, w, horizon);
      canvas.drawRect(sky, Paint()..shader = ui.Gradient.linear(sky.topCenter, sky.bottomCenter, const [Color(0xFF3A9AF2), Color(0xFFB8E6FF)]));
      final c = Offset(w * 0.5, horizon + h * 0.05);
      const bands = [Color(0xFFFF4A52), Color(0xFFFF9A2A), Color(0xFFFFE04A), Color(0xFF4ACF5A), Color(0xFF2EA8FF), Color(0xFF8A5AE6)];
      for (var i = 0; i < bands.length; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: w * (0.62 - i * 0.035)),
          pi,
          pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.035
            ..color = bands[i].withValues(alpha: 0.75),
        );
      }
      paintBosphorus(canvas, Rect.fromLTWH(0, horizon, w, h * 0.38), ferryAt: 0.22, colors: const [Color(0xFF2EA8E6), Color(0xFF1A5AAF)], tower: 0);
      _island(canvas, Offset(w * 0.68, horizon + h * 0.02), w * 0.5);
      paintGulls(canvas, [Offset(w * 0.3 + 12 * sin(t), h * 0.22), Offset(w * 0.36 + 12 * sin(t + 1), h * 0.19)], const Color(0xFF2A3A6A));
  }
}

void _quay(Canvas canvas, Rect quay) {
  canvas.drawRect(quay, Paint()..shader = ui.Gradient.linear(quay.topCenter, quay.bottomCenter, const [Color(0xFF8A6A7A), Color(0xFF3A2440)]));
  for (var x = 0.0; x < quay.width; x += 46) {
    canvas.drawRect(Rect.fromLTWH(x, quay.top, 44, 8), Paint()..color = const Color(0xFFB08A9A));
  }
}

void _snow(Canvas canvas, Size size, double t) {
  final r = Random(11);
  final flake = Paint()..color = Colors.white.withValues(alpha: 0.85);
  for (var i = 0; i < 60; i++) {
    final speed = 14 + r.nextDouble() * 20;
    final x = (r.nextDouble() * size.width + sin(t + i) * 10) % size.width;
    final y = (r.nextDouble() * size.height + t * speed) % size.height;
    canvas.drawCircle(Offset(x, y), 1.2 + r.nextDouble() * 1.8, flake);
  }
}

void _hill(Canvas canvas, Size size, double horizon, Color color) {
  final p = Path()
    ..moveTo(0, horizon)
    ..quadraticBezierTo(size.width * 0.3, horizon - size.height * 0.16, size.width * 0.55, horizon - size.height * 0.1)
    ..quadraticBezierTo(size.width * 0.8, horizon - size.height * 0.05, size.width, horizon - size.height * 0.12)
    ..lineTo(size.width, horizon)
    ..close();
  canvas.drawPath(p, Paint()..color = color);
}

/// Rumeli Hisarı: stone walls climbing the hill between round towers.
void _fortress(Canvas canvas, Offset base, double h) {
  final stone = Paint()..shader = ui.Gradient.linear(base - Offset(0, h), base, const [Color(0xFFE6D6C0), Color(0xFFB8A48A)]);
  final shade = Paint()..color = const Color(0xFF8A7860);
  void tower(double x, double th, double tw) {
    final r = Rect.fromLTWH(base.dx + x - tw / 2, base.dy - th, tw, th);
    canvas.drawRect(r, stone);
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(r.left + i * tw / 4 + tw / 16, r.top - tw * 0.12, tw / 8, tw * 0.12), stone);
    }
    canvas.drawPath(
      Path()..addPolygon([Offset(r.left - tw * 0.06, r.top - tw * 0.12), Offset(r.center.dx, r.top - tw * 0.7), Offset(r.right + tw * 0.06, r.top - tw * 0.12)], true),
      Paint()..color = const Color(0xFF5A6A8A),
    );
    canvas.drawRect(Rect.fromLTWH(r.center.dx - tw * 0.06, r.top + th * 0.3, tw * 0.12, th * 0.16), shade);
  }

  final wall = Path()
    ..moveTo(base.dx - h * 0.9, base.dy)
    ..lineTo(base.dx - h * 0.9, base.dy - h * 0.25)
    ..lineTo(base.dx, base.dy - h * 0.5)
    ..lineTo(base.dx + h * 0.9, base.dy - h * 0.3)
    ..lineTo(base.dx + h * 0.9, base.dy)
    ..close();
  canvas.drawPath(wall, stone);
  tower(-h * 0.9, h * 0.55, h * 0.3);
  tower(h * 0.9, h * 0.6, h * 0.32);
  tower(0, h * 0.85, h * 0.36);
}

/// The bazaar's painted arches in two rows.
void _arches(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final arch = Paint()..color = const Color(0xFF3A1A0A).withValues(alpha: 0.55);
  for (var i = 0; i < 4; i++) {
    final x = w * (i / 4), aw = w / 4;
    final p = Path()
      ..moveTo(x + aw * 0.1, h * 0.86)
      ..lineTo(x + aw * 0.1, h * 0.5)
      ..arcToPoint(Offset(x + aw * 0.9, h * 0.5), radius: Radius.circular(aw * 0.4))
      ..lineTo(x + aw * 0.9, h * 0.86)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.35));
    for (var k = 0; k < 9; k++) {
      final a = pi + k * pi / 8;
      final c = Offset(x + aw * 0.5, h * 0.5);
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * aw * 0.42, aw * 0.035, Paint()..color = k.isEven ? const Color(0xFFE2333C) : Colors.white);
    }
    canvas.drawRect(Rect.fromLTWH(x, h * 0.42, aw * 0.08, h * 0.44), arch);
  }
}

/// Galata Tower up close, with lit windows.
void _galata(Canvas canvas, Offset base, double h) {
  final w = h * 0.24;
  final body = Rect.fromLTWH(base.dx - w / 2, base.dy - h * 0.72, w, h * 0.72);
  canvas.drawRect(body, Paint()..shader = ui.Gradient.linear(body.centerLeft, body.centerRight, const [Color(0xFF6A5A6A), Color(0xFFB8A8A0), Color(0xFF5A4A5A)], const [0, 0.45, 1]));
  for (var row = 0; row < 5; row++) {
    for (final dx in [-0.25, 0.0, 0.25]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx + dx * w, body.top + h * (0.08 + row * 0.12)), width: w * 0.1, height: h * 0.05), Radius.circular(w * 0.05)),
        Paint()..color = const Color(0xFFFFD27A),
      );
    }
  }
  final balcony = Rect.fromLTWH(base.dx - w * 0.62, body.top - h * 0.04, w * 1.24, h * 0.05);
  canvas.drawRect(balcony, Paint()..color = const Color(0xFF4A3A4A));
  final cone = Path()..addPolygon([Offset(balcony.left + w * 0.06, balcony.top), Offset(base.dx, balcony.top - h * 0.26), Offset(balcony.right - w * 0.06, balcony.top)], true);
  canvas.drawPath(cone, Paint()..shader = ui.Gradient.linear(Offset(balcony.left, 0), Offset(balcony.right, 0), const [Color(0xFF2A3A5A), Color(0xFF4A6A8A), Color(0xFF2A3A5A)], const [0, 0.45, 1]));
}

/// A green island with pine trees and little white houses.
void _island(Canvas canvas, Offset c, double w) {
  final land = Path()
    ..moveTo(c.dx - w / 2, c.dy)
    ..quadraticBezierTo(c.dx - w * 0.3, c.dy - w * 0.22, c.dx, c.dy - w * 0.24)
    ..quadraticBezierTo(c.dx + w * 0.3, c.dy - w * 0.22, c.dx + w / 2, c.dy)
    ..close();
  canvas.drawPath(land, Paint()..color = const Color(0xFF3F9A4A));
  for (var i = 0; i < 4; i++) {
    final hx = c.dx - w * 0.22 + i * w * 0.13;
    final hy = c.dy - w * (0.06 + (i % 2) * 0.04);
    canvas.drawRect(Rect.fromLTWH(hx, hy - w * 0.05, w * 0.08, w * 0.05), Paint()..color = Colors.white);
    canvas.drawPath(
      Path()..addPolygon([Offset(hx - w * 0.01, hy - w * 0.05), Offset(hx + w * 0.04, hy - w * 0.09), Offset(hx + w * 0.09, hy - w * 0.05)], true),
      Paint()..color = const Color(0xFFE2533C),
    );
  }
  for (final dx in [-0.3, -0.05, 0.2]) {
    final tx = c.dx + dx * w, ty = c.dy - w * (0.16 - dx.abs() * 0.12);
    canvas.drawPath(Path()..addPolygon([Offset(tx - w * 0.05, ty), Offset(tx, ty - w * 0.14), Offset(tx + w * 0.05, ty)], true), Paint()..color = const Color(0xFF1E6A2A));
  }
}
