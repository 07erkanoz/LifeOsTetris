import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/chain/chain_game.dart';
import '../core/scoring.dart';
import '../l10n/strings.dart';
import '../theme/palette.dart';

/// User preferences, best scores and lifetime stats, persisted with
/// shared_preferences.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  final SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.dark;
  AppLanguage _language = AppLanguage.system;
  bool _music = true;
  double _musicVolume = 0.6;
  bool _sfx = true;
  bool _effects = true;
  bool _shake = true;
  bool _vibration = true;
  bool _showButtons = !_desktop;
  double _buttonOpacity = 0.9;
  bool _fullScreen = true;
  double _vibrationStrength = 0.5;
  bool _highRefreshRate = _desktop;
  VisualTheme _visualTheme = VisualTheme.initial;
  String? _lastPlay;
  String? _savedGame;
  String? _savedBlocks;

  /// Desktops draw at the monitor's rate by default; phones stay at 60 fps
  /// (cooler, longer battery) unless the player turns it on.
  static bool get _desktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
  final Map<GameMode, int> _best = {for (final m in GameMode.values) m: 0};
  final Map<GameMode, double> _bestTime = {};
  final Map<String, int> _dailyStars = {};
  int _gamesPlayed = 0;
  int _totalLines = 0;
  int _totalSeconds = 0;
  int? _lastTrack;
  int _blocksBest = 0;
  int _bombBest = 0;
  final Map<String, int> _chainBest = {};
  ChainDifficulty _chainDifficulty = ChainDifficulty.easy;
  final Map<int, int> _blockStars = {};
  final Map<int, int> _adventureStars = {};

  static Future<Settings> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    final s = Settings._(prefs);
    if (prefs != null) {
      s._themeMode = ThemeMode.values[(prefs.getInt('themeMode') ?? ThemeMode.dark.index).clamp(0, 2)];
      s._language = AppLanguage.values[(prefs.getInt('language') ?? 0).clamp(0, AppLanguage.values.length - 1)];
      s._music = prefs.getBool('music') ?? true;
      s._musicVolume = prefs.getDouble('musicVolume') ?? 0.6;
      s._sfx = prefs.getBool('sfx') ?? true;
      s._effects = prefs.getBool('effects') ?? true;
      s._shake = prefs.getBool('shake') ?? true;
      s._vibration = prefs.getBool('vibration') ?? true;
      // Desktops play with the keyboard: on-screen buttons start off there.
      s._showButtons = prefs.getBool('showButtons') ?? !_desktop;
      s._buttonOpacity = prefs.getDouble('buttonOpacity') ?? 0.9;
      s._fullScreen = prefs.getBool('fullScreen') ?? true;
      s._vibrationStrength = prefs.getDouble('vibrationStrength') ?? 0.5;
      s._highRefreshRate = prefs.getBool('highRefreshRate') ?? _desktop;
      s._visualTheme = VisualTheme.parse(prefs.getString('visualTheme'));
      s._lastPlay = prefs.getString('lastPlay');
      s._savedGame = prefs.getString('savedGame');
      s._savedBlocks = prefs.getString('savedBlocks');
      for (final m in GameMode.values) {
        s._best[m] = prefs.getInt('best_${m.name}') ?? 0;
        final time = prefs.getDouble('bestTime_${m.name}');
        if (time != null) s._bestTime[m] = time;
      }
      for (final entry in (prefs.getString('dailyStars') ?? '').split(',')) {
        final parts = entry.split(':');
        final stars = parts.length == 2 ? int.tryParse(parts[1]) : null;
        if (stars != null) s._dailyStars[parts[0]] = stars;
      }
      // Scores from the first test builds were stored without a mode.
      final legacy = prefs.getInt('bestScore');
      if (legacy != null && legacy > s._best[GameMode.classic]!) s._best[GameMode.classic] = legacy;
      s._lastTrack = prefs.getInt('lastTrack');
      s._blocksBest = prefs.getInt('blocksBest') ?? 0;
      s._bombBest = prefs.getInt('bombBest') ?? 0;
      for (final m in ChainMode.values) {
        for (final d in ChainDifficulty.values) {
          final best = prefs.getInt(_chainKey(m, d));
          if (best != null) s._chainBest[_chainKey(m, d)] = best;
        }
      }
      s._chainDifficulty = ChainDifficulty.parse(prefs.getString('chainDifficulty'));
      _readStars(prefs.getString('blockStars'), s._blockStars);
      _readStars(prefs.getString('adventureStars'), s._adventureStars);
      s._gamesPlayed = prefs.getInt('gamesPlayed') ?? 0;
      s._totalLines = prefs.getInt('totalLines') ?? 0;
      s._totalSeconds = prefs.getInt('totalSeconds') ?? 0;
    }
    applyVisualTheme(s._visualTheme);
    return s;
  }

  /// Parses "level:stars,level:stars" into [into].
  static void _readStars(String? raw, Map<int, int> into) {
    for (final entry in (raw ?? '').split(',')) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final level = int.tryParse(parts[0]), stars = int.tryParse(parts[1]);
      if (level != null && stars != null) into[level] = stars;
    }
  }

  static String _writeStars(Map<int, int> stars) => stars.entries.map((e) => '${e.key}:${e.value}').join(',');

  /// In-memory settings, used by tests.
  factory Settings.memory() {
    final s = Settings._(null);
    applyVisualTheme(s._visualTheme);
    return s;
  }

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get music => _music;
  double get musicVolume => _musicVolume;
  bool get sfx => _sfx;
  bool get effects => _effects;
  bool get shake => _shake;
  bool get vibration => _vibration;
  bool get showButtons => _showButtons;

  /// The look of the game (blocks, cards, keys, icons and type).
  VisualTheme get visualTheme => _visualTheme;

  /// Mode the big play button starts (a name from the home menu's list).
  String? get lastPlay => _lastPlay;
  set lastPlay(String? v) => _set(() => _lastPlay = v, () => v == null ? _prefs?.remove('lastPlay') : _prefs?.setString('lastPlay', v));

  /// Klasik / Süper Küpler game in progress (JSON), to continue later.
  String? get savedGame => _savedGame;

  /// Bulmaca Küpler game in progress (JSON), to continue later.
  String? get savedBlocks => _savedBlocks;

  /// Saving happens every few seconds: it writes quietly, without
  /// rebuilding listeners, unless a save appears or disappears (the menus
  /// show a continue button for it).
  set savedGame(String? v) {
    final changed = (v == null) != (_savedGame == null);
    _savedGame = v;
    v == null ? _prefs?.remove('savedGame') : _prefs?.setString('savedGame', v);
    if (changed) notifyListeners();
  }

  set savedBlocks(String? v) {
    final changed = (v == null) != (_savedBlocks == null);
    _savedBlocks = v;
    v == null ? _prefs?.remove('savedBlocks') : _prefs?.setString('savedBlocks', v);
    if (changed) notifyListeners();
  }

  double get buttonOpacity => _buttonOpacity;

  /// Desktop: borderless full screen (Windows), on by default.
  bool get fullScreen => _fullScreen;

  /// Draw at the screen's full refresh rate (120/144/165 Hz) instead of 60.
  bool get highRefreshRate => _highRefreshRate;

  /// Vibration strength, 0..1.
  double get vibrationStrength => _vibrationStrength;
  int get gamesPlayed => _gamesPlayed;

  /// Music track playing when the app was last used.
  int? get lastTrack => _lastTrack;
  set lastTrack(int? v) {
    _lastTrack = v;
    if (v != null) _prefs?.setInt('lastTrack', v);
  }

  int get totalLines => _totalLines;
  int get totalSeconds => _totalSeconds;

  int bestScore(GameMode mode) => _best[mode]!;

  /// Fastest finish of a timed challenge ("Hız Koşusu", "Kazı"), if any.
  double? bestTime(GameMode mode) => _bestTime[mode];

  // ------------------------------------------------------------ daily puzzle

  /// Key of a calendar day, like "2026-10-15".
  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  /// Stars earned on the daily puzzle of [day] (0 = not solved).
  int dailyStars(DateTime day) => _dailyStars[dayKey(day)] ?? 0;

  /// Days in a row with a solved daily puzzle, counting back from [today]
  /// (or from yesterday while today's is still open).
  int dailyStreak(DateTime today) {
    var day = DateTime(today.year, today.month, today.day);
    if (dailyStars(day) == 0) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (dailyStars(day) > 0) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  /// Saves a solved daily puzzle, keeping the best star count.
  void recordDaily(DateTime day, int stars) {
    final key = dayKey(day);
    if (stars <= (_dailyStars[key] ?? 0)) return;
    _set(
      () => _dailyStars[key] = stars,
      () => _prefs?.setString('dailyStars', _dailyStars.entries.map((e) => '${e.key}:${e.value}').join(',')),
    );
  }

  // ------------------------------------------------------------ bulmaca küpler

  /// Best endless score of Bulmaca Küpler.
  int get blocksBest => _blocksBest;

  /// Stars earned on level [level] (0 = not completed yet).
  int blockStars(int level) => _blockStars[level] ?? 0;

  int get totalBlockStars => _blockStars.values.fold(0, (a, b) => a + b);

  /// Highest playable level: one past the highest completed.
  int get unlockedBlockLevel => _blockStars.keys.fold(0, (a, b) => a > b ? a : b) + 1;

  /// Saves a completed level, keeping the best star count.
  void recordBlockLevel(int level, int stars) {
    if (stars <= blockStars(level)) return;
    _set(() => _blockStars[level] = stars, () => _prefs?.setString('blockStars', _writeStars(_blockStars)));
  }

  // ------------------------------------------------------------ macera

  /// Stars earned on adventure level [level] (0 = not solved yet).
  int adventureStars(int level) => _adventureStars[level] ?? 0;

  int get totalAdventureStars => _adventureStars.values.fold(0, (a, b) => a + b);

  /// Adventure levels solved so far.
  int get adventureSolved => _adventureStars.length;

  /// Highest playable adventure level: one past the highest solved.
  int get unlockedAdventure => _adventureStars.keys.fold(0, (a, b) => a > b ? a : b) + 1;

  void recordAdventure(int level, int stars) {
    if (stars <= adventureStars(level)) return;
    _set(() => _adventureStars[level] = stars, () => _prefs?.setString('adventureStars', _writeStars(_adventureStars)));
  }

  /// Best score of "Bomba".
  int get bombBest => _bombBest;

  /// Records a finished Bulmaca Küpler game for the lifetime stats. Returns
  /// true when an endless or [bombs] [score] is a new best.
  bool recordBlocksGame({required bool endless, bool bombs = false, required int score, required int lines, required double seconds}) {
    final record = bombs ? score > _bombBest : endless && score > _blocksBest;
    _set(
      () {
        if (record) bombs ? _bombBest = score : _blocksBest = score;
        _gamesPlayed++;
        _totalLines += lines;
        _totalSeconds += seconds.round();
      },
      () {
        if (record) _prefs?.setInt(bombs ? 'bombBest' : 'blocksBest', score);
        _prefs?.setInt('gamesPlayed', _gamesPlayed);
        _prefs?.setInt('totalLines', _totalLines);
        _prefs?.setInt('totalSeconds', _totalSeconds);
      },
    );
    return record;
  }

  static String _chainKey(ChainMode mode, ChainDifficulty difficulty) => 'chainBest_${mode.name}_${difficulty.name}';

  /// Zincir Küpler's best score for [mode] at [difficulty] (0 before any).
  int chainBest(ChainMode mode, ChainDifficulty difficulty) => _chainBest[_chainKey(mode, difficulty)] ?? 0;

  /// The difficulty last picked for Zincir Küpler; easy at first.
  ChainDifficulty get chainDifficulty => _chainDifficulty;
  set chainDifficulty(ChainDifficulty v) => _set(() => _chainDifficulty = v, () => _prefs?.setString('chainDifficulty', v.name));

  /// Records a finished Zincir Küpler game. Returns true for a new best.
  bool recordChainGame({required ChainMode mode, required ChainDifficulty difficulty, required int score, required double seconds}) {
    final key = _chainKey(mode, difficulty);
    final record = score > 0 && score > (_chainBest[key] ?? 0);
    _set(
      () {
        if (record) _chainBest[key] = score;
        _gamesPlayed++;
        _totalSeconds += seconds.round();
      },
      () {
        if (record) _prefs?.setInt(key, score);
        _prefs?.setInt('gamesPlayed', _gamesPlayed);
        _prefs?.setInt('totalSeconds', _totalSeconds);
      },
    );
    return record;
  }

  /// Highest score across all modes.
  int get topScore => [..._best.values, _blocksBest, _bombBest, ..._chainBest.values].fold(0, max);

  set themeMode(ThemeMode v) => _set(() => _themeMode = v, () => _prefs?.setInt('themeMode', v.index));
  set language(AppLanguage v) => _set(() => _language = v, () => _prefs?.setInt('language', v.index));
  set music(bool v) => _set(() => _music = v, () => _prefs?.setBool('music', v));
  set musicVolume(double v) => _set(() => _musicVolume = v, () => _prefs?.setDouble('musicVolume', v));
  set sfx(bool v) => _set(() => _sfx = v, () => _prefs?.setBool('sfx', v));
  set effects(bool v) => _set(() => _effects = v, () => _prefs?.setBool('effects', v));
  set shake(bool v) => _set(() => _shake = v, () => _prefs?.setBool('shake', v));
  set vibration(bool v) => _set(() => _vibration = v, () => _prefs?.setBool('vibration', v));
  set showButtons(bool v) => _set(() => _showButtons = v, () => _prefs?.setBool('showButtons', v));
  set buttonOpacity(double v) => _set(() => _buttonOpacity = v, () => _prefs?.setDouble('buttonOpacity', v));
  set highRefreshRate(bool v) => _set(() => _highRefreshRate = v, () => _prefs?.setBool('highRefreshRate', v));
  set vibrationStrength(double v) => _set(() => _vibrationStrength = v, () => _prefs?.setDouble('vibrationStrength', v));
  set fullScreen(bool v) => _set(() => _fullScreen = v, () => _prefs?.setBool('fullScreen', v));
  set visualTheme(VisualTheme v) => _set(() {
    _visualTheme = v;
    applyVisualTheme(v);
  }, () => _prefs?.setString('visualTheme', v.name));

  /// Records a finished game. Returns true when it is a new best for [mode]:
  /// the highest score, or for timed challenges the fastest [won] run.
  bool recordGame({required GameMode mode, required int score, required int lines, required double seconds, bool won = false}) {
    final bestTime = _bestTime[mode];
    final record = mode.recordsTime ? won && (bestTime == null || seconds < bestTime) : score > _best[mode]!;
    _set(
      () {
        if (record) mode.recordsTime ? _bestTime[mode] = seconds : _best[mode] = score;
        _gamesPlayed++;
        _totalLines += lines;
        _totalSeconds += seconds.round();
      },
      () {
        if (record) mode.recordsTime ? _prefs?.setDouble('bestTime_${mode.name}', seconds) : _prefs?.setInt('best_${mode.name}', score);
        _prefs?.setInt('gamesPlayed', _gamesPlayed);
        _prefs?.setInt('totalLines', _totalLines);
        _prefs?.setInt('totalSeconds', _totalSeconds);
      },
    );
    return record;
  }

  void toggleTheme(Brightness current) => themeMode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;

  void _set(void Function() apply, void Function() persist) {
    apply();
    persist();
    notifyListeners();
  }
}
