// Mock-ups for stage five, Zincir Küpler: the ferry-line mission map, the
// puzzle mode and a match against the computer (Ekşi Limon).
//   flutter test tool/stage5_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): asama5-gorevler.png,
// asama5-bulmaca.png, asama5-rakip.png.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart';
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart' hide paintSparkle;

import 'mock_kit.dart';

const _bg = Color(0xFF231D36);
const _panel = Color(0xFF332B4C);
const _well = Color(0xFF110D1C);
const _soft = Color(0xFFB8AEDA);

const _codes = {'y': ChainColor.yellow, 'm': ChainColor.magenta, 'b': ChainColor.blue, 'g': ChainColor.green, 'o': ChainColor.orange};

void _screenBg(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
  final dot = Paint()..color = Colors.white.withValues(alpha: 0.04);
  for (var y = 10.0; y < size.height; y += 26) {
    for (var x = 10.0; x < size.width; x += 26) {
      canvas.drawCircle(Offset(x, y), 1.4, dot);
    }
  }
}

void _panelBox(Canvas canvas, RRect r, {Color color = _panel, Color? border}) {
  canvas.drawRRect(r.shift(const Offset(0, 5)), Paint()..color = Colors.black.withValues(alpha: 0.35));
  canvas.drawRRect(r, Paint()..color = color);
  if (border != null) {
    canvas.drawRRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = border);
  }
}

/// A Zincir board: [rows] top to bottom, y m b g o a cube, G garbage
/// (a run of G is one slab), . empty. [cursor] is the left cube of the
/// swap cursor (column, row).
void _board(Canvas canvas, Rect r, List<String> rows, {(int, int)? cursor, Color well = _well, double frame = 10}) {
  final cols = rows.first.length;
  final cell = r.width / cols;
  final outer = RRect.fromRectAndRadius(r.inflate(frame), Radius.circular(frame * 2.2));
  canvas.drawRRect(outer.shift(const Offset(0, 6)), Paint()..color = Colors.black.withValues(alpha: 0.4));
  canvas.drawRRect(outer, Paint()..color = _panel);
  canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(frame)), Paint()..color = well);
  final dot = Paint()..color = Colors.white.withValues(alpha: 0.05);
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < cols; x++) {
      canvas.drawCircle(Offset(r.left + (x + 0.5) * cell, r.top + (y + 0.5) * cell), cell * 0.05, dot);
    }
  }
  for (var y = 0; y < rows.length; y++) {
    var x = 0;
    while (x < cols) {
      final ch = rows[y][x];
      if (ch == 'G') {
        var end = x;
        while (end < cols && rows[y][end] == 'G') {
          end++;
        }
        paintGarbageSlab(canvas, Rect.fromLTWH(r.left + x * cell + 1, r.top + y * cell + 1, (end - x) * cell - 2, cell - 2));
        x = end;
        continue;
      }
      final c = _codes[ch];
      if (c != null) {
        paintChainCube(canvas, Rect.fromLTWH(r.left + x * cell, r.top + y * cell, cell, cell).deflate(cell * 0.03), chainColors[c]!);
      }
      x++;
    }
  }
  if (cursor != null) {
    final (cx, cy) = cursor;
    final cr = Rect.fromLTWH(r.left + cx * cell, r.top + cy * cell, cell * 2, cell).inflate(cell * 0.06);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.07
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final l = cell * 0.26;
    for (final (corner, dx, dy) in [(cr.topLeft, 1.0, 1.0), (cr.topRight, -1.0, 1.0), (cr.bottomLeft, 1.0, -1.0), (cr.bottomRight, -1.0, -1.0)]) {
      canvas.drawLine(corner, corner + Offset(dx * l, 0), p);
      canvas.drawLine(corner, corner + Offset(0, dy * l), p);
    }
  }
}

void _star(Canvas canvas, Offset c, double r, {bool on = true}) => paintGoldStar(canvas, c, r, on: on);

// ------------------------------------------------------------- missions --

