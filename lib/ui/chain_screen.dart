import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/chain/chain_game.dart';
import '../game/chain/chain_controller.dart';
import '../game/chain/chain_painter.dart';
import '../game/render/background_painter.dart';
import '../game/sugar/sugar_art.dart' show LokumPose;
import '../l10n/strings.dart';
import '../platform/orientation_lock.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'lokum_wardrobe.dart';
import 'sugar_widgets.dart' show DancingLokum;
import 'widgets.dart';

const _chainColors = [Color(0xFFFF33EE), Color(0xFF3F6BFF), Color(0xFF1FE85A)];
const _hot = [Color(0xFFFFE21F), Color(0xFFFF8A10)];

/// "Zincir Küpler": swap neighbouring cubes, line up three of a colour, and
/// let falling cubes chain while the stack rises from below.
class ChainScreen extends StatefulWidget {
  const ChainScreen({super.key, required this.settings, required this.audio, this.haptics, required this.mode, this.resume = false});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;
  final ChainMode mode;

  /// Continue the saved game instead of showing the start panel.
  final bool resume;

  static Future<void> open(BuildContext context, {required Settings settings, required AudioService audio, Haptics? haptics, required ChainMode mode, bool resume = false}) =>
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => ChainScreen(settings: settings, audio: audio, haptics: haptics, mode: mode, resume: resume),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );

  @override
  State<ChainScreen> createState() => _ChainScreenState();
}

class _ChainScreenState extends State<ChainScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ChainController c = ChainController(settings: widget.settings, audio: widget.audio, haptics: widget.haptics, mode: widget.mode);
  late final Ticker _ticker = createTicker(c.tick);
  final FocusNode _focus = FocusNode();
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.resume) c.resumeSaved();
    _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locked) {
      _locked = true;
      OrientationLock.portrait(context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) c.pauseIfRunning();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    c.audio.duck = 1;
    c.dispose();
    super.dispose();
  }

  /// Back pauses a running game; otherwise it leaves.
  void _back() {
    if (c.playing && !c.paused) {
      c.togglePause();
    } else {
      _leave();
    }
  }

  void _leave() {
    c.saveProgress();
    if (mounted) Navigator.of(context).pop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    final key = e.logicalKey;
    final down = e is KeyDownEvent;
    final repeat = e is KeyRepeatEvent;
    if (key == LogicalKeyboardKey.shiftLeft || key == LogicalKeyboardKey.shiftRight || key == LogicalKeyboardKey.keyC) {
      if (down) c.raising = true;
      if (e is KeyUpEvent) c.raising = false;
      return KeyEventResult.handled;
    }
    if (!down && !repeat) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
      if (down) c.started && !c.game.isOver ? c.togglePause() : _back();
      return KeyEventResult.handled;
    }
    if (!c.started || c.game.isOver) {
      if (down && (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space)) c.start();
      return KeyEventResult.handled;
    }
    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        c.moveCursor(-1, 0);
      case LogicalKeyboardKey.arrowRight:
        c.moveCursor(1, 0);
      case LogicalKeyboardKey.arrowUp:
        c.moveCursor(0, -1);
      case LogicalKeyboardKey.arrowDown:
        c.moveCursor(0, 1);
      case LogicalKeyboardKey.space || LogicalKeyboardKey.keyX || LogicalKeyboardKey.enter:
        if (down) c.swapAtCursor();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    c.strings = AppStrings.of(context);
    final palette = GamePalette.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: palette.background.first,
          body: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: BackgroundBasePainter(palette))),
              SafeArea(
                child: ListenableBuilder(
                  listenable: c,
                  builder: (context, _) => Stack(
                    children: [
                      Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 10), child: _Play(c: c, onBack: _back)),
                      if (!c.started)
                        _StartPanel(c: c, onBack: _leave)
                      else if (c.paused)
                        _PausePanel(c: c, onMenu: _leave)
                      else if (c.showResult)
                        _OverPanel(c: c, onMenu: _leave),
                    ],
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

class _Play extends StatelessWidget {
  const _Play({required this.c, required this.onBack});

  final ChainController c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = c.settings;
    final brightness = Theme.of(context).brightness;
    final title = '${s.chainTitle} · ${c.mode == ChainMode.timeAttack ? s.chainTimeTitle : s.chainEndlessTitle}';
    return Column(
      children: [
        Row(
          children: [
            GlassIconButton(
              key: const ValueKey('chain-pause'),
              icon: c.playing ? Icons.pause_rounded : Icons.arrow_back_rounded,
              tooltip: c.playing ? s.pause : s.menu,
              onTap: onBack,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: GradientText(
                    title,
                    gradient: const LinearGradient(colors: _chainColors),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
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
          ],
        ),
        const SizedBox(height: 10),
        _Hud(c: c),
        const SizedBox(height: 10),
        Expanded(child: _Board(c: c)),
        const SizedBox(height: 8),
        // Lokum stands in the free corner left of the button, when there
        // is room for him.
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            width: box.maxWidth,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _RaiseButton(c: c),
                if (box.maxWidth >= 340) Positioned(left: 4, bottom: -4, child: _ChainLokum(c: c)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value, this.pulse = 0, this.colors, this.alert = false});

  final String label;
  final String value;
  final double pulse;
  final List<Color>? colors;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final style = TextStyle(fontSize: 24, height: 1.05, fontWeight: FontWeight.w900, color: alert ? const Color(0xFFF87171) : p.text, fontFeatures: const [FontFeature.tabularFigures()]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardLabel(label),
        const SizedBox(height: 2),
        Transform.scale(
          alignment: Alignment.centerLeft,
          scale: 1 + 0.18 * pulse,
          child: colors == null ? Text(value, style: style) : GradientText(value, gradient: LinearGradient(colors: colors!), style: style),
        ),
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.c});

  final ChainController c;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final g = c.game;
    final timeAttack = c.mode == ChainMode.timeAttack;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(child: _HudValue(label: s.scoreLabel, value: s.score(g.score), pulse: c.fx.scorePulse)),
          Expanded(
            child: _HudValue(
              label: s.chainLabel,
              value: g.chainCount > 1 ? '×${g.chainCount}' : '×${max(1, g.maxChain)}',
              pulse: c.fx.chainPulse,
              colors: g.chainCount > 1 ? _hot : null,
            ),
          ),
          Expanded(
            child: timeAttack
                ? _HudValue(label: s.timeLabel, value: s.clock(g.remaining), alert: g.started && g.remaining <= 10)
                : _HudValue(label: s.bestLabel, value: s.score(max(c.best, g.score))),
          ),
        ],
      ),
    );
  }
}

