import 'dart:math';

import '../core/scoring.dart';
import '../core/tetris_game.dart';
import '../l10n/strings.dart';
import '../l10n/voice_lines.dart';
import 'play_history.dart';

/// What the voice knows about the player when a game starts: their own
/// record, average and habits. Lines compare the player only with
/// themselves.
class VoiceContext {
  const VoiceContext({
    this.best = 0,
    this.scores = true,
    this.average,
    this.todayBest,
    this.maxQuads = 0,
    this.levelCeiling,
    this.novice = false,
    this.opening,
  });

  /// Says nothing at the start (a resumed game, the menu).
  static const VoiceContext quiet = VoiceContext();

  /// Built from the saved history for a new game of [mode].
  factory VoiceContext.forGame(
    GameMode mode, {
    required int best,
    required PlayHistory history,
    required DateTime now,
    required int gamesPlayed,
  }) {
    final scores = !mode.recordsTime;
    final games = history.ofMode(mode);
    final last = games.isEmpty ? null : games.last;
    final firstToday = !history.playedOn(now);
    final hour = now.hour;

    // One line to open the game with, if there is something worth saying.
    VoiceLine? opening;
    final gap = last == null || !scores || last.record || best <= 0 ? null : best - last.score;
    if (gap != null && gap > 0 && last!.score >= best * 0.85) {
      opening = VoiceLine(Voice.openNearMiss, 0, {'gap': gap});
    } else if (last != null && last.seconds < 45 && !last.won) {
      opening = const VoiceLine(Voice.openQuickLoss, 0);
    } else if (firstToday && history.streak(now) >= 1) {
      // Playing today keeps the run of days going: yesterday's streak + 1.
      opening = VoiceLine(Voice.openStreak, 0, {'days': history.streak(now) + 1});
    } else if (hour < 5 && firstToday) {
      opening = const VoiceLine(Voice.openNight, 0);
    } else if (hour >= 6 && hour < 10 && firstToday) {
      opening = const VoiceLine(Voice.openMorning, 0);
    }

    return VoiceContext(
      best: best,
      scores: scores,
      average: scores ? history.averageScore(mode) : null,
      todayBest: scores ? history.todayBest(mode, now) : null,
      maxQuads: history.maxQuads(mode),
      levelCeiling: history.levelCeiling(mode),
      novice: gamesPlayed < 8,
      opening: opening,
    );
  }

  VoiceContext withoutOpening() => VoiceContext(
    best: best,
    scores: scores,
    average: average,
    todayBest: todayBest,
    maxQuads: maxQuads,
    levelCeiling: levelCeiling,
    novice: novice,
  );

  /// Best score of the mode before this game (0 before the first one).
  final int best;

  /// The mode is won on points (not on time).
  final bool scores;
  final int? average;
  final int? todayBest;
  final int maxQuads;
  final int? levelCeiling;
  final bool novice;

  /// Said shortly after the start; its variant is picked when shown.
  final VoiceLine? opening;
}

/// A line on screen.
class Motivation {
  const Motivation(this.line, this.id, {required this.priority, this.loud = false, this.duration = 3});

  final VoiceLine line;
  final int id;
  final int priority;

  /// A moment worth a sound (a record), not just a quiet word.
  final bool loud;

  /// Seconds on screen: longer lines stay longer.
  final double duration;

  Voice get kind => line.voice;
  String text(AppStrings s) => line.text(s);
}

/// Picks the line to show for [voice] with [values], without repeating
/// recent wordings.
VoiceLine pickLine(Voice voice, LineMemory memory, Random random, [Map<String, num> values = const {}]) {
  final usable = usableVariants(voice, values.keys);
  return VoiceLine(voice, memory.pick(voice.name, usable, random), values);
}

/// Decides when the game speaks. It talks rarely, and only about something
/// that really happened to this player in this game.
class MotivationEngine {
  MotivationEngine({int? seed, LineMemory? memory}) : _random = Random(seed), memory = memory ?? LineMemory();

  final Random _random;
  final LineMemory memory;

  /// Seconds after the start before the opening line.
  static const double openingDelay = 1.2;

  /// Quiet time after a line before a minor one may follow.
  static const double cooldown = 6;

  /// Minor lines (flow, endurance, openings) per game.
  static const int minorBudget = 3;

  static const List<int> enduranceLines = [50, 100, 200];

  /// Stack height (visible rows) that counts as the board nearly lost, and
  /// the height to get back down to for a comeback.
  static const int dangerHeight = 15;
  static const int safeHeight = 8;

  Motivation? current;
  double age = 0;

  VoiceContext _context = VoiceContext.quiet;
  int _nextId = 1;
  int _lastScore = 0;
  double _played = 0;
  double _sinceShown = 99;
  double _sinceFlow = 99;
  int _minorShown = 0;
  final Set<Voice> _said = {};
  bool _openingDone = true;
  bool _inDanger = false;

  /// What this game did, for the history.
  int quads = 0;
  int maxCombo = 0;
  int peak = 0;
  int comebacks = 0;

