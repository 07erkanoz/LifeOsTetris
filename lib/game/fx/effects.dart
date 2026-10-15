import 'dart:math';

import 'package:flutter/animation.dart';

import '../../core/scoring.dart';
import '../../core/tetris_game.dart';
import '../../l10n/strings.dart';
import '../../theme/palette.dart';

/// All effect coordinates are in board cells: x from the left edge of the
/// well, y from the top of the *visible* well. The painter scales them.

enum ParticleKind { block, grayBlock, spark, dot }

class Particle {
  Particle({
    required this.kind,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.maxLife,
    required this.size,
    required this.color,
    this.type,
    this.gravity = 0,
    this.drag = 0,
    this.rotation = 0,
    this.spin = 0,
    this.delay = 0,
  });

  final ParticleKind kind;
  double x, y, vx, vy;
  double life = 0;
  final double maxLife;
  final double size;
  final Color color;
  final PieceType? type;
  final double gravity;
  final double drag;
  double rotation;
  final double spin;
  double delay;

  double get t => (life / maxLife).clamp(0.0, 1.0);
  bool get alive => life < maxLife;
  bool get visible => delay <= 0;
}

class FloaterLine {
  FloaterLine(this.text, this.size, this.colors, {this.glow});

  final String text;

  /// Font size in cells.
  final double size;
  final List<Color> colors;
  final Color? glow;
}

class Floater {
  Floater(this.x, this.y, this.lines, {this.duration = 1.4});

  final double x, y;
  final List<FloaterLine> lines;
  final double duration;
  double age = 0;

  double get t => (age / duration).clamp(0.0, 1.0);
}

class Shockwave {
  Shockwave(this.x, this.y, this.radius, this.color, {this.duration = 0.45, this.width = 0.25});

  final double x, y, radius, duration, width;
  final Color color;
  double age = 0;

  double get t => (age / duration).clamp(0.0, 1.0);
}

class DropTrail {
  DropTrail(this.column, this.top, this.bottom, this.color);

  final int column;
  final double top, bottom;
  final Color color;
  double age = 0;
  static const duration = 0.32;

  double get t => (age / duration).clamp(0.0, 1.0);
}

class LockPulse {
  LockPulse(this.cells);

  final List<Cell> cells;
  double age = 0;
  static const duration = 0.28;

  double get t => (age / duration).clamp(0.0, 1.0);
}

/// Signature colours of each power, used by effects and the power bar.
const Map<PowerType, List<Color>> powerColors = {
  PowerType.bomb: [Color(0xFFFB7185), Color(0xFFF97316)],
  PowerType.single: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
  PowerType.drill: [Color(0xFFFDE047), Color(0xFFF59E0B)],
  PowerType.gravity: [Color(0xFF4ADE80), Color(0xFF14B8A6)],
  PowerType.slowMotion: [Color(0xFF7DD3FC), Color(0xFF3B82F6)],
  PowerType.ghostLine: [Color(0xFFE9D5FF), Color(0xFFA855F7)],
};

class DrillBeam {
  DrillBeam(this.column);

  final int column;
  double age = 0;
  static const duration = 0.55;

  double get t => (age / duration).clamp(0.0, 1.0);
}

const _cool = [Color(0xFFFFFFFF), Color(0xFF7DD3FC), Color(0xFF818CF8)];
const _gold = [Color(0xFFFEF08A), Color(0xFFF59E0B)];
const _rainbow = [Color(0xFF22D3EE), Color(0xFFA855F7), Color(0xFFF97316), Color(0xFFFACC15)];
const _violet = [Color(0xFFF3E8FF), Color(0xFFC084FC), Color(0xFF9333EA)];
const _perfect = [Color(0xFFFDE047), Color(0xFF22D3EE), Color(0xFFA855F7)];
const _combo = [Color(0xFF38BDF8), Color(0xFF6366F1)];
const _b2b = [Color(0xFFF97316), Color(0xFFEF4444)];

/// What the animated background needs from a game's effects: a clock and
/// an occasional coloured pulse.
abstract interface class BackdropFx {
  double get time;
  double get pulse;
  Color get pulseColor;
}

/// Drives every visual effect: particles, shake, floating text, trails,
/// shockwaves, row collapse, level-up wave and the game-over crumble.
class EffectsEngine implements BackdropFx {
  EffectsEngine({int? seed}) : _rng = Random(seed);

  final Random _rng;

  /// "Efektler" setting: particles, trails and flashes.
  bool particlesEnabled = true;

  /// "Ekran sarsıntısı" setting.
  bool shakeEnabled = true;

  /// Language for the floating callouts.
  AppStrings strings = AppStrings.tr;

  final List<Particle> particles = [];
  final List<Floater> floaters = [];
  final List<Shockwave> shockwaves = [];
  final List<DropTrail> trails = [];
  final List<LockPulse> lockPulses = [];
  final List<DrillBeam> beams = [];

