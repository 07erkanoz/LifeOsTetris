import 'sugar_game.dart';

/// The Şeker Küpler levels: eighteen chapters of ten. Every fifth level
/// opens a chest; the tenth of a chapter is its boss. Each chapter brings
/// something new: ice, chains, candy boxes, timed bombs, all of them; then
/// chocolate, pomegranates, conveyor belts, cakes, doors, and Ekşi Limon
/// himself. The second season, up the Bosphorus, brings fog, tunnels,
/// gulls, jam, lanterns and Acı Biber.
class SugarLevels {
  static const int perChapter = 10;
  static const int chapters = 18;

  /// The first chapter of the second season (0-based).
  static const int secondSeason = 12;
  static int get count => all.length;
  static int chapterOf(int level) => ((level - 1) ~/ perChapter).clamp(0, chapters - 1);
  static bool chestAt(int level) => level % 5 == 0;

  static SugarLevel of(int number) => all[(number - 1).clamp(0, all.length - 1)];

  static SugarGoal Function() _score(int n) => () => SugarGoal.score(n);
  static SugarGoal Function() _color(SugarColor c, int n) => () => SugarGoal.color(c, n);
  static SugarGoal Function() _ice(int n) => () => SugarGoal.ice(n);
  static SugarGoal Function() _box(int n) => () => SugarGoal.box(n);
  static SugarGoal Function() _choco(int n) => () => SugarGoal.choco(n);
  static SugarGoal Function() _fruit(int n) => () => SugarGoal.fruit(n);
  static SugarGoal Function() _cake(int n) => () => SugarGoal.cake(n);
  static SugarGoal Function() _door(int n) => () => SugarGoal.door(n);
  static SugarGoal Function() _limon(int n) => () => SugarGoal.limon(n);
  static SugarGoal Function() _fog(int n) => () => SugarGoal.fog(n);
  static SugarGoal Function() _gull(int n) => () => SugarGoal.gull(n);
  static SugarGoal Function() _lantern(int n) => () => SugarGoal.lantern(n);
  static SugarGoal Function() _pepper(int n) => () => SugarGoal.pepper(n);

  /// Jam over every cell of [layout] that holds sweets (all but tunnels).
  static SugarGoal Function() _jam(List<String> layout) => () => SugarGoal.jam(layout.join().split('').where((c) => c != 'X').length);

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

    // ------------------------------------------------------- 7 · Kadıköy --
    _l(61, 16, 5, _chocoPairs, [_choco(8)], [6000, 12500, 19000], hint: 'choco'),
    _l(62, 14, 5, _chocoCorners, [_choco(12)], [7000, 11000, 13500]),
    _l(63, 14, 5, _chocoBand, [_choco(6), _color(_b, 24)], [3500, 7000, 10000]),
    _l(64, 20, 5, _chocoIce, [_choco(8), _ice(16)], [6500, 15500, 20500]),
    _l(65, 16, 5, _chocoChains, [_choco(4), _color(_r, 24)], [6500, 9000, 10500]),
    _l(66, 14, 5, _chocoBoxes, [_choco(4), _box(8), _color(_y, 25)], [4500, 9000, 11000]),
    _l(67, 14, 6, _chocoFrame, [_choco(12)], [3000, 6500, 7500]),
    _l(68, 14, 5, _chocoBottom, [_choco(22)], [5500, 11000, 12000], hard: true),
    _l(69, 18, 5, _chocoMiddle, [_choco(4), _color(_g, 25)], [4000, 9000, 14000], bombEvery: 6, bombTimer: 11),
    _l(70, 18, 5, _chocoFortress, [_choco(16), _ice(12), _color(_r, 30)], [7000, 10500, 14500], boss: true),

