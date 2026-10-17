// Mock-ups, second round: a game's own page with its flagship mode up top
// and every mode shown by a scene of its own (Zincir Küpler, Klasik Küpler),
// and the new tower game, Kule Küpler, in near-3D.
//   flutter test tool/games_pages_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): oyun-sayfalari-2.png,
// kule-kupler.png, kule-dusus.png, kule-tirmanis.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show chainColors, paintChainCube, paintGarbageSlab;
import 'package:lifeos_kupler/game/render/block_sprites.dart';
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/ui/gift_art.dart' show chestGold, paintChest;

import 'mock_kit.dart';

const _bg = Color(0xFF2A2340);
const _card = Color(0xFF3A3152);
const _edge = Color(0xFF15101F);
const _text = Colors.white;
const _soft = Color(0xFFB8AEDA);
const _label = Color(0xFF8F86B0);
const _accent = Color(0xFFFF5FB8);
const _gold = Color(0xFFFACC15);
const _newRed = Color(0xFFF43F5E);
const _chipFill = Color(0xFF4F4572);

const _blocks = [Color(0xFF3B82F6), Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFA855F7), Color(0xFF06B6D4), Color(0xFFFACC15)];

// Lokum flavours for the tower floors: rose, pistachio, lemon, lavender,
// orange, mint.
const _lokum = [Color(0xFFFF8FB8), Color(0xFF9ED96B), Color(0xFFFFDA6A), Color(0xFFBFA2FF), Color(0xFFFFAA5E), Color(0xFF7FDCC4)];

// ------------------------------------------------------------ basics

void _icon(Canvas canvas, IconData icon, Offset c, double size, Color color) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'MaterialIcons', fontSize: size))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'MaterialIcons', fontSize: size))
    ..addText(String.fromCharCode(icon.codePoint));
  final p = b.build()..layout(ui.ParagraphConstraints(width: size * 2));
  canvas.drawParagraph(p, c - Offset(p.maxIntrinsicWidth / 2, p.height / 2));
}

void _t(Canvas canvas, String text, Offset at, double size, Color color, {double width = 300, FontWeight weight = FontWeight.w800, int lines = 1}) =>
    mockText(canvas, text, at, size, color, centre: false, width: width, weight: weight, lines: lines);

void _box(Canvas canvas, RRect r, {Color fill = _card, Color border = _edge, double width = 2.5, double depth = 4}) {
  canvas.drawRRect(r.shift(Offset(0, depth)), Paint()..color = _edge);
  canvas.drawRRect(r, Paint()..color = fill);
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = border);
}

double _chip(Canvas canvas, String text, Offset at, Color fill, {Color ink = Colors.white, double size = 10.5, IconData? icon}) {
  final w = text.length * size * 0.6 + 14 + (icon == null ? 0 : size + 3);
  final r = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, w, size + 8), Radius.circular(size));
  canvas.drawRRect(r, Paint()..color = fill);
  if (icon != null) _icon(canvas, icon, Offset(at.dx + 7 + size / 2, r.center.dy), size + 1, ink);
  mockText(canvas, text, r.center + Offset(icon == null ? 0 : (size + 3) / 2, 0.5), size, ink, width: w);
  return w;
}

void _screen(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
  final dot = Paint()..color = Colors.white.withValues(alpha: 0.035);
  for (var y = 10.0; y < size.height; y += 26) {
    for (var x = 10.0; x < size.width; x += 26) {
      canvas.drawCircle(Offset(x, y), 1.3, dot);
    }
  }
}

void _header(Canvas canvas, String title, {String? chip}) {
  _box(canvas, RRect.fromRectAndRadius(const Rect.fromLTWH(16, 54, 42, 42), const Radius.circular(13)), fill: const Color(0xFF4A4068), depth: 3);
  _icon(canvas, Icons.arrow_back_rounded, const Offset(37, 75), 22, _text);
  _t(canvas, title, const Offset(72, 56), 27, _text);
  if (chip != null) _chip(canvas, chip, const Offset(312, 66), _chipFill, size: 11.5, icon: Icons.grid_view_rounded);
}

void _sectionLabel(Canvas canvas, String text, double y) => _t(canvas, text, Offset(20, y), 12.5, _label);

/// Clips to [r] (rounded), runs [paint] in it, and outlines it.
void _framed(Canvas canvas, Rect r, void Function(Rect r) paint, {double radius = 14}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
  canvas.save();
  canvas.clipRRect(rr);
  paint(r);
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = _edge);
}

void _well(Canvas canvas, Rect r, {List<Color> colors = const [Color(0xFF221B36), Color(0xFF120E1E)]}) =>
    canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors));

void _progress(Canvas canvas, Rect r, double v, List<Color> colors) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
  canvas.drawRRect(rr, Paint()..color = const Color(0xFF241D38));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, max(r.height, r.width * v), r.height), Radius.circular(r.height / 2)),
      Paint()..shader = ui.Gradient.linear(r.topLeft, r.topRight, colors));
}

void _playButton(Canvas canvas, Rect r, String label, {List<Color> colors = const [Color(0xFF6BF0A0), Color(0xFF1FB85A)], Color shade = const Color(0xFF0E6A32)}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.42));
  canvas.drawRRect(rr.shift(const Offset(0, 4)), Paint()..color = shade);
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = _edge);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 10, r.top + 4, r.width - 20, r.height * 0.26), Radius.circular(r.height)), Paint()..color = Colors.white.withValues(alpha: 0.3));
  mockLabel(canvas, label, r.center, r.height * 0.44, colors: const [Colors.white, Colors.white], outline: shade);
}

void _stars(Canvas canvas, Offset at, int got, {double r = 7}) {
  for (var i = 0; i < 3; i++) {
    paintGoldStar(canvas, at + Offset(i * r * 2.3, 0), r, on: i < got);
  }
}

// ------------------------------------------------------------ cards

/// The flagship mode of a game: a large scene, its name, where you are and a
/// button.
void _featured(Canvas canvas, double top, void Function(Rect r) scene, String tag, String title, String line, double progress, String progressText, String button,
    {List<Color> tone = const [Color(0xFFFF9AD8), Color(0xFFE0247A)]}) {
  final r = Rect.fromLTWH(16, top, 358, 262);
  _box(canvas, RRect.fromRectAndRadius(r, const Radius.circular(24)), border: _accent, width: 3);
  _framed(canvas, Rect.fromLTWH(r.left + 10, r.top + 10, r.width - 20, 150), scene, radius: 17);
  _chip(canvas, tag, Offset(r.left + 20, r.top + 20), const Color(0xE61A1330), ink: _gold, size: 11, icon: Icons.star_rounded);
  _t(canvas, title, Offset(r.left + 16, r.top + 168), 23, _text, width: 330);
  _t(canvas, line, Offset(r.left + 16, r.top + 198), 12.5, _soft, width: 330, weight: FontWeight.w600);
  _progress(canvas, Rect.fromLTWH(r.left + 16, r.top + 228, 150, 10), progress, tone);
  _t(canvas, progressText, Offset(r.left + 174, r.top + 222), 12, _text, width: 100);
  _playButton(canvas, Rect.fromLTWH(r.right - 112, r.top + 214, 98, 36), button);
}

/// A mode card with its own scene on top.
void _sceneCard(Canvas canvas, Rect r, void Function(Rect r) scene, String title, String line, String? record, {bool isNew = false, IconData recordIcon = Icons.emoji_events_rounded}) {
  _box(canvas, RRect.fromRectAndRadius(r, const Radius.circular(20)));
  _framed(canvas, Rect.fromLTWH(r.left + 8, r.top + 8, r.width - 16, 96), scene);
  if (isNew) _chip(canvas, 'YENİ', Offset(r.right - 54, r.top + 14), _newRed, size: 10);
  _t(canvas, title, Offset(r.left + 12, r.top + 110), 16.5, _text, width: r.width - 20);
  _t(canvas, line, Offset(r.left + 12, r.top + 133), 11.5, _soft, width: r.width - 22, weight: FontWeight.w600, lines: 2);
  _icon(canvas, recordIcon, Offset(r.left + 19, r.bottom - 15), 14, record == null ? _label : _gold);
  _t(canvas, record ?? 'Henüz oynanmadı', Offset(r.left + 29, r.bottom - 24), 12, record == null ? _label : _text, width: r.width - 40);
}

/// A compact mode row: scene on the left, name and line, record on the right.
void _sceneRow(Canvas canvas, double top, void Function(Rect r) scene, String title, String line, String? record, {bool isNew = false}) {
  final r = Rect.fromLTWH(16, top, 358, 76);
  _box(canvas, RRect.fromRectAndRadius(r, const Radius.circular(18)));
  _framed(canvas, Rect.fromLTWH(r.left + 7, r.top + 7, 104, r.height - 14), scene, radius: 12);
  _t(canvas, title, Offset(r.left + 122, r.top + 12), 16, _text, width: 160);
  _t(canvas, line, Offset(r.left + 122, r.top + 35), 11.5, _soft, width: 170, weight: FontWeight.w600, lines: 2);
  if (isNew) _chip(canvas, 'YENİ', Offset(r.right - 52, r.top + 10), _newRed, size: 9.5);
  if (record != null) {
    _icon(canvas, Icons.emoji_events_rounded, Offset(r.right - 62, r.bottom - 17), 13, _gold);
    _t(canvas, record, Offset(r.right - 53, r.bottom - 25), 11.5, _text, width: 60);
  } else {
    _icon(canvas, Icons.chevron_right_rounded, Offset(r.right - 18, r.center.dy + 6), 26, _soft);
  }
}

// ------------------------------------------------------------ scenes: chain

const _chainRows = ['mbgyob', 'ygomby', 'bomgyb', 'gymbog', 'obygmy'];
const _chainCodes = {'y': ChainColor.yellow, 'm': ChainColor.magenta, 'b': ChainColor.blue, 'g': ChainColor.green, 'o': ChainColor.orange};

void _chainBoard(Canvas canvas, Rect r, int rows, {int cols = 6, Set<(int, int)> holes = const {}, int shift = 0}) {
  final s = min(r.width / cols, r.height / rows);
  final x0 = r.left + (r.width - cols * s) / 2;
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      if (holes.contains((x, y))) continue;
      final code = _chainRows[(y + shift) % _chainRows.length][(x + shift) % 6];
      paintChainCube(canvas, Rect.fromLTWH(x0 + x * s, r.bottom - (y + 1) * s, s, s).deflate(s * 0.04), chainColors[_chainCodes[code]]!);
    }
  }
}


