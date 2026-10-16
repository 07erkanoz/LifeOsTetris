import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/sugar/sugar_game.dart';
import '../core/sugar/sugar_levels.dart';
import '../game/sugar/sugar_art.dart';
import '../game/sugar/sugar_controller.dart';
import '../game/sugar/sugar_painter.dart';
import '../l10n/strings.dart';
import '../platform/orientation_lock.dart';
import '../settings/settings.dart';
import 'game_screen.dart' show showSettingsDialog;
import 'sugar_widgets.dart';

String _thousands(int n) {
  final s = '$n';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// "Şeker Küpler" level: swap neighbouring cubes, line up three of a colour,
/// meet the goals before the moves run out.
class SugarScreen extends StatefulWidget {
  const SugarScreen({super.key, required this.settings, required this.audio, this.haptics, required this.level, this.resume = false, this.seed});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;
  final int level;

  /// Continue the saved game of [level] instead of showing its start panel.
  final bool resume;
  final int? seed;

  static Future<void> open(
    BuildContext context, {
    required Settings settings,
    required AudioService audio,
    Haptics? haptics,
    required int level,
    bool resume = false,
  }) => Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => SugarScreen(settings: settings, audio: audio, haptics: haptics, level: level, resume: resume),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  State<SugarScreen> createState() => _SugarScreenState();
}

class _SugarScreenState extends State<SugarScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final SugarController c = SugarController(
    settings: widget.settings,
    audio: widget.audio,
    haptics: widget.haptics,
    level: SugarLevels.of(widget.level),
    seed: widget.seed,
  );
  late final Ticker _ticker = createTicker(c.tick);
  final FocusNode _focus = FocusNode();
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.resume) c.start(resume: true);
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
    if (state != AppLifecycleState.resumed) {
      c.pauseIfRunning();
      c.saveProgress();
    }
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
    if (c.started && !c.game.isOver && !c.paused) {
      c.togglePause();
    } else {
      _leave();
    }
  }

  void _leave() {
    c.saveProgress();
    if (mounted) Navigator.of(context).pop();
  }

  /// Straight back to the home menu (past the map); the level is kept.
  void _home() {
    c.saveProgress();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
      c.started && !c.game.isOver ? c.togglePause() : _back();
      return KeyEventResult.handled;
    }
    if (!c.started && (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space)) {
      c.start();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    c.strings = AppStrings.of(context);
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
          backgroundColor: const Color(0xFF3A1470),
          body: Stack(
            children: [
              Positioned.fill(child: SugarBackdrop(chapter: SugarLevels.chapterOf(c.level.number))),
              SafeArea(
                child: ListenableBuilder(
                  listenable: c,
                  builder: (context, _) => Stack(
                    children: [
                      _Play(c: c, onBack: _back),
                      if (!c.started)
                        _StartPanel(c: c, onBack: _leave)
                      else if (c.paused)
                        _PausePanel(c: c, onMenu: _leave, onHome: _home)
                      else if (c.showResult)
                        c.game.status == SugarStatus.won ? _WonPanel(c: c, onMap: _leave) : _LostPanel(c: c, onMap: _leave),
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

// ------------------------------------------------------------------ play --

class _Play extends StatelessWidget {
  const _Play({required this.c, required this.onBack});

  final SugarController c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final g = c.game;
    final running = c.started && !g.isOver;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        children: [
          _TopBar(c: c, onBack: onBack),
          const SizedBox(height: 6),
          // The bar, the counting score and the meter move every frame.
          ValueListenableBuilder(
            valueListenable: c.frame,
            builder: (context, _, _) => Column(
              children: [
                SugarScoreBar(score: c.shownScore.round(), stars: c.level.stars, goalsDone: g.goalsDone, pulse: c.fx.starPulse),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: CandyText(_thousands(c.shownScore.round()), size: 23 + 4 * c.fx.scorePulse, stroke: 0.18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: SugarRushMeter(value: g.rushMeter, label: s.sugarRushMeter)),
                    const SizedBox(width: 64),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                // The boosters sit right under the board; both float in the
                // middle of what is left.
                const below = 128.0;
                final cell = SugarGeometry.fit(Size(box.maxWidth, box.maxHeight - below - 18));
                final geometry = SugarGeometry(cell);
                final hint = switch (c.armed) {
                  SugarBooster.hammer => s.sugarHammerHint,
                  SugarBooster.rainbow => s.sugarRainbowHint,
                  _ => null,
                };
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 18),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _BoardInput(
                          c: c,
                          geometry: geometry,
                          child: CustomPaint(
                            key: const ValueKey('sugar-board'),
                            size: geometry.canvas,
                            painter: SugarBoardPainter(c: c, geometry: geometry, dpr: MediaQuery.devicePixelRatioOf(context)),
                          ),
                        ),
                        // Lokum sits on the tray's top-right corner.
                        Positioned(
                          right: -6,
                          top: -cell * 1.25,
                          child: IgnorePointer(child: _Mascot(c: c, size: cell * 1.05)),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 26,
                      child: hint != null ? Center(child: FittedBox(child: CandyText(hint, size: 16, outline: const Color(0xFF3A0F60), stroke: 0.2))) : null,
                    ),
                    _Boosters(c: c, running: running),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Lokum, hopping when its mood changes.
class _Mascot extends StatelessWidget {
  const _Mascot({required this.c, required this.size});

  final SugarController c;
  final double size;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: c.frame,
    builder: (context, _, _) {
      final t = (c.now - c.mascot.changed) / 0.4;
      return SugarMascotView(key: const ValueKey('sugar-mascot'), pose: c.mascot.pose, line: c.mascot.line, hop: t >= 0 && t < 1 ? t : 0, size: size);
    },
  );
}

class _Boosters extends StatelessWidget {
  const _Boosters({required this.c, required this.running});

  final SugarController c;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = c.settings;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SugarBoosterButton(
          key: const ValueKey('sugar-hammer'),
          kind: SugarBooster.hammer,
          count: settings.sugarBoosters(SugarBooster.hammer),
          label: s.sugarHammer,
          active: c.hammerArmed,
          onTap: running ? () => c.toggleBooster(SugarBooster.hammer) : null,
        ),
        SugarBoosterButton(
          key: const ValueKey('sugar-rainbow'),
          kind: SugarBooster.rainbow,
          count: settings.sugarBoosters(SugarBooster.rainbow),
          label: s.sugarRainbow,
          active: c.rainbowArmed,
          onTap: running ? () => c.toggleBooster(SugarBooster.rainbow) : null,
        ),
        SugarBoosterButton(
          key: const ValueKey('sugar-moves'),
          kind: SugarBooster.moves,
          count: settings.sugarBoosters(SugarBooster.moves),
          label: s.sugarExtraMoves(SugarBooster.extraMoves),
          onTap: running ? c.useExtraMoves : null,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.c, required this.onBack});

  final SugarController c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final g = c.game;
    final running = c.started && !g.isOver;
    final low = running && g.moves <= 5 && !g.goalsDone;
    final warn = low ? 0.5 + 0.5 * sin(c.fx.time * 6) : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF7FD), Color(0xFFFFE3F4)]),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF2A0B4F).withValues(alpha: 0.7), offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SugarRoundButton(
                key: const ValueKey('sugar-pause'),
                icon: running ? Icons.pause_rounded : Icons.arrow_back_rounded,
                tooltip: running ? s.pause : s.menu,
                size: 36,
                onTap: onBack,
              ),
            ],
          ),
          const SizedBox(width: 6),
          // Low on moves: the bubble throbs every frame.
          ValueListenableBuilder(
            valueListenable: c.frame,
            builder: (context, _, _) => SugarMovesBubble(moves: g.moves, label: s.sugarMoves, size: 76, warn: low ? 0.5 + 0.5 * sin(c.fx.time * 6) : warn),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CandyText(s.sugarLevel(c.level.number), size: 18, color: const Color(0xFF7A2A9E), stroke: 0),
                    if (c.level.boss) ...[
                      const SizedBox(width: 6),
                      SugarTag(s.sugarBoss, colors: const [Color(0xFFFF8A8A), Color(0xFFC81E3A)]),
                    ],
                    if (c.level.hard) ...[const SizedBox(width: 6), SugarTag(s.sugarHard)],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final goal in g.goals) _GoalChip(goal: goal)]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.goal});

  final SugarGoal goal;

  @override
  Widget build(BuildContext context) {
    final done = goal.done;
    final share = (goal.progress / goal.target).clamp(0.0, 1.0);
    final text = goal.kind == GoalKind.score ? _thousands(goal.target) : '${min(goal.progress, goal.target)}/${goal.target}';
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(color: const Color(0xFFF3D9F0), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SugarGoalIcon(goal, size: 30),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 64),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CandyText(text, size: 15, color: sugarInk, stroke: 0),
                    ),
                  ),
                  if (done)
                    const Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF1FB85A)),
                    ),
                ],
              ),
              Container(
                width: 52,
                height: 7,
                decoration: BoxDecoration(color: const Color(0xFFE2BCE0), borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: share,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(colors: done ? const [Color(0xFF6BF0A0), Color(0xFF1FB85A)] : const [Color(0xFF6BE3FF), Color(0xFF2E86FF)]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Taps pick a cube (and a neighbour to swap with); a drag swaps at once.
class _BoardInput extends StatefulWidget {
  const _BoardInput({required this.c, required this.geometry, required this.child});

  final SugarController c;
  final SugarGeometry geometry;
  final Widget child;

  @override
  State<_BoardInput> createState() => _BoardInputState();
}

class _BoardInputState extends State<_BoardInput> {
  Cell? _from;
  Offset _start = Offset.zero;
  bool _dragged = false;

  Cell _cellAt(Offset local) {
    final g = widget.geometry;
    final p = local - g.origin;
    return ((p.dx / g.cell).floor(), (p.dy / g.cell).floor());
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onPanDown: (d) {
      _from = _cellAt(d.localPosition);
      _start = d.localPosition;
      _dragged = false;
    },
    onPanUpdate: (d) {
      final from = _from;
      if (from == null || _dragged) return;
      final delta = d.localPosition - _start;
      if (delta.distance < widget.geometry.cell * 0.35) return;
      _dragged = true;
      if (widget.c.hammerArmed) return;
      final horizontal = delta.dx.abs() > delta.dy.abs();
      widget.c.dragCell(from, horizontal ? delta.dx.sign.toInt() : 0, horizontal ? 0 : delta.dy.sign.toInt());
    },
    onPanEnd: (_) {
      final from = _from;
      if (from != null && !_dragged) widget.c.tapCell(from.$1, from.$2);
      _from = null;
    },
    onPanCancel: () {
      final from = _from;
      if (from != null && !_dragged) widget.c.tapCell(from.$1, from.$2);
      _from = null;
    },
    child: widget.child,
  );
}

// ---------------------------------------------------------------- panels --

class _Dim extends StatelessWidget {
  const _Dim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xFF1A0730).withValues(alpha: 0.55),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

class _GoalLine extends StatelessWidget {
  const _GoalLine({required this.goal});

  final SugarGoal goal;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = switch (goal.kind) {
      GoalKind.score => s.sugarGoalScore(_thousands(goal.target)),
      GoalKind.color => s.sugarGoalColor(goal.target),
      GoalKind.ice => s.sugarGoalIce(goal.target),
      GoalKind.box => s.sugarGoalBox(goal.target),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SugarGoalIcon(goal, size: 34),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700, color: sugarInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({required this.c, required this.onBack});

  final SugarController c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final level = c.level;
    final goals = [for (final g in level.goals) g()];
    final hint = level.hint;
    return _Dim(
      child: CandyPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CandyText(s.sugarLevel(level.number), size: 34, outline: const Color(0xFF8A1550)),
                if (level.boss) ...[
                  const SizedBox(width: 8),
                  SugarTag(s.sugarBoss, colors: const [Color(0xFFFF8A8A), Color(0xFFC81E3A)]),
                ],
                if (level.hard) ...[const SizedBox(width: 8), SugarTag(s.sugarHard)],
              ],
            ),
            const SizedBox(height: 4),
            SugarStars(on: c.settings.sugarStars(level.number), size: 18, arc: true),
            const SizedBox(height: 10),
            if (hint != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0B8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFC21A), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFFE08A00), size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.sugarHint(hint),
                        style: const TextStyle(fontFamily: 'Baloo2', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF6A3A00), height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            CandyText(s.sugarGoals, size: 16, color: const Color(0xFF9A5AB5), stroke: 0),
            for (final g in goals) _GoalLine(goal: g),
            const SizedBox(height: 4),
            Text(
              s.sugarMovesLeft(level.moves),
              style: const TextStyle(fontFamily: 'Baloo2', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF9A5AB5)),
            ),
            const SizedBox(height: 16),
            CandyButton(
              key: const ValueKey('sugar-play'),
              label: s.sugarPlay,
              colors: sugarGreen,
              ink: const Color(0xFF0E6A32),
              width: double.infinity,
              textSize: 26,
              onTap: c.start,
            ),
            const SizedBox(height: 12),
            CandyButton(
              label: s.sugarMap,
              colors: sugarWhite,
              ink: const Color(0xFFD08ABF),
              width: double.infinity,
              height: 48,
              textSize: 18,
              icon: Icons.map_rounded,
              onTap: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _PausePanel extends StatelessWidget {
  const _PausePanel({required this.c, required this.onMenu, required this.onHome});

  final SugarController c;
  final VoidCallback onMenu;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return _Dim(
      child: CandyPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CandyText(s.paused, size: 32, outline: const Color(0xFF8A1550)),
            const SizedBox(height: 4),
            CandyText(s.sugarLevel(c.level.number), size: 18, color: const Color(0xFF9A5AB5), stroke: 0),
            const SizedBox(height: 18),
            CandyButton(
              key: const ValueKey('sugar-resume'),
              label: s.resume,
              colors: sugarGreen,
              ink: const Color(0xFF0E6A32),
              width: double.infinity,
              icon: Icons.play_arrow_rounded,
              onTap: c.togglePause,
            ),
            const SizedBox(height: 12),
            CandyButton(
              label: s.restart,
              width: double.infinity,
              height: 50,
              textSize: 19,
              icon: Icons.replay_rounded,
              onTap: () {
                c.settings.savedSugar = null;
                c.start();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CandyButton(
                    key: const ValueKey('sugar-settings'),
                    label: s.settingsTitle,
                    colors: sugarWhite,
                    ink: const Color(0xFFD08ABF),
                    height: 48,
                    textSize: 17,
                    icon: Icons.settings_rounded,
                    onTap: () => showSettingsDialog(context, c.settings),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CandyButton(
                    label: s.sugarMap,
                    colors: sugarWhite,
                    ink: const Color(0xFFD08ABF),
                    height: 48,
                    textSize: 17,
                    icon: Icons.map_rounded,
                    onTap: onMenu,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CandyButton(
              key: const ValueKey('sugar-home'),
              label: s.mainMenu,
              colors: sugarWhite,
              ink: const Color(0xFFD08ABF),
              width: double.infinity,
              height: 48,
              textSize: 18,
              icon: Icons.home_rounded,
              onTap: onHome,
            ),
          ],
        ),
      ),
    );
  }
}

class _WonPanel extends StatelessWidget {
  const _WonPanel({required this.c, required this.onMap});

  final SugarController c;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final stars = c.game.starCount;
    final next = c.level.number < SugarLevels.count ? c.level.number + 1 : null;
    return _Dim(
      child: CandyPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SugarMascotView(pose: LokumPose.cheer, size: 70),
            CandyText(s.sugarWon, size: 32, colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], outline: const Color(0xFF6A0E4A)),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: stars.toDouble()),
              duration: Duration(milliseconds: 350 * max(1, stars)),
              builder: (context, v, _) => SugarStars(on: v.floor(), size: 30, arc: true),
            ),
            const SizedBox(height: 6),
            CandyText(_thousands(c.game.score), size: 30, outline: const Color(0xFF8A1550)),
            if (c.newBest) CandyText(s.sugarNewBest, size: 18, color: const Color(0xFF1FB85A), stroke: 0),
            if (c.chest.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0B8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFC21A), width: 2),
                ),
                child: Column(
                  children: [
                    CandyText(s.sugarChest, size: 18, color: const Color(0xFFE08A00), stroke: 0),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 14,
                      children: [
                        for (final e in c.chest.entries)
                          Text(
                            '${switch (e.key) {
                              SugarBooster.hammer => s.sugarHammer,
                              SugarBooster.rainbow => s.sugarRainbow,
                              SugarBooster.moves => s.sugarExtraMoves(SugarBooster.extraMoves),
                            }} ×${e.value}',
                            style: const TextStyle(fontFamily: 'Baloo2', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF6A3A00)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (next != null)
              CandyButton(
                key: const ValueKey('sugar-next'),
                label: s.sugarNext,
                colors: sugarGreen,
                ink: const Color(0xFF0E6A32),
                width: double.infinity,
                icon: Icons.arrow_forward_rounded,
                onTap: () => c.play(SugarLevels.of(next)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  s.sugarAllDone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Baloo2', fontSize: 17, fontWeight: FontWeight.w700, color: sugarInk),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CandyButton(label: s.sugarRetry, height: 48, textSize: 17, icon: Icons.replay_rounded, onTap: () => c.play(c.level)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CandyButton(
                    label: s.sugarMap,
                    colors: sugarWhite,
                    ink: const Color(0xFFD08ABF),
                    height: 48,
                    textSize: 17,
                    icon: Icons.map_rounded,
                    onTap: onMap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LostPanel extends StatelessWidget {
  const _LostPanel({required this.c, required this.onMap});

  final SugarController c;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final extra = c.settings.sugarBoosters(SugarBooster.moves);
    return _Dim(
      child: CandyPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SugarMascotView(pose: LokumPose.wow, size: 64),
            CandyText(c.lostToBomb ? s.sugarBombLost : s.sugarLost, size: 32, outline: const Color(0xFF8A1550)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [for (final g in c.game.goals) _GoalChip(goal: g)],
            ),
            const SizedBox(height: 18),
            if (extra > 0) ...[
              CandyButton(
                key: const ValueKey('sugar-extra'),
                label: '${s.sugarKeepGoing(SugarBooster.extraMoves)} ($extra)',
                colors: sugarGreen,
                ink: const Color(0xFF0E6A32),
                width: double.infinity,
                textSize: 20,
                onTap: c.useExtraMoves,
              ),
              const SizedBox(height: 12),
            ],
            CandyButton(
              key: const ValueKey('sugar-retry'),
              label: s.sugarRetry,
              width: double.infinity,
              icon: Icons.replay_rounded,
              onTap: () => c.play(c.level),
            ),
            const SizedBox(height: 12),
            CandyButton(
              label: s.sugarMap,
              colors: sugarWhite,
              ink: const Color(0xFFD08ABF),
              width: double.infinity,
              height: 48,
              textSize: 18,
              icon: Icons.map_rounded,
              onTap: onMap,
            ),
          ],
        ),
      ),
    );
  }
}
