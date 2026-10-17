import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/tower/tower_game.dart';
import '../sugar/istanbul_art.dart' show paintGulls, paintSkyline;
import '../sugar/sugar_art.dart' show paintSparkle, paintSugarLabel;
import 'tower_art.dart';
import 'tower_controller.dart';

/// The sky at [floors] up: the Bosphorus by day, clouds, dusk, night,
/// space.
Color towerSkyAt(double floors) {
  const keys = [
    (0.0, Color(0xFFCDEBFF)),
    (40.0, Color(0xFF8CC4FF)),
    (120.0, Color(0xFF5E92F0)),
    (170.0, Color(0xFFFF9AA2)),
    (230.0, Color(0xFFB0508A)),
    (300.0, Color(0xFF3A2470)),
    (400.0, Color(0xFF141238)),
    (520.0, Color(0xFF05030F)),
  ];
  if (floors <= keys.first.$1) return keys.first.$2;
  for (var i = 1; i < keys.length; i++) {
    final (h, c) = keys[i];
    if (floors <= h) {
      final (h0, c0) = keys[i - 1];
      return Color.lerp(c0, c, (floors - h0) / (h - h0))!;
    }
  }
  return keys.last.$2;
}

/// The size of things on screen for a view [size] wide and high.
({double unit, double floor, double ground}) towerMetrics(Size size) {
  final unit = min(size.width * 0.145, size.height * 0.068);
  return (unit: unit, floor: unit * 0.46, ground: size.height * 0.84);
}

/// Draws a Kule Küpler game: sky, city, tower, the sliding floor and what
/// falls off it.
class TowerPainter extends CustomPainter {
  TowerPainter({required this.c}) : super(repaint: c.frame);

  final TowerController c;

