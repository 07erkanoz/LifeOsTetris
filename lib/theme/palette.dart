import 'package:flutter/material.dart';

import '../core/tetromino.dart';

/// Vivid block colours shared by both themes.
const Map<PieceType, Color> blockColors = {
  PieceType.i: Color(0xFF22D3EE),
  PieceType.o: Color(0xFFFACC15),
  PieceType.t: Color(0xFFA855F7),
  PieceType.s: Color(0xFF22C55E),
  PieceType.z: Color(0xFFEF4444),
  PieceType.j: Color(0xFF3B82F6),
  PieceType.l: Color(0xFFF97316),
  PieceType.mono: Color(0xFFCBD5E1),
  PieceType.bomb: Color(0xFFF43F5E),
  PieceType.drill: Color(0xFFF59E0B),
  PieceType.gem: Color(0xFFFBBF24),
};

const String fontFamily = 'Inter';

/// Colour tokens for the game UI. Registered as a [ThemeExtension] so widgets
/// can read it with `GamePalette.of(context)`.
@immutable
class GamePalette extends ThemeExtension<GamePalette> {
  const GamePalette({
    required this.isDark,
    required this.background,
    required this.glows,
    required this.text,
    required this.muted,
    required this.label,
    required this.glass,
    required this.glassBorder,
    required this.glassShadow,
    required this.accent1,
    required this.accent2,
    required this.wellTop,
    required this.wellBottom,
    required this.grid,
    required this.frameFill,
    required this.frameBorder,
    required this.frameShadow,
    required this.shadeTarget,
    required this.track,
    required this.icon,
  });

  final bool isDark;
  final List<Color> background;
  final List<Color> glows;
  final Color text;
  final Color muted;
  final Color label;
  final Color glass;
  final Color glassBorder;
  final Color glassShadow;
  final Color accent1;
  final Color accent2;
  final Color wellTop;
  final Color wellBottom;
  final Color grid;
  final Color frameFill;
  final Color frameBorder;
  final Color frameShadow;

  /// Colour blocks are darkened towards for their side faces.
  final Color shadeTarget;
  final Color track;
  final Color icon;

  LinearGradient get accentGradient => LinearGradient(colors: [accent1, accent2]);

  static const dark = GamePalette(
    isDark: true,
    background: [Color(0xFF0A0D1A), Color(0xFF0E1226), Color(0xFF0A0C18)],
    glows: [Color(0x2938BDF8), Color(0x2E6366F1), Color(0x1A22D3EE)],
    text: Color(0xFFE8ECF8),
    muted: Color(0xFF8590AE),
    label: Color(0xFF6B7799),
    glass: Color(0x0BFFFFFF),
    glassBorder: Color(0x17FFFFFF),
    glassShadow: Color(0x73000000),
    accent1: Color(0xFF38BDF8),
    accent2: Color(0xFF6366F1),
    wellTop: Color(0xFF0B0F20),
    wellBottom: Color(0xFF10152C),
    grid: Color(0x1294A3D6),
    frameFill: Color(0x0DFFFFFF),
    frameBorder: Color(0x387DD3FC),
    frameShadow: Color(0x99000000),
    shadeTarget: Color(0xFF080A1C),
    track: Color(0x14FFFFFF),
    icon: Color(0xFFA9B4D0),
  );

  static const light = GamePalette(
    isDark: false,
    background: [Color(0xFFF4F6FA), Color(0xFFE9EDF4), Color(0xFFF1F4F9)],
    glows: [Color(0x2438BDF8), Color(0x1F6366F1), Color(0x1422D3EE)],
    text: Color(0xFF1B2236),
    muted: Color(0xFF5D6886),
    label: Color(0xFF8590AB),
    glass: Color(0xB3FFFFFF),
    glassBorder: Color(0xFFFFFFFF),
    glassShadow: Color(0x1A1E2850),
    accent1: Color(0xFF0EA5E9),
    accent2: Color(0xFF4F46E5),
    wellTop: Color(0xFFF8FAFD),
    wellBottom: Color(0xFFECEFF5),
    grid: Color(0x14505F8C),
    frameFill: Color(0xBFFFFFFF),
    frameBorder: Color(0xFFFFFFFF),
    frameShadow: Color(0x2E1E2850),
    shadeTarget: Color(0xFF141832),
    track: Color(0xFFE1E6EF),
    icon: Color(0xFF56617F),
  );

  static GamePalette of(BuildContext context) => Theme.of(context).extension<GamePalette>()!;

  @override
  GamePalette copyWith() => this;

  @override
  GamePalette lerp(covariant GamePalette? other, double t) => t < 0.5 ? this : (other ?? this);
}

ThemeData buildTheme(GamePalette palette) {
  final base = palette.isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: palette.background.first,
    colorScheme: base.colorScheme.copyWith(primary: palette.accent1, secondary: palette.accent2),
    textTheme: base.textTheme.apply(fontFamily: fontFamily, bodyColor: palette.text, displayColor: palette.text),
    extensions: [palette],
  );
}

Color lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color shade(Color c, Color target, double t) => Color.lerp(c, target, t)!;
