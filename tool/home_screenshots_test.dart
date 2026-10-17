// Screenshots of the real home lobby in every skin and a few sizes.
//   flutter test tool/home_screenshots_test.dart
// Writes SHOTS_OUT (default build/home-shots/): <theme>-<size>.png.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/home-shots/';
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

  for (final theme in [VisualTheme.toyHd, VisualTheme.neon, VisualTheme.pixel]) {
    for (final (name, size, ratio) in [('telefon', const Size(430, 932), 2.5), ('yatay', const Size(915, 412), 2.0), ('masaustu', const Size(1600, 900), 1.0)]) {
      testWidgets('${theme.name} $name', (tester) async {
        tester.view.physicalSize = size * ratio;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);
        final settings = Settings.memory()
          ..language = AppLanguage.tr
          ..visualTheme = theme
          ..lastPlay = 'superMode';
        // A player some way in: a record, stars, a level left half way.
        settings.recordGame(mode: GameMode.superMode, score: 15398, lines: 40, seconds: 300);
        for (var n = 1; n <= 7; n++) {
          settings.recordBlockLevel(n, 3);
        }
        settings.savedSugar = jsonEncode({'level': 12});
        final chain = ChainGame()..start(ChainMode.endless);
        chain.score = 4321;
        settings.savedChain = jsonEncode(chain.toSave());
        await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
        final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: ratio);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        File('$_out${theme.name}-$name.png')
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes!);
      });
    }
  }
}
