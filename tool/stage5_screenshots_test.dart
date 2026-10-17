// Screenshots of Zincir Küpler's ferry line, puzzles and the match against
// Ekşi Limon in the real app, for review.
//   flutter test tool/stage5_screenshots_test.dart [SHOTS_EN=1 for English]
// Writes SHOTS_OUT (default build/stage5-shots/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_sim.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';

final String _out = Platform.environment['SHOTS_OUT'] ?? 'build/stage5-shots/';
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

/// Opens the app, the modes page and [mode] on it.
Future<Settings> _open(WidgetTester tester, String mode, {void Function(Settings)? setup}) async {
  tester.view.physicalSize = const Size(1100, 2390);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = Platform.environment['SHOTS_EN'] == '1' ? AppLanguage.en : AppLanguage.tr;
  setup?.call(settings);
  await tester.pumpWidget(RepaintBoundary(key: _root, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await _pump(tester, 20);
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  await _pump(tester, 10, 40);
  await tester.ensureVisible(find.byKey(ValueKey('mode-$mode'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(ValueKey('mode-$mode')));
  await _pump(tester, 15, 40);
  return settings;
}

ChainController _c(WidgetTester tester, Type screen) => (tester.state(find.byType(screen)) as dynamic).c as ChainController;

/// Some missions done, with stars.
void _progress(Settings s, int done) {
  for (var n = 1; n <= done; n++) {
    s.recordMission(n, const [3, 2, 3, 1, 2][n % 5]);
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the ferry line map', (tester) async {
    await _open(tester, 'chainMissions', setup: (s) => _progress(s, 12));
    await _pump(tester, 10);
    await _shot(tester, 'vapur-hatti.png');
  });

  testWidgets('a chain mission under way', (tester) async {
    await _open(tester, 'chainMissions', setup: (s) => _progress(s, 10));
    await tester.tap(find.byKey(const ValueKey('mission-11')));
    await _pump(tester, 20, 40);
    await _shot(tester, 'gorev-baslangic.png');
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await _pump(tester, 10);
    final c = _c(tester, ChainScreen);
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 33));
      if (i % 20 == 0 && c.game.settled) {
        final sim = ChainSim.of(c.game);
        for (final (x, y) in sim.swaps()) {
          final t = sim.copy()..swap(x, y);
          if (t.settle().cleared > 0) {
            c.game.swap(x, y);
            break;
          }
        }
      }
    }
    await _shot(tester, 'gorev.png');
  });

  testWidgets('the puzzle packs', (tester) async {
    await _open(tester, 'chainPuzzles', setup: (s) {
      for (var n = 1; n <= 26; n++) {
        s.recordPuzzle(n, n % 4 == 0 ? 2 : 3);
      }
    });
    await _shot(tester, 'bulmacalar.png');
  });

  testWidgets('a puzzle with its hint, then solved', (tester) async {
    await _open(tester, 'chainPuzzles', setup: (s) {
      for (var n = 1; n <= 30; n++) {
        s.recordPuzzle(n, 3);
      }
    });
    await tester.ensureVisible(find.byKey(const ValueKey('puzzle-31')));
    await tester.tap(find.byKey(const ValueKey('puzzle-31')));
    await _pump(tester, 20, 40);
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await _pump(tester, 20);
    await tester.tap(find.byKey(const ValueKey('puzzle-hint')));
    await _pump(tester, 20);
    await _shot(tester, 'bulmaca.png');
    final c = _c(tester, ChainScreen);
    for (var k = 0; k < 6 && !c.game.isOver; k++) {
      final move = ChainSim.of(c.game).solve(c.game.movesLeft);
      if (move == null || move.isEmpty) break;
      c.game.swap(move.first.$1, move.first.$2);
      for (var i = 0; i < 90 && !c.game.settled; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      await _pump(tester, 3);
    }
    await _pump(tester, 80);
    await _shot(tester, 'bulmaca-cozuldu.png');
  });

  testWidgets('the rival picker and a match', (tester) async {
    await _open(tester, 'chainVersus', setup: (s) => s.recordRivalWin(0));
    await _shot(tester, 'rakipler.png');
    await tester.tap(find.byKey(const ValueKey('versus-start')));
    await _pump(tester, 10);
    final c = _c(tester, ChainVersusScreen) as ChainVersusController;
    // The player makes the best swap now and then.
    for (var i = 0; i < 600; i++) {
      await tester.pump(const Duration(milliseconds: 33));
      if (i % 25 == 0 && c.game.settled) {
        final sim = ChainSim.of(c.game);
        (int, int)? best;
        var top = 0.0;
        for (final (x, y) in sim.swaps()) {
          final t = sim.copy()..swap(x, y);
          final v = chainMoveValue(sim, t, t.settle());
          if (v > top) {
            top = v;
            best = (x, y);
          }
        }
        if (best != null) c.game.swap(best.$1, best.$2);
      }
      if (c.game.isOver) break;
    }
    await _shot(tester, 'mac.png');
    if (!c.game.isOver) c.cpu.endMatch(won: false);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }
    await _shot(tester, 'set.png');
  });
}
