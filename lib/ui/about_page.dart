import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/tetromino.dart';
import '../game/render/block_sprites.dart';
import '../l10n/strings.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'widgets.dart';

const String appVersion = '1.0.0';
const String developerName = 'Erkan ÖZ';
const String developerSiteLabel = 'erkanoz.com';
final Uri developerSite = Uri.parse('https://erkanoz.com');
const String lifeosLabel = 'lifeos.com.tr';
final Uri lifeosSite = Uri.parse('https://lifeos.com.tr');

const _musicCredits = [
  ('Commercial Music', 'Viacheslav Starostin', 'Pixabay'),
  ('Free Background Music', 'DesiFreeMusic', 'Pixabay'),
  ('Harlem Heat', 'Dagored', 'freetouse.com'),
  ('Bon Aleè', 'Moavii', 'freetouse.com'),
];

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.settings});

  final Settings settings;

  static Future<void> open(BuildContext context, Settings settings) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => AboutPage(settings: settings),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final muted = TextStyle(fontSize: 13, height: 1.45, color: p.muted, fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: p.background.first,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.background, stops: const [0, 0.55, 1]),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              // Desktop windows get two columns instead of a tall phone strip.
              final wide = box.maxWidth >= 900;
              final stats = GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: [
                  _StatTile(
                    icon: Icons.emoji_events_rounded,
                    colors: const [Color(0xFFFDE047), Color(0xFFF97316)],
                    label: s.bestScore,
                    value: s.score(settings.topScore),
                  ),
                  _StatTile(
                    icon: Icons.sports_esports_rounded,
                    colors: const [Color(0xFF38BDF8), Color(0xFF6366F1)],
                    label: s.gamesPlayed,
                    value: '${settings.gamesPlayed}',
                  ),
                  _StatTile(
                    icon: Icons.layers_rounded,
                    colors: const [Color(0xFF22C55E), Color(0xFF14B8A6)],
                    label: s.totalLines,
                    value: s.score(settings.totalLines),
                  ),
                  _StatTile(
                    icon: Icons.timer_rounded,
                    colors: const [Color(0xFFA855F7), Color(0xFFEC4899)],
                    label: s.playTime,
                    value: s.duration(settings.totalSeconds),
                  ),
                ],
              );
              final features = GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    for (final (i, (title, sub)) in s.features.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            PieceView(type: standardPieces[(i * 2 + 2) % standardPieces.length], cell: 8, size: const Size(34, 34)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                                  ),
                                  Text(sub, style: muted),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
              final music = GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  children: [
                    for (final (title, artist, source) in _musicCredits)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.music_note_rounded, size: 18, color: p.accent1),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(fontWeight: FontWeight.w700, color: p.text),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '$artist · $source',
                                textAlign: TextAlign.end,
                                style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(s.fontAndSounds, style: muted.copyWith(fontSize: 12)),
                  ],
                ),
              );
              final story = Container(
                padding: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(colors: [p.accent1.withValues(alpha: 0.6), const Color(0xFFA855F7).withValues(alpha: 0.6)]),
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    color: p.isDark ? const Color(0xF20E1226) : const Color(0xF7FFFFFF),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote_rounded, color: p.accent1, size: 28),
                      for (final (i, paragraph) in s.aboutStory.indexed)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 4 : 12),
                          child: Text(
                            paragraph,
                            style: TextStyle(fontSize: 14.5, height: 1.6, fontWeight: FontWeight.w500, color: p.text),
                          ),
                        ),
                    ],
                  ),
                ),
              );
              final left = [_SectionTitle(s.statsLabel), stats, const SizedBox(height: 22), _SectionTitle(s.featuresLabel), features];
              final right = [
                _SectionTitle(s.developerLabel),
                _DeveloperCard(strings: s),
                const SizedBox(height: 22),
                _SectionTitle(s.musicLabel),
                music,
              ];
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1080 : 560),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(wide ? 28 : 18, 10, wide ? 28 : 18, 32),
                    children: [
                      Row(
                        children: [
                          GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: s.back, onTap: () => Navigator.of(context).pop()),
                          const Spacer(),
                          _Chip(text: s.version(appVersion)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _Hero(),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(s.tagline, textAlign: TextAlign.center, style: muted.copyWith(fontSize: 15)),
                      ),
                      const SizedBox(height: 22),
                      _SectionTitle(s.aboutGameLabel),
                      story,
                      const SizedBox(height: 22),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right),
                            ),
                          ],
                        )
                      else ...[
                        ...left,
                        const SizedBox(height: 22),
                        ...right,
                      ],
                      const SizedBox(height: 26),
                      Center(
                        child: Text(
                          '${s.madeWith}\n© ${DateTime.now().year} $developerName',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.label, fontSize: 12, height: 1.6, fontWeight: FontWeight.w600),
                        ),
                      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: CardLabel(text));
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.glassBorder),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.muted),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.colors, required this.label, required this.value});

  final IconData icon;
  final List<Color> colors;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: colors),
              boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: p.text),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    Widget link(IconData icon, String title, String subtitle, Uri uri, List<Color> colors) => Expanded(
      child: GestureDetector(
        onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: p.isDark ? const Color(0x0FFFFFFF) : Colors.white,
            border: Border.all(color: colors.first.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: colors.first),
                  const Spacer(),
                  Icon(Icons.north_east_rounded, size: 14, color: p.label),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                style: TextStyle(fontSize: 11, height: 1.3, fontWeight: FontWeight.w600, color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [p.accent1, p.accent2, const Color(0xFFA855F7)]),
        boxShadow: [BoxShadow(color: p.accent2.withValues(alpha: 0.3), blurRadius: 26, offset: const Offset(0, 10))],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.5),
          color: p.isDark ? const Color(0xFF111630) : const Color(0xFFF8FAFD),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.accent1, p.accent2]),
                    boxShadow: [BoxShadow(color: p.accent1.withValues(alpha: 0.5), blurRadius: 18)],
                  ),
                  child: const Text(
                    'EÖ',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        developerName,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: p.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.developerRole,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                link(Icons.person_rounded, developerSiteLabel, strings.personalSite, developerSite, [p.accent1, p.accent2]),
                const SizedBox(width: 10),
                link(Icons.blur_on_rounded, lifeosLabel, strings.lifeosFamily, lifeosSite, const [Color(0xFFA855F7), Color(0xFF6366F1)]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo over a little scene of blocks drifting down behind it.
class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final sprites = BlockSprites.of(16, MediaQuery.devicePixelRatioOf(context), p);
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: RepaintBoundary(child: CustomPaint(painter: _FallingBlocksPainter(_anim, sprites, p))),
            ),
          ),
          const FittedBox(fit: BoxFit.scaleDown, child: LogoTitle(fontSize: 38)),
        ],
      ),
    );
  }
}

class _FallingBlocksPainter extends CustomPainter {
  _FallingBlocksPainter(this.anim, this.sprites, this.palette) : super(repaint: anim);

  final Animation<double> anim;
  final BlockSprites sprites;
  final GamePalette palette;

  static final _pieces = List.generate(9, (i) {
    final r = Random(40 + i);
    return (standardPieces[i % standardPieces.length], r.nextDouble(), r.nextDouble(), 0.6 + r.nextDouble() * 0.6, r.nextDouble() * pi);
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.accent2.withValues(alpha: palette.isDark ? 0.35 : 0.18),
            palette.accent1.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    final t = anim.value;
    for (final (type, x, phase, speed, angle) in _pieces) {
      final y = ((phase + t * speed) % 1.0) * (size.height + 80) - 40;
      canvas.save();
      canvas.translate(x * size.width, y);
      canvas.rotate(angle + t * 2 * pi * 0.15 * speed);
      for (final c in shapeOf(type, Rotation.spawn)) {
        sprites.draw(canvas, sprites.block(type), (c.x - 1.5) * sprites.cell, (c.y - 1) * sprites.cell, opacity: 0.55);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingBlocksPainter old) => old.sprites != sprites || old.palette != palette;
}
