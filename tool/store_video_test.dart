// The frames of the store video (App Store app preview, the YouTube video
// for Google Play): about 28 seconds of the real game at 30 frames a second.
//   flutter test tool/store_video_test.dart --dart-define=VIDEO_DEVICE=iphone --dart-define=VIDEO_LOCALE=tr
// Writes build/video/<locale>-<device>/frame_NNNNN.png; .github/workflows/
// store-video.yml turns them into an MP4 with the game's music.
// iphone: 886×1920 (App Store, 6.5" and 6.9"); ipad: 1200×1600.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/app.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/chain/chain_versus.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_solver.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/core/tower/tower_game.dart';
import 'package:lifeos_kupler/core/tower/tower_landmarks.dart';
import 'package:lifeos_kupler/game/chain/chain_controller.dart';
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/game/tower/landmark_art.dart';
import 'package:lifeos_kupler/game/tower/tower_art.dart';
import 'package:lifeos_kupler/game/tower/tower_controller.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/settings/settings.dart';
import 'package:lifeos_kupler/ui/chain_screen.dart';
import 'package:lifeos_kupler/ui/tower_screen.dart';

import 'mock_kit.dart';
import 'store_kit.dart';

const _device = String.fromEnvironment('VIDEO_DEVICE', defaultValue: 'iphone');
const _locale = String.fromEnvironment('VIDEO_LOCALE', defaultValue: 'tr');

/// Pixels and the logical size they come from.
final (Size, double) _size = _device == 'ipad' ? (const Size(1200, 1600), 1.5625) : (const Size(886, 1920), 886 / 390);

const _frame = Duration(microseconds: 33333);
final String _dir = 'build/video/$_locale-$_device/';
var _n = 0;

/// Pumps one frame and keeps it.
Future<void> _record(WidgetTester tester, [int frames = 1]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(_frame);
    await storeShot(tester, '${_dir}frame_${(_n++).toString().padLeft(5, '0')}.png', _size.$2);
  }
}

Future<Settings> _app(WidgetTester tester) async {
  tester.view.physicalSize = _size.$1;
  tester.view.devicePixelRatio = _size.$2;
  addTearDown(tester.view.reset);
  final settings = Settings.memory()..language = _locale == 'tr' ? AppLanguage.tr : AppLanguage.en;
  settings.recordTowerRun(mode: TowerMode.climb, floors: 240, seconds: 600);
  settings.lastPlay = 'towerClimb';
  await tester.pumpWidget(RepaintBoundary(key: storeRoot, child: KuplerApp(settings: settings, audio: AudioService(enabled: false))));
  await pumpFrames(tester, 20);
  return settings;
}

/// The closing card: Lokum, the name, what it is.
class _EndCard extends CustomPainter {
  _EndCard(this.tagline, this.line);

  final String tagline, line;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    paintDusk(canvas, r);
    final horizon = size.height * 0.82;
    paintSkyline(canvas, size.width, horizon, size.height * 0.5, const Color(0xFF4A2A6A));
    paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height - horizon), ferryAt: 0.1, tower: 0);
    final k = size.width / 390;
    paintLandmark(canvas, Landmark.maidens, Offset(size.width * 0.8, horizon + 6), 0.55 * k);
    final h = 20 * k, a = 38 * k;
    final base = Offset(size.width * 0.3, horizon + 4);
    for (var i = 0; i < 8; i++) {
      final c = base - Offset(0, (i + 1) * h) + towerU * (sin(i * 1.3) * 2 * k);
      if (i > 0) paintFloorShadow(canvas, c, a, a, h);
      paintTowerFloor(canvas, c, a, a, h, flavor: i, seed: i);
    }
    paintLokum(canvas, Offset(size.width / 2, size.height * 0.26), 150 * k, pose: LokumPose.cheer);
    mockLabel(canvas, 'Lokum', Offset(size.width / 2, size.height * 0.4), 84 * k);
    mockText(canvas, tagline, Offset(size.width / 2, size.height * 0.47), 26 * k, Colors.white, width: size.width);
    mockText(canvas, line, Offset(size.width / 2, size.height * 0.52), 17 * k, const Color(0xFFFFE6F0), width: size.width, weight: FontWeight.w600);
  }

  @override
  bool shouldRepaint(_EndCard old) => false;
}

