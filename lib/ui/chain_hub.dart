import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/chain/chain_game.dart';
import '../core/chain/chain_missions.dart';
import '../core/chain/chain_puzzles.dart';
import '../core/chain/chain_versus.dart';
import '../game/sugar/istanbul_art.dart';
import '../game/sugar/sugar_art.dart' show paintGoldStar;
import '../l10n/strings.dart';
import '../platform/orientation_lock.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'chain_screen.dart';
import 'widgets.dart';

const _chainColors = [Color(0xFFFF33EE), Color(0xFF3F6BFF), Color(0xFF1FE85A)];
const _pink = Color(0xFFFF4FB0);
const _soft = Color(0xFFB8AEDA);

/// Plays mission [m]: a match on the versus screen, a puzzle or a board
/// mission on the Zincir screen.
Future<void> playMission(BuildContext context, Settings settings, AudioService audio, Haptics? haptics, ChainMission m) => switch (m.kind) {
  MissionKind.versus => ChainVersusScreen.open(context, settings: settings, audio: audio, haptics: haptics, rival: ChainRival.values[m.target], mission: m),
  MissionKind.puzzle => ChainScreen.open(context, settings: settings, audio: audio, haptics: haptics, mode: ChainMode.puzzle, puzzle: m.target, mission: m),
  _ => ChainScreen.open(context, settings: settings, audio: audio, haptics: haptics, mode: ChainMode.mission, mission: m),
};

IconData missionIcon(MissionKind k) => switch (k) {
  MissionKind.chain => Icons.link_rounded,
  MissionKind.score => Icons.emoji_events_rounded,
  MissionKind.garbage => Icons.view_stream_rounded,
  MissionKind.survive => Icons.timer_rounded,
  MissionKind.puzzle => Icons.extension_rounded,
  MissionKind.versus => Icons.sports_kabaddi_rounded,
};

// ------------------------------------------------------------- the ferry line

/// "Vapur Hattı": the Bosphorus from above, the ferry's route zig-zagging
/// from pier to pier, five missions at each.
class ChainMissionsScreen extends StatefulWidget {
  const ChainMissionsScreen({super.key, required this.settings, required this.audio, this.haptics});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;

  static Future<void> open(BuildContext context, {required Settings settings, required AudioService audio, Haptics? haptics}) => Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => ChainMissionsScreen(settings: settings, audio: audio, haptics: haptics),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );

  /// Map height and where pier [p] sits on it.
  static const double step = 130;
  static const double bottom = 300;
  static const double top = 160;
  static double height() => bottom + (ChainMissions.piers.length - 1) * step + top;
  static Offset pier(int p, double width) => Offset(p.isEven ? width * 0.27 : width * 0.73, height() - bottom - p * step);

  @override
  State<ChainMissionsScreen> createState() => _ChainMissionsScreenState();
}

class _ChainMissionsScreenState extends State<ChainMissionsScreen> {
  ScrollController? _scroll;
  bool _locked = false;
  int? _picked;

