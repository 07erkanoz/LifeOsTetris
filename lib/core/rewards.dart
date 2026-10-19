import 'dart:math';

import 'sugar/sugar_game.dart' show SugarColor;
import 'sugar/sugar_levels.dart' show SugarBooster;

/// Things gifts unlock, kept by name.
enum Unlock {
  /// Zincir Küpler's lokum cubes.
  cubesLokum,

  /// Zincir Küpler's İznik tile cubes.
  cubesCini,

  /// İstanbul scenes behind the Şeker board.
  sceneGalata,
  sceneSnow,
  sceneIslands,

  /// Çamlıca by night, for beating Ekşi Limon.
  sceneCamlica,

  /// The Şeker shuffle booster.
  shuffle,

  /// Zincir Küpler's stop-the-clock booster.
  freeze,

  /// Weekly event outfits for Lokum.
  outfitTulipCrown,
  outfitCaptain,
  outfitApron,
  outfitSimitNecklace,

  /// The guide's hat, for a full postcard album.
  outfitGuide,

  /// The golden lemon crown, for beating Ekşi Limon at his best.
  outfitLemonCrown,

  /// Kule Küpler floor looks, from the tower's milestone chests.
  floorCini,
  floorMarble,
  floorGlass,
  floorGold,

  /// Outfits from the newer weekly events: the mehter band, the Black Sea,
  /// the hamam and the Maraş ice-cream seller.
  outfitMehter,
  outfitKaradeniz,
  outfitHamam,
  outfitDondurma,

  /// The days of the calendar: a halay handkerchief for Şeker Bayramı, an
  /// oyalı yazma for Hıdırellez.
  outfitHalay,
  outfitYazma;

  static Unlock? parse(String name) {
    for (final u in values) {
      if (u.name == name) return u;
    }
    return null;
  }
}

/// What a gift holds: boosters, Zincir freezes, maybe something new and a
/// postcard for the album: [card] when it is a given one, else (with
/// [postcard]) the next card the chests hold.
class Gift {
  const Gift({this.boosters = const {}, this.freezes = 0, this.unlock, this.postcard = false, this.card});

  final Map<SugarBooster, int> boosters;
  final int freezes;
  final Unlock? unlock;
  final bool postcard;
  final int? card;
}

enum ChestTier { bronze, silver, gold }

/// The rules of the gifts: how much, how often, what each one opens.
abstract final class Rewards {
  // ---------------------------------------------------------- daily gift --

  static const int dailyDays = 7;

  /// The gift of day [day] (0-based) of the week's calendar. The first
  /// week's seventh day also opens the lokum cubes.
  static Gift daily(int day, {bool firstWeek = false}) => switch (day % dailyDays) {
    0 => const Gift(boosters: {SugarBooster.hammer: 2}),
    1 => const Gift(boosters: {SugarBooster.moves: 2}),
    2 => const Gift(boosters: {SugarBooster.hammer: 3, SugarBooster.rainbow: 1}),
    3 => const Gift(boosters: {SugarBooster.rainbow: 2}),
    4 => const Gift(boosters: {SugarBooster.moves: 3, SugarBooster.hammer: 2}),
    5 => const Gift(boosters: {SugarBooster.hammer: 3, SugarBooster.rainbow: 2}),
    _ => Gift(boosters: const {SugarBooster.hammer: 4, SugarBooster.rainbow: 3, SugarBooster.moves: 3}, unlock: firstWeek ? Unlock.cubesLokum : null, postcard: true),
  };

  // ----------------------------------------------------------- sugar jar --

  /// Sweets the jar holds after [fills] fillings: it grows a little each
  /// time.
  static int jarCapacity(int fills) => min(300, 150 + 25 * fills);

  /// What the [fills]th full jar gives (0-based); the first opens the
  /// shuffle booster.
  static Gift jar(int fills) => Gift(
    boosters: {SugarBooster.hammer: 2, SugarBooster.rainbow: 1, SugarBooster.moves: 1, SugarBooster.shuffle: fills == 0 ? 2 : 1},
    unlock: fills == 0 ? Unlock.shuffle : null,
    postcard: true,
  );

