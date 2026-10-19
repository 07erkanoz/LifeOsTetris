part of 'game_screen.dart';

// ------------------------------------------------------------ home lobby

/// The start screen: the games first. A continue bar for what was going on,
/// the showcase that slides from game to game, every game as its own tile,
/// then Lokum with a suggestion, the daily puzzle and the shortcuts. Every
/// skin dresses it its own way.
class _HomeLobby extends StatefulWidget {
  const _HomeLobby({super.key, required this.c});

  final GameController c;

  @override
  State<_HomeLobby> createState() => _HomeLobbyState();
}

class _HomeLobbyState extends State<_HomeLobby> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  /// The clocks the games' scenes run on: 52 steps a 2.6 s cycle, about 20
  /// frames a second. They are small and slow, and redrawing all of them at
  /// the screen's rate (or twice that at 120 Hz) is what made the home heavy.
  /// Each has its own phase, so they do not all redraw in the same frame:
  /// one per game for the tiles, then the showcase and the continue bars.
  late final List<_SteppedClock> _artClocks = [
    for (var i = 0; i < _Game.values.length + 2; i++)
      _SteppedClock(_clock, 52, phase: i / (_Game.values.length + 2), gate: i < _Game.values.length ? () => _turn == i : null),
  ];

  /// The games' tiles move one at a time, in their order, a cycle each;
  /// the others hold still where they stopped. Less to watch, less to draw.
  int _turn = 0;
  double _lastBeat = 0;

  void _nextTurn() {
    final v = _clock.value;
    if (v < _lastBeat) _turn = (_turn + 1) % _Game.values.length;
    _lastBeat = v;
  }
  _SteppedClock get _showcaseClock => _artClocks[_Game.values.length];
  _SteppedClock get _barClock => _artClocks[_Game.values.length + 1];
  int _tip = 0;
  double _hop = 0;
  final _showcaseKey = GlobalKey();

  GameController get c => widget.c;

  /// Whether the scenes are moving (for tests).
  @visibleForTesting
  bool get moving => _clock.isAnimating;

  @override
  void initState() {
    super.initState();
    c.settings.addListener(_syncMotion);
    _clock.addListener(_nextTurn);
    _syncMotion();
  }

  /// The scenes move only with visual effects on.
  void _syncMotion() {
    if (c.settings.effects) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
      _clock.value = 0.62;
    }
  }

  @override
  void dispose() {
    c.settings.removeListener(_syncMotion);
    for (final clock in _artClocks) {
      clock.dispose();
    }
    _clock.removeListener(_nextTurn);
    _clock.dispose();
    super.dispose();
  }

  void _nextTip(int count) {
    c.audio.play(Sfx.click, volume: 0.6);
    setState(() {
      _tip = (_tip + 1) % max(1, count);
      _hop = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final tips = _lobbyTips(c, s);
    final tip = tips[_tip % tips.length];
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    final header = _LobbyHeader(c: c);
    final lokum = _LobbyHero(
      tip: tip,
      clock: _clock,
      hop: _hop,
      onHopDone: () => _hop = 0,
      onLokum: () => _nextTip(tips.length),
      onAction: () => tip.run(context, c),
      outfit: c.settings.outfit,
      onWardrobe: () => showLokumWardrobe(context, c.settings),
    );
    final bars = _continueBars(context);
    // On a special day Lokum's greeting comes first, where it is seen at
    // once, rather than under the games.
    final greeting = tips.first.quiet;
    // The showcase: as tall as its width wants, a little less under a
    // continue bar so the six games still fit on a phone.
    // On a short phone it gives up some height so all six games fit.
    Widget showcase(double width, {bool compact = false}) =>
        _Showcase(key: _showcaseKey, c: c, clock: _showcaseClock, width: width, ratio: compact ? (bars.isEmpty ? 0.6 : 0.5) : (bars.isEmpty ? 0.83 : 0.72));
    final gamesLabel = Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    s.allGames,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.muted, fontSize: _fs(p, 13), fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${_Game.values.length}',
                  style: TextStyle(color: p.text, fontSize: _fs(p, 11), fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: TextButton(
            key: const ValueKey('change-mode'),
            onPressed: () => _openModes(context, c),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${s.allModes} ›',
                maxLines: 1,
                style: TextStyle(color: p.muted, fontSize: _fs(p, 13.5), fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
    Widget tiles(int columns, {double art = 0.42}) => LayoutBuilder(
      builder: (context, area) {
        final width = (area.maxWidth - (columns - 1) * 12) / columns;
        return GridView.count(
          key: const ValueKey('game-tiles'),
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: width / _tileHeight(p, width, textScale, art: art),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 4),
          children: [
            for (final g in _Game.values) _GameTile(game: g, c: c, clock: _artClocks[g.index], onTap: () => _hasSave(c, g) ? _resume(context, g) : _openGame(context, c, g)),
          ],
        );
      },
    );
    final daily = _LobbyDaily(
      settings: c.settings,
      onTap: () => BlocksScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, entry: BlocksEntry.daily),
    );
    final shortcuts = _shortcutRow(context, c);

    // Always the whole screen: the game is waiting behind it.
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: p.background.first)),
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: BackgroundBasePainter(p))),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 900 && box.maxHeight >= 560;
                final short = !wide && box.maxWidth > box.maxHeight && box.maxHeight < 560;
                if (wide) {
                  // Big screens get the same lobby, scaled up to fill them:
                  // the showcase and the rest on the left, the games on the
                  // right.
                  final zoom = min(box.maxWidth / 1280, box.maxHeight / 740).clamp(1.0, 1.6);
                  final inner = Size(box.maxWidth / zoom, box.maxHeight / zoom);
                  final content = min(inner.width, 1400.0) - 48;
                  final left = (content * 0.44).clamp(400.0, 580.0);
                  final columns = content - left - 28 >= 600 ? 3 : 2;
                  return SizedBox.fromSize(
                    size: box.biggest,
                    child: FittedBox(
                      alignment: Alignment.topCenter,
                      child: SizedBox.fromSize(
                        size: inner,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: left,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        header,
                                        const SizedBox(height: 14),
                                        if (greeting) ...[lokum, const SizedBox(height: 14)],
                                        ...bars,
                                        showcase(left),
                                        const SizedBox(height: 16),
                                        shortcuts,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 56),
                                        gamesLabel,
                                        const SizedBox(height: 6),
                                        tiles(columns),
                                        const SizedBox(height: 18),
                                        if (!greeting) ...[lokum, const SizedBox(height: 14)],
                                        daily,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (short) {
                  // Phones on their side: the showcase on the left, the games
                  // and the rest on the right.
                  final half = (box.maxWidth - 32 - 18) / 2;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [header, const SizedBox(height: 8), if (greeting) ...[lokum, const SizedBox(height: 8)], ...bars, showcase(half)],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [gamesLabel, tiles(2), const SizedBox(height: 14), if (!greeting) ...[lokum, const SizedBox(height: 12)], daily, const SizedBox(height: 12), shortcuts],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Phones and upright tablets: the games first, what was going
                // on after them. A tablet gets the width, three games a row.
                final tablet = box.maxWidth >= 640;
                final maxWidth = tablet ? 960.0 : 520.0;
                final width = min(box.maxWidth, maxWidth) - 32;
                final compact = !tablet && box.maxHeight < 720;
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: SingleChildScrollView(
                      key: const ValueKey('lobby-scroll'),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const SizedBox(height: 12),
                          if (greeting) ...[lokum, const SizedBox(height: 12)],
                          ...bars,
                          showcase(width, compact: compact),
                          const SizedBox(height: 6),
                          gamesLabel,
                          tiles(tablet ? 3 : 2, art: compact ? 0.3 : 0.42),
                          const SizedBox(height: 18),
                          if (greeting)
                            daily
                          else if (tablet)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: lokum),
                                const SizedBox(width: 16),
                                Expanded(child: daily),
                              ],
                            )
                          else ...[
                            lokum,
                            const SizedBox(height: 14),
                            daily,
                          ],
                          const SizedBox(height: 14),
                          shortcuts,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!c.settings.homeTourSeen)
            Positioned.fill(
              child: _HomeTour(
                target: _showcaseKey,
                onDone: () => setState(() => c.settings.homeTourSeen = true),
              ),
            ),
        ],
      ),
    );
  }

  /// Back into [game]'s game left half way.
  void _resume(BuildContext context, _Game game) {
    final settings = c.settings;
    switch (game) {
      case _Game.sugar:
        SugarScreen.open(context, settings: settings, audio: c.audio, haptics: c.haptics, level: _savedSugarLevel(settings)!, resume: true);
      case _Game.chain:
        ChainScreen.open(context, settings: settings, audio: c.audio, haptics: c.haptics, mode: _savedChainSummary(settings)!.mode, resume: true);
      case _Game.puzzle:
        BlocksScreen.open(context, settings: settings, audio: c.audio, haptics: c.haptics, entry: BlocksEntry.resume);
      case _Game.superGame || _Game.classic:
        c.resume();
      case _Game.tower:
        break;
    }
  }

  /// Right under the header: the game left half way (the last one played
  /// first, the others go back in from their tiles), or with none the last
  /// game played; nothing for a new player.
  List<Widget> _continueBars(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = c.settings;
    final saved = c.savedSummary;
    final savedPuzzle = BlocksController.summaryOf(settings.savedBlocks);
    final sugarLevel = _savedSugarLevel(settings);
    final chain = _savedChainSummary(settings);
    Widget bar(String key, _Game game, String title, String? detail, VoidCallback onTap, {bool resume = true}) => _ContinueBar(
      key: ValueKey(key),
      game: game,
      label: resume ? s.leftOffLabel : s.lastPlayedLabel,
      title: title,
      detail: detail,
      button: resume ? s.badgeContinue : s.play,
      clock: _barClock,
      onTap: onTap,
    );
    final bars = [
      if (sugarLevel != null)
        bar(
          'resume-sugar',
          _Game.sugar,
          s.sugarTitle,
          s.sugarCardLevel(sugarLevel),
          () => SugarScreen.open(context, settings: settings, audio: c.audio, haptics: c.haptics, level: sugarLevel, resume: true),
        ),
      if (chain != null)
        bar(
          'resume-chain',
          _Game.chain,
          s.chainTitle,
          '${chain.mode == ChainMode.timeAttack ? s.chainTimeTitle : s.chainEndlessTitle} · ${s.score(chain.score)}',
          () => ChainScreen.open(context, settings: settings, audio: c.audio, haptics: c.haptics, mode: chain.mode, resume: true),
        ),
      if (savedPuzzle != null)
        bar(
          'resume-puzzle',
          _Game.puzzle,
          s.puzzleTitle,
          blocksResumeSubtitle(s, savedPuzzle),
          () => BlocksScreen.open(context, settings: settings, audio: c.audio, haptics: c.haptics, entry: BlocksEntry.resume),
        ),
      if (saved != null)
        bar(
          'resume-game',
          saved.mode == GameMode.superMode ? _Game.superGame : _Game.classic,
          s.modeName(saved.mode),
          s.resumeSummary(s.modeName(saved.mode), saved.score, saved.level),
          c.resume,
        ),
    ];
    final lastPlay = settings.lastPlay;
    if (bars.isEmpty) {
      if (lastPlay == null) return const [];
      final last = _PlayMode.fromName(lastPlay);
      final record = last.record(settings, s);
      return [bar('play', _Game.of(last), last.fullTitle(s), record == null ? last.subtitle(s) : s.bestLine(record), () => _launch(context, c, last), resume: false)];
    }
    final lastGame = lastPlay == null ? null : _Game.of(_PlayMode.fromName(lastPlay));
    return [bars.firstWhere((b) => (b as _ContinueBar).game == lastGame, orElse: () => bars.first)];
  }
}

