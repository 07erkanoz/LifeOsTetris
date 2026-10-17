import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../audio/audio_service.dart';
import '../../audio/haptics.dart';
import '../../core/rewards.dart';
import '../../core/tower/tower_game.dart';
import '../../l10n/strings.dart';
import '../../settings/settings.dart';
import '../sugar/sugar_art.dart';
import 'tower_art.dart';

/// A piece falling off the tower: the cut-off part, or a floor that missed.
class TowerPiece {
  TowerPiece(this.floor, this.level, {this.spin = 1});

  final TowerFloor floor;

  /// Floor level it started at (may be fractional as it falls).
  double level;
  double fall = 0;
  double angle = 0;
  final double spin;
  double age = 0;
}

/// A ring spreading round a floor dropped right on.
class TowerRing {
  TowerRing(this.floor, this.level);

  final TowerFloor floor;
  final int level;
  double age = 0;
}

/// A word over the tower: MÜKEMMEL, the streak, a floor grown back.
class TowerLabel {
  TowerLabel(this.kind, this.value, this.level);

  final TowerLabelKind kind;
  final int value;
  final int level;
  double age = 0;
}

enum TowerLabelKind { perfect, grew, milestone }

enum SparkKind {
  /// Sugar crumbs from a cut: they fall.
  crumb,

  /// A star from a perfect drop: it flies out and fades.
  star,

  /// Confetti from a milestone: it flutters down.
  confetti,

  /// A puff of sugar dust where a floor lands.
  puff,
}

/// A particle, born at a point of the tower (floor units and level) and
/// moving from there in screen pixels.
class TowerSpark {
  TowerSpark(this.kind, this.cu, this.cv, this.level, {required this.vx, required this.vy, required this.color, required this.size, this.life = 0.9, this.spin = 0});

  final SparkKind kind;
  final double cu, cv, level;
  double dx = 0, dy = 0;
  double vx, vy;
  final Color color;
  final double size;
  final double life;
  final double spin;
  double age = 0;
}

/// Runs a Kule Küpler game: time, taps, the camera, falling pieces, sound,
/// haptics, chests and records.
class TowerController extends ChangeNotifier {
  TowerController({required this.settings, required this.audio, Haptics? haptics, required this.mode, TowerGame? game})
    : haptics = haptics ?? Haptics(),
      game = game ?? TowerGame() {
    settings.addListener(_applySettings);
    _applySettings();
  }

  final Settings settings;
  final AudioService audio;
  final Haptics haptics;
  final TowerGame game;
  final TowerMode mode;

  /// The words over the tower, in the player's language.
  AppStrings strings = AppStrings.tr;

  /// Repaints the tower.
  final ValueNotifier<int> frame = ValueNotifier(0);

  bool paused = false;

  /// A drop has been made: the hint goes away.
  bool dropped = false;

  /// The camera's height, in floors, easing after the top of the tower.
  double camera = 0;

  /// Seconds since the last floor landed (its little bounce).
  double landAge = 9;
  final List<TowerPiece> pieces = [];
  final List<TowerRing> rings = [];
  final List<TowerLabel> labels = [];
  final List<TowerSpark> sparks = [];
  bool effects = true;
  bool shakeOn = true;

  /// Screen shake, 0 to 1, easing off.
  double shake = 0;

  /// A flash over the whole view: its strength and colour.
  double flash = 0;
  Color flashColor = const Color(0xFFFFFFFF);

  /// The top floor's glow after a perfect drop; gold once a streak runs.
  double topGlow = 0;
  bool goldGlow = false;

  final Random _fx = Random();

  /// A chest reached and not yet opened: the run waits for it.
  int? chestAt;

  double clock = 0;
  double _overAge = -1;
  double _runSeconds = 0;
  bool _recorded = false;
  bool _wasBest = false;

  /// How the floors look: the chosen look if it is unlocked.
  FloorLook get look {
    final l = FloorLook.parse(settings.towerLook);
    final u = l.unlock;
    return u == null || settings.unlocked(u) ? l : FloorLook.lokum;
  }

