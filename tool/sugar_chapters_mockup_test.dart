// Mock-up of six new Şeker Küpler chapters (levels 121-180): a place of
// İstanbul each, a new obstacle each, a new rival at the end; and a level
// of the day once they are all done.
//   flutter test tool/sugar_chapters_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): seker-yeni-bolumler.png.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/core/tower/tower_landmarks.dart';
import 'package:lifeos_kupler/game/sugar/istanbul_art.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';
import 'package:lifeos_kupler/game/tower/landmark_art.dart';

import 'mock_kit.dart';

const _soft = Color(0xFFD9C8F5);
const _ink = Color(0xFF15101F);

/// The place: a sky, the skyline, the water and the landmark.
void _place(Canvas canvas, Rect r, List<Color> sky, {Landmark? landmark, double k = 0.5, bool night = false, void Function(double horizon)? extra}) {
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, sky, [for (var i = 0; i < sky.length; i++) i / (sky.length - 1)]));
  if (night) {
    final rnd = Random(4);
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height * 0.5), 1 + rnd.nextDouble(), Paint()..color = Colors.white.withValues(alpha: 0.7));
    }
  }
  final horizon = r.bottom - r.height * 0.22;
  canvas.save();
  canvas.translate(r.left, 0);
  paintSkyline(canvas, r.width, horizon, r.height * 0.55, (night ? const Color(0xFF2A1A4A) : const Color(0xFF7A4A9A)).withValues(alpha: 0.8));
  canvas.restore();
  paintBosphorus(canvas, Rect.fromLTWH(r.left, horizon, r.width, r.bottom - horizon), ferryAt: 0.25, tower: 0);
  if (landmark != null) paintLandmark(canvas, landmark, Offset(r.left + r.width * 0.72, horizon + 4), k);
  extra?.call(horizon);
}

/// A sweet on a cell, and the new thing on it.
Rect _cell(Offset c, double s) => Rect.fromCenter(center: c, width: s, height: s);

void _fog(Canvas canvas, Offset c, double s) {
  paintCandy(canvas, _cell(c, s * 0.9), SugarColor.blue);
  canvas.drawRRect(RRect.fromRectAndRadius(_cell(c, s), Radius.circular(s * 0.2)), Paint()..color = Colors.white.withValues(alpha: 0.45));
  final p = Paint()
    ..color = Colors.white.withValues(alpha: 0.85)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08);
  for (final (dx, dy, rr) in [(-0.2, 0.05, 0.3), (0.15, -0.1, 0.32), (0.05, 0.2, 0.28), (0.25, 0.15, 0.22)]) {
    canvas.drawCircle(c + Offset(dx * s, dy * s), rr * s, p);
  }
}

void _tunnel(Canvas canvas, Offset c, double s, Color tone) {
  canvas.drawOval(Rect.fromCenter(center: c, width: s * 0.95, height: s * 0.5), Paint()..shader = ui.Gradient.radial(c, s * 0.5, [const Color(0xFF0A0418), tone]));
  canvas.drawOval(Rect.fromCenter(center: c, width: s * 0.95, height: s * 0.5), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.08
    ..color = tone);
}

void _gull(Canvas canvas, Offset c, double s) {
  paintCandy(canvas, _cell(c + Offset(0, s * 0.2), s * 0.7), SugarColor.red);
  final body = Paint()..color = Colors.white;
  canvas.drawOval(Rect.fromCenter(center: c - Offset(0, s * 0.28), width: s * 0.5, height: s * 0.28), body);
  canvas.drawCircle(c - Offset(s * 0.22, s * 0.36), s * 0.12, body);
  canvas.drawPath(Path()..addPolygon([c - Offset(s * 0.32, s * 0.36), c - Offset(s * 0.46, s * 0.32), c - Offset(s * 0.32, s * 0.31)], true), Paint()..color = const Color(0xFFFFB020));
  canvas.drawCircle(c - Offset(s * 0.24, s * 0.38), s * 0.025, Paint()..color = _ink);
  canvas.drawPath(
    Path()
      ..moveTo(c.dx - s * 0.05, c.dy - s * 0.3)
      ..quadraticBezierTo(c.dx + s * 0.2, c.dy - s * 0.75, c.dx + s * 0.42, c.dy - s * 0.5)
      ..quadraticBezierTo(c.dx + s * 0.2, c.dy - s * 0.42, c.dx + s * 0.1, c.dy - s * 0.25),
    Paint()..color = const Color(0xFFE6E9F0),
  );
}

