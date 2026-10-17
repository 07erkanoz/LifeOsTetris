import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/sugar/sugar_game.dart';
import '../core/sugar/sugar_levels.dart';
import '../game/sugar/istanbul_art.dart';
import '../game/sugar/sugar_art.dart';
import '../l10n/strings.dart';

/// A booster's name.
String sugarBoosterName(AppStrings s, SugarBooster b) => switch (b) {
  SugarBooster.hammer => s.sugarHammer,
  SugarBooster.rainbow => s.sugarRainbow,
  SugarBooster.moves => s.sugarExtraMoves(SugarBooster.extraMoves),
  SugarBooster.shuffle => s.sugarShuffle,
};

/// Pieces of the Şeker Küpler screens: candy text, buttons and panels,
/// goal icons, the star bar, boosters and the backdrop.

const sugarInk = Color(0xFF5A1F7A);
const sugarPink = [Color(0xFFFF9AD8), Color(0xFFE0247A)];
const sugarGreen = [Color(0xFF6BF0A0), Color(0xFF1FB85A)];
const sugarWhite = [Color(0xFFFFFFFF), Color(0xFFFFE3F4)];

/// Text with a thick outline, the candy way.
class CandyText extends StatelessWidget {
  const CandyText(this.text, {super.key, this.size = 20, this.color = Colors.white, this.colors, this.outline = const Color(0xFF6A0E4A), this.stroke = 0.18, this.align = TextAlign.center});

  final String text;
  final double size;
  final Color color;
  final List<Color>? colors;
  final Color outline;
  final double stroke;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    TextStyle style(Paint p) => TextStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: FontWeight.w800, height: 1.05, foreground: p);
    final fill = Paint()..color = color;
    final gradient = colors;
    if (gradient != null) {
      fill.shader = ui.Gradient.linear(Offset(0, size * 0.1), Offset(0, size), gradient, [for (var i = 0; i < gradient.length; i++) i / (gradient.length - 1)]);
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        if (stroke > 0)
          Text(text, textAlign: align, style: style(Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * stroke
            ..strokeJoin = StrokeJoin.round
            ..color = outline)),
        Text(text, textAlign: align, style: style(fill)),
      ],
    );
  }
}

/// A glossy candy button.
class CandyButton extends StatefulWidget {
  const CandyButton({super.key, required this.label, required this.onTap, this.colors = sugarPink, this.icon, this.height = 58, this.width, this.textSize = 22, this.ink = const Color(0xFF8A1550)});

  final String label;
  final VoidCallback? onTap;
  final List<Color> colors;
  final IconData? icon;
  final double height;
  final double? width;
  final double textSize;
  final Color ink;

  @override
  State<CandyButton> createState() => _CandyButtonState();
}

class _CandyButtonState extends State<CandyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.height * 0.4);
    final enabled = widget.onTap != null;
    final light = widget.colors == sugarWhite;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 90),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: widget.colors),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: widget.ink, offset: Offset(0, _down ? 3 : 6))],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 5,
                    height: widget.height * 0.26,
                    child: DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(widget.height))),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[Icon(widget.icon, color: light ? sugarInk : Colors.white, size: widget.textSize * 1.2), const SizedBox(width: 8)],
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: light
                                  ? CandyText(widget.label, size: widget.textSize, color: sugarInk, stroke: 0)
                                  : CandyText(widget.label, size: widget.textSize, outline: widget.ink, stroke: 0.14),
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// A light candy card.
class CandyPanel extends StatelessWidget {
  const CandyPanel({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF7FD), Color(0xFFFFE3F4)]),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [BoxShadow(color: const Color(0xFF2A0B4F).withValues(alpha: 0.7), offset: const Offset(0, 8)), const BoxShadow(color: Color(0x66000000), blurRadius: 30)],
    ),
    child: child,
  );
}

// ------------------------------------------------------------- painters --

/// The icon of a goal: a cube of its colour, a frozen cube, a star.
class SugarGoalIcon extends StatelessWidget {
  const SugarGoalIcon(this.goal, {super.key, this.size = 38});

  final SugarGoal goal;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _GoalIconPainter(goal.kind, goal.color));
}

