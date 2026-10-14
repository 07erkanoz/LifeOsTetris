import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/audio_service.dart';
import 'settings/settings.dart';
import 'theme/palette.dart';
import 'ui/game_screen.dart';

class KuplerApp extends StatelessWidget {
  const KuplerApp({super.key, required this.settings, required this.audio});

  final Settings settings;
  final AudioService audio;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'LifeOS Küpler',
        debugShowCheckedModeBanner: false,
        themeMode: settings.themeMode,
        theme: buildTheme(GamePalette.light),
        darkTheme: buildTheme(GamePalette.dark),
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
            child: child!,
          );
        },
        home: GameScreen(settings: settings, audio: audio),
      ),
    );
  }
}
