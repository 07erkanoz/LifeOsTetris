import 'dart:math';

import 'package:flutter/animation.dart';

import '../../core/blocks/block_puzzle.dart';
import '../../core/tetromino.dart';
import '../../l10n/strings.dart';
import '../../theme/palette.dart';
import '../fx/effects.dart';

/// A cleared block still on screen: it swells, flashes white and bursts.
class VanishingBlock {
  VanishingBlock(this.cell, this.block, this.delay);

  final Cell cell;
  final BlockCell block;
  double delay;
  double age = 0;
  static const duration = 0.22;

  double get t => (age / duration).clamp(0.0, 1.0);
  bool get done => delay <= 0 && age >= duration;
}

/// A glowing band along a cleared row or column.
class LineBeam {
  LineBeam(this.index, {required this.column});

  final int index;
  final bool column;
  double age = 0;
  static const duration = 0.5;

  double get t => (age / duration).clamp(0.0, 1.0);
}

class PlacePulse {
  PlacePulse(this.cells, this.color);

  final List<Cell> cells;
  final PieceType color;
  double age = 0;
  static const duration = 0.3;

  double get t => (age / duration).clamp(0.0, 1.0);
}

const _cool = [Color(0xFFFFFFFF), Color(0xFF7DD3FC), Color(0xFF818CF8)];
const _gold = [Color(0xFFFEF08A), Color(0xFFF59E0B)];
const _rainbow = [Color(0xFF22D3EE), Color(0xFFA855F7), Color(0xFFF97316), Color(0xFFFACC15)];
const _hot = [Color(0xFFFDE047), Color(0xFFF97316), Color(0xFFEF4444)];
const _combo = [Color(0xFF38BDF8), Color(0xFF6366F1)];

/// Effects of "Bulmaca Küpler". Coordinates are in board cells, (0, 0) at
/// the top-left corner of the 8×8 grid.
class BlocksFx implements BackdropFx {
  BlocksFx({int? seed}) : _rng = Random(seed);

  final Random _rng;

  bool particlesEnabled = true;
  bool shakeEnabled = true;
  AppStrings strings = AppStrings.tr;

  final List<Particle> particles = [];
  final List<Floater> floaters = [];
  final List<Shockwave> shockwaves = [];
  final List<VanishingBlock> vanishing = [];
  final List<LineBeam> beams = [];
  final List<PlacePulse> placePulses = [];

  @override
  double time = 0;
  @override
  double pulse = 0;
  @override
  Color pulseColor = const Color(0xFF38BDF8);

  double boardFlash = 0;
  double _trauma = 0;

  /// Seconds since the game ended (-1 while playing).
  double overAge = -1;

  /// Seconds since the tray was refilled, for the pop-in.
  double trayAge = 1;

  /// HUD pulses (0..1).
  double scorePulse = 0, gemPulse = 0, movesPulse = 0;

  static const int _maxParticles = 700;
  static const double _mid = BlockPuzzleGame.size / 2;

  void reset() {
    particles.clear();
    floaters.clear();
    shockwaves.clear();
    vanishing.clear();
    beams.clear();
    placePulses.clear();
    pulse = boardFlash = _trauma = 0;
    overAge = -1;
    trayAge = 1;
    scorePulse = gemPulse = movesPulse = 0;
  }

  bool get busy => particles.isNotEmpty || floaters.isNotEmpty || vanishing.isNotEmpty || shockwaves.isNotEmpty || pulse > 0;

  Offset get shake {
    if (!shakeEnabled || _trauma <= 0) return Offset.zero;
    final k = _trauma * _trauma * 0.35;
    return Offset(k * (sin(time * 47.0) * 0.7 + sin(time * 83.0) * 0.3), k * (cos(time * 53.0) * 0.7 + sin(time * 71.0) * 0.3));
  }

  double _r(double a, double b) => a + _rng.nextDouble() * (b - a);

  void _add(Particle p) {
    if (!particlesEnabled) return;
    if (particles.length >= _maxParticles) particles.removeAt(0);
    particles.add(p);
  }

