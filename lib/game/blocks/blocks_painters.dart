import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/blocks/block_puzzle.dart';
import '../../core/tetromino.dart';
import '../../theme/palette.dart';
import '../render/block_sprites.dart';
import '../render/board_painter.dart';
import 'blocks_controller.dart';
import 'blocks_fx.dart';

const int _n = BlockPuzzleGame.size;

/// Layout of the board canvas. The canvas is larger than the frame so
/// particles can fly over the surrounding UI.
class BlocksGeometry {
  BlocksGeometry(this.cell) : pad = cell * 0.3, margin = cell * 1.4;

  final double cell;
  final double pad;
  final double margin;

  double get grid => _n * cell;
  double get frame => grid + 2 * pad;
  Offset get gridOrigin => Offset(margin + pad, margin + pad);
  Size get canvas => Size(frame + 2 * margin, frame + 2 * margin);

  /// Cell size whose frame fits a square of [side].
  static double fit(double side) => side / (_n + 0.6);
}

BlockSprite _sprite(BlockSprites sprites, BlockCell cell) => sprites.block(cell.gem ? PieceType.gem : cell.color);

typedef BlockSprite = ui.Image;

class BlocksBoardPainter extends CustomPainter {
  BlocksBoardPainter({required this.controller, required this.sprites, required this.palette, required this.geometry})
    : super(repaint: controller.frame);

  final BlocksController controller;
  final BlockSprites sprites;
  final GamePalette palette;
  final BlocksGeometry geometry;

  BlockPuzzleGame get game => controller.game;
  BlocksFx get fx => controller.fx;

  @override
  void paint(Canvas canvas, Size size) {
    final c = geometry.cell;
    final shake = fx.shake * c;
    canvas.save();
    canvas.translate(shake.dx, shake.dy);
    final chrome = _chrome();
    canvas.drawImageRect(
      chrome,
      Rect.fromLTWH(0, 0, chrome.width.toDouble(), chrome.height.toDouble()),
      Offset.zero & geometry.canvas,
      Paint()..filterQuality = FilterQuality.low,
    );
    canvas.translate(geometry.gridOrigin.dx, geometry.gridOrigin.dy);
    final grid = Rect.fromLTWH(0, 0, geometry.grid, geometry.grid);

    _paintPulse(canvas, grid);
    _paintCells(canvas);
    _paintPreview(canvas, grid);
    _paintPlacePulses(canvas);
    _paintVanishing(canvas);
    _paintBeams(canvas, grid);
    _paintFlash(canvas, grid);
    paintShockwaves(canvas, fx.shockwaves, c);
    paintParticles(canvas, fx.particles, sprites, c);
    _paintOverShade(canvas, grid);
    canvas.restore();
  }

  static final Map<String, ui.Image> _chromeCache = {};

  ui.Image _chrome() {
    final dpr = min(sprites.dpr, 2.0);
    final key = '${geometry.cell}/${palette.skin.name}/${palette.isDark}/$dpr';
    final hit = _chromeCache[key];
    if (hit != null) return hit;
    if (_chromeCache.length >= 4) _chromeCache.remove(_chromeCache.keys.first)?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    _paintFrame(canvas);
    final picture = recorder.endRecording();
    final image = picture.toImageSync((geometry.canvas.width * dpr).ceil(), (geometry.canvas.height * dpr).ceil());
    picture.dispose();
    return _chromeCache[key] = image;
  }

