import 'dart:math';

import 'package:flutter/material.dart';

import '../core/tetris_game.dart';
import '../theme/palette.dart';

/// The game's own icon set. Each icon exists as a chunky vector drawing (toy
/// skin) and as 9×9 pixel art (pixel skin); the glass skin keeps Material
/// icons.
enum GameIconKind {
  palette,
  back,
  forward,
  northEast,
  grid,
  layers,
  volume,
  shake,
  timer,
  gamepad,
  speed,
  phone,
  person,
  lock,
  fire,
  fullscreen,
  quote,
  heart,
  dice,
  blur,
  infinity,

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
  Icons.arrow_back_rounded: GameIconKind.back,
  Icons.arrow_forward_rounded: GameIconKind.forward,
  Icons.north_east_rounded: GameIconKind.northEast,
  Icons.grid_view_rounded: GameIconKind.grid,
  Icons.layers_rounded: GameIconKind.layers,
  Icons.volume_up_rounded: GameIconKind.volume,
  Icons.vibration_rounded: GameIconKind.shake,
  Icons.timer_rounded: GameIconKind.timer,
  Icons.sports_esports_rounded: GameIconKind.gamepad,
  Icons.gamepad_rounded: GameIconKind.gamepad,
  Icons.speed_rounded: GameIconKind.speed,
  Icons.smartphone_rounded: GameIconKind.phone,
  Icons.person_rounded: GameIconKind.person,
  Icons.lock_rounded: GameIconKind.lock,
  Icons.local_fire_department_rounded: GameIconKind.fire,
  Icons.fullscreen_rounded: GameIconKind.fullscreen,
  Icons.format_quote_rounded: GameIconKind.quote,
  Icons.favorite_rounded: GameIconKind.heart,
  Icons.casino_rounded: GameIconKind.dice,
  Icons.blur_on_rounded: GameIconKind.blur,
  Icons.all_inclusive_rounded: GameIconKind.infinity,
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
  GameIconKind.back: ['.........', '....#....', '...##....', '..#######', '.########', '..#######', '...##....', '....#....', '.........'],
  GameIconKind.forward: [
    '.........',
    '....#....',
    '....##...',
    '#######..',
    '########.',
    '#######..',
    '....##...',
    '....#....',
    '.........',
  ],
  GameIconKind.northEast: [
    '...######',
    '......###',
    '.....####',
    '....###.#',
    '...###..#',
    '..###....',
    '.###.....',
    '###......',
    '##.......',
  ],
  GameIconKind.grid: ['##.##.##.', '##.##.##.', '.........', '##.##.##.', '##.##.##.', '.........', '##.##.##.', '##.##.##.', '.........'],
  GameIconKind.layers: [
    '..#####..',
    '..#####..',
    '.........',
    '.#######.',
    '.#######.',
    '.........',
    '#########',
    '#########',
    '.........',
  ],
  GameIconKind.volume: [
    '....#....',
    '...##..#.',
    '#####...#',
    '#####.#.#',
    '#####.#.#',
    '#####...#',
    '...##..#.',
    '....#....',
    '.........',
  ],
  GameIconKind.shake: ['#..###..#', '#.#...#.#', '..#...#..', '#.#...#.#', '#.#...#.#', '..#...#..', '#.#...#.#', '#..###..#', '.........'],
  GameIconKind.timer: ['...###...', '....#....', '..#####..', '.#..#..#.', '#...#...#', '#...##..#', '#.......#', '.#.....#.', '..#####..'],
  GameIconKind.gamepad: [
    '.........',
    '..#####..',
    '.#######.',
    '##.###.##',
    '#...#.#.#',
    '##.###.##',
    '#########',
    '##.....##',
    '.........',
  ],
  GameIconKind.speed: ['.........', '..#####..', '.#.....#.', '#.....#.#', '#....#..#', '#...#...#', '#.......#', '.........', '.........'],
  GameIconKind.phone: ['..#####..', '..#...#..', '..#...#..', '..#...#..', '..#...#..', '..#...#..', '..#####..', '..##.##..', '..#####..'],
  GameIconKind.person: [
    '...###...',
    '..#####..',
    '..#####..',
    '...###...',
    '.........',
    '.#######.',
    '#########',
    '#########',
    '#########',
  ],
  GameIconKind.lock: ['...###...', '..#...#..', '..#...#..', '.#######.', '.#######.', '.###.###.', '.###.###.', '.#######.', '.........'],
  GameIconKind.fire: ['....#....', '...##....', '...###.#.', '..######.', '.###.###.', '.##...##.', '.##...##.', '..##.##..', '...###...'],
  GameIconKind.fullscreen: [
    '###...###',
    '#.......#',
    '#.......#',
    '.........',
    '.........',
    '.........',
    '#.......#',
    '#.......#',
    '###...###',
  ],
  GameIconKind.quote: ['.........', '.##...##.', '#..#.#..#', '#..#.#..#', '.###..###', '...#....#', '..#....#.', '.#....#..', '.........'],
  GameIconKind.heart: ['.........', '.##...##.', '####.####', '#########', '#########', '.#######.', '..#####..', '...###...', '....#....'],
  GameIconKind.dice: ['#########', '#.......#', '#.#...#.#', '#.......#', '#...#...#', '#.......#', '#.#...#.#', '#.......#', '#########'],
  GameIconKind.blur: ['....#....', '..#...#..', '.........', '#..###..#', '...###...', '#..###..#', '.........', '..#...#..', '....#....'],
  GameIconKind.infinity: [
    '.........',
    '.........',
    '.##...##.',
    '#..#.#..#',
    '#...#...#',
    '#..#.#..#',
    '.##...##.',
    '.........',
    '.........',
  ],
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
    case GameIconKind.back || GameIconKind.forward:
      canvas.save();
      if (kind == GameIconKind.forward) {
        canvas.translate(size, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawLine(o(5.5, 12), o(19, 12), stroke..strokeWidth = 3 * k);
      canvas.drawPath(
        Path()
          ..moveTo(11 * k, 5.5 * k)
          ..lineTo(4.5 * k, 12 * k)
          ..lineTo(11 * k, 18.5 * k),
        stroke,
      );
      canvas.restore();
    case GameIconKind.northEast:
      canvas.drawLine(o(6, 18), o(17.5, 6.5), stroke..strokeWidth = 3 * k);
      canvas.drawPath(
        Path()
          ..moveTo(8.5 * k, 6 * k)
          ..lineTo(18 * k, 6 * k)
          ..lineTo(18 * k, 15.5 * k),
        stroke,
      );
    case GameIconKind.grid:
      for (final (x, y) in [(3.0, 3.0), (13.0, 3.0), (3.0, 13.0), (13.0, 13.0)]) {
        canvas.drawRRect(rr(x, y, x + 8, y + 8, 2.2), fill);
      }
    case GameIconKind.layers:
      canvas.drawPath(poly([12, 3, 21, 8, 12, 13, 3, 8]), fill);
      canvas.drawPath(poly([12, 3, 21, 8, 12, 13, 3, 8]), stroke..strokeWidth = 1.6 * k);
      stroke.strokeWidth = 2.6 * k;
      canvas.drawPath(
        Path()
          ..moveTo(3.5 * k, 12.5 * k)
          ..lineTo(12 * k, 17 * k)
          ..lineTo(20.5 * k, 12.5 * k),
        stroke,
      );
      canvas.drawPath(
        Path()
          ..moveTo(3.5 * k, 16.5 * k)
          ..lineTo(12 * k, 21 * k)
          ..lineTo(20.5 * k, 16.5 * k),
        stroke,
      );
    case GameIconKind.volume:
      canvas.drawPath(poly([3, 9, 7.5, 9, 12.5, 4.5, 12.5, 19.5, 7.5, 15, 3, 15]), fill);
      stroke.strokeWidth = 2.4 * k;
      canvas.drawArc(Rect.fromCircle(center: o(12.5, 12), radius: 4.5 * k), -0.9, 1.8, false, stroke);
      canvas.drawArc(Rect.fromCircle(center: o(12.5, 12), radius: 8.5 * k), -0.9, 1.8, false, stroke);
    case GameIconKind.shake:
      canvas.drawRRect(rr(7.5, 3, 16.5, 21, 2.4), stroke..strokeWidth = 2.4 * k);
      for (final x in [3.5, 20.5]) {
        canvas.drawLine(o(x, 8), o(x, 16), stroke);
      }
    case GameIconKind.timer:
      canvas.drawCircle(o(12, 13.5), 8 * k, stroke..strokeWidth = 2.4 * k);
      canvas.drawLine(o(12, 13.5), o(12, 9), stroke..strokeWidth = 2.6 * k);
      canvas.drawLine(o(9.5, 2.8), o(14.5, 2.8), stroke);
    case GameIconKind.gamepad:
      final pad = Path()
        ..moveTo(6 * k, 7 * k)
        ..lineTo(18 * k, 7 * k)
        ..quadraticBezierTo(22 * k, 7 * k, 22.5 * k, 13 * k)
        ..quadraticBezierTo(23 * k, 19 * k, 19 * k, 18.5 * k)
        ..lineTo(5 * k, 18.5 * k)
        ..quadraticBezierTo(1 * k, 19 * k, 1.5 * k, 13 * k)
        ..quadraticBezierTo(2 * k, 7 * k, 6 * k, 7 * k)
        ..close();
      canvas.drawPath(pad, fill);
      final hole = Paint()..color = Color.lerp(color, Colors.black, 0.55)!;
      canvas.drawRect(Rect.fromLTRB(5 * k, 11.8 * k, 10 * k, 13.8 * k), hole);
      canvas.drawRect(Rect.fromLTRB(6.5 * k, 10.3 * k, 8.5 * k, 15.3 * k), hole);
      canvas.drawCircle(o(16, 11.5), 1.3 * k, hole);
      canvas.drawCircle(o(18.6, 14), 1.3 * k, hole);
    case GameIconKind.speed:
      canvas.drawArc(Rect.fromCircle(center: o(12, 14), radius: 8.5 * k), pi * 0.85, pi * 1.3, false, stroke..strokeWidth = 2.6 * k);
      canvas.drawLine(o(12, 14), o(16.5, 8.5), stroke..strokeWidth = 2.8 * k);
      canvas.drawCircle(o(12, 14), 2 * k, fill);
    case GameIconKind.phone:
      canvas.drawRRect(rr(6.5, 2.5, 17.5, 21.5, 2.8), stroke..strokeWidth = 2.4 * k);
      canvas.drawCircle(o(12, 18), 1.3 * k, fill);
    case GameIconKind.person:
      canvas.drawCircle(o(12, 7.5), 4.3 * k, fill);
      canvas.drawPath(
        Path()
          ..moveTo(3.5 * k, 21 * k)
          ..quadraticBezierTo(3.5 * k, 13.5 * k, 12 * k, 13.5 * k)
          ..quadraticBezierTo(20.5 * k, 13.5 * k, 20.5 * k, 21 * k)
          ..close(),
        fill,
      );
    case GameIconKind.lock:
      canvas.drawArc(Rect.fromLTRB(7.5 * k, 3 * k, 16.5 * k, 13 * k), pi, pi, false, stroke..strokeWidth = 2.6 * k);
      canvas.drawLine(o(7.5, 8), o(7.5, 11), stroke);
      canvas.drawLine(o(16.5, 8), o(16.5, 11), stroke);
      canvas.drawRRect(rr(4.5, 10.5, 19.5, 21, 2.6), fill);
      canvas.drawCircle(o(12, 15.2), 1.7 * k, Paint()..color = Color.lerp(color, Colors.black, 0.55)!);
    case GameIconKind.fire:
      final flame = Path()
        ..moveTo(12 * k, 2 * k)
        ..quadraticBezierTo(14 * k, 7 * k, 17.5 * k, 9.5 * k)
        ..quadraticBezierTo(20.5 * k, 13 * k, 19 * k, 17 * k)
        ..quadraticBezierTo(17 * k, 22 * k, 12 * k, 22 * k)
        ..quadraticBezierTo(5 * k, 22 * k, 5 * k, 15.5 * k)
        ..quadraticBezierTo(5 * k, 11 * k, 8.5 * k, 8.5 * k)
        ..quadraticBezierTo(8.5 * k, 11.5 * k, 10.5 * k, 12 * k)
        ..quadraticBezierTo(9.5 * k, 6 * k, 12 * k, 2 * k)
        ..close();
      canvas.drawPath(flame, fill);
    case GameIconKind.fullscreen:
      stroke.strokeWidth = 2.8 * k;
      for (final (x, y, dx, dy) in [(4.0, 4.0, 1.0, 1.0), (20.0, 4.0, -1.0, 1.0), (4.0, 20.0, 1.0, -1.0), (20.0, 20.0, -1.0, -1.0)]) {
        canvas.drawPath(
          Path()
            ..moveTo(x * k, (y + 5 * dy) * k)
            ..lineTo(x * k, y * k)
            ..lineTo((x + 5 * dx) * k, y * k),
          stroke,
        );
      }
    case GameIconKind.quote:
      for (final x in [3.5, 13.0]) {
        canvas.drawCircle(o(x + 3.5, 10), 3.5 * k, fill);
        canvas.drawPath(poly([x + 3.5, 13.5, x + 7, 10, x + 3, 19.5]), fill);
      }
    case GameIconKind.heart:
      final heart = Path()
        ..moveTo(12 * k, 20.5 * k)
        ..cubicTo(2 * k, 14 * k, 1.5 * k, 8 * k, 5 * k, 5.2 * k)
        ..cubicTo(8 * k, 3 * k, 11 * k, 4.5 * k, 12 * k, 7 * k)
        ..cubicTo(13 * k, 4.5 * k, 16 * k, 3 * k, 19 * k, 5.2 * k)
        ..cubicTo(22.5 * k, 8 * k, 22 * k, 14 * k, 12 * k, 20.5 * k)
        ..close();
      canvas.drawPath(heart, fill);
    case GameIconKind.dice:
      canvas.drawRRect(rr(3, 3, 21, 21, 4.5), fill);
      final pip = Paint()..color = Color.lerp(color, Colors.black, 0.6)!;
      for (final (x, y) in [(7.5, 7.5), (16.5, 7.5), (12.0, 12.0), (7.5, 16.5), (16.5, 16.5)]) {
        canvas.drawCircle(o(x, y), 1.8 * k, pip);
      }
    case GameIconKind.blur:
      for (final (x, y, r) in [
        (12.0, 12.0, 3.2),
        (5.0, 12.0, 1.8),
        (19.0, 12.0, 1.8),
        (12.0, 5.0, 1.8),
        (12.0, 19.0, 1.8),
        (6.5, 6.5, 1.2),
        (17.5, 6.5, 1.2),
        (6.5, 17.5, 1.2),
        (17.5, 17.5, 1.2),
      ]) {
        canvas.drawCircle(o(x, y), r * k, fill);
      }
    case GameIconKind.infinity:
      final loop = Path()
        ..moveTo(12 * k, 12 * k)
        ..cubicTo(15 * k, 7 * k, 21.5 * k, 7 * k, 21.5 * k, 12 * k)
        ..cubicTo(21.5 * k, 17 * k, 15 * k, 17 * k, 12 * k, 12 * k)
        ..cubicTo(9 * k, 7 * k, 2.5 * k, 7 * k, 2.5 * k, 12 * k)
        ..cubicTo(2.5 * k, 17 * k, 9 * k, 17 * k, 12 * k, 12 * k);
      canvas.drawPath(loop, stroke..strokeWidth = 2.8 * k);
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
