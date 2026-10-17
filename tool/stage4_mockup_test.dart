// Mock-ups for stage four: Şeker Küpler chapters 7–12 (their İstanbul
// scenes and history), the five new obstacles, and the final against
// Ekşi Limon on Çamlıca.
//   flutter test tool/stage4_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): asama4-bolumler.png,
// asama4-engeller.png, asama4-final.png.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/ui/gift_art.dart';

import 'mock_kit.dart';


// ------------------------------------------------------------- the board --

const _sc = SugarColor.values;

void _tiles(Canvas canvas, Rect board, int cols, int rows) {
  final cell = board.width / cols;
  final tray = RRect.fromRectAndRadius(board.inflate(cell * 0.14), Radius.circular(cell * 0.35));
  canvas.drawRRect(tray.shift(Offset(0, cell * 0.14)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
  canvas.drawRRect(tray, Paint()..color = const Color(0xFF3A1270).withValues(alpha: 0.92));
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(board.left + x * cell, board.top + y * cell, cell, cell).deflate(1), Radius.circular(cell * 0.12)),
          Paint()..color = ((x + y).isEven ? const Color(0xFF4A1A85) : const Color(0xFF41167A)));
    }
  }
}

/// A mini board: [cells] gives each cell's content as one char:
/// 0–5 a candy, c chocolate, p pomegranate, > belt (candy painted by the
/// next char), K cake corner, d/D a door, l lemon slice, . empty.
void _mini(Canvas canvas, Rect board, List<String> rows, {Map<String, Color> doors = const {}}) {
  final cols = rows.first.length;
  final cell = board.width / cols;
  _tiles(canvas, board, cols, rows.length);
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < cols; x++) {
      final ch = rows[y][x];
      final r = Rect.fromLTWH(board.left + x * cell, board.top + y * cell, cell, cell);
      switch (ch) {
        case 'c':
          paintChocolate(canvas, r);
        case 'p':
          paintPomegranate(canvas, r);
        case 'l':
          paintLemonSlice(canvas, r, turn: x * 0.3);
        case 'K':
          paintCake(canvas, Rect.fromLTWH(r.left, r.top, cell * 2, cell * 2));
        case 'k':
          paintCake(canvas, Rect.fromLTWH(r.left, r.top, cell * 2, cell * 2), layers: 2);
        case 'r' || 'y' || 'b' || 'g':
          paintDoor(canvas, r, doors[ch] ?? Colors.red);
        case 'o':
          paintDoor(canvas, r, Colors.red, open: true);
        case '.' || '_':
          break;
        default:
          final n = int.tryParse(ch);
          if (n != null) paintCandy(canvas, r.deflate(cell * 0.04), _sc[n % 6]);
      }
    }
  }
}

