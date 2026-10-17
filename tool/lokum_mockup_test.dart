// Mock-ups for stage two: Lokum alive in Şeker Küpler — his new poses and
// outfits, diving into the board for the sugar rush, pointing at a move,
// his wardrobe, and a story card with Ekşi Limon.
//   flutter test tool/lokum_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): lokum-tepkiler.png,
// lokum-oyunda.png, lokum-dolap.png, hikaye-karti.png, lokum-her-yerde.png,
// istanbul-turu.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart' show ChainColor;
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show chainColors, paintChainCube;
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

final String _out = Platform.environment['MOCKUP_OUT'] ?? 'build/mockups/';

const _ink = Color(0xFF5A1F7A);

void _text(Canvas canvas, String text, Offset at, double size, Color color, {bool centre = true, double width = 400, FontWeight weight = FontWeight.w800}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, textAlign: centre ? TextAlign.center : TextAlign.left, height: 1.1))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, height: 1.1))
    ..addText(text);
  final p = b.build()..layout(ui.ParagraphConstraints(width: width));
  canvas.drawParagraph(p, centre ? at - Offset(width / 2, p.height / 2) : at);
}

void _label(Canvas canvas, String text, Offset c, double size, {List<Color> colors = const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)]}) {
  paintSugarLabel(canvas, text, c, size,
      Paint()..shader = ui.Gradient.linear(c - Offset(0, size / 2), c + Offset(0, size / 2), colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]),
      outline: const Color(0xFF6A0E4A), stroke: 0.2);
}

void _card(Canvas canvas, RRect r, {List<Color> colors = const [Color(0xFFFFF7FD), Color(0xFFFFE3F4)]}) {
  canvas.drawRRect(r.shift(const Offset(0, 6)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.5));
  canvas.drawRRect(r, Paint()..shader = ui.Gradient.linear(r.outerRect.topCenter, r.outerRect.bottomCenter, colors));
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white);
}

void _bubble(Canvas canvas, Rect r, String text, {bool tailLeft = true, double size = 17, Color fill = Colors.white, Color ink = _ink}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(18));
  final tail = Path()
    ..addPolygon(tailLeft ? [Offset(r.left + 22, r.bottom - 2), Offset(r.left + 6, r.bottom + 18), Offset(r.left + 42, r.bottom - 2)] : [Offset(r.right - 42, r.bottom - 2), Offset(r.right - 6, r.bottom + 18), Offset(r.right - 22, r.bottom - 2)], true);
  canvas.drawRRect(rr.shift(const Offset(0, 4)), Paint()..color = Colors.black.withValues(alpha: 0.25));
  canvas.drawPath(tail, Paint()..color = fill);
  canvas.drawRRect(rr, Paint()..color = fill);
  _text(canvas, text, r.center, size, ink, width: r.width - 24);
}

void _backdrop(Canvas canvas, Rect r, List<Color> sky, int seed) {
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, sky, [for (var i = 0; i < sky.length; i++) i / (sky.length - 1)]));
  final rnd = Random(seed);
  for (var i = 0; i < 14; i++) {
    final c = [const Color(0xFFFFB3E6), const Color(0xFF9FD8FF), const Color(0xFFFFE08A)][i % 3];
    canvas.drawCircle(r.topLeft + Offset(rnd.nextDouble() * r.width, rnd.nextDouble() * r.height), 20 + rnd.nextDouble() * 46, Paint()
      ..color = c.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
  }
}


// ------------------------------------------------------------------ board --

const _rows = ['RBYGPOBY', 'GOYBRGYP', 'PRRYBGBO', 'OGPRYRGB', 'YBGGPYRG', 'RPGYOBPY', 'GYBPGYRB', 'BOYRBPGO'];
SugarColor _c(String k) => SugarColor.values['ROYGBP'.indexOf(k)];