const _piers = [
  ('Eminönü', 1, true),
  ('Üsküdar', 6, true),
  ('Beşiktaş', 11, false),
  ('Çengelköy', 16, false),
  ('Bebek', 21, false),
];

void _missionScreen(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  // Night over the Bosphorus, seen from above: two shores, the water between.
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF16122A));
  final sea = Path()..moveTo(w * 0.42, 0);
  for (var y = 0.0; y <= h; y += 40) {
    sea.lineTo(w * (0.38 + 0.08 * sin(y / 140)), y);
  }
  for (var y = h; y >= 0; y -= 40) {
    sea.lineTo(w * (0.64 + 0.08 * sin(y / 140 + 1.4)), y);
  }
  sea.close();
  canvas.drawPath(sea, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), const [Color(0xFF2A3A8A), Color(0xFF1A2460)]));
  final rnd = Random(4);
  for (var i = 0; i < 60; i++) {
    final y = rnd.nextDouble() * h;
    final x = w * (0.42 + 0.18 * rnd.nextDouble() + 0.08 * sin(y / 140));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 8 + rnd.nextDouble() * 14, height: 2), const Radius.circular(2)), Paint()..color = const Color(0x557FA8FF));
  }
  for (var i = 0; i < 260; i++) {
    final left = i.isEven;
    final x = left ? rnd.nextDouble() * w * 0.34 : w * 0.7 + rnd.nextDouble() * w * 0.3;
    canvas.drawCircle(Offset(x, rnd.nextDouble() * h), 0.8 + rnd.nextDouble(), Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.25 + rnd.nextDouble() * 0.5));
  }
  mockText(canvas, 'AVRUPA', Offset(48, h * 0.5), 12, const Color(0x66FFFFFF), width: 80);
  mockText(canvas, 'ASYA', Offset(w - 40, h * 0.5), 12, const Color(0x66FFFFFF), width: 80);
  // The ferry line: a dashed route zig-zagging from pier to pier.
  final pts = [for (var i = 0; i < _piers.length; i++) Offset(i.isEven ? w * 0.26 : w * 0.74, h - 250 - i * 110.0)];
  final route = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1], b = pts[i];
    route.cubicTo(a.dx, a.dy - 60, b.dx, b.dy + 60, b.dx, b.dy);
  }
  var reached = 0.0;
  for (final m in route.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += 14) {
      final done = d < m.length * 0.42;
      if (done) reached = d;
      canvas.drawCircle(m.getTangentForOffset(d)!.position, done ? 3.4 : 2.6, Paint()..color = done ? const Color(0xFFFFE066) : Colors.white.withValues(alpha: 0.35));
    }
    final at = m.getTangentForOffset(reached)!;
    // The little ferry at the current stop.
    final f = at.position + const Offset(0, 4);
    canvas.drawPath(Path()..addPolygon([f + const Offset(-22, 0), f + const Offset(22, 0), f + const Offset(17, 8), f + const Offset(-17, 8)], true), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(f.dx - 13, f.dy - 8, 26, 8), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(f.dx - 2, f.dy - 16, 5, 8), Paint()..color = const Color(0xFFFFD000));
  }
  for (var i = 0; i < _piers.length; i++) {
    final (name, first, done) = _piers[i];
    final p = pts[i];
    final current = i == 2;
    final locked = i > 2;
    final r = current ? 34.0 : 28.0;
    if (current) canvas.drawCircle(p, r + 14, Paint()..color = const Color(0xFFFF4FB0).withValues(alpha: 0.3));
    canvas.drawCircle(p + const Offset(0, 4), r, Paint()..color = Colors.black.withValues(alpha: 0.4));
    canvas.drawCircle(p, r, Paint()
      ..shader = ui.Gradient.linear(p - Offset(0, r), p + Offset(0, r),
          locked ? const [Color(0xFF7A7090), Color(0xFF4A4260)] : done ? const [Color(0xFFFFE066), Color(0xFFE0A000)] : const [Color(0xFFFF7AC6), Color(0xFFE0247A)]));
    canvas.drawCircle(p, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white);
    // An anchor for a pier.
    final a = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = locked ? const Color(0xFFC8C0D8) : Colors.white;
    canvas.drawLine(p + const Offset(0, -12), p + const Offset(0, 12), a);
    canvas.drawLine(p + const Offset(-7, -6), p + const Offset(7, -6), a);
    canvas.drawArc(Rect.fromCircle(center: p + const Offset(0, 2), radius: 11), 0.3, pi - 0.6, false, a);
    canvas.drawCircle(p + const Offset(0, -15), 3.5, a);
    final labelLeft = i.isEven;
    final lx = labelLeft ? p.dx + r + 10 : p.dx - r - 10 - 150;
    mockText(canvas, name, Offset(lx, p.dy - 26), 18, locked ? const Color(0xFFB0A8C8) : Colors.white, centre: false, width: 150);
    mockText(canvas, 'Görev $first–${first + 4}', Offset(lx, p.dy - 2), 12.5, _soft, centre: false, width: 150, weight: FontWeight.w700);
    for (var s = 0; s < 3; s++) {
      _star(canvas, Offset(lx + 9 + s * 19, p.dy + 26), 8, on: done || (current && s == 0));
    }
  }
  // Top bar.
  final top = RRect.fromRectAndRadius(Rect.fromLTWH(14, 46, w - 28, 62), const Radius.circular(20));
  _panelBox(canvas, top, color: const Color(0xEE2A2440));
  mockText(canvas, 'Vapur Hattı', Offset(34, 56), 22, const Color(0xFFFF4FB0), centre: false, width: 200);
  mockText(canvas, 'Zincir Küpler görevleri', Offset(34, 82), 12.5, _soft, centre: false, width: 200, weight: FontWeight.w700);
  _star(canvas, Offset(w - 120, 77), 12);
  mockText(canvas, '27/150', Offset(w - 102, 64), 20, Colors.white, centre: false, width: 100);
  // The mission card for the current stop.
  final card = RRect.fromRectAndRadius(Rect.fromLTWH(14, h - 200, w - 28, 186), const Radius.circular(24));
  _panelBox(canvas, card, color: const Color(0xF52A2440), border: const Color(0xFFFF4FB0));
  mockText(canvas, 'BEŞİKTAŞ · GÖREV 13', Offset(34, h - 186), 13, const Color(0xFFFFE066), centre: false, width: 300);
  mockText(canvas, '90 saniyede iki kez ×3 zincir yap', Offset(34, h - 164), 20, Colors.white, centre: false, width: 360);
  final goals = [('×3', 'zincir', '1/2'), ('90', 'saniye', ''), ('', 'çöp yok', '')];
  for (var i = 0; i < goals.length; i++) {
    final (big, small, prog) = goals[i];
    final g = RRect.fromRectAndRadius(Rect.fromLTWH(34 + i * 86.0, h - 128, 78, 54), const Radius.circular(14));
    canvas.drawRRect(g, Paint()..color = _well);
    if (big.isEmpty) {
      paintGarbageSlab(canvas, Rect.fromLTWH(g.left + 14, g.top + 9, 50, 16));
      canvas.drawLine(Offset(g.left + 12, g.top + 30), Offset(g.right - 12, g.top + 4), Paint()
        ..strokeWidth = 3
        ..color = Colors.white);
    } else {
      mockText(canvas, big, Offset(g.outerRect.center.dx, g.top + 18), 20, const Color(0xFFFFE066), width: 78);
    }
    mockText(canvas, prog.isEmpty ? small : '$small · $prog', Offset(g.outerRect.center.dx, g.top + 42), 11.5, _soft, width: 78, weight: FontWeight.w700);
  }
  mockButton(canvas, Rect.fromLTWH(w - 132, h - 126, 100, 52), 'OYNA', colors: const [Color(0xFFFF7AC6), Color(0xFFE0247A)], shade: const Color(0xFF8A1550));
  mockText(canvas, 'Ödül: 1 Saati Durdur · ilk 3 yıldızda Lokum kartı', Offset(34, h - 56), 13, const Color(0xFFFFD0EC), centre: false, width: 360, weight: FontWeight.w700);
}