extension on ChainGame {
  bool get started => status != ChainStatus.ready;
}

class _Board extends StatelessWidget {
  const _Board({required this.c});

  final ChainController c;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final geometry = ChainGeometry(ChainGeometry.fit(box.biggest));
        Offset local(Offset p) => p - geometry.wellOrigin;
        return Center(
          child: Listener(
            key: const ValueKey('chain-board'),
            onPointerDown: (e) => c.touchDown(local(e.localPosition), geometry.cell),
            onPointerMove: (e) => c.touchMove(local(e.localPosition), geometry.cell),
            onPointerUp: (_) => c.touchUp(),
            onPointerCancel: (_) => c.touchUp(),
            child: CustomPaint(
              size: geometry.canvas,
              painter: ChainBoardPainter(c: c, palette: palette, geometry: geometry, dpr: dpr),
            ),
          ),
        );
      },
    );
  }
}

/// Lokum by the button: he cheers chains and frets near the top, without
/// words, so nothing on the board is covered.
class _ChainLokum extends StatelessWidget {
  const _ChainLokum({required this.c});

  final ChainController c;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ValueListenableBuilder(
      valueListenable: c.frame,
      builder: (context, _, _) => LokumView(
        key: const ValueKey('chain-lokum'),
        outfit: c.outfit,
        pose: c.lokum.pose,
        hop: c.lokum.hop(c.clock),
        beat: (c.clock / 0.9) % 1,
        size: 46,
      ),
    ),
  );
}

/// Hold to lift the stack faster (points for every row).
class _RaiseButton extends StatelessWidget {
  const _RaiseButton({required this.c});

