import 'package:flutter/material.dart';

import '../core/tetromino.dart';

/// Visual style of the whole game: blocks, cards, keys, icons and type.
enum GameSkin {
  /// Glossy jelly blocks on glass cards (the original look).
  glass,

  /// Flat toy bricks with ink outlines and hard shadows.
  toy,

  /// Bevelled pixel-art blocks and pixel type.
  pixel,
}

const String _skinName = String.fromEnvironment('KUPLER_SKIN', defaultValue: 'glass');

/// The skin in use (picked at build time for now).
final GameSkin activeSkin = GameSkin.values.firstWhere((s) => s.name == _skinName, orElse: () => GameSkin.glass);

/// Extra text scale of the skin's typeface (pixel type runs small).
double get skinTextScale => activeSkin == GameSkin.pixel ? 1.15 : 1;

/// Block colours of the active skin, shared by both themes.
Map<PieceType, Color> get blockColors => switch (activeSkin) {
  GameSkin.glass => _glassBlocks,
  GameSkin.toy => _toyBlocks,
  GameSkin.pixel => _pixelBlocks,
};

const Map<PieceType, Color> _toyBlocks = {
  PieceType.i: Color(0xFF3CC4DC),
  PieceType.o: Color(0xFFFFC53D),
  PieceType.t: Color(0xFFA374EC),
  PieceType.s: Color(0xFF7ED04B),
  PieceType.z: Color(0xFFFF5D62),
  PieceType.j: Color(0xFF4F80F2),
  PieceType.l: Color(0xFFFF9645),
  PieceType.mono: Color(0xFFCFC5DC),
  PieceType.bomb: Color(0xFFFF5D62),
  PieceType.drill: Color(0xFFFFB238),
  PieceType.gem: Color(0xFFFFC53D),
};

const Map<PieceType, Color> _pixelBlocks = {
  PieceType.i: Color(0xFF29ADFF),
  PieceType.o: Color(0xFFFFEC27),
  PieceType.t: Color(0xFFFF77A8),
  PieceType.s: Color(0xFF00E436),
  PieceType.z: Color(0xFFFF004D),
  PieceType.j: Color(0xFF5B6EE1),
  PieceType.l: Color(0xFFFFA300),
  PieceType.mono: Color(0xFFC2C3C7),
  PieceType.bomb: Color(0xFFFF004D),
  PieceType.drill: Color(0xFFFFA300),
  PieceType.gem: Color(0xFFFFEC27),
};

