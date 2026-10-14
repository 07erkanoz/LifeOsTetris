# LifeOS Küpler

Düşen blokları dizip satırları patlattığın, bol efektli 2.5D blok bulmaca oyunu.
Flutter ile yazıldı; Android, iOS, Windows, Linux, macOS ve web'de çalışır.

Geliştirici: **Erkan ÖZ** · [lifeos.com.tr](https://lifeos.com.tr)

## Özellikler

- **Süper Küpler:** satır sildikçe dolan enerji barı (3 satır = 1 güç, dörtlü
  bar'ı anında doldurur, en fazla 3 güç) ve 6 güç: 💣 Bomba (3×3 patlatır),
  ▪️ Tekli blok, 🔩 Matkap (blokları delip sütunu yer), 🧲 Yerçekimi (havadaki
  bloklar düşer), ⏳ Ağır çekim (10 sn) ve 👻 Hayalet Çizgi (yığının içinden
  süzülür, dokununca bulunduğu satırın boşluklarını doldurur).
- **Bulmaca Küpler:** 10 bölümde 100 bulmaca. Tahtada altın ★ bloklar var;
  sadece verilen parçalarla hepsini temizlemek gerekiyor. Parçalar kendiliğinden
  düşmez. Her seviye her açılışta **yeni, rastgele** bir tahta üretir; üretilen
  her tahta oyun motorunda oynatılarak çözülebilir olduğu doğrulanır. 2 parça
  artırırsan ★★★, 1 parça ★★, hiç artırmazsan ★. Çözdükçe sıradaki açılır.
- **Klasik Küpler:** *Normal* (hız 10. seviyeye kadar yavaşça artar, sonra sabit)
  ve *Rahat* (sabit, sakin hız). Her modun rekoru ayrı tutulur.
- **Koyu ve açık tema**, telefon ve masaüstü için ayrı yerleşim; ekran ne olursa
  olsun tahta ekrana tam oturur.
- **Efektler:** parçacık patlamaları, ekran sarsıntısı, sert düşüş izleri, şok
  dalgaları, satır çökme animasyonu, seviye atlama dalgası, oyun sonu dağılması,
  "ÇİFT! / DÖRTLÜ! / KOMBO ×2" yazıları ve hareketli arka plan.
- **Ses:** oyuna özel üretilmiş efekt sesleri ve rastgele sırayla çalan 4 müzik.
- **Motivasyon yazıları:** puan ve satır hedefleri, rekor kırma, ilk dörtlü, kombo
  serileri, kıl payı kurtuluşlar ve ara sıra övgüler tahtanın üstünde belirir.
- **Dil:** Türkçe ve İngilizce (ilk açılışta cihaz diline göre seçilir, menüden ve
  ayarlardan değiştirilebilir).
- Tutma, hayalet parça, 7'li torba, SRS döndürme, T-spin, kombo, B2B, mükemmel
  temizlik.

## Kontroller

| Klavye | Dokunmatik | Eylem |
|---|---|---|
| ← → | Yatay kaydır / butonlar | Taşı |
| ↑ veya X | Tahtaya dokun | Döndür |
| Z | – | Ters döndür |
| ↓ | Aşağı kaydır | Yumuşak düşüş |
| Space | Aşağı fırlat / ⇊ butonu | Sert düşüş |
| C | Yukarı fırlat / ⇅ butonu | Tut |
| P, Esc | ⏸ | Duraklat |
| 1 · 2 · 3 | Güç yuvasına dokun | Gücü kullan (Süper Küpler) |

## Geliştirme

```bash
flutter pub get
flutter test
flutter run                 # bağlı cihaz / masaüstü
flutter build apk --release # Android
```

- Efekt seslerini yeniden üretmek: `python3 tool/generate_sfx.py` (numpy gerekir).
- Efekt demosu: `flutter run --dart-define=KUPLER_DEMO=true` neredeyse dolu bir
  tahtayla başlar; ilk sert düşüşte dörtlü silme ve seviye atlama görülür.
  `--dart-define=KUPLER_DEMO_SUPER=true` eklenirse Süper Küpler'de, güç
  yuvaları dolu başlar. `KUPLER_DEMO_PUZZLE=<n>` Enter ile n. bulmacayı,
  `KUPLER_DEMO_LEVELS=true` bulmaca seçim ekranını açar.

### Proje yapısı

```
lib/core/      Saf oyun mantığı (Flutter'dan bağımsız, testli)
lib/game/      Kontrolcü, efekt motoru, çizim (blok sprite'ları, tahta, arka plan)
lib/audio/     Efekt sesleri ve karışık çalan müzik listesi
lib/ui/        Ekranlar ve bileşenler (oyun, menüler, Hakkında)
lib/l10n/      Türkçe / İngilizce metinler
lib/theme/     Koyu / açık renk paleti
assets/        Yazı tipi (Inter, OFL), sesler, müzikler (bkz. assets/audio/music/CREDITS.md)
```

## Test sürümü (Android)

`main` dalına her gönderimde GitHub Actions bir APK derler ve
**Releases → Test sürümü** altına koyar:

- `LifeOS-Kupler-arm64.apk` – modern telefonlar için küçük APK
- `LifeOS-Kupler.apk` – tüm Android telefonlar
- `LifeOS-Kupler-Windows.zip` – klasörü çıkarıp `lifeos_kupler.exe` çalıştırılır

Telefondan doğrudan indirmek için tarayıcıda:
https://github.com/07erkanoz/LifeOsTetris/releases/download/test-build/LifeOS-Kupler-arm64.apk
