import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../core/chain/chain_game.dart' show ChainColor;
import '../core/rewards.dart';
import '../core/sugar/sugar_levels.dart';
import '../game/chain/chain_sprites.dart' hide paintSparkle;
import '../game/sugar/istanbul_art.dart';
import '../game/sugar/sugar_art.dart';
import '../game/tower/tower_art.dart';
import '../l10n/strings.dart';
import '../settings/settings.dart';
import 'gift_art.dart';
import 'lokum_wardrobe.dart';
import 'sugar_widgets.dart';

/// Every gift in one place: today's gift, the sugar jar, star chests, the
/// weekly event, and what they have opened (cube looks, Şeker scenes, the
/// postcard album).
class GiftsScreen extends StatelessWidget {
  const GiftsScreen({super.key, required this.settings, this.audio});

  final Settings settings;
  final AudioService? audio;

  static Future<void> open(BuildContext context, {required Settings settings, AudioService? audio}) => Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => GiftsScreen(settings: settings, audio: audio),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      key: const ValueKey('gifts'),
      backgroundColor: const Color(0xFF3A1470),
      body: Stack(
        children: [
          const Positioned.fill(child: SugarBackdrop(chapter: 0)),
          SafeArea(
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        SugarRoundButton(key: const ValueKey('gifts-back'), icon: Icons.arrow_back_rounded, tooltip: s.back, onTap: () => Navigator.of(context).pop()),
                        Expanded(child: Center(child: CandyText(s.giftsTitle, size: 28, colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)]))),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        // Four sections only: built all at once.
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                          child: Column(
                            children: [
                              _Daily(settings: settings, audio: audio),
                              const SizedBox(height: 14),
                              _JarAndChests(settings: settings, audio: audio),
                              const SizedBox(height: 14),
                              _Event(settings: settings, audio: audio),
                              const SizedBox(height: 14),
                              _Collection(settings: settings),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _ink = sugarInk;
const _muted = Color(0xFF9A5AB5);
TextStyle _style(double size, Color color, {FontWeight weight = FontWeight.w800}) => TextStyle(fontFamily: 'Baloo2', fontSize: size, fontWeight: weight, color: color, height: 1.15);

class _Title extends StatelessWidget {
  const _Title(this.title, {this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CandyText(title, size: 22, color: _ink, stroke: 0),
      if (hint != null) Text(hint!, textAlign: TextAlign.center, style: _style(13.5, _muted, weight: FontWeight.w700)),
      const SizedBox(height: 10),
    ],
  );
}

/// A gift's boosters as icons with counts.
class _GiftItems extends StatelessWidget {
  const _GiftItems(this.gift, {this.size = 30});

  final Gift gift;
  final double size;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 4,
    children: [
      for (final e in gift.boosters.entries)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SugarBoosterIcon(e.key, size: size),
            if (e.value > 1) Text('×${e.value}', style: _style(size * 0.45, _ink)),
          ],
        ),
    ],
  );
}

// ---------------------------------------------------------------- daily --

class _Daily extends StatelessWidget {
  const _Daily({required this.settings, this.audio});

