import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/tower/tower_landmarks.dart';
import '../sugar/sugar_art.dart' show paintGoldStar, paintSparkle;

const Color _ink = Color(0xFF15101F);
const _stone = [Color(0xFFE9D9BE), Color(0xFFBFA987)];
const _darkStone = [Color(0xFFCDB89A), Color(0xFF9E8A6C)];
const _lead = [Color(0xFFA9B8C9), Color(0xFF5A6A80)];
const _roof = [Color(0xFFD8574A), Color(0xFF9E3328)];
const _white = [Color(0xFFFFFFFF), Color(0xFFE2DCE6)];
const _pale = [Color(0xFFF4EFE6), Color(0xFFD8CDBB)];
const _sand = [Color(0xFFE8C9A8), Color(0xFFC09A78)];
const _concrete = [Color(0xFFF2F2F5), Color(0xFFC3C6D2)];
const _glass = [Color(0xFFBFE8FF), Color(0xFF5E9AD0)];
const _gold = [Color(0xFFFFE47A), Color(0xFFD99A10)];
const _hill = [Color(0xFF9ED96B), Color(0xFF5A9A3A)];
const _earth = [Color(0xFFC2AA80), Color(0xFF8A7656)];
const _window = Color(0xFF4A2E3E);

/// One part of a landmark as it is drawn: its shapes, then the small things
/// on them (windows, bands, a clock), in landmark units around the foot.
class _Draft {
  _Draft(this.foot, this.k);

  final Offset foot;
  final double k;
  final List<(Path, List<Color>)> shapes = [];
  final List<void Function(Canvas)> details = [];

  Offset p(double x, double y) => foot + Offset(x * k, y * k);
  Rect r(double x, double y, double w, double h) => Rect.fromLTWH(foot.dx + x * k, foot.dy + y * k, w * k, h * k);

  void rect(double x, double y, double w, double h, List<Color> c) => shapes.add((Path()..addRect(r(x, y, w, h)), c));
  void round(double x, double y, double w, double h, double radius, List<Color> c) =>
      shapes.add((Path()..addRRect(RRect.fromRectAndRadius(r(x, y, w, h), Radius.circular(radius * k))), c));
  void poly(List<(double, double)> pts, List<Color> c) => shapes.add((Path()..addPolygon([for (final (x, y) in pts) p(x, y)], true), c));
  void cone(double x, double base, double w, double h, List<Color> c) => poly([(x - w / 2, base), (x + w / 2, base), (x, base - h)], c);
  void dome(double x, double base, double w, double h, List<Color> c) {
    final a = p(x - w / 2, base), b = p(x + w / 2, base);
    shapes.add((
      Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, a.dy - h * k * 1.33, b.dx, b.dy - h * k * 1.33, b.dx, b.dy)
        ..close(),
      c,
    ));
  }

  /// Arched windows in a row.
  void windows(double x, double y, int n, double w, double h, double gap) => details.add((canvas) {
    final paint = Paint()..color = _window;
    for (var i = 0; i < n; i++) {
      canvas.drawRRect(RRect.fromRectAndCorners(r(x + i * (w + gap), y, w, h), topLeft: Radius.circular(w * k / 2), topRight: Radius.circular(w * k / 2)), paint);
    }
  });

  /// A line across a part: a band of stone, a railing.
  void band(double x0, double y, double x1, {Color color = const Color(0xFF9A7A5A), double width = 2}) => details.add(
    (canvas) => canvas.drawLine(p(x0, y), p(x1, y), Paint()
      ..color = color
      ..strokeWidth = max(1, width * k)),
  );

  /// Battlements along the top of a wall.
  void merlons(double x0, double x1, double y, double step) {
    for (var x = x0; x < x1 - step * 0.4; x += step) {
      rect(x, y - 10, step * 0.55, 10, _stone);
    }
  }

  void detail(void Function(Canvas canvas) paint) => details.add(paint);
}

