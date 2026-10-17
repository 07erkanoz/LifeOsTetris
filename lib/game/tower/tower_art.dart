import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/rewards.dart';

/// The isometric axes on screen: u to the lower right, v to the lower left.
const Offset towerU = Offset(0.866, 0.5), towerV = Offset(-0.866, 0.5);

const Color _ink = Color(0xFF15101F);

/// The six lokum flavours: rose, pistachio, lemon, lavender, orange, mint.
const List<Color> lokumFlavors = [Color(0xFFFF8FB8), Color(0xFF9ED96B), Color(0xFFFFDA6A), Color(0xFFBFA2FF), Color(0xFFFFAA5E), Color(0xFF7FDCC4)];

/// How the floors look: lokum, or what the tower's chests open.
enum FloorLook {
  lokum(null),
  cini(Unlock.floorCini),
  marble(Unlock.floorMarble),
  glass(Unlock.floorGlass),
  gold(Unlock.floorGold);

  const FloorLook(this.unlock);

  final Unlock? unlock;

  static FloorLook parse(String? name) => values.firstWhere((l) => l.name == name, orElse: () => FloorLook.lokum);
}

Color _shade(Color c, double k) => k >= 0 ? Color.lerp(c, Colors.white, k)! : Color.lerp(c, const Color(0xFF1A0E26), -k)!;

/// The top face of a floor centred on [c] with half-sizes [a] (along u) and
/// [b] (along v).
Path isoDiamond(Offset c, double a, double b) =>
    Path()..addPolygon([c - towerU * a - towerV * b, c + towerU * a - towerV * b, c + towerU * a + towerV * b, c - towerU * a + towerV * b], true);

/// The soft shadow a floor casts on the one below it.
void paintFloorShadow(Canvas canvas, Offset c, double a, double b, double h, {double alpha = 1}) => canvas.drawPath(
  isoDiamond(c + Offset(h * 0.12, h * 1.06), a * 1.02, b * 1.02),
  Paint()
    ..color = Colors.black.withValues(alpha: 0.32 * alpha)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(1.2, h * 0.16)),
);

/// The colour of a floor of [flavor] in [look].
Color floorColor(FloorLook look, int flavor) => switch (look) {
  FloorLook.lokum => lokumFlavors[flavor % lokumFlavors.length],
  FloorLook.cini => const [Color(0xFF2F6FE4), Color(0xFF1FA2B8), Color(0xFF3B5BD9)][flavor % 3],
  FloorLook.marble => const [Color(0xFFF1EDE6), Color(0xFFE6E2DC), Color(0xFFEFE7DD)][flavor % 3],
  FloorLook.glass => const [Color(0xFF7FE3F5), Color(0xFF9CC8FF), Color(0xFFB9A8FF)][flavor % 3],
  FloorLook.gold => const [Color(0xFFFFC93C), Color(0xFFF5B526), Color(0xFFFFD46A)][flavor % 3],
};

