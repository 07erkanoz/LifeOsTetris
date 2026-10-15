import 'dart:math';

import 'package:flutter/material.dart';

import '../core/tetris_game.dart';
import '../game/fx/effects.dart';
import '../game/game_controller.dart';
import '../l10n/strings.dart';
import '../theme/palette.dart';
import 'game_icons.dart';
import 'widgets.dart';

/// Energy meter plus all six powers of Süper Küpler, each with how many the
/// player holds. Powers at zero stay visible (dimmed) so players learn what
/// exists; gravity dims while nothing would fall.
class PowerBar extends StatelessWidget {
  const PowerBar({super.key, required this.c, this.vertical = false});

  final GameController c;

  /// Desktop side panel: a 3×2 grid with names and key hints.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final game = c.game;
    final energy = game.energy;
    final pulse = c.fx.energyPulse;

    final bar = Row(
      children: [
        for (var i = 0; i < TetrisGame.energyPerPower; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: i < energy ? null : p.track,
                gradient: i < energy ? const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFFA855F7), Color(0xFFF472B6)]) : null,
                border: Border.all(color: i < energy ? Colors.white.withValues(alpha: 0.55) : p.glassBorder),
                boxShadow: i < energy
                    ? [
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.45 + 0.45 * pulse),
                          blurRadius: 8 + 14 * pulse,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Text(
          '$energy/${TetrisGame.energyPerPower}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: p.text),
        ),
      ],
    );

    Widget tile(int i) {
      final type = PowerType.values[i];
      return _PowerTile(
        type: type,
        count: game.powerCount(type),
        usable: game.canUsePower(type),
        size: vertical ? 46 : 36,
        keyLabel: vertical ? '${i + 1}' : null,
        showName: vertical,
        pop: c.fx.lastPower == type ? c.fx.powerPulse : 0,
        onTap: () => c.usePower(type),
      );
    }

    final header = Row(
      children: [
        CardLabel(s.energyLabel),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            s.energyHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.label),
          ),
        ),
      ],
    );

    if (!vertical) {
      // Phones: one slim row so the board keeps its size. The energy meter
      // is a ring that fills a third per cleared line.
      return GlassCard(
        glow: max(c.fx.powerPulse, pulse * 0.5),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: [
            Tooltip(
              message: '${s.energyLabel}: ${s.energyHint}',
              child: SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: _EnergyRingPainter(energy: energy, pulse: pulse, track: p.track, palette: p),
                  child: Center(
                    child: Text(
                      '$energy/${TetrisGame.energyPerPower}',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: p.text),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            for (var i = 0; i < PowerType.values.length; i++) Expanded(child: Center(child: tile(i))),
          ],
        ),
      );
    }

    return GlassCard(
      glow: max(c.fx.powerPulse, pulse * 0.5),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 8),
          bar,
          SizedBox(height: vertical ? 14 : 10),
          if (vertical)
            for (var row = 0; row < 2; row++) ...[
              if (row > 0) const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [for (var i = row * 3; i < row * 3 + 3; i++) Expanded(child: tile(i))],
              ),
            ]
          else
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for (var i = 0; i < PowerType.values.length; i++) tile(i)]),
        ],
      ),
    );
  }
}

class _PowerTile extends StatelessWidget {
  const _PowerTile({
    required this.type,
    required this.count,
    required this.usable,
    required this.size,
    required this.onTap,
    this.keyLabel,
    this.showName = false,
    this.pop = 0,
  });

  final PowerType type;
  final int count;
  final bool usable;
  final double size;
  final VoidCallback onTap;
  final String? keyLabel;
  final bool showName;

  /// 0..1 while this power was just earned.
  final double pop;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final colors = powerColors[type]!;
    final owned = count > 0;
    final active = owned && usable;
    final circle = CustomPaint(
      size: Size.square(size),
      painter: _PowerKeyPainter(
        type: type,
        color: owned
            ? (p.flat ? blockColors[_powerTone[type]]! : Color.lerp(colors.first, colors.last, 0.55)!)
            : (p.flat ? p.track : (p.isDark ? const Color(0xFF2B3152) : const Color(0xFFD9DEEA))),
        glyphColor: owned ? Colors.white : p.icon.withValues(alpha: p.flat ? 0.4 : 0.55),
        ink: p.flat ? p.ink : null,
        dark: p.isDark,
        glow: active ? 0.35 + 0.65 * pop : 0,
      ),
    );
    final hint = !owned ? s.powerNone : (!usable && type == PowerType.gravity ? s.gravityNothing : null);
    return Tooltip(
      message: '${s.powerName(type)}\n${s.powerDescription(type)}${hint == null ? '' : '\n$hint'}',
      textAlign: TextAlign.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: owned && !usable ? 0.5 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 1 + 0.3 * pop,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    circle,
                    if (owned)
                      Positioned(
                        right: -7,
                        bottom: -3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 0 : 10),
                            color: p.flat ? p.glass : (p.isDark ? const Color(0xFF111630) : Colors.white),
                            border: Border.all(color: p.flat ? p.ink : colors.last, width: p.flat ? 2 : 1.5),
                          ),
                          child: Text(
                            '×$count',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: p.text),
                          ),
                        ),
                      ),
                    if (keyLabel != null)
                      Positioned(
                        left: -4,
                        bottom: -4,
                        child: Container(
                          width: 17,
                          height: 17,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.isDark ? const Color(0xFF111630) : Colors.white,
                            border: Border.all(color: p.glassBorder),
                          ),
                          child: Text(
                            keyLabel!,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.muted),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showName) ...[
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    s.powerShortName(type),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: owned ? p.text : p.label),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Block colour each power borrows in the flat skins, so the bar uses the
/// same palette as the board.
const Map<PowerType, PieceType> _powerTone = {
  PowerType.bomb: PieceType.z,
  PowerType.single: PieceType.mono,
  PowerType.drill: PieceType.o,
  PowerType.gravity: PieceType.s,
  PowerType.slowMotion: PieceType.i,
  PowerType.ghostLine: PieceType.t,
};

