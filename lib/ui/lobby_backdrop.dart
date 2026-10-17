part of 'game_screen.dart';

// --------------------------------------------------------- lobby backdrop

/// The lobby's living background, dressed per skin: drifting cubes and
/// sweets under a sky that follows the time of day (toy skins), aurora
/// light and a passing streak (neon), drifting pixel clouds and a shooting
/// star (pixel). Everything loops every [period] seconds; a tap pops the
/// nearest drifting cube.
class _LobbyBackdrop extends StatefulWidget {
  const _LobbyBackdrop({required this.c});

  final GameController c;

  @override
  State<_LobbyBackdrop> createState() => _LobbyBackdropState();
}

class _LobbyBackdropState extends State<_LobbyBackdrop> with SingleTickerProviderStateMixin {
  static const double period = 60;

  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 60));

  /// Cubes popped by a tap: index and the time it happened.
  final Map<int, double> _pops = {};

  @override
  void initState() {
    super.initState();
    widget.c.settings.addListener(_sync);
    _sync();
  }

  void _sync() {
    if (widget.c.settings.effects) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    widget.c.settings.removeListener(_sync);
    _clock.dispose();
    super.dispose();
  }

  double get _now => _clock.value * period;

  void _tap(TapUpDetails d, Size size, GamePalette p) {
    if (!widget.c.settings.effects) return;
    final now = _now;
    var best = -1;
    var bestDistance = 60.0;
    for (var i = 0; i < _floaters.length; i++) {
      if (_pops.containsKey(i)) continue;
      final at = _floaters[i].at(now, size);
      final distance = (at - d.localPosition).distance;
      if (distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    if (best < 0) return;
    widget.c.audio.play(Sfx.soft, volume: 0.6);
    setState(() => _pops[best] = now);
  }

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (d) => _tap(d, box.biggest, p),
        child: RepaintBoundary(
          child: CustomPaint(
            size: box.biggest,
            painter: _BackdropPainter(palette: p, clock: _clock, pops: _pops, dpr: dpr, hour: DateTime.now().hour, still: !widget.c.settings.effects),
          ),
        ),
      ),
    );
  }
}

/// One drifting cube or sweet: where it starts, how fast it rises and
/// spins (whole turns per [period] so the loop is seamless).
class _Floater {
  const _Floater(this.x, this.y, this.rise, this.drift, this.spin, this.size, this.kind);

  final double x, y;

  /// Screen heights per period, whole numbers.
  final int rise;
  final double drift;
  final int spin;
  final double size;
  final int kind;

  Offset at(double t, Size size) {
    final k = t / _LobbyBackdropState.period;
    final y = ((this.y - k * rise) % 1.2 + 1.2) % 1.2 - 0.1;
    final x = this.x + sin(k * pi * 2 * 2 + this.y * 9) * drift;
    return Offset(x * size.width, y * size.height);
  }

  double angle(double t) => t / _LobbyBackdropState.period * pi * 2 * spin + x * 7;
}

