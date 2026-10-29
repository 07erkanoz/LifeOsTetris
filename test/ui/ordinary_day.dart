import 'package:lifeos_kupler/core/special_days.dart';
import 'package:lifeos_kupler/settings/settings.dart';

/// On a national day or a bayram Lokum's greeting comes first on the home
/// screen, ahead of the tips the tests look for. Settings on the real clock
/// play an ordinary day then, so the tests pass on any day (CI ran on
/// 29 Ekim); a test that sets its own clock keeps it.
Settings ordinaryDay(Settings settings) {
  if (settings.clock == DateTime.now && SpecialDay.of(DateTime.now()) != null) {
    settings.clock = () => DateTime(2026, 10, 20, 10);
  }
  return settings;
}
