// Renders the store screenshots with the real game screens.
//   flutter test tool/store_screenshots_test.dart
// Writes ios/metadata/screenshots/<locale>/<device>-<nn>-<scene>.png at the
// exact pixel sizes App Store Connect asks for (iPhone 6.9", iPad 13"); the
// two-digit number keeps them in order (App Store Connect takes ten).
//   flutter test tool/store_screenshots_test.dart --dart-define=STORE=play
// writes the same scenes for Google Play to android/metadata/screenshots/:
// a 9:16 phone (Play takes at most 2:1) and 7" and 10" tablets.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_versus.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/game/tower/tower_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';
import 'package:lifeos_kupler/ui/tower_screen.dart';

import 'store_kit.dart';

const _play = String.fromEnvironment('STORE') == 'play';

/// Output folder (`SHOTS_OUT`).
final String _out = Platform.environment['SHOTS_OUT'] ?? (_play ? 'android/metadata/screenshots/' : 'ios/metadata/screenshots/');

/// App Store sizes: iPhone 6.9" (1320×2868 @3x) and iPad 13" (2064×2752 @2x);
/// Google Play: a 1080×1920 phone, a 7" and a 10" tablet.
const _devices = _play
    ? [('phone', Size(1080, 1920), 2.625), ('tablet7', Size(1200, 1920), 2.0), ('tablet10', Size(1600, 2560), 2.0)]
    : [('iphone', Size(1320, 2868), 3.0), ('ipad', Size(2064, 2752), 2.0)];

const _locales = [('tr', AppLanguage.tr), ('en-US', AppLanguage.en)];

final Map<String, StoreScene> _scenes = {
  // The home screen, Kule Küpler on the play card.
  'menu': (tester, settings) async {
    settings.lastPlay = 'towerClimb';
    settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
    await pumpFrames(tester, 30);
  },
  // Kule Küpler in the clouds: a perfect run, stars bursting off the top.
  'tower': (tester, settings) async {
    settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
    await startMode(tester, 'towerClimb');
    final c = (tester.state(find.byType(TowerScreen)) as dynamic).c as TowerController;
    buildTower(c, 124);
    for (var i = 0; i < 4; i++) {
      c.game.position = 0;
      c.tap();
      await pumpFrames(tester, i < 3 ? 14 : 4);
    }
    c.game.position = -0.9;
  },
  // İstanbul'u İnşa Et: Kız Kulesi rising.
  'build': (tester, settings) async {
    settings.recordTowerRun(mode: TowerMode.climb, floors: 1140, seconds: 3000);
    settings.claimLandmarks();
    await startMode(tester, 'towerBuild');
    await pumpFrames(tester, 30);
  },
  // Şeker Küpler mid-level: specials on the board, the rush meter filling.
  'sugar': (tester, settings) async {
    final c = (await sugarUpTo(tester, settings, 51))!;
    await sugarMoves(tester, c, 1);
    SugarPiece? at(int x, int y) => c.game.board[y][x];
    at(0, 1)?.special = Special.lineV;
    at(5, 6)?.special = Special.lineH;
    at(7, 3)?.special = Special.bomb;
    at(1, 6)?.special = Special.prism;
    c.game.rushMeter = 0.7;
    await pumpFrames(tester, 50);
  },
  // The final on Çamlıca: Ekşi Limon throwing lemon slices.
  'limon': (tester, settings) async {
    final c = (await sugarUpTo(tester, settings, 119))!;
    await sugarMoves(tester, c, 4);
    await pumpFrames(tester, 40);
  },
  // The games page: every game with its scene, its modes, the last played.
  'games': (tester, settings) async {
    settings.lastPlay = 'chainMissions';
    settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
    for (var n = 1; n <= 30; n++) {
      settings.recordSugarLevel(n, stars: 3, score: 15000, seconds: 60);
    }
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    await pumpFrames(tester, 30, 40);
  },
  // Bulmaca: two lines blasting at once in the jewel colours, a streak on.
  'puzzle': (tester, settings) async {
    await startMode(tester, 'blocksEndless');
    final c = blocksOf(tester);
    c.game.debugSetBoard(['.TTTTTTT', '.LLLLLLL', 'SS..ZZ..', 'J..IIII.', 'JJ.O..OO', '.....TT.', 'ZZ..SS..', '.JJ...L.']);
    c.game.debugSetTray(['dot', 'i2v', 'o2']);
    c.game.streak = 3;
    c.place(1, 0, 0);
    await pumpFrames(tester, 9);
  },
  // A match against Ekşi Limon: garbage crossing between the boards.
  'versus': (tester, settings) async {
    await startMode(tester, 'chainVersus');
    await tester.tap(find.byKey(const ValueKey('versus-start')));
    await pumpFrames(tester, 10);
    final c = (tester.state(find.byType(ChainVersusScreen)) as dynamic).c as ChainVersusController;
    for (var i = 0; i < 420; i++) {
      await tester.pump(const Duration(milliseconds: 33));
      if (i % 25 == 0 && c.game.settled) {
        final move = ChainCpu(ChainRival.master).pick(c.game);
        if (move != null) c.game.swap(move.$1, move.$2);
      }
      if (c.game.isOver) break;
    }
  },
  // Vapur Hattı: the missions along the Bosphorus piers.
  'ferry': (tester, settings) async {
    for (var n = 1; n <= 23; n++) {
      settings.recordMission(n, const [3, 2, 3, 3, 2][n % 5]);
    }
    await startMode(tester, 'chainMissions');
    await pumpFrames(tester, 10);
  },
  // A four-line clear caught mid-explosion.
  'tetris': (tester, settings) async {
    await startMode(tester, 'normal');
    final game = fallingGame(tester).game;
    tallStack(game);
    game.lines = 0;
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 2));
    await pumpFrames(tester, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await pumpFrames(tester, 7);
  },
};

/// The order on the store page.
const _order = ['menu', 'tower', 'build', 'sugar', 'limon', 'games', 'ferry', 'versus', 'puzzle', 'tetris'];

void main() {
  setUpAll(loadStoreFonts);
  assert(_order.length == _scenes.length && _order.every(_scenes.containsKey));

  for (final (device, size, dpr) in _devices) {
    for (final (locale, language) in _locales) {
      var n = 0;
      for (final name in _order) {
        final scene = _scenes[name]!;
        final index = ++n;
        testWidgets('$device $locale $name', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = dpr;
          addTearDown(tester.view.reset);
          final settings = Settings.memory()..language = language;
          await tester.pumpWidget(RepaintBoundary(key: storeRoot, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
          await pumpFrames(tester, 30);
          await scene(tester, settings);
          await storeShot(tester, '$_out$locale/$device-${index.toString().padLeft(2, '0')}-$name.png', dpr);
        });
      }
    }
  }
}
