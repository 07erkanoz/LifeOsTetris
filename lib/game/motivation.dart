import 'dart:math';

import '../core/scoring.dart';
import '../core/tetris_game.dart';
import '../l10n/strings.dart';

enum MotivationKind { praise, scoreMilestone, linesMilestone, newBest, combo, backToBack, closeCall, maxSpeed, firstQuad }

class Motivation {
  const Motivation(this.kind, this.id, {this.value = 0});

  final MotivationKind kind;
  final int id;

  /// Milestone value, combo count or praise index depending on [kind].
  final int value;

  int get priority => switch (kind) {
    MotivationKind.newBest => 5,
    MotivationKind.scoreMilestone || MotivationKind.firstQuad || MotivationKind.maxSpeed => 4,
    MotivationKind.linesMilestone || MotivationKind.closeCall => 3,
    MotivationKind.combo || MotivationKind.backToBack => 2,
    MotivationKind.praise => 1,
  };

  String text(AppStrings s) => switch (kind) {
    MotivationKind.praise => s.praise[value % s.praise.length],
    MotivationKind.scoreMilestone => s.scoreMilestone(value),
    MotivationKind.linesMilestone => s.linesMilestone(value),
    MotivationKind.newBest => s.newBest,
    MotivationKind.combo => s.comboStreak(value),
    MotivationKind.backToBack => s.backToBackPraise,
    MotivationKind.closeCall => s.closeCall,
    MotivationKind.maxSpeed => s.maxSpeed,
    MotivationKind.firstQuad => s.firstQuad,
  };
}

/// Decides when to cheer the player on. Messages are rate limited so they
/// stay special: only important ones (records, milestones) may interrupt.
class MotivationEngine {
  MotivationEngine({int? seed}) : _random = Random(seed);

  final Random _random;

  static const scoreMilestones = [1000, 2500, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000];
  static const lineMilestones = [25, 50, 100, 150, 200, 300, 500];
  static const showFor = 2.4;
  static const cooldown = 3.2;

  Motivation? current;
  double age = 0;

  int _nextId = 1;
  int _bestAtStart = 0;
  int _lastScore = 0;
  bool _beatBest = false;
  bool _quadDone = false;
  double _sinceShown = 99;
  double _sinceCloseCall = 99;
  int _lastPraise = -1;

  void reset({required int bestScore}) {
    current = null;
    age = 0;
    _bestAtStart = bestScore;
    _lastScore = 0;
    _beatBest = false;
    _quadDone = false;
    _sinceShown = 99;
    _sinceCloseCall = 99;
  }

  bool get visible => current != null && age < showFor;

  void update(double dt, TetrisGame game) {
    age += dt;
    _sinceShown += dt;
    _sinceCloseCall += dt;
    if (current != null && age >= showFor) current = null;
    if (game.mode == GameMode.puzzle) return;

    final score = game.score;
    if (score != _lastScore) {
      if (!_beatBest && _bestAtStart > 0 && _lastScore <= _bestAtStart && score > _bestAtStart) {
        _beatBest = true;
        _offer(MotivationKind.newBest);
      } else {
        for (final m in scoreMilestones) {
          if (_lastScore < m && score >= m) _offer(MotivationKind.scoreMilestone, value: m);
        }
      }
      _lastScore = score;
    }
  }

  void onEvent(GameEvent event, TetrisGame game) {
    if (game.mode == GameMode.puzzle) return;
    switch (event) {
      case LinesCleared(:final count, :final combo, :final backToBack, :final rows):
        final linesBefore = game.lines - count;
        for (final m in lineMilestones) {
          if (linesBefore < m && game.lines >= m) _offer(MotivationKind.linesMilestone, value: m);
        }
        if (count == 4 && !_quadDone) {
          _quadDone = true;
          _offer(MotivationKind.firstQuad);
        }
        if (_stackHeight(game, rows) >= 15 && _sinceCloseCall > 15) {
          _sinceCloseCall = 0;
          _offer(MotivationKind.closeCall);
        }
        if (combo >= 3) _offer(MotivationKind.combo, value: combo);
        if (backToBack) _offer(MotivationKind.backToBack);
        final chance = count >= 2 ? 0.35 : 0.08;
        if (_random.nextDouble() < chance) _offer(MotivationKind.praise, value: _pickPraise());
      case LevelUp(:final level):
        if (game.mode.speedsUp && level == speedCapLevel) _offer(MotivationKind.maxSpeed);
      default:
        break;
    }
  }

  int _pickPraise() {
    var i = _random.nextInt(10);
    if (i == _lastPraise) i = (i + 1) % 10;
    return _lastPraise = i;
  }

  /// Height of the stack (in visible rows) before the clear removed [rows].
  int _stackHeight(TetrisGame game, List<int> rows) {
    for (var y = TetrisGame.hiddenRows; y < TetrisGame.height; y++) {
      if (rows.contains(y)) continue;
      if (game.board[y].any((c) => c != null)) return TetrisGame.height - y;
    }
    return 0;
  }

  void _offer(MotivationKind kind, {int value = 0}) {
    final candidate = Motivation(kind, _nextId, value: value);
    final showing = visible ? current : null;
    if (showing != null && candidate.priority <= showing.priority) return;
    if (showing == null && candidate.priority <= 2 && _sinceShown < cooldown) return;
    _nextId++;
    current = candidate;
    age = 0;
    _sinceShown = 0;
  }
}
