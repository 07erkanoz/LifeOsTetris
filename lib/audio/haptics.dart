import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Vibration feedback. Uses the device's vibration motor directly: Flutter's
/// HapticFeedback goes through Android's "touch feedback" system setting,
/// which is off on many phones, so it often did nothing at all.
class Haptics {
  bool _hasVibrator = false;
  bool _hasAmplitude = false;

  /// Strength from the settings, 0..1 (0.5 is the default feel).
  double strength = 0.5;

  int _scaleMs(int ms) => (ms * (0.55 + 0.9 * strength)).round();
  int _scaleAmplitude(int amplitude) => (amplitude * (0.45 + 1.1 * strength)).round().clamp(1, 255);

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

  // Pulses under ~30 ms at low amplitude are not felt at all on many phones
  // (Xiaomi/Redmi motors in particular), so even "light" is a clear tap.
  void light() => _buzz(30, 140, HapticFeedback.lightImpact);
  void medium() => _buzz(50, 210, HapticFeedback.mediumImpact);
  void heavy() => _buzz(110, 255, HapticFeedback.heavyImpact);

  /// Two strong pulses for big moments (quad, perfect clear, level up).
  void celebrate() {
    if (!_mobile) return;
    if (!_hasVibrator) {
      HapticFeedback.heavyImpact();
      return;
    }
    Vibration.vibrate(
      pattern: [0, _scaleMs(70), 70, _scaleMs(110)],
      intensities: _hasAmplitude ? [0, _scaleAmplitude(230), 0, _scaleAmplitude(210)] : const [],
    ).catchError((Object _) {});
  }

  void _buzz(int ms, int amplitude, Future<void> Function() fallback) {
    if (!_mobile) return;
    if (!_hasVibrator) {
      fallback();
      return;
    }
    Vibration.vibrate(duration: _scaleMs(ms), amplitude: _hasAmplitude ? _scaleAmplitude(amplitude) : -1).catchError((Object _) {});
  }
}
