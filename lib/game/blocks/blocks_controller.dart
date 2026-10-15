import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../audio/audio_service.dart';
import '../../audio/haptics.dart';
import '../../core/blocks/block_puzzle.dart';
import '../../core/blocks/level_generator.dart';
import '../../l10n/strings.dart';
import '../../settings/settings.dart';
import 'blocks_fx.dart';

enum BlocksView { menu, levels, playing }

/// Glue for "Bulmaca Küpler": game, drag and drop, effects, audio, haptics
/// and saved progress.
class BlocksController extends ChangeNotifier {
  BlocksController({required this.settings, required this.audio, Haptics? haptics}) : haptics = haptics ?? Haptics() {
    settings.addListener(_applySettings);
    _applySettings();
  }

  final Settings settings;
  final AudioService audio;
  final Haptics haptics;
  final BlockPuzzleGame game = BlockPuzzleGame();
  final BlocksFx fx = BlocksFx();

  /// Ticks for the board painters; the controller itself only notifies when
  /// HUD values change.
  final ValueNotifier<int> frame = ValueNotifier(0);
  final ValueNotifier<int> backgroundFrame = ValueNotifier(0);

  BlocksView view = BlocksView.menu;
  bool paused = false;
  BlockLevel? level;

  /// Day of the daily puzzle being played (null for levels and endless).
  DateTime? dailyDay;
  bool get isDaily => dailyDay != null;

  /// Today's date; tests may move it.
  DateTime Function() today = DateTime.now;
  int lastStars = 0;
  bool newRecord = false;
  double playTime = 0;
  double _endAge = -1;

  AppStrings _strings = AppStrings.tr;
  AppStrings get strings => _strings;
  set strings(AppStrings value) {
    _strings = value;
    fx.strings = value;
  }

  void _applySettings() {
    fx.particlesEnabled = settings.effects;
    fx.shakeEnabled = settings.shake;
    audio.sfxOn = settings.sfx;
    audio.musicOn = settings.music;
    audio.musicVolume = settings.musicVolume;
    haptics.strength = settings.vibrationStrength;
  }

  bool get isEndless => level == null;

  /// The result card waits a moment so the last blast can play out.
  bool get showResult => view == BlocksView.playing && game.isOver && _endAge > (game.status == BlockStatus.won ? 1.6 : 1.1);

  // ------------------------------------------------------------ navigation

  void openLevels() {
    view = BlocksView.levels;
    paused = false;
    audio.play(Sfx.click);
    notifyListeners();
  }

  void openMenu() {
    saveProgress();
    view = BlocksView.menu;
    paused = false;
    cancelDrag();
    fx.reset();
    audio.duck = 1;
    notifyListeners();
  }

  void startEndless() {
    dailyDay = null;
    level = null;
    _begin(() {
      game.startEndless();
      if (demo) {
        game.debugSetBoard(['......ZT', '.....ZZT', '.....Z.T', 'Z.....ZT', 'ZZ....ZT', 'I.....ZT', 'JJJJJJ..', 'LL*LLL..']);
        game.debugSetTray(['o2', 'i3h', 't1']);
      }
    });
  }

  /// Plays level [number] on a freshly generated board.
  void startLevel(int number) {
    dailyDay = null;
    final n = number.clamp(1, BlockLevels.count);
    final next = BlockLevels.generate(n);
    level = next;
    _begin(() => game.startLevel(next));
  }

  /// The same board again.
  void retryLevel() {
    final current = level;
    if (current == null) return startEndless();
    _begin(() => game.startLevel(current));
  }

  void nextLevel() => startLevel(min((level?.number ?? 0) + 1, BlockLevels.count));

  /// Replays the current mode: same level number on a new board, or a new
  /// endless game.
  void restart() => isDaily ? startDaily() : (isEndless ? startEndless() : startLevel(level!.number));

  /// Today's daily puzzle: the same board and pieces for every player,
  /// built from the date. It gets harder through the week.
  void startDaily() {
    final now = today();
    final day = DateTime(now.year, now.month, now.day);
    final next = dailyLevel(day);
    level = next;
    _begin(() {
      dailyDay = day;
      game.startLevel(next, random: Random(dailySeed(day)));
    });
  }

  static int dailySeed(DateTime day) => day.year * 10000 + day.month * 100 + day.day;

  /// Monday plays like level 15, Sunday like level 65.
  static BlockLevel dailyLevel(DateTime day) =>
      BlockLevels.generate(const [15, 22, 30, 38, 45, 55, 65][day.weekday - 1], random: Random(dailySeed(day)));

  // ------------------------------------------------------------ saving

  /// Saves a game in progress so it can be continued later (also after the
  /// app is closed). Bulmaca is turn based, so every placement saves.
  void saveProgress() {
    if (demo || view != BlocksView.playing || game.status != BlockStatus.playing) return;
    settings.savedBlocks = jsonEncode({
      'game': game.toSave(),
      'playTime': playTime,
      if (dailyDay != null) 'daily': dailyDay!.toIso8601String(),
    });
  }

