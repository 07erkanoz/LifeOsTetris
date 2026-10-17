part of 'game_screen.dart';

// ---------------------------------------------------------------- modes

enum _ModeGroup { superGroup, classic, puzzle, chain, sugar, challenges, tower }

/// Everything the play button and the modes page can start.
enum _PlayMode {
  superMode(_ModeGroup.superGroup),
  normal(_ModeGroup.classic),
  relaxed(_ModeGroup.classic),
  blocksLevels(_ModeGroup.puzzle),
  blocksEndless(_ModeGroup.puzzle),
  adventure(_ModeGroup.puzzle, isNew: true),
  bomb(_ModeGroup.puzzle, isNew: true),
  chainEndless(_ModeGroup.chain, isNew: true),
  chainTime(_ModeGroup.chain, isNew: true),
  chainMissions(_ModeGroup.chain, isNew: true),
  chainPuzzles(_ModeGroup.chain, isNew: true),
  chainVersus(_ModeGroup.chain, isNew: true),
  sugar(_ModeGroup.sugar, isNew: true),
  sprint(_ModeGroup.challenges),
  ultra(_ModeGroup.challenges),
  dig(_ModeGroup.challenges),
  target(_ModeGroup.challenges, isNew: true),
  chaos(_ModeGroup.challenges, isNew: true),
  towerClimb(_ModeGroup.tower, isNew: true),
  towerWind(_ModeGroup.tower, isNew: true),
  towerDaily(_ModeGroup.tower, isNew: true),
  towerBuild(_ModeGroup.tower, isNew: true);

  const _PlayMode(this.group, {this.isNew = false});

  final _ModeGroup group;

  /// Gets a "YENİ" badge on the modes page.
  final bool isNew;

  static _PlayMode fromName(String? name) => values.firstWhere((m) => m.name == name, orElse: () => _PlayMode.superMode);

  /// The falling-block mode behind it, if any.
  GameMode? get gameMode => switch (this) {
    _PlayMode.normal => GameMode.classic,
    _PlayMode.relaxed => GameMode.relaxed,
    _PlayMode.superMode => GameMode.superMode,
    _PlayMode.sprint => GameMode.sprint,
    _PlayMode.ultra => GameMode.ultra,
    _PlayMode.dig => GameMode.dig,
    _PlayMode.target => GameMode.target,
    _PlayMode.chaos => GameMode.chaos,
    _ => null,
  };

  String title(AppStrings s) => switch (this) {
    _PlayMode.superMode => s.superTitle,
    _PlayMode.normal => s.normal,
    _PlayMode.relaxed => s.relaxed,
    _PlayMode.blocksLevels => s.levelsCard,
    _PlayMode.blocksEndless => s.endlessMode,
    _PlayMode.adventure => s.adventureTitle,
    _PlayMode.sprint => s.sprintTitle,
    _PlayMode.ultra => s.ultraTitle,
    _PlayMode.dig => s.digTitle,
    _PlayMode.bomb => s.bombTitle,
    _PlayMode.chainEndless => s.chainEndlessTitle,
    _PlayMode.chainTime => s.chainTimeTitle,
    _PlayMode.chainMissions => s.chainMissionsTitle,
    _PlayMode.chainPuzzles => s.chainPuzzlesTitle,
    _PlayMode.chainVersus => s.chainVersusTitle,
    _PlayMode.sugar => s.sugarTitle,
    _PlayMode.target => s.targetTitle,
    _PlayMode.chaos => s.chaosTitle,
    _PlayMode.towerClimb => s.towerClimbTitle,
    _PlayMode.towerWind => s.towerWindTitle,
    _PlayMode.towerDaily => s.towerDailyTitle,
    _PlayMode.towerBuild => s.towerBuildTitle,
  };

  /// Title with its family, for the play button ("Klasik · Normal").
  String fullTitle(AppStrings s) => switch (group) {
    _ModeGroup.classic => '${s.classicTitle} · ${title(s)}',
    _ModeGroup.puzzle => '${s.puzzleTitle} · ${title(s)}',
    _ModeGroup.chain => '${s.chainTitle} · ${title(s)}',
    _ModeGroup.tower => '${s.towerTitle} · ${title(s)}',
    _ => title(s),
  };

