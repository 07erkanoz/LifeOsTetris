import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/tetromino.dart';
import '../game/render/background_painter.dart';
import '../game/render/block_sprites.dart';
import '../game/sugar/sugar_art.dart' show paintLokum;
import '../l10n/strings.dart';
import '../theme/palette.dart';
import 'game_icons.dart';

export 'game_icons.dart' show GameIcon;

/// Phones and tablets: vibration and on-screen buttons only make sense there.
bool get isMobilePlatform => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

const neonCyan = Color(0xFF3DF5FF);
const neonBlue = Color(0xFF3D7BFF);
const neonPink = Color(0xFFFF4FD8);
const neonViolet = Color(0xFF8C5BFF);
const _neonPanelTop = Color(0xCC131B36);
const _neonPanelBottom = Color(0xB30A0F22);

/// A neon panel: dark glass, a thin outline in [tone] and a soft halo that
/// grows with [glow].
Decoration neonCardDecoration({double radius = 20, double glow = 0, Color tone = neonCyan}) => BoxDecoration(
  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_neonPanelTop, _neonPanelBottom]),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Color.lerp(tone.withValues(alpha: 0.3), tone, glow)!, width: 1.3),
  boxShadow: [
    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
    BoxShadow(color: tone.withValues(alpha: 0.1 + 0.4 * glow), blurRadius: 18 + 12 * glow),
  ],
);

/// Icon colour and glow on neon panels.
const neonGlyph = Color(0xFFD4FBFF);
List<Shadow> neonGlyphGlow([Color tone = neonCyan]) => [Shadow(color: tone.withValues(alpha: 0.85), blurRadius: 10)];

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
    if (p.flat) {
      return Container(
        padding: padding,
        decoration: flatCardDecoration(p, radius: radius, glow: glow),
        child: child,
      );
    }
    if (isNeon(p)) {
      return Container(padding: padding, decoration: neonCardDecoration(radius: radius, glow: glow), child: child);
    }
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

/// Card of the flat skins: solid fill, ink outline and a hard shadow (toy),
/// or a chamfered pixel frame (pixel).
Decoration flatCardDecoration(GamePalette p, {double radius = 20, double glow = 0, Color? fill, double depth = 4}) {
  final border = Color.lerp(p.glassBorder, p.accent1, glow)!;
  if (p.skin == GameSkin.pixel) {
    return ShapeDecoration(
      color: fill ?? p.glass,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: border, width: 3),
      ),
      shadows: [BoxShadow(color: p.glassShadow, offset: Offset(depth * 0.75, depth * 0.75))],
    );
  }
  return BoxDecoration(
    color: fill ?? p.glass,
    borderRadius: BorderRadius.circular(radius * 0.8),
    border: Border.all(color: border, width: 2.5),
    boxShadow: [BoxShadow(color: p.glassShadow, offset: Offset(0, depth))],
  );
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
      style: GamePalette.of(context).flat
          ? TextStyle(fontSize: 12, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: GamePalette.of(context).label)
          : TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: GamePalette.of(context).label),
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
    final p = GamePalette.of(context);
    if (p.flat) {
      final tone = flatTone(gradient?.colors, p);
      // Pixel tones are deep button colours; lift them for text on navy.
      final color = p.skin == GameSkin.pixel && p.isDark && tone.computeLuminance() < 0.25 ? Color.lerp(tone, Colors.white, 0.4)! : tone;
      return Text(text, style: style.copyWith(color: color));
    }
    final g = gradient ?? p.accentGradient;
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

/// The word mark: Lokum's face, "Küpler" and, under it, what the app is.
class LogoTitle extends StatelessWidget {
  const LogoTitle({super.key, this.fontSize = 20});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final face = SizedBox(width: fontSize * 1.35, height: fontSize * 1.35, child: CustomPaint(painter: _LogoFace()));
    final tagline = Text(s.appTagline, style: TextStyle(fontSize: fontSize * 0.42, height: 1, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: p.muted));
    if (p.flat) return _flat(p, face, tagline);
    final style = TextStyle(fontSize: fontSize, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: p.text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        face,
        SizedBox(width: fontSize * 0.3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [GradientText(s.appName, style: style), tagline],
        ),
      ],
    );
  }
}

