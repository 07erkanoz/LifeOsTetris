import 'package:flutter/widgets.dart';

import '../core/chain/chain_game.dart';
import '../core/sugar/sugar_game.dart' show SugarCombo;
import '../core/game_events.dart';
import '../core/scoring.dart';
import '../core/special_days.dart';
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

  /// [text] in capitals the way the language writes them: Turkish keeps
  /// the dot on i (İ) and drops it from ı (I), which toUpperCase does not.
  String upper(String text) => isTurkish ? text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase() : text.toUpperCase();

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
  String get mode => _t('Oyun', 'Game');

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
  String get backAgainToExit => _t('Çıkmak için bir kez daha geri bas', 'Press back again to exit');
  String get paused => _t('Duraklatıldı', 'Paused');
  String get resume => _t('Devam et', 'Resume');
  String get restart => _t('Baştan', 'Restart');
  String get menu => _t('Menü', 'Menu');
  String get gameOver => _t('Oyun Bitti', 'Game Over');
  String get newRecord => _t('YENİ REKOR!', 'NEW RECORD!');
  String get playAgain => _t('Tekrar oyna', 'Play again');
  String get mainMenu => _t('Ana menü', 'Main menu');
  String get quitGame => _t('Çıkış', 'Quit');

  // ------------------------------------------------------------ about

  String version(String v) => _t('Sürüm $v', 'Version $v');
  String get aboutGameLabel => _t('HİKÂYE', 'THE STORY');
  List<String> get aboutStory => isTurkish
      ? const [
          'Hayat, tıpkı yukarıdan kontrolsüzce düşen bloklar gibidir: beklenmedik anlarda üst üste yığılır ve kaos yaratır. '
              'Hukuk kuralları bu kaosu nasıl bir düzene sokmaya çalışıyorsa, Küpler de size o karmaşanın içinde kendi '
              'düzeninizi inşa etme fırsatı sunar.',
          'Bir avukat ve arabulucunun analitik bakış açısıyla tasarlanan bu oyunda amacınız yalnızca blokları yerleştirmek değil; '
              'hayatın hızla üzerinize bıraktığı uyuşmazlıkları ve parçaları doğru açıyla hizalayıp çözmektir. Her satır, çözüme '
              'kavuşturulmuş bir problemdir. Blokları dengeleyin, satırları eritin ve kendi yaşam işletim sisteminizi (LifeOS) '
              'kaostan kurtarın.',
        ]
      : const [
          'Life is like blocks falling from above without control: they pile up when you least expect it and create chaos. '
              'Just as the rules of law try to bring order to that chaos, Küpler gives you the chance to build your own '
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
          ('Beş oyun', 'Şeker, Zincir, Bulmaca, Süper, Klasik'),
          ('Bol efekt', 'Parçacık, ışık, sarsıntı'),
          ('Koyu & açık tema', 'Göz yormayan renkler'),
          ('Türkçe & İngilizce', 'Tek dokunuşla değiştir'),
        ]
      : const [
          ('Five games', 'Sugar, Chain, Puzzle, Super, Classic'),
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
  // Home lobby: Lokum's suggestions and the mode cards.
  String get forYou => _t('SENİN İÇİN', 'FOR YOU');
  // Home: the games showcase, the game tiles, the continue bar, the tour.
  String get allGames => _t('TÜM OYUNLAR', 'ALL GAMES');
  String get allModes => _t('Tüm modlar', 'All modes');
  String get newGameBadge => _t('YENİ OYUN', 'NEW GAME');
  String get leftOffLabel => _t('KALDIĞIN YERDEN', 'WHERE YOU LEFT OFF');
  String get lastPlayedLabel => _t('SON OYNADIĞIN', 'LAST PLAYED');
  String get towerKind => _t('Kule diz', 'Stack a tower');
  String get sugarKind => _t('Eşleştir · patlat', 'Match · pop');
  String get chainKind => _t('Zincir kur', 'Make chains');
  String get puzzleKind => _t('Blok yerleştir', 'Place blocks');
  String get superKind => _t('Güçlü bloklar', 'Power blocks');
  String get classicKind => _t('Düşen bloklar', 'Falling blocks');
  String get tourTitle => _t('Burada tam 6 oyun var!', 'There are 6 games right here!');
  String get tourLine => _t('Kaydırıp bak ya da aşağıdan birini seç.', 'Swipe to look, or pick one below.');
  String get tourOk => _t('ANLADIM', 'GOT IT');
  String get artSuper => _t('SÜPER!', 'SUPER!');
  String get artLines => _t('4 SATIR!', '4 LINES!');
  String get tipUntried => _t('Buna hiç bakmadın, bence bayılırsın!', "You haven't tried this, you'll love it!");
  String get tipTry => _t('Bir dene', 'Give it a go');
  String tipLeftOff(int level) => _t('$level. seviyede kalmıştık!', 'We stopped at level $level!');
  String get tipContinue => _t('Devam et', 'Continue');
  String get tipDaily => _t('Bugünün bulmacası seni bekliyor!', "Today's puzzle is waiting for you!");
  String get tipSolve => _t('Çöz', 'Solve');
  String get tipBeatBest => _t('Hadi, rekorunu bir zorlayalım!', "Come on, let's push your record!");
  String get tipPlay => _t('Oyna', 'Play');
  String get tipTapMe => _t('Bana dokun, aklımda bir şey daha var!', "Tap me, I've got another idea!");
  // Gifts: the daily calendar, the sugar jar, star chests, the weekly event.
  String get giftsTitle => _t('HEDİYELER', 'GIFTS');
  String get giftsShort => _t('Hediyeler', 'Gifts');
  /// The fortune read in the coffee cup when the daily gift opens: [main]
  /// is the booster there is most of, [big] a day that opens a chest.
  String coffeeFortune(String main, {required bool big, required int seed}) {
    if (big) {
      return _t('Fincanda bir kapı görüyorum: kısmetin büyük, bugün sandık açılıyor!', "I see a door in the cup: big luck today, a chest is opening!");
    }
    final lines = switch (main) {
      'hammer' => [
        _t('Fincanda bir çekiç görüyorum; önündeki engeller bir bir kırılacak!', 'I see a hammer in the cup; the obstacles ahead will break one by one!'),
        _t('Telvede sağlam bir el var; bugün kırmadığın buz kalmayacak!', 'There is a strong hand in the grounds; no ice will stand today!'),
      ],
      'rainbow' => [
        _t('Telvede bir gökkuşağı var; bugün renkler senden yana!', 'There is a rainbow in the grounds; the colours are on your side today!'),
        _t('Fincan rengârenk; bir sürpriz seni bekliyor!', 'The cup is full of colour; a surprise is waiting for you!'),
      ],
      'shuffle' => [_t('Fincanda bir rüzgâr var; işler lehine dönecek!', 'There is a wind in the cup; things will turn your way!')],
      _ => [
        _t('Yolun açık, üç yıldız görüyorum!', 'Your road is open, I see three stars!'),
        _t('Fincanda uzun bir yol var; hamlen bol, yolun açık!', 'There is a long road in the cup; plenty of moves, the way is clear!'),
      ],
    };
    return lines[seed % lines.length];
  }

  String get fortuneTitle => _t('Kahve falın', 'Your coffee fortune');
  String get dailyGiftTitle => _t('Günlük hediye', 'Daily gift');
  String get dailyGiftHint => _t('Her gün bir hediye. Bir gün kaçırırsan kaldığın yerden devam.', 'A gift every day. Miss a day and you carry on where you were.');
  String giftDayLabel(int day) => _t('${day + 1}. gün', 'Day ${day + 1}');
  String get giftToday => _t('BUGÜN', 'TODAY');
  String get giftTaken => _t('ALINDI', 'TAKEN');
  String get giftTake => _t('AL', 'TAKE');
  String get giftTomorrow => _t('Yarın yeni hediye', 'A new gift tomorrow');
  String get giftTomorrowShort => _t('yarın', 'tomorrow');
  String get giftTakeToday => _t('HEDİYENİ AL', 'TAKE YOUR GIFT');
  String giftNextIn(int hours, int minutes) => hours > 0
      ? _t('Sıradaki hediye: $hours sa $minutes dk sonra', 'Next gift in ${hours}h ${minutes}m')
      : _t('Sıradaki hediye: $minutes dk sonra', 'Next gift in ${minutes}m');
  String get giftBigChest => _t('Büyük sandık', 'Big chest');
  String get tipGift => _t('Bugünün hediyesi geldi, aç bakalım!', "Today's gift is here, open it!");
  String get tipOpen => _t('Aç', 'Open');
  String tipGiftsWaiting(int n) => _t('$n hediye seni bekliyor!', '$n gifts are waiting for you!');
  String get tipSee => _t('Gör', 'See');
  String get jarTitle => _t('Şeker kavanozu', 'Sugar jar');
  String get jarHint => _t('Patlattığın her şeker kavanoza düşer.', 'Every sweet you pop drops into the jar.');
  String get jarFull => _t('Kavanoz doldu!', 'The jar is full!');
  String get jarFullAsk => _t('Kavanoz doldu! İçinde ne var?', "The jar is full! What's inside?");
  String get jarOpen => _t('AÇ', 'OPEN');
  String get jarOpenFull => _t('KAVANOZU AÇ', 'OPEN THE JAR');
  String get chestsTitle => _t('Yıldız sandıkları', 'Star chests');
  String chestsHint(int every) => _t("Şeker Küpler'de her $every yıldızda bir sandık.", 'A chest for every $every Sugar Blocks stars.');
  String chestNext(int stars) => _t('Sonraki sandık: $stars yıldız', 'Next chest: $stars stars');
  String chestName(int tier) => switch (tier) {
    2 => _t('ALTIN SANDIK!', 'GOLD CHEST!'),
    1 => _t('GÜMÜŞ SANDIK!', 'SILVER CHEST!'),
    _ => _t('BRONZ SANDIK!', 'BRONZE CHEST!'),
  };
  String get chestOpen => _t('SANDIĞI AÇ', 'OPEN THE CHEST');
  /// Lokum's word on a special day (shown to Turkish players): a title and
  /// a line; [year] counts the Republic's years.
  ({String title, String line}) specialDay(SpecialDay d, int year) => switch (d) {
    SpecialDay.yilbasi => (title: _t('Mutlu yıllar!', 'Happy New Year!'), line: _t('Yeni yılın sağlık, mutluluk ve bol yıldız getirsin.', 'May the new year bring health, joy and plenty of stars.')),
    SpecialDay.cocuk => (title: _t('23 Nisan kutlu olsun!', 'Happy 23 April!'), line: _t('Ulusal Egemenlik ve Çocuk Bayramımız kutlu olsun!', 'Happy National Sovereignty and Children\'s Day!')),
    SpecialDay.emek => (title: _t('1 Mayıs kutlu olsun!', 'Happy 1 May!'), line: _t('Emek ve Dayanışma Günü kutlu olsun.', 'Happy Labour and Solidarity Day.')),
    SpecialDay.genclik => (title: _t('19 Mayıs kutlu olsun!', 'Happy 19 May!'), line: _t("Atatürk'ü Anma, Gençlik ve Spor Bayramımız kutlu olsun!", 'Happy Commemoration of Atatürk, Youth and Sports Day!')),
    SpecialDay.demokrasi => (title: _t('15 Temmuz', '15 July'), line: _t("Demokrasi ve Millî Birlik Günü'nde şehitlerimizi rahmetle anıyoruz.", 'On Democracy and National Unity Day we remember those who lost their lives.')),
    SpecialDay.zafer => (title: _t('30 Ağustos kutlu olsun!', 'Happy 30 August!'), line: _t('Zafer Bayramımız kutlu olsun!', 'Happy Victory Day!')),
    SpecialDay.cumhuriyet => (title: _t('Cumhuriyet Bayramımız kutlu olsun!', 'Happy Republic Day!'), line: _t('Cumhuriyetimizin $year. yılı kutlu olsun!', 'Happy ${year}th year of the Republic!')),
    SpecialDay.ramazan => (title: _t('İyi bayramlar!', 'Happy Eid!'), line: _t('Ramazan Bayramınız mübarek olsun.', 'Happy Eid al-Fitr.')),
    SpecialDay.kurban => (title: _t('İyi bayramlar!', 'Happy Eid!'), line: _t('Kurban Bayramınız mübarek olsun.', 'Happy Eid al-Adha.')),
    SpecialDay.hidirellez => (title: _t('Hıdırellez kutlu olsun!', 'Happy Hıdırellez!'), line: _t('Dilekler gül ağacına, bahar gönüllere!', 'Wishes on the rose bush, spring in every heart!')),
    SpecialDay.ataturk => (title: _t('10 Kasım', '10 November'), line: _t("Ulu Önder Mustafa Kemal Atatürk'ü saygı, sevgi ve özlemle anıyoruz.", 'We remember Mustafa Kemal Atatürk with respect, love and longing.')),
  };
  String get eventTitle => _t('Haftanın etkinliği', "This week's event");
  String get eventTitleDay => _t('Özel gün etkinliği', 'Special day event');
  String eventDaysLeft(int n) => n <= 1 ? _t('Bu gece biter', 'Ends tonight') : _t('$n gün kaldı', '$n days left');
  String get eventClaim => _t('ÖDÜLÜ AL', 'TAKE THE PRIZE');
  String eventProgress(int got, int of) => '$got / $of';
  String eventName(String e) => switch (e) {
    'tulip' => _t('Lale Festivali', 'Tulip Festival'),
    'ferry' => _t('Vapur Haftası', 'Ferry Week'),
    'coffee' => _t('Kahve Haftası', 'Coffee Week'),
    'hamam' => _t('Hamam Haftası', 'Hamam Week'),
    'dondurma' => _t('Dondurma Haftası', 'Ice Cream Week'),
    'mehter' => _t('Mehter Haftası', 'Mehter Week'),
    'karadeniz' => _t('Karadeniz Haftası', 'Black Sea Week'),
    'bayram' => _t('Şeker Bayramı', 'Sugar Feast'),
    'hidirellez' => _t('Hıdırellez', 'Hıdırellez'),
    _ => _t('Simit Haftası', 'Simit Week'),
  };
  String eventGoal(String e) => switch (e) {
    'coffee' => _t('Herhangi bir seviyede turuncu girdap patlat', 'Pop orange swirls in any level'),
    'tulip' || 'mehter' || 'hidirellez' => _t('Herhangi bir seviyede kırmızı kalp patlat', 'Pop red hearts in any level'),
    'ferry' || 'hamam' => _t('Herhangi bir seviyede mavi damla patlat', 'Pop blue drops in any level'),
    'dondurma' => _t('Herhangi bir seviyede mor şeker patlat', 'Pop purple sweets in any level'),
    'karadeniz' => _t('Herhangi bir seviyede yeşil jöle patlat', 'Pop green jellies in any level'),
    _ => _t('Herhangi bir seviyede sarı yıldız patlat', 'Pop yellow stars in any level'),
  };
  ({String when, String fact}) eventFact(String e) => switch (e) {
    'tulip' => (
      when: _t('LALE DEVRİ · 1718–1730', 'THE TULIP ERA · 1718–1730'),
      fact: _t("İstanbul'da lale bahçeleri, Sadabad köşkleri ve helva sohbetleri moda oldu; nadir lale soğanları servet değerinde alınıp satıldı.", 'Tulip gardens, the Sadabad pavilions and halva gatherings were the fashion in Istanbul; rare bulbs sold for fortunes.'),
    ),
    'ferry' => (
      when: _t('ŞİRKET-İ HAYRİYE · 1851', 'ŞİRKET-İ HAYRİYE · 1851'),
      fact: _t("Boğaz'da düzenli vapur seferlerini başlatan şirket kuruldu; vapurlar kıyıdaki köyleri şehre bağladı.", 'The company that began regular ferries on the Bosphorus was founded; its boats tied the shore villages to the city.'),
    ),
    'hamam' => (
      when: _t('ÇEMBERLİTAŞ · 1584', 'ÇEMBERLİTAŞ · 1584'),
      fact: _t("Mimar Sinan'ın yaptığı Çemberlitaş Hamamı açıldı; kurna, kese ve köpük, şehrin yüzyıllardır süren hamam âdetinin parçasıydı.", "The Çemberlitaş bath, built by Mimar Sinan, opened; basin, scrubbing mitt and foam were part of the city's centuries-old bath ritual."),
    ),
    'dondurma' => (
      when: _t('MARAŞ · SALEP VE SAKIZ', 'MARAŞ · SALEP AND MASTIC'),
      fact: _t('Maraş dondurmasını uzatan, dağ orkidelerinin kökünden yapılan salep ve damla sakızıdır; dondurmacı onu uzun kepçesiyle döndürür.', 'What makes Maraş ice cream stretch is salep, made from the roots of mountain orchids, and mastic; the seller twirls it on his long paddle.'),
    ),
    'mehter' => (
      when: _t('MEHTERHANE · DAVUL VE ZURNA', 'THE MEHTER BAND · DRUM AND ZURNA'),
      fact: _t('Mehter, bilinen en eski askerî bandolardan biridir; davul, zurna, kös ve zilleriyle orduyu yürüyüşte coştururdu.', 'The mehter is one of the oldest known military bands; with drums, zurnas, kettledrums and cymbals it stirred the army on the march.'),
    ),
    'karadeniz' => (
      when: _t('KARADENİZ · KEMENÇE', 'THE BLACK SEA · KEMENÇE'),
      fact: _t('Üç telli Karadeniz kemençesi, yaydan çıkan hızlı ezgisiyle horonu ayağa kaldırır.', 'The three-stringed Black Sea kemençe, with its quick bowed tunes, gets everyone up for the horon dance.'),
    ),
    'bayram' => (
      when: _t('RAMAZAN BAYRAMI · ÜÇ GÜN', 'THE FEAST AFTER RAMADAN · THREE DAYS'),
      fact: _t('Bayramda büyüklerin eli öpülür, çocuklara harçlık ve şeker verilir; misafire lokum ve kolonya ikram edilir.', "At the feast, children kiss their elders' hands and get pocket money and sweets; guests are offered lokum and cologne."),
    ),
    'hidirellez' => (
      when: _t('HIDIRELLEZ · 6 MAYIS', 'HIDIRELLEZ · 6 MAY'),
      fact: _t('Baharın gelişi kutlanır; dilekler gül ağacına bağlanır, ateşin üstünden atlanır.', "Spring's arrival is celebrated: wishes are tied to a rose bush and people leap over a fire."),
    ),
    'coffee' => (
      when: _t('TAHTAKALE · 1554', 'TAHTAKALE · 1554'),
      fact: _t("İstanbul'un ilk kahvehaneleri Tahtakale'de açıldı; kısa sürede sohbetin, tavlanın ve şiirin buluşma yeri oldular.", "Istanbul's first coffeehouses opened in Tahtakale and soon became the place for talk, backgammon and poetry."),
    ),
    _ => (
      when: _t('ÜSKÜDAR · 1593', 'ÜSKÜDAR · 1593'),
      fact: _t('Simit, 1593 tarihli bir Üsküdar kadı sicilinde fiyatıyla birlikte kayda geçmiş; şehrin en eski sokak lezzetlerinden biri.', "Simit appears with its price in an Üsküdar court register of 1593, one of the city's oldest street foods."),
    ),
  };
  String get newUnlock => _t('YENİ ÖZELLİK AÇILDI!', 'SOMETHING NEW!');
  String get tryNow => _t('HEMEN DENE', 'TRY IT NOW');
  String get giftGot => _t('Hediyen', 'Your gift');
  String get giftCollect => _t('TOPLA', 'COLLECT');
  String unlockName(String u) => switch (u) {
    'cubesLokum' => _t('Lokum küpler', 'Lokum cubes'),
    'cubesCini' => _t('Çini küpler', 'Tile cubes'),
    'sceneGalata' => _t('Galata gecesi', 'Galata by night'),
    'sceneSnow' => _t('Karlı Kız Kulesi', "Snowy Maiden's Tower"),
    'sceneIslands' => _t('Adalar baharı', 'Spring on the islands'),
    'sceneCamlica' => _t('Çamlıca gecesi', 'Çamlıca by night'),
    'shuffle' => _t('Karıştır', 'Shuffle'),
    'freeze' => _t('Zamanı Durdur', 'Stop the Clock'),
    'outfitTulipCrown' => _t('Lale tacı', 'Tulip crown'),
    'outfitCaptain' => _t('Vapur kaptanı şapkası', "Ferry captain's cap"),
    'outfitApron' => _t('Kahveci önlüğü', "Coffee maker's apron"),
    'outfitGuide' => _t('Rehber şapkası', "Guide's hat"),
    'outfitLemonCrown' => _t('Altın Limon tacı', 'Golden lemon crown'),
    'floorCini' => _t('Çini katlar', 'Tile floors'),
    'floorMarble' => _t('Mermer katlar', 'Marble floors'),
    'floorGlass' => _t('Cam katlar', 'Glass floors'),
    'floorGold' => _t('Altın katlar', 'Gold floors'),
    'outfitMehter' => _t('Mehter kıyafeti', 'Mehter outfit'),
    'outfitKaradeniz' => _t('Karadeniz kukuletesi', 'Black Sea hood'),
    'outfitHamam' => _t('Hamam takımı', 'Hamam set'),
    'outfitDondurma' => _t('Dondurmacı yeleği', "Ice-cream seller's vest"),
    'outfitHalay' => _t('Halay mendili', 'Halay handkerchief'),
    'outfitYazma' => _t('Oyalı yazma', 'Lace-edged scarf'),
    _ => _t('Simit kolye', 'Simit necklace'),
  };
  String unlockText(String u) => switch (u) {
    'cubesLokum' => _t("Zincir Küpler'de pudra şekerli lokum küpler.", 'Powdered lokum cubes for Chain Blocks.'),
    'cubesCini' => _t("Zincir Küpler'de İznik çinisi görünümü.", 'Iznik tile cubes for Chain Blocks.'),
    'sceneGalata' || 'sceneSnow' || 'sceneIslands' || 'sceneCamlica' => _t('Şeker tahtasının arkasında yeni bir İstanbul manzarası.', 'A new Istanbul scene behind the Sugar Blocks board.'),
    'shuffle' => _t("Şeker'de takıldığında tahtayı karıştırır.", 'Shuffles the Sugar Blocks board when you are stuck.'),
    'freeze' => _t("Zincir'de yükselişi birkaç saniye durdurur.", 'Holds the Chain Blocks stack for a few seconds.'),
    'floorCini' || 'floorMarble' || 'floorGlass' || 'floorGold' => _t("Kule Küpler'de katların yeni görünümü.", 'A new look for the floors of Tower Blocks.'),
    _ => _t("Lokum'un dolabında yeni bir kostüm.", "A new outfit in Lokum's wardrobe."),
  };
  String get collectionTitle => _t('Koleksiyon', 'Collection');
  String get cubeLook => _t('Zincir küpleri', 'Chain Blocks cubes');
  String get sugarSceneLabel => _t('Şeker manzarası', 'Sugar Blocks scene');
  String get towerLookLabel => _t('Kule katları', 'Tower floors');
  String floorLookName(String l) => switch (l) {
    'cini' => _t('Çini', 'Tile'),
    'marble' => _t('Mermer', 'Marble'),
    'glass' => _t('Cam', 'Glass'),
    'gold' => _t('Altın', 'Gold'),
    _ => _t('Lokum', 'Lokum'),
  };
  String cubeStyleName(String s) => switch (s) {
    'lokum' => _t('Lokum', 'Lokum'),
    'cini' => _t('Çini', 'Tile'),
    _ => _t('Canlı', 'Vivid'),
  };
  String get sceneDefault => _t('Bölüme göre', 'By chapter');
  String get postcardsTitle => _t('İstanbul kartpostalları', 'Istanbul postcards');
  String postcardsCount(int got, int all) => '$got / $all';
  String get postcardLocked => _t('Sandıklardan çıkar', 'Found in chests');
  String get freezeLabel => _t('Durdur', 'Stop');
  /// The İstanbul postcards in their sets, each set oldest first.
  ({String title, String when, String fact}) postcard(int i) => switch (i) {
    0 => (title: _t('Yerebatan Sarnıcı', 'The Basilica Cistern'), when: '532', fact: _t('I. Justinianus döneminde yapıldı; tavanını 336 sütun taşır.', 'Built under Justinian I; 336 columns hold up its roof.')),
    1 => (title: _t('Ayasofya', 'Hagia Sophia'), when: '537', fact: _t('I. Justinianus döneminde tamamlandı; dev kubbesiyle yüzyıllarca dünyanın en büyük kapalı mekânlarından biri oldu.', 'Completed under Justinian I; its great dome made it one of the largest interiors in the world for centuries.')),
    2 => (title: _t('Kınalıada', 'Kınalıada'), when: '1072', fact: _t("Tahttan indirilen IV. Romanos Diogenes buraya sürgün edildi; adalara Prens Adaları denmesi bu sürgünlerden gelir.", "Deposed Romanos IV Diogenes was exiled here; such exiles gave the Princes' Islands their name.")),
    3 => (title: _t('Galata Kulesi', 'Galata Tower'), when: '1348', fact: _t('Cenevizliler yaptı; Osmanlı döneminde yangın gözcülerinin kulesi oldu.', "Built by the Genoese; in Ottoman times it was the fire watchmen's tower.")),
    4 => (title: _t('Rumeli Hisarı', 'Rumeli Fortress'), when: '1452', fact: _t("II. Mehmed, Boğaz'ı denetlemek için hisarı yaklaşık dört ayda yaptırdı.", 'Mehmed II had the fortress built in about four months to command the Bosphorus.')),
    5 => (title: _t('Karadan yürüyen gemiler', 'Ships over the hills'), when: '1453', fact: _t("Haliç'in ağzı zincirle kapatılınca Osmanlı gemileri bir gecede karadan yürütülerek Haliç'e indirildi.", 'With the Golden Horn chained shut, Ottoman ships were hauled overland in a night and launched into it.')),
    6 => (title: _t('Cevahir Bedesteni', 'The Cevahir Bedesten'), when: '1461', fact: _t("Kapalıçarşı'nın kalbi; değerli mallar burada korunur, kapılar her akşam kilitlenirdi.", 'The heart of the Grand Bazaar: valuables were kept here and the gates were locked every evening.')),
    7 => (title: _t('İlk kahvehaneler', 'The first coffeehouses'), when: '1554', fact: _t("İstanbul'un ilk kahvehaneleri Tahtakale'de açıldı; sohbetin, tavlanın ve şiirin buluşma yeri oldular.", "Istanbul's first coffeehouses opened in Tahtakale and became the place for talk, backgammon and poetry.")),
    8 => (title: _t('Süleymaniye', 'The Süleymaniye'), when: '1557', fact: _t("Mimar Sinan'ın eseri; külliyesiyle birlikte 1557'de tamamlandı ve şehrin siluetinin simgesi oldu.", "Mimar Sinan's work, completed with its complex in 1557; it became the emblem of the skyline.")),
    9 => (title: _t('Simit', 'Simit'), when: '1593', fact: _t('1593 tarihli bir Üsküdar kadı sicilinde fiyatıyla birlikte kayda geçmiş; şehrin en eski sokak lezzetlerinden biri.', "Recorded with its price in an Üsküdar court register of 1593, one of the city's oldest street foods.")),
    10 => (title: _t('Donan Boğaz', 'The frozen Bosphorus'), when: '1621', fact: _t("O kış Boğaz dondu; kaynaklar, Üsküdar'dan karşıya buzun üstünde yüründüğünü yazar.", 'That winter the Bosphorus froze; chroniclers write that people walked across from Üsküdar.')),
    11 => (title: _t('Mısır Çarşısı', 'The Spice Bazaar'), when: '1660–1664', fact: _t('Yeni Cami külliyesinin parçası olarak tamamlandı; adını yapımına ayrılan Mısır gelirlerinden alır.', 'Completed as part of the New Mosque complex; named for the Egyptian revenues set aside to build it.')),
    12 => (title: _t('Lale Devri', 'The Tulip Era'), when: '1718–1730', fact: _t("Lale bahçeleri ve helva sohbetleri İstanbul'un modası oldu; nadir lale soğanları servet değerindeydi.", 'Tulip gardens and halva gatherings were the fashion; rare bulbs were worth fortunes.')),
    13 => (title: _t('Galata Köprüsü', 'The Galata Bridge'), when: '1845', fact: _t("Haliç'in iki yakasını bağlayan ilk Galata Köprüsü açıldı; köprü o günden beri birkaç kez yenilendi.", 'The first Galata Bridge joined the two shores of the Golden Horn; it has been rebuilt several times since.')),
    15 => (title: _t('Kalkedon', 'Chalcedon'), when: _t('MÖ 685', '685 BC'), fact: _t("Megaralılar Kadıköy'e Bizantion'dan 17 yıl önce yerleşti. Herodot'a göre karşı kıyıyı seçmedikleri için onlara 'körler' dendi.", 'Megarians settled at Kadıköy 17 years before Byzantion. Herodotus says they were called blind for missing the better shore opposite.')),
    16 => (title: _t('Balat', 'Balat'), when: '1492', fact: _t("İspanya'dan sürülen Sefarad Yahudileri II. Bayezid'in kabulüyle Balat'a yerleşti; Rum, Ermeni ve Yahudi mahalleleri yan yana yaşadı.", 'Sephardic Jews driven out of Spain settled in Balat, received by Bayezid II; Greek, Armenian and Jewish quarters lived side by side.')),
    17 => (title: _t('Ortaköy Camii', 'The Ortaköy Mosque'), when: '1856', fact: _t("Sultan Abdülmecid'in yaptırdığı Büyük Mecidiye Camii, Garabet ve oğlu Nigoğos Balyan'ın eseri; suyun hemen kıyısında durur.", 'The Grand Mecidiye Mosque, built for Sultan Abdülmecid by Garabet Balyan and his son Nigoğos, stands right at the water.')),
    18 => (title: _t('Sühulet', 'The Sühulet'), when: '1872', fact: _t("Şirket-i Hayriye'nin Sühulet'i Kabataş ile Üsküdar arasında at arabalarını taşıdı; dünyanın ilk araba vapurlarından biri.", "Şirket-i Hayriye's Sühulet carried horse carts between Kabataş and Üsküdar, one of the world's first car ferries.")),
    19 => (title: _t('Tünel', 'The Tünel'), when: '1875', fact: _t("Karaköy'den Beyoğlu'na tırmanan Tünel, Londra'dan sonra dünyanın en eski ikinci yeraltı hattı.", "Climbing from Karaköy to Beyoğlu, the Tünel is the world's second oldest underground line, after London's.")),
    _ => (title: _t('Şirket-i Hayriye', 'Şirket-i Hayriye'), when: '1851', fact: _t("Boğaz'da düzenli vapur seferlerini başlatan şirket kuruldu; vapurlar kıyı köylerini şehre bağladı.", 'The company that began regular Bosphorus ferries was founded; its boats tied the shore villages to the city.')),
  };
  String postcardSet(int i) => switch (i) {
    0 => _t('Fetihten önce', 'Before the conquest'),
    1 => _t('Fetih ve çarşılar', 'Conquest and bazaars'),
    2 => _t("Boğaz'ın yüzyılları", 'Centuries of the Bosphorus'),
    _ => _t('İki yakanın hikâyeleri', 'Tales of the two shores'),
  };
  String get setClaim => _t('SET ÖDÜLÜ', 'SET PRIZE');
  String get setDone => _t('Tamamlandı', 'Complete');
  String get albumHint => _t('Bölüm sonları, etkinlikler ve sandıklar kart verir. Bütün setleri tamamla, rehber şapkası senin olsun.', 'Chapter ends, events and chests give cards. Complete every set for the guide\'s hat.');
  String newPostcard(String title) => _t('Yeni kartpostal: $title', 'New postcard: $title');
  String get tipDidYouKnow => _t('Biliyor muydun?', 'Did you know?');
  String get tipSeeCard => _t('Kartı gör', 'See the card');
  String chapterCardHint(int chapter) => _t('Bölümü bitir, kartını al', 'Finish the chapter for its card');
  // Lokum's wardrobe.
  String get wardrobeTitle => _t("LOKUM'UN DOLABI", "LOKUM'S WARDROBE");
  String get wardrobeShort => _t('Dolap', 'Wardrobe');
  String get wardrobeHint => _t("Şeker Küpler'de yıldız topla, yeni kostümler açılsın. Lokum seçtiğini her yerde giyer.", 'Collect stars in Sugar Blocks to unlock outfits. Lokum wears your pick everywhere.');
  String get outfitWorn => _t('GİYİLİ', 'WEARING');
  String get close => _t('Kapat', 'Close');
  String get outfitWear => _t('Giy', 'Wear');
  String get outfitEvent => _t('Etkinlik ödülü', 'Event prize');
  String starsCount(int n) => _t('$n yıldız', '$n stars');
  String outfitName(String name) => switch (name) {
    'fez' => _t('Fes', 'Fez'),
    'tulip' => _t('Lale', 'Tulip'),
    'nazar' => _t('Nazar boncuğu', 'Evil-eye bead'),
    'moustache' => _t('Pala bıyık', 'Grand moustache'),
    'simit' => _t('Simitçi tablası', 'Simit tray'),
    'kalpak' => _t('Kalpak', 'Kalpak'),
    'janissary' => _t('Yeniçeri börkü', 'Janissary börk'),
    'sultan' => _t('Padişah kavuğu', "Sultan's turban"),
    'tulipCrown' => _t('Lale tacı', 'Tulip crown'),
    'captain' => _t('Kaptan şapkası', "Captain's cap"),
    'apron' => _t('Kahveci önlüğü', "Coffee apron"),
    'simitNecklace' => _t('Simit kolye', 'Simit necklace'),
    'guide' => _t('Rehber şapkası', "Guide's hat"),
    'lemonCrown' => _t('Altın Limon tacı', 'Golden lemon crown'),
    'zeybek' => _t('Zeybek börkü', 'Zeybek börk'),
    'hoca' => _t('Hoca kavuğu', "Nasreddin Hoca's kavuk"),
    'mehter' => _t('Mehter kıyafeti', 'Mehter outfit'),
    'karadeniz' => _t('Kukulete ve kemençe', 'Black Sea hood and kemençe'),
    'hamam' => _t('Hamam takımı', 'Hamam set'),
    'dondurma' => _t('Maraş dondurmacısı', 'Maraş ice-cream seller'),
    'halay' => _t('Halay mendili', 'Halay handkerchief'),
    'yazma' => _t('Oyalı yazma', 'Lace-edged scarf'),
    _ => _t('Kostümsüz', 'No outfit'),
  };
  String outfitUnlocked(String name) => _t('Yeni kostüm: ${outfitName(name)}!', 'New outfit: ${outfitName(name)}!');
  String get badgeContinue => _t('DEVAM', 'CONTINUE');
  String bestLine(String score) => _t('Rekor $score', 'Best $score');
  String starsLine(int got, int all) => _t('$got / $all yıldız', '$got / $all stars');
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
  String get changeMode => _t('Oyun değiştir', 'Change game');
  String get modesTitle => _t('Oyunlar', 'Games');
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
  // ------------------------------------------------------- kule küpler
  String get towerTitle => _t('Kule Küpler', 'Tower Blocks');
  String get towerGroup => _t('KULE', 'TOWER');
  String get towerBlurb => _t('Lokum katları diz, kuleyi yükselt', 'Stack lokum floors, raise the tower');
  String get towerClimbTitle => _t('Tırmanış', 'The Climb');
  String get towerClimbSubtitle => _t('Bulutları aş, yıldızlara uzan', 'Past the clouds, up to the stars');
  String get towerWindTitle => _t('Rüzgâr', 'Wind');
  String get towerWindSubtitle => _t('Kat esintiyle hızlanıp yavaşlar', 'The floor speeds up and slows in the gusts');
  String get towerDailyTitle => _t('Günün Kulesi', "Today's Tower");
  String get towerDailySubtitle => _t('Herkese aynı kule, üç deneme', 'The same tower for all, three tries');
  String get towerBuildTitle => _t("İstanbul'u İnşa Et", 'Build Istanbul');
  String get towerBuildSubtitle => _t('Her kat bir kuleyi yükseltir', 'Every floor raises a landmark');
  String get towerFloorWord => _t('KAT', 'FLOOR');
  String get towerPerfect => _t('MÜKEMMEL!', 'PERFECT!');
  String get towerGrew => _t('Kat genişledi!', 'Floor grew!');
  String towerFloorShout(int n) => _t('$n. KAT!', 'FLOOR $n!');
  String towerStreak(int n) => _t('MÜKEMMEL ×$n', 'PERFECT ×$n');
  String towerNextChest(int n) => _t('Sıradaki sandık: $n. kat', 'Next chest: floor $n');
  String get towerTapHint => _t('Dokun, katı bırak', 'Tap to drop the floor');
  String floorsLine(int n) => _t('${score(n)} kat', n == 1 ? '1 floor' : '${score(n)} floors');
  String towerChestTitle(int n) => _t('$n. kat sandığı', 'Floor $n chest');
  String get towerOverTitle => _t('Kule durdu!', 'The tower stopped!');
  String get towerRevive => _t('Devam et (1 hak)', 'Keep going (once)');
  String towerToBuild(int n, String landmark) => _t('$landmark için +${score(n)} kat', '+${score(n)} floors for $landmark');
  String towerTriesLeft(int n) => _t('Bugün $n deneme kaldı', n == 1 ? '1 try left today' : '$n tries left today');
  String get towerNoTries => _t('Bugünlük bitti, yarın yeni kule', "That's all for today; a new tower tomorrow");
  String get towerBuildIntro => _t('Her oyunda koyduğun katlar buraya eklenir.', 'Every floor of every run is added here.');
  String towerLeft(int n) => _t('$n kat kaldı', n == 1 ? '1 floor to go' : '$n floors to go');
  String get towerAllDone => _t('Bütün İstanbul kuruldu!', 'All of Istanbul is built!');
  String get landmarksLabel => _t('KULELER', 'LANDMARKS');
  String totalFloors(int n) => _t('Toplam ${score(n)} kat', 'All told ${score(n)} floors');
  String landmarkDone(String name) => _t('$name tamamlandı!', '$name is finished!');
  String get towerPlay => _t('KULEYE ÇIK', 'CLIMB');
  String landmarkName(String l) => switch (l) {
    'galata' => _t('Galata Kulesi', 'Galata Tower'),
    'maidens' => _t('Kız Kulesi', "Maiden's Tower"),
    'rumeli' => _t('Rumeli Hisarı', 'Rumeli Fortress'),
    'beyazit' => _t('Beyazıt Kulesi', 'Beyazıt Tower'),
    'dolmabahce' => _t('Dolmabahçe Saat Kulesi', 'Dolmabahçe Clock Tower'),
    'haydarpasa' => _t('Haydarpaşa Garı', 'Haydarpaşa Station'),
    'selimiye' => _t('Selimiye Kışlası', 'Selimiye Barracks'),
    _ => _t('Çamlıca Kulesi', 'Çamlıca Tower'),
  };
  String landmarkPart(String l, int i) => (switch (l) {
    'galata' => _t('Taban|Gövde|Seyir terası|Külah|Alem', 'Base|Body|Viewing gallery|Cone roof|Finial'),
    'maidens' => _t('Ada ve rıhtım|Taş gövde|Balkon|Kubbe|Fener ve bayrak', 'Islet and quay|Stone body|Balcony|Dome|Lantern and flag'),
    'rumeli' => _t('Surlar|Küçük kule|Büyük kule|Burçlar|Külahlar', 'Walls|Small tower|Great tower|Battlements|Cone roofs'),
    'beyazit' => _t('Kaide|Taş gövde|Üst gövde|Gözetleme köşkü|Külah', 'Plinth|Stone body|Upper body|Watch room|Cone roof'),
    'dolmabahce' => _t('Kaide|Gövde|Saat katı|Kubbe|Alem', 'Plinth|Body|Clock floor|Dome|Finial'),
    'haydarpasa' => _t('Rıhtım|Bina|Sol kule|Sağ kule|Çatılar', 'Quay|Building|Left tower|Right tower|Roofs'),
    'selimiye' => _t('Avlu|Ana bina|Köşe kuleleri|Çatılar|Bayrak', 'Courtyard|Main building|Corner towers|Roofs|Flag'),
    _ => _t('Tepe|Gövde|Seyir katı|Üst gövde|Anten', 'Hill|Shaft|Viewing deck|Upper shaft|Antenna'),
  }).split('|')[i];

  String get mainModeTag => _t('ANA MOD', 'MAIN MODE');
  String get moreModesLabel => _t('DİĞER MODLAR', 'MORE MODES');
  String get calmLabel => _t('SAKİN', 'CALM');
  String linesTag(int n) => _t('$n satır', '$n lines');
  String modeCount(int n) => _t('$n mod', n == 1 ? '1 mode' : '$n modes');
  String lastPlayedShort(String mode) => _t('Son: $mode', 'Last: $mode');
  String get sugarBlurb => _t("Eşleştir, patlat, İstanbul'u gez", 'Match, pop and tour Istanbul');
  String get chainBlurb => _t('Kaydır, zincir kur, rakibini yen', 'Swap, chain and beat your rival');
  String get puzzleBlurb => _t('Parçaları yerleştir, satır temizle', 'Place pieces, clear lines');
  String get classicBlurb => _t('Düşen bloklar, klasik kurallar', 'Falling blocks, classic rules');

  // ------------------------------------------------------- zincir küpler
  /// The app's name and what it is.
  /// The app's name; the mascot keeps his own, Lokum.
  static const String appTitle = 'Küpler';
  String get appName => appTitle;
  String get appTagline => _t('Şeker ve Blok Oyunları', 'Sweets & Block Games');
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
  // The first mission's lesson, and the card before the chain missions.
  String chainLesson(String step) => switch (step) {
    'swap' => _t('Sarıyı sağa kaydır, bakalım ne olacak!', 'Slide the yellow right and see!'),
    'fall' => _t('Maviler gitti; üstteki sarı düşüyor...', 'The blues are gone; the yellow above falls...'),
    _ => _t('İşte zincir! Düşen küp yeniden eşleşti.', "That's a chain! The falling cube matched again."),
  };
  String get chainHowTitle => _t('Zincir nasıl yapılır?', 'How to make a chain');
  String get chainHowStep1 => _t('Eşleştir', 'Make a match');
  String get chainHowStep2 => _t('Üstteki küp düşer', 'The cube above falls');
  String get chainHowStep3 => _t('Yeniden eşleşirse ×2!', 'It matches again: ×2!');
  String get chainHowKeys => _t('Oklar: imleç · Boşluk: takas · Shift: yükselt', 'Arrows: cursor · Space: swap · Shift: raise');
  String get chainStart => _t('BAŞLA', 'START');
  String get chainRaise => _t('Yükselt', 'Raise');
  String chainLongest(int n) => _t('En uzun zincir ×$n', 'Longest chain ×$n');
  String chainCubes(int n) => _t('$n küp patlattın', '$n cubes cleared');

  // Zincir: the ferry line, puzzles, the match against Ekşi Limon.
  String get chainMissionsTitle => _t('Vapur Hattı', 'Ferry Line');
  String get chainMissionsSubtitle => _t('Boğaz iskelelerinde görevler', 'Missions along the Bosphorus piers');
  String get chainPuzzlesTitle => _t('Bulmacalar', 'Puzzles');
  String get chainPuzzlesSubtitle => _t('Hazır tahtayı az hamlede temizle', 'Clear a set board in a few swaps');
  String get chainVersusTitle => _t("Limon'a Karşı", 'Versus Lemon');
  String get chainVersusSubtitle => _t('Bilgisayara karşı maç', 'A match against the computer');
  String missionLabel(int n) => _t('GÖREV $n', 'MISSION $n');
  String pierMissions(int first) => _t('Görev $first–${first + 4}', 'Missions $first–${first + 4}');
  String missionText(ChainMission m) {
    final secs = m.seconds.round();
    if (m.number == 1 && m.kind == MissionKind.chain) return _t("Lokum'un gösterdiği küpü kaydır", 'Slide the cube Lokum shows');
    return switch (m.kind) {
      MissionKind.chain => m.count == 1
          ? _t('$secs saniyede ×${m.target} zincir yap', 'Make a ×${m.target} chain in $secs s')
          : _t('$secs saniyede ${m.count} kez ×${m.target} zincir yap', 'Make ${m.count} ×${m.target} chains in $secs s'),
      MissionKind.score => _t('$secs saniyede ${score(m.target)} puan yap', 'Score ${score(m.target)} in $secs s'),
      MissionKind.garbage => _t('$secs saniyede ${m.target} kare çöp kır', 'Break ${m.target} garbage cells in $secs s'),
      MissionKind.survive => _t('$secs saniye tavana değmeden dayan', 'Keep off the top for $secs s'),
      MissionKind.puzzle => _t('Bulmaca ${m.target}: tahtayı temizle', 'Puzzle ${m.target}: clear the board'),
      MissionKind.versus => _t('${rivalName(m.target)} rakibini yen', 'Beat ${rivalName(m.target)}'),
    };
  }

  String missionProgress(int p, int t) => '$p / $t';
  String get missionGoal => _t('HEDEF', 'GOAL');
  String get missionDone => _t('GÖREV TAMAM!', 'MISSION DONE!');
  String get missionMissed => _t('OLMADI', 'NOT THIS TIME');
  String get missionPlay => _t('OYNA', 'PLAY');
  String pierDone(String pier) => _t('$pier iskelesi tamam!', '$pier pier done!');
  String get missionsAllDone => _t('Bütün iskeleler tamam! Yıldızları topla.', 'Every pier done! Go for the stars.');
  String prizeLine(String items) => _t('Ödül: $items', 'Prize: $items');
  String freezesCount(int n) => _t('Zamanı Durdur ×$n', 'Stop the Clock ×$n');
  String get europe => _t('AVRUPA', 'EUROPE');
  String get asia => _t('ASYA', 'ASIA');
  String puzzleLabel(int n) => _t('BULMACA $n', 'PUZZLE $n');
  String puzzleGoal(int moves) => moves == 1 ? _t('Tahtayı tek hamlede temizle', 'Clear the board in one swap') : _t('Tahtayı $moves hamlede temizle', 'Clear the board in $moves swaps');
  String get puzzleSolved => _t('ÇÖZÜLDÜ!', 'SOLVED!');
  String get puzzleFailed => _t('HAMLE BİTTİ', 'OUT OF SWAPS');
  String get puzzleHow => _t('Küpler yükselmez, süre işlemez; her kaydırma bir hamle.', 'Nothing rises and no clock runs; every swap is one move.');
  String get puzzleSwaps => _t('HAMLE', 'SWAPS');
  String get undo => _t('Geri al', 'Undo');
  String get hint => _t('İpucu', 'Hint');
  String get restartShort => _t('Baştan', 'Restart');
  String get nextOne => _t('Sonraki', 'Next');
  String get puzzlesHow => _t('Süre yok, yükselme yok; sadece düşün', 'No clock, no rising; just think');
  String packName(int i) => switch (i) {
    0 => 'Eminönü',
    1 => _t('Haliç', 'Golden Horn'),
    2 => 'Galata',
    _ => _t('Boğaziçi', 'Bosphorus'),
  };
  String packLevel(int i) => switch (i) {
    0 => _t('Çırak', 'Apprentice'),
    1 => _t('Kalfa', 'Journeyman'),
    2 => _t('Usta', 'Master'),
    _ => _t('Zincir ustası', 'Chain master'),
  };
  String get packLocked => _t('Önceki paketi bitir, açılsın', 'Finish the pack before to open it');
  String get packBebek => _t("Vapur Hattı'nda Bebek'e varınca açılır", 'Opens when the ferry line reaches Bebek');
  String rivalName(int i) => switch (i) {
    0 => _t('Limon Çırak', 'Lemon Apprentice'),
    1 => _t('Limon Kalfa', 'Lemon Journeyman'),
    _ => _t('Ekşi Limon', 'Sour Lemon'),
  };
  String rivalText(int i) => switch (i) {
    0 => _t('Kolay · yavaş düşünür, zincir kurmaz', 'Easy · slow, never builds chains'),
    1 => _t('Orta · ×2 zincirler kurar', 'Medium · builds ×2 chains'),
    _ => _t('Usta · hızlıdır, zincirle saldırır', 'Master · fast, attacks with chains'),
  };
  String rivalPrize(int i) => switch (i) {
    0 => _t('İlk galibiyet: Lokum küpler', 'First win: lokum cubes'),
    1 => _t('İlk galibiyet: Çini küpler', 'First win: İznik tile cubes'),
    _ => _t('İlk galibiyet: Altın Limon tacı', 'First win: the golden lemon crown'),
  };
  String rivalWins(int n) => n == 0 ? _t('henüz galibiyet yok', 'no wins yet') : _t('$n galibiyet', n == 1 ? '1 win' : '$n wins');
  String get versusPick => _t('Rakibini seç', 'Pick your rival');
  String get versusHow => _t('Zincirler ve kombolar rakibe çöp bloğu yollar. Tavana ilk değen seti kaybeder; 3 setin 2\'sini alan kazanır.', 'Chains and combos send garbage across. The first to stay at the top loses the set; best of three.');
  String get versusYou => _t('SEN', 'YOU');
  String get setLabel => _t('SET', 'SETS');
  String versusIncoming(int n) => _t('geliyor: $n kare', 'incoming: $n cells');
  String get setWon => _t('SETİ ALDIN!', 'SET TO YOU!');
  String get setLost => _t("SET LİMON'UN", 'SET TO LEMON');
  String get matchWon => _t('MAÇI KAZANDIN!', 'YOU WON THE MATCH!');
  String get matchLost => _t('LİMON KAZANDI', 'LEMON WON');
  String get nextSet => _t('Sonraki set', 'Next set');
  String get rematch => _t('Rövanş', 'Rematch');
  String get startMatch => _t('MAÇA BAŞLA', 'START THE MATCH');
  String get otherRival => _t('Başka rakip', 'Another rival');

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
  String lokumSurprise(String what) => _t("Lokum'un sürprizi: $what", "Lokum's surprise: $what");
  String jarGained(int n) => _t('Kavanoza +$n şeker', '+$n sweets in the jar');
  String eventGained(String event, int n) => '$event +$n';
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
  String sugarChapter(int n) => '${chapterLabel(n)} · ${chapterPlace(n)}';
  String chapterLabel(int n) => _t('BÖLÜM ${n + 1}', 'CHAPTER ${n + 1}');

  /// Where in İstanbul chapter [n] (0-based) is set.
  String chapterPlace(int n) => switch (n) {
    0 => 'Eminönü',
    1 => _t('Kız Kulesi', "Maiden's Tower"),
    2 => _t('Rumeli Hisarı', 'Rumeli Fortress'),
    3 => _t('Kapalıçarşı', 'Grand Bazaar'),
    4 => 'Galata',
    5 => _t('Adalar', "Princes' Islands"),
    6 => 'Kadıköy',
    7 => 'Ortaköy',
    8 => _t('Boğaz Vapuru', 'The Bosphorus ferry'),
    9 => _t('İstiklal', 'İstiklal Avenue'),
    10 => 'Balat',
    11 => _t('Çamlıca Tepesi', 'Çamlıca Hill'),
    12 => 'Salacak',
    13 => _t('Haydarpaşa', 'Haydarpaşa Station'),
    14 => _t('Karaköy İskelesi', 'Karaköy Pier'),
    15 => 'Kuzguncuk',
    16 => _t('Dolmabahçe', 'Dolmabahçe Palace'),
    _ => 'Anadolu Kavağı',
  };

  /// The story card of chapter [n]: when and where, what happened there
  /// (history), then Ekşi Limon's move and Lokum's answer.
  ({String when, String history, String limon, String lokum}) chapterStory(int n) => switch (n) {
    0 => (
      when: _t('1777 · Bahçekapı', '1777 · Bahçekapı'),
      history: _t(
        "Mısır Çarşısı'nın birkaç adım ötesinde açılan bir şekerci dükkânı, lokumu İstanbul'un simgesi yaptı. Bu gece o dükkânın iki yüz yıllık tarif defteri çalındı.",
        'A few steps from the Spice Bazaar, a confectioner opened a shop that made lokum the symbol of Istanbul. Tonight its two-hundred-year-old book of recipes was stolen.',
      ),
      limon: _t("Defter artık bende. İstanbul'un tatlısını sayfa sayfa ekşiteceğim; ilk durak bu çarşı.", "The book is mine now. I'll sour Istanbul's sweets page by page, starting with this bazaar."),
      lokum: _t('Bu çarşıyı avucumun içi gibi bilirim. Hadi şekerleri kurtaralım, izini de kaybetmeyelim.', 'I know every corner of this bazaar. Save the sweets and we keep on his trail.'),
    ),
    1 => (
      when: _t('1621 · Üsküdar', '1621 · Üsküdar'),
      history: _t(
        "O kış Boğaz dondu; kaynaklar, halkın Üsküdar'dan karşı kıyıya buzun üstünde yürüyerek geçtiğini yazar. Efsaneye göre Kız Kulesi, kehanetten saklanan bir prensesin sığınağıydı.",
        "That winter the Bosphorus froze; chroniclers write that people walked across the ice from Üsküdar. Legend says the Maiden's Tower once hid a princess from a prophecy.",
      ),
      limon: _t('Buz bu şehrin tarihini bir kez yazdı, bir kez daha yazacak. Kuleye giden her yolu donduruyorum.', "Ice wrote this city's history once and it will again. I'm freezing every way to the tower."),
      lokum: _t("1621'de de buz çözülmüştü, bu da çözülür. Buzlu kareleri kır, kuleye varalım.", "The ice of 1621 melted too. Crack the icy squares and we'll reach the tower."),
    ),
    2 => (
      when: _t('1452 · Rumeli Hisarı', '1452 · Rumeli Fortress'),
      history: _t(
        "II. Mehmed, Boğaz'ı denetlemek için hisarı yaklaşık dört ayda yükseltti. Ertesi bahar Bizans, Haliç'in ağzını dev bir demir zincirle kapattı.",
        'Mehmed II raised the fortress in about four months to command the Bosphorus. The next spring Byzantium closed the Golden Horn with a great iron chain.',
      ),
      limon: _t('Zincirin hikâyesini ben de bilirim. Şekerleri tek tek bağladım; hiçbiri yerinden kıpırdamayacak.', "I know the story of the chain too. I've bound the sweets one by one; not one will move."),
      lokum: _t('O zinciri de aşmışlardı: gemileri bir gecede karadan yürüttüler. Zincirleri kır, yol açılsın.', 'That chain was beaten too: ships were hauled overland in a single night. Break the chains and clear the way.'),
    ),
    3 => (
      when: _t('1461 · Kapalıçarşı', '1461 · Grand Bazaar'),
      history: _t(
        'Çarşının kalbi Cevahir Bedesteni, fetihten kısa süre sonra yapıldı. Mücevherler ve değerli kumaşlar burada korunur, kapılar her akşam kilitlenirdi.',
        'The heart of the bazaar, the Cevahir Bedesten, was built soon after the conquest. Jewels and fine cloth were kept here and the gates were locked every evening.',
      ),
      limon: _t('Şekerleri bedestenin sandıklarına kilitledim. Bu labirentte kimse yolunu bulamaz.', "I've locked the sweets in the bedesten's chests. Nobody finds their way in this maze."),
      lokum: _t('Kutunun yanında eşleştirirsen kilit açılır. Defterin bir sayfası da burada olmalı.', 'Match beside a box and the lock gives way. A page of the book must be here too.'),
    ),
    4 => (
      when: _t('1348 · Galata', '1348 · Galata'),
      history: _t(
        'Cenevizlilerin yaptığı kule, Osmanlı döneminde yangın gözcülerinin yeri oldu. Şehirde duman görülünce kuleden işaret verilir, mahalleler uyarılırdı.',
        'Built by the Genoese, the tower became the post of fire watchmen in Ottoman times. When smoke rose over the city a signal went out from the top.',
      ),
      limon: _t("Galata'nın her köşesine saatli bombalar kurdum. Gözcüler bile yetişemez.", 'I set time bombs all over Galata. Not even the watchmen will keep up.'),
      lokum: _t('Gözcü gibi düşün: önce sayısı en küçük olanı söndür. Süre dolmadan!', 'Think like a watchman: put out the lowest count first. Before time runs out!'),
    ),
    5 => (
      when: _t('1072 · Kınalıada', '1072 · Kınalıada'),
      history: _t(
        "Tahttan indirilen Bizans imparatoru IV. Romanos Diogenes buraya sürgün edildi. Adaların 'Prens Adaları' diye anılması, böyle sürgünlerin yeri olmalarından gelir.",
        "Deposed Byzantine emperor Romanos IV Diogenes was exiled here. The islands are called the Princes' Islands because they were where such exiles were sent.",
      ),
      limon: _t('Ben sürgüne gitmem, kaçarım. Adaların gökkuşağını da yanıma alıyorum!', "I don't get exiled, I escape. And I'm taking the islands' rainbow with me!"),
      lokum: _t('Renkleri gökkuşağı toplarıyla geri alırız. Defterin son sayfaları onda, peşini bırakmıyoruz.', "We'll win the colours back with rainbow balls. He has the book's last pages; we don't let go."),
    ),
    6 => (
      when: _t('MÖ 685 · Kalkedon', '685 BC · Chalcedon'),
      history: _t(
        "Megaralılar Kadıköy'e, Bizantion'dan 17 yıl önce yerleşti. Herodot'un aktardığına göre Pers komutanı Megabazos, karşıdaki yarımadayı bırakıp bu kıyıyı seçtikleri için onlara 'körler' demişti.",
        'Megarians settled at Kadıköy 17 years before Byzantion was founded. Herodotus tells how the Persian general Megabazus called them blind for choosing this shore over the peninsula opposite.',
      ),
      limon: _t('Körler kıyısı, öyle mi? Bu yakanın şekerlerini acı kakaoyla kaplıyorum; her hamlede biraz daha yayılacak.', "The shore of the blind, is it? I'm coating this side's sweets in bitter cocoa, and it spreads with every move."),
      lokum: _t('Biz iki yakayı da görürüz. Çikolatanın yanında eşleştir, her hamlede birini kır ki yayılmasın.', "We see both shores. Match beside the chocolate and break some every move, so it can't spread."),
    ),
    7 => (
      when: _t('1856 · Ortaköy', '1856 · Ortaköy'),
      history: _t(
        "Sultan Abdülmecid, Ortaköy iskelesinin hemen yanına Büyük Mecidiye Camii'ni yaptırdı. Mimarları Dolmabahçe Sarayı'nı da yapan Garabet Balyan ile oğlu Nigoğos'tu; cami suya o kadar yakındır ki dalgalar avlusunun dibine vurur.",
        'Sultan Abdülmecid had the Grand Mecidiye Mosque built beside the Ortaköy pier. Its architects were Garabet Balyan and his son Nigoğos, who also built Dolmabahçe Palace; it stands so close to the water that waves break at its courtyard.',
      ),
      limon: _t('Defterdeki nar şerbeti tarifinin narlarını tahtanın tepesine sakladım. Aşağı inemeyecekler.', "I've hidden the pomegranates for the book's sherbet at the top of the board. They'll never come down."),
      lokum: _t('Narlar şekerle birlikte düşer. Altlarında eşleştir, en alt sıraya inince bizimdir.', 'Pomegranates fall with the sweets. Match below them; once they reach the bottom row they are ours.'),
    ),
    8 => (
      when: _t('1872 · Sühulet', '1872 · The Sühulet'),
      history: _t(
        "Şirket-i Hayriye'nin Sühulet vapuru, Kabataş ile Üsküdar arasında at arabalarını güvertesinde taşımaya başladı. Tasarımı şirketin müdürü Giritli Hüseyin Haki Efendi'nindi; dünyanın ilk araba vapurlarından biri sayılır.",
        "Şirket-i Hayriye's ferry Sühulet began carrying horse carts on its deck between Kabataş and Üsküdar. It was designed by the company's director Hüseyin Haki Efendi and counts among the world's first car ferries.",
      ),
      limon: _t('Vapurun güvertesini ele geçirdim. Şekerleri bantlara dizdim; her hamlede kayıp gidecekler.', "I've taken the ferry's deck. The sweets are on the belts now, and they slide away with every move."),
      lokum: _t('Bant her hamleden sonra bir kare kayar. Şekerin nereye gideceğini kestir; bazen eşleşme kendiliğinden gelir.', 'The belt moves one cell after every move. Think where the sweets will land; sometimes the match comes by itself.'),
    ),
    9 => (
      when: _t('1875 · Tünel', '1875 · The Tünel'),
      history: _t(
        "Karaköy'den Beyoğlu'na tırmanan Tünel açıldı. Londra'dan sonra dünyanın en eski ikinci yeraltı hattıdır; yokuşu bir buçuk dakikada çıkar. Hemen yukarıdaki Cadde-i Kebir, bugünkü İstiklal, pastaneleriyle ünlendi.",
        "The Tünel opened, climbing from Karaköy to Beyoğlu. It is the world's second oldest underground line, after London's, and takes the hill in a minute and a half. The Grande Rue above, today's İstiklal, grew famous for its patisseries.",
      ),
      limon: _t('Caddenin pastalarını kat kat dizdim, şekerlerin önüne yığdım. Bakalım kaç katını yiyebileceksin.', "I've stacked the avenue's cakes tier upon tier in front of the sweets. Let's see how many tiers you can eat."),
      lokum: _t('Pastanın yanında her eşleşme bir katını yer. Son kat da gidince yerinden paketli şeker çıkar!', 'Every match beside a cake eats a tier. When the last one goes, a wrapped sweet appears in its place!'),
    ),
    10 => (
      when: _t('1492 · Balat', '1492 · Balat'),
      history: _t(
        "İspanya'dan sürülen Sefarad Yahudileri, II. Bayezid'in kabulüyle İstanbul'a geldi; birçoğu Haliç kıyısındaki Balat'a yerleşti. Rum, Ermeni ve Yahudi mahalleleri yüzyıllarca yan yana yaşadı; renkli cumbalı evler bugün de yokuşları süsler.",
        'Sephardic Jews driven out of Spain came to Istanbul, received by Bayezid II, and many settled in Balat on the Golden Horn. Greek, Armenian and Jewish quarters lived side by side for centuries; colourful bay-windowed houses still line its hills.',
      ),
      limon: _t("Balat'ın renkli kapılarını kilitledim. Her biri yalnız kendi rengini tanır; anahtarlar bende.", "I've locked Balat's coloured doors. Each knows only its own colour, and I have the keys."),
      lokum: _t('Anahtara ne gerek var! Kapının yanında onun renginde bir eşleşme yap, kapı açılsın. Arkasında çizgili şeker var.', "No key needed: make a match in the door's own colour beside it and it opens. A striped sweet waits behind."),
    ),
    11 => (
      when: _t('Çamlıca Tepesi', 'Çamlıca Hill'),
      history: _t(
        "Şehrin iki yakasını ve Boğaz'ı birden gören Çamlıca, 19. yüzyılda İstanbulluların mesire yeriydi; kaynak suyu ünlüydü. Ekşi Limon tarif defterinin son sayfalarıyla tepeye kaçtı. Bütün şehir aşağıda, ışıl ışıl.",
        'Çamlıca, which sees both shores and the Bosphorus at once, was where 19th-century Istanbul went for outings; its spring water was famous. Sour Lemon has fled up here with the last pages of the book. The whole city glitters below.',
      ),
      limon: _t('Buraya kadar geldin demek. Bu tepe benim; oynadıkça tahtana limon atacağım. Ekşiliğimi bitirebilirsen defter senin.', "So you made it this far. This hill is mine, and I'll throw lemons on your board as you play. Wear down all my sourness and the book is yours."),
      lokum: _t('Her eşleşme onu biraz tatlandırır, özel şekerler iki kat! Limon dilimlerinin yanında eşleştir, temizle. Hadi, son sayfa!', 'Every match sweetens him a little, specials twice as much! Match beside the lemon slices to wash them away. Come on, the last page!'),
    ),
    // The second season: up the Bosphorus after Acı Biber, Ekşi Limon's
    // cousin.
    12 => (
      when: _t('Bir sis sabahı · Salacak', 'A foggy morning · Salacak'),
      history: _t(
        "Kız Kulesi yüzyıllarca Boğaz'ın girişinde bir fener gibi nöbet tuttu; sisli sabahlarda gemiler onun ışığına bakarak yol buldu. Ekşi Limon tatlandı ve köşesine çekildi. Ama kuzeni Acı Biber şehre geldi, Salacak sahilini sabah sisiyle örttü.",
        "For centuries the Maiden's Tower kept watch at the mouth of the Bosphorus like a lighthouse; on foggy mornings ships found their way by its light. Sour Lemon has turned sweet and retired. But his cousin Acı Biber has come to town and wrapped the Salacak shore in morning fog.",
      ),
      limon: _t('Kuzenim yumuşadı, ben yumuşamam! Bu sisin içinde şekerlerini bulamayacaksın.', "My cousin went soft. I won't! You'll never find your sweets in this fog."),
      lokum: _t('Sis ne kadar koyu olursa olsun Kız Kulesi yolu gösterir. Sisin yanında eşleştir, dağılsın.', "However thick the fog, the Maiden's Tower shows the way. Match beside the fog and it lifts."),
    ),
    13 => (
      when: _t('1908 · Haydarpaşa', '1908 · Haydarpaşa'),
      history: _t(
        "Haydarpaşa Garı 1908'de açıldı; Anadolu'ya giden trenler yıllarca buradan, denizin kıyısından kalktı. Acı Biber garın altına tüneller kazdı.",
        'Haydarpaşa Station opened in 1908; for years the trains to Anatolia left from here, right by the sea. Acı Biber has dug tunnels under the station.',
      ),
      limon: _t('Şekerler tünele girecek, nereden çıkacaklarını kimse bilmeyecek!', 'The sweets go into my tunnels, and nobody knows where they come out!'),
      lokum: _t('Tünel ne yapar? Üstten alır, alttan verir. Şekerin nereye düşeceğini kestir, gerisi kolay.', "What does a tunnel do? In at the top, out at the bottom. Guess where each sweet lands and the rest is easy."),
    ),
    14 => (
      when: _t('Bir vapur sabahı · Karaköy', 'A ferry morning · Karaköy'),
      history: _t(
        "Karaköy iskelesinden yüz yılı aşkın süredir vapurlar kalkar; martılar simit kırıntısı için vapurların peşinden uçar. Acı Biber martılara şeker kapmayı öğretti.",
        'Ferries have left Karaköy pier for over a hundred years, with gulls flying after them for crumbs of simit. Acı Biber has taught the gulls to grab sweets.',
      ),
      limon: _t('Martılarım şekerlerine bayılıyor. Kapsınlar bakalım, sana ne kalacak?', "My gulls love your sweets. Let them grab away, and see what's left for you!"),
      lokum: _t('Martıyı korkutmak kolay: yanında bir eşleşme yap, havalansın gitsin.', "Scaring a gull is easy: make a match beside it and off it flies."),
    ),
    15 => (
      when: _t('Bir yaz günü · Kuzguncuk', 'A summer day · Kuzguncuk'),
      history: _t(
        "Kuzguncuk'ta cami ile kilise yan yana durur; renkli ahşap evleri ve bostanlarıyla bilinir. Mahallenin teyzeleri her yaz kavanoz kavanoz gül reçeli yapar.",
        "In Kuzguncuk a mosque and a church stand side by side; it is known for its colourful wooden houses and gardens. Every summer the neighbourhood's aunties make jar after jar of rose jam.",
      ),
      limon: _t('Reçel mi? Ben acıyı severim! Kavanozların hepsini tahtaya döktüm, toplayamazsın.', "Jam? I like things hot! I've spilled every jar over the board, and you can't mop it up."),
      lokum: _t('Biz toplamayız, yayarız! Reçelin üstünde eşleştir, bütün tahta tatlansın.', "We don't mop it up, we spread it! Match on the jam until the whole board is sweet."),
    ),
    16 => (
      when: _t('1856 · Dolmabahçe', '1856 · Dolmabahçe'),
      history: _t(
        "Dolmabahçe Sarayı 1856'da tamamlandı; büyük salonundaki kristal avize dünyanın en büyüklerindendir. Acı Biber bahçedeki fenerlerin hepsini söndürdü.",
        'Dolmabahçe Palace was finished in 1856; the crystal chandelier in its great hall is one of the largest in the world. Acı Biber has put out every lantern in the garden.',
      ),
      limon: _t('Karanlıkta kimse şekerlerini göremez. Fenerleri yakmak üç vuruş ister, yetişemezsin!', "Nobody sees their sweets in the dark. A lantern takes three hits to light, and you won't keep up!"),
      lokum: _t('Bir, iki, üç: fenerin yanında üç kez eşleştir, saray yine ışıl ışıl olsun.', 'One, two, three: match beside a lantern three times and the palace glows again.'),
    ),
    _ => (
      when: _t('Anadolu Kavağı', 'Anadolu Kavağı'),
      history: _t(
        "Yoros Kalesi, Boğaz'ın Karadeniz'e açıldığı yeri yüzyıllardır tepeden gözler. Acı Biber Boğaz turunun sonunda, kalenin yanında bizi bekliyor.",
        'Yoros Castle has watched over the spot where the Bosphorus opens onto the Black Sea for centuries. At the end of the trip up the Bosphorus, Acı Biber waits for us by the castle.',
      ),
      limon: _t('Son durak! Şekerlerini acılaştıracağım; sayıları bitmeden eşleştiremezsen yanarlar.', "Last stop! I'll make your sweets hot, and if you don't match them before their count runs out, they burn."),
      lokum: _t('Her eşleşme onun acısını biraz alır. Acı şekerleri zamanında eşleştir; hadi, Boğaz turunu tatlı bitirelim!', "Every match takes some of his heat away. Match the hot sweets in time; come on, let's end this trip on a sweet note!"),
    ),
  };
  String get storyNext => _t('Devam ›', 'Next ›');
  String get storyTap => _t('Oyuna başla ›', 'Play ›');
  String get sugarRush => _t('ŞEKER\nÇILGINLIĞI!', 'SUGAR\nRUSH!');
  String get sugarRushMeter => _t('ŞEKER ÇILGINLIĞI', 'SUGAR RUSH');
  String get sugarLucky => _t('ŞANSLI ŞEKER!', 'LUCKY SWEET!');
  String sugarStar(int n) => _t('$n. YILDIZ!', 'STAR $n!');
  String get sugarCombo => _t('SÜPER KOMBO!', 'SUPER COMBO!');
  String sugarGoalFog(int n) => _t('$n sisi dağıt', 'Clear $n fog');
  String sugarGoalGull(int n) => _t('$n martıyı kaçır', 'Shoo $n gulls');
  String get sugarGoalJam => _t('Bütün tahtayı reçelle kapla', 'Cover the whole board in jam');
  String sugarGoalLantern(int n) => _t('$n feneri yak', 'Light $n lanterns');
  String get sugarGoalPepper => _t("Acı Biber'in acısını al", "Take away Acı Biber's heat");
  String get sugarPepperAngry => _t('ACI BİBER KIZDI!', 'ACI BİBER IS FUMING!');
  String sugarComboName(SugarCombo c) => switch (c) {
    SugarCombo.cross => _t('ÇAPRAZ!', 'CROSS!'),
    SugarCombo.bigCross => _t('DEV IŞIN!', 'GIANT BEAM!'),
    SugarCombo.mega => _t('MEGA PATLAMA!', 'MEGA BLAST!'),
    SugarCombo.rainbow => _t('GÖKKUŞAĞI!', 'RAINBOW!'),
    SugarCombo.wipe => _t('TAHTA TERTEMİZ!', 'BOARD WIPE!'),
  };
  String get sugarGoalMet => _t('HEDEF TAMAM!\nYILDIZLAR İÇİN DEVAM', 'GOAL MET!\nKEEP GOING FOR STARS');
  String get sugarBombLost => _t('BOMBA PATLADI', 'THE BOMB WENT OFF');
  String get sugarRainbow => _t('Gökkuşağı', 'Rainbow');
  String get sugarRainbowHint => _t('Gökkuşağı topu yapmak istediğin şekere dokun', 'Tap the sweet to turn into a rainbow ball');
  String sugarGoalBox(int n) => _t('$n kutuyu aç', 'Open $n boxes');
  String sugarGoalChoco(int n) => _t('$n çikolatayı temizle', 'Clear $n chocolate');
  String sugarGoalFruit(int n) => _t('$n narı aşağı indir', 'Bring down $n pomegranates');
  String sugarGoalCake(int n) => _t('$n pastayı bitir', 'Eat $n cakes');
  String sugarGoalDoor(int n) => _t('$n kapıyı aç', 'Open $n doors');
  String get sugarGoalLimon => _t("Ekşi Limon'u tatlandır", 'Sweeten Sour Lemon');
  String get sugarLimonAngry => _t('LİMON\nKIZDI!', 'LEMON\nIS MAD!');
  String get limonName => _t('EKŞİ LİMON', 'SOUR LEMON');
  String percent(int n) => _t('%$n', '$n%');
  String get finaleTitle => _t('İSTANBUL TATLANDI!', 'THE CITY IS SWEET AGAIN!');
  String get finaleText => _t(
    "Tarif defteri yerine döndü. Ekşi Limon bile pudra şekerine bulandı; şimdi bir lokum tadabilir mi diye soruyor.",
    'The book of recipes is home. Even Sour Lemon is covered in powdered sugar, and now he asks if he might taste a lokum.',
  );
  String finalePrize(String items) => _t('Büyük ödül: Çamlıca gecesi manzarası, $items', 'Grand prize: the Çamlıca by night scene, $items');

  /// What Lokum, the mascot, says: [key] picks the moment, [i] the line.
  String lokum(String key, int i) {
    final lines = switch (key) {
      'start' => [_t('Hadi bakalım, başlıyoruz!', 'Here we go!'), _t('Bu seviye bize vız gelir!', 'This one\'s a piece of cake!'), _t('Kolları sıvadım!', 'Sleeves rolled up!'), _t('Hazırım, ya sen?', 'I\'m ready, are you?'), _t('Damlaya damlaya göl olur!', 'Drop by drop, a lake fills!')],
      'nice' => [_t('Oh, güzel!', 'Ooh, nice!'), _t('Tatlı bir hamle!', 'Sweet move!'), _t('Aynen böyle!', 'That\'s the way!'), _t('Bak bu oldu!', 'Now we\'re talking!')],
      'great' => [_t('Vay vay vay!', 'Whoa, whoa, whoa!'), _t('Helal olsun sana!', 'Hats off to you!'), _t('Ağzım açık kaldı!', 'My jaw just dropped!'), _t('Bu ne güzellik böyle!', 'Now that\'s gorgeous!')],
      'rush' => [_t('Şeker yağmuru başladı!', 'It\'s raining sweets!'), _t('Şekerler durmadan patlıyor!', 'They\'re popping on their own!'), _t('Çılgınlık zamanı!', 'Sugar madness!')],
      'lucky' => [_t('Bugün şansımız yaver gidiyor!', 'Luck\'s on our side today!'), _t('Bu da bizden olsun!', 'This one\'s on the house!'), _t('Kısmetimize düştü!', 'What a lucky drop!')],
      'bomb' => [_t('Aman dikkat, bomba var!', 'Careful, a bomb!'), _t('Şu bombayı hemen patlat!', 'Pop that bomb, quick!'), _t('Saat işliyor, acele et!', 'The clock\'s ticking, hurry!')],
      'last' => [_t('Son birkaç hamle, dikkat!', 'Last few moves, careful!'), _t('Az kaldı, sakin ol!', 'Nearly there, stay calm!'), _t('Bitirmek üzereyiz!', 'We\'re about to finish!'), _t('Acele işe şeytan karışır, sakin!', 'Haste makes waste, steady now!')],
      'goalMet' => [_t('Hedef tamam! Şimdi yıldızlar!', 'Goal met! Now the stars!'), _t('Devam, üç yıldız bizim!', 'Keep going, three stars!')],
      'comboHint' => [_t('Bunları birleştir!', 'Swap these two together!'), _t('İkisini yan yana getir, gör!', 'Put these two together and see!')],
      'gull' => [_t('Martılar şeker kaptı!', 'Gulls took our sweets!'), _t('Kış kış, martı!', 'Shoo, gull, shoo!')],
      'lantern' => [_t('Fener yandı!', 'A lantern is lit!'), _t('Bak nasıl parlıyor!', 'Look how it shines!')],
      'pepper' => [_t('Acı geliyor, eşleştir!', 'Hot ones! Match them!'), _t('Yanmadan eşleştir!', 'Match them before they burn!')],
      'finale' => [_t('Şenlik başlasın!', 'Let the party begin!'), _t('Kalanlar da patlasın!', 'Pop the rest too!'), _t('Bonus zamanı!', 'Bonus time!')],
      'win' => [_t('Yaşasın, başardık!', 'Hooray, we did it!'), _t('Ellerine sağlık!', 'Well played, you!'), _t('İşte bu be!', 'That\'s how it\'s done!'), _t('Tatlı ye, tatlı konuş!', 'Eat sweet, speak sweet!')],
      'lose' => [_t('Üzülme, bir daha deneriz.', 'Don\'t worry, we\'ll try again.'), _t('Kıl payı kaçtı!', 'So close!'), _t('Olur böyle, hadi bir daha!', 'It happens, one more go!'), _t('Her işte bir hayır vardır.', 'Every cloud has a silver lining.')],
      'hint' => [_t('Şuna bir bak istersen.', 'Take a look at this one.'), _t('Psst, burada bir şey var!', 'Psst, there\'s something here!'), _t('Bence buradan dene.', 'I\'d try right here.'), _t('Bilmemek ayıp değil, sormamak ayıp!', 'No shame in not knowing, only in not asking!')],
      'sleepy' => [_t('Hıı... Dalmışım biraz.', 'Hmm... I dozed off a bit.'), _t('Uyumadım, gözümü dinlendirdim!', 'I was only resting my eyes!'), _t('Hadi, sıra sende!', 'Come on, your move!')],
      'chain' => [_t('Zincir!', 'Chain!'), _t('Zincir üstüne zincir!', 'Chain after chain!'), _t('Durma, devam!', 'Don\'t stop now!'), _t('Birlikten kuvvet doğar!', 'Together we are strong!')],
      'danger' => [_t('Aman, tavana dayandı!', 'Uh-oh, near the top!'), _t('Yer daralıyor, çabuk!', 'Running out of room, quick!')],
      'quad' => [_t('Dört sıra birden!', 'Four lines at once!'), _t('Dörtlü! Şahane!', 'A quad! Brilliant!')],
      'level' => [_t('Hız arttı, hazır ol!', 'Speeding up, get ready!'), _t('Yeni seviye, kolay gelsin!', 'New level, good luck!')],
      'over' => [_t('Bir el daha?', 'One more round?'), _t('Az kaldı, bir daha!', 'So close, again!'), _t('Sabreden derviş muradına ermiş.', 'Patience gets there in the end.')],
      'record' => [_t('Yeni rekor! Helal olsun!', 'New best! Well done!'), _t('Rekor artık senin!', 'The record is yours!')],
      'pause' => [_t('Mola! Bir çay koyayım mı?', 'Break time! Kettle on?'), _t('Biraz soluklan, buradayım.', 'Catch your breath, I\'m here.'), _t('Acele yok, keyfine bak.', 'No rush, take your time.'), _t('Bir fincan kahvenin kırk yıl hatırı vardır.', 'A cup of coffee is remembered for forty years.')],
      'puzzleStuck' => [_t('Baştan alalım, yolu buluruz.', 'Restart, we\'ll find the way.'), _t('Bir geri al, tekrar bak.', 'Undo one and look again.')],
      'attack' => [_t('Al bakalım Limon!', 'Take that, Lemon!'), _t('Limon ne olduğunu anlamadı!', 'Lemon didn\'t see that coming!')],
      'choco' => [_t('Çikolata yayılıyor, yetiş!', 'Chocolate\'s spreading, hurry!'), _t('Şu çikolatayı durduralım!', 'Let\'s stop that chocolate!')],
      'fruit' => [_t('Bir nar daha bizde!', 'Another pomegranate for us!'), _t('Nar sepete!', 'Into the basket!')],
      'cake' => [_t('Pastayı bitirdik!', 'The cake is gone!'), _t('Afiyet olsun bize!', 'Bon appétit to us!')],
      'door' => [_t('Kapı açıldı!', 'The door is open!'), _t('Bakalım arkasından ne çıkacak!', 'Let\'s see what\'s behind it!')],
      'limon' => [_t('Limon attı, temizle şunları!', 'More lemons! Wash them off!'), _t('Ekşi geliyor, dikkat!', 'Sour coming, watch out!')],
      'limonAngry' => [_t('Kızdı! Bırakma!', 'He\'s mad! Keep at it!'), _t('Tatlanıyor, az kaldı!', 'He\'s sweetening, nearly there!')],
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
    'choco' => _t('Çikolatanın yanında eşleştir. Bir hamlede hiç kırmazsan bir kare yayılır!', 'Match beside the chocolate. Break none in a move and it spreads a cell!'),
    'fruit' => _t('Nar eşleşmez, şekerle düşer. En alt sıraya indir, toplansın.', "Pomegranates don't match; they fall with the sweets. Bring them to the bottom row."),
    'belt' => _t('Banttaki şekerler her hamleden sonra ok yönünde bir kare kayar.', 'Sweets on a belt move one cell the way the arrows point after every move.'),
    'cake' => _t('Pastanın yanındaki her eşleşme bir katını yer. Son kat gidince paketli şeker çıkar.', 'Every match beside a cake eats a tier. The last tier leaves a wrapped sweet.'),
    'door' => _t('Kapı yalnız kendi renginde bir eşleşmeyle açılır; arkasında çizgili şeker var.', 'A door opens only to a match in its own colour; a striped sweet waits behind.'),
    'limon' => _t("Her eşleşme Ekşi Limon'u tatlandırır, özel şekerler iki kat. Attığı dilimlerin yanında eşleştir!", 'Every match sweetens Sour Lemon, specials twice as much. Match beside the slices he throws!'),
    'fog' => _t('Sis bazı kareleri örter. Yanında eşleştir, sis dağılsın; altından şeker çıkar.', 'Fog hides some cells. Match beside it to clear it and find the sweet beneath.'),
    'tunnel' => _t('Şekerler tünelden geçip aşağıdan çıkar. Hangi şekerin nereye düşeceğini kestir!', 'Sweets fall through the tunnel and come out below. Guess where each one lands!'),
    'gull' => _t('Martılar birkaç hamlede bir şeker kapar. Martının yanında eşleştir, kaçsın!', 'Every few moves gulls grab a sweet. Match beside a gull to shoo it off!'),
    'jam' => _t('Reçelli karede eşleşince reçel o eşleşmenin bütün karelerine yayılır. Bütün tahtayı kapla!', 'A match on jam spreads the jam over all its cells. Cover the whole board!'),
    'lantern' => _t('Fener üç vuruşta yanar: yanında üç kez eşleştir.', 'A lantern lights after three hits: match beside it three times.'),
    'pepper' => _t('Acı Biber tahtaya acı şekerler atar: sayısı bitmeden eşleştir! Her eşleşme acısını azaltır.', 'Acı Biber makes sweets hot: match them before their count runs out! Every match cools him down.'),
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
    'Gri satırlardaki yıldızlı blokları temizle: her biri ${GameMode.targetBonus.round()} saniye kazandırır.',
    'Clear the star blocks in the grey rows: each adds ${GameMode.targetBonus.round()} seconds.',
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

  /// A day, short: "12 Eki", "Oct 12".
  String shortDate(DateTime d) => _t('${d.day} ${_monthsTr[d.month - 1].substring(0, 3)}', '${_monthsEn[d.month - 1]} ${d.day}');

  // Records: the player's own top ten of each mode.
  String get recordsTitle => _t('REKORLARIN', 'YOUR RECORDS');
  String get recordsShort => _t('Rekorlar', 'Records');
  String get recordsNone => _t('Henüz rekor yok. İlk oyunun ilk rekorun olacak!', 'No records yet. Your first game sets the first one!');
  String get recordJustNow => _t('şimdi', 'now');
  String get recordEarlier => _t('önceden', 'earlier');
  String recordPlace(int n) => _t('REKORLARINDA $n. SIRA!', 'No. $n IN YOUR RECORDS!');
  String get recordYours => _t('Rekor senin! Şimdi farkı aç.', 'The record is yours! Now widen the gap.');
  String recordNextPlace(int place, String gap) => place == 1 ? _t('Sıradaki hedef: rekor · $gap kaldı', 'Next goal: the record · $gap to go') : _t('Sıradaki hedef: $place. sıra · $gap kaldı', 'Next goal: No. $place · $gap to go');
  String recordTopFive(String gap) => _t("İlk 5'e girmek için $gap kaldı", '$gap to make your top five');
  String toRecord(String gap) => _t('Rekora $gap kaldı', '$gap to your record');
  String pastRecord(String gap) => _t('REKOR! +$gap', 'RECORD! +$gap');
  String towerToRecord(int floors) => _t('Rekora $floors kat', '$floors to the record');

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
  String get levelsModeSubtitle => _t('100 seviye: mücevherleri topla', '100 levels: collect the jewels');
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
  String get gemsLeft => _t('MÜCEVHER', 'JEWELS');
  String get movesLeft => _t('HAMLE', 'MOVES');
  String get blocksGoal => _t('Satır ve sütunları doldur, bütün mücevherleri topla!', 'Fill rows and columns to collect every jewel!');
  String get blocksHowTo => _t(
    'Parçaları tahtaya sürükle. Dolan satır ve sütunlar patlar. Hiçbir parça sığmazsa oyun biter.',
    'Drag the pieces onto the board. Full rows and columns blast away. When nothing fits, the game is over.',
  );
  String threeStars(int moves) => _t('3 yıldız için en fazla $moves hamle', '3 stars in $moves moves or fewer');
  String get levelDone => _t('TAMAMLANDI!', 'COMPLETE!');
  String get levelCompleteTitle => _t('Seviye tamamlandı!', 'Level complete!');
  String get outOfMovesTitle => _t('Hamlen bitti', 'Out of moves');
  String get noRoomTitle => _t('Yer kalmadı', 'No room left');
  String get levelFailedHint => _t(
    'Biraz daha planla: mücevherli blokların olduğu satır ve sütunlara odaklan.',
    'Plan a little more: focus on the rows and columns with jewels.',
  );
  String movesUsed(int n) => _t('$n hamlede', 'in $n moves');
  String get sameBoard => _t('Aynı tahta', 'Same board');
  String get nextLevel => _t('Sonraki seviye', 'Next level');
  String get allLevelsDone => _t('Tüm seviyeleri bitirdin!', 'You finished every level!');
  String get bestLabel => _t('EN İYİ', 'BEST');
  /// Praise for a clear: it grows with the lines and with the combo.
  String? blastWord(int lines, [int streak = 1]) => switch ((lines + (streak >= 5 ? 3 : (streak >= 3 ? 1 : 0))).clamp(1, 5)) {
    1 => _t('GÜZEL!', 'NICE!'),
    2 => _t('HARİKA!', 'GREAT!'),
    3 => _t('MUHTEŞEM!', 'AMAZING!'),
    4 => _t('İNANILMAZ!', 'INCREDIBLE!'),
    _ => _t('EFSANE!', 'LEGENDARY!'),
  };
  String get luckyPiece => _t('ŞANSLI PARÇA!', 'LUCKY PIECE!');
  String get rescueTitle => _t('Yer kalmadı!', 'Out of room!');
  String get rescueMovesTitle => _t('Hamle bitti!', 'Out of moves!');
  String get rescueHint => _t('Bir güçlendiriciyle devam et:', 'Carry on with a booster:');
  String get rescueShuffle => _t('Yeni parçalar', 'New pieces');
  String get rescueHammer => _t('Çekiçle 3×3 kır', 'Smash a 3×3');
  String get rescueMoves => _t('+3 hamle', '+3 moves');
  String get rescueGiveUp => _t('Bitir', 'End game');
  String jewelName(int kind) => switch (kind) {
    1 => _t('Zümrüt', 'Emerald'),
    2 => _t('Safir', 'Sapphire'),
    3 => _t('Kehribar', 'Amber'),
    _ => _t('Yakut', 'Ruby'),
  };
  String get jewelStory => _t("KAPALIÇARŞI'NIN KAYIP MÜCEVHERLERİ", 'THE LOST JEWELS OF THE GRAND BAZAAR');

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