void _paintFerry(Canvas canvas, Rect r) {
  canvas.save();
  canvas.translate(r.left, r.top);
  final size = r.size;
  paintDusk(canvas, Offset.zero & size);
  final horizon = size.height * 0.5;
  paintSkyline(canvas, size.width, horizon, size.height, const Color(0xFF3A1E5A));
  paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height - horizon), ferryAt: 0.97);
  paintGulls(canvas, [Offset(size.width * 0.7, size.height * 0.2), Offset(size.width * 0.78, size.height * 0.26)], const Color(0xFF3A1E5A));
  // The ferry line: piers along the shore, done ones gold.
  final pts = [for (var i = 0; i < 6; i++) Offset(size.width * (0.08 + i * 0.168), size.height * (0.86 - (i.isOdd ? 0.1 : 0)))];
  final dash = Paint()
    ..color = Colors.white.withValues(alpha: 0.75)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < pts.length - 1; i++) {
    for (var k = 0.0; k < 1; k += 0.18) {
      canvas.drawLine(Offset.lerp(pts[i], pts[i + 1], k)!, Offset.lerp(pts[i], pts[i + 1], k + 0.08)!, dash);
    }
  }
  const names = ['Eminönü', 'Karaköy', 'Beşiktaş', 'Ortaköy', 'Bebek', 'Sarıyer'];
  for (var i = 0; i < pts.length; i++) {
    final done = i < 4, current = i == 4;
    if (current) canvas.drawCircle(pts[i], 13, Paint()..color = _accent.withValues(alpha: 0.35));
    canvas.drawCircle(pts[i], 8, Paint()..color = done ? _gold : (current ? _accent : const Color(0xFF6B5F92)));
    canvas.drawCircle(pts[i], 8, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _edge);
    if (done || current) mockText(canvas, names[i], pts[i] - const Offset(0, 17), 9.5, Colors.white, width: 70);
  }
  canvas.restore();
}

void Function(Rect) _ferry(Canvas canvas) => (r) => _paintFerry(canvas, r);

void Function(Rect) _versus(Canvas canvas) => (r) {
      _well(canvas, r, colors: const [Color(0xFF3A2160), Color(0xFF1A1030)]);
      final w = r.width * 0.36;
      _chainBoard(canvas, Rect.fromLTWH(r.left + 6, r.top + 26, w, r.height - 30), 4, cols: 4, holes: {(1, 3), (2, 3), (3, 2)});
      _chainBoard(canvas, Rect.fromLTWH(r.right - w - 6, r.top + 26, w, r.height - 30), 4, cols: 4, holes: {(0, 3)}, shift: 2);
      paintGarbageSlab(canvas, Rect.fromLTWH(r.right - w - 6, r.top + 14, w, 14));
      paintEksiLimon(canvas, Offset(r.center.dx, r.top + r.height * 0.42), r.height * 0.42);
      paintSugarLabel(canvas, 'VS', Offset(r.center.dx, r.bottom - 16), 18,
          Paint()..shader = ui.Gradient.linear(Offset(0, r.bottom - 26), Offset(0, r.bottom - 6), const [Color(0xFFFFF6B0), Color(0xFFFF8A10)]),
          outline: const Color(0xFF3A0F2A), stroke: 0.2);
    };

void Function(Rect) _chainPuzzle(Canvas canvas) => (r) {
      _well(canvas, r);
      final b = Rect.fromLTWH(r.left + 8, r.top + 22, r.width - 16, r.height - 24);
      _chainBoard(canvas, b, 3, holes: {(0, 2), (1, 2), (4, 2), (5, 2), (5, 1)}, shift: 1);
      final s = min(b.width / 6, b.height / 3);
      final x0 = b.left + (b.width - 6 * s) / 2;
      final hint = Rect.fromLTWH(x0 + 2 * s, b.bottom - 2 * s, 2 * s, s).inflate(2);
      canvas.drawRRect(RRect.fromRectAndRadius(hint, const Radius.circular(8)), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFF3A0));
      _icon(canvas, Icons.swap_horiz_rounded, hint.center, 22, Colors.white);
      _chip(canvas, '3 hamle', Offset(r.left + 8, r.top + 6), const Color(0xE61A1330), ink: _text, size: 10);
    };

void Function(Rect) _chainEndless(Canvas canvas) => (r) {
      _well(canvas, r);
      _chainBoard(canvas, Rect.fromLTWH(r.left + 4, r.top + 18, r.width - 8, r.height - 18), 4, holes: {(1, 3), (4, 3)});
      paintSugarLabel(canvas, '×3', Offset(r.center.dx, r.top + 18), 22,
          Paint()..shader = ui.Gradient.linear(Offset(0, r.top + 6), Offset(0, r.top + 30), const [Color(0xFFFFF6B0), Color(0xFFFF8A10)]),
          outline: const Color(0xFF3A0F2A), stroke: 0.2);
    };

void Function(Rect) _chainTime(Canvas canvas) => (r) {
      _well(canvas, r);
      _chainBoard(canvas, Rect.fromLTWH(r.left + 4, r.top + 30, r.width - 8, r.height - 30), 3, holes: {(2, 2), (3, 2)}, shift: 3);
      _chip(canvas, '1:24', Offset(r.right - 62, r.top + 6), const Color(0xFFF59E0B), ink: _edge, size: 12, icon: Icons.hourglass_bottom_rounded);
    };

// ------------------------------------------------------------ scenes: falling blocks

/// A falling-block well: [rows] of the stack from the bottom ('x' block,
/// 'g' grey, '*' star, '.' empty), and an optional falling piece.
void _blockWell(Canvas canvas, Rect r, List<String> rows, {List<(int, int)> piece = const [], int pieceColor = 4, bool ghost = false, Color? tint}) {
  _well(canvas, r, colors: tint == null ? const [Color(0xFF221B36), Color(0xFF120E1E)] : [tint, const Color(0xFF120E1E)]);
  final cols = rows.first.length;
  final s = r.width / cols;
  final grid = Paint()..color = Colors.white.withValues(alpha: 0.05);
  for (var x = 0; x <= cols; x++) {
    canvas.drawLine(Offset(r.left + x * s, r.top), Offset(r.left + x * s, r.bottom), grid);
  }
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < cols; x++) {
      final ch = rows[y][x];
      final at = Offset(r.left + x * s, r.bottom - (y + 1) * s);
      switch (ch) {
        case 'x':
          paintToyBlock(canvas, at, s, _blocks[(x * 3 + y * 2) % _blocks.length], _edge);
        case 'g':
          paintToyBlock(canvas, at, s, const Color(0xFF7A7590), _edge);
        case '*':
          paintToyBlock(canvas, at, s, _blocks[(x + y) % _blocks.length], _edge);
          paintGoldStar(canvas, at + Offset(s / 2, s / 2), s * 0.32);
      }
    }
  }
  for (final (x, y) in piece) {
    if (ghost) {
      final landing = Rect.fromLTWH(r.left + x * s, r.bottom - (rows.length + 1 + (y - piece.map((p) => p.$2).reduce(min))) * s, s, s);
      canvas.drawRRect(RRect.fromRectAndRadius(landing.deflate(2), Radius.circular(s * 0.2)), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.35));
    }
    paintToyBlock(canvas, Offset(r.left + x * s, r.top + y * s), s, _blocks[pieceColor], _edge);
  }
}

void Function(Rect) _normal(Canvas canvas) => (r) {
      _blockWell(canvas, Rect.fromLTWH(r.center.dx - 85, r.top, 170, r.height),
          ['xxxx.xxxxx', 'xx.xxx.xxx', '.x..xx..x.'], piece: const [(4, 1), (5, 1), (6, 1), (5, 0)]);
      paintSparkle(canvas, Offset(r.left + 40, r.top + 40), 10, const Color(0xFFFFE066));
      // Next piece box on the side.
      final next = RRect.fromRectAndRadius(Rect.fromLTWH(r.right - 70, r.top + 14, 56, 56), const Radius.circular(10));
      canvas.drawRRect(next, Paint()..color = const Color(0xFF2E2648));
      mockText(canvas, 'SIRADAKİ', Offset(next.center.dx, next.top + 10), 8.5, _soft, width: 56);
      for (final (x, y) in const [(0, 0), (1, 0), (1, 1), (2, 1)]) {
        paintToyBlock(canvas, Offset(next.left + 10 + x * 12, next.top + 24 + y * 12), 12, _blocks[3], _edge);
      }
      _chip(canvas, 'Seviye 4', Offset(r.left + 12, r.top + 12), const Color(0xE61A1330), size: 10.5);
    };

void Function(Rect) _relaxed(Canvas canvas) => (r) {
      _blockWell(canvas, Rect.fromLTWH(r.left, r.top, r.width, r.height), ['xx.xxxxx', '.x...xx.'], piece: const [(3, 1), (4, 1), (3, 2), (4, 2)], pieceColor: 1,
          tint: const Color(0xFF1E3A30));
      _icon(canvas, Icons.spa_rounded, Offset(r.right - 16, r.top + 16), 18, const Color(0xFF86EFAC));
    };

void Function(Rect) _target(Canvas canvas) => (r) => _blockWell(canvas, r, ['x*xxx.xx', '.x.*xx.x'], piece: const [(5, 0), (5, 1)], pieceColor: 2, tint: const Color(0xFF3A3010));

void Function(Rect) _chaos(Canvas canvas) => (r) {
      _blockWell(canvas, r, ['xxx.xxxx', 'x.xx..x.'], tint: const Color(0xFF34184A));
      canvas.save();
      canvas.translate(r.center.dx, r.top + 18);
      canvas.rotate(0.35);
      for (final (x, y) in const [(-1, 0), (0, 0), (1, 0)]) {
        paintToyBlock(canvas, Offset(x * 12.0 - 6, y * 12.0 - 6), 12, _blocks[4], _edge);
      }
      canvas.restore();
      _icon(canvas, Icons.casino_rounded, Offset(r.right - 16, r.top + 16), 18, Colors.white);
      paintSparkle(canvas, Offset(r.left + 16, r.top + 14), 7, const Color(0xFFFF9AD8));
    };

void Function(Rect) _sprint(Canvas canvas) => (r) {
      _blockWell(canvas, r, ['xxxxxxx.', 'xx.xxxxx'], tint: const Color(0xFF103040));
      final line = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(Offset(r.left + 10, r.top + 12 + i * 7.0), Offset(r.left + 30 + i * 6.0, r.top + 12 + i * 7.0), line);
      }
      _chip(canvas, '40 satır', Offset(r.right - 62, r.top + 6), const Color(0xFF06B6D4), ink: _edge, size: 10);
    };

void Function(Rect) _ultra(Canvas canvas) => (r) {
      _blockWell(canvas, r, ['xxx.xxxx', '.xx..xx.'], tint: const Color(0xFF3A2810));
      _chip(canvas, '3:00', Offset(r.right - 54, r.top + 6), const Color(0xFFF59E0B), ink: _edge, size: 10.5, icon: Icons.timer_rounded);
    };

// ------------------------------------------------------------ game pages

void _chainPage(Canvas canvas, Size size) {
  _screen(canvas, size);
  _header(canvas, 'Zincir Küpler', chip: '5 mod');
  _featured(canvas, 110, _ferry(canvas), 'ANA MOD', 'Vapur Hattı', 'Boğaz iskelelerinde görevler · Sıradaki: Bebek', 12 / 72, '12 / 72 yıldız', 'DEVAM');
  _sectionLabel(canvas, 'DİĞER MODLAR', 392);
  const w = 173.0, h = 196.0;
  _sceneCard(canvas, const Rect.fromLTWH(16, 414, w, h), _versus(canvas), "Limon'a Karşı", 'Bilgisayara karşı maç, 3 rakip', '3 galibiyet', isNew: true);
  _sceneCard(canvas, const Rect.fromLTWH(201, 414, w, h), _chainPuzzle(canvas), 'Bulmacalar', 'Hazır tahtayı az hamlede temizle', '9 / 80 çözüldü', isNew: true);
  _sceneCard(canvas, const Rect.fromLTWH(16, 622, w, h), _chainEndless(canvas), 'Sonsuz', 'Küpleri kaydır, zincir kur', 'Rekor 4.321');
  _sceneCard(canvas, const Rect.fromLTWH(201, 622, w, h), _chainTime(canvas), 'Zamana Karşı', '2 dakikada en yüksek skor', null);
}

