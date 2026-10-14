import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/audio_service.dart';
import '../core/tetris_game.dart';
import '../game/game_controller.dart';
import '../game/render/background_painter.dart';
import '../game/render/block_sprites.dart';
import '../game/render/board_painter.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'about_page.dart';
import 'board_view.dart';
import 'widgets.dart';

String formatScore(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

String formatTime(double seconds) {
  final s = seconds.floor();
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.settings, required this.audio});

  final Settings settings;
  final AudioService audio;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameController controller = GameController(settings: widget.settings, audio: widget.audio);
  late final Ticker _ticker = createTicker(controller.tick);
  final FocusNode _focus = FocusNode(debugLabel: 'game');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker.start();
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
  };

  bool _isGameKey(LogicalKeyboardKey key) => _gameKeys.contains(key);

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Scaffold(
      backgroundColor: palette.background.first,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
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
                      repaint: controller.frame,
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
    if (game.status == GameStatus.ready) return _StartOverlay(key: const ValueKey('start'), c: controller);
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
  Widget build(BuildContext context) => GlassCard(
    glow: c.fx.holdPulse,
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CardLabel('TUT'),
        const SizedBox(height: 4),
        PieceView(type: c.game.held, cell: cell, size: size, dimmed: !c.game.canHold, pop: c.fx.holdPulse),
      ],
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
          const CardLabel('SIRADAKİ'),
          const SizedBox(height: 4),
          for (var i = 0; i < count; i++)
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
        formatScore(c.game.score),
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
      return Center(
        child: BoardView(controller: c, cell: cell),
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
                tooltip: 'Tema',
                onTap: () => settings.toggleTheme(brightness),
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: settings.music ? Icons.music_note_rounded : Icons.music_off_rounded,
                tooltip: 'Müzik',
                onTap: () => settings.music = !settings.music,
              ),
              const SizedBox(width: 8),
              GlassIconButton(icon: Icons.pause_rounded, tooltip: 'Duraklat', onTap: c.togglePause),
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
                      children: [
                        const CardLabel('SKOR'),
                        _ScoreText(c: c, size: 26),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [_Stat('SEVİYE', '${c.game.level}'), const SizedBox(width: 14), _Stat('SATIR', '${c.game.lines}')],
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
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
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
                  const SizedBox(height: 16),
                  GlassCard(
                    glow: c.fx.levelPulse,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CardLabel('SKOR'),
                        const SizedBox(height: 4),
                        _ScoreText(c: c, size: 38),
                        const SizedBox(height: 8),
                        stat('Seviye', '${game.level}'),
                        stat('Satır', '${game.lines}'),
                        stat('Süre', formatTime(c.playTime)),
                        stat('En iyi', formatScore(settings.bestScore), accent: true),
                        stat('Mod', c.mode == GameMode.classic ? 'Klasik' : 'Rahat'),
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
                        const CardLabel('KONTROLLER'),
                        const SizedBox(height: 10),
                        key(['←', '→'], 'Sağa / sola'),
                        key(['↑', 'X'], 'Döndür'),
                        key(['Z'], 'Ters döndür'),
                        key(['↓'], 'Yumuşak düşüş'),
                        key(['Space'], 'Sert düşüş'),
                        key(['C'], 'Tut'),
                        key(['P', 'Esc'], 'Duraklat'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const CardLabel('AYARLAR'),
        const SizedBox(height: 10),
        ThemeSegment(isDark: isDark, onChanged: (dark) => settings.themeMode = dark ? ThemeMode.dark : ThemeMode.light),
        const SizedBox(height: 6),
        ToggleRow(
          label: 'Müzik',
          icon: compact ? null : Icons.music_note_rounded,
          value: settings.music,
          onChanged: (v) => settings.music = v,
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: p.accent1,
            inactiveTrackColor: p.track,
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(value: settings.musicVolume, onChanged: settings.music ? (v) => settings.musicVolume = v : null),
        ),
        ToggleRow(
          label: 'Efekt sesleri',
          icon: compact ? null : Icons.volume_up_rounded,
          value: settings.sfx,
          onChanged: (v) => settings.sfx = v,
        ),
        ToggleRow(
          label: 'Görsel efektler',
          icon: compact ? null : Icons.auto_awesome_rounded,
          value: settings.effects,
          onChanged: (v) => settings.effects = v,
        ),
        ToggleRow(
          label: 'Ekran sarsıntısı',
          icon: compact ? null : Icons.vibration_rounded,
          value: settings.shake,
          onChanged: (v) => settings.shake = v,
        ),
        ToggleRow(
          label: 'Titreşim',
          icon: compact ? null : Icons.smartphone_rounded,
          value: settings.vibration,
          onChanged: (v) => settings.vibration = v,
        ),
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
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ColoredBox(color: p.background.first.withValues(alpha: p.isDark ? 0.62 : 0.55)),
          ),
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
    final touch = Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS;
    return _OverlayShell(
      children: [
        const Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: LogoTitle(fontSize: 32)),
        ),
        const SizedBox(height: 8),
        Text(
          'Blokları diz, satırları patlat!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: p.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        if (c.settings.bestScore > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_rounded, color: const Color(0xFFFACC15), size: 20),
              const SizedBox(width: 6),
              Text(
                'En iyi: ',
                style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
              ),
              GradientText(formatScore(c.settings.bestScore), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 18),
        ],
        GradientButton(
          key: const ValueKey('start-classic'),
          label: 'Klasik',
          subtitle: 'Hız 10. seviyeye kadar yavaşça artar',
          icon: Icons.bolt_rounded,
          onTap: () => c.start(GameMode.classic),
        ),
        const SizedBox(height: 12),
        GradientButton(
          label: 'Rahat',
          subtitle: 'Sabit ve sakin hız, sonsuz oyun',
          icon: Icons.spa_rounded,
          secondary: true,
          onTap: () => c.start(GameMode.relaxed),
        ),
        const SizedBox(height: 18),
        Text(
          touch
              ? 'Dokun: döndür · Kaydır: taşı · Aşağı fırlat: düşür · Yukarı fırlat: tut'
              : '← → taşı · ↑ döndür · Space düşür · C tut · P duraklat',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: p.label, fontWeight: FontWeight.w600, height: 1.5),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => AboutPage.open(context),
          icon: Icon(Icons.info_outline_rounded, size: 16, color: p.muted),
          label: Text(
            'Hakkında',
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
    return _OverlayShell(
      children: [
        Text(
          'Duraklatıldı',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 18),
        GradientButton(label: 'Devam et', icon: Icons.play_arrow_rounded, onTap: c.togglePause),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientButton(label: 'Baştan', icon: Icons.replay_rounded, secondary: true, onTap: () => c.start()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(label: 'Menü', icon: Icons.home_rounded, secondary: true, onTap: c.toMenu),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsPanel(settings: c.settings),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => AboutPage.open(context),
          icon: Icon(Icons.info_outline_rounded, size: 16, color: p.muted),
          label: Text(
            'Hakkında',
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
          'Oyun Bitti',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 10),
        if (c.newRecord)
          const Center(
            child: GradientText(
              '★ YENİ REKOR! ★',
              gradient: LinearGradient(colors: [Color(0xFFFDE047), Color(0xFFF97316)]),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
        const SizedBox(height: 6),
        Center(
          child: GradientText(formatScore(game.score), style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 14),
        Row(children: [stat('SEVİYE', '${game.level}'), stat('SATIR', '${game.lines}'), stat('SÜRE', formatTime(c.playTime))]),
        const SizedBox(height: 10),
        Text(
          'En iyi: ${formatScore(c.settings.bestScore)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        GradientButton(label: 'Tekrar oyna', icon: Icons.replay_rounded, onTap: () => c.start()),
        const SizedBox(height: 10),
        GradientButton(label: 'Ana menü', icon: Icons.home_rounded, secondary: true, onTap: c.toMenu),
      ],
    );
  }
}