Rect _board(Canvas canvas, Offset o, double cell, {Set<(int, int)> skip = const {}, void Function(int x, int y, Rect r)? special}) {
  final tray = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 8 * cell, 8 * cell).inflate(9), const Radius.circular(22));
  canvas.drawRRect(tray.shift(const Offset(0, 7)), Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
  canvas.drawRRect(tray, Paint()..color = const Color(0xFF3A1270).withValues(alpha: 0.92));
  canvas.drawRRect(tray, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFFF9AD8).withValues(alpha: 0.7));
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final r = Rect.fromLTWH(o.dx + x * cell, o.dy + y * cell, cell, cell);
      canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(1.5), const Radius.circular(9)),
          Paint()..color = ((x + y).isEven ? const Color(0xFF4A1A85) : const Color(0xFF41167A)).withValues(alpha: 0.9));
      if (skip.contains((x, y))) continue;
      if (special != null) {
        special(x, y, r);
      } else {
        paintCandy(canvas, r, _c(_rows[y][x]));
      }
    }
  }
  return tray.outerRect;
}

// --------------------------------------------------------------- screens --

void poses(Canvas canvas, Size size) {
  _backdrop(canvas, Offset.zero & size, const [Color(0xFF5B1FA8), Color(0xFFB0307E), Color(0xFF3A1470)], 3);
  _label(canvas, 'LOKUM CANLANIYOR', Offset(size.width / 2, 46), 34);
  final items = [
    (LokumPose.happy, 'Mutlu', 'menüde, beklerken'),
    (LokumPose.cheer, 'Coşkulu', 'büyük zincirde'),
    (LokumPose.wow, 'Şaşkın', 'şanslı şeker gelince'),
    (LokumPose.scared, 'Korkmuş', 'bomba 2\'ye inince'),
    (LokumPose.sad, 'Üzgün', 'seviye kaybedilince'),
    (LokumPose.dance, 'Dans', 'final şöleninde'),
    (LokumPose.point, 'İşaret', 'ipucu gösterirken'),
    (LokumPose.chomp, 'Yutma', 'tahtaya dalarken'),
    (LokumPose.sleepy, 'Uykulu', 'uzun süre beklenince'),
    (LokumPose.wink, 'Göz kırpan', 'öneri verirken'),
  ];
  const cols = 5;
  final cw = (size.width - 40) / cols;
  for (var i = 0; i < items.length; i++) {
    final (pose, name, moment) = items[i];
    final x = 20 + (i % cols) * cw, y = 92.0 + (i ~/ cols) * 230;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x + 6, y, cw - 12, 214), const Radius.circular(22));
    _card(canvas, r);
    paintLokum(canvas, Offset(r.outerRect.center.dx + (pose == LokumPose.point ? -18 : 0), y + 88), 92, pose: pose, beat: 0.2);
    _text(canvas, name, Offset(r.outerRect.center.dx, y + 166), 19, _ink, width: cw);
    _text(canvas, moment, Offset(r.outerRect.center.dx, y + 192), 13, const Color(0xFF9A5AB5), width: cw - 20, weight: FontWeight.w700);
    if (pose == LokumPose.sleepy) _text(canvas, 'z z', Offset(r.outerRect.center.dx + 44, y + 26), 20, const Color(0xFF9A5AB5), width: 60);
  }
  _label(canvas, 'KOSTÜMLER', Offset(size.width / 2, 572), 28);
  final outfits = [
    (LokumOutfit.fez, 'Fes'),
    (LokumOutfit.kalpak, 'Kalpak'),
    (LokumOutfit.sultan, 'Padişah kavuğu'),
    (LokumOutfit.janissary, 'Yeniçeri börkü'),
    (LokumOutfit.tulip, 'Lale'),
    (LokumOutfit.nazar, 'Nazar boncuğu'),
    (LokumOutfit.moustache, 'Pala bıyık'),
    (LokumOutfit.simit, 'Simitçi tablası'),
  ];
  final ow = (size.width - 40) / 4;
  for (var i = 0; i < outfits.length; i++) {
    final (outfit, name) = outfits[i];
    final x = 20 + (i % 4) * ow, y = 606.0 + (i ~/ 4) * 186;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x + 6, y, ow - 12, 172), const Radius.circular(22));
    _card(canvas, r, colors: const [Color(0xFFFFF3C8), Color(0xFFFFE08A)]);
    paintLokum(canvas, Offset(r.outerRect.center.dx, y + 84), 86, outfit: outfit);
    _text(canvas, name, Offset(r.outerRect.center.dx, y + 150), 16, const Color(0xFF6A3A00), width: ow);
  }
}

