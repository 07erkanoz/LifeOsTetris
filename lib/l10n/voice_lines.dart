import 'strings.dart';

/// The moments the game speaks about. Every line is about something that
/// really happened to this player (their record, their own average, a
/// comeback), never a generic cheer.
enum Voice {
  // ---- during a game
  nearBest,
  newBest,
  pastBest,
  aboveAverage,
  todayBest,
  comeback,
  flow,
  firstQuadNew,
  firstQuad,
  quadRecord,
  levelRecord,
  maxSpeed,
  endurance,
  openNight,
  openMorning,
  openNearMiss,
  openQuickLoss,
  openStreak,

  // ---- when a game ends
  endNewBest,
  endNearMiss,
  endAboveAverage,
  endBestToday,
  endWall,
  endQuick,
  endComeback,
  endGrowth,
  endLoss,
  endTimedFirst,
  endTimedRecord,
  endTimedSlower,
  endTimedFail,

  // ---- on the main menu
  homeRecordFresh,
  homeNearMiss,
  homeStreak,
  homeNotToday,
  homeBack,
  homeGrowth,
  homeWeek,
  homeNight,
  homeMorning,
}

/// One chosen line: which moment, which wording, and the numbers in it.
/// The text is built when shown, so it follows a language change.
class VoiceLine {
  const VoiceLine(this.voice, this.variant, [this.values = const {}]);

  final Voice voice;
  final int variant;

  /// gap, best, avg, score, prev, count → points; level, days, lines, pct
  /// → plain numbers; time → a clock; secs → seconds with one decimal.
  final Map<String, num> values;

  String text(AppStrings s) {
    final lines = voiceLines(s)[voice]!;
    var line = lines[variant % lines.length];
    for (final e in values.entries) {
      line = line.replaceAll('{${e.key}}', _format(s, e.key, e.value));
    }
    // English counts are plural except for one ("1 point", "1 day").
    if (!s.isTurkish) line = line.replaceAllMapped(_one, (m) => '${m[1]}1 ${m[2]}');
    return line;
  }

  static final _one = RegExp(r'(^|[^\d.,])1 (point|day|line|game|quad)s\b');

  static String _format(AppStrings s, String key, num value) => switch (key) {
    'gap' || 'best' || 'avg' || 'score' || 'prev' || 'count' => s.score(value.round()),
    'time' => s.clock(value.toDouble()),
    'secs' => s.isTurkish ? value.toStringAsFixed(1).replaceAll('.', ',') : value.toStringAsFixed(1),
    _ => '${value.round()}',
  };

  @override
  bool operator ==(Object other) => other is VoiceLine && other.voice == voice && other.variant == variant;

  @override
  int get hashCode => Object.hash(voice, variant);
}

Map<Voice, List<String>> voiceLines(AppStrings s) => s.isTurkish ? _tr : _en;

/// Number of wordings of [voice]; the same in every language.
int voiceVariants(Voice voice) => _tr[voice]!.length;

final _placeholder = RegExp(r'\{(\w+)\}');

/// Wordings of [voice] that only need numbers from [keys] (in every
/// language), e.g. no "your old record was…" before there is one.
List<int> usableVariants(Voice voice, Iterable<String> keys) {
  final have = keys.toSet();
  bool fits(String line) => _placeholder.allMatches(line).every((m) => have.contains(m.group(1)));
  return [
    for (var i = 0; i < _tr[voice]!.length; i++)
      if (fits(_tr[voice]![i]) && fits(_en[voice]![i])) i,
  ];
}

// Numbers are always followed by a word ("{gap} puan", "{days} gün"), so
// Turkish never needs a suffix glued to a digit.