void _classicPage(Canvas canvas, Size size) {
  _screen(canvas, size);
  _header(canvas, 'Klasik Küpler', chip: '7 mod');
  _featured(canvas, 110, _normal(canvas), 'ANA MOD', 'Normal', 'Hız yavaşça artar · Satırları temizle', 0.45, 'Rekor 267', 'OYNA',
      tone: const [Color(0xFF7DD3FC), Color(0xFF3B82F6)]);
  _sectionLabel(canvas, 'SAKİN', 392);
  _sceneRow(canvas, 414, _relaxed(canvas), 'Rahat', 'Sabit, sakin hız; acele yok', null);
  _sectionLabel(canvas, 'MEYDAN OKUMA', 508);
  _sceneRow(canvas, 530, _target(canvas), 'Hedef', 'Yıldızları topla, süre kazan', null, isNew: true);
  _sceneRow(canvas, 616, _chaos(canvas), 'Kaos', 'Sürprizlerle dolu maraton', null, isNew: true);
  _sceneRow(canvas, 702, _sprint(canvas), 'Hız Koşusu', '40 satır, en kısa süre', '1:52');
  _sceneRow(canvas, 788, _ultra(canvas), '3 Dakika', '3 dakikada en yüksek skor', null);
}

// ------------------------------------------------------------ the tower

const _u = Offset(0.866, 0.5), _v = Offset(-0.866, 0.5);

Color _shade(Color c, double k) => k >= 0 ? Color.lerp(c, Colors.white, k)! : Color.lerp(c, const Color(0xFF1A0E26), -k)!;

/// A lokum floor in isometric view: top face centred on [c], [a] half-size
/// along the right axis, [b] along the left one, [h] tall. Lit from the upper
/// left: a glossy top dusted with sugar crystals, jelly sides with a sheen, a
/// wavy cream layer, a bright bevel along the back edges.
void _isoFloor(Canvas canvas, Offset c, double a, double b, double h, Color color, {int seed = 0, double alpha = 1, List<Color>? pattern}) {
  final back = c - _u * a - _v * b, right = c + _u * a - _v * b, front = c + _u * a + _v * b, left = c - _u * a + _v * b;
  final down = Offset(0, h);
  final small = a < 16 || h < 10;
  Path poly(List<Offset> p) => Path()..addPolygon(p, true);
  Color al(Color x, [double k = 1]) => x.withValues(alpha: x.a * alpha * k);

  // Jelly sides.
  final rightFace = poly([right, front, front + down, right + down]);
  final leftFace = poly([front, left, left + down, front + down]);
  canvas.drawPath(rightFace, Paint()..shader = ui.Gradient.linear(right, right + down, [al(_shade(color, 0.22)), al(_shade(color, 0.06)), al(_shade(color, -0.14))], const [0, 0.55, 1]));
  canvas.drawPath(leftFace, Paint()..shader = ui.Gradient.linear(left, left + down, [al(_shade(color, -0.02)), al(_shade(color, -0.14)), al(_shade(color, -0.3))], const [0, 0.55, 1]));
  canvas.drawPath(rightFace, Paint()..shader = ui.Gradient.linear(right, front, [al(Colors.white, 0), al(Colors.white, 0.2), al(Colors.white, 0)], const [0.1, 0.4, 0.75]));
  if (pattern != null && !small) {
    // Tiles on the sides (the çini floor).
    for (final (p0, p1) in [(right, front), (front, left)]) {
      for (var k = 0.1; k < 0.95; k += 0.2) {
        final m = Offset.lerp(p0, p1, k)! + Offset(0, h * 0.5);
        canvas.drawPath(Path()..addPolygon([m - Offset(0, h * 0.28), m + Offset(h * 0.22, 0), m + Offset(0, h * 0.28), m - Offset(h * 0.22, 0)], true), Paint()..color = al(pattern.first, 0.9));
        canvas.drawCircle(m, h * 0.07, Paint()..color = al(pattern.last));
      }
    }
  } else if (!small) {
    // A wavy cream layer.
    Path wave(Offset p0, Offset p1) {
      const n = 14;
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final p = Offset.lerp(p0, p1, i / n)! + Offset(0, h * 0.5 + sin(i / n * pi * 4 + seed) * h * 0.04);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      for (var i = n; i >= 0; i--) {
        final p = Offset.lerp(p0, p1, i / n)! + Offset(0, h * 0.66 + sin(i / n * pi * 4 + seed + 1) * h * 0.035);
        path.lineTo(p.dx, p.dy);
      }
      return path..close();
    }

    canvas.drawPath(wave(right, front), Paint()..color = al(const Color(0xFFFFF7EC), 0.92));
    canvas.drawPath(wave(front, left), Paint()..color = al(const Color(0xFFE9DACA), 0.88));
  }
  // The front corner catches the light; a soft shade at the foot.
  canvas.drawLine(front + const Offset(0, 1.5), front + down - const Offset(0, 1.5), Paint()
    ..color = al(Colors.white, 0.45)
    ..strokeWidth = small ? 0.8 : 1.4);
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = small ? 0.9 : 1.4
    ..strokeJoin = StrokeJoin.round
    ..color = al(_edge, 0.7);
  canvas.drawPath(rightFace, edge);
  canvas.drawPath(leftFace, edge);

  // The top: lit, glossy, sugared.
  final top = poly([back, right, front, left]);
  canvas.drawPath(top, Paint()..shader = ui.Gradient.linear(back, front, [al(_shade(color, 0.55)), al(_shade(color, 0.24))]));
  final gloss = Offset.lerp(c, back, 0.18)!;
  canvas.drawPath(_diamond(gloss, a * 0.74, b * 0.74), Paint()..shader = ui.Gradient.radial(gloss, max(a, b) * 0.95, [al(Colors.white, 0.36), al(Colors.white, 0)]));
  if (!small) {
    final rnd = Random(seed);
    for (var i = 0; i < (a * b / 34).round(); i++) {
      final s = rnd.nextDouble(), t = rnd.nextDouble();
      final p = back + (right - back) * s + (left - back) * t;
      final r = 0.6 + rnd.nextDouble() * 1.3;
      if (rnd.nextDouble() < 0.12) {
        // A sugar crystal that glints.
        canvas.drawPath(Path()..addPolygon([p - Offset(0, r * 1.8), p + Offset(r, 0), p + Offset(0, r * 1.8), p - Offset(r, 0)], true), Paint()..color = al(Colors.white, 0.95));
      } else {
        canvas.drawCircle(p, r, Paint()..color = al(Colors.white, 0.45 + rnd.nextDouble() * 0.4));
      }
    }
  }
  // Bevel: light along the back edges, a darker lip along the front.
  Offset inset(Offset p) => Offset.lerp(p, c, small ? 0.06 : 0.045)!;
  canvas.drawPath(Path()
    ..moveTo(inset(left).dx, inset(left).dy)
    ..lineTo(inset(back).dx, inset(back).dy)
    ..lineTo(inset(right).dx, inset(right).dy), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = small ? 1 : 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = al(Colors.white, 0.75));
  canvas.drawPath(Path()
    ..moveTo(inset(right).dx, inset(right).dy)
    ..lineTo(inset(front).dx, inset(front).dy)
    ..lineTo(inset(left).dx, inset(left).dy), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = small ? 0.8 : 1.4
    ..strokeJoin = StrokeJoin.round
    ..color = al(_shade(color, -0.2), 0.6));
  canvas.drawPath(top, edge);
}

/// The soft shadow a floor casts on the one below it.
void _floorShadow(Canvas canvas, Offset c, double a, double b, double h, {double alpha = 1}) => canvas.drawPath(
  _diamond(c + Offset(h * 0.12, h * 1.06), a * 1.02, b * 1.02),
  Paint()
    ..color = Colors.black.withValues(alpha: 0.32 * alpha)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(1.2, h * 0.16)),
);

/// The tower: floors from the bottom, each (cu, cv, a, b) in floor units.
List<(double, double, double, double)> _towerPlan(int n, {double size = 60}) {
  final cuts = [4.0, -6, 3, 0, 7, -3, 0, 5, -2, 0, 4, -5, 0, 3, -4, 2, 0, 0];
  var cu = 0.0, cv = 0.0, a = size, b = size;
  final out = <(double, double, double, double)>[];
  for (var i = 0; i < n; i++) {
    final d = cuts[i % cuts.length];
    if (i.isEven) {
      a -= d.abs() / 2;
      cu += d / 2;
    } else {
      b -= d.abs() / 2;
      cv += d / 2;
    }
    out.add((cu, cv, a, b));
  }
  return out;
}

void _tower(Canvas canvas, Offset base, int floors, double h, {int skip = 0, double size = 60, double scale = 1}) {
  final plan = _towerPlan(floors, size: size);
  for (var i = skip; i < floors; i++) {
    final (cu, cv, a, b) = plan[i];
    final c = base + (_u * cu + _v * cv) * scale - Offset(0, i * h);
    if (i > skip) _floorShadow(canvas, c, a * scale, b * scale, h);
    _isoFloor(canvas, c, a * scale, b * scale, h, _lokum[i % _lokum.length], seed: i);
  }
}

void _towerSky(Canvas canvas, Rect r, {double height = 0.5}) {
  // Higher up the sky darkens towards night.
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF1E1450), Color(0xFF5A2E98), Color(0xFFE0608A), Color(0xFFFFB070)], [0, height * 0.6, height * 1.25, 1]));
  final rnd = Random(9);
  for (var i = 0; i < 40; i++) {
    final p = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height * height);
    canvas.drawCircle(p, 0.6 + rnd.nextDouble() * 1.2, Paint()..color = Colors.white.withValues(alpha: 0.3 + rnd.nextDouble() * 0.5));
  }
}

void _cloud(Canvas canvas, Offset c, double w, {double alpha = 0.85}) {
  final p = Paint()..color = const Color(0xFFFFE6F0).withValues(alpha: alpha);
  canvas.drawOval(Rect.fromCenter(center: c, width: w, height: w * 0.28), p);
  canvas.drawCircle(c + Offset(-w * 0.15, -w * 0.1), w * 0.17, p);
  canvas.drawCircle(c + Offset(w * 0.1, -w * 0.13), w * 0.21, p);
}

