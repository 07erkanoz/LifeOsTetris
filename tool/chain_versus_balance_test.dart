// How a casual player does against each Ekşi Limon:
//   flutter test tool/chain_versus_balance_test.dart
// The player is played by the computer too, a little slower and sloppier.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/chain/chain_game.dart';
import 'package:lifeos_kupler/core/chain/chain_versus.dart';

void main() {
  test('balance', () {
    const dt = 1 / 30;
    for (final (name, think, slips, look) in const [('casual', 1.15, 0.3, 1), ('keen', 1.3, 0.35, 2), ('good', 0.9, 0.2, 2)]) {
      for (final rival in ChainRival.values) {
      var wins = 0, sets = 0, seconds = 0.0;
      const matches = 24;
      for (var m = 0; m < matches; m++) {
        final random = Random(m * 97 + rival.index);
        final v = ChainVersus(rival, random: random);
        final me = ChainCpu.custom(think: think, slips: slips, look: look, random: Random(m));
        var t = 0.0;
        while (!v.matchOver && t < 900) {
          v.startSet();
          while (!v.setOver && t < 900) {
            me.update(v.player, dt);
            v.update(dt);
            t += dt;
          }
          sets++;
        }
        seconds += t;
        if (v.playerWonMatch) wins++;
      }
      // ignore: avoid_print
      print('$name vs ${rival.name}: player wins $wins/$matches, ${(seconds / sets).toStringAsFixed(0)} s a set');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 30)));

  test('a rival alone keeps off the top for a while', () {
    for (final rival in ChainRival.values) {
      final g = ChainGame(random: Random(3))..startVersus();
      final cpu = ChainCpu(rival, random: Random(3));
      var t = 0.0;
      while (!g.isOver && t < 600) {
        cpu.update(g, 1 / 30);
        g.update(1 / 30);
        g.drainEvents();
        t += 1 / 30;
      }
      // ignore: avoid_print
      print('${rival.name} alone: ${t.toStringAsFixed(0)} s');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
