import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/settings/settings.dart';

int _paints(double frameSeconds, {double jitter = 0, bool high = false}) {
  final settings = Settings.memory()..highRefreshRate = high;
  final c = GameController(settings: settings, audio: AudioService(enabled: false))..start(GameMode.relaxed);
  var t = Duration.zero;
  c.tick(t);
  final before = c.frame.value;
  for (var i = 0; i < 120; i++) {
    final step = frameSeconds + (i.isEven ? -jitter : jitter);
    t += Duration(microseconds: (step * 1e6).round());
    c.tick(t);
  }
  return c.frame.value - before;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('60 Hz with vsync jitter repaints every frame', () {
    expect(_paints(1 / 60, jitter: 0.0008), 120);
  });

  test('120 Hz repaints at 60 fps', () {
    expect(_paints(1 / 120), inInclusiveRange(58, 62));
  });

  test('high frame rate draws every frame at 120 and 165 Hz', () {
    expect(_paints(1 / 120, high: true), 120);
    expect(_paints(1 / 165, high: true), 120);
  });
}
