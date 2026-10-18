// Mock-up of the first Vapur Hattı mission as a guided first chain, and the
// "how to" card before the chain missions after it.
//   flutter test tool/chain_tutorial_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): zincir-ogretici.png.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show chainColors, paintChainCube;
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

import 'mock_kit.dart';

const _soft = Color(0xFFD9C8F5);
const _bg = Color(0xFF2A2340);
const _well = Color(0xFF120E1E);

const _map = {'Y': ChainColor.yellow, 'M': ChainColor.magenta, 'B': ChainColor.blue, 'G': ChainColor.green, 'O': ChainColor.orange};

/// The board before the swap: the bottom row's yellow and blue swap, three
/// blues go, the yellow above falls onto two yellows: ×2.
const _start = [
  '......',
  '......',
  '......',
  '..Y...',
  'BBYBYG',
  'MGOGBM',
  'GOMBMO',
];

/// The rows as [rows], with cells [hide] gone and [lift] cubes drawn [up]
/// cells higher; [glow] cells shine; [dim] fades all but [keep].
void _board(Canvas canvas, Rect r, List<String> rows, {Set<(int, int)> hide = const {}, Set<(int, int)> glow = const {}, Set<(int, int)> keep = const {}, bool dim = false, Map<(int, int), double> lift = const {}}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(18));
  canvas.drawRRect(rr, Paint()..color = _well);
  final s = r.width / 6;
  final top = r.bottom - rows.length * s - 6;
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < 6; x++) {
      final ch = rows[y][x];
      if (ch == '.' || hide.contains((x, y))) continue;
      final up = lift[(x, y)] ?? 0;
      final cell = Rect.fromLTWH(r.left + x * s, top + (y - up) * s, s, s).deflate(s * 0.05);
      if (glow.contains((x, y))) {
        canvas.drawCircle(cell.center, s * 0.8, Paint()..shader = ui.Gradient.radial(cell.center, s * 0.8, const [Color(0xCCFFFFFF), Color(0x00FFFFFF)]));
      }
      paintChainCube(canvas, cell, chainColors[_map[ch]!]!);
      if (dim && !keep.contains((x, y))) canvas.drawRRect(RRect.fromRectAndRadius(cell, Radius.circular(s * 0.18)), Paint()..color = _well.withValues(alpha: 0.65));
    }
  }
}

Rect _cell(Rect r, int rows, int x, int y) {
  final s = r.width / 6;
  return Rect.fromLTWH(r.left + x * s, r.bottom - rows * s - 6 + y * s, s, s);
}

void _hand(Canvas canvas, Offset tip, double size) {
  // A pointing hand: a finger and a palm, white with an outline.
  final ink = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xFF2A1A40);
  final fill = Paint()..color = Colors.white;
  final finger = RRect.fromRectAndRadius(Rect.fromLTWH(tip.dx - size * 0.11, tip.dy, size * 0.22, size * 0.55), Radius.circular(size * 0.11));
  final palm = RRect.fromRectAndRadius(Rect.fromLTWH(tip.dx - size * 0.16, tip.dy + size * 0.38, size * 0.62, size * 0.5), Radius.circular(size * 0.18));
  for (final p in [palm, finger]) {
    canvas.drawRRect(p, fill);
    canvas.drawRRect(p, ink);
  }
}

void _arrow(Canvas canvas, Offset from, Offset to, {Color color = Colors.white}) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(from, to, p);
  final dir = (to - from) / (to - from).distance;
  final n = Offset(-dir.dy, dir.dx);
  canvas.drawPath(Path()
    ..moveTo((to - dir * 12 + n * 9).dx, (to - dir * 12 + n * 9).dy)
    ..lineTo(to.dx, to.dy)
    ..lineTo((to - dir * 12 - n * 9).dx, (to - dir * 12 - n * 9).dy), p);
}