  void update(double dt) {
    time += dt;
    _trauma = max(0, _trauma - dt * 1.6);
    pulse = max(0, pulse - dt * 0.9);
    boardFlash = max(0, boardFlash - dt * 2.4);
    scorePulse = max(0, scorePulse - dt * 3);
    gemPulse = max(0, gemPulse - dt * 2);
    movesPulse = max(0, movesPulse - dt * 3);
    trayAge += dt;
    if (overAge >= 0) overAge += dt;

    for (final v in vanishing) {
      if (v.delay > 0) {
        v.delay -= dt;
      } else {
        v.age += dt;
      }
    }
    vanishing.removeWhere((v) => v.done);
    for (final b in beams) {
      b.age += dt;
    }
    beams.removeWhere((b) => b.age >= LineBeam.duration);
    for (final p in placePulses) {
      p.age += dt;
    }
    placePulses.removeWhere((p) => p.age >= PlacePulse.duration);

    for (final p in particles) {
      if (p.delay > 0) {
        p.delay -= dt;
        continue;
      }
      p.life += dt;
      if (p.drag > 0) {
        final f = max(0.0, 1 - p.drag * dt);
        p.vx *= f;
        p.vy *= f;
      }
      p.vy += p.gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.spin * dt;
    }
    particles.removeWhere((p) => !p.alive || p.y > 30);
    for (final f in floaters) {
      f.age += dt;
    }
    floaters.removeWhere((f) => f.age >= f.duration);
    for (final s in shockwaves) {
      s.age += dt;
    }
    shockwaves.removeWhere((s) => s.age >= s.duration);
  }

  void handle(BlockEvent event) {
    switch (event) {
      case BlocksPlaced(:final shape, :final cells):
        _placed(shape, cells);
      case LinesBlasted():
        _blast(event);
      case TrayRefilled():
        trayAge = 0;
      case LevelWon(:final stars, :final bonus):
        _won(stars, bonus);
      case BombPlanted(:final cell):
        _bombPlanted(cell);
      case BombWentOff(:final cell):
        _bombWentOff(cell);
      case BlocksGameOver():
        overAge = 0;
        pulseColor = const Color(0xFFEF4444);
        pulse = 0.8;
        _trauma = min(1, _trauma + 0.5);
    }
  }

  void _placed(BlockShape shape, List<Cell> cells) {
    placePulses.add(PlacePulse(cells, shape.color));
    movesPulse = 1;
    final color = blockColors[shape.color]!;
    final own = cells.toSet();
    for (final c in cells) {
      if (own.contains(Cell(c.x, c.y + 1))) continue;
      for (var i = 0; i < 2; i++) {
        _add(
          Particle(
            kind: i == 0 ? ParticleKind.dot : ParticleKind.spark,
            x: c.x + _r(0.15, 0.85),
            y: c.y + 0.95,
            vx: _r(-2, 2),
            vy: _r(-2.5, -0.5),
            maxLife: _r(0.3, 0.5),
            size: i == 0 ? _r(0.04, 0.08) : _r(0.08, 0.14),
            color: lighten(color, 0.4),
            gravity: 6,
            drag: 2,
          ),
        );
      }
    }
    _trauma = min(1, _trauma + 0.12);
  }