class _GoalIconPainter extends CustomPainter {
  _GoalIconPainter(this.kind, this.color);

  final GoalKind kind;
  final SugarColor? color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    switch (kind) {
      case GoalKind.color:
        paintCandy(canvas, r, color!);
      case GoalKind.ice:
        paintCandy(canvas, r, SugarColor.blue);
        paintIce(canvas, r, layers: 1, seed: 1);
      case GoalKind.box:
        paintCandyBox(canvas, r);
      case GoalKind.choco:
        paintChocolate(canvas, r);
      case GoalKind.fruit:
        paintPomegranate(canvas, r);
      case GoalKind.cake:
        paintCake(canvas, r.inflate(size.width * 0.08));
      case GoalKind.door:
        paintDoor(canvas, r, sugarColors[SugarColor.blue]!);
      case GoalKind.limon:
        paintEksiLimon(canvas, r.center + Offset(0, size.height * 0.08), size.width * 0.72);
      case GoalKind.score:
        paintGoldStar(canvas, r.center, size.width * 0.46);
    }
  }

  @override
  bool shouldRepaint(_GoalIconPainter old) => old.kind != kind || old.color != color;
}

/// Gold stars in a row: [on] of [count] lit.
class SugarStars extends StatelessWidget {
  const SugarStars({super.key, required this.on, this.count = 3, this.size = 16, this.arc = false});

  final int on, count;
  final double size;
  final bool arc;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size * 2.3 * count, size * (arc ? 2.6 : 2.2)), painter: _StarsPainter(on, count, size, arc));
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.on, this.count, this.r, this.arc);

  final int on, count;
  final double r;
  final bool arc;

  @override
  void paint(Canvas canvas, Size size) {
    for (var k = 0; k < count; k++) {
      final x = size.width * (k + 0.5) / count;
      final lift = arc && count == 3 && k == 1 ? -r * 0.4 : 0.0;
      paintGoldStar(canvas, Offset(x, size.height / 2 + lift), arc && k == 1 ? r * 1.2 : r, on: k < on);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.on != on || old.count != count || old.r != r;
}

/// The score bar: fills up to three stars.
class SugarScoreBar extends StatelessWidget {
  const SugarScoreBar({super.key, required this.score, required this.stars, this.goalsDone = false, this.pulse = const [0, 0, 0]});

  final int score;
  final List<int> stars;
  final bool goalsDone;

  /// 0..1 glow on each star just reached.
  final List<double> pulse;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(double.infinity, 38), painter: _ScoreBarPainter(score, stars, goalsDone, List.of(pulse)));
}

class _ScoreBarPainter extends CustomPainter {
  _ScoreBarPainter(this.score, this.stars, this.goalsDone, this.pulse);

  final int score;
  final List<int> stars;
  final bool goalsDone;
  final List<double> pulse;

  static const _marks = [0.3, 0.62, 0.92];

  /// Where [score] sits on the bar: the stars are evenly spaced and the
  /// fill runs between them.
  double share(int score) {
    var from = 0, at = 0.0;
    for (var k = 0; k < 3; k++) {
      if (score < stars[k]) return at + (_marks[k] - at) * (score - from) / max(1, stars[k] - from);
      from = stars[k];
      at = _marks[k];
    }
    return min(1.0, at + 0.08 * (score - from) / max(1, stars[2] * 0.3));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(Rect.fromLTWH(14, size.height / 2 - 10, size.width - 28, 20), const Radius.circular(10));
    canvas.drawRRect(bar.shift(const Offset(0, 3)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.6));
    canvas.drawRRect(bar, Paint()..color = const Color(0xFF3B1466));
    final share = this.share(score);
    if (share > 0) {
      final fill = RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, max(bar.height, bar.width * share), bar.height), const Radius.circular(10));
      canvas.drawRRect(fill, Paint()..shader = ui.Gradient.linear(fill.outerRect.centerLeft, fill.outerRect.centerRight, const [Color(0xFFFFE066), Color(0xFFFF8A00)]));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.left + 6, bar.top + 4, max(0, fill.outerRect.width - 12), 5), const Radius.circular(3)),
          Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
    for (var k = 0; k < 3; k++) {
      final c = Offset(bar.left + bar.width * _marks[k], bar.center.dy);
      if (pulse[k] > 0) {
        canvas.drawCircle(c, 26 * pulse[k] + 10, Paint()
          ..color = const Color(0xFFFFE066).withValues(alpha: 0.7 * pulse[k])
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
      paintGoldStar(canvas, c, 15 * (1 + 0.45 * pulse[k]), on: score >= stars[k]);
    }
  }

  @override
  bool shouldRepaint(_ScoreBarPainter old) => old.score != score || old.goalsDone != goalsDone || old.stars != stars || old.pulse.join() != pulse.join();
}