void _arrow(Canvas canvas, Offset a, Offset b, {Color color = Colors.white}) {
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..color = color;
  canvas.drawLine(a, b, p);
  final d = (b - a) / (b - a).distance;
  final n = Offset(-d.dy, d.dx);
  canvas.drawPath(Path()
    ..moveTo((b - d * 10 + n * 7).dx, (b - d * 10 + n * 7).dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo((b - d * 10 - n * 7).dx, (b - d * 10 - n * 7).dy), p);
}

// --------------------------------------------------------------- screens --

const _chapters = [
  (7, 'Kadıköy', 'MÖ 685 · Kalkedon', "Megaralılar buraya Bizantion'dan 17 yıl önce yerleşti. Herodot'a göre karşı kıyıyı seçmedikleri için 'körler' diye anıldılar.", 'yayılan çikolata'),
  (8, 'Ortaköy', '1856 · Mecidiye Camii', "Sultan Abdülmecid'in yaptırdığı cami, Garabet ve Nigoğos Balyan'ın eseri. Suyun hemen kıyısında, Boğaz'ın en tanınan yapılarından.", 'narı aşağı indir'),
  (9, 'Boğaz Vapuru', '1872 · Sühulet', "Şirket-i Hayriye'nin Sühulet'i, Kabataş ile Üsküdar arasında at arabalarını taşıdı; dünyanın ilk araba vapurlarından biri.", 'taşıyıcı bantlar'),
  (10, 'İstiklal', '1875 · Tünel', "Karaköy'den Beyoğlu'na tırmanan Tünel, Londra'dan sonra dünyanın en eski ikinci yeraltı hattı. Yokuşu bir buçuk dakikada çıkar.", 'kat kat pasta'),
  (11, 'Balat', '1492 · Sefarad göçü', "İspanya'dan sürülen Sefarad Yahudileri II. Bayezid'in kabulüyle Balat'a yerleşti; Rum, Ermeni ve Yahudi mahalleleri yan yana yaşadı.", 'renkli kapılar'),
  (12, 'Çamlıca Tepesi', 'Final · iki yaka bir bakışta', "Şehrin iki yakasını ve Boğaz'ı birden gören tepe, 19. yüzyılda İstanbulluların mesire yeriydi; kaynak suyu ünlüydü.", 'Ekşi Limon ile final'),
];

/// 1. The six new chapters: scene, place, year, the history and the new piece.
void chapters(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF3A1470), Color(0xFF241050)]));
  mockLabel(canvas, '4. AŞAMA · YENİ BÖLÜMLER', Offset(size.width / 2, 46), 28);
  mockText(canvas, 'Şeker Küpler 61–120. seviye · her bölüm bir İstanbul durağı, bir gerçek tarih, bir yeni engel', Offset(size.width / 2, 86), 14.5, const Color(0xFFE6D6FF), width: 400, weight: FontWeight.w700);
  const cw = 197.0, ch = 336.0;
  for (var i = 0; i < _chapters.length; i++) {
    final (n, place, year, fact, piece) = _chapters[i];
    final x = 14 + (i % 2) * (cw + 8), y = 116 + (i ~/ 2) * (ch + 12);
    final card = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cw, ch), const Radius.circular(20));
    mockCard(canvas, card, colors: const [Color(0xFFFFF8F0), Color(0xFFFFEAF4)], border: n == 12 ? const Color(0xFFFFC21A) : Colors.white, width: n == 12 ? 4 : 2);
    final pic = RRect.fromRectAndCorners(Rect.fromLTWH(x, y, cw, 150), topLeft: const Radius.circular(20), topRight: const Radius.circular(20));
    canvas.save();
    canvas.clipRRect(pic);
    canvas.translate(x, y);
    paintStoryScene(canvas, const Size(cw, 150), i + 6);
    canvas.restore();
    if (n == 12) paintEksiLimon(canvas, Offset(x + cw - 40, y + 64), 54);
    canvas.drawCircle(Offset(x + 26, y + 26), 17, Paint()..color = n == 12 ? const Color(0xFFFFC21A) : const Color(0xFFE0247A));
    canvas.drawCircle(Offset(x + 26, y + 26), 17, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white);
    mockText(canvas, '$n', Offset(x + 26, y + 26), 17, n == 12 ? const Color(0xFF6A3A00) : Colors.white, width: 40);
    mockText(canvas, place, Offset(x + 14, y + 158), 20, mockInk, centre: false, width: cw - 28);
    mockText(canvas, year, Offset(x + 14, y + 186), 13.5, const Color(0xFFD06A00), centre: false, width: cw - 28);
    mockText(canvas, fact, Offset(x + 14, y + 208), 12.2, const Color(0xFF6A4A7A), centre: false, width: cw - 28, weight: FontWeight.w600, height: 1.22);
    // The new piece, as a chip at the bottom with its picture.
    final chip = RRect.fromRectAndRadius(Rect.fromLTWH(x + 10, y + ch - 46, cw - 20, 36), const Radius.circular(18));
    canvas.drawRRect(chip, Paint()..color = n == 12 ? const Color(0xFFFFE9A8) : const Color(0xFFF2E2FA));
    final icon = Rect.fromCenter(center: Offset(chip.left + 20, chip.center.dy), width: 28, height: 28);
    switch (n) {
      case 7:
        paintChocolate(canvas, icon);
      case 8:
        paintPomegranate(canvas, icon);
      case 9:
        paintBelt(canvas, icon);
      case 10:
        paintCake(canvas, icon);
      case 11:
        paintDoor(canvas, icon, const Color(0xFF2EA8E6));
      default:
        paintLemonSlice(canvas, icon);
    }
    mockText(canvas, piece, Offset(chip.left + 40, chip.top + 8), 14, mockInk, centre: false, width: cw - 60);
  }
  mockText(canvas, 'Hikâye kartları da 6 bölüm daha uzuyor; Ekşi Limon tarif defterini Çamlıca\'ya taşıyor.', Offset(size.width / 2, size.height - 30), 13.5, const Color(0xFFFFE08A), width: 400, weight: FontWeight.w700);
}

