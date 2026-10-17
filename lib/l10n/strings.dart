import 'package:flutter/widgets.dart';

import '../core/chain/chain_game.dart';
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
  // Home lobby: Lokum's suggestions and the mode cards.
  String get forYou => _t('SENİN İÇİN', 'FOR YOU');
  String get tipUntried => _t('Bunu hiç denemedin!', "You haven't tried this one!");
  String get tipTry => _t('Hemen dene', 'Try it');
  String tipLeftOff(int level) => _t('Kaldığın yer: Seviye $level', 'You stopped at level $level');
  String get tipContinue => _t('Devam et', 'Continue');
  String get tipDaily => _t('Bugünün bulmacası hazır!', "Today's puzzle is ready!");
  String get tipSolve => _t('Çöz', 'Solve');
  String get tipBeatBest => _t('Rekorunu geçebilir misin?', 'Can you beat your best?');
  String get tipPlay => _t('Oyna', 'Play');
  String get tipTapMe => _t('Bana dokun, bir fikrim daha var!', 'Tap me for another idea!');
  // Gifts: the daily calendar, the sugar jar, star chests, the weekly event.
  String get giftsTitle => _t('HEDİYELER', 'GIFTS');
  String get giftsShort => _t('Hediyeler', 'Gifts');
  String get dailyGiftTitle => _t('Günlük hediye', 'Daily gift');
  String get dailyGiftHint => _t('Her gün bir hediye. Bir gün kaçırırsan kaldığın yerden devam.', 'A gift every day. Miss a day and you carry on where you were.');
  String giftDayLabel(int day) => _t('${day + 1}. gün', 'Day ${day + 1}');
  String get giftToday => _t('BUGÜN', 'TODAY');
  String get giftTaken => _t('ALINDI', 'TAKEN');
  String get giftTake => _t('AL', 'TAKE');
  String get giftTomorrow => _t('Yarın yeni hediye', 'A new gift tomorrow');
  String get giftBigChest => _t('Büyük sandık', 'Big chest');
  String get tipGift => _t('Bugünkü hediyen hazır!', "Today's gift is ready!");
  String get tipOpen => _t('Aç', 'Open');
  String tipGiftsWaiting(int n) => _t('Açılmayı bekleyen $n hediyen var!', '$n gifts are waiting for you!');
  String get tipSee => _t('Gör', 'See');
  String get jarTitle => _t('Şeker kavanozu', 'Sugar jar');
  String get jarHint => _t('Patlattığın her şeker kavanoza düşer.', 'Every sweet you pop drops into the jar.');
  String get jarFull => _t('Kavanoz doldu!', 'The jar is full!');
  String get jarOpen => _t('AÇ', 'OPEN');
  String get chestsTitle => _t('Yıldız sandıkları', 'Star chests');
  String chestsHint(int every) => _t("Şeker Küpler'de her $every yıldızda bir sandık.", 'A chest for every $every Sugar Blocks stars.');
  String chestNext(int stars) => _t('Sonraki sandık: $stars yıldız', 'Next chest: $stars stars');
  String chestName(int tier) => switch (tier) {
    2 => _t('ALTIN SANDIK!', 'GOLD CHEST!'),
    1 => _t('GÜMÜŞ SANDIK!', 'SILVER CHEST!'),
    _ => _t('BRONZ SANDIK!', 'BRONZE CHEST!'),
  };
  String get chestOpen => _t('SANDIĞI AÇ', 'OPEN THE CHEST');
  String get eventTitle => _t('Haftanın etkinliği', "This week's event");
  String eventDaysLeft(int n) => n <= 1 ? _t('Bu gece biter', 'Ends tonight') : _t('$n gün kaldı', '$n days left');
  String get eventClaim => _t('ÖDÜLÜ AL', 'TAKE THE PRIZE');
  String eventProgress(int got, int of) => '$got / $of';
  String eventName(String e) => switch (e) {
    'tulip' => _t('Lale Festivali', 'Tulip Festival'),
    'ferry' => _t('Vapur Haftası', 'Ferry Week'),
    'coffee' => _t('Kahve Haftası', 'Coffee Week'),
    _ => _t('Simit Haftası', 'Simit Week'),
  };
  String eventGoal(String e) => switch (e) {
    'tulip' => _t('Herhangi bir seviyede kırmızı kalp patlat', 'Pop red hearts in any level'),
    'ferry' => _t('Herhangi bir seviyede mavi damla patlat', 'Pop blue drops in any level'),
    'coffee' => _t('Herhangi bir seviyede turuncu girdap patlat', 'Pop orange swirls in any level'),
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
    _ => _t('Simit kolye', 'Simit necklace'),
  };
  String unlockText(String u) => switch (u) {
    'cubesLokum' => _t("Zincir Küpler'de pudra şekerli lokum küpler.", 'Powdered lokum cubes for Chain Blocks.'),
    'cubesCini' => _t("Zincir Küpler'de İznik çinisi görünümü.", 'Iznik tile cubes for Chain Blocks.'),
    'sceneGalata' || 'sceneSnow' || 'sceneIslands' || 'sceneCamlica' => _t('Şeker tahtasının arkasında yeni bir İstanbul manzarası.', 'A new Istanbul scene behind the Sugar Blocks board.'),
    'shuffle' => _t("Şeker'de takıldığında tahtayı karıştırır.", 'Shuffles the Sugar Blocks board when you are stuck.'),
    'freeze' => _t("Zincir'de yükselişi birkaç saniye durdurur.", 'Holds the Chain Blocks stack for a few seconds.'),
    _ => _t("Lokum'un dolabında yeni bir kostüm.", "A new outfit in Lokum's wardrobe."),
  };
  String get collectionTitle => _t('Koleksiyon', 'Collection');
  String get cubeLook => _t('Zincir küpleri', 'Chain Blocks cubes');
  String get sugarSceneLabel => _t('Şeker manzarası', 'Sugar Blocks scene');
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
    _ => _t('Çamlıca Tepesi', 'Çamlıca Hill'),
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
      lokum: _t('Bu çarşının her köşesini bilirim. Şekerleri kurtaralım, izini kaybetmeden.', 'I know every corner of this bazaar. Save the sweets and we keep on his trail.'),
    ),
    1 => (
      when: _t('1621 · Üsküdar', '1621 · Üsküdar'),
      history: _t(
        "O kış Boğaz dondu; kaynaklar, halkın Üsküdar'dan karşı kıyıya buzun üstünde yürüyerek geçtiğini yazar. Efsaneye göre Kız Kulesi, kehanetten saklanan bir prensesin sığınağıydı.",
        "That winter the Bosphorus froze; chroniclers write that people walked across the ice from Üsküdar. Legend says the Maiden's Tower once hid a princess from a prophecy.",
      ),
      limon: _t('Buz bu şehrin tarihini bir kez yazdı, bir kez daha yazacak. Kuleye giden her yolu donduruyorum.', "Ice wrote this city's history once and it will again. I'm freezing every way to the tower."),
      lokum: _t("1621'in buzu da çözülmüştü. Buzlu kareleri kır, kuleye ulaşalım.", "The ice of 1621 melted too. Crack the icy squares and we'll reach the tower."),
    ),
    2 => (
      when: _t('1452 · Rumeli Hisarı', '1452 · Rumeli Fortress'),
      history: _t(
        "II. Mehmed, Boğaz'ı denetlemek için hisarı yaklaşık dört ayda yükseltti. Ertesi bahar Bizans, Haliç'in ağzını dev bir demir zincirle kapattı.",
        'Mehmed II raised the fortress in about four months to command the Bosphorus. The next spring Byzantium closed the Golden Horn with a great iron chain.',
      ),
      limon: _t('Zincirin hikâyesini ben de bilirim. Şekerleri tek tek bağladım; hiçbiri yerinden kıpırdamayacak.', "I know the story of the chain too. I've bound the sweets one by one; not one will move."),
      lokum: _t('O zincir de aşılmıştı: gemiler bir gecede karadan yürütüldü. Zincirleri kır, yol açılsın.', 'That chain was beaten too: ships were hauled overland in a single night. Break the chains and clear the way.'),
    ),
    3 => (
      when: _t('1461 · Kapalıçarşı', '1461 · Grand Bazaar'),
      history: _t(
        'Çarşının kalbi Cevahir Bedesteni, fetihten kısa süre sonra yapıldı. Mücevherler ve değerli kumaşlar burada korunur, kapılar her akşam kilitlenirdi.',
        'The heart of the bazaar, the Cevahir Bedesten, was built soon after the conquest. Jewels and fine cloth were kept here and the gates were locked every evening.',
      ),
      limon: _t('Şekerleri bedestenin sandıklarına kilitledim. Bu labirentte kimse yolunu bulamaz.', "I've locked the sweets in the bedesten's chests. Nobody finds their way in this maze."),
      lokum: _t('Kutunun yanında eşleştir, kilit çözülür. Defterin bir sayfası da burada olmalı.', 'Match beside a box and the lock gives way. A page of the book must be here too.'),
    ),
    4 => (
      when: _t('1348 · Galata', '1348 · Galata'),
      history: _t(
        'Cenevizlilerin yaptığı kule, Osmanlı döneminde yangın gözcülerinin yeri oldu. Şehirde duman görülünce kuleden işaret verilir, mahalleler uyarılırdı.',
        'Built by the Genoese, the tower became the post of fire watchmen in Ottoman times. When smoke rose over the city a signal went out from the top.',
      ),
      limon: _t("Galata'nın her köşesine saatli bombalar kurdum. Gözcüler bile yetişemez.", 'I set time bombs all over Galata. Not even the watchmen will keep up.'),
      lokum: _t('Gözcü gibi düşün: önce sayısı en az olanı söndür. Süre bitmeden!', 'Think like a watchman: put out the lowest count first. Before time runs out!'),
    ),
    5 => (
      when: _t('1072 · Kınalıada', '1072 · Kınalıada'),
      history: _t(
        "Tahttan indirilen Bizans imparatoru IV. Romanos Diogenes buraya sürgün edildi. Adaların 'Prens Adaları' diye anılması, böyle sürgünlerin yeri olmalarından gelir.",
        "Deposed Byzantine emperor Romanos IV Diogenes was exiled here. The islands are called the Princes' Islands because they were where such exiles were sent.",
      ),
      limon: _t('Ben sürgüne gitmem, kaçarım. Adaların gökkuşağını da yanıma alıyorum!', "I don't get exiled, I escape. And I'm taking the islands' rainbow with me!"),
      lokum: _t('Renkleri gökkuşağı toplarıyla geri alacağız. Defterin son sayfaları onda; peşini bırakmak yok.', "We'll win the colours back with rainbow balls. He has the book's last pages; we don't let go."),
    ),
    6 => (
      when: _t('MÖ 685 · Kalkedon', '685 BC · Chalcedon'),
      history: _t(
        "Megaralılar Kadıköy'e, Bizantion'dan 17 yıl önce yerleşti. Herodot'un aktardığına göre Pers komutanı Megabazos, karşıdaki yarımadayı bırakıp bu kıyıyı seçtikleri için onlara 'körler' demişti.",
        'Megarians settled at Kadıköy 17 years before Byzantion was founded. Herodotus tells how the Persian general Megabazus called them blind for choosing this shore over the peninsula opposite.',
      ),
      limon: _t('Körler kıyısı, öyle mi? Bu yakanın şekerlerini acı kakaoyla kaplıyorum; her hamlede biraz daha yayılacak.', "The shore of the blind, is it? I'm coating this side's sweets in bitter cocoa, and it spreads with every move."),
      lokum: _t('Biz karşıyı da görürüz, bu yakayı da. Çikolatanın yanında eşleştir; her hamlede birini kır ki yayılmasın.', "We see both shores. Match beside the chocolate and break some every move, so it can't spread."),
    ),
    7 => (
      when: _t('1856 · Ortaköy', '1856 · Ortaköy'),
      history: _t(
        "Sultan Abdülmecid, Ortaköy iskelesinin hemen yanına Büyük Mecidiye Camii'ni yaptırdı. Mimarları Dolmabahçe Sarayı'nı da yapan Garabet Balyan ile oğlu Nigoğos'tu; cami suya o kadar yakındır ki dalgalar avlusunun dibine vurur.",
        'Sultan Abdülmecid had the Grand Mecidiye Mosque built beside the Ortaköy pier. Its architects were Garabet Balyan and his son Nigoğos, who also built Dolmabahçe Palace; it stands so close to the water that waves break at its courtyard.',
      ),
      limon: _t('Defterdeki nar şerbeti tarifinin narlarını tahtanın tepesine sakladım. Aşağı inemeyecekler.', "I've hidden the pomegranates for the book's sherbet at the top of the board. They'll never come down."),
      lokum: _t('Narlar şekerle birlikte düşer. Altlarını eşleştir, en alt sıraya varınca toplanırlar.', 'Pomegranates fall with the sweets. Match below them; once they reach the bottom row they are ours.'),
    ),
    8 => (
      when: _t('1872 · Sühulet', '1872 · The Sühulet'),
      history: _t(
        "Şirket-i Hayriye'nin Sühulet vapuru, Kabataş ile Üsküdar arasında at arabalarını güvertesinde taşımaya başladı. Tasarımı şirketin müdürü Giritli Hüseyin Haki Efendi'nindi; dünyanın ilk araba vapurlarından biri sayılır.",
        "Şirket-i Hayriye's ferry Sühulet began carrying horse carts on its deck between Kabataş and Üsküdar. It was designed by the company's director Hüseyin Haki Efendi and counts among the world's first car ferries.",
      ),
      limon: _t('Vapurun güvertesini ele geçirdim. Şekerleri bantlara dizdim; her hamlede kayıp gidecekler.', "I've taken the ferry's deck. The sweets are on the belts now, and they slide away with every move."),
      lokum: _t('Bant her hamleden sonra bir kare kayar. Şekerin nereye varacağını düşün; bazen eşleşme kendiliğinden gelir.', 'The belt moves one cell after every move. Think where the sweets will land; sometimes the match comes by itself.'),
    ),
    9 => (
      when: _t('1875 · Tünel', '1875 · The Tünel'),
      history: _t(
        "Karaköy'den Beyoğlu'na tırmanan Tünel açıldı. Londra'dan sonra dünyanın en eski ikinci yeraltı hattıdır; yokuşu bir buçuk dakikada çıkar. Hemen yukarıdaki Cadde-i Kebir, bugünkü İstiklal, pastaneleriyle ünlendi.",
        "The Tünel opened, climbing from Karaköy to Beyoğlu. It is the world's second oldest underground line, after London's, and takes the hill in a minute and a half. The Grande Rue above, today's İstiklal, grew famous for its patisseries.",
      ),
      limon: _t('Caddenin pastalarını kat kat dizdim, şekerlerin önüne yığdım. Bakalım kaç katını yiyebileceksin.', "I've stacked the avenue's cakes tier upon tier in front of the sweets. Let's see how many tiers you can eat."),
      lokum: _t('Pastanın yanındaki her eşleşme bir kat yer. Son kat gidince yerinden paketli şeker çıkar!', 'Every match beside a cake eats a tier. When the last one goes, a wrapped sweet appears in its place!'),
    ),
    10 => (
      when: _t('1492 · Balat', '1492 · Balat'),
      history: _t(
        "İspanya'dan sürülen Sefarad Yahudileri, II. Bayezid'in kabulüyle İstanbul'a geldi; birçoğu Haliç kıyısındaki Balat'a yerleşti. Rum, Ermeni ve Yahudi mahalleleri yüzyıllarca yan yana yaşadı; renkli cumbalı evler bugün de yokuşları süsler.",
        'Sephardic Jews driven out of Spain came to Istanbul, received by Bayezid II, and many settled in Balat on the Golden Horn. Greek, Armenian and Jewish quarters lived side by side for centuries; colourful bay-windowed houses still line its hills.',
      ),
      limon: _t("Balat'ın renkli kapılarını kilitledim. Her biri yalnız kendi rengini tanır; anahtarlar bende.", "I've locked Balat's coloured doors. Each knows only its own colour, and I have the keys."),
      lokum: _t('Anahtara gerek yok: kapının yanında kendi renginde bir eşleşme yap, kapı açılsın. Arkasında çizgili şeker var.', "No key needed: make a match in the door's own colour beside it and it opens. A striped sweet waits behind."),
    ),
    _ => (
      when: _t('Çamlıca Tepesi', 'Çamlıca Hill'),
      history: _t(
        "Şehrin iki yakasını ve Boğaz'ı birden gören Çamlıca, 19. yüzyılda İstanbulluların mesire yeriydi; kaynak suyu ünlüydü. Ekşi Limon tarif defterinin son sayfalarıyla tepeye kaçtı. Bütün şehir aşağıda, ışıl ışıl.",
        'Çamlıca, which sees both shores and the Bosphorus at once, was where 19th-century Istanbul went for outings; its spring water was famous. Sour Lemon has fled up here with the last pages of the book. The whole city glitters below.',
      ),
      limon: _t('Buraya kadar geldin demek. Bu tepe benim; oynadıkça tahtana limon atacağım. Ekşiliğimi bitirebilirsen defter senin.', "So you made it this far. This hill is mine, and I'll throw lemons on your board as you play. Wear down all my sourness and the book is yours."),
      lokum: _t('Her eşleşme onu biraz tatlandırır, özel şekerler iki kat! Limon dilimlerinin yanında eşleştir, temizle. Hadi, son sayfa!', 'Every match sweetens him a little, specials twice as much! Match beside the lemon slices to wash them away. Come on, the last page!'),
    ),
  };
  String get storyNext => _t('Devam ›', 'Next ›');
  String get storyTap => _t('Oyuna başla ›', 'Play ›');
  String get sugarRush => _t('ŞEKER\nÇILGINLIĞI!', 'SUGAR\nRUSH!');
  String get sugarRushMeter => _t('ŞEKER ÇILGINLIĞI', 'SUGAR RUSH');
  String get sugarLucky => _t('ŞANSLI ŞEKER!', 'LUCKY SWEET!');
  String sugarStar(int n) => _t('$n. YILDIZ!', 'STAR $n!');
  String get sugarCombo => _t('SÜPER KOMBO!', 'SUPER COMBO!');
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
      'hint' => [_t('Şunu dene!', 'Try this one!'), _t('Şuraya bak!', 'Look here!')],
      'sleepy' => [_t('Hıı... uyudum mu?', 'Zzz... did I nod off?'), _t('Sıra sende!', 'Your move!')],
      'chain' => [_t('Zincir!', 'Chain!'), _t('Harika zincir!', 'Great chain!'), _t('Devam, devam!', 'Keep it going!')],
      'danger' => [_t('Dikkat, tavan!', 'Mind the top!'), _t('Hızlı ol!', 'Quick!')],
      'quad' => [_t('Dörtlü!', 'A quad!'), _t('Dört sıra birden!', 'Four at once!')],
      'level' => [_t('Hızlanıyoruz!', 'Speeding up!'), _t('Yeni seviye!', 'New level!')],
      'over' => [_t('Bir daha?', 'Again?'), _t('Az kaldı, tekrar!', 'So close, once more!')],
      'record' => [_t('Yeni rekor!', 'New best!'), _t('Sen bir şampiyonsun!', "You're a champ!")],
      'pause' => [_t('Mola! Bir çay içelim mi?', 'A break! Tea, anyone?'), _t('Dinlen biraz.', 'Have a rest.')],
      'puzzleStuck' => [_t('Baştan alalım, yol orada!', "Let's restart, the way is there!"), _t('Bir geri al, tekrar bak.', 'Undo one and look again.')],
      'attack' => [_t('Al sana çöp!', 'Garbage coming your way!'), _t('Limon şaşırdı!', 'That got Lemon!')],
      'choco' => [_t('Çikolata yayılıyor!', 'The chocolate is spreading!'), _t('Çikolatayı durdur!', 'Stop the chocolate!')],
      'fruit' => [_t('Bir nar daha!', 'Another pomegranate!'), _t('Nar bizde!', 'Got the pomegranate!')],
      'cake' => [_t('Pasta bitti!', 'Cake gone!'), _t('Afiyet olsun!', 'Enjoy!')],
      'door' => [_t('Kapı açıldı!', 'The door is open!'), _t('Bak arkasında ne var!', "Look what's behind it!")],
      'limon' => [_t('Limon attı, temizle!', 'Lemons! Wash them away!'), _t('Ekşi geliyor!', 'Here comes the sour!')],
      'limonAngry' => [_t('Kızdı! Devam!', "He's mad! Keep going!"), _t('Az kaldı, tatlanıyor!', "Nearly there, he's sweetening!")],
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
