// Mock-up of the reorganised games page: the games first, each with its own
// page of modes (Zincir Küpler and Klasik Küpler shown), and a place for the
// coming tower game.
//   flutter test tool/games_menu_mockup_test.dart
// Writes MOCKUP_OUT (default build/mockups/): oyunlar-duzen.png.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/sugar/sugar_game.dart';
import 'package:lifeos_kupler/game/chain/chain_sprites.dart' show chainColors, paintChainCube;
import 'package:lifeos_kupler/game/render/block_sprites.dart';
import 'package:lifeos_kupler/game/sugar/sugar_art.dart';

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

void _box(Canvas canvas, RRect r, {Color fill = _card, Color border = _edge, double width = 2.5, double depth = 4}) {
  canvas.drawRRect(r.shift(Offset(0, depth)), Paint()..color = _edge);
  canvas.drawRRect(r, Paint()..color = fill);
  canvas.drawRRect(r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = border);
}

void _chip(Canvas canvas, String text, Offset at, Color fill, {Color ink = Colors.white, double size = 10.5}) {
  final w = text.length * size * 0.62 + 14;
  final r = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, w, size + 7), Radius.circular(size));
  canvas.drawRRect(r, Paint()..color = fill);
  mockText(canvas, text, r.center + const Offset(0, 0.5), size, ink, width: w);
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

void _header(Canvas canvas, String title) {
  _box(canvas, RRect.fromRectAndRadius(const Rect.fromLTWH(16, 54, 42, 42), const Radius.circular(13)), fill: const Color(0xFF4A4068), depth: 3);
  _icon(canvas, Icons.arrow_back_rounded, const Offset(37, 75), 22, _text);
  _t(canvas, title, const Offset(72, 56), 27, _text, weight: FontWeight.w800);
}

// ------------------------------------------------------------ game scenes

enum _Scene { sugar, chain, puzzle, power, classic, tower }

void _scene(Canvas canvas, Rect r, _Scene scene) {
  canvas.save();
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
  canvas.clipRRect(rr);
  final sky = switch (scene) {
    _Scene.sugar => const [Color(0xFF6A25B8), Color(0xFF3A1270)],
    _Scene.tower => const [Color(0xFFFF9A62), Color(0xFF7B3FC4)],
    _ => const [Color(0xFF1E1830), Color(0xFF120E1E)],
  };
  canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, sky));
  switch (scene) {
    case _Scene.sugar:
      final s = r.height / 3.2;
      const colors = SugarColor.values;
      final cols = (r.width / s).floor();
      final x0 = r.left + (r.width - cols * s) / 2;
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < cols; x++) {
          paintCandy(canvas, Rect.fromLTWH(x0 + x * s, r.top + (r.height - 3 * s) / 2 + y * s, s, s).deflate(s * 0.04), colors[(x * 2 + y * 3) % colors.length]);
        }
      }
      paintSparkle(canvas, r.topRight + Offset(-s * 0.6, s * 0.5), s * 0.35, const Color(0xFFFFE066));
    case _Scene.chain:
      final s = r.height / 4.6;
      final cols = (r.width / s).floor();
      final x0 = r.left + (r.width - cols * s) / 2;
      const colors = [ChainColor.magenta, ChainColor.blue, ChainColor.green, ChainColor.yellow, ChainColor.orange];
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < cols; x++) {
          if (y == 3 && x % 3 == 1) continue;
          paintChainCube(canvas, Rect.fromLTWH(x0 + x * s, r.bottom - (y + 1) * s, s, s).deflate(s * 0.04), chainColors[colors[(x * 3 + y * 2) % colors.length]]!);
        }
      }
      paintSugarLabel(canvas, '×3', Offset(r.center.dx, r.top + s * 0.55), s * 0.75,
          Paint()..shader = ui.Gradient.linear(r.topCenter, r.topCenter + Offset(0, s), const [Color(0xFFFFF6B0), Color(0xFFFF8A10)]),
          outline: const Color(0xFF3A0F2A), stroke: 0.2);
    case _Scene.puzzle:
      const n = 6;
      final s = r.height / (n + 0.6);
      final o = Offset(r.center.dx - n * s / 2, r.center.dy - n * s / 2);
      final slot = Paint()..color = Colors.white.withValues(alpha: 0.07);
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(1), Radius.circular(s * 0.18)), slot);
          if (y >= 3 && x < 5 && !(y == 4 && x >= 1 && x <= 3) && (x + y * 5) % 7 != 0) {
            paintToyBlock(canvas, Offset(o.dx + x * s, o.dy + y * s), s, _blocks[(x + y) % 5], _edge);
          }
        }
      }
      for (var dx = 0; dx < 3; dx++) {
        paintToyBlock(canvas, Offset(o.dx + (1 + dx) * s, o.dy + 1.2 * s), s, _blocks[2], _edge);
      }
    case _Scene.power || _Scene.classic:
      final s = r.height / 6.5;
      final cols = (r.width / s).floor();
      final x0 = r.left + (r.width - cols * s) / 2;
      final gap = cols ~/ 2 - 1;
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < cols; x++) {
          if (y == 1 && (x == gap || x == gap + 1)) continue;
          if (y == 0 && (x * 7 + 3) % 5 < 2) continue;
          paintToyBlock(canvas, Offset(x0 + x * s, r.bottom - (2 - y) * s), s, _blocks[(x * 3 + y) % _blocks.length], _edge);
        }
      }
      final power = scene == _Scene.power;
      final cells = power ? const [(0, 0), (1, 0), (2, 0), (1, -1)] : const [(0, 0), (1, 0), (0, 1), (1, 1)];
      for (final (dx, dy) in cells) {
        paintToyBlock(canvas, Offset(x0 + (gap - (power ? 1 : 0) + dx) * s, r.top + s * 1.8 + dy * s), s, power ? _blocks[4] : _blocks[6], _edge);
      }
      if (power) {
        paintSparkle(canvas, Offset(x0 + (gap + 2.6) * s, r.top + s * 1.2), s * 0.5, const Color(0xFFFFE066));
        paintSparkle(canvas, Offset(x0 + (gap - 1.6) * s, r.top + s * 2.6), s * 0.32, const Color(0xFF9AF0FF));
      }
    case _Scene.tower:
      final h = r.height / 7.5;
      var w = r.width * 0.5;
      var x = r.center.dx - w / 2;
      for (var i = 0; i < 6; i++) {
        final slab = Rect.fromLTWH(x, r.bottom - (i + 1) * h, w, h);
        canvas.drawRRect(RRect.fromRectAndRadius(slab.deflate(1), Radius.circular(h * 0.2)), Paint()..color = [const Color(0xFF2DD4BF), const Color(0xFFA78BFA), const Color(0xFFFB7185)][i % 3]);
        canvas.drawRRect(RRect.fromRectAndRadius(slab.deflate(1), Radius.circular(h * 0.2)), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = _edge);
        if (i.isOdd) {
          x += w * 0.06;
          w *= 0.92;
        }
      }
      final slab = Rect.fromLTWH(r.left + r.width * 0.62, r.top + h * 0.7, w, h);
      canvas.drawRRect(RRect.fromRectAndRadius(slab, Radius.circular(h * 0.2)), Paint()..color = const Color(0xFF2DD4BF));
      canvas.drawRRect(RRect.fromRectAndRadius(slab, Radius.circular(h * 0.2)), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _edge);
  }
  canvas.restore();
  canvas.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = _edge);
}

