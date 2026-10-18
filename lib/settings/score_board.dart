import 'dart:convert';

/// A score on a list of records: the value (points, floors, or hundredths
/// of a second for a timed run) and the day it was made (null for a best
/// carried over from before the lists).
class ScoreEntry {
  const ScoreEntry(this.value, this.at);

  final int value;
  final DateTime? at;
}

/// The player's own records: the best [keep] of each list, highest first
/// (lowest first for timed runs). Lists are named by key ("game_normal",
/// "tower_climb").
class ScoreBoard {
  ScoreBoard([Map<String, List<ScoreEntry>>? lists]) : _lists = lists ?? {};

  static const int keep = 10;

  final Map<String, List<ScoreEntry>> _lists;

  List<ScoreEntry> of(String key) => List.unmodifiable(_lists[key] ?? const []);

  static bool _better(int a, int b, bool lower) => lower ? a < b : a > b;

  /// The place (1-based) [value] would take on [key]'s list, or 0 when it
  /// would not make the list.
  int placeFor(String key, int value, {bool lower = false}) {
    final list = _lists[key] ?? const [];
    var place = 1;
    for (final e in list) {
      if (!_better(value, e.value, lower)) place++;
    }
    return place <= keep ? place : 0;
  }

  /// Adds [value] made [at] to [key]'s list; [seed], a best from before the
  /// lists, goes on first when the list is still empty. Returns its place
  /// (0 when it did not make the list).
  int add(String key, int value, DateTime at, {bool lower = false, int? seed}) {
    final list = _lists.putIfAbsent(key, () => []);
    if (list.isEmpty && seed != null && seed > 0) list.add(ScoreEntry(seed, null));
    final place = placeFor(key, value, lower: lower);
    if (place == 0) return 0;
    list.insert(place - 1, ScoreEntry(value, at));
    if (list.length > keep) list.removeRange(keep, list.length);
    return place;
  }

  String encode() => jsonEncode({
    for (final e in _lists.entries) e.key: [for (final s in e.value) [s.value, s.at?.millisecondsSinceEpoch]],
  });

  static ScoreBoard decode(String? raw) {
    if (raw == null || raw.isEmpty) return ScoreBoard();
    try {
      final data = jsonDecode(raw) as Map<String, Object?>;
      return ScoreBoard({
        for (final e in data.entries)
          e.key: [
            for (final s in e.value as List)
              ScoreEntry((s as List)[0] as int, s[1] == null ? null : DateTime.fromMillisecondsSinceEpoch(s[1] as int)),
          ],
      });
    } catch (_) {
      return ScoreBoard();
    }
  }
}
