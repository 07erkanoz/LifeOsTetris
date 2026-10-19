import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'audio/audio_service.dart';
import 'audio/haptics.dart';
import 'l10n/strings.dart';
import 'settings/settings.dart';
import 'theme/palette.dart';
import 'ui/fps_overlay.dart';
import 'ui/game_screen.dart';

class KuplerApp extends StatelessWidget {
  const KuplerApp({super.key, required this.settings, required this.audio, this.haptics});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;

  @override
  Widget build(BuildContext context) {
    final app = ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Küpler',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const _AppScrollBehavior(),
        themeMode: settings.themeMode,
        locale: switch (settings.language) {
          AppLanguage.system => null,
          AppLanguage.tr => const Locale('tr'),
          AppLanguage.en => const Locale('en'),
        },
        supportedLocales: supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildTheme(GamePalette.light),
        darkTheme: buildTheme(GamePalette.dark),
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return DesktopScale(
            child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
            // Large system font sizes broke button layouts; keep text within
            // a range the game's fixed-size HUD can hold.
            child: _AppShell(
              audio: audio,
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.1,
                child: Builder(
                  builder: (context) {
                    // Pixel type has a small em box: scale it up to match.
                    if (skinTextScale == 1) return child!;
                    final mq = MediaQuery.of(context);
                    return MediaQuery(
                      data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1) * skinTextScale)),
                      child: child!,
                    );
                  },
                ),
              ),
            ),
          ),
          );
        },
        home: GameScreen(settings: settings, audio: audio, haptics: haptics),
      ),
    );
    // Frame times in a corner, only in builds made for measuring.
    return FpsOverlay.enabled ? FpsOverlay(child: app) : app;
  }
}

/// A big desktop window draws the whole app larger, laid out as if on a
/// screen of about [base]: on a 1920×1080 window the cards, the text and the
/// boards fill it instead of floating small in the middle. Sprites are drawn
/// for the real pixels (the device pixel ratio grows with the scale).
class DesktopScale extends StatelessWidget {
  const DesktopScale({super.key, required this.child});

  final Widget child;

  static const Size base = Size(1366, 800);

  static bool get _desktop =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);

  /// How much larger to draw on a window of [size] (1: as it is).
  static double factorFor(Size size) => (size.width / base.width < size.height / base.height ? size.width / base.width : size.height / base.height).clamp(1.0, 2.0);

  @override
  Widget build(BuildContext context) {
    if (!_desktop) return child;
    final mq = MediaQuery.of(context);
    final k = factorFor(mq.size);
    if (k < 1.05) return child;
    final inner = mq.size / k;
    return MediaQuery(
      data: mq.copyWith(
        size: inner,
        devicePixelRatio: mq.devicePixelRatio * k,
        padding: mq.padding / k,
        viewPadding: mq.viewPadding / k,
        viewInsets: mq.viewInsets / k,
      ),
      child: SizedBox.expand(
        child: FittedBox(alignment: Alignment.topLeft, child: SizedBox.fromSize(size: inner, child: child)),
      ),
    );
  }
}

/// No scrollbars: on Windows the default ones are wide, always-visible bars
/// that look out of place over the game's glass cards. Lists still scroll
/// with the mouse wheel, touch and trackpad.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

/// Full screen on phones: the status and navigation bars stay hidden (a
/// swipe from the edge shows them for a moment), in every orientation.
/// Android brings them back after the app was in the background, so they
/// are hidden again on return. Music stops while the app is away.
class _AppShell extends StatefulWidget {
  const _AppShell({required this.audio, required this.child});

  final AudioService audio;
  final Widget child;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  static bool get _mobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  void _hideBars() {
    if (_mobile) SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hideBars();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.audio.inBackground = false;
        _hideBars();
      case AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
        widget.audio.inBackground = true;
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
