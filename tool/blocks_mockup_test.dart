// Mock-ups for a livelier Bulmaca Küpler: the new game screen, gem levels
// (the lost jewels of the Grand Bazaar), the effects step by step, and the
// rules that make it play like a block blaster.
//   flutter test tool/blocks_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): bulmaca-oyun.png,
// bulmaca-mucevher.png, bulmaca-efekt.png, bulmaca-kurallar.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show paintChainCube;
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;

void _text(Canvas canvas, String text, Offset at, double size, Color color, {bool centre = true, double width = 400, FontWeight weight = FontWeight.w800, double height = 1.15}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, textAlign: centre ? TextAlign.center : TextAlign.left, height: height))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, height: height))
    ..addText(text);
  final p = b.build()..layout(ui.ParagraphConstraints(width: width));
  canvas.drawParagraph(p, centre ? at - Offset(width / 2, p.height / 2) : at);
}

void _label(Canvas canvas, String text, Offset c, double size, {List<Color> colors = const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], Color outline = const Color(0xFF6A0E4A)}) {
  paintSugarLabel(canvas, text, c, size,
      Paint()..shader = ui.Gradient.linear(c - Offset(0, size / 2), c + Offset(0, size / 2), colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]),
      outline: outline, stroke: 0.2);
}

// ------------------------------------------------------------ the parts --

/// Block colours: vivid, like the new Zincir cubes.
const _colors = {
  'R': Color(0xFFF2425A),
  'O': Color(0xFFFF8A1E),
  'Y': Color(0xFFFFC414),
  'G': Color(0xFF1FBF5A),
  'C': Color(0xFF1FB8E0),
  'B': Color(0xFF3A6CF0),
  'P': Color(0xFFA24CF0),
};

void _block(Canvas canvas, Rect r, Color color) => paintChainCube(canvas, r.deflate(r.width * 0.04), color);

/// A cut jewel: ruby, emerald, sapphire or amber, inside a block.
void _gem(Canvas canvas, Offset c, double s, int kind) {
  const tones = [
    [Color(0xFFFF8A9A), Color(0xFFE0102E), Color(0xFF7A0012)],
    [Color(0xFF8AF0B0), Color(0xFF12A04A), Color(0xFF064A20)],
    [Color(0xFF9AC8FF), Color(0xFF1F5AE0), Color(0xFF0A2A7A)],
    [Color(0xFFFFE6A0), Color(0xFFF0A010), Color(0xFF8A5000)],
  ];
  final t = tones[kind % 4];
  final pts = [for (var i = 0; i < 6; i++) c + Offset(cos(pi / 6 + i * pi / 3), sin(pi / 6 + i * pi / 3)) * s];
  final outer = Path()..addPolygon(pts, true);
  canvas.drawPath(outer.shift(Offset(0, s * 0.12)), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawPath(outer, Paint()..shader = ui.Gradient.linear(c - Offset(s, s), c + Offset(s, s), t, const [0, 0.5, 1]));
  final inner = [for (final p in pts) Offset.lerp(c, p, 0.5)!];
  canvas.drawPath(Path()..addPolygon(inner, true), Paint()..color = _l(t[1], 0.25));
  for (var i = 0; i < 6; i++) {
    canvas.drawLine(pts[i], inner[i], Paint()
      ..strokeWidth = s * 0.06
      ..color = Colors.white.withValues(alpha: 0.35));
  }
  canvas.drawPath(Path()..addPolygon([pts[3], pts[4], inner[4], inner[3]], true), Paint()..color = Colors.white.withValues(alpha: 0.45));
  canvas.drawPath(outer, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.07
    ..color = Colors.white.withValues(alpha: 0.8));
}

/// A block with a jewel set in it.
void _gemBlock(Canvas canvas, Rect r, int kind) {
  canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(r.width * 0.04), Radius.circular(r.width * 0.2)), Paint()..color = const Color(0xFF3A2A5A));
  canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(r.width * 0.1), Radius.circular(r.width * 0.16)), Paint()..color = const Color(0xFF241A3A));
  _gem(canvas, r.center, r.width * 0.32, kind);
}