  @override
  void paint(Canvas canvas, Size size) {
    final game = c.game;
    final m = towerMetrics(size);
    final u = m.unit, h = m.floor;
    final cam = c.camera;
    final look = c.look;
    double yOf(double level) => m.ground - (level - cam) * h;
    Offset at(double cu, double cv, double level) => Offset(size.width / 2, yOf(level)) + (towerU * cu + towerV * cv) * u;

    _sky(canvas, size, m.ground, h, cam);
    _clouds(canvas, size, m.ground, h, cam, front: false);
    canvas.save();
    if (c.shake > 0) {
      final k = c.shake * c.shake * 9;
      canvas.translate(sin(c.clock * 71) * k, cos(c.clock * 57) * k * 0.7);
    }
    _ground(canvas, size, yOf(0) + h, h);

    // The tower: only the floors on screen.
    final first = max(0, (cam - 3).floor());
    for (var i = first; i < game.floors.length; i++) {
      final f = game.floors[i];
      var level = i.toDouble();
      // The floor just dropped lands with a little drop and bounce.
      if (i == game.floors.length - 1 && i > 0 && c.landAge < 0.14) level += 1.2 * (1 - Curves.easeIn.transform(c.landAge / 0.14));
      final p = at(f.cu, f.cv, level);
      if (p.dy < -h * 4) break;
      if (i > first) paintFloorShadow(canvas, p, f.a * u, f.b * u, h, alpha: 0.8);
      paintTowerFloor(canvas, p, f.a * u, f.b * u, h, look: i == 0 ? FloorLook.marble : look, flavor: f.flavor, seed: i);
    }

    // The top floor glows after a perfect drop: gold once a streak runs.
    if (c.topGlow > 0 && game.floors.length > 1) {
      final f = game.top;
      final p = at(f.cu, f.cv, game.height.toDouble());
      final glow = c.goldGlow ? const Color(0xFFFFD34D) : Colors.white;
      canvas.drawPath(
        isoDiamond(p, f.a * u, f.b * u),
        Paint()
          ..color = glow.withValues(alpha: 0.55 * c.topGlow)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawPath(
        isoDiamond(p, f.a * u * 1.04, f.b * u * 1.04),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = glow.withValues(alpha: 0.8 * c.topGlow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Rings round a floor dropped right on.
    for (final r in c.rings) {
      final k = r.age / 0.7;
      final p = at(r.floor.cu, r.floor.cv, r.level.toDouble());
      final grow = 1.1 + 0.6 * Curves.easeOut.transform(k);
      canvas.drawPath(
        isoDiamond(p, r.floor.a * u * grow, r.floor.b * u * grow),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - k) + 1
          ..color = Colors.white.withValues(alpha: 0.9 * (1 - k)),
      );
    }

    // The sliding floor, its shadow on the top, and its trail.
    if (game.status == TowerStatus.playing) {
      final top = game.top;
      final slab = game.slab;
      final lift = 1.6 + 0.08 * sin(c.clock * 5);
      final level = game.height + lift;
      final p = at(slab.cu, slab.cv, level);
      final land = at(slab.cu, slab.cv, game.height.toDouble());
      final over = isoDiamond(land, slab.a * u, slab.b * u);
      final topPath = isoDiamond(at(top.cu, top.cv, game.height.toDouble()), top.a * u, top.b * u);
      canvas.drawPath(Path.combine(PathOperation.intersect, over, topPath), Paint()..color = Colors.white.withValues(alpha: 0.22));
      final axis = game.axis == TowerAxis.u ? towerU : towerV;
      for (var i = 3; i >= 1; i--) {
        paintTowerFloor(canvas, p - axis * (game.direction * i * u * 0.12), slab.a * u, slab.b * u, h, look: look, flavor: slab.flavor, seed: 90 + i, alpha: 0.1 * (4 - i));
      }
      paintTowerFloor(canvas, p, slab.a * u, slab.b * u, h, look: look, flavor: slab.flavor, seed: 99);
    }

    // Pieces falling off.
    for (final piece in c.pieces) {
      final f = piece.floor;
      final p = at(f.cu, f.cv, piece.level - piece.fall);
      if (p.dy > size.height + h * 4) continue;
      canvas.save();
      canvas.translate(p.dx, p.dy + h / 2);
      canvas.rotate(piece.angle * piece.spin * 0.6);
      paintTowerFloor(canvas, Offset(0, -h / 2), f.a * u, f.b * u, h, look: look, flavor: f.flavor, seed: 50, alpha: (1 - piece.age / 2.2).clamp(0.0, 1.0));
      canvas.restore();
    }

    // Sparks: crumbs, stars, confetti, puffs of sugar.
    for (final s in c.sparks) {
      final k = s.age / s.life;
      final p = at(s.cu, s.cv, s.level) + Offset(s.dx, s.dy);
      final alpha = (1 - k).clamp(0.0, 1.0);
      switch (s.kind) {
        case SparkKind.star:
          paintSparkle(canvas, p, s.size * (1.2 - k * 0.6), s.color, opacity: alpha);
        case SparkKind.puff:
          canvas.drawCircle(p, s.size * (1 + k * 1.4), Paint()..color = s.color.withValues(alpha: 0.45 * alpha));
        case SparkKind.crumb || SparkKind.confetti:
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(s.spin * s.age);
          final w = s.kind == SparkKind.confetti ? s.size * (0.4 + 0.6 * cos(s.age * 9).abs()) : s.size;
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: s.kind == SparkKind.confetti ? s.size * 0.6 : s.size), Paint()..color = s.color.withValues(alpha: alpha));
          canvas.restore();
      }
    }
    canvas.restore();

    _clouds(canvas, size, m.ground, h, cam, front: true);

    // Words over the tower.
    for (final l in c.labels) {
      final k = l.age / 1.1;
      final milestone = l.kind == TowerLabelKind.milestone;
      final p = Offset(size.width / 2, yOf(l.level + (milestone ? 4.6 : 2.4)) - 30 * Curves.easeOut.transform(k));
      final scale = 1 + 0.25 * (1 - Curves.easeOutBack.transform(min(1, k * 3)));
      final s = c.strings;
      final text = switch (l.kind) {
        TowerLabelKind.perfect => l.value >= 2 ? '${s.towerPerfect} ×${l.value}' : s.towerPerfect,
        TowerLabelKind.grew => s.towerGrew,
        TowerLabelKind.milestone => s.towerFloorShout(l.value),
      };
      final alpha = (1 - max(0, k - 0.6) / 0.4).clamp(0.0, 1.0);
      final colors = l.kind == TowerLabelKind.grew ? const [Color(0xFFB8FFD0), Color(0xFF22C55E)] : const [Color(0xFFFFF6B0), Color(0xFFFF8A10)];
      paintSugarLabel(
        canvas,
        text,
        p + (l.kind == TowerLabelKind.grew ? Offset(0, h * 1.3) : Offset.zero),
        h * (l.kind == TowerLabelKind.grew ? 0.8 : (milestone ? 1.5 : 1.05)) * scale,
        Paint()..shader = ui.Gradient.linear(p - Offset(0, h * 0.6), p + Offset(0, h * 0.6), [colors[0].withValues(alpha: alpha), colors[1].withValues(alpha: alpha)]),
        outline: const Color(0xFF3A0F2A).withValues(alpha: alpha),
        stroke: 0.2,
      );
      if (c.effects && l.kind == TowerLabelKind.perfect && k < 0.5) {
        paintSparkle(canvas, p + Offset(-u * 1.3, h * 0.4), h * 0.5 * (1 - k), const Color(0xFFFFE066));
        paintSparkle(canvas, p + Offset(u * 1.2, h * 0.8), h * 0.4 * (1 - k), const Color(0xFFFF9AD8));
      }
    }

    if (c.flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..shader = ui.Gradient.radial(size.center(Offset.zero), size.longestSide * 0.7, [c.flashColor.withValues(alpha: 0.05 * c.flash), c.flashColor.withValues(alpha: 0.5 * c.flash)]),
      );
    }
  }

