/// Tetromino definitions following the Super Rotation System (SRS).
///
/// Coordinates use screen orientation: x grows to the right, y grows
/// downward. Each piece lives in an n×n bounding box (n = 4 for I, 3 for
/// J/L/S/T/Z, and O uses a 4×3 box so it spawns in the middle columns).
library;

enum PieceType { i, o, t, s, z, j, l }

/// A cell offset inside a grid.
class Cell {
  const Cell(this.x, this.y);

  final int x;
  final int y;

  Cell operator +(Cell other) => Cell(x + other.x, y + other.y);

  @override
  bool operator ==(Object other) => other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

/// Rotation states in SRS order: spawn, right (CW), 180, left (CCW).
enum Rotation {
  spawn,
  right,
  flip,
  left;

  Rotation get cw => Rotation.values[(index + 1) % 4];
  Rotation get ccw => Rotation.values[(index + 3) % 4];
}

const Map<PieceType, List<Cell>> _spawnCells = {
  PieceType.i: [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(3, 1)],
  PieceType.o: [Cell(1, 0), Cell(2, 0), Cell(1, 1), Cell(2, 1)],
  PieceType.t: [Cell(1, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
  PieceType.s: [Cell(1, 0), Cell(2, 0), Cell(0, 1), Cell(1, 1)],
  PieceType.z: [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(2, 1)],
  PieceType.j: [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
  PieceType.l: [Cell(2, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
};

int boxSize(PieceType type) => switch (type) {
  PieceType.i => 4,
  PieceType.o => 4,
  _ => 3,
};

final Map<PieceType, List<List<Cell>>> _rotations = {for (final type in PieceType.values) type: _buildRotations(type)};

List<List<Cell>> _buildRotations(PieceType type) {
  final states = <List<Cell>>[_spawnCells[type]!];
  if (type == PieceType.o) {
    return List.filled(4, states.first);
  }
  final n = boxSize(type);
  for (var r = 1; r < 4; r++) {
    // Clockwise rotation inside the bounding box: (x, y) -> (n-1-y, x).
    states.add([for (final c in states.last) Cell(n - 1 - c.y, c.x)]);
  }
  return states;
}

/// Cells of [type] in [rotation], relative to the bounding box origin.
List<Cell> shapeOf(PieceType type, Rotation rotation) => _rotations[type]![rotation.index];

// SRS wall kick tests, written with y pointing UP as in the guideline.
// They are flipped to screen space when applied.
const _jlstzKicks = <String, List<Cell>>{
  '0>1': [Cell(0, 0), Cell(-1, 0), Cell(-1, 1), Cell(0, -2), Cell(-1, -2)],
  '1>0': [Cell(0, 0), Cell(1, 0), Cell(1, -1), Cell(0, 2), Cell(1, 2)],
  '1>2': [Cell(0, 0), Cell(1, 0), Cell(1, -1), Cell(0, 2), Cell(1, 2)],
  '2>1': [Cell(0, 0), Cell(-1, 0), Cell(-1, 1), Cell(0, -2), Cell(-1, -2)],
  '2>3': [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(0, -2), Cell(1, -2)],
  '3>2': [Cell(0, 0), Cell(-1, 0), Cell(-1, -1), Cell(0, 2), Cell(-1, 2)],
  '3>0': [Cell(0, 0), Cell(-1, 0), Cell(-1, -1), Cell(0, 2), Cell(-1, 2)],
  '0>3': [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(0, -2), Cell(1, -2)],
};

const _iKicks = <String, List<Cell>>{
  '0>1': [Cell(0, 0), Cell(-2, 0), Cell(1, 0), Cell(-2, -1), Cell(1, 2)],
  '1>0': [Cell(0, 0), Cell(2, 0), Cell(-1, 0), Cell(2, 1), Cell(-1, -2)],
  '1>2': [Cell(0, 0), Cell(-1, 0), Cell(2, 0), Cell(-1, 2), Cell(2, -1)],
  '2>1': [Cell(0, 0), Cell(1, 0), Cell(-2, 0), Cell(1, -2), Cell(-2, 1)],
  '2>3': [Cell(0, 0), Cell(2, 0), Cell(-1, 0), Cell(2, 1), Cell(-1, -2)],
  '3>2': [Cell(0, 0), Cell(-2, 0), Cell(1, 0), Cell(-2, -1), Cell(1, 2)],
  '3>0': [Cell(0, 0), Cell(1, 0), Cell(-2, 0), Cell(1, -2), Cell(-2, 1)],
  '0>3': [Cell(0, 0), Cell(-1, 0), Cell(2, 0), Cell(-1, 2), Cell(2, -1)],
};

/// Kick offsets to try, in screen space (y down), for a rotation.
List<Cell> kicksFor(PieceType type, Rotation from, Rotation to) {
  if (type == PieceType.o) return const [Cell(0, 0)];
  final table = type == PieceType.i ? _iKicks : _jlstzKicks;
  final tests = table['${from.index}>${to.index}']!;
  return [for (final k in tests) Cell(k.x, -k.y)];
}

/// A piece placed on the board.
class Piece {
  const Piece(this.type, this.rotation, this.x, this.y);

  final PieceType type;
  final Rotation rotation;
  final int x;
  final int y;

  Iterable<Cell> get cells sync* {
    for (final c in shapeOf(type, rotation)) {
      yield Cell(x + c.x, y + c.y);
    }
  }

  Piece copyWith({Rotation? rotation, int? x, int? y}) => Piece(type, rotation ?? this.rotation, x ?? this.x, y ?? this.y);

  Piece moved(int dx, int dy) => Piece(type, rotation, x + dx, y + dy);
}
