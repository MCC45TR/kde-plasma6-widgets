# 📂 Plasma 6 Widgets Changelog

Bu dosyalarda projedeki her bir widget için yapılan değişiklikler sürümlerine göre gruplandırılmıştır.

---

## 🔍 MFile Finder (`file-search`)

### v1.2.2 (2026-01-25)
**TR:**
- **Dil Desteği Güncellemesi:** Birçok dil için (`es`, `it`, `pt`, `ru`, `ja`, `zh`, `hi`, `hy`, `id`, `ro`, `ur`) çeviriler güncellendi ve eksik dizeler tamamlandı.
**EN:**
- **Translation Updates:** Updated translations for multiple languages (Spanish, Italian, Portuguese, Russian, Japanese, Chinese, Hindi, Armenian, Indonesian, Romanian, and Urdu).

### v1.2.1 (2026-01-22)
**TR:**
- **Panel Yüksekliği Özelleştirmesi:** Manuel ayar (18-96px) ve "Otomatik" seçeneği eklendi.
**EN:**
- **Panel Height Customization:** Added manual height configuration with an "Automatic" option.

### v1.2.0 (2026-01-18)
**TR:**
- **Yapılandırma Penceresi Onarımı:**
    - Eksik sekmeler düzeltildi ve yeniden yapılandırıldı (`General`, `Search`, `Preview`, `Categories`, `Debug`, `Help`).
    - **Prefixes (Önekler)** sekmesi eklendi; mevcut arama komutları (`gg:`, `date:`, `power:` vb.) listelendi.
    - QML sözdizimi hataları ve eksik özellik uyarıları giderildi.
- **Power View İyileştirmeleri:**
    - "Oturumu Kapat" ve "Kullanıcı Değiştir" butonlarına **çift tıklama onayı** (Double-click Confirmation) eklendi.
    - Buton yerleşimleri ve aralıklar optimize edildi.
- **UI & UX Düzeltmeleri:**
    - **Buton Modu:** Popup açılırken içeriğin panel düğmesinin arkasında kalmaması için **üst boşluk (top margin)** eklendi.
    - **Arama Çubuğu:** Buton modunda arama çubuğu ile liste arasındaki gereksiz boşluk kaldırıldı.
- **Teknik Düzeltmeler:**
    - `ConfigCategories.qml` dosyasının `CategoryManager` import hatası giderildi.
    - `metadata.json` yapılandırma yolu (`contents/config/config.qml`) standartlara uygun hale getirildi.

**EN:**
- **Configuration Window Repair:**
    - Fixed missing tabs and restructured config components (`General`, `Search`, `Preview`, `Categories`, `Debug`, `Help`).
    - Added **Prefixes** tab listing available search commands (`gg:`, `date:`, `power:`, etc.).
    - Resolved QML syntax errors and missing property definitions.
- **Power View Improvements:**
    - Added **double-click confirmation** for "Log Out" and "Switch User" buttons to prevent accidental clicks.
    - Optimized layout spacing and alignment.
- **UI & UX Fixes:**
    - **Button Mode:** Added **top margin** (50px) to popup content to prevent overlapping with the panel button when opening upwards.
    - **Search Bar:** Removed extra gap between the search bar and results list in Button Mode.
- **Technical Fixes:**
    - Fixed `CategoryManager` import in `ConfigCategories.qml`.
    - Corrected configuration module path in `metadata.json`.

### v1.1.5-beta (2026-01-17)
**TR:**
- **Sabitlenmiş Öğeler UI:** Arka plan, yuvarlatılmış köşeler ve animasyonlu daralma/genişleme özelliği eklendi. Boşluklar dengelendi.
- **Özel "date:" Görünümü:** Arama çubuğuna `date:` yazıldığında çıkan devasa saat ve tarih ekranı eklendi.
- **Özel "help:" Görünümü:** Tüm prefixleri ve açıklamalarını listeleyen yardım ekranı eklendi.
- **Barlow Condensed Yazı Tipi:** Saat ve tarih ekranı için font widget'a gömüldü.
- **Prefix İyileştirmeleri:** `gg:`, `dd:`, `wp:` gibi komutlarda arama metninin ipucunda görünmesi sağlandı ve Enter ile çalışma hataları giderildi.
- **Kategori Ayarları:** "Smart Limit" etkinken limit girişlerinin pasifleşmesi sağlandı ve kategori listesindeki görsel kaymalar düzeltildi.

