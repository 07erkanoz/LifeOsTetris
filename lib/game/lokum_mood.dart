import '../l10n/strings.dart';
import 'sugar/sugar_art.dart';

/// Lokum's mood beside a game: the pose he strikes, what he says and for
/// how long. Times are the game's own clock, in seconds.
class LokumMood {
  LokumPose pose = LokumPose.happy;
  String? line;
  double until = 0;
  int priority = 0;

  /// When the pose last changed (for the hop).
  double changed = -10;
  int _count = 0;

  /// Strikes [newPose] and, unless a more important line is showing, says
  /// Lokum's line for [key] (see [AppStrings.lokum]).
  void say(AppStrings strings, String? key, LokumPose newPose, double now, {int priority = 1, double hold = 2.2}) {
    if (now < until && priority < this.priority) return;
    if (newPose != pose || key != null) changed = now;
    pose = newPose;
    line = key == null ? null : strings.lokum(key, _count++);
    until = now + hold;
    this.priority = priority;
  }

  /// Back to happy once the moment is over (unless [keep]).
  void settle(double now, {bool keep = false}) {
    if (now <= until || (line == null && pose == LokumPose.happy)) return;
    line = null;
    priority = 0;
    if (!keep && pose != LokumPose.happy) {
      pose = LokumPose.happy;
      changed = now;
    }
  }

  void reset() {
    pose = LokumPose.happy;
    line = null;
    priority = 0;
    until = 0;
    changed = -10;
  }

  /// How far into his hop he is (0 when still).
  double hop(double now) {
    final t = (now - changed) / 0.4;
    return t >= 0 && t < 1 ? t : 0;
  }
}