void missions(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF15111F));
  mockLabel(canvas, 'ZİNCİR · VAPUR HATTI', Offset(size.width / 2, 44), 30);
  mockText(canvas, 'Boğaz\'ın iskelelerinde 150 görev: her iskele 5 görev, her görev 3 yıldız', Offset(size.width / 2, 84), 15, const Color(0xFFE6D6FF), width: 820, weight: FontWeight.w700);
  const phone = Size(400, 860);
  mockPhone(canvas, Rect.fromLTWH(26, 120, phone.width, phone.height), _missionScreen);
  // The kinds of missions, on the right.
  final x = 470.0;
  mockText(canvas, 'Görev türleri', Offset(x, 130), 22, const Color(0xFFFF4FB0), centre: false, width: 380);
  final kinds = [
    ('Zincir', 'Belli sürede ×3, ×4 zincir yap', 'chain'),
    ('Çöp kır', 'Tahtadaki kırmızı blokları kır', 'garbage'),
    ('Skor', 'Süre bitmeden hedef skora ulaş', 'score'),
    ('Dayan', '2 dakika tavana değmeden kal', 'clock'),
    ('Bulmaca', 'Hazır tahtayı N hamlede temizle', 'puzzle'),
    ('Rakip', 'Limon\'u bir maçta yen', 'versus'),
  ];
  for (var i = 0; i < kinds.length; i++) {
    final (name, text, kind) = kinds[i];
    final y = 170.0 + i * 92;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 384, 80), const Radius.circular(18));
    _panelBox(canvas, r);
    final ic = Rect.fromLTWH(x + 14, y + 14, 52, 52);
    canvas.drawRRect(RRect.fromRectAndRadius(ic, const Radius.circular(12)), Paint()..color = _well);
    switch (kind) {
      case 'chain':
        mockLabel(canvas, '×3', ic.center, 24);
      case 'garbage':
        paintGarbageSlab(canvas, Rect.fromCenter(center: ic.center, width: 40, height: 16));
      case 'score':
        mockText(canvas, '5K', ic.center, 22, Colors.white, width: 52);
      case 'clock':
        canvas.drawCircle(ic.center, 16, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..color = Colors.white);
        canvas.drawLine(ic.center, ic.center + const Offset(0, -10), Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white);
        canvas.drawLine(ic.center, ic.center + const Offset(7, 3), Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white);
      case 'puzzle':
        for (var k = 0; k < 4; k++) {
          paintChainCube(canvas, Rect.fromLTWH(ic.left + 6 + (k % 2) * 20, ic.top + 6 + (k ~/ 2) * 20, 19, 19), chainColors[ChainColor.values[k]]!);
        }
      default:
        paintEksiLimon(canvas, ic.center + const Offset(0, 4), 34);
    }
    mockText(canvas, name, Offset(x + 80, y + 14), 19, Colors.white, centre: false, width: 290);
    mockText(canvas, text, Offset(x + 80, y + 44), 14, _soft, centre: false, width: 290, weight: FontWeight.w700);
  }
  final note = RRect.fromRectAndRadius(Rect.fromLTWH(x, 734, 384, 210), const Radius.circular(18));
  _panelBox(canvas, note, color: const Color(0xFF2A2440), border: const Color(0xFFFFE066));
  paintLokum(canvas, Offset(x + 52, 808), 70, pose: LokumPose.point, outfit: LokumOutfit.captain);
  mockText(canvas, 'Her iskeleye varınca', Offset(x + 100, 750), 17, const Color(0xFFFFE066), centre: false, width: 270);
  mockText(canvas, '• o semtin kartpostalı\n• Zincir için yeni küp görünümü ya da arka plan\n• son iskelede (Anadolu Kavağı) altın sandık',
      Offset(x + 100, 778), 14, Colors.white, centre: false, width: 272, weight: FontWeight.w700, height: 1.35);
  mockText(canvas, 'Sonsuz ve Zamana Karşı olduğu gibi kalır; Vapur Hattı ayrı bir giriş olur.', Offset(x + 192, 912), 13, _soft, width: 360, weight: FontWeight.w700);
}