**EN:**
- **Pinned Items UI:** Added background, rounded corners, and animated collapse/expand. Balanced spacing.
- **Special "date:" View:** Added a massive clock and date screen when searching for `date:`.
- **Special "help:" View:** Added a help screen listing all available prefixes and their descriptions.
- **Barlow Condensed Font:** Embedded the font for the date/time view.
- **Prefix Enhancements:** Dynamic query hints for `gg:`, `dd:`, `wp:`, etc., and fixed Enter execution bugs.
- **Category Settings:** Disabled limit inputs when "Smart Limit" is active and fixed UI overlaps in the category list.

### v1.1.4-beta (2026-01-17)
**TR:**
- **KRunner Prefix Desteği:** 
    - Yeni önekler eklendi: `app:`, `shell:`, `b:`, `power:`, `services:`, `date`, `define:`, `unit:`, `help:`.
    - `man:/` öneki için sistemde kurulu değilse uyarı verme özelliği eklendi.
- **Döşeme Görünümü (Tile View) İyileştirmeleri:**
    - "Geniş Kategoriler" (Tarih, Hesap Makinesi, Sözlük vb.) için tam genişlikte kart tasarımı.
    - Klavye yön tuşları ve `Enter` ile seçim başlatma desteği (Sonuçlar ve Geçmiş için).
- **Lokalizasyon:** Yeni prefixler için Türkçe ve İngilizce çeviriler eklendi.

**EN:**
- **KRunner Prefix Support:**
    - Added new prefixes: `app:`, `shell:`, `b:`, `power:`, `services:`, `date`, `define:`, `unit:`, `help:`.
    - Added warning support for `man:/` prefix if the package is missing.
- **Tile View Improvements:**
    - Designed full-width card view for "Wide Categories" (Date, Calculator, Dictionary etc.).
    - Added keyboard navigation (Arrow keys) and `Enter` activation support for both results and history.
- **Localization:** Added translations for new prefixes.

### v1.1.3-alpha (2026-01-17)
**TR:**
- **Backend-Frontend Entegrasyonu:** 
    - `CategoryManager.js` fonksiyonları (`applyPriorityToResults`, `filterHiddenCategories`, `isCategoryVisible`) `TileDataManager`'da aktif.
    - `SimilarityUtils.js` benzerlik sıralaması arama sonuçlarına uygulanıyor.
    - `TelemetryManager.resetStats()` için Debug ayarlarına "İstatistikleri Sıfırla" butonu eklendi.
    - `PinnedManager.getPinInfo()` ve aktivite yönetimi fonksiyonları entegre edildi.
- **Yapılandırma Yönetimi (ConfigManager.js):**
    - Profil bazlı varsayılanlar (Minimal, Developer, Power User).
    - Yapılandırma doğrulama ve özellik bayrakları (`isFeatureEnabled`).
- **Panel Algılama:** Widget masaüstünde yer alıyorsa otomatik olarak Button Mode gibi davranır.
- **Sağ Tık Menüsü:** 
    - Liste ve Döşeme görünümleri için sağ tık context menu desteği eklendi.
    - `QtQuick.Controls.Menu` kullanılarak daha iyi uyumluluk sağlandı.
- **Önizleme Kontrolü:** `previewEnabled` ayarı backend zinciri ile bağlandı.

**EN:**
- **Backend-Frontend Integration:**
    - `CategoryManager.js` functions now active in `TileDataManager`.
    - `SimilarityUtils.js` similarity sorting applied to search results.
    - Added "Reset Statistics" button in Debug settings.
    - Integrated `PinnedManager.getPinInfo()` and activity management functions.
- **Configuration Management (ConfigManager.js):**
    - Profile-based defaults (Minimal, Developer, Power User).
    - Config validation and feature flags (`isFeatureEnabled`).
- **Panel Detection:** Widget automatically uses Button Mode when placed on desktop.
- **Right-Click Menu:** 
    - Added context menu support for both List and Tile views.
    - Migrated to `QtQuick.Controls.Menu` for better compatibility.
- **Preview Control:** `previewEnabled` setting properly chained to backend.

