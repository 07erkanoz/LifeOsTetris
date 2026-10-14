import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/scoring.dart';
import '../l10n/strings.dart';

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
  bool _showButtons = true;
  double _buttonOpacity = 0.9;
  bool _fullScreen = true;
  double _vibrationStrength = 0.5;
  final Map<GameMode, int> _best = {for (final m in GameMode.values) m: 0};
  int _gamesPlayed = 0;
  int _totalLines = 0;
  int _totalSeconds = 0;
  int? _lastTrack;
  int _blocksBest = 0;
  final Map<int, int> _blockStars = {};

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
      s._showButtons = prefs.getBool('showButtons') ?? true;
      s._buttonOpacity = prefs.getDouble('buttonOpacity') ?? 0.9;
      s._fullScreen = prefs.getBool('fullScreen') ?? true;
      s._vibrationStrength = prefs.getDouble('vibrationStrength') ?? 0.5;
      for (final m in GameMode.values) {
        s._best[m] = prefs.getInt('best_${m.name}') ?? 0;
      }
      // Scores from the first test builds were stored without a mode.
      final legacy = prefs.getInt('bestScore');
      if (legacy != null && legacy > s._best[GameMode.classic]!) s._best[GameMode.classic] = legacy;
      s._lastTrack = prefs.getInt('lastTrack');
      s._blocksBest = prefs.getInt('blocksBest') ?? 0;
      for (final entry in (prefs.getString('blockStars') ?? '').split(',')) {
        final parts = entry.split(':');
        if (parts.length != 2) continue;
        final level = int.tryParse(parts[0]), stars = int.tryParse(parts[1]);
        if (level != null && stars != null) s._blockStars[level] = stars;
      }
      s._gamesPlayed = prefs.getInt('gamesPlayed') ?? 0;
      s._totalLines = prefs.getInt('totalLines') ?? 0;
      s._totalSeconds = prefs.getInt('totalSeconds') ?? 0;
    }
    return s;
  }

  /// In-memory settings, used by tests.
  factory Settings.memory() => Settings._(null);

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get music => _music;
  double get musicVolume => _musicVolume;
  bool get sfx => _sfx;
  bool get effects => _effects;
  bool get shake => _shake;
  bool get vibration => _vibration;
  bool get showButtons => _showButtons;
  double get buttonOpacity => _buttonOpacity;

  /// Desktop: borderless full screen (Windows), on by default.
  bool get fullScreen => _fullScreen;

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
    _set(
      () => _blockStars[level] = stars,
      () => _prefs?.setString('blockStars', _blockStars.entries.map((e) => '${e.key}:${e.value}').join(',')),
    );
  }

  /// Records a finished Bulmaca Küpler game for the lifetime stats. Returns
  /// true when an endless [score] is a new best.
  bool recordBlocksGame({required bool endless, required int score, required int lines, required double seconds}) {
    final record = endless && score > _blocksBest;
    _set(
      () {
        if (record) _blocksBest = score;
        _gamesPlayed++;
        _totalLines += lines;
        _totalSeconds += seconds.round();
      },
      () {
        if (record) _prefs?.setInt('blocksBest', score);
        _prefs?.setInt('gamesPlayed', _gamesPlayed);
        _prefs?.setInt('totalLines', _totalLines);
        _prefs?.setInt('totalSeconds', _totalSeconds);
      },
    );
    return record;
  }

  /// Highest score across all modes.
  int get topScore => _best.values.fold(_blocksBest, (a, b) => a > b ? a : b);

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
  set vibrationStrength(double v) => _set(() => _vibrationStrength = v, () => _prefs?.setDouble('vibrationStrength', v));
  set fullScreen(bool v) => _set(() => _fullScreen = v, () => _prefs?.setBool('fullScreen', v));

  /// Records a finished game. Returns true when [score] is a new best for
  /// [mode].
  bool recordGame({required GameMode mode, required int score, required int lines, required double seconds}) {
    final record = score > _best[mode]!;
    _set(
      () {
        if (record) _best[mode] = score;
        _gamesPlayed++;
        _totalLines += lines;
        _totalSeconds += seconds.round();
      },
      () {
        if (record) _prefs?.setInt('best_${mode.name}', score);
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
