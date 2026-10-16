import 'sugar_game.dart';

/// The Şeker Küpler levels: three chapters of ten. Every fifth level opens a
/// chest; the tenth of a chapter is its boss.
class SugarLevels {
  static const int perChapter = 10;
  static int get count => all.length;
  static int chapterOf(int level) => (level - 1) ~/ perChapter;
  static bool chestAt(int level) => level % 5 == 0;

  static SugarLevel of(int number) => all[(number - 1).clamp(0, all.length - 1)];

  static final List<SugarLevel> all = [
    // -------------------------------------------- 1 · Şeker Kasabası --
    _l(1, 20, 5, _open, [() => SugarGoal.score(6000)], [6000, 11500, 15000], hint: 'swap'),
    _l(2, 18, 5, _open, [() => SugarGoal.color(SugarColor.red, 30)], [5500, 10000, 13000]),
    _l(3, 18, 5, _open, [() => SugarGoal.score(9000)], [9000, 13000, 17500], hint: 'line'),
    _l(4, 18, 5, _open, [() => SugarGoal.color(SugarColor.blue, 24), () => SugarGoal.color(SugarColor.yellow, 24)], [5000, 9500, 13000]),
    _l(5, 20, 5, _open, [() => SugarGoal.score(12000)], [12000, 14500, 20000], hint: 'bomb'),
    _l(6, 18, 5, _open, [() => SugarGoal.color(SugarColor.green, 32), () => SugarGoal.color(SugarColor.orange, 32)], [5000, 9000, 14500]),
    _l(7, 20, 5, _open, [() => SugarGoal.score(11000)], [11000, 14500, 20000], hint: 'prism'),
    _l(8, 18, 5, _open, [() => SugarGoal.color(SugarColor.orange, 45)], [6500, 12000, 15500], hard: true),
    _l(9, 21, 6, _open, [() => SugarGoal.color(SugarColor.red, 20), () => SugarGoal.color(SugarColor.blue, 20)], [4000, 7500, 10500]),
    _l(10, 22, 5, _open, [() => SugarGoal.score(16000), () => SugarGoal.color(SugarColor.yellow, 40)], [16000, 18500, 21000], boss: true),

    // ------------------------------------------------- 2 · Buzlu Vadi --
    _l(11, 18, 5, _iceMiddle, [() => SugarGoal.ice(16)], [5000, 9500, 14000], hint: 'ice'),
    _l(12, 20, 5, _iceBottom, [() => SugarGoal.ice(16)], [7000, 13000, 15500]),
    _l(13, 17, 5, _iceCross, [() => SugarGoal.ice(28), () => SugarGoal.color(SugarColor.green, 15)], [6500, 12500, 16500]),
    _l(14, 21, 5, _iceFrame, [() => SugarGoal.ice(22)], [7000, 13000, 14500]),
    _l(15, 15, 5, _thickMiddle, [() => SugarGoal.ice(12)], [5500, 10000, 12500], hint: 'thickIce'),
    _l(16, 25, 6, _iceDiamond, [() => SugarGoal.ice(28)], [5500, 11000, 14000]),
    _l(17, 16, 5, _iceStripes, [() => SugarGoal.ice(24), () => SugarGoal.color(SugarColor.yellow, 20)], [6000, 11500, 14500]),
    _l(18, 13, 5, _thickBand, [() => SugarGoal.ice(12)], [6000, 11000, 14000], hard: true),
    _l(19, 22, 5, _iceHalf, [() => SugarGoal.ice(32)], [6500, 12500, 16500]),
    _l(20, 24, 5, _iceAll, [() => SugarGoal.ice(64)], [10500, 20000, 24000], boss: true),

    // ---------------------------------------------- 3 · Zincir Kalesi --
    _l(21, 20, 5, _chainRow, [() => SugarGoal.score(12000)], [12000, 16000, 20500], hint: 'chain'),
    _l(22, 20, 5, _chainPairs, [() => SugarGoal.color(SugarColor.red, 40)], [6000, 11500, 18500]),
    _l(23, 20, 5, _chainIce, [() => SugarGoal.ice(12), () => SugarGoal.color(SugarColor.blue, 30)], [6500, 12500, 14000]),
    _l(24, 22, 5, _chainCross, [() => SugarGoal.score(10000), () => SugarGoal.color(SugarColor.blue, 28)], [10000, 13000, 19500]),
    _l(25, 19, 5, _chainFrameIce, [() => SugarGoal.ice(20)], [6500, 12500, 15000]),
    _l(26, 22, 6, _chainDiagonal, [() => SugarGoal.color(SugarColor.green, 20), () => SugarGoal.color(SugarColor.orange, 20)], [4500, 9000, 10500]),
    _l(27, 15, 5, _chainThick, [() => SugarGoal.ice(12)], [7000, 13000, 16000]),
    _l(28, 16, 5, _chainVault, [() => SugarGoal.ice(16), () => SugarGoal.color(SugarColor.green, 25)], [6000, 11000, 13500], hard: true),
    _l(29, 24, 5, _chainBand, [() => SugarGoal.score(12000)], [12000, 17000, 20500]),
    _l(30, 27, 5, _fortress, [() => SugarGoal.ice(28), () => SugarGoal.color(SugarColor.red, 30)], [8000, 15000, 22500], boss: true),
  ];