/// Pixel type is small for its size: everything on the lobby is set a third
/// larger on that skin so it stays readable.
double _fs(GamePalette p, double size) => p.skin == GameSkin.pixel ? size * 1.3 : size;

/// Strong second-line text: muted greys are too faint on the dark skins.
Color _second(GamePalette p) => p.isDark ? Color.lerp(p.muted, p.text, 0.45)! : p.muted;

/// The row of small buttons at the end of the home screen.
Widget _shortcutRow(BuildContext context, GameController c) {
  final s = AppStrings.of(context);
  return Row(
    children: [
      for (final (i, (key, icon, label, onTap)) in [
        ('open-themes', Icons.palette_rounded, s.themeLabel, () => _ThemeSheet.open(context, c.settings)),
        ('open-settings', Icons.settings_rounded, s.settingsTitle, () => _SettingsSheet.open(context, c.settings)),
        ('open-about', Icons.info_outline_rounded, s.about, () => AboutPage.open(context, c.settings)),
        // Phones leave with the system's back or home; desktops need a way out.
        if (_canQuit) ('quit-game', Icons.power_settings_new_rounded, s.quitGame, () => ServicesBinding.instance.exitApplication(ui.AppExitType.required)),
      ].indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: _ShortcutTile(key: ValueKey(key), icon: icon, label: label, onTap: onTap),
        ),
      ],
    ],
  );
}

// ------------------------------------------------------------- suggestions

/// [parent], changing only [steps] times a cycle while it runs (and
/// exactly with it while it stands still): what listens repaints at that
/// rate, not at the screen's. [phase] (0..1 of a step) moves the moments it
/// changes, so clocks with different phases change in different frames.
/// While [gate] says no, it holds still where it was.
class _SteppedClock extends Animation<double> with AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin, AnimationEagerListenerMixin {
  _SteppedClock(this.parent, this.steps, {this.phase = 0, this.gate}) {
    _value = _of(parent);
    parent.addListener(_tick);
    parent.addStatusListener(notifyStatusListeners);
  }

  final AnimationController parent;
  final int steps;
  final double phase;
  final bool Function()? gate;
  late double _value;

  double _of(AnimationController p) => p.isAnimating ? ((p.value * steps + phase).floor() - phase) / steps : p.value;

  void _tick() {
    if (parent.isAnimating && gate?.call() == false) return;
    final v = _of(parent);
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }

  @override
  double get value => _value;

  @override
  AnimationStatus get status => parent.status;

  @override
  void dispose() {
    parent.removeListener(_tick);
    parent.removeStatusListener(notifyStatusListeners);
    clearListeners();
    clearStatusListeners();
    super.dispose();
  }
}

/// Where Lokum stands on the home: on a coffee saucer, as lokum is served,
/// in the bayram sweet bowl, or on nothing at all.
enum _Stage { saucer, bowl, none }

/// What Lokum suggests: a title, a second line, a button and what it does.
class _LobbyTip {
  const _LobbyTip({
    required this.title,
    required this.line,
    required this.button,
    required this.pose,
    this.mode,
    this.daily = false,
    this.gifts = false,
    this.card,
    this.keyName = 'tip',
    this.props = const [],
    this.dressed = true,
    this.stage = _Stage.saucer,
  });

  final String title, line, button;
  final LokumPose pose;
  final _PlayMode? mode;
  final bool daily;

  /// Opens the gifts screen.
  final bool gifts;

  /// Shows this postcard.
  final int? card;
  final String keyName;

  /// What Lokum carries on a special day, and whether he wears his outfit.
  final List<LokumProp> props;
  final bool dressed;

  /// What he stands on.
  final _Stage stage;

  /// A greeting or a remembrance: nothing to press.
  bool get quiet => button.isEmpty;