void _jam(Canvas canvas, Offset c, double s) {
  final r = RRect.fromRectAndRadius(_cell(c, s * 0.96), Radius.circular(s * 0.2));
  canvas.drawRRect(r, Paint()..color = const Color(0xCCE0245A));
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.05
    ..color = const Color(0xFFFF8AB0));
  for (final (dx, dy) in [(-0.2, -0.22), (0.18, -0.15), (0.0, 0.2)]) {
    canvas.drawCircle(c + Offset(dx * s, dy * s), s * 0.06, Paint()..color = Colors.white.withValues(alpha: 0.6));
  }
  paintCandy(canvas, _cell(c, s * 0.7), SugarColor.yellow);
}

void _lantern(Canvas canvas, Offset c, double s, int lit) {
  final body = Rect.fromCenter(center: c + Offset(0, s * 0.05), width: s * 0.5, height: s * 0.62);
  final on = lit >= 3;
  if (on) canvas.drawCircle(c, s * 0.7, Paint()..shader = ui.Gradient.radial(c, s * 0.7, const [Color(0xCCFFE07A), Color(0x00FFE07A)]));
  canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(s * 0.12)), Paint()..color = on ? const Color(0xFFFFD34A) : const Color(0xFF5A4A7A));
  canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(s * 0.12)), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.06
    ..color = const Color(0xFF8A5A10));
  canvas.drawRect(Rect.fromCenter(center: body.topCenter - Offset(0, s * 0.05), width: s * 0.34, height: s * 0.1), Paint()..color = const Color(0xFF8A5A10));
  for (var i = 0; i < 3; i++) {
    canvas.drawCircle(body.bottomCenter + Offset((i - 1) * s * 0.18, s * 0.16), s * 0.06, Paint()..color = i < lit ? const Color(0xFFFFE07A) : Colors.white.withValues(alpha: 0.3));
  }
}

/// Acı Biber: a red pepper with a green cap and a cheeky grin.
void _pepper(Canvas canvas, Offset c, double s) {
  final body = Path()
    ..moveTo(c.dx - s * 0.28, c.dy - s * 0.3)
    ..quadraticBezierTo(c.dx + s * 0.4, c.dy - s * 0.45, c.dx + s * 0.3, c.dy + s * 0.05)
    ..quadraticBezierTo(c.dx + s * 0.18, c.dy + s * 0.45, c.dx - s * 0.05, c.dy + s * 0.62)
    ..quadraticBezierTo(c.dx - s * 0.02, c.dy + s * 0.3, c.dx - s * 0.32, c.dy + s * 0.05)
    ..quadraticBezierTo(c.dx - s * 0.45, c.dy - s * 0.2, c.dx - s * 0.28, c.dy - s * 0.3)
    ..close();
  canvas.drawPath(body, Paint()..shader = ui.Gradient.linear(c - Offset(s * 0.3, s * 0.3), c + Offset(s * 0.3, s * 0.5), const [Color(0xFFFF5A3A), Color(0xFFC0101A)]));
  canvas.drawPath(body, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.04
    ..color = const Color(0xFF6A0A10));
  canvas.drawPath(
    Path()
      ..moveTo(c.dx - s * 0.12, c.dy - s * 0.33)
      ..quadraticBezierTo(c.dx - s * 0.05, c.dy - s * 0.55, c.dx + s * 0.12, c.dy - s * 0.6),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3AA34A),
  );
  for (final dx in [-0.12, 0.1]) {
    canvas.drawCircle(c + Offset(dx * s, -s * 0.08), s * 0.07, Paint()..color = Colors.white);
    canvas.drawCircle(c + Offset(dx * s + s * 0.015, -s * 0.07), s * 0.035, Paint()..color = _ink);
  }
  // Angry brows and a grin.
  final ink = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.035
    ..strokeCap = StrokeCap.round
    ..color = _ink;
  canvas.drawLine(c + Offset(-s * 0.2, -s * 0.2), c + Offset(-s * 0.05, -s * 0.15), ink);
  canvas.drawLine(c + Offset(s * 0.18, -s * 0.2), c + Offset(s * 0.03, -s * 0.15), ink);
  canvas.drawArc(Rect.fromCenter(center: c + Offset(0, s * 0.06), width: s * 0.26, height: s * 0.16), 0.2, pi - 0.4, false, ink);
  // A little flame on top: it is hot.
  canvas.drawPath(
    Path()
      ..moveTo(c.dx + s * 0.32, c.dy - s * 0.3)
      ..quadraticBezierTo(c.dx + s * 0.5, c.dy - s * 0.5, c.dx + s * 0.4, c.dy - s * 0.7)
      ..quadraticBezierTo(c.dx + s * 0.6, c.dy - s * 0.48, c.dx + s * 0.45, c.dy - s * 0.28)
      ..close(),
    Paint()..color = const Color(0xFFFFA020),
  );
}