### v1.1.2-alpha (2026-01-17)
**TR:**
- **Hızlı Uygulama Başlatma:** Geçmişten tıklanan uygulamaların (`.desktop`) `kioclient exec` ile anında başlatılması sağlandı.
- **Mimari Yenilenme:** Kod yapısı `LogicController`, `TileDataManager` ve `SearchPopup` bileşenlerine ayrılarak modüler hale getirildi.
- **Tembel Yükleme (Lazy Loading):** Tüm bileşenlerde asenkron yükleme yapılarak açılış hızı artırıldı ve kaynak tüketimi azaltıldı.
- **Görsel İyileştirmeler:**
    - Geçmiş öğeleri için sağ tık bağlam menüsü (Context Menu) eklendi.
    - İkon ve dosya yolu yakalama mantığı geliştirildi.
    - Yerleşim ve anchor (çapa) hataları giderildi.
- **Hata Düzeltmeleri:** `HistoryListView` ve `HistoryTileView` bileşenlerindeki tıklama sorunları ve sözdizimi hataları düzeltildi.
- **Görev Takibi:** Geliştirme süreci için `TODO.md` dosyası oluşturuldu.

**EN:**
- **Instant App Launch:** Enabled direct execution of `.desktop` files from history using `kioclient exec`.
- **Architectural Refactor:** Split `main.qml` into `LogicController`, `TileDataManager`, and `SearchPopup` for better maintainability.
- **Asynchronous Lazy Loading:** Implemented for all UI components to minimize resource footprint and improve startup time.
- **UI & Experience:**
    - Added context menu for history items.
    - Improved file/folder icon fetching.
    - Fixed layout/anchor issues.
- **Bug Fixes:** Resolved missing onClicked handlers and syntax errors in History list and tile views.
- **Dev Workflow:** Added `TODO.md` to track planned features and fixes.

### v1.1.1-alpha (2026-01-16)
**TR-TR:**
- **Genişletilmiş Dil Desteği:** 20 farklı dilde yerelleştirme desteği tamamlandı.
- **Dökümantasyon:** README dosyası güncel ekran görüntüleri ile yenilendi.

**EN-US:**
- **Extended Localization:** Completed localization support for 20 different languages.
- **Documentation:** Updated README with new screenshots.

### v1.1.0-alpha (2026-01-01)
**TR-TR:**
- **Modülerleştirme:** Kullanıcı arayüzü tamamen modüler QML bileşenlerine ayrıştırıldı (`CompactView`, `ResultsListView`, `HistoryTileView` vb.).
- **Yerelleştirme:** Senkron JavaScript tabanlı yerelleştirme sistemine (`localization.js`) geçildi.
- **Geçmiş Yönetimi:** `HistoryManager.js` modülüne taşınarak kod yapısı temizlendi.
- **Gelişmiş Klavye Navigasyonu:**
    - Döşeme görünümünde ↑↓←→ tuşlarıyla akıllı gezinme.
    - Tab/Shift+Tab ile bölümler arası geçiş.
    - Ctrl+1/2 ile görünüm modları arası hızlı geçiş.
    - Ctrl+Space ile dosya önizleme açma/kapama.
- **Akıllı Arama (Smart Query):** KRunner prefix'lerini algılayan ipucu sistemi (`timeline:`, `gg:`, `dd:`, `kill`, `spell`, `#unicode`).
- **Hover Önizleme:** Dosya üzerine gelince thumbnail, tür ve yol bilgilerini gösteren gelişmiş tooltip.
- **Görünüm Profilleri:** Minimal / Developer / Power User profilleri ve yeni yapılandırma sekmeleri eklendi.
- **Debug & Telemetry:** Gerçek zamanlı gecikme ölçümü ve `DebugOverlay.qml` entegrasyonu.
- **Performans:** Tile view'lar için `Loader` ile lazy loading ve virtualization desteği.
- **Hata Düzeltmeleri:** QML ReferenceError hataları ve geçmişten uygulama başlatma sorunları giderildi.

**EN-US:**
- **Modularization:** Entire UI refactored into modular QML components (`CompactView`, `ResultsListView`, etc.).
- **Localization:** Migrated to synchronous `localization.js` system.
- **Advanced Keyboard Navigation:** Smart tile navigation with arrow keys, section cycling with Tab, and quick view switching.
- **Smart Query:** Added `QueryHints` for KRunner prefixes.
- **Hover Preview:** Enhanced tooltips with thumbnails and file metadata.
- **View Profiles:** Introduced Minimal / Developer / Power User profiles.
- **Performance:** Lazy loading for tiles and list virtualization.