/// 2. The five new obstacles: how each works, before and after a move.
void obstacles(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF3A1470), Color(0xFF241050)]));
  mockLabel(canvas, 'YENİ ENGELLER', Offset(size.width / 2, 46), 30);
  mockText(canvas, 'Her biri tek kuralla çalışır, hepsi Lokum\'un ilk ipucuyla tanıtılır', Offset(size.width / 2, 84), 14.5, const Color(0xFFE6D6FF), width: 400, weight: FontWeight.w700);
  const doors = {'r': Color(0xFFE2533C), 'b': Color(0xFF2EA8E6), 'y': Color(0xFFFFC21A)};
  final rows = <(String, String, String, List<String>, List<String>)>[
    ('Yayılan çikolata', '7 · Kadıköy', 'Bir hamlede hiç çikolata kırmazsan bir kare daha yayılır. Yanında eşleştir, temizle.', ['0c1', 'cc2', '311'], ['0c1', 'cc2', 'c11']),
    ('Narı indir', '8 · Ortaköy', 'Nar şekerle beraber düşer. En alt sıraya ulaşınca toplanır; hedef: 4 nar.', ['p02', '130', '214'], ['_02', '130', 'p14']),
    ('Taşıyıcı bant', '9 · Boğaz Vapuru', 'Her hamleden sonra banttaki şekerler bir kare kayar; yeni eşleşmeler kendiliğinden doğar.', ['>>>', '120', '304'], ['>>>', '120', '304']),
    ('Kat kat pasta', '10 · İstiklal', '2×2 pasta 3 kattır; yanındaki her eşleşme bir kat yer. Son kat gidince bir özel şeker çıkar.', ['K.0', '..1', '232'], ['k.0', '..1', '2_2']),
    ('Renkli kapılar', '11 · Balat', 'Kapı yalnız kendi renginde bir eşleşmeyle açılır. Arkasında hediye ya da yol vardır.', ['0r2', '03b', '0y1'], ['_o2', '_3b', '_y1']),
  ];
  for (var i = 0; i < rows.length; i++) {
    final (name, where, how, before, after) = rows[i];
    final y = 112.0 + i * 156;
    final card = RRect.fromRectAndRadius(Rect.fromLTWH(14, y, size.width - 28, 144), const Radius.circular(20));
    mockCard(canvas, card, colors: const [Color(0xFFFFF8F0), Color(0xFFFFEAF4)], width: 2);
    mockText(canvas, name, Offset(30, y + 12), 19, mockInk, centre: false, width: 190);
    mockText(canvas, where, Offset(30, y + 38), 13, const Color(0xFFD06A00), centre: false, width: 190);
    mockText(canvas, how, Offset(30, y + 60), 12.5, const Color(0xFF6A4A7A), centre: false, width: 170, weight: FontWeight.w600, height: 1.22);
    const bw = 84.0;
    final b1 = Rect.fromLTWH(212, y + 30, bw, bw);
    final b2 = Rect.fromLTWH(322, y + 30, bw, bw);
    // Belts: the top row is a belt with candies riding on it.
    void board(Rect r, List<String> rws, {int shift = 0}) {
      if (rws.first == '>>>') {
        _tiles(canvas, r, 3, 3);
        final cell = r.width / 3;
        for (var x = 0; x < 3; x++) {
          paintBelt(canvas, Rect.fromLTWH(r.left + x * cell, r.top, cell, cell));
          paintCandy(canvas, Rect.fromLTWH(r.left + x * cell, r.top, cell, cell).deflate(cell * 0.14), _sc[[4, 0, 2][(x - shift) % 3]]);
        }
        _mini(canvas, Rect.fromLTWH(r.left, r.top + cell, r.width, cell * 2), rws.sublist(1));
      } else {
        _mini(canvas, r, rws, doors: doors);
      }
    }

    board(b1, before);
    board(b2, after, shift: 1);
    _arrow(canvas, Offset(b1.right + 8, b1.center.dy), Offset(b2.left - 8, b1.center.dy), color: const Color(0xFFE0247A));
    mockText(canvas, 'önce', Offset(b1.center.dx, b1.bottom + 14), 12, mockMuted, width: 80);
    mockText(canvas, 'sonra', Offset(b2.center.dx, b2.bottom + 14), 12, mockMuted, width: 80);
  }
  mockText(canvas, 'Eski engeller (buz, zincir, kutu, bomba) de karışık gelmeye devam eder', Offset(size.width / 2, size.height - 28), 13.5, const Color(0xFFFFE08A), width: 400, weight: FontWeight.w700);
}

