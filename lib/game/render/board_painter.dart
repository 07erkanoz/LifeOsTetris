import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/tetris_game.dart';
import '../../theme/palette.dart';
import '../fx/effects.dart';
import 'block_sprites.dart';

/// Geometry of the board canvas: a margin around the frame lets particles
/// fly outside the well without being clipped.
class BoardGeometry {
  BoardGeometry(this.cell) : framePad = cell * 0.35, margin = cell * 1.3;

  final double cell;
  final double framePad;
  final double margin;

  double get wellWidth => TetrisGame.width * cell;
  double get wellHeight => TetrisGame.visibleHeight * cell;
  Offset get wellOrigin => Offset(margin + framePad, margin + framePad);
  Size get size => Size(wellWidth + 2 * (margin + framePad), wellHeight + 2 * (margin + framePad));

  /// Size of the visible frame around the well (the canvas is larger so
  /// particles can fly over the surrounding UI).
  Size get frameSize => Size(wellWidth + 2 * framePad, wellHeight + 2 * framePad);

  /// Cell size whose frame (10.7 × 20.7 cells) fits into [available].
  static double fit(Size available) => min(available.width / 10.7, available.height / 20.7);
}

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.game,
    required this.fx,
    required this.sprites,
    required this.palette,
    required this.geometry,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final TetrisGame game;
  final EffectsEngine fx;
  final BlockSprites sprites;
  final GamePalette palette;
  final BoardGeometry geometry;

  static const int _h = TetrisGame.hiddenRows;

  @override
  void paint(Canvas canvas, Size size) {
    final c = geometry.cell;
    final well = Rect.fromLTWH(0, 0, geometry.wellWidth, geometry.wellHeight);
    // Frame, shadow, well and grid never change during a game: they are
    // rasterised once and drawn as a single image every frame.
    final chrome = _chrome(well);
    canvas.drawImageRect(
      chrome,
      Rect.fromLTWH(0, 0, chrome.width.toDouble(), chrome.height.toDouble()),
      Offset.zero & geometry.size,
      Paint()..filterQuality = FilterQuality.low,
    );
    canvas.save();
    canvas.translate(geometry.wellOrigin.dx, geometry.wellOrigin.dy);

    _paintWellEffects(canvas, well);

    // Everything that sits on the grid is clipped at the top edge so the
    // hidden spawn rows stay invisible.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-c * 2, 0, well.right + c * 2, well.bottom + c * 2));
    _paintTrails(canvas);
    _paintAimHelpers(canvas);
    _paintGhost(canvas);
    _paintStack(canvas);
    _paintLockPulses(canvas);
    _paintActive(canvas);
    canvas.restore();

    _paintClearBeams(canvas, well);
    _paintDrillBeams(canvas, well);
    _paintGhostLine(canvas, well);
    _paintSlowMotion(canvas, well);
    _paintFlash(canvas, well);
    _paintShockwaves(canvas);
    _paintParticles(canvas);
    _paintGameOverShade(canvas, well);
    canvas.restore();
  }

  static final Map<String, ui.Image> _chromeCache = {};

  ui.Image _chrome(Rect well) {
    final dpr = min(sprites.dpr, 2.0);
    final key = '${geometry.cell}/${palette.isDark}/$dpr';
    final hit = _chromeCache[key];
    if (hit != null) return hit;
    if (_chromeCache.length >= 4) _chromeCache.remove(_chromeCache.keys.first);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(dpr)
      ..translate(geometry.wellOrigin.dx, geometry.wellOrigin.dy);
    _paintFrame(canvas, well);
    final picture = recorder.endRecording();
    final image = picture.toImageSync((geometry.size.width * dpr).ceil(), (geometry.size.height * dpr).ceil());
    picture.dispose();
    return _chromeCache[key] = image;
  }

  void _paintFrame(Canvas canvas, Rect well) {
    final c = geometry.cell;
    final frame = RRect.fromRectAndRadius(well.inflate(geometry.framePad), Radius.circular(c * 0.8));
    canvas.drawRRect(
      frame.shift(Offset(0, c * 0.6)),
      Paint()
        ..color = palette.frameShadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, c * 1.1),
    );
    canvas.drawRRect(frame, Paint()..color = palette.frameFill);
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = palette.frameBorder,
    );
    final wellRRect = RRect.fromRectAndRadius(well, Radius.circular(c * 0.45));
    canvas.drawRRect(
      wellRRect,
      Paint()..shader = ui.Gradient.linear(well.topCenter, well.bottomCenter, [palette.wellTop, palette.wellBottom]),
    );
    final grid = Paint()
      ..color = palette.grid
      ..strokeWidth = 1;
    for (var x = 1; x < TetrisGame.width; x++) {
      canvas.drawLine(Offset(x * c, 4), Offset(x * c, well.bottom - 4), grid);
    }
    for (var y = 1; y < TetrisGame.visibleHeight; y++) {
      canvas.drawLine(Offset(4, y * c), Offset(well.right - 4, y * c), grid);
    }
  }

  void _paintWellEffects(Canvas canvas, Rect well) {
    final c = geometry.cell;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(well, Radius.circular(c * 0.45)));
    if (fx.pulse > 0) {
      canvas.drawRect(
        well,
        Paint()
          ..shader = ui.Gradient.radial(well.center, well.height * 0.7, [
            fx.pulseColor.withValues(alpha: 0.28 * fx.pulse),
            fx.pulseColor.withValues(alpha: 0),
          ]),
      );
    }
    final wave = fx.levelWaveT;
    if (wave >= 0) {
      final y = well.bottom - (well.height + 6 * c) * Curves.easeInOut.transform(wave.clamp(0.0, 1.0)) + 3 * c;
      final band = Rect.fromLTRB(well.left, y - 3 * c, well.right, y + 3 * c);
      canvas.drawRect(
        band,
        Paint()
          ..shader = ui.Gradient.linear(
            band.topCenter,
            band.bottomCenter,
            [palette.accent2.withValues(alpha: 0), palette.accent1.withValues(alpha: 0.45), palette.accent2.withValues(alpha: 0)],
            const [0, 0.5, 1],
          ),
      );
      canvas.drawRect(Rect.fromLTRB(well.left, y - 1, well.right, y + 1), Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    final piece = game.active;
    final ghost = game.ghost;
    if (piece != null && ghost != null && game.status == GameStatus.playing) {
      final color = blockColors[piece.type]!;
      final xs = piece.cells.map((e) => e.x);
      final left = xs.reduce(min) * c, right = (xs.reduce(max) + 1) * c;
      final top = (piece.cells.map((e) => e.y).reduce(max) - _h + 1 + fx.offsetY) * c;
      final bottom = (ghost.cells.map((e) => e.y).reduce(min) - _h) * c;
      if (bottom > top) {
        final rect = Rect.fromLTRB(left + (fx.offsetX * c) + 3, max(0, top), right + (fx.offsetX * c) - 3, bottom);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
              color.withValues(alpha: 0),
              color.withValues(alpha: palette.isDark ? 0.14 : 0.1),
            ]),
        );
      }
    }
    canvas.restore();
  }

  void _paintTrails(Canvas canvas) {
    final c = geometry.cell;
    for (final t in fx.trails) {
      final fade = 1 - Curves.easeOut.transform(t.t);
      final rect = Rect.fromLTRB((t.column + 0.12) * c, t.top * c, (t.column + 0.88) * c, (t.bottom + 0.6) * c);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
            t.color.withValues(alpha: 0),
            t.color.withValues(alpha: 0.55 * fade),
          ]),
      );
      final core = Rect.fromLTRB((t.column + 0.44) * c, t.top * c, (t.column + 0.56) * c, (t.bottom + 0.5) * c);
      canvas.drawRect(
        core,
        Paint()
          ..shader = ui.Gradient.linear(core.topCenter, core.bottomCenter, [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.8 * fade),
          ]),
      );
    }
  }

  void _paintGhost(Canvas canvas) {
    final ghost = game.ghost;
    if (ghost == null || game.status != GameStatus.playing) return;
    final c = geometry.cell;
    final opacity = 0.75 + 0.25 * sin(fx.time * 4);
    final image = sprites.ghost(ghost.type);
    for (final cell in ghost.cells) {
      if (cell.y < _h) continue;
      sprites.draw(canvas, image, (cell.x + fx.offsetX) * c, (cell.y - _h) * c, opacity: opacity);
    }
  }

  void _paintStack(Canvas canvas) {
    final c = geometry.cell;
    if (fx.shattered && fx.particlesEnabled) return;
    final collapsing = fx.collapseAge < EffectsEngine.collapseDuration;
    final collapseT = fx.collapseProgress;
    final clearing = game.status == GameStatus.clearing ? game.clearingRows : const <int>[];
    final p = game.clearProgress;
    final grayT = fx.gameOverAge < 0 ? -1.0 : fx.gameOverAge / EffectsEngine.gameOverGrayDuration;

    for (var y = _h; y < TetrisGame.height; y++) {
      final yv = y - _h;
      var drawY = yv.toDouble();
      if (collapsing) drawY -= (fx.collapseShift[yv] ?? 0) * (1 - collapseT);
      final isClearing = clearing.contains(y);
      final gray = grayT >= 0 && (TetrisGame.visibleHeight - 1 - yv) / TetrisGame.visibleHeight < grayT;
      for (var x = 0; x < TetrisGame.width; x++) {
        final type = game.cellAt(x, y);
        if (type == null) continue;
        final fall = fx.fallAge < EffectsEngine.fallDuration ? (fx.fallShift[(x, yv)] ?? 0) * (1 - fx.fallProgress) : 0.0;
        final px = x * c, py = (drawY - fall) * c;
        if (isClearing) {
          final vanish = EffectsEngine.cellVanishTime(x);
          if (p >= vanish) continue;
          final k = p / vanish;
          sprites.draw(canvas, sprites.block(type), px, py, scale: 1 + 0.14 * k);
          sprites.draw(canvas, sprites.white, px, py, scale: 1 + 0.14 * k, opacity: min(1, p / 0.12) * 0.85);
          continue;
        }
        sprites.draw(canvas, gray ? sprites.gray : sprites.block(type), px, py);
      }
    }
  }

  /// Aiming aids for power pieces: the drill's column and the bomb's blast area.
  void _paintAimHelpers(Canvas canvas) {
    final piece = game.active;
    final ghost = game.ghost;
    if (piece == null || ghost == null || game.status != GameStatus.playing) return;
    final c = geometry.cell;
    final pulse = 0.6 + 0.4 * sin(fx.time * 6);
    if (piece.type == PieceType.drill) {
      final cell = piece.cells.first;
      final x = (cell.x + fx.offsetX) * c;
      final rect = Rect.fromLTWH(x + c * 0.15, max(0, (cell.y - _h + 1) * c), c * 0.7, geometry.wellHeight);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
            const Color(0xFFFDE047).withValues(alpha: 0.35 * pulse),
            const Color(0xFFF59E0B).withValues(alpha: 0.05),
          ]),
      );
    } else if (piece.type == PieceType.bomb) {
      final center = ghost.cells.first;
      final area = Rect.fromLTWH(
        (center.x - 1) * c,
        (center.y - _h - 1) * c,
        3 * c,
        3 * c,
      ).intersect(Rect.fromLTWH(0, 0, geometry.wellWidth, geometry.wellHeight));
      if (area.isEmpty) return;
      final rrect = RRect.fromRectAndRadius(area.deflate(2), Radius.circular(c * 0.3));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF43F5E).withValues(alpha: 0.16 * pulse));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, c * 0.06)
          ..color = const Color(0xFFFB7185).withValues(alpha: 0.8 * pulse),
      );
    }
  }

  void _paintDrillBeams(Canvas canvas, Rect well) {
    final c = geometry.cell;
    for (final b in fx.beams) {
      final fade = 1 - Curves.easeIn.transform(b.t);
      final x = (b.column + 0.5) * c;
      final glow = Rect.fromCenter(center: Offset(x, well.center.dy), width: c * 1.6, height: well.height);
      canvas.drawRect(
        glow,
        Paint()
          ..blendMode = palette.isDark ? BlendMode.plus : BlendMode.srcOver
          ..shader = ui.Gradient.linear(
            glow.centerLeft,
            glow.centerRight,
            [const Color(0x00F59E0B), const Color(0xFFFDE047).withValues(alpha: 0.55 * fade), const Color(0x00F59E0B)],
            const [0, 0.5, 1],
          ),
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, well.center.dy), width: max(2, c * 0.12 * fade), height: well.height),
        Paint()..color = Colors.white.withValues(alpha: 0.9 * fade),
      );
    }
  }

  void _paintGhostLine(Canvas canvas, Rect well) {
    final line = game.ghostLine;
    final row = game.ghostLineRow;
    if (line == null || row == null) return;
    final c = geometry.cell;
    final pulse = 0.65 + 0.35 * sin(fx.time * 8);
    const purple = Color(0xFFA855F7);
    // Highlight the row that would be filled, with the gaps outlined.
    final rowRect = Rect.fromLTWH(well.left, row * c, well.width, c);
    canvas.drawRect(rowRect, Paint()..color = purple.withValues(alpha: 0.18 * pulse));
    final y = row + _h;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, c * 0.07)
      ..color = const Color(0xFFE9D5FF).withValues(alpha: 0.9 * pulse);
    for (var x = 0; x < TetrisGame.width; x++) {
      if (game.cellAt(x, y) != null) continue;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x * c, row * c, c, c).deflate(c * 0.12), Radius.circular(c * 0.2));
      canvas.drawRRect(r, Paint()..color = purple.withValues(alpha: 0.28 * pulse));
      canvas.drawRRect(r, outline);
    }
    // The sinking line itself.
    final ly = (line + 0.5) * c;
    final band = Rect.fromLTRB(well.left - c * 0.4, ly - c * 0.7, well.right + c * 0.4, ly + c * 0.7);
    canvas.drawRect(
      band,
      Paint()
        ..blendMode = palette.isDark ? BlendMode.plus : BlendMode.srcOver
        ..shader = ui.Gradient.linear(
          band.topCenter,
          band.bottomCenter,
          [purple.withValues(alpha: 0), purple.withValues(alpha: 0.45), purple.withValues(alpha: 0)],
          const [0, 0.5, 1],
        ),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(well.center.dx, ly), width: well.width + c * 0.8, height: max(2, c * 0.1)),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  void _paintSlowMotion(Canvas canvas, Rect well) {
    final left = game.slowMotion;
    if (left <= 0) return;
    final c = geometry.cell;
    final k = min(1.0, left) * min(1.0, (TetrisGame.slowMotionDuration - left) * 4 + 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(well, Radius.circular(c * 0.45)),
      Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.1 * k),
    );
    // Remaining time as a bar along the top of the well.
    final bar = Rect.fromLTWH(well.left + c * 0.3, -c * 0.22, (well.width - c * 0.6) * (left / TetrisGame.slowMotionDuration), c * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, Radius.circular(c)),
      Paint()..shader = ui.Gradient.linear(bar.centerLeft, bar.centerRight, const [Color(0xFF7DD3FC), Color(0xFF3B82F6)]),
    );
  }

  void _paintLockPulses(Canvas canvas) {
    final c = geometry.cell;
    for (final pulse in fx.lockPulses) {
      final opacity = (1 - pulse.t) * 0.75;
      for (final cell in pulse.cells) {
        if (cell.y < _h) continue;
        sprites.draw(canvas, sprites.white, cell.x * c, (cell.y - _h) * c, opacity: opacity, scale: 1 + 0.08 * (1 - pulse.t));
      }
    }
  }

  void _paintActive(Canvas canvas) {
    final piece = game.active;
    if (piece == null || game.status == GameStatus.over) return;
    final c = geometry.cell;
    final spawn = fx.spawnAge < 0.18 ? Curves.easeOutBack.transform(fx.spawnAge / 0.18) : 1.0;
    final scale = (0.6 + 0.4 * spawn) * (1 + 0.12 * fx.rotatePop);
    final cells = [for (final cell in piece.cells) Offset((cell.x + fx.offsetX) * c, (cell.y - _h + fx.offsetY) * c)];

    // Pulsing aura behind the piece.
    final auraImage = sprites.aura(piece.type);
    final auraOpacity = (palette.isDark ? 0.6 : 0.38) + 0.15 * sin(fx.time * 5);
    for (final o in cells) {
      sprites.draw(canvas, auraImage, o.dx, o.dy, scale: 1.25, opacity: auraOpacity);
    }

    final image = sprites.block(piece.type);
    for (final o in cells) {
      sprites.draw(canvas, image, o.dx, o.dy, scale: scale);
    }
    final lock = game.lockProgress;
    if (lock > 0) {
      final flicker = 0.6 + 0.4 * sin(fx.time * 22);
      for (final o in cells) {
        sprites.draw(canvas, sprites.white, o.dx, o.dy, scale: scale, opacity: lock * 0.45 * flicker);
      }
    }
  }

  void _paintClearBeams(Canvas canvas, Rect well) {
    if (game.status != GameStatus.clearing) return;
    final c = geometry.cell;
    final p = game.clearProgress;
    final fade = 1 - Curves.easeIn.transform(p);
    for (final row in game.clearingRows) {
      final cy = (row - _h + 0.5) * c;
      final band = Rect.fromLTRB(well.left - c, cy - c * 0.9, well.right + c, cy + c * 0.9);
      canvas.drawRect(
        band,
        Paint()
          ..blendMode = palette.isDark ? BlendMode.plus : BlendMode.srcOver
          ..shader = ui.Gradient.linear(
            band.topCenter,
            band.bottomCenter,
            [const Color(0x007DD3FC), const Color(0xFF7DD3FC).withValues(alpha: 0.22 * fade), const Color(0x007DD3FC)],
            const [0, 0.5, 1],
          ),
      );
      final width = well.width * (0.3 + 0.9 * Curves.easeOut.transform(min(1, p * 2.5)));
      final line = Rect.fromCenter(center: Offset(well.center.dx, cy), width: width, height: max(2, c * 0.08));
      canvas.drawRect(
        line,
        Paint()
          ..shader = ui.Gradient.linear(
            line.centerLeft,
            line.centerRight,
            [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.95 * fade), Colors.white.withValues(alpha: 0)],
            const [0, 0.5, 1],
          ),
      );
    }
  }

  void _paintFlash(Canvas canvas, Rect well) {
    if (fx.boardFlash <= 0) return;
    final c = geometry.cell;
    canvas.drawRRect(
      RRect.fromRectAndRadius(well.inflate(geometry.framePad), Radius.circular(c * 0.8)),
      Paint()
        ..blendMode = palette.isDark ? BlendMode.plus : BlendMode.srcOver
        ..color = Colors.white.withValues(alpha: 0.45 * fx.boardFlash * fx.boardFlash),
    );
  }

  void _paintShockwaves(Canvas canvas) => paintShockwaves(canvas, fx.shockwaves, geometry.cell);

  void _paintParticles(Canvas canvas) => paintParticles(canvas, fx.particles, sprites, geometry.cell);

  void _paintGameOverShade(Canvas canvas, Rect well) {
    if (fx.gameOverAge < 0) return;
    final k = (fx.gameOverAge / 1.6).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(well, Radius.circular(geometry.cell * 0.45)),
      Paint()..color = Colors.black.withValues(alpha: (palette.isDark ? 0.35 : 0.12) * k),
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.sprites != sprites || old.palette != palette || old.geometry.cell != geometry.cell || old.game != game;
}