/// A floor in isometric view: top face centred on [c], half-sizes [a] and
/// [b], [h] tall. Lit from the upper left: a glossy top, jelly sides with a
/// sheen, a bright bevel along the back edges, and what [look] adds (powdered
/// sugar and a cream layer, İznik tiles, marble veins, glass, gold).
void paintTowerFloor(Canvas canvas, Offset c, double a, double b, double h, {FloorLook look = FloorLook.lokum, int flavor = 0, int seed = 0, double alpha = 1}) {
  final color = floorColor(look, flavor);
  final back = c - towerU * a - towerV * b, right = c + towerU * a - towerV * b, front = c + towerU * a + towerV * b, left = c - towerU * a + towerV * b;
  final down = Offset(0, h);
  final small = a < 16 || h < 10;
  final glass = look == FloorLook.glass;
  final k = alpha * (glass ? 0.78 : 1);
  Path poly(List<Offset> p) => Path()..addPolygon(p, true);
  Color al(Color x, [double m = 1]) => x.withValues(alpha: x.a * k * m);

  // The sides.
  final rightFace = poly([right, front, front + down, right + down]);
  final leftFace = poly([front, left, left + down, front + down]);
  canvas.drawPath(rightFace, Paint()..shader = ui.Gradient.linear(right, right + down, [al(_shade(color, 0.22)), al(_shade(color, 0.06)), al(_shade(color, -0.14))], const [0, 0.55, 1]));
  canvas.drawPath(leftFace, Paint()..shader = ui.Gradient.linear(left, left + down, [al(_shade(color, -0.02)), al(_shade(color, -0.14)), al(_shade(color, -0.3))], const [0, 0.55, 1]));
  canvas.drawPath(rightFace, Paint()..shader = ui.Gradient.linear(right, front, [al(Colors.white, 0), al(Colors.white, look == FloorLook.gold ? 0.4 : 0.2), al(Colors.white, 0)], const [0.1, 0.4, 0.75]));
  if (!small) _sideDetail(canvas, look, right, front, left, h, seed, al);
  canvas.drawLine(front + const Offset(0, 1.5), front + down - const Offset(0, 1.5), Paint()
    ..color = al(Colors.white, 0.45)
    ..strokeWidth = small ? 0.8 : 1.4);
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = small ? 0.9 : 1.4
    ..strokeJoin = StrokeJoin.round
    ..color = al(_ink, glass ? 0.45 : 0.7);
  canvas.drawPath(rightFace, edge);
  canvas.drawPath(leftFace, edge);

  // The top.
  final top = poly([back, right, front, left]);
  canvas.drawPath(top, Paint()..shader = ui.Gradient.linear(back, front, [al(_shade(color, 0.55)), al(_shade(color, 0.24))]));
  final gloss = Offset.lerp(c, back, 0.18)!;
  canvas.drawPath(isoDiamond(gloss, a * 0.74, b * 0.74), Paint()..shader = ui.Gradient.radial(gloss, max(a, b) * 0.95, [al(Colors.white, 0.36), al(Colors.white, 0)]));
  if (!small) _topDetail(canvas, look, c, back, right, left, a, b, seed, al);
  Offset inset(Offset p) => Offset.lerp(p, c, small ? 0.06 : 0.045)!;
  canvas.drawPath(
    Path()
      ..moveTo(inset(left).dx, inset(left).dy)
      ..lineTo(inset(back).dx, inset(back).dy)
      ..lineTo(inset(right).dx, inset(right).dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = small ? 1 : 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = al(Colors.white, 0.75),
  );
  canvas.drawPath(
    Path()
      ..moveTo(inset(right).dx, inset(right).dy)
      ..lineTo(inset(front).dx, inset(front).dy)
      ..lineTo(inset(left).dx, inset(left).dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = small ? 0.8 : 1.4
      ..strokeJoin = StrokeJoin.round
      ..color = al(_shade(color, -0.2), 0.6),
  );
  canvas.drawPath(top, edge);
}

void _sideDetail(Canvas canvas, FloorLook look, Offset right, Offset front, Offset left, double h, int seed, Color Function(Color, [double]) al) {
  switch (look) {
    case FloorLook.lokum:
      // A wavy cream layer.
      Path wave(Offset p0, Offset p1) {
        const n = 14;
        final path = Path();
        for (var i = 0; i <= n; i++) {
          final p = Offset.lerp(p0, p1, i / n)! + Offset(0, h * 0.5 + sin(i / n * pi * 4 + seed) * h * 0.04);
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        for (var i = n; i >= 0; i--) {
          final p = Offset.lerp(p0, p1, i / n)! + Offset(0, h * 0.66 + sin(i / n * pi * 4 + seed + 1) * h * 0.035);
          path.lineTo(p.dx, p.dy);
        }
        return path..close();
      }

      canvas.drawPath(wave(right, front), Paint()..color = al(const Color(0xFFFFF7EC), 0.92));
      canvas.drawPath(wave(front, left), Paint()..color = al(const Color(0xFFE9DACA), 0.88));
    case FloorLook.cini:
      // A row of tiles: a white lozenge with a gold eye in each.
      for (final (p0, p1) in [(right, front), (front, left)]) {
        for (var k = 0.1; k < 0.95; k += 0.2) {
          final m = Offset.lerp(p0, p1, k)! + Offset(0, h * 0.5);
          canvas.drawPath(
            Path()..addPolygon([m - Offset(0, h * 0.3), m + Offset(h * 0.24, 0), m + Offset(0, h * 0.3), m - Offset(h * 0.24, 0)], true),
            Paint()..color = al(Colors.white, 0.92),
          );
          canvas.drawCircle(m, h * 0.08, Paint()..color = al(const Color(0xFFFFC93C)));
        }
      }
    case FloorLook.marble:
      final vein = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = al(const Color(0xFF8A8478), 0.5);
      final rnd = Random(seed);
      for (final (p0, p1) in [(right, front), (front, left)]) {
        final s = rnd.nextDouble() * 0.5;
        final a0 = Offset.lerp(p0, p1, s)! + Offset(0, h * 0.2);
        final a1 = Offset.lerp(p0, p1, s + 0.4)! + Offset(0, h * 0.8);
        canvas.drawPath(Path()
          ..moveTo(a0.dx, a0.dy)
          ..quadraticBezierTo((a0.dx + a1.dx) / 2 + h * 0.3, (a0.dy + a1.dy) / 2, a1.dx, a1.dy), vein);
      }
    case FloorLook.glass:
      final shine = Paint()
        ..color = al(Colors.white, 0.5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final a0 = Offset.lerp(right, front, 0.2)! + Offset(0, h * 0.25), a1 = Offset.lerp(right, front, 0.35)! + Offset(0, h * 0.75);
      canvas.drawLine(a0, a1, shine);
    case FloorLook.gold:
      final band = Paint()
        ..color = al(const Color(0xFFFFF3B0), 0.7)
        ..strokeWidth = h * 0.08;
      canvas.drawLine(right + Offset(0, h * 0.3), front + Offset(0, h * 0.3), band);
      canvas.drawLine(front + Offset(0, h * 0.3), left + Offset(0, h * 0.3), band);
  }
}

void _topDetail(Canvas canvas, FloorLook look, Offset c, Offset back, Offset right, Offset left, double a, double b, int seed, Color Function(Color, [double]) al) {
  final rnd = Random(seed);
  switch (look) {
    case FloorLook.lokum || FloorLook.gold || FloorLook.glass:
      // Powdered sugar with a few glinting crystals (gold dust on gold).
      final dust = look == FloorLook.gold ? const Color(0xFFFFF6C8) : Colors.white;
      for (var i = 0; i < (a * b / (look == FloorLook.lokum ? 34 : 90)).round(); i++) {
        final s = rnd.nextDouble(), t = rnd.nextDouble();
        final p = back + (right - back) * s + (left - back) * t;
        final r = 0.6 + rnd.nextDouble() * 1.3;
        if (rnd.nextDouble() < 0.12) {
          canvas.drawPath(Path()..addPolygon([p - Offset(0, r * 1.8), p + Offset(r, 0), p + Offset(0, r * 1.8), p - Offset(r, 0)], true), Paint()..color = al(dust, 0.95));
        } else {
          canvas.drawCircle(p, r, Paint()..color = al(dust, 0.45 + rnd.nextDouble() * 0.4));
        }
      }
    case FloorLook.cini:
      // A rosette in the middle.
      final r = min(a, b) * 0.32;
      for (var i = 0; i < 6; i++) {
        final ang = i * pi / 3;
        canvas.drawOval(
          Rect.fromCenter(center: c + Offset(cos(ang), sin(ang) * 0.58) * r, width: r * 0.8, height: r * 0.46),
          Paint()..color = al(i.isEven ? const Color(0xFF2F6FE4) : const Color(0xFFE0474C), 0.85),
        );
      }
      canvas.drawCircle(c, r * 0.3, Paint()..color = al(const Color(0xFFFFC93C)));
    case FloorLook.marble:
      final vein = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = al(const Color(0xFF8A8478), 0.45);
      for (var i = 0; i < 2; i++) {
        final p0 = back + (right - back) * rnd.nextDouble() + (left - back) * 0.1;
        final p1 = back + (right - back) * rnd.nextDouble() + (left - back) * 0.9;
        canvas.drawPath(Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(c.dx + (rnd.nextDouble() - 0.5) * a, c.dy, p1.dx, p1.dy), vein);
      }
  }
}

/// A short stack of three floors in [look], the top one centred on [top]:
/// the picture of a floor look.
void paintFloorStack(Canvas canvas, Offset top, FloorLook look, {double scale = 1}) {
  final a = 30 * scale, h = 14 * scale;
  for (var i = 2; i >= 0; i--) {
    final c = top + Offset(0, i * h);
    if (i < 2) paintFloorShadow(canvas, c, a, a, h);
    paintTowerFloor(canvas, c, a, a, h, look: look, flavor: i, seed: i + 3);
  }
}
