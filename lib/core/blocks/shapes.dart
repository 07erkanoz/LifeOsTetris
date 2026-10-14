import '../tetromino.dart';

/// A piece of "Bulmaca Küpler": a fixed shape that is dragged onto the
/// board as it is (pieces never rotate in this mode).
class BlockShape {
  const BlockShape(this.id, this.cells, this.color, this.weight, {this.tier = 0});

  /// Builds a shape from rows of '#' and '.' characters.
  factory BlockShape.parse(String id, List<String> rows, PieceType color, int weight, {int tier = 0}) => BlockShape(
    id,
    [
      for (var y = 0; y < rows.length; y++)
        for (var x = 0; x < rows[y].length; x++)
          if (rows[y][x] == '#') Cell(x, y),
    ],
    color,
    weight,
    tier: tier,
  );

  final String id;

  /// Cells relative to the top-left corner of the shape's bounding box.
  final List<Cell> cells;

  /// Block colour (one of the tetromino colours).
  final PieceType color;

  /// How often the shape is dealt, relative to the others.
  final int weight;

  /// 0: easy, 1: normal, 2: awkward. Later levels deal more awkward shapes.
  final int tier;

  int get width => cells.fold(0, (w, c) => c.x + 1 > w ? c.x + 1 : w);
  int get height => cells.fold(0, (h, c) => c.y + 1 > h ? c.y + 1 : h);
  int get size => cells.length;

  @override
  String toString() => 'BlockShape($id)';
}

BlockShape _s(String id, List<String> rows, PieceType color, int weight, {int tier = 0}) =>
    BlockShape.parse(id, rows, color, weight, tier: tier);

/// Every shape of the mode: the familiar block-puzzle set.
final List<BlockShape> blockShapes = [
  _s('dot', ['#'], PieceType.t, 2),
  _s('i2h', ['##'], PieceType.s, 4),
  _s('i2v', ['#', '#'], PieceType.s, 4),
  _s('i3h', ['###'], PieceType.j, 4),
  _s('i3v', ['#', '#', '#'], PieceType.j, 4),
  _s('i4h', ['####'], PieceType.i, 3, tier: 1),
  _s('i4v', ['#', '#', '#', '#'], PieceType.i, 3, tier: 1),
  _s('i5h', ['#####'], PieceType.i, 2, tier: 2),
  _s('i5v', ['#', '#', '#', '#', '#'], PieceType.i, 2, tier: 2),
  _s('o2', ['##', '##'], PieceType.o, 6),
  _s('o3', ['###', '###', '###'], PieceType.o, 2, tier: 2),
  _s('r23', ['###', '###'], PieceType.z, 2, tier: 1),
  _s('r32', ['##', '##', '##'], PieceType.z, 2, tier: 1),
  _s('c1', ['##', '#.'], PieceType.l, 2),
  _s('c2', ['##', '.#'], PieceType.l, 2),
  _s('c3', ['#.', '##'], PieceType.l, 2),
  _s('c4', ['.#', '##'], PieceType.l, 2),
  _s('l1', ['#.', '#.', '##'], PieceType.l, 2, tier: 1),
  _s('l2', ['###', '#..'], PieceType.l, 2, tier: 1),
  _s('l3', ['##', '.#', '.#'], PieceType.l, 2, tier: 1),
  _s('l4', ['..#', '###'], PieceType.l, 2, tier: 1),
  _s('j1', ['.#', '.#', '##'], PieceType.j, 2, tier: 1),
  _s('j2', ['#..', '###'], PieceType.j, 2, tier: 1),
  _s('j3', ['##', '#.', '#.'], PieceType.j, 2, tier: 1),
  _s('j4', ['###', '..#'], PieceType.j, 2, tier: 1),
  _s('t1', ['###', '.#.'], PieceType.t, 2, tier: 1),
  _s('t2', ['.#.', '###'], PieceType.t, 2, tier: 1),
  _s('t3', ['#.', '##', '#.'], PieceType.t, 2, tier: 1),
  _s('t4', ['.#', '##', '.#'], PieceType.t, 2, tier: 1),
  _s('s1', ['.##', '##.'], PieceType.s, 2, tier: 2),
  _s('s2', ['#.', '##', '.#'], PieceType.s, 2, tier: 2),
  _s('z1', ['##.', '.##'], PieceType.z, 2, tier: 2),
  _s('z2', ['.#', '##', '#.'], PieceType.z, 2, tier: 2),
  _s('b1', ['###', '#..', '#..'], PieceType.i, 1, tier: 2),
  _s('b2', ['###', '..#', '..#'], PieceType.i, 1, tier: 2),
  _s('b3', ['#..', '#..', '###'], PieceType.i, 1, tier: 2),
  _s('b4', ['..#', '..#', '###'], PieceType.i, 1, tier: 2),
];

BlockShape shapeById(String id) => blockShapes.firstWhere((s) => s.id == id);
