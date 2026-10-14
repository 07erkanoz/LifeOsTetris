import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';

void main() {
  test('shuffle plays every track before repeating and never twice in a row', () {
    final audio = AudioService(enabled: false);
    final count = AudioService.tracks.length;
    int? previous;
    for (var round = 0; round < 20; round++) {
      final seen = <int>{};
      for (var i = 0; i < count; i++) {
        final next = audio.nextTrackIndex();
        expect(next, isNot(previous));
        seen.add(next);
        previous = next;
      }
      expect(seen.length, count);
    }
  });
}