  void _paintFrame(Canvas canvas) {
    final c = geometry.cell;
    final o = geometry.gridOrigin;
    final grid = Rect.fromLTWH(o.dx, o.dy, geometry.grid, geometry.grid);
    if (palette.skin == GameSkin.toy) {
      _paintToyFrame(canvas, grid);
      return;
    }
    if (palette.skin == GameSkin.pixel) {
      _paintPixelFrame(canvas, grid);
      return;
    }
    final frame = RRect.fromRectAndRadius(grid.inflate(geometry.pad), Radius.circular(c * 0.6));
    canvas.drawRRect(
      frame.shift(Offset(0, c * 0.4)),
      Paint()
        ..color = palette.frameShadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, c * 0.8),
    );
    canvas.drawRRect(frame, Paint()..color = palette.frameFill);
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = palette.frameBorder,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(grid, Radius.circular(c * 0.35)),
      Paint()..shader = ui.Gradient.linear(grid.topCenter, grid.bottomCenter, [palette.wellTop, palette.wellBottom]),
    );
    // Empty slots: soft rounded squares, like sockets for the blocks.
    final slot = Paint()..color = palette.isDark ? const Color(0x0DFFFFFF) : const Color(0x0F1E2850);
    final inset = c * 0.08;
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(grid.left + x * c + inset, grid.top + y * c + inset, c - 2 * inset, c - 2 * inset),
            Radius.circular(c * 0.18),
          ),
          slot,
        );
      }
    }
  }

  /// Toy box: ink outline, hard shadow and sunken sockets.
  void _paintToyFrame(Canvas canvas, Rect grid) {
    final c = geometry.cell;
    final outline = max(2.0, c * 0.07);
    final frame = RRect.fromRectAndRadius(grid.inflate(geometry.pad), Radius.circular(c * 0.45));
    canvas.drawRRect(frame.shift(Offset(0, c * 0.14)), Paint()..color = palette.ink);
    canvas.drawRRect(frame, Paint()..color = palette.frameFill);
    canvas.drawRRect(
      frame.deflate(outline / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline
        ..color = palette.ink,
    );
    final well = RRect.fromRectAndRadius(grid, Radius.circular(c * 0.3));
    canvas.drawRRect(well, Paint()..color = palette.wellTop);
    final slot = Paint()..color = palette.isDark ? Colors.white.withValues(alpha: 0.05) : palette.grid.withValues(alpha: 0.45);
    final inset = c * 0.1;
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(grid.left + x * c + inset, grid.top + y * c + inset, c - 2 * inset, c - 2 * inset),
            Radius.circular(c * 0.2),
          ),
          slot,
        );
      }
    }
    canvas.drawRRect(
      well.deflate(outline * 0.35),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline * 0.7
        ..color = palette.ink,
    );
  }

  /// Arcade cabinet: square bevelled frame and a checkerboard grid.
  void _paintPixelFrame(Canvas canvas, Rect grid) {
    final c = geometry.cell;
    final u = c / 8;
    final frame = grid.inflate(geometry.pad);
    canvas.drawRect(frame.shift(Offset(u * 1.5, u * 1.5)), Paint()..color = palette.ink);
    canvas.drawRect(frame, Paint()..color = palette.frameBorder);
    canvas.drawRect(frame.deflate(u), Paint()..color = palette.frameFill);
    canvas.drawRect(grid.inflate(u * 0.75), Paint()..color = palette.ink);
    canvas.drawRect(grid, Paint()..color = palette.wellTop);
    final check = Paint()..color = palette.grid;
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        if ((x + y).isOdd) canvas.drawRect(Rect.fromLTWH(grid.left + x * c, grid.top + y * c, c, c), check);
      }
    }
  }

  void _paintPulse(Canvas canvas, Rect grid) {
    if (fx.pulse <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(grid, Radius.circular(geometry.cell * 0.35)),
      Paint()
        ..shader = ui.Gradient.radial(grid.center, grid.width * 0.75, [
          fx.pulseColor.withValues(alpha: 0.3 * fx.pulse),
          fx.pulseColor.withValues(alpha: 0),
        ]),
    );
  }

  void _paintCells(Canvas canvas) {
    final c = geometry.cell;
    final grayT = fx.overAge < 0 ? -1.0 : fx.overAge / 0.9;
    for (var y = 0; y < _n; y++) {
      final gray = grayT >= 0 && (_n - 1 - y) / _n < grayT;
      for (var x = 0; x < _n; x++) {
        final cell = game.board[y][x];
        if (cell == null) continue;
        sprites.draw(canvas, gray && !cell.gem ? sprites.gray : _sprite(sprites, cell), x * c, y * c);
      }
    }
    // Gems twinkle so they read as the goal.
    final shine = 0.5 + 0.5 * sin(fx.time * 3);
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        final cell = game.board[y][x];
        if (cell == null || !cell.gem) continue;
        final phase = sin(fx.time * 2.2 + x * 0.9 + y * 1.3);
        if (phase > 0.6) sprites.draw(canvas, sprites.white, x * c, y * c, opacity: (phase - 0.6) * 0.5 * shine);
      }
    }
  }

  void _paintPreview(Canvas canvas, Rect grid) {
    final shape = controller.dragShape;
    final target = controller.target;
    if (shape == null || target == null) return;
    final c = geometry.cell;
    final color = blockColors[shape.color]!;
    final pulse = 0.75 + 0.25 * sin(fx.time * 8);

    // Lines that would blast light up in the piece's colour.
    final rows = controller.targetRows, columns = controller.targetColumns;
    if (rows.isNotEmpty || columns.isNotEmpty) {
      final band = Paint()
        ..blendMode = palette.isDark ? BlendMode.plus : BlendMode.srcOver
        ..color = color.withValues(alpha: 0.22 * pulse);
      for (final r in rows) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, r * c, grid.width, c), Radius.circular(c * 0.2)), band);
      }
      for (final col in columns) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col * c, 0, c, grid.height), Radius.circular(c * 0.2)), band);
      }
      final recolor = sprites.block(shape.color);
      final seen = <Cell>{};
      void tint(int x, int y) {
        if (!seen.add(Cell(x, y))) return;
        final cell = game.board[y][x];
        if (cell == null) return;
        sprites.draw(canvas, recolor, x * c, y * c, opacity: cell.gem ? 0.35 : 0.75);
        if (cell.gem) sprites.draw(canvas, sprites.white, x * c, y * c, opacity: 0.35 * pulse);
      }

      for (final r in rows) {
        for (var x = 0; x < _n; x++) {
          tint(x, r);
        }
      }
      for (final col in columns) {
        for (var y = 0; y < _n; y++) {
          tint(col, y);
        }
      }
    }

    // Where the piece will land.
    final ghost = sprites.block(shape.color);
    for (final cell in shape.cells) {
      sprites.draw(canvas, ghost, (target.$1 + cell.x) * c, (target.$2 + cell.y) * c, opacity: 0.45 + 0.1 * pulse);
    }
  }

  void _paintPlacePulses(Canvas canvas) {
    final c = geometry.cell;
    for (final p in fx.placePulses) {
      final scale = BlocksFx.popScale(p.t);
      for (final cell in p.cells) {
        if (game.board[cell.y][cell.x] == null) continue;
        sprites.draw(canvas, sprites.block(p.color), cell.x * c, cell.y * c, scale: scale);
        sprites.draw(canvas, sprites.white, cell.x * c, cell.y * c, scale: scale, opacity: (1 - p.t) * 0.55);
      }
    }
  }

  void _paintVanishing(Canvas canvas) {
    final c = geometry.cell;
    for (final v in fx.vanishing) {
      final x = v.cell.x * c, y = v.cell.y * c;
      final image = _sprite(sprites, v.block);
      if (v.delay > 0) {
        // Waiting for the blast wave: glow white as it approaches.
        sprites.draw(canvas, image, x, y);
        sprites.draw(canvas, sprites.white, x, y, opacity: (0.35 - v.delay * 2).clamp(0.0, 0.35));
        continue;
      }
      final t = v.t;
      final scale = 1 + 0.25 * Curves.easeOut.transform(t);
      sprites.draw(canvas, image, x, y, scale: scale, opacity: 1 - t);
      sprites.draw(canvas, sprites.white, x, y, scale: scale, opacity: (1 - t) * 0.9);
    }
  }

  void _paintBeams(Canvas canvas, Rect grid) {
    final c = geometry.cell;
    for (final b in fx.beams) {
      final fade = 1 - Curves.easeIn.transform(b.t);
      final mid = (b.index + 0.5) * c;
      final rect = b.column
          ? Rect.fromCenter(center: Offset(mid, grid.center.dy), width: c * 1.8, height: grid.height + c)
          : Rect.fromCenter(center: Offset(grid.center.dx, mid), width: grid.width + c, height: c * 1.8);
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = palette.isDark ? BlendMode.plus : BlendMode.srcOver
          ..shader = ui.Gradient.linear(
            b.column ? rect.centerLeft : rect.topCenter,
            b.column ? rect.centerRight : rect.bottomCenter,
            [const Color(0x007DD3FC), const Color(0xFF7DD3FC).withValues(alpha: 0.35 * fade), const Color(0x007DD3FC)],
            const [0, 0.5, 1],
          ),
      );
      final grow = Curves.easeOut.transform(min(1, b.t * 2.5));
      final line = b.column
          ? Rect.fromCenter(center: Offset(mid, grid.center.dy), width: max(2, c * 0.08), height: grid.height * grow)
          : Rect.fromCenter(center: Offset(grid.center.dx, mid), width: grid.width * grow, height: max(2, c * 0.08));
      canvas.drawRect(line, Paint()..color = Colors.white.withValues(alpha: 0.9 * fade));
    }
  }

  void _paintFlash(Canvas canvas, Rect grid) {
    if (fx.boardFlash <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(grid.inflate(geometry.pad), Radius.circular(geometry.cell * 0.6)),
      Paint()
        ..blendMode = palette.isDark ? BlendMode.plus : BlendMode.srcOver
        ..color = Colors.white.withValues(alpha: 0.4 * fx.boardFlash * fx.boardFlash),
    );
  }

  void _paintOverShade(Canvas canvas, Rect grid) {
    if (fx.overAge < 0 || game.status == BlockStatus.won) return;
    final k = (fx.overAge / 1.2).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(grid, Radius.circular(geometry.cell * 0.35)),
      Paint()..color = Colors.black.withValues(alpha: (palette.isDark ? 0.3 : 0.1) * k),
    );
  }

  @override
  bool shouldRepaint(covariant BlocksBoardPainter old) =>
      old.sprites != sprites || old.palette != palette || old.geometry.cell != geometry.cell || old.controller != controller;
}

