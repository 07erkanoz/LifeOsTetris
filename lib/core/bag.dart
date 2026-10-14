import 'dart:math';

import 'tetromino.dart';

/// 7-bag randomizer: every run of seven pieces contains each tetromino once.
class PieceBag {
  PieceBag([int? seed]) : _random = Random(seed), _fixed = false;

  /// A bag that deals exactly [pieces], in order, and then runs out.
  PieceBag.fixed(List<PieceType> pieces) : _random = Random(0), _fixed = true {
    _queue.addAll(pieces);
  }

  final Random _random;
  final bool _fixed;
  final List<PieceType> _queue = [];

  /// True when a fixed bag has nothing left to deal.
  bool get isExhausted => _fixed && _queue.isEmpty;

  /// Pieces still to be dealt by a fixed bag.
  int get remaining => _queue.length;

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

  void _fill(int count) {
    if (_fixed) return;
    while (_queue.length < count) {
      _queue.addAll(List.of(standardPieces)..shuffle(_random));
    }
  }
}