  void run(BuildContext context, GameController c) {
    if (quiet) return;
    final postcard = card;
    if (postcard != null) {
      showPostcard(context, postcard);
      return;
    }
    if (gifts) {
      GiftsScreen.open(context, settings: c.settings, audio: c.audio);
      return;
    }
    if (daily) {
      BlocksScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, entry: BlocksEntry.daily);
      return;
    }
    _launch(context, c, mode ?? _PlayMode.fromName(c.settings.lastPlay));
  }
}

/// Has the player played [m] at all (a score, a star, a save)?
bool _played(Settings s, _PlayMode m) {
  if (s.lastPlay == m.name) return true;
  final game = m.gameMode;
  if (game != null) return s.bestScore(game) > 0 || s.bestTime(game) != null;
  final chain = m.chainMode;
  if (chain != null) return ChainDifficulty.values.any((d) => s.chainBest(chain, d) > 0) || _savedChainSummary(s)?.mode == chain;
  return switch (m) {
    _PlayMode.blocksLevels => s.totalBlockStars > 0,
    _PlayMode.blocksEndless => s.blocksBest > 0,
    _PlayMode.adventure => s.adventureSolved > 0,
    _PlayMode.bomb => s.bombBest > 0,
    _PlayMode.sugar => s.totalSugarStars > 0 || s.savedSugar != null,
    _PlayMode.chainMissions => s.totalMissionStars > 0,
    _PlayMode.chainPuzzles => s.puzzlesSolved > 0,
    _PlayMode.chainVersus => ChainRival.values.any((r) => s.rivalWins(r.index) > 0),
    _PlayMode.towerClimb || _PlayMode.towerWind || _PlayMode.towerDaily => s.towerBest(m.towerMode!) > 0,
    _PlayMode.towerBuild => s.towerTotal > 0,
    _ => false,
  };
}

int? _savedSugarLevel(Settings s) {
  final raw = s.savedSugar;
  if (raw == null) return null;
  try {
    return (jsonDecode(raw) as Map<String, Object?>)['level'] as int?;
  } catch (_) {
    return null;
  }
}

({ChainMode mode, int score})? _savedChainSummary(Settings s) {
  final raw = s.savedChain;
  if (raw == null) return null;
  try {
    final save = jsonDecode(raw) as Map<String, Object?>;
    return (mode: ChainMode.values.byName(save['mode'] as String), score: save['score'] as int);
  } catch (_) {
    return null;
  }
}

/// Suggestions in order of what matters most to the player right now.
List<_LobbyTip> _lobbyTips(GameController c, AppStrings s) {
  final settings = c.settings;
  final tips = <_LobbyTip>[];
  // On a national day, a bayram or 10 Kasım, Lokum greets Turkish players
  // (or remembers with them) first.
  final today = settings.clock();
  final day = s.isTurkish ? SpecialDay.of(today) : null;
  if (day != null) {
    final words = s.specialDay(day, today.year - 1923);
    tips.add(
      _LobbyTip(
        title: words.title,
        line: words.line,
        button: '',
        pose: day == SpecialDay.ataturk
            ? LokumPose.sad
            : day.solemn
            ? LokumPose.happy
            : LokumPose.cheer,
        props: day.props,
        dressed: false,
        stage: switch (day) {
          SpecialDay.ramazan || SpecialDay.kurban => _Stage.bowl,
          SpecialDay.ataturk => _Stage.none,
          _ => _Stage.saucer,
        },
        keyName: 'tip-day-${day.name}',
      ),
    );
  }
  final sugarLevel = _savedSugarLevel(settings);
  if (sugarLevel != null) {
    tips.add(
      _LobbyTip(title: s.tipLeftOff(sugarLevel), line: s.sugarTitle, button: s.tipContinue, pose: LokumPose.cheer, mode: _PlayMode.sugar, keyName: 'tip-sugar'),
    );
  }
  // Then gifts waiting to be opened.
  final waiting = settings.giftsReady;
  if (waiting > 0) {
    tips.add(
      _LobbyTip(
        title: settings.dailyGiftReady ? s.tipGift : s.tipGiftsWaiting(waiting),
        line: s.giftsShort,
        button: s.tipOpen,
        pose: LokumPose.cheer,
        gifts: true,
        keyName: 'tip-gift',
      ),
    );
  }
  final now = DateTime.now();
  if (settings.dailyStars(now) == 0) {
    tips.add(_LobbyTip(title: s.tipDaily, line: s.dailySubtitle(now), button: s.tipSolve, pose: LokumPose.happy, daily: true, keyName: 'tip-daily'));
  }
  // A bit of İstanbul history from the album, a different card each day.
  final cards = settings.cards.toList()..sort();
  if (cards.isNotEmpty) {
    final card = cards[DateTime(now.year, now.month, now.day).difference(DateTime(2020)).inDays % cards.length];
    final p = s.postcard(card);
    tips.add(_LobbyTip(title: '${s.tipDidYouKnow} ${p.title}, ${p.when}', line: p.fact, button: s.tipSeeCard, pose: LokumPose.wink, card: card, keyName: 'tip-card'));
  }
  for (final m in const [
    _PlayMode.towerClimb,
    _PlayMode.chainEndless,
    _PlayMode.sugar,
    _PlayMode.adventure,
    _PlayMode.blocksLevels,
    _PlayMode.bomb,
    _PlayMode.superMode,
    _PlayMode.sprint,
  ]) {
    if (_played(settings, m)) continue;
    tips.add(
      _LobbyTip(title: s.tipUntried, line: '${m.fullTitle(s)} · ${m.subtitle(s)}', button: s.tipTry, pose: LokumPose.wink, mode: m, keyName: 'tip-${m.name}'),
    );
    if (tips.length >= 4) break;
  }
  final event = settings.event;
  tips.add(
    _LobbyTip(
      title: s.eventName(event.name),
      line: '${s.eventGoal(event.name)} · ${s.eventDaysLeft(WeeklyEvent.daysLeft(settings.clock()))}',
      button: s.tipSee,
      pose: LokumPose.wink,
      gifts: true,
      keyName: 'tip-event',
    ),
  );
  final note = c.homeNote?.text(s);
  final last = _PlayMode.fromName(settings.lastPlay);
  tips.add(_LobbyTip(title: note ?? s.tipBeatBest, line: last.fullTitle(s), button: s.tipPlay, pose: LokumPose.happy, mode: last, keyName: 'home-note'));
  return tips;
}

// ------------------------------------------------------------------ parts

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Row(
      children: [
        const Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(fit: BoxFit.scaleDown, child: LogoTitle(fontSize: 28)),
          ),
        ),
        _GiftsButton(c: c),
        const SizedBox(width: 8),
        GlassIconButton(
          key: const ValueKey('lobby-settings'),
          icon: Icons.settings_rounded,
          tooltip: s.settingsTitle,
          onTap: () => _SettingsSheet.open(context, c.settings),
        ),
      ],
    );
  }
}