void _towerGame(Canvas canvas, Size size) {
  final r = Offset.zero & size;
  _towerSky(canvas, r, height: 0.55);
  // Istanbul far below.
  paintSkyline(canvas, size.width, size.height - 18, 150, const Color(0xFF6A3A7A));
  canvas.drawRect(Rect.fromLTWH(0, size.height - 18, size.width, 18), Paint()..color = const Color(0xFF7A4A9A));
  _cloud(canvas, const Offset(70, 300), 120, alpha: 0.5);
  _cloud(canvas, const Offset(330, 230), 90, alpha: 0.4);
  _cloud(canvas, const Offset(320, 700), 150, alpha: 0.7);
  paintGulls(canvas, const [Offset(300, 380), Offset(318, 372)], const Color(0xFF3A1E5A));

  const h = 26.0;
  const base = Offset(195, 800);
  const floors = 13;
  _tower(canvas, base, floors, h);
  final plan = _towerPlan(floors + 1);
  final (cu, cv, a, b) = plan[floors - 1];
  final top = base + _u * cu + _v * cv - const Offset(0, (floors - 1) * h);

  // The perfect ring round the last floor.
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white.withValues(alpha: 0.8);
  final k = 1.28;
  canvas.drawPath(Path()
    ..addPolygon([top - _u * a * k - _v * b * k, top + _u * a * k - _v * b * k, top + _u * a * k + _v * b * k, top - _u * a * k + _v * b * k], true), ring);

  // The cut-off piece tumbling down on the right.
  canvas.save();
  canvas.translate(52, 560);
  canvas.rotate(-0.45);
  _isoFloor(canvas, Offset.zero, 8, b * 0.8, h, _lokum[(floors - 1) % _lokum.length], seed: 77, alpha: 0.95);
  canvas.restore();

  // The next floor sliding in along the right axis, with a trail.
  final slide = top - const Offset(0, h * 2.2) - _v * (b * 1.75);
  for (var i = 3; i >= 1; i--) {
    _isoFloor(canvas, slide - _v * (i * 12.0), a, b, h, _lokum[floors % _lokum.length], seed: 90 + i, alpha: 0.12 * (4 - i));
  }
  _isoFloor(canvas, slide, a, b, h, _lokum[floors % _lokum.length], seed: 99);
  mockLabel(canvas, 'MÜKEMMEL!', top + const Offset(-70, -12), 24);

  // Lokum cheering on a cloud.
  _cloud(canvas, const Offset(66, 724), 110);
  paintLokum(canvas, const Offset(64, 682), 64, pose: LokumPose.wow);

  // HUD.
  _chip(canvas, 'Rekor 41', const Offset(16, 60), const Color(0xCC1A1330), size: 12, icon: Icons.emoji_events_rounded);
  _box(canvas, RRect.fromRectAndRadius(const Rect.fromLTWH(332, 54, 42, 42), const Radius.circular(13)), fill: const Color(0xCC1A1330), depth: 3);
  _icon(canvas, Icons.pause_rounded, const Offset(353, 75), 24, _text);
  mockLabel(canvas, '27', const Offset(195, 96), 64);
  mockText(canvas, 'KAT', const Offset(195, 140), 14, Colors.white);
  _chip(canvas, 'MÜKEMMEL ×4', const Offset(141, 158), _gold, ink: _edge, size: 11.5, icon: Icons.bolt_rounded);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(195, 812), width: 186, height: 34), const Radius.circular(17)), Paint()..color = const Color(0xCC1A1330));
  _icon(canvas, Icons.touch_app_rounded, const Offset(124, 812), 20, Colors.white);
  mockText(canvas, 'Dokun, katı bırak', const Offset(204, 812), 14, Colors.white, width: 140);
}

/// A tower thumbnail for cards: a few floors on a dusk sky.
void Function(Rect) _towerThumb(Canvas canvas, {int floors = 7, bool stars = false}) => (r) {
      _towerSky(canvas, r, height: stars ? 0.7 : 0.35);
      paintSkyline(canvas, r.right, r.bottom - 4, r.height * 1.4, const Color(0xFF6A3A7A).withValues(alpha: 0.9));
      final h = r.height / (floors + 4.5);
      final scale = h / 26;
      _tower(canvas, Offset(r.center.dx, r.bottom - h * 1.2), floors, h, scale: scale);
      final (cu, cv, a, b) = _towerPlan(floors + 1)[floors - 1];
      final top = Offset(r.center.dx, r.bottom - h * 1.2) + (_u * cu + _v * cv) * scale - Offset(0, floors * h);
      _isoFloor(canvas, top - _v * (b * scale * 1.1), a * scale, b * scale, h, _lokum[floors % _lokum.length], seed: 5);
    };

void Function(Rect) _windThumb(Canvas canvas) => (r) {
      _towerThumb(canvas, floors: 6)(r);
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = r.top + 18 + i * 14.0;
        canvas.drawPath(Path()
          ..moveTo(r.left + 8, y)
          ..cubicTo(r.left + 30, y - 8, r.left + 46, y + 8, r.left + 64 + i * 6, y - 2), p);
      }
    };

void Function(Rect) _dailyThumb(Canvas canvas) => (r) {
      _towerThumb(canvas, floors: 5)(r);
      _chip(canvas, '3 deneme', Offset(r.left + 8, r.top + 8), const Color(0xE61A1330), size: 10, icon: Icons.calendar_today_rounded);
    };

/// Istanbul's towers in a row, the first built, the second next.
void Function(Rect) _towersMap(Canvas canvas) => (r) {
      canvas.save();
      canvas.translate(r.left, r.top);
      final size = r.size;
      paintDusk(canvas, Offset.zero & size);
      final horizon = size.height * 0.76;
      paintSkyline(canvas, size.width, horizon, size.height * 0.6, const Color(0xFF3A1E5A));
      paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height - horizon), ferryAt: 0.1, tower: 0);
      void body(Offset foot, double w, double h, Color c) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(foot.dx - w / 2, foot.dy - h, w, h), const Radius.circular(3)), Paint()..color = c);
      }

      void cone(Offset tip, double w, double h, Color c) =>
          canvas.drawPath(Path()..addPolygon([tip, tip + Offset(-w / 2, h), tip + Offset(w / 2, h)], true), Paint()..color = c);
      const built = Color(0xFFFFE3B0), next = Color(0xFFFF9AD8), locked = Color(0xFF241638);
      // Galata: built, three stars.
      final g = Offset(size.width * 0.16, horizon + 2);
      body(g, 30, 64, built);
      canvas.drawRect(Rect.fromLTWH(g.dx - 18, g.dy - 68, 36, 6), Paint()..color = built);
      cone(Offset(g.dx, g.dy - 104), 32, 36, const Color(0xFF8A5A9A));
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(Rect.fromLTWH(g.dx - 9 + i * 7, g.dy - 52, 3, 7), Paint()..color = const Color(0xFF8A5A9A));
      }
      _stars(canvas, Offset(g.dx - 16, g.dy + 14), 3, r: 6);
      // Kız Kulesi: on its islet, next.
      final kz = Offset(size.width * 0.4, horizon + 22);
      canvas.drawOval(Rect.fromCenter(center: kz + const Offset(0, 4), width: 70, height: 14), Paint()..color = const Color(0xFF5A3A6A));
      canvas.drawCircle(kz - const Offset(0, 40), 34, Paint()..color = next.withValues(alpha: 0.3));
      body(kz, 22, 48, next);
      cone(Offset(kz.dx, kz.dy - 76), 22, 28, const Color(0xFFE0247A));
      _chip(canvas, 'SIRADAKİ', Offset(kz.dx - 32, kz.dy - 102), _accent, size: 9.5);
      // Beyazıt and Çamlıca: locked.
      final bz = Offset(size.width * 0.64, horizon + 2);
      body(bz, 14, 92, locked);
      canvas.drawRect(Rect.fromLTWH(bz.dx - 11, bz.dy - 80, 22, 5), Paint()..color = locked);
      _icon(canvas, Icons.lock_rounded, Offset(bz.dx, bz.dy - 106), 16, Colors.white.withValues(alpha: 0.8));
      final cm = Offset(size.width * 0.86, horizon + 2);
      canvas.drawPath(Path()..addPolygon([cm + const Offset(-12, 0), cm + const Offset(-5, -112), cm + const Offset(5, -112), cm + const Offset(12, 0)], true), Paint()..color = locked);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cm.dx - 12, cm.dy - 96, 24, 12), const Radius.circular(4)), Paint()..color = locked);
      canvas.drawLine(cm - const Offset(0, 112), cm - const Offset(0, 136), Paint()
        ..color = locked
        ..strokeWidth = 3);
      _icon(canvas, Icons.lock_rounded, Offset(cm.dx + 22, cm.dy - 120), 16, Colors.white.withValues(alpha: 0.8));
      canvas.restore();
    };

void _towerPage(Canvas canvas, Size size) {
  _screen(canvas, size);
  _header(canvas, 'Kule Küpler', chip: '3 mod');
  _featured(canvas, 110, _towersMap(canvas), 'ANA MOD', 'İstanbul Kuleleri', 'Kuleyi hedef kata çıkar · Sıradaki: Kız Kulesi', 1 / 6, '1 / 6 kule', 'DEVAM',
      tone: const [Color(0xFFFFD27A), Color(0xFFFF8A3D)]);
  _sectionLabel(canvas, 'DİĞER MODLAR', 392);
  const w = 173.0, h = 196.0;
  _sceneCard(canvas, const Rect.fromLTWH(16, 414, w, h), _towerThumb(canvas, floors: 9, stars: true), 'Sonsuz Gökyüzü', 'Bulutları aş, yıldızlara uzan', 'Rekor 41 kat');
  _sceneCard(canvas, const Rect.fromLTWH(201, 414, w, h), _windThumb(canvas), 'Rüzgâr', 'Kat sallanır, zamanlamayı tuttur', null, isNew: true);
  _sceneCard(canvas, const Rect.fromLTWH(16, 622, w, h), _dailyThumb(canvas), 'Günün Kulesi', 'Her gün yeni bir kule, üç deneme', null, recordIcon: Icons.calendar_today_rounded);
}

// ------------------------------------------------------------ games list with the tower first

void _sweetsThumb(Canvas canvas, Rect r) {
  _well(canvas, r, colors: const [Color(0xFF6A25B8), Color(0xFF3A1270)]);
  final s = r.height / 3.2;
  final cols = (r.width / s).floor();
  final x0 = r.left + (r.width - cols * s) / 2;
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < cols; x++) {
      paintCandy(canvas, Rect.fromLTWH(x0 + x * s, r.top + (r.height - 3 * s) / 2 + y * s, s, s).deflate(s * 0.04), SugarColor.values[(x * 2 + y * 3) % 6]);
    }
  }
}

void _gameCard(Canvas canvas, double top, void Function(Rect r) scene, String title, String line, String? modes, String? progress, {bool isNew = false, bool selected = false}) {
  final r = Rect.fromLTWH(16, top, 358, 104);
  _box(canvas, RRect.fromRectAndRadius(r, const Radius.circular(20)), border: selected ? _accent : _edge, width: selected ? 3 : 2.5);
  final art = Rect.fromLTWH(r.left + 10, r.top + 10, 116, r.height - 20);
  _framed(canvas, art, scene);
  final x = art.right + 13;
  _t(canvas, title, Offset(x, r.top + 12), 19, _text, width: 180);
  _t(canvas, line, Offset(x, r.top + 38), 12.5, _soft, width: r.right - x - 34, weight: FontWeight.w600);
  var cx = x;
  if (modes != null) cx += _chip(canvas, modes, Offset(cx, r.bottom - 30), _chipFill, size: 11) + 8;
  if (progress != null) {
    _icon(canvas, Icons.emoji_events_rounded, Offset(cx + 7, r.bottom - 21), 14, _gold);
    _t(canvas, progress, Offset(cx + 17, r.bottom - 29.5), 12, _text, width: 120);
  }
  if (isNew) _chip(canvas, 'YENİ', Offset(r.right - 52, r.top + 10), _newRed, size: 10);
  _icon(canvas, modes == null ? Icons.play_arrow_rounded : Icons.chevron_right_rounded, Offset(r.right - 20, r.center.dy + 6), 28, modes == null ? _gold : _soft);
}

