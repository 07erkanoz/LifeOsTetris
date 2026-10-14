import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'audio/audio_service.dart';
import 'l10n/strings.dart';
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
            child: child!,
          );
        },
        home: GameScreen(settings: settings, audio: audio),
      ),
    );
  }
}