void _top(Canvas canvas, Size size, String goal, String progress) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
  mockText(canvas, 'Vapur Hattı · Eminönü', Offset(size.width / 2, 66), 22, const Color(0xFFFF4FD8), width: size.width);
  final card = RRect.fromRectAndRadius(Rect.fromLTWH(16, 96, size.width - 32, 92), const Radius.circular(20));
  canvas.drawRRect(card, Paint()..color = const Color(0xFF3A3152));
  mockText(canvas, 'GÖREV 1 · İLK ZİNCİRİN', const Offset(32, 108), 13, const Color(0xFF9D93C2), centre: false, width: 300);
  mockText(canvas, goal, const Offset(32, 128), 18, Colors.white, centre: false, width: size.width - 70, lines: 2);
  mockProgress(canvas, Rect.fromLTWH(32, 162, size.width - 64, 14), progress == '1 / 1' ? 1 : 0, colors: const [Color(0xFF6BF0A0), Color(0xFF1FB85A)], track: const Color(0xFF221B36));
}

Rect _boardRect(Size size) => Rect.fromLTWH(40, 260, size.width - 80, (size.width - 80) / 6 * 7 + 12);

void _step1(Canvas canvas, Size size) {
  _top(canvas, size, 'Lokum\'un gösterdiği küpü kaydır', '0 / 1');
  final r = _boardRect(size);
  final a = _cell(r, 7, 2, 4), b = _cell(r, 7, 3, 4);
  _board(canvas, r, _start, dim: true, keep: {(2, 4), (3, 4), (0, 4), (1, 4), (2, 3), (4, 4)});
  // The two to swap, framed.
  final frame = RRect.fromRectAndRadius(Rect.fromLTRB(a.left, a.top, b.right, b.bottom).inflate(4), const Radius.circular(10));
  canvas.drawRRect(frame, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..color = const Color(0xFFFFE066));
  _arrow(canvas, a.center + const Offset(0, -38), b.center + const Offset(6, -38), color: const Color(0xFFFFE066));
  _hand(canvas, a.center + const Offset(-4, 4), 64);
  paintLokum(canvas, Offset(70, size.height - 70), 80, pose: LokumPose.point, pointLeft: false);
  mockBubble(canvas, Rect.fromLTWH(120, size.height - 136, size.width - 136, 62), 'Sarıyı sağa kaydır, bakalım ne olacak!', size: 14.5);
}

void _step2(Canvas canvas, Size size) {
  _top(canvas, size, 'Lokum\'un gösterdiği küpü kaydır', '0 / 1');
  final r = _boardRect(size);
  const swapped = ['......', '......', '......', '..Y...', 'BBBYYG', 'MGOGBM', 'GOMBMO'];
  _board(canvas, r, swapped, glow: {(0, 4), (1, 4), (2, 4)});
  mockLabel(canvas, '3 KÜP!', _cell(r, 7, 1, 4).center + const Offset(0, -44), 22);
  // The yellow above drops into the gap.
  final y = _cell(r, 7, 2, 3);
  _arrow(canvas, y.center + const Offset(0, -10), y.center + Offset(0, y.height * 0.85));
  paintLokum(canvas, Offset(70, size.height - 70), 80, pose: LokumPose.wow);
  mockBubble(canvas, Rect.fromLTWH(120, size.height - 136, size.width - 136, 62), 'Maviler gitti; üstteki sarı düşüyor...', size: 14.5);
}

void _step3(Canvas canvas, Size size) {
  _top(canvas, size, 'Lokum\'un gösterdiği küpü kaydır', '1 / 1');
  final r = _boardRect(size);
  const fallen = ['......', '......', '......', '......', '..YYYG', 'MGOGBM', 'GOMBMO'];
  _board(canvas, r, fallen, glow: {(2, 4), (3, 4), (4, 4)});
  final c = _cell(r, 7, 3, 4).center;
  for (final (dx, dy, k) in [(-70.0, -40.0, 12.0), (64.0, -60.0, 14.0), (90.0, 10.0, 9.0), (-40.0, 30.0, 8.0)]) {
    paintSparkle(canvas, c + Offset(dx, dy), k, dx < 0 ? Colors.white : const Color(0xFFFFE066));
  }
  mockLabel(canvas, 'ZİNCİR ×2!', c + const Offset(0, -90), 38);
  paintLokum(canvas, Offset(70, size.height - 70), 80, pose: LokumPose.cheer);
  mockBubble(canvas, Rect.fromLTWH(120, size.height - 136, size.width - 136, 62), 'İşte zincir! Düşen küp yeniden eşleşti.', size: 14.5);
}

