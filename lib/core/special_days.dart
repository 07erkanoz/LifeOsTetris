import 'rewards.dart' show WeeklyEvent;

/// What Lokum carries on a special day.
enum LokumProp {
  /// A Turkish flag on a pole, in his left hand.
  flag,

  /// A kite on its string.
  kite,

  /// The 19 Mayıs youth torch.
  torch,

  /// A laurel wreath, for victory.
  laurel,

  /// A black mourning ribbon on his chest.
  ribbon,

  /// A bottle of lemon cologne, offered when a level is won.
  cologne,

  /// A little decorated pine beside him, for the new year.
  pine,

  /// A white dove on his raised hand, for 1 Mayıs.
  dove,
}

/// The national days, the bayrams and 10 Kasım: the days Lokum greets
/// Turkish players (or, on 10 Kasım and 15 Temmuz, remembers with them)
/// instead of making a suggestion.
enum SpecialDay {
  yilbasi([LokumProp.pine]),
  cocuk([LokumProp.kite]),
  emek([LokumProp.dove]),
  genclik([LokumProp.torch]),
  demokrasi([LokumProp.flag]),
  zafer([LokumProp.laurel, LokumProp.flag]),
  cumhuriyet([LokumProp.flag]),
  ramazan([]),
  kurban([]),
  hidirellez([]),
  ataturk([LokumProp.ribbon]);

  const SpecialDay(this.props);

  final List<LokumProp> props;

  /// A day of remembrance rather than of celebration.
  bool get solemn => this == ataturk || this == demokrasi;

  /// Kurban Bayramı's first day, by the Diyanet calendar; each year's is
  /// added once Diyanet publishes it.
  static final List<DateTime> kurbanStarts = [DateTime.utc(2027, 5, 16)];

  static bool _within(DateTime day, DateTime start, int days) => !day.isBefore(start) && day.isBefore(start.add(Duration(days: days)));

  /// The special day [now] (local time) falls on, if any. A national day
  /// comes before a bayram it shares the day with.
  static SpecialDay? of(DateTime now) {
    final day = DateTime.utc(now.year, now.month, now.day);
    switch ((now.month, now.day)) {
      case (11, 10):
        return ataturk;
      case (1, 1):
        return yilbasi;
      case (4, 23):
        return cocuk;
      case (5, 1):
        return emek;
      case (5, 19):
        return genclik;
      case (7, 15):
        return demokrasi;
      case (8, 30):
        return zafer;
      case (10, 29):
        return cumhuriyet;
      // The holiday begins at one in the afternoon on the 28th.
      case (10, 28) when now.hour >= 13:
        return cumhuriyet;
    }
    if (WeeklyEvent.bayramStarts.any((d) => _within(day, d, 3))) return ramazan;
    if (kurbanStarts.any((d) => _within(day, d, 4))) return kurban;
    if (now.month == 5 && (now.day == 5 || now.day == 6)) return hidirellez;
    return null;
  }
}