  String subtitle(AppStrings s) => switch (this) {
    _PlayMode.superMode => s.superSubtitle,
    _PlayMode.normal => s.normalSubtitle,
    _PlayMode.relaxed => s.relaxedShort,
    _PlayMode.blocksLevels => s.levelsCardSubtitle,
    _PlayMode.blocksEndless => s.endlessCardSubtitle,
    _PlayMode.adventure => s.adventureSubtitle,
    _PlayMode.sprint => s.sprintSubtitle,
    _PlayMode.ultra => s.ultraSubtitle,
    _PlayMode.dig => s.digSubtitle,
    _PlayMode.bomb => s.bombSubtitle,
    _PlayMode.chainEndless => s.chainEndlessSubtitle,
    _PlayMode.chainTime => s.chainTimeSubtitle,
    _PlayMode.chainMissions => s.chainMissionsSubtitle,
    _PlayMode.chainPuzzles => s.chainPuzzlesSubtitle,
    _PlayMode.chainVersus => s.chainVersusSubtitle,
    _PlayMode.sugar => s.sugarSubtitle,
    _PlayMode.target => s.targetSubtitle,
    _PlayMode.chaos => s.chaosSubtitle,
    _PlayMode.towerClimb => s.towerClimbSubtitle,
    _PlayMode.towerWind => s.towerWindSubtitle,
    _PlayMode.towerDaily => s.towerDailySubtitle,
    _PlayMode.towerBuild => s.towerBuildSubtitle,
  };

  IconData get icon => switch (this) {
    _PlayMode.superMode => Icons.auto_awesome_rounded,
    _PlayMode.normal => Icons.bolt_rounded,
    _PlayMode.relaxed => Icons.spa_rounded,
    _PlayMode.blocksLevels => Icons.grid_view_rounded,
    _PlayMode.blocksEndless => Icons.all_inclusive_rounded,
    _PlayMode.adventure => Icons.extension_rounded,
    _PlayMode.sprint => Icons.speed_rounded,
    _PlayMode.ultra => Icons.timer_rounded,
    _PlayMode.dig => Icons.layers_rounded,
    _PlayMode.bomb => Icons.local_fire_department_rounded,
    _PlayMode.chainEndless => Icons.link_rounded,
    _PlayMode.chainTime => Icons.hourglass_bottom_rounded,
    _PlayMode.chainMissions => Icons.directions_boat_rounded,
    _PlayMode.chainPuzzles => Icons.extension_rounded,
    _PlayMode.chainVersus => Icons.sports_kabaddi_rounded,
    _PlayMode.sugar => Icons.cake_rounded,
    _PlayMode.target => Icons.star_rounded,
    _PlayMode.chaos => Icons.casino_rounded,
    _PlayMode.towerClimb => Icons.layers_rounded,
    _PlayMode.towerWind => Icons.air_rounded,
    _PlayMode.towerDaily => Icons.calendar_today_rounded,
    _PlayMode.towerBuild => Icons.location_city_rounded,
  };

  /// Badge colour, from the theme's own blocks.
  Color tone() =>
      blockColors[switch (this) {
        _PlayMode.superMode => PieceType.t,
        _PlayMode.normal => PieceType.j,
        _PlayMode.relaxed => PieceType.s,
        _PlayMode.blocksLevels || _PlayMode.blocksEndless => PieceType.i,
        _PlayMode.sprint => PieceType.i,
        _PlayMode.ultra => PieceType.l,
        _PlayMode.dig => PieceType.s,
        _PlayMode.bomb => PieceType.z,
        _PlayMode.chainEndless => PieceType.t,
        _PlayMode.chainTime => PieceType.o,
        _PlayMode.chainMissions => PieceType.i,
        _PlayMode.chainPuzzles => PieceType.s,
        _PlayMode.chainVersus => PieceType.z,
        _PlayMode.sugar => PieceType.z,
        _PlayMode.adventure => PieceType.l,
        _PlayMode.target => PieceType.o,
        _PlayMode.chaos => PieceType.t,
        _PlayMode.towerClimb || _PlayMode.towerBuild => PieceType.z,
        _PlayMode.towerWind => PieceType.i,
        _PlayMode.towerDaily => PieceType.o,
      }]!;

  /// The Kule Küpler mode behind it, if any.
  TowerMode? get towerMode => switch (this) {
    _PlayMode.towerClimb => TowerMode.climb,
    _PlayMode.towerWind => TowerMode.wind,
    _PlayMode.towerDaily => TowerMode.daily,
    _ => null,
  };

