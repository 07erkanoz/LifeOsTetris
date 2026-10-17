import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/rewards.dart';
import 'package:lifeos_kupler/l10n/strings.dart';

void main() {
  test('capitals follow the language: Turkish keeps the dot on i', () {
    expect(AppStrings.tr.upper('Rumeli Hisarı'), 'RUMELİ HİSARI');
    expect(AppStrings.tr.upper('Haftanın etkinliği'), 'HAFTANIN ETKİNLİĞİ');
    expect(AppStrings.en.upper('this week'), 'THIS WEEK');
  });

  test('the English texts of the new features use English names', () {
    const s = AppStrings.en;
    final texts = [
      for (var i = 0; i < Rewards.postcards; i++) ...[s.postcard(i).title, s.postcard(i).fact],
      for (final e in WeeklyEvent.values) ...[s.eventName(e.name), s.eventGoal(e.name), s.eventFact(e.name).fact],
      for (final u in Unlock.values) ...[s.unlockName(u.name), s.unlockText(u.name)],
      for (var c = 0; c < 12; c++) ...[s.chapterStory(c).history, s.chapterStory(c).limon, s.chapterStory(c).lokum, s.chapterPlace(c)],
      for (final h in ['choco', 'fruit', 'belt', 'cake', 'door', 'limon']) s.sugarHint(h),
      s.sugarGoalLimon,
      s.wardrobeHint,
      s.chestsHint(5),
      s.cubeLook,
      s.sugarSceneLabel,
      s.postcardsTitle,
    ];
    for (final t in texts) {
      expect(t, isNot(matches(RegExp('Şeker|Zincir|Küpler|İstanbul|İznik'))), reason: t);
    }
  });
}