  // --------------------------------------------------------- star chests --

  static const int chestEvery = 5;

  /// Chests reached with [stars] Şeker stars.
  static int chestsFor(int stars) => stars ~/ chestEvery;

  /// The tier of chest [n] (1-based): every sixth gold, every third silver.
  static ChestTier tier(int n) => n % 6 == 0
      ? ChestTier.gold
      : n % 3 == 0
      ? ChestTier.silver
      : ChestTier.bronze;

  /// What chests open, by chest number.
  static const Map<int, Unlock> _chestUnlocks = {
    3: Unlock.cubesCini,
    6: Unlock.freeze,
    9: Unlock.sceneGalata,
    12: Unlock.sceneSnow,
    18: Unlock.sceneIslands,
  };

  /// Chest [n] (1-based).
  static Gift chest(int n) {
    final unlock = _chestUnlocks[n];
    return switch (tier(n)) {
      ChestTier.bronze => const Gift(boosters: {SugarBooster.hammer: 1, SugarBooster.moves: 1}, postcard: true),
      ChestTier.silver => Gift(boosters: const {SugarBooster.hammer: 2, SugarBooster.rainbow: 1, SugarBooster.moves: 1}, unlock: unlock, postcard: true),
      ChestTier.gold => Gift(
        boosters: const {SugarBooster.hammer: 3, SugarBooster.rainbow: 2, SugarBooster.moves: 2},
        freezes: unlock == Unlock.freeze ? 3 : 2,
        unlock: unlock,
        postcard: true,
      ),
    };
  }

  // ----------------------------------------------- Lokum's level surprise --

  /// A little pack for every level won: usually a hammer or extra moves,
  /// sometimes a rainbow ball.
  static Gift surprise(int seed) {
    final roll = Random(seed).nextDouble();
    return Gift(
      boosters: {
        roll < 0.5
            ? SugarBooster.hammer
            : roll < 0.8
            ? SugarBooster.moves
            : SugarBooster.rainbow: 1,
      },
    );
  }

  // ----------------------------------------------------------- postcards --

  /// The İstanbul postcards, oldest first, in sets of [setSize].
  static const int postcards = 20;
  static const int setSize = 5;
  static int get sets => postcards ~/ setSize;

  /// The card a chapter (0-based) gives when its last level is passed:
  /// Mısır Çarşısı, the frozen Bosphorus, Rumeli Hisarı, the Bedesten,
  /// Galata Tower, Kınalıada, Chalcedon, the Ortaköy mosque, the Sühulet,
  /// the Tünel, Balat. Çamlıca gives [finale] instead.
  static const List<int> chapterCards = [11, 10, 4, 6, 3, 2, 15, 17, 18, 19, 16];

  /// Beating Ekşi Limon on Çamlıca, the last level.
  static const Gift finale = Gift(
    boosters: {SugarBooster.hammer: 5, SugarBooster.rainbow: 3, SugarBooster.moves: 3, SugarBooster.shuffle: 2},
    freezes: 3,
    unlock: Unlock.sceneCamlica,
  );

  /// The cards chests, the jar and the seventh day give, in turn.
  static const List<int> chestCards = [0, 1, 5, 8, 13];

  /// The card of chapter [chapter], if it has one.
  static int? chapterCard(int chapter) => chapter < chapterCards.length ? chapterCards[chapter] : null;

  // ------------------------------------------------- Zincir: the ferry line

  /// What reaching pier [pier] (all five missions done) gives; the last
  /// pier gives more.
  static Gift pierPrize(int pier, {bool last = false}) => last
      ? const Gift(boosters: {SugarBooster.hammer: 4, SugarBooster.rainbow: 3, SugarBooster.moves: 3}, freezes: 5)
      : Gift(boosters: {pier.isEven ? SugarBooster.hammer : SugarBooster.rainbow: 1}, freezes: 2);

