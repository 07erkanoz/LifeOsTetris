// The phone's back on the home screen: the hint before the app closes.
//   flutter test tool/back_hint_screenshot_test.dart
// Writes SHOTS_OUT (default build/back/): exit-hint.png.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';

import 'store_kit.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/back/';
const _size = Size(390, 844);
const _dpr = 2.5;

void main() {
  setUpAll(loadStoreFonts);

  testWidgets('the exit hint', (tester) async {
    tester.view.physicalSize = _size * _dpr;
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);
    final settings = Settings.memory()..language = AppLanguage.tr;
    await tester.pumpWidget(RepaintBoundary(key: storeRoot, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
    await pumpFrames(tester, 10);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    await tester.binding.handlePopRoute();
    await pumpFrames(tester, 12);
    await storeShot(tester, '${_out}exit-hint.png', _dpr);
    expect(tester.takeException(), isNull);
  });
}
