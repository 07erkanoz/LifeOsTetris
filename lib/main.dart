import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_service.dart';
import 'audio/haptics.dart';
import 'settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final settings = await Settings.load();
  final audio = AudioService();
  unawaited(audio.init());
  final haptics = Haptics();
  unawaited(haptics.init());
  runApp(KuplerApp(settings: settings, audio: audio, haptics: haptics));
}
