import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// High refresh rate on Android (implemented in MainActivity.kt): Android
/// keeps apps at 60 Hz unless they pick a faster display mode. Desktops
/// already follow the monitor, so only the game's own frame cap matters there.
class DisplayMode {
  DisplayMode._();

  static const _channel = MethodChannel('lifeos_kupler/display');
  static bool? _applied;

  /// The screen's fastest refresh rate, once known (Android only).
  static final ValueNotifier<double?> maxRefreshRate = ValueNotifier(null);

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> init() async {
    if (!_android) return;
    try {
      maxRefreshRate.value = await _channel.invokeMethod<double>('maxRefreshRate');
    } catch (e) {
      debugPrint('Refresh rate unavailable: $e');
    }
  }

  static Future<void> setHighRefreshRate(bool on) async {
    if (!_android || _applied == on) return;
    _applied = on;
    try {
      await _channel.invokeMethod<double>('setHighRefreshRate', on);
    } catch (e) {
      debugPrint('Refresh rate change failed: $e');
    }
  }
}