void _card(Canvas canvas, Rect r, int n, String place, String obstacle, String line, List<Color> sky, {Landmark? landmark, double k = 0.5, bool night = false, required void Function(Rect demo) demo, void Function(double h, Rect art)? extra, bool boss = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(24));
  canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()..color = _ink);
  canvas.save();
  canvas.clipRRect(rr);
  final art = Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.52);
  _place(canvas, art, sky, landmark: landmark, k: k, night: night, extra: extra == null ? null : (h) => extra(h, art));
  final band = Rect.fromLTRB(r.left, art.bottom, r.right, r.bottom);
  canvas.drawRect(band, Paint()..shader = ui.Gradient.linear(band.topCenter, band.bottomCenter, boss ? const [Color(0xFF8A1A2A), Color(0xFF4A0A1A)] : const [Color(0xFF4A2A7A), Color(0xFF2A1450)]));
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white.withValues(alpha: 0.85));
  // Chapter and levels.
  final chip = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 12, r.top + 12, 150, 26), const Radius.circular(13));
  canvas.drawRRect(chip, Paint()..color = Colors.black.withValues(alpha: 0.45));
  mockText(canvas, 'Bölüm $n · ${(n - 1) * 10 + 1}-${n * 10}', chip.center, 13, Colors.white, width: 150);
  mockText(canvas, place, Offset(band.left + 16, band.top + 12), 22, Colors.white, centre: false, width: band.width - 110);
  // The new obstacle: a little demo and its name.
  final d = Rect.fromLTWH(band.right - 92, band.top + 12, 78, 78);
  canvas.drawRRect(RRect.fromRectAndRadius(d, const Radius.circular(16)), Paint()..color = Colors.white.withValues(alpha: 0.1));
  demo(d);
  final tag = RRect.fromRectAndRadius(Rect.fromLTWH(band.left + 16, band.top + 46, ('YENİ: $obstacle').length * 8.4 + 24, 24), const Radius.circular(12));
  canvas.drawRRect(tag, Paint()..color = boss ? const Color(0xFFFF5A3A) : const Color(0xFFFF5FB8));
  mockText(canvas, 'YENİ: $obstacle', tag.center, 12, Colors.white, width: tag.width + 40);
  mockText(canvas, line, Offset(band.left + 16, band.top + 80), 13, _soft, centre: false, width: band.width - 120, weight: FontWeight.w600, lines: 3);
}

