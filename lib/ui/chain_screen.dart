import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/chain/chain_game.dart';
import '../core/chain/chain_missions.dart';
import '../core/chain/chain_puzzles.dart';
import '../core/chain/chain_versus.dart';
import '../game/sugar/istanbul_art.dart' show paintEksiLimon;
import '../core/rewards.dart';
import '../game/chain/chain_controller.dart';
import '../game/chain/chain_painter.dart';
import '../game/chain/chain_sprites.dart' show chainColors, paintChainCube;
import '../game/render/background_painter.dart';
import '../game/sugar/sugar_art.dart' show LokumOutfit, LokumPose;
import '../l10n/strings.dart';
import '../platform/orientation_lock.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'lokum_wardrobe.dart';
import 'sugar_widgets.dart' show DancingLokum, sugarBoosterName;
import 'widgets.dart';

const _chainColors = [Color(0xFFFF33EE), Color(0xFF3F6BFF), Color(0xFF1FE85A)];
const _hot = [Color(0xFFFFE21F), Color(0xFFFF8A10)];

/// "Zincir Küpler": swap neighbouring cubes, line up three of a colour, and
/// let falling cubes chain while the stack rises from below.
class ChainScreen extends StatefulWidget {
  const ChainScreen({super.key, required this.settings, required this.audio, this.haptics, required this.mode, this.resume = false, this.puzzle, this.mission});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;
  final ChainMode mode;

  /// Continue the saved game instead of showing the start panel.
  final bool resume;

  /// A puzzle to play (its number), a ferry-line mission, or both.
  final int? puzzle;
  final ChainMission? mission;

  static Future<void> open(
    BuildContext context, {
    required Settings settings,
    required AudioService audio,
    Haptics? haptics,
    required ChainMode mode,
    bool resume = false,
    int? puzzle,
    ChainMission? mission,
  }) => Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => ChainScreen(settings: settings, audio: audio, haptics: haptics, mode: mode, resume: resume, puzzle: puzzle, mission: mission),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  State<ChainScreen> createState() => _ChainScreenState();
}