class _LogoFace extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => paintLokum(canvas, Offset(size.width / 2, size.height * 0.5), size.height * 0.92);

  @override
  bool shouldRepaint(_LogoFace old) => false;
}

extension on LogoTitle {
  /// Sticker-like word mark: ink outline and a hard drop shadow.
  Widget _flat(GamePalette p, Widget face, Widget tagline) {
    final pixel = p.skin == GameSkin.pixel;
    final size = pixel ? fontSize * 0.95 : fontSize * 1.05;
    Widget word(String text, Color color) {
      final base = TextStyle(fontSize: size, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: pixel ? 1 : 0);
      return Stack(
        children: [
          Transform.translate(
            offset: Offset(pixel ? size * 0.08 : 0, size * 0.09),
            child: Text(
              text,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = pixel ? 0.01 : size * 0.16
                  ..strokeJoin = StrokeJoin.round
                  ..color = p.ink,
              ),
            ),
          ),
          if (pixel)
            Transform.translate(
              offset: Offset(size * 0.08, size * 0.09),
              child: Text(text, style: base.copyWith(color: p.ink)),
            ),
          if (!pixel)
            Text(
              text,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = size * 0.16
                  ..strokeJoin = StrokeJoin.round
                  ..color = p.ink,
              ),
            ),
          Text(text, style: base.copyWith(color: color)),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        face,
        SizedBox(width: fontSize * 0.3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [word(AppStrings.appTitle, p.accent1), tagline],
        ),
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
    if (p.flat) {
      final button = GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          size: Size.square(size),
          painter: _KeycapPainter(color: p.keyFace, pressed: false, dark: p.isDark, palette: p),
          child: SizedBox.square(
            dimension: size,
            child: Align(
              alignment: const Alignment(0, -0.25),
              child: GameIcon(icon, size: size * 0.46, color: p.keyGlyph),
            ),
          ),
        ),
      );
      return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
    }
    final neon = isNeon(p);
    final button = GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: size * 0.35,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: size * 0.45, color: neon ? neonGlyph : p.icon, shadows: neon ? neonGlyphGlow() : null),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

enum ControlGlyph { hold, left, right, rotate, drop }

const Map<ControlGlyph, List<String>> _pixelGlyphs = {
  ControlGlyph.left: ['.........', '....#....', '...##....', '..#######', '.########', '..#######', '...##....', '....#....', '.........'],
  ControlGlyph.right: ['.........', '....#....', '....##...', '#######..', '########.', '#######..', '....##...', '....#....', '.........'],
  ControlGlyph.rotate: [
    '..####.#.',
    '.#....##.',
    '#....###.',
    '#........',
    '#.......#',
    '#.......#',
    '.#.....#.',
    '..#####..',
    '.........',
  ],
  ControlGlyph.drop: ['.#######.', '..#####..', '...###...', '....#....', '.#######.', '..#####..', '...###...', '....#....', '#########'],
  ControlGlyph.hold: ['#########', '#.......#', '#.......#', '#..###..#', '#..###..#', '#..###..#', '#.......#', '#.......#', '#########'],
};

/// Crisp vector icons for the on-screen controls (font icons looked soft and
/// thin on some Android screens).
class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final ControlGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (activeSkin == GameSkin.pixel) {
      paintPixelArt(canvas, size.width, _pixelGlyphs[glyph]!, color);
      return;
    }
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