void _board(Canvas canvas, Rect r, List<String> rows, {Set<int> glowRows = const {}, Set<int> glowCols = const {}, Color glow = Colors.white, Map<(int, int), int> gems = const {}}) {
  final rr = RRect.fromRectAndRadius(r.inflate(12), const Radius.circular(22));
  canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()..color = Colors.black.withValues(alpha: 0.35));
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(rr.outerRect.topCenter, rr.outerRect.bottomCenter, const [Color(0xFF3A3A9A), Color(0xFF2A1F6A)]));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFF7A8AF0).withValues(alpha: 0.7));
  final cell = r.width / 8;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final c = Rect.fromLTWH(r.left + x * cell, r.top + y * cell, cell, cell);
      canvas.drawRRect(RRect.fromRectAndRadius(c.deflate(cell * 0.06), Radius.circular(cell * 0.18)), Paint()..color = const Color(0xFF1E1650).withValues(alpha: 0.85));
    }
  }
  // Lines that the dragged piece will clear, lit in its colour.
  for (final y in glowRows) {
    final line = Rect.fromLTWH(r.left, r.top + y * cell, r.width, cell);
    canvas.drawRRect(RRect.fromRectAndRadius(line.inflate(3), Radius.circular(cell * 0.3)), Paint()
      ..color = glow.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }
  for (final x in glowCols) {
    final line = Rect.fromLTWH(r.left + x * cell, r.top, cell, r.height);
    canvas.drawRRect(RRect.fromRectAndRadius(line.inflate(3), Radius.circular(cell * 0.3)), Paint()
      ..color = glow.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < 8; x++) {
      final ch = rows[y][x];
      final c = Rect.fromLTWH(r.left + x * cell, r.top + y * cell, cell, cell);
      final gem = gems[(x, y)];
      if (gem != null) {
        _gemBlock(canvas, c, gem);
      } else if (_colors[ch] case final color?) {
        _block(canvas, c, (glowRows.contains(y) || glowCols.contains(x)) ? Color.lerp(color, glow, 0.55)! : color);
      } else if (ch == '+') {
        // The dragged piece's landing spot.
        canvas.drawRRect(RRect.fromRectAndRadius(c.deflate(cell * 0.06), Radius.circular(cell * 0.18)), Paint()..color = glow.withValues(alpha: 0.55));
      }
    }
  }
}

/// A piece in the tray, [cell] per block.
void _piece(Canvas canvas, Offset c, List<String> rows, Color color, double cell) {
  final w = rows[0].length * cell, h = rows.length * cell;
  final o = c - Offset(w / 2, h / 2);
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      if (rows[y][x] == '#') _block(canvas, Rect.fromLTWH(o.dx + x * cell, o.dy + y * cell, cell, cell), color);
    }
  }
}

void _backdrop(Canvas canvas, Rect r) {
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF3A1F9A), Color(0xFF6A2AB0), Color(0xFF2A1470)], const [0, 0.5, 1]));
  final rnd = Random(4);
  for (var i = 0; i < 16; i++) {
    final c = [const Color(0xFF7AB8FF), const Color(0xFFFF8AD8), const Color(0xFFFFE08A)][i % 3];
    canvas.drawCircle(r.topLeft + Offset(rnd.nextDouble() * r.width, rnd.nextDouble() * r.height), 20 + rnd.nextDouble() * 50, Paint()
      ..color = c.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
  }
}

void _hud(Canvas canvas, Size size, String title, {String? left}) {
  final bar = RRect.fromRectAndRadius(Rect.fromLTWH(14, 14, size.width - 28, 54), const Radius.circular(18));
  canvas.drawRRect(bar, Paint()..color = const Color(0xFF1E1650).withValues(alpha: 0.7));
  canvas.drawCircle(Offset(bar.left + 30, bar.center.dy), 18, Paint()..color = Colors.white.withValues(alpha: 0.15));
  _text(canvas, 'II', Offset(bar.left + 30, bar.center.dy), 18, Colors.white, width: 40);
  _text(canvas, title, Offset(bar.center.dx, bar.center.dy), 20, Colors.white, width: 220);
  if (left != null) _text(canvas, left, Offset(bar.right - 60, bar.center.dy), 15, const Color(0xFFFFD36B), width: 110);
}

// --------------------------------------------------------------- screens --