  String? _summaryOf;
  ({int? level, int movesLeft, int score, bool daily})? _summary;

  /// Level (null for endless), moves left and score of the saved game.
  ({int? level, int movesLeft, int score, bool daily})? get savedSummary {
    final raw = settings.savedBlocks;
    if (raw == null) return null;
    if (raw != _summaryOf) {
      _summaryOf = raw;
      try {
        final data = jsonDecode(raw) as Map;
        final g = data['game'] as Map;
        final lv = g['level'] as Map?;
        final moves = g['moves'] as int;
        _summary = (
          level: lv?['number'] as int?,
          movesLeft: lv == null ? 0 : max(0, (lv['moveLimit'] as int) - moves),
          score: g['score'] as int,
          daily: data['daily'] != null,
        );
      } catch (_) {
        _summary = null;
      }
    }
    return _summary;
  }

  /// Continues the saved game.
  bool resume() {
    final raw = settings.savedBlocks;
    if (raw == null) return false;
    final data = jsonDecode(raw);
    _begin(() {
      try {
        game.restore(((data as Map)['game']! as Map).cast<String, Object?>());
        playTime = (data['playTime'] as num?)?.toDouble() ?? 0;
      } catch (e) {
        debugPrint('Saved puzzle unreadable: $e');
        settings.savedBlocks = null;
        game.startEndless();
      }
      level = game.level;
      final daily = (data as Map)['daily'] as String?;
      dailyDay = daily == null ? null : DateTime.tryParse(daily);
    }, keepSave: true);
    return true;
  }

  void _begin(void Function() start, {bool keepSave = false}) {
    if (!keepSave) settings.savedBlocks = null;
    view = BlocksView.playing;
    paused = false;
    newRecord = false;
    lastStars = 0;
    playTime = 0;
    _endAge = -1;
    cancelDrag();
    fx.reset();
    start();
    audio.startMusic();
    audio.duck = 1;
    audio.play(Sfx.start, volume: 0.8);
    _process(game.drainEvents());
    notifyListeners();
  }

  void togglePause() {
    if (view != BlocksView.playing || game.isOver) return;
    paused = !paused;
    cancelDrag();
    audio.duck = paused ? 0.35 : 1;
    audio.play(Sfx.click);
    notifyListeners();
  }

  void pauseIfRunning() {
    if (view == BlocksView.playing && !paused && !game.isOver) togglePause();
  }

  // ------------------------------------------------------------ frame loop

  Duration? _lastTick;
  double _sinceRepaint = 0;
  int _paintCount = 0;
  Object? _hudSnapshot;

  void tick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    final running = view == BlocksView.playing && !paused;
    if (running && !game.isOver) playTime += dt;
    if (_endAge >= 0) _endAge += dt;
    fx.update(running ? dt : 0);

