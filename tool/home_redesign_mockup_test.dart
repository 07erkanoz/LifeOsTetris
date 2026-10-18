// Mock-up of the redesigned home screen: the six games up front. A big
// showcase that slides from game to game, every game as its own tile under
// it, and what the player was doing only after that.
//   flutter test tool/home_redesign_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): ana-ekran-yeni.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/tower/tower_landmarks.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show chainColors, paintChainCube;
import 'package:lifeos_kupler/game/render/block_sprites.dart';
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/game/tower/landmark_art.dart';
import 'package:lifeos_kupler/game/tower/tower_art.dart';

import 'mock_kit.dart';

const _edge = Color(0xFF15101F);
const _soft = Color(0xFFC9BFEA);
const _label = Color(0xFF9D93C2);
const _blocks = [Color(0xFF3B82F6), Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFA855F7), Color(0xFF06B6D4), Color(0xFFFACC15)];

void _icon(Canvas canvas, IconData icon, Offset c, double size, Color color) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'MaterialIcons', fontSize: size))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'MaterialIcons', fontSize: size))
    ..addText(String.fromCharCode(icon.codePoint));
  final p = b.build()..layout(ui.ParagraphConstraints(width: size * 2));
  canvas.drawParagraph(p, c - Offset(p.maxIntrinsicWidth / 2, p.height / 2));
}

void _t(Canvas canvas, String text, Offset at, double size, Color color, {double width = 300, FontWeight weight = FontWeight.w800, int lines = 1}) =>
    mockText(canvas, text, at, size, color, centre: false, width: width, weight: weight, lines: lines);

void _box(Canvas canvas, RRect r, {Color fill = const Color(0xFF3A3152), Color border = _edge, double width = 2.5, double depth = 4}) {
  canvas.drawRRect(r.shift(Offset(0, depth)), Paint()..color = _edge);
  canvas.drawRRect(r, Paint()..color = fill);
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = border);
}

void _chip(Canvas canvas, String text, Offset at, Color fill, {Color ink = Colors.white, double size = 10.5}) {
  final w = text.length * size * 0.64 + 14;
  final r = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, w, size + 8), Radius.circular(size));
  canvas.drawRRect(r.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawRRect(r, Paint()..color = fill);
  mockText(canvas, text, r.center + const Offset(0, 0.5), size, ink, width: w);
}

// ------------------------------------------------------------ the games

enum _G { tower, sugar, chain, puzzle, power, classic }

const _names = {
  _G.tower: 'Kule Küpler',
  _G.sugar: 'Şeker Küpler',
  _G.chain: 'Zincir Küpler',
  _G.puzzle: 'Bulmaca Küpler',
  _G.power: 'Süper Küpler',
  _G.classic: 'Klasik Küpler',
};

const _lines = {
  _G.tower: 'Katları diz, gökyüzüne uzan',
  _G.sugar: "Eşleştir, patlat, İstanbul'u gez",
  _G.chain: "Kaydır, zincir kur, Limon'u yen",
  _G.puzzle: 'Parçaları yerleştir, satır temizle',
  _G.power: 'Bombalar, matkaplar, süper güçler',
  _G.classic: 'Düşen bloklar, klasik kurallar',
};

/// What kind of game it is, in two words, on its tile.
const _kinds = {
  _G.tower: 'Kule diz',
  _G.sugar: 'Eşleştir · patlat',
  _G.chain: 'Zincir kur',
  _G.puzzle: 'Blok yerleştir',
  _G.power: 'Güçlü bloklar',
  _G.classic: 'Düşen bloklar',
};

const _tones = {
  _G.tower: [Color(0xFFFF9A4D), Color(0xFFD9481A)],
  _G.sugar: [Color(0xFFFF5FB8), Color(0xFFB8186E)],
  _G.chain: [Color(0xFF38BDF8), Color(0xFF1D5FD0)],
  _G.puzzle: [Color(0xFF34D399), Color(0xFF0B8A60)],
  _G.power: [Color(0xFFB46CFF), Color(0xFF6420D0)],
  _G.classic: [Color(0xFF5B6CFF), Color(0xFF2A3290)],
};

// ------------------------------------------------------------ scenes

/// The game itself, mid-play, filling [r]: what tells one game from the
/// others at a glance.
void _art(Canvas canvas, Rect r, _G g) {
  canvas.save();
  canvas.clipRect(r);
  final u = r.height / 196;
  switch (g) {
    case _G.tower:
      _towerArt(canvas, r, u);
    case _G.sugar:
      _sugarArt(canvas, r, u);
    case _G.chain:
      _chainArt(canvas, r, u);
    case _G.puzzle:
      _puzzleArt(canvas, r, u);
    case _G.power:
      _powerArt(canvas, r, u);
    case _G.classic:
      _classicArt(canvas, r, u);
  }
  canvas.restore();
}

void _sky(Canvas canvas, Rect r, List<Color> colors) =>
    canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]));