/// 1. The new game screen: dragging a piece lights the lines it will clear,
/// a running combo, praise words, a big tray.
void game(Canvas canvas, Size size) {
  _backdrop(canvas, Offset.zero & size);
  _hud(canvas, size, 'Sonsuz', left: 'En iyi 8.420');
  // The score, big, with the combo meter.
  _label(canvas, '3.260', Offset(size.width / 2, 108), 46, colors: const [Colors.white, Color(0xFFE6E0FF)], outline: const Color(0xFF2A1470));
  final meter = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width / 2, 150), width: 170, height: 30), const Radius.circular(15));
  canvas.drawRRect(meter, Paint()..shader = ui.Gradient.linear(meter.outerRect.centerLeft, meter.outerRect.centerRight, const [Color(0xFFFF6A00), Color(0xFFFF2A6A)]));
  _text(canvas, 'KOMBO ×4', meter.outerRect.center, 17, Colors.white, width: 170);
  for (var i = 0; i < 3; i++) {
    final x = meter.left - 18 + i * 4.0;
    canvas.drawPath(
        Path()
          ..moveTo(x, meter.center.dy + 10)
          ..quadraticBezierTo(x - 8, meter.center.dy - 4, x + 2, meter.center.dy - 16 + i * 3)
          ..quadraticBezierTo(x + 8, meter.center.dy, x, meter.center.dy + 10),
        Paint()..color = [const Color(0xFFFFE066), const Color(0xFFFF9A2A), const Color(0xFFFF4A2A)][i]);
  }
  final b = Rect.fromLTWH(26, 192, size.width - 52, size.width - 52);
  const rows = [
    'PP..YYY.',
    'P...Y.GG',
    'RR.BBB.G',
    'RRRBB+BG',
    'GGGOO++C',
    'B..O..+C',
    'BBYYY..C',
    'B.YY..CC',
  ];
  _board(canvas, b, rows, glowRows: {3}, glowCols: {6}, glow: const Color(0xFFFFB0E8));
  // The piece under the finger, lifted above it.
  final cell = b.width / 8;
  final held = Offset(b.left + 6.5 * cell, b.top + 4.5 * cell) + const Offset(0, -6);
  canvas.drawCircle(held + Offset(0, cell * 2.6), 22, Paint()..color = Colors.white.withValues(alpha: 0.25));
  _text(canvas, 'parmak', held + Offset(0, cell * 2.6), 11, Colors.white, width: 60);
  // Praise for the last clear.
  canvas.save();
  canvas.translate(size.width / 2, b.top + b.height * 0.32);
  canvas.rotate(-0.08);
  _label(canvas, 'MUHTEŞEM!', Offset.zero, 50);
  canvas.restore();
  _label(canvas, '+240', Offset(b.left + b.width * 0.7, b.top + b.height * 0.18), 30, colors: const [Colors.white, Color(0xFFFFE066)], outline: const Color(0xFF2A1470));
  // The tray: big pieces, one being dragged (shown faint).
  final ty = b.bottom + 74;
  for (var i = 0; i < 3; i++) {
    final c = Offset(size.width * (0.2 + i * 0.3), ty);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 118, height: 104), const Radius.circular(20)), Paint()..color = const Color(0xFF1E1650).withValues(alpha: 0.55));
  }
  _piece(canvas, Offset(size.width * 0.2, ty), ['###', '#..'], _colors['O']!, 26);
  canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: 0.25));
  _piece(canvas, Offset(size.width * 0.5, ty), ['.#', '##', '.#'], _colors['P']!, 26);
  canvas.restore();
  _piece(canvas, Offset(size.width * 0.8, ty), ['##', '##'], _colors['G']!, 26);
  paintLokum(canvas, Offset(size.width - 46, b.top - 18), 62, pose: LokumPose.cheer, outfit: LokumOutfit.fez);
  _text(canvas, 'Sürüklerken patlayacak satır ve sütun parlar · parça parmağın üstünde durur', Offset(size.width / 2, size.height - 30), 13.5, const Color(0xFFE6E0FF), width: size.width - 30, weight: FontWeight.w700);
}