void inGame(Canvas canvas, Size size) {
  // Left: the sugar rush, Lokum dives in and gobbles a row.
  final left = Rect.fromLTWH(0, 0, size.width / 2, size.height);
  _backdrop(canvas, left, const [Color(0xFF6A1FA8), Color(0xFFD0307E), Color(0xFF3A1470)], 5);
  const cell = 48.0;
  final o = Offset(left.left + (left.width - 8 * cell) / 2, 240);
  const row = 4;
  _board(canvas, o, cell, special: (x, y, r) {
    if (y == row) {
      // Pulled toward Lokum's mouth: smaller and smaller with speed lines.
      final k = (x / 7);
      final target = o + Offset(6.8 * cell, row * cell + cell / 2);
      final at = Offset.lerp(r.center, target, 0.15 + k * 0.6)!;
      final side = cell * (1 - k * 0.55);
      canvas.drawLine(at, at - Offset(cell * 0.9, 0), Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.6));
      paintCandy(canvas, Rect.fromCenter(center: at, width: side, height: side), _c(_rows[y][x]));
      return;
    }
    paintCandy(canvas, r, _c(_rows[y][x]));
  });
  // Row glow and Lokum mid-dive with his mouth wide open.
  final band = Rect.fromLTWH(o.dx - 6, o.dy + row * cell - 4, 8 * cell + 12, cell + 8);
  canvas.drawRRect(RRect.fromRectAndRadius(band, const Radius.circular(20)), Paint()
    ..color = const Color(0xFFFFE066).withValues(alpha: 0.28)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  canvas.save();
  canvas.translate(o.dx + 7.3 * cell, o.dy + row * cell + cell * 0.2);
  canvas.rotate(-0.45);
  paintLokum(canvas, Offset.zero, 104, pose: LokumPose.chomp);
  canvas.restore();
  for (var i = 0; i < 16; i++) {
    final a = i * pi / 8;
    paintSparkle(canvas, o + Offset(7.0 * cell, row * cell + cell / 2) + Offset(cos(a), sin(a)) * 74, 6, const Color(0xFFFFE066));
  }
  canvas.save();
  canvas.translate(left.center.dx, 170);
  canvas.rotate(-0.06);
  _label(canvas, 'ŞEKER ÇILGINLIĞI!', Offset.zero, 42);
  canvas.restore();
  _text(canvas, 'Lokum tahtaya dalıp bir sırayı yutar', Offset(left.center.dx, 690), 18, Colors.white, width: 400);
  _text(canvas, '+2.400', Offset(left.center.dx, 740), 34, const Color(0xFFFFF6B0), width: 300);

  // Right: Lokum points at a move after a pause.
  final right = Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
  _backdrop(canvas, right, const [Color(0xFF5B1FA8), Color(0xFFB0307E), Color(0xFF3A1470)], 9);
  final o2 = Offset(right.left + (right.width - 8 * cell) / 2, 240);
  _board(canvas, o2, cell);
  // The hinted pair glows.
  for (final (x, y) in [(2, 2), (3, 2)]) {
    final r = Rect.fromLTWH(o2.dx + x * cell, o2.dy + y * cell, cell, cell);
    canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(12)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFFFFE066));
  }
  final arrowFrom = o2 + Offset(2.5 * cell, 2.5 * cell), arrowTo = o2 + Offset(3.5 * cell, 2.5 * cell);
  canvas.drawLine(arrowFrom, arrowTo, Paint()
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..color = Colors.white);
  canvas.drawPath(Path()..addPolygon([arrowTo + const Offset(10, 0), arrowTo + const Offset(-4, -10), arrowTo + const Offset(-4, 10)], true), Paint()..color = Colors.white);
  paintLokum(canvas, Offset(right.right - 92, o2.dy + 8 * cell + 100), 104, pose: LokumPose.point, pointLeft: true);
  _bubble(canvas, Rect.fromLTWH(right.left + 26, o2.dy + 8 * cell + 46, 230, 56), 'Şunu dene! Pembeleri diz.', size: 17);
  _text(canvas, 'Takılınca Lokum hamleyi gösterir', Offset(right.center.dx, 170), 20, Colors.white, width: 400);
}