  void _blast(LinesBlasted e) {
    final n = e.lines;
    // The blast spreads out from the middle of the cleared cells.
    final cx = e.cells.map((c) => c.$1.x + 0.5).reduce((a, b) => a + b) / e.cells.length;
    final cy = e.cells.map((c) => c.$1.y + 0.5).reduce((a, b) => a + b) / e.cells.length;
    for (final (cell, block) in e.cells) {
      final d = sqrt(pow(cell.x + 0.5 - cx, 2) + pow(cell.y + 0.5 - cy, 2));
      final delay = d * 0.035;
      vanishing.add(VanishingBlock(cell, block, delay));
      final type = block.gem ? PieceType.gem : block.color;
      final color = blockColors[type]!;
      final burst = delay + VanishingBlock.duration * 0.8;
      for (var i = 0; i < 2; i++) {
        final a = _r(0, pi * 2);
        final speed = _r(3, 7.0 + n);
        _add(
          Particle(
            kind: ParticleKind.block,
            type: type,
            x: cell.x + 0.5,
            y: cell.y + 0.5,
            vx: cos(a) * speed,
            vy: sin(a) * speed - 3,
            maxLife: _r(0.6, 1.0),
            size: _r(0.25, 0.45),
            color: color,
            gravity: 15,
            drag: 0.8,
            rotation: _r(0, pi),
            spin: _r(-9, 9),
            delay: burst,
          ),
        );
      }
      _add(
        Particle(
          kind: ParticleKind.spark,
          x: cell.x + 0.5,
          y: cell.y + 0.5,
          vx: _r(-3, 3),
          vy: _r(-3, 3),
          maxLife: _r(0.3, 0.6),
          size: _r(0.14, 0.26),
          color: const Color(0xFFFFFFFF),
          drag: 2,
          delay: burst,
        ),
      );
      if (block.gem) _gemBurst(cell, burst);
      if (block.isBomb) _defuseBurst(cell, burst);
    }
    for (final r in e.rows) {
      beams.add(LineBeam(r, column: false));
    }
    for (final c in e.columns) {
      beams.add(LineBeam(c, column: true));
    }
    if (particlesEnabled) shockwaves.add(Shockwave(cx, cy, 3 + n * 1.5, const Color(0xFFFFFFFF), duration: 0.5, width: 0.22));
    if (n >= 3 || e.perfect) {
      _confetti(e.perfect ? 140 : 60 + n * 10);
      boardFlash = 0.7;
      if (particlesEnabled) shockwaves.add(Shockwave(_mid, _mid, 9, const Color(0xFF7DD3FC), duration: 0.8, width: 0.3));
    }
    _trauma = min(1, _trauma + 0.15 + 0.12 * n);
    pulseColor = n >= 3 ? const Color(0xFFA855F7) : const Color(0xFF38BDF8);
    pulse = max(pulse, 0.3 + 0.15 * n);
    scorePulse = 1;

    final lines = <FloaterLine>[];
    if (e.perfect) lines.add(FloaterLine(strings.perfectClear, 1.25, const [Color(0xFFFDE047), Color(0xFF22D3EE), Color(0xFFA855F7)]));
    final word = strings.blastWord(n);
    if (word != null) {
      final (size, colors, glow) = switch (n) {
        2 => (1.0, _cool, const Color(0xFF38BDF8)),
        3 => (1.15, _hot, const Color(0xFFF97316)),
        _ => (1.3, _rainbow, const Color(0xFFA855F7)),
      };
      lines.add(FloaterLine(word, size, colors, glow: glow));
    }
    lines.add(FloaterLine('+${e.points}', 0.7, _gold, glow: const Color(0xFFF59E0B)));
    if (e.streak >= 2) lines.add(FloaterLine(strings.combo(e.streak), 0.55, _combo, glow: const Color(0xFF6366F1)));
    floaters.add(Floater(_mid, (cy - 0.6).clamp(1.6, 6.4), lines, duration: n >= 3 ? 1.6 : 1.25));
  }

  void _gemBurst(Cell cell, double delay) {
    gemPulse = 1;
    for (var i = 0; i < 10; i++) {
      final a = _r(-pi * 0.9, -pi * 0.1);
      final speed = _r(4, 10);
      _add(
        Particle(
          kind: i.isEven ? ParticleKind.spark : ParticleKind.dot,
          x: cell.x + 0.5,
          y: cell.y + 0.5,
          vx: cos(a) * speed,
          vy: sin(a) * speed,
          maxLife: _r(0.6, 1.1),
          size: i.isEven ? _r(0.2, 0.36) : _r(0.07, 0.12),
          color: i % 3 == 0 ? const Color(0xFFFFFFFF) : const Color(0xFFFDE047),
          drag: 1.2,
          delay: delay,
        ),
      );
    }
    if (particlesEnabled) shockwaves.add(Shockwave(cell.x + 0.5, cell.y + 0.5, 1.6, const Color(0xFFFDE047), duration: 0.45, width: 0.2));
  }

  static const _fire = [Color(0xFFFDE047), Color(0xFFF97316), Color(0xFFEF4444), Color(0xFFFFFFFF)];

  void _bombPlanted(Cell cell) {
    if (particlesEnabled) {
      shockwaves.add(Shockwave(cell.x + 0.5, cell.y + 0.5, 1.8, const Color(0xFFFB7185), duration: 0.45, width: 0.22));
    }
    for (var i = 0; i < 8; i++) {
      final a = _r(0, pi * 2);
      _add(
        Particle(
          kind: ParticleKind.spark,
          x: cell.x + 0.5,
          y: cell.y + 0.5,
          vx: cos(a) * _r(2, 5),
          vy: sin(a) * _r(2, 5),
          maxLife: _r(0.3, 0.6),
          size: _r(0.12, 0.22),
          color: _fire[i % _fire.length],
          drag: 2,
        ),
      );
    }
    _trauma = min(1, _trauma + 0.15);
  }