  /// The Zincir Küpler mode behind it, if any.
  ChainMode? get chainMode => switch (this) {
    _PlayMode.chainEndless => ChainMode.endless,
    _PlayMode.chainTime => ChainMode.timeAttack,
    _ => null,
  };

  /// Best result so far, or null before the first one.
  String? record(Settings settings, AppStrings s) {
    final mode = gameMode;
    if (mode != null) {
      if (mode.recordsTime) {
        final best = settings.bestTime(mode);
        return best == null ? null : s.clock(best);
      }
      final best = settings.bestScore(mode);
      return best > 0 ? s.score(best) : null;
    }
    return switch (this) {
      _PlayMode.blocksLevels => settings.totalBlockStars > 0 ? s.starsLine(settings.totalBlockStars, BlockLevels.count * 3) : null,
      _PlayMode.blocksEndless => settings.blocksBest > 0 ? s.score(settings.blocksBest) : null,
      _PlayMode.adventure => settings.adventureSolved > 0 ? s.starsLine(settings.totalAdventureStars, Adventure.count * 3) : null,
      _PlayMode.bomb => settings.bombBest > 0 ? s.score(settings.bombBest) : null,
      _PlayMode.sugar => settings.totalSugarStars > 0 ? s.starsLine(settings.totalSugarStars, SugarLevels.count * 3) : null,
      _PlayMode.chainEndless || _PlayMode.chainTime => switch (settings.chainBest(chainMode!, settings.chainDifficulty)) {
        0 => null,
        final best => s.score(best),
      },
      _PlayMode.chainMissions => settings.totalMissionStars > 0 ? s.starsLine(settings.totalMissionStars, ChainMissions.count * 3) : null,
      _PlayMode.chainPuzzles => settings.puzzlesSolved > 0 ? '${settings.puzzlesSolved}/${ChainPuzzles.count}' : null,
      _PlayMode.chainVersus => switch ([for (final r in ChainRival.values) settings.rivalWins(r.index)].fold(0, (a, b) => a + b)) {
        0 => null,
        final wins => s.rivalWins(wins),
      },
      _PlayMode.towerClimb || _PlayMode.towerWind || _PlayMode.towerDaily => switch (settings.towerBest(towerMode!)) {
        0 => null,
        final best => s.floorsLine(best),
      },
      _PlayMode.towerBuild => settings.towerTotal > 0 ? s.totalFloors(settings.towerTotal) : null,
      _ => null,
    };
  }
}

/// Starts [mode] and remembers it for the play button.
void _launch(BuildContext context, GameController c, _PlayMode mode) {
  c.settings.lastPlay = mode.name;
  final game = mode.gameMode;
  if (game != null) {
    c.start(game);
    return;
  }
  if (mode == _PlayMode.sugar) {
    SugarMapScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics);
    return;
  }
  final tower = mode.towerMode;
  if (tower != null) {
    TowerScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, mode: tower);
    return;
  }
  if (mode == _PlayMode.towerBuild) {
    TowerBuildScreen.open(context, settings: c.settings, audio: c.audio);
    return;
  }
  switch (mode) {
    case _PlayMode.chainMissions:
      ChainMissionsScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics);
      return;
    case _PlayMode.chainPuzzles:
      ChainPuzzlesScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics);
      return;
    case _PlayMode.chainVersus:
      ChainVersusScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics);
      return;
    default:
      break;
  }
  final chain = mode.chainMode;
  if (chain != null) {
    ChainScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, mode: chain);
    return;
  }
  BlocksScreen.open(
    context,
    settings: c.settings,
    audio: c.audio,
    haptics: c.haptics,
    entry: switch (mode) {
      _PlayMode.blocksEndless => BlocksEntry.endless,
      _PlayMode.adventure => BlocksEntry.adventure,
      _PlayMode.bomb => BlocksEntry.bombs,
      _ => BlocksEntry.levels,
    },
  );
}

