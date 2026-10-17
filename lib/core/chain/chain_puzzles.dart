/// A Zincir Küpler puzzle: a still stack to clear in exactly [moves] swaps.
class ChainPuzzle {
  const ChainPuzzle(this.moves, this.rows);

  final int moves;

  /// The stack, top to bottom, at the bottom of the board.
  final List<String> rows;
}

/// The eighty puzzles in four packs of twenty, each pack a little harder.
/// Made by tool/chain_puzzles_gen_test.dart: the fewest swaps that clear
/// each one is its count, checked on the real game.
abstract final class ChainPuzzles {
  static const int perPack = 20;
  static int get count => all.length;
  static int get packs => count ~/ perPack;
  static int packOf(int n) => (n - 1) ~/ perPack;

  static ChainPuzzle of(int n) => all[(n - 1).clamp(0, all.length - 1)];

  static const List<ChainPuzzle> all = [
    // Eminönü: 1–20
    ChainPuzzle(1, ['..M...', 'MYMYY.']),
    ChainPuzzle(1, ['YYMYMM']),
    ChainPuzzle(1, ['...MM.', '..YMYY']),
    ChainPuzzle(1, ['.MY...', '.MMYY.']),
    ChainPuzzle(1, ['...Y..', '.YMYMM']),
    ChainPuzzle(1, ['..MM..', '.YYMY.']),
    ChainPuzzle(2, ['..YM..', '..MMYY']),
    ChainPuzzle(2, ['..M...', 'M.Y...', 'MYY...']),
    ChainPuzzle(2, ['...M..', '...M..', '..YYMY']),
    ChainPuzzle(2, ['.MM...', '.YY...', '.MY...']),
    ChainPuzzle(2, ['.M.M..', '.Y.Y..', '.MMYMM']),
    ChainPuzzle(2, ['..Y.Y.', '..Y.YY', '..MYMM']),
    ChainPuzzle(2, ['...Y..', '...Y.Y', 'MMYMYY']),
    ChainPuzzle(2, ['..M...', '.MY.M.', '.MMYYM']),
    ChainPuzzle(2, ['.....Y', '..M..Y', 'YYMYYM']),
    ChainPuzzle(2, ['...Y..', '...Y..', '...M.Y', '.MYMYY']),
    ChainPuzzle(2, ['...Y..', '..MM..', '..YY..', 'YYMY..']),
    ChainPuzzle(2, ['...M..', '.YMM..', '.YMYMM']),
    ChainPuzzle(2, ['....Y.', '....M.', '....MY', '.YYMYY']),
    ChainPuzzle(2, ['...M..', '..MM..', 'MMYYMY']),
    // Haliç: 21–40
    ChainPuzzle(2, ['..YY..', '.BMM..', '.YBBM.']),
    ChainPuzzle(2, ['.Y....', '.BY...', '.BY...', '.MBMM.']),
    ChainPuzzle(2, ['..Y...', 'YBY...', 'MMBMB.']),
    ChainPuzzle(2, ['.BYY..', '.MBY..', '.MMB..']),
    ChainPuzzle(2, ['...B..', '...Y..', '...M..', '..MB..', '.YMYB.']),
    ChainPuzzle(2, ['...B..', '..BYB.', '.MMYYM']),
    ChainPuzzle(2, ['...B..', '...Y..', '.MMY..', '.BBMY.']),
    ChainPuzzle(2, ['.BB...', '.YY...', 'MBMMY.']),
    ChainPuzzle(2, ['..M...', '..YM..', '..YM..', 'BYBB..']),
    ChainPuzzle(2, ['....B.', '..MMB.', '.YYMYB']),
    ChainPuzzle(3, ['M.....', 'B.B...', 'B.YB..', 'MBYMYB']),
    ChainPuzzle(3, ['.Y....', '.M....', '.B....', 'BY.M..', 'YBBMBB']),
    ChainPuzzle(3, ['..M...', '..B...', '..BY..', 'MYMM..', 'YMBM..']),
    ChainPuzzle(3, ['...Y..', '.B.YB.', '.B.BY.', '.MBMMB']),
    ChainPuzzle(3, ['..M..B', '..YMBM', 'BYBBYB']),
    ChainPuzzle(3, ['..M.M.', '..MYYM', 'BMBBMY']),
    ChainPuzzle(3, ['...MB.', '...YY.', '..MBB.', '.YYMYY']),
    ChainPuzzle(3, ['.....M', '.....Y', '..YBYB', 'YYMBYM']),
    ChainPuzzle(3, ['..Y..B', '..BYBY', 'BMBMBM']),
    ChainPuzzle(3, ['....B.', '....M.', '...MM.', '..YMY.', '.MBBMY']),
    // Galata: 41–60
    ChainPuzzle(3, ['...Y..', '...Y..', '.M.B..', '.BBY..', '.YMMYY']),
    ChainPuzzle(3, ['M.....', 'B.....', 'Y.....', 'B.BY..', 'BYMMBB']),
    ChainPuzzle(3, ['...M..', '.M.M..', '.YYB..', 'YBYYBY']),
    ChainPuzzle(3, ['..B...', '.BM...', '.YY...', '.BBY..', 'BMBM..']),
    ChainPuzzle(3, ['..MBB.', '.MMYM.', 'BYYMM.']),
    ChainPuzzle(3, ['...Y..', '...Y..', '...M..', '.M.MMY', '.MBBMB']),
    ChainPuzzle(3, ['.....Y', '.....Y', '.MBYMM', '.MMBBM']),
    ChainPuzzle(3, ['..Y...', 'YMYM.M', 'YYBYBB']),
    ChainPuzzle(3, ['....M.', '....B.', '..BBMB', 'YBYYMB']),
    ChainPuzzle(3, ['.Y...M', '.BYY.M', 'BBYYMY']),
    ChainPuzzle(3, ['....B.', '....Y.', '....M.', '...BB.', '..YBMY', 'YYMYBB']),
    ChainPuzzle(3, ['....B.', '..YYM.', '..MBY.', '..BMBM', '..BBMM']),
    ChainPuzzle(3, ['.....M', '..M.BY', 'MMB.YB', 'BBYMBM']),
    ChainPuzzle(3, ['.B.M..', '.M.B..', 'MBMYY.', 'MMBBYB']),
    ChainPuzzle(3, ['..M...', '..Y...', '.YM...', 'YMMYB.', 'MYYMBB']),
    ChainPuzzle(3, ['.M....', '.Y....', '.Y..Y.', '.BB.Y.', '.MYMB.', '.MMYM.']),
    ChainPuzzle(3, ['....B.', '.Y..MB', 'MYM.BM', 'YMBBMB']),
    ChainPuzzle(3, ['....B.', '....B.', '....M.', '..M.M.', '.MY.BB', 'MBBYMY']),
    ChainPuzzle(3, ['..B...', '..B...', '..Y.BM', '.YY.MB', 'MMBMMB']),
    ChainPuzzle(3, ['..Y...', '..M...', '.YY...', '.YM...', '.MYBY.', '.BMBMM']),
    // Boğaziçi: 61–80
    ChainPuzzle(3, ['..MB..', '.BBG..', '.GMYM.', 'GBYYBB']),
    ChainPuzzle(3, ['Y.....', 'M..M..', 'G..G.M', 'M..B.M', 'MYYGBB']),
    ChainPuzzle(3, ['BYGGB.', 'BYMMG.', 'YBMBB.']),
    ChainPuzzle(3, ['...G.B', '...Y.B', '.GYGBM', 'GMMYGG']),
    ChainPuzzle(3, ['....M.', '....YM', '..YBYM', '..GMBB', '..GGMM']),
    ChainPuzzle(3, ['..G...', '..B...', '.YG...', 'GBYGG.', 'BYMMGM']),
    ChainPuzzle(3, ['.G....', '.GBY..', '.BMB..', '.GYY..', 'BMBBM.']),
    ChainPuzzle(3, ['....G.', '....Y.', '..B.B.', 'GGMGY.', 'BMMGYG']),
    ChainPuzzle(4, ['....G.', '...BY.', '...MMB', '..MGGM', '.MYMBY']),
    ChainPuzzle(4, ['..MY..', '.GGM..', 'GYMB..', 'YBYYBY']),
    ChainPuzzle(4, ['.....B', 'G..B.G', 'M..M.G', 'M.YMYY', 'GMGBGM']),
    ChainPuzzle(4, ['..B...', '..YM..', '..BB..', '..BM..', '..YYB.', '.GBBM.', '.GGBB.']),
    ChainPuzzle(4, ['.B.M..', '.BYY..', '.YGG..', '.YBY.Y', 'YGYYMM']),
    ChainPuzzle(4, ['..Y...', '..M...', '..MGM.', '..BMG.', 'M.MMB.', 'MMBYYG']),
    ChainPuzzle(4, ['...M..', '...B..', 'M..M..', 'Y..M..', 'GG.G..', 'YGBG..', 'YMBMG.']),
    ChainPuzzle(4, ['...YM.', '.GYYGY', '.GGBYG', 'YBBMGM']),
    ChainPuzzle(4, ['...G..', '.B.M..', '.Y.G..', '.YMB..', 'GGBMB.', 'BGYBG.']),
    ChainPuzzle(4, ['....M.', '.G..G.', '.Y..M.', 'GY.YM.', 'BB.YB.', 'GYYGG.']),
    ChainPuzzle(4, ['M..G.Y', 'G.BM.Y', 'M.MBGG', 'MGBGMY']),
    ChainPuzzle(4, ['.Y....', 'GB....', 'MYB...', 'BYMYBB', 'MGGBYY']),
  ];
}