/// Expanding rings, in cell units.
void paintShockwaves(Canvas canvas, List<Shockwave> shockwaves, double c) {
  for (final s in shockwaves) {
    final t = Curves.easeOutCubic.transform(s.t);
    final radius = s.radius * t * c;
    final alpha = (1 - s.t) * 0.8;
    canvas.drawCircle(
      Offset(s.x * c, s.y * c),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, s.width * c * (1 - s.t))
        ..color = s.color.withValues(alpha: alpha),
    );
  }
}

/// Block shards, sparks and glowing dots, in cell units.
void paintParticles(Canvas canvas, List<Particle> particles, BlockSprites sprites, double c) {
  final glow = Paint();
  final solid = Paint();
  for (final p in particles) {
    if (!p.visible) continue;
    final t = p.t;
    final fade = 1 - t * t;
    final x = p.x * c, y = p.y * c;
    switch (p.kind) {
      case ParticleKind.block:
        sprites.draw(
          canvas,
          sprites.block(p.type!),
          x - c / 2,
          y - c / 2,
          scale: p.size * (1 - 0.3 * t),
          opacity: fade,
          rotation: p.rotation,
        );
      case ParticleKind.grayBlock:
        sprites.draw(canvas, sprites.gray, x - c / 2, y - c / 2, scale: p.size * (1 - 0.25 * t), opacity: fade, rotation: p.rotation);
      case ParticleKind.spark:
        final r = p.size * c * (1 - 0.5 * t);
        glow.color = p.color.withValues(alpha: 0.22 * fade);
        canvas.drawCircle(Offset(x, y), r * 1.6, glow);
        solid.color = p.color.withValues(alpha: fade);
        canvas.drawPath(_star(x, y, r), solid);
      case ParticleKind.dot:
        final r = p.size * c;
        glow.color = p.color.withValues(alpha: 0.25 * fade);
        canvas.drawCircle(Offset(x, y), r * 2.2, glow);
        solid.color = p.color.withValues(alpha: fade);
        canvas.drawCircle(Offset(x, y), r, solid);
    }
  }
}