Future<void> _openModes(BuildContext context, GameController c) async {
  final mode = await Navigator.of(context).push<_PlayMode>(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => _ModesPage(settings: c.settings),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
  if (mode != null && context.mounted) _launch(context, c, mode);
}

/// A small square button of the home screen's bottom row.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: p.flat
            ? flatCardDecoration(p, radius: 16, fill: p.keyFace, depth: 4)
            : BoxDecoration(
                color: p.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.glassBorder, width: 1.5),
              ),
        child: Column(
          children: [
            GameIcon(icon, size: 22, color: p.flat ? p.keyGlyph : p.icon),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(fontSize: _fs(p, 12.5), fontWeight: FontWeight.w800, color: _second(p)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool get _canQuit =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// The settings dialog, for screens outside the home menu.
Future<void> showSettingsDialog(BuildContext context, Settings settings) => _SettingsSheet.open(context, settings);

/// Every setting in a dialog, opened from the home screen.
class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.settings});

  final Settings settings;

  static Future<void> open(BuildContext context, Settings settings) => showDialog<void>(
    context: context,
    barrierColor: GamePalette.of(context).background.first.withValues(alpha: 0.7),
    builder: (_) => _SettingsSheet(settings: settings),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(color: GamePalette.of(context).background.first, borderRadius: BorderRadius.circular(24)),
          child: GlassCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: SingleChildScrollView(child: SettingsPanel(settings: settings)),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- games

/// The games of the app, in the order of the games page. The first of a
/// game's modes is its main one, shown large on the game's own page.
enum _Game {
  tower,
  sugar,
  chain,
  puzzle,
  superGame,
  classic;

  List<_PlayMode> get modes => switch (this) {
    _Game.tower => const [_PlayMode.towerClimb, _PlayMode.towerWind, _PlayMode.towerDaily, _PlayMode.towerBuild],
    _Game.sugar => const [_PlayMode.sugar],
    _Game.chain => const [_PlayMode.chainMissions, _PlayMode.chainVersus, _PlayMode.chainPuzzles, _PlayMode.chainEndless, _PlayMode.chainTime],
    _Game.puzzle => const [_PlayMode.blocksLevels, _PlayMode.adventure, _PlayMode.bomb, _PlayMode.blocksEndless],
    _Game.superGame => const [_PlayMode.superMode],
    _Game.classic => const [_PlayMode.normal, _PlayMode.relaxed, _PlayMode.target, _PlayMode.chaos, _PlayMode.sprint, _PlayMode.ultra, _PlayMode.dig],
  };

  /// The modes after the main one: (label, modes, as compact rows).
  List<(String, List<_PlayMode>, bool)> sections(AppStrings s) => switch (this) {
    _Game.classic => [
      (s.calmLabel, const [_PlayMode.relaxed], true),
      (s.challengesLabel, const [_PlayMode.target, _PlayMode.chaos, _PlayMode.sprint, _PlayMode.ultra, _PlayMode.dig], true),
    ],
    _ => [(s.moreModesLabel, modes.skip(1).toList(), false)],
  };

  /// Gets a "YENİ" badge until one of its modes is played.
  bool get isNew => this == _Game.tower || this == _Game.sugar || this == _Game.chain;

  static _Game of(_PlayMode m) => values.firstWhere((g) => g.modes.contains(m));

  String title(AppStrings s) => switch (this) {
    _Game.tower => s.towerTitle,
    _Game.sugar => s.sugarTitle,
    _Game.chain => s.chainTitle,
    _Game.puzzle => s.puzzleTitle,
    _Game.superGame => s.superTitle,
    _Game.classic => s.classicTitle,
  };

  String blurb(AppStrings s) => switch (this) {
    _Game.tower => s.towerBlurb,
    _Game.sugar => s.sugarBlurb,
    _Game.chain => s.chainBlurb,
    _Game.puzzle => s.puzzleBlurb,
    _Game.superGame => s.superSubtitle,
    _Game.classic => s.classicBlurb,
  };
}

/// A word on a mode's scene: its clock or its length.
String? _sceneTag(_PlayMode m, AppStrings s) => switch (m) {
  _PlayMode.chainTime => s.clock(ChainGame.timeAttackLength, tenths: false),
  _PlayMode.ultra => s.clock(GameMode.ultraSeconds, tenths: false),
  _PlayMode.sprint => s.linesTag(GameMode.sprintLines),
  _ => null,
};

Decoration _cardBox(GamePalette p, {bool selected = false, double radius = 20}) => p.flat
    ? flatCardDecoration(p, radius: p.skin == GameSkin.pixel ? 4 : radius, depth: 4, glow: selected ? 1 : 0)
    : BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: selected ? p.accent1 : p.glassBorder, width: selected ? 2.5 : 1.5),
      );

