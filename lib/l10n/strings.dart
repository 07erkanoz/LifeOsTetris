import 'package:flutter/widgets.dart';

import '../core/game_events.dart';

enum AppLanguage { system, tr, en }

const supportedLocales = [Locale('en'), Locale('tr')];

/// All user-visible text in Turkish and English.
class AppStrings {
  const AppStrings._(this.languageCode);

  static const tr = AppStrings._('tr');
  static const en = AppStrings._('en');

  final String languageCode;

  static AppStrings forCode(String code) => code == 'tr' ? tr : en;
  static AppStrings of(BuildContext context) => forCode(Localizations.localeOf(context).languageCode);

  bool get isTurkish => languageCode == 'tr';
  String _t(String tr, String en) => isTurkish ? tr : en;

  // ------------------------------------------------------------ numbers

  String score(int value) {
    final digits = value.toString();
    final sep = _t('.', ',');
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(sep);
      out.write(digits[i]);
    }
    return out.toString();
  }

  // ------------------------------------------------------------ HUD

  String get hold => _t('TUT', 'HOLD');
  String get next => _t('SIRADAKİ', 'NEXT');
  String get scoreLabel => _t('SKOR', 'SCORE');
  String get levelLabel => _t('SEVİYE', 'LEVEL');
  String get linesLabel => _t('SATIR', 'LINES');
  String get timeLabel => _t('SÜRE', 'TIME');
  String get controlsLabel => _t('KONTROLLER', 'CONTROLS');
  String get settingsLabel => _t('AYARLAR', 'SETTINGS');
  String get level => _t('Seviye', 'Level');
  String get lines => _t('Satır', 'Lines');
  String get time => _t('Süre', 'Time');
  String get best => _t('En iyi', 'Best');
  String get mode => _t('Mod', 'Mode');

  // ------------------------------------------------------------ modes

  String get classic => _t('Klasik', 'Classic');
  String get classicSubtitle => _t('Hız 10. seviyeye kadar yavaşça artar', 'Speed rises gently until level 10');
  String get relaxed => _t('Rahat', 'Relaxed');
  String get relaxedSubtitle => _t('Sabit ve sakin hız, sonsuz oyun', 'Calm, constant speed. Play forever');

  // ------------------------------------------------------------ controls

  String get moveLeftRight => _t('Sağa / sola', 'Move left / right');
  String get rotate => _t('Döndür', 'Rotate');
  String get rotateBack => _t('Ters döndür', 'Rotate back');
  String get softDrop => _t('Yumuşak düşüş', 'Soft drop');
  String get hardDrop => _t('Sert düşüş', 'Hard drop');
  String get holdAction => _t('Tut', 'Hold');
  String get pause => _t('Duraklat', 'Pause');
  String get touchHint => _t(
    'Dokun: döndür · Kaydır: taşı · Aşağı fırlat: düşür · Yukarı fırlat: tut',
    'Tap: rotate · Swipe: move · Flick down: drop · Flick up: hold',
  );
  String get keyboardHint =>
      _t('← → taşı · ↑ döndür · Space düşür · C tut · P duraklat', '← → move · ↑ rotate · Space drop · C hold · P pause');

  // ------------------------------------------------------------ settings

  String get theme => _t('Tema', 'Theme');
  String get light => _t('Açık', 'Light');
  String get dark => _t('Koyu', 'Dark');
  String get language => _t('Dil', 'Language');
  String get music => _t('Müzik', 'Music');
  String get soundEffects => _t('Efekt sesleri', 'Sound effects');
  String get visualEffects => _t('Görsel efektler', 'Visual effects');
  String get screenShake => _t('Ekran sarsıntısı', 'Screen shake');
  String get vibration => _t('Titreşim', 'Vibration');
  String get onScreenButtons => _t('Ekran butonları', 'On-screen buttons');
  String get buttonOpacity => _t('Buton görünürlüğü', 'Button visibility');
  String get holdTapHint => _t('Dokun: tut', 'Tap: hold');

  // ------------------------------------------------------------ menus

  String get tagline => _t('Blokları diz, satırları patlat!', 'Stack the blocks, blast the lines!');
  String get bestPrefix => _t('En iyi: ', 'Best: ');
  String get about => _t('Hakkında', 'About');
  String get back => _t('Geri', 'Back');
  String get paused => _t('Duraklatıldı', 'Paused');
  String get resume => _t('Devam et', 'Resume');
  String get restart => _t('Baştan', 'Restart');
  String get menu => _t('Menü', 'Menu');
  String get gameOver => _t('Oyun Bitti', 'Game Over');
  String get newRecord => _t('★ YENİ REKOR! ★', '★ NEW RECORD! ★');
  String get playAgain => _t('Tekrar oyna', 'Play again');
  String get mainMenu => _t('Ana menü', 'Main menu');

  // ------------------------------------------------------------ about

  String version(String v) => _t('Sürüm $v', 'Version $v');
  String get aboutGameLabel => _t('OYUN', 'GAME');
  String get aboutGame => _t(
    'LifeOS Küpler; düşen blokları dizip satırları patlattığın, bol efektli 2.5D bir blok bulmaca oyunudur. '
        'Klasik modda hız yavaşça artar, Rahat modda sakin bir tempoda sonsuza kadar oynarsın.',
    'LifeOS Küpler is a 2.5D block puzzle full of effects: stack the falling blocks and blast full lines. '
        'In Classic mode the speed rises gently; in Relaxed mode you play forever at a calm pace.',
  );
  String get statsLabel => _t('İSTATİSTİKLERİN', 'YOUR STATS');
  String get gamesPlayed => _t('Oyun', 'Games');
  String get totalLines => _t('Toplam satır', 'Total lines');
  String get playTime => _t('Oynama süresi', 'Play time');
  String get bestScore => _t('En iyi skor', 'Best score');
  String duration(int seconds) {
    final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60;
    if (h > 0) return _t('$h sa $m dk', '${h}h ${m}m');
    return _t('$m dk', '${m}m');
  }

  String get featuresLabel => _t('ÖNE ÇIKANLAR', 'HIGHLIGHTS');
  List<(String, String)> get features => isTurkish
      ? const [
          ('2 oyun modu', 'Klasik ve Rahat'),
          ('Bol efekt', 'Parçacık, ışık, sarsıntı'),
          ('Koyu & açık tema', 'Göz yormayan renkler'),
          ('Türkçe & İngilizce', 'Tek dokunuşla değiştir'),
        ]
      : const [
          ('2 game modes', 'Classic and Relaxed'),
          ('Packed with effects', 'Particles, light, shake'),
          ('Dark & light themes', 'Easy on the eyes'),
          ('Turkish & English', 'Switch with one tap'),
        ];
  String get developerLabel => _t('GELİŞTİRİCİ', 'DEVELOPER');
  String get personalSite => _t('Kişisel site', 'Personal site');
  String get lifeosFamily => _t('LifeOS ailesinin bir parçası', 'Part of the LifeOS family');
  String get madeWith => _t('Sevgiyle tasarlandı ve geliştirildi', 'Designed and built with love');
  String get developerRole => _t('Tasarım ve geliştirme', 'Design & development');
  String get musicLabel => _t('MÜZİK', 'MUSIC');
  String get fontAndSoundsLabel => _t('YAZI TİPİ VE SESLER', 'FONT & SOUNDS');
  String get fontAndSounds => _t(
    'Inter yazı tipi (SIL Open Font License). Ses efektleri oyun için özel olarak üretilmiştir.',
    'Inter typeface (SIL Open Font License). Sound effects were created specially for the game.',
  );

  // ------------------------------------------------------------ callouts

  String clearLabel(int lines, TSpin tSpin) {
    final names = isTurkish ? const ['', 'TEK', 'ÇİFT', 'ÜÇLÜ', 'DÖRTLÜ'] : const ['', 'SINGLE', 'DOUBLE', 'TRIPLE', 'QUAD'];
    final mini = _t('MİNİ T-SPIN', 'MINI T-SPIN');
    return switch (tSpin) {
      TSpin.full => lines == 0 ? 'T-SPIN' : 'T-SPIN ${names[lines]}!',
      TSpin.mini => lines == 0 ? mini : '$mini ${names[lines]}',
      TSpin.none => lines == 1 ? names[1] : '${names[lines]}!',
    };
  }

  String get tSpin => 'T-SPIN';
  String get miniTSpin => _t('MİNİ T-SPIN', 'MINI T-SPIN');
  String get perfectClear => _t('MÜKEMMEL!', 'PERFECT!');
  String combo(int n) => _t('KOMBO ×$n', 'COMBO ×$n');
  String get backToBack => 'B2B';
  String levelUp(int level) => _t('SEVİYE $level', 'LEVEL $level');
  String get speedingUp => _t('HIZLANIYOR', 'SPEEDING UP');
  String get keepGoing => _t('DEVAM!', 'KEEP GOING!');

  // ------------------------------------------------------------ motivation

  List<String> get praise => isTurkish
      ? const [
          'Harika!',
          'Süper gidiyorsun!',
          'Muhteşem!',
          'Durdurulamazsın!',
          'Ustaca!',
          'Böyle devam!',
          'Çok iyi!',
          'Efsane!',
          'Bu ne hız!',
          'Tam isabet!',
        ]
      : const [
          'Awesome!',
          "You're on fire!",
          'Amazing!',
          'Unstoppable!',
          'Masterful!',
          'Keep it up!',
          'Nice one!',
          'Legendary!',
          'So fast!',
          'Spot on!',
        ];

  String scoreMilestone(int score) => _t('${this.score(score)} puan! Harikasın!', '${this.score(score)} points! You rock!');
  String linesMilestone(int lines) => _t('$lines satır temizlendi!', '$lines lines cleared!');
  String get newBest => _t('Yeni rekor! Kendini geçtin!', 'New best! You beat yourself!');
  String comboStreak(int n) => _t('$n kombo! Seri katil!', '$n combo! On a roll!');
  String get backToBackPraise => _t('Arka arkaya! Usta işi!', 'Back to back! Pro move!');
  String get closeCall => _t('Kıl payı kurtuldun!', 'Close call! Nice save!');
  String get maxSpeed => _t('Maksimum hız! Sen bir efsanesin', 'Top speed! You are a legend');
  String get firstQuad => _t('İlk dörtlün! Muhteşem!', 'Your first quad! Brilliant!');
}