/// Paints a 2.5D "jelly keycap" in [rect]: a darker base for depth, a
/// glossy top face, a soft rim and highlight, matching the game's blocks.
/// When [pressed] the top face sinks onto its base.
void paintKeycap(
  Canvas canvas,
  Rect rect,
  Color color, {
  required bool pressed,
  required bool dark,
  double glow = 0,
  double alpha = 1,
  bool primary = false,
}) {
  switch (activeSkin) {
    case GameSkin.toy:
      _paintToyKey(canvas, rect, color, pressed: pressed, glow: glow);
      return;
    case GameSkin.pixel:
      _paintPixelKey(canvas, rect, color, pressed: pressed, glow: glow);
      return;
    case GameSkin.glass:
      if (neonStyle && dark) {
        _paintNeonKey(canvas, rect, pressed: pressed, primary: primary);
        return;
      }
  }
  final depth = rect.height * 0.09;
  final radius = Radius.circular(min(rect.width, rect.height) * 0.32);
  final sink = pressed ? depth * 0.75 : 0.0;
  final base = RRect.fromRectAndRadius(Rect.fromLTRB(rect.left, rect.top + depth, rect.right, rect.bottom), radius);
  final face = RRect.fromRectAndRadius(Rect.fromLTRB(rect.left, rect.top + sink, rect.right, rect.bottom - depth + sink), radius);

  canvas.drawRRect(
    base.shift(Offset(0, depth * 0.8)),
    Paint()
      ..color = (dark ? Colors.black : const Color(0xFF1E2850)).withValues(alpha: dark ? 0.55 : 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.height * 0.12),
  );
  if (glow > 0) {
    canvas.drawRRect(
      face,
      Paint()
        ..color = color.withValues(alpha: 0.55 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.height * 0.25),
    );
  }
  canvas.drawRRect(base, Paint()..color = Color.lerp(color, Colors.black, dark ? 0.5 : 0.28)!.withValues(alpha: alpha));
  canvas.drawRRect(
    face,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          lighten(color, 0.28).withValues(alpha: alpha),
          color.withValues(alpha: alpha),
          Color.lerp(color, Colors.black, 0.12)!.withValues(alpha: alpha),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(face.outerRect),
  );
  final inset = rect.height * 0.045;
  canvas.drawRRect(
    face.deflate(inset),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, rect.height * 0.03)
      ..color = Colors.white.withValues(alpha: (dark ? 0.22 : 0.5) + (1 - alpha) * 0.25),
  );
  final gloss = Rect.fromLTWH(face.left + face.width * 0.16, face.top + face.height * 0.08, face.width * 0.68, face.height * 0.32);
  canvas.drawRRect(
    RRect.fromRectAndRadius(gloss, Radius.circular(gloss.height / 2)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: dark ? 0.3 : 0.6),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(gloss),
  );
}

/// Neon key: dark glass with a glowing outline (cyan, or pink to violet for
/// the primary key); pressing brightens the glow and the face.
void _paintNeonKey(Canvas canvas, Rect rect, {required bool pressed, required bool primary}) {
  final h = rect.height;
  final face = RRect.fromRectAndRadius(rect.deflate(h * (pressed ? 0.06 : 0.035)), Radius.circular(min(rect.width, h) * 0.3));
  final tones = primary ? const [neonPink, neonViolet] : const [neonCyan, neonBlue];
  final outline = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tones).createShader(face.outerRect);
  canvas.drawRRect(
    face,
    Paint()
      ..shader = outline
      ..color = Color.fromRGBO(0, 0, 0, pressed ? 0.95 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.08
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * (pressed ? 0.17 : 0.11)),
  );
  final tint = primary ? 0.3 : 0.1;
  canvas.drawRRect(
    face,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF131B36), tones.first, tint + (pressed ? 0.15 : 0))!.withValues(alpha: 0.88),
          Color.lerp(const Color(0xFF0A0F22), tones.last, tint * 0.6 + (pressed ? 0.1 : 0))!.withValues(alpha: 0.8),
        ],
      ).createShader(face.outerRect),
  );
  canvas.save();
  canvas.clipRRect(face);
  final top = Rect.fromLTWH(face.left, face.top, face.width, face.height * 0.45);
  canvas.drawRect(
    top,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.09), Colors.white.withValues(alpha: 0)],
      ).createShader(top),
  );
  canvas.restore();
  canvas.drawRRect(
    face,
    Paint()
      ..shader = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.4, h * 0.028),
  );
}

Color get _ink => (GamePalette.dark.isDark ? GamePalette.dark : GamePalette.light).ink;