/// The gifts, with a badge for those waiting.
class _GiftsButton extends StatelessWidget {
  const _GiftsButton({required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final waiting = c.settings.giftsReady;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassIconButton(
          key: const ValueKey('gifts-open'),
          icon: Icons.card_giftcard_rounded,
          tooltip: s.giftsShort,
          onTap: () => GiftsScreen.open(context, settings: c.settings, audio: c.audio),
        ),
        if (waiting > 0)
          Positioned(
            right: -4,
            top: -4,
            child: IgnorePointer(
              child: Container(
                key: const ValueKey('gifts-badge'),
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFFF3B5C), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 2)),
                child: Text('$waiting', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, height: 1)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Lokum and his speech bubble with the suggestion and its button.
class _LobbyHero extends StatelessWidget {
  const _LobbyHero({
    required this.tip,
    required this.clock,
    required this.hop,
    required this.onHopDone,
    required this.onLokum,
    required this.onAction,
    required this.outfit,
    required this.onWardrobe,
  });

  final _LobbyTip tip;
  final Animation<double> clock;
  final double hop;
  final VoidCallback onHopDone;
  final VoidCallback onLokum;
  final VoidCallback onAction;
  final LokumOutfit outfit;
  final VoidCallback onWardrobe;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final pixel = p.skin == GameSkin.pixel;
    final neon = isNeon(p);
    final titleColor = p.text;
    final lineColor = _second(p);
    final bubble = Container(
      key: ValueKey(tip.keyName),
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      decoration: neon
          ? neonCardDecoration(radius: 20, tone: neonPink, glow: 0.5)
          : p.flat
          ? flatCardDecoration(p, radius: pixel ? 4 : 22, depth: 5)
          : BoxDecoration(
              color: p.glass,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.glassBorder, width: 1.5),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tip.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: titleColor, fontSize: _fs(p, 16.5), height: 1.15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            tip.line,
            // A greeting or a remembrance is shown whole.
            maxLines: tip.quiet ? null : 2,
            overflow: tip.quiet ? null : TextOverflow.ellipsis,
            style: TextStyle(color: lineColor, fontSize: _fs(p, 13), height: 1.2, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (!tip.quiet) _TipButton(label: tip.button, onTap: onAction),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 104,
          height: 118,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('lokum'),
                  onTap: onLokum,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('hop-${tip.keyName}'),
                    tween: Tween(begin: hop, end: 0),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOut,
                    onEnd: onHopDone,
                    // His own layer: his bob repaints him, not the whole page.
                    builder: (context, jump, _) => RepaintBoundary(
                      child: CustomPaint(
                        painter: _LokumPainter(pose: tip.pose, outfit: tip.dressed ? outfit : LokumOutfit.none, props: tip.props, stage: tip.stage, palette: p, clock: clock, jump: jump, dpr: MediaQuery.devicePixelRatioOf(context)),
                      ),
                    ),
                  ),
                ),
              ),
              // His wardrobe, a tap away (not on a special day, when he
              // goes without it).
              if (!tip.quiet) Positioned(left: -2, bottom: 0, child: _WardrobeButton(onTap: onWardrobe)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: bubble),
      ],
    );
  }
}

/// The little hanger by Lokum's feet that opens his wardrobe.
class _WardrobeButton extends StatelessWidget {
  const _WardrobeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final pixel = p.skin == GameSkin.pixel;
    final neon = isNeon(p);
    final fill = neon ? neonCyan : (pixel ? const Color(0xFFFFD23F) : Colors.white);
    return Tooltip(
      message: AppStrings.of(context).wardrobeShort,
      child: Semantics(
        button: true,
        label: AppStrings.of(context).wardrobeShort,
        child: GestureDetector(
          key: const ValueKey('wardrobe-open'),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: fill,
              shape: pixel ? BoxShape.rectangle : BoxShape.circle,
              border: Border.all(color: neon ? Colors.white : const Color(0xFFFF4FA3), width: 2),
              boxShadow: [
                if (neon) BoxShadow(color: neonCyan.withValues(alpha: 0.6), blurRadius: 10),
                if (pixel) const BoxShadow(color: Color(0xFF0A0A22), offset: Offset(2, 2)),
                if (!neon && !pixel) const BoxShadow(color: Color(0x55000000), offset: Offset(0, 2), blurRadius: 3),
              ],
            ),
            child: Icon(Icons.checkroom_rounded, size: 20, color: neon || pixel ? const Color(0xFF1B1B3A) : const Color(0xFFFF4FA3)),
          ),
        ),
      ),
    );
  }
}

/// The bubble's button: a solid, readable pill on every skin.
class _TipButton extends StatelessWidget {
  const _TipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final pixel = p.skin == GameSkin.pixel;
    final neon = isNeon(p);
    final fill = neon ? neonPink : (pixel ? const Color(0xFFFFD23F) : p.accent1);
    final ink = pixel || fill.computeLuminance() > 0.5 ? const Color(0xFF1B1B3A) : Colors.white;
    return GestureDetector(
      key: const ValueKey('tip-action'),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: pixel ? 6 : 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(pixel ? 2 : 14),
          border: neon ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5) : null,
          boxShadow: [
            if (neon) BoxShadow(color: neonPink.withValues(alpha: 0.6), blurRadius: 14),
            if (pixel) const BoxShadow(color: Color(0xFF0A0A22), offset: Offset(3, 3)),
            if (!neon && !pixel) BoxShadow(color: Color.lerp(fill, Colors.black, 0.35)!, offset: const Offset(0, 3)),
          ],
        ),
        child: Text(
          '${AppStrings.of(context).upper(label)}  ›',
          style: TextStyle(color: ink, fontSize: _fs(p, 14), fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
      ),
    );
  }
}

/// The daily puzzle, sized for the lobby (readable on the pixel skin too).
class _LobbyDaily extends StatelessWidget {
  const _LobbyDaily({required this.settings, required this.onTap});

  final Settings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final now = DateTime.now();
    final stars = settings.dailyStars(now);
    final streak = settings.dailyStreak(now);
    final done = stars > 0;
    final line = [done ? s.dailyDone : s.dailySubtitle(now), if (streak > 0) s.streakDays(streak)].join(' · ');
    final pixel = p.skin == GameSkin.pixel;
    final neon = isNeon(p);
    const green = [Color(0xFF14B8A6), Color(0xFF22C55E)];
    final ink = done ? p.text : Colors.white;
    return GestureDetector(
      key: const ValueKey('daily-puzzle'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: done
            ? (neon
                  ? neonCardDecoration(radius: 22, tone: const Color(0xFF22C55E))
                  : (p.flat ? flatCardDecoration(p, radius: pixel ? 4 : 22, depth: 5) : BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(22))))
            : p.flat
            ? flatCardDecoration(p, radius: pixel ? 4 : 22, fill: pixel ? const Color(0xFF008751) : green.first, depth: 5)
            : BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: green),
                boxShadow: [
                  BoxShadow(
                    color: green.last.withValues(alpha: neon ? 0.55 : 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
        child: Row(
          children: [
            GameIcon(Icons.calendar_today_rounded, size: _fs(p, 26), color: ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.dailyTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: _fs(p, 18), fontWeight: FontWeight.w900),
                  ),
                  Text(
                    line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink.withValues(alpha: 0.9), fontSize: _fs(p, 13), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (done) ...[
              for (var i = 0; i < 3; i++)
                GameIcon(Icons.star_rounded, size: _fs(p, 20), color: i < stars ? const Color(0xFFFACC15) : p.muted.withValues(alpha: 0.4)),
            ] else
              GameIcon(Icons.chevron_right_rounded, size: _fs(p, 28), color: ink),
          ],
        ),
      ),
    );
  }
}

const _modeTones = {
  _ModeGroup.superGroup: [Color(0xFFB45BFF), Color(0xFFFF5FB8)],
  _ModeGroup.classic: [Color(0xFF3B82F6), Color(0xFF38BDF8)],
  _ModeGroup.puzzle: [Color(0xFF14B8A6), Color(0xFF6EE7B7)],
  _ModeGroup.chain: [Color(0xFFFF33EE), Color(0xFF7C3AED)],
  _ModeGroup.sugar: [Color(0xFFFF4D8D), Color(0xFFFF9A1F)],
  _ModeGroup.challenges: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  _ModeGroup.tower: [Color(0xFFFF8FB8), Color(0xFFFFAA5E)],
};