### v1.0.5 (2025-12-31)
**TR-TR:**
- Geçmiş öğelerini doğrudan çalıştırma özelliği eklendi.
- Döşeme görünümünde tıklama sorunları düzeltildi.
- Simge boyutu ayarları ve üst klasör yolu gösterimi eklendi.
- Akıllı zaman damgası (timestamp) gösterimi sağlandı.

**EN-US:**
- Added support for direct execution of history items.
- Fixed non-clickable items in tile view.
- Added icon size settings and parent directory display.

---

## 🌐 MBrowser Search (`browser-search`)

### v1.1.0 (2026-01-22)
**TR:**
- **Kenar Boşluğu Ayarı:** "Widget Margin" seçeneği (Normal, Az, Yok) eklendi.
**EN:**
- **Edge Margin Setting:** Added "Widget Margin" configuration (Normal, Less, None).

### v1.0.0 (2025-12-30)
- İlk sürüm; hızlı arama ve tarayıcı kısayolları.

---

## 🎵 MMusic Player (`music-player`)

### v1.2.4 (2026-01-24)
**TR:**
- **İyileştirme**: Widget kenar boşlukları artık ayarlanabiliyor ve bu ayar kalıcı olarak kaydediliyor.
- **Hata Düzeltmesi**: Ayarın her oturumda sıfırlanma sorunu giderildi.
**EN:**
- **Improvement**: Widget edge margins are now adjustable and settings are saved permanently.
- **Bug Fix**: Fixed the issue where the margin setting was resetting to default on every session.

### v1.3.0 (2026-01-22)
**TR:**
- **Kenar Boşluğu Ayarı:** "Widget Margin" seçeneği (Normal, Az, Yok) eklendi.
**EN:**
- **Edge Margin Setting:** Added "Widget Margin" configuration (Normal, Less, None).

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

---

## 🌤️ MWeather (`weather`)

### v1.1.8 (2026-01-22)
**TR:**
- **Kenar Boşluğu Ayarı:** "Widget Margin" seçeneği (Normal, Az, Yok) eklendi.
**EN:**
- **Edge Margin Setting:** Added "Widget Margin" configuration (Normal, Less, None).

### v1.1.5 (2026-01-16)
**TR-TR:**
- **UI Düzeltmesi**: Küçük modda uzun hava durumu açıklamalarının (örn. "Parçalı Bulutlu") kesilmesi sorunu metin kaydırma (Word Wrap) ile düzeltildi.

**EN-US:**
- **Small Mode Fix**: Resolved text truncation for long weather descriptions using Word Wrap.

### v1.1.4 (2026-01-16)
**TR-TR:**
- **Marka Yenileme**: Uygulama adı **MWeather** olarak güncellendi.
- **KDE Discover Desteği**: `metainfo.xml` eklenerek mağaza entegrasyonu sağlandı.
- **Modüler Mimari**: `main.qml` dosyası `SmallMode`, `WideMode` ve `LargeMode` olarak parçalandı.
- **Gelişmiş Animasyonlar**: Detaylar paneli için "Morphing Details" animasyonu eklendi.
- **Görsel İyileştirmeler**: 3 yeni Google Hava Durumu tarzı ikon paketi ve optimize edilmiş sıcaklık gösterimi.

**EN-US:**
- **Rebranding**: Renamed to **MWeather**.
- **Discover Integration**: Added AppStream `metainfo.xml`.
- **Modular Refactor**: Split layout into Small, Wide, and Large components.
- **Advanced Animations**: Added "Morphing Details" transition.
- **Visuals**: 3 new icon packs (Google style) and optimized temperature layout.

---

## 🔋 Battery Widget (`battery`)

### v1.0.0 (2025-12-29)
**TR-TR:**
- **Düzen Esnekliği**: 4 cihaza kadar destek sağlandı.
- **Görsel Güncelleme**: Roboto Condensed yazı tipi, dinamik ikonlar ve opak arka plan.
- **Genişleme Animasyonu**: Bilgi paneli için yumuşak geçiş eklendi.

---

## 🚀 Advanced Reboot (`plasma-advancedreboot`)

### v1.0.0 (2025-12-27)
**TR-TR:**
- **Bootctl Entegrasyonu**: Önyükleme girdilerini listeleme ve seçme özelliği eklendi.
- **Özel Arayüz**: Yeniden tasarlanan onay ekranı ve sayfa göstergeleri.

