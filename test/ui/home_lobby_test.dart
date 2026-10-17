import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';

Future<void> pumpFor(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<Settings> pumpLobby(WidgetTester tester, {Size size = const Size(390, 844), Settings? settings, double text = 1}) async {
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

void main() {
  for (final theme in [VisualTheme.toyHd, VisualTheme.neon, VisualTheme.pixel]) {
    for (final size in const [Size(390, 844), Size(360, 640), Size(844, 390), Size(1024, 768), Size(1920, 1080)]) {
      for (final text in [1.0, 1.3]) {
        testWidgets('${theme.name} ${size.width.round()}×${size.height.round()} text ×$text: the lobby fits', (tester) async {
          final settings = Settings.memory()
            ..language = AppLanguage.tr
            ..visualTheme = theme;
          await pumpLobby(tester, size: size, settings: settings, text: text);
          expect(tester.takeException(), isNull);
          for (final key in ['play', 'change-mode', 'open-settings', 'lokum', 'tip-action']) {
            expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
          }
          // The essentials are on screen without scrolling.
          final screen = Offset.zero & size;
          for (final key in ['play', 'open-settings']) {
            expect(screen.contains(tester.getCenter(find.byKey(ValueKey(key)))), isTrue, reason: '$key in view');
          }
          await pumpFor(tester, 10);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Lokum suggests the daily puzzle, then a mode never played; tapping him changes the idea', (tester) async {
    await pumpLobby(tester);
    expect(find.byKey(const ValueKey('tip-daily')), findsOneWidget, reason: 'today\'s puzzle is not solved');
    await tester.tap(find.byKey(const ValueKey('lokum')));
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('tip-chainEndless')), findsOneWidget);
    expect(find.text('Bunu hiç denemedin!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tip-action')));
    await pumpFor(tester, 15, 40);
    expect(find.byType(ChainScreen), findsOneWidget);
  });

  testWidgets('a Şeker Küpler level left half way comes first, on the bubble and the cards', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    settings.savedSugar = jsonEncode({'level': 7});
    await pumpLobby(tester, settings: settings);
    expect(find.byKey(const ValueKey('tip-sugar')), findsOneWidget);
    expect(find.text('Kaldığın yer: Seviye 7'), findsWidgets);
    expect(find.text('DEVAM'), findsOneWidget);
    // The play card's own mode is not repeated among the cards.
    expect(find.byKey(const ValueKey('card-superMode')), findsNothing);
    expect(find.byKey(const ValueKey('card-sugar')), findsOneWidget);
  });

  testWidgets('a mode played is no longer new', (tester) async {
    final settings = Settings.memory()..language = AppLanguage.tr;
    settings.recordChainGame(mode: ChainMode.endless, difficulty: ChainDifficulty.easy, score: 900, seconds: 30);
    await pumpLobby(tester, settings: settings);
    await tester.tap(find.byKey(const ValueKey('lokum')));
    await pumpFor(tester, 10);
    expect(find.byKey(const ValueKey('tip-chainEndless')), findsNothing);
    // Played modes move to the end of the cards, with their record.
    final card = find.byKey(const ValueKey('card-chainEndless'));
    await tester.scrollUntilVisible(card, 160, scrollable: find.descendant(of: find.byKey(const ValueKey('lobby-cards')), matching: find.byType(Scrollable)));
    expect(find.descendant(of: card, matching: find.textContaining('900')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('YENİ')), findsNothing);
  });

  testWidgets('with visual effects off the scenes hold still', (tester) async {
    final settings = Settings.memory()
      ..language = AppLanguage.tr
      ..effects = false;
    await pumpLobby(tester, settings: settings);
    bool moving() => (tester.state(find.byKey(const ValueKey('start'))) as dynamic).moving as bool;
    expect(moving(), isFalse);
    settings.effects = true;
    await tester.pump(const Duration(milliseconds: 33));
    expect(moving(), isTrue);
  });
}
