part of 'game_screen.dart';

// ------------------------------------------------------- games showcase

/// What a game is, in two words, on its tile; its colours; its tile and
/// showcase picture.
extension on _Game {
  String kind(AppStrings s) => switch (this) {
    _Game.tower => s.towerKind,
    _Game.sugar => s.sugarKind,
    _Game.chain => s.chainKind,
    _Game.puzzle => s.puzzleKind,
    _Game.superGame => s.superKind,
    _Game.classic => s.classicKind,
  };

  List<Color> get tones => switch (this) {
    _Game.tower => const [Color(0xFFFF9A4D), Color(0xFFD9481A)],
    _Game.sugar => const [Color(0xFFFF5FB8), Color(0xFFB8186E)],
    _Game.chain => const [Color(0xFF38BDF8), Color(0xFF1D5FD0)],
    _Game.puzzle => const [Color(0xFF34D399), Color(0xFF0B8A60)],
    _Game.superGame => const [Color(0xFFB46CFF), Color(0xFF6420D0)],
    _Game.classic => const [Color(0xFF5B6CFF), Color(0xFF2A3290)],
  };
}

const _showEdge = Color(0xFF15101F);

/// Opens [game]: a game of one mode starts, the others show their page.
Future<void> _openGame(BuildContext context, GameController c, _Game game) async {
  if (game.modes.length == 1) {
    _launch(context, c, game.modes.single);
    return;
  }
  final mode = await Navigator.of(context).push<_PlayMode>(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => _ModesPage(settings: c.settings, game: game),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
  if (mode != null && context.mounted) _launch(context, c, mode);
}

/// Whether [game] wears a NEW badge: one of the new games, not played yet,
/// for a player who has played something else (to a new player everything
/// is new, and a badge on every game says nothing).
bool _isFresh(Settings s, _Game game) => game.isNew && s.lastPlay != null && !game.modes.any((m) => _played(s, m));

/// Whether [game] has a game left half way.
bool _hasSave(GameController c, _Game game) => switch (game) {
  _Game.sugar => _savedSugarLevel(c.settings) != null,
  _Game.chain => _savedChainSummary(c.settings) != null,
  _Game.puzzle => c.settings.savedBlocks != null,
  _Game.superGame => c.savedSummary?.mode == GameMode.superMode,
  _Game.classic => c.savedSummary != null && c.savedSummary!.mode != GameMode.superMode,
  _Game.tower => false,
};

/// The words painted on the pictures.
typedef _ArtWords = ({String perfect, String power, String lines});

_ArtWords _artWords(AppStrings s) => (perfect: s.towerPerfect, power: s.artSuper, lines: s.artLines);

/// The big cards at the top of the home screen: one game each, sliding to
/// the next every few seconds; the next card peeks in from the side. A card
/// is at most [maxCard] wide: on a tablet more of the next one shows.
class _Showcase extends StatefulWidget {
  const _Showcase({super.key, required this.c, required this.clock, required this.width, required this.ratio});

  final GameController c;
  final Animation<double> clock;

  /// The room across, and a card's height for its width.
  final double width, ratio;

  static const double maxCard = 560;

  /// How much of the width a card takes.
  double get fraction => min(0.91, maxCard / width);

  @override
  State<_Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<_Showcase> {
  late PageController _pages = PageController(viewportFraction: widget.fraction);
  late final Timer _timer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
  int _page = 0;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void didUpdateWidget(_Showcase old) {
    super.didUpdateWidget(old);
    // Turned on its side: cards of a new width, on the same game.
    if ((widget.fraction - _pages.viewportFraction).abs() > 0.001) {
      final old = _pages;
      _pages = PageController(viewportFraction: widget.fraction, initialPage: _page);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pages.dispose();
    super.dispose();
  }

  /// On to the next game, unless the player has a finger on it, the effects
  /// are off or the system asks for less motion.
  void _advance() {
    if (!mounted || _touching || !_pages.hasClients || !widget.c.settings.effects || MediaQuery.disableAnimationsOf(context)) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _go((_page + 1) % _Game.values.length);
  }

  void _go(int page) => _pages.animateToPage(page, duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final c = widget.c;
    const games = _Game.values;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = (widget.width * widget.fraction * widget.ratio + (textScale - 1) * 70).clamp(150.0, 430.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: Listener(
            onPointerDown: (_) => _touching = true,
            onPointerUp: (_) => _touching = false,
            onPointerCancel: (_) => _touching = false,
            child: PageView.builder(
              key: const ValueKey('showcase'),
              controller: _pages,
              padEnds: false,
              itemCount: games.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 6),
                child: _ShowcaseCard(
                  game: games[i],
                  index: i,
                  clock: widget.clock,
                  fresh: _isFresh(c.settings, games[i]),
                  onTap: () => _launch(context, c, games[i].modes.first),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, g) in games.indexed)
              GestureDetector(
                onTap: () => _go(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: i == _page ? 26 : 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: i == _page ? g.tones.first : p.text.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 1 : 5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One game in the showcase: the game itself mid-play, its name, what it
/// is, and OYNA, which starts its main mode.
class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.game, required this.index, required this.clock, required this.fresh, required this.onTap});

  final _Game game;
  final int index;
  final Animation<double> clock;
  final bool fresh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final pixel = p.skin == GameSkin.pixel;
    final radius = pixel ? 6.0 : 24.0;
    return Semantics(
      button: true,
      label: '${game.title(s)}, ${game.blurb(s)}',
      child: GestureDetector(
        key: ValueKey('show-${game.name}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
            boxShadow: [BoxShadow(color: _showEdge, offset: const Offset(0, 6)), BoxShadow(color: game.tones.first.withValues(alpha: 0.35), blurRadius: 22)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(child: CustomPaint(painter: _GameArtPainter(game: game, clock: clock, words: _artWords(s)))),
                      if (fresh) Positioned(left: 10, top: 10, child: _Badge(text: s.newGameBadge, colors: const [Color(0xFFF43F5E), Color(0xFFE11D48)])),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(pixel ? 2 : 12)),
                          child: Text(
                            '${index + 1} / ${_Game.values.length}',
                            style: TextStyle(color: Colors.white, fontSize: _fs(p, 11.5), fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 9, 12, 11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: game.tones, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                game.title(s),
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _fs(p, 26),
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [Shadow(color: Color(0x55000000), offset: Offset(1.5, 2))],
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              game.blurb(s),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: _fs(p, 13), height: 1.2, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ShowPlay(label: s.play),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The green OYNA of a showcase card, breathing a little.
class _ShowPlay extends StatelessWidget {
  const _ShowPlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final pixel = p.skin == GameSkin.pixel;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: pixel ? 7 : 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6BF0A0), Color(0xFF1FB85A)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(pixel ? 3 : 18),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0xFF0E6A32), offset: Offset(0, 4))],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: _fs(p, 19),
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: const [Shadow(color: Color(0xFF0E6A32), offset: Offset(0, 1.5))],
        ),
      ),
    );
  }
}

/// A game under the showcase: its picture, its name and what kind it is.
class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.c, required this.clock, required this.onTap});

  final _Game game;
  final GameController c;
  final Animation<double> clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final pixel = p.skin == GameSkin.pixel;
    final radius = pixel ? 4.0 : 18.0;
    final settings = c.settings;
    final saved = _hasSave(c, game);
    final fresh = _isFresh(settings, game);
    final last = _Game.of(_PlayMode.fromName(settings.lastPlay)) == game && settings.lastPlay != null;
    return Semantics(
      button: true,
      label: '${game.title(s)}, ${game.kind(s)}',
      child: GestureDetector(
        key: ValueKey('tile-${game.name}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: last ? Colors.white : _showEdge, width: last ? 3 : 2.5),
            boxShadow: const [BoxShadow(color: _showEdge, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(child: CustomPaint(painter: _GameArtPainter(game: game, clock: clock, words: _artWords(s), offset: 0.3 + game.index * 0.17))),
                      if (saved || fresh)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: _Badge(
                            text: saved ? s.badgeContinue : s.newBadge,
                            colors: saved ? const [Color(0xFF22C55E), Color(0xFF15803D)] : const [Color(0xFFF43F5E), Color(0xFFE11D48)],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 8, 7),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: game.tones, begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                game.title(s),
                                maxLines: 1,
                                style: TextStyle(color: Colors.white, fontSize: _fs(p, 15.5), height: 1.2, fontWeight: FontWeight.w900),
                              ),
                            ),
                            Text(
                              game.kind(s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: _fs(p, 11), height: 1.25, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: pixel ? BoxShape.rectangle : BoxShape.circle),
                        child: const GameIcon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The height of a game tile [width] wide: its picture ([art] of the width
/// tall) and two lines.
double _tileHeight(GamePalette p, double width, double textScale, {double art = 0.42}) => (width * art + (_fs(p, 15.5) * 1.2 + _fs(p, 11) * 1.25) * textScale + 14).ceilToDouble();

/// The slim bar at the top: a game left half way (or the last one played),
/// its picture and colour, and a button that goes straight back in.
class _ContinueBar extends StatelessWidget {
  const _ContinueBar({super.key, required this.game, required this.label, required this.title, required this.detail, required this.button, required this.clock, required this.onTap});

  final _Game game;
  final String label, title, button;
  final String? detail;
  final Animation<double> clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final pixel = p.skin == GameSkin.pixel;
    final radius = pixel ? 4.0 : 18.0;
    final line = TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: _fs(p, 11.5), height: 1.2, fontWeight: FontWeight.w900, letterSpacing: 0.3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: game.tones, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
            boxShadow: const [BoxShadow(color: _showEdge, offset: Offset(0, 4))],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 62,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius - 6 < 2 ? 2 : radius - 6),
                    child: RepaintBoundary(child: CustomPaint(painter: _GameArtPainter(game: game, clock: clock, words: _artWords(s), offset: 0.5))),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: GameIcon(Icons.history_rounded, size: _fs(p, 13), color: Colors.white.withValues(alpha: 0.9)),
                              ),
                            ),
                            TextSpan(text: label),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: line,
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: _fs(p, 17), height: 1.2, fontWeight: FontWeight.w900),
                      ),
                      if (detail != null)
                        Text(
                          detail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: _fs(p, 12.5), height: 1.2, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: pixel ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC93C),
                      borderRadius: BorderRadius.circular(pixel ? 2 : 14),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Color(0xFFB07A00), offset: Offset(0, 3))],
                    ),
                    child: Text(
                      '${s.upper(button)} ›',
                      style: TextStyle(color: const Color(0xFF2A1A00), fontSize: _fs(p, 13.5), fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- the tour

/// The first time the home screen opens: everything dims but the showcase,
/// and Lokum says there are six games. Any tap closes it.
class _HomeTour extends StatefulWidget {
  const _HomeTour({required this.target, required this.onDone});

  /// The showcase, left bright.
  final GlobalKey target;
  final VoidCallback onDone;

  @override
  State<_HomeTour> createState() => _HomeTourState();
}

class _HomeTourState extends State<_HomeTour> {
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final target = widget.target.currentContext?.findRenderObject() as RenderBox?;
    final self = context.findRenderObject() as RenderBox?;
    if (target == null || self == null || !target.hasSize || !self.hasSize) return;
    final topLeft = self.globalToLocal(target.localToGlobal(Offset.zero));
    setState(() => _hole = (topLeft & target.size).inflate(8));
  }

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final hole = _hole;
    return GestureDetector(
      key: const ValueKey('home-tour'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDone,
      child: LayoutBuilder(
        builder: (context, box) {
          final bubbleTop = hole == null ? box.maxHeight * 0.4 : min(hole.bottom + 22, box.maxHeight - 230);
          final left = hole == null ? 16.0 : max(16.0, hole.left);
          final width = min(440.0, box.maxWidth - left - 16);
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _TourShadePainter(hole))),
              Positioned(
                left: left,
                top: bubbleTop,
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 92, height: 104, child: CustomPaint(painter: _TourLokumPainter())),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 4 : 18),
                              boxShadow: const [BoxShadow(color: Color(0x44000000), offset: Offset(0, 3), blurRadius: 6)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.tourTitle, style: TextStyle(color: const Color(0xFF5A1F7A), fontSize: _fs(p, 16.5), height: 1.2, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 3),
                                Text(s.tourLine, style: TextStyle(color: const Color(0xFF7A4A9A), fontSize: _fs(p, 13.5), height: 1.2, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Container(
                        key: const ValueKey('home-tour-ok'),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6BF0A0), Color(0xFF1FB85A)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 3 : 20),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: Color(0xFF0E6A32), offset: Offset(0, 4))],
                        ),
                        child: Text(s.tourOk, style: TextStyle(color: Colors.white, fontSize: _fs(p, 18), fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
              if (hole != null)
                Positioned(
                  left: hole.left + hole.width * 0.62,
                  top: hole.top + hole.height * 0.3,
                  child: const IgnorePointer(child: _SwipeHint()),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A hand sweeping left across the showcase.
class _SwipeHint extends StatefulWidget {
  const _SwipeHint();

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint> with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _move,
    builder: (context, child) {
      final t = Curves.easeInOut.transform(_move.value);
      return Opacity(
        opacity: (1 - (t - 0.8).clamp(0.0, 0.2) * 5).clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(-110 * t, 0), child: child),
      );
    },
    child: const GameIcon(Icons.swipe_left_rounded, size: 52, color: Colors.white),
  );
}

class _TourShadePainter extends CustomPainter {
  _TourShadePainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    final h = hole;
    if (h != null) shade.addRRect(RRect.fromRectAndRadius(h, const Radius.circular(28)));
    canvas.drawPath(shade, Paint()..color = const Color(0xCC0E0820));
  }

  @override
  bool shouldRepaint(_TourShadePainter old) => old.hole != hole;
}

class _TourLokumPainter extends CustomPainter {
  const _TourLokumPainter();

  @override
  void paint(Canvas canvas, Size size) => paintLokum(canvas, Offset(size.width / 2, size.height * 0.5), size.height * 0.88, pose: LokumPose.point);

  @override
  bool shouldRepaint(_TourLokumPainter old) => false;
}

// ------------------------------------------------------------- the pictures

/// Each game mid-play, filling the card: what tells one game from the
/// others at a glance. It moves with [clock]: a floor drops onto the tower,
/// sweets pop, a chain lights up, a piece slides in, a bomb goes off, four
/// lines clear.
class _GameArtPainter extends CustomPainter {
  _GameArtPainter({required this.game, required this.clock, required this.words, this.offset = 0}) : super(repaint: clock);

  final _Game game;
  final Animation<double> clock;
  final _ArtWords words;
  final double offset;

  static const _blocks = [Color(0xFF3B82F6), Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFA855F7), Color(0xFF06B6D4), Color(0xFFFACC15)];

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final t = (clock.value + offset) % 1;
    final u = size.height / 196;
    canvas.save();
    canvas.clipRect(r);
    switch (game) {
      case _Game.tower:
        _tower(canvas, r, u, t);
      case _Game.sugar:
        _sugar(canvas, r, u, t);
      case _Game.chain:
        _chain(canvas, r, u, t);
      case _Game.puzzle:
        _puzzle(canvas, r, u, t);
      case _Game.superGame:
        _power(canvas, r, u, t);
      case _Game.classic:
        _classic(canvas, r, u, t);
    }
    canvas.restore();
  }

  static double _wave(double t) => 0.5 + 0.5 * sin(t * 2 * pi);

  static void _sky(Canvas canvas, Rect r, List<Color> colors) =>
      canvas.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors, [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]));

  static void _rays(Canvas canvas, Offset c, double len, Color color, {int n = 12, double turn = 0}) {
    final paint = Paint()..color = color;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final a = turn + i * 2 * pi / n;
      path
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.09) * len, c.dy + sin(a - 0.09) * len)
        ..lineTo(c.dx + cos(a + 0.09) * len, c.dy + sin(a + 0.09) * len)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  static void _glow(Canvas canvas, Offset c, double radius, Color color) =>
      canvas.drawCircle(c, radius, Paint()..shader = ui.Gradient.radial(c, radius, [color, color.withValues(alpha: 0)]));

  static void _cloud(Canvas canvas, Offset c, double w, {double alpha = 0.9}) {
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawOval(Rect.fromCenter(center: c, width: w, height: w * 0.32), paint);
    canvas.drawCircle(c + Offset(-w * 0.14, -w * 0.12), w * 0.17, paint);
    canvas.drawCircle(c + Offset(w * 0.1, -w * 0.15), w * 0.21, paint);
  }

  static void _lines(Canvas canvas, Offset from, double len, double gap, int n, Color color, double width, {bool down = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final l = len * (i.isEven ? 1 : 0.6);
      if (down) {
        final x = from.dx + i * gap;
        canvas.drawLine(Offset(x, from.dy - l), Offset(x, from.dy), paint);
      } else {
        final y = from.dy + i * gap;
        canvas.drawLine(Offset(from.dx - l, y), Offset(from.dx, y), paint);
      }
    }
  }

  static void _label(Canvas canvas, String text, Offset c, double size, {double scale = 1}) {
    if (scale <= 0.01) return;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    paintSugarLabel(
      canvas,
      text,
      Offset.zero,
      size,
      Paint()..shader = ui.Gradient.linear(Offset(0, -size / 2), Offset(0, size / 2), const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)], const [0, 0.5, 1]),
      outline: const Color(0xFF6A0E4A),
      stroke: 0.2,
    );
    canvas.restore();
  }

  /// 0 → 1 → a little over → 1: a label popping in.
  static double _pop(double t) => t <= 0 ? 0 : Curves.easeOutBack.transform(t.clamp(0.0, 1.0));

  void _tower(Canvas canvas, Rect r, double u, double t) {
    _sky(canvas, r, const [Color(0xFF5B5BE0), Color(0xFFFF8FB0), Color(0xFFFFC98A)]);
    final sun = Offset(r.left + 52 * u, r.top + 52 * u);
    _glow(canvas, sun, (56 + 6 * _wave(t)) * u, const Color(0xAAFFF1B0));
    canvas.drawCircle(sun, 20 * u, Paint()..color = const Color(0xFFFFF0B8));
    _cloud(canvas, Offset(r.right - 46 * u + sin(t * 2 * pi) * 6 * u, r.top + 40 * u), 60 * u, alpha: 0.85);
    _cloud(canvas, Offset(r.left + 110 * u - sin(t * 2 * pi) * 5 * u, r.top + 92 * u), 44 * u, alpha: 0.6);
    final horizon = r.bottom - 22 * u;
    canvas.save();
    canvas.translate(r.left, 0);
    paintSkyline(canvas, r.width, horizon, 110 * u, const Color(0xBF7A4A9A));
    canvas.restore();
    paintBosphorus(canvas, Rect.fromLTWH(r.left, horizon, r.width, r.bottom - horizon), ferryAt: -1, tower: 0);
    paintLandmark(canvas, Landmark.galata, Offset(r.left + 40 * u, horizon + 2 * u), 0.3 * u);
    // The tower, a little crooked; the next floor drops on and fits.
    final a = 30 * u, h = 14 * u;
    final base = Offset(r.center.dx + 14 * u, horizon + 2 * u);
    Offset at(int i) => base - Offset(0, (i + 1) * h) + towerU * (sin(i * 1.7) * 2.2 * u);
    for (var i = 0; i < 5; i++) {
      if (i > 0) paintFloorShadow(canvas, at(i), a, a, h);
      paintTowerFloor(canvas, at(i), a, a, h, flavor: i, seed: i);
    }
    final fall = Curves.easeIn.transform((t / 0.5).clamp(0.0, 1.0));
    final target = at(5);
    final from = target + Offset(34 * u, -62 * u);
    final pos = Offset.lerp(from, target, fall)!;
    if (fall < 1) _lines(canvas, pos + Offset(-a * 1.2, -h * 0.6), 24 * u, 7 * u, 3, Colors.white.withValues(alpha: 0.8), 2.4 * u);
    paintFloorShadow(canvas, pos, a, a, h, alpha: fall);
    paintTowerFloor(canvas, pos, a, a, h, flavor: 5, seed: 9);
    final landed = (t - 0.5) / 0.18;
    if (landed > 0) {
      final twinkle = _wave(t * 3);
      paintSparkle(canvas, target + Offset(-a * 1.15, -h * 0.3), (6 + 4 * twinkle) * u, Colors.white);
      paintSparkle(canvas, target + Offset(a * 1.25, -h * 0.9), (5 + 3 * (1 - twinkle)) * u, const Color(0xFFFFE066));
      _label(canvas, words.perfect, Offset(r.right - 58 * u, r.top + 82 * u), 16 * u, scale: _pop(landed));
    }
  }

  void _sugar(Canvas canvas, Rect r, double u, double t) {
    _sky(canvas, r, const [Color(0xFF9B3DE8), Color(0xFF5A1592)]);
    _rays(canvas, Offset(r.center.dx + 30 * u, r.top + 84 * u), 280 * u, Colors.white.withValues(alpha: 0.06), n: 14, turn: t * 2 * pi / 14);
    final s = 34 * u;
    const cols = 7, rows = 4;
    final o = Offset(r.center.dx + 30 * u - cols * s / 2, r.top + 18 * u);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, cols * s, rows * s).inflate(5 * u), Radius.circular(12 * u)), Paint()..color = const Color(0x553A0A6A));
    const colors = SugarColor.values;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (y == 1 && x == 4) continue;
        final cell = Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(s * 0.05);
        if (y == 2 && x == 1) {
          paintStriped(canvas, cell, SugarColor.red, horizontal: true);
        } else if (y == 3 && x == 5) {
          paintWrapped(canvas, cell, SugarColor.blue);
        } else {
          paintCandy(canvas, cell, colors[(x * 2 + y * 3 + (x * y) % 2) % colors.length]);
        }
      }
    }
    // A match going off, again and again.
    final pop = Offset(o.dx + 4.5 * s, o.dy + 1.5 * s);
    final beat = _wave(t);
    _glow(canvas, pop, s * (1.1 + 0.45 * beat), const Color(0xCCFFF3A0));
    _rays(canvas, pop, s * (0.9 + 0.3 * beat), const Color(0x99FFFFFF), n: 10, turn: t * 2 * pi / 10);
    paintSparkle(canvas, pop + Offset(-s * 0.7, -s * 0.5), s * (0.22 + 0.14 * beat), Colors.white);
    paintSparkle(canvas, pop + Offset(s * 0.8, s * 0.3), s * (0.3 - 0.1 * beat), const Color(0xFFFFE066));
    paintSparkle(canvas, pop + Offset(s * 0.1, s * 0.9), s * 0.2, const Color(0xFF9AF0FF));
    _label(canvas, '+360', pop + Offset(0, -s * (0.1 + 0.25 * t)), s * 0.62, scale: _pop(t / 0.25));
    paintLokum(canvas, Offset(r.left + 40 * u, r.bottom - 38 * u), 62 * u, pose: LokumPose.cheer, hop: t < 0.5 ? t * 2 : 0);
  }

  void _chain(Canvas canvas, Rect r, double u, double t) {
    _sky(canvas, r, const [Color(0xFF2350C8), Color(0xFF101A52)]);
    _rays(canvas, Offset(r.center.dx + 50 * u, r.top + 40 * u), 300 * u, Colors.white.withValues(alpha: 0.05), n: 16, turn: t * 2 * pi / 16);
    final s = 27 * u;
    const cols = 6, rows = 6;
    final o = Offset(r.center.dx + 64 * u - cols * s / 2, r.bottom - rows * s - 8 * u);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, cols * s, rows * s).inflate(5 * u), Radius.circular(10 * u)), Paint()..color = const Color(0x660A0E30));
    const board = ['......', '..M...', '.BMG..', 'GBMYB.', 'YGBMGY', 'MYGBYM'];
    const map = {'M': ChainColor.magenta, 'B': ChainColor.blue, 'G': ChainColor.green, 'Y': ChainColor.yellow};
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final ch = board[y][x];
        if (ch == '.') continue;
        paintChainCube(canvas, Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s).deflate(s * 0.04), chainColors[map[ch]!]!);
      }
    }
    // Three magenta cubes in a column light up: a chain.
    final beat = _wave(t * 2);
    final col = Rect.fromLTWH(o.dx + 2 * s, o.dy + s, s, 3 * s).inflate(3 * u);
    _glow(canvas, col.center, s * (1.6 + 0.6 * beat), Color.fromRGBO(255, 255, 255, 0.35 + 0.35 * beat));
    canvas.drawRRect(RRect.fromRectAndRadius(col, Radius.circular(8 * u)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * u
      ..color = Colors.white.withValues(alpha: 0.6 + 0.4 * beat));
    paintSparkle(canvas, col.topRight + Offset(4 * u, 2 * u), s * (0.26 + 0.14 * beat), const Color(0xFFFFE066));
    paintSparkle(canvas, col.centerLeft + Offset(-6 * u, 10 * u), s * (0.32 - 0.12 * beat), Colors.white);
    _label(canvas, '×3', Offset(r.center.dx + 64 * u, r.top + 24 * u), 20 * u, scale: 1 + 0.08 * beat);
    paintEksiLimon(canvas, Offset(r.left + 52 * u, r.center.dy + 14 * u + sin(t * 2 * pi) * 4 * u), 70 * u);
    _label(canvas, 'VS', Offset(r.left + 106 * u, r.center.dy - 30 * u), 16 * u);
  }

  void _puzzle(Canvas canvas, Rect r, double u, double t) {
    _sky(canvas, r, const [Color(0xFF1FC7A8), Color(0xFF0B5F74)]);
    _rays(canvas, r.center, 280 * u, Colors.white.withValues(alpha: 0.05), n: 14, turn: t * 2 * pi / 14);
    const n = 8;
    final s = 20 * u;
    final o = Offset(r.center.dx - 40 * u - n * s / 2, r.top + (r.height - n * s) / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, n * s, n * s).inflate(5 * u), Radius.circular(10 * u)), Paint()..color = const Color(0x66052A33));
    final slot = Paint()..color = Colors.white.withValues(alpha: 0.1);
    const filled = ['........', '....xx..', 'x...xx..', 'xx.xxxx.', 'xx.xxxxx', 'xx.xxx.x', 'x..xxxxx', 'xx.xxxxx'];
    final land = Curves.easeInOut.transform((t / 0.55).clamp(0.0, 1.0));
    final cleared = land >= 1;
    final flash = cleared ? _wave((t - 0.55) / 0.45 * 0.5 + 0.75) : 0.0;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final cell = Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s, s);
        canvas.drawRRect(RRect.fromRectAndRadius(cell.deflate(1.2 * u), Radius.circular(s * 0.2)), slot);
        if (filled[y][x] == 'x') paintToyBlock(canvas, cell.topLeft, s, _blocks[(x + y * 3) % 6], _showEdge);
      }
    }
    // An L piece slides in from the tray and fills column 2: the column
    // clears.
    const piece = [(0, 0), (0, 1), (0, 2), (1, 2)];
    final tray = Offset(o.dx + n * s + 24 * u, o.dy + 16 * u);
    final into = Offset(o.dx + 2 * s, o.dy + 4 * s);
    final p = Offset.lerp(tray, into, land)!;
    if (!cleared) {
      for (final (dx, dy) in piece) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(into.dx + dx * s, into.dy + dy * s, s, s).deflate(1.5 * u), Radius.circular(s * 0.2)), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * u
          ..color = Colors.white.withValues(alpha: 0.55));
      }
    }
    for (final (dx, dy) in piece) {
      paintToyBlock(canvas, p + Offset(dx * s, dy * s), s, cleared ? Colors.white : _blocks[2], _showEdge);
    }
    if (cleared) {
      final row = Rect.fromLTWH(o.dx, o.dy + 4 * s, n * s, s);
      _glow(canvas, row.center, n * s * (0.45 + 0.25 * flash), Color.fromRGBO(255, 255, 255, 0.4 + 0.4 * flash));
      paintSparkle(canvas, row.centerLeft + Offset(-4 * u, 0), s * (0.4 + 0.3 * flash), Colors.white);
      paintSparkle(canvas, row.centerRight + Offset(4 * u, 0), s * (0.4 + 0.3 * flash), const Color(0xFFFFE066));
      _label(canvas, '+120', Offset(o.dx + n * s + 44 * u, r.top + 52 * u), 16 * u, scale: _pop((t - 0.55) / 0.15));
    }
  }

  void _power(Canvas canvas, Rect r, double u, double t) {
    _sky(canvas, r, const [Color(0xFFE04BD8), Color(0xFF5A1AB0), Color(0xFF240C5A)]);
    final s = 24 * u;
    final cols = (r.width / s).ceil() + 1;
    final x0 = r.center.dx - cols * s / 2;
    final floor = r.bottom - 4 * u;
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < cols; x++) {
        if (y == 2 && (x * 5 + 2) % 7 < 3) continue;
        paintToyBlock(canvas, Offset(x0 + x * s, floor - (y + 1) * s), s, _blocks[(x * 3 + y) % 7], _showEdge);
      }
    }
    // A bomb going off on the stack, a drill coming down, a gem.
    final beat = _wave(t * 2);
    final bomb = Offset(r.center.dx - 50 * u, floor - 3 * s);
    final c = bomb + Offset(s * 0.65, s * 0.65);
    _glow(canvas, c, s * (2 + 0.8 * beat), const Color(0xCCFFB347));
    _rays(canvas, c, s * (1.7 + 0.5 * beat), const Color(0x99FFF3A0), turn: t * 2 * pi / 12);
    paintBomb(canvas, bomb, s * 1.3);
    final drill = Offset(r.center.dx + 46 * u, r.top + 14 * u + 34 * u * t);
    _lines(canvas, drill + Offset(s * 0.4, -2 * u), 18 * u, s * 0.4, 3, Colors.white.withValues(alpha: 0.5), 2.4 * u, down: true);
    paintDrill(canvas, drill, s * 1.5);
    paintGem(canvas, Offset(r.right - 70 * u, r.top + 52 * u + sin(t * 2 * pi) * 4 * u), s * 1.3, shadeTarget: _showEdge);
    paintSparkle(canvas, Offset(r.right - 30 * u, r.top + 40 * u), (6 + 4 * beat) * u, Colors.white);
    // The energy bar filling up.
    final bar = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 16 * u, r.top + 20 * u, 90 * u, 12 * u), Radius.circular(6 * u));
    canvas.drawRRect(bar, Paint()..color = const Color(0xCC2A0B4F));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * (0.55 + 0.45 * t), bar.height), Radius.circular(6 * u)),
      Paint()..shader = ui.Gradient.linear(bar.outerRect.topLeft, bar.outerRect.bottomLeft, const [Color(0xFFFFF06A), Color(0xFFFF8A10)]),
    );
    canvas.drawRRect(bar, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u
      ..color = Colors.white.withValues(alpha: 0.8));
    _label(canvas, words.power, Offset(r.left + 64 * u, r.top + 62 * u), 20 * u, scale: 1 + 0.06 * beat);
  }

  void _classic(Canvas canvas, Rect r, double u, double t) {
    _sky(canvas, r, const [Color(0xFF26307A), Color(0xFF0E1236)]);
    final s = 18 * u;
    const cols = 10;
    final x0 = r.center.dx - cols * s / 2, floor = r.bottom - 6 * u;
    canvas.drawRect(Rect.fromLTRB(x0, r.top, x0 + cols * s, floor), Paint()..color = const Color(0xFF0A0C26));
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var x = 0; x <= cols; x++) {
      canvas.drawLine(Offset(x0 + x * s, r.top), Offset(x0 + x * s, floor), grid);
    }
    const stack = ['xx.xxx..xx', 'xxxxxxxxx.', 'xxxxxxxxx.', 'xxxxxxxxx.', 'xxxxxxxxx.'];
    for (var y = 0; y < stack.length; y++) {
      for (var x = 0; x < cols; x++) {
        if (stack[y][x] != 'x') continue;
        paintToyBlock(canvas, Offset(x0 + x * s, floor - (stack.length - y) * s), s, _blocks[(x * 2 + y) % 7], _showEdge);
      }
    }
    // The long piece drops into the gap: four lines at once.
    final drop = Curves.easeIn.transform((t / 0.45).clamp(0.0, 1.0));
    final gx = x0 + 9 * s;
    final top = r.top + 10 * u, bottom = floor - 4 * s;
    final py = top + (bottom - top) * drop;
    if (drop < 1) {
      for (var i = 0; i < 4; i++) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gx, bottom + i * s, s, s).deflate(1.5), Radius.circular(3 * u)), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * u
          ..color = Colors.white.withValues(alpha: 0.5));
      }
      _lines(canvas, Offset(gx + s * 0.25, py - 2 * u), 14 * u, s * 0.5, 2, Colors.white.withValues(alpha: 0.45), 2 * u, down: true);
    }
    for (var i = 0; i < 4; i++) {
      paintToyBlock(canvas, Offset(gx, py + i * s), s, _blocks[5], _showEdge);
    }
    final cleared = (t - 0.45) / 0.4;
    if (cleared > 0) {
      final flash = (1 - (cleared - 0.5).abs() * 2).clamp(0.0, 1.0);
      canvas.drawRect(Rect.fromLTWH(x0, floor - 4 * s, cols * s, 4 * s), Paint()..color = Colors.white.withValues(alpha: 0.75 * flash));
      _label(canvas, words.lines, Offset(x0 - 2 * u, r.top + 40 * u), 17 * u, scale: _pop(cleared * 2));
      paintSparkle(canvas, Offset(gx + s * 1.8, floor - 3 * s), (6 + 5 * flash) * u, const Color(0xFFFFE066));
      paintSparkle(canvas, Offset(x0 - 6 * u, floor - 2 * s), (5 + 4 * flash) * u, Colors.white);
    }
  }

  @override
  bool shouldRepaint(_GameArtPainter old) => old.game != game || old.offset != offset || old.words != words;
}