/// The moves left, in a pink bubble that throbs red near the end.
class SugarMovesBubble extends StatelessWidget {
  const SugarMovesBubble({super.key, required this.moves, required this.label, this.size = 84, this.warn = 0});

  final int moves;
  final String label;
  final double size;

  /// 0..1 red throb.
  final double warn;

  @override
  Widget build(BuildContext context) {
    final colors = [Color.lerp(const Color(0xFFFF7AC6), const Color(0xFFFF6A6A), warn)!, Color.lerp(const Color(0xFFE0247A), const Color(0xFFC0122A), warn)!];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.25, -0.35), radius: 0.9, colors: colors),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: const Color(0xFF7A1C5B), offset: const Offset(0, 4)), if (warn > 0) BoxShadow(color: const Color(0xFFFF3B5C).withValues(alpha: 0.6 * warn), blurRadius: 18)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CandyText('$moves', size: size * 0.42, outline: const Color(0xFF8A1550), stroke: 0.12),
          CandyText(label, size: size * 0.15, outline: const Color(0xFF8A1550), stroke: 0.2),
        ],
      ),
    );
  }
}

/// A booster: a round button with its icon, a count badge and a name.
class SugarBoosterButton extends StatelessWidget {
  const SugarBoosterButton({super.key, required this.kind, required this.count, required this.label, required this.onTap, this.active = false, this.size = 64});

  final SugarBooster kind;
  final int count;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final empty = count <= 0;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: empty ? null : onTap,
        child: Opacity(
          opacity: empty ? 0.5 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size + 14,
                height: size + 8,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.25, -0.3),
                          colors: active ? const [Color(0xFFFFF6B0), Color(0xFFFFC21A)] : const [Color(0xFFFFFFFF), Color(0xFFFFD6F0)],
                        ),
                        border: Border.all(color: active ? Colors.white : const Color(0xFFFF7AC6), width: 3),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF2A0B4F).withValues(alpha: 0.7), offset: const Offset(0, 5)),
                          if (active) const BoxShadow(color: Color(0xAAFFE066), blurRadius: 20),
                        ],
                      ),
                      child: CustomPaint(painter: _BoosterIconPainter(kind)),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: empty ? const Color(0xFF8E86A8) : const Color(0xFF2BD96B), border: Border.all(color: Colors.white, width: 2.5)),
                        child: CandyText('$count', size: 14, stroke: 0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              CandyText(label, size: 14, outline: const Color(0xFF3A0F60), stroke: 0.22),
            ],
          ),
        ),
      ),
    );
  }
}

/// A booster's icon on its own.
class SugarBoosterIcon extends StatelessWidget {
  const SugarBoosterIcon(this.kind, {super.key, this.size = 40});

  final SugarBooster kind;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _BoosterIconPainter(kind));
}

class _BoosterIconPainter extends CustomPainter {
  _BoosterIconPainter(this.kind);

