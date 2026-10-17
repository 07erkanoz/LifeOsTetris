import 'package:flutter/material.dart';

import '../game/sugar/sugar_art.dart';
import '../l10n/strings.dart';
import '../settings/settings.dart';
import 'sugar_widgets.dart';

/// What Lokum wears, read from the settings: the chosen outfit while it is
/// still unlocked, else none.
extension LokumWardrobe on Settings {
  LokumOutfit get outfit => LokumOutfit.worn(lokumOutfit, totalSugarStars, unlocks);
}

/// Lokum on his own, [size] tall, wearing [outfit].
class LokumView extends StatelessWidget {
  const LokumView({super.key, required this.outfit, this.pose = LokumPose.happy, this.size = 60, this.hop = 0, this.beat = 0, this.pointLeft = false});

  final LokumOutfit outfit;
  final LokumPose pose;
  final double size;
  final double hop;
  final double beat;
  final bool pointLeft;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.25,
    height: size * 1.3,
    child: CustomPaint(painter: _LokumViewPainter(pose, outfit, hop, beat, pointLeft)),
  );
}

class _LokumViewPainter extends CustomPainter {
  _LokumViewPainter(this.pose, this.outfit, this.hop, this.beat, this.pointLeft);

  final LokumPose pose;
  final LokumOutfit outfit;
  final double hop;
  final double beat;
  final bool pointLeft;

  @override
  void paint(Canvas canvas, Size size) => paintLokum(canvas, Offset(size.width / 2, size.height * 0.56), size.height / 1.3, pose: pose, hop: hop, beat: beat, pointLeft: pointLeft, outfit: outfit);

  @override
  bool shouldRepaint(_LokumViewPainter old) => old.pose != pose || old.outfit != outfit || old.hop != hop || old.beat != beat || old.pointLeft != pointLeft;
}

/// Lokum's wardrobe: every outfit, the stars each needs, and the one he
/// wears everywhere.
Future<void> showLokumWardrobe(BuildContext context, Settings settings) => showDialog<void>(
  context: context,
  barrierColor: const Color(0xFF1A0838).withValues(alpha: 0.7),
  builder: (context) => Dialog(
    key: const ValueKey('wardrobe'),
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => _Wardrobe(settings: settings),
      ),
    ),
  ),
);

class _Wardrobe extends StatelessWidget {
  const _Wardrobe({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final stars = settings.totalSugarStars;
    final worn = settings.outfit;
    return CandyPanel(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CandyText(s.wardrobeTitle, size: 28, colors: const [Color(0xFFFFF6B0), Color(0xFFFFC21A), Color(0xFFFF6A00)]),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF2A0B4F).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(18)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const SugarStars(on: 1, count: 1, size: 11), const SizedBox(width: 2), CandyText(s.starsCount(stars), size: 17, stroke: 0)]),
            ),
            LokumView(key: const ValueKey('wardrobe-lokum'), outfit: worn, pose: LokumPose.cheer, size: 104),
            LayoutBuilder(
              builder: (context, box) {
                const gap = 8.0;
                final w = (box.maxWidth - gap * 2) / 3;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final o in LokumOutfit.values)
                      SizedBox(
                        width: w,
                        child: _OutfitTile(outfit: o, worn: o == worn, locked: !o.open(stars, settings.unlocks), onTap: () => settings.lokumOutfit = o == LokumOutfit.none ? null : o.name),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              s.wardrobeHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Baloo2', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF9A5AB5), height: 1.15),
            ),
            const SizedBox(height: 12),
            CandyButton(key: const ValueKey('wardrobe-close'), label: s.close, height: 48, textSize: 19, width: double.infinity, onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _OutfitTile extends StatelessWidget {
  const _OutfitTile({required this.outfit, required this.worn, required this.locked, required this.onTap});

  final LokumOutfit outfit;
  final bool worn;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Semantics(
      button: !locked,
      selected: worn,
      label: s.outfitName(outfit.name),
      child: GestureDetector(
        key: ValueKey('outfit-${outfit.name}'),
        onTap: locked ? null : onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: worn ? const [Color(0xFFFFF3C8), Color(0xFFFFD36B)] : const [Color(0xFFFFFFFF), Color(0xFFFFEAF6)],
            ),
            border: Border.all(color: worn ? const Color(0xFFFFB000) : Colors.white, width: worn ? 3 : 2),
            boxShadow: [BoxShadow(color: const Color(0xFFD08ABF).withValues(alpha: 0.7), offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Opacity(
                opacity: locked ? 0.4 : 1,
                child: LokumView(outfit: outfit, size: 54),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  s.outfitName(outfit.name),
                  maxLines: 1,
                  style: const TextStyle(fontFamily: 'Baloo2', fontSize: 14, fontWeight: FontWeight.w800, color: sugarInk),
                ),
              ),
              SizedBox(
                height: 20,
                child: locked && outfit.gift != null
                    ? Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(s.outfitEvent, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF9A8AB0))),
                        ),
                      )
                    : locked
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF9A8AB0)),
                            const SizedBox(width: 3),
                            const SugarStars(on: 1, count: 1, size: 8),
                            Text(
                              '${outfit.stars}',
                              style: const TextStyle(fontFamily: 'Baloo2', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF9A8AB0)),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(
                          worn ? s.outfitWorn : s.outfitWear,
                          style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w800, color: worn ? const Color(0xFF0E6A32) : const Color(0xFFE0247A)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
