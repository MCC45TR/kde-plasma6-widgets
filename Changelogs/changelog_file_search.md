# 🔍 MFile Finder (`file-search`)

### v1.2.3 (2026-01-29)
**TR:**
- **Hata Düzeltmeleri:** `Plasmoid` nesnesine erişim hatası (`ReferenceError`) düzeltildi, ayarların düzgün yüklenmesi sağlandı.
- **Kararlılık:** Plasma 6 altında oluşan bazı başlatma ve çökme sorunları giderildi.
- **Performans:** Arama motorunun başlatılma sürecindeki gecikmeler optimize edildi.

**EN:**
- **Bug Fixes:** Resolved `ReferenceError: Plasmoid is not defined`, ensuring configuration settings load correctly.
- **Stability:** Fixed various startup and crash issues under Plasma 6.
- **Performance:** Optimized latencies during the search engine initialization process.

### v1.2.2 (2026-01-25)
**TR:**
- **Dil Desteği Güncellemesi:** Birçok dil için (`es`, `it`, `pt`, `ru`, `ja`, `zh`, `hi`, `hy`, `id`, `ro`, `ur`) çeviriler güncellendi ve eksik dizeler tamamlandı.

**EN:**
- **Translation Updates:** Updated translations and completed missing strings for multiple languages (Spanish, Italian, Portuguese, Russian, Japanese, Chinese, Hindi, Armenian, Indonesian, Romanian, and Urdu).

### v1.2.1 (2026-01-22)
**TR:**
- **Panel Yüksekliği Özelleştirmesi:**
    - Panel yüksekliği için manuel ayar (18-96px) ve "Otomatik" seçeneği eklendi.
    - `CompactView` bileşeni seçilen yüksekliğe göre dinamik olarak ölçeklenecek şekilde güncellendi.

**EN:**
- **Panel Height Customization:**
    - Added manual Panel Height configuration (18-96px) with an "Automatic" option.
    - Updated `CompactView` to dynamically scale based on the configured height.

### v1.2.0-beta (2026-01-18)
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
- **Sabitlenmiş Öğeler (Pinned Items):**
    - Arama yapılırken sabitlenmiş öğeler çubuğunu otomatik gizleme seçeneği eklendi ("Minimize automatically when searching").
- **Hava Durumu Entegrasyonu (Weather Integration):**
    - `weather:` (veya `hava:`) öneki ile anlık hava durumu görüntüleme özelliği eklendi.
    - Open-Meteo ve ipinfo.io kullanılarak API anahtarı gerektirmeyen otomatik konum algılama.
    - **Ayarlar:** Hava durumu özelliğini açma/kapama, birim seçimi (Metrik/Imperial/Sistem), yenileme sıklığı ve veri önbellekleme ayarları eklendi.

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
- **Pinned Items:**
    - Added option to automatically hide the pinned items bar when searching ("Minimize automatically when searching").
- **Weather Integration:**
    - Added `weather:` prefix support to view current weather conditions.
    - Implemented automatic IP-based location detection using Open-Meteo and ipinfo.io (No API key required).
    - **Settings:** Added options to Enable/Disable weather, choose units (Metric/Imperial/System), set refresh intervals, and caching logic.

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