void _gamesList(Canvas canvas, Size size) {
  _screen(canvas, size);
  _header(canvas, 'Oyunlar');
  _gameCard(canvas, 114, _towerThumb(canvas), 'Kule Küpler', 'Lokum katları diz, kuleyi yükselt', '3 mod', 'Rekor 41 kat', isNew: true, selected: true);
  _gameCard(canvas, 230, (r) => _sweetsThumb(canvas, r), 'Şeker Küpler', "Eşleştir, patlat, İstanbul'u gez", null, '54 / 360 yıldız', isNew: true);
  _gameCard(canvas, 346, _chainEndless(canvas), 'Zincir Küpler', 'Kaydır, zincir kur, rakibini yen', '5 mod', 'Rekor 4.321', isNew: true);
  _gameCard(canvas, 462, (r) => _blockWell(canvas, r, ['xx.xxxx', '.x.xx.x', '....x..'], piece: const [(2, 0), (3, 0), (4, 0)], pieceColor: 2), 'Bulmaca Küpler',
      'Parçaları yerleştir, satır temizle', '4 mod', '21 / 300 yıldız');
  _gameCard(canvas, 578, (r) => _blockWell(canvas, r, ['xxx.xxx', 'x.xx..x'], piece: const [(2, 0), (3, 0), (4, 0), (3, 1)], pieceColor: 4), 'Süper Küpler',
      'Enerji topla, güçleri kullan!', null, 'Rekor 898');
  _gameCard(canvas, 694, (r) => _blockWell(canvas, r, ['xxxx.xx', 'x.xx.x.'], piece: const [(3, 0), (4, 0), (3, 1), (4, 1)], pieceColor: 6), 'Klasik Küpler',
      'Düşen bloklar, klasik kurallar', '7 mod', 'Rekor 267');
}

// ------------------------------------------------------------ sheets

const _phone = Size(390, 844);

void _sheetBg(Canvas canvas, Size size) =>
    canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));

void _phones(Canvas canvas, List<(String, String, void Function(Canvas, Size))> phones) {
  for (var i = 0; i < phones.length; i++) {
    final left = 40 + i * (_phone.width + 60);
    final (title, text, paint) = phones[i];
    mockText(canvas, title, Offset(left + _phone.width / 2, 40), 26, Colors.white, width: _phone.width + 40);
    mockText(canvas, text, Offset(left + _phone.width / 2, 86), 15, _soft, width: _phone.width + 20, weight: FontWeight.w600, lines: 3);
    mockPhone(canvas, Rect.fromLTWH(left, 140, _phone.width, _phone.height), paint);
  }
}

void _pagesSheet(Canvas canvas, Size size) {
  _sheetBg(canvas, size);
  _phones(canvas, [
    ('Zincir Küpler', 'Ana mod en üstte, büyük: Vapur Hattı ve sıradaki iskele. Diğer modlar kendi sahneleriyle, önemine göre sıralı.', _chainPage),
    ('Klasik Küpler', 'Normal öne çıkıyor; Rahat ayrı, meydan okumalar küçük sahneli satırlar halinde (sayfa aşağı kayar).', _classicPage),
  ]);
}

void _towerSheet(Canvas canvas, Size size) {
  _sheetBg(canvas, size);
  _phones(canvas, [
    ('Kule Küpler · oyun', 'Lokum katları kayarak gelir; dokununca bırakırsın. Taşan kısım kesilip düşer, tam isabet MÜKEMMEL sayılır.', _towerGame),
    ('Oyunlar listesinde', 'Yeni ana oyun olarak en üstte. Kartında kendi kulesi, rekoru ve mod sayısı.', _gamesList),
    ('Kule Küpler · modlar', "İstanbul Kuleleri ana mod: Galata, Kız Kulesi, Beyazıt, Çamlıca... Her kule bir hedef yükseklik.", _towerPage),
  ]);
  const notes = [
    'Nasıl oynanır: kat bir yandan kayarak gelir, dokununca bırakırsın. Alttaki katın dışında kalan kısım kesilip düşer, kule incelir.',
    'Tam üstüne bırakırsan MÜKEMMEL: dört tam isabet üst üste kat yeniden genişler, Lokum sevinir.',
    'Katlar lokum: gül, fıstık, limon, lavanta, portakal, nane; üstü pudra şekerli, kenarı kaymaklı. Yükseldikçe gökyüzü gün batımından geceye, yıldızlara döner.',
    'İstanbul Kuleleri: her kule bir hedef kat; ulaşınca kulenin tepesi oturur, yıldız ve kartpostal kazanırsın. Ayrıca Sonsuz Gökyüzü, Rüzgâr ve Günün Kulesi.',
    'Tek parmakla, kısa oturumlu: ana ekrandaki OYNA için ilk öneri bu oyun olabilir.',
  ];
  var y = 140 + _phone.height + 40;
  for (final n in notes) {
    canvas.drawCircle(Offset(56, y + 10), 4, Paint()..color = _accent);
    mockText(canvas, n, Offset(70, y), 16, Colors.white, centre: false, width: size.width - 120, weight: FontWeight.w600, lines: 2);
    y += 34;
  }
}

// ------------------------------------------------------------ the drop, frame by frame

void _dashed(Canvas canvas, Path path, Paint paint, {double on = 7, double off = 5}) {
  for (final metric in path.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += on + off) {
      canvas.drawPath(metric.extractPath(d, min(d + on, metric.length)), paint);
    }
  }
}

Path _diamond(Offset c, double a, double b) => Path()..addPolygon([c - _u * a - _v * b, c + _u * a - _v * b, c + _u * a + _v * b, c - _u * a + _v * b], true);

/// One frame of the drop: the sky, a short tower, and [extra] on top.
void _dropFrame(Canvas canvas, Rect r, int step) {
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(22)));
  _towerSky(canvas, r, height: 0.45);
  canvas.save();
  canvas.translate(r.left, 0);
  paintSkyline(canvas, r.width, r.bottom - 10, 140, const Color(0xFF6A3A7A));
  canvas.restore();
  const h = 24.0, floors = 7;
  final base = Offset(r.center.dx, r.bottom - 20);
  final plan = _towerPlan(floors, size: 52);
  for (var i = 0; i < floors; i++) {
    final (cu, cv, a, b) = plan[i];
    _isoFloor(canvas, base + _u * cu + _v * cv - Offset(0, i * h), a, b, h, _lokum[i % _lokum.length], seed: i);
  }
  final (cu, cv, a, b) = plan[floors - 1];
  final top = base + _u * cu + _v * cv - const Offset(0, (floors - 1) * h);
  final color = _lokum[floors % _lokum.length];
  final above = top - const Offset(0, h * 3.4);
  final white = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.85);
  final o = b * 0.35;
  switch (step) {
    case 0:
      // Sliding back and forth above the tower.
      final slab = above - _v * (b * 1.5);
      _dashed(canvas, Path()
        ..moveTo((above - _v * (b * 2.6)).dx, (above - _v * (b * 2.6)).dy)
        ..lineTo((above + _v * (b * 2.2)).dx, (above + _v * (b * 2.2)).dy), white);
      for (final (end, dir) in [(above - _v * (b * 2.6), -1.0), (above + _v * (b * 2.2), 1.0)]) {
        final d = _v * dir;
        canvas.drawPath(Path()
          ..moveTo((end - d * 12 + Offset(-d.dy, d.dx) * 8).dx, (end - d * 12 + Offset(-d.dy, d.dx) * 8).dy)
          ..lineTo(end.dx, end.dy)
          ..lineTo((end - d * 12 - Offset(-d.dy, d.dx) * 8).dx, (end - d * 12 - Offset(-d.dy, d.dx) * 8).dy), white);
      }
      for (var i = 3; i >= 1; i--) {
        _isoFloor(canvas, slab - _v * (i * 10.0), a, b, h, color, seed: 40 + i, alpha: 0.12 * (4 - i));
      }
      _isoFloor(canvas, slab, a, b, h, color, seed: 40);
    case 1:
      // A tap: it stops, and its shadow shows where it will land.
      final slab = above - _v * o;
      canvas.drawPath(_diamond(top - _v * o, a, b), Paint()..color = Colors.white.withValues(alpha: 0.28));
      _dashed(canvas, _diamond(top - _v * o, a, b), white..strokeWidth = 2);
      _isoFloor(canvas, slab, a, b, h, color, seed: 40);
      final tap = Offset(r.right - 52, r.bottom - 120);
      for (final rad in [18.0, 30.0]) {
        canvas.drawCircle(tap, rad, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white.withValues(alpha: rad == 18 ? 0.8 : 0.4));
      }
      _icon(canvas, Icons.touch_app_rounded, tap + const Offset(6, 14), 40, Colors.white);
    case 2:
      // Straight down, fast.
      final slab = top - Offset(0, h * 1.6) - _v * o;
      final line = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (final dx in [-0.6, 0.0, 0.6]) {
        final x = slab + _u * (a * dx) - Offset(0, h * 0.4);
        canvas.drawLine(x - const Offset(0, 46), x - const Offset(0, 12), line);
      }
      canvas.drawPath(_diamond(top - _v * o, a, b), Paint()..color = Colors.black.withValues(alpha: 0.18));
      _isoFloor(canvas, slab, a, b, h, color, seed: 40);
    case 3:
      // It lands; what hangs over is cut off and tumbles away.
      _isoFloor(canvas, top - Offset(0, h) - _v * (o / 2), a, b - o / 2, h, color, seed: 40);
      canvas.save();
      final cut = top - Offset(0, h) - _v * (b + o / 2) + const Offset(22, 64);
      canvas.translate(cut.dx, cut.dy);
      canvas.rotate(0.55);
      _isoFloor(canvas, Offset.zero, a, o / 2, h, color, seed: 41);
      canvas.restore();
      final crumb = Paint()..color = _shade(color, 0.3);
      for (final p in [const Offset(-8, -6), const Offset(6, 4), const Offset(-2, 12)]) {
        canvas.drawCircle(top - _v * (b + 4) - Offset(0, h * 0.5) + p, 2.6, crumb);
      }
      canvas.drawLine(top - Offset(0, h) - _v * b + _u * a * 1.1, top - Offset(0, h) - _v * b - _u * a * 1.1, Paint()
        ..color = Colors.white
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round);
    case 4:
      // Right on top: MÜKEMMEL, and after a few the floor grows back.
      final landed = top - const Offset(0, h);
      for (final (k, alpha) in [(1.25, 0.9), (1.55, 0.45)]) {
        canvas.drawPath(_diamond(landed, a * k, b * k), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: alpha));
      }
      _isoFloor(canvas, landed, a, b, h, color, seed: 40);
      for (final dir in [_u, -_u, _v, -_v]) {
        final from = landed + dir * (a * 0.95), to = landed + dir * (a * 1.3);
        canvas.drawLine(from, to, white..strokeWidth = 3);
      }
      paintSparkle(canvas, landed + const Offset(-70, -40), 12, const Color(0xFFFFE066));
      paintSparkle(canvas, landed + const Offset(76, -24), 9, const Color(0xFFFF9AD8));
      mockLabel(canvas, 'MÜKEMMEL!', landed - const Offset(0, 74), 24);
      _chip(canvas, '4. tam isabet · kat genişledi', landed - const Offset(86, 54), _gold, ink: _edge, size: 11, icon: Icons.bolt_rounded);
  }
  canvas.restore();
  canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(22)), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = _edge);
}