final _boss = [
  '01l230',
  '214013',
  '3l2140',
  '120l32',
  '403124',
  '231l03',
  '014230',
];

void _bossScreen(Canvas canvas, Size size) {
  paintCamlica(canvas, size);
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0620).withValues(alpha: 0.25));
  // Top: moves, the villain and his sourness bar in three parts.
  final hud = RRect.fromRectAndRadius(Rect.fromLTWH(14, 48, size.width - 28, 74), const Radius.circular(22));
  mockCard(canvas, hud, colors: const [Color(0xEE4A1A85), Color(0xEE2A0B4F)], border: const Color(0xFFFFC21A), width: 2);
  mockText(canvas, 'HAMLE', Offset(56, 70), 12, const Color(0xFFE6D6FF), width: 80);
  mockText(canvas, '17', Offset(56, 96), 30, Colors.white, width: 80);
  mockText(canvas, 'EKŞİ LİMON · 2. AŞAMA', Offset(110, 58), 13, const Color(0xFFFFE08A), centre: false, width: 220);
  final bar = Rect.fromLTWH(110, 82, size.width - 150, 22);
  mockProgress(canvas, bar, 0.58, colors: const [Color(0xFFFFF06A), Color(0xFFD8A400)], track: const Color(0xCC1A0838));
  for (final t in [1 / 3, 2 / 3]) {
    canvas.drawLine(Offset(bar.left + bar.width * t, bar.top + 2), Offset(bar.left + bar.width * t, bar.bottom - 2), Paint()
      ..strokeWidth = 2.5
      ..color = Colors.white);
  }
  mockText(canvas, '%58 ekşi', Offset(bar.center.dx, bar.center.dy), 12.5, const Color(0xFF5A3A00), width: 120);
  // Ekşi Limon above the board, throwing a slice.
  paintEksiLimon(canvas, Offset(size.width / 2, 196), 96);
  mockBubble(canvas, Rect.fromLTWH(size.width / 2 + 56, 134, 150, 46), 'Al sana limon!', size: 14);
  // The board, 6 by 7.
  const cols = 6, rows = 7;
  final cell = (size.width - 60) / cols;
  final board = Rect.fromLTWH(30, 278, cell * cols, cell * rows);
  _tiles(canvas, board, cols, rows);
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      final r = Rect.fromLTWH(board.left + x * cell, board.top + y * cell, cell, cell);
      final ch = _boss[y][x];
      if (ch == 'l') {
        paintLemonSlice(canvas, r, turn: x * 0.4);
      } else if (y == 4 && x == 2) {
        paintStriped(canvas, r.deflate(cell * 0.04), SugarColor.green, horizontal: false);
      } else {
        paintCandy(canvas, r.deflate(cell * 0.04), _sc[int.parse(ch) % 6]);
      }
    }
  }
  // A slice in flight from the lemon to the board.
  final from = Offset(size.width / 2 - 30, 220), to = board.topLeft + Offset(cell * 4.5, cell * 1.5);
  final arc = Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(from.dx + 90, from.dy - 30, to.dx, to.dy);
  for (final m in arc.computeMetrics()) {
    for (var d = 0.0; d < m.length * 0.7; d += 12) {
      canvas.drawCircle(m.getTangentForOffset(d)!.position, 2.4, Paint()..color = const Color(0xFFFFF06A).withValues(alpha: 0.8));
    }
    final tip = m.getTangentForOffset(m.length * 0.75)!.position;
    paintLemonSlice(canvas, Rect.fromCenter(center: tip, width: cell * 0.8, height: cell * 0.8), turn: 0.5);
  }
  // A striped candy's beam hitting him.
  final beam = Rect.fromLTWH(board.left + cell * 2.3, 240, cell * 0.4, board.top + cell * 4 - 240);
  canvas.drawRRect(RRect.fromRectAndRadius(beam, Radius.circular(cell * 0.2)), Paint()
    ..shader = ui.Gradient.linear(beam.topCenter, beam.bottomCenter, [const Color(0xFFFFFFFF).withValues(alpha: 0.95), const Color(0xFF6BF0A0).withValues(alpha: 0.4)]));
  paintSparkle(canvas, Offset(beam.center.dx, 238), 16, const Color(0xFFFFE066));
  mockLabel(canvas, '−8%', Offset(beam.center.dx - 54, 250), 26, colors: const [Color(0xFFFFFFFF), Color(0xFF6BF0A0), Color(0xFF1FB85A)], outline: const Color(0xFF0E4A2A));
  // Lokum cheering, the boosters.
  paintLokum(canvas, Offset(66, size.height - 108), 84, pose: LokumPose.cheer, outfit: LokumOutfit.kalpak);
  mockBubble(canvas, Rect.fromLTWH(116, size.height - 168, 290, 48), 'Özel şekerler ona iki kat vurur!', size: 14);
  for (var i = 0; i < 3; i++) {
    final c = Offset(178 + i * 82.0, size.height - 76);
    canvas.drawCircle(c, 30, Paint()..color = const Color(0xFF3A1270));
    canvas.drawCircle(c, 30, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF9AD8));
    switch (i) {
      case 0:
        paintRainbow(canvas, Rect.fromCenter(center: c, width: 40, height: 40));
      case 1:
        paintStriped(canvas, Rect.fromCenter(center: c, width: 40, height: 40), SugarColor.red, horizontal: true);
      default:
        paintSugarLabel(canvas, '+3', c, 22, Paint()..color = const Color(0xFFFF7AC6), outline: Colors.white, stroke: 0.18);
    }
  }
}