void wardrobe(Canvas canvas, Size size) {
  _backdrop(canvas, Offset.zero & size, const [Color(0xFFFFB6D9), Color(0xFFC9A0FF), Color(0xFF6A3AC8)], 12);
  _label(canvas, 'LOKUM\'UN DOLABI', Offset(size.width / 2, 52), 32);
  // Star count.
  final pill = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width / 2, 98), width: 150, height: 40), const Radius.circular(20));
  canvas.drawRRect(pill, Paint()..color = const Color(0xFF2A0B4F).withValues(alpha: 0.7));
  paintGoldStar(canvas, pill.outerRect.centerLeft + const Offset(26, 0), 13);
  _text(canvas, '42 yıldız', pill.outerRect.center + const Offset(14, 0), 18, Colors.white, width: 110);
  // Lokum, dressed.
  canvas.drawCircle(Offset(size.width / 2, 250), 120, Paint()..shader = ui.Gradient.radial(Offset(size.width / 2, 250), 120, [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0)]));
  paintLokum(canvas, Offset(size.width / 2, 260), 170, pose: LokumPose.cheer, outfit: LokumOutfit.fez);
  final items = [
    (LokumOutfit.fez, 'Fes', 'GİYİLİ', 0),
    (LokumOutfit.tulip, 'Lale', 'SENİN', 0),
    (LokumOutfit.nazar, 'Nazar boncuğu', 'SENİN', 0),
    (LokumOutfit.simit, 'Simitçi tablası', '60', 60),
    (LokumOutfit.kalpak, 'Kalpak', '90', 90),
    (LokumOutfit.sultan, 'Padişah kavuğu', '120', 120),
  ];
  final cw = (size.width - 48) / 3;
  for (var i = 0; i < items.length; i++) {
    final (outfit, name, state, cost) = items[i];
    final x = 24 + (i % 3) * cw, y = 420.0 + (i ~/ 3) * 222;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x + 6, y, cw - 12, 206), const Radius.circular(22));
    final locked = cost > 42;
    _card(canvas, r, colors: state == 'GİYİLİ' ? const [Color(0xFFFFF3C8), Color(0xFFFFD36B)] : const [Color(0xFFFFF7FD), Color(0xFFFFE3F4)]);
    canvas.saveLayer(r.outerRect, Paint()..color = Colors.white.withValues(alpha: locked ? 0.45 : 1));
    paintLokum(canvas, Offset(r.outerRect.center.dx, y + 84), 84, outfit: outfit);
    canvas.restore();
    _text(canvas, name, Offset(r.outerRect.center.dx, y + 150), 15, _ink, width: cw - 12);
    if (cost > 0) {
      paintGoldStar(canvas, Offset(r.outerRect.center.dx - 22, y + 180), 11, on: !locked);
      _text(canvas, state, Offset(r.outerRect.center.dx + 8, y + 180), 17, locked ? const Color(0xFF9A8AB0) : const Color(0xFF6A3A00), width: 60);
    } else {
      _text(canvas, state, Offset(r.outerRect.center.dx, y + 180), 15, state == 'GİYİLİ' ? const Color(0xFF0E6A32) : const Color(0xFF9A5AB5), width: cw);
    }
  }
  _text(canvas, 'Yıldızlarla yeni kostümler açılır', Offset(size.width / 2, size.height - 40), 17, Colors.white, width: 400);
}