/// 2. A gem level: jewels set in blocks, goals at the top, a jewel flying
/// to its counter.
void gems(Canvas canvas, Size size) {
  _backdrop(canvas, Offset.zero & size);
  _hud(canvas, size, 'Seviye 12', left: '9 hamle');
  _text(canvas, "KAPALIÇARŞI'NIN KAYIP MÜCEVHERLERİ", Offset(size.width / 2, 88), 13, const Color(0xFFFFD36B), width: 380);
  // The goals.
  const goals = [(0, 3, 6), (1, 5, 5), (2, 1, 4)];
  for (var i = 0; i < goals.length; i++) {
    final (kind, got, of) = goals[i];
    final c = Offset(size.width * (0.22 + i * 0.28), 126);
    final chip = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 104, height: 46), const Radius.circular(23));
    canvas.drawRRect(chip, Paint()..color = got >= of ? const Color(0xFF1FB85A) : const Color(0xFF1E1650).withValues(alpha: 0.8));
    _gem(canvas, chip.outerRect.centerLeft + const Offset(24, 0), 14, kind);
    _text(canvas, got >= of ? 'TAMAM' : '$got/$of', c + const Offset(14, 0), got >= of ? 14 : 18, Colors.white, width: 60);
  }
  final b = Rect.fromLTWH(26, 170, size.width - 52, size.width - 52);
  const rows = [
    '........',
    '.BB..RR.',
    '.B....R.',
    'GG.YY.PP',
    'G..YY..P',
    '.CC..OO.',
    '.C....O.',
    '........',
  ];
  final gemCells = <(int, int), int>{(3, 0): 0, (4, 0): 2, (0, 2): 1, (7, 2): 0, (3, 6): 1, (4, 6): 0, (0, 7): 2, (7, 7): 1, (2, 4): 0, (5, 4): 2};
  _board(canvas, b, rows, gems: gemCells);
  // A ruby flying up to its goal, with a trail.
  final cell = b.width / 8;
  final from = Offset(b.left + 3.5 * cell, b.top + 3.5 * cell);
  final to = Offset(size.width * 0.22 - 28, 126);
  for (var i = 0; i < 6; i++) {
    final t = i / 6;
    final p = Offset.lerp(from, to, t)! + Offset(0, -sin(t * pi) * 60);
    paintSparkle(canvas, p, 6 + i * 1.0, const Color(0xFFFF8A9A), opacity: 0.4 + t * 0.6);
  }
  _gem(canvas, Offset.lerp(from, to, 0.62)! + Offset(0, -sin(0.62 * pi) * 60), 18, 0);
  _label(canvas, 'Yakut!', from + const Offset(0, -10), 26, colors: const [Color(0xFFFFE0E6), Color(0xFFFF4A6A)], outline: const Color(0xFF5A0012));
  // The tray.
  final ty = b.bottom + 70;
  _piece(canvas, Offset(size.width * 0.2, ty), ['####'], _colors['C']!, 24);
  _piece(canvas, Offset(size.width * 0.5, ty), ['#.', '##'], _colors['R']!, 24);
  _piece(canvas, Offset(size.width * 0.8, ty), ['###', '###'], _colors['Y']!, 24);
  _text(canvas, 'Mücevherli bloğun satırını ya da sütununu temizle: mücevher hedefine uçar', Offset(size.width / 2, size.height - 30), 13.5, const Color(0xFFE6E0FF), width: size.width - 30, weight: FontWeight.w700);
}

/// 3. The effects, one step after another.
void effects(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF221550));
  _label(canvas, 'BİR HAMLENİN ŞOVU', Offset(size.width / 2, 40), 30);
  final w = (size.width - 50) / 4;
  final steps = [
    ('1 · Sürükle', 'Patlayacak satır parlar, yer önizlemesi'),
    ('2 · Bırak', 'Bloklar zıplayarak oturur'),
    ('3 · Patla', 'Işın, saçılan parçalar, puan uçar'),
    ('4 · Tertemiz!', 'Tahta boşalınca dev bonus'),
  ];
  for (var i = 0; i < 4; i++) {
    final x = 10 + i * (w + 10);
    final r = Rect.fromLTWH(x + 14, 100, w - 28, w - 28);
    final cell = r.width / 8;
    switch (i) {
      case 0:
        _board(canvas, r, const ['........', '........', '........', 'RRRR.+++', '........', '........', '........', '........'], glowRows: {3}, glow: const Color(0xFF9AE6FF));
      case 1:
        _board(canvas, r, const ['........', '........', '........', 'RRRRCCCC', '........', '........', '........', '........'], glowRows: {3}, glow: const Color(0xFFFFFFFF));
        for (var k = 0; k < 3; k++) {
          canvas.drawCircle(Offset(r.left + (5.5 + k) * cell, r.top + 3.5 * cell), cell * 0.75, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withValues(alpha: 0.6));
        }
      case 2:
        _board(canvas, r, const ['........', '........', '........', '........', '........', '........', '........', '........']);
        final line = Rect.fromLTWH(r.left - 6, r.top + 3 * cell, r.width + 12, cell);
        canvas.drawRRect(RRect.fromRectAndRadius(line.inflate(6), Radius.circular(cell)), Paint()
          ..color = const Color(0xFF9AE6FF).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawRRect(RRect.fromRectAndRadius(line.deflate(cell * 0.3), Radius.circular(cell)), Paint()..color = Colors.white);
        final rnd = Random(3);
        for (var k = 0; k < 26; k++) {
          final p = Offset(r.left + rnd.nextDouble() * r.width, r.top + 3.5 * cell + (rnd.nextDouble() - 0.5) * cell * 5);
          final c = [_colors['R']!, _colors['C']!, Colors.white][k % 3];
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(rnd.nextDouble() * 3);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: cell * 0.35, height: cell * 0.35), Paint()..color = c);
          canvas.restore();
        }
        _label(canvas, '+80', r.center + Offset(0, -cell * 1.8), 26, colors: const [Colors.white, Color(0xFFFFE066)], outline: const Color(0xFF2A1470));
      default:
        _board(canvas, r, const ['........', '........', '........', '........', '........', '........', '........', '........']);
        final rnd = Random(5);
        for (var k = 0; k < 40; k++) {
          final p = r.topLeft + Offset(rnd.nextDouble() * r.width, rnd.nextDouble() * r.height);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(rnd.nextDouble() * 3);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: 4), Paint()..color = _colors.values.elementAt(k % 7));
          canvas.restore();
        }
        _label(canvas, 'TERTEMİZ!', r.center + Offset(0, -10), 30);
        _label(canvas, '+300', r.center + Offset(0, 26), 22, colors: const [Colors.white, Color(0xFFFFE066)], outline: const Color(0xFF2A1470));
    }
    final (title, line) = steps[i];
    _text(canvas, title, Offset(x + w / 2, r.bottom + 34), 18, Colors.white, width: w);
    _text(canvas, line, Offset(x + w / 2, r.bottom + 62), 13, const Color(0xFFC9B8F0), width: w - 10, weight: FontWeight.w700);
  }
  // The praise ladder.
  _text(canvas, 'Övgüler büyüyerek gelir', Offset(size.width / 2, 400), 17, const Color(0xFFFFD36B), width: 400);
  const words = ['Güzel!', 'Harika!', 'Muhteşem!', 'İnanılmaz!', 'EFSANE!'];
  for (var i = 0; i < words.length; i++) {
    _label(canvas, words[i], Offset(size.width * (0.12 + i * 0.19), 444 - i * 4.0), 20 + i * 4.0);
    _text(canvas, ['1 satır', '2 satır', '3 satır', 'kombo ×3', 'kombo ×5'][i], Offset(size.width * (0.12 + i * 0.19), 482), 12.5, const Color(0xFFC9B8F0), width: 120, weight: FontWeight.w700);
  }
}