const Map<Voice, List<String>> _tr = {
  Voice.nearBest: [
    'Rekora {gap} puan kaldı. Şimdi sakin ol.',
    'Rekorun burnunun dibinde: {gap} puan.',
    'Az kaldı, {gap} puan. Bırakma!',
    'Bu oyun rekor olabilir. {gap} puan daha.',
    'Acele yok. {gap} puanı tek tek toplarsın.',
    'Rekorla aranda sadece {gap} puan var.',
    'Hadi, {gap} puan daha ve rekor senin.',
    'Buraya her oyunda gelemiyorsun. {gap} puan kaldı.',
  ],
  Voice.newBest: [
    'Yeni rekor! Bundan sonrası bonus.',
    'Rekoru kırdın. Bakalım nereye kadar gidecek.',
    'Eski rekor tarih oldu.',
    'Şu an en iyi oyunundasın. Devam!',
    'Rekor senin. Durma, farkı aç.',
    'İşte bu! Yeni rekor.',
    'Dün hayal gibi gelen skoru geçtin.',
    'Rekoru kırdın. Şimdi öyle bir yere taşı ki bir dahakine sen bile zorlan.',
  ],
  Voice.pastBest: [
    'Artık eski rekorunla değil, kendinle yarışıyorsun.',
    'Eski rekoru çoktan geçtin. Yeni çıtayı bu oyun koyuyor.',
    'Rekoru kırmak bir şey, farkı bu kadar açmak başka.',
    'Her satırla bir sonraki oyunun hedefini yükseltiyorsun.',
    'Bu oyun unutulmaz.',
    'Çok yükseklerdesin. Derin bir nefes al, devam.',
  ],
  Voice.aboveAverage: [
    'Ortalamanı geçtin. Bundan sonrası kâr.',
    'Normalde bu civarda biterdi. Bugün bitmiyor.',
    'Sıradan bir oyunu çoktan geçtin. Bu iyi bir oyun.',
    'Ortalaman {avg} puan. Onu geride bıraktın.',
    'Oyunlarının çoğu buraya kadar gelemiyor.',
    'Ortalamanın üstündesin. Hadi bunu unutulmaz bir oyuna çevir.',
  ],
  Voice.todayBest: [
    'Bugünün en iyi oyunu bu.',
    'Bugün oynadığın her oyunu geçtin.',
    'Günün en iyisi. Üstelik daha bitmedi.',
    'Bugün elin ısındı.',
    'Isınma bitti, asıl oyun şimdi başlıyor.',
  ],
  Voice.comeback: [
    'Herkes burada pes ederdi. Sen etmedin.',
    'Tahta tavana dayanmıştı, kurtardın!',
    'Bunu kimse görmedi ama sen biliyorsun.',
    'Paniğe kapılmadın. Asıl ustalık bu.',
    'Az önce kaybediyordun. Şimdi kontrol yine sende.',
    'En zor anda en temiz hamleleri yaptın.',
    'Ölümden döndün! Bu oyunun en iyi anı buydu.',
    'Köşeye sıkıştın ama kurtuldun.',
  ],
  Voice.flow: [
    'Akışa girdin. Düşünme, oyna.',
    'Elin kendiliğinden gidiyor. Bozma.',
    'Ritmi yakaladın.',
    'Her parça yerine oturuyor.',
    'Tam kıvamında oynuyorsun.',
    'Hem sakin hem hızlı. En iyi hâlin bu.',
    'Tahtayı ezbere biliyor gibisin.',
    'Seri uzuyor, bozma.',
  ],
  Voice.firstQuadNew: [
    'Bu oyunun ilk dörtlüsü. Beklemeyi biliyorsun.',
    'Dört satır birden! Sabrın karşılığı.',
    'Kuyuyu açık tutup I parçasını bekledin. İşte sonucu.',
    'Bunu bilerek yaptın, değil mi?',
    'Dörtlü! İşi ciddiye aldın.',
  ],
  Voice.firstQuad: [
    'İlk dörtlü geldi. Gerisi sende.',
    'Kuyu açık, el sakin: dörtlü.',
    'Bilindik tarif: sabır, kuyu, dörtlü.',
    'Dörtlüyle açtın. Oyunun havasını sen belirledin.',
    'Dörtlüyle başlayan oyun uzun sürer.',
  ],
  Voice.quadRecord: [
    'Bu oyunda {count} dörtlü yaptın. Bir oyunda hiç bu kadar yapmamıştın.',
    '{count} dörtlü! Oyun bitmeden kendi rekorunu kırdın.',
    'Dörtlüde yeni rekor: {count} tane.',
    'Bir oyunda en fazla {prev} dörtlü yapmıştın. Şimdi {count} oldu.',
  ],
  Voice.levelRecord: [
    'Son oyunlarında {level}. seviyeyi hiç görmemiştin. Şimdi buradasın.',
    '{level}. seviye! Son zamanlarda buraya kadar gelememiştin.',
    'Bu hız sana yeni ama dayanıyorsun.',
    'Son zamanlarda bu kadar hızlı oynamamıştın. Birkaç parçada alışırsın.',
    '{level}. seviyeye çıktın. Burası artık sana yabancı değil.',
  ],
  Voice.maxSpeed: [
    'Son hız! Bundan sonrası tamamen sende.',
    'Oyun daha fazla hızlanamaz. Ama sen hızlanabilirsin.',
    'Son vitesteyiz. Nefesini kontrol et.',
    'Bu hızda düşünmeye vakit yok. Kendine güven.',
  ],
  Voice.endurance: [
    '{lines} satır oldu. Sabır da bir yetenek.',
    '{lines} satırdır buradasın, odağın hiç dağılmadı.',
    '{lines} satır! Uzun oyun sabır ister.',
    '{lines} satır temizledin ve hâlâ soğukkanlısın.',
  ],
  Voice.openNight: [
    'Gece oyunu başka olur. Acele etme.',
    'Saat geç oldu. En güzel oyunlar bazen bu saatte çıkar.',
    'Herkes uyurken tahta sadece senin.',
  ],
  Voice.openMorning: ['Günün ilk oyunu. Kafa en temiz bu saatte.', 'Zinde kafa, boş tahta.', 'Güne sakin bir oyunla başla, gerisi gelir.'],
  Voice.openNearMiss: [
    'Geçen oyunda rekora {gap} puan kalmıştı. Bu sefer olacak mı?',
    'Rekorla aranda bir hesap var: geçen sefer {gap} puan kalmıştı.',
    'Geçen oyunda rekorun kıyısından döndün. Bu sefer olabilir.',
  ],
  Voice.openQuickLoss: [
    'Geçen oyun çabuk bitti. Bu sefer ilk parçaları yavaş koy.',
    'Erken biten oyun ısınma sayılır.',
    'Geçen oyunu unut. Tahta tertemiz.',
  ],
  Voice.openStreak: [
    '{days} gündür buradasın. Alışkanlık böyle başlar.',
    'Bugün de geldin, üst üste {days} gün. Elin her gün biraz daha alışıyor.',
    '{days} gün üst üste! Artık tesadüf değil.',
  ],
  Voice.endNewBest: [
    'Şimdiye kadarki en iyi oyunun! Bundan sonra geçmen gereken skor bu.',
    'Yeni rekor: {score} puan. Bu sayı bir süre aklından çıkmaz.',
    'Eski rekorun {prev} puandı, şimdi {score} puan. Aradaki her puan senin emeğin.',
    'Bu oyunla çıtayı yükselttin. Artık kendini bununla ölçeceksin.',
    'Rekor geldi. Şimdi işin zor kısmı: bunu da geçmek.',
  ],
  Voice.endNearMiss: [
    'Rekora {gap} puan kala bitti. Bu kadar yaklaşmışken bırakır mısın?',
    '{gap} puan! Bir sonraki oyunda o fark kapanır.',
    'Rekorun kapısına kadar geldin. Bir dahakine o kapı açılır.',
    'Bu kadar yaklaşıp kaçırmak can sıkar. Ama demek ki artık o seviyedesin.',
    'Rekor {gap} puan ötede kaldı. El ısınmışken bir tane daha?',
  ],
  Voice.endAboveAverage: [
    'Ortalamanın üstünde bir oyun. Bunlar birikince rekor kendiliğinden gelir.',
    'Normalde {avg} puan civarı yapıyorsun. Bu oyun onu geçti, gidişat iyi.',
    'Rekor değil ama ortalamanın üstünde. İyi oyunlar böyle birikir.',
    'Bu oyunda her zamankinden iyiydin. Bunu bil.',
  ],
  Voice.endBestToday: [
    'Bugünün en iyi oyunu bu. Günü rekorla kapatmaya hâlâ vakit var.',
    'Bugün oynadıklarının en iyisi. El ısındı.',
    'Her oyun bir öncekinden iyi olmak zorunda değil ama bu oldu.',
  ],
  Voice.endWall: [
    'Son oyunlarının çoğu {level}. seviye civarında bitiyor. Demek ki engel orada. Aşılır, merak etme.',
    'Yine {level}. seviye. Hız artınca yığını alçak tut, tavana yaklaştırma.',
    '{level}. seviye seni birkaç kez durdurdu. Bir dahakine oraya gelince tutma kartını kullan.',
  ],
  Voice.endQuick: [
    'Kısa sürdü. İlk dakikalar hep en zoru.',
    'Erken bitti. Bunu ısınma say.',
    'Bazen tahta baştan ters gelir. Bir sonraki daha iyi gelir.',
  ],
  Voice.endComeback: [
    'Bu oyunda bir ara kaybediyordun ama geri döndün. Asıl önemli olan bu.',
    'Tahta tavana dayandığında pes etmedin. Bunu unutma.',
    'Kaybetmeye en yakın olduğun an, en iyi oynadığın andı.',
  ],
  Voice.endGrowth: [
    'Son beş oyununun ortalaması öncekilerden yüzde {pct} daha yüksek.',
    'Fark etmiyor olabilirsin ama gelişiyorsun: ortalaman yüzde {pct} arttı.',
    'Bu oyuna alışıyorsun. Son oyunların ortalaması yüzde {pct} yukarıda.',
  ],
  Voice.endLoss: [
    'Bu oyun bitti ama öğrendiklerin seninle.',
    'Kaybetmek de oyunun parçası. Önemli olan bir dahakine ne yapacağın.',
    'Bu sefer tahta kazandı. Rövanş senin elinde.',
    'Her oyun bir deneme. Bu da bir sonrakini daha iyi yapacak.',
    'Bitti ama sıradaki oyunun ilk parçası seni bekliyor.',
    'Bazen böyle olur. Bir tane daha, bu sefer sakin.',
  ],
  Voice.endTimedFirst: [
    'İlk bitişin: {time}. Artık yenmen gereken bir süre var.',
    'Parkuru bitirdin: {time}. Asıl yarış şimdi başlıyor, kendinle.',
  ],
  Voice.endTimedRecord: [
    'Yeni en iyi süre: {time}. Artık saatle yarışıyorsun.',
    'Bu parkuru hiç bu kadar hızlı bitirmemiştin: {time}.',
    'Eski süreni geçtin. Yeni hedefin {time}.',
  ],
  Voice.endTimedSlower: [
    'Bitirdin ama en iyi sürenin {secs} saniye gerisindesin. Yolu artık biliyorsun.',
    'Rekora {secs} saniye var. Bir sonraki koşuda daha az düşün, akışına bırak.',
    '{secs} saniye fark. İlk satırları biraz daha hızlı açarsan kapanır.',
  ],
  Voice.endTimedFail: [
    'Bitişe yetişemedin ama yolun yarısını öğrendin.',
    'Bu sefer süre yetmedi. Bir dahakine ilk satırları daha hızlı aç.',
    'Koşu yarım kaldı. Yarım kalan koşular en çok şey öğretir.',
  ],
  Voice.homeRecordFresh: [
    'Son oyunda rekor kırdın. Şimdi sıra onu korumakta.',
    'Yeni rekorun {score} puan. Onu geçecek ilk kişi yine sen olacaksın.',
  ],
  Voice.homeNearMiss: ['Son oyunda rekora {gap} puan kalmıştı. Yarım kalan bir iş var.', 'Rekorun {gap} puan ötede seni bekliyor.'],
  Voice.homeStreak: [
    '{days} gündür buradasın. Alışkanlık böyle kazanılır.',
    '{days} gün üst üste! Bu oyun artık gününün bir parçası.',
    'Üst üste {days} gün. Elin her gün biraz daha alışıyor.',
  ],
  Voice.homeNotToday: [
    'Dün en iyi oyununda {score} puan yapmıştın. Bugün henüz oynamadın.',
    'Dün {score} puana kadar çıkmıştın. Bugün nereye kadar?',
  ],
  Voice.homeBack: ['Tekrar hoş geldin! Tahta seni bekliyordu.', 'Bir süredir yoktun. El unutmaz, bir dene.'],
  Voice.homeGrowth: [
    'Son oyunlarının ortalaması yüzde {pct} yükseldi. Gelişiyorsun.',
    'Gidişat iyi: son oyunlarının ortalaması yüzde {pct} arttı.',
  ],
  Voice.homeWeek: [
    'Bu hafta {count} oyun oynadın. Tahtayı ezberlemeye başladın.',
    'Son yedi günde {count} oyun. Pratik yapa yapa geliyor.',
  ],
  Voice.homeNight: ['Gece turu mu? Tahta hazır.', 'Gece sessiz, oyun sakin.'],
  Voice.homeMorning: ['Günaydın! Zinde kafa, boş tahta.', 'Sabahın ilk oyunu hep en temizi olur.'],
};

