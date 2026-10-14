import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the timer position updater never piles up when a sound restarts quickly', (tester) async {
    var calls = 0;
    final updater = TimerPositionUpdater(
      getPosition: () async {
        calls++;
        return Duration.zero;
      },
      interval: const Duration(milliseconds: 200),
    );
    // Quick replays: overlapping stop + resume, as the sound effects do.
    for (var i = 0; i < 20; i++) {
      updater
        ..start()
        ..start()
        ..stop()
        ..start();
    }
    calls = 0;
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 5);
    updater.stop();
  });
}