void _rays(Canvas canvas, Offset c, double len, Color color, {int n = 12, double turn = 0}) {
  final p = Paint()..color = color;
  for (var i = 0; i < n; i++) {
    final a = turn + i * 2 * pi / n;
    canvas.drawPath(Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx + cos(a - 0.09) * len, c.dy + sin(a - 0.09) * len)
      ..lineTo(c.dx + cos(a + 0.09) * len, c.dy + sin(a + 0.09) * len)
      ..close(), p);
  }
}

void _glow(Canvas canvas, Offset c, double radius, Color color) => canvas.drawCircle(c, radius, Paint()
  ..shader = ui.Gradient.radial(c, radius, [color, color.withValues(alpha: 0)]));

void _cloud(Canvas canvas, Offset c, double w, {double alpha = 0.9}) {
  final p = Paint()..color = Colors.white.withValues(alpha: alpha);
  canvas.drawOval(Rect.fromCenter(center: c, width: w, height: w * 0.32), p);
  canvas.drawCircle(c + Offset(-w * 0.14, -w * 0.12), w * 0.17, p);
  canvas.drawCircle(c + Offset(w * 0.1, -w * 0.15), w * 0.21, p);
}

void _speedLines(Canvas canvas, Offset from, double len, double gap, int n, Color color, {double width = 2.5}) {
  final p = Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < n; i++) {
    final y = from.dy + i * gap;
    final l = len * (i.isEven ? 1 : 0.6);
    canvas.drawLine(Offset(from.dx - l, y), Offset(from.dx, y), p);
  }
}

void _towerArt(Canvas canvas, Rect r, double u) {
  _sky(canvas, r, const [Color(0xFF5B5BE0), Color(0xFFFF8FB0), Color(0xFFFFC98A)]);
  _glow(canvas, Offset(r.left + 52 * u, r.top + 52 * u), 60 * u, const Color(0xAAFFF1B0));
  canvas.drawCircle(Offset(r.left + 52 * u, r.top + 52 * u), 20 * u, Paint()..color = const Color(0xFFFFF0B8));
  _cloud(canvas, Offset(r.right - 46 * u, r.top + 40 * u), 60 * u, alpha: 0.85);
  _cloud(canvas, Offset(r.left + 110 * u, r.top + 90 * u), 44 * u, alpha: 0.6);
  final horizon = r.bottom - 22 * u;
  canvas.save();
  canvas.translate(r.left, 0);
  paintSkyline(canvas, r.width, horizon, 110 * u, const Color(0xFF7A4A9A).withValues(alpha: 0.75));
  canvas.restore();
  paintBosphorus(canvas, Rect.fromLTWH(r.left, horizon, r.width, r.bottom - horizon), ferryAt: 0.75, tower: 0);
  paintLandmark(canvas, Landmark.galata, Offset(r.left + 40 * u, horizon + 2 * u), 0.3 * u);
  // The tower: lokum floors, a little crooked, and the next one coming in.
  final a = 30 * u, h = 14 * u;
  final base = Offset(r.center.dx + 14 * u, horizon + 2 * u);
  Offset at(int i) => base - Offset(0, (i + 1) * h) + towerU * (sin(i * 1.7) * 2.2 * u);
  for (var i = 0; i < 5; i++) {
    if (i > 0) paintFloorShadow(canvas, at(i), a, a, h);
    paintTowerFloor(canvas, at(i), a, a, h, flavor: i, seed: i);
  }
  final top = at(4);
  final fall = top - Offset(-24 * u, 40 * u);
  _speedLines(canvas, fall + Offset(-40 * u, -8 * u), 26 * u, 7 * u, 3, Colors.white.withValues(alpha: 0.8), width: 2.4 * u);
  paintTowerFloor(canvas, fall, a, a, h, flavor: 1, seed: 9);
  paintSparkle(canvas, top + Offset(-a * 1.1, -h * 0.4), 9 * u, Colors.white);
  paintSparkle(canvas, top + Offset(a * 1.25, -h * 0.9), 7 * u, const Color(0xFFFFE066));
  mockLabel(canvas, 'MÜKEMMEL!', Offset(r.right - 58 * u, r.top + 82 * u), 16 * u);
}

void _sugarArt(Canvas canvas, Rect r, double u) {
  _sky(canvas, r, const [Color(0xFF9B3DE8), Color(0xFF5A1592)]);
  _rays(canvas, Offset(r.center.dx + 30 * u, r.top + 84 * u), 260 * u, Colors.white.withValues(alpha: 0.06), n: 14);
  final s = 34 * u;
  const cols = 7, rows = 4;
  final o = Offset(r.center.dx + 30 * u - cols * s / 2, r.top + 18 * u);
  final board = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, cols * s, rows * s).inflate(5 * u), Radius.circular(12 * u));
  canvas.drawRRect(board, Paint()..color = const Color(0x553A0A6A));
  const colors = SugarColor.values;
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      final cell = Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(s * 0.05);
      final color = colors[(x * 2 + y * 3 + (x * y) % 2) % colors.length];
      if (y == 1 && x == 4) continue;
      if (y == 2 && x == 1) {
        paintStriped(canvas, cell, SugarColor.red, horizontal: true);
      } else if (y == 3 && x == 5) {
        paintWrapped(canvas, cell, SugarColor.blue);
      } else {
        paintCandy(canvas, cell, color);
      }
    }
  }
  // A match going off.
  final pop = Offset(o.dx + 4.5 * s, o.dy + 1.5 * s);
  _glow(canvas, pop, s * 1.4, const Color(0xCCFFF3A0));
  _rays(canvas, pop, s * 1.1, const Color(0x99FFFFFF), n: 10, turn: 0.2);
  paintSparkle(canvas, pop + Offset(-s * 0.7, -s * 0.5), s * 0.32, Colors.white);
  paintSparkle(canvas, pop + Offset(s * 0.8, s * 0.3), s * 0.26, const Color(0xFFFFE066));
  paintSparkle(canvas, pop + Offset(s * 0.1, s * 0.9), s * 0.2, const Color(0xFF9AF0FF));
  mockLabel(canvas, '+360', pop + Offset(0, -s * 0.15), s * 0.62);
  paintLokum(canvas, Offset(r.left + 40 * u, r.bottom - 38 * u), 62 * u, pose: LokumPose.cheer);
}