void story(Canvas canvas, Size size) {
  final r = Offset.zero & size;
  // Eminönü at dusk: sky, skyline, the Bosphorus and the quay.
  final horizon = size.height * 0.56;
  paintDusk(canvas, Rect.fromLTWH(0, 0, size.width, horizon));
  paintSkyline(canvas, size.width, horizon, 230, const Color(0xFF3A1F5A));
  paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height * 0.16), ferryAt: 0.42);
  paintGulls(canvas, const [Offset(250, 320), Offset(282, 300), Offset(120, 250)], const Color(0xFF3A1F5A));
  final quay = Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28);
  canvas.drawRect(quay, Paint()..shader = ui.Gradient.linear(quay.topCenter, quay.bottomCenter, const [Color(0xFF8A6A7A), Color(0xFF3A2440)]));
  for (var x = 0.0; x < size.width; x += 46) {
    canvas.drawRect(Rect.fromLTWH(x, quay.top, 44, 8), Paint()..color = const Color(0xFFB08A9A));
  }
  // The panel frame.
  final panel = RRect.fromRectAndRadius(Rect.fromLTWH(18, 70, size.width - 36, size.height - 230), const Radius.circular(28));
  canvas.drawRRect(panel, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..color = Colors.white);
  paintEksiLimon(canvas, Offset(size.width * 0.68, size.height * 0.3), 140);
  _bubble(canvas, Rect.fromLTWH(30, 104, 250, 104), 'Ha ha! İstanbul\'un bütün tatlılarını ekşiteceğim!', tailLeft: false, size: 17, fill: const Color(0xFFFFF7A0), ink: const Color(0xFF5A3A00));
  paintLokum(canvas, Offset(size.width * 0.24, size.height * 0.7), 120, pose: LokumPose.point, outfit: LokumOutfit.fez);
  _bubble(canvas, Rect.fromLTWH(size.width * 0.44, size.height * 0.732, 216, 60), 'Mısır Çarşısı\'ndan başlayalım!', size: 16);
  // Caption and progress.
  _label(canvas, 'BÖLÜM 1', Offset(size.width / 2, size.height - 128), 22, colors: const [Colors.white, Color(0xFFFFE3F4)]);
  _label(canvas, 'Eminönü', Offset(size.width / 2, size.height - 96), 34);
  for (var i = 0; i < 3; i++) {
    canvas.drawCircle(Offset(size.width / 2 - 20 + i * 20, size.height - 58), i == 0 ? 6 : 5, Paint()..color = i == 0 ? Colors.white : Colors.white.withValues(alpha: 0.4));
  }
  _text(canvas, 'Dokun ›', Offset(size.width - 70, size.height - 58), 18, Colors.white, width: 120);
  canvas.drawRect(r, Paint()..color = Colors.transparent);
}

