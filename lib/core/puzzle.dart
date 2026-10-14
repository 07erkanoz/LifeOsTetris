import 'tetromino.dart';

/// One placement of a puzzle's solution: piece, rotation and box x.
typedef PuzzleMove = (PieceType type, Rotation rotation, int x);

/// A "Bulmaca Küpler" level.
///
/// [rows] are the bottom rows of the board, top to bottom, one character per
/// cell: '.' empty, '*' a gem (golden target block), a piece letter
/// (IOTSZJL) a normal block. [pieces] are dealt in order; the first
/// [solution].length of them solve the puzzle by hard drops, the rest are
/// spares that earn the extra stars.
class PuzzleLevel {
  const PuzzleLevel({required this.number, required this.rows, required this.pieces, required this.solution});

  final int number;
  final List<String> rows;
  final String pieces;
  final List<PuzzleMove> solution;

  /// 1-based chapter of ten levels.
  int get chapter => (number - 1) ~/ 10 + 1;

  List<PieceType> get queue => [for (final ch in pieces.split('')) PieceType.values.byName(ch.toLowerCase())];

  int get gemCount => rows.join().split('').where((c) => c == '*').length;

  /// Stars for finishing with [piecesLeft] unused pieces.
  static int starsFor(int piecesLeft) => piecesLeft >= 2 ? 3 : (piecesLeft == 1 ? 2 : 1);
}
