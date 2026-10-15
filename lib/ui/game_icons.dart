import 'dart:math';

import 'package:flutter/material.dart';

import '../core/tetris_game.dart';
import '../theme/palette.dart';

/// The game's own icon set. Each icon exists as a chunky vector drawing (toy
/// skin) and as 9×9 pixel art (pixel skin); the glass skin keeps Material
/// icons.
enum GameIconKind {
  palette,
  pause,
  play,
  musicOn,
  musicOff,
  sun,
  moon,
  info,
  sparkle,
  blocks,
  bolt,
  leaf,
  trophy,
  globe,
  chat,
  tap,
  home,
  replay,
  star,
}

final Map<IconData, GameIconKind> _byMaterial = {
  Icons.palette_rounded: GameIconKind.palette,
  Icons.pause_rounded: GameIconKind.pause,
  Icons.play_arrow_rounded: GameIconKind.play,
  Icons.music_note_rounded: GameIconKind.musicOn,
  Icons.music_off_rounded: GameIconKind.musicOff,
  Icons.light_mode_rounded: GameIconKind.sun,
  Icons.dark_mode_rounded: GameIconKind.moon,
  Icons.info_outline_rounded: GameIconKind.info,
  Icons.auto_awesome_rounded: GameIconKind.sparkle,
  Icons.extension_rounded: GameIconKind.blocks,
  Icons.bolt_rounded: GameIconKind.bolt,
  Icons.spa_rounded: GameIconKind.leaf,
  Icons.emoji_events_rounded: GameIconKind.trophy,
  Icons.language_rounded: GameIconKind.globe,
  Icons.translate_rounded: GameIconKind.chat,
  Icons.touch_app_rounded: GameIconKind.tap,
  Icons.home_rounded: GameIconKind.home,
  Icons.replay_rounded: GameIconKind.replay,
  Icons.star_rounded: GameIconKind.star,
};

/// Drop-in replacement for [Icon] that follows the skin.
class GameIcon extends StatelessWidget {
  const GameIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final theme = IconTheme.of(context);
    final size = this.size ?? theme.size ?? 24;
    final color = this.color ?? theme.color ?? p.icon;
    final kind = _byMaterial[icon];
    if (!p.flat || kind == null) return Icon(icon, size: size, color: color);
    return CustomPaint(size: Size.square(size), painter: _GameIconPainter(kind, color, p.skin));
  }
}

class _GameIconPainter extends CustomPainter {
  _GameIconPainter(this.kind, this.color, this.skin);

  final GameIconKind kind;
  final Color color;
  final GameSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    if (skin == GameSkin.pixel) {
      paintPixelArt(canvas, size.width, _pixelIcons[kind]!, color);
      if (kind == GameIconKind.musicOff) paintPixelArt(canvas, size.width, _slash, color);
    } else {
      paintToyIcon(canvas, size.width, kind, color);
    }
  }

  @override
  bool shouldRepaint(covariant _GameIconPainter old) => old.kind != kind || old.color != color || old.skin != skin;
}

// ---------------------------------------------------------------- pixel art

/// Draws rows of '#' cells scaled to a [size] square (art is 9×9).
void paintPixelArt(Canvas canvas, double size, List<String> rows, Color color) {
  final n = rows.length;
  final u = size / n;
  final paint = Paint()
    ..color = color
    ..isAntiAlias = false;
  for (var y = 0; y < n; y++) {
    final row = rows[y];
    for (var x = 0; x < row.length; x++) {
      if (row.codeUnitAt(x) == 35) canvas.drawRect(Rect.fromLTWH(x * u, y * u, u + 0.4, u + 0.4), paint);
    }
  }
}

const _slash = ['#........', '.#.......', '..#......', '...#.....', '....#....', '.....#...', '......#..', '.......#.', '........#'];