/// Lokum's tour of İstanbul: the twelve chapters as stops along a path.
void istanbulMap(Canvas canvas, Size size) {
  final r = Offset.zero & size;
  paintDusk(canvas, Rect.fromLTWH(0, 0, size.width, 260));
  paintSkyline(canvas, size.width, 260, 150, const Color(0xFF3A1F5A));
  canvas.drawRect(Rect.fromLTWH(0, 260, size.width, size.height - 260), Paint()..shader = ui.Gradient.linear(Offset(0, 260), Offset(0, size.height), const [Color(0xFF4A3090), Color(0xFF2A1A5A)]));
  paintGulls(canvas, const [Offset(300, 90), Offset(330, 72), Offset(80, 120)], const Color(0xFF3A1F5A));
  _label(canvas, 'LOKUM\'UN İSTANBUL TURU', Offset(size.width / 2, 40), 28);
  const stops = [
    ('Eminönü', 'Mısır Çarşısı · başlangıç', true),
    ('Kız Kulesi', 'buzlu şekerler', true),
    ('Rumeli Hisarı', 'zincirler', true),
    ('Kapalıçarşı', 'kapalı kutular', true),
    ('Galata', 'süreli bombalar', true),
    ('Adalar', 'gökkuşağı şekerler', true),
    ('Kadıköy', 'yayılan çikolata', false),
    ('Ortaköy', 'meyveyi indir', false),
    ('Boğaz Vapuru', 'taşıyıcı bantlar', false),
    ('İstiklal', 'kat kat pasta', false),
    ('Balat', 'renkli kapılar', false),
    ('Çamlıca Tepesi', 'Ekşi Limon ile final', false),
  ];
  // A winding path down the page.
  final pins = [for (var i = 0; i < stops.length; i++) Offset(size.width * (i.isEven ? 0.28 : 0.72), 300.0 + i * 88)];
  final path = Path()..moveTo(pins.first.dx, pins.first.dy);
  for (var i = 1; i < pins.length; i++) {
    final a = pins[i - 1], b = pins[i];
    path.cubicTo(a.dx, a.dy + 50, b.dx, b.dy - 50, b.dx, b.dy);
  }
  canvas.drawPath(path, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.18));
  for (var i = 0; i < stops.length; i++) {
    final (name, what, open) = stops[i];
    final c = pins[i];
    final isNew = i >= 6;
    canvas.drawCircle(c + const Offset(0, 4), 24, Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawCircle(c, 24, Paint()..color = open ? const Color(0xFFFF4FA3) : (i == 11 ? const Color(0xFFFFD000) : const Color(0xFF6A5AA0)));
    canvas.drawCircle(c, 24, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white);
    _text(canvas, '${i + 1}', c, 20, i == 11 ? const Color(0xFF5A3A00) : Colors.white, width: 40);
    final left = i.isEven;
    final tx = left ? c.dx + 36 : c.dx - 36 - 190;
    _text(canvas, name, Offset(tx, c.dy - 22), 19, Colors.white, centre: false, width: 190);
    _text(canvas, what, Offset(tx, c.dy + 2), 14, isNew ? const Color(0xFFFFE066) : const Color(0xFFE6D6FF), centre: false, width: 190, weight: FontWeight.w700);
  }
  paintLokum(canvas, pins[4] + const Offset(-64, 0), 54, pose: LokumPose.cheer, outfit: LokumOutfit.fez);
  paintEksiLimon(canvas, pins[11] + const Offset(72, 0), 50);
  _text(canvas, 'Sarı yazılar: yeni bölümler (7–12)', Offset(size.width / 2, size.height - 30), 15, const Color(0xFFFFE066), width: 400, weight: FontWeight.w700);
  canvas.drawRect(r, Paint()..color = Colors.transparent);
}

/// One phone screen of the "Lokum everywhere" sheet.
void _phone(Canvas canvas, Rect r, String title, List<Color> sky, void Function(Rect inner) body) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(30));
  canvas.drawRRect(rr.shift(const Offset(0, 8)), Paint()..color = Colors.black.withValues(alpha: 0.35));
  canvas.save();
  canvas.clipRRect(rr);
  _backdrop(canvas, r, sky, r.left.round() + r.top.round());
  body(r.deflate(16));
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..color = Colors.white);
  _text(canvas, title, Offset(r.center.dx, r.bottom + 30), 22, Colors.white, width: r.width);
}

