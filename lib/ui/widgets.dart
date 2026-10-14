import 'package:flutter/material.dart';

import '../core/tetromino.dart';
import '../game/render/background_painter.dart';
import '../game/render/block_sprites.dart';
import '../theme/palette.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 20, this.glow = 0});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// 0..1 accent glow used for short "pulse" feedback.
  final double glow;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Color.lerp(p.glassBorder, p.accent1, glow * 0.8)!, width: 1.5),
        boxShadow: [
          BoxShadow(color: p.glassShadow, blurRadius: 24, offset: const Offset(0, 8)),
          if (glow > 0)
            BoxShadow(
              color: p.accent1.withValues(alpha: 0.45 * glow),
              blurRadius: 24 * glow,
            ),
        ],
      ),
      child: child,
    );
  }
}

class CardLabel extends StatelessWidget {
  const CardLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: GamePalette.of(context).label),
    ),
  );
}

class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style, this.gradient});

  final String text;
  final TextStyle style;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? GamePalette.of(context).accentGradient;
    return ShaderMask(
      shaderCallback: (rect) => g.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }
}

/// A tetromino drawn with the same sprites as the board.
class PieceView extends StatelessWidget {
  const PieceView({super.key, required this.type, required this.cell, required this.size, this.dimmed = false, this.pop = 0});

  final PieceType? type;
  final double cell;
  final Size size;
  final bool dimmed;
  final double pop;

  @override
  Widget build(BuildContext context) {
    final sprites = BlockSprites.of(cell, MediaQuery.devicePixelRatioOf(context), GamePalette.of(context));
    return CustomPaint(
      size: size,
      painter: PiecePreviewPainter(type: type, sprites: sprites, dimmed: dimmed, pop: pop),
    );
  }
}

class LogoTitle extends StatelessWidget {
  const LogoTitle({super.key, this.fontSize = 20});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: p.text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PieceView(type: PieceType.t, cell: fontSize * 0.42, size: Size(fontSize * 1.4, fontSize)),
        SizedBox(width: fontSize * 0.35),
        Text('LifeOS ', style: style),
        GradientText('Küpler', style: style),
      ],
    );
  }
}

/// Square glass icon button used in the header.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.tooltip, this.size = 40});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final button = GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: size * 0.35,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: size * 0.45, color: p.icon),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

enum ControlGlyph { hold, left, right, rotate, drop }

/// Crisp vector icons for the on-screen controls (font icons looked soft and
/// thin on some Android screens).
class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final ControlGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    Offset p(double x, double y) => Offset(x * s, y * s);

    switch (glyph) {
      case ControlGlyph.left || ControlGlyph.right:
        final flip = glyph == ControlGlyph.right ? -1.0 : 1.0;
        final path = Path()
          ..moveTo(s * (0.5 + 0.12 * flip), s * 0.22)
          ..lineTo(s * (0.5 - 0.16 * flip), s * 0.5)
          ..lineTo(s * (0.5 + 0.12 * flip), s * 0.78);
        canvas.drawPath(path, stroke);
      case ControlGlyph.drop:
        for (final y in [0.14, 0.4]) {
          canvas.drawPath(
            Path()
              ..moveTo(s * 0.24, s * y)
              ..lineTo(s * 0.5, s * (y + 0.18))
              ..lineTo(s * 0.76, s * y),
            stroke,
          );
        }
        canvas.drawLine(p(0.26, 0.86), p(0.74, 0.86), stroke);
      case ControlGlyph.rotate:
        final rect = Rect.fromCircle(center: p(0.5, 0.52), radius: s * 0.3);
        canvas.drawArc(rect, -1.2, 4.9, false, stroke);
        // Arrow head at the start of the arc (top right), pointing clockwise.
        final tip = p(0.5 + 0.3 * 0.362, 0.52 - 0.3 * 0.932);
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx + s * 0.2, tip.dy - s * 0.02)
            ..lineTo(tip.dx + s * 0.02, tip.dy - s * 0.02)
            ..lineTo(tip.dx + s * 0.06, tip.dy + s * 0.17),
          stroke,
        );
      case ControlGlyph.hold:
        final box = RRect.fromRectAndRadius(Rect.fromLTRB(s * 0.2, s * 0.2, s * 0.8, s * 0.8), Radius.circular(s * 0.16));
        canvas.drawRRect(box, stroke..strokeWidth = s * 0.1);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(s * 0.37, s * 0.37, s * 0.63, s * 0.63), Radius.circular(s * 0.06)), fill);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) => old.glyph != glyph || old.color != color;
}

/// Round on-screen control with a glossy glass body. Supports press-and-hold
/// through [onDown]/[onUp].
class ControlButton extends StatefulWidget {
  const ControlButton({super.key, required this.glyph, this.onDown, this.onUp, this.size = 58, this.primary = false, this.tooltip});