  final Settings settings;
  final AudioService? audio;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ready = settings.dailyGiftReady;
    // The calendar shows the day to take now as today; taken days before it.
    final today = ready ? settings.giftDay : (settings.giftDay + Rewards.dailyDays - 1) % Rewards.dailyDays;
    final now = settings.clock();
    final left = DateTime(now.year, now.month, now.day + 1).difference(now);
    return CandyPanel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        children: [
          _Title(s.dailyGiftTitle, hint: s.dailyGiftHint),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 6.0;
              final w = (box.maxWidth - gap * 3) / 4;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: [
                  for (var d = 0; d < Rewards.dailyDays; d++)
                    SizedBox(
                      width: d == Rewards.dailyDays - 1 ? w * 2 + gap : w,
                      height: 104,
                      child: _DayTile(day: d, gift: Rewards.daily(d), taken: d < today || (!ready && d == today), today: ready && d == today, next: d == today + 1),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (ready)
            _Breathe(
              child: CandyButton(
                key: const ValueKey('gift-daily'),
                label: s.giftTakeToday,
                colors: sugarGreen,
                ink: const Color(0xFF0E6A32),
                height: 52,
                width: double.infinity,
                onTap: () {
                  final gift = settings.claimDailyGift();
                  if (gift != null) showGiftPopup(context, settings, gift, title: s.dailyGiftTitle, audio: audio);
                },
              ),
            )
          else
            Container(
              key: const ValueKey('gift-next'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF3E6FA), borderRadius: BorderRadius.circular(22)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 22, color: Color(0xFFE0247A)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(s.giftNextIn(left.inHours, left.inMinutes % 60), style: _style(15, _ink))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.gift, required this.taken, required this.today, this.next = false});

  final int day;
  final Gift gift;
  final bool taken;
  final bool today;

  /// The day after the one to take (or taken) now.
  final bool next;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final big = day == Rewards.dailyDays - 1;
    final later = !taken && !today && !next;
    final tile = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: today ? const [BoxShadow(color: Color(0x99FFC21A), blurRadius: 16, spreadRadius: 1)] : null,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: today
              ? const [Color(0xFFFFF3C8), Color(0xFFFFD36B)]
              : taken
              ? const [Color(0xFFE6F9EE), Color(0xFFC9F0D8)]
              : big
              ? const [Color(0xFFFFE9F5), Color(0xFFFFC6E6)]
              : later
              ? const [Color(0xFFF4ECF8), Color(0xFFEADFF0)]
              : const [Colors.white, Color(0xFFFFEAF6)],
        ),
        border: Border.all(color: today ? const Color(0xFFFFB000) : (next ? const Color(0xFFFF9AD8) : Colors.white), width: today ? 3 : 2),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(s.giftDayLabel(day), style: _style(13, today ? const Color(0xFF8A4A00) : (later ? const Color(0xFFB8A8D0) : _muted))),
          Expanded(
            child: today && !big
                // Today's gift waits in a present that hops.
                ? _Breathe(
                    hop: true,
                    child: GiftPicture(size: const Size(52, 50), paint: (c, size) => paintPresent(c, size.center(const Offset(0, 2)), 46, tilt: -0.1)),
                  )
                : big
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GiftPicture(size: const Size(52, 48), paint: (c, size) => paintChest(c, size.center(const Offset(0, 4)), 46, chestGold)),
                      const SizedBox(width: 6),
                      Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(s.giftBigChest, style: _style(14, _ink)))),
                    ],
                  )
                : Center(child: Opacity(opacity: taken ? 0.4 : (later ? 0.6 : 1), child: _GiftItems(gift, size: 24))),
          ),
          SizedBox(
            height: 18,
            child: today
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: const Color(0xFFE0247A), borderRadius: BorderRadius.circular(9)),
                    child: Text(s.giftToday, style: _style(11.5, Colors.white)),
                  )
                : next
                ? Text(s.giftTomorrowShort, style: _style(12, const Color(0xFFE0247A)))
                : later && !big
                ? const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFB8A8D0))
                : null,
          ),
        ],
      ),
    );
    if (!taken) return tile;
    // Taken: a green ALINDI ribbon across it and a tick in the corner.
    return Stack(
      children: [
        Positioned.fill(child: tile),
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Transform.rotate(
                  angle: -0.42,
                  child: OverflowBox(
                    maxWidth: 400,
                    child: Container(
                      width: 260,
                      height: 20,
                      color: const Color(0xFF1FB85A),
                      alignment: Alignment.center,
                      child: Text(s.giftTaken, style: _style(11.5, Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned(right: 5, bottom: 5, child: Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF1FB85A))),
      ],
    );
  }
}

/// Keeps something alive: a gentle breath (or a hop) on its own clock; still
/// when the system asks for less motion.
class _Breathe extends StatefulWidget {
  const _Breathe({required this.child, this.hop = false});

  final Widget child;
  final bool hop;

  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = sin(_t.value * 2 * pi);
        if (widget.hop) {
          // Up, a squash on landing.
          final up = max(0.0, v);
          return Transform.translate(offset: Offset(0, -6 * up), child: Transform.rotate(angle: 0.06 * sin(_t.value * 4 * pi), child: child));
        }
        return Transform.scale(scale: 1 + 0.025 * v, child: child);
      },
    );
  }
}

