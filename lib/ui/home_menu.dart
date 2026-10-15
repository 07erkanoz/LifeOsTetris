part of 'game_screen.dart';

// ---------------------------------------------------------------- modes

enum _ModeGroup { superGroup, classic, puzzle, challenges }

/// Everything the play button and the modes page can start.
enum _PlayMode {
  superMode(_ModeGroup.superGroup),
  normal(_ModeGroup.classic),
  relaxed(_ModeGroup.classic),
  blocksLevels(_ModeGroup.puzzle),
  blocksEndless(_ModeGroup.puzzle),
  adventure(_ModeGroup.puzzle, soon: true),
  sprint(_ModeGroup.challenges),
  ultra(_ModeGroup.challenges),
  dig(_ModeGroup.challenges),
  bomb(_ModeGroup.challenges, soon: true),
  target(_ModeGroup.challenges, soon: true),
  chaos(_ModeGroup.challenges, soon: true);

  const _PlayMode(this.group, {this.soon = false});

  final _ModeGroup group;

  /// Shown but not playable yet.
  final bool soon;

  static _PlayMode fromName(String? name) => values.firstWhere((m) => m.name == name && !m.soon, orElse: () => _PlayMode.superMode);

  /// The falling-block mode behind it, if any.
  GameMode? get gameMode => switch (this) {
    _PlayMode.normal => GameMode.classic,
    _PlayMode.relaxed => GameMode.relaxed,
    _PlayMode.superMode => GameMode.superMode,
    _PlayMode.sprint => GameMode.sprint,
    _PlayMode.ultra => GameMode.ultra,
    _PlayMode.dig => GameMode.dig,
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
    _PlayMode.target => s.targetTitle,
    _PlayMode.chaos => s.chaosTitle,
  };

  /// Title with its family, for the play button ("Klasik · Normal").
  String fullTitle(AppStrings s) => switch (group) {
    _ModeGroup.classic => '${s.classicTitle} · ${title(s)}',
    _ModeGroup.puzzle => '${s.puzzleTitle} · ${title(s)}',
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
    _PlayMode.target => s.targetSubtitle,
    _PlayMode.chaos => s.chaosSubtitle,
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
    _PlayMode.target => Icons.star_rounded,
    _PlayMode.chaos => Icons.casino_rounded,
  };

  /// Badge colour, from the theme's own blocks.
  Color tone() =>
      blockColors[switch (this) {
        _PlayMode.superMode => PieceType.t,
        _PlayMode.normal => PieceType.j,
        _PlayMode.relaxed => PieceType.s,
        _PlayMode.blocksLevels || _PlayMode.blocksEndless || _PlayMode.adventure => PieceType.i,
        _PlayMode.sprint => PieceType.i,
        _PlayMode.ultra => PieceType.l,
        _PlayMode.dig => PieceType.s,
        _PlayMode.bomb => PieceType.z,
        _PlayMode.target => PieceType.o,
        _PlayMode.chaos => PieceType.t,
      }]!;

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
      _PlayMode.blocksLevels => settings.totalBlockStars > 0 ? '★ ${settings.totalBlockStars}/${BlockLevels.count * 3}' : null,
      _PlayMode.blocksEndless => settings.blocksBest > 0 ? s.score(settings.blocksBest) : null,
      _ => null,
    };
  }
}

