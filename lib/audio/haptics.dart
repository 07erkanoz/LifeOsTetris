import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Vibration feedback. Uses the device's vibration motor directly: Flutter's
/// HapticFeedback goes through Android's "touch feedback" system setting,
/// which is off on many phones, so it often did nothing at all.
class Haptics {
  bool _hasVibrator = false;
  bool _hasAmplitude = false;

  static bool get _mobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!_mobile) return;
    try {
      _hasVibrator = await Vibration.hasVibrator();
      _hasAmplitude = _hasVibrator && await Vibration.hasAmplitudeControl();
    } catch (e) {
      debugPrint('Vibration unavailable: $e');
    }
  }

  void light() => _buzz(18, 70, HapticFeedback.lightImpact);
  void medium() => _buzz(35, 150, HapticFeedback.mediumImpact);
  void heavy() => _buzz(70, 255, HapticFeedback.heavyImpact);

  /// Two strong pulses for big moments (quad, perfect clear, level up).
  void celebrate() {
    if (!_mobile) return;
    if (!_hasVibrator) {
      HapticFeedback.heavyImpact();
      return;
    }
    Vibration.vibrate(
      pattern: const [0, 60, 60, 90],
      intensities: _hasAmplitude ? const [0, 255, 0, 200] : const [],
    ).catchError((Object _) {});
  }

  void _buzz(int ms, int amplitude, Future<void> Function() fallback) {
    if (!_mobile) return;
    if (!_hasVibrator) {
      fallback();
      return;
    }
    Vibration.vibrate(duration: ms, amplitude: _hasAmplitude ? amplitude : -1).catchError((Object _) {});
  }
}
