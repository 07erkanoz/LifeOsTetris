import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Borderless full screen on Windows, implemented in
/// windows/runner/flutter_window.cpp. Other platforms ignore it.
class WindowMode {
  WindowMode._();

  static const _channel = MethodChannel('lifeos_kupler/window');
  static bool? _applied;

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static Future<void> setFullScreen(bool on) async {
    if (!supported || _applied == on) return;
    _applied = on;
    try {
      await _channel.invokeMethod<bool>('setFullScreen', on);
    } catch (e) {
      debugPrint('Full screen failed: $e');
    }
  }
}