/// The five parts of [l], each a function filling a draft.
List<void Function(_Draft d)> _parts(Landmark l) => switch (l) {
  Landmark.galata => [
    (d) {
      d.poly([(-150, 0), (150, 0), (110, -34), (-110, -34)], _earth);
      d.rect(-56, -64, 112, 30, _darkStone);
    },
    (d) {
      d.rect(-44, -236, 88, 172, _stone);
      d.band(-44, -180, 44);
      d.band(-44, -120, 44);
      d.windows(-24, -214, 2, 16, 26, 16);
      d.windows(-24, -164, 2, 16, 26, 16);
      d.windows(-24, -110, 2, 16, 26, 16);
    },
    (d) {
      d.rect(-54, -270, 108, 34, _pale);
      d.windows(-46, -264, 6, 10, 18, 6);
      d.band(-58, -238, 58, color: _ink, width: 2.4);
    },
    (d) => d.cone(0, -270, 104, 104, _lead),
    (d) {
      d.rect(-2.5, -404, 5, 32, _gold);
      d.detail((canvas) => canvas.drawCircle(d.p(0, -404), 5 * d.k, Paint()..color = _gold.first));
    },
  ],
  Landmark.maidens => [
    (d) {
      d.rect(-150, 0, 300, 22, _earth);
      d.rect(40, -60, 108, 60, _white);
      d.poly([(34, -60), (154, -60), (140, -80), (48, -80)], _roof);
      d.detail((canvas) {
        for (var i = 0; i < 4; i++) {
          canvas.drawRRect(RRect.fromRectAndRadius(d.r(52 + i * 24, -44, 12, 18), Radius.circular(5 * d.k)), Paint()..color = const Color(0xFF8A4A3A));
        }
      });
    },
    (d) {
      d.rect(-46, -170, 92, 170, _stone);
      d.band(-46, -120, 46);
      d.band(-46, -64, 46);
      d.windows(-26, -150, 2, 16, 26, 20);
      d.windows(-26, -100, 2, 16, 26, 20);
      d.windows(-26, -46, 2, 16, 26, 20);
    },
    (d) {
      d.rect(-64, -186, 128, 16, _white);
      d.rect(-38, -246, 76, 60, _stone);
      d.windows(-24, -236, 2, 16, 30, 16);
      d.detail((canvas) {
        final rail = Paint()
          ..color = _ink
          ..strokeWidth = max(1, 1.6 * d.k);
        for (var x = -60.0; x <= 60; x += 10) {
          canvas.drawLine(d.p(x, -186), d.p(x, -198), rail);
        }
        canvas.drawLine(d.p(-64, -198), d.p(64, -198), rail);
      });
    },
    (d) => d.dome(0, -246, 84, 34, _lead),
    (d) {
      d.rect(-9, -306, 18, 22, _lead);
      d.rect(-2, -400, 4, 96, _concrete);
      d.rect(2, -398, 46, 30, const [Color(0xFFE30A17), Color(0xFFC00812)]);
      d.detail((canvas) {
        final c = d.p(20, -383);
        canvas.drawCircle(c, 9 * d.k, Paint()..color = Colors.white);
        canvas.drawCircle(c + Offset(2.4 * d.k, 0), 7.4 * d.k, Paint()..color = const Color(0xFFE30A17));
        paintGoldStar(canvas, c + Offset(10 * d.k, 0), 3.4 * d.k);
      });
    },
  ],
  Landmark.rumeli => [
    (d) {
      d.rect(-150, -70, 300, 70, _stone);
      d.merlons(-150, 150, -70, 20);
      d.detail((canvas) => canvas.drawRRect(RRect.fromRectAndCorners(d.r(-14, -40, 28, 40), topLeft: Radius.circular(14 * d.k), topRight: Radius.circular(14 * d.k)), Paint()..color = _window));
    },
    (d) {
      d.rect(-142, -150, 60, 150, _stone);
      d.windows(-120, -126, 1, 14, 22, 0);
    },
    (d) {
      d.rect(-42, -232, 84, 232, _stone);
      d.windows(-24, -206, 2, 14, 24, 20);
      d.windows(-24, -150, 2, 14, 24, 20);
      d.band(-42, -110, 42);
    },
    (d) {
      d.rect(82, -172, 60, 172, _stone);
      d.windows(104, -146, 1, 14, 22, 0);
      d.merlons(-42, 42, -232, 14);
    },
    (d) {
      d.cone(-112, -150, 72, 62, _roof);
      d.cone(112, -172, 72, 66, _roof);
      d.cone(0, -242, 96, 84, _roof);
    },
  ],
  Landmark.beyazit => [
    (d) => d.rect(-42, -42, 84, 42, _darkStone),
    (d) {
      d.rect(-26, -204, 52, 162, _stone);
      d.band(-26, -150, 26);
      d.band(-26, -96, 26);
      d.windows(-6, -186, 1, 12, 22, 0);
      d.windows(-6, -132, 1, 12, 22, 0);
    },
    (d) {
      d.rect(-22, -292, 44, 88, _stone);
      d.windows(-6, -276, 1, 12, 22, 0);
      d.rect(-34, -298, 68, 6, _pale);
    },
    (d) {
      d.rect(-30, -340, 60, 42, _white);
      d.windows(-24, -334, 4, 9, 22, 4);
    },
    (d) {
      d.cone(0, -340, 70, 54, _lead);
      d.rect(-2, -414, 4, 22, _gold);
    },
  ],
  Landmark.dolmabahce => [
    (d) {
      d.rect(-62, -24, 124, 24, _pale);
      d.rect(-52, -54, 104, 30, _pale);
    },
    (d) {
      d.rect(-40, -214, 80, 160, _pale);
      d.detail((canvas) {
        final paint = Paint()
          ..color = const Color(0xFFB8A888)
          ..strokeWidth = max(1, 3 * d.k);
        for (final x in [-30.0, 30.0]) {
          canvas.drawLine(d.p(x, -60), d.p(x, -210), paint);
        }
      });
      d.windows(-12, -190, 1, 24, 40, 0);
      d.windows(-12, -120, 1, 24, 40, 0);
    },
    (d) {
      d.rect(-46, -266, 92, 52, _pale);
      d.detail((canvas) {
        final c = d.p(0, -240);
        canvas.drawCircle(c, 18 * d.k, Paint()..color = Colors.white);
        canvas.drawCircle(
          c,
          18 * d.k,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1, 2.4 * d.k)
            ..color = _gold.last,
        );
        final hand = Paint()
          ..color = _ink
          ..strokeWidth = max(1, 2 * d.k)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(c, c + Offset(0, -12 * d.k), hand);
        canvas.drawLine(c, c + Offset(8 * d.k, 3 * d.k), hand);
      });
    },
    (d) => d.dome(0, -266, 76, 40, _lead),
    (d) {
      d.rect(-3, -346, 6, 30, _gold);
      d.detail((canvas) => canvas.drawCircle(d.p(0, -348), 6 * d.k, Paint()..color = _gold.first));
    },
  ],
  Landmark.haydarpasa => [
    (d) => d.rect(-150, -22, 300, 22, _darkStone),
    (d) {
      d.rect(-132, -134, 264, 112, _sand);
      d.windows(-110, -112, 7, 14, 26, 18);
      d.windows(-110, -62, 7, 14, 26, 18);
    },
    (d) {
      d.rect(-134, -206, 58, 72, _sand);
      d.windows(-114, -190, 1, 16, 30, 0);
    },
    (d) {
      d.rect(76, -206, 58, 72, _sand);
      d.windows(96, -190, 1, 16, 30, 0);
    },
    (d) {
      d.cone(-105, -206, 70, 66, _lead);
      d.cone(105, -206, 70, 66, _lead);
      d.poly([(-76, -134), (76, -134), (60, -164), (-60, -164)], _roof);
    },
  ],
  Landmark.selimiye => [
    (d) => d.rect(-150, -30, 300, 30, _hill),
    (d) {
      d.rect(-118, -124, 236, 94, _pale);
      d.windows(-100, -108, 8, 12, 22, 14);
      d.windows(-100, -68, 8, 12, 22, 14);
    },
    (d) {
      d.rect(-142, -174, 42, 144, _pale);
      d.rect(100, -174, 42, 144, _pale);
      d.windows(-128, -150, 1, 14, 24, 0);
      d.windows(114, -150, 1, 14, 24, 0);
    },
    (d) {
      d.cone(-121, -174, 54, 44, _roof);
      d.cone(121, -174, 54, 44, _roof);
      d.poly([(-118, -124), (118, -124), (98, -142), (-98, -142)], _roof);
    },
    (d) {
      d.rect(-1.5, -236, 3, 94, _concrete);
      d.rect(1.5, -234, 42, 26, const [Color(0xFFE30A17), Color(0xFFC00812)]);
      d.detail((canvas) {
        final c = d.p(18, -221);
        canvas.drawCircle(c, 7 * d.k, Paint()..color = Colors.white);
        canvas.drawCircle(c + Offset(2 * d.k, 0), 5.8 * d.k, Paint()..color = const Color(0xFFE30A17));
        paintGoldStar(canvas, c + Offset(8 * d.k, 0), 2.8 * d.k);
      });
    },
  ],
  Landmark.camlica => [
    (d) => d.poly([(-150, 0), (150, 0), (90, -40), (-90, -40)], _hill),
    (d) => d.poly([(-26, -40), (26, -40), (16, -222), (-16, -222)], _concrete),
    (d) {
      d.round(-42, -266, 84, 44, 16, _glass);
      d.band(-40, -244, 40, color: Colors.white, width: 2);
    },
    (d) => d.poly([(-14, -266), (14, -266), (9, -364), (-9, -364)], _concrete),
    (d) {
      d.rect(-3, -436, 6, 72, const [Color(0xFFFF5A5A), Color(0xFFD02020)]);
      d.detail((canvas) {
        final paint = Paint()..color = Colors.white;
        for (var y = -430.0; y < -370; y += 16) {
          canvas.drawRect(d.r(-3, y, 6, 6), paint);
        }
      });
    },
  ],
};

