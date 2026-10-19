// Screenshots of Şeker Küpler's İstanbul story cards and Lokum's
// wardrobe, with the real fonts, for review.
//   flutter test tool/story_screenshots_test.dart
// Writes SHOTS_OUT (default build/story-shots/): story-<chapter>.png
// (the last page of each card) and wardrobe.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/lokum_wardrobe.dart';
import 'package:lifeos_kupler/ui/story_card.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/story-shots/';
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
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  await family('MaterialIcons', [Directory('$sdk/bin/cache/artifacts/material_fonts').listSync().whereType<File>().firstWhere((f) => f.path.toLowerCase().endsWith('materialicons-regular.otf')).path]);
}

Future<void> _pump(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(_loadFonts);
  for (var chapter = 0; chapter < 6; chapter++) {
    testWidgets('story card $chapter', (tester) async {
      tester.view.physicalSize = const Size(975, 2110);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      final settings = Settings.memory()..language = AppLanguage.tr;
      await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
      await _pump(tester, 6);
      Navigator.of(tester.element(find.byKey(const ValueKey('start')))).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: const Color(0xFF3A1470),
            body: SafeArea(child: StoryCard(chapter: chapter, outfit: LokumOutfit.fez, onDone: () {}, moving: false)),
          ),
        ),
      );
      for (var page = 0; page < 2; page++) {
        await _pump(tester, 25);
        await tester.tap(find.byKey(const ValueKey('story-card')));
      }
      await _pump(tester, 25);
      expect(tester.takeException(), isNull);
      await _shot(tester, 'story-$chapter.png');
    });
  }

  testWidgets('wardrobe', (tester) async {
    tester.view.physicalSize = const Size(975, 2110);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final settings = Settings.memory()
      ..language = AppLanguage.tr
      ..lokumOutfit = 'fez';
    for (var n = 1; n <= 12; n++) {
      settings.recordSugarLevel(n, stars: 2, score: 5000, seconds: 30);
    }
    await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
    await _pump(tester, 10);
    showLokumWardrobe(tester.element(find.byKey(const ValueKey('start'))), settings);
    await _pump(tester, 20);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'wardrobe.png');
  });
}