// ------------------------------------------------------------ cards

/// A game on the games page: its scene, name, line, modes and progress.
void _gameCard(Canvas canvas, Rect r, _Scene scene, String title, String line, String? modes, String? progress,
    {bool selected = false, bool isNew = false, bool soon = false, IconData? progressIcon}) {
  canvas.saveLayer(r.inflate(10), Paint()..color = Colors.white.withValues(alpha: soon ? 0.6 : 1));
  _box(canvas, RRect.fromRectAndRadius(r, const Radius.circular(20)), border: selected ? _accent : _edge, width: selected ? 3 : 2.5);
  final art = Rect.fromLTWH(r.left + 10, r.top + 10, r.height * 1.12, r.height - 20);
  _scene(canvas, art, scene);
  final x = art.right + 13;
  _t(canvas, title, Offset(x, r.top + 12), 19, _text, width: r.right - x - 40);
  _t(canvas, line, Offset(x, r.top + 38), 12.5, _soft, width: r.right - x - 34, weight: FontWeight.w600);
  var cx = x;
  final y = r.bottom - 30;
  if (modes != null) {
    _chip(canvas, modes, Offset(cx, y), const Color(0xFF4F4572), ink: _text, size: 11);
    cx += modes.length * 11 * 0.62 + 22;
  }
  if (progress != null) {
    _icon(canvas, progressIcon ?? Icons.emoji_events_rounded, Offset(cx + 7, y + 9), 14, progressIcon == Icons.history_rounded ? _accent : _gold);
    _t(canvas, progress, Offset(cx + 17, y + 0.5), 12, _text, width: r.right - cx - 46);
  }
  if (isNew) _chip(canvas, 'YENİ', Offset(r.right - 52, r.top + 10), _newRed, size: 10);
  if (soon) _chip(canvas, 'YAKINDA', Offset(r.right - 74, r.top + 10), const Color(0xFF6B5F92), size: 10);
  if (!soon) {
    _icon(canvas, modes == null ? Icons.play_arrow_rounded : Icons.chevron_right_rounded, Offset(r.right - 20, r.center.dy + 6), 28, modes == null ? _gold : _soft);
  }
  canvas.restore();
}