    // ------------------------------------------------------- 8 · Ortaköy --
    _l(71, 16, 5, _fruitTwo, [_fruit(2)], [6000, 10500, 18000], hint: 'fruit'),
    _l(72, 22, 5, _fruitIce, [_fruit(3), _ice(16)], [12500, 18000, 20000]),
    _l(73, 28, 5, _fruitChains, [_fruit(3)], [12000, 23000, 38000]),
    _l(74, 32, 5, _fruitChoco, [_fruit(3), _choco(8)], [11500, 18500, 31000]),
    _l(75, 18, 5, _fruitBoxes, [_fruit(3), _box(5)], [9500, 12500, 17500]),
    _l(76, 24, 5, _fruitTwo, [_fruit(3), _color(_o, 25)], [14000, 18500, 25500]),
    _l(77, 22, 5, _fruitIceSides, [_fruit(3), _ice(12)], [11500, 18500, 22500]),
    _l(78, 28, 5, _fruitChoco, [_fruit(3), _choco(8)], [12500, 21000, 33000], hard: true),
    _l(79, 16, 5, _fruitTwo, [_fruit(3), _color(_y, 25)], [7000, 11500, 14500], bombEvery: 5, bombTimer: 10),
    _l(80, 34, 5, _fruitFortress, [_fruit(4), _box(8), _ice(8)], [18000, 25000, 34000], boss: true),

    // -------------------------------------------------- 9 · Boğaz Vapuru --
    _l(81, 12, 5, _open, [_color(_b, 36)], [7500, 11000, 12000], hint: 'belt', belts: {3: 1}),
    _l(82, 14, 5, _iceDecks, [_ice(16), _color(_g, 62)], [13500, 20500, 25000], belts: {2: 1, 5: -1}),
    _l(83, 12, 5, _open, [_color(_r, 30), _color(_g, 30)], [6500, 11500, 12500], belts: {3: 1, 4: -1}),
    _l(84, 14, 5, _fruitTwo, [_fruit(3)], [7500, 15000, 21500], belts: {6: 1}),
    _l(85, 14, 5, _chocoMiddle, [_choco(4), _color(_o, 43)], [8000, 14000, 15000], belts: {1: -1, 6: 1}),
    _l(86, 14, 5, _chainDecks, [_color(_o, 43)], [7500, 13500, 14000], belts: {3: 1}),
    _l(87, 12, 6, _open, [_color(_y, 22), _color(_b, 22)], [4000, 9000, 9500], belts: {2: 1, 4: -1, 6: 1}),
    _l(88, 14, 5, _boxDecks, [_box(8), _color(_r, 35)], [9500, 14000, 14500], hard: true, belts: {3: 1, 4: 1}),
    _l(89, 18, 5, _open, [_color(_g, 38)], [6500, 12500, 15000], belts: {7: -1}, bombEvery: 5, bombTimer: 10),
    _l(90, 14, 5, _iceDecksChoco, [_ice(16), _choco(4), _color(_b, 43)], [10000, 17500, 18500], boss: true, belts: {2: 1, 5: -1}),

    // ------------------------------------------------------ 10 · İstiklal --
    _l(91, 14, 5, _cakeOne, [_cake(1)], [15000, 18500, 23500], hint: 'cake'),
    _l(92, 16, 5, _cakeTwo, [_cake(2), _color(_r, 36)], [6500, 11500, 15500]),
    _l(93, 14, 5, _cakeIce, [_cake(2), _ice(24)], [6000, 13500, 16000]),
    _l(94, 14, 5, _cakeFour, [_cake(4), _color(_y, 25)], [5500, 9000, 11000]),
    _l(95, 14, 5, _cakeFruit, [_cake(1), _fruit(2)], [4500, 10500, 17500]),
    _l(96, 16, 5, _cakeChoco, [_cake(2), _choco(5), _color(_g, 30)], [5500, 10500, 15500]),
    _l(97, 14, 5, _cakeTwo, [_cake(2), _color(_o, 36)], [7500, 12000, 13000], belts: {6: 1}),
    _l(98, 14, 5, _cakeBoxes, [_cake(3), _box(4)], [8500, 14000, 20500], hard: true),
    _l(99, 14, 5, _cakeTwo, [_cake(2), _color(_b, 30)], [7500, 10500, 13500], bombEvery: 5, bombTimer: 10),
    _l(100, 16, 5, _cakeFortress, [_cake(4), _ice(8), _color(_o, 35)], [9500, 14000, 16500], boss: true),

