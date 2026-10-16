import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/audio/audio_service.dart';
import 'package:lifeos_kupler/core/tetris_game.dart';
import 'package:lifeos_kupler/game/game_controller.dart';
import 'package:lifeos_kupler/game/motivation.dart';
import 'package:lifeos_kupler/game/play_history.dart';
import 'package:lifeos_kupler/game/voice_notes.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:lifeos_kupler/l10n/voice_lines.dart';
import 'package:lifeos_kupler/settings/settings.dart';

const _cleared = LinesCleared(rows: [21], tSpin: TSpin.none, combo: 0, backToBack: false, perfectClear: false, points: 100);
const _quad = LinesCleared(rows: [18, 19, 20, 21], tSpin: TSpin.none, combo: 0, backToBack: false, perfectClear: false, points: 800);

GameRecord _game(GameMode mode, int score, DateTime ended, {int level = 5, double seconds = 120, bool record = false, bool won = false}) =>
    GameRecord(mode: mode, score: score, level: level, lines: 10, seconds: seconds, ended: ended, record: record, won: won);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final noon = DateTime(2026, 10, 16, 12);

  group('the line pool', () {
    test('every moment has the same wordings in Turkish and English', () {
      for (final voice in Voice.values) {
        final tr = voiceLines(AppStrings.tr)[voice]!, en = voiceLines(AppStrings.en)[voice]!;
        expect(tr, isNotEmpty, reason: voice.name);
        expect(en.length, tr.length, reason: voice.name);
        for (var i = 0; i < tr.length; i++) {
          Set<String> keys(String line) => RegExp(r'\{(\w+)\}').allMatches(line).map((m) => m.group(1)!).toSet();
          expect(keys(en[i]), keys(tr[i]), reason: '${voice.name} #$i uses the same numbers in both languages');
        }
      }
    });

    test('no line falls back on empty cheers', () {
      for (final lines in [voiceLines(AppStrings.tr), voiceLines(AppStrings.en)]) {
        for (final line in lines.values.expand((l) => l)) {
          for (final word in ['Harika', 'Tebrikler', 'Muhteşem', 'Süper', 'Awesome', 'Congrat', 'Amazing']) {
            expect(line.contains(word), isFalse, reason: line);
          }
        }
      }
    });

    test('a wording that needs a missing number is never picked', () {
      final memory = LineMemory();
      final random = Random(1);
      for (var i = 0; i < 40; i++) {
        final line = pickLine(Voice.endNewBest, memory, random, {'score': 4200});
        expect(line.text(AppStrings.tr), isNot(contains('{')));
        expect(line.text(AppStrings.en), isNot(contains('{')));
      }
    });

    test('numbers are written the way each language writes them', () {
      final line = VoiceLine(Voice.nearBest, 0, {'gap': 1240});
      expect(line.text(AppStrings.tr), contains('1.240 puan'));
      expect(line.text(AppStrings.en), contains('1,240 points'));
    });

    test('lines do not repeat until every wording was used', () {
      final memory = LineMemory();
      final count = voiceVariants(Voice.comeback);
      final picked = {for (var i = 0; i < count; i++) memory.pick('comeback', List.generate(count, (i) => i), Random(i))};
      expect(picked, hasLength(count));
    });
  });

  group('during a game', () {
    test('getting close to the record, then beating it', () {
      final game = TetrisGame()..start(seed: 1);
      final m = MotivationEngine(seed: 1)..reset(context: const VoiceContext(best: 5000));
      game.score = 4300;
      m.update(0.016, game);
      expect(m.current?.kind, Voice.nearBest);
      expect(m.current!.text(AppStrings.tr), contains('700'));
      expect(m.current!.loud, isFalse);

      game.score = 5100;
      m.update(0.016, game);
      expect(m.current?.kind, Voice.newBest, reason: 'a record replaces any line on screen');
      expect(m.current!.loud, isTrue);

      m.update(10, game);
      game.score = 5300;
      m.update(0.016, game);
      expect(m.current, isNull, reason: 'said once per game');
    });

    test('timed challenges do not talk about points', () {
      final game = TetrisGame()..start(seed: 1, mode: GameMode.sprint);
      final m = MotivationEngine(seed: 1)..reset(context: const VoiceContext(best: 5000, scores: false, average: 100));
      game.score = 4500;
      m.update(0.016, game);
      expect(m.current, isNull);
    });

    test('passing the own average', () {
      final game = TetrisGame()..start(seed: 1);
      final m = MotivationEngine(seed: 1)..reset(context: const VoiceContext(best: 20000, average: 2000));
      game.score = 2100;
      m.update(0.016, game);
      expect(m.current?.kind, Voice.aboveAverage);
    });

    test('the first quad speaks differently to new and to experienced players', () {
      final game = TetrisGame()..start(seed: 1);
      final m = MotivationEngine(seed: 1)..reset(context: const VoiceContext(novice: true));
      m.onEvent(_quad, game);
      expect(m.current?.kind, Voice.firstQuadNew);
      m.reset(context: const VoiceContext());
      m.onEvent(_quad, game);
      expect(m.current?.kind, Voice.firstQuad);
    });

    test('more quads than ever in one game', () {
      final game = TetrisGame()..start(seed: 1);
      final m = MotivationEngine(seed: 1)..reset(context: const VoiceContext(maxQuads: 2));
      for (var i = 0; i < 3; i++) {
        m.onEvent(_quad, game);
      }
      expect(m.current?.kind, Voice.quadRecord);
      expect(m.current!.text(AppStrings.tr), contains('3'));
      expect(m.quads, 3);
    });

    test('a comeback from near the top', () {
      final game = TetrisGame()..start(seed: 1);
      final m = MotivationEngine(seed: 1)..reset();
      game.debugSetBoard(List.filled(16, 'J.J.J.J.J.'));
      m.onEvent(const PieceLocked(PieceType.j, []), game);
      expect(m.peak, 16);
      game.debugSetBoard(List.filled(5, 'J.J.J.J.J.'));
      m.onEvent(_cleared, game);
      expect(m.current?.kind, Voice.comeback);
      expect(m.comebacks, 1);
    });

    test('a level past the recent ceiling', () {
      final game = TetrisGame()..start(seed: 1);
      final m = MotivationEngine(seed: 1)..reset(context: const VoiceContext(levelCeiling: 5));
      m.onEvent(const LevelUp(5), game);
      expect(m.current, isNull);
      m.onEvent(const LevelUp(6), game);
      expect(m.current?.kind, Voice.levelRecord);
      expect(m.current!.line.values['level'], 6);
    });

    test('the opening line comes a moment after the start', () {
      final game = TetrisGame()..start(seed: 1);
      final m = MotivationEngine(seed: 1)..reset(context: const VoiceContext(opening: VoiceLine(Voice.openStreak, 0, {'days': 4})));
      m.update(0.5, game);
      expect(m.current, isNull);
      m.update(MotivationEngine.openingDelay, game);
      expect(m.current?.kind, Voice.openStreak);
      expect(m.current!.text(AppStrings.tr), contains('4'));
    });

    test('minor lines keep quiet for a while and have a budget', () {
      final game = TetrisGame()..start(seed: 1);
      final m = MotivationEngine(seed: 1)..reset();
      var shown = 0;
      for (var i = 0; i < 20; i++) {
        game.lines = [50, 100, 200][i % 3];
        m.onEvent(const LinesCleared(rows: [21], tSpin: TSpin.none, combo: 0, backToBack: false, perfectClear: false, points: 0), game);
        if (m.current != null && m.current!.kind == Voice.endurance) shown++;
        m.update(MotivationEngine.cooldown + 6, game);
        game.lines = 0;
        m.update(0.016, game);
      }
      expect(shown, lessThanOrEqualTo(MotivationEngine.minorBudget));
    });
  });

  group('the note after a game', () {
    VoiceLine note(GameRecord g, {int best = 0, double? bestTime, int? avg, int? today, PlayHistory? history}) => pickEndNote(
      game: g,
      history: (history ?? PlayHistory())..add(g),
      bestBefore: best,
      bestTimeBefore: bestTime,
      averageBefore: avg,
      todayBestBefore: today,
      memory: LineMemory(),
      random: Random(1),
    );

    test('a record, with the old one when there was one', () {
      final line = note(_game(GameMode.classic, 9000, noon, record: true), best: 7000);
      expect(line.voice, Voice.endNewBest);
      expect(line.text(AppStrings.tr), isNot(contains('{')));
    });

    test('just short of the record', () {
      final line = note(_game(GameMode.classic, 6500, noon), best: 7000);
      expect(line.voice, Voice.endNearMiss);
    });

    test('above the own average, or the best of today', () {
      expect(note(_game(GameMode.classic, 3000, noon), best: 9000, avg: 2000).voice, Voice.endAboveAverage);
      expect(note(_game(GameMode.classic, 1500, noon), best: 9000, avg: 2000, today: 1200).voice, Voice.endBestToday);
    });

    test('a quick loss is a warm-up, a long one an honest loss', () {
      expect(note(_game(GameMode.classic, 200, noon, seconds: 20), best: 9000).voice, Voice.endQuick);
      expect(note(_game(GameMode.classic, 200, noon, seconds: 200, level: 9), best: 9000).voice, Voice.endLoss);
    });

    test('the same wall again', () {
      final history = PlayHistory([for (var i = 0; i < 4; i++) _game(GameMode.classic, 1000, noon, level: 6)]);
      final line = note(_game(GameMode.classic, 1000, noon, level: 6), best: 9000, history: history);
      expect(line.voice, Voice.endWall);
      expect(line.text(AppStrings.tr), contains('6. seviye'));
    });

    test('timed challenges talk about time', () {
      expect(note(_game(GameMode.sprint, 0, noon, seconds: 80, won: true, record: true)).voice, Voice.endTimedFirst);
      expect(note(_game(GameMode.sprint, 0, noon, seconds: 80, won: true, record: true), bestTime: 90).voice, Voice.endTimedRecord);
      final slower = note(_game(GameMode.sprint, 0, noon, seconds: 92.5, won: true), bestTime: 90);
      expect(slower.voice, Voice.endTimedSlower);
      expect(slower.text(AppStrings.tr), contains('2,5 saniye'));
      expect(note(_game(GameMode.sprint, 0, noon, seconds: 60)).voice, Voice.endTimedFail);
    });
  });

  group('the main menu note', () {
    VoiceLine? home(PlayHistory history, DateTime now, {int best = 0}) =>
        pickHomeNote(history: history, bestOf: (_) => best, now: now, memory: LineMemory(), random: Random(1));

    test('a first-time player gets the tagline', () {
      expect(home(PlayHistory(), noon), isNull);
    });

    test('back after a few days', () {
      final history = PlayHistory()..add(_game(GameMode.classic, 500, noon.subtract(const Duration(days: 5))));
      expect(home(history, noon)?.voice, Voice.homeBack);
    });

    test('a run of days', () {
      final history = PlayHistory()
        ..add(_game(GameMode.classic, 500, noon.subtract(const Duration(days: 2))))
        ..add(_game(GameMode.classic, 600, noon.subtract(const Duration(days: 1))))
        ..add(_game(GameMode.classic, 700, noon.subtract(const Duration(hours: 1))));
      final line = home(history, noon, best: 99999)!;
      expect(line.voice, Voice.homeStreak);
      expect(line.text(AppStrings.tr), contains('3'));
    });
  });

  group('play history', () {
    test('streaks, caps and a round trip through text', () {
      final history = PlayHistory();
      for (var i = 0; i < PlayHistory.keepGames + 5; i++) {
        history.add(_game(GameMode.classic, i, noon.subtract(Duration(days: i ~/ 10))));
      }
      expect(history.games, hasLength(PlayHistory.keepGames));
      expect(history.streak(noon), 5);
      final again = PlayHistory.decode(history.encode());
      expect(again.games.map((g) => g.score), history.games.map((g) => g.score));
      expect(again.streak(noon), 5);
      expect(PlayHistory.decode('not json').games, isEmpty);
    });

    test('growth compares the last five games with the five before', () {
      final history = PlayHistory([
        for (var i = 0; i < 5; i++) _game(GameMode.classic, 1000, noon),
        for (var i = 0; i < 5; i++) _game(GameMode.classic, 1300, noon),
      ]);
      expect(history.growthPercent(GameMode.classic), 30);
    });
  });

  test('a finished game is remembered and gets a note; the menu then has one too', () {
    // Morning: the menu has a line even after a pointless first game.
    final settings = Settings.memory()..clock = () => DateTime(2026, 10, 16, 8);
    final c = GameController(settings: settings, audio: AudioService(enabled: false));
    c.start(GameMode.classic);
    c.game.debugSetBoard(List.filled(TetrisGame.visibleHeight, 'J.J.J.J.J.'));
    var t = Duration.zero;
    for (var i = 0; i < 120 && c.game.status != GameStatus.over; i++) {
      t += const Duration(milliseconds: 16);
      c.hardDrop();
      c.tick(t);
    }
    // The first tick only starts the clock; one more handles the events.
    c.tick(t + const Duration(milliseconds: 16));
    expect(c.game.status, GameStatus.over);
    expect(settings.history.games, hasLength(1));
    expect(c.endNote, isNotNull);
    expect(c.endNote!.text(AppStrings.tr), isNot(contains('{')));
    expect(c.homeNote?.voice, Voice.homeMorning);
  });

  test('clear labels avoid trademarked names', () {
    expect(AppStrings.tr.clearLabel(4, TSpin.none), 'DÖRTLÜ!');
    expect(AppStrings.en.clearLabel(4, TSpin.none), 'QUAD!');
    expect(AppStrings.en.clearLabel(2, TSpin.full), 'T-SPIN DOUBLE!');
    expect(AppStrings.en.score(12480), '12,480');
    expect(AppStrings.tr.score(12480), '12.480');
  });
}