/// Toy key: flat face on a darker lip, ink outline; sinks when pressed.
void _paintToyKey(Canvas canvas, Rect rect, Color color, {required bool pressed, double glow = 0}) {
  final ink = _ink;
  final depth = rect.height * 0.12;
  final outline = max(2.0, rect.height * 0.045);
  final radius = Radius.circular(min(rect.width, rect.height) * 0.3);
  final sink = pressed ? depth * 0.8 : 0.0;
  final body = RRect.fromRectAndRadius(Rect.fromLTRB(rect.left, rect.top + sink, rect.right, rect.bottom), radius);
  final face = RRect.fromRectAndRadius(Rect.fromLTRB(rect.left, rect.top + sink, rect.right, rect.bottom - depth), radius);
  canvas.drawRRect(body, Paint()..color = ink);
  canvas.drawRRect(body.deflate(outline), Paint()..color = Color.lerp(color, ink, 0.38)!);
  canvas.drawRRect(face.deflate(outline), Paint()..color = Color.lerp(color, Colors.white, 0.25 * glow)!);
}

/// Pixel key: square bevel with a black border; the bevel flips when pressed.
void _paintPixelKey(Canvas canvas, Rect rect, Color color, {required bool pressed, double glow = 0}) {
  final u = max(2.0, (rect.height / 16).roundToDouble());
  final depth = u * 2;
  final sink = pressed ? depth : 0.0;
  final body = Rect.fromLTRB(rect.left, rect.top + sink, rect.right, rect.bottom - depth + sink);
  final ink = _ink;
  if (!pressed) canvas.drawRect(Rect.fromLTRB(rect.left + u, rect.top + depth, rect.right + 0, rect.bottom), Paint()..color = ink);
  final chamfer = Path()
    ..moveTo(body.left + u, body.top)
    ..lineTo(body.right - u, body.top)
    ..lineTo(body.right - u, body.top + u)
    ..lineTo(body.right, body.top + u)
    ..lineTo(body.right, body.bottom - u)
    ..lineTo(body.right - u, body.bottom - u)
    ..lineTo(body.right - u, body.bottom)
    ..lineTo(body.left + u, body.bottom)
    ..lineTo(body.left + u, body.bottom - u)
    ..lineTo(body.left, body.bottom - u)
    ..lineTo(body.left, body.top + u)
    ..lineTo(body.left + u, body.top + u)
    ..close();
  canvas.drawPath(chamfer, Paint()..color = ink);
  final inner = body.deflate(u);
  final face = Color.lerp(color, Colors.white, 0.3 * glow)!;
  canvas.drawRect(inner, Paint()..color = face);
  final light = Paint()..color = Color.lerp(face, Colors.white, 0.4)!;
  final dark = Paint()..color = Color.lerp(face, Colors.black, 0.35)!;
  canvas.drawRect(Rect.fromLTWH(inner.left, inner.top, inner.width, u), pressed ? dark : light);
  canvas.drawRect(Rect.fromLTWH(inner.left, inner.top, u, inner.height), pressed ? dark : light);
  canvas.drawRect(Rect.fromLTWH(inner.left, inner.bottom - u, inner.width, u), pressed ? light : dark);
  canvas.drawRect(Rect.fromLTWH(inner.right - u, inner.top, u, inner.height), pressed ? light : dark);
}

/// The face of a keycap painted by [paintKeycap] (for placing its glyph).
Rect keycapFace(Rect rect, {required bool pressed}) {
  switch (activeSkin) {
    case GameSkin.toy:
      final depth = rect.height * 0.12;
      final sink = pressed ? depth * 0.8 : 0.0;
      return Rect.fromLTRB(rect.left, rect.top + sink, rect.right, rect.bottom - depth + sink);
    case GameSkin.pixel:
      final depth = max(2.0, (rect.height / 16).roundToDouble()) * 2;
      final sink = pressed ? depth : 0.0;
      return Rect.fromLTRB(rect.left, rect.top + sink, rect.right, rect.bottom - depth + sink);
    case GameSkin.glass:
      break;
  }
  final depth = rect.height * 0.09;
  final sink = pressed ? depth * 0.75 : 0.0;
  return Rect.fromLTRB(rect.left, rect.top + sink, rect.right, rect.bottom - depth + sink);
}

