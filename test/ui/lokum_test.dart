import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/game/lokum_mood.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';
import 'package:lifeos_kupler/ui/lokum_wardrobe.dart';

import 'ordinary_day.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<Settings> pumpApp(WidgetTester tester, {Size size = const Size(390, 844), Settings? settings}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  settings = ordinaryDay(settings ?? (Settings.memory()..language = AppLanguage.tr));
  await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
  await pumpFor(tester, 6);
  return settings;
}

void main() {
  test('outfits open with Şeker stars and stay off until then', () {
    expect(LokumOutfit.values.first, LokumOutfit.none);
    final byStars = [for (final o in LokumOutfit.values) if (o.gift == null) o.stars];
    expect(byStars, orderedEquals([...byStars]..sort()));
    // Event outfits come with their prize, not with stars.
    expect(LokumOutfit.worn('captain', 180), LokumOutfit.none);
    expect(LokumOutfit.worn('captain', 0, {'outfitCaptain'}), LokumOutfit.captain);
    expect(LokumOutfit.worn('fez', 0), LokumOutfit.none);
    expect(LokumOutfit.worn('fez', 3), LokumOutfit.fez);
    expect(LokumOutfit.worn('sultan', 109), LokumOutfit.none);
    expect(LokumOutfit.worn('nonsense', 180), LokumOutfit.none);
  });

  test('Lokum settles back to happy once his moment is over', () {
    final mood = LokumMood();
    mood.say(AppStrings.tr, 'quad', LokumPose.wow, 1);
    expect(mood.pose, LokumPose.wow);
    expect(mood.line, 'Dört sıra birden!');
    // A lesser moment does not cut in.
    mood.say(AppStrings.tr, null, LokumPose.cheer, 1.5, priority: 0);
    expect(mood.pose, LokumPose.wow);
    mood.settle(2);
    expect(mood.pose, LokumPose.wow);
    mood.settle(4);
    expect(mood.pose, LokumPose.happy);
    expect(mood.line, isNull);
    // A wordless pose passes too.
    mood.say(AppStrings.tr, null, LokumPose.cheer, 5);
    mood.settle(8);
    expect(mood.pose, LokumPose.happy);
    // At the end he keeps his face.
    mood.say(AppStrings.tr, 'over', LokumPose.sad, 9, priority: 5, hold: 99);
    mood.settle(200, keep: true);
    expect(mood.pose, LokumPose.sad);
  });

  testWidgets('the wardrobe opens from the home; locked outfits wait for stars; the pick sticks', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    await pumpApp(tester, settings: settings);
    await tester.ensureVisible(find.byKey(const ValueKey('wardrobe-open')));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byKey(const ValueKey('wardrobe-open')));
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('wardrobe')), findsOneWidget);
    for (final o in LokumOutfit.values) {
      expect(find.byKey(ValueKey('outfit-${o.name}'), skipOffstage: false), findsOneWidget, reason: o.name);
    }
    // No stars yet: the fez is locked.
    await tester.tap(find.byKey(const ValueKey('outfit-fez')));
    await pumpFor(tester, 4);
    expect(settings.lokumOutfit, isNull);
    // Ten stars open the fez and the tulip.
    for (var n = 1; n <= 5; n++) {
      settings.recordSugarLevel(n, stars: 2, score: 5000, seconds: 30);
    }
    await pumpFor(tester, 4);
    await tester.tap(find.byKey(const ValueKey('outfit-fez')));
    await pumpFor(tester, 4);
    expect(settings.lokumOutfit, 'fez');
    expect(settings.outfit, LokumOutfit.fez);
    await tester.tap(find.byKey(const ValueKey('outfit-nazar')), warnIfMissed: false);
    await pumpFor(tester, 4);
    expect(settings.outfit, LokumOutfit.fez, reason: 'the bead needs 18 stars');
    await tester.ensureVisible(find.byKey(const ValueKey('wardrobe-close')));
    await tester.tap(find.byKey(const ValueKey('wardrobe-close')));
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('wardrobe')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wardrobe fits a small phone with large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final settings = await pumpApp(tester, size: const Size(360, 640));
    showLokumWardrobe(tester.element(find.byKey(const ValueKey('start'))), settings);
    await pumpFor(tester, 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zincir Küpler: Lokum stands by the Yükselt button, clear of the board', (tester) async {
    final settings = await pumpApp(tester);
    settings.lokumOutfit = 'fez';
    ChainScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings, audio: AudioService(enabled: false), mode: ChainMode.endless);
    await pumpFor(tester, 12, 40);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFor(tester, 20);
    final lokum = tester.getRect(find.byKey(const ValueKey('chain-lokum')));
    final board = tester.getRect(find.byKey(const ValueKey('chain-board')));
    final raise = tester.getRect(find.byKey(const ValueKey('chain-raise')));
    expect(lokum.top, greaterThanOrEqualTo(board.bottom - 12), reason: 'he does not cover the cubes');
    expect(lokum.overlaps(raise), isFalse);
    expect(lokum.bottom, lessThanOrEqualTo(844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('classic on a big desktop window: Lokum under the left cards; on a phone he waits for the pause', (tester) async {
    final settings = await pumpApp(tester, size: const Size(1920, 1080));
    final c = (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
    c.start(GameMode.superMode);
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('side-lokum')), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(390, 844);
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('side-lokum')), findsNothing);
    c.togglePause();
    await pumpFor(tester, 10);
    expect(find.text(AppStrings.tr.lokum('pause', c.playTime.floor())), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(settings.lokumOutfit, isNull);
  });

  testWidgets('on 10 Kasım Lokum remembers Atatürk with Turkish players; English players see the usual home', (tester) async {
    final tr = Settings.memory()
      ..language = AppLanguage.tr
      ..clock = () => DateTime(2026, 11, 10, 9, 5);
    await pumpApp(tester, settings: tr);
    expect(find.byKey(const ValueKey('tip-day-ataturk')), findsOneWidget);
    expect(find.textContaining('Atatürk'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on Cumhuriyet Bayramı the greeting shows in Turkish only', (tester) async {
    final tr = Settings.memory()
      ..language = AppLanguage.tr
      ..clock = () => DateTime(2026, 10, 29, 10);
    await pumpApp(tester, settings: tr);
    expect(find.byKey(const ValueKey('tip-day-cumhuriyet')), findsOneWidget);
    expect(find.text('Cumhuriyetimizin 103. yılı kutlu olsun!'), findsOneWidget);
    final en = Settings.memory()
      ..language = AppLanguage.en
      ..clock = () => DateTime(2026, 10, 29, 10);
    await pumpApp(tester, settings: en);
    expect(find.byKey(const ValueKey('tip-day-cumhuriyet')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
