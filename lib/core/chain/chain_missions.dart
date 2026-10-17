import 'chain_game.dart';
import 'chain_versus.dart';

/// "Vapur Hattı": Zincir Küpler's missions along the Bosphorus ferry line,
/// five at each pier, harder as the ferry goes north.
abstract final class ChainMissions {
  static const int perPier = 5;

  /// The piers, from Eminönü up the Bosphorus to Anadolu Kavağı.
  static const List<String> piers = [
    'Eminönü',
    'Karaköy',
    'Üsküdar',
    'Kabataş',
    'Beşiktaş',
    'Kuzguncuk',
    'Ortaköy',
    'Beylerbeyi',
    'Arnavutköy',
    'Çengelköy',
    'Bebek',
    'Kandilli',
    'Rumelihisarı',
    'Kanlıca',
    'Emirgan',
    'Paşabahçe',
    'Yeniköy',
    'Beykoz',
    'Sarıyer',
    'Anadolu Kavağı',
  ];

  static int get count => piers.length * perPier;

  static int pierOf(int mission) => (mission - 1) ~/ perPier;

  static ChainMission of(int number) => all[(number - 1).clamp(0, all.length - 1)];

  /// The rival a match mission at pier [pier] is against.
  static ChainRival rivalAt(int pier) => pier < 8 ? ChainRival.apprentice : (pier < 15 ? ChainRival.journeyman : ChainRival.master);

  static final List<ChainMission> all = [
    for (var p = 0; p < piers.length; p++) ..._pier(p),
  ];

  static List<ChainMission> _pier(int p) {
    final d = p < 6 ? ChainDifficulty.easy : (p < 13 ? ChainDifficulty.normal : ChainDifficulty.hard);
    final n = p * perPier;
    final chainTarget = p < 5 ? 2 : (p < 14 ? 3 : 4);
    final chains = p % 3 == 2 ? 2 : 1;
    return [
      ChainMission(number: n + 1, kind: MissionKind.chain, target: chainTarget, count: chains, seconds: 80.0 + 20 * chains + 5 * (chainTarget - 2), difficulty: d),
      ChainMission(number: n + 2, kind: MissionKind.score, target: (1200 + p * 300) ~/ 100 * 100, seconds: 90, difficulty: d),
      ChainMission(number: n + 3, kind: MissionKind.garbage, target: 12 + (p ~/ 2) * 3, seconds: 100, difficulty: d),
      ChainMission(number: n + 4, kind: MissionKind.puzzle, target: 1 + p * 4 + (p % 4)),
      p % 4 == 3
          ? ChainMission(number: n + 5, kind: MissionKind.versus, target: rivalAt(p).index)
          : ChainMission(number: n + 5, kind: MissionKind.survive, target: 0, seconds: 60.0 + p * 4, difficulty: d),
    ];
  }

  /// Stars for a mission done with [left] seconds to spare (timed goals),
  /// or with the longest chain [chain] (surviving).
  static int stars(ChainMission m, {required double left, required int chain}) => switch (m.kind) {
    MissionKind.survive => chain >= 3 ? 3 : (chain >= 2 ? 2 : 1),
    MissionKind.puzzle => 3,
    MissionKind.versus => 3,
    _ => left >= m.seconds / 2 ? 3 : (left >= m.seconds / 4 ? 2 : 1),
  };
}