void main() {
  setUpAll(() async {
    await loadStoreFonts();
    await mockFonts();
    final dir = Directory(_dir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  // 2 s: the home screen, Kule Küpler on the play card.
  testWidgets('home', (tester) async {
    await _app(tester);
    await _record(tester, 60);
  });

  // 1.5 s: the games page.
  testWidgets('games', (tester) async {
    await _app(tester);
    await tester.tap(find.byKey(const ValueKey('change-mode')));
    await _record(tester, 45);
  });

  // 8 s: the climb: perfect drops in a row, a cut, the chest at floor 50.
  testWidgets('tower', (tester) async {
    final settings = await _app(tester);
    await startMode(tester, 'towerClimb');
    final c = (tester.state(find.byType(TowerScreen)) as dynamic).c as TowerController;
    buildTower(c, 44);
    c.camera = c.game.height - 5.5;
    var drops = 0, chest = 0;
    var last = c.game.position;
    for (var f = 0; f < 240; f++) {
      if (c.chestAt != null && find.byKey(const ValueKey('gift-collect')).evaluate().isNotEmpty && ++chest == 36) {
        await tester.tap(find.byKey(const ValueKey('gift-collect')));
        chest = 0;
      }
      final p = c.game.position;
      if (c.playing && c.chestAt == null && last.sign != p.sign) {
        // Right on, mostly; now and then a little off, for the cut.
        c.game.position = drops % 5 == 3 ? 0.28 : 0;
        c.tap();
        drops++;
        // The next floor comes in from closer by: a brisk climb.
        c.game.position = -0.75;
      }
      last = c.game.position;
      await _record(tester);
    }
    expect(settings.towerBest(TowerMode.climb), greaterThanOrEqualTo(0));
  });

  // 2.5 s: İstanbul'u İnşa Et.
  testWidgets('build', (tester) async {
    final settings = await _app(tester);
    settings.recordTowerRun(mode: TowerMode.climb, floors: 900, seconds: 3000);
    settings.claimLandmarks();
    await startMode(tester, 'towerBuild');
    await _record(tester, 75);
  });

  // 5 s: Şeker Küpler, specials going off.
  testWidgets('sugar', (tester) async {
    final settings = await _app(tester);
    final c = (await sugarUpTo(tester, settings, 51))!;
    SugarPiece? at(int x, int y) => c.game.board[y][x];
    at(0, 1)?.special = Special.lineV;
    at(5, 6)?.special = Special.lineH;
    at(7, 3)?.special = Special.bomb;
    var wait = 12;
    for (var f = 0; f < 150; f++) {
      if (!c.busy && c.game.status == SugarStatus.idle && --wait <= 0) {
        final m = SugarSolver.best(c.game);
        if (m != null) c.trySwap(m.$1, m.$2);
        wait = 14;
      }
      await _record(tester);
    }
  });

  // 3.5 s: Zincir Küpler, a full board, chains going off.
  testWidgets('chain', (tester) async {
    final settings = await _app(tester);
    settings.chainDifficulty = ChainDifficulty.normal;
    await startMode(tester, 'chainEndless');
    await tester.tap(find.byKey(const ValueKey('chain-start')));
    await pumpFrames(tester, 8);
    final c = (tester.state(find.byType(ChainScreen)) as dynamic).c as ChainController;
    c.game.debugSetBoard([
      '......',
      '......',
      '......',
      '......',
      'G..Y..',
      'BBGY.M',
      'GMYMBM',
      'GYMBGB',
      'MBGYMY',
      'YGBMBG',
      'BMYGYM',
      'GYBMGB',
    ]);
    c.game.stopTime = 100;
    c.game.score = 1480;
    final cpu = ChainCpu(ChainRival.master);
    var wait = 6;
    for (var f = 0; f < 105; f++) {
      if (c.game.settled && --wait <= 0) {
        final move = cpu.pick(c.game);
        if (move != null) c.game.swap(move.$1, move.$2);
        wait = 9;
      }
      await _record(tester);
    }
  });

  // 3 s: Klasik Küpler, a four-line clear.
  testWidgets('tetris', (tester) async {
    await _app(tester);
    await startMode(tester, 'normal');
    final game = fallingGame(tester).game;
    tallStack(game);
    game.lines = 0;
    game.debugSetActive(const Piece(PieceType.i, Rotation.right, 7, 2));
    await _record(tester, 10);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _record(tester, 55);
  });

  // 1.5 s: the closing card.
  testWidgets('end', (tester) async {
    tester.view.physicalSize = _size.$1;
    tester.view.devicePixelRatio = _size.$2;
    addTearDown(tester.view.reset);
    final tr = _locale == 'tr';
    await tester.pumpWidget(RepaintBoundary(
      key: storeRoot,
      child: CustomPaint(
        size: Size.infinite,
        painter: _EndCard(tr ? 'Şeker ve Blok Oyunları' : 'Sweets & Block Games', tr ? 'Ücretsiz · Reklamsız · İnternetsiz oynanır' : 'Free · No ads · Plays offline'),
      ),
    ));
    await _record(tester, 45);
  });
}