class _ChainScreenState extends State<ChainScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late ChainController c = _controller(widget.puzzle, widget.mission);

  ChainController _controller(int? puzzle, ChainMission? mission) =>
      ChainController(settings: widget.settings, audio: widget.audio, haptics: widget.haptics, mode: widget.mode, puzzle: puzzle, mission: mission);

  /// The next puzzle (or the next mission on the same screen kind).
  void _next() {
    final old = c;
    final p = c.puzzle, m = c.mission;
    if (m != null) {
      if (m.number >= ChainMissions.count) return _leave();
      final next = ChainMissions.of(m.number + 1);
      // A match mission plays on its own screen: back to the map for it.
      if (next.kind == MissionKind.versus) return _leave();
      c = _controller(next.kind == MissionKind.puzzle ? next.target : null, next);
    } else if (p != null && p < ChainPuzzles.count) {
      c = _controller(p + 1, null);
    } else {
      return _leave();
    }
    setState(() {});
    c.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }
  late final Ticker _ticker = createTicker((d) => c.tick(d));
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
                        c.mode == ChainMode.puzzle || c.mode == ChainMode.mission ? _GoalPanel(c: c, onMenu: _leave, onNext: _next) : _OverPanel(c: c, onMenu: _leave),
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
    final title = switch (c.mode) {
      ChainMode.puzzle when c.mission == null => '${s.chainPuzzlesTitle} · ${c.puzzle}',
      ChainMode.puzzle || ChainMode.mission => '${s.chainMissionsTitle} · ${ChainMissions.piers[ChainMissions.pierOf(c.mission!.number)]}',
      ChainMode.timeAttack => '${s.chainTitle} · ${s.chainTimeTitle}',
      _ => '${s.chainTitle} · ${s.chainEndlessTitle}',
    };
    // On a wide window the bar and the board keep together in the middle.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
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
        if (c.mode == ChainMode.puzzle) _PuzzleButtons(c: c) else
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
                if (box.maxWidth >= 340 && c.settings.unlocked(Unlock.freeze)) Positioned(right: 0, child: _FreezeButton(c: c)),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value, this.pulse = 0, this.colors, this.alert = false, this.small = false});

  final String label;
  final String value;
  final double pulse;
  final List<Color>? colors;
  final bool alert;

  /// A line of words rather than a number.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final style = TextStyle(
      fontSize: small ? 15 : 24,
      height: small ? 1.2 : 1.05,
      fontWeight: small ? FontWeight.w800 : FontWeight.w900,
      color: alert ? const Color(0xFFF87171) : p.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
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
    final m = c.mission;
    if (c.mode == ChainMode.puzzle) {
      final p = c.puzzle!;
      return GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(flex: 2, child: _HudValue(label: s.puzzleLabel(p), value: s.puzzleGoal(ChainPuzzles.of(p).moves), small: true)),
            Expanded(child: _HudValue(label: s.puzzleSwaps, value: '${g.movesLeft}', colors: _hot)),
          ],
        ),
      );
    }
    if (m != null) {
      final target = m.kind == MissionKind.chain ? m.count : (m.kind == MissionKind.survive ? m.seconds.round() : m.target);
      final progress = m.kind == MissionKind.survive ? g.time.floor().clamp(0, target) : g.missionProgress;
      return GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(flex: 2, child: _HudValue(label: '${s.missionLabel(m.number)} · ${s.missionGoal}', value: s.missionText(m), small: true)),
                Expanded(child: _HudValue(label: s.timeLabel, value: s.clock(g.started ? g.missionLeft : m.seconds), alert: g.started && g.missionLeft <= 10)),
              ],
            ),
            const SizedBox(height: 6),
            _GoalBar(value: target == 0 ? 0 : progress / target, label: m.kind == MissionKind.score ? s.score(g.score) : s.missionProgress(progress, target)),
          ],
        ),
      );
    }
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
            child: Stack(
              children: [
                CustomPaint(
                  size: geometry.canvas,
                  painter: ChainBoardPainter(c: c, palette: palette, geometry: geometry, dpr: dpr),
                ),
                if (c.lesson != null && !c.game.isOver)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: geometry.canvas.height * 0.18,
                    child: IgnorePointer(child: _LessonBubble(key: ValueKey('chain-lesson-${c.lesson}'), text: AppStrings.of(context).chainLesson(c.lesson!), outfit: c.outfit)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The first mission's lesson: Lokum's words over the empty board, popping
/// in at each step.
class _LessonBubble extends StatelessWidget {
  const _LessonBubble({super.key, required this.text, required this.outfit});

  final String text;
  final LokumOutfit outfit;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.6, end: 1),
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutBack,
    builder: (context, k, child) => Transform.scale(scale: k, child: child),
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 6)],
      ),
      child: Row(
        children: [
          LokumView(outfit: outfit, pose: LokumPose.happy, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 16, height: 1.15, fontWeight: FontWeight.w800, color: Color(0xFF7A2A9E))),
          ),
        ],
      ),
    ),
  );
}

/// Before a chain mission: a chain in three small pictures.
class _ChainHowTo extends StatelessWidget {
  const _ChainHowTo();