({String? badge, List<Color> badgeColors, String line, double? progress}) _cardInfo(_PlayMode m, Settings settings, AppStrings s) {
  final tone = _modeTones[m.group]!;
  final played = _played(settings, m);
  String? badge = !played && m.isNew ? s.newBadge : null;
  var line = m.subtitle(s);
  double? progress;
  switch (m) {
    case _PlayMode.sugar:
      final saved = _savedSugarLevel(settings);
      if (saved != null) {
        badge = s.badgeContinue;
        line = s.tipLeftOff(saved);
      } else if (settings.totalSugarStars > 0) {
        line = s.starsLine(settings.totalSugarStars, SugarLevels.count * 3);
      }
      progress = (max(saved ?? 0, settings.sugarLevel) - 1) / SugarLevels.count;
    case _PlayMode.blocksLevels:
      if (settings.totalBlockStars > 0) line = s.starsLine(settings.totalBlockStars, BlockLevels.count * 3);
      progress = (settings.unlockedBlockLevel - 1) / BlockLevels.count;
    case _PlayMode.adventure:
      if (settings.totalAdventureStars > 0) line = s.starsLine(settings.totalAdventureStars, Adventure.count * 3);
      progress = settings.adventureSolved / Adventure.count;
    case _PlayMode.chainMissions:
      if (settings.totalMissionStars > 0) line = s.starsLine(settings.totalMissionStars, ChainMissions.count * 3);
      progress = settings.totalMissionStars / (ChainMissions.count * 3);
    case _PlayMode.chainPuzzles:
      final record = m.record(settings, s);
      if (record != null) line = record;
      progress = settings.puzzlesSolved / ChainPuzzles.count;
    case _PlayMode.towerClimb || _PlayMode.towerWind:
      final best = settings.towerBest(m.towerMode!);
      if (best > 0) line = s.bestLine(s.floorsLine(best));
      progress = best > 0 ? best / TowerGame.milestoneAfter(best) : null;
    case _PlayMode.towerDaily:
      final today = settings.clock();
      line = settings.towerTriesLeft(today) > 0 ? s.towerTriesLeft(settings.towerTriesLeft(today)) : s.towerNoTries;
    case _PlayMode.towerBuild:
      final build = settings.towerBuild;
      final landmark = build.current;
      if (landmark != null) {
        line = '${s.landmarkName(landmark.name)} · ${s.score(build.into(landmark))} / ${s.score(landmark.floors)}';
        progress = build.fraction(landmark);
      } else {
        line = s.towerAllDone;
        progress = 1;
      }
    default:
      final record = m.record(settings, s);
      if (record != null) line = s.bestLine(record);
      final chain = _savedChainSummary(settings);
      if (chain != null && chain.mode == m.chainMode) {
        badge = s.badgeContinue;
        line = s.score(chain.score);
      }
      if (m == _PlayMode.chainTime && record == null) line = '${s.chainTitle} · ${m.subtitle(s)}';
  }
  return (badge: badge, badgeColors: tone, line: line, progress: progress?.clamp(0.0, 1.0));
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.colors});

  final String text;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final pixel = p.skin == GameSkin.pixel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(pixel ? 2 : 12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: _fs(p, 11.5), fontWeight: FontWeight.w900, letterSpacing: 0.6),
      ),
    );
  }
}

// ------------------------------------------------------------ live scenes

enum _Scene { power, blocks, puzzle, chain, sugar, ferry, versus, chainPuzzle, relaxed, target, chaos, sprint, dig, bombs, adventure, tower, towerWind, towerBuild }

_Scene _sceneOf(_PlayMode m) => switch (m.group) {
  _ModeGroup.superGroup => _Scene.power,
  _ModeGroup.classic || _ModeGroup.challenges => _Scene.blocks,
  _ModeGroup.puzzle => _Scene.puzzle,
  _ModeGroup.chain => _Scene.chain,
  _ModeGroup.sugar => _Scene.sugar,
  _ModeGroup.tower => _Scene.tower,
};

/// The scene that shows [m] itself on a game's page, where its modes sit
/// side by side.
_Scene _modeSceneOf(_PlayMode m) => switch (m) {
  _PlayMode.chainMissions => _Scene.ferry,
  _PlayMode.chainVersus => _Scene.versus,
  _PlayMode.chainPuzzles => _Scene.chainPuzzle,
  _PlayMode.relaxed => _Scene.relaxed,
  _PlayMode.target => _Scene.target,
  _PlayMode.chaos => _Scene.chaos,
  _PlayMode.sprint || _PlayMode.ultra => _Scene.sprint,
  _PlayMode.dig => _Scene.dig,
  _PlayMode.bomb => _Scene.bombs,
  _PlayMode.adventure => _Scene.adventure,
  _PlayMode.towerWind => _Scene.towerWind,
  _PlayMode.towerBuild => _Scene.towerBuild,
  _ => _sceneOf(m),
};

class _ModeScene extends StatelessWidget {
  const _ModeScene({required this.mode, required this.clock, this.scene});

  final _PlayMode mode;
  final Animation<double> clock;