void _chainArt(Canvas canvas, Rect r, double u) {
  _sky(canvas, r, const [Color(0xFF2350C8), Color(0xFF101A52)]);
  _rays(canvas, Offset(r.center.dx + 50 * u, r.top + 40 * u), 280 * u, Colors.white.withValues(alpha: 0.05), n: 16);
  final s = 27 * u;
  const cols = 6, rows = 6;
  final o = Offset(r.center.dx + 64 * u - cols * s / 2, r.bottom - rows * s - 8 * u);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, cols * s, rows * s).inflate(5 * u), Radius.circular(10 * u)), Paint()..color = const Color(0x660A0E30));
  const board = ['......', '..M...', '.BMG..', 'GBMYB.', 'YGBMGY', 'MYGBYM'];
  const map = {'M': ChainColor.magenta, 'B': ChainColor.blue, 'G': ChainColor.green, 'Y': ChainColor.yellow};
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      final ch = board[y][x];
      if (ch == '.') continue;
      paintChainCube(canvas, Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(s * 0.04), chainColors[map[ch]!]!);
    }
  }
  // The three magenta cubes in a column light up: a chain.
  final col = Rect.fromLTWH(o.dx + 2 * s, o.dy + s, s, 3 * s).inflate(3 * u);
  canvas.drawRRect(RRect.fromRectAndRadius(col, Radius.circular(8 * u)), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3 * u
    ..color = Colors.white);
  _glow(canvas, col.center, s * 2, const Color(0x88FFFFFF));
  paintSparkle(canvas, col.topRight + Offset(4 * u, 2 * u), s * 0.36, const Color(0xFFFFE066));
  paintSparkle(canvas, col.centerLeft + Offset(-6 * u, 10 * u), s * 0.26, Colors.white);
  mockLabel(canvas, '×3 ZİNCİR!', Offset(r.center.dx + 64 * u, r.top + 24 * u), 18 * u);
  paintEksiLimon(canvas, Offset(r.left + 52 * u, r.center.dy + 14 * u), 70 * u);
  mockText(canvas, 'VS', Offset(r.left + 104 * u, r.center.dy - 30 * u), 18 * u, const Color(0xFFFFE066));
}

void _puzzleArt(Canvas canvas, Rect r, double u) {
  _sky(canvas, r, const [Color(0xFF1FC7A8), Color(0xFF0B5F74)]);
  _rays(canvas, Offset(r.center.dx, r.center.dy), 260 * u, Colors.white.withValues(alpha: 0.05), n: 14);
  const n = 8;
  final s = 20 * u;
  final o = Offset(r.center.dx - 40 * u - n * s / 2, r.top + (r.height - n * s) / 2);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, n * s, n * s).inflate(5 * u), Radius.circular(10 * u)), Paint()..color = const Color(0x66052A33));
  final slot = Paint()..color = Colors.white.withValues(alpha: 0.1);
  const filled = ['........', '....xx..', 'x...xx..', 'xx.xxxx.', 'xxxxxxxx', 'xx.xxx.x', 'x..xxxxx', 'xx.xxxxx'];
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final cell = Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s);
      canvas.drawRRect(RRect.fromRectAndRadius(cell.deflate(1.2 * u), Radius.circular(s * 0.2)), slot);
      if (filled[y][x] == 'x') paintToyBlock(canvas, cell.topLeft, s, y == 4 ? Colors.white : _blocks[(x + y * 3) % 6], _edge);
    }
  }
  // Row 4 is full: it clears.
  final row = Rect.fromLTWH(o.dx, o.dy + 4 * s, n * s, s);
  _glow(canvas, row.center, n * s * 0.6, const Color(0x99FFFFFF));
  paintSparkle(canvas, row.centerLeft + Offset(-4 * u, 0), s * 0.6, Colors.white);
  paintSparkle(canvas, row.centerRight + Offset(4 * u, 0), s * 0.6, const Color(0xFFFFE066));
  // A piece on its way in, from the tray.
  final p = Offset(o.dx + n * s + 22 * u, o.dy + 18 * u);
  const piece = [(0, 0), (0, 1), (0, 2), (1, 2)];
  for (final (dx, dy) in piece) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(p.dx + dx * s + 4 * u, p.dy + dy * s + 6 * u, s, s), Radius.circular(s * 0.2)), Paint()..color = Colors.black.withValues(alpha: 0.25));
  }
  for (final (dx, dy) in piece) {
    paintToyBlock(canvas, p + Offset(dx * s, dy * s), s, _blocks[2], _edge);
  }
  final hand = p + Offset(s * 1.6, s * 2.6);
  _icon(canvas, Icons.touch_app_rounded, hand, 30 * u, Colors.white);
  mockLabel(canvas, 'SATIR!', Offset(r.right - 46 * u, r.bottom - 34 * u), 16 * u);
}