  void reset({VoiceContext context = VoiceContext.quiet}) {
    _context = context;
    current = null;
    age = 0;
    _lastScore = 0;
    _played = 0;
    _sinceShown = 99;
    _sinceFlow = 99;
    _minorShown = 0;
    _said.clear();
    _openingDone = context.opening == null;
    _inDanger = false;
    quads = 0;
    maxCombo = 0;
    peak = 0;
    comebacks = 0;
  }

  bool get visible => current != null && age < current!.duration;

  void update(double dt, TetrisGame game) {
    age += dt;
    _played += dt;
    _sinceShown += dt;
    _sinceFlow += dt;
    if (current != null && age >= current!.duration) current = null;

    if (!_openingDone && _played >= openingDelay) {
      _openingDone = true;
      final o = _context.opening!;
      _offer(o.voice, 2, values: o.values);
    }

    final score = game.score;
    if (score == _lastScore) return;
    final before = _lastScore;
    _lastScore = score;
    final c = _context;
    if (!c.scores) return;

    final best = c.best;
    if (best > 0) {
      if (before <= best && score > best) {
        _once(Voice.newBest, 6, loud: true);
      } else if (_said.contains(Voice.newBest) && score >= best * 1.25 && best >= 1000) {
        _once(Voice.pastBest, 5, loud: true);
      } else if (best >= 1000 && score < best && score >= best * 0.85) {
        _once(Voice.nearBest, 4, values: {'gap': best - score});
      }
    }
    final avg = c.average;
    if (avg != null && avg >= 500 && before <= avg && score > avg && (best == 0 || score < best * 0.85)) {
      _once(Voice.aboveAverage, 3, values: {'avg': avg});
    }
    final today = c.todayBest;
    if (today != null && today > 0 && today < best && before <= today && score > today) {
      _once(Voice.todayBest, 3);
    }
  }

  void onEvent(GameEvent event, TetrisGame game) {
    switch (event) {
      case PieceLocked():
        final h = _height(game, const []);
        peak = max(peak, h);
        if (h >= dangerHeight) _inDanger = true;
      case LinesCleared(:final count, :final combo, :final backToBack, :final rows):
        maxCombo = max(maxCombo, combo);
        if (count >= 4) {
          quads++;
          if (quads == 1) _once(_context.novice ? Voice.firstQuadNew : Voice.firstQuad, 3);
          if (_context.maxQuads >= 2 && quads > _context.maxQuads) {
            _once(Voice.quadRecord, 5, values: {'count': quads, 'prev': _context.maxQuads}, loud: true);
          }
        }
        // The cleared rows are still on the board: the stack after the
        // clear is what is left above them.
        final after = max(0, _height(game, rows) - count);
        if (_inDanger && after <= safeHeight) {
          _inDanger = false;
          comebacks++;
          _offer(Voice.comeback, 4);
        }
        final linesBefore = game.lines - count;
        for (final m in enduranceLines) {
          if (linesBefore < m && game.lines >= m) _offer(Voice.endurance, 2, values: {'lines': m});
        }
        if ((combo >= 3 || backToBack) && _sinceFlow > 25 && _random.nextDouble() < 0.5) {
          if (_offer(Voice.flow, 1)) _sinceFlow = 0;
        }
      case LevelUp(:final level):
        final ceiling = _context.levelCeiling;
        if (ceiling != null && level > ceiling && level >= 3) _once(Voice.levelRecord, 4, values: {'level': level});
        if (game.mode.speedsUp && level == speedCapLevel) _once(Voice.maxSpeed, 3);
      default:
        break;
    }
  }

  /// Height of the stack in visible rows, leaving out [skip] rows.
  int _height(TetrisGame game, List<int> skip) {
    for (var y = TetrisGame.hiddenRows; y < TetrisGame.height; y++) {
      if (skip.contains(y)) continue;
      if (game.board[y].any((c) => c != null)) return TetrisGame.height - y;
    }
    return 0;
  }

  /// Offers [voice] at most once per game.
  void _once(Voice voice, int priority, {Map<String, num> values = const {}, bool loud = false}) {
    if (_said.contains(voice)) return;
    if (_offer(voice, priority, values: values, loud: loud)) _said.add(voice);
  }

  bool _offer(Voice voice, int priority, {Map<String, num> values = const {}, bool loud = false}) {
    final showing = visible ? current : null;
    if (showing != null && priority <= showing.priority) return false;
    final minor = priority <= 2;
    if (showing == null && minor && _sinceShown < cooldown) return false;
    if (minor && _minorShown >= minorBudget) return false;
    final line = pickLine(voice, memory, _random, values);
    // Long enough to read: about 25 characters a second, 2.6–5.2 s.
    final length = line.text(AppStrings.tr).length;
    current = Motivation(line, _nextId++, priority: priority, loud: loud, duration: (1.4 + length / 25).clamp(2.6, 5.2));
    age = 0;
    _sinceShown = 0;
    if (minor) _minorShown++;
    return true;
  }
}