  /// Shown instead of the scene of [mode]'s game.
  final _Scene? scene;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    // Each card starts at its own point of the loop.
    final offset = (mode.index * 0.37) % 1;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 2 : 16),
        child: CustomPaint(
          painter: _ScenePainter(scene: scene ?? _sceneOf(mode), palette: p, clock: clock, offset: offset, dpr: MediaQuery.devicePixelRatioOf(context)),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.scene, required this.palette, required this.clock, required this.offset, required this.dpr}) : super(repaint: clock);

  final _Scene scene;
  final GamePalette palette;
  final Animation<double> clock;
  final double offset;
  final double dpr;

  static const _pieces = [PieceType.i, PieceType.o, PieceType.t, PieceType.s, PieceType.z, PieceType.j, PieceType.l];

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final t = (clock.value + offset) % 1;
    final p = palette;
    final sugar = scene == _Scene.sugar;
    canvas.drawRect(
      r,
      Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, sugar ? const [Color(0xFF5B1FA8), Color(0xFF3A1270)] : [p.wellTop, p.wellBottom]),
    );
    // The challenges each get a tint of their own.
    final tint = switch (scene) {
      _Scene.relaxed => const Color(0xFF22C55E),
      _Scene.target => const Color(0xFFF59E0B),
      _Scene.chaos => const Color(0xFFA855F7),
      _Scene.sprint => const Color(0xFF06B6D4),
      _Scene.dig => const Color(0xFF9CA3AF),
      _ => null,
    };
    if (tint != null) canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [tint.withValues(alpha: 0.28), tint.withValues(alpha: 0.04)]));
    switch (scene) {
      case _Scene.power || _Scene.blocks:
        _falling(canvas, r, t, power: scene == _Scene.power);
      case _Scene.puzzle:
        _puzzle(canvas, r, t);
      case _Scene.chain:
        _chain(canvas, r, t);
      case _Scene.sugar:
        _sugar(canvas, r, t);
      case _Scene.ferry:
        _ferry(canvas, r, t);
      case _Scene.versus:
        _versus(canvas, r, t);
      case _Scene.chainPuzzle:
        _chainPuzzle(canvas, r, t);
      case _Scene.relaxed || _Scene.target || _Scene.chaos || _Scene.sprint || _Scene.dig:
        _challenge(canvas, r, t);
      case _Scene.bombs || _Scene.adventure:
        _puzzleSpecial(canvas, r, t);
      case _Scene.tower || _Scene.towerWind:
        _tower(canvas, r, t);
      case _Scene.towerBuild:
        _towerBuild(canvas, r, t);
    }
  }

  /// A short lokum tower on its sky, the next floor sliding over it.
  void _tower(Canvas canvas, Rect r, double t) {
    final wind = scene == _Scene.towerWind;
    canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [towerSkyAt(wind ? 190 : 140), towerSkyAt(wind ? 120 : 30)]));
    const n = 6;
    final h = r.height / (n + 4.2);
    final u = h / 0.46;
    final a = min(u * 0.95, r.width / 3.8);
    final base = Offset(r.center.dx, r.bottom - h * 0.6);
    for (var i = 0; i < n; i++) {
      final c = base + towerU * (sin(i * 1.7) * a * 0.05) - Offset(0, (i + 1) * h);
      if (i > 0) paintFloorShadow(canvas, c, a, a, h, alpha: 0.7);
      paintTowerFloor(canvas, c, a, a, h, flavor: i, seed: i);
    }
    final top = base - Offset(0, n * h);
    final slide = sin(t * pi * 2) * (wind ? 1.3 + 0.3 * sin(t * pi * 6) : 1.2);
    final slab = top - Offset(0, h * 1.7) - towerV * (a * slide);
    paintTowerFloor(canvas, slab, a, a, h, flavor: n, seed: 9);
    if (wind) {
      final line = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = max(1.5, h * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = r.top + r.height * (0.2 + i * 0.12);
        final x = r.left + ((t + i * 0.3) % 1) * r.width;
        canvas.drawPath(
          Path()
            ..moveTo(x - r.width * 0.25, y)
            ..cubicTo(x - r.width * 0.15, y - h * 0.5, x - r.width * 0.08, y + h * 0.5, x, y),
          line,
        );
      }
    }
  }

  /// Kız Kulesi rising part by part on the Bosphorus at dusk.
  void _towerBuild(Canvas canvas, Rect r, double t) {
    canvas.save();
    canvas.translate(r.left, r.top);
    final size = r.size;
    paintDusk(canvas, Offset.zero & size);
    final horizon = size.height * 0.8;
    paintSkyline(canvas, size.width, horizon, size.height * 0.7, const Color(0xFF4A2A6A));
    paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height - horizon), ferryAt: 0.15, tower: 0);
    final k = min(size.width / 330, size.height * 0.78 / 420);
    paintLandmark(canvas, Landmark.maidens, Offset(size.width / 2, horizon + 4), k, done: 3, rising: 0.25 + 0.6 * t, time: t * 6);
    canvas.restore();
  }

  /// The Bosphorus at dusk, the ferry on its way and the piers along it.
  void _ferry(Canvas canvas, Rect r, double t) {
    canvas.save();
    canvas.translate(r.left, r.top);
    final size = r.size;
    paintDusk(canvas, Offset.zero & size);
    final horizon = size.height * 0.52;
    paintSkyline(canvas, size.width, horizon, size.height, const Color(0xFF3A1E5A));
    paintBosphorus(canvas, Rect.fromLTWH(0, horizon, size.width, size.height - horizon), ferryAt: 0.1 + 0.8 * t);
    final s = size.height / 100;
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = max(1.5, 2.2 * s)
      ..strokeCap = StrokeCap.round;
    final pts = [for (var i = 0; i < 6; i++) Offset(size.width * (0.08 + i * 0.168), size.height * (0.88 - (i.isOdd ? 0.09 : 0)))];
    for (var i = 0; i < pts.length - 1; i++) {
      for (var k = 0.0; k < 1; k += 0.2) {
        canvas.drawLine(Offset.lerp(pts[i], pts[i + 1], k)!, Offset.lerp(pts[i], pts[i + 1], k + 0.09)!, dash);
      }
    }
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, 1.8 * s)
      ..color = const Color(0xFF1A0E26);
    for (var i = 0; i < pts.length; i++) {
      if (i == 4) canvas.drawCircle(pts[i], (9 + 3 * sin(t * pi * 4)) * s, Paint()..color = const Color(0xFFFF5FB8).withValues(alpha: 0.35));
      final dot = Paint()..color = i < 4 ? const Color(0xFFFACC15) : (i == 4 ? const Color(0xFFFF5FB8) : const Color(0xFF6B5F92));
      canvas.drawCircle(pts[i], 6 * s, dot);
      canvas.drawCircle(pts[i], 6 * s, ink);
    }
    canvas.restore();
  }

  /// Two small boards, Ekşi Limon between them, a slab on its way across.
  void _versus(Canvas canvas, Rect r, double t) {
    canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF3A2160), Color(0xFF1A1030)]));
    final s = min(r.width * 0.36 / 4, r.height * 0.78 / 4).floorToDouble();
    final art = _LobbySprites.of(s, dpr, palette.skin == GameSkin.pixel);
    const colors = [ChainColor.magenta, ChainColor.blue, ChainColor.green, ChainColor.yellow, ChainColor.orange];
    for (final (side, x0) in [(0, r.left + s * 0.3), (1, r.right - s * 4.3)]) {
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          if (y == 3 && (x + side) % 3 == 0) continue;
          art.draw(canvas, art.pyramid(colors[(x * 3 + y * 2 + side) % colors.length]), Offset(x0 + x * s, r.bottom - (y + 1) * s - 2));
        }
      }
    }
    // The slab falls on the rival's board.
    final k = Curves.easeIn.transform(t);
    paintGarbageSlab(canvas, Rect.fromLTWH(r.right - s * 4.3, r.top + 2 + (r.height - 6.2 * s) * k, s * 4, s * 0.9));
    paintEksiLimon(canvas, Offset(r.center.dx, r.top + r.height * 0.4), r.height * 0.4, laugh: t > 0.5);
    paintSugarLabel(
      canvas,
      'VS',
      Offset(r.center.dx, r.bottom - r.height * 0.14),
      r.height * 0.2,
      Paint()..shader = ui.Gradient.linear(Offset(0, r.bottom - r.height * 0.24), Offset(0, r.bottom - r.height * 0.04), const [Color(0xFFFFF6B0), Color(0xFFFF8A10)]),
      outline: const Color(0xFF3A0F2A),
      stroke: 0.2,
    );
  }

  /// A set board: a glowing pair shows the swap that clears it.
  void _chainPuzzle(Canvas canvas, Rect r, double t) {
    final s = min(r.width / 6, r.height / 3.6).floorToDouble();
    final x0 = r.left + (r.width - 6 * s) / 2;
    final art = _LobbySprites.of(s, dpr, palette.skin == GameSkin.pixel);
    const rows = ['mbgyob', 'ygmyby', 'bo..gb'];
    const codes = {'y': ChainColor.yellow, 'm': ChainColor.magenta, 'b': ChainColor.blue, 'g': ChainColor.green, 'o': ChainColor.orange};
    final swap = Curves.easeInOut.transform(((t - 0.35) / 0.3).clamp(0.0, 1.0));
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < 6; x++) {
        final c = codes[rows[y][x]];
        if (c == null) continue;
        var at = Offset(x0 + x * s, r.bottom - (y + 1) * s);
        if (y == 1 && (x == 2 || x == 3)) at += Offset((x == 2 ? 1 : -1) * s * swap, 0);
        art.draw(canvas, art.pyramid(c), at);
      }
    }
    final hint = Rect.fromLTWH(x0 + 2 * s, r.bottom - 2 * s, 2 * s, s).inflate(2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hint, Radius.circular(s * 0.25)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, s * 0.09)
        ..color = const Color(0xFFFFF3A0).withValues(alpha: 0.5 + 0.5 * sin(t * pi * 6).abs()),
    );
    if (t > 0.7) paintSparkle(canvas, hint.center - Offset(0, s * 0.8), s * 0.4, const Color(0xFFFFE066), opacity: (1 - t) / 0.3);
  }

  /// A challenge's well: the stack and what makes the challenge its own.
  void _challenge(Canvas canvas, Rect r, double t) {
    // Small scenes (a row of a game's page) get bigger blocks.
    final s = (r.height / (r.height < 90 ? 4.2 : 6)).floorToDouble();
    final cols = max(4, (r.width / s).floor());
    final x0 = r.left + (r.width - cols * s) / 2;
    final sprites = BlockSprites.of(s, dpr, palette);
    final rows = switch (scene) {
      _Scene.dig => const ['gggg.ggggg', 'gg.ggggggg', 'g.ggggg.gg'],
      _Scene.sprint => const ['x...xx..x.', 'xxxxxxx.xx', 'xx.xxxxxxx'],
      _ => const ['.x...x..x.', 'xx.xxxx.xx', 'xxx.xxx.xx'],
    };
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < cols; x++) {
        final ch = rows[y][x % rows[y].length];
        if (ch == '.') continue;
        final image = ch == 'g' ? sprites.gray : sprites.block(_pieces[(x * 3 + y) % _pieces.length], BlockSprites.variantAt(x, y));
        sprites.draw(canvas, image, x0 + x * s, r.bottom - (rows.length - y) * s);
        if (scene == _Scene.target && (x * 5 + y * 3) % 7 == 1) paintGoldStar(canvas, Offset(x0 + (x + 0.5) * s, r.bottom - (rows.length - y - 0.5) * s), s * 0.3);
      }
    }
    final fall = Curves.easeIn.transform(min(1, t / 0.9));
    final y = r.top - s + (r.height - (rows.length + 1) * s) * fall;
    final mid = x0 + (cols ~/ 2 - 1) * s;
    switch (scene) {
      case _Scene.dig:
        sprites.draw(canvas, sprites.block(PieceType.drill), mid, y);
      case _Scene.chaos:
        // A piece tumbling in, and sparks.
        for (final dx in const [-1, 0, 1]) {
          sprites.draw(canvas, sprites.block(PieceType.t), mid + dx * s, y, rotation: t * pi * 2);
        }
        paintSparkle(canvas, Offset(r.left + s, r.top + s), s * 0.4, const Color(0xFFFF9AD8), opacity: (sin(t * pi * 4) + 1) / 2);
      case _Scene.sprint:
        final line = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = max(1.5, s * 0.1)
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(Offset(mid - s * (2.2 + i * 0.4), y + s * (0.2 + i * 0.3)), Offset(mid - s * 0.4, y + s * (0.2 + i * 0.3)), line);
        }
        sprites.draw(canvas, sprites.block(PieceType.i), mid, y);
      default:
        for (final (dx, dy) in const [(0, 0), (1, 0), (0, 1), (1, 1)]) {
          sprites.draw(canvas, sprites.block(PieceType.o), mid + dx * s, y + dy * s - s);
        }
    }
  }

  /// The block puzzle with a bomb ticking, or with the jewels of the
  /// adventure's picture.
  void _puzzleSpecial(Canvas canvas, Rect r, double t) {
    const n = 6;
    final s = (min(r.width, r.height) / (n + 0.6)).floorToDouble();
    final o = Offset(r.center.dx - n * s / 2, r.center.dy - n * s / 2);
    final sprites = BlockSprites.of(s, dpr, palette);
    final slot = Paint()..color = palette.text.withValues(alpha: 0.07);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(1), Radius.circular(s * 0.18)), slot);
        if (y < 2 || (x * 3 + y * 5) % 4 == 0) continue;
        final image = scene == _Scene.adventure ? sprites.jewel(x + y) : sprites.block(_pieces[(x + y) % 5 + 1]);
        sprites.draw(canvas, image, o.dx + x * s, o.dy + y * s);
      }
    }
    if (scene == _Scene.bombs) {
      sprites.draw(canvas, sprites.block(PieceType.bomb), o.dx + 3 * s, o.dy + s, scale: 1 + 0.12 * sin(t * pi * 8).abs());
    } else {
      paintSparkle(canvas, o + Offset(s * 4.5, s * 1.2), s * 0.45, const Color(0xFFFFE066), opacity: (sin(t * pi * 2) + 1) / 2);
    }
  }

  void _falling(Canvas canvas, Rect r, double t, {required bool power}) {
    final s = (r.height / 7).floorToDouble();
    final cols = max(4, (r.width / s).floor());
    final x0 = r.left + (r.width - cols * s) / 2;
    final sprites = BlockSprites.of(s, dpr, palette);
    final grid = Paint()..color = palette.text.withValues(alpha: 0.05);
    for (var x = 0; x <= cols; x++) {
      canvas.drawLine(Offset(x0 + x * s, r.top), Offset(x0 + x * s, r.bottom), grid);
    }
    final gap = cols ~/ 2 - 1;
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < cols; x++) {
        if (y == 1 && (x == gap || x == gap + 1)) continue;
        if (y == 0 && (x * 7 + 3) % 5 < 2) continue;
        sprites.draw(canvas, sprites.block(_pieces[(x * 3 + y) % _pieces.length], BlockSprites.variantAt(x, y)), x0 + x * s, r.bottom - (2 - y) * s);
      }
    }
    final py = r.top - 2 * s + (r.height + s) * Curves.easeIn.transform(min(1, t / 0.86));
    final cells = power ? const [(0, 0), (1, 0), (2, 0), (1, -1)] : const [(0, 0), (1, 0)];
    final type = power ? PieceType.t : PieceType.o;
    for (final (dx, dy) in cells) {
      final y = min(py, r.bottom - 2 * s) + dy * s;
      sprites.draw(canvas, sprites.block(type), x0 + (gap - (power ? 1 : 0) + dx) * s, y);
    }
    if (power) paintSparkle(canvas, Offset(x0 + (gap + 2.2) * s, min(py, r.bottom - 2 * s) - s * 0.9), s * 0.45, const Color(0xFFFFE066));
    if (t > 0.86) {
      final k = (t - 0.86) / 0.14;
      canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - s * 1.05, r.width, s * 1.1), Paint()..color = Colors.white.withValues(alpha: 0.7 * (1 - k)));
    }
  }

  void _puzzle(Canvas canvas, Rect r, double t) {
    const n = 6;
    final s = (min(r.width, r.height) / (n + 1.0)).floorToDouble();
    final o = Offset(r.center.dx - n * s / 2, r.center.dy - n * s / 2 + s * 0.4);
    final sprites = BlockSprites.of(s, dpr, palette);
    final slot = Paint()..color = palette.text.withValues(alpha: 0.07);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(1), Radius.circular(s * 0.18)), slot);
        final filled = y >= 3 && x < 4 && !(y == 4 && x >= 1 && x <= 3) && (x + y * 5) % 7 != 0;
        if (filled) sprites.draw(canvas, sprites.block(_pieces[(x + y) % 5 + 1]), o.dx + x * s, o.dy + y * s);
      }
    }
    final k = Curves.easeInOut.transform(min(1, t * 1.25));
    final at = Offset.lerp(o + Offset(s * 3.5, -s * 1.5), o + Offset(s * 1, s * 4), k)!;
    for (var dx = 0; dx < 3; dx++) {
      sprites.draw(canvas, sprites.block(PieceType.l), at.dx + dx * s, at.dy);
    }
  }

  void _chain(Canvas canvas, Rect r, double t) {
    final s = (r.height / 5.0).floorToDouble();
    final cols = max(4, (r.width / s).floor());
    final x0 = r.left + (r.width - cols * s) / 2;
    final art = _LobbySprites.of(s, dpr, palette.skin == GameSkin.pixel);
    const colors = [ChainColor.magenta, ChainColor.blue, ChainColor.green, ChainColor.yellow];
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < cols; x++) {
        var pos = Offset(x0 + x * s, r.bottom - (y + 1) * s);
        if (y == 0 && (x == 1 || x == 2)) pos += Offset((x == 1 ? 1 : -1) * s * Curves.easeInOut.transform(min(1, t * 2)), 0);
        art.draw(canvas, art.pyramid(colors[(x * 3 + y * 2) % colors.length]), pos);
      }
    }
    if (t > 0.5) {
      final k = (t - 0.5) / 0.5;
      paintSugarLabel(
        canvas,
        '×2',
        Offset(r.center.dx, r.top + r.height * 0.3 - k * 6),
        s * (0.8 + 0.25 * Curves.easeOutBack.transform(min(1, k * 2))),
        Paint()..shader = ui.Gradient.linear(Offset(0, r.top), Offset(0, r.top + s), const [Color(0xFFFFF6B0), Color(0xFFFF8A10)]),
        outline: const Color(0xFF3A0F2A),
        stroke: 0.2,
      );
    }
  }

  void _sugar(Canvas canvas, Rect r, double t) {
    final s = (r.height / 3.3).floorToDouble();
    final cols = max(3, (r.width / s).floor());
    final x0 = r.left + (r.width - cols * s) / 2;
    final art = _LobbySprites.of(s, dpr, palette.skin == GameSkin.pixel);
    const pattern = [SugarColor.red, SugarColor.blue, SugarColor.green, SugarColor.purple, SugarColor.orange, SugarColor.green, SugarColor.blue];
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < cols; x++) {
        final at = Offset(x0 + x * s, r.top + (r.height - 3 * s) / 2 + y * s);
        final popping = y == 1 && x >= 1 && x <= 3 && x < cols;
        if (popping) {
          if (t < 0.55) {
            art.draw(canvas, art.candy(SugarColor.yellow), at, scale: 1 + 0.1 * sin(t * pi * 6));
          } else {
            final k = (t - 0.55) / 0.45;
            paintSparkle(canvas, at + Offset(s / 2, s / 2 - k * 8), s * 0.3 * (1 - k * 0.5), const Color(0xFFFFE066), opacity: 1 - k);
          }
          continue;
        }
        art.draw(canvas, art.candy(pattern[(x * 2 + y * 3) % pattern.length]), at);
      }
    }
    if (t >= 0.55) {
      final k = (t - 0.55) / 0.45;
      paintSugarLabel(
        canvas,
        '+360',
        Offset(r.center.dx, r.center.dy - k * 12),
        s * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 1 - k * 0.6),
        outline: const Color(0xFF6A0E4A),
        stroke: 0.2,
      );
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.scene != scene || old.palette != palette || old.offset != offset || old.dpr != dpr;
}