/// A full jar: it wobbles and shines with light turning behind it.
class _FullJar extends StatefulWidget {
  const _FullJar();

  @override
  State<_FullJar> createState() => _FullJarState();
}

class _FullJarState extends State<_FullJar> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = still ? 0.2 : _t.value;
        return GiftPicture(
          size: const Size(170, 130),
          repaintKey: t,
          paint: (canvas, size) {
            final c = size.center(const Offset(0, 4));
            paintRays(canvas, c, 82, turn: t * 2 * pi / 12 * 2);
            canvas.save();
            canvas.translate(c.dx, c.dy + 50);
            // A wobble now and then, as if the sweets inside push.
            final wobble = t < 0.35 ? sin(t / 0.35 * pi * 4) * 0.09 * (1 - t / 0.35) : 0.0;
            canvas.rotate(wobble);
            paintJar(canvas, const Offset(0, -50), 112, 1, shine: true);
            canvas.restore();
            for (final (dx, dy, k, ph) in [(-62.0, -40.0, 8.0, 0.0), (60.0, -50.0, 10.0, 0.33), (66.0, 26.0, 6.0, 0.66), (-56.0, 36.0, 7.0, 0.5)]) {
              final tw = 0.5 + 0.5 * sin((t + ph) * 2 * pi * 2);
              paintSparkle(canvas, c + Offset(dx, dy), k * (0.6 + 0.6 * tw), dx < 0 ? Colors.white : const Color(0xFFFFE066));
            }
          },
        );
      },
    );
  }
}

// ---------------------------------------------------- jar and star chests --

class _JarAndChests extends StatelessWidget {
  const _JarAndChests({required this.settings, this.audio});

  final Settings settings;
  final AudioService? audio;

  @override
  Widget build(BuildContext context) {
    final jar = _Jar(settings: settings, audio: audio);
    final chests = _Chests(settings: settings, audio: audio);
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 420
          ? Column(children: [jar, const SizedBox(height: 14), chests])
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: jar),
                  const SizedBox(width: 12),
                  Expanded(child: chests),
                ],
              ),
            ),
    );
  }
}

class _Jar extends StatelessWidget {
  const _Jar({required this.settings, this.audio});