  final ChainController c;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    return Listener(
      key: const ValueKey('chain-raise'),
      onPointerDown: (_) => c.raising = true,
      onPointerUp: (_) => c.raising = false,
      onPointerCancel: (_) => c.raising = false,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        radius: 18,
        glow: c.game.raising ? 1 : 0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_double_arrow_up_rounded, color: p.icon, size: 26),
            const SizedBox(width: 8),
            Text(s.chainRaise, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ panels --

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                radius: 26,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({required this.c, required this.onBack});

  final ChainController c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    Widget how(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: p.icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15, height: 1.25, color: p.text, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    return _Panel(
      children: [
        Center(
          child: GradientText(
            c.mode == ChainMode.timeAttack ? s.chainTimeTitle : s.chainTitle,
            gradient: const LinearGradient(colors: _chainColors),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 12),
        how(Icons.swap_horiz_rounded, s.chainHowSwap),
        how(Icons.auto_awesome_rounded, s.chainHowMatch),
        how(Icons.link_rounded, s.chainHowChain),
        if (c.difficulty.garbage && c.mode == ChainMode.endless) how(Icons.view_stream_rounded, s.chainHowGarbage),
        how(Icons.warning_amber_rounded, s.chainHowTop),
        if (desktop) how(Icons.keyboard_rounded, s.chainHowKeys),
        const SizedBox(height: 16),
        CardLabel(s.chainDifficulty),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final d in ChainDifficulty.values) ...[
              if (d != ChainDifficulty.values.first) const SizedBox(width: 8),
              Expanded(child: _DifficultyChip(c: c, difficulty: d)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          switch (c.difficulty) {
            ChainDifficulty.easy => s.chainEasyHint,
            ChainDifficulty.normal => s.chainNormalHint,
            ChainDifficulty.hard => s.chainHardHint,
          },
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: p.muted, fontWeight: FontWeight.w600),
        ),
        if (c.best > 0) ...[
          const SizedBox(height: 4),
          Text('${s.bestLabel}: ${s.score(c.best)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: p.muted, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        GradientButton(key: const ValueKey('chain-start'), label: s.chainStart, icon: Icons.play_arrow_rounded, colors: _chainColors, onTap: c.start),
        const SizedBox(height: 10),
        GradientButton(label: s.menu, icon: Icons.home_rounded, secondary: true, onTap: onBack),
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.c, required this.difficulty});

  final ChainController c;
  final ChainDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final selected = c.difficulty == difficulty;
    final label = switch (difficulty) {
      ChainDifficulty.easy => s.chainEasy,
      ChainDifficulty.normal => s.chainNormal,
      ChainDifficulty.hard => s.chainHard,
    };
    final tone = switch (difficulty) {
      ChainDifficulty.easy => const Color(0xFF1FE85A),
      ChainDifficulty.normal => const Color(0xFFFFE21F),
      ChainDifficulty.hard => const Color(0xFFFF4D6D),
    };
    return GestureDetector(
      key: ValueKey('chain-difficulty-${difficulty.name}'),
      onTap: () => c.setDifficulty(difficulty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? tone.withValues(alpha: 0.22) : p.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? tone : p.glassBorder, width: selected ? 2.5 : 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: selected ? p.text : p.muted),
        ),
      ),
    );
  }
}

class _PausePanel extends StatelessWidget {
  const _PausePanel({required this.c, required this.onMenu});

  final ChainController c;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    return _Panel(
      children: [
        Text(s.paused, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text)),
        const SizedBox(height: 18),
        GradientButton(key: const ValueKey('chain-resume'), label: s.resume, icon: Icons.play_arrow_rounded, colors: _chainColors, onTap: c.togglePause),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: GradientButton(label: s.restart, icon: Icons.replay_rounded, secondary: true, onTap: c.start)),
            const SizedBox(width: 10),
            Expanded(child: GradientButton(key: const ValueKey('chain-menu'), label: s.menu, icon: Icons.home_rounded, secondary: true, onTap: onMenu)),
          ],
        ),
      ],
    );
  }
}

class _OverPanel extends StatelessWidget {
  const _OverPanel({required this.c, required this.onMenu});

  final ChainController c;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final g = c.game;
    return _Panel(
      children: [
        Center(
          child: DancingLokum(outfit: c.outfit, size: 56, pose: c.newRecord ? LokumPose.dance : LokumPose.sad, moving: c.newRecord && c.settings.effects),
        ),
        Text(g.timeUp ? s.timeUp : s.gameOver, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text)),
        if (c.newRecord) ...[
          const SizedBox(height: 6),
          Center(child: GradientText(s.newRecord, gradient: const LinearGradient(colors: _hot), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        ],
        const SizedBox(height: 10),
        Center(
          child: GradientText(
            s.score(g.score),
            gradient: const LinearGradient(colors: _chainColors),
            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900, height: 1.1),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [if (g.maxChain > 1) s.chainLongest(g.maxChain), s.chainCubes(g.cleared)].join(' · '),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: p.muted, fontWeight: FontWeight.w700),
        ),
        Text('${s.bestLabel}: ${s.score(max(c.best, g.score))}', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        GradientButton(key: const ValueKey('chain-again'), label: s.playAgain, icon: Icons.replay_rounded, colors: _chainColors, onTap: c.start),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: GradientButton(label: s.chainDifficulty, icon: Icons.tune_rounded, secondary: true, onTap: c.backToStart)),
            const SizedBox(width: 10),
            Expanded(child: GradientButton(label: s.menu, icon: Icons.home_rounded, secondary: true, onTap: onMenu)),
          ],
        ),
      ],
    );
  }
}