void _winScreen(Canvas canvas, Size size) {
  paintCamlica(canvas, size, dawn: true);
  for (var i = 0; i < 40; i++) {
    final r = Random(i);
    canvas.drawRect(Rect.fromCenter(center: Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.5), width: 6, height: 10),
        Paint()..color = [const Color(0xFFFF7AC6), const Color(0xFFFFE066), const Color(0xFF6BF0A0), const Color(0xFF7FD8FF)][i % 4]);
  }
  mockLabel(canvas, 'İSTANBUL TATLANDI!', Offset(size.width / 2, 78), 32);
  mockText(canvas, 'Tarif defteri yerine döndü', Offset(size.width / 2, 116), 17, Colors.white, width: 380);
  final panel = RRect.fromRectAndRadius(Rect.fromLTWH(24, 150, size.width - 48, 560), const Radius.circular(28));
  mockCard(canvas, panel);
  // The recipe book, open, glowing.
  final book = Offset(size.width / 2, 250);
  canvas.drawCircle(book, 90, Paint()..shader = ui.Gradient.radial(book, 90, [const Color(0xFFFFF0A0).withValues(alpha: 0.9), const Color(0xFFFFF0A0).withValues(alpha: 0)]));
  for (final dir in [-1.0, 1.0]) {
    final page = Path()
      ..moveTo(book.dx, book.dy - 40)
      ..quadraticBezierTo(book.dx + dir * 40, book.dy - 54, book.dx + dir * 80, book.dy - 44)
      ..lineTo(book.dx + dir * 80, book.dy + 36)
      ..quadraticBezierTo(book.dx + dir * 40, book.dy + 26, book.dx, book.dy + 40)
      ..close();
    canvas.drawPath(page.shift(const Offset(0, 6)), Paint()..color = const Color(0xFF8A2A2A));
    canvas.drawPath(page, Paint()..color = const Color(0xFFFFF6E0));
    for (var k = 0; k < 5; k++) {
      final y = book.dy - 26 + k * 13.0;
      canvas.drawLine(Offset(book.dx + dir * 14, y), Offset(book.dx + dir * (k == 4 ? 44 : 66), y - dir * 0), Paint()
        ..strokeWidth = 2.2
        ..color = const Color(0xFFC8A890));
    }
  }
  paintCandy(canvas, Rect.fromCenter(center: book + const Offset(-40, -62), width: 30, height: 30), SugarColor.red);
  // Lokum dances, the lemon, sugared, asks for a taste.
  paintLokum(canvas, Offset(112, 404), 100, pose: LokumPose.dance, beat: 0.2, outfit: LokumOutfit.sultan);
  paintEksiLimon(canvas, Offset(size.width - 110, 410), 82, laugh: false);
  for (var i = 0; i < 9; i++) {
    final r = Random(i + 50);
    canvas.drawCircle(Offset(size.width - 110 + (r.nextDouble() - 0.5) * 80, 410 + (r.nextDouble() - 0.5) * 60), 2.4, Paint()..color = Colors.white);
  }
  mockBubble(canvas, Rect.fromLTWH(size.width - 230, 318, 196, 46), 'Bir lokum tadabilir miyim?', size: 13.5, right: true);
  mockText(canvas, 'ÖDÜLLER', Offset(size.width / 2, 486), 16, mockMuted, width: 300);
  final items = <(String, void Function(Rect))>[
    ('Altın sandık', (r) => paintChest(canvas, r.center + const Offset(0, 6), 58, chestGold, glow: true)),
    ('Çamlıca kartı', (r) {
      final card = Rect.fromCenter(center: r.center, width: 62, height: 44);
      canvas.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(5)), Paint()..color = const Color(0xFFFFF8EC));
      canvas.save();
      canvas.clipRect(card.deflate(4));
      canvas.translate(card.left + 4, card.top + 4);
      paintCamlica(canvas, card.deflate(4).size);
      canvas.restore();
    }),
    ('Gökkuşağı ×3', (r) => paintRainbow(canvas, Rect.fromCenter(center: r.center, width: 50, height: 50))),
  ];
  for (var i = 0; i < items.length; i++) {
    final (name, draw) = items[i];
    final x = size.width / 2 + (i - 1) * 118.0;
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 556), width: 104, height: 96), const Radius.circular(18));
    mockCard(canvas, r, colors: const [Colors.white, Color(0xFFFFEAF6)], width: 2);
    draw(Rect.fromCenter(center: Offset(x, 546), width: 80, height: 64));
    mockText(canvas, name, Offset(x, 590), 13, mockInk, width: 100);
  }
  mockButton(canvas, Rect.fromLTWH(60, 632, size.width - 120, 58), 'DEVAM');
}