// --------------------------------------------------------------- puzzle --

const _puzzle = [
  '......',
  '......',
  '......',
  '......',
  '...o..',
  '..oyo.',
  '.mmymy',
  'gbgbgb',
];

void _puzzleScreen(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  _screenBg(canvas, size);
  // Header.
  final top = RRect.fromRectAndRadius(Rect.fromLTWH(14, 48, w - 28, 92), const Radius.circular(22));
  _panelBox(canvas, top);
  mockText(canvas, 'BULMACA 14 · HALİÇ', Offset(32, 60), 13, _soft, centre: false, width: 240);
  mockText(canvas, 'Tek hamlede ×3 zincir', Offset(32, 80), 22, Colors.white, centre: false, width: 240);
  final moves = RRect.fromRectAndRadius(Rect.fromLTWH(w - 132, 62, 100, 64), const Radius.circular(16));
  canvas.drawRRect(moves, Paint()..color = _well);
  mockText(canvas, 'HAMLE', Offset(moves.outerRect.center.dx, 76), 12, _soft, width: 100);
  mockText(canvas, '1', Offset(moves.outerRect.center.dx, 104), 32, const Color(0xFFFFE066), width: 100);
  // The board and the hint.
  const cols = 6;
  final cell = (w - 80) / cols;
  final board = Rect.fromLTWH(40, 170, cell * cols, cell * _puzzle.length);
  _board(canvas, board, _puzzle, cursor: (3, 6));
  final hint = Offset(board.left + cell * 4, board.top + cell * 6.5);
  canvas.drawCircle(hint, cell * 1.4, Paint()..shader = ui.Gradient.radial(hint, cell * 1.4, [const Color(0xFFFFE066).withValues(alpha: 0.35), const Color(0xFFFFE066).withValues(alpha: 0)]));
  // A two-headed arrow over the swap.
  for (final (stroke, color) in [(7.0, const Color(0xFF110D1C)), (3.5, const Color(0xFFFFE066))]) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final y = board.top + cell * 5.82;
    final a = Offset(hint.dx - cell * 0.55, y), b = Offset(hint.dx + cell * 0.55, y);
    canvas.drawLine(a, b, p);
    canvas.drawPath(Path()
      ..moveTo(a.dx + 8, y - 7)
      ..lineTo(a.dx, y)
      ..lineTo(a.dx + 8, y + 7), p);
    canvas.drawPath(Path()
      ..moveTo(b.dx - 8, y - 7)
      ..lineTo(b.dx, y)
      ..lineTo(b.dx - 8, y + 7), p);
  }
  // Lokum hints, the buttons.
  paintLokum(canvas, Offset(62, h - 140), 78, pose: LokumPose.point);
  mockBubble(canvas, Rect.fromLTWH(108, h - 196, 290, 48), 'Pembeleri yan yana getir, gerisi kendiliğinden zincirlenir!', size: 13.5);
  final labels = ['Geri al', 'İpucu', 'Baştan'];
  for (var i = 0; i < 3; i++) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(24 + i * ((w - 48) / 3), h - 88, (w - 48) / 3 - 10, 56), const Radius.circular(18));
    _panelBox(canvas, r, border: i == 1 ? const Color(0xFFFFE066) : null);
    mockText(canvas, labels[i], r.outerRect.center, 16, i == 1 ? const Color(0xFFFFE066) : Colors.white, width: 120);
  }
}

