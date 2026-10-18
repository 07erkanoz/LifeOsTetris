// The new effects in the real game: Şeker Küpler's glowing specials with a
// spark between two side by side, a named combo going off; and the first
// Vapur Hattı mission's lesson, step by step.
//   flutter test tool/combo_tutorial_screenshots_test.dart
// Writes SHOTS_OUT (default build/effects/): specials.png, combo.png,
// lesson-1.png, lesson-2.png, lesson-3.png, how-to.png.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/chain/chain_missions.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';

import 'store_kit.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/effects/';
const _size = Size(390, 844);
const _dpr = 2.5;

Future<Settings> _app(WidgetTester tester) async {
  tester.view.physicalSize = _size * _dpr;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = AppLanguage.tr;
  await tester.pumpWidget(RepaintBoundary(key: storeRoot, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await pumpFrames(tester, 10);
  return settings;
}

void main() {
  setUpAll(loadStoreFonts);

  testWidgets('glowing specials and a combo', (tester) async {
    final settings = await _app(tester);
    final c = (await sugarUpTo(tester, settings, 20))!;
    final b = c.game.board;
    b[5][2]!.special = Special.lineH;
    b[5][3]!.special = Special.bomb;
    b[2][6]!.special = Special.prism;
    b[3][1]!.special = Special.lineV;
    await pumpFrames(tester, 20);
    await storeShot(tester, '${_out}specials.png', _dpr);
    c.trySwap((2, 5), (3, 5));
    await pumpFrames(tester, 7);
    await storeShot(tester, '${_out}combo.png', _dpr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the first mission is a lesson', (tester) async {
    await _app(tester);
    await startMode(tester, 'chainMissions');
    await tester.tap(find.byKey(const ValueKey('mission-1')));
    await pumpFrames(tester, 15, 40);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFrames(tester, 20);
    await storeShot(tester, '${_out}lesson-1.png', _dpr);
    final c = (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;
    final (x, y) = c.game.onlySwap!;
    c.game.swap(x, y);
    for (var i = 0; i < 60 && c.lesson != 'fall'; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await pumpFrames(tester, 6);
    await storeShot(tester, '${_out}lesson-2.png', _dpr);
    for (var i = 0; i < 120 && c.lesson != 'chain'; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await pumpFrames(tester, 4);
    await storeShot(tester, '${_out}lesson-3.png', _dpr);
    expect(c.game.maxChain, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the how-to card before the next chain mission', (tester) async {
    final settings = await _app(tester);
    ChainScreen.open(tester.element(find.byKey(const ValueKey('start'))), settings: settings, audio: AudioService(enabled: false), mode: ChainMode.mission, mission: ChainMissions.of(6));
    await pumpFrames(tester, 20, 40);
    expect(find.byKey(const ValueKey('chain-how-to')), findsOneWidget);
    await storeShot(tester, '${_out}how-to.png', _dpr);
    expect(tester.takeException(), isNull);
  });
}
