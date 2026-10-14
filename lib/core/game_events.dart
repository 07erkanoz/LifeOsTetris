import 'tetromino.dart';

/// Things that happened inside the game during an update. The UI drains these
/// every frame to trigger sounds, haptics and visual effects.
sealed class GameEvent {
  const GameEvent();
}

class PieceSpawned extends GameEvent {
  const PieceSpawned(this.type);
  final PieceType type;
}

class PieceMoved extends GameEvent {
  const PieceMoved(this.dx);
  final int dx;
}

class PieceMoveBlocked extends GameEvent {
  const PieceMoveBlocked(this.dx);
  final int dx;
}

class PieceRotated extends GameEvent {
  const PieceRotated({required this.clockwise, required this.kicked});
  final bool clockwise;
  final bool kicked;
}

class SoftDropped extends GameEvent {
  const SoftDropped();
}

class HardDropped extends GameEvent {
  const HardDropped({required this.type, required this.fromCells, required this.toCells, required this.distance});
  final PieceType type;
  final List<Cell> fromCells;
  final List<Cell> toCells;
  final int distance;
}

class PieceLocked extends GameEvent {
  const PieceLocked(this.type, this.cells);
  final PieceType type;
  final List<Cell> cells;
}

class PieceHeld extends GameEvent {
  const PieceHeld(this.type);
  final PieceType type;
}

enum TSpin { none, mini, full }

class LinesCleared extends GameEvent {
  const LinesCleared({
    required this.rows,
    required this.tSpin,
    required this.combo,
    required this.backToBack,
    required this.perfectClear,
    required this.points,
  });

  /// Board row indices (including hidden rows) that are being cleared.
  final List<int> rows;
  final TSpin tSpin;

  /// 0 for the first clear in a chain, 1 for the next one and so on.
  final int combo;
  final bool backToBack;
  final bool perfectClear;
  final int points;

  int get count => rows.length;
}

/// A T-spin that did not clear any lines still scores and gets a callout.
class TSpinNoLines extends GameEvent {
  const TSpinNoLines(this.tSpin, this.points);
  final TSpin tSpin;
  final int points;
}

/// Emitted after the line clear delay, when the rows are actually removed.
class RowsCollapsed extends GameEvent {
  const RowsCollapsed(this.rows);
  final List<int> rows;
}

class LevelUp extends GameEvent {
  const LevelUp(this.level);
  final int level;
}

class GameOver extends GameEvent {
  const GameOver();
}