    // --------------------------------------------------------- 11 · Balat --
    _l(101, 16, 5, _doorsTwo, [_door(2)], [7000, 14000, 18500], hint: 'door'),
    _l(102, 20, 5, _doorsRow, [_door(4)], [7000, 10500, 18500]),
    _l(103, 22, 5, _doorsIce, [_door(4), _ice(8)], [8000, 16500, 21500]),
    _l(104, 28, 5, _doorsChains, [_door(4)], [9500, 17500, 20000]),
    _l(105, 18, 5, _doorsCake, [_door(4), _cake(1)], [8000, 12000, 19500]),
    _l(106, 22, 5, _doorsFruit, [_door(2), _fruit(2)], [9500, 20500, 29500]),
    _l(107, 14, 5, _doorsRow, [_door(4)], [6500, 13500, 15500], belts: {6: -1}),
    _l(108, 20, 5, _doorsChoco, [_door(4), _choco(6)], [10000, 17500, 20500], hard: true),
    _l(109, 14, 5, _doorsTwo, [_door(2), _color(_y, 25)], [6500, 10000, 10500], bombEvery: 5, bombTimer: 10),
    _l(110, 28, 5, _doorsFortress, [_door(6), _box(4)], [12500, 19000, 24500], boss: true),

    // ------------------------------------------------ 12 · Çamlıca Tepesi --
    _l(111, 24, 5, _fruitChoco, [_fruit(2), _choco(8)], [8000, 23000, 24000]),
    _l(112, 14, 5, _doorsRow, [_door(4), _color(_r, 43)], [9000, 16000, 17500], belts: {2: 1, 5: -1}),
    _l(113, 14, 5, _cakeChoco, [_cake(2), _choco(5), _color(_y, 30)], [6000, 10000, 12500]),
    _l(114, 14, 5, _fruitTwo, [_fruit(3)], [9500, 19000, 21500], belts: {3: -1, 6: 1}),
    _l(115, 16, 5, _doorsCake, [_door(4), _cake(1), _color(_r, 24)], [6000, 9000, 13500]),
    _l(116, 14, 5, _chocoChains, [_choco(4), _color(_b, 24)], [4500, 11500, 12000], bombEvery: 5, bombTimer: 10),
    _l(117, 14, 5, _cakeTwo, [_cake(2), _color(_g, 36)], [8000, 15000, 17000], belts: {1: 1, 6: -1}),
    _l(118, 26, 5, _everything, [_cake(1), _door(2), _choco(4), _fruit(1)], [10000, 26500, 43500], hard: true),
    _l(119, 22, 5, _doorsFruit, [_door(2), _fruit(3)], [8000, 15500, 22500]),
    _l(120, 34, 5, _open, [_limon(420)], [15000, 20000, 32500], boss: true, hint: 'limon', limonEvery: 4),
    // ======================================== the second season: Boğaz Turu

    // ------------------------------------------------------ 13 · Salacak --
    _l(121, 14, 5, _fogMiddle, [_fog(8)], [12000, 15500, 20000], hint: 'fog'),
    _l(122, 16, 5, _fogBottom, [_fog(16)], [5000, 12000, 19000]),
    _l(123, 16, 5, _fogCross, [_fog(14), _color(_r, 30)], [5500, 10000, 13500]),
    _l(124, 22, 5, _fogIce, [_fog(8), _ice(16)], [8000, 14500, 17500]),
    _l(125, 14, 5, _fogChains, [_fog(8)], [11500, 15000, 18500]),
    _l(126, 14, 5, _fogBoxes, [_fog(8), _box(4)], [9000, 15000, 15500]),
    _l(127, 16, 5, _fogFrame, [_fog(22)], [7500, 10500, 11500]),
    _l(128, 20, 5, _fogMiddle, [_fog(8), _color(_b, 40)], [7000, 17500, 21000], hard: true),
    _l(129, 20, 5, _fogBottom, [_fog(16)], [9500, 16500, 20500], bombEvery: 5, bombTimer: 10),
    _l(130, 14, 5, _fogFortress, [_fog(18), _ice(12)], [5000, 10000, 12500], boss: true),