/// The card before the next chain missions: how a chain works, in three
/// small pictures.
void _howTo(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _bg.withValues(alpha: 0.6));
  _top(canvas, size, '100 saniyede ×2 zincir yap', '0 / 1');
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xCC0E0820));
  final card = Rect.fromLTWH(20, 150, size.width - 40, 560);
  mockCard(canvas, RRect.fromRectAndRadius(card, const Radius.circular(28)));
  mockText(canvas, 'Zincir nasıl yapılır?', Offset(card.center.dx, card.top + 34), 24, mockInk, width: card.width);
  final steps = [
    ('1', 'Eşleştir', _start, <(int, int)>{(0, 4), (1, 4), (2, 4)}, const ['......', '......', '......', '..Y...', 'BBBYYG', 'MGOGBM', 'GOMBMO']),
    ('2', 'Üstteki küp düşer', _start, <(int, int)>{}, const ['......', '......', '......', '..Y...', '...YYG', 'MGOGBM', 'GOMBMO']),
    ('3', 'Yeniden eşleşirse ×2!', _start, <(int, int)>{(2, 4), (3, 4), (4, 4)}, const ['......', '......', '......', '......', '..YYYG', 'MGOGBM', 'GOMBMO']),
  ];
  for (final (i, (n, text, _, glow, rows)) in steps.indexed) {
    final y = card.top + 80 + i * 136.0;
    canvas.drawCircle(Offset(card.left + 34, y + 54), 18, Paint()..color = const Color(0xFFFF5FB8));
    mockText(canvas, n, Offset(card.left + 34, y + 54), 18, Colors.white, width: 30);
    // Only the bottom four rows: the chain happens there.
    final b = Rect.fromLTWH(card.left + 62, y, 130, 130 / 6 * 4 + 12);
    _board(canvas, b, rows.sublist(3), glow: {for (final (gx, gy) in glow) (gx, gy - 3)});
    if (i == 1) {
      final cube = _cell(b, 4, 2, 0);
      _arrow(canvas, cube.center, cube.center + Offset(0, cube.height * 0.9), color: const Color(0xFFFFE066));
    }
    mockText(canvas, text, Offset(card.left + 206, y + 44), 17, mockInk, centre: false, width: card.width - 220, lines: 2);
  }
  mockButton(canvas, Rect.fromLTWH(card.left + 30, card.bottom - 70, card.width - 60, 50), 'BAŞLA');
}

void _sheet(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));
  const phones = [
    ('1 · Lokum gösterir', 'Görev 1 hazır bir tahtayla başlar. Her yer söner, yalnız iki küp parlar; el ve ok kaydırmayı gösterir.'),
    ('2 · Eşleşme patlar', 'Üç mavi gider. Lokum "üstteki sarı düşüyor" der; ok küpün düşeceği yeri gösterir.'),
    ('3 · Zincir!', 'Düşen sarı öbür iki sarıyla eşleşir: ZİNCİR ×2. Görev biter, yıldızlar gelir.'),
    ('4 · Sonraki zincir görevleri', 'Başlarken bu kart çıkar: 3 resimde zincir. Görev sırasında ipucu da var.'),
  ];
  for (var i = 0; i < phones.length; i++) {
    final left = 40 + i * 440.0;
    mockText(canvas, phones[i].$1, Offset(left + 195, 44), 24, Colors.white, width: 420);
    mockText(canvas, phones[i].$2, Offset(left + 195, 96), 14.5, _soft, width: 400, weight: FontWeight.w600, lines: 3);
    mockPhone(canvas, Rect.fromLTWH(left, 150, 390, 844), [_step1, _step2, _step3, _howTo][i]);
  }
}

void main() {
  setUpAll(mockFonts);

  testWidgets('chain tutorial', (tester) async {
    await mockSave(tester, const Size(40 * 2 + 390 * 4 + 50 * 3, 150 + 844 + 40), _sheet, 'zincir-ogretici.png', scale: 2);
  });
}