  /// The sky over the view, from the height at its foot to the height at its
  /// top; stars, the moon and a ringed planet come out higher up.
  void _sky(Canvas canvas, Size size, double ground, double h, double cam) {
    double levelAt(double y) => cam + (ground - y) / h;
    final topLevel = levelAt(0), bottomLevel = levelAt(size.height);
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [towerSkyAt(topLevel), towerSkyAt((topLevel + bottomLevel) / 2), towerSkyAt(bottomLevel)], const [0, 0.5, 1]),
    );
    final night = ((topLevel - 250) / 120).clamp(0.0, 1.0);
    if (night > 0) {
      final rnd = Random(7);
      final drift = (cam * h * 0.04) % size.height;
      for (var i = 0; i < 70; i++) {
        final p = Offset(rnd.nextDouble() * size.width, (rnd.nextDouble() * size.height + drift) % size.height);
        canvas.drawCircle(p, 0.6 + rnd.nextDouble() * 1.3, Paint()..color = Colors.white.withValues(alpha: night * (0.3 + 0.6 * rnd.nextDouble())));
      }
    }
    final moon = ((topLevel - 300) / 60).clamp(0.0, 1.0) * (1 - ((topLevel - 560) / 60).clamp(0.0, 1.0));
    if (moon > 0) {
      final c0 = Offset(size.width * 0.2, size.height * 0.2);
      canvas.drawCircle(c0, 22, Paint()..color = const Color(0xFFFFF4D0).withValues(alpha: moon));
      canvas.drawCircle(c0 + const Offset(9, -6), 19, Paint()..color = towerSkyAt(topLevel).withValues(alpha: moon));
    }
    final space = ((topLevel - 500) / 80).clamp(0.0, 1.0);
    if (space > 0) {
      final c0 = Offset(size.width * 0.78, size.height * 0.16);
      canvas.drawCircle(c0, 26, Paint()..shader = ui.Gradient.linear(c0 - const Offset(24, 24), c0 + const Offset(24, 24), [const Color(0xFFFFB0E0).withValues(alpha: space), const Color(0xFF7A3AB0).withValues(alpha: space)]));
      canvas.drawOval(
        Rect.fromCenter(center: c0, width: 82, height: 18),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFFFE0F4).withValues(alpha: 0.8 * space),
      );
    }
  }

  /// Clouds at their own heights, drifting slower than the tower; a few pass
  /// in front of it.
  void _clouds(Canvas canvas, Size size, double ground, double h, double cam, {required bool front}) {
    final rnd = Random(21);
    for (var i = 0; i < 40; i++) {
      final level = 30 + i * 7.0 + rnd.nextDouble() * 5;
      final x = rnd.nextDouble();
      final w = 90 + rnd.nextDouble() * 110;
      final inFront = i % 4 == 0;
      if (inFront != front) continue;
      final y = ground + (cam - level) * h * (inFront ? 1.1 : 0.7);
      if (y < -60 || y > size.height + 60) continue;
      // Clouds in front keep clear of the floor count up top.
      if (inFront && y < size.height * 0.3) continue;
      final drift = (x * size.width + c.clock * (inFront ? 14 : 6)) % (size.width + w) - w / 2;
      final fade = level > 260 ? (1 - (level - 260) / 40).clamp(0.0, 1.0) : 1.0;
      if (fade <= 0) continue;
      _cloud(canvas, Offset(drift, y), w, (inFront ? 0.55 : 0.8) * fade);
    }
    if (!front && cam < 160 && cam > 10) {
      final y = ground + (cam - 60) * h * 0.7;
      final x = (c.clock * 22) % (size.width + 80) - 40;
      paintGulls(canvas, [Offset(x, y), Offset(x + 18, y - 8)], const Color(0xFF3A4A7A));
    }
  }

  void _cloud(Canvas canvas, Offset c0, double w, double alpha) {
    final p = Paint()..color = const Color(0xFFFFF4FA).withValues(alpha: alpha);
    canvas.drawOval(Rect.fromCenter(center: c0, width: w, height: w * 0.28), p);
    canvas.drawCircle(c0 + Offset(-w * 0.15, -w * 0.1), w * 0.17, p);
    canvas.drawCircle(c0 + Offset(w * 0.1, -w * 0.13), w * 0.21, p);
  }

  /// İstanbul and the Bosphorus at the foot of the tower.
  void _ground(Canvas canvas, Size size, double y, double h) {
    if (y - 160 > size.height) return;
    paintSkyline(canvas, size.width, y, 220, const Color(0xFF7A8AC0));
    final water = Rect.fromLTWH(0, y, size.width, max(0, size.height - y) + 4);
    canvas.drawRect(water, Paint()..shader = ui.Gradient.linear(water.topCenter, water.bottomCenter, const [Color(0xFF5A7AC8), Color(0xFF2A3A7A)]));
    final glint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final rnd = Random(3);
    for (var i = 0; i < 18; i++) {
      final gx = rnd.nextDouble() * size.width, gy = y + 8 + rnd.nextDouble() * 60;
      canvas.drawLine(Offset(gx, gy), Offset(gx + 10 + rnd.nextDouble() * 14, gy), glint..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(TowerPainter old) => old.c != c;
}
