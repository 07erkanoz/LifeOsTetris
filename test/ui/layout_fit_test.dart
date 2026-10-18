import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';

/// The theme fonts themselves: the test font draws every glyph a full em
/// wide and reports overflows the real type never has.
Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Inter', [
    for (final w in ['Regular', 'SemiBold', 'ExtraBold', 'Black']) 'assets/fonts/Inter-$w.otf',
  ]);
  await family('Baloo2', [
    for (final w in ['SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/Baloo2-$w.ttf',
  ]);
  await family('Jersey10', ['assets/fonts/Jersey10-Regular.ttf']);
}

void main() {
  setUpAll(_loadFonts);

  // A tablet / small desktop window and a phone held sideways: where the side
  // panels and the score card are tightest. Every skin has its own font.
  for (final theme in [VisualTheme.toyHd, VisualTheme.pixel, VisualTheme.neon]) {
    for (final size in [const Size(1024, 768), const Size(844, 390)]) {
      for (final language in [AppLanguage.tr, AppLanguage.en]) {
        for (final scale in [1.0, 1.1]) {
          testWidgets('${theme.name} ${size.width.toInt()}×${size.height.toInt()} ${language.name} text ×$scale: every Küpler mode fits', (
            tester,
          ) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
            final settings = Settings.memory()
              ..language = language
              ..visualTheme = theme;
            await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull, reason: 'main menu');

            for (final mode in ['superMode', 'normal', 'relaxed', 'sprint', 'ultra', 'dig', 'target', 'chaos']) {
              // The bar on top plays the last mode once nothing waits.
              settings
                ..lastPlay = mode
                ..savedGame = null;
              await tester.pump();
              await tester.tap(find.byKey(const ValueKey('play')));
              await tester.pump(const Duration(milliseconds: 100));
              final c = (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
              // Big numbers are the widest the HUD gets.
              c.game.score = 9876543;
              c.game.lines = 888;
              c.game.level = 15;
              c.playTime = 3599;
              for (var i = 0; i < 10; i++) {
                await tester.pump(const Duration(milliseconds: 33));
              }
              expect(tester.takeException(), isNull, reason: mode);
              c.togglePause();
              await tester.pump(const Duration(milliseconds: 300));
              expect(tester.takeException(), isNull, reason: '$mode paused');
              c.toMenu();
              await tester.pump(const Duration(milliseconds: 300));
            }
          });
        }
      }
    }
  }
}