// ------------------------------------------------------------ Kız Kulesi, stage by stage

enum _Part { done, current, locked }

/// Kız Kulesi on its islet, each of its five parts built, being built or
/// still to come. [foot] is the middle of the islet's top.
void _maidensTower(Canvas canvas, Offset foot, double k, List<_Part> parts) {
  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round
    ..color = _edge;
  final ghost = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.45);
  final glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..color = _accent.withValues(alpha: 0.7)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  void shape(_Part state, Path path, Color fill, {List<Color>? gradient}) {
    switch (state) {
      case _Part.locked:
        _dashed(canvas, path, ghost, on: 6, off: 5);
      case _Part.current:
        canvas.drawPath(path, glow);
        canvas.drawPath(path, Paint()..color = fill.withValues(alpha: 0.55));
        _dashed(canvas, path, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Colors.white, on: 6, off: 4);
      case _Part.done:
        final b = path.getBounds();
        canvas.drawPath(path, gradient == null ? (Paint()..color = fill) : (Paint()..shader = ui.Gradient.linear(b.topLeft, b.bottomRight, gradient)));
        canvas.drawPath(path, outline);
    }
  }

  Path rect(double x, double y, double w, double h) => Path()..addRect(Rect.fromLTWH(foot.dx + x * k, foot.dy + y * k, w * k, h * k));
  final stone = const Color(0xFFE9D9BE), stoneDark = const Color(0xFFBFA987);

  // 1 · The islet, the quay and the white house with the red roof.
  shape(parts[0], rect(-150, 0, 300, 22), const Color(0xFFCDBB9A), gradient: const [Color(0xFFE2D3B6), Color(0xFFA8957A)]);
  shape(parts[0], rect(40, -60, 108, 60), Colors.white, gradient: const [Colors.white, Color(0xFFE7E1EA)]);
  shape(parts[0], Path()..addPolygon([foot + Offset(34 * k, -60 * k), foot + Offset(154 * k, -60 * k), foot + Offset(140 * k, -80 * k), foot + Offset(48 * k, -80 * k)], true), const Color(0xFFC4473A));
  if (parts[0] == _Part.done) {
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(foot.dx + (52 + i * 24) * k, foot.dy - 44 * k, 12 * k, 18 * k), Radius.circular(5 * k)), Paint()..color = const Color(0xFF8A4A3A));
    }
  }
  // 2 · The stone body.
  shape(parts[1], rect(-46, -170, 92, 170), stone, gradient: [stone, stoneDark]);
  if (parts[1] == _Part.done) {
    final band = Paint()
      ..color = const Color(0xFF9A7A5A)
      ..strokeWidth = 2;
    for (final y in [-120.0, -64.0]) {
      canvas.drawLine(foot + Offset(-46 * k, y * k), foot + Offset(46 * k, y * k), band);
    }
    for (final y in [-150.0, -100.0, -46.0]) {
      for (final x in [-26.0, 10.0]) {
        canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(foot.dx + x * k, foot.dy + y * k, 16 * k, 26 * k), topLeft: Radius.circular(8 * k), topRight: Radius.circular(8 * k)),
            Paint()..color = const Color(0xFF5A3A4A));
      }
    }
  }
  // 3 · The balcony and the octagon above it.
  shape(parts[2], rect(-64, -186, 128, 16), const Color(0xFFF2F2F5));
  shape(parts[2], rect(-38, -246, 76, 60), stone, gradient: [stone, stoneDark]);
  if (parts[2] == _Part.done) {
    final rail = Paint()
      ..color = _edge
      ..strokeWidth = 1.6;
    for (var x = -60.0; x <= 60; x += 10) {
      canvas.drawLine(foot + Offset(x * k, -186 * k), foot + Offset(x * k, -198 * k), rail);
    }
    canvas.drawLine(foot + Offset(-64 * k, -198 * k), foot + Offset(64 * k, -198 * k), rail);
    for (final x in [-24.0, 8.0]) {
      canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(foot.dx + x * k, foot.dy - 236 * k, 16 * k, 30 * k), topLeft: Radius.circular(8 * k), topRight: Radius.circular(8 * k)),
          Paint()..color = const Color(0xFF5A3A4A));
    }
  }
  // 4 · The lead dome.
  final dome = Path()
    ..moveTo(foot.dx - 42 * k, foot.dy - 246 * k)
    ..cubicTo(foot.dx - 42 * k, foot.dy - 290 * k, foot.dx + 42 * k, foot.dy - 290 * k, foot.dx + 42 * k, foot.dy - 246 * k)
    ..close();
  shape(parts[3], dome, const Color(0xFF7A8A9E), gradient: const [Color(0xFFA9B8C9), Color(0xFF5A6A80)]);
  // 5 · The lantern and the flag.
  shape(parts[4], rect(-9, -306, 18, 22), const Color(0xFF7A8A9E));
  shape(parts[4], rect(-2, -400, 4, 96), const Color(0xFFDADDE5));
  final flag = Path()..addRect(Rect.fromLTWH(foot.dx + 2 * k, foot.dy - 398 * k, 46 * k, 30 * k));
  shape(parts[4], flag, const Color(0xFFE30A17));
  if (parts[4] == _Part.done) {
    final c = foot + Offset(20 * k, -383 * k);
    canvas.drawCircle(c, 9 * k, Paint()..color = Colors.white);
    canvas.drawCircle(c + Offset(2.4 * k, 0), 7.4 * k, Paint()..color = const Color(0xFFE30A17));
    paintGoldStar(canvas, c + Offset(10 * k, 0), 3.4 * k);
  }
}

void _stageRow(Canvas canvas, Rect r, int n, String name, String floors, String goal, int stars, _Part state) {
  final current = state == _Part.current;
  _box(canvas, RRect.fromRectAndRadius(r, const Radius.circular(18)), border: current ? _accent : _edge, width: current ? 3 : 2.5,
      fill: state == _Part.locked ? const Color(0xFF2F2844) : _card);
  final badge = r.topLeft + Offset(30, r.height / 2);
  canvas.drawCircle(badge, 18, Paint()..color = switch (state) { _Part.done => _gold, _Part.current => _accent, _Part.locked => const Color(0xFF4A4068) });
  canvas.drawCircle(badge, 18, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = _edge);
  if (state == _Part.locked) {
    _icon(canvas, Icons.lock_rounded, badge, 18, Colors.white70);
  } else {
    mockText(canvas, '$n', badge, 18, state == _Part.done ? _edge : Colors.white);
  }
  _t(canvas, name, r.topLeft + const Offset(60, 10), 17, state == _Part.locked ? _soft : _text, width: 220);
  _t(canvas, '$floors · $goal', r.topLeft + const Offset(60, 36), 12.5, _soft, width: r.width - 190, weight: FontWeight.w600);
  if (state == _Part.done) _stars(canvas, Offset(r.right - 92, r.center.dy), stars, r: 9);
  if (current) _playButton(canvas, Rect.fromLTWH(r.right - 112, r.center.dy - 18, 98, 36), 'DEVAM');
}

void _dropSheet(Canvas canvas, Size size) {
  _sheetBg(canvas, size);
  mockText(canvas, 'Kule Küpler · kat nasıl düşer?', Offset(size.width / 2, 44), 32, Colors.white, width: 900);
  mockText(canvas, 'Kat her zaman kulenin üstünden gelir; dokununca dimdik aşağı düşer.', Offset(size.width / 2, 86), 17, _soft, width: 1000, weight: FontWeight.w600);
  const frames = [
    ('1 · Gelir', 'Kat, kulenin üstünde bir çapraz eksende ileri geri kayar. Sıradaki kat öbür eksenden gelir.'),
    ('2 · Dokun', 'Dokununca durur. Kulenin üstüne düşen gölgesi nereye oturacağını gösterir.'),
    ('3 · Düşer', 'Dimdik ve hızlı düşer, hafif bir sekmeyle oturur.'),
    ('4 · Kesilir', 'Alttaki katın dışında kalan parça kesilip düşer; kule incelir.'),
    ('5 · MÜKEMMEL', 'Tam üstüne oturursa halka yayılır. Dört tam isabette kat yeniden genişler.'),
  ];
  const fw = 300.0, fh = 470.0, gap = 34.0;
  final left = (size.width - (frames.length * fw + (frames.length - 1) * gap)) / 2;
  for (var i = 0; i < frames.length; i++) {
    final x = left + i * (fw + gap);
    final (title, text) = frames[i];
    _dropFrame(canvas, Rect.fromLTWH(x, 130, fw, fh), i);
    mockText(canvas, title, Offset(x + fw / 2, 130 + fh + 28), 21, Colors.white, width: fw);
    mockText(canvas, text, Offset(x + fw / 2, 130 + fh + 70), 14, _soft, width: fw, weight: FontWeight.w600, lines: 3);
    if (i < frames.length - 1) _icon(canvas, Icons.arrow_forward_rounded, Offset(x + fw + gap / 2, 130 + fh / 2), 26, _accent);
  }

  // The progression: Kız Kulesi in five stages.
  final top = 130 + fh + 130.0;
  mockText(canvas, 'İlerleme · her kule bir bölüm, her bölüm birkaç etap', Offset(size.width / 2, top), 28, Colors.white, width: 1200);
  mockText(canvas, 'Kız Kulesi: 5 etap, toplam 90 kat. Her etap 2–4 dakika; biten parça kalıcı olarak yerine oturur.', Offset(size.width / 2, top + 40), 16, _soft,
      width: 1200, weight: FontWeight.w600);
  final scene = Rect.fromLTWH(left, top + 76, 520, 560);
  _framed(canvas, scene, (r) {
    canvas.save();
    canvas.translate(r.left, r.top);
    paintDusk(canvas, Offset.zero & r.size);
    paintSkyline(canvas, r.width, r.height * 0.74, r.height * 0.7, const Color(0xFF4A2A6A));
    paintBosphorus(canvas, Rect.fromLTWH(0, r.height * 0.74, r.width, r.height * 0.26), ferryAt: 0.12, tower: 0);
    paintGulls(canvas, [Offset(r.width * 0.75, r.height * 0.18), Offset(r.width * 0.8, r.height * 0.22)], const Color(0xFF3A1E5A));
    canvas.restore();
    _maidensTower(canvas, Offset(r.left + r.width * 0.46, r.top + r.height * 0.8), 1.0, const [_Part.done, _Part.done, _Part.done, _Part.current, _Part.locked]);
  }, radius: 22);
  _chip(canvas, 'Etap 4 / 5 · Kubbe', Offset(scene.left + 16, scene.top + 16), const Color(0xE61A1330), ink: _gold, size: 13, icon: Icons.flag_rounded);

  const stages = [
    ('Ada ve rıhtım', '16 kat', 'ilk katları yerleştir', 3, _Part.done),
    ('Taş gövde', '22 kat', '3 MÜKEMMEL yap', 3, _Part.done),
    ('Balkon', '18 kat', 'kat yarıdan fazla incelmesin', 2, _Part.done),
    ('Kubbe', '20 kat', 'rüzgâr çıkar, kat sallanır', 0, _Part.current),
    ('Fener ve bayrak', '14 kat', 'son 5 kat MÜKEMMEL', 0, _Part.locked),
  ];
  final listX = scene.right + 30;
  final listW = size.width - left - listX;
  for (var i = 0; i < stages.length; i++) {
    final (name, floors, goal, stars, state) = stages[i];
    _stageRow(canvas, Rect.fromLTWH(listX, top + 76 + i * 76.0, listW, 64), i + 1, name, floors, goal, stars, state);
  }

  // The road of towers.
  final roadTop = top + 76 + 5 * 76.0 + 14;
  _t(canvas, 'KULELER YOLU · toplam 740 kat', Offset(listX + 4, roadTop), 14, _label, width: 400);
  const towers = [
    ('Galata', '80 kat', _Part.done),
    ('Kız Kulesi', '90 kat', _Part.current),
    ('Rumeli Hisarı', '90 kat', _Part.locked),
    ('Beyazıt', '100 kat', _Part.locked),
    ('Dolmabahçe Saat Kulesi', '70 kat', _Part.locked),
    ('Haydarpaşa', '80 kat', _Part.locked),
    ('Selimiye', '90 kat', _Part.locked),
    ('Çamlıca', '140 kat', _Part.locked),
  ];
  var cx = listX, cy = roadTop + 26;
  for (final (name, floors, state) in towers) {
    final text = '$name · $floors';
    final w = text.length * 13 * 0.6 + 14 + 16;
    if (cx + w > listX + listW) {
      cx = listX;
      cy += 34;
    }
    final fill = switch (state) { _Part.done => _gold, _Part.current => _accent, _Part.locked => _chipFill };
    _chip(canvas, text, Offset(cx, cy), fill, ink: state == _Part.done ? _edge : Colors.white, size: 13,
        icon: switch (state) { _Part.done => Icons.check_rounded, _Part.current => Icons.play_arrow_rounded, _Part.locked => Icons.lock_rounded });
    cx += w + 8;
  }

  // The rules of the road.
  const notes = [
    'Etabı tutturamazsan yalnızca o etabı yeniden denersin; kulenin bitmiş kısmı kaybolmaz.',
    'Etaplar ilerledikçe zorlaşır: kayma hızlanır, rüzgâr çıkar, katlar daralır, bulutlar önünü keser.',
    'Kule bitince Boğaz’daki yerine oturur: kartpostal ve Lokum kostümü. Bütün kuleler: İstanbul silueti ödülü.',
    'Sonsuz Gökyüzü’nde katlar lokumdur; kuleler yolunda her kulenin kendi taşı, tuğlası ve kurşunu.',
  ];
  var ny = scene.bottom + 34;
  for (final n in notes) {
    canvas.drawCircle(Offset(left + 8, ny + 10), 4, Paint()..color = _accent);
    mockText(canvas, n, Offset(left + 24, ny), 16, Colors.white, centre: false, width: size.width - 2 * left - 30, weight: FontWeight.w600, lines: 2);
    ny += 32;
  }
}

