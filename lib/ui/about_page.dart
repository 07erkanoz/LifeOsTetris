import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../theme/palette.dart';
import 'widgets.dart';

const String appVersion = '1.0.0';
const String developerName = 'Erkan ÖZ';
const String websiteLabel = 'lifeos.com.tr';
final Uri websiteUri = Uri.parse('https://lifeos.com.tr');

const _musicCredits = [
  ('Commercial Music', 'Viacheslav Starostin', 'Pixabay'),
  ('Free Background Music', 'DesiFreeMusic', 'Pixabay'),
  ('Harlem Heat', 'Dagored', 'freetouse.com'),
  ('Bon Aleè', 'Moavii', 'freetouse.com'),
];

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const AboutPage(),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = GamePalette.of(context);
    final s = AppStrings.of(context);
    TextStyle body() => TextStyle(fontSize: 14, height: 1.5, color: p.muted, fontWeight: FontWeight.w600);

    Widget section(String label, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CardLabel(label), const SizedBox(height: 10), ...children]),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.background, stops: const [0, 0.55, 1]),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: s.back, onTap: () => Navigator.of(context).pop()),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: FittedBox(fit: BoxFit.scaleDown, child: LogoTitle(fontSize: 34)),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      s.version(appVersion),
                      style: TextStyle(color: p.label, fontWeight: FontWeight.w600),
                    ),
                  ),
                  section(s.aboutGameLabel, [Text(s.aboutGame, style: body())]),
                  section(s.developerLabel, [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: p.accentGradient),
                          child: const Text(
                            'EÖ',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                developerName,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
                              ),
                              Text(s.developerRole, style: body()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GradientButton(
                      label: websiteLabel,
                      icon: Icons.language_rounded,
                      onTap: () => launchUrl(websiteUri, mode: LaunchMode.externalApplication),
                    ),
                  ]),
                  section(s.musicLabel, [
                    for (final (title, artist, source) in _musicCredits)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.music_note_rounded, size: 18, color: p.accent1),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$title  ',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: p.text),
                                    ),
                                    TextSpan(
                                      text: '$artist · $source',
                                      style: TextStyle(color: p.muted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]),
                  section(s.fontAndSoundsLabel, [Text(s.fontAndSounds, style: body())]),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} $developerName · $websiteLabel',
                      style: TextStyle(color: p.label, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