/// 4. The rules that make it play like a block blaster.
void rules(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF3A1F9A), Color(0xFF2A1470)]));
  _label(canvas, 'OYUNUN MANTIĞI', Offset(size.width / 2, 40), 30);
  const items = [
    ('Puan', 'Her blok 1 puan. 1 satır 10, 2 satır 30, 3 satır 60, 4 satır 100... hepsi kombo ile çarpılır.'),
    ('Kombo', "3 hamle içinde yine temizlersen kombo artar (×2, ×3...). 3 hamle temizlemezsen sıfırlanır."),
    ('Tertemiz', 'Tahtayı tamamen boşaltırsan +300 ve büyük şov.'),
    ('Adil parçalar', 'Gelen üç parçadan en az biri her zaman sığar. Sıkışınca ara sıra bir satırı tamamlayan "şanslı parça" gelir.'),
    ('Kurtarma', 'Hiçbir parça sığmazsa: Çekiç ile bir bloğu kır ya da Karıştır ile yeni üç parça al, oyun sürsün.'),
    ('Mücevher seviyeleri', 'Bloklara gömülü yakut, zümrüt, safir, kehribar. Hedef: belli sayıda topla. Kapalıçarşı hikâyesiyle.'),
    ('Lokum', "Komboda sevinir, sıkışınca 'şuraya koy' diye ipucu gösterir, rekorda dans eder."),
  ];
  var y = 84.0;
  for (final (title, line) in items) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(18, y, size.width - 36, 92), const Radius.circular(18));
    canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.1));
    _text(canvas, title, Offset(r.left + 16, y + 10), 19, const Color(0xFFFFD36B), centre: false, width: r.width - 32);
    _text(canvas, line, Offset(r.left + 16, y + 38), 14.5, Colors.white, centre: false, width: r.width - 32, weight: FontWeight.w600, height: 1.25);
    y += 102;
  }
}

Future<void> _save(WidgetTester tester, Size size, void Function(Canvas, Size) paint, String name, {double scale = 2.5}) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    paint(canvas, size);
    final image = await recorder.endRecording().toImage((size.width * scale).round(), (size.height * scale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('$_out$name')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Baloo2');
    for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Baloo2-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
  });
  testWidgets('game', (tester) => _save(tester, const Size(430, 760), game, 'bulmaca-oyun.png'));
  testWidgets('gems', (tester) => _save(tester, const Size(430, 760), gems, 'bulmaca-mucevher.png'));
  testWidgets('effects', (tester) => _save(tester, const Size(900, 510), effects, 'bulmaca-efekt.png', scale: 2));
  testWidgets('rules', (tester) => _save(tester, const Size(430, 810), rules, 'bulmaca-kurallar.png'));
}
