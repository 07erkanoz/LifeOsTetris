// The main screens on a desktop window, to review how they sit there.
//   flutter test tool/desktop_review_test.dart
// Writes SHOTS_OUT (default build/desktop/): <size>-<screen>.png.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/gifts_screen.dart';

import 'store_kit.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/desktop/';

void main() {
  setUpAll(loadStoreFonts);
  for (final (name, size) in [('1280', const Size(1280, 720)), ('1920', const Size(1920, 1080))]) {
    Future<Settings> app(WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final settings = Settings.memory()
        ..language = AppLanguage.tr
        ..lastPlay = 'sugar';
      settings.recordGame(mode: GameMode.superMode, score: 15398, lines: 40, seconds: 300);
      await tester.pumpWidget(RepaintBoundary(key: storeRoot, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
      await pumpFrames(tester, 20);
      return settings;
    }

    Future<void> shot(WidgetTester tester, String screen) async {
      await pumpFrames(tester, 30);
      await storeShot(tester, '$_out$name-$screen.png', 1);
      expect(tester.takeException(), isNull);
    }

    testWidgets('$name home', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      await app(tester);
      await shot(tester, 'home');
    });
    testWidgets('$name games', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      await app(tester);
      await tester.tap(find.byKey(const ValueKey('change-mode')));
      await shot(tester, 'games');
      await tester.tap(find.byKey(const ValueKey('game-classic')));
      await shot(tester, 'game-page');
    });
    testWidgets('$name classic', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      await app(tester);
      await startMode(tester, 'normal');
      await shot(tester, 'classic');
    });
    testWidgets('$name sugar', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      final settings = await app(tester);
      await sugarUpTo(tester, settings, 20);
      await shot(tester, 'sugar');
    });
    testWidgets('$name chain', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      await app(tester);
      await startMode(tester, 'chainEndless');
      await tester.tap(find.byKey(const ValueKey('chain-start')));
      await shot(tester, 'chain');
    });
    testWidgets('$name tower', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      await app(tester);
      await startMode(tester, 'towerClimb');
      await shot(tester, 'tower');
    });
    testWidgets('$name puzzle', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      await app(tester);
      await startMode(tester, 'blocksLevels');
      await shot(tester, 'puzzle');
    });
    testWidgets('$name gifts', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      final settings = await app(tester);
      GiftsScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings);
      await shot(tester, 'gifts');
    });
  }
}