/// A mode on a game's page: badge, name, line and record (as today).
void _modeCard(Canvas canvas, Rect r, IconData icon, Color tone, String title, String line, String? record, {bool selected = false, bool isNew = false}) {
  _box(canvas, RRect.fromRectAndRadius(r, const Radius.circular(20)), border: selected ? _accent : _edge, width: selected ? 3 : 2.5);
  final badge = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 12, r.top + 12, 38, 38), const Radius.circular(12));
  _box(canvas, badge, fill: tone, width: 2, depth: 2);
  _icon(canvas, icon, badge.center, 22, Colors.white);
  if (isNew) _chip(canvas, 'YENİ', Offset(r.right - 50, r.top + 12), _newRed, size: 10);
  _t(canvas, title, Offset(r.left + 12, r.bottom - 74), 16, _text, width: r.width - 20);
  _t(canvas, line, Offset(r.left + 12, r.bottom - 52), 12, _soft, width: r.width - 22, weight: FontWeight.w600, lines: 2);
  _icon(canvas, Icons.emoji_events_rounded, Offset(r.left + 19, r.bottom - 15), 14, record == null ? _label : _gold);
  _t(canvas, record ?? '—', Offset(r.left + 29, r.bottom - 24), 12.5, record == null ? _label : _text, width: r.width - 40);
}

void _sectionLabel(Canvas canvas, String text, double y) => _t(canvas, text, Offset(20, y), 12.5, _label, weight: FontWeight.w800);

/// The top of a game's page: its scene large, what it is, its modes.
void _hero(Canvas canvas, _Scene scene, String line, String modes, String? last) {
  final r = const Rect.fromLTWH(16, 112, 358, 132);
  _box(canvas, RRect.fromRectAndRadius(r, const Radius.circular(22)));
  final art = Rect.fromLTWH(r.left + 10, r.top + 10, 150, r.height - 20);
  _scene(canvas, art, scene);
  final x = art.right + 14;
  _t(canvas, line, Offset(x, r.top + 16), 14.5, _text, width: r.right - x - 10, lines: 2);
  _chip(canvas, modes, Offset(x, r.top + 66), const Color(0xFF4F4572), size: 11);
  if (last != null) {
    _icon(canvas, Icons.history_rounded, Offset(x + 7, r.top + 101), 14, _accent);
    _t(canvas, last, Offset(x + 17, r.top + 92), 12, _soft, width: r.right - x - 24);
  }
}

void _gamesPage(Canvas canvas, Size size) {
  _screen(canvas, size);
  _header(canvas, 'Oyunlar');
  const games = [
    (_Scene.sugar, 'Şeker Küpler', "Eşleştir, patlat, İstanbul'u gez", null, '54 / 360 yıldız', false, true, false),
    (_Scene.chain, 'Zincir Küpler', 'Kaydır, zincir kur, rakibini yen', '5 mod', 'Son: Vapur Hattı', true, true, false),
    (_Scene.puzzle, 'Bulmaca Küpler', 'Parçaları yerleştir, satır temizle', '4 mod', '21 / 300 yıldız', false, false, false),
    (_Scene.power, 'Süper Küpler', 'Enerji topla, güçleri kullan!', null, 'Rekor 898', false, false, false),
    (_Scene.classic, 'Klasik Küpler', 'Düşen bloklar, klasik kurallar', '7 mod', 'Rekor 267', false, false, false),
    (_Scene.tower, 'Kule Küpler', 'Blokları üst üste diz', null, null, false, false, true),
  ];
  var y = 114.0;
  for (final (scene, title, line, modes, progress, selected, isNew, soon) in games) {
    _gameCard(canvas, Rect.fromLTWH(16, y, 358, 104), scene, title, line, modes, progress,
        selected: selected, isNew: isNew, soon: soon, progressIcon: selected ? Icons.history_rounded : null);
    y += 116;
  }
}

void _modesGrid(Canvas canvas, double top, List<(IconData, Color, String, String, String?, bool, bool)> modes, {double h = 150}) {
  for (var i = 0; i < modes.length; i++) {
    final (icon, tone, title, line, record, selected, isNew) = modes[i];
    _modeCard(canvas, Rect.fromLTWH(16 + (i % 2) * 185.0, top + (i ~/ 2) * (h + 12), 173, h), icon, tone, title, line, record, selected: selected, isNew: isNew);
  }
}