Path _star(double x, double y, double r) {
  final inner = r * 0.28;
  return Path()
    ..moveTo(x, y - r)
    ..lineTo(x + inner, y - inner)
    ..lineTo(x + r, y)
    ..lineTo(x + inner, y + inner)
    ..lineTo(x, y + r)
    ..lineTo(x - inner, y + inner)
    ..lineTo(x - r, y)
    ..lineTo(x - inner, y - inner)
    ..close();
}

/// Floating callouts ("DÖRTLÜ!", "+800", "KOMBO ×2"). Painted without the
/// board's perspective tilt so text stays crisp and readable.
class FloaterPainter extends CustomPainter {
  FloaterPainter({required this.floaters, required this.cell, required this.origin, required Listenable repaint}) : super(repaint: repaint);

  /// The live list of an effects engine; read on every repaint.
  final List<Floater> floaters;
  final double cell;

  /// Canvas position of the board's (0, 0) cell corner.
  final Offset origin;

  static const _outline = Color(0xE60F172A);

  @override
  void paint(Canvas canvas, Size size) {
    final c = cell;
    for (final f in floaters) {
      final appear = Curves.easeOutBack.transform((f.age / 0.32).clamp(0.0, 1.0));
      final scale = 0.35 + 0.65 * appear;
      final outT = ((f.t - 0.68) / 0.32).clamp(0.0, 1.0);
      final alpha = 1 - outT;
      final rise = Curves.easeIn.transform(outT) * 1.4;
      if (alpha <= 0) continue;

      // Text layout is expensive: do it once per floater and cell size.
      var cached = _layouts[f];
      if (cached == null || cached.$1 != c) {
        cached = (c, [for (final line in f.lines) _layout(line, c)]);
        _layouts[f] = cached;
      }
      final painters = cached.$2;
      final total = painters.fold<double>(0, (sum, p) => sum + p.$1.height * 0.92);
      final widest = painters.fold<double>(0, (w, p) => max(w, p.$1.width));
      var y = -total / 2;

      canvas.save();
      canvas.translate(origin.dx + f.x * c, origin.dy + (f.y - rise) * c);
      canvas.scale(scale);
      // Bounded layer for the fade so only the text area is composited.
      canvas.saveLayer(
        Rect.fromCenter(center: Offset.zero, width: widest + c * 2, height: total + c * 2),
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
      for (var i = 0; i < painters.length; i++) {
        final (stroke, fill) = painters[i];
        // Lines after the first slide in with a small stagger.
        final stagger = ((f.age - i * 0.06) / 0.25).clamp(0.0, 1.0);
        final dx = -stroke.width / 2;
        canvas.save();
        canvas.translate(0, (1 - Curves.easeOut.transform(stagger)) * c * 0.6);
        stroke.paint(canvas, Offset(dx, y));
        fill.paint(canvas, Offset(dx, y));
        canvas.restore();
        y += stroke.height * 0.92;
      }
      canvas.restore();
      canvas.restore();
    }
  }

  static final Expando<(double, List<(TextPainter, TextPainter)>)> _layouts = Expando();

  (TextPainter, TextPainter) _layout(FloaterLine line, double c) {
    final fontSize = line.size * c;
    TextStyle style(Paint paint, {List<Shadow>? shadows}) => TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: fontSize * 0.03,
      foreground: paint,
      shadows: shadows,
    );
    final stroke = TextPainter(
      text: TextSpan(
        text: line.text,
        style: style(
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, fontSize * 0.14)
            ..strokeJoin = StrokeJoin.round
            ..color = _outline,
          shadows: line.glow == null ? null : [Shadow(color: line.glow!.withValues(alpha: 0.85), blurRadius: fontSize * 0.6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final shader = ui.Gradient.linear(
      Offset.zero,
      line.colors.length > 3 ? Offset(stroke.width, stroke.height * 0.3) : Offset(0, stroke.height),
      line.colors,
      [for (var i = 0; i < line.colors.length; i++) i / (line.colors.length - 1)],
    );
    final fill = TextPainter(
      text: TextSpan(text: line.text, style: style(Paint()..shader = shader)),
      textDirection: TextDirection.ltr,
    )..layout();
    return (stroke, fill);
  }

  @override
  bool shouldRepaint(covariant FloaterPainter old) => old.cell != cell || old.floaters != floaters || old.origin != origin;
}