const Map<GameIconKind, List<String>> _pixelIcons = {
  GameIconKind.palette: [
    '..#####..',
    '.#######.',
    '##.###.##',
    '#########',
    '##.######',
    '#######..',
    '.####....',
    '..###..#.',
    '.......#.',
  ],
  GameIconKind.pause: ['.........', '.##...##.', '.##...##.', '.##...##.', '.##...##.', '.##...##.', '.##...##.', '.##...##.', '.........'],
  GameIconKind.play: ['.........', '.##......', '.####....', '.######..', '.#######.', '.######..', '.####....', '.##......', '.........'],
  GameIconKind.musicOn: [
    '...######',
    '...######',
    '...#....#',
    '...#....#',
    '...#....#',
    '.###..###',
    '####.####',
    '####.####',
    '.##...##.',
  ],
  GameIconKind.musicOff: [
    '...######',
    '...######',
    '...#....#',
    '...#....#',
    '...#....#',
    '.###..###',
    '####.####',
    '####.####',
    '.##...##.',
  ],
  GameIconKind.sun: ['....#....', '.#.....#.', '...###...', '..#####..', '#.#####.#', '..#####..', '...###...', '.#.....#.', '....#....'],
  GameIconKind.moon: ['...####..', '..###....', '.###.....', '.###.....', '.###.....', '.####....', '..####..#', '...#####.', '....###..'],
  GameIconKind.info: ['.#######.', '##.....##', '#...#...#', '#.......#', '#..##...#', '#...#...#', '#..###..#', '##.....##', '.#######.'],
  GameIconKind.sparkle: [
    '....#....',
    '....#....',
    '...###...',
    '#########',
    '...###...',
    '....#..#.',
    '....#.###',
    '.......#.',
    '.........',
  ],
  GameIconKind.blocks: [
    '####.####',
    '####.####',
    '####.####',
    '####.####',
    '.........',
    '####.####',
    '####.#..#',
    '####.#..#',
    '####.####',
  ],
  GameIconKind.bolt: ['.....###.', '....###..', '...###...', '..######.', '.######..', '....###..', '...###...', '..##.....', '.#.......'],
  GameIconKind.leaf: ['.....####', '...######', '..####..#', '.####..##', '.###..###', '.##..####', '.#..####.', '..#####..', '#........'],
  GameIconKind.trophy: [
    '#########',
    '#.#####.#',
    '#.#####.#',
    '.#######.',
    '..#####..',
    '...###...',
    '....#....',
    '..#####..',
    '..#####..',
  ],
  GameIconKind.globe: ['..#####..', '.##.#.##.', '#..#.#..#', '#########', '#..#.#..#', '#########', '#..#.#..#', '.##.#.##.', '..#####..'],
  GameIconKind.chat: ['#########', '#.......#', '#.##.##.#', '#.......#', '#.#####.#', '#.......#', '#########', '.##......', '.#.......'],
  GameIconKind.tap: ['..##.....', '..##.....', '..######.', '..#######', '#########', '#########', '.########', '..######.', '...####..'],
  GameIconKind.home: ['....#....', '...###...', '..#####..', '.#######.', '#########', '.#######.', '.##..###.', '.##..###.', '.##..###.'],
  GameIconKind.replay: [
    '..####.#.',
    '.#....##.',
    '#....###.',
    '#........',
    '#.......#',
    '#.......#',
    '.#.....#.',
    '..#####..',
    '.........',
  ],
  GameIconKind.star: ['....#....', '...###...', '#########', '.#######.', '..#####..', '..#####..', '.###.###.', '.##...##.', '.#.....#.'],
};

/// Pixel art of the power glyphs.
const Map<PowerType, List<String>> pixelPowerIcons = {
  PowerType.bomb: ['.......#.', '......#.#', '.....#...', '..####...', '.######..', '.######..', '.######..', '.######..', '..####...'],
  PowerType.single: ['.........', '.........', '..#####..', '..#####..', '..#####..', '..#####..', '..#####..', '.........', '.........'],
  PowerType.drill: ['.#######.', '.#######.', '.#######.', '..#####..', '..#####..', '...###...', '...###...', '....#....', '....#....'],
  PowerType.gravity: ['.#.....#.', '.#.....#.', '.#.....#.', '###...###', '.#.....#.', '.........', '#########', '#########', '.........'],
  PowerType.slowMotion: [
    '#########',
    '.#.....#.',
    '..#...#..',
    '...#.#...',
    '....#....',
    '...#.#...',
    '..#.#.#..',
    '.#.###.#.',
    '#########',
  ],
  PowerType.ghostLine: [
    '....#....',
    '...###...',
    '....#....',
    '.........',
    '.........',
    '##.##.##.',
    '.........',
    '.........',
    '.........',
  ],
};

// ---------------------------------------------------------------- toy vectors

