import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/sugar/sugar_game.dart';
import 'sugar_art.dart';
import 'sugar_controller.dart';
import 'sugar_fx.dart';

/// Sizes of the Şeker Küpler board for a cell size.
class SugarGeometry {
  const SugarGeometry(this.cell);

  final double cell;

  /// Tray border around the cells, in cells.
  static const double rim = 0.22;

  Offset get origin => Offset(rim * cell, rim * cell);
  Size get canvas => Size((SugarGame.size + 2 * rim) * cell, (SugarGame.size + 2 * rim) * cell);

  static double fit(Size space) => max(8, min(space.width, space.height) / (SugarGame.size + 2 * rim)).floorToDouble();
}

class SugarBoardPainter extends CustomPainter {
  SugarBoardPainter({required this.c, required this.geometry, required this.dpr}) : super(repaint: c.frame);

  final SugarController c;
  final SugarGeometry geometry;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final g = c.game;
    final fx = c.fx;
    final cell = geometry.cell;
    final sprites = SugarSprites.of(cell, dpr);
    final shake = fx.shake * cell;
    canvas.save();
    canvas.translate(shake.dx, shake.dy);
    final o = geometry.origin;
    final board = o & Size(SugarGame.size * cell, SugarGame.size * cell);

    // Tray.
    final tray = RRect.fromRectAndRadius(board.inflate(cell * 0.18), Radius.circular(cell * 0.5));
    canvas.drawRRect(tray.shift(Offset(0, cell * 0.14)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
    canvas.drawRRect(tray, Paint()..color = const Color(0xFF3A1270).withValues(alpha: 0.9));
    canvas.drawRRect(
      tray,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, cell * 0.055)
        ..color = (c.hammerArmed ? const Color(0xFFFFE066) : const Color(0xFFFF9AD8)).withValues(alpha: c.hammerArmed ? 0.6 + 0.4 * sin(fx.time * 8) : 0.7),
    );
    final tile = Paint();
    for (var y = 0; y < SugarGame.size; y++) {
      for (var x = 0; x < SugarGame.size; x++) {
        final r = Rect.fromLTWH(o.dx + x * cell, o.dy + y * cell, cell, cell).deflate(cell * 0.03);
        tile.color = ((x + y).isEven ? const Color(0xFF4A1A85) : const Color(0xFF41167A)).withValues(alpha: 0.9);
        canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(cell * 0.2)), tile);
      }
    }

    // Arrows on the rim show which way each belt runs.
    for (final MapEntry(key: y, value: dir) in c.level.belts.entries) {
      final cy = o.dy + (y + 0.5) * cell;
      for (final x in [board.left - cell * 0.09, board.right + cell * 0.09]) {
        final back = x - dir * cell * 0.07;
        canvas.drawPath(
          Path()..addPolygon([Offset(x + dir * cell * 0.07, cy), Offset(back, cy - cell * 0.13), Offset(back, cy + cell * 0.13)], true),
          Paint()..color = const Color(0xFFFFC21A),
        );
      }
    }

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(board.inflate(cell * 0.12), Radius.circular(cell * 0.4)));

    // Conveyor belts run under the sweets.
    for (final MapEntry(key: y, value: dir) in c.level.belts.entries) {
      for (var x = 0; x < SugarGame.size; x++) {
        sprites.draw(canvas, sprites.belt(dir), o + Offset(x * cell, y * cell));
      }
    }

    // Selection glow under the cube.
    final sel = c.selected;
    if (sel != null) {
      final r = Rect.fromLTWH(o.dx + sel.$1 * cell, o.dy + sel.$2 * cell, cell, cell);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(cell * 0.02), Radius.circular(cell * 0.26)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35 + 0.15 * sin(fx.time * 9))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.12),
      );
    }

    // Boxes, chocolate, doors and lemon slices stay put; cakes take four
    // cells.
    for (var y = 0; y < SugarGame.size; y++) {
      for (var x = 0; x < SugarGame.size; x++) {
        final at = o + Offset(x * cell, y * cell);
        final b = g.box[y][x];
        if (b > 0) sprites.draw(canvas, sprites.box(b), at);
        if (g.choco[y][x] > 0) sprites.draw(canvas, sprites.chocolate, at);
        if (g.slice[y][x] > 0) sprites.draw(canvas, sprites.lemonSlice, at);
        if (g.door[y][x] > 0) sprites.draw(canvas, sprites.door(SugarColor.values[g.door[y][x] - 1]), at);
        final cellRect = at & Size(cell, cell);
        if (g.jam[y][x] > 0) paintJam(canvas, cellRect);
        if (g.hole[y][x] > 0) {
          paintTunnel(canvas, cellRect, top: y == 0 || g.hole[y - 1][x] == 0, bottom: y == SugarGame.size - 1 || g.hole[y + 1][x] == 0, t: fx.time * 0.8);
        }
        if (g.lantern[y][x] > 0) paintLantern(canvas, cellRect, g.lantern[y][x], glow: g.lantern[y][x] == 1 ? 0.5 + 0.3 * sin(fx.time * 5) : 0);
        if (g.gull[y][x] > 0) paintGull(canvas, cellRect, flap: max(0, sin(fx.time * 3 + x * 1.7 + y)) * 0.6);
      }
    }
    for (final (x, y) in g.cakes) {
      if (g.cake[y][x] > 0) sprites.drawCake(canvas, g.cake[y][x], o + Offset(x * cell, y * cell));
    }

    // Sweets, where their motions put them.
    final hint = c.hint;
    final hintScale = 1 + 0.07 * max(0, sin(fx.time * 7));
    final now = c.now;
    for (var y = 0; y < SugarGame.size; y++) {
      for (var x = 0; x < SugarGame.size; x++) {
        final p = g.board[y][x];
        if (p == null) continue;
        var pos = Offset(x.toDouble(), y.toDouble());
        var squash = 1.0;
        final m = c.motions[p.id];
        if (m != null) {
          if (now < m.start) {
            pos = m.from;
          } else {
            (pos, squash) = m.at(now);
          }
        }
        final at = o + pos * cell;
        var scale = 1.0;
        if (hint != null && ((x, y) == hint.$1 || (x, y) == hint.$2)) scale = hintScale;
        if (sel == (x, y)) scale = 1.08;
        final timer = p.timer;
        if (timer != null && timer <= 3) {
          // A bomb about to go off throbs red.
          canvas.drawCircle(
            at + Offset(cell / 2, cell / 2),
            cell * (0.52 + 0.06 * sin(fx.time * 10)),
            Paint()
              ..color = const Color(0xFFFF3B3B).withValues(alpha: 0.55)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.14),
          );
        }
        if (p.special != Special.none && !p.fruit) {
          final centre = at + Offset(cell / 2, cell / 2);
          final beat = 0.5 + 0.5 * sin(fx.time * 4 + x * 0.7 + y * 1.3);
          final tone = p.isPrism ? Colors.white : sugarColors[p.color]!;
          final r = cell * (0.6 + 0.08 * beat);
          canvas.drawCircle(centre, r, Paint()..shader = ui.Gradient.radial(centre, r, [tone.withValues(alpha: 0.7), tone.withValues(alpha: 0)]));
          canvas.drawCircle(centre, cell * 0.5, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.045
            ..color = Colors.white.withValues(alpha: 0.35 + 0.45 * beat));
        }
        sprites.draw(canvas, sprites.piece(p), at, scale: scale, scaleY: squash);
        if (p.chained) sprites.draw(canvas, sprites.chains, at);
        if (timer != null && p.special == Special.none) {
          paintSugarLabel(
            canvas,
            '$timer',
            at + Offset(cell / 2, cell * 0.55),
            cell * 0.42,
            Paint()..color = timer <= 3 ? const Color(0xFFFFD0D0) : Colors.white,
            outline: const Color(0xFF2E140A),
            stroke: 0.2,
          );
        }
      }
    }
    // Two specials side by side: a spark flickers between them.
    if (g.status == SugarStatus.idle) {
      for (final (a, b) in g.comboPairs) {
        if (c.motions.containsKey(g.board[a.$2][a.$1]!.id) || c.motions.containsKey(g.board[b.$2][b.$1]!.id)) continue;
        final p = o + Offset((a.$1 + 0.5) * cell, (a.$2 + 0.5) * cell), q = o + Offset((b.$1 + 0.5) * cell, (b.$2 + 0.5) * cell);
        final flicker = (fx.time * 9).floor();
        final along = q - p, normal = Offset(-along.dy, along.dx) / along.distance;
        final bolt = Path()..moveTo(p.dx + along.dx * 0.28, p.dy + along.dy * 0.28);
        for (var i = 1; i <= 4; i++) {
          final k = 0.28 + 0.44 * i / 4;
          final jag = i == 4 ? 0.0 : ((i + flicker).isEven ? 1 : -1) * cell * 0.09;
          final pt = p + along * k + normal * jag;
          bolt.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(bolt, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.14
          ..color = const Color(0xFFFFE066).withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.06));
        canvas.drawPath(bolt, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.05
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white);
      }
    }
    // Cubes popping.
    for (final gh in c.ghosts) {
      final at = o + Offset(gh.x, gh.y) * cell;
      final img = sprites.piece(gh.piece);
      if (now < gh.start) {
        sprites.draw(canvas, img, at);
        continue;
      }
      final t = ((now - gh.start) / SugarGhost.life).clamp(0.0, 1.0);
      sprites.draw(canvas, img, at, scale: 1 + 0.35 * Curves.easeOut.transform(t), opacity: 1 - t);
    }
    canvas.restore();

    // Ice over the cells, and the fog.
    for (var y = 0; y < SugarGame.size; y++) {
      for (var x = 0; x < SugarGame.size; x++) {
        final h = g.ice[y][x];
        if (h > 0) sprites.draw(canvas, sprites.ice(h, x + y), o + Offset(x * cell, y * cell));
        if (g.fog[y][x] > 0) paintFog(canvas, Rect.fromLTWH(o.dx + x * cell, o.dy + y * cell, cell, cell), drift: sin(fx.time * 0.8 + x + y * 0.6));
      }
    }

    _beams(canvas, o, cell, fx);
    _sparks(canvas, o, cell, fx);
    _dive(canvas, o, cell);
    if (fx.flash > 0) {
      canvas.drawRRect(tray, Paint()..color = Colors.white.withValues(alpha: 0.45 * fx.flash));
    }
    _floaters(canvas, o, cell, fx);
    canvas.restore();
  }

  /// Lokum diving in for a sugar rush: down from his corner, along a row
  /// with his mouth wide open, and out at the far side.
  void _dive(Canvas canvas, Offset o, double cell) {
    final start = c.diveStart;
    if (start == null || !c.diving) return;
    final t = ((c.now - start) / SugarController.diveLength).clamp(0.0, 1.0);
    final row = c.diveRow + 0.5;
    const n = SugarGame.size;
    late Offset at;
    var tilt = 0.0;
    var fade = 1.0;
    if (t < 0.2) {
      final k = Curves.easeIn.transform(t / 0.2);
      at = Offset(n - 0.2 + 0.4 * (1 - k), -1.4 + (row + 1.4) * k);
      tilt = -0.6 * k;
    } else if (t < 0.88) {
      final k = Curves.easeInOut.transform((t - 0.2) / 0.68);
      at = Offset(n - 0.4 - (n + 0.2) * k, row + 0.12 * sin(k * pi * 6));
      tilt = -0.5;
    } else {
      final k = (t - 0.88) / 0.12;
      at = Offset(-0.6 - k * 0.6, row - k * 1.2);
      tilt = -0.5 + k;
      fade = 1 - k;
    }
    final p = o + at * cell;
    // A sugary trail behind him.
    for (var i = 1; i <= 6; i++) {
      final q = p + Offset(i * cell * 0.55, sin(i + t * 20) * cell * 0.15);
      if (q.dx > o.dx + n * cell + cell) break;
      paintSparkle(canvas, q, cell * 0.16 * (1 - i / 7), const Color(0xFFFFE066), opacity: fade * (1 - i / 7));
    }
    canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: fade));
    canvas.translate(p.dx, p.dy);
    canvas.rotate(tilt);
    paintLokum(canvas, Offset.zero, cell * 1.5, pose: LokumPose.chomp, outfit: c.outfit);
    canvas.restore();
  }

  void _beams(Canvas canvas, Offset o, double cell, SugarFx fx) {
    for (final b in fx.beams) {
      if (b.delay > 0) continue;
      final t = b.t;
      final fade = 1 - Curves.easeIn.transform(t);
      final centre = o + Offset((b.x + 0.5) * cell, (b.y + 0.5) * cell);
      switch (b.kind) {
        case Special.lineH || Special.lineV:
          final horizontal = b.kind == Special.lineH && b.targets.length <= SugarGame.size;
          final cross = b.targets.length > SugarGame.size;
          for (final h in cross ? const [true, false] : [horizontal]) {
            final grow = Curves.easeOut.transform(min(1, t * 3));
            final len = SugarGame.size * cell * grow;
            final beam = h
                ? Rect.fromCenter(center: Offset(o.dx + SugarGame.size * cell / 2, centre.dy), width: len, height: cell * 0.5)
                : Rect.fromCenter(center: Offset(centre.dx, o.dy + SugarGame.size * cell / 2), width: cell * 0.5, height: len);
            canvas.drawRRect(
              RRect.fromRectAndRadius(beam.inflate(cell * 0.3), Radius.circular(cell)),
              Paint()
                ..color = b.color.withValues(alpha: 0.55 * fade)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.4),
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(beam, Radius.circular(cell)),
              Paint()
                ..shader = h
                    ? ui.Gradient.linear(
                        beam.topCenter,
                        beam.bottomCenter,
                        [Colors.white.withValues(alpha: 0.15 * fade), Colors.white.withValues(alpha: fade), Colors.white.withValues(alpha: 0.15 * fade)],
                        const [0, 0.5, 1],
                      )
                    : ui.Gradient.linear(
                        beam.centerLeft,
                        beam.centerRight,
                        [Colors.white.withValues(alpha: 0.15 * fade), Colors.white.withValues(alpha: fade), Colors.white.withValues(alpha: 0.15 * fade)],
                        const [0, 0.5, 1],
                      ),
            );
          }
        case Special.bomb:
          final reach = b.targets.length > 9 ? 2.6 : 1.6;
          final r = cell * reach * Curves.easeOut.transform(t);
          canvas.drawCircle(
            centre,
            r,
            Paint()
              ..color = const Color(0xFFFFE066).withValues(alpha: 0.5 * fade)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.3),
          );
          canvas.drawCircle(
            centre,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * 0.22 * fade
              ..color = Colors.white.withValues(alpha: fade),
          );
        case Special.prism:
          final ray = Paint()
            ..strokeWidth = cell * 0.09
            ..strokeCap = StrokeCap.round;
          for (var i = 0; i < b.targets.length; i++) {
            final (x, y) = b.targets[i];
            final end = o + Offset((x + 0.5) * cell, (y + 0.5) * cell);
            final hue = sugarColors.values.elementAt(i % sugarColors.length);
            final reach = Curves.easeOut.transform(min(1, t * 2.5));
            ray.color = Color.lerp(Colors.white, hue, 0.4)!.withValues(alpha: fade);
            canvas.drawLine(centre, Offset.lerp(centre, end, reach)!, ray);
            canvas.drawCircle(end, cell * 0.25 * fade, Paint()..color = Colors.white.withValues(alpha: 0.6 * fade));
          }
          canvas.drawCircle(
            centre,
            cell * (0.5 + t),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.6 * fade)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.35),
          );
        case Special.none:
          canvas.drawCircle(
            centre,
            cell * (0.3 + 0.6 * t),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * 0.12 * fade
              ..color = const Color(0xFFFFE066).withValues(alpha: fade),
          );
      }
    }
  }

  void _sparks(Canvas canvas, Offset o, double cell, SugarFx fx) {
    final paint = Paint();
    for (final s in fx.sparks) {
      if (s.delay > 0) continue;
      final p = o + Offset(s.x * cell, s.y * cell);
      final fade = 1 - s.t;
      switch (s.kind) {
        case 0:
          paintSparkle(canvas, p, s.size * cell, s.color, opacity: fade);
        case 1:
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(s.spin);
          final side = s.size * cell;
          paint.color = s.color.withValues(alpha: fade);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: side, height: side), Radius.circular(side * 0.3)), paint);
          paint.color = Colors.white.withValues(alpha: 0.6 * fade);
          canvas.drawCircle(Offset(-side * 0.18, -side * 0.18), side * 0.15, paint);
          canvas.restore();
        case 3:
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(s.spin * 0.6);
          final side = s.size * cell;
          paint.color = s.color.withValues(alpha: min(1, fade * 2));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: side * 1.6, height: side * 0.7 * cos(s.spin).abs() + side * 0.1),
              Radius.circular(side * 0.2),
            ),
            paint,
          );
          canvas.restore();
        default:
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(s.spin);
          final side = s.size * cell;
          paint.color = s.color.withValues(alpha: 0.9 * fade);
          canvas.drawPath(Path()..addPolygon([Offset(0, -side), Offset(side * 0.7, side * 0.5), Offset(-side * 0.6, side * 0.6)], true), paint);
          canvas.restore();
      }
    }
  }

  void _floaters(Canvas canvas, Offset o, double cell, SugarFx fx) {
    for (final f in fx.floaters) {
      if (f.delay > 0) continue;
      final t = f.t;
      final rise = f.big ? 0.0 : t * 0.8;
      final pop = f.big ? (t < 0.15 ? Curves.easeOutBack.transform(t / 0.15) : 1.0) : 1.0;
      final fade = t > 0.75 ? 1 - (t - 0.75) / 0.25 : 1.0;
      final at = o + Offset(f.x * cell, (f.y - rise) * cell);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      if (f.big) canvas.rotate(-0.08);
      canvas.scale(f.bubble ? (t < 0.2 ? Curves.easeOutBack.transform(t / 0.2) : 1.0) : pop);
      var size = f.size * cell;
      final lines = f.text.split('\n');
      if (f.big) {
        // Big callouts fit the board, a line at a time.
        final widest = lines.map((l) => sugarLabelWidth(l, size)).reduce(max);
        size *= min(1.0, SugarGame.size * cell * 0.92 / widest);
      }
      if (f.bubble) {
        canvas.drawCircle(
          Offset(0, size * 0.04),
          size * 0.95,
          Paint()
            ..shader = ui.Gradient.radial(Offset(-size * 0.2, -size * 0.25), size * 1.2, [
              const Color(0xFF8AF0FF).withValues(alpha: fade),
              const Color(0xFF2E86FF).withValues(alpha: fade),
            ]),
        );
        canvas.drawCircle(
          Offset(0, size * 0.04),
          size * 0.95,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * 0.12
            ..color = Colors.white.withValues(alpha: fade),
        );
      }
      for (var i = 0; i < lines.length; i++) {
        paintSugarLabel(
          canvas,
          lines[i],
          Offset(0, size * 1.02 * (i - (lines.length - 1) / 2)),
          size,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, -size / 2),
              Offset(0, size / 2),
              [for (final c in f.colors) c.withValues(alpha: fade)],
              [for (var i = 0; i < f.colors.length; i++) i / (f.colors.length - 1)],
            )
            ..color = Colors.white.withValues(alpha: fade),
          outline: (f.bubble ? const Color(0xFF0E4A9A) : const Color(0xFF6A0E4A)).withValues(alpha: fade),
          stroke: f.big ? 0.2 : 0.18,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SugarBoardPainter old) => old.c != c || old.geometry.cell != geometry.cell || old.dpr != dpr;
}