/// Candies and pyramid cubes for the lobby, drawn once per size. On the
/// pixel skin they are drawn small and blown up unsmoothed: pixel art.
class _LobbySprites {
  _LobbySprites._(this.cell, this.dpr, this.pixel);

  static final Map<String, _LobbySprites> _cache = {};

  static _LobbySprites of(double cell, double dpr, bool pixel) {
    final key = '$cell@$dpr/$pixel';
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length >= 8) _cache.remove(_cache.keys.first)?.dispose();
    return _cache[key] = _LobbySprites._(cell, dpr, pixel);
  }

  static const double pad = 0.25;

  final double cell, dpr;
  final bool pixel;
  final Map<Object, ui.Image> _images = {};

  ui.Image _render(void Function(Canvas canvas, Rect r) paint) {
    final side = cell * (1 + 2 * pad);
    final scale = pixel ? max(0.2, 7 / cell) : dpr;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    paint(canvas, Rect.fromLTWH(cell * pad, cell * pad, cell, cell));
    final px = max(1, (side * scale).ceil());
    return recorder.endRecording().toImageSync(px, px);
  }

  ui.Image candy(SugarColor c) => _images[c] ??= _render((canvas, r) => paintCandy(canvas, r, c));
  ui.Image pyramid(ChainColor c) => _images[c] ??= _render((canvas, r) => paintChainCube(canvas, r.deflate(cell * 0.03), chainColors[c]!));

  void draw(Canvas canvas, ui.Image image, Offset topLeft, {double scale = 1}) {
    final side = cell * (1 + 2 * pad) * scale;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCenter(center: topLeft + Offset(cell / 2, cell / 2), width: side, height: side),
      Paint()..filterQuality = pixel ? FilterQuality.none : FilterQuality.low,
    );
  }

  void dispose() {
    for (final i in _images.values) {
      i.dispose();
    }
  }
}

