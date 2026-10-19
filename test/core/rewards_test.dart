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

  test('the rotation keeps the four old weeks until 21 December 2026, then all eight', () {
    // Before: tulip, ferry, coffee, simit, as always.
    expect(WeeklyEvent.of(DateTime(2026, 10, 19)), WeeklyEvent.simit);
    expect(WeeklyEvent.of(DateTime(2026, 10, 26)), WeeklyEvent.tulip);
    expect(WeeklyEvent.of(DateTime(2026, 12, 14)), WeeklyEvent.simit);
    // From the 21st the eight, starting on a tulip week like the four did.
    final weeks = [for (var w = 0; w < 8; w++) WeeklyEvent.of(DateTime(2026, 12, 21).add(Duration(days: 7 * w)))];
    expect(weeks, [WeeklyEvent.tulip, WeeklyEvent.ferry, WeeklyEvent.coffee, WeeklyEvent.simit, WeeklyEvent.hamam, WeeklyEvent.dondurma, WeeklyEvent.mehter, WeeklyEvent.karadeniz]);
    expect(weeks.where((e) => e.isCalendar), isEmpty);
  });

  test('Şeker Bayramı and Hıdırellez take the week\'s place, then give it back with its count', () {
    var now = DateTime(2027, 3, 8, 12); // Monday, the eve
    final s = Settings.memory()..clock = () => now;
    final week = s.event;
    expect(week.isCalendar, isFalse);
    s.addSugarCandies({week.color: 60});
    expect(s.eventCount, 60);
    // Şeker Bayramı, 9–11 March 2027: its own event, from zero, smaller steps.
    now = DateTime(2027, 3, 9, 10);
    expect(s.event, WeeklyEvent.bayram);
    expect(WeeklyEvent.daysLeft(now), 3);
    expect(WeeklyEvent.daysLeft(DateTime(2027, 3, 11, 22)), 1);
    expect(s.eventCount, 0);
    s.addSugarCandies({SugarColor.yellow: 300});
    expect(s.eventPrizesReady, 4, reason: 'the calendar days need fewer sweets');
    for (var i = 0; i < 4; i++) {
      s.claimEventPrize();
    }
    expect(s.unlocked(Unlock.outfitHalay), isTrue);
    // After the bayram the week's event is back, its sweets still counted.
    now = DateTime(2027, 3, 12, 9);
    expect(s.event, week);
    expect(s.eventCount, 60);
    // Hıdırellez: 5 and 6 May, every year.
    expect(WeeklyEvent.of(DateTime(2027, 5, 5)), WeeklyEvent.hidirellez);
    expect(WeeklyEvent.of(DateTime(2028, 5, 6, 23)), WeeklyEvent.hidirellez);
    expect(WeeklyEvent.of(DateTime(2028, 5, 7)).isCalendar, isFalse);
  });

  test('the week\'s event stays the one its sweets were counted for', () {
    var now = DateTime(2026, 10, 20, 12);
    final s = Settings.memory()..clock = () => now;
    s.addSugarCandies({s.event.color: 10});
    expect(s.event, WeeklyEvent.simit);
    // Even if the rotation were to say otherwise later in the week, the
    // stored event is kept: the next week starts from the rotation again.
    now = DateTime(2026, 10, 25, 20);
    expect(s.event, WeeklyEvent.simit);
    expect(s.eventCount, 10);
    now = DateTime(2026, 10, 26, 8);
    expect(s.event, WeeklyEvent.tulip);
    expect(s.eventCount, 0);
  });

  test('postcards: chapter ends, the event and chests each give their own cards', () {
    final s = at(DateTime(2026, 10, 19));
    // Chapter cards are the city's places, all different.
    expect(Rewards.chapterCards.toSet().length, Rewards.chapterCards.length);
    // The newer events give boosters for their third prize, not a card.
    final eventCards = [for (final e in WeeklyEvent.values) ?e.card];
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