    // -------------------------------------------------- 14 · Haydarpaşa --
    _l(131, 20, 5, _tunnelMiddle, [_ice(16)], [5000, 15500, 19500], hint: 'tunnel'),
    _l(132, 18, 5, _tunnelSides, [_color(_y, 30), _color(_g, 30)], [6000, 9500, 10000]),
    _l(133, 14, 5, _tunnelFog, [_fog(8)], [5500, 12500, 15000]),
    _l(134, 24, 5, _tunnelTwo, [_ice(12), _color(_r, 25)], [6500, 12500, 18500]),
    _l(135, 14, 5, _tunnelBoxes, [_box(8)], [12000, 17000, 18000]),
    _l(136, 22, 5, _tunnelChains, [_color(_b, 35)], [6500, 10500, 14000]),
    _l(137, 20, 5, _tunnelFruit, [_fruit(3)], [8500, 12000, 19500]),
    _l(138, 18, 5, _tunnelThick, [_ice(16)], [8000, 11000, 14000], hard: true),
    _l(139, 22, 5, _tunnelSides, [_color(_o, 35)], [6500, 9500, 16500], bombEvery: 5, bombTimer: 10),
    _l(140, 22, 5, _tunnelMaze, [_fog(8), _ice(16), _box(2)], [8500, 11500, 15500], boss: true),

    // ------------------------------------------------------ 15 · Karaköy --
    _l(141, 14, 5, _gullsTwo, [_gull(8)], [5000, 8000, 9000], hint: 'gull', gullEvery: 3),
    _l(142, 16, 5, _iceBottom, [_gull(8), _ice(16)], [7500, 10000, 13500], gullEvery: 3),
    _l(143, 14, 5, _gullsFog, [_gull(6), _fog(8)], [5000, 9000, 11500], gullEvery: 4),
    _l(144, 18, 5, _boxRing, [_gull(8), _box(12)], [6500, 14000, 16500], gullEvery: 4),
    _l(145, 16, 5, _gullsTunnel, [_gull(10)], [3000, 6000, 7500], gullEvery: 3),
    _l(146, 18, 5, _open, [_gull(10), _color(_r, 30)], [5500, 9000, 10500], gullEvery: 3, gullCount: 3),
    _l(147, 20, 5, _chainBand, [_gull(10)], [5500, 8500, 13000], gullEvery: 3),
    _l(148, 14, 5, _gullsFog, [_gull(12), _fog(8)], [4000, 10000, 13000], hard: true, gullEvery: 3, gullCount: 3),
    _l(149, 14, 5, _gullsTwo, [_gull(10)], [4000, 6500, 9000], gullEvery: 3, bombEvery: 5, bombTimer: 10),
    _l(150, 16, 5, _gullsFortress, [_gull(14), _ice(16)], [8000, 12500, 15500], boss: true, gullEvery: 3, gullCount: 3),

    // ---------------------------------------------------- 16 · Kuzguncuk --
    _l(151, 28, 5, _jamMiddle, [_jam(_jamMiddle)], [8000, 11000, 13500], hint: 'jam'),
    _l(152, 28, 5, _jamCorners, [_jam(_jamCorners)], [8500, 14500, 23000]),
    _l(153, 32, 5, _jamTunnel, [_jam(_jamTunnel)], [6500, 11500, 23500]),
    _l(154, 34, 5, _jamFog, [_jam(_jamFog), _fog(8)], [8000, 13500, 23000]),
    _l(155, 36, 5, _jamChains, [_jam(_jamChains)], [11000, 17500, 35500]),
    _l(156, 28, 5, _jamBoxes, [_jam(_jamBoxes), _box(8)], [10000, 15500, 16500]),
    _l(157, 38, 5, _jamIce, [_jam(_jamIce), _ice(16)], [11000, 23500, 37000]),
    _l(158, 30, 5, _jamCorners, [_jam(_jamCorners)], [8500, 18500, 21500], hard: true, gullEvery: 4),
    _l(159, 38, 5, _jamMiddle, [_jam(_jamMiddle)], [14500, 24000, 28500], bombEvery: 5, bombTimer: 10),
    _l(160, 42, 5, _jamFortress, [_jam(_jamFortress), _box(8)], [11500, 16500, 46000], boss: true),