  final Settings settings;
  final AudioService? audio;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final full = settings.jarFull;
    final fill = min(1.0, settings.jarCount / settings.jarCapacity);
    return CandyPanel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        children: [
          _Title(s.jarTitle, hint: s.jarHint),
          if (full) const _FullJar() else GiftPicture(size: const Size(120, 120), repaintKey: fill, paint: (c, size) => paintJar(c, size.center(Offset.zero), 112, fill)),
          const SizedBox(height: 8),
          _Bar(value: fill),
          const SizedBox(height: 4),
          Text(full ? s.jarFullAsk : '${min(settings.jarCount, settings.jarCapacity)} / ${settings.jarCapacity}', textAlign: TextAlign.center, style: _style(16, full ? const Color(0xFF8A4A00) : _ink)),
          const SizedBox(height: 8),
          if (full)
            _Breathe(
              child: CandyButton(
                key: const ValueKey('gift-jar'),
                label: s.jarOpenFull,
                height: 46,
                textSize: 19,
                width: double.infinity,
                onTap: () {
                  final gift = settings.openJar();
                  if (gift != null) showGiftPopup(context, settings, gift, title: s.jarFull, audio: audio);
                },
              ),
            )
          else
          CandyButton(
            key: const ValueKey('gift-jar'),
            label: s.jarOpen,
            height: 46,
            textSize: 19,
            width: double.infinity,
            onTap: full
                ? () {
                    final gift = settings.openJar();
                    if (gift != null) showGiftPopup(context, settings, gift, title: s.jarFull, audio: audio);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _Chests extends StatelessWidget {
  const _Chests({required this.settings, this.audio});

  final Settings settings;
  final AudioService? audio;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final stars = settings.totalSugarStars;
    final ready = settings.starChestsReady;
    final next = settings.starChestsOpened + 1;
    final tier = Rewards.tier(next);
    final need = next * Rewards.chestEvery;
    return CandyPanel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        children: [
          _Title(s.chestsTitle, hint: s.chestsHint(Rewards.chestEvery)),
          GiftPicture(
            size: const Size(120, 120),
            repaintKey: (next, ready),
            paint: (c, size) => paintChest(c, size.center(const Offset(0, 8)), 96, chestTone(tier), glow: ready > 0),
          ),
          const SizedBox(height: 8),
          _Bar(value: ready > 0 ? 1 : ((stars - (next - 1) * Rewards.chestEvery) / Rewards.chestEvery).clamp(0.0, 1.0), colors: const [Color(0xFFFFE066), Color(0xFFFFB000)]),
          const SizedBox(height: 4),
          Text(ready > 0 ? s.chestName(tier.index) : s.chestNext(need), textAlign: TextAlign.center, style: _style(16, ready > 0 ? const Color(0xFF8A4A00) : _ink)),
          const SizedBox(height: 8),
          CandyButton(
            key: const ValueKey('gift-chest'),
            label: ready > 1 ? '${s.chestOpen} ×$ready' : s.chestOpen,
            colors: sugarGreen,
            ink: const Color(0xFF0E6A32),
            height: 46,
            textSize: 17,
            width: double.infinity,
            onTap: ready > 0
                ? () {
                    final gift = settings.openStarChest();
                    if (gift != null) showGiftPopup(context, settings, gift, title: s.chestName(tier.index), chest: tier, audio: audio);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, this.colors = const [Color(0xFFFF9AD8), Color(0xFFE0247A)]});

  final double value;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
    height: 14,
    decoration: BoxDecoration(color: const Color(0xFF2A0B4F).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(7)),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: max(0.08, value),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(7)),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

// ---------------------------------------------------------------- event --

class _Event extends StatelessWidget {
  const _Event({required this.settings, this.audio});

  final Settings settings;
  final AudioService? audio;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final e = settings.event;
    final fact = s.eventFact(e.name);
    final got = settings.eventCount;
    final claimed = settings.eventClaimed;
    final ready = settings.eventPrizesReady;
    const tiers = WeeklyEvent.tiers;
    return CandyPanel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        key: const ValueKey('gift-event-panel'),
        children: [
          Text(s.upper(s.eventTitle), style: _style(13, _muted)),
          CandyText(s.eventName(e.name), size: 26, color: const Color(0xFFD92B4A), stroke: 0),
          Text(s.eventDaysLeft(WeeklyEvent.daysLeft(settings.clock())), style: _style(14, const Color(0xFFE0247A))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E0E33).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2B33C), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fact.when, style: _style(12.5, const Color(0xFFFFD36B))),
                const SizedBox(height: 3),
                Text(fact.fact, style: _style(13.5, Colors.white, weight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GiftPicture(size: const Size(30, 30), paint: (c, size) => paintCandy(c, Offset.zero & size, e.color)),
              const SizedBox(width: 6),
              Flexible(child: Text(s.eventGoal(e.name), style: _style(14.5, _muted))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < tiers.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _Prize(gift: e.prize(i), need: tiers[i], taken: i < claimed, ready: i >= claimed && got >= tiers[i])),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _Bar(value: got / tiers.last, colors: const [Color(0xFFFF7A8A), Color(0xFFD0102A)]),
          const SizedBox(height: 4),
          Text(s.eventProgress(min(got, tiers.last), tiers.last), style: _style(15, _ink)),
          if (ready > 0) ...[
            const SizedBox(height: 8),
            CandyButton(
              key: const ValueKey('gift-event'),
              label: s.eventClaim,
              colors: sugarGreen,
              ink: const Color(0xFF0E6A32),
              height: 48,
              textSize: 18,
              width: double.infinity,
              onTap: () {
                final gift = settings.claimEventPrize();
                if (gift != null) showGiftPopup(context, settings, gift, title: s.eventName(e.name), audio: audio);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Prize extends StatelessWidget {
  const _Prize({required this.gift, required this.need, required this.taken, required this.ready});

  final Gift gift;
  final int need;
  final bool taken;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final outfit = gift.unlock;
    return Container(
      height: 82,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: taken
              ? const [Color(0xFFE6F9EE), Color(0xFFC9F0D8)]
              : ready
              ? const [Color(0xFFFFF3C8), Color(0xFFFFD36B)]
              : const [Colors.white, Color(0xFFFFEAF6)],
        ),
        border: Border.all(color: ready ? const Color(0xFFFFB000) : Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Expanded(
            child: outfit != null
                ? LokumView(outfit: LokumOutfit.values.firstWhere((o) => o.gift == outfit.name, orElse: () => LokumOutfit.none), size: 42)
                : FittedBox(fit: BoxFit.scaleDown, child: _GiftItems(gift, size: 24)),
          ),
          taken ? const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF1FB85A)) : Text('$need', style: _style(13, _ink)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- collection --

class _Collection extends StatelessWidget {
  const _Collection({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cubes = ChainCubeStyle.parse(settings.chainCubes);
    bool cubeOpen(ChainCubeStyle c) => switch (c) {
      ChainCubeStyle.vivid => true,
      ChainCubeStyle.lokum => settings.unlocked(Unlock.cubesLokum),
      ChainCubeStyle.cini => settings.unlocked(Unlock.cubesCini),
    };
    const scenes = [null, Unlock.sceneGalata, Unlock.sceneSnow, Unlock.sceneIslands, Unlock.sceneCamlica];
    final look = FloorLook.parse(settings.towerLook);
    return CandyPanel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _Title(s.collectionTitle)),
          Text(s.cubeLook, style: _style(16, _ink)),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final c in ChainCubeStyle.values) ...[
                if (c.index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _Choice(
                    key: ValueKey('cubes-${c.name}'),
                    label: s.cubeStyleName(c.name),
                    chosen: cubes == c || (!cubeOpen(cubes) && c == ChainCubeStyle.vivid),
                    locked: !cubeOpen(c),
                    onTap: () => settings.chainCubes = c == ChainCubeStyle.vivid ? null : c.name,
                    picture: GiftPicture(
                      size: const Size(76, 40),
                      paint: (canvas, size) {
                        for (var i = 0; i < 3; i++) {
                          final color = ChainColor.values[i];
                          paintChainCube(canvas, Rect.fromLTWH(i * 26.0, 6, 24, 24), c.colors[color]!, style: c, symbol: color.index);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(s.sugarSceneLabel, style: _style(16, _ink)),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < scenes.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Choice(
                    key: ValueKey('scene-${scenes[i]?.name ?? 'none'}'),
                    label: scenes[i] == null ? s.sceneDefault : s.unlockName(scenes[i]!.name),
                    chosen: settings.sugarScene == scenes[i]?.name || (scenes[i] == null && settings.sugarScene == null),
                    locked: scenes[i] != null && !settings.unlocked(scenes[i]!),
                    onTap: () => settings.sugarScene = scenes[i]?.name,
                    picture: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(aspectRatio: 1.6, child: SugarBackdrop(scene: sugarSceneIndex(scenes[i]?.name))),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(s.towerLookLabel, style: _style(16, _ink)),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final l in FloorLook.values) ...[
                if (l.index > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Choice(
                    key: ValueKey('floor-${l.name}'),
                    label: s.floorLookName(l.name),
                    chosen: look == l || (l == FloorLook.lokum && look.unlock != null && !settings.unlocked(look.unlock!)),
                    locked: l.unlock != null && !settings.unlocked(l.unlock!),
                    onTap: () => settings.towerLook = l.name,
                    picture: GiftPicture(size: const Size(56, 48), paint: (canvas, size) => paintFloorStack(canvas, Offset(size.width / 2, size.height * 0.3), l, scale: 0.5)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          CandyButton(
            key: const ValueKey('postcards'),
            label: '${s.postcardsTitle}  ${s.postcardsCount(settings.postcards, Rewards.postcards)}',
            colors: sugarWhite,
            ink: const Color(0xFFD08ABF),
            height: 50,
            textSize: 17,
            icon: Icons.photo_album_rounded,
            onTap: () => showPostcards(context, settings),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.label, required this.chosen, required this.locked, required this.onTap, required this.picture});

  final String label;
  final bool chosen;
  final bool locked;
  final VoidCallback onTap;
  final Widget picture;

  @override
  Widget build(BuildContext context) => Semantics(
    button: !locked,
    selected: chosen,
    label: label,
    child: GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: chosen ? const Color(0xFFFFF0C2) : Colors.white,
          border: Border.all(color: chosen ? const Color(0xFFFFB000) : const Color(0xFFF2D6EA), width: chosen ? 3 : 2),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(opacity: locked ? 0.35 : 1, child: picture),
                if (locked) const Icon(Icons.lock_rounded, size: 20, color: Color(0xFF9A8AB0)),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: _style(12.5, locked ? const Color(0xFF9A8AB0) : _ink))),
          ],
        ),
      ),
    ),
  );
}

// -------------------------------------------------------------- popups --

/// Shows what [gift] held; when it opened something new, says so and
/// offers to try it.
Future<void> showGiftPopup(BuildContext context, Settings settings, Gift gift, {required String title, ChestTier? chest, AudioService? audio}) {
  audio?.play(Sfx.levelup, volume: 0.7);
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xFF1A0838).withValues(alpha: 0.7),
    builder: (context) {
      final s = AppStrings.of(context);
      final unlock = gift.unlock;
      return Dialog(
        key: const ValueKey('gift-popup'),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: CandyPanel(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(fit: BoxFit.scaleDown, child: CandyText(unlock != null ? s.newUnlock : title, size: 26, colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)])),
                  const SizedBox(height: 6),
                  if (unlock != null) ...[
                    _UnlockPicture(unlock: unlock),
                    const SizedBox(height: 6),
                    CandyText(s.unlockName(unlock.name), size: 22, color: _ink, stroke: 0),
                    Text(s.unlockText(unlock.name), textAlign: TextAlign.center, style: _style(14.5, _muted, weight: FontWeight.w700)),
                  ] else
                    _Reveal(chest: chest),
                  const SizedBox(height: 12),
                  Text(s.giftGot, style: _style(14, _muted)),
                  const SizedBox(height: 4),
                  _PopIn(delay: 0.55, child: _GiftItems(gift, size: 40)),
                  if (gift.freezes > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${s.unlockName('freeze')} ×${gift.freezes}', style: _style(15, _ink)),
                    ),
                  if (settings.lastCard case final card?)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GiftPicture(size: const Size(46, 38), paint: (c, size) => paintPostcard(c, Offset.zero & size, card)),
                          const SizedBox(width: 8),
                          Flexible(child: Text(s.newPostcard(s.postcard(card).title), style: _style(14, const Color(0xFFE0247A)))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (unlock != null && _tryable(unlock))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CandyButton(
                        key: const ValueKey('gift-try'),
                        label: s.tryNow,
                        colors: sugarGreen,
                        ink: const Color(0xFF0E6A32),
                        width: double.infinity,
                        height: 50,
                        textSize: 19,
                        onTap: () {
                          _tryUnlock(settings, unlock);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  CandyButton(
                    key: const ValueKey('gift-collect'),
                    label: s.giftCollect,
                    width: double.infinity,
                    height: 48,
                    textSize: 19,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

bool _tryable(Unlock u) => u != Unlock.shuffle && u != Unlock.freeze;

/// Opening a gift: the chest shakes, bursts open with light and confetti.
class _Reveal extends StatefulWidget {
  const _Reveal({this.chest});

  final ChestTier? chest;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _open.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final tone = widget.chest == null ? chestGold : chestTone(widget.chest!);
    return AnimatedBuilder(
      animation: Listenable.merge([_open, _spin]),
      builder: (context, _) {
        final t = still ? 1.0 : _open.value;
        final spin = still ? 0.0 : _spin.value;
        return GiftPicture(
          size: const Size(200, 140),
          repaintKey: (t, spin),
          paint: (canvas, size) {
            final c = size.center(const Offset(0, 14));
            if (t < 0.45) {
              // It shakes, harder and harder.
              final k = t / 0.45;
              canvas.save();
              canvas.translate(c.dx, c.dy);
              canvas.rotate(sin(k * pi * 10) * 0.12 * k);
              paintChest(canvas, Offset.zero, 110, tone, glow: true);
              canvas.restore();
              return;
            }
            final k = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
            paintRays(canvas, c - const Offset(0, 10), 70 + 40 * k, turn: spin * 2 * pi, n: 14, color: Color.fromRGBO(255, 240, 160, 0.5 * k));
            paintChest(canvas, c, 110, tone, open: true, glow: true);
            // Confetti flying out, then drifting.
            final rnd = Random(7);
            const colors = [Color(0xFFFF5FB8), Color(0xFFFFE066), Color(0xFF6BF0A0), Color(0xFF7AC8FF)];
            for (var i = 0; i < 18; i++) {
              final a = -pi / 2 + (rnd.nextDouble() - 0.5) * pi * 1.4;
              final d = (40 + rnd.nextDouble() * 50) * Curves.easeOut.transform(k);
              final p = c + Offset(cos(a) * d, sin(a) * d + 30 * k * k);
              canvas.save();
              canvas.translate(p.dx, p.dy);
              canvas.rotate(a + k * 6);
              canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), Paint()..color = colors[i % 4].withValues(alpha: 1 - k * 0.4));
              canvas.restore();
            }
          },
        );
      },
    );
  }
}

/// [child] pops in [delay] seconds after it is shown.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child, this.delay = 0});

  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = delay + 0.4;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: (total * 1000).round()),
      child: child,
      builder: (context, v, child) {
        final k = ((v * total - delay) / 0.4).clamp(0.0, 1.0);
        return Opacity(opacity: k, child: Transform.scale(scale: 0.6 + 0.4 * Curves.easeOutBack.transform(k), child: child));
      },
    );
  }
}

/// Puts an unlock to use at once: wears the outfit, picks the look.
void _tryUnlock(Settings settings, Unlock u) {
  switch (u) {
    case Unlock.cubesLokum:
      settings.chainCubes = ChainCubeStyle.lokum.name;
    case Unlock.cubesCini:
      settings.chainCubes = ChainCubeStyle.cini.name;
    case Unlock.sceneGalata || Unlock.sceneSnow || Unlock.sceneIslands || Unlock.sceneCamlica:
      settings.sugarScene = u.name;
    case Unlock.outfitTulipCrown || Unlock.outfitCaptain || Unlock.outfitApron || Unlock.outfitSimitNecklace || Unlock.outfitGuide || Unlock.outfitLemonCrown:
      settings.lokumOutfit = LokumOutfit.values.firstWhere((o) => o.gift == u.name).name;
    case Unlock.floorCini || Unlock.floorMarble || Unlock.floorGlass || Unlock.floorGold:
      settings.towerLook = FloorLook.values.firstWhere((l) => l.unlock == u).name;
    case Unlock.shuffle || Unlock.freeze:
      break;
  }
}

class _UnlockPicture extends StatelessWidget {
  const _UnlockPicture({required this.unlock});

  final Unlock unlock;

  @override
  Widget build(BuildContext context) => switch (unlock) {
    Unlock.cubesLokum || Unlock.cubesCini => GiftPicture(
      size: const Size(150, 150),
      paint: (canvas, size) {
        final style = unlock == Unlock.cubesLokum ? ChainCubeStyle.lokum : ChainCubeStyle.cini;
        for (var y = 0; y < 3; y++) {
          for (var x = 0; x < 3; x++) {
            final color = ChainColor.values[(x + y * 2) % 5];
            paintChainCube(canvas, Rect.fromLTWH(x * 50.0 + 2, y * 50.0 + 2, 46, 46), style.colors[color]!, style: style, symbol: color.index);
          }
        }
      },
    ),
    Unlock.sceneGalata || Unlock.sceneSnow || Unlock.sceneIslands || Unlock.sceneCamlica => ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(width: 220, height: 140, child: SugarBackdrop(scene: sugarSceneIndex(unlock.name))),
    ),
    Unlock.shuffle => const SugarBoosterIcon(SugarBooster.shuffle, size: 110),
    Unlock.freeze => const Icon(Icons.hourglass_bottom_rounded, size: 100, color: Color(0xFF3A6CF0)),
    Unlock.floorCini || Unlock.floorMarble || Unlock.floorGlass || Unlock.floorGold => GiftPicture(
      size: const Size(150, 140),
      paint: (canvas, size) => paintFloorStack(canvas, Offset(size.width / 2, size.height * 0.36), FloorLook.values.firstWhere((l) => l.unlock == unlock), scale: 1.4),
    ),
    _ => LokumView(outfit: LokumOutfit.values.firstWhere((o) => o.gift == unlock.name, orElse: () => LokumOutfit.none), pose: LokumPose.cheer, size: 110),
  };
}

/// The İstanbul postcard album: three sets of five, each with its history
/// and a prize for the full set.
Future<void> showPostcards(BuildContext context, Settings settings, {AudioService? audio}) => showDialog<void>(
  context: context,
  barrierColor: const Color(0xFF1A0838).withValues(alpha: 0.7),
  builder: (context) => Dialog(
    key: const ValueKey('postcard-album'),
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(14),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final s = AppStrings.of(context);
          return CandyPanel(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: CandyText(s.postcardsTitle, size: 24, color: _ink, stroke: 0)),
                Text(s.postcardsCount(settings.postcards, Rewards.postcards), style: _style(14, _muted)),
                Text(s.albumHint, textAlign: TextAlign.center, style: _style(12.5, _muted, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var set = 0; set < Rewards.sets; set++) _AlbumSet(settings: settings, set: set, audio: audio),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CandyButton(label: s.close, height: 46, textSize: 18, width: double.infinity, onTap: () => Navigator.of(context).pop()),
              ],
            ),
          );
        },
      ),
    ),
  ),
);

class _AlbumSet extends StatelessWidget {
  const _AlbumSet({required this.settings, required this.set, this.audio});

  final Settings settings;
  final int set;
  final AudioService? audio;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ids = [for (var i = 0; i < Rewards.setSize; i++) set * Rewards.setSize + i];
    final got = ids.where(settings.hasCard).length;
    final done = settings.setComplete(set);
    final claimed = settings.setClaimed(set);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: done ? const Color(0xFFFFF3C8) : Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: done ? const Color(0xFFFFB000) : const Color(0xFFF2D6EA), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(s.postcardSet(set), style: _style(16, _ink))),
              if (claimed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1FB85A)), const SizedBox(width: 3), Text(s.setDone, style: _style(13, const Color(0xFF0E6A32)))],
                )
              else if (done)
                GestureDetector(
                  key: ValueKey('set-claim-$set'),
                  onTap: () {
                    final gift = settings.claimSetPrize(set);
                    if (gift != null) showGiftPopup(context, settings, gift, title: s.postcardSet(set), audio: audio);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1FB85A), borderRadius: BorderRadius.circular(12)),
                    child: Text(s.setClaim, style: _style(13, Colors.white)),
                  ),
                )
              else
                Text('$got / ${Rewards.setSize}', style: _style(13, _muted)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final i in ids) ...[
                if (i != ids.first) const SizedBox(width: 5),
                Expanded(child: _Card(settings: settings, i: i)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.settings, required this.i});

