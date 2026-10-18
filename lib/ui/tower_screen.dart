import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/rewards.dart';
import '../core/tower/tower_game.dart';
import '../core/tower/tower_landmarks.dart';
import '../game/sugar/sugar_art.dart' show LokumPose;
import '../game/tower/tower_controller.dart';
import '../game/tower/tower_painter.dart';
import '../l10n/strings.dart';
import '../platform/orientation_lock.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'gifts_screen.dart' show showGiftPopup;
import 'records_list.dart';
import 'sugar_widgets.dart' show DancingLokum;
import 'widgets.dart';

const _towerColors = [Color(0xFFFF8FB8), Color(0xFFFFAA5E)];
const _gold = Color(0xFFFACC15);

/// Shows each landmark of İstanbul'u İnşa Et finished since the last look,
/// with its prize.
Future<void> claimLandmarkPrizes(BuildContext context, Settings settings, AudioService audio) async {
  for (final (landmark, gift) in settings.claimLandmarks()) {
    if (!context.mounted) return;
    final s = AppStrings.of(context);
    await showGiftPopup(context, settings, gift, title: s.landmarkDone(s.landmarkName(landmark.name)), chest: ChestTier.gold, audio: audio);
  }
}

/// A Kule Küpler run: tap to drop the sliding floor.
class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key, required this.settings, required this.audio, this.haptics, required this.mode});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;
  final TowerMode mode;

  static Future<void> open(BuildContext context, {required Settings settings, required AudioService audio, Haptics? haptics, required TowerMode mode}) =>
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => TowerScreen(settings: settings, audio: audio, haptics: haptics, mode: mode),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TowerController c = TowerController(settings: widget.settings, audio: widget.audio, haptics: widget.haptics, mode: widget.mode);
  late final Ticker _ticker = createTicker((d) => c.tick(d));
  final FocusNode _focus = FocusNode();
  bool _locked = false;
  bool _chestShowing = false;

  /// The day's tower has no tries left today: only the panel shows.
  late final bool _noTries = widget.mode == TowerMode.daily && widget.settings.towerTriesLeft(widget.settings.clock()) <= 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.addListener(_watchChest);
    // Starting changes the settings (the mode last played): after this frame.
    if (!_noTries) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) c.start();
      });
    }
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
    c.removeListener(_watchChest);
    _ticker.dispose();
    _focus.dispose();
    c.audio.duck = 1;
    c.dispose();
    super.dispose();
  }

  /// A milestone reached: open its chest, then the run goes on.
  void _watchChest() {
    final at = c.chestAt;
    if (at == null || _chestShowing) return;
    _chestShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final gift = c.openChest();
      await showGiftPopup(context, widget.settings, gift, title: AppStrings.of(context).towerChestTitle(at), chest: Rewards.towerTier(at), audio: c.audio);
      _chestShowing = false;
      c.closeChest();
    });
  }

  void _back() {
    if (c.playing && !c.paused) {
      c.togglePause();
    } else {
      _leave();
    }
  }

  Future<void> _leave() async {
    if (c.dropped || c.game.isOver) c.finishRun();
    await claimLandmarkPrizes(context, widget.settings, widget.audio);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _again() async {
    c.finishRun();
    await claimLandmarkPrizes(context, widget.settings, widget.audio);
    if (!mounted) return;
    if (widget.mode == TowerMode.daily && widget.settings.towerTriesLeft(widget.settings.clock()) <= 0) {
      setState(() {});
      return;
    }
    c.start();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
      c.playing ? c.togglePause() : _back();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.arrowDown) {
      if (c.showResult) {
        _again();
      } else {
        c.tap();
      }
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
          backgroundColor: const Color(0xFF8CC4FF),
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('tower-board'),
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => c.tap(),
                  child: RepaintBoundary(child: CustomPaint(painter: TowerPainter(c: c))),
                ),
              ),
              SafeArea(
                child: ListenableBuilder(
                  listenable: c,
                  builder: (context, _) => Stack(
                    children: [
                      _Hud(c: c, onBack: _back),
                      if (!c.dropped && c.playing) const _TapHint(),
                      if (c.paused)
                        _PausePanel(c: c, onMenu: _leave)
                      else if (c.showResult || (_noTries && c.game.floors.isEmpty))
                        _OverPanel(c: c, onMenu: _leave, onAgain: _again),
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

/// Bold white text that reads on any sky.
TextStyle _skyText(double size, {Color color = Colors.white}) => TextStyle(
  fontSize: size,
  height: 1,
  fontWeight: FontWeight.w900,
  color: color,
  shadows: const [Shadow(color: Color(0xAA1A0E26), blurRadius: 6, offset: Offset(0, 2))],
);

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.color = const Color(0xCC1A1330)});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
    child: child,
  );
}

class _Hud extends StatelessWidget {
  const _Hud({required this.c, required this.onBack});