/// Starts [mode] and remembers it for the play button.
void _launch(BuildContext context, GameController c, _PlayMode mode) {
  if (mode.soon) return;
  c.settings.lastPlay = mode.name;
  final game = mode.gameMode;
  if (game != null) {
    c.start(game);
    return;
  }
  BlocksScreen.open(
    context,
    settings: c.settings,
    audio: c.audio,
    haptics: c.haptics,
    entry: mode == _PlayMode.blocksEndless ? BlocksEntry.endless : BlocksEntry.levels,
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

// ---------------------------------------------------------------- home

/// The start screen: continue, one big play button for the last mode, the
/// daily puzzle and a row of small buttons. Every mode lives on its own
/// page ([_ModesPage]).
class _StartOverlay extends StatelessWidget {
  const _StartOverlay({super.key, required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final last = _PlayMode.fromName(c.settings.lastPlay);
    final saved = c.savedSummary;

    final best = c.settings.topScore > 0
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GameIcon(Icons.emoji_events_rounded, color: Color(0xFFFACC15), size: 20),
              const SizedBox(width: 6),
              Text(
                s.bestPrefix,
                style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
              ),
              GradientText(s.score(c.settings.topScore), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          )
        : null;
    final brand = <Widget>[
      const Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: LogoTitle(fontSize: 32)),
      ),
      const SizedBox(height: 8),
      Text(
        s.tagline,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: p.muted, fontWeight: FontWeight.w600),
      ),
      if (best != null) ...[const SizedBox(height: 12), best],
    ];
    final play = <Widget>[
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
      _PlayButton(mode: last, onTap: () => _launch(context, c, last)),
      const SizedBox(height: 4),
      Center(
        child: TextButton(
          key: const ValueKey('change-mode'),
          onPressed: () => _openModes(context, c),
          child: Text(
            '${s.changeMode} ›',
            style: TextStyle(color: p.muted, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: 6),
      DailyPuzzleButton(
        settings: c.settings,
        onTap: () => BlocksScreen.open(context, settings: c.settings, audio: c.audio, haptics: c.haptics, entry: BlocksEntry.daily),
      ),
    ];
    final shortcuts = Row(
      children: [
        for (final (i, (key, icon, label, onTap)) in [
          ('open-modes', Icons.grid_view_rounded, s.modesTitle, () => _openModes(context, c)),
          ('open-themes', Icons.palette_rounded, s.themeLabel, () => _ThemeSheet.open(context, c.settings)),
          ('open-settings', Icons.settings_rounded, s.settingsTitle, () => _SettingsSheet.open(context, c.settings)),
          ('open-about', Icons.info_outline_rounded, s.about, () => AboutPage.open(context, c.settings)),
        ].indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ShortcutTile(key: ValueKey(key), icon: icon, label: label, onTap: onTap),
          ),
        ],
      ],
    );

    if (_isShortLandscape(context)) {
      return _OverlayShell(
        maxWidth: 780,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...brand, const SizedBox(height: 16), shortcuts]),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: play),
              ),
            ],
          ),
        ],
      );
    }
    return _OverlayShell(children: [...brand, const SizedBox(height: 20), ...play, const SizedBox(height: 18), shortcuts]);
  }
}

