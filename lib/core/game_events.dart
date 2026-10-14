import 'powers.dart';
import 'tetromino.dart';

export 'powers.dart';

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

// ------------------------------------------------------------ powers

class EnergyGained extends GameEvent {
  const EnergyGained(this.energy);
  final int energy;
}

class PowerEarned extends GameEvent {
  const PowerEarned(this.type);
  final PowerType type;
}

class PowerActivated extends GameEvent {
  const PowerActivated(this.type);
  final PowerType type;
}

/// A cell removed by a power, with what used to be in it.
typedef RemovedCell = (Cell cell, PieceType type);

class BombExploded extends GameEvent {
  const BombExploded(this.center, this.removed, this.points);
  final Cell center;
  final List<RemovedCell> removed;
  final int points;
}

class ColumnDrilled extends GameEvent {
  const ColumnDrilled(this.column, this.fromRow, this.removed, this.points);
  final int column;
  final int fromRow;
  final List<RemovedCell> removed;
  final int points;
}

/// A block that fell during the gravity power: column, old row, new row.
typedef FallenCell = (int x, int fromY, int toY);

class GravityApplied extends GameEvent {
  const GravityApplied(this.moves);
  final List<FallenCell> moves;
}

class SlowMotionStarted extends GameEvent {
  const SlowMotionStarted(this.seconds);
  final double seconds;
}

class SlowMotionEnded extends GameEvent {
  const SlowMotionEnded();
}

class GhostLineStarted extends GameEvent {
  const GhostLineStarted();
}

class GhostLineFilled extends GameEvent {
  const GhostLineFilled(this.row, this.cells);

  /// Board row (including hidden rows).
  final int row;
  final List<Cell> cells;
}

// ------------------------------------------------------------ puzzles

class PuzzleSolved extends GameEvent {
  const PuzzleSolved({required this.stars, required this.piecesLeft});
  final int stars;
  final int piecesLeft;
}

class PuzzleFailed extends GameEvent {
  const PuzzleFailed();
}
