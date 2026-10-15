import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'audio/audio_service.dart';
import 'audio/haptics.dart';
import 'l10n/strings.dart';
import 'settings/settings.dart';
import 'theme/palette.dart';
import 'ui/game_screen.dart';

class KuplerApp extends StatelessWidget {
  const KuplerApp({super.key, required this.settings, required this.audio, this.haptics});

  final Settings settings;
  final AudioService audio;
  final Haptics? haptics;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'LifeOS Küpler',
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
          return AnnotatedRegion<SystemUiOverlayStyle>(
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
          );
        },
        home: GameScreen(settings: settings, audio: audio, haptics: haptics),
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