/// A small rounded label: a mode count, a scene's clock, "YENİ".
class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.color, this.ink, this.icon});

  final String text;
  final Color? color;
  final Color? ink;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final fill = color ?? p.track;
    final fg = ink ?? (fill.computeLuminance() > 0.45 ? p.ink : Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: p.flat
          ? flatCardDecoration(p, radius: p.skin == GameSkin.pixel ? 2 : 10, fill: fill, depth: 0)
          : BoxDecoration(color: fill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[GameIcon(icon!, size: _fs(p, 12), color: fg), const SizedBox(width: 3)],
          Text(
            text,
            style: TextStyle(fontSize: _fs(p, 10.5), height: 1.2, fontWeight: FontWeight.w900, letterSpacing: 0.4, color: fg),
          ),
        ],
      ),
    );
  }
}

const _newTone = Color(0xFFF43F5E);

// ---------------------------------------------------------------- games page

/// The games, or with [game] that game's modes: its main one large, the
/// others with scenes of their own. Picking a mode returns it.
class _ModesPage extends StatefulWidget {
  const _ModesPage({required this.settings, this.game});

  final Settings settings;
  final _Game? game;

  @override
  State<_ModesPage> createState() => _ModesPageState();
}

class _ModesPageState extends State<_ModesPage> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Future<void> _openGame(_Game game) async {
    if (game.modes.length == 1) {
      Navigator.of(context).pop(game.modes.single);
      return;
    }
    final mode = await Navigator.of(context).push<_PlayMode>(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => _ModesPage(settings: widget.settings, game: game),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
    if (mode != null && mounted) Navigator.of(context).pop(mode);
  }

  @override
  Widget build(BuildContext context) {
    assert(_PlayMode.values.every((m) => _Game.values.where((g) => g.modes.contains(m)).length == 1), 'every mode belongs to one game');
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final game = widget.game;
    final settings = widget.settings;
    final last = _PlayMode.fromName(settings.lastPlay);
    return Scaffold(
      backgroundColor: p.background.first,
      body: CustomPaint(
        painter: BackgroundBasePainter(p),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final width = min(box.maxWidth, 1000.0);
              // Room for larger text and the pixel skin's bigger letters.
              final k = max(1.0, MediaQuery.textScalerOf(context).scale(10) / 10) * (p.skin == GameSkin.pixel ? 1.18 : 1);
              Widget grid(int columns, double extent, List<Widget> children) => GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: extent),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: children,
              );
              // Games in one column on a phone, larger cards side by side on a
              // tablet or a desktop.
              final gameColumns = width >= 1100 ? 3 : (width >= 600 ? 2 : 1);
              final gameExtent = gameColumns == 1 ? 112 * k : max(112 * k, min(300.0, (width - 32 - 12 * (gameColumns - 1)) / gameColumns * 0.58));
              Widget label(String text) => Padding(padding: const EdgeInsets.fromLTRB(4, 20, 0, 8), child: CardLabel(text));
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView(
                    // Small page: build every card, so a far one is there to scroll to.
                    scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    children: [
                      Row(
                        children: [
                          GlassIconButton(
                            key: ValueKey(game == null ? 'modes-back' : 'game-back'),
                            icon: Icons.arrow_back_rounded,
                            tooltip: s.back,
                            size: 40,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                game == null ? s.modesTitle : game.title(s),
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
                              ),
                            ),
                          ),
                          if (game != null) _Tag(s.modeCount(game.modes.length), icon: Icons.grid_view_rounded),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (game == null)
                        grid(gameColumns, gameExtent, [
                          for (final g in _Game.values) _GameCard(game: g, settings: settings, clock: _clock, onTap: () => _openGame(g)),
                        ])
                      else ...[
                        _FeaturedMode(mode: game.modes.first, settings: settings, clock: _clock, wide: width >= 600, scale: k),
                        for (final (title, modes, rows) in game.sections(s)) ...[
                          label(title),
                          if (rows)
                            grid(width >= 900 ? 3 : (width >= 600 ? 2 : 1), 84 * k, [
                              for (final m in modes) _ModeRow(mode: m, settings: settings, clock: _clock, selected: m == last),
                            ])
                          else
                            grid(width >= 900 ? 4 : (width >= 600 ? 3 : 2), 96 + 110 * k, [
                              for (final m in modes) _ModeTile(mode: m, settings: settings, clock: _clock, selected: m == last),
                            ]),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A game on the games page: its scene, what it is, how many modes, and the
/// last one played (or its best).
class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.settings, required this.clock, required this.onTap});

  final _Game game;
  final Settings settings;
  final Animation<double> clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final last = _PlayMode.fromName(settings.lastPlay);
    final selected = _Game.of(last) == game;
    final several = game.modes.length > 1;
    final fresh = game.isNew && !game.modes.any((m) => _played(settings, m));
    String? line;
    var lineIcon = Icons.emoji_events_rounded;
    if (selected && several) {
      line = s.lastPlayedShort(last.title(s));
      lineIcon = Icons.history_rounded;
    } else {
      for (final m in game.modes) {
        line ??= m.record(settings, s);
      }
    }
    return Semantics(
      button: true,
      label: game.title(s),
      child: GestureDetector(
        key: ValueKey('game-${game.name}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: _cardBox(p, selected: selected),
          child: LayoutBuilder(
            builder: (context, box) {
              final scene = _ModeScene(mode: game.modes.first, clock: clock);
              final title = Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        game.title(s),
                        maxLines: 1,
                        style: TextStyle(fontSize: _fs(p, 18), height: 1.15, fontWeight: FontWeight.w900, color: p.text),
                      ),
                    ),
                  ),
                  if (fresh) _Tag(s.newBadge, color: _newTone, ink: Colors.white),
                ],
              );
              final blurb = Text(
                game.blurb(s),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: _fs(p, 12.5), height: 1.2, fontWeight: FontWeight.w700, color: _second(p)),
              );
              final tags = Row(
                children: [
                  if (several) ...[_Tag(s.modeCount(game.modes.length)), const SizedBox(width: 8)],
                  if (line != null) ...[
                    GameIcon(lineIcon, size: 14, color: selected && several ? p.accent1 : const Color(0xFFFACC15)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: _fs(p, 12), fontWeight: FontWeight.w800, color: p.text),
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              );
              final go = GameIcon(
                several ? Icons.chevron_right_rounded : Icons.play_arrow_rounded,
                size: 28,
                color: several ? _second(p) : const Color(0xFFFACC15),
              );
              // A tall card (tablets, desktops): the scene on top.
              if (box.maxHeight >= 180) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: scene),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [title, const SizedBox(height: 2), blurb, const SizedBox(height: 6), tags],
                            ),
                          ),
                          const SizedBox(width: 4),
                          go,
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(aspectRatio: 1.2, child: scene),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 2), blurb, const Spacer(), tags],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Center(child: go),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The scene of a mode with its tags on it.
class _TaggedScene extends StatelessWidget {
  const _TaggedScene({required this.mode, required this.settings, required this.clock, this.main = false});