  static const _steps = [
    (['..Y...', 'BBBYYG', 'MGOGBM'], {(0, 1), (1, 1), (2, 1)}, false),
    (['..Y...', '...YYG', 'MGOGBM'], <(int, int)>{}, true),
    (['......', '..YYYG', 'MGOGBM'], {(2, 1), (3, 1), (4, 1)}, false),
  ];

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final labels = [s.chainHowStep1, s.chainHowStep2, s.chainHowStep3];
    return Container(
      key: const ValueKey('chain-how-to'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.glassBorder, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.chainHowTitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: p.text)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (rows, glow, fall)) in _steps.indexed) ...[
                if (i > 0) Padding(padding: const EdgeInsets.only(top: 22), child: Icon(Icons.chevron_right_rounded, color: p.muted)),
                Expanded(
                  child: Column(
                    children: [
                      AspectRatio(aspectRatio: 2, child: CustomPaint(painter: _HowToPainter(rows, glow, fall))),
                      const SizedBox(height: 4),
                      Text(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.15, fontWeight: FontWeight.w800, color: p.text)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HowToPainter extends CustomPainter {
  _HowToPainter(this.rows, this.glow, this.fall);

  final List<String> rows;
  final Set<(int, int)> glow;
  final bool fall;

  static const _map = {'Y': ChainColor.yellow, 'M': ChainColor.magenta, 'B': ChainColor.blue, 'G': ChainColor.green, 'O': ChainColor.orange};

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width / 6, size.height / rows.length);
    final o = Offset((size.width - 6 * s) / 2, size.height - rows.length * s);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.4)), Paint()..color = const Color(0xFF120E1E));
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < 6; x++) {
        final ch = rows[y][x];
        if (ch == '.') continue;
        final cell = Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s);
        if (glow.contains((x, y))) canvas.drawCircle(cell.center, s * 0.75, Paint()..color = Colors.white.withValues(alpha: 0.35));
        paintChainCube(canvas, cell.deflate(s * 0.05), chainColors[_map[ch]!]!);
      }
    }
    if (fall) {
      // The yellow on top drops into the gap.
      final c = Offset(o.dx + 2.5 * s, o.dy + 0.5 * s);
      final paint = Paint()
        ..color = const Color(0xFFFFE066)
        ..strokeWidth = s * 0.14
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(c + Offset(0, s * 0.45), c + Offset(0, s * 1.2), paint);
      canvas.drawLine(c + Offset(-s * 0.22, s * 0.95), c + Offset(0, s * 1.2), paint);
      canvas.drawLine(c + Offset(s * 0.22, s * 0.95), c + Offset(0, s * 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(_HowToPainter old) => false;
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

/// Stop the clock: holds the rising stack for a few seconds.
class _FreezeButton extends StatelessWidget {
  const _FreezeButton({required this.c});

  final ChainController c;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final n = c.settings.chainFreezes;
    return Semantics(
      button: true,
      label: s.freezeLabel,
      child: GestureDetector(
        key: const ValueKey('chain-freeze'),
        onTap: n > 0 && c.playing ? c.useFreeze : null,
        child: Opacity(
          opacity: n > 0 ? 1 : 0.45,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            radius: 16,
            glow: c.game.stopTime > 0 ? 1 : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_bottom_rounded, color: p.icon, size: 22),
                const SizedBox(width: 4),
                Text('×$n', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

/// A mission's progress as a bar with its count.
class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return SizedBox(
      height: 18,
      child: Stack(
        children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(9), border: Border.all(color: p.glassBorder)))),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: DecoratedBox(decoration: BoxDecoration(gradient: const LinearGradient(colors: _chainColors), borderRadius: BorderRadius.circular(9))),
          ),
          Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: p.text, height: 1))),
        ],
      ),
    );
  }
}

/// Under a puzzle: undo, a hint, start over.
class _PuzzleButtons extends StatelessWidget {
  const _PuzzleButtons({required this.c});

  final ChainController c;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    Widget button(String key, IconData icon, String label, VoidCallback onTap, {bool glow = false}) => Expanded(
      child: GestureDetector(
        key: ValueKey(key),
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          radius: 16,
          glow: glow ? 1 : 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: GamePalette.of(context).icon),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: GamePalette.of(context).text)),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        Padding(padding: const EdgeInsets.only(right: 8), child: _ChainLokum(c: c)),
        button('puzzle-undo', Icons.undo_rounded, s.undo, c.undo),
        const SizedBox(width: 8),
        button('puzzle-hint', Icons.lightbulb_rounded, s.hint, c.showHint, glow: c.hint != null),
        const SizedBox(width: 8),
        button('puzzle-restart', Icons.restart_alt_rounded, s.restartShort, c.restartPuzzle),
      ],
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
    final m = c.mission;
    if (c.mode == ChainMode.puzzle || m != null) {
      final p = c.puzzle;
      return _Panel(
        children: [
          Center(
            child: GradientText(
              m != null ? s.missionLabel(m.number) : s.puzzleLabel(p!),
              gradient: const LinearGradient(colors: _chainColors),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
          ),
          if (m != null) Text(ChainMissions.piers[ChainMissions.pierOf(m.number)], textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: GamePalette.of(context).muted, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            m != null && m.kind != MissionKind.puzzle ? s.missionText(m) : s.puzzleGoal(ChainPuzzles.of(p!).moves),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, height: 1.25, fontWeight: FontWeight.w900, color: GamePalette.of(context).text),
          ),
          const SizedBox(height: 10),
          if (p != null) how(Icons.extension_rounded, s.puzzleHow) else ...[
            how(Icons.swap_horiz_rounded, s.chainHowSwap),
            if (m!.kind == MissionKind.chain && m.number > 1) ...[const SizedBox(height: 6), const _ChainHowTo(), const SizedBox(height: 6)] else how(Icons.link_rounded, s.chainHowChain),
            if (m.kind == MissionKind.garbage) how(Icons.view_stream_rounded, s.chainHowGarbage),
            how(Icons.warning_amber_rounded, s.chainHowTop),
          ],
          if (m != null && c.settings.missionStars(m.number) > 0) ...[
            const SizedBox(height: 6),
            Center(child: _Stars(c.settings.missionStars(m.number))),
          ],
          const SizedBox(height: 16),
          GradientButton(key: const ValueKey('chain-start'), label: s.chainStart, icon: Icons.play_arrow_rounded, colors: _chainColors, onTap: c.start),
          const SizedBox(height: 10),
          GradientButton(label: s.back, icon: Icons.arrow_back_rounded, secondary: true, onTap: onBack),
        ],
      );
    }
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

