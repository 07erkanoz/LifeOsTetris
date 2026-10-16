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

  /// Perspective strength of the tilt (Matrix4 entry 3,2).
  static const double perspective = 0.0009;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    final geometry = BoardGeometry(cell);
    final sprites = BlockSprites.of(cell, MediaQuery.devicePixelRatioOf(context), palette);
    final frame = geometry.frameSize;
    final canvasOffset = -geometry.margin;
    final tiltMatrix = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..rotateX(-tilt);
    // The same tilt as the board's Transform (about the bottom centre), for
    // points on the board canvas; used to place the flat callouts.
    final pivot = Offset(frame.width / 2, frame.height);
    Offset project(Offset canvasPoint) {
      final p = canvasPoint + Offset(canvasOffset, canvasOffset) - pivot;
      return MatrixUtils.transformPoint(tiltMatrix, p) + pivot - Offset(canvasOffset, canvasOffset);
    }

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
                transform: tiltMatrix,
                child: SizedBox.fromSize(size: frame, child: board),
              ),
            ),
            Positioned(
              left: canvasOffset,
              top: canvasOffset,
              child: IgnorePointer(
                child: CustomPaint(
                  size: geometry.size,
                  painter: FloaterPainter(
                    floaters: controller.fx.floaters,
                    cell: cell,
                    origin: geometry.wellOrigin,
                    repaint: controller.frame,
                    project: project,
                    wellTop: project(geometry.wellOrigin - Offset(0, geometry.framePad)).dy,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