void _powerArt(Canvas canvas, Rect r, double u) {
  _sky(canvas, r, const [Color(0xFFE04BD8), Color(0xFF5A1AB0), Color(0xFF240C5A)]);
  final s = 24 * u;
  final cols = (r.width / s).ceil();
  final x0 = r.center.dx - cols * s / 2;
  final floor = r.bottom - 4 * u;
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < cols; x++) {
      if (y == 2 && (x * 5 + 2) % 7 < 3) continue;
      paintToyBlock(canvas, Offset(x0 + x * s, floor - (y + 1) * s), s, _blocks[(x * 3 + y) % 7], _edge);
    }
  }
  // A bomb going off on the stack, a gem and a drill falling in.
  final bombAt = Offset(r.center.dx - 50 * u, floor - 3 * s);
  _glow(canvas, bombAt + Offset(s / 2, s / 2), s * 2.4, const Color(0xCCFFB347));
  _rays(canvas, bombAt + Offset(s / 2, s / 2), s * 2, const Color(0x99FFF3A0), n: 12, turn: 0.1);
  paintBomb(canvas, bombAt, s * 1.3);
  final drill = Offset(r.center.dx + 46 * u, r.top + 30 * u);
  final trail = Paint()
    ..color = Colors.white.withValues(alpha: 0.5)
    ..strokeWidth = 2.4 * u
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 3; i++) {
    final x = drill.dx + s * (0.3 + i * 0.35) * 1.2;
    canvas.drawLine(Offset(x, drill.dy - 22 * u), Offset(x, drill.dy - 6 * u), trail);
  }
  paintDrill(canvas, drill, s * 1.5);
  paintGem(canvas, Offset(r.right - 70 * u, r.top + 56 * u), s * 1.3, shadeTarget: _edge);
  paintSparkle(canvas, Offset(r.right - 30 * u, r.top + 40 * u), 9 * u, Colors.white);
  // The energy bar filling up.
  final bar = Rect.fromLTWH(r.left + 16 * u, r.top + 20 * u, 90 * u, 12 * u);
  mockProgress(canvas, bar, 0.8, colors: const [Color(0xFFFFF06A), Color(0xFFFF8A10)]);
  _icon(canvas, Icons.bolt_rounded, bar.centerRight + Offset(12 * u, 0), 22 * u, const Color(0xFFFFE066));
  mockLabel(canvas, 'SÜPER!', Offset(r.left + 64 * u, r.top + 64 * u), 20 * u);
}

void _classicArt(Canvas canvas, Rect r, double u) {
  _sky(canvas, r, const [Color(0xFF26307A), Color(0xFF0E1236)]);
  final s = 18 * u;
  const cols = 10;
  final x0 = r.center.dx - cols * s / 2, floor = r.bottom - 6 * u;
  final well = Rect.fromLTRB(x0, r.top - 4, x0 + cols * s, floor);
  canvas.drawRect(well, Paint()..color = const Color(0xFF0A0C26));
  final grid = Paint()
    ..color = Colors.white.withValues(alpha: 0.05)
    ..strokeWidth = 1;
  for (var x = 0; x <= cols; x++) {
    canvas.drawLine(Offset(x0 + x * s, well.top), Offset(x0 + x * s, floor), grid);
  }
  const stack = ['xx.xxx..xx', 'xxxxxxxxx.', 'xxxxxxxxx.', 'xxxxxxxxx.', 'xxxxxxxxx.'];
  for (var y = 0; y < stack.length; y++) {
    for (var x = 0; x < cols; x++) {
      if (stack[y][x] != 'x') continue;
      paintToyBlock(canvas, Offset(x0 + x * s, floor - (stack.length - y) * s), s, _blocks[(x * 2 + y) % 7], _edge);
    }
  }
  // The long piece drops into the gap: four lines at once.
  final gx = x0 + 9 * s;
  for (var i = 0; i < 4; i++) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gx, floor - (4 - i) * s, s, s).deflate(1.5), Radius.circular(3 * u)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * u
      ..color = Colors.white.withValues(alpha: 0.5));
  }
  final py = r.top + 14 * u;
  for (var i = 0; i < 4; i++) {
    paintToyBlock(canvas, Offset(gx, py + i * s), s, _blocks[5], _edge);
  }
  final trail = Paint()
    ..color = Colors.white.withValues(alpha: 0.45)
    ..strokeWidth = 2 * u
    ..strokeCap = StrokeCap.round;
  for (final dx in [0.25, 0.75]) {
    canvas.drawLine(Offset(gx + s * dx, py - 14 * u), Offset(gx + s * dx, py - 2 * u), trail);
  }
  mockLabel(canvas, '4 SATIR!', Offset(x0 - 2 * u, r.top + 40 * u), 17 * u);
  paintSparkle(canvas, Offset(gx + s * 1.8, py + s), 8 * u, const Color(0xFFFFE066));
}

