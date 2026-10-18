// Mock-up of personal high scores for the falling-block games (Klasik and
// Süper Küpler): a top five when a game ends with the next goal, a bar to
// the record while playing, and every mode's list on the game's page.
//   flutter test tool/records_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): rekorlar.png.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/game/render/block_sprites.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

import 'mock_kit.dart';

const _bg = Color(0xFF2A2340);
const _card = Color(0xFF3A3152);
const _edge = Color(0xFF15101F);
const _soft = Color(0xFFB8AEDA);
const _label = Color(0xFF8F86B0);
const _gold = Color(0xFFFACC15);
const _pink = Color(0xFFFF5FB8);
const _blocks = [Color(0xFF3B82F6), Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFA855F7), Color(0xFF06B6D4), Color(0xFFFACC15)];

void _t(Canvas canvas, String text, Offset at, double size, Color color, {double width = 300, FontWeight weight = FontWeight.w800}) =>
    mockText(canvas, text, at, size, color, centre: false, width: width, weight: weight);

void _box(Canvas canvas, RRect r, {Color fill = _card, Color border = _edge, double width = 2.5}) {
  canvas.drawRRect(r.shift(const Offset(0, 4)), Paint()..color = _edge);
  canvas.drawRRect(r, Paint()..color = fill);
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = border);
}

void _screen(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
  // A board behind, dimmed.
  const s = 32.0;
  final o = Offset((size.width - 10 * s) / 2, 140);
  canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 10 * s, 20 * s), Paint()..color = const Color(0xFF120E1E));
  for (var y = 12; y < 20; y++) {
    for (var x = 0; x < 10; x++) {
      if ((x * 7 + y * 3) % 9 == 0) continue;
      paintToyBlock(canvas, o + Offset(x * s, y * s), s, _blocks[(x + y) % 7], _edge);
    }
  }
}

/// One row of the list: place, score, when, and a highlight for this game.
void _row(Canvas canvas, Rect r, int place, String score, String when, {bool now = false, String? extra}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
  if (now) {
    canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.centerLeft, r.centerRight, const [Color(0xFFFF5FB8), Color(0xFFB45BFF)]));
  } else {
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.06));
  }
  final medal = place <= 3 ? const [Color(0xFFFACC15), Color(0xFFCBD5E1), Color(0xFFE59E5A)][place - 1] : const Color(0xFF5A4C86);
  canvas.drawCircle(Offset(r.left + 22, r.center.dy), 14, Paint()..color = medal);
  mockText(canvas, '$place', Offset(r.left + 22, r.center.dy), 15, place <= 3 ? const Color(0xFF3A2A00) : Colors.white, width: 30);
  _t(canvas, score, Offset(r.left + 46, r.center.dy - 12), 19, Colors.white, width: 140);
  _t(canvas, when, Offset(r.right - 128, r.center.dy - 9), 13.5, now ? Colors.white : _soft, width: 120, weight: FontWeight.w700);
  if (extra != null) {
    final tag = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 120, r.center.dy - 11, extra.length * 8.0 + 18, 22), const Radius.circular(11));
    canvas.drawRRect(tag, Paint()..color = Colors.white);
    mockText(canvas, extra, tag.center, 12, _pink, width: tag.width + 20);
  }
}

void _gameOver(Canvas canvas, Size size) {
  _screen(canvas, size);
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xBB0E0820));
  final panel = Rect.fromLTWH(18, 90, size.width - 36, 660);
  _box(canvas, RRect.fromRectAndRadius(panel, const Radius.circular(26)));
  mockText(canvas, 'Oyun bitti', Offset(panel.center.dx, panel.top + 36), 24, Colors.white, width: panel.width);
  mockText(canvas, 'Klasik Küpler · Normal', Offset(panel.center.dx, panel.top + 66), 14, _soft, width: panel.width, weight: FontWeight.w700);
  mockLabel(canvas, '12.480', Offset(panel.center.dx, panel.top + 116), 50);
  final badge = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(panel.center.dx, panel.top + 166), width: 190, height: 34), const Radius.circular(17));
  canvas.drawRRect(badge, Paint()..color = _pink);
  mockText(canvas, 'REKORLARINDA 2. SIRA!', badge.center, 14, Colors.white, width: 190);
  paintSparkle(canvas, badge.outerRect.topRight + const Offset(-6, 4), 9, _gold);
  paintSparkle(canvas, badge.outerRect.topLeft + const Offset(8, 2), 7, Colors.white);

  _t(canvas, 'REKORLARIN', Offset(panel.left + 22, panel.top + 204), 13, _label);
  final rows = [
    (1, '15.398', '12 Eki', false, null),
    (2, '12.480', 'şimdi', true, 'YENİ'),
    (3, '9.210', '16 Eki', false, null),
    (4, '8.770', '10 Eki', false, null),
    (5, '6.105', '9 Eki', false, null),
  ];
  for (final (i, (place, score, day, now, extra)) in rows.indexed) {
    _row(canvas, Rect.fromLTWH(panel.left + 16, panel.top + 228 + i * 54.0, panel.width - 32, 46), place, score, day, now: now, extra: extra);
  }
  // The next goal.
  final goal = RRect.fromRectAndRadius(Rect.fromLTWH(panel.left + 16, panel.top + 506, panel.width - 32, 56), const Radius.circular(16));
  canvas.drawRRect(goal, Paint()..color = const Color(0xFF221B36));
  paintGoldStar(canvas, Offset(goal.left + 28, goal.center.dy), 13);
  _t(canvas, 'Sıradaki hedef: 1. sıra', Offset(goal.left + 50, goal.top + 8), 15, Colors.white, width: 260);
  _t(canvas, 'Rekora 2.918 puan kaldı', Offset(goal.left + 50, goal.top + 29), 13, _soft, width: 260, weight: FontWeight.w700);
  mockButton(canvas, Rect.fromLTWH(panel.left + 16, panel.bottom - 76, panel.width / 2 - 24, 52), 'TEKRAR');
  mockButton(canvas, Rect.fromLTWH(panel.center.dx + 8, panel.bottom - 76, panel.width / 2 - 24, 52), 'MENÜ', colors: const [Color(0xFF8A7AC8), Color(0xFF5A4A8A)], shade: const Color(0xFF2A1A4A));
}

