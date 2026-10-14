# LifeOS Küpler

Düşen blokları dizip satırları patlattığın, bol efektli 2.5D blok bulmaca oyunu.
Flutter ile yazıldı; Android, iOS, Windows, Linux, macOS ve web'de çalışır.

Geliştirici: **Erkan ÖZ** · [lifeos.com.tr](https://lifeos.com.tr)

## Özellikler

- **İki mod:** *Klasik* (hız 10. seviyeye kadar yavaşça artar, sonra sabit) ve
  *Rahat* (sabit, sakin hız).
- **Koyu ve açık tema**, telefon ve masaüstü için ayrı yerleşim; ekran ne olursa
  olsun tahta ekrana tam oturur.
- **Efektler:** parçacık patlamaları, ekran sarsıntısı, sert düşüş izleri, şok
  dalgaları, satır çökme animasyonu, seviye atlama dalgası, oyun sonu dağılması,
  "ÇİFT! / DÖRTLÜ! / KOMBO ×2" yazıları ve hareketli arka plan.
- **Ses:** oyuna özel üretilmiş efekt sesleri ve rastgele sırayla çalan 4 müzik.
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

### Proje yapısı

```
lib/core/      Saf oyun mantığı (Flutter'dan bağımsız, testli)
lib/game/      Kontrolcü, efekt motoru, çizim (blok sprite'ları, tahta, arka plan)
lib/audio/     Efekt sesleri ve karışık çalan müzik listesi
lib/ui/        Ekranlar ve bileşenler (oyun, menüler, Hakkında)
lib/theme/     Koyu / açık renk paleti
assets/        Yazı tipi (Inter, OFL), sesler, müzikler (bkz. assets/audio/music/CREDITS.md)
```

## Test sürümü (Android)

`main` dalına her gönderimde GitHub Actions bir APK derler ve
**Releases → Test sürümü** altına koyar. Telefondan indirip kurabilirsin.