// ------------------------------------------------------------ pieces of the screen

void _screen(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF34205A), Color(0xFF1C1236)]));
  final dot = Paint()..color = Colors.white.withValues(alpha: 0.035);
  for (var y = 10.0; y < size.height; y += 26) {
    for (var x = 10.0; x < size.width; x += 26) {
      canvas.drawCircle(Offset(x, y), 1.3, dot);
    }
  }
}

void _header(Canvas canvas) {
  paintLokum(canvas, const Offset(40, 78), 46);
  mockLabel(canvas, 'Lokum', const Offset(112, 70), 30);
  _t(canvas, '6 oyun · ücretsiz · reklamsız', const Offset(72, 88), 12.5, _soft, weight: FontWeight.w700);
  for (final (x, icon) in [(286.0, Icons.card_giftcard_rounded), (334.0, Icons.settings_rounded)]) {
    _box(canvas, RRect.fromRectAndRadius(Rect.fromLTWH(x, 56, 40, 40), const Radius.circular(13)), fill: const Color(0xFF4A3D6E), depth: 3);
    _icon(canvas, icon, Offset(x + 20, 76), 22, Colors.white);
  }
  canvas.drawCircle(const Offset(322, 58), 9, Paint()..color = const Color(0xFFF43F5E));
  mockText(canvas, '1', const Offset(322, 58), 11, Colors.white, width: 20);
}

/// The showcase card of [g]: the game large, its name, what it is, OYNA.
void _hero(Canvas canvas, Rect r, _G g, {String? tag, int index = 0}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(24));
  canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()..color = _edge);
  canvas.save();
  canvas.clipRRect(rr);
  final info = r.height * 0.34;
  final art = Rect.fromLTRB(r.left, r.top, r.right, r.bottom - info);
  _art(canvas, art, g);
  final band = Rect.fromLTRB(r.left, art.bottom, r.right, r.bottom);
  final tone = _tones[g]!;
  canvas.drawRect(band, Paint()..shader = ui.Gradient.linear(band.topLeft, band.bottomRight, tone));
  canvas.drawRect(Rect.fromLTWH(band.left, band.top, band.width, 3), Paint()..color = Colors.white.withValues(alpha: 0.35));
  final k = r.width / 326;
  _t(canvas, _names[g]!, Offset(band.left + 16 * k + 1.5, band.top + 10 * k + 2), 27 * k, Colors.black.withValues(alpha: 0.25), width: r.width);
  _t(canvas, _names[g]!, Offset(band.left + 16 * k, band.top + 10 * k), 27 * k, Colors.white, width: r.width);
  _t(canvas, _lines[g]!, Offset(band.left + 16 * k, band.top + 46 * k), 13 * k, Colors.white.withValues(alpha: 0.88), width: r.width - 140 * k, weight: FontWeight.w700, lines: 2);
  mockButton(canvas, Rect.fromLTWH(band.right - 112 * k, band.top + 20 * k, 98 * k, 46 * k), 'OYNA');
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white.withValues(alpha: 0.9));
  if (tag != null) _chip(canvas, tag, Offset(r.left + 12, r.top + 12), const Color(0xFFF43F5E), size: 11 * k);
  _chip(canvas, '${index + 1} / 6', Offset(r.right - 56 * k, r.top + 12), Colors.black.withValues(alpha: 0.4), size: 11 * k);
}

/// One game in the "all games" grid: the game, its name, what kind it is.
void _tile(Canvas canvas, Rect r, _G g, {String? tag, bool selected = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(18));
  canvas.drawRRect(rr.shift(const Offset(0, 4)), Paint()..color = _edge);
  canvas.save();
  canvas.clipRRect(rr);
  final art = Rect.fromLTRB(r.left, r.top, r.right, r.bottom - 42);
  _art(canvas, art, g);
  final band = Rect.fromLTRB(r.left, art.bottom, r.right, r.bottom);
  canvas.drawRect(band, Paint()..shader = ui.Gradient.linear(band.topLeft, band.bottomRight, _tones[g]!));
  _t(canvas, _names[g]!, Offset(band.left + 11, band.top + 3), 15.5, Colors.white, width: r.width - 20);
  _t(canvas, _kinds[g]!, Offset(band.left + 11, band.top + 22), 11, Colors.white.withValues(alpha: 0.85), width: r.width - 40, weight: FontWeight.w700);
  canvas.drawCircle(Offset(band.right - 18, band.center.dy), 12, Paint()..color = Colors.white.withValues(alpha: 0.25));
  _icon(canvas, Icons.play_arrow_rounded, Offset(band.right - 18, band.center.dy + 1), 20, Colors.white);
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = selected ? 3.5 : 2.5
    ..color = selected ? Colors.white : _edge);
  if (tag != null) _chip(canvas, tag, Offset(r.left + 8, r.top + 8), tag == 'YENİ' ? const Color(0xFFF43F5E) : const Color(0xFF16A34A), size: 9.5);
}