    // --------------------------------------------------- 17 · Dolmabahçe --
    _l(161, 14, 5, _lanternsTwo, [_lantern(2)], [6000, 10500, 15500], hint: 'lantern'),
    _l(162, 14, 5, _lanternsFour, [_lantern(4)], [4500, 7000, 9500]),
    _l(163, 16, 5, _lanternsIce, [_lantern(4), _ice(8)], [6000, 7500, 10500]),
    _l(164, 14, 5, _lanternsFog, [_lantern(2), _fog(8)], [6000, 11000, 14500]),
    _l(165, 18, 5, _lanternsTunnel, [_lantern(4)], [5000, 9500, 15500]),
    _l(166, 30, 5, _lanternsJam, [_lantern(2), _jam(_lanternsJam)], [11000, 19000, 22000]),
    _l(167, 16, 5, _lanternsFour, [_lantern(4), _gull(6)], [4500, 7000, 12500], gullEvery: 4),
    _l(168, 14, 5, _lanternsSix, [_lantern(6)], [5500, 9500, 12000], hard: true),
    _l(169, 16, 5, _lanternsFour, [_lantern(4)], [4500, 7500, 13500], bombEvery: 5, bombTimer: 10),
    _l(170, 18, 5, _lanternsFortress, [_lantern(6), _box(4), _ice(8)], [9000, 13500, 15500], boss: true),