void everywhere(Canvas canvas, Size size) {
  _backdrop(canvas, Offset.zero & size, const [Color(0xFF5A1FA8), Color(0xFFB0307E), Color(0xFF3A1470)], 21);
  _label(canvas, 'LOKUM HER YERDE', Offset(size.width / 2, 52), 34);
  _text(canvas, 'Dolaptan seçtiğin kostüm her ekranda Lokum\'un üstünde', Offset(size.width / 2, 96), 18, Colors.white, width: 800, weight: FontWeight.w700);
  const outfit = LokumOutfit.fez;
  final w = (size.width - 80) / 2, h = 470.0;

  // 1. Home: Lokum greets you, his wardrobe one tap away.
  _phone(canvas, Rect.fromLTWH(30, 130, w, h), 'Ana menü', const [Color(0xFFFFD6EC), Color(0xFFE6CCFF)], (r) {
    _text(canvas, 'LifeOS Küpler', Offset(r.center.dx, r.top + 22), 26, _ink, width: r.width);
    paintLokum(canvas, Offset(r.left + 90, r.top + 150), 120, pose: LokumPose.wink, outfit: outfit);
    _bubble(canvas, Rect.fromLTWH(r.left + 168, r.top + 70, r.width - 172, 76), 'Bugün Zincir\'i denedin mi?', size: 16);
    final dolap = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 182, r.top + 170, r.width - 200, 44), const Radius.circular(22));
    canvas.drawRRect(dolap, Paint()..color = const Color(0xFFFF4FA3));
    _text(canvas, 'Lokum\'un dolabı', dolap.outerRect.center, 17, Colors.white, width: dolap.width);
    for (var i = 0; i < 3; i++) {
      final card = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + i * (r.width / 3) + 4, r.top + 250, r.width / 3 - 8, 150), const Radius.circular(18));
      _card(canvas, card);
      _text(canvas, ['Şeker', 'Zincir', 'Klasik'][i], Offset(card.outerRect.center.dx, card.bottom - 24), 16, _ink, width: card.width);
    }
    for (final (i, c) in [SugarColor.red, SugarColor.yellow].indexed) {
      paintCandy(canvas, Rect.fromCenter(center: Offset(r.left + r.width / 6 + (i - 0.5) * 34, r.top + 310), width: 34, height: 34), c);
    }
    paintChainCube(canvas, Rect.fromCenter(center: Offset(r.center.dx, r.top + 310), width: 40, height: 40), chainColors[ChainColor.magenta]!);
  });

  // 2. Zincir Küpler: cheering the chains from the side.
  _phone(canvas, Rect.fromLTWH(50 + w, 130, w, h), 'Zincir Küpler', const [Color(0xFF14103A), Color(0xFF2A1060)], (r) {
    final rnd = Random(4);
    const cell = 40.0;
    final o = Offset(r.left + 8, r.top + 70);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - 6, o.dy - 6, 6 * cell + 12, 8 * cell + 12), const Radius.circular(14)), Paint()..color = Colors.black.withValues(alpha: 0.4));
    for (var y = 2; y < 8; y++) {
      for (var x = 0; x < 6; x++) {
        if (y == 2 && x.isOdd) continue;
        paintChainCube(canvas, Rect.fromLTWH(o.dx + x * cell + 2, o.dy + y * cell + 2, cell - 4, cell - 4), chainColors[ChainColor.values[rnd.nextInt(5)]]!, halo: false);
      }
    }
    _label(canvas, '4 ZİNCİR!', Offset(o.dx + 3 * cell, o.dy + 40), 34);
    paintLokum(canvas, Offset(r.right - 62, r.bottom - 150), 104, pose: LokumPose.cheer, hop: 0.4, outfit: outfit);
    _bubble(canvas, Rect.fromLTWH(r.right - 150, r.top + 120, 146, 70), 'Harika! Devam!', size: 16, tailLeft: false);
  });

  // 3. The classic modes: peeking over the well, cheering a Tetris.
  _phone(canvas, Rect.fromLTWH(30, 680, w, h), 'Klasik ve Süper mod', const [Color(0xFF1A2A6A), Color(0xFF4A3A9A)], (r) {
    const cell = 28.0;
    final o = Offset(r.left + 20, r.top + 40);
    canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 10 * cell, 14 * cell), Paint()..color = Colors.black.withValues(alpha: 0.45));
    const colors = [Color(0xFF00D8FF), Color(0xFFFFD000), Color(0xFFB04CFF), Color(0xFF12D24E), Color(0xFFFF3B4A), Color(0xFF2F5BFF), Color(0xFFFF7A00)];
    final rnd = Random(8);
    for (var y = 9; y < 14; y++) {
      for (var x = 0; x < 10; x++) {
        if (y < 11 && rnd.nextInt(3) == 0) continue;
        final c = colors[rnd.nextInt(colors.length)];
        final b = Rect.fromLTWH(o.dx + x * cell + 1, o.dy + y * cell + 1, cell - 2, cell - 2);
        canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)), Paint()..shader = ui.Gradient.linear(b.topLeft, b.bottomRight, [Color.lerp(c, Colors.white, 0.35)!, c]));
      }
    }
    for (var y = 11; y < 14; y++) {
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy + y * cell, 10 * cell, cell), Paint()..color = Colors.white.withValues(alpha: y == 12 ? 0.75 : 0.55));
    }
    _label(canvas, 'DÖRTLÜ!', Offset(o.dx + 5 * cell, o.dy + 5 * cell), 40);
    paintLokum(canvas, Offset(r.right - 52, r.top + 250), 90, pose: LokumPose.wow, outfit: outfit);
    _bubble(canvas, Rect.fromLTWH(r.right - 130, r.top + 120, 126, 64), 'Dört sıra!', size: 16, tailLeft: false);
  });

  // 4. Results: dancing for a new record.
  _phone(canvas, Rect.fromLTWH(50 + w, 680, w, h), 'Oyun sonu', const [Color(0xFFFFB6D9), Color(0xFFC9A0FF)], (r) {
    final card = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 10, r.top + 30, r.width - 20, 200), const Radius.circular(24));
    _card(canvas, card);
    _text(canvas, 'YENİ REKOR', Offset(r.center.dx, r.top + 70), 26, const Color(0xFFFF4FA3), width: r.width);
    _text(canvas, '15.398', Offset(r.center.dx, r.top + 130), 52, _ink, width: r.width);
    _text(canvas, '40 sıra · 5:00', Offset(r.center.dx, r.top + 190), 17, const Color(0xFF9A5AB5), width: r.width, weight: FontWeight.w700);
    paintLokum(canvas, Offset(r.center.dx - 40, r.bottom - 120), 120, pose: LokumPose.dance, beat: 0.2, outfit: outfit);
    _bubble(canvas, Rect.fromLTWH(r.center.dx + 30, r.bottom - 230, r.width / 2 - 30, 64), 'Kutlama!', size: 17);
  });
}