  final SugarBooster kind;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final k = size.width / 68;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(k);
    switch (kind) {
      case SugarBooster.hammer:
        canvas.rotate(-0.6);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 6), width: 7, height: 34), const Radius.circular(3)), Paint()..color = const Color(0xFFB0703A));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -12), width: 32, height: 16), const Radius.circular(5)),
            Paint()..shader = ui.Gradient.linear(const Offset(0, -20), const Offset(0, -4), const [Color(0xFFDDE3EE), Color(0xFF7D879A)]));
      case SugarBooster.rainbow:
        paintRainbow(canvas, Rect.fromCenter(center: Offset.zero, width: 44, height: 44));
      case SugarBooster.moves:
        paintSugarLabel(canvas, '+${SugarBooster.extraMoves}', Offset.zero, 28,
            Paint()..shader = ui.Gradient.linear(const Offset(0, -14), const Offset(0, 14), const [Color(0xFFFF7AC6), Color(0xFFE0247A)]),
            outline: Colors.white, stroke: 0.18);
      case SugarBooster.shuffle:
        // Three sweets chasing each other round.
        for (var i = 0; i < 3; i++) {
          final a = -pi / 2 + i * pi * 2 / 3;
          canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: 17), a + 0.35, 1.5, false, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFE0247A));
          paintCandy(canvas, Rect.fromCenter(center: Offset(cos(a), sin(a)) * 17, width: 18, height: 18), SugarColor.values[i * 2]);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoosterIconPainter old) => old.kind != kind;
}

/// The sweet dusk behind the board, a little different per chapter.
/// The story scene behind the board for an unlocked scene name, or null
/// for the chapter's own sky.
int? sugarSceneIndex(String? name) => switch (name) {
  'sceneGalata' => 4,
  'sceneSnow' => 1,
  'sceneIslands' => 5,
  'sceneCamlica' => 11,
  _ => null,
};

class SugarBackdrop extends StatelessWidget {
  const SugarBackdrop({super.key, this.chapter = 0, this.scene});

  final int chapter;

  /// An İstanbul scene (a story chapter) instead of the chapter's sky.
  final int? scene;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BackdropPainter(chapter, scene), size: Size.infinite);
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.chapter, this.scene);

  final int chapter;
  final int? scene;

  static const _skies = [
    [Color(0xFF5B1FA8), Color(0xFFB0307E), Color(0xFF3A1470)],
    [Color(0xFF2B3FA8), Color(0xFF6A5AD8), Color(0xFF281470)],
    [Color(0xFF3A1F6A), Color(0xFF8A2F5E), Color(0xFF1E0F3A)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final view = scene;
    if (view != null) {
      // The scene, dimmed a little so the board stays easy to read.
      canvas.save();
      canvas.clipRect(screen);
      paintBackdropScene(canvas, size, view, t: 8);
      canvas.restore();
      canvas.drawRect(screen, Paint()..color = const Color(0xFF1E0B3A).withValues(alpha: 0.25));
      return;
    }
    canvas.drawRect(screen, Paint()..shader = ui.Gradient.linear(screen.topCenter, screen.bottomCenter, _skies[chapter % 3], const [0, 0.55, 1]));
    final rnd = Random(4 + chapter);
    for (var i = 0; i < 16; i++) {
      final c = [const Color(0xFFFFB3E6), const Color(0xFF9FD8FF), const Color(0xFFFFE08A)][i % 3];
      canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), 20 + rnd.nextDouble() * 50, Paint()
        ..color = c.withValues(alpha: 0.12 + rnd.nextDouble() * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.chapter != chapter || old.scene != scene;
}

/// Round, light icon button for the top corners.
class SugarRoundButton extends StatelessWidget {
  const SugarRoundButton({super.key, required this.icon, required this.onTap, this.tooltip, this.size = 44});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(center: Alignment(-0.25, -0.3), colors: [Color(0xFFFFFFFF), Color(0xFFFFD6F0)]),
          border: Border.all(color: const Color(0xFFFF7AC6), width: 2.5),
          boxShadow: [BoxShadow(color: const Color(0xFF2A0B4F).withValues(alpha: 0.7), offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: sugarInk, size: size * 0.55),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// A small tag: BOSS, HARD.
class SugarTag extends StatelessWidget {
  const SugarTag(this.text, {super.key, this.colors = const [Color(0xFFFF7A3D), Color(0xFFE02424)]});

  final String text;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: CandyText(text, size: 14, outline: const Color(0xFF7A0E0E), stroke: 0.16),
  );
}

/// The sugar-rush meter: a rainbow fill with its name on it.
class SugarRushMeter extends StatelessWidget {
  const SugarRushMeter({super.key, required this.value, required this.label, this.height = 26});

  final double value;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(double.infinity, height), painter: _RushPainter(value.clamp(0, 1), label));
}

class _RushPainter extends CustomPainter {
  _RushPainter(this.value, this.label);

  final double value;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(size.height / 2));
    if (value > 0.85) {
      canvas.drawRRect(rr.inflate(3), Paint()
        ..color = const Color(0xFFFF7AC6).withValues(alpha: (value - 0.85) / 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.75));
    if (value > 0.04) {
      final fill = RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, max(size.height - 6, (size.width - 6) * value), size.height - 6), Radius.circular(size.height / 2));
      canvas.drawRRect(fill, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [...sugarColors.values], const [0, 0.2, 0.4, 0.6, 0.8, 1]));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(fill.left + 6, fill.top + 3, max(0, fill.width - 12), 4), const Radius.circular(2)),
          Paint()..color = Colors.white.withValues(alpha: 0.45));
    }
    paintSugarLabel(canvas, label, r.center, size.height * 0.5, Paint()..color = Colors.white, outline: const Color(0xFF3A0F60), stroke: 0.25);
  }

  @override
  bool shouldRepaint(_RushPainter old) => old.value != value || old.label != label;
}