/// The big button: plays the remembered mode.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.mode, required this.onTap});

  final _PlayMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final tone = p.flat ? p.accent1 : null;
    final fg = p.flat && p.accent1.computeLuminance() > 0.45 ? p.ink : Colors.white;
    return GestureDetector(
      key: const ValueKey('play'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: p.flat
            ? flatCardDecoration(p, radius: 26, fill: tone, depth: 6)
            : BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: [p.accent1, p.accent2]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                boxShadow: [BoxShadow(color: p.accent1.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))],
              ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 4 : 16),
              ),
              child: Center(child: GameIcon(Icons.play_arrow_rounded, size: 34, color: fg)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.play,
                    style: TextStyle(color: fg, fontSize: 28, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      GameIcon(mode.icon, size: 16, color: fg.withValues(alpha: 0.85)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          mode.fullTitle(s),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

// ---------------------------------------------------------------- modes page

/// All modes, grouped, as cards with their records. Tapping one returns it.
class _ModesPage extends StatelessWidget {
  const _ModesPage({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final last = _PlayMode.fromName(settings.lastPlay);
    String groupTitle(_ModeGroup g) => switch (g) {
      _ModeGroup.classic => s.classicTitle.toUpperCase(),
      _ModeGroup.superGroup => s.superGroup,
      _ModeGroup.puzzle => s.puzzleGroup,
      _ModeGroup.challenges => s.challengesLabel,
    };
    return Scaffold(
      backgroundColor: p.background.first,
      body: CustomPaint(
        painter: BackgroundBasePainter(p),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 900 ? 4 : (box.maxWidth >= 600 ? 3 : 2);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    children: [
                      Row(
                        children: [
                          GlassIconButton(
                            key: const ValueKey('modes-back'),
                            icon: Icons.arrow_back_rounded,
                            tooltip: s.back,
                            size: 40,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            s.modesTitle,
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
                          ),
                        ],
                      ),
                      for (final group in _ModeGroup.values) ...[
                        const SizedBox(height: 18),
                        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: CardLabel(groupTitle(group))),
                        // A group of one (Süper Küpler) gets a wide card.
                        if (_PlayMode.values.where((m) => m.group == group).length == 1)
                          for (final mode in _PlayMode.values.where((m) => m.group == group))
                            SizedBox(
                              height: 104,
                              child: _ModeCard(mode: mode, selected: mode == last, record: mode.record(settings, s), wide: true),
                            )
                        else
                          GridView(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 160,
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (final mode in _PlayMode.values.where((m) => m.group == group))
                                _ModeCard(mode: mode, selected: mode == last, record: mode.record(settings, s)),
                            ],
                          ),
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.selected, required this.record, this.wide = false});

  final _PlayMode mode;
  final bool selected;
  final String? record;

  /// Badge on the left and text beside it, for a full-width card.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final tone = mode.tone();
    final badge = tone.computeLuminance() > 0.45 ? p.ink : Colors.white;
    final badgeBox = Container(
      width: wide ? 52 : 38,
      height: wide ? 52 : 38,
      decoration: p.flat
          ? flatCardDecoration(p, radius: 13, fill: tone, depth: 2)
          : BoxDecoration(color: tone, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: GameIcon(mode.icon, size: wide ? 28 : 22, color: badge),
      ),
    );
    final soonChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: p.flat
          ? flatCardDecoration(p, radius: 10, fill: p.track, depth: 0)
          : BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(10)),
      child: Text(
        s.comingSoon,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: p.muted),
      ),
    );
    final title = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        mode.title(s),
        maxLines: 1,
        style: TextStyle(fontSize: wide ? 19 : 16, height: 1.15, fontWeight: FontWeight.w800, color: p.text),
      ),
    );
    final subtitle = Text(
      mode.subtitle(s),
      maxLines: wide ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, height: 1.25, fontWeight: FontWeight.w600, color: p.muted),
    );
    final recordRow = Row(
      children: [
        GameIcon(Icons.emoji_events_rounded, size: 14, color: record == null ? p.label : const Color(0xFFFACC15)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            record ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: record == null ? p.label : p.text),
          ),
        ),
      ],
    );
    final card = Container(
      padding: wide ? const EdgeInsets.fromLTRB(16, 12, 16, 12) : const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: p.flat
          ? flatCardDecoration(p, radius: 20, depth: 4, glow: selected ? 1 : 0)
          : BoxDecoration(
              color: p.glass,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? p.accent1 : p.glassBorder, width: selected ? 2.5 : 1.5),
            ),
      child: wide
          ? Row(
              children: [
                badgeBox,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 2), subtitle, const SizedBox(height: 4), recordRow],
                  ),
                ),
                if (mode.soon) soonChip,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badgeBox,
                    const SizedBox(width: 6),
                    if (mode.soon)
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: FittedBox(fit: BoxFit.scaleDown, child: soonChip),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                title,
                const SizedBox(height: 2),
                Flexible(child: subtitle),
                const SizedBox(height: 4),
                recordRow,
              ],
            ),
    );
    return Semantics(
      button: !mode.soon,
      label: mode.title(s),
      child: GestureDetector(
        key: ValueKey('mode-${mode.name}'),
        onTap: mode.soon ? null : () => Navigator.of(context).pop(mode),
        child: Opacity(opacity: mode.soon ? 0.5 : 1, child: card),
      ),
    );
  }
}