void _chainPage(Canvas canvas, Size size) {
  _screen(canvas, size);
  _header(canvas, 'Zincir Küpler');
  _hero(canvas, _Scene.chain, 'Kaydır, zincir kur, rakibini yen', '5 mod', 'Son oynanan: Vapur Hattı');
  _sectionLabel(canvas, 'MODLAR', 266);
  _modesGrid(canvas, 290, const [
    (Icons.link_rounded, Color(0xFFA855F7), 'Sonsuz', 'Küpleri kaydır, zincir kur', 'Rekor 4.321', false, false),
    (Icons.hourglass_bottom_rounded, Color(0xFFF59E0B), 'Zamana Karşı', '2 dakikada en yüksek skor', null, false, true),
    (Icons.directions_boat_rounded, Color(0xFF06B6D4), 'Vapur Hattı', 'Boğaz iskelelerinde görevler', '12 / 72 yıldız', true, true),
    (Icons.extension_rounded, Color(0xFF22C55E), 'Bulmacalar', 'Hazır tahtayı az hamlede temizle', '9/80', false, true),
    (Icons.sports_kabaddi_rounded, Color(0xFFEF4444), "Limon'a Karşı", 'Bilgisayara karşı maç', null, false, true),
  ]);
}

void _classicPage(Canvas canvas, Size size) {
  _screen(canvas, size);
  _header(canvas, 'Klasik Küpler');
  _hero(canvas, _Scene.classic, 'Düşen bloklar, klasik kurallar', '7 mod', null);
  _sectionLabel(canvas, 'MODLAR', 266);
  _modesGrid(canvas, 290, const [
    (Icons.bolt_rounded, Color(0xFF3B82F6), 'Normal', 'Hız yavaşça artar', 'Rekor 267', false, false),
    (Icons.spa_rounded, Color(0xFF22C55E), 'Rahat', 'Sabit, sakin hız', null, false, false),
  ], h: 132);
  _sectionLabel(canvas, 'MEYDAN OKUMA', 446);
  _modesGrid(canvas, 470, const [
    (Icons.speed_rounded, Color(0xFF06B6D4), 'Hız Koşusu', '40 satır, en kısa süre', null, false, false),
    (Icons.timer_rounded, Color(0xFFF59E0B), '3 Dakika', '3 dakikada en yüksek skor', null, false, false),
    (Icons.layers_rounded, Color(0xFF22C55E), 'Kazı', '10 gri satırı kaz', null, false, false),
    (Icons.star_rounded, Color(0xFFFACC15), 'Hedef', 'Yıldızları topla, süre kazan', null, false, true),
    (Icons.casino_rounded, Color(0xFFA855F7), 'Kaos', 'Sürprizlerle dolu maraton', null, false, true),
  ], h: 132);
}

void _sheet(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0xFF1B1530), Color(0xFF2E2350)]));
  const phone = Size(390, 844);
  const captions = [
    ('1 · Oyunlar', 'Önce yalnızca oyunlar. Tek modlu oyun (sarı üçgen) hemen açılır, çok modlu oyun (ok) kendi sayfasına gider.'),
    ('2 · Bir oyunun sayfası', 'Zincir Küpler: üstte oyunun kendisi, altta yalnızca onun modları.'),
    ('3 · Bölümlü modlar', 'Klasik Küpler: asıl modlar ve meydan okumalar ayrı başlıkta.'),
  ];
  for (var i = 0; i < 3; i++) {
    final left = 40 + i * (phone.width + 60);
    final (title, text) = captions[i];
    mockText(canvas, title, Offset(left + phone.width / 2, 40), 26, Colors.white, width: phone.width + 40);
    mockText(canvas, text, Offset(left + phone.width / 2, 84), 15, _soft, width: phone.width + 20, weight: FontWeight.w600, lines: 2);
    mockPhone(canvas, Rect.fromLTWH(left, 130, phone.width, phone.height), switch (i) {
      0 => _gamesPage,
      1 => _chainPage,
      _ => _classicPage,
    });
  }
  // The arrow from the Zincir card to its page.
  final arrow = Paint()
    ..color = _accent
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final from = Offset(40 + phone.width + 4, 130 + 114 + 116 + 52);
  final to = Offset(40 + phone.width + 56, 130 + 120);
  canvas.drawPath(Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(from.dx + 40, from.dy, to.dx, to.dy), arrow);
  final dir = (to - Offset(from.dx + 40, from.dy));
  final a = atan2(dir.dy, dir.dx);
  canvas.drawPath(Path()
    ..moveTo(to.dx + cos(a + 2.5) * 14, to.dy + sin(a + 2.5) * 14)
    ..lineTo(to.dx, to.dy)
    ..lineTo(to.dx + cos(a - 2.5) * 14, to.dy + sin(a - 2.5) * 14), arrow);
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

  testWidgets('games page', (tester) async {
    await mockSave(tester, const Size(40 * 2 + 390 * 3 + 60 * 2, 130 + 844 + 40), _sheet, 'oyunlar-duzen.png', scale: 2);
  });
}
