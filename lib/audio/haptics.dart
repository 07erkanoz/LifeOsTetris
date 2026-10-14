import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Vibration feedback.
///
/// Android goes through the game's own channel (MainActivity.kt), straight
/// to the Vibrator service with "media/game" usage: the vibration plugin tags
/// vibrations as alarms, which some phones (Xiaomi/Redmi among them) silence,
/// and it decides whether a motor exists through another plugin. iOS uses the
/// vibration plugin. Flutter's HapticFeedback is only a fallback: it follows
/// the system "touch feedback" setting, which is off on many phones.
class Haptics {
  static const _channel = MethodChannel('lifeos_kupler/haptics');

  /// Whether the device can vibrate: null until checked.
  static final ValueNotifier<bool?> available = ValueNotifier(null);

  bool _hasVibrator = false;
  bool _hasAmplitude = false;

  /// Strength from the settings, 0..1 (0.5 is the default feel).
  double strength = 0.5;

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _mobile => _android || _ios;

  int _scaleMs(int ms) => (ms * (0.55 + 0.9 * strength)).round();
  int _scaleAmplitude(int amplitude) => (amplitude * (0.45 + 1.1 * strength)).round().clamp(1, 255);

  Future<void> init() async {
    if (!_mobile) return;
    try {
      if (_android) {
        _hasVibrator = await _channel.invokeMethod<bool>('hasVibrator') ?? false;
      } else {
        _hasVibrator = await Vibration.hasVibrator();
        _hasAmplitude = _hasVibrator && await Vibration.hasAmplitudeControl();
      }
    } catch (e) {
      debugPrint('Vibration unavailable: $e');
      _hasVibrator = false;
    }
    available.value = _hasVibrator;
  }

  // Pulses under ~30 ms at low amplitude are not felt at all on many phones,
  // so even "light" is a clear tap.
  void light() => _pattern(const [0, 30], const [0, 140], HapticFeedback.lightImpact);
  void medium() => _pattern(const [0, 50], const [0, 210], HapticFeedback.mediumImpact);
  void heavy() => _pattern(const [0, 110], const [0, 255], HapticFeedback.heavyImpact);

  /// Two strong pulses for big moments (quad, perfect clear, level up).
  void celebrate() => _pattern(const [0, 70, 70, 110], const [0, 230, 0, 210], HapticFeedback.heavyImpact);

  /// [timings] alternate pause / vibrate (ms), [amplitudes] 0..255 per step.
  void _pattern(List<int> timings, List<int> amplitudes, Future<void> Function() fallback) {
    if (!_mobile) return;
    if (!_hasVibrator) {
      fallback();
      return;
    }
    final t = [for (var i = 0; i < timings.length; i++) i.isOdd ? _scaleMs(timings[i]) : timings[i]];
    final a = [for (final x in amplitudes) x == 0 ? 0 : _scaleAmplitude(x)];
    if (_android) {
      _channel.invokeMethod<void>('vibrate', [t, a]).catchError((Object _) {});
    } else {
      Vibration.vibrate(pattern: t, intensities: _hasAmplitude ? a : const []).catchError((Object _) {});
    }
  }
}
