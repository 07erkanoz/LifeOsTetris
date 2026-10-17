import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/rewards.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/settings/settings.dart';

Settings at(DateTime now) => Settings.memory()..clock = () => now;

void main() {
  test('daily gift: once a day, on through the week, a missed day is not lost', () {
    var now = DateTime(2026, 10, 19, 9);
    final s = Settings.memory()..clock = () => now;
    final hammers = s.sugarBoosters(SugarBooster.hammer);
    expect(s.dailyGiftReady, isTrue);
    expect(s.claimDailyGift(), isNotNull);
    expect(s.sugarBoosters(SugarBooster.hammer), hammers + 2);
    expect(s.dailyGiftReady, isFalse);
    expect(s.claimDailyGift(), isNull, reason: 'one a day');
    // Three days later the calendar goes on at day two, not back to one.
    now = DateTime(2026, 10, 22, 20);
    expect(s.giftDay, 1);
    final moves = s.sugarBoosters(SugarBooster.moves);
    s.claimDailyGift();
    expect(s.sugarBoosters(SugarBooster.moves), moves + 2);
    // Through to the seventh day: the first week's big chest opens the
    // lokum cubes; then the calendar starts again.
    for (var d = 2; d < Rewards.dailyDays; d++) {
      now = now.add(const Duration(days: 1));
      s.claimDailyGift();
    }
    expect(s.unlocked(Unlock.cubesLokum), isTrue);
    expect(s.giftDay, 0);
    expect(s.postcards, 1);
    expect(Rewards.daily(6).unlock, isNull, reason: 'only the first week opens it');
  });

  test('the sugar jar fills with every sweet and grows a little each time', () {
    final s = at(DateTime(2026, 10, 19));
    s.addSugarCandies({SugarColor.green: 100});
    expect(s.jarFull, isFalse);
    expect(s.openJar(), isNull);
    s.addSugarCandies({SugarColor.blue: 60});
    expect(s.jarFull, isTrue);
    final gift = s.openJar()!;
    expect(gift.unlock, Unlock.shuffle);
    expect(s.unlocked(Unlock.shuffle), isTrue);
    expect(s.sugarBoosters(SugarBooster.shuffle), 2);
    expect(s.jarCount, 10, reason: 'the extra sweets stay in');
    expect(s.jarCapacity, 175);
    expect(Rewards.jarCapacity(99), 300);
  });

  test('a star chest for every five stars; the third opens the tile cubes', () {
    final s = at(DateTime(2026, 10, 19));
    for (var n = 1; n <= 5; n++) {
      s.recordSugarLevel(n, stars: 3, score: 5000, seconds: 30);
    }
    expect(s.totalSugarStars, 15);
    expect(s.starChestsReady, 3);
    expect(Rewards.tier(3), ChestTier.silver);
    expect(Rewards.tier(6), ChestTier.gold);
    s.openStarChest();
    s.openStarChest();
    expect(s.unlocked(Unlock.cubesCini), isFalse);
    s.openStarChest();
    expect(s.unlocked(Unlock.cubesCini), isTrue);
    expect(s.starChestsReady, 0);
    expect(s.openStarChest(), isNull);
    expect(s.postcards, 3, reason: 'every chest has a postcard');
    expect(Rewards.chest(6).unlock, Unlock.freeze);
    expect(Rewards.chest(6).freezes, 3);
  });

  test('the weekly event: its colour counts, prizes in steps, a new week starts afresh', () {
    var now = DateTime(2026, 10, 19, 12); // a Monday
    final s = Settings.memory()..clock = () => now;
    final e = s.event;
    expect(WeeklyEvent.daysLeft(now), 7);
    expect(WeeklyEvent.daysLeft(DateTime(2026, 10, 25, 23)), 1);
    expect(WeeklyEvent.of(DateTime(2026, 10, 25)), e, reason: 'the same week');
    expect(WeeklyEvent.of(DateTime(2026, 10, 26)), isNot(e));
    final other = SugarColor.values.firstWhere((c) => c != e.color);
    s.addSugarCandies({e.color: 60, other: 500});
    expect(s.eventCount, 60);
    expect(s.eventPrizesReady, 1);
    final gift = s.claimEventPrize()!;
    expect(gift.boosters[SugarBooster.hammer], 2);
    expect(s.eventPrizesReady, 0);
    s.addSugarCandies({e.color: 440});
    expect(s.eventPrizesReady, 3);
    s.claimEventPrize();
    s.claimEventPrize();
    s.claimEventPrize();
    expect(s.unlocked(e.outfit), isTrue, reason: 'the last prize is the outfit');
    // Next week: a new event, from zero.
    now = DateTime(2026, 10, 26, 8);
    expect(s.eventCount, 0);
    expect(s.eventClaimed, 0);
  });

  test('postcards: chapter ends, the event and chests each give their own cards', () {
    final s = at(DateTime(2026, 10, 19));
    // Chapter cards are the city's places, all different.
    expect(Rewards.chapterCards.toSet().length, Rewards.chapterCards.length);
    final eventCards = [for (final e in WeeklyEvent.values) e.card];
    expect({...Rewards.chapterCards, ...eventCards, ...Rewards.chestCards}.length, Rewards.postcards, reason: 'each card has one way in');
    // The event's third prize is its card.
    expect(s.event.prize(2).card, s.event.card);
    // A card is had once.
    s.applyGift(const Gift(card: 4));
    s.applyGift(const Gift(card: 4));
    expect(s.postcards, 1);
    expect(s.lastCard, isNull, reason: 'nothing new the second time');
    // Chests take their pool in turn, then give boosters only.
    for (var i = 0; i < Rewards.chestCards.length + 2; i++) {
      s.applyGift(const Gift(postcard: true));
    }
    expect(Rewards.chestCards.every(s.hasCard), isTrue);
    expect(s.postcards, Rewards.chestCards.length + 1);
  });

  test("Lokum's surprise is one booster, and the badge counts what waits", () {
    for (var seed = 0; seed < 20; seed++) {
      final g = Rewards.surprise(seed);
      expect(g.boosters.values.fold(0, (a, b) => a + b), 1);
    }
    final s = at(DateTime(2026, 10, 19));
    expect(s.giftsReady, 1, reason: "today's gift");
    s.recordSugarLevel(1, stars: 3, score: 5000, seconds: 30);
    s.recordSugarLevel(2, stars: 3, score: 5000, seconds: 30);
    expect(s.giftsReady, 2, reason: 'and a star chest');
  });
}
