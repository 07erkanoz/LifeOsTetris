import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Klasik and Süper Küpler stay upright on phones: their 10×20 well can be
/// at most half as wide as the screen is tall, so held sideways the board
/// would be tiny. Bulmaca Küpler's square board fits landscape well, and
/// tablets are big enough either way.
class OrientationLock {
  OrientationLock._();

  static bool isPhone(BuildContext context) =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) &&
      MediaQuery.sizeOf(context).shortestSide < 600;

  /// Upright only (phones).
  static void portrait(BuildContext context) => portraitIf(isPhone(context));

  static void portraitIf(bool phone) {
    if (phone) SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }

  /// Any orientation.
  static void any() => SystemChrome.setPreferredOrientations(const []);
}