  /// Rows each block still has to fall after the gravity power, keyed by
  /// (column, visible row) of its new position. Animated to zero.
  Map<(int, int), double> fallShift = const {};
  double fallAge = 1;
  static const fallDuration = 0.5;

  @override
  double time = 0;
  double _trauma = 0;

  /// Row shift (in cells) per board row after a collapse, animated to zero.
  Map<int, double> collapseShift = const {};
  double collapseAge = 1;
  static const collapseDuration = 0.32;

  double boardFlash = 0;
  @override
  Color pulseColor = const Color(0xFF38BDF8);
  @override
  double pulse = 0;

  double levelWaveAge = -1;
  static const levelWaveDuration = 1.0;

  /// Seconds since game over, or -1 while playing.
  double gameOverAge = -1;
  bool shattered = false;

  /// The run ended by reaching its goal: no grey-out, no shatter.
  bool finishedWon = false;
  static const gameOverGrayDuration = 0.8;

  // Active piece smoothing.
  double offsetX = 0, offsetY = 0, rotatePop = 0, spawnAge = 1;
  int? _lastActiveY;
  PieceType? _lastActiveType;

  // HUD pulses (0..1) read by widgets.
  double holdPulse = 0, scorePulse = 0, levelPulse = 0, energyPulse = 0, powerPulse = 0;

  /// The power earned last, for the power bar's pop.
  PowerType? lastPower;

  static const int _maxParticles = 900;

  void reset() {
    particles.clear();
    floaters.clear();
    shockwaves.clear();
    trails.clear();
    lockPulses.clear();
    beams.clear();
    fallShift = const {};
    fallAge = 1;
    _trauma = 0;
    collapseShift = const {};
    collapseAge = 1;
    boardFlash = 0;
    pulse = 0;
    levelWaveAge = -1;
    gameOverAge = -1;
    shattered = false;
    finishedWon = false;
    offsetX = offsetY = rotatePop = 0;
    spawnAge = 1;
    _lastActiveY = null;
    _lastActiveType = null;
    holdPulse = scorePulse = levelPulse = energyPulse = powerPulse = 0;
    lastPower = null;
  }

  double get fallProgress => Curves.bounceOut.transform((fallAge / fallDuration).clamp(0.0, 1.0));

  double get collapseProgress => Curves.easeOutBack.transform((collapseAge / collapseDuration).clamp(0.0, 1.0));

  double get levelWaveT => levelWaveAge < 0 ? -1 : (levelWaveAge / levelWaveDuration);

  /// Screen shake offset in cells.
  Offset get shake {
    if (!shakeEnabled || _trauma <= 0) return Offset.zero;
    final k = _trauma * _trauma * 0.55;
    return Offset(k * (sin(time * 47.0) * 0.7 + sin(time * 83.0) * 0.3), k * (cos(time * 53.0) * 0.7 + sin(time * 71.0) * 0.3));
  }

  void addTrauma(double amount) => _trauma = min(1, _trauma + amount);

  double _r(double a, double b) => a + _rng.nextDouble() * (b - a);

  void _add(Particle p) {
    if (!particlesEnabled) return;
    if (particles.length >= _maxParticles) particles.removeAt(0);
    particles.add(p);
  }

  // ------------------------------------------------------------ update

  void update(double dt, TetrisGame game) {
    time += dt;
    _trauma = max(0, _trauma - dt * 1.5);
    boardFlash = max(0, boardFlash - dt * 2.2);
    pulse = max(0, pulse - dt * 0.9);
    holdPulse = max(0, holdPulse - dt * 3);
    scorePulse = max(0, scorePulse - dt * 3);
    levelPulse = max(0, levelPulse - dt * 1.2);
    energyPulse = max(0, energyPulse - dt * 2.5);
    powerPulse = max(0, powerPulse - dt * 1.5);
    collapseAge += dt;
    fallAge += dt;
    for (final b in beams) {
      b.age += dt;
    }
    beams.removeWhere((b) => b.age >= DrillBeam.duration);
    if (levelWaveAge >= 0) {
      levelWaveAge += dt;
      if (levelWaveAge > levelWaveDuration) levelWaveAge = -1;
    }
    if (gameOverAge >= 0) {
      gameOverAge += dt;
      if (!shattered && !finishedWon && gameOverAge > gameOverGrayDuration + 0.15) _shatter(game);
    }

    final decay = exp(-dt * 26);
    offsetX *= decay;
    offsetY *= exp(-dt * 30);
    rotatePop *= exp(-dt * 14);
    spawnAge += dt;
    _trackActive(game);

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
    particles.removeWhere((p) => !p.alive || p.y > 40);

    for (final f in floaters) {
      f.age += dt;
    }
    floaters.removeWhere((f) => f.age >= f.duration);
    for (final s in shockwaves) {
      s.age += dt;
    }
    shockwaves.removeWhere((s) => s.age >= s.duration);
    for (final tr in trails) {
      tr.age += dt;
    }
    trails.removeWhere((tr) => tr.age >= DropTrail.duration);
    for (final l in lockPulses) {
      l.age += dt;
    }
    lockPulses.removeWhere((l) => l.age >= LockPulse.duration);

    if (particlesEnabled && game.status == GameStatus.playing && !game.paused) _ambientActiveSparkles(game, dt);
  }

