import 'package:flutter/widgets.dart';

import '../core/game_events.dart';
import '../core/scoring.dart';

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
  String highRefreshRate(double? hz) => hz == null || hz < 61
      ? _t('Yüksek kare hızı', 'High frame rate')
      : _t('Yüksek kare hızı (${hz.round()} Hz)', 'High frame rate (${hz.round()} Hz)');
  String get noVibrator => _t('Bu cihazda titreşim motoru bulunamadı', 'No vibration motor found on this device');
  String get audioProblem => _t('Ses sorunu', 'Audio problem');
  String get vibrationStrength => _t('Titreşim gücü', 'Vibration strength');
  String get quickButtons => _t('Tut ve düşür butonları', 'Hold and drop buttons');
  String get dropShort => _t('DÜŞÜR', 'DROP');
  String get onScreenButtons => _t('Ekran butonları', 'On-screen buttons');
  String get buttonOpacity => _t('Buton görünürlüğü', 'Button visibility');
  String get fullScreen => _t('Tam ekran (F11)', 'Full screen (F11)');
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
  String get aboutGameLabel => _t('HİKÂYE', 'THE STORY');
  List<String> get aboutStory => isTurkish
      ? const [
          'Hayat, tıpkı yukarıdan kontrolsüzce düşen bloklar gibidir: beklenmedik anlarda üst üste yığılır ve kaos yaratır. '
              'Hukuk kuralları bu kaosu nasıl bir düzene sokmaya çalışıyorsa, LifeOS Küpler de size o karmaşanın içinde kendi '
              'düzeninizi inşa etme fırsatı sunar.',
          'Bir avukat ve arabulucunun analitik bakış açısıyla tasarlanan bu oyunda amacınız yalnızca blokları yerleştirmek değil; '
              'hayatın hızla üzerinize bıraktığı uyuşmazlıkları ve parçaları doğru açıyla hizalayıp çözmektir. Her satır, çözüme '
              'kavuşturulmuş bir problemdir. Blokları dengeleyin, satırları eritin ve kendi yaşam işletim sisteminizi (LifeOS) '
              'kaostan kurtarın.',
        ]
      : const [
          'Life is like blocks falling from above without control: they pile up when you least expect it and create chaos. '
              'Just as the rules of law try to bring order to that chaos, LifeOS Küpler gives you the chance to build your own '
              'order within it.',
          'Designed with the analytical mind of a lawyer and mediator, this game is not only about placing blocks. It is about '
              'lining up the disputes and pieces life quickly drops on you at the right angle, and resolving them. Every line is a '
              'problem solved. Balance the blocks, melt the lines away and rescue your own life operating system (LifeOS) from chaos.',
        ];
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
          ('3 oyun modu', 'Klasik, Süper ve Bulmaca'),
          ('Bol efekt', 'Parçacık, ışık, sarsıntı'),
          ('Koyu & açık tema', 'Göz yormayan renkler'),
          ('Türkçe & İngilizce', 'Tek dokunuşla değiştir'),
        ]
      : const [
          ('3 game modes', 'Classic, Super and Puzzle'),
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

  // ------------------------------------------------------------ süper küpler

  String get classicTitle => _t('Klasik Küpler', 'Classic Blocks');
  String get normal => _t('Normal', 'Normal');
  String get normalSubtitle => _t('Hız yavaşça artar', 'Speed rises gently');
  String get relaxedShort => _t('Sabit, sakin hız', 'Calm, constant speed');
  String get superTitle => _t('Süper Küpler', 'Super Blocks');
  String get superSubtitle => _t('Enerji topla, güçleri kullan!', 'Charge up and unleash powers!');
  String get newBadge => _t('YENİ', 'NEW');
  String get powersLabel => _t('GÜÇLER', 'POWERS');
  String get energyLabel => _t('ENERJİ', 'ENERGY');
  String get ghostLineHint => _t('Doğru satırda dokun, boşluklar dolsun!', 'Tap on the right row to fill the gaps!');
  String get usePower => _t('Güç kullan', 'Use a power');
  String get energyHint => _t('3 satır = 1 güç', '3 lines = 1 power');
  String get powerNone => _t('Henüz yok. Satır sildikçe sırası gelir.', 'None yet. Keep clearing lines to earn it.');
  String get gravityNothing => _t('Şu an düşecek blok yok', 'Nothing to drop right now');
  String get newPower => _t('YENİ GÜÇ', 'NEW POWER');

  String modeName(GameMode mode) => switch (mode) {
    GameMode.classic => classic,
    GameMode.relaxed => relaxed,
    GameMode.superMode => superTitle,
  };

  // ------------------------------------------------------------ bulmaca küpler

  String get puzzleTitle => _t('Bulmaca Küpler', 'Puzzle Blocks');
  String get puzzleSubtitle => _t('Sürükle, yerleştir, patlat! 100 seviye', 'Drag, drop, blast! 100 levels');
  String get newBoard => _t('Yeni tahta', 'New board');
  String chapter(int n) => _t('Bölüm $n', 'Chapter $n');
  String get locked => _t('Önceki seviyeyi bitir', 'Finish the previous level');

  // ------------------------------------------------------------ bulmaca küpler (blocks)

  String get blocksSubtitle => _t('Sürükle, yerleştir, patlat!', 'Drag, drop, blast!');
  String get levelsMode => _t('Seviyeler', 'Levels');
  String get levelsModeSubtitle => _t('100 seviye: ★ blokları topla', '100 levels: collect the ★ blocks');
  String get endlessMode => _t('Sonsuz', 'Endless');
  String get endlessModeSubtitle => _t('Rekor için oyna', 'Play for a record');
  String continueLevel(int n) => _t('Devam et: Seviye $n', 'Continue: Level $n');
  String levelNumber(int n) => _t('Seviye $n', 'Level $n');
  String get gemsLeft => _t('KALAN ★', '★ LEFT');
  String get movesLeft => _t('HAMLE', 'MOVES');
  String get blocksGoal => _t('Satır ve sütunları doldur, tüm ★ blokları patlat!', 'Fill rows and columns to blast every ★ block!');
  String get blocksHowTo => _t(
    'Parçaları tahtaya sürükle. Dolan satır ve sütunlar patlar. Hiçbir parça sığmazsa oyun biter.',
    'Drag the pieces onto the board. Full rows and columns blast away. When nothing fits, the game is over.',
  );
  String threeStars(int moves) => _t('★★★ için en fazla $moves hamle', '★★★ in $moves moves or fewer');
  String get levelDone => _t('TAMAMLANDI!', 'COMPLETE!');
  String get levelCompleteTitle => _t('Seviye tamamlandı!', 'Level complete!');
  String get outOfMovesTitle => _t('Hamlen bitti', 'Out of moves');
  String get noRoomTitle => _t('Yer kalmadı', 'No room left');
  String get levelFailedHint => _t(
    'Biraz daha planla: ★ blokların olduğu satır ve sütunlara odaklan.',
    'Plan a little more: focus on the rows and columns with ★ blocks.',
  );
  String movesUsed(int n) => _t('$n hamlede', 'in $n moves');
  String get sameBoard => _t('Aynı tahta', 'Same board');
  String get nextLevel => _t('Sonraki seviye', 'Next level');
  String get allLevelsDone => _t('Tüm seviyeleri bitirdin!', 'You finished every level!');
  String get bestLabel => _t('EN İYİ', 'BEST');
  String? blastWord(int lines) => switch (lines) {
    < 2 => null,
    2 => _t('HARİKA!', 'GREAT!'),
    3 => _t('MUHTEŞEM!', 'AMAZING!'),
    4 => _t('EFSANE!', 'LEGENDARY!'),
    _ => _t('İNANILMAZ!', 'INCREDIBLE!'),
  };

  String powerName(PowerType type) => switch (type) {
    PowerType.bomb => _t('BOMBA', 'BOMB'),
    PowerType.single => _t('TEKLİ BLOK', 'SINGLE BLOCK'),
    PowerType.drill => _t('MATKAP', 'DRILL'),
    PowerType.gravity => _t('YERÇEKİMİ', 'GRAVITY'),
    PowerType.slowMotion => _t('AĞIR ÇEKİM', 'SLOW-MO'),
    PowerType.ghostLine => _t('HAYALET ÇİZGİ', 'GHOST LINE'),
  };

  String powerShortName(PowerType type) => switch (type) {
    PowerType.bomb => _t('Bomba', 'Bomb'),
    PowerType.single => _t('Tekli', 'Single'),
    PowerType.drill => _t('Matkap', 'Drill'),
    PowerType.gravity => _t('Yerçekimi', 'Gravity'),
    PowerType.slowMotion => _t('Ağır çekim', 'Slow-mo'),
    PowerType.ghostLine => _t('Hayalet', 'Ghost'),
  };

  String powerDescription(PowerType type) => switch (type) {
    PowerType.bomb => _t('Düştüğü yerde 3×3 alanı patlatır', 'Blasts a 3×3 area where it lands'),
    PowerType.single => _t('Tek karelik blok: delikleri kapat', 'A one-cell block to plug holes'),
    PowerType.drill => _t('Blokları delip bütün sütunu yer', 'Drills through and eats a whole column'),
    PowerType.gravity => _t('Havadaki bloklar düşer, boşluklar dolar', 'Floating blocks fall and fill the gaps'),
    PowerType.slowMotion => _t('10 saniye boyunca her şey yavaşlar', 'Everything slows down for 10 seconds'),
    PowerType.ghostLine => _t('Seçtiğin satırın boşluklarını doldurur', 'Fills the gaps of the row you choose'),
  };

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
