import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/chain/chain_game.dart';
import '../../theme/palette.dart';
import 'chain_controller.dart';
import 'chain_fx.dart';
import 'chain_sprites.dart';

/// Sizes of the Zincir Küpler board for a given cell size.
class ChainGeometry {
  const ChainGeometry(this.cell);

  final double cell;

  /// Room left and right of the well for the danger markers.
  static const double side = 0.55;

  /// The well shows a sliver of the next row under the stack.
  static const double rows = ChainGame.height + 0.42;

  Offset get wellOrigin => Offset(side * cell, 0.16 * cell);
  Size get well => Size(ChainGame.width * cell, rows * cell);
  Size get canvas => Size((ChainGame.width + 2 * side) * cell, (rows + 0.32) * cell);

  /// The largest cell that fits [space].
  static double fit(Size space) =>
      max(8, min(space.width / (ChainGame.width + 2 * side), space.height / (rows + 0.32))).floorToDouble();
}

class ChainBoardPainter extends CustomPainter {
  /// Paints [c]'s board, or another one it runs ([game] with its [fx]: the
  /// computer's side of a match).
  ChainBoardPainter({required this.c, required this.palette, required this.geometry, required this.dpr, ChainGame? game, ChainFx? fx})
    : game = game ?? c.game,
      fx = fx ?? c.fx,
      super(repaint: c.frame);

  final ChainController c;
  final ChainGame game;
  final ChainFx fx;
  final GamePalette palette;
  final ChainGeometry geometry;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final g = game;
    final fx = this.fx;
    final cell = geometry.cell;
    final sprites = ChainSprites.of(cell, dpr, c.cubes);
    final shake = fx.shake * cell;
    canvas.save();
    canvas.translate(shake.dx, shake.dy);
    final origin = geometry.wellOrigin;
    final well = origin & geometry.well;
    final danger = g.grace > 0 ? 0.5 + 0.5 * sin(fx.time * 14) : 0.0;