// ------------------------------------------------------------ the long climb

void _coin(Canvas canvas, Offset c, double r) {
  canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.linear(c - Offset(0, r), c + Offset(0, r), const [Color(0xFFFFE47A), Color(0xFFE09A10)]));
  canvas.drawCircle(c, r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1, r * 0.16)
    ..color = const Color(0xFF7A4A08));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r * 0.9, height: r * 0.9), Radius.circular(r * 0.2)), Paint()..color = const Color(0xFFFFF3C0).withValues(alpha: 0.85));
}

/// A tall, thin tower for the height strip: [n] floors of height [h].
void _thinTower(Canvas canvas, Offset base, int n, double h, double size) {
  for (var i = 0; i < n; i++) {
    final wobble = sin(i * 0.7) * size * 0.06;
    final c = base + _u * wobble - Offset(0, i * h);
    final shrink = size * (1 - 0.18 * i / n);
    if (i > 0) _floorShadow(canvas, c, shrink, shrink, h, alpha: 0.6);
    _isoFloor(canvas, c, shrink, shrink, h, _lokum[i % _lokum.length], seed: i);
  }
}

/// One run, bottom to top: the sky changes as the tower climbs, a chest
/// waits at each milestone.
void _heightStrip(Canvas canvas, Size size) {
  final r = Offset.zero & size;
  canvas.drawRect(r, Paint()
    ..shader = ui.Gradient.linear(r.bottomCenter, r.topCenter, const [
      Color(0xFFCDEBFF), Color(0xFF8CC4FF), Color(0xFF6F9CF0), Color(0xFFFF9AA2), Color(0xFFB0508A), Color(0xFF3A2470), Color(0xFF141238), Color(0xFF05030F),
    ], const [0, 0.1, 0.28, 0.42, 0.52, 0.62, 0.78, 1]));
  final rnd = Random(4);
  for (var i = 0; i < 90; i++) {
    final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.42);
    canvas.drawCircle(p, 0.6 + rnd.nextDouble() * 1.3, Paint()..color = Colors.white.withValues(alpha: 0.35 + rnd.nextDouble() * 0.6));
  }
  // A ringed planet up in space, the moon at night.
  final planet = Offset(size.width * 0.78, size.height * 0.08);
  canvas.drawCircle(planet, 22, Paint()..shader = ui.Gradient.linear(planet - const Offset(20, 20), planet + const Offset(20, 20), const [Color(0xFFFFB0E0), Color(0xFF7A3AB0)]));
  canvas.drawOval(Rect.fromCenter(center: planet, width: 70, height: 16), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFFFE0F4).withValues(alpha: 0.8));
  final moon = Offset(size.width * 0.2, size.height * 0.27);
  canvas.drawCircle(moon, 20, Paint()..color = const Color(0xFFFFF4D0));
  canvas.drawCircle(moon + const Offset(8, -5), 17, Paint()..color = const Color(0xFF1A1440));
  for (final (x, y, w) in [(0.2, 0.7, 120.0), (0.82, 0.66, 100.0), (0.5, 0.76, 160.0), (0.15, 0.82, 90.0)]) {
    _cloud(canvas, Offset(size.width * x, size.height * y), w, alpha: 0.8);
  }
  paintGulls(canvas, [Offset(size.width * 0.7, size.height * 0.86), Offset(size.width * 0.76, size.height * 0.85)], const Color(0xFF3A4A7A));
  paintSkyline(canvas, size.width, size.height - 16, 110, const Color(0xFF6A7AB0));
  canvas.drawRect(Rect.fromLTWH(0, size.height - 16, size.width, 16), Paint()..color = const Color(0xFF4A6AB0));
  _thinTower(canvas, Offset(size.width * 0.5, size.height - 24), 128, 6.2, 22);
  // Zones and milestones.
  const zones = [(0.02, '0 · Boğaz'), (0.15, '50 · Bulutlar, martılar'), (0.4, '150 · Gün batımı'), (0.6, '300 · Gece, ay'), (0.82, '500 · Uzay')];
  for (final (k, label) in zones) {
    final y = size.height * (1 - k) - 20;
    canvas.drawLine(Offset(size.width - 120, y + 18), Offset(size.width - 6, y + 18), Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5);
    _t(canvas, label, Offset(size.width - 120, y), 11.5, Colors.white, width: 118);
  }
  const chests = [(0.06, '25'), (0.12, '50'), (0.24, '100'), (0.46, '200'), (0.6, '300'), (0.82, '500')];
  for (final (k, label) in chests) {
    final c = Offset(34, size.height * (1 - k) - 14);
    paintChest(canvas, c, 22, chestGold, glow: label == '500');
    mockText(canvas, label, c + const Offset(0, 20), 11, Colors.white, width: 40);
  }
}

/// The game at floor 128, in the clouds.
void _climbGame(Canvas canvas, Size size) {
  final r = Offset.zero & size;
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF4F86F0), Color(0xFF8CB8FF), Color(0xFFC8E0FF)], const [0, 0.55, 1]));
  for (final (x, y, w, al) in [(70.0, 260.0, 110.0, 0.7), (320.0, 330.0, 130.0, 0.8), (90.0, 560.0, 160.0, 0.85), (330.0, 640.0, 120.0, 0.85)]) {
    _cloud(canvas, Offset(x, y), w, alpha: al);
  }
  paintGulls(canvas, const [Offset(290, 420), Offset(306, 412)], const Color(0xFF3A4A7A));
  const h = 26.0, floors = 14;
  const base = Offset(195, 830);
  _tower(canvas, base, floors, h, size: 56);
  final plan = _towerPlan(floors, size: 56);
  final (cu, cv, a, b) = plan[floors - 1];
  final top = base + _u * cu + _v * cv - const Offset(0, (floors - 1) * h);
  // Clouds drift past the lower floors.
  _cloud(canvas, const Offset(130, 760), 220, alpha: 0.75);
  _cloud(canvas, const Offset(300, 800), 180, alpha: 0.7);
  final slide = top - const Offset(0, h * 2.4) - _v * (b * 1.6);
  for (var i = 3; i >= 1; i--) {
    _isoFloor(canvas, slide - _v * (i * 11.0), a, b, h, _lokum[floors % _lokum.length], seed: 60 + i, alpha: 0.12 * (4 - i));
  }
  _isoFloor(canvas, slide, a, b, h, _lokum[floors % _lokum.length], seed: 66);

  // HUD: the floor, the best, coins, the streak and the next chest.
  _chip(canvas, 'Rekor 240', const Offset(16, 60), const Color(0xCC1A1330), size: 12, icon: Icons.emoji_events_rounded);
  final coins = RRect.fromRectAndRadius(const Rect.fromLTWH(16, 92, 78, 24), const Radius.circular(12));
  canvas.drawRRect(coins, Paint()..color = const Color(0xCC1A1330));
  _coin(canvas, const Offset(30, 104), 8);
  _t(canvas, '560', const Offset(44, 96), 13, Colors.white, width: 50);
  _box(canvas, RRect.fromRectAndRadius(const Rect.fromLTWH(332, 54, 42, 42), const Radius.circular(13)), fill: const Color(0xCC1A1330), depth: 3);
  _icon(canvas, Icons.pause_rounded, const Offset(353, 75), 24, _text);
  mockLabel(canvas, '128', const Offset(195, 92), 60);
  mockText(canvas, 'KAT', const Offset(195, 134), 14, Colors.white);
  _chip(canvas, 'MÜKEMMEL ×7', const Offset(140, 150), _gold, ink: _edge, size: 11.5, icon: Icons.bolt_rounded);
  final bar = const Rect.fromLTWH(70, 184, 230, 12);
  _progress(canvas, bar, 128 / 200, const [Color(0xFFFFE47A), Color(0xFFFF8A3D)]);
  paintChest(canvas, Offset(bar.right + 22, bar.center.dy), 22, chestGold);
  mockText(canvas, 'Sıradaki sandık: 200. kat', Offset(bar.center.dx, bar.bottom + 14), 11.5, Colors.white, width: 230);
}