  final _PlayMode mode;
  final Settings settings;
  final Animation<double> clock;
  final bool main;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final tag = _sceneTag(mode, s);
    final fresh = mode.isNew && !_played(settings, mode);
    return Stack(
      fit: StackFit.expand,
      children: [
        _ModeScene(mode: mode, clock: clock, scene: _modeSceneOf(mode)),
        if (main)
          Positioned(
            left: 8,
            top: 8,
            child: _Tag(s.mainModeTag, color: const Color(0xE61A1330), ink: const Color(0xFFFACC15), icon: Icons.star_rounded),
          )
        else if (tag != null)
          Positioned(left: 6, top: 6, child: _Tag(tag, color: const Color(0xE61A1330), ink: Colors.white)),
        if (fresh) Positioned(right: 6, top: 6, child: _Tag(s.newBadge, color: _newTone, ink: Colors.white)),
      ],
    );
  }
}

/// A game's main mode: a large scene, where you are and a button.
class _FeaturedMode extends StatelessWidget {
  const _FeaturedMode({required this.mode, required this.settings, required this.clock, required this.wide, this.scale = 1});

  final _PlayMode mode;
  final Settings settings;
  final Animation<double> clock;

  /// Scene beside the text instead of above it.
  final bool wide;

  /// Grows the card with the text.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final info = _cardInfo(mode, settings, s);
    final status = info.line == mode.subtitle(s) ? null : info.line;
    final going = info.badge == s.badgeContinue || (info.progress ?? 0) > 0;
    final scene = _TaggedScene(mode: mode, settings: settings, clock: clock, main: true);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mode.title(s),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: _fs(p, 22), height: 1.15, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 2),
        Text(
          mode.subtitle(s),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: _fs(p, 13), height: 1.2, fontWeight: FontWeight.w700, color: _second(p)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status != null)
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: _fs(p, 12.5), fontWeight: FontWeight.w800, color: p.text),
                    ),
                  if (info.progress != null) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(value: info.progress, backgroundColor: p.track, valueColor: AlwaysStoppedAnimation(info.badgeColors.first)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _PlayPill(label: going ? s.badgeContinue : s.play),
          ],
        ),
      ],
    );
    return Semantics(
      button: true,
      label: mode.title(s),
      child: GestureDetector(
        key: ValueKey('mode-${mode.name}'),
        onTap: () => Navigator.of(context).pop(mode),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: _cardBox(p, selected: true, radius: 24),
          child: wide
              ? SizedBox(
                  height: 190 * scale,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(aspectRatio: 1.9, child: scene),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Center(child: text)),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 150, child: scene),
                    Padding(padding: const EdgeInsets.fromLTRB(6, 10, 4, 4), child: text),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The green button of the main mode's card (the card itself takes the tap).
class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    const green = [Color(0xFF6BF0A0), Color(0xFF1FB85A)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
      decoration: p.flat
          ? flatCardDecoration(p, radius: p.skin == GameSkin.pixel ? 4 : 18, fill: green.last, depth: 4)
          : BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: green, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              boxShadow: [BoxShadow(color: green.last.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
      child: Text(
        label,
        style: TextStyle(fontSize: _fs(p, 16), height: 1.1, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
      ),
    );
  }
}

/// The record line of a mode card.
class _RecordLine extends StatelessWidget {
  const _RecordLine({required this.record});

  final String? record;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Row(
      children: [
        GameIcon(Icons.emoji_events_rounded, size: 14, color: record == null ? p.label : const Color(0xFFFACC15)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            record ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: _fs(p, 12), fontWeight: FontWeight.w800, color: record == null ? p.label : p.text),
          ),
        ),
      ],
    );
  }
}

