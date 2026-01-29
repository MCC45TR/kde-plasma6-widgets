# 🎵 MMusic Player (`music-player`)

### v1.2.5 (2026-01-29)
**TR-TR:**
- **Yeni Görünüm Modları**:
    - **Ekstra Büyük Mod (Extra Large Mode)**: Büyük albüm kapağı, detaylı oynatıcı kontrolleri, shuffle/loop butonları ve 10 saniyelik atlatma düğmeleri içeren yeni bir mod eklendi.
    - **Panel Görünümü (Panel Mode)**: Panel üzerinde daha şık, kompakt ve dinamik genişliğe sahip yeni bir görünüm tasarımı uygulandı.
- **Uluslararasılaştırma (i18n) Tamamlandı**: Kod tabanındaki tüm arayüz metinleri (`No Media`, `Previous`, `Next` vb.) `i18n()` sarmalına alınarak tam çeviri desteği sağlandı.
- **Yerelleştirme**: 19 farklı dil (TR, DE, FR, ES, IT, AZ, RU, JA, ZH, PT, RO, ID, CS, EL, HY, HI, BN, UR, FA) için çeviri dosyaları (`.po` ve `.mo`) güncellendi ve eksik olanlar sıfırdan oluşturuldu.
- **Hata Düzeltmesi**: Shuffle ve Loop butonlarının görsel durum geri bildirimleri ve mod döngüleri iyileştirildi.

**EN-US:**
- **New View Modes**:
    - **Extra Large Mode**: Added a new comprehensive mode featuring large artwork, shuffle/loop controls, and 10-second seek buttons.
    - **Enhanced Panel Mode**: Implementation of a sleek, compact, and dynamic-width representation specifically designed for the Plasma panel.
- **Full i18n Completion**: All remaining hardcoded UI strings were wrapped in `i18n()` calls for complete localization support.
- **Global Translations**: Added and updated translation files for 19 languages, including binary `.mo` compilation for performance.
- **Bug Fixes**: Improved shuffle and loop button visual states and cycle logic.


### v1.2.4 (2026-01-24)
**TR-TR:**
- **İyileştirme**: Widget kenar boşlukları artık ayarlanabiliyor ve bu ayar kalıcı olarak kaydediliyor.
- **Hata Düzeltmesi**: Widget kenar boşluğu ayarının her oturumda defaulta dönme sorunu giderildi.

**EN-US:**
- **Improvement**: Widget edge margins are now adjustable and settings are saved permanently.
- **Bug Fix**: Fixed the issue where the margin setting was resetting to default on every session.


### v1.3.0 (2026-01-22)
**TR-TR:**
- **Yeni Özellik**: Widget kenar boşluğu (Normal, Az, Yok) seçeneği eklendi.

**EN-US:**
- **New Feature**: Added "Widget Edge Margin" (Normal, Less, None) configuration.

### v1.2.2 (2026-01-17)
**TR-TR:**
- **Hata Düzeltmeleri:** Genel kararlılık iyileştirmeleri ve sürüm güncellemesi.

**EN-US:**
- **Bug Fixes:** General stability improvements and version bump.

### v1.2.1 (2026-01-16)
**TR-TR:**
- **Marka Yenileme (Rebranding)**: Widget adı **MMusic Player** olarak güncellendi.
- **Genişletilmiş Lokalizasyon**: Toplam 20 dil desteğine ulaşıldı.
- **Yapılandırma Düzeltmesi**: Genel ayarlar sekmesinde yaşanan görsel kaybolma ve syntax hataları giderildi.
- **Dökümantasyon**: Detaylı `README.md` eklendi.

**EN-US:**
- **Rebranding**: Renamed to **MMusic Player**.
- **Extended Localization**: Now supports 20 languages.
- **Config Fix**: Fixed the "General" settings tab visibility issue.

### v1.1.0 (2025-12-31)
**TR-TR:**
- **Dinamik Uygulama Rozeti (Pill Badge)**: Çalan uygulamanın ikonunu ve ismini gösteren, sistemle uyumlu yeni rozet tasarımı.
- **Gelişmiş Oynatıcı Bulma**: Aktif olmayan ancak çalışan MPRIS kaynaklarını tarama özelliği.
- **Sistem İkonu Entegrasyonu**: Kontrol butonları artık sistem ikon temasını (`media-*`) kullanıyor.
- **Hata Düzeltmeleri**: Hizalama ve reaktif güncelleme sorunları giderildi.

**EN-US:**
- **Dynamic App Badge**: New pill-shaped badge displaying the active player icon and name.
- **Advanced Discovery**: Scans all MPRIS sources to find preferred players even if not active.
- **System Icons**: Playback controls now use standardized system icons.

### v1.0.0 (2025-12-30)
**TR-TR:**
- Butonlar için yönlü genişleme/daralma animasyonu (squeeze effect) eklendi.
- Önceki/Sonraki butonları asimetrik yuvarlatılmış dikdörtgen formuna dönüştürüldü (2025-12-29).
