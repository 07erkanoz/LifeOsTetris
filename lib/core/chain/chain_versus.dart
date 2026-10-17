import 'dart:math';

import 'chain_game.dart';
import 'chain_sim.dart';

/// The three Ekşi Limons to play against: how long each thinks between
/// swaps, how often he picks a worse move than he sees, and how far
/// ahead he looks.
enum ChainRival {
  /// Slow, and happy with any match.
  apprentice(think: 2.6, slips: 0.75, look: 1),

  /// Goes for combos and two-step chains.
  journeyman(think: 1.6, slips: 0.4, look: 2),

  /// Fast, and sets up chains two swaps ahead.
  master(think: 0.85, slips: 0.1, look: 2);

  const ChainRival({required this.think, required this.slips, required this.look});

  final double think;
  final double slips;
  final int look;
}

/// The computer playing a board: every so often, once the board is still,
/// it tries each swap on a [ChainSim] and makes the one it likes best; with
/// nothing to match it lifts the stack for a moment.
class ChainCpu {
  ChainCpu(ChainRival rival, {Random? random}) : this.custom(think: rival.think, slips: rival.slips, look: rival.look, random: random);

  /// A player of any skill (the balance tool plays one for the person).
  ChainCpu.custom({required this.think, required this.slips, required this.look, Random? random}) : _random = random ?? Random();

  final double think;
  final double slips;
  final int look;
  final Random _random;
  double _wait = 1.2;
  double _raiseFor = 0;

  void update(ChainGame g, double dt) {
    if (g.status != ChainStatus.playing) return;
    if (_raiseFor > 0) {
      _raiseFor -= dt;
      g.raising = _raiseFor > 0;
      return;
    }
    _wait -= dt;
    if (_wait > 0) return;
    if (!g.settled) {
      _wait = 0.08;
      return;
    }
    _wait = think * (0.8 + 0.4 * _random.nextDouble());
    final move = pick(g);
    if (move == null) {
      // Nothing to match: lift the stack a little for new cubes, unless it
      // is already high.
      if (ChainSim.of(g).height < 7) {
        _raiseFor = 0.14;
        g.raising = true;
      }
      return;
    }
    g.setCursor(move.$1, move.$2);
    g.swap(move.$1, move.$2);
  }

  /// The swap to make on [g] now, or null when nothing matches.
  (int, int)? pick(ChainGame g) {
    final base = ChainSim.of(g);
    final moves = <(double, int, int)>[];
    for (final (x, y) in base.swaps()) {
      final s = base.copy()..swap(x, y);
      var v = chainMoveValue(base, s, s.settle());
      if (look >= 2) {
        // A swap that sets up a chain for the next one counts too.
        var best = 0.0;
        for (final (x2, y2) in s.swaps()) {
          final t = s.copy()..swap(x2, y2);
          best = max(best, chainMoveValue(s, t, t.settle()));
        }
        v += best * 0.6;
      }
      if (v > 0) moves.add((v, x, y));
    }
    if (moves.isEmpty) return null;
    if (_random.nextDouble() < slips) {
      final m = moves[_random.nextInt(moves.length)];
      return (m.$2, m.$3);
    }
    moves.sort((a, b) => b.$1.compareTo(a.$1));
    return (moves.first.$2, moves.first.$3);
  }
}

/// A match against the computer, best of three sets: two boards side by
/// side, each one's big combos and chains dropping garbage on the other;
/// the first to stay at the top too long loses the set.
class ChainVersus {
  ChainVersus(this.rival, {Random? random})
    : _random = random ?? Random(),
      player = ChainGame(random: random),
      cpu = ChainGame(random: random) {
    ai = ChainCpu(rival, random: _random);
  }

  final ChainRival rival;
  final Random _random;
  final ChainGame player;
  final ChainGame cpu;
  late ChainCpu ai;

  int playerSets = 0;
  int cpuSets = 0;

  static const int setsToWin = 2;

  bool get matchOver => playerSets >= setsToWin || cpuSets >= setsToWin;
  bool get setOver => player.isOver || cpu.isOver;
  bool get playerWonMatch => playerSets >= setsToWin;

  /// The computer's board events from the last [update].
  List<ChainEvent> cpuEvents = const [];

  void startSet() {
    player.startVersus();
    cpu.startVersus();
    ai = ChainCpu(rival, random: _random);
  }

  /// Runs both boards for [dt] seconds: garbage goes across, a top-out ends
  /// the set. Returns the player's board events.
  List<ChainEvent> update(double dt) {
    player.update(dt);
    ai.update(cpu, dt);
    cpu.update(dt);
    final mine = player.drainEvents();
    final theirs = cpu.drainEvents();
    for (final e in mine) {
      if (e is ChainAttack) cpu.receive(e.widths);
    }
    for (final e in theirs) {
      if (e is ChainAttack) player.receive(e.widths);
    }
    // One board topped out: the other wins the set.
    if (player.isOver && !player.won && cpu.status == ChainStatus.playing) {
      cpuSets++;
      cpu.endMatch(won: true);
      theirs.addAll(cpu.drainEvents());
    } else if (cpu.isOver && !cpu.won && player.status == ChainStatus.playing) {
      playerSets++;
      player.endMatch(won: true);
      mine.addAll(player.drainEvents());
    }
    cpuEvents = theirs;
    return mine;
  }
}