  void _trackActive(TetrisGame game) {
    final piece = game.active;
    if (piece == null) {
      _lastActiveY = null;
      return;
    }
    if (_lastActiveType == piece.type && _lastActiveY != null && piece.y > _lastActiveY!) {
      // Gravity / soft drop step: slide smoothly into the new row.
      offsetY = max(-1.2, offsetY - (piece.y - _lastActiveY!));
    }
    _lastActiveY = piece.y;
    _lastActiveType = piece.type;
  }

  double _sparkleTimer = 0;

  void _ambientActiveSparkles(TetrisGame game, double dt) {
    final piece = game.active;
    if (piece == null) return;
    _sparkleTimer += dt;
    if (_sparkleTimer < 0.09) return;
    _sparkleTimer = 0;
    final cells = piece.cells.toList();
    final c = cells[_rng.nextInt(cells.length)];
    final color = blockColors[piece.type]!;
    _add(
      Particle(
        kind: ParticleKind.dot,
        x: c.x + _r(0.1, 0.9),
        y: c.y - TetrisGame.hiddenRows + offsetY + _r(0.1, 0.9),
        vx: _r(-0.3, 0.3),
        vy: _r(-1.2, -0.4),
        maxLife: _r(0.5, 0.9),
        size: _r(0.04, 0.08),
        color: lighten(color, 0.4),
      ),
    );
  }

  // ------------------------------------------------------------ events

  void handle(GameEvent event, TetrisGame game) {
    switch (event) {
      case PieceSpawned():
        spawnAge = 0;
        offsetX = 0;
        offsetY = -0.6;
        _lastActiveY = game.active?.y;
        _lastActiveType = game.active?.type;
      case PieceMoved(:final dx):
        offsetX = (offsetX - dx).clamp(-1.0, 1.0);
      case PieceMoveBlocked(:final dx):
        offsetX = dx * 0.14;
        _wallBump(game, dx);
      case PieceRotated(:final kicked):
        rotatePop = 1;
        _rotateSparks(game, kicked ? 10 : 4);
      case SoftDropped():
        _softDropDust(game);
      case HardDropped():
        _hardDrop(event);
      case PieceLocked(:final cells):
        lockPulses.add(LockPulse(cells));
      case PieceHeld(:final type):
        holdPulse = 1;
        _holdBurst(game, type);
      case LinesCleared():
        _linesCleared(event, game);
      case TSpinNoLines(:final tSpin, :final points):
        final piece = game.active;
        floaters.add(
          Floater(5, piece == null ? 8 : (piece.y - TetrisGame.hiddenRows).clamp(3, 14).toDouble(), [
            FloaterLine(tSpin == TSpin.mini ? strings.miniTSpin : strings.tSpin, 1.1, _violet, glow: const Color(0xFFA855F7)),
            FloaterLine('+$points', 0.8, _gold),
          ]),
        );
        addTrauma(0.2);
        scorePulse = 1;
      case RowsCollapsed(:final rows):
        _collapse(rows);
      case LevelUp(:final level):
        _levelUp(level, speedingUp: game.mode.speedsUp && level <= speedCapLevel);
      case GameOver(won: true):
        gameOverAge = 0;
        shattered = false;
        finishedWon = true;
        addTrauma(0.3);
        pulseColor = const Color(0xFFFBBF24);
        pulse = 1;
        floaters.add(
          Floater(5, 8, [
            FloaterLine(game.mode == GameMode.ultra || game.mode == GameMode.target ? strings.timeUp : strings.challengeDone, 1.4, const [
              Color(0xFFFFFFFF),
              Color(0xFFFDE047),
              Color(0xFFF59E0B),
            ], glow: const Color(0xFFF59E0B)),
          ], duration: 2.2),
        );
      case GameOver():
        gameOverAge = 0;
        shattered = false;
        addTrauma(0.6);
        pulseColor = const Color(0xFFEF4444);
        pulse = 0.8;
      case EnergyGained():
        energyPulse = 1;
      case PowerEarned(:final type):
        powerPulse = 1;
        lastPower = type;
        final colors = powerColors[type]!;
        floaters.add(
          Floater(5, 3.0, [
            FloaterLine(strings.newPower, 0.5, const [Color(0xFFFFFFFF), Color(0xFFE9D5FF)]),
            FloaterLine(strings.powerName(type), 1.05, [const Color(0xFFFFFFFF), ...colors], glow: colors.last),
            FloaterLine(strings.powerDescription(type), 0.42, const [Color(0xFFF8FAFC), Color(0xFFCBD5E1)]),
          ], duration: 2.0),
        );
        pulseColor = colors.last;
        pulse = max(pulse, 0.5);
        for (var i = 0; i < 28; i++) {
          final a = _r(0, pi * 2);
          final speed = _r(3, 8);
          _add(
            Particle(
              kind: i.isEven ? ParticleKind.spark : ParticleKind.dot,
              x: 5,
              y: 3.0,
              vx: cos(a) * speed,
              vy: sin(a) * speed,
              maxLife: _r(0.5, 0.9),
              size: i.isEven ? _r(0.15, 0.3) : _r(0.05, 0.1),
              color: colors[i % colors.length],
              drag: 2.2,
            ),
          );
        }
      case PowerActivated(:final type):
        final colors = powerColors[type]!;
        pulseColor = colors.last;
        pulse = max(pulse, 0.6);
        boardFlash = max(boardFlash, 0.25);
        floaters.add(
          Floater(5, 7.5, [
            FloaterLine(strings.powerName(type), 1.1, [const Color(0xFFFFFFFF), ...colors], glow: colors.last),
          ], duration: 1.1),
        );
        _powerSparks(colors);
      case BombExploded(:final center, :final removed, :final points):
        _explode(center, removed, points);
      case ColumnDrilled(:final column, :final removed, :final points):
        _drill(column, removed, points);
      case GravityApplied(:final moves):
        _gravity(moves);
      case SlowMotionStarted() || SlowMotionEnded() || GhostLineStarted() || ChaosEnded():
        break;
      case StarsCollected(:final cells, :final seconds):
        _starsCollected(cells, seconds);
      case GarbageRaised():
        addTrauma(0.25);
        pulseColor = const Color(0xFF94A3B8);
        pulse = max(pulse, 0.4);
      case ChaosStarted(:final type):
        _chaos(type);
      case GhostLineFilled(:final row, :final cells):
        lockPulses.add(LockPulse(cells));
        for (final c in cells) {
          for (var i = 0; i < 4; i++) {
            final a = _r(0, pi * 2);
            _add(
              Particle(
                kind: i == 0 ? ParticleKind.spark : ParticleKind.dot,
                x: c.x + 0.5,
                y: row - TetrisGame.hiddenRows + 0.5,
                vx: cos(a) * _r(1, 4),
                vy: sin(a) * _r(1, 4),
                maxLife: _r(0.4, 0.8),
                size: i == 0 ? _r(0.15, 0.28) : _r(0.05, 0.1),
                color: const Color(0xFFE9D5FF),
                drag: 2,
              ),
            );
          }
        }
        addTrauma(0.2);
    }
  }