const Map<PieceType, Color> _glassBlocks = {
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

String get fontFamily => switch (activeSkin) {
  GameSkin.glass => 'Inter',
  GameSkin.toy => 'Baloo2',
  GameSkin.pixel => 'Jersey10',
};

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
    this.skin = GameSkin.glass,
    this.ink = const Color(0xFF000000),
    this.pattern = const Color(0x00000000),
    this.keyFace = const Color(0xFF3A4370),
    this.keyGlyph = const Color(0xFFFFFFFF),
    this.keyPrimary = const Color(0xFF3B82F6),
    this.keyPrimaryGlyph = const Color(0xFFFFFFFF),
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

  final GameSkin skin;

  /// Outline and hard-shadow colour of the toy and pixel skins.
  final Color ink;

  /// Backdrop pattern (dots or checks).
  final Color pattern;

  /// On-screen keys: regular and primary body, and their glyphs.
  final Color keyFace;
  final Color keyGlyph;
  final Color keyPrimary;
  final Color keyPrimaryGlyph;

  bool get flat => skin != GameSkin.glass;

  LinearGradient get accentGradient => LinearGradient(colors: [accent1, accent2]);

  static GamePalette get dark => switch (activeSkin) {
    GameSkin.glass => glassDark,
    GameSkin.toy => toyDark,
    GameSkin.pixel => pixelDark,
  };

  static GamePalette get light => switch (activeSkin) {
    GameSkin.glass => glassLight,
    GameSkin.toy => toyLight,
    GameSkin.pixel => pixelLight,
  };

  static const glassDark = GamePalette(
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

  static const glassLight = GamePalette(
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
    keyFace: Color(0xFFE4E9F4),
    keyGlyph: Color(0xFF3B4663),
  );

  static const toyDark = GamePalette(
    isDark: true,
    skin: GameSkin.toy,
    background: [Color(0xFF2A2238), Color(0xFF2A2238), Color(0xFF2A2238)],
    glows: [Color(0x00000000), Color(0x00000000), Color(0x00000000)],
    pattern: Color(0xFF342B45),
    text: Color(0xFFFFF4E6),
    muted: Color(0xFFC6B9D8),
    label: Color(0xFFA192B8),
    glass: Color(0xFF3B3150),
    glassBorder: Color(0xFF17121F),
    glassShadow: Color(0xFF17121F),
    accent1: Color(0xFFFFC53D),
    accent2: Color(0xFFFF9645),
    wellTop: Color(0xFF1F1929),
    wellBottom: Color(0xFF1F1929),
    grid: Color(0xFF3F3552),
    frameFill: Color(0xFF3B3150),
    frameBorder: Color(0xFF17121F),
    frameShadow: Color(0xFF17121F),
    shadeTarget: Color(0xFF17121F),
    track: Color(0xFF272034),
    icon: Color(0xFFF1E6FF),
    ink: Color(0xFF17121F),
    keyFace: Color(0xFF4C4166),
    keyGlyph: Color(0xFFFFF4E6),
    keyPrimary: Color(0xFFFFC53D),
    keyPrimaryGlyph: Color(0xFF17121F),
  );

  static const toyLight = GamePalette(
    isDark: false,
    skin: GameSkin.toy,
    background: [Color(0xFFF6EDDD), Color(0xFFF6EDDD), Color(0xFFF6EDDD)],
    glows: [Color(0x00000000), Color(0x00000000), Color(0x00000000)],
    pattern: Color(0xFFEADDC7),
    text: Color(0xFF2B2236),
    muted: Color(0xFF6E6280),
    label: Color(0xFF94889F),
    glass: Color(0xFFFFFBF3),
    glassBorder: Color(0xFF2B2236),
    glassShadow: Color(0xFF2B2236),
    accent1: Color(0xFFEF6A3A),
    accent2: Color(0xFFFFB238),
    wellTop: Color(0xFFFFF9EF),
    wellBottom: Color(0xFFFFF9EF),
    grid: Color(0xFFE2D4BE),
    frameFill: Color(0xFFFFFBF3),
    frameBorder: Color(0xFF2B2236),
    frameShadow: Color(0xFF2B2236),
    shadeTarget: Color(0xFF2B2236),
    track: Color(0xFFEDE2D0),
    icon: Color(0xFF2B2236),
    ink: Color(0xFF2B2236),
    keyFace: Color(0xFFFFFBF3),
    keyGlyph: Color(0xFF2B2236),
    keyPrimary: Color(0xFFFFC53D),
    keyPrimaryGlyph: Color(0xFF2B2236),
  );

  static const pixelDark = GamePalette(
    isDark: true,
    skin: GameSkin.pixel,
    background: [Color(0xFF110D20), Color(0xFF110D20), Color(0xFF110D20)],
    glows: [Color(0x00000000), Color(0x00000000), Color(0x00000000)],
    pattern: Color(0xFF151027),
    text: Color(0xFFFFF1E8),
    muted: Color(0xFFC2C3C7),
    label: Color(0xFF8E86AE),
    glass: Color(0xFF1D2B53),
    glassBorder: Color(0xFF4B5C9E),
    glassShadow: Color(0xFF000000),
    accent1: Color(0xFFFFEC27),
    accent2: Color(0xFFFFA300),
    wellTop: Color(0xFF0A0716),
    wellBottom: Color(0xFF0A0716),
    grid: Color(0xFF110D22),
    frameFill: Color(0xFF1D2B53),
    frameBorder: Color(0xFF4B5C9E),
    frameShadow: Color(0xFF000000),
    shadeTarget: Color(0xFF000000),
    track: Color(0xFF0E1430),
    icon: Color(0xFFFFF1E8),
    ink: Color(0xFF000000),
    keyFace: Color(0xFF2E3D72),
    keyGlyph: Color(0xFFFFF1E8),
    keyPrimary: Color(0xFFFF004D),
    keyPrimaryGlyph: Color(0xFFFFF1E8),
  );

  static const pixelLight = GamePalette(
    isDark: false,
    skin: GameSkin.pixel,
    background: [Color(0xFFE9E2D2), Color(0xFFE9E2D2), Color(0xFFE9E2D2)],
    glows: [Color(0x00000000), Color(0x00000000), Color(0x00000000)],
    pattern: Color(0xFFE1D9C6),
    text: Color(0xFF1D2B53),
    muted: Color(0xFF4B5378),
    label: Color(0xFF7A7F99),
    glass: Color(0xFFFFF1E8),
    glassBorder: Color(0xFF1D2B53),
    glassShadow: Color(0xFF1D2B53),
    accent1: Color(0xFFFF004D),
    accent2: Color(0xFFFFA300),
    wellTop: Color(0xFF1D2B53),
    wellBottom: Color(0xFF1D2B53),
    grid: Color(0xFF22315C),
    frameFill: Color(0xFFFFF1E8),
    frameBorder: Color(0xFF1D2B53),
    frameShadow: Color(0xFF1D2B53),
    shadeTarget: Color(0xFF000000),
    track: Color(0xFFD9D0BD),
    icon: Color(0xFF1D2B53),
    ink: Color(0xFF1D2B53),
    keyFace: Color(0xFFFFF1E8),
    keyGlyph: Color(0xFF1D2B53),
    keyPrimary: Color(0xFFFF004D),
    keyPrimaryGlyph: Color(0xFFFFF1E8),
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