/// A mode as a card: its scene on top, name, line and record.
class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.settings, required this.clock, required this.selected});

  final _PlayMode mode;
  final Settings settings;
  final Animation<double> clock;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    return Semantics(
      button: true,
      label: mode.title(s),
      child: GestureDetector(
        key: ValueKey('mode-${mode.name}'),
        onTap: () => Navigator.of(context).pop(mode),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: _cardBox(p, selected: selected),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 96, child: _TaggedScene(mode: mode, settings: settings, clock: clock)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    mode.title(s),
                    maxLines: 1,
                    style: TextStyle(fontSize: _fs(p, 16), height: 1.15, fontWeight: FontWeight.w900, color: p.text),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  mode.subtitle(s),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: _fs(p, 11.5), height: 1.2, fontWeight: FontWeight.w700, color: _second(p)),
                ),
              ),
              const Spacer(),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _RecordLine(record: mode.record(settings, s))),
            ],
          ),
        ),
      ),
    );
  }
}

/// A mode as a compact row: scene on the left, name and line, record.
class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.mode, required this.settings, required this.clock, required this.selected});

  final _PlayMode mode;
  final Settings settings;
  final Animation<double> clock;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final record = mode.record(settings, s);
    return Semantics(
      button: true,
      label: mode.title(s),
      child: GestureDetector(
        key: ValueKey('mode-${mode.name}'),
        onTap: () => Navigator.of(context).pop(mode),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: _cardBox(p, selected: selected, radius: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(aspectRatio: 1.55, child: _TaggedScene(mode: mode, settings: settings, clock: clock)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mode.title(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: _fs(p, 16), height: 1.15, fontWeight: FontWeight.w900, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.subtitle(s),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: _fs(p, 11.5), height: 1.2, fontWeight: FontWeight.w700, color: _second(p)),
                    ),
                  ],
                ),
              ),
              if (record != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GameIcon(Icons.emoji_events_rounded, size: 15, color: Color(0xFFFACC15)),
                      Text(
                        record,
                        style: TextStyle(fontSize: _fs(p, 12), fontWeight: FontWeight.w800, color: p.text),
                      ),
                    ],
                  ),
                )
              else
                Center(child: GameIcon(Icons.chevron_right_rounded, size: 26, color: _second(p))),
            ],
          ),
        ),
      ),
    );
  }
}