/// A tray piece, centred in its slot.
class TrayPiecePainter extends CustomPainter {
  TrayPiecePainter({required this.shape, required this.sprites, this.dimmed = false, this.scale = 1});

  final BlockShape? shape;
  final BlockSprites sprites;
  final bool dimmed;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = this.shape;
    if (shape == null) return;
    final c = sprites.cell;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    final image = dimmed ? sprites.gray : sprites.block(shape.color);
    for (final cell in shape.cells) {
      sprites.draw(canvas, image, (cell.x - shape.width / 2) * c, (cell.y - shape.height / 2) * c, opacity: dimmed ? 0.55 : 1);
    }
  }

  @override
  bool shouldRepaint(covariant TrayPiecePainter old) =>
      old.shape != shape || old.sprites != sprites || old.dimmed != dimmed || old.scale != scale;
}

/// The piece under the finger or mouse, drawn above everything.
class DragPiecePainter extends CustomPainter {
  DragPiecePainter({required this.controller, required this.sprites, required this.globalOrigin}) : super(repaint: controller.frame);

  final BlocksController controller;
  final BlockSprites sprites;

  /// Global position of this painter's canvas origin.
  final Offset Function() globalOrigin;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = controller.dragShape;
    if (shape == null) return;
    final c = sprites.cell;
    final topLeft = controller.dragTopLeft - globalOrigin();
    final aura = sprites.aura(shape.color);
    final image = sprites.block(shape.color);
    final lifted = controller.target == null ? 0.85 : 1.0;
    for (final cell in shape.cells) {
      sprites.draw(canvas, aura, topLeft.dx + cell.x * c, topLeft.dy + cell.y * c, scale: 1.2, opacity: 0.45);
    }
    for (final cell in shape.cells) {
      sprites.draw(canvas, image, topLeft.dx + cell.x * c, topLeft.dy + cell.y * c, scale: 1.04, opacity: lifted);
    }
  }

  @override
  bool shouldRepaint(covariant DragPiecePainter old) => old.sprites != sprites || old.controller != controller;
}
