part of 'game_screen.dart';

// ------------------------------------------------------------ home lobby

/// The start screen: Lokum with a suggestion, the big play card for the
/// last mode, cards for the other modes that show a little of each game,
/// the daily puzzle and the shortcuts. Every skin dresses it its own way.
class _HomeLobby extends StatefulWidget {
  const _HomeLobby({super.key, required this.c});

  final GameController c;

  @override
  State<_HomeLobby> createState() => _HomeLobbyState();
}

class _HomeLobbyState extends State<_HomeLobby> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  int _tip = 0;
  double _hop = 0;

  GameController get c => widget.c;

  /// Whether the scenes are moving (for tests).
  @visibleForTesting
  bool get moving => _clock.isAnimating;

  @override
  void initState() {
    super.initState();
    c.settings.addListener(_syncMotion);
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
    final last = _PlayMode.fromName(c.settings.lastPlay);
    final cards = _lobbyCards(c.settings, last);

    final header = _LobbyHeader(c: c);
    final hero = _LobbyHero(
      tip: tip,
      clock: _clock,
      hop: _hop,
      onHopDone: () => _hop = 0,
      onLokum: () => _nextTip(tips.length),
      onAction: () => tip.run(context, c),
      outfit: c.settings.outfit,
      onWardrobe: () => showLokumWardrobe(context, c.settings),
    );
    final resume = _resumeButtons(context);
    final play = _LobbyPlayCard(mode: last, clock: _clock, settings: c.settings, onTap: () => _launch(context, c, last));
    final changeMode = Center(
      child: TextButton(
        key: const ValueKey('change-mode'),
        onPressed: () => _openModes(context, c),
        child: Text(
          '${s.changeMode} ›',
          style: TextStyle(color: p.muted, fontSize: _fs(p, 14), fontWeight: FontWeight.w700),
        ),
      ),
    );
    final daily = _LobbyDaily(
      settings: c.settings,
      onTap: () => BlocksScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, entry: BlocksEntry.daily),
    );
    final shortcuts = _shortcutRow(context, c);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: TextStyle(color: p.muted, fontSize: _fs(p, 13), fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
    Widget card(_PlayMode m, {double? width}) => SizedBox(
      width: width,
      child: _LobbyModeCard(key: ValueKey('card-${m.name}'), mode: m, settings: c.settings, clock: _clock, onTap: () => _launch(context, c, m)),
    );

    // Always the whole screen: the game is waiting behind it.
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: p.background.first)),
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: BackgroundBasePainter(p))),
          ),
          Positioned.fill(child: _LobbyBackdrop(c: c)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 900 && box.maxHeight >= 560;
                final short = !wide && box.maxWidth > box.maxHeight && box.maxHeight < 560;
                if (wide) {
                  // Big screens get the same lobby, scaled up to fill them.
                  final zoom = min(box.maxWidth / 1280, box.maxHeight / 740).clamp(1.0, 1.6);
                  final inner = Size(box.maxWidth / zoom, box.maxHeight / zoom);
                  // A column of the essentials beside a wall of mode cards.
                  final columns = inner.width >= 1250 ? 4 : 3;
                  return SizedBox.fromSize(
                    size: box.biggest,
                    child: FittedBox(
                      alignment: Alignment.topCenter,
                      child: SizedBox.fromSize(
                        size: inner,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 420 + 32 + columns * 200.0),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 420,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        header,
                                        const SizedBox(height: 14),
                                        hero,
                                        const SizedBox(height: 14),
                                        ...resume,
                                        play,
                                        changeMode,
                                        daily,
                                        const SizedBox(height: 14),
                                        shortcuts,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 60),
                                        label(s.forYou),
                                        LayoutBuilder(
                                          builder: (context, area) {
                                            final w = (area.maxWidth - (columns - 1) * 14) / columns;
                                            return Wrap(spacing: 14, runSpacing: 14, children: [for (final m in cards) card(m, width: w)]);
                                          },
                                        ),
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
                // The cards are as tall as their scene and text need at this
                // width, text size and skin.
                final cardWidth = short ? 150.0 : 162.0;
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final cardHeight = ((cardWidth - 18) / 1.35 + (_fs(p, 16) * 1.3 + _fs(p, 12) * 1.25 * 2) * textScale + 48).ceilToDouble();
                final carousel = SizedBox(
                  height: cardHeight + 8,
                  child: ListView.separated(
                    key: const ValueKey('lobby-cards'),
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => card(cards[i], width: cardWidth),
                  ),
                );
                if (short) {
                  // Play, other modes and the shortcuts on the left, always in
                  // view; Lokum and the cards on the right.
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [header, const SizedBox(height: 8), ...resume, play, changeMode, shortcuts, const SizedBox(height: 10), daily],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [hero, const SizedBox(height: 10), label(s.forYou), carousel],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Phones: the shortcuts stay at the bottom like a tab bar.
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                header,
                                const SizedBox(height: 12),
                                hero,
                                const SizedBox(height: 14),
                                ...resume,
                                play,
                                changeMode,
                                label(s.forYou),
                                carousel,
                                const SizedBox(height: 14),
                                daily,
                              ],
                            ),
                          ),
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 10), child: shortcuts),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// A game left half way (falling blocks, Bulmaca) comes back from here.
  List<Widget> _resumeButtons(BuildContext context) {
    final s = AppStrings.of(context);
    final saved = c.savedSummary;
    final savedPuzzle = BlocksController.summaryOf(c.settings.savedBlocks);
    final sugarLevel = _savedSugarLevel(c.settings);
    final chain = _savedChainSummary(c.settings);
    return [
      if (saved != null) ...[
        GradientButton(
          key: const ValueKey('resume-game'),
          label: s.resumeGame,
          subtitle: s.resumeSummary(s.modeName(saved.mode), saved.score, saved.level),
          icon: Icons.replay_rounded,
          secondary: true,
          onTap: c.resume,
        ),
        const SizedBox(height: 12),
      ],
      if (savedPuzzle != null) ...[
        GradientButton(
          key: const ValueKey('resume-puzzle'),
          label: s.resumeGame,
          subtitle: '${s.puzzleTitle} · ${blocksResumeSubtitle(s, savedPuzzle)}',
          icon: Icons.replay_rounded,
          secondary: true,
          onTap: () => BlocksScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, entry: BlocksEntry.resume),
        ),
        const SizedBox(height: 12),
      ],
      if (sugarLevel != null) ...[
        GradientButton(
          key: const ValueKey('resume-sugar'),
          label: s.resumeGame,
          subtitle: '${s.sugarTitle} · ${s.sugarCardLevel(sugarLevel)}',
          icon: Icons.replay_rounded,
          secondary: true,
          onTap: () => SugarScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, level: sugarLevel, resume: true),
        ),
        const SizedBox(height: 12),
      ],
      if (chain != null) ...[
        GradientButton(
          key: const ValueKey('resume-chain'),
          label: s.resumeGame,
          subtitle: '${s.chainTitle} · ${chain.mode == ChainMode.timeAttack ? s.chainTimeTitle : s.chainEndlessTitle} · ${s.score(chain.score)}',
          icon: Icons.replay_rounded,
          secondary: true,
          onTap: () => ChainScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, mode: chain.mode, resume: true),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

/// Pixel type is small for its size: everything on the lobby is set a third
/// larger on that skin so it stays readable.
double _fs(GamePalette p, double size) => p.skin == GameSkin.pixel ? size * 1.3 : size;

/// Strong second-line text: muted greys are too faint on the dark skins.
Color _second(GamePalette p) => p.isDark ? Color.lerp(p.muted, p.text, 0.45)! : p.muted;

/// The bottom row of small buttons (also used by nothing else now).
Widget _shortcutRow(BuildContext context, GameController c) {
  final s = AppStrings.of(context);
  return Row(
    children: [
      for (final (i, (key, icon, label, onTap)) in [
        ('open-modes', Icons.grid_view_rounded, s.modesTitle, () => _openModes(context, c)),
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

  void run(BuildContext context, GameController c) {
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

/// The cards: modes with something going on first, then new ones, then the
/// rest; never the one already on the play card.
List<_PlayMode> _lobbyCards(Settings s, _PlayMode last) {
  const all = [
    _PlayMode.sugar,
    _PlayMode.chainEndless,
    _PlayMode.blocksLevels,
    _PlayMode.adventure,
    _PlayMode.superMode,
    _PlayMode.normal,
    _PlayMode.bomb,
    _PlayMode.sprint,
    _PlayMode.chainTime,
  ];
  int rank(_PlayMode m) {
    if (m == _PlayMode.sugar && s.savedSugar != null) return 0;
    if (m.chainMode != null && _savedChainSummary(s)?.mode == m.chainMode) return 0;
    if (!_played(s, m) && m.isNew) return 1;
    if (!_played(s, m)) return 2;
    return 3;
  }

  final list = [
    for (final m in all)
      if (m != last) m,
  ];
  final order = {for (final (i, m) in list.indexed) m: i};
  list.sort((a, b) => rank(a) != rank(b) ? rank(a).compareTo(rank(b)) : order[a]!.compareTo(order[b]!));
  return list;
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: lineColor, fontSize: _fs(p, 13), height: 1.2, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _TipButton(label: tip.button, onTap: onAction),
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
                    builder: (context, jump, _) => CustomPaint(
                      painter: _LokumPainter(pose: tip.pose, outfit: outfit, palette: p, clock: clock, jump: jump, dpr: MediaQuery.devicePixelRatioOf(context)),
                    ),
                  ),
                ),
              ),
              // His wardrobe, a tap away.
              Positioned(left: -2, bottom: 0, child: _WardrobeButton(onTap: onWardrobe)),
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
          '${label.toUpperCase()}  ›',
          style: TextStyle(color: ink, fontSize: _fs(p, 14), fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
      ),
    );
  }
}

/// The big play card: the last mode, its record and a live look at it.
class _LobbyPlayCard extends StatelessWidget {
  const _LobbyPlayCard({required this.mode, required this.clock, required this.settings, required this.onTap});

  final _PlayMode mode;
  final Animation<double> clock;
  final Settings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final neon = isNeon(p);
    final fg = p.flat && p.accent1.computeLuminance() > 0.45 ? p.ink : Colors.white;
    final record = mode.record(settings, s);
    return GestureDetector(
      key: const ValueKey('play'),
      onTap: onTap,
      child: Container(
        height: _fs(p, 1) * 136,
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
        decoration: neon
            ? neonCardDecoration(radius: 26, tone: neonPink, glow: 0.6)
            : p.flat
            ? flatCardDecoration(p, radius: p.skin == GameSkin.pixel ? 4 : 26, fill: p.accent1, depth: 6)
            : BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(colors: [p.accent1, p.accent2]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                boxShadow: [BoxShadow(color: p.accent1.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))],
              ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s.play,
                      style: TextStyle(color: neon ? p.text : fg, fontSize: _fs(p, 40), height: 1, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mode.fullTitle(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: (neon ? p.text : fg).withValues(alpha: 0.95), fontSize: _fs(p, 16), fontWeight: FontWeight.w800),
                  ),
                  if (record != null)
                    Text(
                      s.bestLine(record),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: (neon ? p.text : fg).withValues(alpha: 0.8), fontSize: _fs(p, 13), fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AspectRatio(
              aspectRatio: 1.05,
              child: _ModeScene(mode: mode, clock: clock),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mode card: a live scene, the name, one line and a badge.
class _LobbyModeCard extends StatelessWidget {
  const _LobbyModeCard({super.key, required this.mode, required this.settings, required this.clock, required this.onTap});

  final _PlayMode mode;
  final Settings settings;
  final Animation<double> clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final info = _cardInfo(mode, settings, s);
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        radius: p.skin == GameSkin.pixel ? 4 : 22,
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ModeScene(mode: mode, clock: clock),
                  if (info.badge != null)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: _Badge(text: info.badge!, colors: info.badgeColors),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _cardTitle(mode, s),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.text, fontSize: _fs(p, 16), fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                info.line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _second(p), fontSize: _fs(p, 12), height: 1.2, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: info.progress == null
                      ? null
                      : LinearProgressIndicator(value: info.progress, backgroundColor: p.track, valueColor: AlwaysStoppedAnimation(info.badgeColors.first)),
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
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

/// A card names the game, not the variant ("Zincir Küpler", not "Sonsuz").
String _cardTitle(_PlayMode m, AppStrings s) => switch (m) {
  _PlayMode.chainEndless => s.chainTitle,
  _PlayMode.chainTime => s.chainTimeTitle,
  _PlayMode.blocksLevels => s.puzzleTitle,
  _PlayMode.blocksEndless => '${s.puzzleTitle} · ${s.endlessMode}',
  _PlayMode.normal || _PlayMode.relaxed => s.classicTitle,
  _ => m.title(s),
};

const _modeTones = {
  _ModeGroup.superGroup: [Color(0xFFB45BFF), Color(0xFFFF5FB8)],
  _ModeGroup.classic: [Color(0xFF3B82F6), Color(0xFF38BDF8)],
  _ModeGroup.puzzle: [Color(0xFF14B8A6), Color(0xFF6EE7B7)],
  _ModeGroup.chain: [Color(0xFFFF33EE), Color(0xFF7C3AED)],
  _ModeGroup.sugar: [Color(0xFFFF4D8D), Color(0xFFFF9A1F)],
  _ModeGroup.challenges: [Color(0xFFF59E0B), Color(0xFFEF4444)],
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

enum _Scene { power, blocks, puzzle, chain, sugar }

_Scene _sceneOf(_PlayMode m) => switch (m.group) {
  _ModeGroup.superGroup => _Scene.power,
  _ModeGroup.classic || _ModeGroup.challenges => _Scene.blocks,
  _ModeGroup.puzzle => _Scene.puzzle,
  _ModeGroup.chain => _Scene.chain,
  _ModeGroup.sugar => _Scene.sugar,
};

class _ModeScene extends StatelessWidget {
  const _ModeScene({required this.mode, required this.clock});

  final _PlayMode mode;
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    // Each card starts at its own point of the loop.
    final offset = (mode.index * 0.37) % 1;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 2 : 16),
        child: CustomPaint(
          painter: _ScenePainter(scene: _sceneOf(mode), palette: p, clock: clock, offset: offset, dpr: MediaQuery.devicePixelRatioOf(context)),
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
    switch (scene) {
      case _Scene.power || _Scene.blocks:
        _falling(canvas, r, t, power: scene == _Scene.power);
      case _Scene.puzzle:
        _puzzle(canvas, r, t);
      case _Scene.chain:
        _chain(canvas, r, t);
      case _Scene.sugar:
        _sugar(canvas, r, t);
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
  _LokumPainter({required this.pose, required this.outfit, required this.palette, required this.clock, required this.jump, required this.dpr}) : super(repaint: clock);

  final LokumPose pose;
  final LokumOutfit outfit;
  final GamePalette palette;
  final Animation<double> clock;
  final double jump;
  final double dpr;

  static final Map<String, ui.Image> _cache = {};

  ui.Image _image(double size) {
    final pixel = palette.skin == GameSkin.pixel;
    final neon = isNeon(palette);
    final key =
        '$size@$dpr/${pose.name}/${outfit.name}/${pixel
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
      paintLokum(canvas, c, size, pose: pose, outfit: outfit);
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
      paintLokum(canvas, c, size, pose: pose, outfit: outfit);
    }
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
  bool shouldRepaint(_LokumPainter old) => old.pose != pose || old.outfit != outfit || old.palette != palette || old.jump != jump || old.dpr != dpr;
}
