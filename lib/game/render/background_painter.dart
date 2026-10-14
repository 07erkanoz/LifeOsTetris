import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/tetromino.dart';
import '../../theme/palette.dart';
import '../fx/effects.dart';
import 'block_sprites.dart';

class _Floating {
  _Floating(Random r)
      : type = PieceType.values[r.nextInt(PieceType.values.length)],
        x = r.nextDouble(),
        y = r.nextDouble(),
        speed = 0.008 + r.nextDouble() * 0.018,
        drift = (r.nextDouble() - 0.5) * 0.02,
        rotation = r.nextDouble() * pi * 2,
        spin = (r.nextDouble() - 0.5) * 0.4,
        scale = 0.6 + r.nextDouble() * 0.7;

  final PieceType type;
  final double x, y, speed, drift, rotation, spin, scale;
}

class _Star {
  _Star(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        size = 0.6 + r.nextDouble() * 1.4,
        phase = r.nextDouble() * pi * 2,
        rate = 0.6 + r.nextDouble() * 1.8;

  final double x, y, size, phase, rate;
}

/// Animated backdrop: drifting translucent tetrominoes, twinkling stars in
/// dark mode, soft colour glows and event pulses (Tetris, level up...).
class BackgroundPainter extends CustomPainter {
  BackgroundPainter({
    required this.fx,
    required this.palette,
    required this.sprites,
    required this.effectsEnabled,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final EffectsEngine fx;
  final GamePalette palette;
  final BlockSprites sprites;
  final bool effectsEnabled;

  static final List<_Floating> _floating = List.generate(14, (i) => _Floating(Random(100 + i)));
  static final List<_Star> _stars = List.generate(70, (i) => _Star(Random(500 + i)));

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, palette.background, const [0, 0.55, 1]),
    );
    final glowCenters = [Offset(size.width * 0.15, size.height * 0.12), Offset(size.width * 0.9, size.height * 0.2), Offset(size.width * 0.75, size.height * 0.92)];
    for (var i = 0; i < 3; i++) {
      final radius = max(size.width, size.height) * 0.45;
      canvas.drawCircle(
        glowCenters[i],
        radius,
        Paint()..shader = ui.Gradient.radial(glowCenters[i], radius, [palette.glows[i], palette.glows[i].withValues(alpha: 0)]),
      );
    }

    final t = fx.time;
    if (palette.isDark) {
      final star = Paint();
      for (final s in _stars) {
        final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * s.rate + s.phase));
        star.color = Colors.white.withValues(alpha: 0.5 * twinkle);
        canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size * (effectsEnabled ? twinkle : 0.7), star);
      }
    }

    if (effectsEnabled) {
      final cell = sprites.cell;
      for (final f in _floating) {
        final y = ((f.y - t * f.speed) % 1.2 + 1.2) % 1.2 - 0.1;
        final x = ((f.x + sin(t * 0.2 + f.rotation) * f.drift) % 1 + 1) % 1;
        canvas.save();
        canvas.translate(x * size.width, y * size.height);
        canvas.rotate(f.rotation + t * f.spin);
        canvas.scale(f.scale);
        for (final c in shapeOf(f.type, Rotation.spawn)) {
          sprites.draw(canvas, sprites.block(f.type), (c.x - 1.5) * cell, (c.y - 1) * cell, opacity: palette.isDark ? 0.09 : 0.11);
        }
        canvas.restore();
      }
    }

    if (fx.pulse > 0) {
      final center = Offset(size.width / 2, size.height * 0.55);
      final radius = max(size.width, size.height) * 0.75;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(center, radius, [
            fx.pulseColor.withValues(alpha: (palette.isDark ? 0.22 : 0.14) * fx.pulse),
            fx.pulseColor.withValues(alpha: 0),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter old) =>
      old.palette != palette || old.sprites != sprites || old.effectsEnabled != effectsEnabled;
}

/// Small static piece used in the hold / next cards.
class PiecePreviewPainter extends CustomPainter {
  PiecePreviewPainter({required this.type, required this.sprites, this.dimmed = false, this.pop = 0});

  final PieceType? type;
  final BlockSprites sprites;
  final bool dimmed;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    final type = this.type;
    if (type == null) return;
    final cells = shapeOf(type, Rotation.spawn);
    final cell = sprites.cell;
    final minX = cells.map((c) => c.x).reduce(min), maxX = cells.map((c) => c.x).reduce(max);
    final minY = cells.map((c) => c.y).reduce(min), maxY = cells.map((c) => c.y).reduce(max);
    final w = (maxX - minX + 1) * cell, h = (maxY - minY + 1) * cell;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(1 + 0.25 * pop);
    final image = dimmed ? sprites.gray : sprites.block(type);
    for (final c in cells) {
      sprites.draw(canvas, image, (c.x - minX) * cell - w / 2, (c.y - minY) * cell - h / 2);
    }
  }

  @override
  bool shouldRepaint(covariant PiecePreviewPainter old) =>
      old.type != type || old.sprites != sprites || old.dimmed != dimmed || old.pop != pop;
}
