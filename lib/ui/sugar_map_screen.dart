import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/sugar/sugar_game.dart';
import '../core/sugar/sugar_levels.dart';
import '../game/sugar/sugar_art.dart';
import '../l10n/strings.dart';
import '../platform/orientation_lock.dart';
import '../settings/settings.dart';
import 'game_screen.dart' show showSettingsDialog;
import 'sugar_screen.dart';
import 'sugar_widgets.dart';

/// The Şeker Küpler map: three chapters of levels along a winding road, from
/// the bottom up. "Continue" plays the saved level or the next one.
class SugarMapScreen extends StatefulWidget {
  const SugarMapScreen({super.key, required this.settings, required this.audio, this.haptics});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;

  static Future<void> open(BuildContext context, {required Settings settings, required AudioService audio, Haptics? haptics}) =>
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => SugarMapScreen(settings: settings, audio: audio, haptics: haptics),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );

  /// Height of the map for [width] and where each level sits on it.
  static const double step = 108;
  static const double bottom = 190;
  static const double top = 150;
  static double height() => bottom + (SugarLevels.count - 1) * step + top;

  static const _xs = [0.66, 0.74, 0.52, 0.28, 0.46, 0.72, 0.56, 0.32, 0.24, 0.48];

  static Offset node(int level, double width) => Offset(width * _xs[(level - 1) % _xs.length], height() - bottom - (level - 1) * step);

  @override
  State<SugarMapScreen> createState() => _SugarMapScreenState();
}

class _SugarMapScreenState extends State<SugarMapScreen> {
  ScrollController? _scroll;
  int _chapter = 0;
  bool _locked = false;

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

