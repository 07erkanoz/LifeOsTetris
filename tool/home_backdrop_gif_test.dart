// Frames of the real home lobby with its living background, for GIFs.
//   flutter test tool/home_backdrop_gif_test.dart
// Writes SHOTS_OUT (default build/home-gif/): <theme>/NN.png.
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

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/home-gif/';
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
  await family('MaterialIcons', [Directory('$sdk/bin/cache/artifacts/material_fonts').listSync().whereType<File>().firstWhere((f) => f.path.toLowerCase().endsWith('materialicons-regular.otf')).path]);
}

void main() {
  setUpAll(_loadFonts);
  for (final theme in [VisualTheme.toyHd, VisualTheme.neon, VisualTheme.pixel]) {
    testWidgets(theme.name, (tester) async {
      const ratio = 1.25;
      tester.view.physicalSize = const Size(430, 932) * ratio;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      final settings = Settings.memory()
        ..language = AppLanguage.tr
        ..visualTheme = theme
        ..lastPlay = 'superMode';
      settings.recordGame(mode: GameMode.superMode, score: 15398, lines: 40, seconds: 300);
      await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      for (var f = 0; f < 40; f++) {
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
        final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: ratio);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        File('$_out${theme.name}/${f.toString().padLeft(2, '0')}.png')
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes!);
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