/// A power drawn as a jelly keycap in its colours with its glyph on top.
class _PowerKeyPainter extends CustomPainter {
  _PowerKeyPainter({required this.type, required this.color, required this.glyphColor, required this.dark, this.glow = 0, this.ink});

  final PowerType type;
  final Color color;
  final Color glyphColor;
  final bool dark;
  final double glow;

  /// Outline colour of the flat skins (null for glass).
  final Color? ink;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintKeycap(canvas, rect, color, pressed: false, dark: dark, glow: glow);
    if (activeSkin == GameSkin.pixel) {
      final face = keycapFace(rect, pressed: false);
      final g = min(face.width, face.height) * 0.56;
      final at = Offset(face.center.dx - g / 2, face.center.dy - g / 2);
      canvas.save();
      canvas.translate(at.dx + g / 9, at.dy + g / 9);
      paintPixelArt(canvas, g, pixelPowerIcons[type]!, ink ?? Colors.black);
      canvas.restore();
      canvas.save();
      canvas.translate(at.dx, at.dy);
      paintPixelArt(canvas, g, pixelPowerIcons[type]!, glyphColor);
      canvas.restore();
      return;
    }
    final face = keycapFace(rect, pressed: false);
    final g = min(face.width, face.height) * 1.3;
    canvas.save();
    canvas.translate(face.center.dx - g / 2, face.center.dy - g / 2 + g * 0.04);
    PowerGlyphPainter(type, color: ink ?? Colors.black.withValues(alpha: 0.25)).paint(canvas, Size.square(g));
    canvas.restore();
    canvas.save();
    canvas.translate(face.center.dx - g / 2, face.center.dy - g / 2);
    PowerGlyphPainter(type, color: glyphColor).paint(canvas, Size.square(g));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PowerKeyPainter old) =>
      old.type != type || old.color != color || old.glyphColor != glyphColor || old.dark != dark || old.glow != glow || old.ink != ink;
}

/// Three arcs around the energy count, lit one per cleared line.
class _EnergyRingPainter extends CustomPainter {
  _EnergyRingPainter({required this.energy, required this.pulse, required this.track, required this.palette});

  final int energy;
  final double pulse;
  final Color track;
  final GamePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    if (palette.flat) {
      // Solid segments with an ink outline, no glow.
      const n = TetrisGame.energyPerPower;
      const gap = 0.42;
      const sweep = 2 * pi / n - gap;
      final cap = palette.skin == GameSkin.pixel ? StrokeCap.butt : StrokeCap.round;
      for (var i = 0; i < n; i++) {
        final start = -pi / 2 + gap / 2 + i * 2 * pi / n;
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8.5
            ..strokeCap = cap
            ..color = palette.ink,
        );
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5
            ..strokeCap = cap
            ..color = i < energy ? Color.lerp(palette.accent1, Colors.white, 0.4 * pulse)! : track,
        );
      }
      return;
    }
    const n = TetrisGame.energyPerPower;
    const gap = 0.32;
    const sweep = 2 * pi / n - gap;
    for (var i = 0; i < n; i++) {
      final start = -pi / 2 + gap / 2 + i * 2 * pi / n;
      final on = i < energy;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;
      if (on) {
        paint.shader = const SweepGradient(colors: [Color(0xFF7DD3FC), Color(0xFFA855F7), Color(0xFFF472B6), Color(0xFF7DD3FC)])
            .createShader(rect);
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7 + 6 * pulse
            ..color = const Color(0xFFA855F7).withValues(alpha: 0.25 + 0.3 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      } else {
        paint.color = track;
      }
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter old) =>
      old.energy != energy || old.pulse != pulse || old.track != track || old.palette != palette;
}

/// White vector icon for each power.
class PowerGlyphPainter extends CustomPainter {
  PowerGlyphPainter(this.type, {this.color = Colors.white});

  final PowerType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.translate(s * 0.25, s * 0.25);
    final u = s * 0.5;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
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
          ..color = color
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
  bool shouldRepaint(covariant PowerGlyphPainter old) => old.type != type || old.color != color;
}
