import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../settings/settings.dart';
import '../theme/palette.dart';
import 'widgets.dart';

/// The player's own records: place, value and day, the one just made
/// ([highlight], 1-based) standing out with a NEW tag.
class RecordsList extends StatelessWidget {
  const RecordsList({super.key, required this.entries, required this.format, this.highlight = 0, this.count = 5});

  final List<ScoreEntry> entries;
  final String Function(int value) format;
  final int highlight;
  final int count;

  static const _medals = [Color(0xFFFACC15), Color(0xFFCBD5E1), Color(0xFFE59E5A)];

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final rows = entries.take(count).toList();
    return Column(
      key: const ValueKey('records-list'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in rows.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(p.skin == GameSkin.pixel ? 3 : 12),
                gradient: i + 1 == highlight ? const LinearGradient(colors: [Color(0xFFFF5FB8), Color(0xFFB45BFF)]) : null,
                color: i + 1 == highlight ? null : p.text.withValues(alpha: 0.07),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: i < 3 ? _medals[i] : p.track, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: i < 3 ? const Color(0xFF3A2A00) : p.text)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      format(e.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: i + 1 == highlight ? Colors.white : p.text),
                    ),
                  ),
                  if (i + 1 == highlight)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                      child: Text(s.newBadge, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFFE0247A))),
                    ),
                  Text(
                    i + 1 == highlight ? s.recordJustNow : (e.at == null ? s.recordEarlier : s.shortDate(e.at!)),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: i + 1 == highlight ? Colors.white : p.muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// What to aim for next, under a list of records: the place above, or the
/// top five; for the best one, to widen the gap.
String recordGoal(AppStrings s, List<ScoreEntry> entries, int place, int value, String Function(int gap) gapText, {bool lower = false}) {
  if (place == 1) return s.recordYours;
  if (place > 1 && place - 2 < entries.length) {
    final above = entries[place - 2].value;
    return s.recordNextPlace(place - 1, gapText(lower ? value - above : above - value));
  }
  if (entries.length >= 5) {
    final fifth = entries[4].value;
    return s.recordTopFive(gapText(lower ? value - fifth + 1 : fifth - value + 1));
  }
  return '';
}

/// A title, the list and the next goal, as they show when a game ends.
class RecordsBlock extends StatelessWidget {
  const RecordsBlock({super.key, required this.entries, required this.format, required this.place, required this.goal});

  final List<ScoreEntry> entries;
  final String Function(int value) format;
  final int place;
  final String goal;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (place > 1)
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFF5FB8), borderRadius: BorderRadius.circular(14)),
              child: Text(s.recordPlace(place), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
            ),
          ),
        Padding(padding: const EdgeInsets.only(left: 2, bottom: 4), child: CardLabel(s.recordsTitle)),
        RecordsList(entries: entries, format: format, highlight: place),
        if (goal.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: p.text.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded, size: 18, color: Color(0xFFFACC15)),
                const SizedBox(width: 8),
                Expanded(child: Text(goal, key: const ValueKey('record-goal'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.text))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Every mode's records of a game in one sheet, a tab per mode.
Future<void> showRecordsSheet(BuildContext context, {required String title, required List<(String, String, String Function(int))> modes, required Settings settings}) => showDialog<void>(
  context: context,
  builder: (context) => _RecordsSheet(title: title, modes: modes, settings: settings),
);

class _RecordsSheet extends StatefulWidget {
  const _RecordsSheet({required this.title, required this.modes, required this.settings});

  final String title;

  /// Each tab: its name, the records' key, how a value reads.
  final List<(String, String, String Function(int))> modes;
  final Settings settings;

  @override
  State<_RecordsSheet> createState() => _RecordsSheetState();
}

class _RecordsSheetState extends State<_RecordsSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    final (_, key, format) = widget.modes[_tab];
    final entries = widget.settings.records(key);
    return Dialog(
      key: const ValueKey('records-sheet'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(color: p.background.first, borderRadius: BorderRadius.circular(24)),
          child: GlassCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFFACC15)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${s.recordsShort} · ${widget.title}', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: p.text))),
                      GlassIconButton(icon: Icons.close_rounded, tooltip: s.back, size: 34, onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.modes.length > 1)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (i, (name, _, _)) in widget.modes.indexed)
                          GestureDetector(
                            key: ValueKey('records-tab-$i'),
                            onTap: () => setState(() => _tab = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: i == _tab ? const Color(0xFFFF5FB8) : p.track, borderRadius: BorderRadius.circular(16)),
                              child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: i == _tab ? Colors.white : p.text)),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(s.recordsNone, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.muted, fontWeight: FontWeight.w700)),
                    )
                  else
                    RecordsList(entries: entries, format: format, count: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
