import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/puzzle_generator.dart';
import '../core/tetris_game.dart';
import '../game/game_controller.dart';
import '../game/motivation.dart';
import '../l10n/strings.dart';
import '../game/render/background_painter.dart';
import '../game/render/block_sprites.dart';
import '../game/render/board_painter.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'about_page.dart';
import 'board_view.dart';
import 'power_bar.dart';
import 'widgets.dart';

String formatTime(double seconds) {
  final s = seconds.floor();
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.settings, required this.audio, this.haptics});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameController controller = GameController(settings: widget.settings, audio: widget.audio, haptics: widget.haptics);
  late final Ticker _ticker = createTicker(controller.tick);
  final FocusNode _focus = FocusNode(debugLabel: 'game');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker.start();
    if (GameController.demoLevels) controller.showLevelSelect = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) controller.pauseIfRunning();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    controller.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final c = controller;
    if (event is KeyRepeatEvent) {
      // Auto-repeat is handled by the controller's DAS/ARR.
      return _isGameKey(key) ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    final down = event is KeyDownEvent;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      down ? c.pressLeft() : c.releaseLeft();
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      down ? c.pressRight() : c.releaseRight();
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      c.softDrop(down);
    } else if (!down) {
      return _isGameKey(key) ? KeyEventResult.handled : KeyEventResult.ignored;
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyX || key == LogicalKeyboardKey.keyW) {
      c.rotateCw();
    } else if (key == LogicalKeyboardKey.keyZ || key == LogicalKeyboardKey.controlLeft) {
      c.rotateCcw();
    } else if (key == LogicalKeyboardKey.space) {
      c.hardDrop();
    } else if (key == LogicalKeyboardKey.keyC || key == LogicalKeyboardKey.shiftLeft) {
      c.hold();
    } else if (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.escape) {
      c.togglePause();
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.digit3) {
      c.usePower(key == LogicalKeyboardKey.digit1 ? 0 : (key == LogicalKeyboardKey.digit2 ? 1 : 2));
    } else if (key == LogicalKeyboardKey.enter) {
      if (c.game.status == GameStatus.ready || c.game.status == GameStatus.over) c.start();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  static final _gameKeys = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.keyZ,
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyP,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
  };

  bool _isGameKey(LogicalKeyboardKey key) => _gameKeys.contains(key);

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    controller.strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: palette.background.first,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(child: CustomPaint(painter: BackgroundBasePainter(palette))),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: ListenableBuilder(
                  listenable: widget.settings,
                  builder: (context, _) => CustomPaint(
                    painter: BackgroundPainter(
                      fx: controller.fx,
                      palette: palette,
                      sprites: BlockSprites.of(24, dpr, palette),
                      effectsEnabled: widget.settings.effects,
                      repaint: controller.backgroundFrame,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: ListenableBuilder(
                listenable: Listenable.merge([controller, widget.settings]),
                builder: (context, _) => LayoutBuilder(
                  builder: (context, box) {
                    final wide = box.maxWidth >= 640 && box.maxWidth > box.maxHeight * 1.05;
                    return wide ? _DesktopLayout(c: controller) : _PhoneLayout(c: controller);
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: ListenableBuilder(
                listenable: Listenable.merge([controller, widget.settings]),
                builder: (context, _) => AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _overlay()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlay() {
    final game = controller.game;
    if (controller.showLevelSelect) return _LevelSelectOverlay(key: const ValueKey('levels'), c: controller);
    if (game.status == GameStatus.ready) return _StartOverlay(key: const ValueKey('start'), c: controller);
    if (controller.showPuzzleResult) return _PuzzleResultOverlay(key: ValueKey('puzzle-${game.puzzleSolved}'), c: controller);
    if (controller.showGameOver) return _GameOverOverlay(key: const ValueKey('over'), c: controller);
    if (game.paused) return _PauseOverlay(key: const ValueKey('pause'), c: controller);
    return const SizedBox.shrink(key: ValueKey('none'));
  }
}

// ---------------------------------------------------------------- HUD parts

class _HoldCard extends StatelessWidget {
  const _HoldCard({required this.c, required this.cell, required this.size});

  final GameController c;
  final double cell;
  final Size size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: AppStrings.of(context).holdTapHint,
    child: GestureDetector(
      // Tapping the card holds the current piece, so the game is fully
      // playable without the on-screen buttons.
      behavior: HitTestBehavior.opaque,
      onTap: c.hold,
      child: GlassCard(
        glow: c.fx.holdPulse,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: CardLabel(AppStrings.of(context).hold)),
                const SizedBox(width: 3),
                Icon(Icons.touch_app_rounded, size: 11, color: GamePalette.of(context).label),
              ],
            ),
            const SizedBox(height: 4),
            PieceView(type: c.game.held, cell: cell, size: size, dimmed: !c.game.canHold, pop: c.fx.holdPulse),
          ],
        ),
      ),
    ),
  );
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.c, required this.cell, required this.size, this.count = 1});

  final GameController c;
  final double cell;
  final Size size;
  final int count;

  @override
  Widget build(BuildContext context) {
    final preview = c.game.preview;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardLabel(AppStrings.of(context).next),
          const SizedBox(height: 4),
          for (var i = 0; i < min(count, preview.length); i++)
            Opacity(
              opacity: i == 0 ? 1 : 0.75,
              child: PieceView(
                type: preview[i],
                cell: i == 0 ? cell : cell * 0.72,
                size: i == 0 ? size : Size(size.width, size.height * 0.72),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        CardLabel(label),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.text, fontFeatures: const [ui.FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}

class _ScoreText extends StatelessWidget {
  const _ScoreText({required this.c, required this.size});

  final GameController c;
  final double size;

  @override
  Widget build(BuildContext context) => Transform.scale(
    alignment: Alignment.centerLeft,
    scale: 1 + 0.08 * c.fx.scorePulse,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        AppStrings.of(context).score(c.game.score),
        style: TextStyle(
          fontSize: size,
          height: 1.05,
          fontWeight: FontWeight.w900,
          color: GamePalette.of(context).text,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

class _BoardArea extends StatelessWidget {
  const _BoardArea({required this.c, this.padding = 12});

  final GameController c;
  final double padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cell = BoardGeometry.fit(Size(box.maxWidth - 2 * padding, box.maxHeight - 2 * padding));
      if (cell <= 4) return const SizedBox.shrink();
      return Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: BoardView(controller: c, cell: cell),
          ),
          Positioned(top: 4, left: 8, right: 8, child: _MotivationBanner(c: c)),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------- layouts

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final settings = c.settings;
    final brightness = Theme.of(context).brightness;
    final s = AppStrings.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              const Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: LogoTitle()),
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                tooltip: s.theme,
                onTap: () => settings.toggleTheme(brightness),
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: settings.music ? Icons.music_note_rounded : Icons.music_off_rounded,
                tooltip: s.music,
                onTap: () => settings.music = !settings.music,
              ),
              const SizedBox(width: 8),
              GlassIconButton(icon: Icons.pause_rounded, tooltip: s.pause, onTap: c.togglePause),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 84,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 78,
                  child: _HoldCard(c: c, cell: 13, size: const Size(62, 42)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    glow: c.fx.levelPulse,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: c.game.mode == GameMode.puzzle
                          ? _puzzleStats(context, c)
                          : [
                              CardLabel(s.scoreLabel),
                              _ScoreText(c: c, size: 26),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    _Stat(s.levelLabel, '${c.game.level}'),
                                    const SizedBox(width: 14),
                                    _Stat(s.linesLabel, '${c.game.lines}'),
                                  ],
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 78,
                  child: _NextCard(c: c, cell: 14, size: const Size(62, 42)),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _BoardArea(c: c, padding: 10)),
        if (c.game.powersEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: PowerBar(c: c, slotSize: 42),
          ),
        if (settings.showButtons)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
            child: Opacity(
              opacity: settings.buttonOpacity,
              child: LayoutBuilder(
                builder: (context, box) {
                  // Four regular buttons, one larger primary one, even gaps.
                  final size = ((box.maxWidth - 4 * 10) / 5.25).clamp(44.0, 62.0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ControlButton(glyph: ControlGlyph.hold, size: size, onDown: c.hold),
                      ControlButton(glyph: ControlGlyph.left, size: size, onDown: c.pressLeft, onUp: c.releaseLeft),
                      ControlButton(glyph: ControlGlyph.rotate, size: size * 1.22, onDown: c.rotateCw, primary: true),
                      ControlButton(glyph: ControlGlyph.right, size: size, onDown: c.pressRight, onUp: c.releaseRight),
                      ControlButton(glyph: ControlGlyph.drop, size: size, onDown: c.hardDrop),
                    ],
                  );
                },
              ),
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final side = (width * 0.2).clamp(210.0, 280.0);
    final game = c.game;
    final settings = c.settings;
    final s = AppStrings.of(context);

    TextStyle k() => TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted);
    Widget stat(String label, String value, {bool accent = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: k())),
          accent
              ? GradientText(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  ),
                ),
        ],
      ),
    );

    Widget key(List<String> keys, String action) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 96, child: Wrap(spacing: 4, children: [for (final k in keys) _Kbd(k)])),
          Expanded(child: Text(action, style: k())),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: side,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 6, 0, 16),
                    child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: LogoTitle(fontSize: 26)),
                  ),
                  _HoldCard(c: c, cell: 22, size: const Size(120, 52)),
                  if (game.powersEnabled) ...[const SizedBox(height: 16), PowerBar(c: c, slotSize: 40, showKeys: true)],
                  const SizedBox(height: 16),
                  GlassCard(
                    glow: c.fx.levelPulse,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: game.mode == GameMode.puzzle
                          ? [
                              CardLabel(s.puzzleLabel),
                              const SizedBox(height: 4),
                              GradientText('${c.puzzle?.number ?? ''}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              stat(s.gemsLeftLabel, '${game.gemsLeft}', accent: true),
                              stat(s.piecesLeftLabel, '${game.piecesLeft + (game.active != null ? 1 : 0)}'),
                              stat(s.chapter(c.puzzle?.chapter ?? 1), '★' * settings.puzzleStars(c.puzzle?.number ?? 0)),
                            ]
                          : [
                              CardLabel(s.scoreLabel),
                              const SizedBox(height: 4),
                              _ScoreText(c: c, size: 38),
                              const SizedBox(height: 8),
                              stat(s.level, '${game.level}'),
                              stat(s.lines, '${game.lines}'),
                              stat(s.time, formatTime(c.playTime)),
                              stat(s.best, s.score(settings.bestScore(c.mode)), accent: true),
                              stat(s.mode, s.modeName(c.mode)),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _BoardArea(c: c, padding: 16)),
          SizedBox(
            width: side,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NextCard(c: c, cell: 22, size: const Size(120, 60), count: 4),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CardLabel(s.controlsLabel),
                        const SizedBox(height: 10),
                        key(['←', '→'], s.moveLeftRight),
                        key(['↑', 'X'], s.rotate),
                        key(['Z'], s.rotateBack),
                        key(['↓'], s.softDrop),
                        key(['Space'], s.hardDrop),
                        key(['C'], s.holdAction),
                        key(['P', 'Esc'], s.pause),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: _SettingsPanel(settings: settings, compact: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kbd extends StatelessWidget {
  const _Kbd(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      constraints: const BoxConstraints(minWidth: 28),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0x10FFFFFF) : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: p.isDark ? const Color(0x1FFFFFFF) : const Color(0xFFDFE4EE)),
        boxShadow: [BoxShadow(color: p.isDark ? const Color(0x80000000) : const Color(0xFFD5DBE7), offset: const Offset(0, 2))],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.text),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.settings, this.compact = false});

  final Settings settings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget slider(double value, double min, double max, ValueChanged<double>? onChanged) => SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 5,
        activeTrackColor: p.accent1,
        inactiveTrackColor: p.track,
        thumbColor: Colors.white,
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CardLabel(s.settingsLabel),
        const SizedBox(height: 10),
        ThemeSegment(
          isDark: isDark,
          lightLabel: s.light,
          darkLabel: s.dark,
          onChanged: (dark) => settings.themeMode = dark ? ThemeMode.dark : ThemeMode.light,
        ),
        const SizedBox(height: 8),
        LanguageSegment(isTurkish: s.isTurkish, onChanged: (tr) => settings.language = tr ? AppLanguage.tr : AppLanguage.en),
        const SizedBox(height: 6),
        ToggleRow(
          label: s.music,
          icon: compact ? null : Icons.music_note_rounded,
          value: settings.music,
          onChanged: (v) => settings.music = v,
        ),
        slider(settings.musicVolume, 0, 1, settings.music ? (v) => settings.musicVolume = v : null),
        ToggleRow(
          label: s.soundEffects,
          icon: compact ? null : Icons.volume_up_rounded,
          value: settings.sfx,
          onChanged: (v) => settings.sfx = v,
        ),
        ToggleRow(
          label: s.visualEffects,
          icon: compact ? null : Icons.auto_awesome_rounded,
          value: settings.effects,
          onChanged: (v) => settings.effects = v,
        ),
        ToggleRow(
          label: s.screenShake,
          icon: compact ? null : Icons.vibration_rounded,
          value: settings.shake,
          onChanged: (v) => settings.shake = v,
        ),
        ToggleRow(
          label: s.vibration,
          icon: compact ? null : Icons.smartphone_rounded,
          value: settings.vibration,
          onChanged: (v) => settings.vibration = v,
        ),
        if (!compact) ...[
          ToggleRow(
            label: s.onScreenButtons,
            icon: Icons.gamepad_rounded,
            value: settings.showButtons,
            onChanged: (v) => settings.showButtons = v,
          ),
          if (settings.showButtons) ...[
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                s.buttonOpacity,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.label),
              ),
            ),
            Row(
              children: [
                Expanded(child: slider(settings.buttonOpacity, 0.15, 1, (v) => settings.buttonOpacity = v)),
                const SizedBox(width: 10),
                // Live preview: the real buttons are hidden behind this screen.
                Opacity(
                  opacity: settings.buttonOpacity,
                  child: const IgnorePointer(
                    child: Row(
                      children: [
                        ControlButton(glyph: ControlGlyph.left, size: 34),
                        SizedBox(width: 6),
                        ControlButton(glyph: ControlGlyph.rotate, size: 38, primary: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- overlays

class _OverlayShell extends StatelessWidget {
  const _OverlayShell({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Stack(
      children: [
        // A plain scrim instead of a backdrop blur: blurring the animated
        // game every frame made these screens stutter on phones.
        Positioned.fill(
          child: ColoredBox(color: p.background.first.withValues(alpha: p.isDark ? 0.84 : 0.8)),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassCard(
                  radius: 28,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartOverlay extends StatelessWidget {
  const _StartOverlay({super.key, required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final touch = Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS;
    return _OverlayShell(
      children: [
        const Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: LogoTitle(fontSize: 32)),
        ),
        const SizedBox(height: 8),
        Text(
          s.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: p.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        if (c.settings.topScore > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_rounded, color: const Color(0xFFFACC15), size: 20),
              const SizedBox(width: 6),
              Text(
                s.bestPrefix,
                style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
              ),
              GradientText(s.score(c.settings.topScore), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 18),
        ],
        Stack(
          clipBehavior: Clip.none,
          children: [
            GradientButton(
              key: const ValueKey('start-super'),
              label: s.superTitle,
              subtitle: s.superSubtitle,
              icon: Icons.auto_awesome_rounded,
              colors: const [Color(0xFFA855F7), Color(0xFF6366F1), Color(0xFF38BDF8)],
              onTap: () => c.start(GameMode.superMode),
            ),
            Positioned(
              top: -9,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFFFDE047), Color(0xFFF97316)]),
                  boxShadow: const [BoxShadow(color: Color(0x66F97316), blurRadius: 10)],
                ),
                child: Text(
                  s.newBadge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF3B1D00), letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GradientButton(
          key: const ValueKey('start-puzzle'),
          label: s.puzzleTitle,
          subtitle: s.puzzleSubtitle,
          icon: Icons.extension_rounded,
          colors: const [Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFEAB308)],
          onTap: c.openLevelSelect,
        ),
        const SizedBox(height: 16),
        Center(child: CardLabel(s.classicTitle.toUpperCase())),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                key: const ValueKey('start-classic'),
                label: s.normal,
                subtitle: s.normalSubtitle,
                icon: Icons.bolt_rounded,
                secondary: true,
                onTap: () => c.start(GameMode.classic),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(
                label: s.relaxed,
                subtitle: s.relaxedShort,
                icon: Icons.spa_rounded,
                secondary: true,
                onTap: () => c.start(GameMode.relaxed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          touch ? s.touchHint : s.keyboardHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: p.label, fontWeight: FontWeight.w600, height: 1.5),
        ),
        const SizedBox(height: 14),
        LanguageSegment(isTurkish: s.isTurkish, onChanged: (tr) => c.settings.language = tr ? AppLanguage.tr : AppLanguage.en),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => AboutPage.open(context, c.settings),
          icon: Icon(Icons.info_outline_rounded, size: 16, color: p.muted),
          label: Text(
            s.about,
            style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({super.key, required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    return _OverlayShell(
      children: [
        Text(
          s.paused,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 18),
        GradientButton(label: s.resume, icon: Icons.play_arrow_rounded, onTap: c.togglePause),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientButton(label: s.restart, icon: Icons.replay_rounded, secondary: true, onTap: () => c.start()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(label: s.menu, icon: Icons.home_rounded, secondary: true, onTap: c.toMenu),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsPanel(settings: c.settings),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => AboutPage.open(context, c.settings),
          icon: Icon(Icons.info_outline_rounded, size: 16, color: p.muted),
          label: Text(
            s.about,
            style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({super.key, required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final game = c.game;
    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          CardLabel(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
          ),
        ],
      ),
    );
    return _OverlayShell(
      children: [
        Text(
          s.gameOver,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 10),
        if (c.newRecord)
          Center(
            child: GradientText(
              s.newRecord,
              gradient: const LinearGradient(colors: [Color(0xFFFDE047), Color(0xFFF97316)]),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
        const SizedBox(height: 6),
        Center(
          child: GradientText(s.score(game.score), style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [stat(s.levelLabel, '${game.level}'), stat(s.linesLabel, '${game.lines}'), stat(s.timeLabel, formatTime(c.playTime))],
        ),
        const SizedBox(height: 10),
        Text(
          '${s.bestPrefix}${s.score(c.settings.bestScore(c.mode))}',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        GradientButton(label: s.playAgain, icon: Icons.replay_rounded, onTap: () => c.start()),
        const SizedBox(height: 10),
        GradientButton(label: s.mainMenu, icon: Icons.home_rounded, secondary: true, onTap: c.toMenu),
      ],
    );
  }
}

/// Slides in from the top of the board with a short cheer.
class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner({required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    if (c.game.ghostLine != null) return const IgnorePointer(child: _GhostLineHint());
    if (c.game.mode == GameMode.puzzle && c.game.status == GameStatus.playing && c.playTime < 4) {
      return IgnorePointer(
        child: _InfoPill(text: AppStrings.of(context).puzzleGoal, icon: Icons.star_rounded, color: const Color(0xFFFBBF24)),
      );
    }
    final m = c.motivation.visible ? c.motivation.current : null;
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.8), end: Offset.zero).animate(animation),
            child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(animation), child: child),
          ),
        ),
        child: m == null ? const SizedBox.shrink(key: ValueKey(0)) : _BannerPill(key: ValueKey(m.id), motivation: m),
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  const _BannerPill({super.key, required this.motivation});

  final Motivation motivation;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final (IconData icon, List<Color> colors) = switch (motivation.kind) {
      MotivationKind.newBest || MotivationKind.scoreMilestone => (Icons.emoji_events_rounded, const [Color(0xFFFDE047), Color(0xFFF97316)]),
      MotivationKind.combo ||
      MotivationKind.backToBack => (Icons.local_fire_department_rounded, const [Color(0xFFF97316), Color(0xFFEF4444)]),
      MotivationKind.maxSpeed || MotivationKind.firstQuad => (Icons.bolt_rounded, const [Color(0xFFA855F7), Color(0xFF6366F1)]),
      MotivationKind.closeCall => (Icons.favorite_rounded, const [Color(0xFF22C55E), Color(0xFF14B8A6)]),
      MotivationKind.linesMilestone => (Icons.layers_rounded, const [Color(0xFF22D3EE), Color(0xFF3B82F6)]),
      MotivationKind.praise => (Icons.star_rounded, [p.accent1, p.accent2]),
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(colors: colors),
          boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 6))],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: p.isDark ? const Color(0xF0111630) : const Color(0xF7FFFFFF),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: colors),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  motivation.text(s),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostLineHint extends StatelessWidget {
  const _GhostLineHint();

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: p.isDark ? const Color(0xF0111630) : const Color(0xF7FFFFFF),
          border: Border.all(color: const Color(0xFFA855F7), width: 1.6),
          boxShadow: const [BoxShadow(color: Color(0x66A855F7), blurRadius: 20)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_rounded, size: 18, color: Color(0xFFC084FC)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                s.ghostLineHint,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: p.isDark ? const Color(0xF0111630) : const Color(0xF7FFFFFF),
          border: Border.all(color: color, width: 1.6),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Puzzle HUD for the phone's middle card: puzzle number, gems and pieces left.
List<Widget> _puzzleStats(BuildContext context, GameController c) {
  final s = AppStrings.of(context);
  final p = GamePalette.of(context);
  final game = c.game;
  final pieces = game.piecesLeft + (game.active != null ? 1 : 0);
  return [
    CardLabel('${s.puzzleLabel} ${c.puzzle?.number ?? ''}'),
    Row(
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 24),
        const SizedBox(width: 4),
        Text(
          '${game.gemsLeft}',
          style: TextStyle(fontSize: 24, height: 1.05, fontWeight: FontWeight.w900, color: p.text),
        ),
      ],
    ),
    FittedBox(fit: BoxFit.scaleDown, child: _Stat(s.piecesLeftLabel, '$pieces')),
  ];
}

class _LevelSelectOverlay extends StatelessWidget {
  const _LevelSelectOverlay({super.key, required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final settings = c.settings;
    final unlocked = settings.unlockedPuzzle;
    const chapters = PuzzleGenerator.levelCount ~/ PuzzleGenerator.levelsPerChapter;

    return _OverlayShell(
      children: [
        Row(
          children: [
            GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: s.back, onTap: c.closeLevelSelect, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: GradientText(
                  s.puzzleTitle,
                  gradient: const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFFEAB308)]),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 20),
            const SizedBox(width: 2),
            Text(
              '${settings.totalPuzzleStars}/${PuzzleGenerator.levelCount * 3}',
              style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          s.puzzleGoal,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: p.muted, fontWeight: FontWeight.w600),
        ),
        Text(
          s.starsHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: p.label, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        for (var ch = 1; ch <= chapters; ch++) ...[
          Padding(padding: const EdgeInsets.fromLTRB(2, 8, 0, 8), child: CardLabel(s.chapter(ch).toUpperCase())),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: [
              for (var n = (ch - 1) * PuzzleGenerator.levelsPerChapter + 1; n <= ch * PuzzleGenerator.levelsPerChapter; n++)
                _LevelTile(
                  number: n,
                  stars: settings.puzzleStars(n),
                  locked: n > unlocked,
                  current: n == unlocked,
                  onTap: () => c.startPuzzle(n),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.number, required this.stars, required this.locked, required this.current, required this.onTap});

  final int number;
  final int stars;
  final bool locked;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final tile = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: current ? const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF22C55E)]) : null,
        color: current ? null : (locked ? p.track.withValues(alpha: 0.5) : p.glass),
        border: Border.all(color: stars > 0 ? const Color(0xFFFBBF24).withValues(alpha: 0.7) : p.glassBorder),
        boxShadow: current ? const [BoxShadow(color: Color(0x6614B8A6), blurRadius: 14)] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          locked
              ? Icon(Icons.lock_rounded, size: 18, color: p.label)
              : Text(
                  '$number',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: current ? Colors.white : p.text),
                ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Icon(Icons.star_rounded, size: 11, color: i < stars ? const Color(0xFFFBBF24) : (current ? Colors.white54 : p.track)),
            ],
          ),
        ],
      ),
    );
    if (locked) return Tooltip(message: s.locked, child: tile);
    return GestureDetector(onTap: onTap, child: tile);
  }
}

class _PuzzleResultOverlay extends StatelessWidget {
  const _PuzzleResultOverlay({super.key, required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final solved = c.game.puzzleSolved;
    final number = c.puzzle?.number ?? 1;
    final isLast = number >= PuzzleGenerator.levelCount;
    return _OverlayShell(
      children: [
        Center(child: CardLabel(s.puzzleNumber(number).toUpperCase())),
        const SizedBox(height: 8),
        Text(
          solved ? s.puzzleSolvedTitle : s.puzzleFailedTitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 12),
        if (solved)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == 1 ? 10 : 0),
                  child: Icon(
                    Icons.star_rounded,
                    size: i == 1 ? 64 : 50,
                    color: i < c.lastPuzzleStars ? const Color(0xFFFBBF24) : p.track,
                    shadows: i < c.lastPuzzleStars ? const [Shadow(color: Color(0x99F59E0B), blurRadius: 18)] : null,
                  ),
                ),
            ],
          )
        else
          Text(
            s.puzzleFailedHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, height: 1.4),
          ),
        const SizedBox(height: 20),
        if (solved && !isLast) ...[
          GradientButton(
            key: const ValueKey('next-puzzle'),
            label: s.nextPuzzle,
            icon: Icons.arrow_forward_rounded,
            colors: const [Color(0xFF14B8A6), Color(0xFF22C55E)],
            onTap: c.nextPuzzle,
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: GradientButton(label: s.tryAgain, icon: Icons.replay_rounded, secondary: solved, onTap: c.retryPuzzle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(label: s.newBoard, icon: Icons.casino_rounded, secondary: true, onTap: () => c.startPuzzle(number)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GradientButton(label: s.levelsLabel, icon: Icons.grid_view_rounded, secondary: true, onTap: c.openLevelSelect),
      ],
    );
  }
}
