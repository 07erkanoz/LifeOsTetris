import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Size size, {AppLanguage language = AppLanguage.tr}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KuplerApp(settings: Settings.memory()..language = language, audio: AudioService(enabled: false)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final (name, size) in [('phone', const Size(390, 844)), ('desktop', const Size(1440, 900))]) {
    testWidgets('$name: start a game, play, pause and quit to menu', (tester) async {
      await pumpApp(tester, size);
      expect(find.byKey(const ValueKey('start-classic')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('start-classic')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      expect(find.byKey(const ValueKey('start-classic')), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Duraklatıldı'), findsOneWidget);

      await tester.tap(find.text('Menü'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('start-classic')), findsOneWidget);
    });
  }

  testWidgets('about page shows the developer', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await tester.tap(find.text('Hakkında'));
    await tester.pumpAndSettle();
    expect(find.text('Erkan ÖZ'), findsOneWidget);
    expect(find.text('lifeos.com.tr'), findsOneWidget);
  });

  testWidgets('English UI and switching language from the menu', (tester) async {
    await pumpApp(tester, const Size(390, 844), language: AppLanguage.en);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Türkçe'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Klasik'), findsOneWidget);
    expect(find.text('Hakkında'), findsOneWidget);
  });
}
