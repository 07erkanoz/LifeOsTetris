import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/chain/chain_game.dart';
import '../core/rewards.dart';
import '../core/sugar/sugar_game.dart' show SugarColor;
import '../core/sugar/sugar_levels.dart';
import '../core/tower/tower_game.dart';
import '../core/tower/tower_landmarks.dart';
import '../core/scoring.dart';
import '../game/play_history.dart';
import '../l10n/strings.dart';
import '../theme/palette.dart';
import 'score_board.dart';

export 'score_board.dart' show ScoreEntry;

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
  bool _homeTourSeen = false;
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
  String? _savedChain;

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
  final Map<int, int> _missionStars = {};
  final Map<int, int> _puzzleStars = {};
  final Map<int, int> _rivalWins = {};
  final Map<TowerMode, int> _towerBest = {};
  int _towerTotal = 0;
  int _towerLandmarks = 0;
  String _towerLook = 'lokum';
  String? _towerDay;
  int _towerDayTries = 0;
  int _towerDayBest = 0;
  ChainDifficulty _chainDifficulty = ChainDifficulty.easy;
  final Map<int, int> _blockStars = {};
  final Map<int, int> _adventureStars = {};
  final Map<int, int> _sugarStars = {};
  final Map<int, int> _sugarBest = {};
  final Map<SugarBooster, int> _sugarBoosters = {for (final b in SugarBooster.values) b: b.starting};
  String? _savedSugar;
  String? _lokumOutfit;
  final Set<int> _storiesSeen = {};
  int _giftDay = 0;
  int _giftWeeks = 0;
  String? _giftLast;
  int _jarCount = 0;
  int _jarFills = 0;
  int _chestsOpened = 0;
  int _eventWeek = -1;
  String? _eventName;
  int _dayPeriod = -1;
  int _dayCount = 0;
  int _dayClaimed = 0;
  int _eventCount = 0;
  int _eventClaimed = 0;
  final Set<String> _unlocks = {};
  final Set<int> _cards = {};
  int _setsClaimed = 0;
  int _chainFreezes = 0;
  String? _chainCubes;
  String? _sugarScene;
  PlayHistory _history = PlayHistory();
  ScoreBoard _board = ScoreBoard();
  int _lastPlace = 0;
  LineMemory _lineMemory = LineMemory();

  /// The time used for play history; tests may move it.
  DateTime Function() clock = DateTime.now;

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
      s._homeTourSeen = prefs.getBool('homeTourSeen') ?? false;
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
      s._savedChain = prefs.getString('savedChain');
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
      _readStars(prefs.getString('missionStars'), s._missionStars);
      _readStars(prefs.getString('puzzleStars'), s._puzzleStars);
      _readStars(prefs.getString('rivalWins'), s._rivalWins);
      for (final m in TowerMode.values) {
        final best = prefs.getInt('towerBest_${m.name}');
        if (best != null) s._towerBest[m] = best;
      }
      s._towerTotal = prefs.getInt('towerTotal') ?? 0;
      s._towerLandmarks = prefs.getInt('towerLandmarks') ?? 0;
      s._towerLook = prefs.getString('towerLook') ?? 'lokum';
      s._towerDay = prefs.getString('towerDay');
      s._towerDayTries = prefs.getInt('towerDayTries') ?? 0;
      s._towerDayBest = prefs.getInt('towerDayBest') ?? 0;
      _readStars(prefs.getString('blockStars'), s._blockStars);
      _readStars(prefs.getString('adventureStars'), s._adventureStars);
      _readStars(prefs.getString('sugarStars'), s._sugarStars);
      _readStars(prefs.getString('sugarBest'), s._sugarBest);
      for (final b in SugarBooster.values) {
        s._sugarBoosters[b] = prefs.getInt('sugarBooster_${b.name}') ?? b.starting;
      }
      s._savedSugar = prefs.getString('savedSugar');
      s._lokumOutfit = prefs.getString('lokumOutfit');
      s._storiesSeen.addAll((prefs.getString('storiesSeen') ?? '').split(',').map(int.tryParse).whereType<int>());
      s._giftDay = prefs.getInt('giftDay') ?? 0;
      s._giftWeeks = prefs.getInt('giftWeeks') ?? 0;
      s._giftLast = prefs.getString('giftLast');
      s._jarCount = prefs.getInt('jarCount') ?? 0;
      s._jarFills = prefs.getInt('jarFills') ?? 0;
      s._chestsOpened = prefs.getInt('chestsOpened') ?? 0;
      s._eventWeek = prefs.getInt('eventWeek') ?? -1;
      s._eventName = prefs.getString('eventName');
      s._dayPeriod = prefs.getInt('dayEventPeriod') ?? -1;
      s._dayCount = prefs.getInt('dayEventCount') ?? 0;
      s._dayClaimed = prefs.getInt('dayEventClaimed') ?? 0;
      s._eventCount = prefs.getInt('eventCount') ?? 0;
      s._eventClaimed = prefs.getInt('eventClaimed') ?? 0;
      s._unlocks.addAll(prefs.getStringList('unlocks') ?? const []);
      s._cards.addAll((prefs.getStringList('cards') ?? const []).map(int.tryParse).whereType<int>());
      s._setsClaimed = prefs.getInt('setsClaimed') ?? 0;
      s._chainFreezes = prefs.getInt('chainFreezes') ?? 0;
      s._chainCubes = prefs.getString('chainCubes');
      s._sugarScene = prefs.getString('sugarScene');
      s._gamesPlayed = prefs.getInt('gamesPlayed') ?? 0;
      s._totalLines = prefs.getInt('totalLines') ?? 0;
      s._totalSeconds = prefs.getInt('totalSeconds') ?? 0;
      s._history = PlayHistory.decode(prefs.getString('playHistory'));
      s._board = ScoreBoard.decode(prefs.getString('scoreBoard'));
      s._lineMemory = LineMemory(prefs.getStringList('recentLines'));
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
    // Tests start past the home screen's one-time tour (they turn it on
    // when it is what they look at).
    s._homeTourSeen = true;
    applyVisualTheme(s._visualTheme);
    return s;
  }

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get music => _music;
  double get musicVolume => _musicVolume;
  bool get sfx => _sfx;
  bool get effects => _effects;

  /// Whether the home screen's one-time tour ("there are six games") was shown.
  bool get homeTourSeen => _homeTourSeen;
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

  /// What Lokum wears everywhere (a LokumOutfit name), or null.
  String? get lokumOutfit => _lokumOutfit;
  set lokumOutfit(String? v) => _set(() => _lokumOutfit = v, () => v == null ? _prefs?.remove('lokumOutfit') : _prefs?.setString('lokumOutfit', v));

  /// Whether the story card of Şeker Küpler chapter [chapter] was shown.
  bool storySeen(int chapter) => _storiesSeen.contains(chapter);
  void markStorySeen(int chapter) {
    if (!_storiesSeen.add(chapter)) return;
    _prefs?.setString('storiesSeen', (_storiesSeen.toList()..sort()).join(','));
  }

  // ------------------------------------------------------------- gifts --

  /// Whether gift [u] has been unlocked.
  bool unlocked(Unlock u) => _unlocks.contains(u.name);
  Set<String> get unlocks => Set.unmodifiable(_unlocks);

  /// Postcards collected for the İstanbul album.
  int get postcards => _cards.length;
  bool hasCard(int i) => _cards.contains(i);
  Set<int> get cards => Set.unmodifiable(_cards);

  /// Sets of the album complete (and so their prizes waiting), in order.
  bool setComplete(int set) => [for (var i = 0; i < Rewards.setSize; i++) set * Rewards.setSize + i].every(_cards.contains);
  bool setClaimed(int set) => _setsClaimed & (1 << set) != 0;
  int get setPrizesReady => [for (var i = 0; i < Rewards.sets; i++) i].where((i) => setComplete(i) && !setClaimed(i)).length;

  /// Takes the prize of the completed set [set].
  Gift? claimSetPrize(int set) {
    if (!setComplete(set) || setClaimed(set)) return null;
    _setsClaimed |= 1 << set;
    _prefs?.setInt('setsClaimed', _setsClaimed);
    final all = [for (var i = 0; i < Rewards.sets; i++) i].every(setClaimed);
    final gift = Rewards.setPrize(set, all: all);
    applyGift(gift);
    return gift;
  }

  /// The card handed over by the last gift (to show it), if any.
  int? lastCard;

  /// Zincir Küpler's stop-the-clock boosters.
  int get chainFreezes => _chainFreezes;
  bool useChainFreeze() {
    if (_chainFreezes <= 0) return false;
    _set(() => _chainFreezes--, () => _prefs?.setInt('chainFreezes', _chainFreezes));
    return true;
  }

  /// Zincir Küpler's cube look (a ChainCubeStyle name), or null.
  String? get chainCubes => _chainCubes;
  set chainCubes(String? v) => _set(() => _chainCubes = v, () => v == null ? _prefs?.remove('chainCubes') : _prefs?.setString('chainCubes', v));

  /// The İstanbul scene behind the Şeker board (an Unlock name), or null.
  String? get sugarScene => _sugarScene;
  set sugarScene(String? v) => _set(() => _sugarScene = v, () => v == null ? _prefs?.remove('sugarScene') : _prefs?.setString('sugarScene', v));

  /// Hands over [g]: its boosters, freezes, unlock and postcard.
  void applyGift(Gift g) {
    _set(() {
      g.boosters.forEach((b, n) => _sugarBoosters[b] = sugarBoosters(b) + n);
      _chainFreezes += g.freezes;
      final u = g.unlock;
      if (u != null) _unlocks.add(u.name);
      lastCard = null;
      final card = g.card ?? (g.postcard ? Rewards.chestCards.where((c) => !_cards.contains(c)).firstOrNull : null);
      if (card != null && _cards.add(card)) lastCard = card;
    }, () {
      for (final b in g.boosters.keys) {
        _prefs?.setInt('sugarBooster_${b.name}', sugarBoosters(b));
      }
      _prefs?.setInt('chainFreezes', _chainFreezes);
      _prefs?.setStringList('unlocks', _unlocks.toList());
      _prefs?.setStringList('cards', [for (final c in _cards) '$c']);
    });
  }

  String get _today => PlayHistory.dayKey(clock());

  /// The day of the week's calendar the next daily gift is (0-based).
  int get giftDay => _giftDay;

  /// Today's gift is waiting.
  bool get dailyGiftReady => _giftLast != _today;

  /// Today's gift, once a day. A missed day is not lost: the calendar
  /// goes on from where it was.
  Gift? claimDailyGift() {
    if (!dailyGiftReady) return null;
    final gift = Rewards.daily(_giftDay, firstWeek: _giftWeeks == 0);
    applyGift(gift);
    _giftLast = _today;
    _giftDay++;
    if (_giftDay >= Rewards.dailyDays) {
      _giftDay = 0;
      _giftWeeks++;
    }
    _prefs?.setString('giftLast', _giftLast!);
    _prefs?.setInt('giftDay', _giftDay);
    _prefs?.setInt('giftWeeks', _giftWeeks);
    notifyListeners();
    return gift;
  }

  /// Sweets in the jar, out of [jarCapacity].
  int get jarCount => _jarCount;
  int get jarCapacity => Rewards.jarCapacity(_jarFills);
  bool get jarFull => _jarCount >= jarCapacity;

  /// Empties a full jar for its gift.
  Gift? openJar() {
    if (!jarFull) return null;
    final gift = Rewards.jar(_jarFills);
    _jarCount -= jarCapacity;
    _jarFills++;
    _prefs?.setInt('jarCount', _jarCount);
    _prefs?.setInt('jarFills', _jarFills);
    applyGift(gift);
    return gift;
  }

  /// Star chests reached but not opened yet.
  int get starChestsReady => max(0, Rewards.chestsFor(totalSugarStars) - _chestsOpened);

  /// Chests opened so far.
  int get starChestsOpened => _chestsOpened;

  Gift? openStarChest() {
    if (starChestsReady <= 0) return null;
    _chestsOpened++;
    _prefs?.setInt('chestsOpened', _chestsOpened);
    final gift = Rewards.chest(_chestsOpened);
    applyGift(gift);
    return gift;
  }

  /// This week's event and the sweets popped for it. Once sweets are
  /// counted, the week's event stays the one they were counted for, whatever
  /// the rotation says. A day of the calendar (Şeker Bayramı, Hıdırellez)
  /// takes its place while it lasts, with a count of its own, so the week's
  /// is still there after it.
  WeeklyEvent? get _day {
    final e = WeeklyEvent.of(clock());
    return e.isCalendar ? e : null;
  }

  bool get _weekCurrent => _eventWeek == WeeklyEvent.weekOf(clock());
  bool get _dayCurrent => _dayPeriod == WeeklyEvent.periodOf(clock());
  WeeklyEvent get event => _day ?? (_weekCurrent ? WeeklyEvent.parse(_eventName) : null) ?? WeeklyEvent.of(clock());
  int get eventCount => _day != null ? (_dayCurrent ? _dayCount : 0) : (_weekCurrent ? _eventCount : 0);
  int get eventClaimed => _day != null ? (_dayCurrent ? _dayClaimed : 0) : (_weekCurrent ? _eventClaimed : 0);

  /// Prizes earned but not taken.
  int get eventPrizesReady => event.tiers.where((t) => eventCount >= t).length - eventClaimed;

  Gift? claimEventPrize() {
    if (eventPrizesReady <= 0) return null;
    final gift = event.prize(eventClaimed);
    if (_day != null) {
      _dayClaimed = eventClaimed + 1;
      _prefs?.setInt('dayEventClaimed', _dayClaimed);
    } else {
      _eventClaimed = eventClaimed + 1;
      _prefs?.setInt('eventClaimed', _eventClaimed);
    }
    applyGift(gift);
    return gift;
  }

  /// Sweets popped in a Şeker level: into the jar, and the event's colour
  /// into the event.
  void addSugarCandies(Map<SugarColor, int> popped) {
    final total = popped.values.fold(0, (a, b) => a + b);
    if (total == 0) return;
    final day = _day;
    if (day != null) {
      final period = WeeklyEvent.periodOf(clock());
      if (_dayPeriod != period) {
        _dayPeriod = period;
        _dayCount = 0;
        _dayClaimed = 0;
      }
    } else {
      final week = WeeklyEvent.weekOf(clock());
      if (_eventWeek != week) {
        _eventName = WeeklyEvent.of(clock()).name;
        _eventWeek = week;
        _eventCount = 0;
        _eventClaimed = 0;
      }
      _eventName ??= event.name;
    }
    final color = event.color;
    _set(() {
      _jarCount += total;
      if (day != null) {
        _dayCount += popped[color] ?? 0;
      } else {
        _eventCount += popped[color] ?? 0;
      }
    }, () {
      _prefs?.setInt('jarCount', _jarCount);
      if (day != null) {
        _prefs?.setInt('dayEventPeriod', _dayPeriod);
        _prefs?.setInt('dayEventCount', _dayCount);
        _prefs?.setInt('dayEventClaimed', _dayClaimed);
      } else {
        _prefs?.setInt('eventWeek', _eventWeek);
        _prefs?.setString('eventName', _eventName!);
        _prefs?.setInt('eventCount', _eventCount);
        _prefs?.setInt('eventClaimed', _eventClaimed);
      }
    });
  }

  /// Gifts waiting to be opened (for the badge on the gift button).
  int get giftsReady => (dailyGiftReady ? 1 : 0) + (jarFull ? 1 : 0) + starChestsReady + eventPrizesReady + setPrizesReady;

  /// A Zincir Küpler game left half way (JSON), to continue later.
  String? get savedChain => _savedChain;
  set savedChain(String? v) {
    final changed = (v == null) != (_savedChain == null);
    _savedChain = v;
    v == null ? _prefs?.remove('savedChain') : _prefs?.setString('savedChain', v);
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

  // ------------------------------------------------------- şeker küpler

  /// Stars earned on Şeker Küpler level [level] (0 = not passed yet).
  int sugarStars(int level) => _sugarStars[level] ?? 0;

  /// Best score on Şeker Küpler level [level].
  int sugarBest(int level) => _sugarBest[level] ?? 0;

  int get totalSugarStars => _sugarStars.values.fold(0, (a, b) => a + b);

  /// The level to play next: one past the highest passed (the last level
  /// stays the last).
  int get sugarLevel => min(_sugarStars.keys.fold(0, max) + 1, SugarLevels.count);

  /// Every level passed.
  bool get sugarAllDone => _sugarStars.length >= SugarLevels.count;

  int sugarBoosters(SugarBooster b) => _sugarBoosters[b] ?? 0;

  /// Spends one [b]; false when none is left.
  bool useSugarBooster(SugarBooster b) {
    final left = sugarBoosters(b);
    if (left <= 0) return false;
    _set(() => _sugarBoosters[b] = left - 1, () => _prefs?.setInt('sugarBooster_${b.name}', left - 1));
    return true;
  }

  /// A Şeker Küpler level in progress (JSON), to continue where it was left.
  String? get savedSugar => _savedSugar;
  set savedSugar(String? v) {
    final changed = (v == null) != (_savedSugar == null);
    _savedSugar = v;
    v == null ? _prefs?.remove('savedSugar') : _prefs?.setString('savedSugar', v);
    if (changed) notifyListeners();
  }

  /// Records a played Şeker Küpler level ([stars] 0 when lost). Returns the
  /// chest it opened (passing a fifth level the first time), else empty.
  Map<SugarBooster, int> recordSugarLevel(int level, {required int stars, required int score, required double seconds}) {
    final first = stars > 0 && sugarStars(level) == 0;
    final chest = first && SugarLevels.chestAt(level) ? SugarBooster.chest(level) : const <SugarBooster, int>{};
    _set(
      () {
        if (stars > sugarStars(level)) _sugarStars[level] = stars;
        if (stars > 0 && score > sugarBest(level)) _sugarBest[level] = score;
        chest.forEach((b, n) => _sugarBoosters[b] = sugarBoosters(b) + n);
        _history.markPlayed(clock());
        _gamesPlayed++;
        _totalSeconds += seconds.round();
      },
      () {
        _prefs?.setString('sugarStars', _writeStars(_sugarStars));
        _prefs?.setString('sugarBest', _writeStars(_sugarBest));
        for (final b in chest.keys) {
          _prefs?.setInt('sugarBooster_${b.name}', sugarBoosters(b));
        }
        _prefs?.setString('playHistory', _history.encode());
        _prefs?.setInt('gamesPlayed', _gamesPlayed);
        _prefs?.setInt('totalSeconds', _totalSeconds);
      },
    );
    return chest;
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
        _history.markPlayed(clock());
        _gamesPlayed++;
        _totalLines += lines;
        _totalSeconds += seconds.round();
      },
      () {
        if (record) _prefs?.setInt(bombs ? 'bombBest' : 'blocksBest', score);
        _prefs?.setString('playHistory', _history.encode());
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
        _history.markPlayed(clock());
        _gamesPlayed++;
        _totalSeconds += seconds.round();
      },
      () {
        if (record) _prefs?.setInt(key, score);
        _prefs?.setString('playHistory', _history.encode());
        _prefs?.setInt('gamesPlayed', _gamesPlayed);
        _prefs?.setInt('totalSeconds', _totalSeconds);
      },
    );
    return record;
  }

  // ------------------------------------------- zincir: missions, puzzles

  /// Stars on Vapur Hattı mission [n] (0 = not done yet).
  int missionStars(int n) => _missionStars[n] ?? 0;

  int get totalMissionStars => _missionStars.values.fold(0, (a, b) => a + b);

  /// The next mission to play: one past the highest done.
  int get nextMission => _missionStars.keys.fold(0, max) + 1;

  /// Keeps the best stars of mission [n]; true the first time it is done.
  bool recordMission(int n, int stars) {
    final first = missionStars(n) == 0;
    if (stars <= missionStars(n)) return false;
    _set(() => _missionStars[n] = stars, () => _prefs?.setString('missionStars', _writeStars(_missionStars)));
    return first;
  }

  /// Stars on Zincir puzzle [n] (0 = not solved yet).
  int puzzleStars(int n) => _puzzleStars[n] ?? 0;

  int get puzzlesSolved => _puzzleStars.length;

  void recordPuzzle(int n, int stars) {
    if (stars <= puzzleStars(n)) return;
    _set(() => _puzzleStars[n] = stars, () => _prefs?.setString('puzzleStars', _writeStars(_puzzleStars)));
  }

  /// Matches won against rival [rival] (its index).
  int rivalWins(int rival) => _rivalWins[rival] ?? 0;

  /// Counts a match won against [rival]; true for the first.
  bool recordRivalWin(int rival) {
    final first = rivalWins(rival) == 0;
    _set(() => _rivalWins[rival] = rivalWins(rival) + 1, () => _prefs?.setString('rivalWins', _writeStars(_rivalWins)));
    return first;
  }

  // ------------------------------------------------------- kule küpler

  /// Kule Küpler's highest tower in [mode], in floors.
  int towerBest(TowerMode mode) => _towerBest[mode] ?? 0;

  /// Floors laid in every Kule Küpler run: İstanbul'u İnşa Et.
  int get towerTotal => _towerTotal;

  BuildProgress get towerBuild => BuildProgress(_towerTotal);

  /// The floor look picked: lokum, or one the chests opened.
  String get towerLook => _towerLook;
  set towerLook(String v) => _set(() => _towerLook = v, () => _prefs?.setString('towerLook', v));

  /// Tries left at the day's tower of [now], and its best so far.
  int towerTriesLeft(DateTime now) => _towerDay == dayKey(now) ? max(0, TowerGame.dailyTries - _towerDayTries) : TowerGame.dailyTries;
  int towerDayBest(DateTime now) => _towerDay == dayKey(now) ? _towerDayBest : 0;

  /// Records a finished Kule Küpler run of [floors] floors; true for a new
  /// best. The floors go towards İstanbul'u İnşa Et.
  bool recordTowerRun({required TowerMode mode, required int floors, required double seconds}) {
    final record = floors > 0 && floors > towerBest(mode);
    final today = dayKey(clock());
    _lastPlace = floors > 0 && mode != TowerMode.daily ? _addRecord(towerRecords(mode), floors) : 0;
    _set(
      () {
        if (record) _towerBest[mode] = floors;
        _towerTotal += floors;
        if (mode == TowerMode.daily) {
          if (_towerDay != today) {
            _towerDay = today;
            _towerDayTries = 0;
            _towerDayBest = 0;
          }
          _towerDayTries++;
          _towerDayBest = max(_towerDayBest, floors);
        }
        _history.markPlayed(clock());
        _gamesPlayed++;
        _totalSeconds += seconds.round();
      },
      () {
        if (record) _prefs?.setInt('towerBest_${mode.name}', floors);
        _prefs?.setInt('towerTotal', _towerTotal);
        if (mode == TowerMode.daily) {
          _prefs?.setString('towerDay', today);
          _prefs?.setInt('towerDayTries', _towerDayTries);
          _prefs?.setInt('towerDayBest', _towerDayBest);
        }
        _prefs?.setString('playHistory', _history.encode());
        _prefs?.setInt('gamesPlayed', _gamesPlayed);
        _prefs?.setInt('totalSeconds', _totalSeconds);
      },
    );
    return record;
  }

  /// Landmarks of İstanbul'u İnşa Et finished but not yet rewarded: their
  /// prizes, given now.
  List<(Landmark, Gift)> claimLandmarks() {
    final done = towerBuild.done;
    if (done <= _towerLandmarks) return const [];
    final prizes = [for (var i = _towerLandmarks; i < done; i++) (Landmark.values[i], Rewards.landmarkPrize(i))];
    for (final (_, g) in prizes) {
      applyGift(g);
    }
    _set(() => _towerLandmarks = done, () => _prefs?.setInt('towerLandmarks', done));
    return prizes;
  }

  /// Highest score across all modes.
  int get topScore => [..._best.values, _blocksBest, _bombBest, ..._chainBest.values].fold(0, max);

  set themeMode(ThemeMode v) => _set(() => _themeMode = v, () => _prefs?.setInt('themeMode', v.index));
  set language(AppLanguage v) => _set(() => _language = v, () => _prefs?.setInt('language', v.index));
  set music(bool v) => _set(() => _music = v, () => _prefs?.setBool('music', v));
  set musicVolume(double v) => _set(() => _musicVolume = v, () => _prefs?.setDouble('musicVolume', v));
  set sfx(bool v) => _set(() => _sfx = v, () => _prefs?.setBool('sfx', v));
  set effects(bool v) => _set(() => _effects = v, () => _prefs?.setBool('effects', v));
  set homeTourSeen(bool v) => _set(() => _homeTourSeen = v, () => _prefs?.setBool('homeTourSeen', v));
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

  // ------------------------------------------------------------ records

  /// The list of [mode]'s records: points, or for timed challenges the
  /// fastest finished runs in hundredths of a second.
  static String gameRecords(GameMode mode) => 'game_${mode.name}';

  /// The list of a Kule Küpler mode's records, in floors.
  static String towerRecords(TowerMode mode) => 'tower_${mode.name}';

  /// The records of [key], best first. A best from before the lists shows
  /// as the only one until the next game.
  List<ScoreEntry> records(String key) {
    final list = _board.of(key);
    if (list.isNotEmpty) return list;
    final seed = _seedOf(key);
    return seed == null || seed <= 0 ? const [] : [ScoreEntry(seed, null)];
  }

  /// Where [value] would go on [key]'s list (1-based; 0: off the list).
  int recordPlaceFor(String key, int value) {
    if (_board.of(key).isEmpty) {
      final seed = _seedOf(key);
      if (seed != null && seed > 0) return (_lowerFirst(key) ? value < seed : value > seed) ? 1 : 2;
    }
    return _board.placeFor(key, value, lower: _lowerFirst(key));
  }

  /// The place the last game recorded took on its list (0: none).
  int get lastRecordPlace => _lastPlace;

  bool _lowerFirst(String key) => key.startsWith('game_') && GameMode.values.byName(key.substring(5)).recordsTime;

  int? _seedOf(String key) {
    if (key.startsWith('tower_')) return _towerBest[TowerMode.values.byName(key.substring(6))];
    final mode = GameMode.values.byName(key.substring(5));
    if (!mode.recordsTime) return _best[mode];
    final t = _bestTime[mode];
    return t == null ? null : (t * 100).round();
  }

  int _addRecord(String key, int value) {
    final place = _board.add(key, value, clock(), lower: _lowerFirst(key), seed: _seedOf(key));
    _prefs?.setString('scoreBoard', _board.encode());
    return place;
  }

  /// Records a finished game. Returns true when it is a new best for [mode]:
  /// the highest score, or for timed challenges the fastest [won] run.
  bool recordGame({required GameMode mode, required int score, required int lines, required double seconds, bool won = false}) {
    final bestTime = _bestTime[mode];
    final record = mode.recordsTime ? won && (bestTime == null || seconds < bestTime) : score > _best[mode]!;
    // On the list before the best moves, so an old best is kept on it.
    _lastPlace = mode.recordsTime ? (won ? _addRecord(gameRecords(mode), (seconds * 100).round()) : 0) : (score > 0 ? _addRecord(gameRecords(mode), score) : 0);
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

  // ------------------------------------------------------------ voice

  /// Recent Küpler games and the days with any game, for the in-game voice.
  PlayHistory get history => _history;

  /// Lines the voice said lately; saved with [saveLineMemory].
  LineMemory get lineMemory => _lineMemory;

  /// Adds a finished Küpler game to the history.
  void recordHistory(GameRecord record) => _set(() => _history.add(record), () => _prefs?.setString('playHistory', _history.encode()));

  /// Stores [lineMemory] without rebuilding anything.
  void saveLineMemory() => _prefs?.setStringList('recentLines', _lineMemory.recent);

  void toggleTheme(Brightness current) => themeMode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;

  void _set(void Function() apply, void Function() persist) {
    apply();
    persist();
    notifyListeners();
  }
}
