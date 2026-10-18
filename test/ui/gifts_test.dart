import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/rewards.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_levels.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';
import 'package:lifeos_kupler/ui/gifts_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<Settings> pumpApp(WidgetTester tester, {Size size = const Size(390, 844), Settings? settings, double text = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  settings ??= Settings.memory()..language = AppLanguage.tr;
  await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
  await pumpFor(tester, 6);
  return settings;
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await pumpFor(tester, 2);
  await tester.tap(find.byKey(ValueKey(key)));
  await pumpFor(tester, 12);
}

void main() {
  testWidgets("from the home's gift button: take today's gift, then open the jar and try what it opened", (tester) async {
    final settings = await pumpApp(tester);
    await tapKey(tester, 'gifts-open');
    expect(find.byKey(const ValueKey('gifts')), findsOneWidget);
    final hammers = settings.sugarBoosters(SugarBooster.hammer);
    await tapKey(tester, 'gift-daily');
    expect(find.byKey(const ValueKey('gift-popup')), findsOneWidget);
    await tapKey(tester, 'gift-collect');
    expect(settings.sugarBoosters(SugarBooster.hammer), hammers + 2);
    expect(find.byKey(const ValueKey('gift-daily')), findsNothing, reason: 'one a day');
    expect(tester.takeException(), isNull);

    // A full jar opens the shuffle booster.
    settings.addSugarCandies({SugarColor.red: 160});
    await pumpFor(tester, 4);
    await tapKey(tester, 'gift-jar');
    expect(find.text('YENİ ÖZELLİK AÇILDI!'), findsWidgets);
    expect(find.byKey(const ValueKey('gift-try')), findsNothing, reason: 'nothing to try on the spot');
    await tapKey(tester, 'gift-collect');
    expect(settings.unlocked(Unlock.shuffle), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('star chests open new cube looks; the collection picks them and the album shows the cards', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    for (var n = 1; n <= 5; n++) {
      settings.recordSugarLevel(n, stars: 3, score: 5000, seconds: 30);
    }
    await pumpApp(tester, settings: settings);
    GiftsScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings);
    await pumpFor(tester, 12);
    // A locked look cannot be picked.
    await tapKey(tester, 'cubes-cini');
    expect(settings.chainCubes, isNull);
    for (var i = 0; i < 3; i++) {
      await tapKey(tester, 'gift-chest');
      final tryIt = find.byKey(const ValueKey('gift-try'));
      if (tryIt.evaluate().isNotEmpty) {
        await tester.tap(tryIt);
      } else {
        await tester.tap(find.byKey(const ValueKey('gift-collect')));
      }
      await pumpFor(tester, 12);
    }
    expect(settings.unlocked(Unlock.cubesCini), isTrue);
    expect(settings.chainCubes, 'cini', reason: '"try it now" picks the new look');
    await tapKey(tester, 'cubes-vivid');
    expect(settings.chainCubes, isNull);
    await tapKey(tester, 'postcards');
    expect(find.byKey(const ValueKey('postcard-album')), findsOneWidget);
    // The chests gave the first cards of their pool: the cistern first.
    expect(settings.hasCard(0), isTrue);
    await tester.tap(find.byKey(const ValueKey('postcard-0')));
    await pumpFor(tester, 10);
    expect(find.text('Yerebatan Sarnıcı'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a full set of postcards gives its prize; all of them give the guide\'s hat', (tester) async {
    final settings = await pumpApp(tester);
    for (var i = 0; i < 5; i++) {
      settings.applyGift(Gift(card: i));
    }
    expect(settings.setComplete(0), isTrue);
    expect(settings.giftsReady, greaterThanOrEqualTo(2), reason: 'the set prize waits too');
    showPostcards(tester.element(find.byKey(const ValueKey('start'))), settings);
    await pumpFor(tester, 10);
    final rainbows = settings.sugarBoosters(SugarBooster.rainbow);
    await tapKey(tester, 'set-claim-0');
    await tapKey(tester, 'gift-collect');
    expect(settings.setClaimed(0), isTrue);
    expect(settings.sugarBoosters(SugarBooster.rainbow), rainbows + 2);
    expect(settings.unlocked(Unlock.outfitGuide), isFalse);
    for (var i = 5; i < Rewards.postcards; i++) {
      settings.applyGift(Gift(card: i));
    }
    for (var set = 1; set < Rewards.sets - 1; set++) {
      settings.claimSetPrize(set);
    }
    final last = settings.claimSetPrize(Rewards.sets - 1)!;
    expect(last.unlock, Unlock.outfitGuide);
    expect(settings.unlocked(Unlock.outfitGuide), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lokum tells a card\'s history on the home and shows it', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    settings.applyGift(const Gift(card: 3));
    await pumpApp(tester, settings: settings);
    await tester.ensureVisible(find.byKey(const ValueKey('lokum')));
    await tester.pump(const Duration(milliseconds: 40));
    for (var i = 0; i < 8 && find.byKey(const ValueKey('tip-card')).evaluate().isEmpty; i++) {
      await tester.tap(find.byKey(const ValueKey('lokum')));
      await pumpFor(tester, 10);
    }
    expect(find.byKey(const ValueKey('tip-card')), findsOneWidget);
    expect(find.textContaining('Galata Kulesi'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('tip-action')));
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('postcard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 640), Size(1280, 800)]) {
    testWidgets('the gifts screen fits ${size.width.round()}×${size.height.round()} with large text', (tester) async {
      final settings = await pumpApp(tester, size: size, text: 1.3);
      settings.addSugarCandies({SugarColor.red: 400});
      GiftsScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings);
      await pumpFor(tester, 12);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -2000));
      await pumpFor(tester, 10);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Zincir Küpler: the chosen cube look and the stop-the-clock booster', (tester) async {
    final settings = await pumpApp(tester);
    settings.applyGift(const Gift(unlock: Unlock.freeze, freezes: 2));
    settings.applyGift(const Gift(unlock: Unlock.cubesLokum));
    settings.chainCubes = 'lokum';
    ChainScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings, audio: AudioService(enabled: false), mode: ChainMode.endless);
    await pumpFor(tester, 12, 40);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFor(tester, 20);
    final c = (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;
    expect(c.cubes, ChainCubeStyle.lokum);
    await tester.tap(find.byKey(const ValueKey('chain-freeze')));
    await pumpFor(tester, 4);
    expect(settings.chainFreezes, 1);
    expect(c.game.stopTime, greaterThan(4));
    // A look not unlocked falls back to vivid.
    settings.chainCubes = 'cini';
    expect(c.cubes, ChainCubeStyle.vivid);
    expect(tester.takeException(), isNull);
  });
}
