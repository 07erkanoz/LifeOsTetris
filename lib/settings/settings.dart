import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences plus the best score, persisted with shared_preferences.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  final SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.dark;
  bool _music = true;
  double _musicVolume = 0.6;
  bool _sfx = true;
  bool _effects = true;
  bool _shake = true;
  bool _vibration = true;
  int _bestScore = 0;

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
      s._music = prefs.getBool('music') ?? true;
      s._musicVolume = prefs.getDouble('musicVolume') ?? 0.6;
      s._sfx = prefs.getBool('sfx') ?? true;
      s._effects = prefs.getBool('effects') ?? true;
      s._shake = prefs.getBool('shake') ?? true;
      s._vibration = prefs.getBool('vibration') ?? true;
      s._bestScore = prefs.getInt('bestScore') ?? 0;
    }
    return s;
  }

  /// In-memory settings, used by tests.
  factory Settings.memory() => Settings._(null);

  ThemeMode get themeMode => _themeMode;
  bool get music => _music;
  double get musicVolume => _musicVolume;
  bool get sfx => _sfx;
  bool get effects => _effects;
  bool get shake => _shake;
  bool get vibration => _vibration;
  int get bestScore => _bestScore;

  set themeMode(ThemeMode v) => _set(() => _themeMode = v, () => _prefs?.setInt('themeMode', v.index));
  set music(bool v) => _set(() => _music = v, () => _prefs?.setBool('music', v));
  set musicVolume(double v) => _set(() => _musicVolume = v, () => _prefs?.setDouble('musicVolume', v));
  set sfx(bool v) => _set(() => _sfx = v, () => _prefs?.setBool('sfx', v));
  set effects(bool v) => _set(() => _effects = v, () => _prefs?.setBool('effects', v));
  set shake(bool v) => _set(() => _shake = v, () => _prefs?.setBool('shake', v));
  set vibration(bool v) => _set(() => _vibration = v, () => _prefs?.setBool('vibration', v));

  /// Stores [score] if it beats the record. Returns true for a new record.
  bool submitScore(int score) {
    if (score <= _bestScore) return false;
    _set(() => _bestScore = score, () => _prefs?.setInt('bestScore', score));
    return true;
  }

  void toggleTheme(Brightness current) =>
      themeMode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;

  void _set(void Function() apply, void Function() persist) {
    apply();
    persist();
    notifyListeners();
  }
}
