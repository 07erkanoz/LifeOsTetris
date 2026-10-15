// Renders the app icon with the game's own block painters.
//   flutter test tool/render_icon_test.dart
// Writes assets/icon/icon.png (full square, every platform) and
// assets/icon/icon_foreground.png (Android adaptive foreground: blocks on
// transparency, no glow, so launchers never show a halo).
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/tetromino.dart';
import 'package:lifeos_kupler/game/render/block_sprites.dart';
import 'package:lifeos_kupler/theme/palette.dart';

const double _size = 1024;

/// Output folder (`ICON_OUT`), the app's icon assets by default.
final String _out = Platform.environment['ICON_OUT'] ?? 'assets/icon/';

/// Background of the full icon and of the adaptive icon (pubspec).
const Color iconBackground = Color(0xFF2A2238);

void _paintBlocks(Canvas canvas, double cell, Offset center) {
  final colors = blockColorsOf(_glass ? GameSkin.glass : GameSkin.toy);
  final gap = cell * 0.06;
  final step = cell + gap;
  // Centre the blocks' bounding box, the raised orange block included.
  final height = 3 * step - gap + cell * 0.42;
  final origin = Offset(center.dx - (3 * step - gap) / 2, center.dy - height / 2 + cell * 0.42);
  const grid = [
    [PieceType.i, PieceType.t, null],
    [PieceType.j, PieceType.o, PieceType.s],
    [PieceType.z, PieceType.i, PieceType.t],
  ];
  // The falling orange block: a short trail, then the block itself.
  final fx = origin.dx + 2 * step;
  final fy = origin.dy - cell * 0.42;
  final trail = Rect.fromLTWH(fx + cell * 0.2, fy - cell * 0.75, cell * 0.6, cell * 0.85);
  canvas.drawRRect(
    RRect.fromRectAndRadius(trail, Radius.circular(cell * 0.12)),
    Paint()
      ..shader = ui.Gradient.linear(trail.topCenter, trail.bottomCenter, [
        colors[PieceType.l]!.withValues(alpha: 0),
        colors[PieceType.l]!.withValues(alpha: 0.55),
      ]),
  );
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 3; x++) {
      final type = grid[y][x];
      if (type == null) continue;
      _block(canvas, origin + Offset(x * step, y * step), cell, colors[type]!);
    }
  }
  _block(canvas, Offset(fx, fy), cell, colors[PieceType.l]!);
}

/// `ICON_STYLE=glass` draws the original jelly blocks (for comparison).
final bool _glass = Platform.environment['ICON_STYLE'] == 'glass';

void _block(Canvas canvas, Offset o, double cell, Color color) => _glass
    ? paintBlock(canvas, o, cell, color, shadeTarget: GamePalette.glassDark.shadeTarget, emissive: false)
    : paintToyBlockHd(canvas, o, cell, color, GamePalette.toyDark.ink);

Future<void> _save(void Function(Canvas) paint, String path) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render icon', () async {
    await _save((canvas) {
      const rect = Rect.fromLTWH(0, 0, _size, _size);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(const Offset(_size * 0.45, _size * 0.4), _size * 0.75, [
            const Color(0xFF3D3254),
            iconBackground,
            const Color(0xFF1E1829),
          ], const [0, 0.55, 1]),
      );
      final dot = Paint()..color = const Color(0x14FFFFFF);
      for (var y = 0; y < 22; y++) {
        for (var x = 0; x < 22; x++) {
          canvas.drawCircle(Offset(x * 48.0 + (y.isOdd ? 24 : 0), y * 48.0), 3.2, dot);
        }
      }
      _paintBlocks(canvas, 206, const Offset(_size / 2, _size / 2));
    }, '${_out}icon.png');

    // Adaptive foreground: the launcher masks a 66% circle and the manifest
    // insets the drawable by 16%, so the blocks stay well inside.
    await _save((canvas) => _paintBlocks(canvas, 200, const Offset(_size / 2, _size / 2)), '${_out}icon_foreground.png');
    expect(max(1, 1), 1);
  });
}