// ------------------------------------------------------------------ Lokum

/// Lokum dressed for the skin, drawn once per look into an image: as he is
/// on the toy skins, see-through and lit with a neon rim on neon, 8-bit on
/// pixel. He bobs with the clock and jumps when tapped.
class _LokumPainter extends CustomPainter {
  _LokumPainter({required this.pose, required this.outfit, this.props = const [], this.stage = _Stage.saucer, required this.palette, required this.clock, required this.jump, required this.dpr}) : super(repaint: clock);

  final LokumPose pose;
  final LokumOutfit outfit;
  final List<LokumProp> props;
  final _Stage stage;
  final GamePalette palette;
  final Animation<double> clock;
  final double jump;
  final double dpr;

  static final Map<String, ui.Image> _cache = {};

  ui.Image _image(double size) {
    final pixel = palette.skin == GameSkin.pixel;
    final neon = isNeon(palette);
    final key =
        '$size@$dpr/${pose.name}/${outfit.name}/${props.map((p) => p.name).join('+')}/${stage.name}/${pixel
            ? 'p'
            : neon
            ? 'n'
            : 't'}';
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length >= 12) _cache.remove(_cache.keys.first)?.dispose();
    final w = size * 1.5, h = size * 1.6;
    final scale = pixel ? 24 / size : dpr;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    final c = Offset(w / 2, h * 0.56);
    // The saucer and its coffee behind him, or the bowl he climbs out of.
    final bowlRim = c + Offset(0, size * 0.1);
    switch (stage) {
      case _Stage.saucer:
        paintCoffeeCup(canvas, c + Offset(size * 0.52, size * 0.5), size * 0.3, steam: false);
        paintSaucer(canvas, c + Offset(0, size * 0.55), size * 1.2);
      case _Stage.bowl:
        paintSweetBowlBack(canvas, bowlRim, size * 1.2);
      case _Stage.none:
        break;
    }
    if (neon) {
      canvas.drawCircle(
        c,
        size * 0.8,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            size * 0.8,
            [neonPink.withValues(alpha: 0.4), neonCyan.withValues(alpha: 0.1), const Color(0x00000000)],
            const [0, 0.6, 1],
          ),
      );
      canvas.saveLayer(Offset.zero & Size(w, h), Paint()..color = Colors.white.withValues(alpha: 0.9));
      paintLokum(canvas, c, size, pose: pose, outfit: outfit, props: props);
      canvas.drawCircle(
        c + Offset(0, size * 0.12),
        size * 0.4,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = ui.Gradient.radial(c + Offset(0, size * 0.12), size * 0.4, [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0)]),
      );
      canvas.restore();
      final body = RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, size * 0.04), width: size * 1.02, height: size), Radius.circular(size * 0.46));
      canvas.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = neonPink.withValues(alpha: 0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFB3F2),
      );
    } else {
      paintLokum(canvas, c, size, pose: pose, outfit: outfit, props: props);
    }
    if (stage == _Stage.bowl) paintSweetBowlFront(canvas, bowlRim, size * 1.2);
    final image = recorder.endRecording().toImageSync(max(1, (w * scale).ceil()), max(1, (h * scale).ceil()));
    return _cache[key] = image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width / 1.5, size.height / 1.6);
    final image = _image(s.floorToDouble());
    final bob = sin(clock.value * pi * 2) * 3;
    final up = Curves.easeOut.transform(jump.clamp(0.0, 1.0)) * 14 * sin(jump * pi);
    final dst = Rect.fromCenter(center: size.center(Offset(0, bob - up)), width: s * 1.5, height: s * 1.6);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = palette.skin == GameSkin.pixel ? FilterQuality.none : FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_LokumPainter old) => old.pose != pose || old.outfit != outfit || !listEquals(old.props, props) || old.stage != stage || old.palette != palette || old.jump != jump || old.dpr != dpr;
}