/// 3. The final on Çamlıca: the fight, then the win.
void finale(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1E1236));
  mockLabel(canvas, 'ÇAMLICA FİNALİ · EKŞİ LİMON', Offset(size.width / 2, 44), 30);
  mockText(canvas, '120. seviye: Ekşi Limon\'un ekşiliğini sıfırla. Her eşleşme biraz, özel şekerler iki kat azaltır; o da her 4 hamlede tahtaya limon dilimi atar.',
      Offset(size.width / 2, 92), 15, const Color(0xFFE6D6FF), width: 820, weight: FontWeight.w700);
  const phone = Size(400, 840);
  mockPhone(canvas, Rect.fromLTWH(26, 140, phone.width, phone.height), _bossScreen);
  mockPhone(canvas, Rect.fromLTWH(size.width - 26 - phone.width, 140, phone.width, phone.height), _winScreen);
  mockText(canvas, 'Savaş · 3 aşamalı ekşilik çubuğu', Offset(26 + phone.width / 2, 1010), 16, const Color(0xFFFFE08A), width: 400);
  mockText(canvas, 'Zafer · hikâyenin sonu, büyük ödül', Offset(size.width - 26 - phone.width / 2, 1010), 16, const Color(0xFFFFE08A), width: 400);
  mockText(canvas, 'Limon dilimi: yanında eşleştirince temizlenir. Bir aşama bitince Limon kızar, tahtayı karıştırır ve daha sık atar.',
      Offset(size.width / 2, 1050), 14, const Color(0xFFC9B8E6), width: 820, weight: FontWeight.w700);
}

void main() {
  setUpAll(mockFonts);
  testWidgets('chapters', (tester) => mockSave(tester, const Size(430, 1220), chapters, 'asama4-bolumler.png'));
  testWidgets('obstacles', (tester) => mockSave(tester, const Size(430, 960), obstacles, 'asama4-engeller.png'));
  testWidgets('finale', (tester) => mockSave(tester, const Size(880, 1080), finale, 'asama4-final.png', scale: 2));
}
