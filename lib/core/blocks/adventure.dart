import 'dart:math';

import 'block_puzzle.dart';
import 'level_generator.dart';

/// "Macera": ten chapters of ten fixed levels. Every level solved uncovers
/// one tile of the chapter's picture; the last one completes it. From the
/// third chapter on, some boards start with bombs.
class Adventure {
  static const int chapters = 10;
  static const int perChapter = 10;
  static const int count = chapters * perChapter;

  /// The picture of each chapter: 10×10 cells, top row first, drawn with
  /// the game's own blocks ('.' empty, I O T S Z J L coloured, M grey).
  static const List<List<String>> pictures = [
    // Kalp
    [
      '.ZZ....ZZ.',
      'ZZZZ..ZZZZ',
      'ZOZZZZZZZZ',
      'ZZZZZZZZZZ',
      'ZZZZZZZZZZ',
      '.ZZZZZZZZ.',
      '..ZZZZZZ..',
      '...ZZZZ...',
      '....ZZ....',
      '..........',
    ],
    // Mantar
    [
      '...ZZZZ...',
      '.ZZOZZZZZ.',
      'ZZOOZZZOZZ',
      'ZZZZZZOOOZ',
      'ZOZZZZZOZZ',
      '.MMMMMMMM.',
      '..MMMMMM..',
      '..MMJMMM..',
      '..MMMMMM..',
      '...MMMM...',
    ],
    // Kedi
    [
      'L........L',
      'LL......LL',
      'LLL....LLL',
      'LLLLLLLLLL',
      'LSSLLLLSSL',
      'LSJLLLLSJL',
      'LLLLZZLLLL',
      'LLLMLLMLLL',
      '.LLLMMLLL.',
      '..LLLLLL..',
    ],
    // Ev
    [
      '....ZZ....',
      '...ZZZZ...',
      '..ZZZZZZ..',
      '.ZZZZZZZZ.',
      'ZZZZZZZZZZ',
      '.OOOOOOOO.',
      '.OIIOOLLO.',
      '.OIIOOLLO.',
      '.OOOOOLLO.',
      'SSSSSSSSSS',
    ],
    // Ağaç
    [
      '....SS....',
      '...SSSS...',
      '..SSSZSS..',
      '.SSSSSSSS.',
      'SSZSSSSSSS',
      '.SSSSSZSS.',
      '..SSSSSS..',
      '....LL....',
      '....LL....',
      '..SSLLSS..',
    ],
    // Balık
    [
      '..........',
      '...III....',
      '..IIIII..J',
      '.IIIIIIIJJ',
      'IJIIIIIJJJ',
      'IIIIIIIJJJ',
      '.IIIIIIIJJ',
      '..IIIII..J',
      '...III....',
      '..........',
    ],
    // Roket
    [
      '....ZZ....',
      '...MMMM...',
      '...MIIM...',
      '...MIIM...',
      '...MMMM...',
      '..ZMMMMZ..',
      '.ZZMMMMZZ.',
      '.Z.MMMM.Z.',
      '....OO....',
      '...OLLO...',
    ],
    // Çiçek
    [
      '...TTTT...',
      '..TTTTTT..',
      '.TTOOOOTT.',
      '.TTOOOOTT.',
      '..TTTTTT..',
      '...TTTT...',
      '....SS....',
      '.SS.SS....',
      '..SSSS.SS.',
      '....SSSS..',
    ],
    // Güneş
    [
      'O...OO...O',
      '.O..OO..O.',
      '...OOOO...',
      '..OLLLLO..',
      'OOOLLLLOOO',
      'OOOLLLLOOO',
      '..OLLLLO..',
      '...OOOO...',
      '.O..OO..O.',
      'O...OO...O',
    ],
    // Taç
    [
      '..........',
      'O...OO...O',
      'OO..OO..OO',
      'OOO.OO.OOO',
      'OOOOOOOOOO',
      'OZOOTTOOZO',
      'OOOOOOOOOO',
      'LLLLLLLLLL',
      '..........',
      '..........',
    ],
  ];

  static const int pictureSize = 10;

  /// A picture is cut into ten tiles of 5×2 cells (two columns, five rows),
  /// uncovered in this order (shifted per chapter so each fills differently).
  static const List<int> _revealOrder = [5, 2, 8, 0, 7, 3, 9, 1, 6, 4];

  static int chapterOf(int level) => (level - 1) ~/ perChapter + 1;

  /// 0..9: position of [level] inside its chapter.
  static int stepOf(int level) => (level - 1) % perChapter;

  static int firstOf(int chapter) => (chapter - 1) * perChapter + 1;

  /// Tile (0..9) that solving step [step] of [chapter] uncovers.
  static int tileFor(int chapter, int step) => _revealOrder[(step + chapter * 3) % perChapter];

  /// Top-left cell of [tile] inside the picture.
  static (int x, int y) tileOrigin(int tile) => ((tile % 2) * 5, (tile ~/ 2) * 2);

  /// Difficulty of level [n]: gentler than the 100 levels, with bombs from
  /// the third chapter on.
  static LevelSpec specFor(int n) {
    final k = (n.clamp(1, count) - 1) / (count - 1);
    final chapter = chapterOf(n);
    final bombs = chapter < 3 ? 0 : (chapter < 6 ? (n.isEven ? 1 : 0) : (chapter < 9 ? 1 : 2));
    return (
      gems: 2 + (k * 7).round(),
      fill: 0.22 + 0.2 * k,
      slack: max(3, (9 - k * 5).round()),
      awkward: 0.05 + 0.45 * k,
      bombs: bombs,
      fuse: chapter < 8 ? 9 : 8,
    );
  }

  /// Level [n] (1..[count]): the same board and pieces every time.
  static BlockLevel level(int n) {
    final number = n.clamp(1, count);
    return BlockLevels.generate(number, random: Random(70000 + number), spec: specFor(number));
  }
}