  void _starsCollected(List<Cell> cells, double seconds) {
    final h = TetrisGame.hiddenRows;
    for (final c in cells) {
      for (var i = 0; i < 14; i++) {
        final a = _r(0, pi * 2);
        final speed = _r(2, 8);
        _add(
          Particle(
            kind: i.isEven ? ParticleKind.spark : ParticleKind.dot,
            x: c.x + 0.5,
            y: c.y - h + 0.5,
            vx: cos(a) * speed,
            vy: sin(a) * speed - 2,
            maxLife: _r(0.5, 1.0),
            size: i.isEven ? _r(0.18, 0.34) : _r(0.06, 0.12),
            color: i % 3 == 0 ? const Color(0xFFFFFFFF) : const Color(0xFFFBBF24),
            drag: 2.2,
          ),
        );
      }
      shockwaves.add(Shockwave(c.x + 0.5, c.y - h + 0.5, 3, const Color(0xFFFDE047), duration: 0.5, width: 0.3));
    }
    final first = cells.first;
    floaters.add(
      Floater(5, (first.y - h - 2.5).clamp(3, 15).toDouble(), [
        FloaterLine(strings.plusSeconds(seconds), 1.1, _gold, glow: const Color(0xFFF59E0B)),
      ], duration: 1.3),
    );
    pulseColor = const Color(0xFFFBBF24);
    pulse = max(pulse, 0.8);
    scorePulse = 1;
  }

  /// Colours of each "Kaos" surprise.
  static const Map<ChaosEvent, List<Color>> chaosColors = {
    ChaosEvent.rise: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
    ChaosEvent.fog: [Color(0xFFF1F5F9), Color(0xFF7DD3FC)],
    ChaosEvent.rush: [Color(0xFFFDE047), Color(0xFFEF4444)],
    ChaosEvent.quake: [Color(0xFFFDBA74), Color(0xFFB45309)],
    ChaosEvent.gift: [Color(0xFFFDA4AF), Color(0xFFF43F5E)],
  };