  Settings get settings => widget.settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locked) {
      _locked = true;
      OrientationLock.portrait(context);
    }
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  int get _next => min(settings.nextMission, ChainMissions.count);

  void _play(ChainMission m) {
    widget.audio.play(Sfx.click);
    playMission(context, settings, widget.audio, widget.haptics, m);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF16122A),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            final h = ChainMissionsScreen.height();
            final current = ChainMissions.pierOf(_next);
            final pier = _picked ?? current;
            if (_scroll == null) {
              final y = h - ChainMissionsScreen.pier(current, width).dy;
              _scroll = ScrollController(initialScrollOffset: max(0, y - box.maxHeight * 0.5));
            }
            return Stack(
              children: [
                SingleChildScrollView(
                  controller: _scroll,
                  reverse: true,
                  child: SizedBox(
                    width: width,
                    height: h,
                    child: Stack(
                      children: [
                        RepaintBoundary(child: CustomPaint(size: Size(width, h), painter: _FerryMapPainter(width: width, current: current, done: [for (var p = 0; p < ChainMissions.piers.length; p++) _pierStars(p)]))),
                        for (var p = 0; p < ChainMissions.piers.length; p++) _pierNode(context, p, width, current),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        GlassIconButton(key: const ValueKey('missions-back'), icon: Icons.arrow_back_rounded, tooltip: s.back, onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(s.chainMissionsTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _pink)),
                                      Text(s.chainTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _soft)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.star_rounded, color: Color(0xFFFFC21A), size: 22),
                                Text(' ${settings.totalMissionStars}/${ChainMissions.count * 3}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(left: 12, right: 12, bottom: 0, child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _PierCard(pier: pier, settings: settings, next: _next, onPlay: _play)))),
              ],
            );
          },
        ),
      ),
    );
  }

  int _pierStars(int p) => [for (var i = 1; i <= ChainMissions.perPier; i++) settings.missionStars(p * ChainMissions.perPier + i)].fold(0, (a, b) => a + b);

  Widget _pierNode(BuildContext context, int p, double width, int current) {
    final at = ChainMissionsScreen.pier(p, width);
    final s = AppStrings.of(context);
    final open = p <= current;
    final left = p.isEven;
    return Positioned(
      left: left ? at.dx - 40 : at.dx - 190,
      top: at.dy - 40,
      width: 230,
      height: 80,
      child: GestureDetector(
        key: ValueKey('pier-$p'),
        behavior: HitTestBehavior.opaque,
        onTap: open
            ? () {
                widget.audio.play(Sfx.click);
                setState(() => _picked = p);
              }
            : null,
        child: Row(
          textDirection: left ? TextDirection.ltr : TextDirection.rtl,
          children: [
            const SizedBox(width: 80),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(ChainMissions.piers[p], maxLines: 1, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: open ? Colors.white : _soft.withValues(alpha: 0.7))),
                  ),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(s.pierMissions(p * ChainMissions.perPier + 1), maxLines: 1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _soft))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The picked pier's five missions, each with its stars and a play button.
class _PierCard extends StatelessWidget {
  const _PierCard({required this.pier, required this.settings, required this.next, required this.onPlay});

  final int pier;
  final Settings settings;
  final int next;
  final ValueChanged<ChainMission> onPlay;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      key: const ValueKey('pier-card'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xF52A2440),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _pink, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.of(context).upper(ChainMissions.piers[pier]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFFFE066), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          for (var i = 1; i <= ChainMissions.perPier; i++) _row(context, s, ChainMissions.of(pier * ChainMissions.perPier + i)),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppStrings s, ChainMission m) {
    final stars = settings.missionStars(m.number);
    final open = m.number <= next;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Opacity(
        opacity: open ? 1 : 0.45,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: const Color(0xFF110D1C), borderRadius: BorderRadius.circular(10)),
              child: Icon(missionIcon(m.kind), color: m.number == next ? _pink : Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(s.missionText(m), maxLines: 2, style: const TextStyle(fontSize: 14, height: 1.15, fontWeight: FontWeight.w800, color: Colors.white))),
            for (var k = 0; k < 3; k++) Icon(Icons.star_rounded, size: 16, color: k < stars ? const Color(0xFFFFC21A) : Colors.white24),
            const SizedBox(width: 6),
            SizedBox(
              height: 32,
              child: GestureDetector(
                key: ValueKey('mission-${m.number}'),
                onTap: open ? () => onPlay(m) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: m.number == next ? const [Color(0xFFFF7AC6), Color(0xFFE0247A)] : const [Color(0xFF4A4060), Color(0xFF332B4C)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: open ? Text(s.missionPlay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)) : const Icon(Icons.lock_rounded, size: 16, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FerryMapPainter extends CustomPainter {
  _FerryMapPainter({required this.width, required this.current, required this.done});

  final double width;
  final int current;

  /// Stars earned at each pier.
  final List<int> done;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF16122A));
    // The Bosphorus winding north, both shores lit.
    final sea = Path()..moveTo(w * 0.42, 0);
    for (var y = 0.0; y <= h; y += 40) {
      sea.lineTo(w * (0.38 + 0.08 * sin(y / 160)), y);
    }
    for (var y = h; y >= 0; y -= 40) {
      sea.lineTo(w * (0.64 + 0.08 * sin(y / 160 + 1.4)), y);
    }
    sea.close();
    canvas.drawPath(sea, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), const [Color(0xFF1A2460), Color(0xFF2A3A8A), Color(0xFF1A2460)], const [0, 0.5, 1]));
    final rnd = Random(4);
    for (var i = 0; i < 400; i++) {
      final y = rnd.nextDouble() * h;
      final x = w * (0.42 + 0.18 * rnd.nextDouble() + 0.08 * sin(y / 160));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 8 + rnd.nextDouble() * 14, height: 2), const Radius.circular(2)), Paint()..color = const Color(0x447FA8FF));
    }
    for (var i = 0; i < 1600; i++) {
      final left = i.isEven;
      final x = left ? rnd.nextDouble() * w * 0.32 : w * 0.72 + rnd.nextDouble() * w * 0.28;
      canvas.drawCircle(Offset(x, rnd.nextDouble() * h), 0.8 + rnd.nextDouble(), Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.2 + rnd.nextDouble() * 0.45));
    }
    // The two old bridges: between Ortaköy and Beylerbeyi, and past
    // Kandilli by Rumelihisarı.
    final piers = [for (var p = 0; p < ChainMissions.piers.length; p++) ChainMissionsScreen.pier(p, w)];
    for (final y in [(piers[6].dy + piers[7].dy) / 2 + 24, (piers[11].dy + piers[12].dy) / 2 + 24]) {
      final bridge = Paint()
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFFFE27A).withValues(alpha: 0.7);
      canvas.drawLine(Offset(w * 0.28, y), Offset(w * 0.78, y), bridge);
      for (final x in [w * 0.36, w * 0.7]) {
        canvas.drawLine(Offset(x, y), Offset(x, y - 46), bridge);
      }
      canvas.drawPath(Path()
        ..moveTo(w * 0.36, y - 46)
        ..quadraticBezierTo(w * 0.53, y + 4, w * 0.7, y - 46), bridge);
    }
    // The route, dotted: gold where the ferry has been.
    final pts = piers;
    final route = Path()..moveTo(pts.first.dx, pts.first.dy + 140);
    route.lineTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      route.cubicTo(a.dx, a.dy - 60, b.dx, b.dy + 60, b.dx, b.dy);
    }
    final reached = current;
    for (final m in route.computeMetrics()) {
      final until = m.length * (140 + reached * ChainMissionsScreen.step * 1.15) / (140 + (pts.length - 1) * ChainMissionsScreen.step * 1.15);
      for (var d = 0.0; d < m.length; d += 14) {
        final gold = d <= until;
        canvas.drawCircle(m.getTangentForOffset(d)!.position, gold ? 3.4 : 2.6, Paint()..color = gold ? const Color(0xFFFFE066) : Colors.white.withValues(alpha: 0.3));
      }
    }
    // Piers: an anchor in a coin, gold when done, pink for the current one.
    for (var p = 0; p < pts.length; p++) {
      final c = pts[p];
      final isCurrent = p == current;
      final full = done[p] > 0 && p < current;
      final locked = p > current;
      final r = isCurrent ? 34.0 : 28.0;
      if (isCurrent) canvas.drawCircle(c, r + 14, Paint()..color = _pink.withValues(alpha: 0.3));
      canvas.drawCircle(c + const Offset(0, 4), r, Paint()..color = Colors.black.withValues(alpha: 0.4));
      canvas.drawCircle(c, r, Paint()
        ..shader = ui.Gradient.linear(c - Offset(0, r), c + Offset(0, r),
            locked ? const [Color(0xFF7A7090), Color(0xFF4A4260)] : full ? const [Color(0xFFFFE066), Color(0xFFE0A000)] : const [Color(0xFFFF7AC6), Color(0xFFE0247A)]));
      canvas.drawCircle(c, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white);
      final a = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = locked ? const Color(0xFFC8C0D8) : Colors.white;
      canvas.drawLine(c + const Offset(0, -12), c + const Offset(0, 12), a);
      canvas.drawLine(c + const Offset(-7, -6), c + const Offset(7, -6), a);
      canvas.drawArc(Rect.fromCircle(center: c + const Offset(0, 2), radius: 11), 0.3, pi - 0.6, false, a);
      canvas.drawCircle(c + const Offset(0, -15), 3.5, a);
      // Its stars below the name.
      final left = p.isEven;
      final sx = left ? c.dx + r + 18 : c.dx - r - 18 - 50;
      for (var k = 0; k < 3; k++) {
        paintGoldStar(canvas, Offset(sx + k * 19, c.dy + 30), 7, on: done[p] >= (k + 1) * ChainMissions.perPier);
      }
    }
    // The ferry at the current pier.
    final f = pts[current] + const Offset(0, 44);
    canvas.drawPath(Path()..addPolygon([f + const Offset(-22, 0), f + const Offset(22, 0), f + const Offset(17, 8), f + const Offset(-17, 8)], true), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(f.dx - 13, f.dy - 8, 26, 8), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(f.dx - 2, f.dy - 16, 5, 8), Paint()..color = const Color(0xFFFFD000));
  }

  @override
  bool shouldRepaint(_FerryMapPainter old) => old.width != width || old.current != current || !_same(old.done, done);

  static bool _same(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return a.length == b.length;
  }
}