  /// What Lokum wears, cheering by the tower.
  LokumOutfit get outfit => LokumOutfit.worn(settings.lokumOutfit, settings.totalSugarStars, settings.unlocks);

  bool get playing => game.status == TowerStatus.playing;
  int get best => mode == TowerMode.daily ? settings.towerDayBest(settings.clock()) : settings.towerBest(mode);

  /// The tower beat the best so far.
  bool get newRecord => _wasBest || (game.height > 0 && game.height > best && !_recorded);

  /// The game-over panel waits a moment so the fall can be seen.
  bool get showResult => game.isOver && _overAge > 0.9;

  /// One more go after a miss, once a run (not on the day's tower).
  bool get canRevive => game.isOver && !game.revived && mode != TowerMode.daily;

  /// The next chest's floor.
  int get nextChest => TowerGame.milestoneAfter(game.height);

  void _applySettings() {
    effects = settings.effects;
    shakeOn = settings.shake;
    audio.sfxOn = settings.sfx;
    audio.musicOn = settings.music;
    audio.musicVolume = settings.musicVolume;
    haptics.strength = settings.vibrationStrength;
  }

  void start() {
    final day = settings.clock();
    game.start(mode, seed: mode == TowerMode.daily ? TowerGame.dailySeed(DateTime(day.year, day.month, day.day)) : null);
    settings.lastPlay = switch (mode) {
      TowerMode.climb => 'towerClimb',
      TowerMode.wind => 'towerWind',
      TowerMode.daily => 'towerDaily',
    };
    paused = false;
    dropped = false;
    camera = 0;
    landAge = 9;
    pieces.clear();
    rings.clear();
    labels.clear();
    sparks.clear();
    shake = 0;
    flash = 0;
    topGlow = 0;
    chestAt = null;
    _overAge = -1;
    _runSeconds = 0;
    _recorded = false;
    _wasBest = false;
    audio.startMusic();
    audio.duck = 1;
    audio.play(Sfx.start, volume: 0.8);
    notifyListeners();
  }

  /// A tap: drops the sliding floor.
  void tap() {
    if (!playing || paused || chestAt != null) return;
    dropped = true;
    game.drop();
    _process(game.drainEvents());
    notifyListeners();
  }

  void togglePause() {
    if (!playing || chestAt != null) return;
    paused = !paused;
    audio.duck = paused ? 0.35 : 1;
    audio.play(Sfx.click);
    notifyListeners();
  }

  void pauseIfRunning() {
    if (playing && !paused && chestAt == null) togglePause();
  }

  /// One more go after a miss.
  void revive() {
    if (!canRevive) return;
    game.revive();
    _overAge = -1;
    audio.play(Sfx.power);
    if (settings.vibration) haptics.medium();
    notifyListeners();
  }

  /// The chest waiting at [chestAt]: its gift, given now. The run goes on
  /// with [closeChest].
  Gift openChest() {
    final at = chestAt ?? game.height;
    final look = Rewards.towerLooks[at];
    final gift = Rewards.towerChest(at, unlock: look != null && !settings.unlocked(look) ? look : null);
    settings.applyGift(gift);
    return gift;
  }

  void closeChest() {
    chestAt = null;
    notifyListeners();
  }

  /// Records the run (once): its floors go to İstanbul'u İnşa Et.
  void finishRun() {
    if (_recorded || game.height <= 0 && !game.isOver) return;
    _wasBest = newRecord;
    _recorded = true;
    settings.recordTowerRun(mode: mode, floors: game.height, seconds: _runSeconds);
  }

  // ----------------------------------------------------------------- time --

  Duration? _lastTick;
  double _sinceRepaint = 0;
  Object? _hud;

