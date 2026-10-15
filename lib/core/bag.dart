import 'dart:math';

import 'tetromino.dart';

/// 7-bag randomizer: every run of seven pieces contains each tetromino once.
class PieceBag {
  PieceBag([int? seed]) : _random = Random(seed);

  final Random _random;
  final List<PieceType> _queue = [];

  PieceType next() {
    _fill(1);
    return _queue.removeAt(0);
  }

  /// The upcoming [count] pieces without consuming them.
  List<PieceType> peek(int count) {
    _fill(count);
    return List.unmodifiable(_queue.take(count));
  }

  /// Puts [type] back at the front of the queue (a piece swapped out by a
  /// power comes back next).
  void pushFront(PieceType type) => _queue.insert(0, type);

  /// Pieces already drawn into the queue (for saving a game).
  List<PieceType> get queued => List.unmodifiable(_queue);

  /// Puts saved [pieces] back in front of the queue.
  void restoreQueue(List<PieceType> pieces) => _queue
    ..clear()
    ..addAll(pieces);

  void _fill(int count) {
    while (_queue.length < count) {
      _queue.addAll(List.of(standardPieces)..shuffle(_random));
    }
  }
}