  static SugarLevel _l(
    int n,
    int moves,
    int colors,
    List<String> layout,
    List<SugarGoal Function()> goals,
    List<int> stars, {
    bool boss = false,
    bool hard = false,
    String? hint,
  }) {
    assert(layout.length == SugarGame.size && layout.every((r) => r.length == SugarGame.size));
    return SugarLevel(number: n, moves: moves, colors: colors, layout: layout, goals: goals, stars: stars, boss: boss, hard: hard, hint: hint);
  }

  // '.' plain · 'i' ice · 'I' thick ice · 'c' chained · 'C' chained on ice

  static const _open = ['........', '........', '........', '........', '........', '........', '........', '........'];
  static const _iceMiddle = ['........', '........', '..iiii..', '..iiii..', '..iiii..', '..iiii..', '........', '........'];
  static const _iceBottom = ['........', '........', '........', '........', '........', '........', 'iiiiiiii', 'iiiiiiii'];
  static const _iceCross = ['...ii...', '...ii...', '...ii...', 'iiiiiiii', 'iiiiiiii', '...ii...', '...ii...', '...ii...'];
  static const _iceFrame = ['iiiiiii.', 'i......i', 'i......i', '........', '........', 'i......i', 'i......i', '.iiiiiii'];
  static const _thickMiddle = ['........', '........', '..IIII..', '..I..I..', '..I..I..', '..IIII..', '........', '........'];
  static const _iceDiamond = ['...ii...', '..iiii..', '.ii..ii.', 'ii....ii', 'ii....ii', '.ii..ii.', '..iiii..', '...ii...'];
  static const _iceStripes = ['........', 'iiiiiiii', '........', 'iiiiiiii', '........', 'iiiiiiii', '........', '........'];
  static const _thickBand = ['........', '........', '........', '.IIIIII.', '.IIIIII.', '........', '........', '........'];
  static const _iceHalf = ['........', '........', '........', '........', 'iiiiiiii', 'iiiiiiii', 'iiiiiiii', 'iiiiiiii'];
  static const _iceAll = ['iiiiiiii', 'iiiiiiii', 'iiiiiiii', 'iiiiiiii', 'iiiiiiii', 'iiiiiiii', 'iiiiiiii', 'iiiiiiii'];
  static const _chainRow = ['........', '........', '........', 'c.c..c.c', '........', '........', '........', '........'];
  static const _chainPairs = ['........', '.cc..cc.', '........', '........', '........', '........', '.cc..cc.', '........'];
  static const _chainIce = ['........', '........', '..iCCi..', '..i..i..', '..i..i..', '..iCCi..', '........', '........'];
  static const _chainCross = ['...c....', '...c....', '...c....', 'ccc.cccc', '...c....', '...c....', '...c....', '...c....'];
  static const _chainFrameIce = ['........', '.CiiiiC.', '.i....i.', '.i....i.', '.i....i.', '.i....i.', '.CiiiiC.', '........'];
  static const _chainDiagonal = ['c.......', '.c......', '..c.....', '...c....', '....c...', '.....c..', '......c.', '.......c'];
  static const _chainThick = ['........', '........', 'cIIccIIc', '..I..I..', '..I..I..', 'cIIccIIc', '........', '........'];
  static const _chainVault = ['........', '..cccc..', '..CiiC..', '..iiii..', '..iiii..', '..CiiC..', '..cccc..', '........'];
  static const _chainBand = ['........', '........', 'cccccccc', '........', '........', 'cccccccc', '........', '........'];
  static const _fortress = ['CiiiiiiC', 'i......i', 'i.cccc.i', 'i.c..c.i', 'i.c..c.i', 'i.cccc.i', 'i......i', 'CiiiiiiC'];
}

/// Helpers a player can spend in a level: smash one cube, shuffle the
/// board, [extraMoves] more moves.
enum SugarBooster {
  hammer,
  shuffle,
  moves;

  static const int extraMoves = 3;

  /// What a new player starts with.
  int get starting => switch (this) {
    hammer => 3,
    shuffle => 2,
    moves => 1,
  };

  /// What the chest on [level] holds (every fifth level).
  static Map<SugarBooster, int> chest(int level) => switch ((level ~/ 5) % 3) {
    1 => {hammer: 1, shuffle: 1},
    2 => {moves: 1, hammer: 1},
    _ => {hammer: 2, shuffle: 1, moves: 1},
  };
}