final List<_Floater> _floaters = () {
  final r = Random(7);
  return [
    for (var i = 0; i < 16; i++)
      _Floater(
        r.nextDouble(),
        r.nextDouble() * 1.2,
        1 + r.nextInt(2),
        0.02 + r.nextDouble() * 0.03,
        (r.nextBool() ? 1 : -1) * (1 + r.nextInt(2)),
        26 + r.nextDouble() * 28,
        i,
      ),
  ];
}();

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.palette, required this.clock, required this.pops, required this.dpr, required this.hour, required this.still})
    : super(repaint: clock);

  final GamePalette palette;
  final Animation<double> clock;
  final Map<int, double> pops;
  final double dpr;
  final int hour;
  final bool still;

  static const _pieces = [PieceType.t, PieceType.i, PieceType.o, PieceType.s, PieceType.z, PieceType.j, PieceType.l];

  @override
  void paint(Canvas canvas, Size size) {
    final t = still ? 20.0 : clock.value * _LobbyBackdropState.period;
    final p = palette;
    if (p.skin == GameSkin.pixel) {
      _pixel(canvas, size, t);
    } else if (isNeon(p)) {
      _neon(canvas, size, t);
    } else {
      _sky(canvas, size, t);
    }
    _drifting(canvas, size, t);
  }

  /// Toy and glass skins: a sky glow that follows the hour, stars at night.
  void _sky(Canvas canvas, Size size, double t) {
    final rect = Offset.zero & size;
    final (top, glow) = switch (hour) {
      >= 5 && < 11 => (const Color(0xFFFFB8C8), const Color(0xFFFFD9A0)),
      >= 11 && < 17 => (const Color(0xFFB8D8FF), const Color(0xFFE8D2FF)),
      >= 17 && < 21 => (const Color(0xFFB45BFF), const Color(0xFFFF9A6A)),
      _ => (const Color(0xFF1A2A6A), const Color(0xFF4A3A9A)),
    };
    final strength = palette.isDark ? 0.28 : 0.4;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          Offset(0, size.height * 0.75),
          [top.withValues(alpha: strength), glow.withValues(alpha: strength * 0.5), glow.withValues(alpha: 0)],
          const [0, 0.45, 1],
        ),
    );
    final night = hour >= 21 || hour < 5;
    if (night || palette.isDark) {
      final r = Random(3);
      for (var i = 0; i < 40; i++) {
        final twinkle = 0.5 + 0.5 * sin(t * (0.6 + r.nextDouble() * 1.4) * pi + i);
        canvas.drawCircle(
          Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.6),
          0.8 + r.nextDouble() * 1.4,
          Paint()..color = Colors.white.withValues(alpha: (night ? 0.55 : 0.25) * twinkle),
        );
      }
    }
  }

  /// Neon: slow aurora light, twinkling stars and now and then a streak.
  void _neon(Canvas canvas, Size size, double t) {
    final k = t / _LobbyBackdropState.period * pi * 2;
    for (final (i, color) in [neonPink, neonCyan, neonViolet].indexed) {
      final c = Offset(size.width * (0.5 + 0.35 * sin(k * (i + 1) + i * 2)), size.height * (0.25 + 0.5 * (0.5 + 0.5 * cos(k * (i + 1) * 0.5 + i))));
      final radius = max(size.width, size.height) * 0.45;
      canvas.drawCircle(c, radius, Paint()..shader = ui.Gradient.radial(c, radius, [color.withValues(alpha: 0.24), color.withValues(alpha: 0)]));
    }
    final r = Random(5);
    for (var i = 0; i < 60; i++) {
      final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * (0.8 + r.nextDouble() * 1.6) * pi + i * 1.7));
      canvas.drawCircle(
        Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
        0.6 + r.nextDouble() * 1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.5 * twinkle),
      );
    }
    // A light streak every twelve seconds.
    final s = t % 12;
    if (s < 1.2) {
      final q = s / 1.2;
      final from = Offset(size.width * (1.1 - q * 1.4), size.height * (0.08 + q * 0.3));
      final tail = from + Offset(size.width * 0.18, -size.height * 0.04);
      canvas.drawLine(
        from,
        tail,
        Paint()
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(from, tail, [Colors.white.withValues(alpha: 0.9 * (1 - q)), neonCyan.withValues(alpha: 0)]),
      );
    }
  }

  /// Pixel: blinking square stars, drifting pixel clouds, a shooting star.
  void _pixel(Canvas canvas, Size size, double t) {
    final r = Random(9);
    for (var i = 0; i < 50; i++) {
      final on = sin(t * (1 + r.nextDouble() * 2) + i) > -0.2;
      final x = (r.nextDouble() * size.width / 3).roundToDouble() * 3, y = (r.nextDouble() * size.height * 0.7 / 3).roundToDouble() * 3;
      if (on) canvas.drawRect(Rect.fromLTWH(x, y, 3, 3), Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
    final cloud = Paint()..color = Colors.white.withValues(alpha: palette.isDark ? 0.07 : 0.35);
    for (var i = 0; i < 4; i++) {
      final w = 48.0 + i * 18;
      final x = ((i * 0.31 + t / _LobbyBackdropState.period * (1 + i % 2)) % 1.3 - 0.15) * size.width;
      final y = size.height * (0.12 + i * 0.17);
      for (final (dx, dy, cw) in [(0.0, 6.0, w), (w * 0.15, 0.0, w * 0.5), (w * 0.45, -6.0, w * 0.35)]) {
        canvas.drawRect(Rect.fromLTWH((x + dx).roundToDouble(), (y + dy).roundToDouble(), cw.roundToDouble(), 9), cloud);
      }
    }
    final s = t % 15;
    if (s < 1) {
      for (var k = 0; k < 6; k++) {
        final x = (size.width * (0.9 - s * 0.8) + k * 6).roundToDouble();
        final y = (size.height * (0.1 + s * 0.15) - k * 2).roundToDouble();
        canvas.drawRect(Rect.fromLTWH(x, y, 4, 4), Paint()..color = const Color(0xFFFFD23F).withValues(alpha: 1 - k / 6));
      }
    }
  }

  /// The drifting cubes and sweets, faint, behind everything.
  void _drifting(Canvas canvas, Size size, double t) {
    final blocks = BlockSprites.of(26, dpr, palette);
    final sweets = _LobbySprites.of(28, dpr, palette.skin == GameSkin.pixel);
    final faint = palette.isDark ? 0.3 : 0.34;
    for (final f in _floaters) {
      var scale = f.size / 26;
      var alpha = faint;
      final popped = pops[f.kind];
      final at = f.at(t, size);
      if (popped != null) {
        final k = ((t - popped) % _LobbyBackdropState.period) / 0.45;
        if (k >= 1 && k < 6) continue;
        if (k < 1) {
          scale *= 1 + k * 0.8;
          alpha = (faint + 0.5) * (1 - k);
          for (var i = 0; i < 6; i++) {
            final a = i * pi / 3;
            paintSparkle(canvas, at + Offset(cos(a), sin(a)) * (10 + k * 30), 5 * (1 - k), const Color(0xFFFFE066), opacity: 1 - k);
          }
        }
      }
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(f.angle(t));
      canvas.scale(scale);
      final image = f.kind.isEven ? blocks.block(_pieces[f.kind % _pieces.length]) : sweets.candy(SugarColor.values[f.kind % SugarColor.values.length]);
      final side = 26 * 1.6;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Paint()
          ..filterQuality = FilterQuality.low
          ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.palette != palette || old.pops != pops || old.hour != hour || old.still != still || old.dpr != dpr;
}
