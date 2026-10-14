import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/tetromino.dart';
import '../../theme/palette.dart';
import 'block_sprites.dart';

/// Draws one of every kind of effect off screen once, right after start-up.
///
/// With the Skia renderer (Windows, Linux) a drawing operation's GPU shader
/// is compiled the first time it appears, which made the first bomb blast,
/// quad or callout hitch for a moment mid-game. Rasterising them early moves
/// that cost to the menu, where nobody notices.
class EffectsWarmUp {
  static bool _done = false;

  static void run(GamePalette palette, double dpr) {
    if (_done) return;
    _done = true;
    const cell = 24.0;
    final sprites = BlockSprites.of(cell, dpr, palette);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Block sprites: scaled, faded, rotated; gray and white flashes; aura.
    for (final (i, type) in PieceType.values.indexed) {
      sprites.draw(canvas, sprites.block(type), i * 8.0, 0, scale: 0.6, opacity: 0.5, rotation: 0.4);
    }
    sprites.draw(canvas, sprites.gray, 20, 40, rotation: 1);
    sprites.draw(canvas, sprites.white, 40, 40, opacity: 0.4, scale: 1.2);
    sprites.draw(canvas, sprites.aura(PieceType.t), 60, 40, opacity: 0.6, scale: 1.25);
    sprites.draw(canvas, sprites.ghost(PieceType.i), 80, 40);

    // Glows, sparks and dots.
    final glow = Paint()..color = const Color(0x55FFFFFF);
    final solid = Paint()..color = const Color(0xFFFDE047);
    canvas.drawCircle(const Offset(30, 90), 8, glow);
    canvas.drawCircle(const Offset(30, 90), 3, solid);
    final star = Path()
      ..moveTo(60, 80)
      ..lineTo(63, 87)
      ..lineTo(70, 90)
      ..lineTo(63, 93)
      ..lineTo(60, 100)
      ..lineTo(57, 93)
      ..lineTo(50, 90)
      ..lineTo(57, 87)
      ..close();
    canvas.drawPath(star, solid);

    // Shockwave rings, blurred shapes, additive bands and radial pulses.
    canvas.drawCircle(
      const Offset(100, 100),
      30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xAAF43F5E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10, 120, 60, 30), const Radius.circular(8)),
      Paint()
        ..color = const Color(0x80F97316)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    for (final mode in [BlendMode.plus, BlendMode.srcOver]) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 160, 200, 30),
        Paint()
          ..blendMode = mode
          ..shader = ui.Gradient.linear(
            const Offset(0, 160),
            const Offset(0, 190),
            [const Color(0x007DD3FC), const Color(0x887DD3FC), const Color(0x007DD3FC)],
            const [0, 0.5, 1],
          ),
      );
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 200, 200),
      Paint()..shader = ui.Gradient.radial(const Offset(100, 100), 140, [const Color(0x44FBBF24), const Color(0x00FBBF24)]),
    );

    // Callout text: outlined, gradient filled, glowing, faded in a layer.
    canvas.saveLayer(const Rect.fromLTWH(0, 200, 200, 60), Paint()..color = const Color(0xB3FFFFFF));
    for (final stroke in [true, false]) {
      final painter = TextPainter(
        text: TextSpan(
          text: 'DÖRTLÜ! +800',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            foreground: stroke
                ? (Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 4
                    ..color = const Color(0xE60F172A))
                : (Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 30), const [Color(0xFFFFFFFF), Color(0xFF38BDF8)])),
            shadows: stroke ? const [Shadow(color: Color(0xD938BDF8), blurRadius: 16)] : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, const Offset(4, 210));
      painter.dispose();
    }
    canvas.restore();
    canvas.save();
    canvas.rotate(pi / 7);
    canvas.drawRect(const Rect.fromLTWH(40, 40, 20, 20), solid);
    canvas.restore();

    final picture = recorder.endRecording();
    picture.toImageSync(220, 260).dispose();
    picture.dispose();
  }
}
