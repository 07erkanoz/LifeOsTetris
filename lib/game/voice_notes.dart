import 'dart:math';

import '../core/tetris_game.dart';
import '../l10n/voice_lines.dart';
import 'motivation.dart';
import 'play_history.dart';

/// The line under the result of a finished game. [history] already holds
/// [game]; the `…Before` values are from before it.
VoiceLine pickEndNote({
  required GameRecord game,
  required PlayHistory history,
  required int bestBefore,
  required double? bestTimeBefore,
  required int? averageBefore,
  required int? todayBestBefore,
  required LineMemory memory,
  required Random random,
}) {
  VoiceLine say(Voice v, [Map<String, num> values = const {}]) => pickLine(v, memory, random, values);

  if (game.mode.recordsTime) {
    if (!game.won) return say(Voice.endTimedFail);
    if (bestTimeBefore == null) return say(Voice.endTimedFirst, {'time': game.seconds});
    if (game.record) return say(Voice.endTimedRecord, {'time': game.seconds});
    return say(Voice.endTimedSlower, {'secs': max(0.1, game.seconds - bestTimeBefore)});
  }

  if (game.record) return say(Voice.endNewBest, {'score': game.score, if (bestBefore > 0) 'prev': bestBefore});
  if (bestBefore > 0 && game.score >= bestBefore * 0.85) return say(Voice.endNearMiss, {'gap': bestBefore - game.score});
  if (game.comebacks > 0) return say(Voice.endComeback);
  if (averageBefore != null && averageBefore > 0 && game.score > averageBefore * 1.1) {
    return say(Voice.endAboveAverage, {'avg': averageBefore});
  }
  if (todayBestBefore != null && game.score > todayBestBefore) return say(Voice.endBestToday);
  if (game.seconds < 45) return say(Voice.endQuick);
  final wall = history.wall(game.mode);
  if (wall != null && (game.level - wall).abs() <= 1) return say(Voice.endWall, {'level': wall});
  final growth = history.growthPercent(game.mode);
  if (growth != null) return say(Voice.endGrowth, {'pct': growth});
  return say(Voice.endLoss);
}

/// A line for the main menu, or null when the plain tagline is better.
/// Picks the most meaningful thing most of the time, and something else
/// now and then so the menu does not say the same thing every day.
VoiceLine? pickHomeNote({
  required PlayHistory history,
  required int Function(GameMode) bestOf,
  required DateTime now,
  required LineMemory memory,
  required Random random,
}) {
  // A first-time player gets the tagline, which says what the game is.
  if (history.games.isEmpty && history.days.isEmpty) return null;
  final candidates = <(Voice, Map<String, num>)>[];
  final away = history.daysAway(now) ?? 0;
  if (away >= 3) candidates.add((Voice.homeBack, const {}));

  final last = history.games.isEmpty ? null : history.games.last;
  final recent = last != null && now.difference(last.ended).inHours < 48;
  if (last != null && recent && !last.mode.recordsTime) {
    final best = bestOf(last.mode);
    if (last.record) {
      candidates.add((Voice.homeRecordFresh, {'score': best}));
    } else if (best > 0 && last.score >= best * 0.85 && last.score < best) {
      candidates.add((Voice.homeNearMiss, {'gap': best - last.score}));
    }
  }

  final today = history.playedOn(now);
  final streak = history.streak(now);
  if (streak >= 2 && today) candidates.add((Voice.homeStreak, {'days': streak}));
  if (!today) {
    final yesterday = PlayHistory.dayKey(now.subtract(const Duration(days: 1)));
    final scores = [
      for (final g in history.games)
        if (!g.mode.recordsTime && PlayHistory.dayKey(g.ended) == yesterday) g.score,
    ];
    if (scores.isNotEmpty && scores.reduce(max) > 0) candidates.add((Voice.homeNotToday, {'score': scores.reduce(max)}));
  }
  if (last != null) {
    final growth = history.growthPercent(last.mode);
    if (growth != null) candidates.add((Voice.homeGrowth, {'pct': growth}));
  }
  final week = history.gamesThisWeek(now);
  if (week >= 5) candidates.add((Voice.homeWeek, {'count': week}));
  if (now.hour < 5) candidates.add((Voice.homeNight, const {}));
  if (now.hour >= 6 && now.hour < 10) candidates.add((Voice.homeMorning, const {}));
  if (candidates.isEmpty) return null;

  final (voice, values) = candidates.length == 1 || random.nextDouble() < 0.6
      ? candidates.first
      : candidates[1 + random.nextInt(candidates.length - 1)];
  return pickLine(voice, memory, random, values);
}