// --------------------------------------------------------------- puzzles

/// The puzzle packs: four İstanbul places, twenty puzzles each.
class ChainPuzzlesScreen extends StatelessWidget {
  const ChainPuzzlesScreen({super.key, required this.settings, required this.audio, this.haptics});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;

  static Future<void> open(BuildContext context, {required Settings settings, required AudioService audio, Haptics? haptics}) => Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => ChainPuzzlesScreen(settings: settings, audio: audio, haptics: haptics),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );

  /// Puzzle [n] can be played: the first, or one after a solved one; the
  /// last pack waits for the ferry to reach Bebek.
  static bool canPlay(Settings settings, int n) {
    if (ChainPuzzles.packOf(n) == ChainPuzzles.packs - 1 && settings.nextMission <= ChainMissions.piers.indexOf('Bebek') * ChainMissions.perPier) return false;
    return n == 1 || settings.puzzleStars(n - 1) > 0 || settings.puzzleStars(n) > 0;
  }

  /// The scene behind pack [i]'s card.
  static int _scene(int i) => const [0, 3, 4, 2][i];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    return Scaffold(
      backgroundColor: p.background.first,
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            children: [
              Row(
                children: [
                  GlassIconButton(key: const ValueKey('puzzles-back'), icon: Icons.arrow_back_rounded, tooltip: s.back, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  Expanded(child: GradientText(s.chainPuzzlesTitle, gradient: const LinearGradient(colors: _chainColors), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
                  Text('${settings.puzzlesSolved}/${ChainPuzzles.count}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: p.text)),
                ],
              ),
              Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 12), child: Text(s.puzzlesHow, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.muted))),
              for (var i = 0; i < ChainPuzzles.packs; i++) ...[_pack(context, s, i), const SizedBox(height: 14)],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pack(BuildContext context, AppStrings s, int i) {
    final first = i * ChainPuzzles.perPack + 1;
    final solved = [for (var n = first; n < first + ChainPuzzles.perPack; n++) settings.puzzleStars(n) > 0].where((b) => b).length;
    final locked = !canPlay(settings, first);
    final bebek = i == ChainPuzzles.packs - 1 && locked;
    return ClipRRect(
      key: ValueKey('pack-$i'),
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SceneCard(_scene(i)))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xF0231D36), const Color(0xC0231D36), const Color(0x40231D36)], stops: const [0, 0.55, 1])))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$first–${first + ChainPuzzles.perPack - 1} · ${s.packLevel(i)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFE066))),
                Text(s.packName(i), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 8),
                if (bebek)
                  Text(s.packBebek, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _soft))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var n = first; n < first + ChainPuzzles.perPack; n++) _cell(context, n),
                    ],
                  ),
                const SizedBox(height: 6),
                Text('$solved/${ChainPuzzles.perPack}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int n) {
    final stars = settings.puzzleStars(n);
    final open = canPlay(settings, n);
    return GestureDetector(
      key: ValueKey('puzzle-$n'),
      onTap: open
          ? () {
              audio.play(Sfx.click);
              ChainScreen.open(context, settings: settings, audio: audio, haptics: haptics, mode: ChainMode.puzzle, puzzle: n);
            }
          : null,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: stars > 0 ? const Color(0xFFFFC21A) : (open ? const Color(0xFFFF4FB0) : const Color(0x55FFFFFF)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: open ? Text('$n', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: stars > 0 ? const Color(0xFF6A3A00) : Colors.white)) : const Icon(Icons.lock_rounded, size: 16, color: Colors.white70),
      ),
    );
  }
}

class _SceneCard extends CustomPainter {
  const _SceneCard(this.scene);

  final int scene;

  @override
  void paint(Canvas canvas, Size size) => paintStoryScene(canvas, size, scene, t: 6);

  @override
  bool shouldRepaint(_SceneCard old) => old.scene != scene;
}
