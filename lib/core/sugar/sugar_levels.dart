import 'sugar_game.dart';

/// The Şeker Küpler levels: six chapters of ten. Every fifth level opens a
/// chest; the tenth of a chapter is its boss. Each chapter brings something
/// new: ice, chains, candy boxes, timed bombs, then all of them.
class SugarLevels {
  static const int perChapter = 10;
  static const int chapters = 6;
  static int get count => all.length;
  static int chapterOf(int level) => ((level - 1) ~/ perChapter).clamp(0, chapters - 1);
  static bool chestAt(int level) => level % 5 == 0;

  static SugarLevel of(int number) => all[(number - 1).clamp(0, all.length - 1)];

  static SugarGoal Function() _score(int n) => () => SugarGoal.score(n);
  static SugarGoal Function() _color(SugarColor c, int n) => () => SugarGoal.color(c, n);
  static SugarGoal Function() _ice(int n) => () => SugarGoal.ice(n);
  static SugarGoal Function() _box(int n) => () => SugarGoal.box(n);

  static const _r = SugarColor.red, _o = SugarColor.orange, _y = SugarColor.yellow, _g = SugarColor.green, _b = SugarColor.blue;

  static final List<SugarLevel> all = [
    // ------------------------------------------------ 1 · Şeker Kasabası --
    _l(1, 15, 5, _open, [_score(4500)], [4500, 7000, 9500], hint: 'swap'),
    _l(2, 15, 5, _open, [_color(_r, 25)], [7000, 11000, 15500]),
    _l(3, 16, 5, _open, [_score(2000)], [2000, 9000, 11000], hint: 'line'),
    _l(4, 16, 5, _open, [_color(_b, 25), _color(_y, 25)], [8500, 12000, 14500]),
    _l(5, 21, 5, _open, [_color(_g, 35)], [8000, 26000, 32000], hint: 'bomb'),
    _l(6, 22, 5, _open, [_color(_g, 30), _color(_o, 30)], [10500, 14000, 26500]),
    _l(7, 18, 5, _open, [_score(7000)], [7000, 9500, 10000], hint: 'prism'),
    _l(8, 18, 5, _open, [_color(_o, 45)], [10000, 16500, 19000], hard: true),
    _l(9, 22, 6, _open, [_color(_r, 22), _color(_b, 22)], [7000, 10500, 15500]),
    _l(10, 20, 5, _open, [_color(_y, 48)], [9000, 16000, 19000], boss: true, hint: 'rush'),

    // ---------------------------------------------------- 2 · Buzlu Vadi --
    _l(11, 14, 5, _iceMiddle, [_ice(16)], [8000, 11500, 18500], hint: 'ice'),
    _l(12, 30, 5, _iceBottom, [_ice(16)], [17500, 38500, 47000]),
    _l(13, 23, 5, _iceCross, [_ice(28), _color(_g, 15)], [11500, 24000, 32000]),
    _l(14, 23, 5, _iceFrame, [_ice(22)], [12000, 17500, 20000]),
    _l(15, 21, 5, _thickMiddle, [_ice(12)], [10000, 18000, 31000], hint: 'thickIce'),
    _l(16, 32, 6, _iceDiamond, [_ice(28)], [14000, 31500, 46000]),
    _l(17, 16, 5, _iceStripes, [_ice(24), _color(_y, 24)], [6500, 10500, 12000]),
    _l(18, 16, 5, _thickBand, [_ice(12)], [8500, 18000, 24500], hard: true),
    _l(19, 20, 5, _iceHalf, [_ice(32)], [14000, 19000, 23500]),
    _l(20, 24, 5, _iceAll, [_ice(64)], [13000, 18000, 22000], boss: true),

    // ------------------------------------------------- 3 · Zincir Kalesi --
    _l(21, 20, 5, _chainRow, [_score(6500)], [6500, 8000, 9000], hint: 'chain'),
    _l(22, 32, 5, _chainPairs, [_color(_r, 35)], [19500, 30500, 37500]),
    _l(23, 26, 5, _chainIce, [_ice(12), _color(_b, 30)], [9000, 20000, 26500]),
    _l(24, 28, 5, _chainCross, [_color(_b, 28), _color(_r, 28)], [9000, 18000, 22000]),
    _l(25, 30, 5, _chainFrameIce, [_ice(20)], [8500, 41500, 60000]),
    _l(26, 24, 6, _chainDiagonal, [_color(_g, 20), _color(_o, 20)], [6000, 9500, 16000]),
    _l(27, 23, 5, _chainThick, [_ice(12)], [7500, 17000, 24500]),
    _l(28, 22, 5, _chainVault, [_ice(16), _color(_g, 25)], [8000, 11000, 15500], hard: true),
    _l(29, 22, 5, _chainBand, [_score(3500)], [3500, 7500, 9500]),
    _l(30, 28, 5, _fortress, [_ice(28), _color(_r, 30)], [9000, 14000, 22000], boss: true),

    // ------------------------------------------------ 4 · Kutu Fabrikası --
    _l(31, 14, 5, _boxPairs, [_box(4)], [15000, 19000, 23000], hint: 'box'),
    _l(32, 14, 5, _boxRing, [_box(12)], [7500, 16000, 20000]),
    _l(33, 16, 5, _boxDoubleSides, [_box(4), _color(_o, 25)], [6500, 8500, 9000], hint: 'box2'),
    _l(34, 14, 5, _boxBars, [_box(8)], [7500, 11000, 14500]),
    _l(35, 22, 5, _boxIce, [_box(8), _ice(16)], [9000, 13500, 17500]),
    _l(36, 18, 5, _boxCross, [_box(12)], [10000, 14500, 21000]),
    _l(37, 22, 5, _boxShelf, [_box(6), _color(_b, 30)], [7000, 15500, 22500]),
    _l(38, 16, 5, _boxIceVault, [_box(8), _ice(12)], [6000, 11000, 12500], hard: true),
    _l(39, 20, 5, _boxChains, [_box(8), _color(_y, 30)], [4500, 11000, 15500]),
    _l(40, 22, 5, _boxFortress, [_box(12), _ice(12)], [11500, 19000, 21500], boss: true),

    // ------------------------------------------------- 5 · Bomba Kanyonu --
    _l(41, 22, 5, _bombsTwo, [_color(_r, 30)], [7000, 19000, 21000], hint: 'timed', bombTimer: 12),
    _l(42, 20, 5, _open, [_color(_b, 35)], [6500, 10000, 14500], bombEvery: 5, bombTimer: 10),
    _l(43, 14, 5, _bombIce, [_ice(14)], [8000, 14000, 16000], bombTimer: 11),
    _l(44, 14, 5, _bombBoxes, [_box(8)], [11500, 15500, 18000], bombEvery: 6, bombTimer: 10),
    _l(45, 28, 5, _chainPairs, [_color(_g, 35)], [8500, 17500, 24500], bombEvery: 4, bombTimer: 9),
    _l(46, 18, 5, _iceStripes, [_ice(24)], [6000, 10000, 14500], bombEvery: 5, bombTimer: 9),
    _l(47, 16, 5, _bombsFour, [_color(_o, 22), _color(_g, 22)], [7000, 10500, 14500], bombTimer: 16),
    _l(48, 26, 5, _boxIce, [_box(8), _ice(16)], [13000, 23500, 26500], hard: true, bombEvery: 4, bombTimer: 8),
    _l(49, 24, 5, _open, [_score(10000)], [10000, 11500, 12000], bombEvery: 3, bombTimer: 9),
    _l(50, 30, 5, _bombFortress, [_box(12), _ice(10)], [17500, 29500, 41500], boss: true, bombEvery: 6, bombTimer: 11),

    // ---------------------------------------------- 6 · Gökkuşağı Adası --
    _l(51, 14, 5, _rainbowArch, [_ice(14), _box(4)], [7500, 10500, 12500]),
    _l(52, 22, 6, _iceCross, [_ice(28)], [5500, 9000, 13000]),
    _l(53, 24, 5, _chainCross, [_color(_r, 22), _color(_g, 22)], [4500, 12500, 23000], bombEvery: 6, bombTimer: 11),
    _l(54, 24, 5, _boxCross, [_box(12), _color(_y, 25)], [7500, 26000, 28500]),
    _l(55, 14, 5, _rainbowIsland, [_ice(24), _box(4)], [7000, 9500, 13500], bombEvery: 5, bombTimer: 10),
    _l(56, 24, 6, _open, [_score(5500)], [5500, 6500, 8000], bombEvery: 4, bombTimer: 10),
    _l(57, 18, 5, _boxChains, [_box(8), _color(_o, 30)], [6000, 11500, 13000], bombEvery: 5, bombTimer: 9),
    _l(58, 14, 5, _boxIceVault, [_box(8), _ice(12)], [5500, 10000, 12000], hard: true, bombEvery: 4, bombTimer: 9),
    _l(59, 32, 5, _chainFrameIce, [_ice(20)], [15000, 26000, 46500], bombEvery: 6, bombTimer: 11),
    _l(60, 40, 5, _grandFinale, [_box(8), _ice(24), _color(_r, 35)], [19000, 32500, 43000], boss: true, bombEvery: 6, bombTimer: 11),
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
    int bombTimer = 9,
    int bombEvery = 0,
  }) {
    assert(layout.length == SugarGame.size && layout.every((r) => r.length == SugarGame.size));
    // Earlier chapters are luckier: more specials from the sky, more free
    // cascades, a gift or two on the board, a faster sugar rush.
    final ch = (n - 1) ~/ perChapter;
    return SugarLevel(
      number: n,
      moves: moves,
      colors: colors,
      layout: layout,
      goals: goals,
      stars: stars,
      boss: boss,
      hard: hard,
      hint: hint,
      bombTimer: bombTimer,
      bombEvery: bombEvery,
      luck: const [18, 14, 12, 10, 9, 8][ch],
      gifts: n <= 5 ? 2 : (ch <= 1 || boss ? 1 : 0),
      rush: const [70, 80, 90, 95, 100, 105][ch],
      calm: const [40, 48, 52, 55, 58, 58][ch],
    );
  }

  // '.' plain · 'i' ice · 'I' thick ice · 'c' chained · 'C' chained on ice
  // 'K' box (two layers) · 'k' box (one layer) · 'T' timed bomb

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
  static const _boxPairs = ['........', '........', '........', '.kk..kk.', '........', '........', '........', '........'];
  static const _boxRing = ['........', '........', '..kkkk..', '..k..k..', '..k..k..', '..kkkk..', '........', '........'];
  static const _boxDoubleSides = ['........', '........', '........', 'KK....KK', '........', '........', '........', '........'];
  static const _boxBars = ['........', '........', '..KKKK..', '........', '........', '..KKKK..', '........', '........'];
  static const _boxIce = ['iiiiiiii', '........', '.kk..kk.', '........', '........', '.kk..kk.', '........', 'iiiiiiii'];
  static const _boxCross = ['k......k', '.k....k.', '..k..k..', '........', '........', '..k..k..', '.k....k.', 'k......k'];
  static const _boxShelf = ['........', 'KKK..KKK', '........', '........', '........', '........', '........', '........'];
  static const _boxIceVault = ['........', '.K.KK.K.', '........', '.iiiiii.', '.iiiiii.', '........', '.K.KK.K.', '........'];
  static const _boxChains = ['........', '..cccc..', '.k....k.', '.k....k.', '.k....k.', '.k....k.', '..cccc..', '........'];
  static const _boxFortress = ['KK....KK', 'K......K', '...ii...', '..iiii..', '..iiii..', '...ii...', 'K......K', 'KK....KK'];
  static const _bombsTwo = ['........', '........', '..T.....', '........', '........', '.....T..', '........', '........'];
  static const _bombIce = ['........', '........', '..iiii..', '..iTii..', '..iiTi..', '..iiii..', '........', '........'];
  static const _bombBoxes = ['........', '........', '.kk..kk.', '........', '...T....', '.kk..kk.', '........', '........'];
  static const _bombsFour = ['........', '.T....T.', '........', '........', '........', '........', '.T....T.', '........'];
  static const _bombFortress = ['KK....KK', 'K......K', '...ii...', '..iTii..', '..iiTi..', '...ii...', 'K......K', 'KK....KK'];
  static const _rainbowArch = ['........', '..iiii..', '.ii..ii.', '.i....i.', '.i.kk.i.', '.i.kk.i.', '........', '........'];
  static const _rainbowIsland = ['........', '..iiii..', '.iiiiii.', '.ik..ki.', '.ik..ki.', '.iiiiii.', '..iiii..', '........'];
  static const _grandFinale = ['KiiiiiiK', 'i......i', 'i.KccK.i', 'i.c..c.i', 'i.c..c.i', 'i.KccK.i', 'i......i', 'KiiiiiiK'];
}

/// Helpers a player can spend in a level: smash one sweet, turn one into a
/// rainbow ball, [extraMoves] more moves.
enum SugarBooster {
  hammer,
  rainbow,
  moves,

  /// Shuffles the board (opened by the first full sugar jar).
  shuffle;

  static const int extraMoves = 3;

  /// What a new player starts with.
  int get starting => switch (this) {
    hammer => 3,
    rainbow => 1,
    moves => 2,
    shuffle => 0,
  };

  /// What the chest on [level] holds (every fifth level).
  static Map<SugarBooster, int> chest(int level) => switch ((level ~/ 5) % 3) {
    1 => {hammer: 2, rainbow: 1},
    2 => {moves: 1, hammer: 1, rainbow: 1},
    _ => {hammer: 2, rainbow: 1, moves: 1},
  };
}