Future<void> _save(WidgetTester tester, Size size, void Function(Canvas, Size) paint, String name, {double scale = 2}) async {
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
  testWidgets('poses', (tester) => _save(tester, const Size(900, 990), poses, 'lokum-tepkiler.png'));
  testWidgets('in game', (tester) => _save(tester, const Size(900, 800), inGame, 'lokum-oyunda.png'));
  testWidgets('wardrobe', (tester) => _save(tester, const Size(430, 900), wardrobe, 'lokum-dolap.png', scale: 2.5));
  testWidgets('everywhere', (tester) => _save(tester, const Size(900, 1220), everywhere, 'lokum-her-yerde.png'));
  testWidgets('istanbul map', (tester) => _save(tester, const Size(430, 1360), istanbulMap, 'istanbul-turu.png', scale: 2.5));
  // Lone Lokum sprites on a clear background, for placement previews.
  for (final (pose, name) in [(LokumPose.cheer, 'cheer'), (LokumPose.wow, 'wow'), (LokumPose.happy, 'happy')]) {
    testWidgets('sprite $name', (tester) => _save(tester, const Size(200, 220), (canvas, size) => paintLokum(canvas, const Offset(100, 125), 150, pose: pose, outfit: LokumOutfit.fez), 'sprite-$name.png'));
  }
  testWidgets('story', (tester) => _save(tester, const Size(430, 900), story, 'hikaye-karti.png', scale: 2.5));
}