const Map<Voice, List<String>> _en = {
  Voice.nearBest: [
    "{gap} points from your record. You're racing the best version of yourself.",
    'Just {gap} points between you and your best game.',
    'Your record is in sight: {gap} points away.',
    'This could really be a record now. {gap} points to go.',
    'No rush. {gap} points come to a steady hand.',
    'Your best game is just ahead: {gap} points.',
    '{gap} points from your own limit.',
    "You don't get here every game. {gap} points left.",
  ],
  Voice.newBest: [
    "You've never been here before. Every line from now on is new ground.",
    'New record. Everything after this is exploration.',
    "Your old record is behind you. You're off your own map now.",
    "Higher than anything you've ever scored. And you're still going.",
    "Record broken. Don't stop, see how far it goes.",
    'This is the moment you play for. New record.',
    "Yesterday's impossible score is now below you.",
    "The record is yours. Now push it so high even you'll struggle to beat it.",
  ],
  Voice.pastBest: [
    "You're not racing your old record anymore. You're racing tomorrow's you.",
    'Way past your old record. This game is setting the bar for the next one.',
    'Beating a record is one thing. Leaving it this far behind is another.',
    'Every line raises the bar for your next game.',
    "You'll remember this game.",
    "You're way up here. Take a breath and keep going.",
  ],
  Voice.aboveAverage: [
    'Past your average. Everything from here is a bonus.',
    'This is usually where your games end. Not today.',
    "You've passed the bar of an ordinary game. This is a good one now.",
    "Your average game is {avg} points. You've left it behind.",
    'From here on is ground most of your games never reach.',
    "You're above your average. Now turn good into unforgettable.",
  ],
  Voice.todayBest: [
    'This is now your best game today.',
    "You've topped every game you played today.",
    "Today's best, and it isn't over.",
    'Something is clicking today.',
    "Warm-up's over. This is today's real game.",
  ],
  Voice.comeback: [
    "Most people would have given up here. You didn't.",
    'The board hit the ceiling. You brought it back.',
    'Nobody saw that. But you know.',
    "You didn't panic. That's the real skill.",
    "A moment ago you were about to lose. Now you're in charge again.",
    'Your cleanest moves came at the hardest moment.',
    'Best moment of the game: the comeback.',
    'The board had you cornered. You stayed calm.',
  ],
  Voice.flow: [
    "You're in the flow. Don't think, just play.",
    'Your hands are moving before you think. Let them.',
    "You've found the rhythm.",
    'Every piece seems to know where it goes.',
    'You own this pace.',
    'Calm and fast. Your best state.',
    "You're not reading the board anymore. You're feeling it.",
    "The streak is growing. Don't break it.",
  ],
  Voice.firstQuadNew: [
    'First quad of the game. Waiting is a skill, and you have it.',
    "Four lines at once. That's how patient players play.",
    "You kept the well open and waited for the I piece. There's the payoff.",
    'You did that on purpose. Notice that?',
    "A quad. A sign you're taking this game seriously.",
  ],
  Voice.firstQuad: [
    "First quad's in. The rest is up to you.",
    'Open well, steady hand. Quad.',
    'The usual recipe: patience, a well, a quad.',
    "An opening quad. You've set the tone of this game.",
    'Games that open with a quad tend to last.',
  ],
  Voice.quadRecord: [
    "Quads this game: {count}. You've never made this many in one game.",
    "{count} quads. A personal record, and the game isn't over.",
    'A new peak in quads: {count}.',
    "Your most quads in one game used to be {prev}. Now it's {count}.",
  ],
  Voice.levelRecord: [
    "None of your recent games reached level {level}. Now you're here.",
    "Level {level}. You haven't been this far lately.",
    "This speed is new to you. And you're holding on.",
    "You've entered a speed you don't know yet. Your hands will catch up in a few pieces.",
    'Level {level}. You belong up here now.',
  ],
  Voice.maxSpeed: [
    'Top speed. Everything from here is up to you.',
    "The game can't get any faster. You can.",
    'Top gear. Steady your breathing.',
    'At this speed every decision takes less than a second. Trust yourself.',
  ],
  Voice.endurance: [
    '{lines} lines. Patience is a talent too.',
    "{lines} lines in and your focus hasn't slipped.",
    '{lines} lines. Long games take character.',
    "{lines} lines cleared and you're still playing calmly.",
  ],
  Voice.openNight: [
    'Late-night games are different. Take your time.',
    "It's late. The best games sometimes come in the quiet.",
    'At this hour the board is all yours.',
  ],
  Voice.openMorning: [
    'First game of the morning. Your mind is at its clearest.',
    'Fresh mind, empty board.',
    'Start the day with a calm game. The rest will follow.',
  ],
  Voice.openNearMiss: [
    'Last game you were {gap} points short of your record. This time?',
    'Unfinished business: the record. You were {gap} points away.',
    "Your last game turned back at the record's door. The door's still open.",
  ],
  Voice.openQuickLoss: [
    'The last game ended early. Place the first pieces slowly this time.',
    'A quick loss is just a warm-up.',
    'Forget the last game. This board is clean.',
  ],
  Voice.openStreak: [
    "{days} days in a row. That's how habits begin.",
    'Here again, {days} days running. Your hands know this game a little better every day.',
    "{days} days straight. That's no accident anymore.",
  ],
  Voice.endNewBest: [
    "Your best game ever. That's the score to beat from now on.",
    'New record: {score} points. That number will stay with you for a while.',
    "Your old record was {prev} points. Now it's {score}. Every point in between was earned.",
    "This game moved your limit. From now on you'll measure yourself here.",
    'Record set. Now the hard part: beating it again.',
  ],
  Voice.endNearMiss: [
    'It ended {gap} points short of your record. This close, are you leaving it here?',
    '{gap} points. The next game can close that gap.',
    'You made it to the record\'s door. The next game could open it.',
    "Getting this close and missing stings. That's a good sign: you belong there now.",
    'Your record stayed {gap} points away. One more while your hands are warm?',
  ],
  Voice.endAboveAverage: [
    'An above-average game. Stack enough of these and the record comes on its own.',
    'Your usual game is {avg} points. This one beat it. The line is going up.',
    "Not a record, but above your average. That's how good games add up.",
    'You were better than usual this game. Notice that.',
  ],
  Voice.endBestToday: [
    "Your best game today. There's still time to end the day with a record.",
    "The best of today's games. Your hands are warm.",
    "Not every game has to beat the last one, but this one did.",
  ],
  Voice.endWall: [
    "Most of your recent games end around level {level}. That's your wall, and walls are there to be climbed.",
    'Level {level} again. When the speed picks up, keep the stack low and away from the ceiling.',
    'Level {level} has stopped you a few times. Next time you get there, use the hold card.',
  ],
  Voice.endQuick: [
    'That was short. The first minutes are always the hardest.',
    'Ended early. Call it a warm-up, not a game.',
    'Sometimes the board starts out stubborn. The next one will be kinder.',
  ],
  Voice.endComeback: [
    "This game you nearly lost once and came back. That's worth more than the score.",
    "When the board hit the ceiling, you didn't give up. Remember that next time.",
    'The moment you came closest to losing was the moment you played best.',
  ],
  Voice.endGrowth: [
    'Your last five games average {pct} percent more than the ones before.',
    "You might not notice, but you're improving: your recent average is up {pct} percent.",
    'Your hands are learning this game. Recent average up {pct} percent.',
  ],
  Voice.endLoss: [
    "This game's over. You carry one thing into the next: what you learned here.",
    "Losing is part of the game. What matters is what you'll do differently.",
    'The board won this time. The rematch is yours.',
    'Every game is a try. This one will make the next one better.',
    "It's over, but the next game's first piece is already waiting.",
    'Sometimes the game goes like this. One more, but calmer this time.',
  ],
  Voice.endTimedFirst: [
    'Your first finish: {time}. Now you have a time to beat.',
    'Course finished: {time}. Now the real race begins, against yourself.',
  ],
  Voice.endTimedRecord: [
    'New best time: {time}. The clock is racing you now.',
    "You've never finished this course this fast: {time}.",
    'Your old time is behind you. {time} is the target from now on.',
  ],
  Voice.endTimedSlower: [
    'Finished, but {secs} seconds behind your best. You know the route now.',
    '{secs} seconds from your record. Next run, think less and flow more.',
    '{secs} seconds apart. Open the first lines a little faster and it closes.',
  ],
  Voice.endTimedFail: [
    "You didn't reach the finish line, but you learned half the route.",
    'Time ran out this time. Next run, open the first lines faster.',
    'The run was cut short. Unfinished runs teach the most.',
  ],
  Voice.homeRecordFresh: [
    'You broke your record last game. Now you get to defend it.',
    "Your new record is {score} points. The first to beat it will be you again.",
  ],
  Voice.homeNearMiss: [
    'Last game you were {gap} points short of your record. Unfinished business.',
    'Your record is waiting {gap} points away.',
  ],
  Voice.homeStreak: [
    "{days} days in a row. That's how a habit is built.",
    '{days} days straight. This game is part of your day now.',
    '{days} days running. Your hands are a little surer every day.',
  ],
  Voice.homeNotToday: [
    "Yesterday's best was {score} points. Today's page is still blank.",
    'Yesterday you reached {score} points. How far today?',
  ],
  Voice.homeBack: ['Welcome back. The board was waiting for you.', "It's been a while. Your hands haven't forgotten. Let's see."],
  Voice.homeGrowth: [
    "Your recent average is up {pct} percent. You're improving.",
    'The line is going up: your recent average rose {pct} percent.',
  ],
  Voice.homeWeek: [
    '{count} games this week. Your hands are learning this board by heart.',
    "{count} games in seven days. It's all adding up.",
  ],
  Voice.homeNight: ['A late round? The board is ready.', 'Quiet night, calm game.'],
  Voice.homeMorning: ['Good morning. Fresh mind, empty board.', "The day's first game is the cleanest one."],
};