  final ControlGlyph glyph;
  final VoidCallback? onDown;
  final VoidCallback? onUp;
  final double size;
  final bool primary;
  final String? tooltip;

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _pressed = false;

  void _down() {
    setState(() => _pressed = true);
    widget.onDown?.call();
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onUp?.call();
  }

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = widget.size;
    final primary = widget.primary;
    final iconColor = primary ? Colors.white : (p.isDark ? const Color(0xFFDDE5F7) : const Color(0xFF3B4663));

    final body = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: primary
            ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [lighten(p.accent1, 0.1), p.accent2])
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: p.isDark ? [const Color(0xFF2A3150), const Color(0xFF161B32)] : [Colors.white, const Color(0xFFE6EAF2)],
              ),
        boxShadow: [
          BoxShadow(
            color: primary
                ? p.accent1.withValues(alpha: _pressed ? 0.75 : 0.45)
                : (p.isDark ? const Color(0x99000000) : const Color(0x331E2850)),
            blurRadius: primary ? 24 : 14,
            offset: Offset(0, _pressed ? 3 : 7),
          ),
          if (_pressed && !primary) BoxShadow(color: p.accent1.withValues(alpha: 0.45), blurRadius: 18),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _pressed
              ? p.accent1.withValues(alpha: 0.9)
              : (primary ? Colors.white.withValues(alpha: 0.35) : (p.isDark ? const Color(0x2EFFFFFF) : Colors.white)),
          width: _pressed ? 2 : 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glossy top highlight.
          Positioned(
            top: s * 0.06,
            child: Container(
              width: s * 0.62,
              height: s * 0.32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(s * 0.31, s * 0.16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: primary ? 0.35 : (p.isDark ? 0.12 : 0.8)),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          CustomPaint(size: Size.square(s * (primary ? 0.44 : 0.4)), painter: _GlyphPainter(widget.glyph, iconColor)),
        ],
      ),
    );

    final button = Listener(
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: AnimatedScale(scale: _pressed ? 0.92 : 1, duration: const Duration(milliseconds: 70), child: body),
    );
    return widget.tooltip == null ? button : Tooltip(message: widget.tooltip!, child: button);
  }
}

/// Pill-shaped primary action button.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onTap, this.icon, this.subtitle, this.secondary = false, this.width});

  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final bool secondary;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final fg = secondary ? p.text : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(horizontal: subtitle == null ? 14 : 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: secondary ? null : LinearGradient(colors: [p.accent1, p.accent2]),
          color: secondary ? p.glass : null,
          border: Border.all(color: secondary ? p.glassBorder : Colors.white.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(color: secondary ? p.glassShadow : p.accent1.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: fg, size: 22), const SizedBox(width: 8)],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: icon == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  // Labels shrink instead of wrapping so buttons keep their
                  // shape with long translations or large system fonts.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (subtitle != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(color: fg.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToggleRow extends StatelessWidget {
  const ToggleRow({super.key, required this.label, required this.value, required this.onChanged, this.icon});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: p.muted), const SizedBox(width: 10)],
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.muted),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 42,
              height: 24,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: value ? LinearGradient(colors: [p.accent1, p.accent2]) : null,
                color: value ? null : p.track,
              ),
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-option segmented control used for theme and language.
class SegmentedPicker extends StatelessWidget {
  const SegmentedPicker({super.key, required this.options, required this.selected, required this.onChanged});

  final List<(String label, Widget? leading)> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: i == selected ? LinearGradient(colors: [p.accent1, p.accent2]) : null,
                  ),
                  child: IconTheme(
                    data: IconThemeData(size: 16, color: i == selected ? Colors.white : p.muted),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (options[i].$2 != null) ...[options[i].$2!, const SizedBox(width: 6)],
                        Flexible(
                          child: Text(
                            options[i].$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: i == selected ? Colors.white : p.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ThemeSegment extends StatelessWidget {
  const ThemeSegment({super.key, required this.isDark, required this.onChanged, this.lightLabel = 'Açık', this.darkLabel = 'Koyu'});

  final bool isDark;
  final ValueChanged<bool> onChanged;
  final String lightLabel;
  final String darkLabel;

  @override
  Widget build(BuildContext context) => SegmentedPicker(
    options: [(lightLabel, const Icon(Icons.light_mode_rounded)), (darkLabel, const Icon(Icons.dark_mode_rounded))],
    selected: isDark ? 1 : 0,
    onChanged: (i) => onChanged(i == 1),
  );
}

/// "Türkçe / English" picker. Language names stay in their own language.
class LanguageSegment extends StatelessWidget {
  const LanguageSegment({super.key, required this.isTurkish, required this.onChanged});

  final bool isTurkish;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedPicker(
    options: const [('Türkçe', Icon(Icons.translate_rounded)), ('English', Icon(Icons.language_rounded))],
    selected: isTurkish ? 0 : 1,
    onChanged: (i) => onChanged(i == 0),
  );
}