class _KeycapPainter extends CustomPainter {
  _KeycapPainter({
    required this.color,
    required this.pressed,
    required this.dark,
    this.glyph,
    this.glyphColor = Colors.white,
    this.glyphScale = 0.42,
    this.alpha = 1,
    this.palette,
    this.primary = false,
  });

  /// The main key (rotate): neon draws it pink to violet.
  final bool primary;

  /// Only used to pick ink for the flat skins.
  final GamePalette? palette;

  final Color color;
  final bool pressed;
  final bool dark;
  final ControlGlyph? glyph;
  final Color glyphColor;
  final double glyphScale;

  /// Body opacity: below 1 the key turns to tinted glass.
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintKeycap(canvas, rect, color, pressed: pressed, dark: dark, glow: pressed ? 1 : 0, alpha: alpha, primary: primary);
    final glyph = this.glyph;
    if (glyph == null) return;
    final neon = neonStyle && activeSkin == GameSkin.glass && dark;
    final face = neon ? rect : keycapFace(rect, pressed: pressed);
    final g = min(face.width, face.height) * glyphScale;
    canvas.save();
    canvas.translate(face.center.dx - g / 2, face.center.dy - g / 2);
    if (neon) {
      // The glyph glows in its key's colour, like a lit tube.
      final glowBounds = Rect.fromLTWH(-g * 0.3, -g * 0.3, g * 1.6, g * 1.6);
      canvas.saveLayer(glowBounds, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: g * 0.09, sigmaY: g * 0.09));
      _GlyphPainter(glyph, primary ? neonPink : neonCyan).paint(canvas, Size.square(g));
      canvas.restore();
      _GlyphPainter(glyph, primary ? Colors.white : neonGlyph).paint(canvas, Size.square(g));
      canvas.restore();
      return;
    }
    // A soft drop shadow lifts the glyph off the face.
    if (activeSkin == GameSkin.glass) {
      canvas.save();
      canvas.translate(0, g * 0.05);
      _GlyphPainter(glyph, Colors.black.withValues(alpha: 0.22)).paint(canvas, Size.square(g));
      canvas.restore();
    }
    _GlyphPainter(glyph, glyphColor).paint(canvas, Size.square(g));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KeycapPainter old) =>
      old.color != color ||
      old.pressed != pressed ||
      old.dark != dark ||
      old.glyph != glyph ||
      old.glyphColor != glyphColor ||
      old.alpha != alpha ||
      old.primary != primary;
}

/// On-screen control drawn as a jelly keycap that sinks when pressed.
/// Supports press-and-hold through [onDown]/[onUp].
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

/// Body opacity of the secondary keys: tinted glass that lets the backdrop
/// show through (the rotate key stays mostly solid).
const double keycapGlass = 0.45;

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
    final color = primary ? p.keyPrimary : p.keyFace;
    final glyphColor = primary ? p.keyPrimaryGlyph : p.keyGlyph;
    final body = CustomPaint(
      size: Size.square(s),
      painter: _KeycapPainter(
        color: color,
        pressed: _pressed,
        dark: p.isDark,
        glyph: widget.glyph,
        glyphColor: glyphColor,
        glyphScale: primary ? 0.46 : 0.42,
        alpha: p.flat ? 1 : (primary ? max(0.85, keycapGlass) : keycapGlass),
        primary: primary,
      ),
    );

    final button = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: body,
    );
    return widget.tooltip == null ? button : Tooltip(message: widget.tooltip!, child: button);
  }
}

/// Pill-shaped primary action button.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.secondary = false,
    this.width,
    this.colors,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final bool secondary;
  final double? width;

  /// Gradient override for primary buttons.
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    if (p.flat) return _flat(context, p);
    final fg = secondary ? p.text : Colors.white;
    final gradient = colors ?? [p.accent1, p.accent2];
    final neon = isNeon(p);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(horizontal: subtitle == null ? 14 : 20, vertical: 14),
        // Coloured buttons stay bright (like the play button); secondary
        // ones become neon panels.
        decoration: neon && secondary
            ? neonCardDecoration(radius: 18)
            : BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: secondary ? null : LinearGradient(colors: gradient),
          color: secondary ? p.glass : null,
          border: Border.all(color: secondary ? p.glassBorder : Colors.white.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(color: secondary ? p.glassShadow : gradient.first.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8)),
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