GamePalette p0(BuildContext context) => GamePalette.of(context);

/// Gold stars in a row, [n] of three lit.
class _Stars extends StatelessWidget {
  const _Stars(this.n, {this.size = 30});

  final int n;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Icon(Icons.star_rounded, size: size * (i == 1 ? 1.2 : 1), color: i < n ? const Color(0xFFFFC21A) : GamePalette.of(context).muted.withValues(alpha: 0.35)),
    ],
  );
}

/// A puzzle or a mission ended: solved or not, the stars, the prize, on.
class _GoalPanel extends StatelessWidget {
  const _GoalPanel({required this.c, required this.onMenu, required this.onNext});

  final ChainController c;
  final VoidCallback onMenu;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final g = c.game;
    final won = g.won;
    final puzzle = c.mode == ChainMode.puzzle && c.mission == null;
    final prize = c.prize;
    final m = c.mission;
    final pierDone = prize != null && m != null;
    return _Panel(
      children: [
        Center(child: DancingLokum(outfit: c.outfit, size: 56, pose: won ? LokumPose.dance : LokumPose.sad, moving: won && c.settings.effects)),
        Text(
          won ? (puzzle ? s.puzzleSolved : s.missionDone) : (puzzle || c.mode == ChainMode.puzzle ? s.puzzleFailed : (g.timeUp ? s.timeUp : s.missionMissed)),
          key: const ValueKey('chain-goal-result'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
        ),
        if (won) ...[const SizedBox(height: 8), Center(child: _Stars(c.stars, size: 36))],
        if (pierDone) ...[
          const SizedBox(height: 8),
          Text(s.pierDone(ChainMissions.piers[ChainMissions.pierOf(m.number)]), textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFFFC21A))),
        ],
        if (prize != null)
          Text(
            s.prizeLine([for (final e in prize.boosters.entries) '${sugarBoosterName(s, e.key)} ×${e.value}', if (prize.freezes > 0) s.freezesCount(prize.freezes)].join(', ')),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.muted),
          ),
        if (!puzzle && c.mode == ChainMode.mission) ...[
          const SizedBox(height: 6),
          Text(s.score(g.score), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.muted, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 18),
        if (won)
          GradientButton(key: const ValueKey('chain-next'), label: s.nextOne, icon: Icons.arrow_forward_rounded, colors: _chainColors, onTap: onNext)
        else
          GradientButton(key: const ValueKey('chain-again'), label: s.playAgain, icon: Icons.replay_rounded, colors: _chainColors, onTap: c.start),
        const SizedBox(height: 10),
        Row(
          children: [
            if (won) ...[Expanded(child: GradientButton(label: s.playAgain, icon: Icons.replay_rounded, secondary: true, onTap: c.start)), const SizedBox(width: 10)],
            Expanded(child: GradientButton(key: const ValueKey('chain-menu'), label: s.back, icon: Icons.arrow_back_rounded, secondary: true, onTap: onMenu)),
          ],
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- versus --

/// "Limon'a Karşı": a match against one of the three Ekşi Limons. Without
/// a [rival] (a ferry-line match fixes one) it opens on the rival picker.
class ChainVersusScreen extends StatefulWidget {
  const ChainVersusScreen({super.key, required this.settings, required this.audio, this.haptics, this.rival, this.mission});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;
  final ChainRival? rival;
  final ChainMission? mission;

  static Future<void> open(BuildContext context, {required Settings settings, required AudioService audio, Haptics? haptics, ChainRival? rival, ChainMission? mission}) =>
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => ChainVersusScreen(settings: settings, audio: audio, haptics: haptics, rival: rival, mission: mission),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );

  @override
  State<ChainVersusScreen> createState() => _ChainVersusScreenState();
}

class _ChainVersusScreenState extends State<ChainVersusScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late ChainRival _rival = widget.rival ?? ChainRival.values[min(ChainRival.values.length - 1, _firstUnbeaten)];
  late ChainVersusController c = _controller();
  late final Ticker _ticker = createTicker((d) => c.tick(d));
  final FocusNode _focus = FocusNode();
  bool _locked = false;

  int get _firstUnbeaten {
    for (final r in ChainRival.values) {
      if (widget.settings.rivalWins(r.index) == 0) return r.index;
    }
    return ChainRival.values.length - 1;
  }

  ChainVersusController _controller() => ChainVersusController(settings: widget.settings, audio: widget.audio, haptics: widget.haptics, rival: _rival, mission: widget.mission);

  void _pick(ChainRival r) {
    if (r == _rival) return;
    final old = c;
    setState(() {
      _rival = r;
      c = _controller();
    });
    widget.audio.play(Sfx.click);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  void _back() {
    if (c.playing && !c.paused) {
      c.togglePause();
    } else {
      _leave();
    }
  }

  void _leave() {
    if (mounted) Navigator.of(context).pop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    final key = e.logicalKey;
    final down = e is KeyDownEvent;
    if (key == LogicalKeyboardKey.shiftLeft || key == LogicalKeyboardKey.shiftRight || key == LogicalKeyboardKey.keyC) {
      if (down) c.raising = true;
      if (e is KeyUpEvent) c.raising = false;
      return KeyEventResult.handled;
    }
    if (!down && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
      if (down) _back();
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
                      Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 10), child: _VersusPlay(c: c, onBack: _back)),
                      if (!c.started)
                        _RivalPanel(c: c, fixed: widget.rival != null, onPick: _pick, onBack: _leave)
                      else if (c.paused)
                        _PausePanel(c: c, onMenu: _leave)
                      else if (c.showResult)
                        _SetPanel(c: c, onMenu: _leave),
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

class _VersusPlay extends StatelessWidget {
  const _VersusPlay({required this.c, required this.onBack});

  final ChainVersusController c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final mini = ChainGeometry(ChainGeometry.fit(const Size(92, 150)));
    return Column(
      children: [
        Row(
          children: [
            GlassIconButton(key: const ValueKey('versus-pause'), icon: c.playing ? Icons.pause_rounded : Icons.arrow_back_rounded, tooltip: c.playing ? s.pause : s.menu, onTap: onBack),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: GradientText('${s.chainVersusTitle} · ${s.rivalName(c.rival.index)}', gradient: const LinearGradient(colors: _chainColors), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Side(label: s.versusYou, sets: c.versus.playerSets, face: LokumView(outfit: c.outfit, size: 36)),
                    const SizedBox(height: 8),
                    _Side(label: s.rivalName(c.rival.index), sets: c.versus.cpuSets, face: const SizedBox(width: 40, height: 36, child: CustomPaint(painter: _LimonFace()))),
                    const SizedBox(height: 6),
                    ValueListenableBuilder(
                      valueListenable: c.frame,
                      builder: (context, _, _) => c.incoming > 0
                          ? Container(
                              key: const ValueKey('versus-incoming'),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF5A1A2A), borderRadius: BorderRadius.circular(12)),
                              child: Text(s.versusIncoming(c.incoming), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFB0B8))),
                            )
                          : Text(s.score(c.game.score), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.muted)),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                key: const ValueKey('versus-cpu-board'),
                size: mini.canvas,
                painter: ChainBoardPainter(c: c, palette: p, geometry: mini, dpr: dpr, game: c.cpu, fx: c.cpuFx),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _Board(c: c)),
        const SizedBox(height: 8),
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

/// One side of the match: a face, a name and the sets won.
class _Side extends StatelessWidget {
  const _Side({required this.label, required this.sets, required this.face});

  final String label;
  final int sets;
  final Widget face;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Row(
      children: [
        face,
        const SizedBox(width: 8),
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: p.text))),
        for (var i = 0; i < ChainVersus.setsToWin; i++)
          Container(
            margin: const EdgeInsets.only(left: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: i < sets ? const Color(0xFFFF33EE) : p.glass, border: Border.all(color: p.glassBorder)),
          ),
      ],
    );
  }
}