  final Settings settings;
  final int i;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final owned = settings.hasCard(i);
    final card = s.postcard(i);
    return GestureDetector(
      key: ValueKey('postcard-$i'),
      onTap: owned ? () => _showPostcard(context, i) : null,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: LayoutBuilder(builder: (context, box) => GiftPicture(size: box.biggest, paint: (c, size) => paintPostcard(c, Offset.zero & size, i, locked: !owned))),
          ),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(owned ? card.title : card.when, maxLines: 1, style: _style(11.5, owned ? _ink : const Color(0xFF9A8AB0)))),
        ],
      ),
    );
  }
}

void _showPostcard(BuildContext context, int i) => showPostcard(context, i);

/// One postcard, large, with its history.
Future<void> showPostcard(BuildContext context, int i) => showDialog<void>(
  context: context,
  builder: (context) {
    final s = AppStrings.of(context);
    final card = s.postcard(i);
    return Dialog(
      key: const ValueKey('postcard'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF8EC), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 20)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LayoutBuilder(builder: (context, box) => GiftPicture(size: box.biggest, paint: (c, size) => paintStoryScene(c, size, postcardScene(i), t: 8))),
                  ),
                ),
                const SizedBox(height: 10),
                Text(card.when, style: _style(14, const Color(0xFFB07A1E))),
                Text(card.title, style: _style(22, _ink)),
                const SizedBox(height: 4),
                Text(card.fact, style: _style(15, const Color(0xFF4A3A5A), weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