---

## 🕒 Clocks & Time

### Digital Clock (`digital-clock`)
- **2025-12-27**: `Roboto Condensed Variable` yazı tipi, tema entegrasyonu ve saniye göstergesi hover efekti eklendi.

### Analog Clock (`analog-clock` / `minimal-analog-clock`)
- **2026-01-22 (v1.2)**: "Widget Margin" ayarı (Normal, Az, Yok) eklendi.
- **2026-01-21 (v1.1)**: **Büyük Tasarım ve Yapılandırma Güncellemesi**.
    - **Variable Font & Dinamik Ölçeklendirme**: Roboto Flex değişken yazı tipi desteği ile dijital saatin ağırlığı ve genişliği widget boyutuna göre (dikey/yatay) otomatik uyarlanır.
    - **Yeni Saat Stilleri**: "Otomatik", "Klasik (Daire)" ve "Modern (Squircle)" modları eklendi.
    - **Küçük Kare Görünümü**: Sadece saati (HH) gösteren şık, büyük fontlu mod eklendi.
    - **Gelişmiş Özelleştirme**: Kullanıcı el ile font kalınlığı, genişliği ve dikey rakam boşluğunu sürgülerle ayarlayabilir.
    - **Lokalizasyon & UI**: 20+ dil desteği (.po) ve tamamen yenilenmiş ayar kategorileri.
- **2025-12-30**: **Minimal Analog Clock** projesi oluşturuldu (Temel tasarım ve akrep/yelkovan mantığı).
- **2025-12-27**: Dinamik elkovan uzunluğu ve başlangıç pozisyonu iyileştirmeleri.
- **2025-12-26**: Squircle şekline uygun görsel iyileştirmeler.

---

## 📅 MCalendar (`calendar`)

### v1.8 (2026-03-02)
**TR-TR:**
- **İçerik Boşluğu Ayarı**: Widget içeriği ile arka plan kenarları arasındaki boşluğu (0px ile 20px arası) ayarlama seçeneği eklendi.
- **Düzen İyileştirmesi**: Ay başlığı ile hafta içi gün isimleri arasındaki gereksiz boşluk kaldırılarak daha kompakt bir görünüm sağlandı.
- **Yerelleştirme**: Yeni ayarlar 20'den fazla dilde yerelleştirildi.

**EN-US:**
- **Content Padding Feature**: Added configuration to adjust spacing between widget content and background edges (0px to 20px).
- **Layout Refinement**: Removed unnecessary gap between the month title and weekday labels for a cleaner, more compact look.
- **Global Localization**: Localized new settings for over 20 supported languages.

### v1.6 (2026-01-22)
**TR:**
- **Yeni Özellik**: Widget kenar boşluğu (Normal, Az, Yok) seçeneği eklendi.
**EN:**
- **New Feature**: Added "Widget Edge Margin" (Normal, Less, None) configuration.

- **2025-12-31**: Google Takvim entegrasyonu kaldırılarak tam çevrimdışı moda geçildi. Yeni yerelleştirme sistemine entegre edildi.
- **2025-12-20**: Dairesel tarih göstergesi, dinamik yükseklik ve etkinlik başlığı kayma düzeltmeleri.

---

## 📝 Notes (`notes`)

- **2025-12-06**: Liste tabanlı arayüz, sürükle-bırak sıralama, girintileme ve karanlık mod zorunluluğu.

---

## 🤖 Gemini Chat (`gemini-kchat-fork`) - *Project Removed*

- **2026-01-01**: Proje dosyaları silindi.
- **Eski Özellikler**: Matematiksel render (MathJax), model seçimi (Flash/Pro), JSON modu, stop butonu ve 10 dilde yerelleştirme.

---

## 🛠️ Core / Global Changes

- **2025-12-31**: **Global Icon Refactoring**: Tüm widget'lardaki yerel PNG ikonlar kaldırılarak standart sistem ikonlarına (`office-calendar`, `clock` vb.) geçildi.
- **2025-12-31**: **Standardized Localization**: Tüm proje için JSON tabanlı senkron yerelleştirme sistemi (20+ dil desteği) standartlaştırıldı.
- **2025-12-31**: `install_all.sh` betiği tüm widget'ları destekleyecek şekilde güncellendi.