  int? get _savedLevel {
    final raw = settings.savedSugar;
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map<String, Object?>)['level'] as int?;
    } catch (_) {
      return null;
    }
  }

  void _play(int level) {
    widget.audio.play(Sfx.click);
    SugarScreen.open(context, settings: settings, audio: widget.audio, haptics: widget.haptics, level: level, resume: _savedLevel == level);
  }

  void _onScroll() {
    final s = _scroll!;
    if (!s.hasClients) return;
    // Reversed: offset 0 is the bottom of the map.
    final view = s.position.viewportDimension;
    final middle = s.offset + view / 2;
    final level = ((middle - SugarMapScreen.bottom) / SugarMapScreen.step).round() + 1;
    final chapter = SugarLevels.chapterOf(level.clamp(1, SugarLevels.count));
    if (chapter != _chapter) setState(() => _chapter = chapter);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A8F),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final current = settings.sugarLevel;
          final saved = _savedLevel;
          final cont = saved ?? current;
          return LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              final h = SugarMapScreen.height();
              if (_scroll == null) {
                final y = h - SugarMapScreen.node(current, width).dy;
                _scroll = ScrollController(initialScrollOffset: max(0, y - box.maxHeight * 0.45))..addListener(_onScroll);
                _chapter = SugarLevels.chapterOf(current);
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
                          RepaintBoundary(
                            child: CustomPaint(
                              size: Size(width, h),
                              painter: _MapPainter(
                                width: width,
                                current: current,
                                stars: [for (var n = 1; n <= SugarLevels.count; n++) settings.sugarStars(n)],
                                strings: s,
                              ),
                            ),
                          ),
                          for (var n = 1; n <= SugarLevels.count; n++)
                            Positioned(
                              left: SugarMapScreen.node(n, width).dx - 40,
                              top: SugarMapScreen.node(n, width).dy - 40,
                              width: 80,
                              height: 80,
                              child: Semantics(
                                button: n <= current,
                                label: s.sugarLevel(n),
                                child: GestureDetector(
                                  key: ValueKey('sugar-level-$n'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: n <= current ? () => _play(n) : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Top: back, chapter ribbon, stars.
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SugarRoundButton(key: const ValueKey('sugar-map-back'), icon: Icons.arrow_back_rounded, tooltip: s.back, onTap: () => Navigator.of(context).pop()),
                          const SizedBox(width: 10),
                          Expanded(child: _Ribbon(text: s.sugarChapter(_chapter), chapter: _chapter)),
                          const SizedBox(width: 10),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(color: const Color(0xFF2A0B4F).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SugarStars(on: 1, count: 1, size: 11),
                                CandyText('${settings.totalSugarStars}/${SugarLevels.count * 3}', size: 17, stroke: 0),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SugarRoundButton(
                            key: const ValueKey('sugar-map-settings'),
                            icon: Icons.settings_rounded,
                            tooltip: s.settingsTitle,
                            onTap: () => showSettingsDialog(context, settings),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom: continue.
                  Positioned(
                    left: 34,
                    right: 34,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: CandyButton(
                          key: const ValueKey('sugar-continue'),
                          label: s.sugarContinueLevel(cont),
                          icon: Icons.play_arrow_rounded,
                          height: 64,
                          textSize: 24,
                          onTap: () => _play(cont),
                        ),
                      ),
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

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.text, required this.chapter});

  final String text;
  final int chapter;

  static const _colors = [
    [Color(0xFFFF9AD8), Color(0xFFE0247A)],
    [Color(0xFF7AD8FF), Color(0xFF2E86FF)],
    [Color(0xFFC79BFF), Color(0xFF6A2FC8)],
    [Color(0xFFFFC08A), Color(0xFFFF7A1A)],
    [Color(0xFFFF8A8A), Color(0xFFD0203A)],
    [Color(0xFF8AF0B0), Color(0xFF1FB85A)],
  ];
  static const _ink = [Color(0xFF8A1550), Color(0xFF0E4A9A), Color(0xFF3A0F7A), Color(0xFF8A3A00), Color(0xFF7A0E1A), Color(0xFF0E6A32)];

  @override
  Widget build(BuildContext context) {
    final parts = text.split(' · ');
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _colors[chapter % 6]),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF2A0B4F).withValues(alpha: 0.6), offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CandyText(parts.first, size: 13, outline: _ink[chapter % 6], stroke: 0.18),
          if (parts.length > 1) FittedBox(child: CandyText(parts.last, size: 21, outline: _ink[chapter % 6], stroke: 0.18)),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.width, required this.current, required this.stars, required this.strings});

  final double width;
  final int current;
  final List<int> stars;
  final AppStrings strings;

  static const _skies = [
    [Color(0xFFFFB6D9), Color(0xFFFF8AC2), Color(0xFFB45BFF)],
    [Color(0xFFF2A6D8), Color(0xFF8A5AD8), Color(0xFF3B2A8F)],
    [Color(0xFF6A2FC8), Color(0xFF3A1A6A), Color(0xFF2A1250)],
    [Color(0xFF5A2A8A), Color(0xFFE08A5A), Color(0xFFFFC08A)],
    [Color(0xFFFFB07A), Color(0xFFE0603A), Color(0xFF7A2040)],
    [Color(0xFF7A2040), Color(0xFF3AA8E0), Color(0xFF8AE8FF)],
  ];
  static const _hills = [
    [[Color(0xFFB6F2C8), Color(0xFF5CC98A)], [Color(0xFFD6FFE0), Color(0xFF7ADBA0)]],
    [[Color(0xFFE9E1FF), Color(0xFFB9A6F0)], [Color(0xFFFFFFFF), Color(0xFFCFC2F7)]],
    [[Color(0xFF7A5AA8), Color(0xFF4A2F78)], [Color(0xFF9A7AC8), Color(0xFF5A3A8A)]],
    [[Color(0xFFFFD9B0), Color(0xFFE0A070)], [Color(0xFFFFE8CC), Color(0xFFF0B888)]],
    [[Color(0xFFE08A5A), Color(0xFFA04A2A)], [Color(0xFFF0A070), Color(0xFFB85A30)]],
    [[Color(0xFFFFF2B0), Color(0xFFF0D070)], [Color(0xFF8AF0B0), Color(0xFF3AC878)]],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final step = SugarMapScreen.step;
    double edge(int ch) => h - (SugarMapScreen.bottom + (ch * SugarLevels.perChapter - 0.5) * step);
    // One sky for the whole map, each chapter's colours fading into the next.
    final colors = <Color>[], stops = <double>[];
    for (var ch = 0; ch < SugarLevels.chapters; ch++) {
      final bottom = ch == 0 ? h : edge(ch);
      final top = ch == SugarLevels.chapters - 1 ? 0.0 : edge(ch + 1);
      for (var k = 0; k < 3; k++) {
        colors.add(_skies[ch][k]);
        stops.add(1 - (bottom - (bottom - top) * (0.1 + 0.4 * k)) / h);
      }
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset(0, h), Offset.zero, colors, stops));
    final dots = Random(12);
    for (var i = 0; i < 160; i++) {
      canvas.drawCircle(Offset(dots.nextDouble() * width, dots.nextDouble() * h), 0.8 + dots.nextDouble() * 1.8,
          Paint()..color = Colors.white.withValues(alpha: 0.3 + dots.nextDouble() * 0.5));
    }
    // Hills, far (high on the map) to near, each down to the bottom so they
    // overlap without seams.
    final hills = <(double, int, int)>[];
    for (var ch = 0; ch < SugarLevels.chapters; ch++) {
      final bottom = ch == 0 ? h : edge(ch);
      final top = ch == SugarLevels.chapters - 1 ? 0.0 : edge(ch + 1);
      for (var k = 0; k < 4; k++) {
        hills.add((top + (bottom - top) * (k + 0.75) / 4, ch, k));
      }
    }
    hills.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (y, ch, k) in hills) {
      final rnd = Random(ch * 10 + k);
      final amp = 30.0 + rnd.nextDouble() * 20;
      final phase = rnd.nextDouble() * 6;
      final p = Path()..moveTo(0, h);
      for (var x = 0.0; x <= width; x += 8) {
        p.lineTo(x, y + sin(x / width * pi * 2 + phase) * amp + sin(x / 60 + phase) * amp * 0.25);
      }
      p
        ..lineTo(width, h)
        ..close();
      canvas.drawPath(p, Paint()..shader = ui.Gradient.linear(Offset(0, y - amp), Offset(0, y + 260), _hills[ch][k % 2]));
    }
    for (var ch = 0; ch < SugarLevels.chapters; ch++) {
      final bottom = ch == 0 ? h : edge(ch);
      final top = ch == SugarLevels.chapters - 1 ? 0.0 : edge(ch + 1);
      final rnd = Random(40 + ch);
      for (var i = 0; i < 7; i++) {
        final x = (i.isEven ? 0.08 : 0.9) * width + (rnd.nextDouble() - 0.5) * 40;
        final y = top + 110 + rnd.nextDouble() * (bottom - top - 150);
        switch (ch) {
          case 0:
            _lollipop(canvas, Offset(x, y), 30 + rnd.nextDouble() * 20, i);
          case 1:
            _pine(canvas, Offset(x, y), 46 + rnd.nextDouble() * 24);
          case 2:
            _tower(canvas, Offset(x, y), 50 + rnd.nextDouble() * 26);
          case 3:
            final side = 34 + rnd.nextDouble() * 16;
            paintCandyBox(canvas, Rect.fromCenter(center: Offset(x, y - side / 2), width: side, height: side), layers: 2);
          case 4:
            _rock(canvas, Offset(x, y), 50 + rnd.nextDouble() * 30);
          default:
            _palm(canvas, Offset(x, y), 56 + rnd.nextDouble() * 20, i);
        }
      }
    }

    // The road.
    final pts = [for (var n = 1; n <= SugarLevels.count; n++) SugarMapScreen.node(n, width)];
    final road = Path()..moveTo(pts.first.dx - 40, pts.first.dy + 160);
    road.cubicTo(pts.first.dx - 40, pts.first.dy + 70, pts.first.dx, pts.first.dy + 70, pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      road.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    }
    canvas.drawPath(road, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6E4AB8).withValues(alpha: 0.35));
    canvas.drawPath(road, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.85));
    final dot = Paint()..color = const Color(0xFFFF9AD8);
    for (final metric in road.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 22) {
        canvas.drawCircle(metric.getTangentForOffset(d)!.position, 3, dot);
      }
    }

    // Chests beside every fifth level.
    for (var n = 5; n <= SugarLevels.count; n += 5) {
      if (SugarLevels.of(n).boss) continue;
      final c = pts[n - 1];
      final side = c.dx > width / 2 ? -1 : 1;
      _chest(canvas, c + Offset(side * 92.0, -6), open: stars[n - 1] > 0);
    }

    for (var n = 1; n <= SugarLevels.count; n++) {
      _node(canvas, pts[n - 1], n);
    }
  }

  void _node(Canvas canvas, Offset c, int n) {
    final level = SugarLevels.of(n);
    final done = stars[n - 1] > 0;
    final isCurrent = n == current && !done;
    final open = n <= current;
    final boss = level.boss;
    final r = isCurrent ? 36.0 : (boss ? 34.0 : 28.0);
    if (isCurrent) {
      canvas.drawCircle(c, r + 18, Paint()
        ..color = const Color(0xFFFF7AC6).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
      canvas.drawCircle(c, r + 9, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.85));
    }
    canvas.drawCircle(c + const Offset(0, 6), r, Paint()..color = const Color(0xFF3A1A6A).withValues(alpha: 0.55));
    final colors = done
        ? const [Color(0xFFFFF0A0), Color(0xFFFFB800)]
        : isCurrent
            ? const [Color(0xFFFF9AD8), Color(0xFFE0247A)]
            : open
                ? const [Color(0xFFFFC2E6), Color(0xFFE05AA8)]
                : boss
                    ? const [Color(0xFFFF8A8A), Color(0xFFC81E3A)]
                    : const [Color(0xFFD7D2E6), Color(0xFF8E86A8)];
    canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c - Offset(r * 0.3, r * 0.4), r * 1.5, colors));
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: c - Offset(0, r * 0.45), width: r * 1.1, height: r * 0.45), Paint()..color = Colors.white.withValues(alpha: 0.35));
    if (!open && !boss && !level.hard) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + const Offset(0, 5), width: 22, height: 17), const Radius.circular(4)), Paint()..color = const Color(0xFF5E5778));
      canvas.drawArc(Rect.fromCenter(center: c - const Offset(0, 4), width: 15, height: 16), pi, pi, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF5E5778));
    } else {
      final ink = done ? const Color(0xFFB06A00) : (boss && !open ? const Color(0xFF7A0E22) : (open ? const Color(0xFF8A1550) : const Color(0xFF5E5778)));
      paintSugarLabel(canvas, '$n', c + const Offset(0, 2), isCurrent ? 34 : 26, Paint()..color = Colors.white, outline: ink, stroke: 0.16);
    }
    if (done) {
      for (var k = 0; k < 3; k++) {
        final a = -pi / 2 + (k - 1) * 0.55;
        paintGoldStar(canvas, c + Offset(cos(a), sin(a)) * (r + 12), k == 1 ? 12 : 10, on: k < stars[n - 1]);
      }
    }
    if (isCurrent) {
      final pin = c - Offset(0, r + 46);
      canvas.drawPath(Path()..addPolygon([pin + const Offset(-14, 10), pin + const Offset(14, 10), pin + const Offset(0, 34)], true), Paint()..color = Colors.white);
      canvas.drawCircle(pin, 24, Paint()..color = Colors.white);
      paintCandy(canvas, Rect.fromCenter(center: pin, width: 36, height: 36), SugarColor.values[n % 6], shadow: false);
      final tag = RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, r + 26), width: 92, height: 32), const Radius.circular(16));
      canvas.drawRRect(tag.shift(const Offset(0, 4)), Paint()..color = const Color(0xFF0E6A32));
      canvas.drawRRect(tag, Paint()..shader = ui.Gradient.linear(tag.outerRect.topCenter, tag.outerRect.bottomCenter, sugarGreen));
      paintSugarLabel(canvas, strings.sugarPlay, tag.center, 20, Paint()..color = Colors.white, outline: const Color(0xFF0E6A32), stroke: 0.16);
    }
    if (level.hard) {
      final tag = RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(r + 24, -r + 2), width: 54, height: 24), const Radius.circular(12));
      canvas.drawRRect(tag, Paint()..shader = ui.Gradient.linear(tag.outerRect.topCenter, tag.outerRect.bottomCenter, const [Color(0xFFFF7A3D), Color(0xFFE02424)]));
      canvas.drawRRect(tag, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white);
      paintSugarLabel(canvas, strings.sugarHard, tag.center, 15, Paint()..color = Colors.white, outline: const Color(0xFF7A0E0E), stroke: 0.16);
    }
    if (boss) {
      final k = c - Offset(0, r + (done ? 36 : 14));
      final crown = Path()
        ..moveTo(k.dx - 20, k.dy + 10)
        ..lineTo(k.dx - 22, k.dy - 10)
        ..lineTo(k.dx - 10, k.dy)
        ..lineTo(k.dx, k.dy - 16)
        ..lineTo(k.dx + 10, k.dy)
        ..lineTo(k.dx + 22, k.dy - 10)
        ..lineTo(k.dx + 20, k.dy + 10)
        ..close();
      canvas.drawPath(crown.shift(const Offset(0, 3)), Paint()..color = const Color(0xFF7A3A00));
      canvas.drawPath(crown, Paint()..shader = ui.Gradient.linear(k - const Offset(0, 16), k + const Offset(0, 10), const [Color(0xFFFFF0A0), Color(0xFFFFB000)]));
      for (final dx in [-10.0, 0.0, 10.0]) {
        canvas.drawCircle(k + Offset(dx, 4), 3, Paint()..color = const Color(0xFFFF3B5C));
      }
    }
  }

  void _chest(Canvas canvas, Offset c, {required bool open}) {
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 54, height: 36), const Radius.circular(6));
    canvas.drawRRect(body.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF3A1A0A).withValues(alpha: 0.5));
    canvas.drawRRect(body, Paint()..shader = ui.Gradient.linear(body.outerRect.topCenter, body.outerRect.bottomCenter, const [Color(0xFFC9772E), Color(0xFF7E3F12)]));
    final lid = Rect.fromCenter(center: c - Offset(0, open ? 26 : 16), width: 58, height: 18);
    if (open) {
      canvas.drawCircle(c - const Offset(0, 14), 22, Paint()
        ..color = const Color(0xFFFFE066).withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }
    canvas.drawRRect(RRect.fromRectAndRadius(lid, const Radius.circular(9)), Paint()..shader = ui.Gradient.linear(lid.topCenter, lid.bottomCenter, const [Color(0xFFE08E3E), Color(0xFF9A4E18)]));
    for (final dx in [-16.0, 16.0]) {
      canvas.drawRect(Rect.fromCenter(center: c + Offset(dx, -6), width: 6, height: 40), Paint()..color = const Color(0xFFFFC21A));
    }
    canvas.drawCircle(c - const Offset(0, 4), 6, Paint()..color = const Color(0xFFFFE27A));
    if (!open) {
      for (var i = 0; i < 5; i++) {
        paintSparkle(canvas, c + Offset(-26.0 + i * 13, -34.0 - (i.isEven ? 6 : 0)), 5, const Color(0xFFFFE066));
      }
    }
  }

  void _pine(Canvas canvas, Offset base, double h) {
    for (var i = 0; i < 3; i++) {
      final w = h * (0.55 - i * 0.12), top = base.dy - h * (0.35 + i * 0.28);
      canvas.drawPath(Path()..addPolygon([Offset(base.dx, top - h * 0.3), Offset(base.dx + w, top + h * 0.12), Offset(base.dx - w, top + h * 0.12)], true),
          Paint()..color = Color.lerp(const Color(0xFF2F8F7A), const Color(0xFF1E6B5C), i / 2)!);
      canvas.drawPath(Path()..addPolygon([Offset(base.dx, top - h * 0.3), Offset(base.dx + w * 0.5, top - h * 0.08), Offset(base.dx - w * 0.5, top - h * 0.08)], true),
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    }
  }

  void _lollipop(Canvas canvas, Offset base, double h, int i) {
    canvas.drawLine(base, base - Offset(0, h), Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white);
    final c = base - Offset(0, h + h * 0.35);
    final colour = sugarColors.values.elementAt(i % 6);
    canvas.drawCircle(c, h * 0.38, Paint()..color = colour);
    canvas.drawArc(Rect.fromCircle(center: c, radius: h * 0.24), 0, pi * 1.4, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.08
      ..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawCircle(c - Offset(h * 0.12, h * 0.14), h * 0.07, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  /// A canyon rock spire.
  void _rock(Canvas canvas, Offset base, double h) {
    final p = Path()
      ..moveTo(base.dx - h * 0.3, base.dy)
      ..lineTo(base.dx - h * 0.18, base.dy - h * 0.7)
      ..lineTo(base.dx - h * 0.04, base.dy - h)
      ..lineTo(base.dx + h * 0.12, base.dy - h * 0.82)
      ..lineTo(base.dx + h * 0.28, base.dy)
      ..close();
    canvas.drawPath(p, Paint()..shader = ui.Gradient.linear(base - Offset(h * 0.3, 0), base + Offset(h * 0.3, 0), const [Color(0xFFE0905A), Color(0xFF9A4A2A)]));
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(Offset(base.dx - h * 0.2, base.dy - h * 0.2 * i), Offset(base.dx + h * 0.2, base.dy - h * 0.2 * i - h * 0.04), Paint()
        ..strokeWidth = 2
        ..color = const Color(0xFF7A3A20).withValues(alpha: 0.5));
    }
  }

  /// A palm tree with a rainbow-coloured fruit.
  void _palm(Canvas canvas, Offset base, double h, int i) {
    final top = base - Offset(h * 0.1, h);
    canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(base.dx + h * 0.08, base.dy - h * 0.5, top.dx, top.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.09
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFB07A4A));
    for (var k = 0; k < 5; k++) {
      final a = -pi + k * pi / 4;
      final tip = top + Offset(cos(a), sin(a) * 0.6 + 0.35) * h * 0.42;
      canvas.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo((top.dx + tip.dx) / 2, top.dy - h * 0.18, tip.dx, tip.dy),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * 0.08
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF2FA85A));
    }
    canvas.drawCircle(top + Offset(0, h * 0.06), h * 0.07, Paint()..color = sugarColors.values.elementAt(i % 6));
  }

  void _tower(Canvas canvas, Offset base, double h) {
    final body = Rect.fromLTWH(base.dx - h * 0.2, base.dy - h, h * 0.4, h);
    canvas.drawRect(body, Paint()..shader = ui.Gradient.linear(body.centerLeft, body.centerRight, const [Color(0xFF8E7AB8), Color(0xFF5A4688)]));
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(body.left + i * h * 0.15, body.top - h * 0.1, h * 0.1, h * 0.1), Paint()..color = const Color(0xFF8E7AB8));
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: body.center, width: h * 0.12, height: h * 0.2), Radius.circular(h * 0.06)),
        Paint()..color = const Color(0xFFFFD86B).withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.width != width || old.current != current || old.strings != strings || !_same(old.stars, stars);

  static bool _same(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return a.length == b.length;
  }
}