void _dashed(Canvas canvas, Path path, Paint paint, {double on = 6, double off = 5}) {
  for (final metric in path.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += on + off) {
      canvas.drawPath(metric.extractPath(d, min(d + on, metric.length)), paint);
    }
  }
}

/// [l] standing on [foot] at scale [k] (1 is about 420 px tall): parts
/// before [done] finished, the next one rising from its foot by [rising]
/// (0 to 1), the rest a dashed outline still to come.
void paintLandmark(Canvas canvas, Landmark l, Offset foot, double k, {int done = Landmark.parts, double rising = 0, double time = 0}) {
  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1, 2 * k)
    ..strokeJoin = StrokeJoin.round
    ..color = _ink;
  final ghost = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1, 2 * k)
    ..color = Colors.white.withValues(alpha: 0.45);
  final parts = _parts(l);
  void solid(_Draft d) {
    for (final (path, colors) in d.shapes) {
      final b = path.getBounds();
      canvas.drawPath(path, colors.length == 1 ? (Paint()..color = colors.first) : (Paint()..shader = ui.Gradient.linear(b.topLeft, b.bottomRight, colors)));
      canvas.drawPath(path, outline);
    }
    for (final paint in d.details) {
      paint(canvas);
    }
  }

  for (var i = 0; i < parts.length; i++) {
    final d = _Draft(foot, k);
    parts[i](d);
    if (i < done) {
      solid(d);
    } else if (i == done && rising > 0) {
      for (final (path, _) in d.shapes) {
        _dashed(canvas, path, ghost);
      }
      final bounds = d.shapes.map((s) => s.$1.getBounds()).reduce((a, b) => a.expandToInclude(b));
      final line = bounds.bottom - bounds.height * rising.clamp(0.0, 1.0);
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(bounds.left - 8, line, bounds.right + 8, bounds.bottom + 8));
      solid(d);
      canvas.restore();
      // The building line: where the floors are going in now.
      canvas.drawLine(
        Offset(bounds.left - 6, line),
        Offset(bounds.right + 6, line),
        Paint()
          ..color = const Color(0xFFFF5FB8)
          ..strokeWidth = max(1.5, 3 * k)
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      final x = bounds.left + bounds.width * (0.5 + 0.45 * sin(time * 2));
      paintSparkle(canvas, Offset(x, line), max(4, 9 * k), const Color(0xFFFFE066));
    } else {
      for (final (path, _) in d.shapes) {
        _dashed(canvas, path, ghost);
      }
    }
  }
}
