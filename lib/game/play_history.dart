import 'dart:convert';
import 'dart:math';

import '../core/tetris_game.dart';

/// One finished Küpler game, as much as the in-game voice needs to compare
/// the player with themselves later.
class GameRecord {
  const GameRecord({
    required this.mode,
    required this.score,
    required this.level,
    required this.lines,
    required this.seconds,
    required this.ended,
    this.quads = 0,
    this.maxCombo = 0,
    this.peak = 0,
    this.comebacks = 0,
    this.won = false,
    this.record = false,
  });

  final GameMode mode;
  final int score;
  final int level;
  final int lines;
  final double seconds;
  final DateTime ended;
  final int quads;
  final int maxCombo;

  /// Highest the stack got, in visible rows.
  final int peak;

  /// Times the stack came back down from near the top.
  final int comebacks;
  final bool won;

  /// It set a new best for its mode.
  final bool record;

  Map<String, Object?> toJson() => {
    'm': mode.name,
    's': score,
    'l': level,
    'n': lines,
    't': seconds,
    'e': ended.toIso8601String(),
    'q': quads,
    'c': maxCombo,
    'p': peak,
    'b': comebacks,
    if (won) 'w': true,
    if (record) 'r': true,
  };

  static GameRecord? fromJson(Object? json) {
    try {
      final m = json! as Map;
      return GameRecord(
        mode: GameMode.values.byName(m['m'] as String),
        score: m['s'] as int,
        level: m['l'] as int,
        lines: m['n'] as int,
        seconds: (m['t'] as num).toDouble(),
        ended: DateTime.parse(m['e'] as String),
        quads: m['q'] as int? ?? 0,
        maxCombo: m['c'] as int? ?? 0,
        peak: m['p'] as int? ?? 0,
        comebacks: m['b'] as int? ?? 0,
        won: m['w'] == true,
        record: m['r'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The player's recent games and the days they played, kept on the device.
/// Nothing here leaves the phone; it only lets the game talk about the
/// player's own progress.
class PlayHistory {
  PlayHistory([List<GameRecord>? games, Set<String>? days]) : games = games ?? [], days = days ?? {};

  /// Oldest first, at most [keepGames].
  final List<GameRecord> games;

  /// Calendar days (see [dayKey]) with at least one finished game of any
  /// kind, at most [keepDays].
  final Set<String> days;

  static const int keepGames = 40;
  static const int keepDays = 60;

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  void add(GameRecord record) {
    games.add(record);
    if (games.length > keepGames) games.removeRange(0, games.length - keepGames);
    markPlayed(record.ended);
  }

  void markPlayed(DateTime when) {
    days.add(dayKey(when));
    if (days.length > keepDays) {
      final sorted = days.toList()..sort();
      days.removeAll(sorted.take(days.length - keepDays));
    }
  }

  List<GameRecord> ofMode(GameMode mode) => [
    for (final g in games)
      if (g.mode == mode) g,
  ];

  /// Average score of the last [count] games of [mode]; null with fewer
  /// than [minGames].
  int? averageScore(GameMode mode, {int count = 10, int minGames = 3}) {
    final list = ofMode(mode);
    if (list.length < minGames) return null;
    final recent = list.sublist(max(0, list.length - count));
    return (recent.fold(0, (a, g) => a + g.score) / recent.length).round();
  }

  /// Best score of [mode] on the day of [now], if any game ended that day.
  int? todayBest(GameMode mode, DateTime now) {
    final today = dayKey(now);
    final scores = [
      for (final g in ofMode(mode))
        if (dayKey(g.ended) == today) g.score,
    ];
    return scores.isEmpty ? null : scores.reduce(max);
  }

  /// Most quads ever made in one game of [mode] (as far as remembered).
  int maxQuads(GameMode mode) => ofMode(mode).fold(0, (a, g) => max(a, g.quads));

  /// Highest level reached in the last [count] games of [mode]; null with
  /// fewer than [minGames].
  int? levelCeiling(GameMode mode, {int count = 10, int minGames = 3}) {
    final list = ofMode(mode);
    if (list.length < minGames) return null;
    return list.sublist(max(0, list.length - count)).fold<int>(0, (a, g) => max(a, g.level));
  }

  /// A level most of the last five games of [mode] ended on (give or take
  /// one): the player's current wall. Null when there is none.
  int? wall(GameMode mode) {
    final list = ofMode(mode);
    if (list.length < 4) return null;
    final recent = list.sublist(max(0, list.length - 5));
    for (final g in recent.reversed) {
      final near = recent.where((o) => (o.level - g.level).abs() <= 1).length;
      if (near >= 3 && g.level >= 2) return g.level;
    }
    return null;
  }

  /// How much the average of the last five games of [mode] beats the five
  /// before, in percent; null without ten games or without a real gain.
  int? growthPercent(GameMode mode) {
    final list = ofMode(mode);
    if (list.length < 10) return null;
    double avg(Iterable<GameRecord> l) => l.fold(0, (a, g) => a + g.score) / l.length;
    final last = avg(list.sublist(list.length - 5));
    final before = avg(list.sublist(list.length - 10, list.length - 5));
    if (before <= 0) return null;
    final pct = ((last / before - 1) * 100).round();
    return pct >= 10 ? pct : null;
  }

  /// Days in a row with a game, counting back from [now] (or from
  /// yesterday when nothing was played today yet).
  int streak(DateTime now) {
    var day = _day(now);
    if (!days.contains(dayKey(day))) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(dayKey(day))) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  bool playedOn(DateTime day) => days.contains(dayKey(day));

  /// Whole days since the last day with a game; null before any.
  int? daysAway(DateTime now) {
    if (days.isEmpty) return null;
    final last = DateTime.parse((days.toList()..sort()).last);
    return _day(now).difference(last).inDays;
  }

  /// Games of any Küpler mode that ended in the seven days up to [now].
  int gamesThisWeek(DateTime now) {
    final from = _day(now).subtract(const Duration(days: 6));
    return games.where((g) => !g.ended.isBefore(from)).length;
  }

  String encode() => jsonEncode({
    'g': [for (final g in games) g.toJson()],
    'd': days.toList()..sort(),
  });

  static PlayHistory decode(String? raw) {
    if (raw == null) return PlayHistory();
    try {
      final data = jsonDecode(raw) as Map;
      return PlayHistory(
        [for (final g in (data['g'] as List? ?? const [])) ?GameRecord.fromJson(g)],
        {for (final d in (data['d'] as List? ?? const [])) d as String},
      );
    } catch (_) {
      return PlayHistory();
    }
  }
}

/// Remembers which lines were said lately (across games and app starts),
/// so the voice does not repeat itself.
class LineMemory {
  LineMemory([List<String>? recent]) : recent = recent ?? [];

  final List<String> recent;
  static const int keep = 80;

  /// Picks one of the [allowed] variants of [key], avoiding the recently
  /// used ones while there is a fresh one left.
  int pick(String key, List<int> allowed, Random random) {
    final fresh = [
      for (final i in allowed)
        if (!recent.contains('$key:$i')) i,
    ];
    if (fresh.isEmpty) recent.removeWhere((r) => r.startsWith('$key:'));
    final options = fresh.isEmpty ? allowed : fresh;
    final i = options[random.nextInt(options.length)];
    recent.add('$key:$i');
    if (recent.length > keep) recent.removeRange(0, recent.length - keep);
    return i;
  }
}
