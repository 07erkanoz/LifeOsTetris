<p align="center">
  <img src="docs/images/icon.png" width="120" alt="LifeOS Küpler ikonu">
</p>

<h1 align="center">LifeOS Küpler</h1>

<p align="center">
  Düşen blokları dizip satırları patlattığın, sürükle-bırak bulmacalarla dolu, bol efektli 2.5D blok oyunu.<br>
  Android · iOS · Windows · Linux · macOS · Web
</p>

<p align="center">
  <a href="https://github.com/07erkanoz/LifeOsTetris/actions/workflows/build.yml"><img src="https://github.com/07erkanoz/LifeOsTetris/actions/workflows/build.yml/badge.svg" alt="Derleme durumu"></a>
</p>

---

## İndir ve dene

| Platform | Dosya |
|---|---|
| Android (modern telefonlar, küçük) | [LifeOS-Kupler-arm64.apk](https://github.com/07erkanoz/LifeOsTetris/releases/download/test-build/LifeOS-Kupler-arm64.apk) |
| Android (tüm telefonlar) | [LifeOS-Kupler.apk](https://github.com/07erkanoz/LifeOsTetris/releases/download/test-build/LifeOS-Kupler.apk) |
| Windows | [LifeOS-Kupler-Windows.zip](https://github.com/07erkanoz/LifeOsTetris/releases/download/test-build/LifeOS-Kupler-Windows.zip) |
| Linux (x64, Arch dahil) | [LifeOS-Kupler-Linux-x64.tar.gz](https://github.com/07erkanoz/LifeOsTetris/releases/download/test-build/LifeOS-Kupler-Linux-x64.tar.gz) |

- **Android:** Linki telefonun tarayıcısında aç ve inen APK'yı kur. "Bilinmeyen kaynaklardan
  yükleme" izni istenebilir.
- **Windows:** Zip'i bir klasöre çıkar ve `lifeos_kupler.exe` dosyasını çalıştır. SmartScreen
  uyarırsa *Ek bilgi → Yine de çalıştır* de.
  Zip şifreli değildir. Windows çıkartırken şifre sorarsa zip'e sağ tıkla,
  *Özellikler → Engellemeyi kaldır* kutusunu işaretle ve tekrar *Tümünü ayıkla* de
  (ya da 7-Zip ile aç). Oyun tam ekran açılır; **F11** veya **Alt+Enter** pencereye geçirir.
- **Arch Linux:** Depodaki [`packaging/arch/PKGBUILD`](packaging/arch/PKGBUILD) ile kur:
  ```bash
  git clone https://github.com/07erkanoz/LifeOsTetris && cd LifeOsTetris/packaging/arch
  makepkg -si          # uygulama menüsünde "LifeOS Küpler" olarak görünür
  ```
- **Diğer Linux dağıtımları:** `tar.gz` dosyasını aç ve `LifeOS-Kupler/lifeos_kupler` dosyasını
  çalıştır. Gerekenler: GTK 3 ve GStreamer (base + good eklentileri; yoksa oyun sessiz çalışır).

Bunlar test derlemeleridir ve `main` dalına yapılan her gönderimde otomatik olarak
yenilenir ([Releases → Test sürümü](https://github.com/07erkanoz/LifeOsTetris/releases/tag/test-build)).

## Ekran görüntüleri

| Menü | Süper Küpler: dörtlü ve yeni güç | Süper Küpler: bomba |
|:---:|:---:|:---:|
| <img src="docs/images/menu.jpg" width="240"> | <img src="docs/images/dortlu.jpg" width="240"> | <img src="docs/images/super-bomba.jpg" width="240"> |

| Bulmaca Küpler | Nişan alma | Patlama |
|:---:|:---:|:---:|
| <img src="docs/images/bulmaca-menu.jpg" width="240"> | <img src="docs/images/bulmaca.jpg" width="240"> | <img src="docs/images/bulmaca-patlama.jpg" width="240"> |

<p align="center"><img src="docs/images/masaustu.jpg" width="720" alt="Masaüstü: Süper Küpler"></p>
<p align="center"><img src="docs/images/bulmaca-masaustu.jpg" width="720" alt="Masaüstü: Bulmaca Küpler"></p>

## Oyun modları

### ✨ Süper Küpler
Satır sildikçe **enerji** dolar: her 3 satır 1 güç verir. 6 gücün hepsi her zaman ekranda,
kaç tane olduğuyla birlikte görünür (her birinden en fazla 3). Güçler karışık sırayla gelir:
altısı da gelmeden hiçbiri tekrar etmez. Kullanmak için gücün simgesine dokun ya da
**1–6** tuşlarına bas.

| Güç | Etkisi |
|---|---|
| 💣 Bomba | Düştüğü yerde 3×3 alanı patlatır (hedef alanı önceden gösterilir) |
| ▪️ Tekli blok | Tek karelik parça; kapanmış delikleri doldurur |
| 🔩 Matkap | Blokların içinden geçer, bütün sütunu yer |
| ⬇️ Yerçekimi | Havada kalan bloklar düşer, dolan satırlar silinir (düşecek blok yoksa kullanılamaz, boşa gitmez) |
| ⏳ Ağır çekim | 10 saniye boyunca her şey yavaşlar |
| 👻 Hayalet Çizgi | Yığının içinden süzülür; dokununca bulunduğu satırın boşluklarını doldurur |

### 🧩 Bulmaca Küpler
Sürükle-bırak blok bulmacası: 8×8 tahta, tepside 3 parça. Parçaları istediğin yere
sürükle; dolan **satır ve sütunlar** birlikte patlar. Parçalar dönmez, düşmez.

- **Seviyeler:** 10 bölümde **100 seviye**. Hamle sınırı içinde tahtadaki bütün altın ★
  blokları patlat. Her açılışta **yeni, rastgele** bir tahta ve parça listesi üretilir; zorluk
  (★ sayısı, tahtanın doluluğu, yedek hamle, zor parçalar) seviyeyle artar.
- Her seviye, gösterilmeden önce bir çözücü tarafından oyun motorunda oynanır: **her seviye
  çözülebilir**. Çözücünün hamle sayısı ★★★ hedefini belirler.
- **Sonsuz:** Yer kalmayana kadar rekor için oyna. Tepsiye her zaman sığan bir parça gelir.
- Nişan alırken patlayacak satır ve sütunlar parçanın rengiyle parlar. Arka arkaya
  patlatmak kombo verir, tahtayı tamamen boşaltmak bonus verir.

### 🎮 Klasik Küpler
- **Normal:** Hız 10. seviyeye kadar yavaşça artar, sonra sabit kalır.
- **Rahat:** Sabit, sakin hız; oyun sonsuza kadar sürer.

Her modun rekoru ayrı tutulur.

## Özellikler

- **Görünüm:** 2.5D "jelibon" bloklar, koyu ve açık tema, telefon ve masaüstü için ayrı
  yerleşim. Tahta her ekrana tam oturur.
- **Efektler:** Parçacık patlamaları, ekran sarsıntısı, sert düşüş izleri, şok dalgaları,
  satır çökme ve seviye atlama animasyonları, "ÇİFT! / DÖRTLÜ! / KOMBO ×2" yazıları,
  hareketli arka plan.
- **Motivasyon yazıları:** Puan ve satır hedefleri, rekor kırma, ilk dörtlü, kombo serileri,
  kıl payı kurtuluşlar ve ara sıra övgüler.
- **Ses:** Oyuna özel üretilmiş efekt sesleri; rastgele sırayla çalan müzik listesi.
- **Dil:** Türkçe ve İngilizce. İlk açılışta cihaz diline göre seçilir.
- **Ayarlar:** Ekran butonlarını gizleme ve saydamlıklarını ayarlama, titreşim ve gücü, ekran
  sarsıntısı, görsel efektler, müzik ve efekt sesi, tam ekran (Windows). Hepsi kaydedilir.
- **Oyun kuralları:** Tutma, hayalet parça, 7'li torba, SRS döndürme, T-spin, kombo, B2B,
  mükemmel temizlik.

## Kontroller

| Klavye | Dokunmatik | Eylem |
|---|---|---|
| ← → | Yatay kaydır / butonlar | Taşı |
| ↑ veya X | Tahtaya dokun | Döndür |
| Z | – | Ters döndür |
| ↓ | Aşağı kaydır | Yumuşak düşüş |
| Space | Aşağı fırlat / ⇊ butonu | Sert düşüş |
| C | TUT kartına dokun / yukarı fırlat | Tut |
| P, Esc | ⏸ | Duraklat |
| 1–6 | Gücün simgesine dokun | Gücü kullan (Süper Küpler) |
| Fare ile sürükle | Parmakla sürükle | Parça yerleştir (Bulmaca Küpler) |
| F11, Alt+Enter | – | Tam ekran (Windows) |

## Geliştirme

```bash
flutter pub get
flutter test                 # oyun kuralları, güçler, bulmaca üretici, arayüz testleri
flutter run                  # bağlı cihaz veya masaüstü
flutter build apk --release  # Android
```

| Komut | Ne yapar |
|---|---|
| `python3 tool/generate_sfx.py` | Efekt seslerini yeniden üretir (numpy gerekir) |
| `dart run flutter_launcher_icons` | `assets/icon/` içindeki kaynaktan tüm platform ikonlarını üretir |
| `python3 tool/make_windows_icon.py` | Windows ikonunu tüm boyutlarıyla üretir (Pillow gerekir) |
| `--dart-define=KUPLER_DEMO=true` | Oyunu neredeyse dolu tahtayla başlatır (efekt demosu) |
| `--dart-define=KUPLER_DEMO_SUPER=true` | Süper Küpler'i birkaç güçle başlatır |
| `--dart-define=KUPLER_DEMO_BLOCKS=true` | Doğrudan Bulmaca Küpler'i açar; Sonsuz mod hazır bir tahtayla başlar |

### Proje yapısı

```
lib/core/          Saf oyun mantığı: kurallar ve güçler (Flutter'dan bağımsız)
lib/core/blocks/   Bulmaca Küpler: tahta, parçalar, seviye üretici ve çözücü
lib/game/          Kontrolcü, efekt motoru, motivasyon, çizim (sprite'lar, tahta, arka plan)
lib/game/blocks/   Bulmaca Küpler kontrolcüsü, efektleri ve çizimi
lib/platform/      Windows tam ekran köprüsü
lib/audio/         Efekt sesleri, müzik listesi, titreşim
lib/ui/            Ekranlar ve bileşenler (oyun, Bulmaca Küpler, güç barı, Hakkında)
lib/l10n/          Türkçe / İngilizce metinler
lib/theme/         Koyu / açık renk paleti
assets/            Yazı tipi, sesler, müzikler, ikon kaynağı
packaging/         Linux masaüstü kısayolu ve Arch Linux PKGBUILD
tool/              Ses ve Windows ikonu üreticileri
```

## Üçüncü taraf içerikler

- **Inter yazı tipi:** SIL Open Font License 1.1 ([assets/fonts/OFL.txt](assets/fonts/OFL.txt)).
- **Müzikler:** Pixabay ve Free To Use (freetouse.com) parçaları; kendi lisanslarına tabidir
  ([assets/audio/music/CREDITS.md](assets/audio/music/CREDITS.md)).
- **Ses efektleri ve ikon:** Bu proje için üretildi.

## Lisans

© 2026 Erkan ÖZ. **Tüm hakları saklıdır.** Kaynak kodu, grafikler, ikon, ses efektleri ve
oyun tasarımı izinsiz kopyalanamaz, değiştirilemez, dağıtılamaz veya satılamaz. Ayrıntılar
için [LICENSE](LICENSE) dosyasına bakın. Müzikler ve yazı tipi kendi lisanslarına tabidir.

## Geliştirici

**Erkan ÖZ** · [erkanoz.com](https://erkanoz.com) · LifeOS ailesinin bir parçası:
[lifeos.com.tr](https://lifeos.com.tr)