  void _chaos(ChaosEvent type) {
    final colors = chaosColors[type]!;
    floaters.add(
      Floater(5, 6.5, [
        FloaterLine(strings.chaosName(type), 1.15, [const Color(0xFFFFFFFF), ...colors], glow: colors.last),
        FloaterLine(strings.chaosHint(type), 0.45, const [Color(0xFFF8FAFC), Color(0xFFCBD5E1)]),
      ], duration: 1.8),
    );
    pulseColor = colors.last;
    pulse = max(pulse, 0.7);
    boardFlash = max(boardFlash, 0.3);
    addTrauma(type == ChaosEvent.quake ? 0.8 : 0.35);
    _powerSparks(colors);
  }

  void _powerSparks(List<Color> colors) {
    for (var i = 0; i < 40; i++) {
      final a = _r(0, pi * 2);
      final speed = _r(4, 11);
      _add(
        Particle(
          kind: i.isEven ? ParticleKind.spark : ParticleKind.dot,
          x: 5,
          y: 8,
          vx: cos(a) * speed,
          vy: sin(a) * speed,
          maxLife: _r(0.5, 0.9),
          size: i.isEven ? _r(0.15, 0.3) : _r(0.05, 0.12),
          color: colors[i % colors.length],
          drag: 2.2,
        ),
      );
    }
    shockwaves.add(Shockwave(5, 8, 7, colors.last, duration: 0.5, width: 0.25));
  }

  void _explode(Cell center, List<RemovedCell> removed, int points) {
    final h = TetrisGame.hiddenRows;
    final cx = center.x + 0.5, cy = center.y - h + 0.5;
    shockwaves.add(Shockwave(cx, cy, 5, const Color(0xFFFDBA74), duration: 0.5, width: 0.4));
    shockwaves.add(Shockwave(cx, cy, 8, const Color(0xFFF43F5E), duration: 0.7, width: 0.25));
    const fire = [Color(0xFFFDE047), Color(0xFFF97316), Color(0xFFEF4444), Color(0xFFFFFFFF)];
    for (var i = 0; i < 70; i++) {
      final a = _r(0, pi * 2);
      final speed = _r(2, 12);
      _add(
        Particle(
          kind: i % 3 == 0 ? ParticleKind.spark : ParticleKind.dot,
          x: cx,
          y: cy,
          vx: cos(a) * speed,
          vy: sin(a) * speed - 2,
          maxLife: _r(0.4, 1.0),
          size: i % 3 == 0 ? _r(0.2, 0.4) : _r(0.08, 0.2),
          color: fire[i % fire.length],
          gravity: 4,
          drag: 2.5,
        ),
      );
    }
    for (final (cell, type) in removed) {
      final dx = cell.x + 0.5 - cx, dy = cell.y - h + 0.5 - cy;
      for (var i = 0; i < 2; i++) {
        _add(
          Particle(
            kind: ParticleKind.block,
            type: type,
            x: cell.x + 0.5,
            y: cell.y - h + 0.5,
            vx: dx * _r(6, 11) + _r(-2, 2),
            vy: dy * _r(6, 11) - _r(3, 7),
            maxLife: _r(0.8, 1.3),
            size: _r(0.3, 0.55),
            color: blockColors[type]!,
            gravity: 18,
            rotation: _r(0, pi),
            spin: _r(-10, 10),
          ),
        );
      }
    }
    floaters.add(
      Floater(cx.clamp(2.5, 7.5), (cy - 2.5).clamp(3, 15), [
        FloaterLine('+$points', 0.8, _gold, glow: const Color(0xFFF59E0B)),
      ], duration: 1.1),
    );
    boardFlash = max(boardFlash, 0.5);
    pulseColor = const Color(0xFFF97316);
    pulse = max(pulse, 0.9);
    scorePulse = 1;
    addTrauma(0.7);
  }

  void _drill(int column, List<RemovedCell> removed, int points) {
    final h = TetrisGame.hiddenRows;
    beams.add(DrillBeam(column));
    for (final (cell, type) in removed) {
      final y = cell.y - h + 0.5;
      final delay = max(0.0, y) * 0.012;
      for (var i = 0; i < 2; i++) {
        final dir = i.isEven ? -1 : 1;
        _add(
          Particle(
            kind: ParticleKind.block,
            type: type,
            x: column + 0.5,
            y: y,
            vx: dir * _r(3, 8),
            vy: _r(-5, -1),
            maxLife: _r(0.7, 1.1),
            size: _r(0.25, 0.45),
            color: blockColors[type]!,
            gravity: 16,
            rotation: _r(0, pi),
            spin: _r(-9, 9),
            delay: delay,
          ),
        );
      }
      _add(
        Particle(
          kind: ParticleKind.spark,
          x: column + 0.5,
          y: y,
          vx: _r(-2, 2),
          vy: _r(-2, 2),
          maxLife: _r(0.3, 0.6),
          size: _r(0.2, 0.35),
          color: const Color(0xFFFDE047),
          delay: delay,
        ),
      );
    }
    if (points > 0) {
      floaters.add(Floater(5, 6, [FloaterLine('+$points', 0.8, _gold, glow: const Color(0xFFF59E0B))], duration: 1.1));
    }
    scorePulse = 1;
    addTrauma(0.4);
  }

