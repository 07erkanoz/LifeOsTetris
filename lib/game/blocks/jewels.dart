import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The jewels of Bulmaca Küpler's levels: ruby, emerald, sapphire, amber.
const List<List<Color>> jewelTones = [
  [Color(0xFFFF8A9A), Color(0xFFE0102E), Color(0xFF7A0012)],
  [Color(0xFF8AF0B0), Color(0xFF12A04A), Color(0xFF064A20)],
  [Color(0xFF9AC8FF), Color(0xFF1F5AE0), Color(0xFF0A2A7A)],
  [Color(0xFFFFE6A0), Color(0xFFF0A010), Color(0xFF8A5000)],
];

/// The main colour of jewel [kind].
Color jewelColor(int kind) => jewelTones[kind % jewelTones.length][1];

/// A cut jewel of [kind], [s] from centre to point, around [c].
void paintJewel(Canvas canvas, Offset c, double s, int kind) {
  final t = jewelTones[kind % jewelTones.length];
  final pts = [for (var i = 0; i < 6; i++) c + Offset(cos(pi / 6 + i * pi / 3), sin(pi / 6 + i * pi / 3)) * s];
  final outer = Path()..addPolygon(pts, true);
  canvas.drawPath(outer.shift(Offset(0, s * 0.12)), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawPath(outer, Paint()..shader = ui.Gradient.linear(c - Offset(s, s), c + Offset(s, s), t, const [0, 0.5, 1]));
  final inner = [for (final p in pts) Offset.lerp(c, p, 0.5)!];
  canvas.drawPath(Path()..addPolygon(inner, true), Paint()..color = Color.lerp(t[1], Colors.white, 0.25)!);
  final facet = Paint()
    ..strokeWidth = s * 0.06
    ..color = Colors.white.withValues(alpha: 0.35);
  for (var i = 0; i < 6; i++) {
    canvas.drawLine(pts[i], inner[i], facet);
  }
  canvas.drawPath(Path()..addPolygon([pts[3], pts[4], inner[4], inner[3]], true), Paint()..color = Colors.white.withValues(alpha: 0.45));
  canvas.drawPath(
    outer,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..color = Colors.white.withValues(alpha: 0.8),
  );
}

/// A dark setting block with jewel [kind] in it, filling [r].
void paintJewelBlock(Canvas canvas, Rect r, int kind) {
  final s = r.width;
  canvas.drawRRect(RRect.fromRectAndRadius(r.shift(Offset(0, s * 0.05)), Radius.circular(s * 0.2)), Paint()..color = Colors.black.withValues(alpha: 0.35));
  canvas.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(s * 0.2)),
    Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF4A3A7A), Color(0xFF2A1F4A)]),
  );
  canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(s * 0.07), Radius.circular(s * 0.16)), Paint()..color = const Color(0xFF1E1638));
  canvas.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(s * 0.2)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, s * 0.03)
      ..color = jewelColor(kind).withValues(alpha: 0.7),
  );
  paintJewel(canvas, r.center, s * 0.32, kind);
}
