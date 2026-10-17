import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/rewards.dart';
import '../core/sugar/sugar_game.dart';
import '../game/sugar/istanbul_art.dart';
import '../game/sugar/sugar_art.dart';

/// Pictures for the gifts: chests, the sugar jar, postcards.

const List<Color> chestBronze = [Color(0xFFE0A070), Color(0xFFFFD0A0), Color(0xFFB0602A)];
const List<Color> chestSilver = [Color(0xFFB8C0D0), Color(0xFFFFFFFF), Color(0xFF8A94A8)];
const List<Color> chestGold = [Color(0xFFE2B33C), Color(0xFFFFF1A8), Color(0xFFB07A1E)];

List<Color> chestTone(ChestTier t) => switch (t) {
  ChestTier.bronze => chestBronze,
  ChestTier.silver => chestSilver,
  ChestTier.gold => chestGold,
};

/// A treasure chest [s] wide around [c], banded in [tone]; open spills
/// light, [glow] says it is waiting to be opened.
void paintChest(Canvas canvas, Offset c, double s, List<Color> tone, {bool open = false, bool glow = false}) {
  if (glow) {
    canvas.drawCircle(c, s * 0.9, Paint()..shader = ui.Gradient.radial(c, s * 0.9, [const Color(0xFFFFF0A0).withValues(alpha: 0.8), const Color(0xFFFFF0A0).withValues(alpha: 0)]));
  }
  final body = Rect.fromCenter(center: c + Offset(0, s * 0.12), width: s, height: s * 0.5);
  canvas.drawRRect(RRect.fromRectAndRadius(body.shift(Offset(0, s * 0.05)), Radius.circular(s * 0.08)), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawRRect(
    RRect.fromRectAndRadius(body, Radius.circular(s * 0.08)),
    Paint()..shader = ui.Gradient.linear(body.topCenter, body.bottomCenter, const [Color(0xFFB0703A), Color(0xFF6A3A1A)]),
  );
  if (open) {
    canvas.drawRect(Rect.fromLTWH(body.left + s * 0.06, body.top - s * 0.02, body.width - s * 0.12, s * 0.1), Paint()..color = const Color(0xFFFFE066));
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i - 2.5) * 0.35;
      canvas.drawLine(
        c + Offset(0, -s * 0.05),
        c + Offset(cos(a), sin(a)) * s * 0.75,
        Paint()
          ..strokeWidth = s * 0.05
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFF0A0).withValues(alpha: 0.7),
      );
    }
  }
  final lid = open ? Rect.fromCenter(center: c + Offset(0, -s * 0.36), width: s, height: s * 0.2) : Rect.fromCenter(center: c + Offset(0, -s * 0.2), width: s, height: s * 0.3);
  canvas.drawRRect(
    RRect.fromRectAndCorners(lid, topLeft: Radius.circular(s * 0.3), topRight: Radius.circular(s * 0.3), bottomLeft: Radius.circular(s * 0.04), bottomRight: Radius.circular(s * 0.04)),
    Paint()..shader = ui.Gradient.linear(lid.topCenter, lid.bottomCenter, const [Color(0xFFC0803A), Color(0xFF7A441E)]),
  );
  final band = Paint()..shader = ui.Gradient.linear(Offset(c.dx - s / 2, 0), Offset(c.dx + s / 2, 0), tone, const [0, 0.5, 1]);
  for (final dx in [-0.32, 0.32]) {
    canvas.drawRect(Rect.fromLTWH(c.dx + dx * s - s * 0.06, lid.top, s * 0.12, body.bottom - lid.top), band);
  }
  canvas.drawRect(Rect.fromLTWH(body.left, body.top - s * 0.02, body.width, s * 0.06), band);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, body.top + s * 0.1), width: s * 0.16, height: s * 0.2), Radius.circular(s * 0.04)), band);
}

