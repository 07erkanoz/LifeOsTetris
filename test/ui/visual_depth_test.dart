import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/game/render/block_sprites.dart';
import 'package:lifeos_kupler/game/render/board_painter.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/theme/palette.dart';
import 'package:lifeos_kupler/ui/game_screen.dart';
import 'package:lifeos_kupler/ui/widgets.dart';

/// Average brightness (0..255) of the opaque pixels in the top [share] of
/// the block inside [image] (the sprite pads the block by 45% of a cell).
Future<double> topBrightness(WidgetTester tester, ui.Image image, {double share = 0.2}) async {
  final data = (await tester.runAsync(() => image.toByteData()))!;
  final w = image.width;
  final cell = w / 1.9;
  final pad = (w - cell) / 2;
  var sum = 0.0, n = 0;
  for (var y = pad.round(); y < (pad + cell * share).round(); y++) {
    for (var x = (pad + cell * 0.3).round(); x < (pad + cell * 0.7).round(); x++) {
      final i = (y * w + x) * 4;
      if (data.getUint8(i + 3) < 200) continue;
      sum += (data.getUint8(i) + data.getUint8(i + 1) + data.getUint8(i + 2)) / 3;
      n++;
    }
  }
  return n == 0 ? 0 : sum / n;
}

Future<GameController> playNormal(WidgetTester tester, VisualTheme theme) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()
    ..language = AppLanguage.tr
    ..visualTheme = theme;
  await tester.pumpWidget(KuplerApp(settings: settings, audio: AudioService(enabled: false)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byKey(const ValueKey('change-mode')));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
  await tester.ensureVisible(find.byKey(const ValueKey('game-classic'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(const ValueKey('game-classic')));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
  await tester.ensureVisible(find.byKey(const ValueKey('mode-normal'), skipOffstage: false));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.byKey(const ValueKey('mode-normal')));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
  return (tester.state(find.byType(GameScreen)) as dynamic).controller as GameController;
}

void main() {
  testWidgets('a block under another is darker at the top (contact shadow)', (tester) async {
    for (final palette in [GamePalette.toyDark, GamePalette.pixelDark, GamePalette.glassDark]) {
      final sprites = BlockSprites.of(40, 1, palette);
      final plain = await topBrightness(tester, sprites.block(PieceType.o));
      final shaded = await topBrightness(tester, sprites.shaded(PieceType.o));
      expect(shaded, lessThan(plain - 4), reason: palette.skin.name);
    }
  });

  test('the neon look is on only for the dark glass skin', () {
    expect(isNeon(GamePalette.glassDark), isTrue);
    expect(isNeon(GamePalette.glassLight), isFalse);
    expect(isNeon(GamePalette.toyDark), isFalse);
    expect(isNeon(GamePalette.pixelDark), isFalse);
    neonStyle = false;
    addTearDown(() => neonStyle = true);
    expect(isNeon(GamePalette.glassDark), isFalse);
  });

  testWidgets('neon jelly cubes come in bubble patterns, other skins in one look', (tester) async {
    final neon = BlockSprites.of(36, 1, GamePalette.glassDark);
    expect(neon.variants, 3);
    expect(identical(neon.block(PieceType.t, 1), neon.block(PieceType.t, 0)), isFalse);
    expect(identical(neon.block(PieceType.t, 3), neon.block(PieceType.t, 0)), isTrue, reason: 'variants wrap around');
    expect(identical(neon.shaded(PieceType.t, 2), neon.shaded(PieceType.t, 0)), isFalse);
    expect(identical(neon.block(PieceType.bomb, 1), neon.block(PieceType.bomb, 0)), isTrue, reason: 'no bubbles in bombs');
    final toy = BlockSprites.of(36, 1, GamePalette.toyDark);
    expect(toy.variants, 1);
    expect(identical(toy.block(PieceType.t, 2), toy.block(PieceType.t, 0)), isTrue);
    expect(BlockSprites.variantAt(3, 5), inInclusiveRange(0, 2));
  });

  for (final theme in VisualTheme.values) {
    testWidgets('${theme.name}: a holey stack draws with and without depth', (tester) async {
      addTearDown(() => BoardPainter.depth = true);
      final c = await playNormal(tester, theme);
      c.game.debugSetBoard([
        '..TTT.....',
        'ZZ.T..OO.I',
        '.ZZ.LLL..I',
        'J...L.SS.I',
        'JJJ..SS..I',
        'IIII.OOTTT',
      ]);
      for (final on in [false, true]) {
        BoardPainter.depth = on;
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('neon controls draw pressed and released, panels build', (tester) async {
    final c = await playNormal(tester, VisualTheme.neon);
    expect(find.byType(ControlButton), findsWidgets);
    expect(find.byType(GlassCard), findsWidgets);
    final key = find.byType(ControlButton).first;
    final gesture = await tester.startGesture(tester.getCenter(key));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.game.paused, isTrue);
    expect(tester.takeException(), isNull);
  });
}