    // ---------------------------------------------- 18 · Anadolu Kavağı --
    _l(171, 26, 5, _open, [_pepper(315)], [8500, 14500, 24000], hint: 'pepper', pepperEvery: 6, bombTimer: 14),
    _l(172, 26, 5, _fogMiddle, [_pepper(315), _fog(8)], [10000, 16000, 21500], pepperEvery: 6, bombTimer: 12),
    _l(173, 28, 5, _tunnelSides, [_pepper(264)], [7500, 18000, 26000], pepperEvery: 6, bombTimer: 12),
    _l(174, 24, 5, _gullsTwo, [_pepper(330), _gull(6)], [13000, 19000, 26000], pepperEvery: 6, bombTimer: 12, gullEvery: 4),
    _l(175, 26, 5, _lanternsTwo, [_pepper(345), _lantern(2)], [13000, 34500, 38500], pepperEvery: 6, bombTimer: 12),
    _l(176, 26, 5, _jamMiddle, [_pepper(288), _jam(_jamMiddle)], [9000, 16000, 24000], pepperEvery: 6, bombTimer: 12),
    _l(177, 30, 5, _fogIce, [_pepper(288), _ice(16)], [11500, 20000, 27000], pepperEvery: 6, bombTimer: 12),
    _l(178, 30, 5, _tunnelMaze, [_pepper(300), _box(2)], [12500, 18500, 23500], hard: true, pepperEvery: 6, bombTimer: 12),
    _l(179, 28, 5, _lanternsFour, [_pepper(390), _lantern(4)], [13500, 18500, 21500], pepperEvery: 6, bombTimer: 12),
    _l(180, 40, 5, _open, [_pepper(570)], [17000, 24500, 36000], boss: true, pepperEvery: 6, bombTimer: 12),
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
    Map<int, int> belts = const {},
    int limonEvery = 0,
    int gullEvery = 0,
    int gullCount = 2,
    int pepperEvery = 0,
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
      luck: const [18, 14, 12, 10, 9, 8, 9, 9, 8, 8, 8, 8, 10, 9, 9, 8, 8, 8][ch],
      gifts: n <= 5 ? 2 : (ch <= 1 || boss || hint != null ? 1 : 0),
      rush: const [70, 80, 90, 95, 100, 105, 100, 100, 105, 105, 105, 110, 100, 105, 105, 105, 110, 110][ch],
      calm: const [40, 48, 52, 55, 58, 58, 56, 56, 58, 58, 58, 58, 55, 56, 56, 58, 58, 58][ch],
      belts: belts,
      limonEvery: limonEvery,
      gullEvery: gullEvery,
      gullCount: gullCount,
      pepperEvery: pepperEvery,
    );
  }

  // '.' plain · 'i' ice · 'I' thick ice · 'c' chained · 'C' chained on ice
  // 'K' box (two layers) · 'k' box (one layer) · 'T' timed bomb
  // 'H' chocolate · 'N' pomegranate · 'W' cake (its other cells 'w')
  // '1'–'5' a door in red, orange, yellow, green, blue

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

  // Kadıköy: chocolate.
  static const _chocoPairs = ['........', '........', '........', '........', '........', '.HH..HH.', '.HH..HH.', '........'];
  static const _chocoMiddle = ['........', '........', '........', '...HH...', '...HH...', '........', '........', '........'];
  static const _chocoCorners = ['........', '........', '........', '........', '........', '........', 'HHH..HHH', 'HHH..HHH'];
  static const _chocoBand = ['........', '........', '........', '........', 'HHH..HHH', '........', '........', '........'];
  static const _chocoIce = ['iiiiiiii', '........', '..HHHH..', '........', '........', '..HHHH..', '........', 'iiiiiiii'];
  static const _chocoChains = ['........', '.cc..cc.', '........', '...HH...', '...HH...', '........', '.cc..cc.', '........'];
  static const _chocoBoxes = ['........', '........', '.kk..kk.', '...HH...', '...HH...', '.kk..kk.', '........', '........'];
  static const _chocoFrame = ['........', 'HH....HH', 'H......H', '........', '........', 'H......H', 'HH....HH', '........'];
  static const _chocoBottom = ['........', '........', '........', '........', '........', 'HHH..HHH', 'HHHHHHHH', 'HHHHHHHH'];
  static const _chocoFortress = ['........', 'HHH..HHH', 'H..ii..H', '..iiii..', '..iiii..', 'H..ii..H', 'HHH..HHH', '........'];

  // Ortaköy: pomegranates, from the top row.
  static const _fruitTwo = ['..N..N..', '........', '........', '........', '........', '........', '........', '........'];
  static const _fruitIce = ['...NN...', '........', '........', '........', 'iiiiiiii', 'iiiiiiii', '........', '........'];
  static const _fruitChains = ['..N..N..', '........', '.c.cc.c.', '........', '........', '.c.cc.c.', '........', '........'];
  static const _fruitChoco = ['.N....N.', '........', '........', 'HH....HH', 'HH....HH', '........', '........', '........'];
  static const _fruitBoxes = ['..N..N..', '........', '........', 'k.kk.kk.', '........', '........', '........', '........'];
  static const _fruitIceSides = ['...NN...', '........', 'ii....ii', 'ii....ii', 'ii....ii', '........', '........', '........'];
  static const _fruitFortress = ['.N....N.', '........', 'k.iiii.k', 'k.i..i.k', 'k.i..i.k', 'k......k', '........', '........'];

  // Boğaz Vapuru: decks under the belts.
  static const _iceDecks = ['........', '........', 'iiiiiiii', '........', '........', 'iiiiiiii', '........', '........'];
  static const _chainDecks = ['........', '........', '.c....c.', '........', '........', '.c....c.', '........', '........'];
  static const _boxDecks = ['........', 'kk....kk', '........', '........', '........', '........', 'kk....kk', '........'];
  static const _iceDecksChoco = ['........', '...HH...', 'iiiiiiii', '........', '........', 'iiiiiiii', '...HH...', '........'];

  // İstiklal: cakes.
  static const _cakeOne = ['........', '........', '........', '...Ww...', '...ww...', '........', '........', '........'];
  static const _cakeTwo = ['........', '........', '........', '.Ww..Ww.', '.ww..ww.', '........', '........', '........'];
  static const _cakeIce = ['........', '........', 'iiiiiiii', 'iWwiiWwi', 'iwwiiwwi', 'iiiiiiii', '........', '........'];
  static const _cakeFour = ['........', '.Ww..Ww.', '.ww..ww.', '........', '........', '.Ww..Ww.', '.ww..ww.', '........'];
  static const _cakeFruit = ['...N....', '........', '........', '...Ww...', '...ww...', '........', '........', '........'];
  static const _cakeChoco = ['........', '........', 'H......H', 'H.Ww.Ww.', '..ww.ww.', 'H......H', '........', '........'];
  static const _cakeBoxes = ['........', 'k.Ww...k', '..ww....', '....Ww..', '....ww..', '.Ww.....', 'kww....k', '........'];
  static const _cakeFortress = ['........', '.Ww..Ww.', '.ww..ww.', '..iiii..', '..iiii..', '.Ww..Ww.', '.ww..ww.', '........'];

  // Balat: doors in red (1), orange (2), yellow (3), green (4), blue (5).
  static const _doorsTwo = ['........', '........', '........', '........', '..1..5..', '........', '........', '........'];
  static const _doorsRow = ['........', '........', '........', '.1.2.3.4', '........', '........', '........', '........'];
  static const _doorsIce = ['........', '........', '.1....3.', '..iiii..', '..iiii..', '.4....5.', '........', '........'];
  static const _doorsChains = ['........', '..cccc..', '.2....4.', '........', '........', '.3....1.', '..cccc..', '........'];
  static const _doorsCake = ['........', '........', '..1..2..', '...Ww...', '...ww...', '..3..5..', '........', '........'];
  static const _doorsFruit = ['..N..N..', '........', '........', '1......5', '........', '........', '........', '........'];
  static const _doorsChoco = ['........', '..H..H..', '.1....2.', '...HH...', '........', '.3....4.', '..H..H..', '........'];
  static const _doorsFortress = ['........', '.1.kk.2.', '........', '3......4', '........', '........', '.5.kk.1.', '........'];

  // Çamlıca: a bit of everything.
  static const _everything = ['...N....', '.1....2.', '........', '...Ww...', '...ww...', '........', 'HH....HH', '........'];

  // The second season: 'F' fog · 'X' tunnel · 'G' gull · 'J' jam · 'Q' lantern.

  // Salacak: morning fog.
  static const _fogMiddle = ['........', '........', '..FFFF..', '..FFFF..', '........', '........', '........', '........'];
  static const _fogBottom = ['........', '........', '........', '........', '........', '........', 'FFFFFFFF', 'FFFFFFFF'];
  static const _fogCross = ['........', '...FF...', '...FF...', '.FFFFFF.', '...FF...', '...FF...', '........', '........'];
  static const _fogIce = ['........', '........', '..FFFF..', '..FFFF..', '........', '........', 'iiiiiiii', 'iiiiiiii'];
  static const _fogChains = ['........', '.c....c.', '..FFFF..', '..FFFF..', '........', '.c....c.', '........', '........'];
  static const _fogBoxes = ['........', '........', '.k.FF.k.', '.k.FF.k.', '...FF...', '...FF...', '........', '........'];
  static const _fogFrame = ['FFF..FFF', 'F......F', 'F......F', '........', '........', 'F......F', 'F......F', 'FFFFFFFF'];
  static const _fogFortress = ['........', '.FFFFFF.', '.FiiiiF.', '.Fi..iF.', '.Fi..iF.', '.FiiiiF.', '.FF..FF.', '........'];

  // Haydarpaşa: tunnels the sweets fall through.
  static const _tunnelMiddle = ['........', '........', '........', '..XXXX..', '........', '........', 'iiiiiiii', 'iiiiiiii'];
  static const _tunnelSides = ['........', '........', 'XX....XX', 'XX....XX', '........', '........', '........', '........'];
  static const _tunnelFog = ['........', '........', '...XX...', '...XX...', '........', '.FF..FF.', '.FF..FF.', '........'];
  static const _tunnelTwo = ['........', '.XX.....', '........', '.....XX.', '........', '........', 'iiiiiiii', 'iiii....'];
  static const _tunnelBoxes = ['........', '........', '..XXXX..', '........', '.kk..kk.', '.kk..kk.', '........', '........'];
  static const _tunnelChains = ['........', '........', 'X......X', 'X.cccc.X', 'X......X', '........', '........', '........'];
  static const _tunnelFruit = ['..N..N..', '........', '.XX..XX.', '........', '........', '........', '........', '........'];
  static const _tunnelThick = ['........', '........', '...XX...', '...XX...', '........', 'IIIIIIII', 'IIIIIIII', '........'];
  static const _tunnelMaze = ['........', 'XX....XX', '...kk...', '.FF..FF.', '.FF..FF.', '...XX...', 'iiiiiiii', 'iiiiiiii'];

  // Karaköy: gulls by the pier.
  static const _gullsTwo = ['........', '........', '..G..G..', '........', '........', '........', '........', '........'];
  static const _gullsFog = ['........', '..G..G..', '........', '........', '........', '.FF..FF.', '.FF..FF.', '........'];
  static const _gullsTunnel = ['........', '.G....G.', '........', '..XXXX..', '........', '........', '........', '........'];
  static const _gullsFortress = ['........', '.G....G.', '..iiii..', '.ii..ii.', '.ii..ii.', '..iiii..', '.G....G.', '........'];

  // Kuzguncuk: jam to spread over the board.
  static const _jamMiddle = ['........', '........', '........', '...JJ...', '...JJ...', '........', '........', '........'];
  static const _jamCorners = ['J......J', '........', '........', '........', '........', '........', '........', 'J......J'];
  static const _jamTunnel = ['........', '........', '..XXXX..', '........', '........', '...JJ...', '........', '........'];
  static const _jamFog = ['........', '........', '..FFFF..', '..FFFF..', '........', '........', '...JJ...', '........'];
  static const _jamChains = ['........', '.cc..cc.', '........', '...JJ...', '........', '........', '.cc..cc.', '........'];
  static const _jamBoxes = ['........', '........', '.kk..kk.', '...JJ...', '........', '.kk..kk.', '........', '........'];
  static const _jamIce = ['........', '........', '...JJ...', '........', '........', 'iiiiiiii', 'iiiiiiii', '........'];
  static const _jamFortress = ['J......J', '.kk..kk.', '........', '..XXXX..', '........', '........', '.kk..kk.', 'J......J'];

  // Dolmabahçe: lanterns to light.
  static const _lanternsTwo = ['........', '........', '........', '..Q..Q..', '........', '........', '........', '........'];
  static const _lanternsFour = ['........', '........', '.Q....Q.', '........', '........', '.Q....Q.', '........', '........'];
  static const _lanternsIce = ['........', '........', '.Q....Q.', '..iiii..', '..iiii..', '.Q....Q.', '........', '........'];
  static const _lanternsFog = ['........', '........', '..Q..Q..', '........', '........', '.FF..FF.', '.FF..FF.', '........'];
  static const _lanternsTunnel = ['........', '........', '.Q....Q.', '...XX...', '........', '.Q....Q.', '........', '........'];
  static const _lanternsJam = ['........', '........', '..Q..Q..', '........', '...JJ...', '........', '........', '........'];
  static const _lanternsSix = ['........', '.Q....Q.', '........', '...QQ...', '........', '........', '.Q....Q.', '........'];
  static const _lanternsFortress = ['........', '.Q....Q.', '..iiii..', '.k.QQ.k.', '.k....k.', '..iiii..', '.Q....Q.', '........'];
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