void _dots(Canvas canvas, double y, int active) {
  final games = _G.values;
  var x = 195 - (games.length - 1) * 8.0 - 9;
  for (var i = 0; i < games.length; i++) {
    final w = i == active ? 26.0 : 9.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, 9), const Radius.circular(5)), Paint()..color = i == active ? _tones[games[i]]![0] : Colors.white.withValues(alpha: 0.25));
    x += w + 7;
  }
}

void _row(Canvas canvas, Rect r, List<Color> colors, IconData icon, String title, String line, {String? button, void Function(Rect)? thumb}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(18));
  canvas.drawRRect(rr.shift(const Offset(0, 4)), Paint()..color = _edge);
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, colors));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = _edge);
  var x = r.left + 16;
  if (thumb != null) {
    final t = Rect.fromLTWH(r.left + 8, r.top + 8, r.height - 16, r.height - 16);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(t, const Radius.circular(12)));
    thumb(t);
    canvas.restore();
    x = t.right + 12;
  } else {
    _icon(canvas, icon, Offset(r.left + 30, r.center.dy), 26, Colors.white);
    x = r.left + 54;
  }
  _t(canvas, title, Offset(x, r.top + 11), 16, Colors.white, width: r.right - x - 100);
  _t(canvas, line, Offset(x, r.top + 33), 12.5, Colors.white.withValues(alpha: 0.82), width: r.right - x - 100, weight: FontWeight.w700);
  if (button != null) {
    final b = RRect.fromRectAndRadius(Rect.fromLTWH(r.right - 92, r.center.dy - 17, 80, 34), const Radius.circular(14));
    canvas.drawRRect(b.shift(const Offset(0, 3)), Paint()..color = const Color(0xFFB07A00));
    canvas.drawRRect(b, Paint()..color = const Color(0xFFFFC93C));
    mockText(canvas, button, b.center, 13, const Color(0xFF2A1A00), width: 80);
  } else {
    _icon(canvas, Icons.chevron_right_rounded, Offset(r.right - 24, r.center.dy), 28, Colors.white);
  }
}

/// The home screen, scrolled to the top, with [hero] in the showcase.
void _home(Canvas canvas, Size size, {_G hero = _G.tower, bool coach = false}) {
  _screen(canvas, size);
  _header(canvas);
  final i = hero.index;
  // The showcase: this game large, the next one peeking in on the right.
  _hero(canvas, const Rect.fromLTWH(352, 112, 326, 270), _G.values[(i + 1) % 6], index: i + 1);
  _hero(canvas, const Rect.fromLTWH(16, 112, 326, 270), hero, tag: hero == _G.tower ? 'YENİ OYUN' : null, index: i);
  _dots(canvas, 396, i);
  _t(canvas, 'TÜM OYUNLAR', const Offset(20, 414), 13, _label);
  _chip(canvas, '6', const Offset(118, 414), const Color(0xFF5A4C86), size: 10.5);
  for (var n = 0; n < 6; n++) {
    final g = _G.values[n];
    _tile(canvas, Rect.fromLTWH(16 + (n % 2) * 185.0, 440 + (n ~/ 2) * 122.0, 173, 110), g,
        tag: g == _G.tower ? 'YENİ' : (g == _G.sugar ? 'DEVAM' : null), selected: g == hero);
  }
  // Below the games: where the player was, the daily, the rest.
  _t(canvas, 'KALDIĞIN YERDEN', const Offset(20, 812), 13, _label);
  _row(canvas, const Rect.fromLTWH(16, 836, 358, 66), const [Color(0xFF4A3D6E), Color(0xFF3A2F5A)], Icons.history_rounded, 'Şeker Küpler', 'Seviye 12 · 54 yıldız',
      button: 'DEVAM', thumb: (t) => _art(canvas, t, _G.sugar));
  _row(canvas, const Rect.fromLTWH(16, 914, 358, 66), const [Color(0xFF14B8A6), Color(0xFF0E8A7E)], Icons.calendar_month_rounded, 'Günlük Görev', '18 Ekim bulmacası · 3 deneme');
  var x = 16.0;
  for (final (icon, name) in [(Icons.palette_rounded, 'Tema'), (Icons.card_giftcard_rounded, 'Koleksiyon'), (Icons.settings_rounded, 'Ayarlar'), (Icons.info_rounded, 'Hakkında')]) {
    _box(canvas, RRect.fromRectAndRadius(Rect.fromLTWH(x, 994, 82, 62), const Radius.circular(16)), fill: const Color(0xFF443867), depth: 3);
    _icon(canvas, icon, Offset(x + 41, 1016), 22, Colors.white);
    mockText(canvas, name, Offset(x + 41, 1042), 11.5, Colors.white, width: 82);
    x += 92;
  }
  if (coach) _coach(canvas, size);
}