  final TowerController c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final g = c.game;
    final next = c.nextChest;
    final previous = TowerGame.milestones.lastWhere((m) => m <= g.height, orElse: () => 0);
    final chestProgress = ((g.height - previous) / max(1, next - previous)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassIconButton(key: const ValueKey('tower-pause'), icon: c.playing ? Icons.pause_rounded : Icons.arrow_back_rounded, tooltip: s.paused, size: 42, onTap: onBack),
              const SizedBox(width: 8),
              _Pill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 15, color: _gold),
                    const SizedBox(width: 4),
                    Text(c.mode != TowerMode.daily && c.best > c.game.height ? s.towerToRecord(c.best - c.game.height) : s.floorsLine(max(c.best, c.game.height)), style: _skyText(12.5)),
                  ],
                ),
              ),
              const Spacer(),
              if (c.mode == TowerMode.daily)
                _Pill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(s.towerTriesLeft(c.settings.towerTriesLeft(c.settings.clock())), style: _skyText(12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text('${g.height}', key: const ValueKey('tower-height'), style: _skyText(58)),
          Text(s.towerFloorWord, style: _skyText(14)),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            child: g.streak >= 2
                ? _Pill(
                    color: _gold,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF15101F)),
                        Text(s.towerStreak(g.streak), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF15101F))),
                      ],
                    ),
                  )
                : null,
          ),
          if (c.mode != TowerMode.daily) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 230,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 9,
                      child: LinearProgressIndicator(
                        value: chestProgress,
                        backgroundColor: const Color(0x991A1330),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB84D)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(s.towerNextChest(next), style: _skyText(11.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TapHint extends StatelessWidget {
  const _TapHint();

  @override
  Widget build(BuildContext context) => Align(
    alignment: const Alignment(0, 0.92),
    child: IgnorePointer(
      child: _Pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 6),
            Text(AppStrings.of(context).towerTapHint, style: _skyText(14)),
          ],
        ),
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.5),
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

class _PausePanel extends StatelessWidget {
  const _PausePanel({required this.c, required this.onMenu});

  final TowerController c;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    return _Panel(
      children: [
        Text(s.paused, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text)),
        const SizedBox(height: 18),
        GradientButton(key: const ValueKey('tower-resume'), label: s.resume, icon: Icons.play_arrow_rounded, colors: _towerColors, onTap: c.togglePause),
        const SizedBox(height: 10),
        GradientButton(key: const ValueKey('tower-menu'), label: s.menu, icon: Icons.home_rounded, secondary: true, onTap: onMenu),
      ],
    );
  }
}

class _OverPanel extends StatelessWidget {
  const _OverPanel({required this.c, required this.onMenu, required this.onAgain});

  final TowerController c;
  final VoidCallback onMenu;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final g = c.game;
    final settings = c.settings;
    final now = settings.clock();
    final daily = c.mode == TowerMode.daily;
    // Before the run is recorded its floors are not in the total yet.
    final pending = c.game.floors.isEmpty ? 0 : (c.canRevive ? g.height : 0);
    final build = BuildProgress(settings.towerTotal + pending);
    final landmark = build.current;
    final triesLeft = settings.towerTriesLeft(now) - (daily && c.canRevive ? 1 : 0);
    final again = !daily || triesLeft > 0;
    return _Panel(
      children: [
        Center(child: DancingLokum(outfit: c.outfit, size: 56, pose: c.newRecord ? LokumPose.dance : LokumPose.sad, moving: c.newRecord && settings.effects)),
        Text(c.newRecord ? s.newRecord : s.towerOverTitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: p.text)),
        const SizedBox(height: 8),
        Center(
          child: GradientText(
            s.floorsLine(g.height),
            gradient: const LinearGradient(colors: _towerColors),
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, height: 1.1),
          ),
        ),
        Text(
          '${s.bestLabel}: ${s.floorsLine(max(c.best, g.height))}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: p.muted, fontWeight: FontWeight.w700),
        ),
        if (landmark != null && g.height > 0) ...[
          const SizedBox(height: 12),
          Text(s.towerToBuild(g.height, s.landmarkName(landmark.name)), textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, color: p.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 9,
              child: LinearProgressIndicator(value: build.fraction(landmark), backgroundColor: p.track, valueColor: const AlwaysStoppedAnimation(Color(0xFFFF5FB8))),
            ),
          ),
        ],
        if (daily) ...[
          const SizedBox(height: 10),
          Text(again ? s.towerTriesLeft(triesLeft) : s.towerNoTries, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: p.muted, fontWeight: FontWeight.w700)),
        ] else if (g.height > 0) ...[
          // The climb's place among the records: already on the list once
          // recorded, where it would go while a second chance is open.
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final key = Settings.towerRecords(c.mode);
              final recorded = !c.canRevive;
              final place = recorded ? settings.lastRecordPlace : settings.recordPlaceFor(key, g.height);
              final shown = recorded || place == 0 ? settings.records(key) : ([...settings.records(key)]..insert(place - 1, ScoreEntry(g.height, now)));
              return RecordsBlock(entries: shown, format: s.floorsLine, place: place, goal: recordGoal(s, shown, place, g.height, s.floorsLine));
            },
          ),
        ],
        const SizedBox(height: 18),
        if (c.canRevive) ...[
          GradientButton(key: const ValueKey('tower-revive'), label: s.towerRevive, icon: Icons.favorite_rounded, colors: const [Color(0xFF6BF0A0), Color(0xFF1FB85A)], onTap: c.revive),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            if (again) ...[
              Expanded(child: GradientButton(key: const ValueKey('tower-again'), label: s.playAgain, icon: Icons.replay_rounded, colors: _towerColors, onTap: onAgain)),
              const SizedBox(width: 10),
            ],
            Expanded(child: GradientButton(key: const ValueKey('tower-leave'), label: s.menu, icon: Icons.home_rounded, secondary: true, onTap: onMenu)),
          ],
        ),
      ],
    );
  }
}