  void _gravity(List<FallenCell> moves) {
    final h = TetrisGame.hiddenRows;
    fallShift = {for (final (x, from, to) in moves) (x, to - h): (to - from).toDouble()};
    fallAge = 0;
    for (final (x, _, to) in moves) {
      for (var i = 0; i < 2; i++) {
        _add(
          Particle(
            kind: ParticleKind.dot,
            x: x + _r(0.1, 0.9),
            y: to - h + 1.0,
            vx: _r(-2, 2),
            vy: _r(-2, -0.5),
            maxLife: _r(0.3, 0.5),
            size: _r(0.05, 0.1),
            color: const Color(0xFF86EFAC),
            gravity: 6,
            delay: fallDuration * 0.55,
          ),
        );
      }
    }
    addTrauma(0.3);
  }

  void _wallBump(TetrisGame game, int dx) {
    final piece = game.active;
    if (piece == null) return;
    final edge = dx < 0 ? piece.cells.map((c) => c.x).reduce(min) : piece.cells.map((c) => c.x).reduce(max) + 1;
    for (final c in piece.cells.where((c) => c.x == (dx < 0 ? edge : edge - 1))) {
      for (var i = 0; i < 2; i++) {
        _add(
          Particle(
            kind: ParticleKind.spark,
            x: edge.toDouble(),
            y: c.y - TetrisGame.hiddenRows + _r(0.2, 0.8),
            vx: -dx * _r(0.5, 2),
            vy: _r(-1.5, 1.5),
            maxLife: _r(0.2, 0.35),
            size: _r(0.08, 0.14),
            color: const Color(0xFFFFFFFF),
            drag: 3,
          ),
        );
      }
    }
  }

  void _rotateSparks(TetrisGame game, int count) {
    final piece = game.active;
    if (piece == null) return;
    final cells = piece.cells.toList();
    final color = blockColors[piece.type]!;
    for (var i = 0; i < count; i++) {
      final c = cells[_rng.nextInt(cells.length)];
      final a = _r(0, pi * 2);
      final speed = _r(1.5, 4);
      _add(
        Particle(
          kind: i.isEven ? ParticleKind.spark : ParticleKind.dot,
          x: c.x + 0.5,
          y: c.y - TetrisGame.hiddenRows + 0.5,
          vx: cos(a) * speed,
          vy: sin(a) * speed,
          maxLife: _r(0.25, 0.45),
          size: _r(0.06, 0.16),
          color: lighten(color, 0.5),
          drag: 4,
        ),
      );
    }
  }

  void _softDropDust(TetrisGame game) {
    final piece = game.active;
    if (piece == null) return;
    final color = blockColors[piece.type]!;
    final top = piece.cells.map((c) => c.y).reduce(min);
    for (final c in piece.cells.where((c) => c.y == top)) {
      _add(
        Particle(
          kind: ParticleKind.dot,
          x: c.x + _r(0.2, 0.8),
          y: c.y - TetrisGame.hiddenRows + 0.1,
          vx: _r(-0.2, 0.2),
          vy: _r(-2.5, -1),
          maxLife: _r(0.25, 0.4),
          size: _r(0.04, 0.08),
          color: lighten(color, 0.3),
        ),
      );
    }
  }

  void _hardDrop(HardDropped e) {
    final color = blockColors[e.type]!;
    final h = TetrisGame.hiddenRows;
    final columns = <int, (int top, int bottom)>{};
    for (final c in e.toCells) {
      final prev = columns[c.x];
      columns[c.x] = prev == null ? (c.y, c.y) : (min(prev.$1, c.y), max(prev.$2, c.y));
    }
    if (particlesEnabled && e.distance > 0) {
      final fromTop = e.fromCells.map((c) => c.y).reduce(min);
      for (final entry in columns.entries) {
        trails.add(DropTrail(entry.key, (fromTop - h).toDouble(), (entry.value.$1 - h).toDouble(), color));
      }
    }

    // Impact dust from every bottom-facing cell.
    final cells = e.toCells.toSet();
    for (final c in e.toCells) {
      if (cells.contains(Cell(c.x, c.y + 1))) continue;
      for (var i = 0; i < 5; i++) {
        final dir = i.isEven ? -1 : 1;
        _add(
          Particle(
            kind: i < 3 ? ParticleKind.dot : ParticleKind.spark,
            x: c.x + _r(0.1, 0.9),
            y: c.y - h + 1,
            vx: dir * _r(1.5, 5),
            vy: _r(-3.5, -0.8),
            maxLife: _r(0.35, 0.6),
            size: _r(0.05, 0.14),
            color: i < 3 ? lighten(color, 0.3) : const Color(0xFFFFFFFF),
            gravity: 9,
            drag: 2,
          ),
        );
      }
    }
    final bottom = e.toCells.map((c) => c.y).reduce(max) - h + 1.0;
    final cx = e.toCells.map((c) => c.x + 0.5).reduce((a, b) => a + b) / e.toCells.length;
    if (particlesEnabled) shockwaves.add(Shockwave(cx, bottom, 2.2 + e.distance * 0.05, lighten(color, 0.3), duration: 0.35, width: 0.18));
    addTrauma(min(0.45, 0.18 + e.distance * 0.012));
    offsetY = 0;
  }