/// Lokum, with a speech bubble when it has something to say.
class SugarMascotView extends StatelessWidget {
  const SugarMascotView({
    super.key,
    required this.pose,
    this.line,
    this.hop = 0,
    this.size = 62,
    this.bubbleLeft = true,
    this.outfit = LokumOutfit.none,
    this.beat = 0,
    this.pointLeft = true,
  });

  final LokumPose pose;
  final String? line;
  final double hop;
  final double size;
  final LokumOutfit outfit;

  /// The dance's beat, 0..1 looping.
  final double beat;

  /// Points to the left (else to the right).
  final bool pointLeft;

  /// The bubble opens to the left of Lokum (else to the right).
  final bool bubbleLeft;

  @override
  Widget build(BuildContext context) {
    final lokum = SizedBox(width: size * 1.25, height: size * 1.3, child: CustomPaint(painter: _LokumPainter(pose, hop, outfit, beat, pointLeft)));
    final text = line;
    if (text == null) return lokum;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: size * 3.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF2A0B4F).withValues(alpha: 0.4), offset: const Offset(0, 3))],
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF7A2A9E), height: 1.1)),
    );
    final padded = Padding(padding: const EdgeInsets.only(top: 4), child: bubble);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bubbleLeft ? [padded, lokum] : [lokum, padded],
    );
  }
}

class _LokumPainter extends CustomPainter {
  _LokumPainter(this.pose, this.hop, this.outfit, this.beat, this.pointLeft);

  final LokumPose pose;
  final double hop;
  final LokumOutfit outfit;
  final double beat;
  final bool pointLeft;

  @override
  void paint(Canvas canvas, Size size) =>
      paintLokum(canvas, Offset(size.width / 2, size.height * 0.56), size.height / 1.3, pose: pose, hop: hop, outfit: outfit, beat: beat, pointLeft: pointLeft);

  @override
  bool shouldRepaint(_LokumPainter old) => old.pose != pose || old.hop != hop || old.outfit != outfit || old.beat != beat || old.pointLeft != pointLeft;
}

/// Lokum dancing on his own clock (for the result panels), still when
/// visual effects are off.
class DancingLokum extends StatefulWidget {
  const DancingLokum({super.key, required this.outfit, this.size = 70, this.pose = LokumPose.dance, this.moving = true});

  final LokumOutfit outfit;
  final double size;
  final LokumPose pose;
  final bool moving;

  @override
  State<DancingLokum> createState() => _DancingLokumState();
}

class _DancingLokumState extends State<DancingLokum> with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.moving) _beat.repeat();
  }

  @override
  void didUpdateWidget(DancingLokum old) {
    super.didUpdateWidget(old);
    if (widget.moving && !_beat.isAnimating) _beat.repeat();
    if (!widget.moving) _beat.stop();
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _beat,
    builder: (context, _) => SugarMascotView(pose: widget.pose, outfit: widget.outfit, size: widget.size, beat: _beat.value, hop: widget.pose == LokumPose.dance ? (_beat.value * 2) % 1 : 0),
  );
}