/// Where the player left off, slim, right under the header: the game's
/// picture and colour, and DEVAM.
void _continueBar(Canvas canvas, Rect r, _G g, String title, String line) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(18));
  canvas.drawRRect(rr.shift(const Offset(0, 4)), Paint()..color = _edge);
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, _tones[g]!));
  final thumb = Rect.fromLTWH(r.left + 7, r.top + 7, r.height * 1.35, r.height - 14);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(thumb, const Radius.circular(12)));
  _art(canvas, thumb, g);
  canvas.restore();
  final x = thumb.right + 12;
  _icon(canvas, Icons.history_rounded, Offset(x + 7, r.top + 16), 14, Colors.white.withValues(alpha: 0.85));
  _t(canvas, 'KALDIĞIN YERDEN · $line', Offset(x + 17, r.top + 8), 11, Colors.white.withValues(alpha: 0.9), width: r.right - x - 110);
  _t(canvas, title, Offset(x, r.top + 25), 17, Colors.white, width: r.right - x - 100);
  final b = RRect.fromRectAndRadius(Rect.fromLTWH(r.right - 94, r.center.dy - 18, 82, 36), const Radius.circular(14));
  canvas.drawRRect(b.shift(const Offset(0, 3)), Paint()..color = const Color(0xFFB07A00));
  canvas.drawRRect(b, Paint()..color = const Color(0xFFFFC93C));
  canvas.drawRRect(b, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white);
  mockText(canvas, 'DEVAM ›', b.center, 13.5, const Color(0xFF2A1A00), width: 82);
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = Colors.white.withValues(alpha: 0.85));
}

/// The home screen with Devam at the top for a returning player ([back]),
/// or the showcase first for someone new.
void _homeTop(Canvas canvas, Size size, {required bool back}) {
  _screen(canvas, size);
  _header(canvas);
  var y = 108.0;
  if (back) {
    _continueBar(canvas, Rect.fromLTWH(16, y, 358, 60), _G.sugar, 'Şeker Küpler', 'Seviye 12');
    y += 74;
  }
  final h = back ? 236.0 : 270.0;
  _hero(canvas, Rect.fromLTWH(352, y, 326, h), _G.sugar, index: 1);
  _hero(canvas, Rect.fromLTWH(16, y, 326, h), _G.tower, tag: 'YENİ OYUN');
  y += h + 14;
  _dots(canvas, y, 0);
  y += 18;
  _t(canvas, 'TÜM OYUNLAR', Offset(20, y), 13, _label);
  _chip(canvas, '6', Offset(118, y), const Color(0xFF5A4C86), size: 10.5);
  y += 26;
  final th = back ? 102.0 : 110.0;
  for (var n = 0; n < 6; n++) {
    final g = _G.values[n];
    _tile(canvas, Rect.fromLTWH(16 + (n % 2) * 185.0, y + (n ~/ 2) * (th + 11), 173, th), g, tag: g == _G.tower ? 'YENİ' : (back && g == _G.sugar ? 'DEVAM' : null));
  }
  y += 3 * (th + 11) + 12;
  _row(canvas, Rect.fromLTWH(16, y, 358, 66), const [Color(0xFF14B8A6), Color(0xFF0E8A7E)], Icons.calendar_month_rounded, 'Günlük Görev', '18 Ekim bulmacası · 3 deneme');
}

void _continueSheet(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));
  const top = 150.0;
  const phones = [
    ('Oyuna dönen oyuncu', 'DEVAM en üstte, ince bir şerit: oyunun resmi, rengi, kaldığı seviye. Altında vitrin ve 6 oyun yine ekranda.', true),
    ('İlk kez açan oyuncu', 'Devam edecek bir şey yok: şerit hiç çıkmaz, ekran doğrudan vitrinle başlar.', false),
  ];
  for (var i = 0; i < phones.length; i++) {
    final (title, text, back) = phones[i];
    final left = 40 + i * 450.0;
    mockText(canvas, title, Offset(left + 195, 44), 26, Colors.white, width: 420);
    mockText(canvas, text, Offset(left + 195, 98), 14.5, _soft, width: 410, weight: FontWeight.w600, lines: 3);
    mockPhone(canvas, Rect.fromLTWH(left, top, 390, 844), (c, s) => _homeTop(c, s, back: back));
  }
}

/// The first time: Lokum says there are six games.
void _coach(Canvas canvas, Size size) {
  final shade = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 104, 382, 302), const Radius.circular(28)));
  canvas.drawPath(shade, Paint()..color = const Color(0xCC0E0820));
  final bubble = const Rect.fromLTWH(118, 444, 252, 92);
  mockBubble(canvas, bubble, 'Burada 6 farklı oyun var!\nKaydır ya da aşağıdan seç.', size: 15.5, up: true);
  paintLokum(canvas, const Offset(62, 512), 92, pose: LokumPose.point);
  // The swipe: a hand and an arrow across the showcase.
  final arrow = Paint()
    ..color = Colors.white
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(290, 236), const Offset(150, 236), arrow);
  canvas.drawPath(Path()
    ..moveTo(166, 222)
    ..lineTo(150, 236)
    ..lineTo(166, 250), arrow);
  _icon(canvas, Icons.swipe_left_rounded, const Offset(316, 252), 46, Colors.white);
  mockButton(canvas, const Rect.fromLTWH(110, 570, 170, 50), 'ANLADIM');
}

