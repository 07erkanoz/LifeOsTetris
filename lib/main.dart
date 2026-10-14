import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_service.dart';
import 'audio/haptics.dart';
import 'platform/window_mode.dart';
import 'settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final settings = await Settings.load();
  final audio = AudioService(
    enabled: AudioService.platformSupported,
    lastTrack: settings.lastTrack,
    onTrackStarted: (t) => settings.lastTrack = t,
  );
  unawaited(audio.init());
  final haptics = Haptics();
  unawaited(haptics.init());
  unawaited(WindowMode.setFullScreen(settings.fullScreen));
  settings.addListener(() => WindowMode.setFullScreen(settings.fullScreen));
  runApp(KuplerApp(settings: settings, audio: audio, haptics: haptics));
}