void _packsScreen(Canvas canvas, Size size) {
  final w = size.width;
  _screenBg(canvas, size);
  mockText(canvas, 'Bulmacalar', Offset(w / 2, 76), 26, const Color(0xFFFF4FB0), width: 300);
  mockText(canvas, 'Süre yok, yükselme yok; sadece düşün', Offset(w / 2, 106), 14, _soft, width: 340, weight: FontWeight.w700);
  const packs = [
    ('Eminönü', 'Çırak', 20, 20, 1),
    ('Haliç', 'Kalfa', 20, 13, 2),
    ('Galata', 'Usta', 20, 0, 3),
    ('Boğaziçi', 'Zincir ustası', 20, 0, 4),
  ];
  for (var i = 0; i < packs.length; i++) {
    final (name, level, total, done, chap) = packs[i];
    final y = 140.0 + i * 168;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(20, y, w - 40, 152), const Radius.circular(22));
    canvas.save();
    canvas.clipRRect(r);
    canvas.translate(r.left, r.top);
    paintStoryScene(canvas, r.outerRect.size, chap == 1 ? 0 : chap == 2 ? 3 : chap == 3 ? 4 : 2, t: 6);
    canvas.restore();
    canvas.drawRRect(r, Paint()..shader = ui.Gradient.linear(r.outerRect.centerLeft, r.outerRect.centerRight, [const Color(0xF0231D36), const Color(0x40231D36)]));
    final locked = i >= 3;
    canvas.drawRRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = i == 1 ? 3.5 : 2
      ..color = i == 1 ? const Color(0xFFFF4FB0) : Colors.white.withValues(alpha: 0.6));
    mockText(canvas, '${i * 20 + 1}–${i * 20 + 20}', Offset(40, y + 18), 13, _soft, centre: false, width: 200);
    mockText(canvas, name, Offset(40, y + 38), 26, Colors.white, centre: false, width: 220);
    mockText(canvas, level, Offset(40, y + 74), 15, const Color(0xFFFFE066), centre: false, width: 220);
    if (locked) {
      mockText(canvas, 'Vapur Hattı\'nda Bebek\'e varınca açılır', Offset(40, y + 108), 13, _soft, centre: false, width: 260, weight: FontWeight.w700);
    } else {
      mockProgress(canvas, Rect.fromLTWH(40, y + 112, 180, 14), done / total, colors: const [Color(0xFFFF7AC6), Color(0xFFE0247A)], track: _well);
      mockText(canvas, '$done/$total', Offset(232, y + 106), 14, Colors.white, centre: false, width: 80);
    }
  }
}