  /// The first match won against each rival: the lokum cubes, the İznik
  /// tiles, the golden lemon crown.
  static Gift rivalPrize(int rival) => switch (rival) {
    0 => const Gift(freezes: 2, unlock: Unlock.cubesLokum),
    1 => const Gift(freezes: 2, unlock: Unlock.cubesCini),
    _ => const Gift(freezes: 3, unlock: Unlock.outfitLemonCrown),
  };

  /// A whole pack of Zincir puzzles solved.
  static Gift puzzlePackPrize(int pack) => Gift(boosters: const {SugarBooster.hammer: 2, SugarBooster.rainbow: 2}, freezes: 1 + pack);

  // ------------------------------------------------------ Kule Küpler --

  /// The floor look the chest at [height] opens the first time it is
  /// reached.
  static const Map<int, Unlock> towerLooks = {100: Unlock.floorCini, 200: Unlock.floorMarble, 300: Unlock.floorGlass, 500: Unlock.floorGold};

  /// The tier of the tower's chest at [height].
  static ChestTier towerTier(int height) => height >= 300
      ? ChestTier.gold
      : height >= 100
      ? ChestTier.silver
      : ChestTier.bronze;

  /// The chest at [height]; [unlock] when its floor look is new.
  static Gift towerChest(int height, {Unlock? unlock}) => switch (towerTier(height)) {
    ChestTier.bronze => Gift(boosters: const {SugarBooster.hammer: 1}, unlock: unlock),
    ChestTier.silver => Gift(boosters: const {SugarBooster.hammer: 1, SugarBooster.moves: 1}, freezes: 1, unlock: unlock),
    ChestTier.gold => Gift(boosters: const {SugarBooster.hammer: 2, SugarBooster.rainbow: 1, SugarBooster.moves: 1}, freezes: 1, unlock: unlock, postcard: unlock == null),
  };

  /// A landmark of İstanbul'u İnşa Et finished.
  static Gift landmarkPrize(int landmark) =>
      Gift(boosters: const {SugarBooster.hammer: 3, SugarBooster.rainbow: 2, SugarBooster.moves: 2}, freezes: 2 + landmark ~/ 2, postcard: true);

  /// What completing set [i] gives; the last set to be completed also
  /// opens the guide's hat.
  static Gift setPrize(int i, {bool all = false}) => switch (i) {
    0 => Gift(boosters: const {SugarBooster.hammer: 3, SugarBooster.rainbow: 2, SugarBooster.moves: 2}, unlock: all ? Unlock.outfitGuide : null),
    1 => Gift(boosters: const {SugarBooster.rainbow: 3, SugarBooster.moves: 3, SugarBooster.shuffle: 2}, unlock: all ? Unlock.outfitGuide : null),
    3 => Gift(boosters: const {SugarBooster.hammer: 3, SugarBooster.rainbow: 3, SugarBooster.moves: 3}, freezes: 2, unlock: all ? Unlock.outfitGuide : null),
    _ => Gift(boosters: const {SugarBooster.hammer: 4, SugarBooster.rainbow: 3}, freezes: 2, unlock: all ? Unlock.outfitGuide : null),
  };
}

/// The İstanbul and Anatolian events: a sweet to collect in any Şeker
/// level, four prizes, and an outfit at the end. One a week, Monday to
/// Sunday; a day of the calendar (Şeker Bayramı, Hıdırellez) takes the
/// week's place while it lasts.
enum WeeklyEvent {
  tulip(SugarColor.red, Unlock.outfitTulipCrown, 12),
  ferry(SugarColor.blue, Unlock.outfitCaptain, 14),
  coffee(SugarColor.orange, Unlock.outfitApron, 7),
  simit(SugarColor.yellow, Unlock.outfitSimitNecklace, 9),
  hamam(SugarColor.blue, Unlock.outfitHamam),

  /// Purple for the orchids whose root, as salep, makes it stretch.
  dondurma(SugarColor.purple, Unlock.outfitDondurma),
  mehter(SugarColor.red, Unlock.outfitMehter),
  karadeniz(SugarColor.green, Unlock.outfitKaradeniz),