    // Frame and well.
    final frame = RRect.fromRectAndRadius(well.inflate(cell * 0.12), Radius.circular(cell * 0.3));
    canvas.drawRRect(frame.shift(Offset(0, cell * 0.08)), Paint()..color = palette.frameShadow.withValues(alpha: 0.7));
    canvas.drawRRect(frame, Paint()..color = palette.frameFill);
    if (danger > 0) {
      canvas.drawRRect(frame, Paint()
        ..color = const Color(0xFFFF3B3B).withValues(alpha: 0.35 + 0.5 * danger)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.12
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.15));
    }
    final wellShape = RRect.fromRectAndRadius(well, Radius.circular(cell * 0.2));
    canvas.drawRRect(wellShape, Paint()..shader = ui.Gradient.linear(well.topCenter, well.bottomCenter, const [Color(0xFF161124), Color(0xFF0C0914)]));

    _markers(canvas, origin, cell, g, danger);

    canvas.save();
    canvas.clipRRect(wellShape);
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var y = 0; y < ChainGame.height; y++) {
      for (var x = 0; x < ChainGame.width; x++) {
        canvas.drawCircle(origin + Offset((x + 0.5) * cell, (y + 0.5 - g.rise) * cell), cell * 0.04, dot);
      }
    }

    // The next row rising in from below, dimmed.
    for (var x = 0; x < g.incoming.length; x++) {
      sprites.draw(canvas, g.incoming[x].color, origin + Offset(x * cell, (ChainGame.height - g.rise) * cell), opacity: 0.4);
    }
    canvas.drawRect(
      Rect.fromLTWH(well.left, origin.dy + (ChainGame.height - g.rise) * cell, well.width, cell * 1.5),
      Paint()..color = const Color(0xFF0C0914).withValues(alpha: 0.45),
    );

    for (final s in g.slabs) {
      final r = Rect.fromLTWH(origin.dx + s.x * cell + 2, origin.dy + (s.y + s.fall - g.rise) * cell + 3, s.width * cell - 4, cell - 6);
      paintGarbageSlab(canvas, r, flash: s.breaking ? (sin(fx.time * 30) > 0 ? 1.0 : 0.3) : 0);
    }

    final blink = (fx.time * 14).floor().isEven;
    for (var y = 0; y < ChainGame.height; y++) {
      for (var x = 0; x < ChainGame.width; x++) {
        final b = g.board[y][x];
        if (b == null || b.isGarbage) continue;
        if (b.state == BlockState.clearing && b.popped) continue;
        final dx = b.state == BlockState.swapping ? b.swapFrom * (b.timer / ChainGame.swapTime) : 0.0;
        final at = origin + Offset((x + dx) * cell, (y + b.fall - g.rise) * cell);
        if (b.state == BlockState.clearing) {
          canvas.drawRRect(
            RRect.fromRectAndRadius((at & Size(cell, cell)).deflate(cell * 0.02), Radius.circular(cell * 0.2)),
            Paint()
              ..color = Colors.white.withValues(alpha: blink ? 0.75 : 0.35)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.18),
          );
          sprites.draw(canvas, b.color, at, bright: blink, scale: 1.04);
        } else {
          sprites.draw(canvas, b.color, at);
        }
      }
    }
    canvas.restore();

    // A puzzle hint: the two cells of the swap glow.
    final hint = identical(g, c.game) ? c.hint : null;
    if (hint != null && !g.isOver) {
      final r = Rect.fromLTWH(origin.dx + hint.$1 * cell, origin.dy + (hint.$2 - g.rise) * cell, cell * 2, cell).inflate(cell * 0.08);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(cell * 0.25)),
        Paint()
          ..color = const Color(0xFFFFE066).withValues(alpha: 0.35 + 0.25 * sin(fx.time * 8))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.2),
      );
    }
    if (!g.isOver) _cursor(canvas, origin, cell, g);
    _sparks(canvas, origin, cell, fx);
    _floaters(canvas, origin, cell, fx);
    canvas.restore();
  }

  void _markers(Canvas canvas, Offset origin, double cell, ChainGame g, double danger) {
    for (var y = 0; y < ChainGame.height; y++) {
      final top = y < 3;
      final hot = top && g.danger;
      final color = hot ? Color.lerp(const Color(0xFFFF3B3B), Colors.white, danger * 0.4)! : const Color(0xFF6B2230).withValues(alpha: 0.55);
      final paint = Paint()..color = color;
      final cy = origin.dy + (y + 0.5) * cell;
      final s = cell * 0.13;
      for (final dir in [-1.0, 1.0]) {
        final x = dir < 0 ? origin.dx - cell * 0.27 : origin.dx + ChainGame.width * cell + cell * 0.27;
        final tip = Offset(x + dir * s, cy);
        canvas.drawPath(Path()..addPolygon([Offset(x - dir * s, cy - s * 0.9), tip, Offset(x - dir * s, cy + s * 0.9)], true), paint);
      }
    }
  }

  void _cursor(Canvas canvas, Offset origin, double cell, ChainGame g) {
    final r = Rect.fromLTWH(origin.dx + g.cursorX * cell - 3, origin.dy + (g.cursorY - g.rise) * cell - 3, cell * 2 + 6, cell + 6);
    final arm = cell * 0.32;
    final path = Path();
    for (final (corner, dx, dy) in [(r.topLeft, 1.0, 1.0), (r.topRight, -1.0, 1.0), (r.bottomLeft, 1.0, -1.0), (r.bottomRight, -1.0, -1.0)]) {
      path
        ..moveTo(corner.dx + dx * arm, corner.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(corner.dx, corner.dy + dy * arm);
    }
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF9EA6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.13
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.08));
    canvas.drawPath(path, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  void _sparks(Canvas canvas, Offset origin, double cell, ChainFx fx) {
    for (final s in fx.sparks) {
      final p = origin + Offset(s.x * cell, s.y * cell);
      final fade = 1 - s.t;
      if (s.shard) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(s.age * 8);
        final side = s.size * cell;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: side, height: side), Radius.circular(side * 0.25)),
          Paint()..color = s.color.withValues(alpha: fade),
        );
        canvas.restore();
      } else {
        paintSparkle(canvas, p, s.size * cell * (0.6 + 0.4 * fade), s.color, opacity: fade);
      }
    }
  }

  void _floaters(Canvas canvas, Offset origin, double cell, ChainFx fx) {
    for (final f in fx.floaters) {
      final t = f.t;
      // Pops in, holds, then drifts up and fades.
      final scale = t < 0.12 ? 0.6 + 0.4 * Curves.easeOutBack.transform(t / 0.12) : 1.0;
      final fade = t > 0.7 ? 1 - (t - 0.7) / 0.3 : 1.0;
      final size = f.size * cell * scale;
      final centre = origin + Offset(f.x * cell, (f.y - t * 0.6) * cell);
      TextPainter layout(Paint paint) => TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: FontWeight.w800, height: 1, foreground: paint),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final outline = layout(Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.16
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF15102A).withValues(alpha: fade));
      // Keep the text inside the well, even for a clear at its edge.
      final left = origin.dx + cell * 0.1, right = origin.dx + geometry.well.width - cell * 0.1;
      final half = outline.width / 2;
      final cx = right - left > outline.width ? centre.dx.clamp(left + half, right - half) : (left + right) / 2;
      final top = Offset(cx - half, centre.dy - outline.height / 2);
      final fill = layout(Paint()
        ..shader = ui.Gradient.linear(top, top + Offset(0, outline.height), [for (final c in f.colors) c.withValues(alpha: fade)]));
      outline.paint(canvas, top);
      fill.paint(canvas, top);
    }
  }

  @override
  bool shouldRepaint(ChainBoardPainter old) => old.geometry.cell != geometry.cell || old.palette != palette || old.dpr != dpr || !identical(old.game, game);
}