class _LimonFace extends CustomPainter {
  const _LimonFace({this.scale = 1, this.laugh = false});

  final double scale;
  final bool laugh;

  @override
  void paint(Canvas canvas, Size size) => paintEksiLimon(canvas, Offset(size.width / 2, size.height * 0.58), size.height * 0.78 * scale, laugh: laugh);

  @override
  bool shouldRepaint(_LimonFace old) => old.scale != scale || old.laugh != laugh;
}

/// Before the match: the three rivals, their records and prizes.
class _RivalPanel extends StatelessWidget {
  const _RivalPanel({required this.c, required this.fixed, required this.onPick, required this.onBack});

  final ChainVersusController c;
  final bool fixed;
  final ValueChanged<ChainRival> onPick;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    return _Panel(
      children: [
        Center(child: GradientText(fixed ? s.rivalName(c.rival.index) : s.versusPick, gradient: const LinearGradient(colors: _chainColors), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
        const SizedBox(height: 6),
        Text(s.versusHow, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.25, color: p.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (final r in fixed ? [c.rival] : ChainRival.values) ...[
          GestureDetector(
            key: ValueKey('rival-${r.name}'),
            onTap: fixed ? null : () => onPick(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              decoration: BoxDecoration(
                color: r == c.rival ? const Color(0xFFFF33EE).withValues(alpha: 0.14) : p.glass,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: r == c.rival ? const Color(0xFFFF33EE) : p.glassBorder, width: r == c.rival ? 2.5 : 1.5),
              ),
              child: Row(
                children: [
                  SizedBox(width: 64, height: 58, child: CustomPaint(painter: _LimonFace(scale: 0.7 + 0.15 * r.index, laugh: r == ChainRival.master))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.rivalName(r.index), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: p.text)),
                        Text(s.rivalText(r.index), style: TextStyle(fontSize: 13, height: 1.2, fontWeight: FontWeight.w700, color: p.muted)),
                        const SizedBox(height: 2),
                        Text(
                          c.settings.rivalWins(r.index) > 0 ? s.rivalWins(c.settings.rivalWins(r.index)) : s.rivalPrize(r.index),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.settings.rivalWins(r.index) > 0 ? const Color(0xFF1FE85A) : const Color(0xFFFFC21A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        GradientButton(key: const ValueKey('versus-start'), label: s.startMatch, icon: Icons.play_arrow_rounded, colors: _chainColors, onTap: c.start),
        const SizedBox(height: 10),
        GradientButton(label: s.back, icon: Icons.arrow_back_rounded, secondary: true, onTap: onBack),
      ],
    );
  }
}

/// A set or the match is over.
class _SetPanel extends StatelessWidget {
  const _SetPanel({required this.c, required this.onMenu});

  final ChainVersusController c;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final v = c.versus;
    final over = v.matchOver;
    final won = over ? v.playerWonMatch : c.game.won;
    final prize = c.prize;
    return _Panel(
      children: [
        Center(child: DancingLokum(outfit: c.outfit, size: 56, pose: won ? LokumPose.dance : LokumPose.sad, moving: won && c.settings.effects)),
        Text(
          over ? (won ? s.matchWon : s.matchLost) : (won ? s.setWon : s.setLost),
          key: const ValueKey('versus-result'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 6),
        Text('${s.versusYou} ${v.playerSets} – ${v.cpuSets} ${s.rivalName(c.rival.index)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: p.muted)),
        if (over && won) ...[const SizedBox(height: 8), Center(child: _Stars(c.stars, size: 36))],
        if (prize != null) ...[
          const SizedBox(height: 6),
          Text(
            s.prizeLine([
              if (prize.unlock != null) s.unlockName(prize.unlock!.name),
              for (final e in prize.boosters.entries) '${sugarBoosterName(s, e.key)} ×${e.value}',
              if (prize.freezes > 0) s.freezesCount(prize.freezes),
            ].join(', ')),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFFFC21A)),
          ),
        ],
        const SizedBox(height: 18),
        if (!over)
          GradientButton(key: const ValueKey('versus-next-set'), label: s.nextSet, icon: Icons.arrow_forward_rounded, colors: _chainColors, onTap: c.nextSet)
        else
          GradientButton(key: const ValueKey('versus-rematch'), label: s.rematch, icon: Icons.replay_rounded, colors: _chainColors, onTap: c.start),
        const SizedBox(height: 10),
        GradientButton(key: const ValueKey('versus-menu'), label: s.back, icon: Icons.arrow_back_rounded, secondary: true, onTap: onMenu),
      ],
    );
  }
}
