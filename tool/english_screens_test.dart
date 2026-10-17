// The newer screens in English, to check the words fit.
//   flutter test tool/english_screens_test.dart
// Writes SHOTS_OUT (default build/english-shots/): <name>.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/rewards.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/blocks/blocks_controller.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/blocks_screen.dart';
import 'package:lifeos_kupler/ui/gifts_screen.dart';
import 'package:lifeos_kupler/ui/lokum_wardrobe.dart';
import 'package:lifeos_kupler/ui/story_card.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/english-shots/';
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
  await family('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
}

Future<void> _pump(WidgetTester tester, int frames, [int ms = 33]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

/// A player some way in, in English.
Future<Settings> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(975, 2110);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = AppLanguage.en;
  for (var n = 1; n <= 9; n++) {
    settings.recordSugarLevel(n, stars: 2, score: 6000, seconds: 40);
  }
  settings.addSugarCandies({settings.event.color: 112, SugarColor.green: 30});
  for (final card in [0, 1, 2, 3, 4, 11]) {
    settings.applyGift(Gift(card: card));
  }
  await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await _pump(tester, 10);
  return settings;
}

BuildContext _ctx(WidgetTester tester) => tester.element(find.byKey(const ValueKey('play')));

void main() {
  setUpAll(_loadFonts);

  testWidgets('home', (tester) async {
    await _open(tester);
    await _shot(tester, 'home');
  });

  testWidgets('gifts', (tester) async {
    final settings = await _open(tester);
    GiftsScreen.open(_ctx(tester), settings: settings);
    await _pump(tester, 15);
    await _shot(tester, 'gifts-top');
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -1200));
    await _pump(tester, 15);
    await _shot(tester, 'gifts-bottom');
  });

  testWidgets('album', (tester) async {
    final settings = await _open(tester);
    showPostcards(_ctx(tester), settings);
    await _pump(tester, 15);
    await _shot(tester, 'album');
  });

  testWidgets('wardrobe', (tester) async {
    final settings = await _open(tester);
    showLokumWardrobe(_ctx(tester), settings);
    await _pump(tester, 15);
    await _shot(tester, 'wardrobe');
  });

  testWidgets('story', (tester) async {
    await _open(tester);
    Navigator.of(_ctx(tester)).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: SafeArea(child: StoryCard(chapter: 2, outfit: LokumOutfit.fez, onDone: () {}, moving: false))),
      ),
    );
    for (var i = 0; i < 2; i++) {
      await _pump(tester, 25);
      await tester.tap(find.byKey(const ValueKey('story-card')));
    }
    await _pump(tester, 25);
    await _shot(tester, 'story');
  });

  testWidgets('puzzle', (tester) async {
    final settings = await _open(tester);
    BlocksScreen.open(_ctx(tester), settings: settings, audio: AudioService(enabled: false), entry: BlocksEntry.menu);
    await _pump(tester, 20);
    final c = (tester.state(find.byType(BlocksScreen)) as dynamic).c as BlocksController;
    c.startLevel(40);
    await _pump(tester, 20);
    await _shot(tester, 'puzzle-level');
    c.game.debugSetBoard(['T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T']);
    c.startEndless();
    c.game.debugSetBoard(['T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T', 'T.T.T.T.', '.T.T.T.T']);
    c.game.debugSetTray(['dot', 'o2', 'o2']);
    c.place(0, 1, 0);
    await _pump(tester, 50);
    await _shot(tester, 'puzzle-rescue');
  });
}