/// Solid colours the flat skins use instead of the glass gradients.
Color flatTone(List<Color>? colors, GamePalette p) {
  final first = colors?.first;
  if (first == null) return p.accent1;
  final toy = p.skin == GameSkin.toy;
  return switch (first.toARGB32()) {
    0xFFA855F7 => toy ? const Color(0xFF9467E6) : const Color(0xFF7E2553),
    0xFF14B8A6 => toy ? const Color(0xFF2FB59A) : const Color(0xFF008751),
    0xFFFDE047 || 0xFF38BDF8 || 0xFF7DD3FC => p.accent1,
    _ => first,
  };
}

extension on GradientButton {
  Widget _flat(BuildContext context, GamePalette p) {
    final tone = secondary ? p.keyFace : flatTone(colors, p);
    final light = tone.computeLuminance() > 0.45;
    final fg = secondary ? p.text : (light ? p.ink : Colors.white);
    final textShadow = !secondary && !light && p.skin == GameSkin.toy
        ? [Shadow(color: p.ink.withValues(alpha: 0.6), offset: const Offset(0, 2))]
        : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(horizontal: subtitle == null ? 14 : 18, vertical: subtitle == null ? 12 : 10),
        decoration: flatCardDecoration(p, radius: 20, fill: tone, depth: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[GameIcon(icon!, color: fg, size: subtitle == null ? 22 : 26), const SizedBox(width: 10)],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: icon == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(color: fg, fontSize: 19, height: 1.15, fontWeight: FontWeight.w800, shadows: textShadow),
                    ),
                  ),
                  if (subtitle != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 13, height: 1.15, fontWeight: FontWeight.w600),
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
            if (icon != null) ...[GameIcon(icon!, size: 18, color: p.muted), const SizedBox(width: 10)],
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
                borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 2 : 12),
                gradient: value && !p.flat ? LinearGradient(colors: [p.accent1, p.accent2]) : null,
                color: value ? (p.flat ? p.accent1 : null) : p.track,
                border: p.flat ? Border.all(color: p.ink, width: 2) : null,
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
    final flat = p.flat;
    final selectedFg = flat && p.accent1.computeLuminance() > 0.45 ? p.ink : Colors.white;
    return Container(
      padding: EdgeInsets.all(flat ? 4 : 3),
      decoration: flat
          ? flatCardDecoration(p, radius: 16, fill: p.track, depth: 0)
          : BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(12)),
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
                  decoration: flat
                      ? (i == selected
                            ? (p.skin == GameSkin.pixel
                                  ? ShapeDecoration(
                                      color: p.accent1,
                                      shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                                    )
                                  : BoxDecoration(
                                      color: p.accent1,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: p.ink, width: 2),
                                    ))
                            : null)
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: i == selected ? LinearGradient(colors: [p.accent1, p.accent2]) : null,
                        ),
                  child: IconTheme(
                    data: IconThemeData(size: 16, color: i == selected ? (flat ? selectedFg : Colors.white) : p.muted),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (options[i].$2 != null) ...[options[i].$2!, const SizedBox(width: 6)],
                        Flexible(
                          child: Text(
                            options[i].$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: flat ? 15 : 13,
                              fontWeight: FontWeight.w700,
                              color: i == selected ? (flat ? selectedFg : Colors.white) : p.muted,
                            ),
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
    options: [(lightLabel, const GameIcon(Icons.light_mode_rounded)), (darkLabel, const GameIcon(Icons.dark_mode_rounded))],
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
    options: const [('Türkçe', GameIcon(Icons.translate_rounded)), ('English', GameIcon(Icons.language_rounded))],
    selected: isTurkish ? 0 : 1,
    onChanged: (i) => onChanged(i == 0),
  );
}
