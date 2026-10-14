import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/l10n/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifeos_kupler/core/scoring.dart';
import 'package:lifeos_kupler/settings/settings.dart';

void main() {
  test('best scores are kept per mode and stats accumulate', () {
    final s = Settings.memory();
    expect(s.recordGame(mode: GameMode.classic, score: 500, lines: 4, seconds: 61), isTrue);
    expect(s.recordGame(mode: GameMode.classic, score: 300, lines: 2, seconds: 30), isFalse);
    expect(s.recordGame(mode: GameMode.relaxed, score: 400, lines: 3, seconds: 20), isTrue);
    expect(s.bestScore(GameMode.classic), 500);
    expect(s.bestScore(GameMode.relaxed), 400);
    expect(s.topScore, 500);
    expect(s.gamesPlayed, 3);
    expect(s.totalLines, 9);
    expect(s.totalSeconds, 111);
  });

  test('every choice the player makes survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await Settings.load();
    first
      ..themeMode = ThemeMode.light
      ..language = AppLanguage.en
      ..music = false
      ..musicVolume = 0.25
      ..sfx = false
      ..effects = false
      ..shake = false
      ..vibration = false
      ..vibrationStrength = 0.9
      ..showButtons = false
      ..buttonOpacity = 0.4
      ..fullScreen = false
      ..highRefreshRate = true
      ..lastTrack = 3;
    first.recordBlockLevel(1, 2);
    first.recordBlocksGame(endless: true, score: 1234, lines: 5, seconds: 60);

    final again = await Settings.load();
    expect(again.themeMode, ThemeMode.light);
    expect(again.language, AppLanguage.en);
    expect(again.music, isFalse);
    expect(again.musicVolume, 0.25);
    expect(again.sfx, isFalse);
    expect(again.effects, isFalse);
    expect(again.shake, isFalse);
    expect(again.vibration, isFalse);
    expect(again.vibrationStrength, 0.9);
    expect(again.showButtons, isFalse);
    expect(again.buttonOpacity, 0.4);
    expect(again.fullScreen, isFalse);
    expect(again.highRefreshRate, isTrue);
    expect(again.lastTrack, 3);
    expect(again.blockStars(1), 2);
    expect(again.blocksBest, 1234);
  });
}
