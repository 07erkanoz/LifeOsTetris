// Screenshots of the power and level banners on a wide full-screen layout.
//   flutter test tool/banner_screenshots_test.dart
// Writes SHOTS_OUT (default build/banner-shots/): <theme>-<size>.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/game_events.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/banner-shots/';
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

void main() {
  setUpAll(_loadFonts);

  for (final theme in [VisualTheme.neon, VisualTheme.toyHd, VisualTheme.pixel]) {
    for (final size in const [Size(1920, 1080), Size(1500, 1000), Size(390, 844)]) {
      testWidgets('${theme.name} ${size.width.round()}x${size.height.round()}', (tester) async {
        tester.view.physicalSize = size * (size.width < 600 ? 2.5 : 1);
        tester.view.devicePixelRatio = size.width < 600 ? 2.5 : 1;
        addTearDown(tester.view.reset);
        final settings = Settings.memory()
          ..language = AppLanguage.tr
          ..visualTheme = theme
          ..lastPlay = 'superMode';
        await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
        await tester.tap(find.byKey(const ValueKey('play')));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
        final c = (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
        c.fx.handle(const PowerEarned(PowerType.bomb), c.game);
        c.fx.handle(const LevelUp(4), c.game);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
        final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: size.width < 600 ? 2.5 : 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        File('$_out${theme.name}-${size.width.round()}x${size.height.round()}.png')
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes!);
      });
    }
  }

  Future<void> shot(WidgetTester tester, String name, double ratio) async {
    final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File('$_out$name')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  }

  testWidgets('windows home menu with quit', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = Settings.memory()..language = AppLanguage.tr;
    await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await shot(tester, 'home-windows.png', 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('sugar pause menu', (tester) async {
    tester.view.physicalSize = const Size(1100, 2390);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final settings = Settings.memory()..language = AppLanguage.tr;
    await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.ensureVisible(find.byKey(const ValueKey('mode-sugar'), skipOffstage: false));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byKey(const ValueKey('mode-sugar')));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.tap(find.byKey(const ValueKey('sugar-continue')));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.ensureVisible(find.byKey(const ValueKey('sugar-play')));
    await tester.tap(find.byKey(const ValueKey('sugar-play')));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await tester.tap(find.byKey(const ValueKey('sugar-pause')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await shot(tester, 'sugar-pause.png', 2.5);
  });
}
