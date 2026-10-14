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

  void _fill(int count) {
    while (_queue.length < count) {
      _queue.addAll(List.of(PieceType.values)..shuffle(_random));
    }
  }
}
