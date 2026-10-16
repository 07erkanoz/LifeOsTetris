import 'dart:math';
import 'dart:ui';

import '../../core/sugar/sugar_game.dart';
import 'sugar_art.dart';

/// A sparkle, a cube shard or an ice chip flying off (board cells as units).
class SugarSpark {
  SugarSpark(this.x, this.y, this.vx, this.vy, this.size, this.color, this.life, {this.kind = 0, this.delay = 0});

  double x, y, vx, vy;
  final double size;
  final Color color;
  final double life;

  /// 0 sparkle, 1 cube shard, 2 ice chip.
  final int kind;
  double delay;
  double age = 0;
  double spin = 0;
  double get t => (age / life).clamp(0, 1);
}

/// Floating text: points, callouts.
class SugarFloater {
  SugarFloater(this.text, this.x, this.y, this.size, this.colors, {this.duration = 1.1, this.big = false, this.delay = 0});

  final String text;
  final double x, y;

  /// Text height in cells.
  final double size;
  final List<Color> colors;
  final double duration;
  final bool big;
  double delay;
  double age = 0;
  double get t => (age / duration).clamp(0, 1);
}

/// A special firing: a beam along a row or column, a bomb ring, prism rays.
class SugarBeam {
  SugarBeam(this.kind, this.x, this.y, this.color, this.targets, {this.delay = 0});

  final Special kind;
  final int x, y;
  final Color color;
  final List<Cell> targets;
  double delay;
  double age = 0;
  static const double life = 0.42;
  double get t => (age / life).clamp(0, 1);
}

class SugarFx {
  SugarFx({int? seed}) : _random = Random(seed);

  final Random _random;
  bool particlesEnabled = true;
  bool shakeEnabled = true;

  final List<SugarSpark> sparks = [];
  final List<SugarFloater> floaters = [];
  final List<SugarBeam> beams = [];
  double time = 0;
  double _trauma = 0;
  double scorePulse = 0;

  bool get busy => sparks.isNotEmpty || floaters.isNotEmpty || beams.isNotEmpty || _trauma > 0.01;

  /// Board offset for screen shake, in cells.
  Offset get shake {
    if (!shakeEnabled || _trauma <= 0) return Offset.zero;
    final k = _trauma * _trauma * 0.16;
    return Offset(sin(time * 61) * k, cos(time * 53) * k);
  }

  void kick(double amount) => _trauma = min(1, _trauma + amount);

  void reset() {
    sparks.clear();
    floaters.clear();
    beams.clear();
    _trauma = scorePulse = 0;
  }

  void update(double dt) {
    time += dt;
    _trauma = max(0, _trauma - dt * 1.8);
    scorePulse = max(0, scorePulse - dt * 2.5);
    for (final s in sparks) {
      if (s.delay > 0) {
        s.delay -= dt;
        continue;
      }
      s.age += dt;
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += (s.kind == 0 ? 2.5 : 10) * dt;
      s.vx *= 1 - dt * 1.4;
      s.spin += dt * 9;
    }
    sparks.removeWhere((s) => s.age >= s.life);
    for (final f in floaters) {
      f.delay > 0 ? f.delay -= dt : f.age += dt;
    }
    floaters.removeWhere((f) => f.age >= f.duration);
    for (final b in beams) {
      b.delay > 0 ? b.delay -= dt : b.age += dt;
    }
    beams.removeWhere((b) => b.age >= SugarBeam.life);
  }

  void burst(double cx, double cy, Color colour, {double delay = 0, int count = 6}) {
    if (!particlesEnabled) return;
    for (var i = 0; i < count; i++) {
      final a = _random.nextDouble() * 2 * pi;
      final v = 1.5 + _random.nextDouble() * 3.5;
      sparks.add(SugarSpark(cx, cy, cos(a) * v, sin(a) * v - 1.5, 0.08 + _random.nextDouble() * 0.12,
          [colour, const Color(0xFFFFFFFF), const Color(0xFFFFE066)][i % 3], 0.45 + _random.nextDouble() * 0.45, delay: delay));
    }
    for (var i = 0; i < 3; i++) {
      final a = -pi / 2 + (_random.nextDouble() - 0.5) * 2.4;
      final v = 2.5 + _random.nextDouble() * 2.5;
      sparks.add(SugarSpark(cx, cy, cos(a) * v, sin(a) * v, 0.14 + _random.nextDouble() * 0.08, colour, 0.65, kind: 1, delay: delay));
    }
  }

  void chips(double cx, double cy, Color colour, {int count = 7}) {
    if (!particlesEnabled) return;
    for (var i = 0; i < count; i++) {
      final a = -pi / 2 + (_random.nextDouble() - 0.5) * 3;
      final v = 2 + _random.nextDouble() * 3;
      sparks.add(SugarSpark(cx + (_random.nextDouble() - 0.5) * 0.6, cy + (_random.nextDouble() - 0.5) * 0.6, cos(a) * v, sin(a) * v,
          0.1 + _random.nextDouble() * 0.1, colour, 0.6 + _random.nextDouble() * 0.3, kind: 2));
    }
  }

  void beam(SugarBlast e, Color colour, {double delay = 0}) {
    beams.add(SugarBeam(e.kind, e.x, e.y, colour, e.cells, delay: delay));
    switch (e.kind) {
      case Special.lineH || Special.lineV:
        kick(0.3);
      case Special.bomb:
        kick(0.45);
      case Special.prism:
        kick(0.55);
      case Special.none:
        kick(0.15);
    }
    if (!particlesEnabled || e.kind == Special.none) return;
    for (final (x, y) in e.cells) {
      if (_random.nextDouble() < 0.5) {
        sparks.add(SugarSpark(x + 0.5, y + 0.5, (_random.nextDouble() - 0.5) * 3, -1 - _random.nextDouble() * 2, 0.08 + _random.nextDouble() * 0.1,
            [const Color(0xFFFFFFFF), const Color(0xFFFFE066), const Color(0xFFFF9AD8), const Color(0xFF9FD8FF)][_random.nextInt(4)], 0.5,
            delay: delay));
      }
    }
  }

  void callout(String text, {double y = 3.2, double size = 1.25, double delay = 0}) {
    floaters.add(SugarFloater(text, SugarGame.size / 2, y, size, const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)],
        duration: 1.3, big: true, delay: delay));
  }

  void points(int points, double x, double y, {double delay = 0}) {
    scorePulse = 1;
    floaters.add(SugarFloater('+$points', x, y, 0.5, const [Color(0xFFFFFFFF), Color(0xFFFFE066)], duration: 0.85, delay: delay));
  }

  static Color colourOf(SugarPiece p) => p.isPrism ? const Color(0xFFFFFFFF) : sugarColors[p.color]!;
}
