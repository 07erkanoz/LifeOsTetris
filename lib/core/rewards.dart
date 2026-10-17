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
  outfitGuide;

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
  static const int postcards = 15;
  static const int setSize = 5;
  static int get sets => postcards ~/ setSize;

  /// The card a chapter (0-based) gives when its last level is passed:
  /// Mısır Çarşısı, the frozen Bosphorus, Rumeli Hisarı, the Bedesten,
  /// Galata Tower, Kınalıada.
  static const List<int> chapterCards = [11, 10, 4, 6, 3, 2];

  /// The cards chests, the jar and the seventh day give, in turn.
  static const List<int> chestCards = [0, 1, 5, 8, 13];

  /// The card of chapter [chapter], if it has one.
  static int? chapterCard(int chapter) => chapter < chapterCards.length ? chapterCards[chapter] : null;

  /// What completing set [i] gives; the last set to be completed also
  /// opens the guide's hat.
  static Gift setPrize(int i, {bool all = false}) => switch (i) {
    0 => Gift(boosters: const {SugarBooster.hammer: 3, SugarBooster.rainbow: 2, SugarBooster.moves: 2}, unlock: all ? Unlock.outfitGuide : null),
    1 => Gift(boosters: const {SugarBooster.rainbow: 3, SugarBooster.moves: 3, SugarBooster.shuffle: 2}, unlock: all ? Unlock.outfitGuide : null),
    _ => Gift(boosters: const {SugarBooster.hammer: 4, SugarBooster.rainbow: 3}, freezes: 2, unlock: all ? Unlock.outfitGuide : null),
  };
}

/// The weekly İstanbul events: a sweet to collect in any Şeker level, four
/// prizes, and an outfit at the end. One a week, Monday to Sunday.
enum WeeklyEvent {
  tulip(SugarColor.red, Unlock.outfitTulipCrown, 12),
  ferry(SugarColor.blue, Unlock.outfitCaptain, 14),
  coffee(SugarColor.orange, Unlock.outfitApron, 7),
  simit(SugarColor.yellow, Unlock.outfitSimitNecklace, 9);

  const WeeklyEvent(this.color, this.outfit, this.card);

  /// The postcard of the third prize.
  final int card;

  /// The sweet to pop.
  final SugarColor color;

  /// The outfit of the last prize.
  final Unlock outfit;

  /// Sweets needed for each prize.
  static const List<int> tiers = [50, 150, 300, 500];

  /// Days since Monday 5 January 1970.
  static int _days(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1970, 1, 5)).inDays;

  /// The week number of [d] (weeks start on Monday).
  static int weekOf(DateTime d) => _days(d) ~/ 7;

  static WeeklyEvent of(DateTime d) => values[weekOf(d) % values.length];

  /// Days left this week, today included.
  static int daysLeft(DateTime d) => 7 - _days(d) % 7;

  /// Prize [i] (0-based).
  Gift prize(int i) => switch (i) {
    0 => const Gift(boosters: {SugarBooster.hammer: 2}),
    1 => const Gift(boosters: {SugarBooster.rainbow: 1, SugarBooster.moves: 2}),
    2 => Gift(boosters: const {SugarBooster.hammer: 3, SugarBooster.rainbow: 2, SugarBooster.moves: 1}, card: card),
    _ => Gift(boosters: const {SugarBooster.hammer: 2, SugarBooster.rainbow: 2}, unlock: outfit),
  };
}