void puzzle(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF15111F));
  mockLabel(canvas, 'ZİNCİR · BULMACA MODU', Offset(size.width / 2, 44), 30);
  mockText(canvas, 'Hazır bir tahta, sınırlı hamle: küpler yükselmez, süre işlemez. 80 bulmaca, 4 paket.', Offset(size.width / 2, 84), 15, const Color(0xFFE6D6FF), width: 820, weight: FontWeight.w700);
  const phone = Size(400, 860);
  mockPhone(canvas, Rect.fromLTWH(26, 120, phone.width, phone.height), _puzzleScreen);
  mockPhone(canvas, Rect.fromLTWH(size.width - 26 - phone.width, 120, phone.width, phone.height), _packsScreen);
  mockText(canvas, 'Bulmaca · İpucu Lokum\'dan, geri alma sınırsız', Offset(26 + phone.width / 2, 1010), 15, const Color(0xFFFFE08A), width: 400);
  mockText(canvas, 'Paketler · İstanbul semtleriyle zorlaşır', Offset(size.width - 26 - phone.width / 2, 1010), 15, const Color(0xFFFFE08A), width: 400);
}

// --------------------------------------------------------------- versus --

const _mine = [
  'GGGG..',
  '......',
  '......',
  '......',
  '.....y',
  'm...bm',
  'gy.mby',
  'bgymyg',
  'ybmgbm',
  'gmybgy',
];

const _theirs = [
  '......',
  '......',
  'GGGGGG',
  'GGG...',
  'b..y..',
  'mgybm.',
  'ybmgyb',
  'gmbymg',
];

