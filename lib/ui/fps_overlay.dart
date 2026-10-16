import 'dart:math';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Frame rate and frame times in a corner, for measuring on a real phone:
/// how long a frame takes to build (UI) and to draw (GPU), on average and
/// at worst over the last two seconds. Only in builds made with
/// `--dart-define=KUPLER_FPS=true`; other builds leave it out entirely.
class FpsOverlay extends StatefulWidget {
  const FpsOverlay({super.key, required this.child});

  static const bool enabled = bool.fromEnvironment('KUPLER_FPS');

  final Widget child;

  @override
  State<FpsOverlay> createState() => _FpsOverlayState();
}

class _FpsOverlayState extends State<FpsOverlay> {
  final List<FrameTiming> _frames = [];
  String _text = '…';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    _frames.addAll(timings);
    final newest = _frames.last.timestampInMicroseconds(FramePhase.vsyncStart);
    _frames.removeWhere((f) => newest - f.timestampInMicroseconds(FramePhase.vsyncStart) > 2000000);
    if (_frames.length < 2) return;
    double ms(Duration d) => d.inMicroseconds / 1000;
    final span = (newest - _frames.first.timestampInMicroseconds(FramePhase.vsyncStart)) / 1e6;
    final fps = span > 0 ? (_frames.length - 1) / span : 0;
    final build = _frames.map((f) => ms(f.buildDuration)).toList();
    final raster = _frames.map((f) => ms(f.rasterDuration)).toList();
    double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    final text =
        '${fps.round()} fps · UI ${avg(build).toStringAsFixed(1)} ms (en çok ${build.reduce(max).toStringAsFixed(1)}) · '
        'GPU ${avg(raster).toStringAsFixed(1)} ms (en çok ${raster.reduce(max).toStringAsFixed(1)})';
    if (text != _text && mounted) setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned(
          left: 6,
          top: MediaQuery.paddingOf(context).top + 4,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xAA000000), borderRadius: BorderRadius.circular(6)),
              child: Text(
                _text,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