  void _holdBurst(TetrisGame game, PieceType type) {
    final color = blockColors[type]!;
    final piece = game.active;
    final cx = piece == null ? 5.0 : piece.x + 1.5;
    for (var i = 0; i < 14; i++) {
      final a = _r(0, pi * 2);
      final speed = _r(2, 6);
      _add(
        Particle(
          kind: i % 3 == 0 ? ParticleKind.block : ParticleKind.spark,
          type: type,
          x: cx,
          y: 0.5,
          vx: cos(a) * speed,
          vy: sin(a) * speed,
          maxLife: _r(0.35, 0.6),
          size: i % 3 == 0 ? _r(0.2, 0.32) : _r(0.08, 0.16),
          color: lighten(color, 0.4),
          drag: 3,
          spin: _r(-8, 8),
        ),
      );
    }
  }

  void _linesCleared(LinesCleared e, TetrisGame game) {
    final h = TetrisGame.hiddenRows;
    final n = e.count;
    final delayScale = TetrisGame.lineClearDelay;

    // Shards burst from each cell as the clear sweeps outward from the centre.
    for (final row in e.rows) {
      for (var x = 0; x < TetrisGame.width; x++) {
        final type = game.cellAt(x, row);
        if (type == null) continue;
        final color = blockColors[type]!;
        final delay = cellVanishTime(x) * delayScale;
        final cx = x + 0.5, cy = row - h + 0.5;
        for (var i = 0; i < 3; i++) {
          final a = _r(-pi * 0.95, -pi * 0.05);
          final speed = _r(3, 8 + n * 1.5);
          _add(
            Particle(
              kind: ParticleKind.block,
              type: type,
              x: cx,
              y: cy,
              vx: cos(a) * speed,
              vy: sin(a) * speed,
              maxLife: _r(0.7, 1.2),
              size: _r(0.22, 0.45),
              color: color,
              gravity: 16,
              drag: 0.6,
              rotation: _r(0, pi),
              spin: _r(-9, 9),
              delay: delay,
            ),
          );
        }
        for (var i = 0; i < 3; i++) {
          final a = _r(0, pi * 2);
          final speed = _r(2, 7);
          _add(
            Particle(
              kind: i == 0 ? ParticleKind.spark : ParticleKind.dot,
              x: cx,
              y: cy,
              vx: cos(a) * speed,
              vy: sin(a) * speed,
              maxLife: _r(0.35, 0.8),
              size: i == 0 ? _r(0.14, 0.3) : _r(0.05, 0.12),
              color: i == 0 ? const Color(0xFFFFFFFF) : lighten(color, 0.35),
              gravity: 5,
              drag: 1.5,
              delay: delay,
            ),
          );
        }
      }
    }

    final topRow = e.rows.reduce(min) - h;
    final bottomRow = e.rows.reduce(max) - h + 1;
    final midY = (topRow + bottomRow) / 2;
    if (particlesEnabled) {
      shockwaves.add(Shockwave(5, midY, 4 + n * 1.5, const Color(0xFFFFFFFF), duration: 0.5, width: 0.22));
    }

    final big = n == 4 || e.tSpin != TSpin.none || e.perfectClear;
    if (big) _confetti(midY, n == 4 || e.perfectClear ? 140 : 70);
    if (n == 4 || e.perfectClear) {
      boardFlash = 0.85;
      if (particlesEnabled) shockwaves.add(Shockwave(5, midY, 12, const Color(0xFF7DD3FC), duration: 0.8, width: 0.35));
    }

    addTrauma(
      switch (n) {
            1 => 0.15,
            2 => 0.25,
            3 => 0.4,
            _ => 0.7,
          } +
          (e.tSpin != TSpin.none ? 0.15 : 0),
    );
    pulseColor = n == 4
        ? const Color(0xFF22D3EE)
        : e.tSpin != TSpin.none
        ? const Color(0xFFA855F7)
        : const Color(0xFF38BDF8);
    pulse = max(pulse, 0.25 + n * 0.15 + (e.perfectClear ? 0.4 : 0));
    scorePulse = 1;

    final lines = <FloaterLine>[];
    if (e.perfectClear) lines.add(FloaterLine(strings.perfectClear, 1.6, _perfect, glow: const Color(0xFFFDE047)));
    final label = strings.clearLabel(n, e.tSpin);
    final (size, colors, glow) = switch ((n, e.tSpin)) {
      (_, TSpin.full || TSpin.mini) => (1.45, _violet, const Color(0xFFA855F7)),
      (4, _) => (2.0, _rainbow, const Color(0xFF22D3EE)),
      (3, _) => (1.6, _cool, const Color(0xFF38BDF8)),
      (2, _) => (1.45, _cool, const Color(0xFF38BDF8)),
      _ => (1.1, _cool, const Color(0xFF38BDF8)),
    };
    lines.add(FloaterLine(label, size, colors, glow: glow));
    lines.add(FloaterLine('+${e.points}', 0.85, _gold, glow: const Color(0xFFF59E0B)));
    if (e.backToBack) lines.add(FloaterLine(strings.backToBack, 0.6, _b2b, glow: const Color(0xFFF97316)));
    if (e.combo >= 1) lines.add(FloaterLine(strings.combo(e.combo), 0.6, _combo, glow: const Color(0xFF6366F1)));
    floaters.add(Floater(5, (topRow - 3.2).clamp(3.5, 12.0), lines, duration: big ? 1.8 : 1.35));
  }

