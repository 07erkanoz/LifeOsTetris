// Screenshots of the real games page and of each game's own page, on a phone
// in every skin.
//   flutter test tool/games_page_screenshots_test.dart
// Writes SHOTS_OUT (default build/games-shots/): <theme>-<page>.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/games-shots/';
final _root = GlobalKey();

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Inter', [for (final w in ['Regular', 'SemiBold', 'ExtraBold', 'Black']) 'assets/fonts/Inter-$w.otf']);
  await family('Baloo2', [for (final w in ['SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/Baloo2-$w.ttf']);
  await family('Jersey10', ['assets/fonts/Jersey10-Regular.ttf']);
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  await family('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
}

Future<void> _pump(WidgetTester tester, [int frames = 14]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> _shot(WidgetTester tester, String name, double ratio) async {
  final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(_loadFonts);

  for (final theme in [VisualTheme.toyHd, VisualTheme.neon, VisualTheme.pixel]) {
    testWidgets(theme.name, (tester) async {
      const size = Size(390, 844), ratio = 2.5;
      tester.view.physicalSize = size * ratio;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      final settings = Settings.memory()
        ..language = AppLanguage.tr
        ..visualTheme = theme
        ..lastPlay = 'chainMissions';
      // A player some way in.
      settings.recordGame(mode: GameMode.classic, score: 26700, lines: 40, seconds: 300);
      settings.recordGame(mode: GameMode.superMode, score: 89800, lines: 60, seconds: 400);
      for (var n = 1; n <= 7; n++) {
        settings.recordBlockLevel(n, 3);
      }
      for (var n = 0; n < 5; n++) {
        settings.recordMission(n, 3);
      }
      await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
      await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('change-mode')));
      await _pump(tester);
      await _shot(tester, '${theme.name}-oyunlar', ratio);
      for (final game in ['chain', 'classic', 'puzzle']) {
        await tester.tap(find.byKey(ValueKey('game-$game')));
        await _pump(tester);
        await _shot(tester, '${theme.name}-$game', ratio);
        await tester.tap(find.byKey(const ValueKey('game-back')));
        await _pump(tester);
      }
    });
  }
}
