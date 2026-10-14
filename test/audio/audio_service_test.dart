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

  test('the first track is never the one that played last time', () {
    final firsts = <int>{};
    for (var i = 0; i < 40; i++) {
      final started = <int>[];
      final audio = AudioService(enabled: false, lastTrack: 2, onTrackStarted: started.add);
      final first = audio.nextTrackIndex();
      expect(first, isNot(2));
      expect(started, [first]);
      firsts.add(first);
    }
    // Every other track gets to open the playlist.
    expect(firsts, hasLength(AudioService.tracks.length - 1));
  });
}