  /// A bomb cleared in time: a puff of smoke and sparks instead of a blast.
  void _defuseBurst(Cell cell, double delay) {
    for (var i = 0; i < 10; i++) {
      final a = _r(-pi * 0.9, -pi * 0.1);
      _add(
        Particle(
          kind: i.isEven ? ParticleKind.dot : ParticleKind.spark,
          x: cell.x + 0.5,
          y: cell.y + 0.5,
          vx: cos(a) * _r(2, 6),
          vy: sin(a) * _r(2, 6),
          maxLife: _r(0.5, 0.9),
          size: i.isEven ? _r(0.1, 0.18) : _r(0.15, 0.26),
          color: i.isEven ? const Color(0xFFCBD5E1) : const Color(0xFFFDBA74),
          drag: 1.5,
          delay: delay,
        ),
      );
    }
  }

  void _bombWentOff(Cell cell) {
    final cx = cell.x + 0.5, cy = cell.y + 0.5;
    if (particlesEnabled) {
      shockwaves.add(Shockwave(cx, cy, 5, const Color(0xFFFDBA74), duration: 0.5, width: 0.4));
      shockwaves.add(Shockwave(cx, cy, 9, const Color(0xFFF43F5E), duration: 0.8, width: 0.25));
    }
    for (var i = 0; i < 90; i++) {
      final a = _r(0, pi * 2);
      final speed = _r(2, 13);
      _add(
        Particle(
          kind: i % 3 == 0 ? ParticleKind.spark : ParticleKind.dot,
          x: cx,
          y: cy,
          vx: cos(a) * speed,
          vy: sin(a) * speed - 2,
          maxLife: _r(0.5, 1.2),
          size: i % 3 == 0 ? _r(0.2, 0.42) : _r(0.08, 0.2),
          color: _fire[i % _fire.length],
          gravity: 4,
          drag: 2.2,
        ),
      );
    }
    floaters.add(
      Floater(_mid, (cy - 1.5).clamp(1.6, 6.4), [
        FloaterLine(strings.bombWentOffTitle.toUpperCase(), 1.1, _hot, glow: const Color(0xFFEF4444)),
      ], duration: 1.6),
    );
    boardFlash = 1;
    _trauma = 1;
  }

  void _won(int stars, int bonus) {
    _confetti(170);
    boardFlash = 0.8;
    pulseColor = const Color(0xFFFBBF24);
    pulse = 1;
    _trauma = min(1, _trauma + 0.3);
    floaters.add(
      Floater(_mid, 3.4, [
        FloaterLine(strings.levelDone, 1.25, const [
          Color(0xFFFFFFFF),
          Color(0xFFFDE047),
          Color(0xFFF59E0B),
        ], glow: const Color(0xFFFBBF24)),
        FloaterLine('★' * stars + '☆' * (3 - stars), 0.95, _gold, glow: const Color(0xFFF59E0B)),
        if (bonus > 0) FloaterLine('+$bonus', 0.6, _gold),
      ], duration: 2.2),
    );
  }

  void _confetti(int count) {
    for (var i = 0; i < count; i++) {
      final type = standardPieces[_rng.nextInt(standardPieces.length)];
      final a = _r(-pi * 0.85, -pi * 0.15);
      final speed = _r(7, 15);
      final isBlock = i % 3 != 0;
      _add(
        Particle(
          kind: isBlock ? ParticleKind.block : ParticleKind.spark,
          type: type,
          x: _r(1, 7),
          y: 7.5,
          vx: cos(a) * speed,
          vy: sin(a) * speed,
          maxLife: _r(1.3, 2.1),
          size: isBlock ? _r(0.2, 0.38) : _r(0.15, 0.3),
          color: isBlock ? blockColors[type]! : lighten(blockColors[type]!, 0.6),
          gravity: 12,
          drag: 0.9,
          rotation: _r(0, pi),
          spin: _r(-10, 10),
          delay: _r(0, 0.15),
        ),
      );
    }
  }

  /// Easing for the place pop.
  static double popScale(double t) => 1 + 0.12 * sin(Curves.easeOut.transform(t) * pi);
}
