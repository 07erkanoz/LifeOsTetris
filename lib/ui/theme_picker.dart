import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/tetromino.dart';
import '../game/render/block_sprites.dart';
import '../l10n/strings.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';

/// A row of theme cards, each previewing its blocks on its own backdrop.
class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key, required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    return Row(
      children: [
        for (final (i, theme) in VisualTheme.values.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ThemeCard(
              key: ValueKey('theme-${theme.name}'),
              theme: theme,
              label: s.themeName(theme),
              selected: settings.visualTheme == theme,
              dark: p.isDark,
              onTap: () => settings.visualTheme = theme,
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({super.key, required this.theme, required this.label, required this.selected, required this.dark, required this.onTap});

  final VisualTheme theme;
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final ring = selected ? p.accent1 : (p.flat ? p.ink : p.glassBorder);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 2 : 14),
                border: Border.all(color: ring, width: selected ? 3 : (p.flat ? 2 : 1.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 0 : 10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _ThemePreviewPainter(theme: theme, dark: dark, dpr: MediaQuery.devicePixelRatioOf(context)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: fontFamilyOf(theme.skin),
                  // Each name in its own typeface; pixel type runs small.
                  fontSize: theme.skin == GameSkin.pixel ? 17 : 12.5,
                  fontWeight: theme.skin == GameSkin.pixel ? FontWeight.w400 : FontWeight.w800,
                  color: selected ? p.text : p.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small stack of blocks on the theme's own background.
class _ThemePreviewPainter extends CustomPainter {
  _ThemePreviewPainter({required this.theme, required this.dark, required this.dpr});

  final VisualTheme theme;
  final bool dark;
  final double dpr;

  static const _cells = [
    (1, 0, PieceType.t),
    (0, 1, PieceType.t),
    (1, 1, PieceType.t),
    (2, 1, PieceType.t),
    (0, 2, PieceType.i),
    (1, 2, PieceType.z),
    (2, 2, PieceType.o),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final palette = dark ? GamePalette.darkOf(theme.skin) : GamePalette.lightOf(theme.skin);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.background.first);
    if (theme.skin == GameSkin.glass) {
      final glow = palette.glows[1];
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(Offset(size.width * 0.2, size.height * 0.1), size.width, [
            glow.withValues(alpha: min(1, glow.a * 3)),
            glow.withValues(alpha: 0),
          ]),
      );
    }
    final cell = size.width * 0.27;
    final origin = Offset((size.width - cell * 3) / 2, size.height - cell * 3 - size.height * 0.08);
    final colors = blockColorsOf(theme.skin);
    for (final (x, y, type) in _cells) {
      final o = origin + Offset(x * cell, y * cell);
      paintSkinBlock(canvas, o, cell, colors[type]!, palette, hd: theme.hd);
    }
  }

  @override
  bool shouldRepaint(covariant _ThemePreviewPainter old) => old.theme != theme || old.dark != dark;
}
