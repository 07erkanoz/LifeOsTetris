import 'package:flutter/widgets.dart';

import '../core/game_events.dart';
import '../core/scoring.dart';
import '../theme/palette.dart';

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
  String get themeLabel => _t('Tema', 'Theme');
  String themeName(VisualTheme theme) => switch (theme) {
    VisualTheme.toyHd => _t('Oyuncak HD', 'Toy HD'),
    VisualTheme.toy => _t('Oyuncak', 'Toy'),
    VisualTheme.pixel => _t('Piksel', 'Pixel'),
    VisualTheme.neon => 'Neon',
  };
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
  String get quitGame => _t('Çıkış', 'Quit');

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
    // More than four rows only happens with a power (gravity).
    if (lines > 4) return _t('$lines SATIR!', '$lines LINES!');
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
    GameMode.sprint => sprintTitle,
    GameMode.ultra => ultraTitle,
    GameMode.dig => digTitle,
    GameMode.target => targetTitle,
    GameMode.chaos => chaosTitle,
  };

  // ------------------------------------------------------------ challenges

  String get challengesLabel => _t('MEYDAN OKUMA', 'CHALLENGES');
  String get sprintTitle => _t('Hız Koşusu', 'Speed Run');
  String get ultraTitle => _t('3 Dakika', '3 Minutes');
  String get digTitle => _t('Kazı', 'Dig');
  String get sprintSubtitle => _t('${GameMode.sprintLines} satır, en kısa süre', '${GameMode.sprintLines} lines, fastest time');
  String get ultraSubtitle => _t('3 dakikada en yüksek skor', 'Best score in 3 minutes');
  String get digSubtitle => _t('${GameMode.digRows} gri satırı kaz', 'Dig through ${GameMode.digRows} grey rows');
  String get leftLabel => _t('KALAN', 'LEFT');
  String get challengeDone => _t('Tamamlandı!', 'Complete!');
  String get timeUp => _t('Süre doldu!', "Time's up!");
  String get challengeFailed => _t('Tamamlanamadı', 'Not finished');
  String get bestTimePrefix => _t('En iyi süre: ', 'Best time: ');

  /// 83.4 s → "1:23.4".
  String clock(double seconds, {bool tenths = true}) {
    final s = seconds < 0 ? 0.0 : seconds;
    final whole = tenths ? s.floor() : s.ceil();
    final m = whole ~/ 60, sec = whole % 60;
    final base = '$m:${sec.toString().padLeft(2, '0')}';
    return tenths ? '$base.${((s - s.floor()) * 10).floor()}' : base;
  }

  // ------------------------------------------------------------ home and modes

  String get play => _t('OYNA', 'PLAY');
  String get changeMode => _t('Modu değiştir', 'Change mode');
  String get modesTitle => _t('Modlar', 'Modes');
  String get settingsTitle => _t('Ayarlar', 'Settings');
  String get superGroup => _t('SÜPER', 'SUPER');
  String get puzzleGroup => _t('BULMACA', 'PUZZLE');
  String get levelsCard => _t('Seviyeler', 'Levels');
  String get levelsCardSubtitle => _t('100 seviye, yıldız topla', '100 levels, collect stars');
  String get endlessCardSubtitle => _t('Yer kaldıkça yerleştir', 'Place pieces while there is room');
  String get adventureTitle => _t('Macera', 'Adventure');
  String get adventureSubtitle => _t('Bölümleri bitir, resmi tamamla', 'Finish chapters, complete the picture');
  String get bombTitle => _t('Bomba', 'Bombs');
  String get bombSubtitle => _t('Patlamadan önce satırını temizle', 'Clear their rows before they blow');

  // ------------------------------------------------------- zincir küpler
  String get chainGroup => _t('ZİNCİR', 'CHAIN');
  String get chainTitle => _t('Zincir Küpler', 'Chain Blocks');
  String get chainEndlessTitle => _t('Sonsuz', 'Endless');
  String get chainEndlessSubtitle => _t('Küpleri kaydır, zincir kur', 'Swap cubes, build chains');
  String get chainTimeTitle => _t('Zamana Karşı', 'Time Attack');
  String get chainTimeSubtitle => _t('2 dakikada en yüksek skor', 'Top score in 2 minutes');
  String get chainLabel => _t('ZİNCİR', 'CHAIN');
  String chainCallout(int n) => _t('ZİNCİR ×$n', 'CHAIN ×$n');
  String chainCombo(int n) => _t('$n KÜP!', '$n CUBES!');
  String get chainBonus => 'BONUS';
  String chainLevel(int n) => _t('SEVİYE $n', 'LEVEL $n');
  String get chainDifficulty => _t('ZORLUK', 'DIFFICULTY');
  String get chainEasy => _t('Kolay', 'Easy');
  String get chainNormal => _t('Normal', 'Normal');
  String get chainHard => _t('Zor', 'Hard');
  String get chainEasyHint => _t('Yavaş, 4 renk, çöp blok yok', 'Slow, 4 colours, no garbage');
  String get chainNormalHint => _t('Orta hız, arada bir çöp blok', 'Medium speed, some garbage');
  String get chainHardHint => _t('Hızlı, sık çöp blok', 'Fast, frequent garbage');
  String get chainHowSwap => _t('Küpü parmağınla sağa sola kaydır', 'Drag a cube left or right');
  String get chainHowMatch => _t('Aynı renkten 3 küpü yan yana ya da üst üste getir', 'Line up 3 of a colour across or down');
  String get chainHowChain => _t('Düşen küpler yeniden eşleşirse ZİNCİR olur', 'Falling cubes that match again make a CHAIN');
  String get chainHowGarbage => _t('Kırmızı blokların yanında eşleştir, kırılsınlar', 'Match next to red slabs to break them');
  String get chainHowTop => _t('Küpler tepeye değmesin!', 'Keep the cubes off the top!');
  String get chainHowKeys => _t('Oklar: imleç · Boşluk: takas · Shift: yükselt', 'Arrows: cursor · Space: swap · Shift: raise');
  String get chainStart => _t('BAŞLA', 'START');
  String get chainRaise => _t('Yükselt', 'Raise');
  String chainLongest(int n) => _t('En uzun zincir ×$n', 'Longest chain ×$n');
  String chainCubes(int n) => _t('$n küp patlattın', '$n cubes cleared');

  // Şeker Küpler
  String get sugarGroup => _t('ŞEKER', 'SWEETS');
  String get sugarTitle => _t('Şeker Küpler', 'Sugar Blocks');
  String get sugarSubtitle => _t('Takas et, eşleştir, seviye atla', 'Swap, match, climb the levels');
  String sugarCardLevel(int n) => _t('Seviye $n', 'Level $n');
  String sugarLevel(int n) => _t('SEVİYE $n', 'LEVEL $n');
  String get sugarMoves => _t('HAMLE', 'MOVES');
  String sugarForStars(String score) => _t('×3 için $score', '×3 at $score');
  String sugarCallout(int cascade) => switch (cascade) {
    2 => _t('GÜZEL!', 'NICE!'),
    3 => _t('SÜPER!', 'SUPER!'),
    4 => _t('HARİKA!', 'AMAZING!'),
    _ => _t('MUHTEŞEM!', 'FANTASTIC!'),
  };
  String get sugarFinale => _t('ŞEKER ŞÖLENİ!', 'SWEET FINALE!');
  String get sugarLastMoves => _t('SON 5 HAMLE!', 'LAST 5 MOVES!');
  String get sugarShuffled => _t('KARIŞTIRILDI', 'SHUFFLED');
  String get sugarHammer => _t('Çekiç', 'Hammer');
  String get sugarShuffle => _t('Karıştır', 'Shuffle');
  String sugarExtraMoves(int n) => _t('+$n Hamle', '+$n Moves');
  String get sugarHammerHint => _t('Kırmak istediğin şekere dokun', 'Tap the sweet to smash');
  String get sugarPlay => _t('OYNA', 'PLAY');
  String sugarContinueLevel(int n) => _t('Devam: Seviye $n', 'Continue: Level $n');
  String get sugarResume => _t('Kaldığın yerden devam', 'Continue where you left off');
  String get sugarGoals => _t('HEDEFLER', 'GOALS');
  String sugarGoalScore(String n) => _t('$n puan topla', 'Score $n points');
  String sugarGoalColor(int n) => _t('$n şeker topla', 'Collect $n sweets');
  String sugarGoalIce(int n) => _t('$n buzu kır', 'Break $n ice');
  String sugarMovesLeft(int n) => _t('$n hamlen var', '$n moves');
  String get sugarWon => _t('SEVİYE TAMAM!', 'LEVEL CLEARED!');
  String get sugarLost => _t('HAMLE BİTTİ', 'OUT OF MOVES');
  String get sugarNext => _t('Sonraki seviye', 'Next level');
  String get sugarRetry => _t('Tekrar dene', 'Try again');
  String get sugarMap => _t('Harita', 'Map');
  String sugarKeepGoing(int n) => _t('+$n hamleyle devam', 'Go on with +$n moves');
  String get sugarChest => _t('SANDIK AÇILDI!', 'CHEST OPENED!');
  String get sugarNewBest => _t('Yeni rekor!', 'New best!');
  String get sugarBoss => _t('BOSS', 'BOSS');
  String get sugarHard => _t('ZOR', 'HARD');
  String get sugarAllDone => _t('Tüm seviyeler bitti! Yıldızları topla.', 'All levels done! Go for the stars.');
  String sugarChapter(int n) => switch (n) {
    0 => _t('BÖLÜM 1 · Şeker Kasabası', 'CHAPTER 1 · Candy Town'),
    1 => _t('BÖLÜM 2 · Buzlu Vadi', 'CHAPTER 2 · Frosty Valley'),
    2 => _t('BÖLÜM 3 · Zincir Kalesi', 'CHAPTER 3 · Chain Castle'),
    3 => _t('BÖLÜM 4 · Kutu Fabrikası', 'CHAPTER 4 · Box Factory'),
    4 => _t('BÖLÜM 5 · Bomba Kanyonu', 'CHAPTER 5 · Bomb Canyon'),
    _ => _t('BÖLÜM 6 · Gökkuşağı Adası', 'CHAPTER 6 · Rainbow Island'),
  };
  String get sugarRush => _t('ŞEKER\nÇILGINLIĞI!', 'SUGAR\nRUSH!');
  String get sugarRushMeter => _t('ŞEKER ÇILGINLIĞI', 'SUGAR RUSH');
  String get sugarLucky => _t('ŞANSLI ŞEKER!', 'LUCKY SWEET!');
  String sugarStar(int n) => _t('$n. YILDIZ!', 'STAR $n!');
  String get sugarCombo => _t('SÜPER KOMBO!', 'SUPER COMBO!');
  String get sugarBombLost => _t('BOMBA PATLADI', 'THE BOMB WENT OFF');
  String get sugarRainbow => _t('Gökkuşağı', 'Rainbow');
  String get sugarRainbowHint => _t('Gökkuşağı topu yapmak istediğin şekere dokun', 'Tap the sweet to turn into a rainbow ball');
  String sugarGoalBox(int n) => _t('$n kutuyu aç', 'Open $n boxes');

  /// What Lokum, the mascot, says: [key] picks the moment, [i] the line.
  String lokum(String key, int i) {
    final lines = switch (key) {
      'start' => [_t('Hadi başlayalım!', "Let's go!"), _t('Bu seviye bizim!', 'This one is ours!'), _t('Hazırım!', 'Ready!')],
      'nice' => [_t('Güzel!', 'Nice!'), _t('Tatlı hamle!', 'Sweet move!'), _t('Böyle devam!', 'Keep it up!')],
      'great' => [_t('Vay canına!', 'Wow!'), _t('Harika gidiyorsun!', "You're on fire!"), _t('Bu muhteşem!!', 'Amazing!!')],
      'rush' => [_t('Şeker çılgınlığı!', 'Sugar rush!'), _t('Yağmur gibi şeker!', "It's raining sweets!")],
      'lucky' => [_t('Şanslı gün!', 'Lucky day!'), _t('Gökten hediye!', 'A gift from the sky!')],
      'bomb' => [_t('Dikkat, bomba!', 'Watch the bomb!'), _t('Bombayı patlat!', 'Pop that bomb!')],
      'last' => [_t('Son hamleler!', 'Last moves!'), _t('Az kaldı!', 'Almost there!')],
      'finale' => [_t('Şölen zamanı!', 'Party time!'), _t('Hepsi patlasın!', 'Pop them all!')],
      'win' => [_t('Yaşasın!', 'Hooray!'), _t('Sen bir şampiyonsun!', "You're a champ!")],
      'lose' => [_t('Bir daha deneyelim!', "Let's try again!"), _t('Az kalmıştı!', 'So close!')],
      _ => [''],
    };
    return lines[i % lines.length];
  }
  String sugarHint(String key) => switch (key) {
    'swap' => _t('Yan yana iki şekerin yerini değiştir, aynı renkten 3 tanesini diz.', 'Swap two neighbouring sweets to line up 3 of a colour.'),
    'line' => _t('4 şeker diz: ÇİZGİLİ ŞEKER çıkar, bir sırayı temizler.', 'Line up 4: a STRIPED SWEET clears a whole row.'),
    'bomb' => _t('L ya da T yap: PAKETLİ ŞEKER çevresini patlatır.', 'Make an L or T: a WRAPPED SWEET blasts around it.'),
    'prism' => _t('5 şeker diz: GÖKKUŞAĞI TOPU çıkar, bir rengin hepsini alır.', 'Line up 5: a RAINBOW BALL takes every sweet of a colour.'),
    'ice' => _t('Buzlu karelerde eşleştir, buzu kır.', 'Match on icy squares to break the ice.'),
    'thickIce' => _t('Kalın buz iki kez kırılır.', 'Thick ice takes two hits.'),
    'chain' => _t('Zincirli şeker kaymaz; eşleştir, zinciri kır.', 'Chained sweets stay put; match them to break the chain.'),
    'rush' => _t('Her eşleşme Şeker Çılgınlığı göstergesini doldurur. Dolunca şekerler kendiliğinden patlar!', 'Every match fills the Sugar Rush meter. When it is full, sweets pop on their own!'),
    'box' => _t('Şeker kutusunun yanında eşleştir, kutu açılsın.', 'Match next to a candy box to open it.'),
    'box2' => _t('Pembe kurdeleli kutular iki kez açılır.', 'Boxes with a ribbon take two hits.'),
    'timed' => _t('Süreli bombayı sayısı sıfıra inmeden eşleştir!', 'Match the timed bomb before its count reaches zero!'),
    _ => '',
  };
  String get targetTitle => _t('Hedef', 'Targets');
  String get targetSubtitle => _t('Yıldızları topla, süre kazan', 'Collect stars to win time');
  String get chaosTitle => _t('Kaos', 'Chaos');
  String get chaosSubtitle => _t('Sürprizlerle dolu maraton', 'A marathon full of surprises');

  // ------------------------------------------------------------ pack 2

  String get starsLabel => _t('YILDIZ', 'STARS');
  String get surpriseLabel => _t('SÜRPRİZ', 'SURPRISE');
  String plusSeconds(double s) => _t('+${s.round()} SN', '+${s.round()} SEC');
  String chaosName(ChaosEvent e) => switch (e) {
    ChaosEvent.rise => _t('YÜKSELİŞ!', 'RISING!'),
    ChaosEvent.fog => _t('SİS!', 'FOG!'),
    ChaosEvent.rush => _t('HIZ ÇILGINLIĞI!', 'RUSH!'),
    ChaosEvent.quake => _t('DEPREM!', 'QUAKE!'),
    ChaosEvent.gift => _t('HEDİYE BOMBA!', 'GIFT BOMB!'),
  };
  String chaosHint(ChaosEvent e) => switch (e) {
    ChaosEvent.rise => _t('Alttan 2 gri satır geldi', '2 grey rows rose from below'),
    ChaosEvent.fog => _t(
      'Yığın ${ChaosEvent.fogSeconds.round()} saniye görünmez',
      'The stack hides for ${ChaosEvent.fogSeconds.round()} s',
    ),
    ChaosEvent.rush => _t('${ChaosEvent.rushSeconds.round()} saniye 3 kat hız', 'Triple speed for ${ChaosEvent.rushSeconds.round()} s'),
    ChaosEvent.quake => _t('Havadaki bloklar düştü', 'Floating blocks fell down'),
    ChaosEvent.gift => _t('Sıradaki parça bomba', 'Your next piece is a bomb'),
  };
  String get targetHowTo => _t(
    'Gri satırlardaki ★ blokları temizle: her ★ ${GameMode.targetBonus.round()} saniye kazandırır.',
    'Clear the ★ blocks in the grey rows: each ★ adds ${GameMode.targetBonus.round()} seconds.',
  );
  String get bombsLabel => _t('BOMBA', 'BOMBS');
  String get bombWentOffTitle => _t('Bomba patladı!', 'A bomb went off!');
  String get bombHowTo => _t(
    'Bombaların üstündeki sayı kalan hamledir. Sayı bitmeden satırını ya da sütununu patlat!',
    'The number on a bomb is the moves left. Blast its row or column before it runs out!',
  );
  String get bombFailedHint => _t(
    'Sayısı küçük bombaların satır ve sütunlarına öncelik ver.',
    'Go for the rows and columns of bombs with the lowest numbers first.',
  );
  String defusedCount(int n) => _t('$n bomba söndürüldü', '$n bombs defused');
  String adventureLevel(int chapter, int step) => _t('Bölüm $chapter · $step', 'Chapter $chapter · $step');
  String pictureName(int chapter) => switch (chapter) {
    1 => _t('Kalp', 'Heart'),
    2 => _t('Mantar', 'Mushroom'),
    3 => _t('Kedi', 'Cat'),
    4 => _t('Ev', 'House'),
    5 => _t('Ağaç', 'Tree'),
    6 => _t('Balık', 'Fish'),
    7 => _t('Roket', 'Rocket'),
    8 => _t('Çiçek', 'Flower'),
    9 => _t('Güneş', 'Sun'),
    _ => _t('Taç', 'Crown'),
  };
  String get adventureHowTo => _t(
    'Her bölüm 10 seviye. Çözdüğün her seviye resmin bir parçasını açar. 3. bölümden sonra bombalara dikkat!',
    'Each chapter has 10 levels. Every level you solve uncovers a piece of the picture. Mind the bombs from chapter 3!',
  );
  String get pieceUncovered => _t('Resmin yeni parçası açıldı!', 'A new piece of the picture!');
  String get pictureDone => _t('Resim tamamlandı!', 'Picture complete!');
  String get chapterLocked => _t('Önceki bölümü bitir', 'Finish the previous chapter');
  String playAdventure(int chapter, int step) => _t('Oyna: Bölüm $chapter · $step', 'Play: Chapter $chapter · $step');
  String get adventureDone => _t('Tüm resimler tamam!', 'Every picture is complete!');
  String get pictures => _t('Resimler', 'Pictures');

  // ------------------------------------------------------------ daily puzzle

  String get dailyTitle => _t('Günlük Görev', 'Daily Puzzle');
  String dailySubtitle(DateTime day) =>
      _t('${day.day} ${_monthsTr[day.month - 1]} bulmacası', '${_monthsEn[day.month - 1]} ${day.day} puzzle');
  String streakDays(int n) => _t('$n günlük seri', '$n-day streak');
  String get dailyDone => _t('Bugünkü görev tamam', "Today's puzzle is done");
  String get dailyNew => _t('Yeni görev', 'New puzzle');
  String get dailyTomorrow => _t('Yarın yeni görev', 'New puzzle tomorrow');
  String resumeDaily(int movesLeft) => _t('Günlük Görev · $movesLeft hamle kaldı', 'Daily Puzzle · $movesLeft moves left');

  static const _monthsTr = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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
  String get resumeGame => _t('Kaldığın yerden devam', 'Continue where you left off');
  String resumeSummary(String mode, int score, int level) =>
      _t('$mode · ${this.score(score)} puan · Seviye $level', '$mode · ${this.score(score)} points · Level $level');
  String resumeBlocksLevel(int level, int movesLeft) =>
      _t('Seviye $level · $movesLeft hamle kaldı', 'Level $level · $movesLeft moves left');
  String resumeBlocksEndless(String endless, int score) =>
      _t('$endless · ${this.score(score)} puan', '$endless · ${this.score(score)} points');
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
