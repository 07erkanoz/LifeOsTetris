import 'dart:math';

import 'package:flutter/material.dart';

import '../core/sugar/sugar_levels.dart';
import '../game/sugar/istanbul_art.dart';
import '../game/sugar/sugar_art.dart';
import '../l10n/strings.dart';
import 'lokum_wardrobe.dart';
import 'sugar_widgets.dart';

/// The story card that opens a Şeker Küpler chapter, in three taps: what
/// happened at this place in İstanbul's history, Ekşi Limon's move, and
/// Lokum's answer. The last tap starts the level.
class StoryCard extends StatefulWidget {
  const StoryCard({super.key, required this.chapter, required this.outfit, required this.onDone, this.moving = true});

  /// 0-based.
  final int chapter;
  final LokumOutfit outfit;
  final VoidCallback onDone;

  /// The scene drifts (visual effects on).
  final bool moving;

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> with TickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 40));
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();

  /// 0: the history, 1: Ekşi Limon speaks, 2: Lokum answers.
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.moving) _clock.repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 2) {
      widget.onDone();
      return;
    }
    setState(() => _page++);
    _enter.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final story = s.chapterStory(widget.chapter);
    return GestureDetector(
      key: const ValueKey('story-card'),
      behavior: HitTestBehavior.opaque,
      onTap: _next,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          final panelH = h - 140;
          final unit = min(w, panelH);
          final limon = min(130.0, unit * 0.26);
          final lokum = min(120.0, unit * 0.24);
          final text = h < 700 ? 14.0 : 16.0;
          return AnimatedBuilder(
            animation: Listenable.merge([_clock, _enter]),
            builder: (context, _) {
              final t = _clock.value * 40;
              final pop = Curves.easeOutBack.transform(_enter.value);
              // What has been said so far stays; the newest part pops in.
              double shown(int page) => _page > page ? 1 : (_page == page ? pop : 0);
              return Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _ScenePainter(widget.chapter, t))),
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 14,
                    height: panelH - 14,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                      // Scrolls only when large text needs more room.
                      child: LayoutBuilder(
                        builder: (context, inner) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: inner.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // The history, like a museum plaque.
                                  Transform.scale(
                                    scale: shown(0),
                                    child: _Plaque(when: story.when, text: story.history, size: text),
                                  ),
                                  SizedBox(height: unit * 0.03),
                                  // Ekşi Limon and his move.
                                  Opacity(
                                    opacity: shown(1).clamp(0.0, 1.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _Bubble(
                                            text: story.limon,
                                            fill: widget.chapter >= SugarLevels.secondSeason ? const Color(0xFFFFD8CC) : const Color(0xFFFFF7A0),
                                            ink: widget.chapter >= SugarLevels.secondSeason ? const Color(0xFF6A0A10) : const Color(0xFF5A3A00),
                                            size: text,
                                            tailRight: true,
                                          ),
                                        ),
                                        Transform.translate(
                                          offset: Offset(0, 5 * sin(t * 1.6)),
                                          child: SizedBox(
                                            width: limon * 1.3,
                                            height: limon * 1.2,
                                            child: CustomPaint(painter: _LimonPainter(laugh: (t * 2).floor().isEven, pepper: widget.chapter >= SugarLevels.secondSeason)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Lokum's answer.
                                  Opacity(
                                    opacity: shown(2).clamp(0.0, 1.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        LokumView(outfit: widget.outfit, pose: _page == 2 ? LokumPose.point : LokumPose.happy, pointLeft: false, size: lokum),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(bottom: lokum * 0.5),
                                            child: _Bubble(text: story.lokum, fill: Colors.white, ink: sugarInk, size: text),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The chapter's name, the pages and the prompt.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CandyText(s.chapterLabel(widget.chapter), size: 20, colors: const [Colors.white, Color(0xFFFFE3F4)]),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CandyText(s.chapterPlace(widget.chapter), size: 38, colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)]),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Container(
                                width: i == _page ? 18 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: i <= _page ? 1 : 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            const SizedBox(width: 14),
                            Opacity(opacity: 0.65 + 0.35 * sin(t * 3).abs(), child: CandyText(_page == 2 ? s.storyTap : s.storyNext, size: 17, stroke: 0.12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// The history, on a dark plaque with its year and place.
class _Plaque extends StatelessWidget {
  const _Plaque({required this.when, required this.text, required this.size});

  final String when;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    decoration: BoxDecoration(
      color: const Color(0xFF1E0E33).withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2B33C), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.of(context).upper(when),
          style: TextStyle(fontFamily: 'Baloo2', fontSize: size * 0.9, fontWeight: FontWeight.w800, color: const Color(0xFFFFD36B), letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
        ),
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fill, required this.ink, required this.size, this.tailRight = false});

  final String text;
  final Color fill;
  final Color ink;
  final double size;

  /// The pointed corner faces right (the speaker is on the right).
  final bool tailRight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(tailRight ? 18 : 4),
        bottomRight: Radius.circular(tailRight ? 4 : 18),
      ),
      boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 4))],
    ),
    child: Text(
      text,
      style: TextStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: FontWeight.w800, color: ink, height: 1.2),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.chapter, this.t);

  final int chapter;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    paintStoryScene(canvas, size, chapter, t: t);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.chapter != chapter || old.t != t;
}

class _LimonPainter extends CustomPainter {
  _LimonPainter({required this.laugh, this.pepper = false});

  final bool laugh;

  /// Acı Biber, the second season's rival, instead.
  final bool pepper;

  @override
  void paint(Canvas canvas, Size size) => pepper
      ? paintAciBiber(canvas, Offset(size.width / 2, size.height * 0.5), size.height / 1.3, laugh: laugh)
      : paintEksiLimon(canvas, Offset(size.width / 2, size.height * 0.55), size.height / 1.3, laugh: laugh);

  @override
  bool shouldRepaint(_LimonPainter old) => old.laugh != laugh || old.pepper != pepper;
}