void _versusScreen(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  _screenBg(canvas, size);
  // Top: me against Limon, the score, his little board.
  final top = RRect.fromRectAndRadius(Rect.fromLTWH(14, 46, w - 28, 160), const Radius.circular(22));
  _panelBox(canvas, top);
  paintLokum(canvas, const Offset(52, 92), 54, outfit: LokumOutfit.captain);
  mockText(canvas, 'SEN', Offset(88, 72), 13, _soft, centre: false, width: 80);
  mockText(canvas, '1', Offset(88, 88), 30, Colors.white, centre: false, width: 80);
  mockText(canvas, 'set', Offset(122, 98), 13, _soft, centre: false, width: 40);
  paintEksiLimon(canvas, const Offset(52, 166), 44);
  mockText(canvas, 'LİMON KALFA', Offset(88, 146), 13, const Color(0xFFFFE066), centre: false, width: 120);
  mockText(canvas, '1', Offset(88, 162), 30, Colors.white, centre: false, width: 80);
  mockText(canvas, 'set', Offset(122, 172), 13, _soft, centre: false, width: 40);
  mockText(canvas, 'SÜRE', Offset(200, 72), 13, _soft, centre: false, width: 70);
  mockText(canvas, '1:12', Offset(200, 90), 28, Colors.white, centre: false, width: 100);
  final small = Rect.fromLTWH(w - 118, 60, 90, 120);
  _board(canvas, small, _theirs, frame: 4);
  // My attack flying to his board.
  final from = Offset(w * 0.5, 420), to = Offset(small.center.dx, small.top + 30);
  final path = Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(w * 0.85, 300, to.dx, to.dy);
  for (final m in path.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += 10) {
      final t = d / m.length;
      canvas.drawCircle(m.getTangentForOffset(d)!.position, 2 + 3 * t, Paint()..color = const Color(0xFFFF4FB0).withValues(alpha: 0.3 + 0.6 * t));
    }
  }
  paintGarbageSlab(canvas, Rect.fromCenter(center: to + const Offset(0, 4), width: 60, height: 14));
  // Incoming garbage for me, warned above my board.
  final warn = RRect.fromRectAndRadius(Rect.fromLTWH(30, 222, 170, 32), const Radius.circular(16));
  canvas.drawRRect(warn, Paint()..color = const Color(0xFF5A1A2A));
  paintGarbageSlab(canvas, Rect.fromLTWH(40, 230, 40, 16));
  mockText(canvas, 'geliyor: 4 kare', Offset(88, 228), 14, const Color(0xFFFFB0B8), centre: false, width: 120);
  // My board.
  const cols = 6;
  final cell = (w - 84) / cols;
  final board = Rect.fromLTWH(42, 270, cell * cols, cell * _mine.length);
  _board(canvas, board, _mine, cursor: (2, 6));
  mockLabel(canvas, 'ZİNCİR ×3', Offset(w * 0.46, 430), 40);
  mockText(canvas, 'Limon\'a 6 kare çöp!', Offset(w * 0.5, 470), 16, const Color(0xFFFFD0EC), width: 200);
  // Bottom.
  final up = RRect.fromRectAndRadius(Rect.fromLTWH(w / 2 - 90, h - 74, 180, 50), const Radius.circular(16));
  _panelBox(canvas, up);
  mockText(canvas, 'Yükselt', up.outerRect.center, 17, Colors.white, width: 180);
}