    _sinceRepaint += dt;
    final interval = settings.highRefreshRate ? 0.0 : 1 / 60;
    if (!_idle && _sinceRepaint >= interval - 0.004) {
      _sinceRepaint = (_sinceRepaint - interval).clamp(0.0, 1 / 60);
      frame.value++;
      _paintCount++;
      if (_paintCount.isEven) backgroundFrame.value++;
    }
    _notifyHudIfChanged();
  }

  /// Menus, pause and finished games stop repainting to save battery.
  bool get _idle => view != BlocksView.playing || paused || (game.isOver && _endAge > 3 && !fx.busy);

  void _notifyHudIfChanged() {
    final snapshot = (
      view,
      paused,
      game.score,
      game.moves,
      game.gemsLeft,
      game.status,
      showResult,
      Object.hashAll(game.tray),
      dragSlot,
      (fx.scorePulse * 4).round(),
      (fx.gemPulse * 4).round(),
      (fx.trayAge * 10).clamp(0, 6).round(),
      playTime.floor(),
    );
    if (snapshot != _hudSnapshot) {
      _hudSnapshot = snapshot;
      notifyListeners();
    }
  }

  void _process(List<BlockEvent> events) {
    for (final e in events) {
      fx.handle(e);
      switch (e) {
        case BlocksPlaced():
          audio.play(Sfx.lock, volume: 0.9);
          if (settings.vibration) haptics.light();
        case LinesBlasted(:final lines, :final perfect, :final streak):
          audio.play(perfect ? Sfx.perfect : Sfx.values.byName('clear${min(lines, 4)}'));
          if (streak >= 2) audio.playCombo(streak - 1);
          if (settings.vibration) lines >= 3 || perfect ? haptics.celebrate() : haptics.medium();
        case TrayRefilled():
          if (game.moves > 0) audio.play(Sfx.hold, volume: 0.5);
        case LevelWon(:final stars):
          _endAge = 0;
          settings.savedBlocks = null;
          lastStars = stars;
          audio.play(Sfx.levelup);
          audio.duck = 0.5;
          if (settings.vibration) haptics.celebrate();
          isDaily ? settings.recordDaily(dailyDay!, stars) : settings.recordBlockLevel(level!.number, stars);
          settings.recordBlocksGame(endless: false, score: game.score, lines: game.lines, seconds: playTime);
        case BlocksGameOver():
          _endAge = 0;
          settings.savedBlocks = null;
          audio.play(Sfx.gameover);
          audio.duck = 0.4;
          if (settings.vibration) haptics.heavy();
          newRecord = settings.recordBlocksGame(endless: isEndless, score: game.score, lines: game.lines, seconds: playTime);
      }
    }
  }

  // ------------------------------------------------------------ drag & drop

  /// Global rectangle of the 8×8 grid, set by the board widget.
  Rect Function()? boardRect;

  int? dragSlot;

  /// Pointer position in global coordinates.
  Offset dragPointer = Offset.zero;
  bool _dragMouse = false;

  /// Where the dragged piece would land, if anywhere.
  (int, int)? target;
  List<int> targetRows = const [];
  List<int> targetColumns = const [];

  BlockShape? get dragShape => dragSlot == null ? null : game.tray[dragSlot!];

  double get boardCell => (boardRect?.call().width ?? 0) / BlockPuzzleGame.size;

  /// Top-left corner of the dragged piece in global coordinates. On touch
  /// screens it floats above the finger so the finger never hides it.
  Offset get dragTopLeft {
    final shape = dragShape;
    if (shape == null) return dragPointer;
    final c = boardCell;
    final lift = _dragMouse ? shape.height * c / 2 : shape.height * c + c * 1.1;
    return dragPointer - Offset(shape.width * c / 2, lift);
  }

  void beginDrag(int slot, Offset global, {required bool mouse}) {
    if (view != BlocksView.playing || paused || game.isOver || game.tray[slot] == null) return;
    dragSlot = slot;
    dragPointer = global;
    _dragMouse = mouse;
    _updateTarget();
    audio.play(Sfx.move, volume: 0.7);
    notifyListeners();
  }

  void updateDrag(Offset global) {
    if (dragSlot == null) return;
    dragPointer = global;
    final before = target;
    _updateTarget();
    if (target != before && target != null) audio.play(Sfx.soft, volume: 0.25);
  }

  void endDrag() {
    final slot = dragSlot;
    if (slot == null) return;
    final spot = target;
    cancelDrag();
    if (spot == null || !place(slot, spot.$1, spot.$2)) {
      audio.play(Sfx.bump, volume: 0.6);
      notifyListeners();
    }
  }

  /// Places the piece in tray [slot] at ([x], [y]) if it fits.
  bool place(int slot, int x, int y) {
    if (view != BlocksView.playing || paused || !game.place(slot, x, y)) return false;
    _process(game.drainEvents());
    saveProgress();
    notifyListeners();
    return true;
  }

  /// The pointer was taken away (e.g. by the system): the piece goes back.
  void abortDrag() {
    if (dragSlot == null) return;
    cancelDrag();
    notifyListeners();
  }

  void cancelDrag() {
    dragSlot = null;
    target = null;
    targetRows = targetColumns = const [];
  }

  void _updateTarget() {
    final shape = dragShape;
    final rect = boardRect?.call();
    if (shape == null || rect == null || rect.isEmpty) {
      target = null;
      return;
    }
    final c = rect.width / BlockPuzzleGame.size;
    final px = (dragTopLeft.dx - rect.left) / c, py = (dragTopLeft.dy - rect.top) / c;
    // Forgiving snap: the nearest free spot within about a cell.
    (int, int)? best;
    var bestDistance = 1.25;
    for (var y = py.floor() - 1; y <= py.ceil() + 1; y++) {
      for (var x = px.floor() - 1; x <= px.ceil() + 1; x++) {
        final d = sqrt(pow(x - px, 2) + pow(y - py, 2));
        if (d < bestDistance && game.canPlace(shape, x, y)) {
          best = (x, y);
          bestDistance = d;
        }
      }
    }
    target = best;
    if (best == null) {
      targetRows = targetColumns = const [];
    } else {
      final (rows, columns) = game.clearsFor(shape, best.$1, best.$2);
      targetRows = rows;
      targetColumns = columns;
    }
  }

  /// Development builds with `--dart-define=KUPLER_DEMO_BLOCKS=true` open
  /// Bulmaca Küpler right away.
  static const bool demo = bool.fromEnvironment('KUPLER_DEMO_BLOCKS');

  @override
  void dispose() {
    settings.removeListener(_applySettings);
    frame.dispose();
    backgroundFrame.dispose();
    super.dispose();
  }
}
