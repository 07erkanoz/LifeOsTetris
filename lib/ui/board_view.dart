import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/render/block_sprites.dart';
import '../game/render/board_painter.dart';
import '../theme/palette.dart';

/// The tilted 2.5D board with touch gestures, screen shake and floaters.
/// It takes exactly the frame's size; the paint canvas overflows it so
/// particles can fly over neighbouring UI.
class BoardView extends StatelessWidget {
  const BoardView({super.key, required this.controller, required this.cell, this.tilt = 0.2});

  final GameController controller;
  final double cell;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    final geometry = BoardGeometry(cell);
    final sprites = BlockSprites.of(cell, MediaQuery.devicePixelRatioOf(context), palette);
    final frame = geometry.frameSize;
    final canvasOffset = -geometry.margin;

    final board = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: canvasOffset,
          top: canvasOffset,
          child: RepaintBoundary(
            child: CustomPaint(
              size: geometry.size,
              painter: BoardPainter(
                game: controller.game,
                fx: controller.fx,
                sprites: sprites,
                palette: palette,
                geometry: geometry,
                repaint: controller.frame,
              ),
            ),
          ),
        ),
      ],
    );

    return SizedBox.fromSize(
      size: frame,
      child: ValueListenableBuilder<int>(
        valueListenable: controller.frame,
        builder: (context, _, child) => Transform.translate(offset: controller.fx.shake * cell, child: child),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.rotateCw,
              onPanStart: (_) => controller.dragStart(),
              onPanUpdate: (d) => controller.dragUpdate(d.delta, cell),
              onPanEnd: (d) => controller.dragEnd(d.velocity.pixelsPerSecond),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0009)
                  ..rotateX(-tilt),
                child: SizedBox.fromSize(size: frame, child: board),
              ),
            ),
            Positioned(
              left: canvasOffset,
              top: canvasOffset,
              child: IgnorePointer(
                child: CustomPaint(
                  size: geometry.size,
                  painter: FloaterPainter(fx: controller.fx, geometry: geometry, repaint: controller.frame),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
