import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/audio_service.dart';
import '../audio/haptics.dart';
import '../core/blocks/block_puzzle.dart';
import '../core/blocks/level_generator.dart';
import '../core/tetromino.dart';
import '../game/blocks/blocks_controller.dart';
import '../game/blocks/blocks_painters.dart';
import '../game/render/background_painter.dart';
import '../game/render/block_sprites.dart';
import '../game/render/board_painter.dart';
import '../l10n/strings.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'about_page.dart';
import 'game_screen.dart' show SettingsPanel;
import 'widgets.dart';

const _gold = Color(0xFFFBBF24);
const _puzzleColors = [Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFEAB308)];

/// "Bulmaca Küpler": drag-and-drop block puzzle with 100 levels and an
/// endless mode. Opened from the main menu as its own screen.
class BlocksScreen extends StatefulWidget {
  const BlocksScreen({super.key, required this.settings, required this.audio, this.haptics});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;

  static Future<void> open(BuildContext context, {required Settings settings, required AudioService audio, Haptics? haptics}) =>
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => BlocksScreen(settings: settings, audio: audio, haptics: haptics),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );

  @override
  State<BlocksScreen> createState() => _BlocksScreenState();
}

class _BlocksScreenState extends State<BlocksScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BlocksController c = BlocksController(settings: widget.settings, audio: widget.audio, haptics: widget.haptics);
  late final Ticker _ticker = createTicker(c.tick);
  final FocusNode _focus = FocusNode(debugLabel: 'blocks');
  final GlobalKey _rootKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) c.pauseIfRunning();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    c.dispose();
    super.dispose();
  }

  void _back() {
    switch (c.view) {
      case BlocksView.menu:
        Navigator.of(context).maybePop();
      case BlocksView.levels:
        c.openMenu();
      case BlocksView.playing:
        if (c.game.isOver) {
          c.isEndless ? c.openMenu() : c.openLevels();
        } else {
          c.togglePause();
        }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
      _back();
      return KeyEventResult.handled;
    }
    final altEnter = key == LogicalKeyboardKey.enter && HardwareKeyboard.instance.isAltPressed;
    if (key == LogicalKeyboardKey.f11 || altEnter) {
      widget.settings.fullScreen = !widget.settings.fullScreen;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Offset _rootOrigin() {
    final box = _rootKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? Offset.zero : box.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    c.strings = AppStrings.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) c.view == BlocksView.menu ? Navigator.of(context).pop() : _back();
      },
      child: Scaffold(
        backgroundColor: palette.background.first,
        body: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Stack(
            key: _rootKey,
            children: [
              Positioned.fill(
                child: RepaintBoundary(child: CustomPaint(painter: BackgroundBasePainter(palette))),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: widget.settings,
                    builder: (context, _) => CustomPaint(
                      painter: BackgroundPainter(
                        fx: c.fx,
                        palette: palette,
                        sprites: BlockSprites.of(24, dpr, palette),
                        effectsEnabled: widget.settings.effects,
                        repaint: c.backgroundFrame,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: ListenableBuilder(
                  listenable: Listenable.merge([c, widget.settings]),
                  builder: (context, _) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (c.view) {
                      BlocksView.menu => _Menu(key: const ValueKey('menu'), c: c),
                      BlocksView.levels => _LevelSelect(key: const ValueKey('levels'), c: c),
                      BlocksView.playing => _PlayView(key: const ValueKey('play'), c: c),
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: Listenable.merge([c, widget.settings]),
                  builder: (context, _) => AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _overlay()),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ListenableBuilder(
                    listenable: c,
                    builder: (context, _) {
                      final cell = c.boardCell;
                      if (c.dragSlot == null || cell <= 0) return const SizedBox.shrink();
                      return RepaintBoundary(
                        child: CustomPaint(
                          painter: DragPiecePainter(controller: c, sprites: BlockSprites.of(cell, dpr, palette), globalOrigin: _rootOrigin),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlay() {
    if (c.view != BlocksView.playing) return const SizedBox.shrink(key: ValueKey('none'));
    if (c.showResult) {
      if (c.isEndless) return _EndlessOver(key: const ValueKey('over'), c: c);
      return _LevelResult(key: ValueKey('result-${c.game.status}'), c: c);
    }
    if (c.paused) return _Pause(key: const ValueKey('pause'), c: c);
    return const SizedBox.shrink(key: ValueKey('none'));
  }
}

// ---------------------------------------------------------------- shared

class _Panel extends StatelessWidget {
  const _Panel({required this.children, this.landscapeTail = 0, this.maxWidth = 420, this.scrim = false});

  final List<Widget> children;

  /// On a phone held sideways, the last [landscapeTail] children (usually
  /// the buttons) move to a second column so nothing has to scroll.
  final int landscapeTail;
  final double maxWidth;
  final bool scrim;

  bool _split(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return landscapeTail > 0 && landscapeTail < children.length && size.width > size.height * 1.2 && size.height < 520;
  }

  Widget _content(BuildContext context) {
    Widget column(List<Widget> items) =>
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: items);
    if (!_split(context)) return column(children);
    final cut = children.length - landscapeTail;
    final tail = children.sublist(cut);
    // A leading spacer only made sense below the content.
    if (tail.first is SizedBox && (tail.first as SizedBox).child == null) tail.removeAt(0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: column(children.sublist(0, cut))),
        const SizedBox(width: 24),
        Expanded(child: column(tail)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final card = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _split(context) ? max(maxWidth, 760) : maxWidth),
          child: GlassCard(radius: 28, padding: const EdgeInsets.fromLTRB(24, 24, 24, 22), child: _content(context)),
        ),
      ),
    );
    if (!scrim) return card;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: p.background.first.withValues(alpha: p.isDark ? 0.84 : 0.8)),
        ),
        SafeArea(child: card),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: GradientText(
      AppStrings.of(context).puzzleTitle,
      gradient: const LinearGradient(colors: _puzzleColors),
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -0.5),
    ),
  );
}

class _Stars extends StatelessWidget {
  const _Stars({required this.count, this.size = 14, this.off});

  final int count;
  final double size;
  final Color? off;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++) Icon(Icons.star_rounded, size: size, color: i < count ? _gold : (off ?? GamePalette.of(context).track)),
    ],
  );
}

// ---------------------------------------------------------------- menu

class _Menu extends StatelessWidget {
  const _Menu({super.key, required this.c});

  final BlocksController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final settings = c.settings;
    final next = settings.unlockedBlockLevel;
    final finished = next > BlockLevels.count;
    return _Panel(
      landscapeTail: 6,
      children: [
        Row(
          children: [
            GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: s.back, size: 36, onTap: () => Navigator.of(context).maybePop()),
            const Spacer(),
            GlassIconButton(
              icon: settings.music ? Icons.music_note_rounded : Icons.music_off_rounded,
              tooltip: s.music,
              size: 36,
              onTap: () => settings.music = !settings.music,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Center(child: _Title(size: 32)),
        const SizedBox(height: 4),
        Text(
          s.blocksSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: p.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        const _MenuArt(),
        const SizedBox(height: 14),
        Text(
          s.blocksHowTo,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.45, color: p.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        GradientButton(
          key: const ValueKey('blocks-continue'),
          label: finished ? s.allLevelsDone : s.continueLevel(next),
          subtitle: s.levelsModeSubtitle,
          icon: Icons.play_arrow_rounded,
          colors: _puzzleColors,
          onTap: () => finished ? c.openLevels() : c.startLevel(next),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                key: const ValueKey('blocks-levels'),
                label: s.levelsMode,
                subtitle: '★ ${settings.totalBlockStars}/${BlockLevels.count * 3}',
                icon: Icons.grid_view_rounded,
                secondary: true,
                onTap: c.openLevels,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(
                key: const ValueKey('blocks-endless'),
                label: s.endlessMode,
                subtitle: settings.blocksBest > 0 ? '${s.bestPrefix}${s.score(settings.blocksBest)}' : s.endlessModeSubtitle,
                icon: Icons.all_inclusive_rounded,
                secondary: true,
                onTap: c.startEndless,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => AboutPage.open(context, settings),
          icon: Icon(Icons.info_outline_rounded, size: 16, color: p.muted),
          label: Text(
            s.about,
            style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// A tiny board with a row about to blast, as a picture of the rules.
class _MenuArt extends StatelessWidget {
  const _MenuArt();

  static const _rows = ['..L.....', 'TTT.*SSS', 'JJZZ.OO.', '.J.ZZOO.'];

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final sprites = BlockSprites.of(20, MediaQuery.devicePixelRatioOf(context), p);
    return Center(
      child: SizedBox(
        width: 8 * 20,
        height: 4 * 20,
        child: CustomPaint(painter: _ArtPainter(sprites)),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.sprites);

  final BlockSprites sprites;

  @override
  void paint(Canvas canvas, Size size) {
    final c = sprites.cell;
    for (var y = 0; y < _MenuArt._rows.length; y++) {
      for (var x = 0; x < 8; x++) {
        final ch = _MenuArt._rows[y][x];
        if (ch == '.') continue;
        final cell = BlockPuzzleGame.parseCell(ch)!;
        sprites.draw(canvas, sprites.block(cell.gem ? PieceType.gem : cell.color), x * c, y * c);
      }
    }
    // The missing block of row 1, hovering in place.
    sprites.draw(canvas, sprites.block(PieceType.t), 3 * c, 1 * c, opacity: 0.5);
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) => old.sprites != sprites;
}

// ---------------------------------------------------------------- level select

class _LevelSelect extends StatefulWidget {
  const _LevelSelect({super.key, required this.c});

  final BlocksController c;

  @override
  State<_LevelSelect> createState() => _LevelSelectState();
}

class _LevelSelectState extends State<_LevelSelect> {
  final GlobalKey _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Open where the player left off instead of at level 1.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.4);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final settings = c.settings;
    final unlocked = settings.unlockedBlockLevel;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    const chapters = BlockLevels.count ~/ BlockLevels.perChapter;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 820 : 460),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: s.back, onTap: c.openMenu, size: 38),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Align(alignment: Alignment.centerLeft, child: _Title(size: 24)),
                  ),
                  const Icon(Icons.star_rounded, color: _gold, size: 20),
                  const SizedBox(width: 2),
                  Text(
                    '${settings.totalBlockStars}/${BlockLevels.count * 3}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                s.blocksGoal,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.muted, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                children: [
                  for (var ch = 1; ch <= chapters; ch++) ...[
                    Padding(padding: const EdgeInsets.fromLTRB(4, 14, 0, 8), child: CardLabel(s.chapter(ch).toUpperCase())),
                    GridView.count(
                      crossAxisCount: wide ? 10 : 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.92,
                      children: [
                        for (var n = (ch - 1) * BlockLevels.perChapter + 1; n <= ch * BlockLevels.perChapter; n++)
                          _LevelTile(
                            key: n == unlocked ? _currentKey : ValueKey('level-$n'),
                            number: n,
                            stars: settings.blockStars(n),
                            locked: n > unlocked,
                            current: n == unlocked,
                            onTap: () => c.startLevel(n),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    super.key,
    required this.number,
    required this.stars,
    required this.locked,
    required this.current,
    required this.onTap,
  });

  final int number;
  final int stars;
  final bool locked;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final tile = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: current ? const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF22C55E)]) : null,
        color: current ? null : (locked ? p.track.withValues(alpha: 0.5) : p.glass),
        border: Border.all(color: stars > 0 ? _gold.withValues(alpha: 0.7) : p.glassBorder),
        boxShadow: current ? const [BoxShadow(color: Color(0x6614B8A6), blurRadius: 14)] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          locked
              ? Icon(Icons.lock_rounded, size: 18, color: p.label)
              : Text(
                  '$number',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: current ? Colors.white : p.text),
                ),
          const SizedBox(height: 3),
          _Stars(count: stars, size: 11, off: current ? Colors.white54 : null),
        ],
      ),
    );
    if (locked) return Tooltip(message: AppStrings.of(context).locked, child: tile);
    return GestureDetector(onTap: onTap, child: tile);
  }
}

// ---------------------------------------------------------------- play

class _PlayView extends StatelessWidget {
  const _PlayView({super.key, required this.c});

  final BlocksController c;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 720 && box.maxWidth > box.maxHeight * 1.1;
        return wide ? _WideLayout(c: c) : _PhoneLayout(c: c);
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.c, this.icons = true});

  final BlocksController c;

  /// Theme and music buttons (moved elsewhere on short landscape screens).
  final bool icons;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = c.settings;
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        GlassIconButton(icon: Icons.pause_rounded, tooltip: s.pause, onTap: c.togglePause),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: GradientText(
                c.isEndless ? s.endlessMode : s.levelNumber(c.level!.number),
                gradient: const LinearGradient(colors: _puzzleColors),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        if (icons) ...[
          GlassIconButton(
            icon: brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: s.theme,
            onTap: () => settings.toggleTheme(brightness),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: settings.music ? Icons.music_note_rounded : Icons.music_off_rounded,
            tooltip: s.music,
            onTap: () => settings.music = !settings.music,
          ),
        ],
      ],
    );
  }
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value, this.icon, this.pulse = 0, this.alert = false});

  final String label;
  final String value;
  final IconData? icon;
  final double pulse;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardLabel(label),
        const SizedBox(height: 2),
        Transform.scale(
          alignment: Alignment.centerLeft,
          scale: 1 + 0.15 * pulse,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, color: _gold, size: 22), const SizedBox(width: 2)],
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: alert ? const Color(0xFFF87171) : p.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.c, this.vertical = false});

  final BlocksController c;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = GamePalette.of(context);
    final game = c.game;
    final level = c.level;
    final values = level == null
        ? [
            _HudValue(label: s.scoreLabel, value: s.score(game.score), pulse: c.fx.scorePulse),
            _HudValue(label: s.bestLabel, value: s.score(max(c.settings.blocksBest, game.score))),
          ]
        : [
            _HudValue(label: s.gemsLeft, value: '${game.gemsLeft}', icon: Icons.star_rounded, pulse: c.fx.gemPulse),
            _HudValue(label: s.movesLeft, value: '${game.movesLeft}', alert: game.movesLeft <= 3),
            _HudValue(label: s.scoreLabel, value: s.score(game.score), pulse: c.fx.scorePulse),
          ];
    final hint = level == null
        ? null
        : Text(
            s.threeStars(level.par),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.muted),
          );
    if (vertical) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final v in values) Padding(padding: const EdgeInsets.only(bottom: 14), child: v),
            ?hint,
          ],
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final v in values)
                Flexible(
                  child: FittedBox(fit: BoxFit.scaleDown, child: v),
                ),
            ],
          ),
          if (hint != null) ...[const SizedBox(height: 4), Center(child: hint)],
        ],
      ),
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({required this.c});

  final BlocksController c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: LayoutBuilder(
        builder: (context, box) {
          // Board as large as fits, with room for the tray below it.
          final boardSide = min(box.maxWidth, (box.maxHeight - 170) / 1.33);
          final cell = BlocksGeometry.fit(boardSide);
          final trayHeight = (cell * 2.9).clamp(84.0, 150.0);
          return Column(
            children: [
              _TopBar(c: c),
              const SizedBox(height: 10),
              _Hud(c: c),
              Expanded(
                child: Center(
                  child: _Board(c: c, cell: cell),
                ),
              ),
              SizedBox(
                height: trayHeight,
                child: _Tray(c: c, cell: cell),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.c});

  final BlocksController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final settings = c.settings;
    final brightness = Theme.of(context).brightness;
    final size = MediaQuery.sizeOf(context);
    // Phones held sideways: slimmer side panels so the board can use the
    // full height; theme and music move to the bottom-left corner.
    final short = size.height < 520;
    final side = short ? (size.width * 0.22).clamp(150.0, 240.0) : (size.width * 0.2).clamp(210.0, 280.0);
    return Padding(
      padding: short ? const EdgeInsets.fromLTRB(14, 8, 14, 8) : const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final cell = BlocksGeometry.fit(min(box.maxWidth - 2 * side - (short ? 24 : 64), box.maxHeight - (short ? 4 : 24)));
          final panel = short
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(c: c, icons: false),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(child: _Hud(c: c, vertical: true)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GlassIconButton(
                          icon: settings.music ? Icons.music_note_rounded : Icons.music_off_rounded,
                          tooltip: s.music,
                          size: 36,
                          onTap: () => settings.music = !settings.music,
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          tooltip: s.theme,
                          size: 36,
                          onTap: () => settings.toggleTheme(brightness),
                        ),
                      ],
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(c: c),
                      const SizedBox(height: 16),
                      _Hud(c: c, vertical: true),
                      const SizedBox(height: 16),
                      Text(
                        c.isEndless ? s.blocksHowTo : s.blocksGoal,
                        style: TextStyle(fontSize: 13, height: 1.45, color: p.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: side, child: panel),
              Expanded(
                child: Center(
                  child: _Board(c: c, cell: cell),
                ),
              ),
              SizedBox(
                width: side,
                child: _Tray(c: c, cell: cell, vertical: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Board extends StatefulWidget {
  const _Board({required this.c, required this.cell});

  final BlocksController c;
  final double cell;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final cell = widget.cell;
    final palette = GamePalette.of(context);
    final geometry = BlocksGeometry(cell);
    final sprites = BlockSprites.of(cell, MediaQuery.devicePixelRatioOf(context), palette);
    c.boardRect = () {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return Rect.zero;
      final origin = box.localToGlobal(Offset(geometry.pad, geometry.pad));
      return origin & Size(geometry.grid, geometry.grid);
    };
    return SizedBox(
      key: _key,
      width: geometry.frame,
      height: geometry.frame,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -geometry.margin,
            top: -geometry.margin,
            child: RepaintBoundary(
              child: CustomPaint(
                size: geometry.canvas,
                painter: BlocksBoardPainter(controller: c, sprites: sprites, palette: palette, geometry: geometry),
              ),
            ),
          ),
          Positioned(
            left: -geometry.margin,
            top: -geometry.margin,
            child: IgnorePointer(
              child: CustomPaint(
                size: geometry.canvas,
                painter: FloaterPainter(floaters: c.fx.floaters, cell: cell, origin: geometry.gridOrigin, repaint: c.frame),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tray extends StatelessWidget {
  const _Tray({required this.c, required this.cell, this.vertical = false});

  final BlocksController c;
  final double cell;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final slots = [
      for (var i = 0; i < 3; i++)
        Expanded(
          child: _TraySlot(c: c, slot: i, boardCell: cell),
        ),
    ];
    return vertical
        ? Column(
            children: [
              for (final (i, s) in slots.indexed) ...[if (i > 0) const SizedBox(height: 12), s],
            ],
          )
        : Row(
            children: [
              for (final (i, s) in slots.indexed) ...[if (i > 0) const SizedBox(width: 10), s],
            ],
          );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({required this.c, required this.slot, required this.boardCell});

  final BlocksController c;
  final int slot;
  final double boardCell;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final shape = c.game.tray[slot];
    final dragging = c.dragSlot == slot;
    final fits = shape != null && c.game.fitsAnywhere(shape);
    final appear = Curves.easeOutBack.transform(((c.fx.trayAge - slot * 0.07) / 0.3).clamp(0.0, 1.0));
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => c.beginDrag(slot, e.position, mouse: e.kind == PointerDeviceKind.mouse),
      onPointerMove: (e) => c.updateDrag(e.position),
      onPointerUp: (_) => c.endDrag(),
      onPointerCancel: (_) => c.abortDrag(),
      child: Container(
        key: ValueKey('tray-$slot'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: p.glass,
          border: Border.all(color: p.glassBorder),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            // Tray pieces are shown smaller than on the board.
            final trayCell = min(boardCell * 0.6, min(box.maxWidth, box.maxHeight) / 5.2);
            final sprites = BlockSprites.of(trayCell, MediaQuery.devicePixelRatioOf(context), p);
            return CustomPaint(
              size: Size(box.maxWidth, box.maxHeight),
              painter: TrayPiecePainter(shape: dragging ? null : shape, sprites: sprites, dimmed: !fits, scale: 0.3 + 0.7 * appear),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- overlays

class _Pause extends StatelessWidget {
  const _Pause({super.key, required this.c});

  final BlocksController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final buttons = [
      Text(
        s.paused,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
      ),
      const SizedBox(height: 18),
      GradientButton(label: s.resume, icon: Icons.play_arrow_rounded, colors: _puzzleColors, onTap: c.togglePause),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: GradientButton(label: s.restart, icon: Icons.replay_rounded, secondary: true, onTap: c.restart),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GradientButton(
              label: c.isEndless ? s.menu : s.levelsMode,
              icon: c.isEndless ? Icons.home_rounded : Icons.grid_view_rounded,
              secondary: true,
              onTap: c.isEndless ? c.openMenu : c.openLevels,
            ),
          ),
        ],
      ),
    ];
    if (MediaQuery.sizeOf(context).width >= 760) {
      return _Panel(
        scrim: true,
        maxWidth: 760,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttons),
              ),
              const SizedBox(width: 28),
              Expanded(child: SettingsPanel(settings: c.settings)),
            ],
          ),
        ],
      );
    }
    return _Panel(
      scrim: true,
      children: [
        ...buttons,
        const SizedBox(height: 18),
        SettingsPanel(settings: c.settings),
      ],
    );
  }
}

class _LevelResult extends StatelessWidget {
  const _LevelResult({super.key, required this.c});

  final BlocksController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final game = c.game;
    final level = c.level!;
    final won = game.status == BlockStatus.won;
    final last = level.number >= BlockLevels.count;
    return _Panel(
      landscapeTail: won && !last ? 6 : 4,
      scrim: true,
      children: [
        Center(child: CardLabel(s.levelNumber(level.number).toUpperCase())),
        const SizedBox(height: 8),
        Text(
          won ? s.levelCompleteTitle : (game.loss == BlockLoss.outOfMoves ? s.outOfMovesTitle : s.noRoomTitle),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 12),
        if (won) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (var i = 0; i < 3; i++) _PopStar(index: i, on: i < c.lastStars, big: i == 1)],
          ),
          const SizedBox(height: 6),
          Text(
            '${s.movesUsed(game.moves)} · ${s.score(game.score)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, fontWeight: FontWeight.w700),
          ),
        ] else
          Text(
            s.levelFailedHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, height: 1.4),
          ),
        const SizedBox(height: 20),
        if (won && !last) ...[
          GradientButton(
            key: const ValueKey('blocks-next'),
            label: s.nextLevel,
            icon: Icons.arrow_forward_rounded,
            colors: _puzzleColors,
            onTap: c.nextLevel,
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: GradientButton(
                key: const ValueKey('blocks-retry'),
                label: s.sameBoard,
                icon: Icons.replay_rounded,
                secondary: won,
                colors: won ? null : _puzzleColors,
                onTap: c.retryLevel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(label: s.newBoard, icon: Icons.casino_rounded, secondary: true, onTap: c.restart),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GradientButton(label: s.levelsMode, icon: Icons.grid_view_rounded, secondary: true, onTap: c.openLevels),
      ],
    );
  }
}

/// A result star that pops in one after another.
class _PopStar extends StatelessWidget {
  const _PopStar({required this.index, required this.on, required this.big});

  final int index;
  final bool on;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 160),
      curve: Interval(index * 0.25, 1, curve: Curves.elasticOut),
      builder: (context, t, child) => Transform.scale(scale: on ? t : 1, child: child),
      child: Padding(
        padding: EdgeInsets.only(bottom: big ? 10 : 0),
        child: Icon(
          Icons.star_rounded,
          size: big ? 64 : 50,
          color: on ? _gold : p.track,
          shadows: on ? const [Shadow(color: Color(0x99F59E0B), blurRadius: 18)] : null,
        ),
      ),
    );
  }
}

class _EndlessOver extends StatelessWidget {
  const _EndlessOver({super.key, required this.c});

  final BlocksController c;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final game = c.game;
    return _Panel(
      landscapeTail: 4,
      scrim: true,
      children: [
        Text(
          s.noRoomTitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: p.text),
        ),
        const SizedBox(height: 10),
        if (c.newRecord)
          Center(
            child: GradientText(
              s.newRecord,
              gradient: const LinearGradient(colors: [Color(0xFFFDE047), Color(0xFFF97316)]),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
        const SizedBox(height: 6),
        Center(
          child: GradientText(
            s.score(game.score),
            gradient: const LinearGradient(colors: _puzzleColors),
            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${s.linesLabel} ${game.lines} · ${s.bestPrefix}${s.score(c.settings.blocksBest)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        GradientButton(
          key: const ValueKey('blocks-again'),
          label: s.playAgain,
          icon: Icons.replay_rounded,
          colors: _puzzleColors,
          onTap: c.startEndless,
        ),
        const SizedBox(height: 10),
        GradientButton(label: s.menu, icon: Icons.home_rounded, secondary: true, onTap: c.openMenu),
      ],
    );
  }
}