  /// When a cell of a clearing row vanishes, as a fraction of the clear delay.
  /// The clear sweeps outward from the centre columns.
  static double cellVanishTime(int x) => 0.18 + 0.62 * ((x + 0.5 - 5).abs() / 5);

  void _confetti(double y, int count) {
    for (var i = 0; i < count; i++) {
      final type = standardPieces[_rng.nextInt(standardPieces.length)];
      final a = _r(-pi * 0.85, -pi * 0.15);
      final speed = _r(8, 19);
      final isBlock = i % 3 != 0;
      _add(
        Particle(
          kind: isBlock ? ParticleKind.block : ParticleKind.spark,
          type: type,
          x: _r(1, 9),
          y: y,
          vx: cos(a) * speed,
          vy: sin(a) * speed,
          maxLife: _r(1.4, 2.3),
          size: isBlock ? _r(0.18, 0.36) : _r(0.15, 0.32),
          color: isBlock ? blockColors[type]! : lighten(blockColors[type]!, 0.6),
          gravity: 13,
          drag: 0.9,
          rotation: _r(0, pi),
          spin: _r(-10, 10),
          delay: _r(0, 0.15),
        ),
      );
    }
  }

  void _collapse(List<int> rows) {
    final shift = <int, double>{};
    final h = TetrisGame.hiddenRows;
    for (var old = 0; old < TetrisGame.height; old++) {
      if (rows.contains(old)) continue;
      final below = rows.where((r) => r > old).length;
      if (below > 0) shift[old + below - h] = below.toDouble();
    }
    collapseShift = shift;
    collapseAge = 0;
  }

  void _levelUp(int level, {required bool speedingUp}) {
    levelWaveAge = 0;
    levelPulse = 1;
    pulseColor = const Color(0xFF6366F1);
    pulse = max(pulse, 0.9);
    addTrauma(0.25);
    floaters.add(
      Floater(5, 6.5, [
        FloaterLine(strings.levelUp(level), 1.5, const [
          Color(0xFFFFFFFF),
          Color(0xFF38BDF8),
          Color(0xFF6366F1),
        ], glow: const Color(0xFF6366F1)),
        FloaterLine(speedingUp ? strings.speedingUp : strings.keepGoing, 0.55, const [Color(0xFFE0F2FE), Color(0xFF7DD3FC)]),
      ], duration: 1.8),
    );
    for (var i = 0; i < 60; i++) {
      final left = i.isEven;
      _add(
        Particle(
          kind: i % 4 == 0 ? ParticleKind.spark : ParticleKind.dot,
          x: left ? _r(-0.3, 0.3) : _r(9.7, 10.3),
          y: _r(14, 20),
          vx: left ? _r(-0.5, 0.8) : _r(-0.8, 0.5),
          vy: _r(-14, -6),
          maxLife: _r(0.8, 1.4),
          size: i % 4 == 0 ? _r(0.15, 0.3) : _r(0.05, 0.1),
          color: i % 3 == 0 ? const Color(0xFFFFFFFF) : const Color(0xFF7DD3FC),
          drag: 0.8,
          delay: _r(0, 0.4),
        ),
      );
    }
  }

  void _shatter(TetrisGame game) {
    shattered = true;
    final h = TetrisGame.hiddenRows;
    for (var y = h; y < TetrisGame.height; y++) {
      for (var x = 0; x < TetrisGame.width; x++) {
        if (game.cellAt(x, y) == null) continue;
        _add(
          Particle(
            kind: ParticleKind.grayBlock,
            x: x + 0.5,
            y: y - h + 0.5,
            vx: _r(-3.5, 3.5),
            vy: _r(-7, -1),
            maxLife: _r(1.6, 2.6),
            size: 1,
            color: const Color(0xFF64748B),
            gravity: 22,
            rotation: 0,
            spin: _r(-5, 5),
            delay: (TetrisGame.height - y) * 0.015 + _r(0, 0.05),
          ),
        );
      }
    }
    addTrauma(0.5);
  }
}