/// A glass jar of sweets [s] tall around [c], [fill] 0..1 full.
void paintJar(Canvas canvas, Offset c, double s, double fill, {bool shine = false}) {
  final body = RRect.fromRectAndCorners(
    Rect.fromCenter(center: c + Offset(0, s * 0.08), width: s * 0.8, height: s * 0.9),
    topLeft: Radius.circular(s * 0.2),
    topRight: Radius.circular(s * 0.2),
    bottomLeft: Radius.circular(s * 0.16),
    bottomRight: Radius.circular(s * 0.16),
  );
  if (shine) {
    canvas.drawCircle(c, s * 0.85, Paint()..shader = ui.Gradient.radial(c, s * 0.85, [const Color(0xFFFFF0A0).withValues(alpha: 0.7), const Color(0xFFFFF0A0).withValues(alpha: 0)]));
  }
  canvas.drawRRect(body.shift(Offset(0, s * 0.03)), Paint()..color = Colors.black.withValues(alpha: 0.25));
  canvas.drawRRect(body, Paint()..color = const Color(0xFFE6F6FF).withValues(alpha: 0.35));
  canvas.save();
  canvas.clipRRect(body.deflate(s * 0.03));
  final top = body.bottom - body.height * fill.clamp(0.0, 1.0);
  final rnd = Random(9);
  final r = s * 0.075;
  for (var y = body.bottom - r; y > top - r * 0.5; y -= r * 1.5) {
    for (var x = body.left + r; x < body.right; x += r * 1.8) {
      final jitter = Offset((rnd.nextDouble() - 0.5) * r * 0.6, (rnd.nextDouble() - 0.5) * r * 0.4);
      paintCandy(
        canvas,
        Rect.fromCenter(center: Offset(x + ((y ~/ r).isEven ? r * 0.8 : 0), y) + jitter, width: r * 2, height: r * 2),
        SugarColor.values[rnd.nextInt(SugarColor.values.length)],
        shadow: false,
      );
    }
  }
  canvas.restore();
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(body.left + s * 0.08, body.top + s * 0.12, s * 0.08, body.height * 0.6), Radius.circular(s * 0.04)),
    Paint()..color = Colors.white.withValues(alpha: 0.55),
  );
  canvas.drawRRect(
    body,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..color = Colors.white.withValues(alpha: 0.9),
  );
  final lid = Rect.fromCenter(center: Offset(c.dx, body.top - s * 0.02), width: s * 0.66, height: s * 0.14);
  canvas.drawRRect(RRect.fromRectAndRadius(lid, Radius.circular(s * 0.05)), Paint()..shader = ui.Gradient.linear(lid.topCenter, lid.bottomCenter, const [Color(0xFFFF9AD8), Color(0xFFE0247A)]));
  for (var i = 0; i < 6; i++) {
    canvas.drawCircle(Offset(lid.left + lid.width * (i + 0.5) / 6, lid.bottom), s * 0.03, Paint()..color = const Color(0xFFE0247A));
  }
}

/// The scene on postcard [i].
int postcardScene(int i) => const [3, 0, 5, 4, 2, 2, 3, 3, 0, 0, 1, 0, 5, 4, 0, 6, 10, 7, 8, 9][i % 20];

/// A small postcard: a white border round its İstanbul scene.
void paintPostcard(Canvas canvas, Rect r, int i, {bool locked = false}) {
  canvas.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(0, 3)), const Radius.circular(6)), Paint()..color = Colors.black.withValues(alpha: 0.3));
  canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = locked ? const Color(0xFFD8CCE6) : const Color(0xFFFFF8EC));
  final inner = r.deflate(r.width * 0.06);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(inner, const Radius.circular(3)));
  if (locked) {
    canvas.drawRect(inner, Paint()..color = const Color(0xFFB8A8CC));
  } else {
    canvas.translate(inner.left, inner.top);
    paintStoryScene(canvas, inner.size, postcardScene(i), t: 8);
  }
  canvas.restore();
}

/// A painter for a [paint] function, so the pictures can sit in widgets.
class GiftPicture extends StatelessWidget {
  const GiftPicture({super.key, required this.size, required this.paint, this.repaintKey});

  final Size size;
  final void Function(Canvas canvas, Size size) paint;

  /// Changes when the picture changes.
  final Object? repaintKey;

  @override
  Widget build(BuildContext context) => CustomPaint(size: size, painter: _FnPainter(paint, repaintKey));
}

class _FnPainter extends CustomPainter {
  _FnPainter(this.fn, this.key);

  final void Function(Canvas, Size) fn;
  final Object? key;

  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size);

  @override
  bool shouldRepaint(_FnPainter old) => old.key != key;
}
