import 'dart:math';
import 'dart:ui';

import '../../core/chain/chain_game.dart';
import '../../l10n/strings.dart';
import 'chain_sprites.dart';

/// A sparkle or a cube shard flying off a burst (board cells as units).
class ChainSpark {
  ChainSpark(this.x, this.y, this.vx, this.vy, this.size, this.color, this.life, {this.shard = false});

  double x, y, vx, vy;
  final double size;
  final Color color;
  final double life;
  final bool shard;
  double age = 0;
  double get t => (age / life).clamp(0, 1);
}

/// Floating text over the board: points, chains, combos, bonuses.
class ChainFloater {
  ChainFloater(this.text, this.x, this.y, this.size, this.colors, {this.duration = 1.2});

  final String text;
  final double x, y;

  /// Text height in cells.
  final double size;
  final List<Color> colors;
  final double duration;
  double age = 0;
  double get t => (age / duration).clamp(0, 1);
}

class ChainFx {
  ChainFx({int? seed}) : _random = Random(seed);

  final Random _random;
  AppStrings strings = AppStrings.tr;
  bool particlesEnabled = true;
  bool shakeEnabled = true;

  final List<ChainSpark> sparks = [];
  final List<ChainFloater> floaters = [];
  double time = 0;
  double _trauma = 0;

  /// Glow on the score after it changes, and on the chain counter.
  double scorePulse = 0;
  double chainPulse = 0;

  /// Red pulse of the well while the stack touches the top.
  double danger = 0;

  bool get busy => sparks.isNotEmpty || floaters.isNotEmpty || _trauma > 0.01;

  /// Board offset for screen shake, in cells.
  Offset get shake {
    if (!shakeEnabled || _trauma <= 0) return Offset.zero;
    final k = _trauma * _trauma * 0.18;
    return Offset(sin(time * 61) * k, cos(time * 53) * k);
  }

  void reset() {
    sparks.clear();
    floaters.clear();
    _trauma = scorePulse = chainPulse = danger = 0;
  }

  /// A big line of text over the middle of the board.
  void callout(String text) => floaters.add(ChainFloater(text, ChainGame.width / 2, 4.5, 0.75, const [Color(0xFFFFF3A0), Color(0xFFFF9A1A)], duration: 1.5));

  /// A burst of coloured cubes over the board, for a goal met.
  void confetti() {
    if (!particlesEnabled) return;
    for (var i = 0; i < 60; i++) {
      final c = chainColors.values.elementAt(i % chainColors.length);
      sparks.add(ChainSpark(_random.nextDouble() * ChainGame.width, 1 + _random.nextDouble() * 3, (_random.nextDouble() - 0.5) * 4, -2 - _random.nextDouble() * 4,
          0.12 + _random.nextDouble() * 0.1, c, 1.2 + _random.nextDouble() * 0.8, shard: true));
    }
  }

  void update(double dt) {
    time += dt;
    _trauma = max(0, _trauma - dt * 1.6);
    scorePulse = max(0, scorePulse - dt * 2.5);
    chainPulse = max(0, chainPulse - dt * 1.5);
    for (final s in sparks) {
      s.age += dt;
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += (s.shard ? 9 : 2.5) * dt;
      s.vx *= 1 - dt * 1.5;
    }
    sparks.removeWhere((s) => s.age >= s.life);
    for (final f in floaters) {
      f.age += dt;
    }
    floaters.removeWhere((f) => f.age >= f.duration);
  }

  void handle(ChainEvent e, ChainGame game) {
    switch (e) {
      case ChainMatched():
        scorePulse = 1;
        final (x, y) = _centre(e.cells, game);
        if (e.chain >= 2) {
          chainPulse = 1;
          _trauma = min(1, _trauma + 0.25 + 0.1 * e.chain);
          floaters.add(ChainFloater(strings.chainCallout(e.chain), x, y - 0.9, 0.95, const [Color(0xFFFFF3A0), Color(0xFFFF9A1A)], duration: 1.4));
        }
        if (e.combo >= 4) {
          floaters.add(ChainFloater(strings.chainCombo(e.combo), x, y + (e.chain >= 2 ? 0.2 : -0.6), 0.7, const [Color(0xFFB8F7FF), Color(0xFF3DB4FF)]));
        }
        if (e.grays > 0) floaters.add(ChainFloater(strings.chainBonus, x - 0.6, y + 0.8, 0.55, const [Color(0xFFFFFFFF), Color(0xFFC9CCE0)]));
        floaters.add(ChainFloater('+${e.points}', x + 0.4, y + 0.1, 0.5, const [Color(0xFFFFFFFF), Color(0xFFFFE066)], duration: 0.9));
      case ChainPopped():
        if (!particlesEnabled) return;
        final colour = chainColors[e.color]!;
        final cx = e.x + 0.5, cy = e.y + 0.5 - game.rise;
        for (var i = 0; i < 6; i++) {
          final a = _random.nextDouble() * 2 * pi;
          final v = 1.5 + _random.nextDouble() * 3.5;
          sparks.add(ChainSpark(cx, cy, cos(a) * v, sin(a) * v - 1.5, 0.08 + _random.nextDouble() * 0.12,
              [colour, const Color(0xFFFFFFFF), const Color(0xFFFFE066)][i % 3], 0.5 + _random.nextDouble() * 0.5));
        }
        for (var i = 0; i < 3; i++) {
          final a = -pi / 2 + (_random.nextDouble() - 0.5) * 2.2;
          final v = 2.5 + _random.nextDouble() * 2.5;
          sparks.add(ChainSpark(cx, cy, cos(a) * v, sin(a) * v, 0.16 + _random.nextDouble() * 0.08, colour, 0.7, shard: true));
        }
      case ChainGarbageDropped():
        _trauma = min(1, _trauma + 0.45);
      case ChainGarbageBroken():
        _trauma = min(1, _trauma + 0.3);
        if (!particlesEnabled) return;
        for (var i = 0; i < e.width * 5; i++) {
          final x = e.x + _random.nextDouble() * e.width;
          sparks.add(ChainSpark(x, e.y + 0.5 - game.rise, (_random.nextDouble() - 0.5) * 3, -2 - _random.nextDouble() * 3,
              0.09 + _random.nextDouble() * 0.1, i.isEven ? garbageRed : const Color(0xFFFFFFFF), 0.6 + _random.nextDouble() * 0.4));
        }
      case ChainLevelUp():
        floaters.add(ChainFloater(strings.chainLevel(e.level), ChainGame.width / 2, 3, 0.8, const [Color(0xFFDDE3FF), Color(0xFF7B83FF)], duration: 1.6));
      case ChainGameOver():
        _trauma = e.timeUp || e.won ? 0 : 0.6;
      default:
        break;
    }
  }

  (double, double) _centre(List<(int, int, ChainColor)> cells, ChainGame game) {
    var sx = 0.0, sy = 0.0;
    for (final (x, y, _) in cells) {
      sx += x + 0.5;
      sy += y + 0.5;
    }
    return (sx / cells.length, sy / cells.length - game.rise);
  }
}