void _playing(Canvas canvas, Size size) {
  _screen(canvas, size);
  // The top bar: score, and a bar to the record.
  final top = RRect.fromRectAndRadius(Rect.fromLTWH(16, 50, size.width - 32, 76), const Radius.circular(20));
  _box(canvas, top);
  _t(canvas, 'PUAN', const Offset(32, 58), 12, _label);
  _t(canvas, '13.062', const Offset(32, 72), 26, Colors.white, width: 160);
  _t(canvas, 'SEVİYE 9', Offset(size.width - 120, 58), 12, _label, width: 100);
  _t(canvas, '86 satır', Offset(size.width - 120, 76), 18, Colors.white, width: 100);
  final bar = Rect.fromLTWH(16, 140, size.width - 32, 34);
  canvas.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(17)), Paint()..color = const Color(0xFF221B36));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * 0.85, bar.height), const Radius.circular(17)),
      Paint()..shader = ui.Gradient.linear(bar.centerLeft, bar.centerRight, const [Color(0xFFFF5FB8), Color(0xFFFACC15)]));
  paintGoldStar(canvas, Offset(bar.right - 18, bar.center.dy), 12);
  mockText(canvas, 'Rekora 2.336 kaldı', bar.center, 14, Colors.white, width: bar.width);
  // Lokum cheering at the side.
  paintLokum(canvas, Offset(size.width - 50, size.height - 90), 70, pose: LokumPose.cheer);
  mockBubble(canvas, Rect.fromLTWH(size.width - 250, size.height - 170, 190, 44), 'Rekor çok yakın!', size: 15, right: true);
}

void _page(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
  _t(canvas, 'Klasik Küpler', const Offset(24, 54), 26, Colors.white);
  // Mode tabs.
  final tabs = ['Normal', 'Rahat', 'Hız Koşusu', '3 Dakika'];
  var x = 16.0;
  for (final (i, tab) in tabs.indexed) {
    final w = tab.length * 9.0 + 28;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, 100, w, 34), const Radius.circular(17));
    canvas.drawRRect(r, Paint()..color = i == 0 ? _pink : const Color(0xFF3A3152));
    mockText(canvas, tab, r.center, 14, Colors.white, width: w);
    x += w + 8;
  }
  final card = Rect.fromLTWH(16, 152, size.width - 32, 640);
  _box(canvas, RRect.fromRectAndRadius(card, const Radius.circular(24)));
  paintGoldStar(canvas, Offset(card.left + 34, card.top + 36), 16);
  _t(canvas, 'Rekorların · Normal', Offset(card.left + 58, card.top + 22), 18, Colors.white, width: 260);
  final rows = ['15.398', '12.480', '9.210', '8.770', '6.105', '5.940', '4.320', '3.880', '2.410', '1.960'];
  const dates = ['12 Eki', '18 Eki', '16 Eki', '10 Eki', '9 Eki', '9 Eki', '8 Eki', '8 Eki', '7 Eki', '7 Eki'];
  for (var i = 0; i < rows.length; i++) {
    _row(canvas, Rect.fromLTWH(card.left + 14, card.top + 62 + i * 50.0, card.width - 28, 42), i + 1, rows[i], dates[i], now: i == 1);
  }
  _t(canvas, 'En uzun oyun: 112 satır · En hızlı 40 satır: 2:14', Offset(card.left + 18, card.bottom - 52), 13, _soft, width: card.width - 30, weight: FontWeight.w700);
}

void _sheet(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));
  const phones = [
    ('1 · Oyun bitince', 'İlk 5 rekor, bu oyun hangi sırada, bir de sıradaki hedef: "rekora 2.918 puan kaldı".'),
    ('2 · Oynarken', 'Puanın altında rekora giden bir çubuk; yaklaşınca Lokum gaz verir, geçince "REKOR!" çıkar.'),
    ('3 · Oyunun sayfasında', 'Her modun ilk 10 rekoru, tarihleriyle; en uzun oyun, en hızlı süre.'),
  ];
  for (var i = 0; i < 3; i++) {
    final left = 40 + i * 450.0;
    mockText(canvas, phones[i].$1, Offset(left + 195, 44), 25, Colors.white, width: 420);
    mockText(canvas, phones[i].$2, Offset(left + 195, 96), 14.5, _soft, width: 410, weight: FontWeight.w600, lines: 3);
    mockPhone(canvas, Rect.fromLTWH(left, 150, 390, 844), [_gameOver, _playing, _page][i]);
  }
}

void main() {
  setUpAll(mockFonts);

  testWidgets('records', (tester) async {
    await mockSave(tester, const Size(40 * 2 + 390 * 3 + 60 * 2, 150 + 844 + 40), _sheet, 'rekorlar.png', scale: 2);
  });
}