  void tick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    final running = playing && !paused && chestAt == null;
    if (running) {
      game.update(dt);
      _runSeconds += dt;
      _process(game.drainEvents());
    }
    if (_overAge >= 0) _overAge += dt;
    clock += dt;
    if (!paused) _animate(dt);
    _sinceRepaint += dt;
    final busy = pieces.isNotEmpty || rings.isNotEmpty || labels.isNotEmpty || sparks.isNotEmpty || landAge < 0.4 || flash > 0 || shake > 0 || (camera - _cameraTarget).abs() > 0.01;
    final idle = paused || (chestAt != null && !busy) || (game.isOver && !busy && _overAge > 2);
    final interval = settings.highRefreshRate ? 0.0 : 1 / 60;
    if (!idle && _sinceRepaint >= interval - 0.004) {
      _sinceRepaint = 0;
      frame.value++;
    }
    final hud = (game.status, paused, game.height, game.streak, showResult, chestAt);
    if (hud != _hud) {
      _hud = hud;
      notifyListeners();
    }
  }

  /// Where the camera heads: a few floors under the top.
  double get _cameraTarget => max(0, game.height - 5.5);

  void _animate(double dt) {
    camera += (_cameraTarget - camera) * min(1, dt * 3.2);
    landAge += dt;
    for (final p in pieces) {
      p.age += dt;
      p.fall += dt * (2 + p.age * 26);
      p.angle += dt * p.spin * 2.2;
    }
    pieces.removeWhere((p) => p.age > 2.2);
    for (final r in rings) {
      r.age += dt;
    }
    rings.removeWhere((r) => r.age > 0.7);
    for (final l in labels) {
      l.age += dt;
    }
    labels.removeWhere((l) => l.age > 1.1);
    for (final s in sparks) {
      s.age += dt;
      s.dx += s.vx * dt;
      s.dy += s.vy * dt;
      switch (s.kind) {
        case SparkKind.crumb:
          s.vy += 900 * dt;
        case SparkKind.confetti:
          s.vy = min(s.vy + 260 * dt, 140);
          s.vx *= 1 - dt * 1.5;
        case SparkKind.star:
          s.vx *= 1 - dt * 3;
          s.vy *= 1 - dt * 3;
        case SparkKind.puff:
          s.vx *= 1 - dt * 4;
          s.vy *= 1 - dt * 4;
      }
    }
    sparks.removeWhere((s) => s.age > s.life);
    shake = max(0, shake - dt * 2.6);
    flash = max(0, flash - dt * 2.2);
    topGlow = max(0, topGlow - dt * 2);
  }

  void _shake(double amount) {
    if (shakeOn) shake = max(shake, amount);
  }

  /// Sugar dust puffing out from under a floor's front corners.
  void _puffs(TowerFloor f, int level) {
    if (!effects) return;
    for (var i = 0; i < 14; i++) {
      // Along the two front edges, drifting out.
      final t = _fx.nextDouble();
      final right = i.isEven;
      final cu = right ? f.cu + f.a : f.cu - f.a + 2 * f.a * t;
      final cv = right ? f.cv - f.b + 2 * f.b * t : f.cv + f.b;
      sparks.add(TowerSpark(SparkKind.puff, cu, cv, level - 1.0,
          vx: (right ? 1 : -1) * (30 + _fx.nextDouble() * 60), vy: -6 - _fx.nextDouble() * 24, color: const Color(0xFFFFFBF2), size: 3 + _fx.nextDouble() * 4, life: 0.5));
    }
  }

  /// Stars bursting from a floor dropped right on; more and golden as a
  /// streak runs.
  void _stars(TowerFloor f, int level, int streak) {
    if (!effects) return;
    final n = 10 + min(streak, 8) * 2;
    for (var i = 0; i < n; i++) {
      final a = i / n * pi * 2 + _fx.nextDouble() * 0.3;
      final speed = 140 + _fx.nextDouble() * 160 + streak * 10;
      sparks.add(TowerSpark(SparkKind.star, f.cu, f.cv, level.toDouble(),
          vx: cos(a) * speed, vy: sin(a) * speed * 0.55 - 40,
          color: streak >= 4 ? const Color(0xFFFFD34D) : (i.isEven ? const Color(0xFFFFFFFF) : const Color(0xFFFF9AD8)), size: 8 + _fx.nextDouble() * 7, life: 0.75));
    }
  }

  /// Crumbs off a cut edge.
  void _crumbs(TowerFloor cut, int level) {
    if (!effects) return;
    final color = floorColor(look, cut.flavor);
    for (var i = 0; i < 14; i++) {
      sparks.add(TowerSpark(SparkKind.crumb, cut.cu, cut.cv, level.toDouble(),
          vx: (_fx.nextDouble() - 0.5) * 220, vy: -120 - _fx.nextDouble() * 160, color: i % 3 == 0 ? const Color(0xFFFFF7EC) : color, size: 4 + _fx.nextDouble() * 4.5,
          life: 1.1, spin: _fx.nextDouble() * 8 - 4));
    }
  }

  /// Confetti for a milestone, from above the tower.
  void _confetti(int level) {
    if (!effects) return;
    const colors = [Color(0xFFFF5FB8), Color(0xFFFFD34D), Color(0xFF7FDCC4), Color(0xFF9CC8FF), Color(0xFFFF8A3D), Color(0xFFBFA2FF)];
    for (var i = 0; i < 70; i++) {
      sparks.add(TowerSpark(SparkKind.confetti, 0, 0, level + 5.0,
          vx: (_fx.nextDouble() - 0.5) * 520, vy: -80 - _fx.nextDouble() * 260, color: colors[i % colors.length], size: 5 + _fx.nextDouble() * 5, life: 2.4, spin: _fx.nextDouble() * 10 - 5));
    }
  }

  void _process(List<TowerEvent> events) {
    for (final e in events) {
      switch (e) {
        case TowerPlaced():
          landAge = 0;
          _puffs(e.floor, e.height);
          final cut = e.cut;
          if (cut != null) {
            pieces.add(TowerPiece(cut, e.height.toDouble(), spin: (cut.cu + cut.cv) >= (e.floor.cu + e.floor.cv) ? 1 : -1));
            _crumbs(cut, e.height);
            _shake(0.18 + min(0.3, max(cut.a, cut.b) * 0.5));
          }
          if (e.perfect) {
            topGlow = 1;
            goldGlow = e.streak >= 4;
            _stars(e.floor, e.height, e.streak);
            if (e.grew) {
              flash = 0.35;
              flashColor = const Color(0xFF8DFFB4);
            }
            if (effects) rings.add(TowerRing(e.floor, e.height));
            labels.add(TowerLabel(TowerLabelKind.perfect, e.streak, e.height));
            if (e.grew) labels.add(TowerLabel(TowerLabelKind.grew, 0, e.height));
            if (e.streak >= 2) {
              audio.playCombo(min(8, e.streak - 1));
            } else {
              audio.play(Sfx.perfect, volume: 0.8);
            }
            if (settings.vibration) e.grew ? haptics.heavy() : haptics.medium();
          } else {
            audio.play(Sfx.lock, volume: 0.9);
            if (settings.vibration) haptics.light();
          }
        case TowerMilestone():
          chestAt = e.height;
          _confetti(e.height);
          flash = 0.55;
          flashColor = const Color(0xFFFFE07A);
          labels.add(TowerLabel(TowerLabelKind.milestone, e.height, e.height));
          audio.play(Sfx.levelup);
          if (settings.vibration) haptics.celebrate();
        case TowerMissed():
          _shake(0.9);
          flash = 0.4;
          flashColor = const Color(0xFFFF4D6A);
          pieces.add(TowerPiece(e.slab, game.height + 1.0, spin: e.slab.cu + e.slab.cv >= game.top.cu + game.top.cv ? 1 : -1));
        case TowerGameOver():
          _overAge = 0;
          audio.play(Sfx.gameover, volume: 0.8);
          if (settings.vibration) haptics.heavy();
          if (!canRevive) finishRun();
      }
    }
  }

  @override
  void dispose() {
    settings.removeListener(_applySettings);
    frame.dispose();
    super.dispose();
  }
}