/// The chest at floor 200: what it gives, and on you go.
void _chestScreen(Canvas canvas, Size size) {
  final r = Offset.zero & size;
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF6A3AB0), Color(0xFFE0608A), Color(0xFFFFB070)], const [0, 0.55, 1]));
  _tower(canvas, const Offset(195, 900), 16, 26, size: 54);
  canvas.drawRect(r, Paint()..color = const Color(0xFF120A24).withValues(alpha: 0.62));
  mockLabel(canvas, '200. KAT!', const Offset(195, 150), 46);
  mockText(canvas, 'Gökyüzü değişiyor: gün batımı', const Offset(195, 196), 15, Colors.white, width: 300);
  // Light rays behind the open chest.
  const c = Offset(195, 340);
  for (var i = 0; i < 12; i++) {
    final a0 = i * pi / 6;
    canvas.drawPath(Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx + cos(a0) * 220, c.dy + sin(a0) * 220)
      ..lineTo(c.dx + cos(a0 + 0.22) * 220, c.dy + sin(a0 + 0.22) * 220)
      ..close(), Paint()..color = const Color(0xFFFFE8A0).withValues(alpha: 0.12));
  }
  paintChest(canvas, c, 150, chestGold, open: true, glow: true);
  paintSparkle(canvas, c + const Offset(-90, -70), 14, const Color(0xFFFFE066));
  paintSparkle(canvas, c + const Offset(96, -40), 11, const Color(0xFFFF9AD8));
  // The rewards.
  const cards = ['+150', 'Yeni kostüm', 'Çini kat'];
  for (var i = 0; i < 3; i++) {
    final card = Rect.fromLTWH(24 + i * 118.0, 470, 106, 150);
    _box(canvas, RRect.fromRectAndRadius(card, const Radius.circular(18)), fill: const Color(0xFF3A3152));
    final mid = Offset(card.center.dx, card.top + 56);
    switch (i) {
      case 0:
        _coin(canvas, mid + const Offset(-10, 6), 18);
        _coin(canvas, mid + const Offset(12, -6), 18);
      case 1:
        paintLokum(canvas, mid + const Offset(0, 6), 62, outfit: LokumOutfit.fez);
      case 2:
        _isoFloor(canvas, mid - const Offset(0, 8), 26, 26, 16, const Color(0xFF3B82F6), seed: 3, pattern: const [Colors.white, Color(0xFFFFD34D)]);
    }
    mockText(canvas, cards[i], Offset(card.center.dx, card.bottom - 40), 15, Colors.white, width: 100);
    mockText(canvas, ['lokum altını', 'Lokum için', 'kat görünümü'][i], Offset(card.center.dx, card.bottom - 20), 11.5, _soft, width: 100, weight: FontWeight.w600);
  }
  _playButton(canvas, const Rect.fromLTWH(95, 660, 200, 52), 'DEVAM');
  mockText(canvas, 'Kule kaldığı yerden devam eder', const Offset(195, 736), 13, _soft, width: 300, weight: FontWeight.w600);
}

/// İstanbul'u İnşa Et: every floor of every run adds to the tower in hand.
void _buildPage(Canvas canvas, Size size) {
  _screen(canvas, size);
  _box(canvas, RRect.fromRectAndRadius(const Rect.fromLTWH(16, 54, 42, 42), const Radius.circular(13)), fill: const Color(0xFF4A4068), depth: 3);
  _icon(canvas, Icons.arrow_back_rounded, const Offset(37, 75), 22, _text);
  _t(canvas, "İstanbul'u İnşa Et", const Offset(72, 58), 24, _text);
  final scene = const Rect.fromLTWH(16, 110, 358, 330);
  _framed(canvas, scene, (r) {
    canvas.save();
    canvas.translate(r.left, r.top);
    paintDusk(canvas, Offset.zero & r.size);
    paintSkyline(canvas, r.width, r.height * 0.8, r.height * 0.7, const Color(0xFF4A2A6A));
    paintBosphorus(canvas, Rect.fromLTWH(0, r.height * 0.8, r.width, r.height * 0.2), ferryAt: 0.1, tower: 0);
    canvas.restore();
    _maidensTower(canvas, Offset(r.left + r.width * 0.44, r.top + r.height * 0.84), 0.66, const [_Part.done, _Part.done, _Part.done, _Part.current, _Part.locked]);
  }, radius: 20);
  _chip(canvas, 'Kız Kulesi · 2. kule', Offset(scene.left + 12, scene.top + 12), const Color(0xE61A1330), ink: _gold, size: 12, icon: Icons.flag_rounded);
  _t(canvas, 'Kız Kulesi', const Offset(20, 452), 22, _text);
  _progress(canvas, const Rect.fromLTWH(20, 488, 230, 12), 640 / 1000, const [Color(0xFFFF9AD8), Color(0xFFE0247A)]);
  _t(canvas, '640 / 1.000 kat', const Offset(260, 482), 13, _text, width: 120);
  _t(canvas, 'Her oyunda koyduğun katlar buraya eklenir.', const Offset(20, 508), 12.5, _soft, width: 350, weight: FontWeight.w600);
  const parts = [
    ('Ada ve rıhtım', '200', _Part.done),
    ('Taş gövde', '400', _Part.done),
    ('Balkon', '600', _Part.done),
    ('Kubbe', '800', _Part.current),
    ('Fener ve bayrak', '1.000', _Part.locked),
  ];
  for (var i = 0; i < parts.length; i++) {
    final (name, at, state) = parts[i];
    final row = Rect.fromLTWH(16, 540 + i * 46.0, 358, 38);
    _box(canvas, RRect.fromRectAndRadius(row, const Radius.circular(14)), border: state == _Part.current ? _accent : _edge, width: state == _Part.current ? 2.5 : 2, depth: 2,
        fill: state == _Part.locked ? const Color(0xFF2F2844) : _card);
    _icon(canvas, switch (state) { _Part.done => Icons.check_circle_rounded, _Part.current => Icons.construction_rounded, _Part.locked => Icons.lock_rounded },
        Offset(row.left + 20, row.center.dy), 18, switch (state) { _Part.done => _gold, _Part.current => _accent, _Part.locked => _label });
    _t(canvas, name, Offset(row.left + 38, row.top + 9), 14, state == _Part.locked ? _soft : _text, width: 200);
    _t(canvas, state == _Part.current ? '160 kat kaldı' : '$at kat', Offset(row.right - 110, row.top + 10), 12.5, state == _Part.current ? _accent : _soft, width: 100);
  }
  _t(canvas, 'KULELER · toplam 12.000 kat', const Offset(20, 778), 12, _label, width: 300);
  var x = 16.0;
  for (final (name, state) in const [('Galata', _Part.done), ('Kız Kulesi', _Part.current), ('Rumeli Hisarı', _Part.locked), ('+5', _Part.locked)]) {
    final w = _chip(canvas, name, Offset(x, 800), switch (state) { _Part.done => _gold, _Part.current => _accent, _Part.locked => _chipFill },
        ink: state == _Part.done ? _edge : Colors.white, size: 11.5, icon: switch (state) { _Part.done => Icons.check_rounded, _Part.current => Icons.construction_rounded, _Part.locked => Icons.lock_rounded });
    x += w + 6;
  }
}

void _climbSheet(Canvas canvas, Size size) {
  _sheetBg(canvas, size);
  mockText(canvas, 'Kule Küpler · uzun tırmanış', Offset(size.width / 2, 40), 32, Colors.white, width: 1000);
  mockText(canvas, 'Bir oyun yüzlerce kat sürer; her kat da İstanbul’un kulelerini kurmaya gider.', Offset(size.width / 2, 80), 17, _soft, width: 1200, weight: FontWeight.w600);
  const panels = [
    ('Bir oyun, yüzlerce kat', 'Yükseldikçe gökyüzü değişir; her dönüm noktasında bir sandık.'),
    ('128. kat, bulutlarda', 'Rekor, lokum altını, MÜKEMMEL serisi ve sıradaki sandığa kalan.'),
    ('200. kat sandığı', 'Altın, Lokum kostümü, yeni kat görünümü. Oyun kaldığı yerden sürer.'),
    ("İstanbul'u İnşa Et", 'Bütün oyunların katları birikir; kule parça parça yükselir.'),
  ];
  const w = 390.0, gap = 44.0, top = 170.0;
  final left = (size.width - (4 * w + 3 * gap)) / 2;
  for (var i = 0; i < 4; i++) {
    final x = left + i * (w + gap);
    final (title, text) = panels[i];
    mockText(canvas, title, Offset(x + w / 2, 128), 22, Colors.white, width: w + 20);
    mockText(canvas, text, Offset(x + w / 2, 156), 13.5, _soft, width: w + 30, weight: FontWeight.w600);
    final r = Rect.fromLTWH(x, top + 12, w, _phone.height);
    mockPhone(canvas, r, switch (i) {
      0 => _heightStrip,
      1 => _climbGame,
      2 => _chestScreen,
      _ => _buildPage,
    });
  }
  const notes = [
    'Uzun oyun: zorluk yavaş artar, MÜKEMMEL serisi katı yeniden genişletip seni ayakta tutar. İyi bir oyun 5–10 dakika, 150–400 kat.',
    'Sandıklar 25, 50, 100, 200, 300 ve 500. katta: lokum altını, Lokum kostümleri, yeni kat görünümleri (çini, mermer, cam, altın).',
    "İstanbul'u İnşa Et: Galata 500, Kız Kulesi 1.000, Rumeli Hisarı 1.200 … Çamlıca 3.000 kat; sekiz kule, toplam 12.000 kat. Haftalarca sürer.",
    'Reklam yok: düşünce bir kez lokum altınıyla devam edebilirsin. Yan modlar: Rüzgâr (sallanan katlar) ve Günün Kulesi (herkese aynı kule).',
  ];
  var y = top + 12 + _phone.height + 34;
  for (final n in notes) {
    canvas.drawCircle(Offset(left + 8, y + 10), 4, Paint()..color = _accent);
    mockText(canvas, n, Offset(left + 24, y), 16, Colors.white, centre: false, width: size.width - 2 * left - 30, weight: FontWeight.w600, lines: 2);
    y += 32;
  }
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

  testWidgets('game pages', (tester) async {
    await mockSave(tester, const Size(40 * 2 + 390 * 2 + 60, 140 + 844 + 40), _pagesSheet, 'oyun-sayfalari-2.png', scale: 2);
  });

  testWidgets('tower climb', (tester) async {
    await mockSave(tester, const Size(1780, 1230), _climbSheet, 'kule-tirmanis.png', scale: 1.6);
  });

  testWidgets('tower drop', (tester) async {
    await mockSave(tester, const Size(1760, 1590), _dropSheet, 'kule-dusus.png', scale: 1.6);
  });

  testWidgets('tower game', (tester) async {
    await mockSave(tester, const Size(40 * 2 + 390 * 3 + 60 * 2, 140 + 844 + 40 + 5 * 34 + 30), _towerSheet, 'kule-kupler.png', scale: 2);
  });
}