void _rivalsScreen(Canvas canvas, Size size) {
  final w = size.width;
  _screenBg(canvas, size);
  mockText(canvas, 'Rakibini seç', Offset(w / 2, 78), 26, const Color(0xFFFF4FB0), width: 300);
  mockText(canvas, 'Zincirler ve kombolar rakibe çöp bloğu yollar', Offset(w / 2, 108), 14, _soft, width: 360, weight: FontWeight.w700);
  const rivals = [
    ('Limon Çırak', 'Kolay · yavaş düşünür, zincir kurmaz', '3 galibiyet', 0.7, 'Kazandın: Lokum küp görünümü'),
    ('Limon Kalfa', 'Orta · ×2 zincirler kurar', '1 galibiyet', 0.85, 'İlk galibiyet: Çini küpler'),
    ('Ekşi Limon', 'Usta · ×3 zincirle saldırır, hızlıdır', 'henüz yok', 1.0, 'İlk galibiyet: Altın Limon tacı'),
  ];
  for (var i = 0; i < rivals.length; i++) {
    final (name, text, record, scale, prize) = rivals[i];
    final y = 140.0 + i * 196;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(20, y, w - 40, 180), const Radius.circular(22));
    _panelBox(canvas, r, border: i == 1 ? const Color(0xFFFF4FB0) : null);
    final c = Offset(80, y + 74);
    canvas.drawCircle(c, 48, Paint()..color = _well);
    paintEksiLimon(canvas, c + const Offset(0, 6), 72 * scale, laugh: i == 2);
    mockText(canvas, name, Offset(144, y + 22), 22, Colors.white, centre: false, width: 230);
    mockText(canvas, text, Offset(144, y + 54), 13.5, _soft, centre: false, width: 230, weight: FontWeight.w700);
    mockText(canvas, record, Offset(144, y + 96), 14, const Color(0xFFFFE066), centre: false, width: 230);
    for (var k = 0; k < 3; k++) {
      final on = i == 0 || (i == 1 && k == 0);
      canvas.drawCircle(Offset(152 + k * 22.0, y + 132), 8, Paint()..color = on ? const Color(0xFFFF4FB0) : _well);
    }
    final prizeBox = RRect.fromRectAndRadius(Rect.fromLTWH(36, y + 140, w - 72, 30), const Radius.circular(12));
    canvas.drawRRect(prizeBox, Paint()..color = _well);
    mockText(canvas, prize, prizeBox.outerRect.center, 13, i == 0 ? const Color(0xFF8AF0B0) : Colors.white, width: w - 80);
  }
  mockButton(canvas, Rect.fromLTWH(60, size.height - 100, w - 120, 58), 'MAÇA BAŞLA', colors: const [Color(0xFFFF7AC6), Color(0xFFE0247A)], shade: const Color(0xFF8A1550));
}

void versus(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF15111F));
  mockLabel(canvas, 'ZİNCİR · LİMON\'A KARŞI', Offset(size.width / 2, 44), 30);
  mockText(canvas, 'Bilgisayara karşı maç: senin zincirlerin onun tahtasına çöp düşürür, onunkiler seninkine. Tavana ilk değen seti kaybeder; 3 setin 2\'sini alan kazanır.',
      Offset(size.width / 2, 88), 15, const Color(0xFFE6D6FF), width: 820, weight: FontWeight.w700);
  const phone = Size(400, 860);
  mockPhone(canvas, Rect.fromLTWH(26, 130, phone.width, phone.height), _versusScreen);
  mockPhone(canvas, Rect.fromLTWH(size.width - 26 - phone.width, 130, phone.width, phone.height), _rivalsScreen);
  mockText(canvas, 'Maç · rakibin tahtası köşede küçük', Offset(26 + phone.width / 2, 1020), 15, const Color(0xFFFFE08A), width: 400);
  mockText(canvas, 'Rakipler · üç zorluk, her biri bir ödül', Offset(size.width - 26 - phone.width / 2, 1020), 15, const Color(0xFFFFE08A), width: 400);
  mockText(canvas, 'Masaüstünde iki tahta yan yana, aynı boyda durur.', Offset(size.width / 2, 1054), 14, const Color(0xFFC9B8E6), width: 820, weight: FontWeight.w700);
}

void main() {
  setUpAll(mockFonts);
  testWidgets('missions', (tester) => mockSave(tester, const Size(880, 1010), missions, 'asama5-gorevler.png', scale: 2));
  testWidgets('puzzle', (tester) => mockSave(tester, const Size(880, 1040), puzzle, 'asama5-bulmaca.png', scale: 2));
  testWidgets('versus', (tester) => mockSave(tester, const Size(880, 1080), versus, 'asama5-rakip.png', scale: 2));
}