// ------------------------------------------------------------ the sheet

void _sheet(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));
  const top = 150.0;
  // 1 · The home screen, all of it (the dashed line is where a phone's
  // screen ends).
  mockText(canvas, '1 · Yeni ana ekran', const Offset(235, 44), 26, Colors.white, width: 440);
  mockText(canvas, 'İlk bakışta 6 oyun: üstte büyük vitrin, altında her oyun kendi resmiyle. Kaldığın yer ve görevler en altta.',
      const Offset(235, 96), 14.5, _soft, width: 420, weight: FontWeight.w600, lines: 3);
  mockPhone(canvas, const Rect.fromLTWH(40, top, 390, 1072), (c, s) => _home(c, s));
  final fold = Paint()
    ..color = const Color(0xFFFFE066)
    ..strokeWidth = 2;
  for (var x = 20.0; x < 450; x += 14) {
    canvas.drawLine(Offset(x, top + 844), Offset(x + 7, top + 844), fold);
  }
  mockText(canvas, 'Sarı kesik çizgi: telefon ekranının sonu. Aşağısı kaydırınca görünür.', const Offset(235, top + 1072 + 30), 13, const Color(0xFFFFE066), width: 420, weight: FontWeight.w700);

  // 2 · Every game's showcase card.
  const mx = 490.0;
  mockText(canvas, '2 · Vitrin: her oyun kendini gösterir', const Offset(mx + 220, 44), 26, Colors.white, width: 460);
  mockText(canvas, 'Vitrin 4 saniyede bir sonraki oyuna kendiliğinden kayar; parmakla da kaydırılır.',
      const Offset(mx + 220, 96), 14.5, _soft, width: 440, weight: FontWeight.w600, lines: 2);
  for (var n = 0; n < 6; n++) {
    _hero(canvas, Rect.fromLTWH(mx + (n % 2) * 228.0, top + (n ~/ 2) * 196.0, 212, 176), _G.values[n], index: n);
  }
  final notes = [
    (Icons.animation_rounded, 'Kartlar canlı', 'Kule\'de kat düşer, Şeker\'de şeker patlar, Zincir\'de zincir yanar: oyun kartın içinde oynar.'),
    (Icons.swipe_rounded, 'Kendiliğinden kayar', 'Vitrin 4 sn\'de bir sonraki oyuna geçer; yandaki kartın ucu hep görünür.'),
    (Icons.grid_view_rounded, 'Her oyun kendi rengi', 'Turuncu Kule, pembe Şeker, mavi Zincir, yeşil Bulmaca, mor Süper, lacivert Klasik.'),
    (Icons.touch_app_rounded, 'Tek dokunuş', 'OYNA hemen asıl modu açar; diğer modlar oyunun kendi sayfasında.'),
    (Icons.blur_off_rounded, 'Düşen blok arka planı kalkar', 'Arka plan sade; ilk izlenim "sadece blok oyunu" olmaz.'),
  ];
  var y = top + 3 * 196 + 10;
  for (final (icon, title, text) in notes) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(mx, y, 440, 78), const Radius.circular(16));
    canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.06));
    _icon(canvas, icon, Offset(mx + 30, y + 39), 28, const Color(0xFFFF8AD0));
    _t(canvas, title, Offset(mx + 58, y + 10), 16, Colors.white, width: 370);
    _t(canvas, text, Offset(mx + 58, y + 33), 12.5, _soft, width: 370, weight: FontWeight.w600, lines: 2);
    y += 88;
  }

  // 3 · The first time it opens.
  const rx = 990.0;
  mockText(canvas, '3 · İlk açılışta', Offset(rx + 195, 44), 26, Colors.white, width: 420);
  mockText(canvas, 'Bir kerelik: Lokum vitrini gösterir, "6 farklı oyun var" der. Vitrin Şeker Küpler\'e kaymış hali.',
      Offset(rx + 195, 96), 14.5, _soft, width: 400, weight: FontWeight.w600, lines: 3);
  mockPhone(canvas, const Rect.fromLTWH(rx, top, 390, 844), (c, s) => _home(c, s, hero: _G.sugar, coach: true));
}

Future<void> _iconFont() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf').readAsBytesSync())));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await mockFonts();
    await _iconFont();
  });

  testWidgets('home redesign', (tester) async {
    await mockSave(tester, const Size(1420, 150 + 1072 + 60), _sheet, 'ana-ekran-yeni.png', scale: 2);
  });

  testWidgets('continue on top', (tester) async {
    await mockSave(tester, const Size(40 * 2 + 390 * 2 + 60, 150 + 844 + 40), _continueSheet, 'ana-ekran-devam.png', scale: 2);
  });
}