  /// The days of the calendar. (The national days are greeted, not
  /// played for: see SpecialDay.)
  bayram(SugarColor.yellow, Unlock.outfitHalay),
  hidirellez(SugarColor.red, Unlock.outfitYazma);

  const WeeklyEvent(this.color, this.outfit, [this.card]);

  /// The postcard of the third prize, for the events that have one.
  final int? card;

  /// The sweet to pop.
  final SugarColor color;

  /// The outfit of the last prize.
  final Unlock outfit;

  /// A day of the calendar rather than a week of the rotation.
  bool get isCalendar => index >= bayram.index;

  /// Sweets needed for each prize: fewer for the short calendar days.
  List<int> get tiers => isCalendar ? const [30, 90, 180, 300] : const [50, 150, 300, 500];

  /// The weeks' order: the first four alone until [_wideFrom], then all
  /// eight. That week is a tulip week in both, so nothing jumps.
  static const List<WeeklyEvent> _first = [tulip, ferry, coffee, simit];
  static const List<WeeklyEvent> _wide = [tulip, ferry, coffee, simit, hamam, dondurma, mehter, karadeniz];

  /// Monday 21 December 2026.
  static const int _wideFrom = 2972;

  /// Şeker Bayramı (Ramazan Bayramı), its three days by the Diyanet
  /// calendar. Each year's dates are added once Diyanet publishes them.
  static final List<DateTime> bayramStarts = [DateTime.utc(2027, 3, 9)];

  /// The calendar's days: (event, first day, how many days).
  static Iterable<(WeeklyEvent, DateTime, int)> _calendar(int year) => [
    for (final d in bayramStarts)
      if (d.year == year) (bayram, d, 3),
    // Hıdırellez: the eve of 6 May and the day itself.
    (hidirellez, DateTime.utc(year, 5, 5), 2),
  ];

  /// The calendar day [d] falls in, if any: (event, its first day, days).
  static (WeeklyEvent, DateTime, int)? _calendarAt(DateTime d) {
    final day = DateTime.utc(d.year, d.month, d.day);
    for (final c in _calendar(d.year)) {
      final (_, start, days) = c;
      if (!day.isBefore(start) && day.isBefore(start.add(Duration(days: days)))) return c;
    }
    return null;
  }

  /// Days since Monday 5 January 1970.
  static int _days(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1970, 1, 5)).inDays;

  /// The week number of [d] (weeks start on Monday).
  static int weekOf(DateTime d) => _days(d) ~/ 7;

  /// The stretch of time an event's sweets are counted for: the week, or
  /// for a day of the calendar a number of its own, past any week's.
  static int periodOf(DateTime d) {
    final c = _calendarAt(d);
    return c == null ? weekOf(d) : 1000000 + _days(c.$2);
  }

  static WeeklyEvent of(DateTime d) {
    final c = _calendarAt(d);
    if (c != null) return c.$1;
    final week = weekOf(d);
    return week < _wideFrom ? _first[week % _first.length] : _wide[(week - _wideFrom) % _wide.length];
  }

  /// Days left of the event, today included.
  static int daysLeft(DateTime d) {
    final c = _calendarAt(d);
    if (c == null) return 7 - _days(d) % 7;
    final (_, start, days) = c;
    return days - DateTime.utc(d.year, d.month, d.day).difference(start).inDays;
  }

  static WeeklyEvent? parse(String? name) {
    for (final e in values) {
      if (e.name == name) return e;
    }
    return null;
  }

  /// Prize [i] (0-based).
  Gift prize(int i) => switch (i) {
    0 => const Gift(boosters: {SugarBooster.hammer: 2}),
    1 => const Gift(boosters: {SugarBooster.rainbow: 1, SugarBooster.moves: 2}),
    2 => Gift(boosters: const {SugarBooster.hammer: 3, SugarBooster.rainbow: 2, SugarBooster.moves: 1}, card: card),
    _ => Gift(boosters: const {SugarBooster.hammer: 2, SugarBooster.rainbow: 2}, unlock: outfit),
  };
}