void _sheet(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));
  mockText(canvas, 'Şeker Küpler · 2. sezon: Boğaz Turu', Offset(size.width / 2, 44), 30, Colors.white, width: size.width);
  mockText(canvas, '6 yeni bölüm, 60 yeni seviye (121-180). Ekşi Limon tatlandı, ama kuzeni Acı Biber şehre geldi ve şekerleri acılaştırıyor.',
      Offset(size.width / 2, 88), 16, _soft, width: size.width - 120, weight: FontWeight.w600, lines: 2);

  const w = 380.0, h = 330.0, gap = 26.0;
  Rect at(int i) => Rect.fromLTWH(40 + (i % 3) * (w + gap), 140 + (i ~/ 3) * (h + gap), w, h);

  _card(canvas, at(0), 13, 'Kız Kulesi', 'SİS', 'Sabah sisi bazı kareleri örter. Yanında eşleştir, sis dağılsın; altından şeker çıkar.',
      const [Color(0xFFBFD8F0), Color(0xFFE9D8EC)], landmark: Landmark.maidens, k: 0.42,
      extra: (hz, art) {
        final p = Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawOval(Rect.fromLTWH(art.left - 20, hz - 40, art.width * 0.7, 60), p);
      },
      demo: (d) => _fog(canvas, d.center, d.width * 0.8));
  _card(canvas, at(1), 14, 'Haydarpaşa Garı', 'TÜNEL', 'Şekerler bir tünele düşer, öbüründen çıkar. Hangi şekerin nereden geleceğini kestir.',
      const [Color(0xFF8CC4FF), Color(0xFFFFD0A0)], landmark: Landmark.haydarpasa, k: 0.36,
      demo: (d) {
        _tunnel(canvas, d.center - Offset(0, d.height * 0.2), d.width * 0.7, const Color(0xFF6A4AE0));
        _tunnel(canvas, d.center + Offset(0, d.height * 0.25), d.width * 0.7, const Color(0xFF2AC0E0));
        paintCandy(canvas, _cell(d.center + Offset(0, d.height * 0.02), d.width * 0.36), SugarColor.green);
      });
  _card(canvas, at(2), 15, 'Eminönü', 'MARTI', 'Martılar her birkaç hamlede bir şeker kapar. Martının yanında eşleştir, kaçsın.',
      const [Color(0xFF7FB8F0), Color(0xFFFFE0B0)],
      extra: (hz, art) => paintGulls(canvas, [Offset(art.left + 60, art.top + 50), Offset(art.left + 110, art.top + 36), Offset(art.left + 260, art.top + 60)], Colors.white),
      demo: (d) => _gull(canvas, d.center + Offset(0, d.height * 0.12), d.width * 0.8));
  _card(canvas, at(3), 16, 'Kuzguncuk', 'REÇEL', 'Reçelli karede eşleşince reçel yanındaki şekerlere bulaşır. Bütün tahtayı reçelle kapla!',
      const [Color(0xFFFFB0A0), Color(0xFFFFE6C0)],
      extra: (hz, art) {
        // Wooden houses in a row.
        const colors = [Color(0xFFE8A060), Color(0xFF9AD0C0), Color(0xFFF0D070), Color(0xFFE08A9A), Color(0xFFB0A0E0)];
        for (var i = 0; i < 5; i++) {
          final x = art.left + 20 + i * 58.0;
          final house = Rect.fromLTWH(x, hz - 52, 50, 52);
          canvas.drawRect(house, Paint()..color = colors[i]);
          canvas.drawPath(Path()..addPolygon([house.topLeft - const Offset(4, 0), Offset(house.center.dx, house.top - 22), house.topRight + const Offset(4, 0)], true), Paint()..color = const Color(0xFFB0443A));
          for (final dx in [10.0, 30.0]) {
            canvas.drawRect(Rect.fromLTWH(x + dx, hz - 40, 10, 14), Paint()..color = const Color(0xFF4A3A6A));
          }
        }
      },
      demo: (d) {
        _jam(canvas, d.center - Offset(d.width * 0.18, 0), d.width * 0.42);
        _jam(canvas, d.center + Offset(d.width * 0.24, 0), d.width * 0.42);
      });
  _card(canvas, at(4), 17, 'Dolmabahçe', 'FENER', 'Saray bahçesinin fenerleri sönmüş. Yanında üç kez eşleştir, fener yansın.',
      const [Color(0xFF2A2A7A), Color(0xFF8A4AA0)], landmark: Landmark.dolmabahce, k: 0.34, night: true,
      demo: (d) {
        _lantern(canvas, d.center - Offset(d.width * 0.2, 0), d.width * 0.55, 1);
        _lantern(canvas, d.center + Offset(d.width * 0.22, 0), d.width * 0.55, 3);
      });
  _card(canvas, at(5), 18, 'Büyükada', 'ACI BİBER', 'Son bölüm: Acı Biber tahtaya acı şekerler atar, eşleşmezsen yanar. Hepsi bir arada!',
      const [Color(0xFFFF8A5A), Color(0xFFFFD08A)], boss: true,
      extra: (hz, art) {
        // The island's hill and a pine.
        canvas.drawPath(Path()..moveTo(art.left + 120, hz)..quadraticBezierTo(art.left + 230, hz - 90, art.right - 20, hz)..close(), Paint()..color = const Color(0xFF5A8A4A));
        _pepper(canvas, Offset(art.left + 80, art.top + 90), 80);
      },
      demo: (d) {
        paintCandy(canvas, _cell(d.center, d.width * 0.62), SugarColor.orange);
        canvas.drawCircle(d.center, d.width * 0.38, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFFFF3A1A));
        mockText(canvas, '3', d.center + Offset(d.width * 0.3, -d.height * 0.3), 16, Colors.white, width: 30);
      });

  // After the last level: one new level a day.
  final r = Rect.fromLTWH(40, 140 + 2 * (h + gap), size.width - 80, 120);
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(24));
  canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()..color = _ink);
  canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [Color(0xFF14B8A6), Color(0xFF0E7A70)]));
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.white.withValues(alpha: 0.85));
  paintLokum(canvas, Offset(r.left + 70, r.center.dy + 4), 84, pose: LokumPose.cheer);
  mockText(canvas, 'Hepsi bitince: Günün Şekeri', Offset(r.left + 130, r.top + 22), 24, Colors.white, centre: false, width: 700);
  mockText(canvas, '180. seviyeden sonra her gün yeni bir seviye; herkese aynı seviye, üç yıldız ve kendi rekorun. Hızlı oyuncular hiç boşta kalmaz.',
      Offset(r.left + 130, r.top + 58), 15, Colors.white.withValues(alpha: 0.9), centre: false, width: r.width - 300, weight: FontWeight.w600, lines: 2);
  for (var i = 0; i < 3; i++) {
    paintGoldStar(canvas, Offset(r.right - 140 + i * 46, r.center.dy), 18);
  }
}

void main() {
  setUpAll(mockFonts);

  testWidgets('sugar chapters', (tester) async {
    await mockSave(tester, const Size(40 * 2 + 380 * 3 + 26 * 2, 140 + 330 * 2 + 26 * 2 + 120 + 40), _sheet, 'seker-yeni-bolumler.png', scale: 2);
  });
}
