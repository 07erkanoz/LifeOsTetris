// Screenshots of the gifts screen, an unlock and the postcard album, with
// the real fonts, for review.
//   flutter test tool/gifts_screenshots_test.dart
// Writes SHOTS_OUT (default build/gift-shots/): gifts-top.png,
// gifts-bottom.png, unlock.png, guide.png, album.png.
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
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/gifts_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/gift-shots/';
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

/// A player a few days in: stars, a filling jar, event progress.
Future<Settings> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(975, 2110);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()
    ..language = AppLanguage.tr
    ..clock = () => DateTime(2026, 10, 21, 10);
  for (var n = 1; n <= 9; n++) {
    settings.recordSugarLevel(n, stars: n.isEven ? 3 : 2, score: 6000, seconds: 40);
  }
  settings.openStarChest();
  settings.openStarChest();
  settings.addSugarCandies({settings.event.color: 112, SugarColor.green: 30});
  await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await _pump(tester, 6);
  GiftsScreen.open(tester.element(find.byKey(const ValueKey('play'))), settings: settings);
  await _pump(tester, 15);
  return settings;
}

void main() {
  setUpAll(_loadFonts);
  testWidgets('gifts screen', (tester) async {
    await _open(tester);
    await _shot(tester, 'gifts-top.png');
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -1200));
    await _pump(tester, 15);
    await _shot(tester, 'gifts-bottom.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unlock', (tester) async {
    final settings = await _open(tester);
    showGiftPopup(tester.element(find.byKey(const ValueKey('gifts'))), settings, Rewards.chest(3), title: 'GÜMÜŞ SANDIK!', chest: ChestTier.silver);
    await _pump(tester, 15);
    await _shot(tester, 'unlock.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets("the guide's hat", (tester) async {
    final settings = await _open(tester);
    settings.applyGift(const Gift(unlock: Unlock.outfitGuide));
    showGiftPopup(tester.element(find.byKey(const ValueKey('gifts'))), settings, Rewards.setPrize(2, all: true), title: 'SET');
    await _pump(tester, 15);
    await _shot(tester, 'guide.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('postcard album', (tester) async {
    final settings = await _open(tester);
    for (final card in [0, 1, 2, 3, 4, 5, 6, 10, 11]) {
      settings.applyGift(Gift(card: card));
    }
    showPostcards(tester.element(find.byKey(const ValueKey('gifts'))), settings);
    await _pump(tester, 15);
    await _shot(tester, 'album.png');
    expect(tester.takeException(), isNull);
  });
}