/// Chunky vector icons on a 24-unit grid: filled shapes and thick rounded
/// strokes so they sit next to the outlined toy blocks.
void paintToyIcon(Canvas canvas, double size, GameIconKind kind, Color color) {
  final k = size / 24;
  Offset o(double x, double y) => Offset(x * k, y * k);
  final fill = Paint()..color = color;
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8 * k
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  RRect rr(double l, double t, double r, double b, double rad) => RRect.fromLTRBR(l * k, t * k, r * k, b * k, Radius.circular(rad * k));
  Path poly(List<double> xy) {
    final path = Path()..moveTo(xy[0] * k, xy[1] * k);
    for (var i = 2; i < xy.length; i += 2) {
      path.lineTo(xy[i] * k, xy[i + 1] * k);
    }
    return path..close();
  }

  void star(Offset c, double r, double inner, int points) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = -pi / 2 + i * pi / points;
      final rad = (i.isEven ? r : inner) * k;
      final pt = c + Offset(cos(a) * rad, sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path..close(), fill);
    canvas.drawPath(path, stroke..strokeWidth = 1.4 * k);
    stroke.strokeWidth = 2.8 * k;
  }

  switch (kind) {
    case GameIconKind.palette:
      final board = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromLTRB(2.5 * k, 3 * k, 21.5 * k, 21 * k)),
        Path()..addOval(Rect.fromCircle(center: o(16.5, 16), radius: 3 * k)),
      );
      canvas.drawPath(board, fill);
      final hole = Paint()..color = Color.lerp(color, Colors.black, 0.55)!;
      for (final (x, y) in [(8.0, 8.5), (12.5, 7.0), (16.8, 9.2), (7.0, 13.5)]) {
        canvas.drawCircle(o(x, y), 1.7 * k, hole);
      }
    case GameIconKind.pause:
      canvas.drawRRect(rr(5.5, 4.5, 10, 19.5, 2), fill);
      canvas.drawRRect(rr(14, 4.5, 18.5, 19.5, 2), fill);
    case GameIconKind.play:
      final tri = poly([7.5, 5, 19, 12, 7.5, 19]);
      canvas.drawPath(tri, fill);
      canvas.drawPath(tri, stroke..strokeWidth = 3 * k);
    case GameIconKind.musicOn || GameIconKind.musicOff:
      canvas.drawOval(Rect.fromCenter(center: o(7.5, 17.5), width: 7 * k, height: 5.8 * k), fill);
      canvas.drawOval(Rect.fromCenter(center: o(16.5, 15.5), width: 7 * k, height: 5.8 * k), fill);
      canvas.drawLine(o(10.4, 17), o(10.4, 6.5), stroke);
      canvas.drawLine(o(19.4, 15), o(19.4, 4.5), stroke);
      canvas.drawPath(poly([9, 5.5, 20.8, 3, 20.8, 7, 9, 9.5]), fill);
      if (kind == GameIconKind.musicOff) {
        canvas.drawLine(o(3.5, 3.5), o(20.5, 20.5), stroke..strokeWidth = 3 * k);
      }
    case GameIconKind.sun:
      canvas.drawCircle(o(12, 12), 4.8 * k, fill);
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        canvas.drawLine(o(12 + cos(a) * 8, 12 + sin(a) * 8), o(12 + cos(a) * 10, 12 + sin(a) * 10), stroke);
      }
    case GameIconKind.moon:
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: o(11.5, 12.5), radius: 8.5 * k)),
        Path()..addOval(Rect.fromCircle(center: o(16, 8.5), radius: 7 * k)),
      );
      canvas.drawPath(moon, fill);
    case GameIconKind.info:
      canvas.drawCircle(o(12, 12), 9 * k, stroke..strokeWidth = 2.4 * k);
      canvas.drawCircle(o(12, 7.6), 1.7 * k, fill);
      canvas.drawLine(o(12, 11.2), o(12, 16.8), stroke..strokeWidth = 3 * k);
    case GameIconKind.sparkle:
      star(o(10, 13.5), 8.5, 2.6, 4);
      star(o(18.5, 5.5), 4, 1.3, 4);
    case GameIconKind.blocks:
      canvas.drawRRect(rr(3, 3, 11, 11, 2.2), fill);
      canvas.drawRRect(rr(13, 3, 21, 11, 2.2), fill);
      canvas.drawRRect(rr(3, 13, 11, 21, 2.2), fill);
      canvas.drawRRect(rr(14.2, 14.2, 19.8, 19.8, 1.6), stroke..strokeWidth = 2.4 * k);
    case GameIconKind.bolt:
      final bolt = poly([13.5, 2.5, 5, 13.5, 11, 13.5, 9.5, 21.5, 19, 9.5, 13, 9.5, 14.5, 2.5]);
      canvas.drawPath(bolt, fill);
      canvas.drawPath(bolt, stroke..strokeWidth = 1.6 * k);
    case GameIconKind.leaf:
      final leaf = Path()
        ..moveTo(4.5 * k, 19.5 * k)
        ..quadraticBezierTo(3 * k, 5 * k, 20 * k, 4 * k)
        ..quadraticBezierTo(20.5 * k, 19.5 * k, 4.5 * k, 19.5 * k)
        ..close();
      canvas.drawPath(leaf, fill);
      canvas.drawLine(
        o(3, 21),
        o(13, 11),
        Paint()
          ..color = Color.lerp(color, Colors.black, 0.45)!
          ..strokeWidth = 2 * k
          ..strokeCap = StrokeCap.round,
      );
    case GameIconKind.trophy:
      canvas.drawPath(
        Path()
          ..moveTo(6 * k, 3.5 * k)
          ..lineTo(18 * k, 3.5 * k)
          ..lineTo(18 * k, 9 * k)
          ..quadraticBezierTo(18 * k, 15 * k, 12 * k, 15 * k)
          ..quadraticBezierTo(6 * k, 15 * k, 6 * k, 9 * k)
          ..close(),
        fill,
      );
      canvas.drawArc(Rect.fromLTRB(2.5 * k, 5 * k, 8.5 * k, 11.5 * k), pi / 2, pi, false, stroke..strokeWidth = 2.2 * k);
      canvas.drawArc(Rect.fromLTRB(15.5 * k, 5 * k, 21.5 * k, 11.5 * k), -pi / 2, pi, false, stroke);
      canvas.drawRRect(rr(10.5, 14, 13.5, 18, 0.5), fill);
      canvas.drawRRect(rr(7, 18, 17, 21, 1.4), fill);
    case GameIconKind.globe:
      final s = stroke..strokeWidth = 2.2 * k;
      canvas.drawCircle(o(12, 12), 8.8 * k, s);
      canvas.drawOval(Rect.fromCenter(center: o(12, 12), width: 8 * k, height: 17.6 * k), s);
      canvas.drawLine(o(3.5, 12), o(20.5, 12), s);
    case GameIconKind.chat:
      final bubble = Path()
        ..addRRect(rr(3, 4, 21, 16.5, 4))
        ..moveTo(7 * k, 15 * k)
        ..lineTo(6 * k, 21 * k)
        ..lineTo(12 * k, 16 * k)
        ..close();
      canvas.drawPath(bubble, fill);
    case GameIconKind.tap:
      canvas.drawCircle(o(12, 12), 3.6 * k, fill);
      canvas.drawCircle(o(12, 12), 8 * k, stroke..strokeWidth = 2.2 * k);
    case GameIconKind.home:
      canvas.drawPath(
        poly([12, 3, 21, 11, 18.5, 11, 18.5, 20.5, 14.5, 20.5, 14.5, 15, 9.5, 15, 9.5, 20.5, 5.5, 20.5, 5.5, 11, 3, 11]),
        fill,
      );
      canvas.drawPath(
        poly([12, 3, 21, 11, 18.5, 11, 18.5, 20.5, 14.5, 20.5, 14.5, 15, 9.5, 15, 9.5, 20.5, 5.5, 20.5, 5.5, 11, 3, 11]),
        stroke..strokeWidth = 1.4 * k,
      );
    case GameIconKind.replay:
      canvas.drawArc(Rect.fromCircle(center: o(12, 13), radius: 7.5 * k), -pi * 0.35, pi * 1.65, false, stroke..strokeWidth = 3 * k);
      canvas.drawPath(poly([12.5, 1.8, 18.5, 5.6, 12.5, 9.4]), fill);
    case GameIconKind.star:
      star(o(12, 12.8), 9.5, 4.2, 5);
  }
}
