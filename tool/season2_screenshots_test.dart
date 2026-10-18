// The second season of Şeker Küpler on a phone: a level of each chapter
// (its new obstacle on the board), the chapters' story cards and the map.
//   flutter test tool/season2_screenshots_test.dart
// Writes SHOTS_OUT (default build/season2/): level-NNN.png, story-NN.png,
// map.png.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';

import 'store_kit.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/season2/';
const _size = Size(390, 844);
const _dpr = 2.5;

Future<Settings> _app(WidgetTester tester, {AppLanguage language = AppLanguage.tr}) async {
  tester.view.physicalSize = _size * _dpr;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = language;
  await tester.pumpWidget(RepaintBoundary(key: storeRoot, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await pumpFrames(tester, 10);
  return settings;
}

void main() {
  setUpAll(loadStoreFonts);

  for (final n in [121, 131, 141, 151, 161, 171]) {
    testWidgets('level $n', (tester) async {
      final settings = await _app(tester);
      final c = (await sugarUpTo(tester, settings, n - 1))!;
      expect(c.level.number, n);
      // A couple of moves, so gulls land and Acı Biber throws.
      await sugarMoves(tester, c, n == 141 ? 3 : (n == 171 ? 5 : 2));
      await pumpFrames(tester, 30);
      await storeShot(tester, '${_out}level-$n.png', _dpr);
      expect(tester.takeException(), isNull);
    });
  }

  for (final ch in [12, 13, 14, 15, 16, 17]) {
    testWidgets('story $ch', (tester) async {
      final settings = await _app(tester);
      // Into the chapter's first level: its story card comes first.
      await sugarUpTo(tester, settings, ch * 10, unseen: ch, play: false);
      await pumpFrames(tester, 90);
      await storeShot(tester, '${_out}story-$ch.png', _dpr);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('map', (tester) async {
    final settings = await _app(tester);
    for (var n = 1; n <= 125; n++) {
      settings.recordSugarLevel(n, stars: 3, score: 15000, seconds: 60);
    }
    for (var ch = 0; ch < 18; ch++) {
      settings.markStorySeen(ch);
    }
    await startMode(tester, 'sugar');
    await pumpFrames(tester, 30);
    await storeShot(tester, '${_out}map.png', _dpr);
    expect(tester.takeException(), isNull);
  });
}
