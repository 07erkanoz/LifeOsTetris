import 'dart:math';

import 'package:flutter/material.dart';

import '../core/tetris_game.dart';
import '../game/fx/effects.dart';
import '../game/game_controller.dart';
import '../l10n/strings.dart';
import '../theme/palette.dart';
import 'widgets.dart';

/// Energy meter plus the three power slots of Süper Küpler.
class PowerBar extends StatelessWidget {
  const PowerBar({super.key, required this.c, this.slotSize = 46, this.showKeys = false});

  final GameController c;
  final double slotSize;
  final bool showKeys;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final game = c.game;
    final powers = game.powers;
    final full = powers.length >= TetrisGame.maxPowers;

    return GlassCard(
      glow: c.fx.powerPulse,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardLabel(s.energyLabel),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < TetrisGame.energyPerPower; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: i < game.energy ? null : p.track,
                            gradient: i < game.energy
                                ? LinearGradient(colors: full ? const [Color(0xFF94A3B8), Color(0xFF64748B)] : [p.accent1, p.accent2])
                                : null,
                            boxShadow: i < game.energy && !full
                                ? [
                                    BoxShadow(
                                      color: p.accent1.withValues(alpha: 0.4 + 0.4 * c.fx.energyPulse),
                                      blurRadius: 6 + 8 * c.fx.energyPulse,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (showKeys) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.powerKeysHint,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.label),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          for (var i = 0; i < TetrisGame.maxPowers; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _PowerSlot(
              type: i < powers.length ? powers[i] : null,
              size: slotSize,
              keyLabel: showKeys ? '${i + 1}' : null,
              newest: i == powers.length - 1 ? c.fx.powerPulse : 0,
              onTap: () => c.usePower(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _PowerSlot extends StatelessWidget {
  const _PowerSlot({required this.type, required this.size, required this.onTap, this.keyLabel, this.newest = 0});

  final PowerType? type;
  final double size;
  final VoidCallback onTap;
  final String? keyLabel;
  final double newest;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final type = this.type;
    if (type == null) {
      return Tooltip(
        message: s.emptySlot,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.track, width: 2),
          ),
          child: Icon(Icons.add_rounded, size: size * 0.4, color: p.track),
        ),
      );
    }
    final colors = powerColors[type]!;
    return Tooltip(
      message: '${s.powerName(type)}\n${s.powerDescription(type)}',
      textAlign: TextAlign.center,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.scale(
          scale: 1 + 0.18 * newest,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: colors.last.withValues(alpha: 0.55), blurRadius: 14 + 10 * newest, offset: const Offset(0, 4)),
                  ],
                ),
                child: CustomPaint(painter: PowerGlyphPainter(type)),
              ),
              if (keyLabel != null)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.isDark ? const Color(0xFF111630) : Colors.white,
                      border: Border.all(color: colors.last),
                    ),
                    child: Text(
                      keyLabel!,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.text),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White vector icon for each power.
class PowerGlyphPainter extends CustomPainter {
  PowerGlyphPainter(this.type);

  final PowerType type;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.translate(s * 0.25, s * 0.25);
    final u = s * 0.5;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Colors.white;
    Offset o(double x, double y) => Offset(x * u, y * u);

    switch (type) {
      case PowerType.bomb:
        canvas.drawCircle(o(0.45, 0.58), u * 0.36, fill);
        canvas.drawPath(
          Path()
            ..moveTo(0.68 * u, 0.3 * u)
            ..quadraticBezierTo(0.85 * u, 0.1 * u, 1.0 * u, 0.12 * u),
          stroke,
        );
        for (var i = 0; i < 4; i++) {
          final a = i * pi / 2 + pi / 4;
          canvas.drawLine(
            o(1.0, 0.12) + Offset(cos(a), sin(a)) * u * 0.06,
            o(1.0, 0.12) + Offset(cos(a), sin(a)) * u * 0.16,
            stroke..strokeWidth = u * 0.08,
          );
        }
      case PowerType.single:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0.22 * u, 0.22 * u, 0.56 * u, 0.56 * u), Radius.circular(u * 0.12)), fill);
      case PowerType.drill:
        canvas.drawPath(
          Path()
            ..moveTo(0.25 * u, 0.05 * u)
            ..lineTo(0.75 * u, 0.05 * u)
            ..lineTo(0.75 * u, 0.35 * u)
            ..lineTo(0.5 * u, 0.98 * u)
            ..lineTo(0.25 * u, 0.35 * u)
            ..close(),
          fill,
        );
        final groove = Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..strokeWidth = u * 0.07
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(o(0.3, 0.45), o(0.7, 0.36), groove);
        canvas.drawLine(o(0.36, 0.62), o(0.64, 0.54), groove);
      case PowerType.gravity:
        for (final x in [0.25, 0.75]) {
          canvas.drawLine(o(x, 0.05), o(x, 0.6), stroke);
          canvas.drawPath(
            Path()
              ..moveTo(x * u - u * 0.15, 0.45 * u)
              ..lineTo(x * u, 0.62 * u)
              ..lineTo(x * u + u * 0.15, 0.45 * u),
            stroke,
          );
        }
        canvas.drawLine(o(0.05, 0.9), o(0.95, 0.9), stroke);
      case PowerType.slowMotion:
        final glass = Path()
          ..moveTo(0.2 * u, 0.05 * u)
          ..lineTo(0.8 * u, 0.05 * u)
          ..lineTo(0.5 * u, 0.5 * u)
          ..lineTo(0.8 * u, 0.95 * u)
          ..lineTo(0.2 * u, 0.95 * u)
          ..lineTo(0.5 * u, 0.5 * u)
          ..close();
        canvas.drawPath(glass, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(0.33 * u, 0.85 * u)
            ..lineTo(0.67 * u, 0.85 * u)
            ..lineTo(0.5 * u, 0.62 * u)
            ..close(),
          fill,
        );
      case PowerType.ghostLine:
        final dash = Paint()
          ..color = Colors.white
          ..strokeWidth = u * 0.14
          ..strokeCap = StrokeCap.round;
        for (var x = 0.05; x < 1.0; x += 0.3) {
          canvas.drawLine(o(x, 0.62), o(x + 0.16, 0.62), dash);
        }
        // Sparkle above the line.
        final star = Path();
        const cx = 0.5, cy = 0.25, r = 0.22, ri = 0.07;
        for (var i = 0; i < 8; i++) {
          final a = i * pi / 4 - pi / 2;
          final rad = i.isEven ? r : ri;
          final pt = o(cx + cos(a) * rad, cy + sin(a) * rad);
          i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(star..close(), fill);
    }
  }

  @override
  bool shouldRepaint(covariant PowerGlyphPainter old) => old.type != type;
}
