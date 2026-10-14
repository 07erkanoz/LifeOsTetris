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

/// Round on-screen control. Supports press-and-hold through [onDown]/[onUp].
class ControlButton extends StatefulWidget {
  const ControlButton({super.key, required this.icon, this.onDown, this.onUp, this.size = 56, this.primary = false});

  final IconData icon;
  final VoidCallback? onDown;
  final VoidCallback? onUp;
  final double size;
  final bool primary;

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
    return Listener(
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.primary
                ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.accent1, p.accent2])
                : null,
            color: widget.primary ? null : p.glass,
            border: Border.all(color: widget.primary ? Colors.white.withValues(alpha: 0.25) : p.glassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.primary ? p.accent1.withValues(alpha: _pressed ? 0.7 : 0.45) : p.glassShadow,
                blurRadius: widget.primary ? 26 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(widget.icon, size: s * (widget.primary ? 0.46 : 0.42), color: widget.primary ? Colors.white : p.icon),
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
            if (icon != null) ...[Icon(icon, color: fg, size: 22), const SizedBox(width: 10)],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: icon == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(color: fg.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w600),
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

/// "Açık / Koyu" segmented theme picker.
class ThemeSegment extends StatelessWidget {
  const ThemeSegment({super.key, required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    Widget seg(String label, IconData icon, bool selected, bool dark) => Expanded(
      child: GestureDetector(
        onTap: () => onChanged(dark),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: selected ? LinearGradient(colors: [p.accent1, p.accent2]) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : p.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : p.muted),
              ),
            ],
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          seg('Açık', Icons.light_mode_rounded, !isDark, false),
          const SizedBox(width: 3),
          seg('Koyu', Icons.dark_mode_rounded, isDark, true),
        ],
      ),
    );
  }
}
