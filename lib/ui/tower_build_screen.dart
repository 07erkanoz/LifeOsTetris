import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/audio_service.dart';
import '../core/tower/tower_landmarks.dart';
import '../game/render/background_painter.dart';
import '../game/sugar/istanbul_art.dart' show paintBosphorus, paintDusk, paintSkyline;
import '../game/tower/landmark_art.dart';
import '../l10n/strings.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'tower_screen.dart' show claimLandmarkPrizes;
import 'widgets.dart';

/// İstanbul'u İnşa Et: the landmark the floors are raising now, its parts,
/// and the road of all eight.
class TowerBuildScreen extends StatefulWidget {
  const TowerBuildScreen({super.key, required this.settings, required this.audio});

  final Settings settings;
  final AudioService audio;

  static Future<void> open(BuildContext context, {required Settings settings, required AudioService audio}) => Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => TowerBuildScreen(settings: settings, audio: audio),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  State<TowerBuildScreen> createState() => _TowerBuildScreenState();
}

class _TowerBuildScreenState extends State<TowerBuildScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6)..start();
  final ValueNotifier<double> _time = ValueNotifier(0);

  /// The landmark shown: the one being built unless another is picked.
  Landmark? _picked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => claimLandmarkPrizes(context, widget.settings, widget.audio));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final build = widget.settings.towerBuild;
    final shown = _picked ?? build.current ?? Landmark.values.last;
    final finished = build.isDone(shown);
    final parts = build.partsDone(shown);
    return Scaffold(
      backgroundColor: p.background.first,
      body: CustomPaint(
        painter: BackgroundBasePainter(p),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  Row(
                    children: [
                      GlassIconButton(key: const ValueKey('build-back'), icon: Icons.arrow_back_rounded, tooltip: s.back, size: 40, onTap: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(s.towerBuildTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: p.text)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AspectRatio(
                    aspectRatio: 1.1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 4 : 22),
                      child: RepaintBoundary(
                        child: CustomPaint(painter: _LandmarkScene(shown, build, _time)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(s.landmarkName(shown.name), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: p.text)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 10,
                            child: LinearProgressIndicator(value: build.fraction(shown), backgroundColor: p.track, valueColor: const AlwaysStoppedAnimation(Color(0xFFFF5FB8))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${s.score(build.into(shown))} / ${s.score(shown.floors)}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.text)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(build.current == null ? s.towerAllDone : s.towerBuildIntro, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.muted)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < Landmark.parts; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PartRow(
                        name: s.landmarkPart(shown.name, i),
                        state: finished || i < parts
                            ? _PartState.done
                            : i == parts
                            ? _PartState.current
                            : _PartState.locked,
                        detail: i < parts || finished
                            ? s.floorsLine(BuildProgress.partAt(shown, i))
                            : i == parts
                            ? s.towerLeft(BuildProgress.partAt(shown, i) - build.into(shown))
                            : s.floorsLine(BuildProgress.partAt(shown, i)),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CardLabel(s.landmarksLabel),
                      const Spacer(),
                      Text(s.totalFloors(build.total), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final l in Landmark.values)
                        _LandmarkTile(
                          landmark: l,
                          progress: build,
                          picked: l == shown,
                          onTap: l.index <= build.done ? () => setState(() => _picked = l) : null,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandmarkScene extends CustomPainter {
  _LandmarkScene(this.landmark, this.build, this.time) : super(repaint: time);

  final Landmark landmark;
  final BuildProgress build;
  final ValueNotifier<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    paintDusk(canvas, Offset.zero & size);
    final horizon = size.height * 0.8;
    paintSkyline(canvas, size.width, horizon, size.height * 0.7, const Color(0xFF4A2A6A));
    paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height - horizon), ferryAt: 0.1 + 0.05 * sin(time.value * 0.3), tower: 0);
    final k = min(size.width / 330, size.height * 0.74 / 440);
    final done = build.isDone(landmark) ? Landmark.parts : build.partsDone(landmark);
    paintLandmark(canvas, landmark, Offset(size.width / 2, horizon + 6), k, done: done, rising: build.isDone(landmark) ? 0 : build.partFraction(landmark), time: time.value);
  }

  @override
  bool shouldRepaint(_LandmarkScene old) => old.landmark != landmark || old.build.total != build.total;
}

enum _PartState { done, current, locked }

class _PartRow extends StatelessWidget {
  const _PartRow({required this.name, required this.state, required this.detail});

  final String name;
  final _PartState state;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final current = state == _PartState.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: p.flat
          ? flatCardDecoration(p, radius: p.skin == GameSkin.pixel ? 4 : 14, depth: 3, glow: current ? 1 : 0)
          : BoxDecoration(
              color: p.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: current ? p.accent1 : p.glassBorder, width: current ? 2 : 1.2),
            ),
      child: Row(
        children: [
          GameIcon(
            switch (state) {
              _PartState.done => Icons.check_circle_rounded,
              _PartState.current => Icons.construction_rounded,
              _PartState.locked => Icons.lock_rounded,
            },
            size: 19,
            color: switch (state) {
              _PartState.done => const Color(0xFFFACC15),
              _PartState.current => const Color(0xFFFF5FB8),
              _PartState.locked => p.label,
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: state == _PartState.locked ? p.muted : p.text)),
          ),
          Text(detail, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: current ? const Color(0xFFFF5FB8) : p.muted)),
        ],
      ),
    );
  }
}

class _LandmarkTile extends StatelessWidget {
  const _LandmarkTile({required this.landmark, required this.progress, required this.picked, required this.onTap});

  final Landmark landmark;
  final BuildProgress progress;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final done = progress.isDone(landmark);
    final locked = landmark.index > progress.done;
    return GestureDetector(
      key: ValueKey('landmark-${landmark.name}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: p.flat
            ? flatCardDecoration(p, radius: p.skin == GameSkin.pixel ? 4 : 14, depth: 3, glow: picked ? 1 : 0)
            : BoxDecoration(
                color: p.glass,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: picked ? p.accent1 : p.glassBorder, width: picked ? 2 : 1.2),
              ),
        child: Column(
          children: [
            Expanded(
              child: Opacity(
                opacity: locked ? 0.45 : 1,
                child: CustomPaint(painter: _TilePainter(landmark, done ? Landmark.parts : progress.partsDone(landmark), locked), size: Size.infinite),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.landmarkName(landmark.name),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, height: 1.1, fontWeight: FontWeight.w800, color: locked ? p.muted : p.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _TilePainter extends CustomPainter {
  _TilePainter(this.landmark, this.done, this.locked);

  final Landmark landmark;
  final int done;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final k = min(size.width / 320, size.height / 450);
    paintLandmark(canvas, landmark, Offset(size.width / 2, size.height - 4), k, done: locked ? 0 : done);
  }

  @override
  bool shouldRepaint(_TilePainter old) => old.done != done || old.locked != locked || old.landmark != landmark;
}
