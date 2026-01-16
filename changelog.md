# Değişiklik Günlüğü (Changelog)

## 2026-01-16

### TR-TR
- **MMusic Player Widget v1.2.1 (Rebranding & Multi-language Support)**:
    - **Marka Yenileme (Rebranding)**: Widget adı **MMusic Player** olarak güncellendi ve Latin dilli yerelleştirmelere "M" ön eki eklendi.
    - **Genişletilmiş Lokalizasyon**: Toplam 20 dil desteğine ulaşıldı. İtalyanca, Yunanca, Azerice, Çince, Ermenice, Hintçe, Bengalce, Urduca, Endonezyaca ve Farsça dilleri eklendi.
    - **Yapılandırma Düzeltmesi**: Genel ayarlar sekmesinde yaşanan görsel kaybolma ve syntax hataları giderildi.
    - **Dökümantasyon**: Widget klasörü içine detaylı `README.md` eklendi ve GitHub URL'si güncellendi.

- **MWeather Widget v1.1.5 (Small Mode Fix)**:
    - **UI Düzeltmesi**: Küçük modda (Small Mode) uzun hava durumu açıklamalarının (örn. "Parçalı Bulutlu") ikon ile çakışması ve kesilmesi sorunu düzeltildi. Metin artık gerektiğinde alt satıra geçiyor (Word Wrap).

- **MWeather Widget v1.1.4 (Rebranding & Discover Support)**:
    - **Marka Yenileme (Rebranding)**: Uygulama adı **MWeather** olarak güncellendi ve Latin dillerinde "M" ön eki eklendi.
    - **KDE Discover Desteği**: `metainfo.xml` (AppStream) eklenerek KDE Discover ve mağaza entegrasyonu güçlendirildi.
    - **Teknik Kimlik**: Plugin ID `com.mcc45tr.mweather` olarak güncellendi.
    - **Senkron Lokalizasyon**: Lokalizasyon sistemi `XMLHttpRequest` tabanlı JSON dosyasından, senkron JavaScript modülüne (`localization.js`) taşındı.
    - **Modüler Mimari**: `main.qml` dosyası parçalanarak `SmallModeLayout`, `WideModeLayout` ve `LargeModeLayout` bileşenlerine ayrıldı. Kod okunabilirliği ve bakım kolaylığı artırıldı.
    - **Gelişmiş Animasyonlar**: Büyük Mod (Large Mode) için "Morphing Details" animasyonu eklendi. Detaylar butonu tam ekran cam efektli panele yumuşak bir geçişle genişliyor.
    - **Görsel İyileştirmeler**:
        - Google Hava Durumu tarzı 3 yeni ikon paketi (V1, V2, V3) eklendi.
        - Büyük modda sıcaklık göstergesi tahmin kartlarının üstüne alındı ve ikon boyutları optimize edildi.
        - Butonlar ve içerik arasında 4px boşluk (margin) eklenerek görsel denge sağlandı.
    - **Hata Düzeltmeleri**: Ermenice (`hy`) çevirilerdeki bozulmalar giderildi. Büyük moddaki binding loop ve null referans hataları çözüldü.

### EN-US
- **MMusic Player Widget v1.2.1 (Rebranding & Multi-language Support)**:
    - **Rebranding**: Renamed to **MMusic Player** and added "M" prefix for Latin-based languages.
    - **Extended Localization**: Now supports 20 languages. Added Italian, Greek, Azerbaijani, Chinese, Armenian, Hindi, Bengali, Urdu, Indonesian, and Persian.
    - **Config Fix**: Fixed the "General" settings tab visibility issue caused by QML syntax errors.
    - **Documentation**: Added a detailed `README.md` within the widget directory and updated the repository URL.

- **MWeather Widget v1.1.5 (Small Mode Fix)**:
    - **UI Fix**: Resolved text truncation and icon overlap issues for long weather descriptions in Small Mode. Text now automatically wraps to a second line when needed.

- **MWeather Widget v1.1.4 (Rebranding & Discover Support)**:
    - **Rebranding**: Renamed the widget to **MWeather** and added "M" prefix for Latin-based languages.
    - **Discover Integration**: Added `metainfo.xml` (AppStream) for ultimate visibility in KDE Discover and stores.
    - **Technical ID**: Updated Plugin ID to `com.mcc45tr.mweather`.
    - **Synchronous Localization**: Migrated the localization system from `XMLHttpRequest` based JSON to a synchronous JavaScript module.
    - **Modular Architecture**: Refactored `main.qml` into modular components: `SmallModeLayout`, `WideModeLayout`, and `LargeModeLayout`. Improved code maintainability and performance.
    - **Advanced Animations**: Introduced "Morphing Details" animation for Large Mode. The details button smoothly expands into a full-glass details panel using `InOutQuad` easing.
    - **Visual Enhancements**:
        - Added 3 new Google Weather style icon packs (V1, V2, V3).
        - Repositioned temperature display above forecast cards in Large Mode and optimized weather icon scaling.
        - Added 4px bottom margin to header buttons for better visual separation.
    - **Bug Fixes**: Corrected corrupted Armenian (`hy`) translations. Resolved binding loops and null reference errors in Large Mode layouts.

## 2026-01-01

### TR-TR
- **File Search Widget (Modülerleştirme ve İyileştirme)**:
    - Kullanıcı arayüzü tamamen modüler QML bileşenlerine ayrıştırıldı (`CompactView`, `ResultsListView`, `HistoryTileView` vb.).
    - Senkron JavaScript tabanlı yerelleştirme sistemine (`localization.js`) geçilerek yükleme performans ve kararlılığı artırıldı.
    - Geçmiş yönetimi `HistoryManager.js` modülüne taşınarak kod yapısı temizlendi.
    - Yapılandırma ekranı ve önizlemeler tamamen yenilendi ve senkron çeviri desteği eklendi.
    - Varsayılan görünüm modu "Dar" (Medium) ve varsayılan ikon boyutları (Liste: 22, Döşeme: 48) olarak güncellendi.
- **File Search Widget (Gelişmiş Klavye Navigasyonu)**:
    - **Akıllı Tile Gezinme**: Döşeme görünümünde ↑↓←→ tuşlarıyla sütun pozisyonunu koruyarak gezinme.
    - **Tab/Shift+Tab**: Arama girişi ile sonuçlar arasında geçiş.
    - **Ctrl+1/2**: Liste ve döşeme görünümü arasında hızlı geçiş.
    - **Ctrl+Space**: Dosya önizlemesini açma/kapama.
    - **Animasyonlu Focus Glow**: Seçili öğe için erişilebilirlik vurgusu.
- **File Search Widget (Debug & Telemetry)**:
    - `TelemetryManager.js` ve `DebugOverlay.qml` entegrasyonu tamamlandı.
    - Gerçek zamanlı arama gecikmesi ölçümü ve istatistik takibi eklendi.
    - Debug ve Telemetri verileri için tam Türkçe/İngilizce lokalizasyon desteği sağlandı.
    - Debug verilerini yerel JSON dosyasına dışa aktarma (Save Dump) özelliği eklendi.
    - JavaScript yardımcı dosyaları (`js/` klasörü) daha temiz bir yapı için organize edildi.
- **File Search Widget (Hata Düzeltmeleri)**:
    - Geçmişten uygulama başlatırken yaşanan yanlış sonuç açılma sorunu giderildi (Artık doğrudan uygulama adı hedefleniyor).
    - Liste görünümünde öğelere tıklayarak açma sorunu çözüldü.
    - QML ReferenceError ve focus metoduna dair çalışma zamanı hataları giderildi.
- **Diğer**:
    - `gemini-kchat-fork` (gemini-chat) projesi silindi.
- **File Search Widget (Akıllı Arama - Smart Query)**:
    - **QueryHints Bileşeni**: KRunner prefix'lerini algılayan ipucu sistemi.
    - Desteklenen prefix'ler: `timeline:/today`, `gg:`, `dd:`, `kill`, `spell`, `#unicode`.
    - Bilinmeyen prefix'ler için uyarı mesajı.
- **File Search Widget (Hover Önizleme)**:
    - Dosya üzerine hover ile gelişmiş tooltip (dosya türü, yol, thumbnail).
    - Görsel dosyalar için thumbnail önizleme (PNG/JPG/GIF/WebP).
    - Ctrl+Space ile klavye tetiklemeli önizleme.
- **File Search Widget (Performans İyileştirmeleri)**:
    - Tile view'lar için `Loader` ile lazy loading.
    - ListView yerleşik virtualization desteği.
    - Milou limit=50 ile incremental render.
- **File Search Widget (Görünüm Profilleri)**:
    - **Profil Sistemi**: Minimal / Developer / Power User profilleri.
    - **Yeni Config Sekmeleri**: Görünüm, Arama, Debug, Kılavuz.
    - **Debug Sekmesi**: Debug overlay toggle, debug verilerini kaydetme düğmesi (Developer modunda aktif).
    - **Kılavuz Sekmesi**: Tüm klavye kısayolları, arama prefix'leri ve profil açıklamaları.
    - 30+ yeni lokalizasyon key'i (EN/TR/DE/FR ve diğer 6 dil).

### EN-US
- **File Search Widget (Advanced Keyboard Navigation)**:
    - **Smart Tile Navigation**: Arrow key navigation (↑↓←→) maintaining column position in tile view.
    - **Tab/Shift+Tab**: Section cycling between search input and results.
    - **Ctrl+1/2**: Quick view mode switching between List and Tile.
    - **Ctrl+Space**: Toggle file preview for selected item.
    - **Animated Focus Glow**: Accessibility highlight for selected items.
- **File Search Widget (Smart Query)**:
    - **QueryHints Component**: Hint system detecting KRunner prefixes.
    - Supported prefixes: `timeline:/today`, `gg:`, `dd:`, `kill`, `spell`, `#unicode`.
    - Warning message for unknown prefixes.
- **File Search Widget (Hover Preview)**:
    - Enhanced tooltip on hover (file type, path, thumbnail).
    - Image thumbnail preview for visual files (PNG/JPG/GIF/WebP).
    - Ctrl+Space keyboard-triggered preview.
- **File Search Widget (Performance Improvements)**:
    - Lazy loading with `Loader` for tile views.
    - Built-in ListView virtualization support.
    - Incremental rendering with Milou limit=50.
- **File Search Widget (View Profiles)**:
    - **Profile System**: Minimal / Developer / Power User profiles.
    - **New Config Tabs**: Appearance, Search, Debug, Help.
    - **Debug Tab**: Debug overlay toggle, save debug data button (active in Developer mode).
    - **Help Tab**: All keyboard shortcuts, search prefixes, and profile descriptions.
    - 30+ new localization keys (EN/TR/DE/FR and 6 other languages).

### EN-US
- **File Search Widget (Modularization & Improvements)**:
    - Entire UI refactored into modular QML components (`CompactView`, `ResultsListView`, `HistoryTileView`, etc.).
    - Migrated to a synchronous JavaScript-based localization system (`localization.js`) for better performance and stability.
    - History management logic moved to a dedicated `HistoryManager.js` module.
    - Configuration screen and previews were completely revamped with synchronous translation support.
    - Updated default display mode to "Medium" (Narrow) and standardized default icon sizes (List: 22, Tile: 48).

### EN-US
- **Gemini KChat (Advanced Support)**:
    - **Math Rendering**: Added custom block rendering for `$$...$$` mathematical expressions.
    - **Model Selection**: Live switching between Gemini models (Flash, Pro, etc.) directly from the widget.
    - **Localization**: Full localization support added (`localization.js`).
    - **File Attach**: Added UI for attaching images (Multimodal prep).
    - **Persona & Safety**: Custom system instructions and configurable safety filters.
    - **JSON Mode**: Support for forced JSON output structure.
    - **Renaming**: Renamed to "Gemini Chat" with updated widget ID.
    - **Message Alignment**: User messages right-aligned, AI messages left-aligned.
    - **Stop Button**: Added ability to abort AI responses with a stop button.
    - **Guide**: Comprehensive API key guide tab and context-aware guide button added.
    - **Localization**: Full 10-language synchronous localization support completed.
- **File Search Widget (Advanced Improvements)**:
    - **Keyboard Navigation**: Arrow key navigation (↑ ↓ ← →) in tile view with Enter to activate.
    - **Category Collapse/Expand**: Click category headers to hide/show items within.
    - **File Preview Tooltip**: Hover over tile items to see file name, category, and path.
    - **Visual Enhancements**: Added focus highlight, category arrow icons, and item count badges.
    - **Localization**: Added "category" and "path" keys to all 10 languages.

---

## 2025-12-31

### TR-TR
- **Global Icon Refactoring**: 
    - Tüm widget'lardaki yerel önizleme ikonları (`icon.png`, `preview.png`) kaldırıldı.
    - Tüm widget'lara sistem ikon paketinden uygun ve standart ikonlar atandı (`office-calendar`, `clock`, `notifications`, `system-software-update` vb.).
    - Bu sayede widget'ların sistem temasıyla tam uyumlu ve tutarlı bir görünüm kazanması sağlandı.
- **Localization System**: 
    - Proje genelindeki tüm widget'lar için **JSON tabanlı gelişmiş lokalizasyon sistemi** standartlaştırıldı.
    - Almanca, Fransızca, İngilizce, Türkçe, Romence, Çekçe, İspanyolca, Rusça, Portekizce ve Japonca dilleri için tam destek eklendi.
    - Tüm widget klasörlerine (`world-clock`, `weather`, `system-monitor`, `spotify`, `plasma-advancedreboot`, `photos`, `notes`, `music-player`, `gemini-kchat-fork`, `events`, `control-center`, `battery`, `aur-updates`, `alarms`, `analog-clock`, `digital-clock`) otomatik olarak `localization.json` şablonları oluşturuldu.
- **Calendar Widget**: 
    - Google Takvim entegrasyonu ve etkinlikler paneli kaldırıldı (Çevrimdışı moda geçildi).
    - Yeni JSON tabanlı yerelleştirme sistemine geçiş yapıldı (`tr()` fonksiyonu entegrasyonu).
    - Ay isimleri ve tarih formatları sistem yereline uyumlu hale getirildi.
- **File Search Widget**: 
    - JSON tabanlı yerelleştirme sistemi uygulandı ve yapılandırma ekranı ile ana arayüz 10 dilde yerelleştirildi.
    - Geçmiş öğelerini doğrudan çalıştırma özelliği eklendi (`matchId`, `runnerId`). 
    - Döşeme görünümünde (tile view) öğelerin tıklanamama sorunu düzeltildi. 
    - Simge boyutu ayarlarının kaydedilmesi ve uygulanması sağlandı. 
    - Dosya/klasör sonuçları için üst klasör yolu gösterimi eklendi. 
    - Geçmiş listesi için akıllı zaman damgası (timestamp) gösterimi eklendi.
- **Project Structure**: 
    - `install_all.sh` betiği güncellendi ve tüm widget'ların sorunsuz kurulduğu doğrulandı.
    - **Analog Clock** ve **Calendar** widget'ları için yeni önizleme ikonları/ekran görüntüleri eklendi.
- **Music Player**:
    - **Yapılandırma Ekranı**: Varsayılan medya oynatıcı seçimi için "Genel" ayarlar sayfası eklendi. Sabit liste yerine şu anda aktif olan MPRIS oynatıcılarını listeleyen dinamik bir yapıya geçildi.
    - **Gelişmiş Oynatıcı Bulma**: Tercih edilen oynatıcıyı (örn. Spotify) sadece "şu anki" değil, tüm çalışan MPRIS kaynakları arasında tarayarak bulma özelliği eklendi.
    - **Sistem İkonu Entegrasyonu**: Kontrol butonları (Önceki, Başlat/Durdur, Sonraki) yerel SVG yerine sistem ikon temasını (`media-*`) kullanacak şekilde güncellendi.
    - **Uygulama Başlatma Fix**: Medya yokken widget'a tıklandığında seçili uygulamanın (.desktop üzerinden) güvenilir şekilde başlatılması sağlandı.
    - **Dinamik Uygulama Rozeti (Pill Badge)**:
        - Sol üst köşeye o an çalan uygulamanın ikonunu ve ismini gösteren, sistem temasıyla uyumlu **pill (hap)** şeklinde bir rozet eklendi.
        - Rozet genişliği uygulama ismine göre dinamik olarak ayarlanır.
        - Yazı tipi ve boyutları (14px) sanatçı bilgileriyle uyumlu hale getirildi.
        - Kompakt modda durum göstergesi (çalıyor/duraklatıldı noktası) eklendi.
    - **Hata Düzeltmeleri**: Yapılandırma ekranındaki iç içe geçme, reaktif güncellenme ve hizalama sorunları giderildi.

### EN-US
- **Global Icon Refactoring**:
  - All local preview icons (icon.png, preview.png) were removed from every widget.
  - Each widget was assigned appropriate and standardized icons from the system icon theme (office-calendar, clock, notifications, system-software-update, etc.).
  - This ensured full visual consistency and seamless integration with the system theme across all widgets.
- **Localization System**:
  - An advanced JSON-based localization system was standardized across all widgets in the project.
  - Full language support was added for German, French, English, Turkish, Romanian, Czech, Spanish, Russian, Portuguese, and Japanese.
  - localization.json templates were automatically generated for all widget directories (world-clock, weather, system-monitor, spotify, plasma-advancedreboot, photos, notes, music-player, gemini-kchat-fork, events, control-center, battery, aur-updates, alarms, analog-clock, digital-clock).
- **Calendar Widget**:
  - Google Calendar integration and the events panel were removed, and the widget was switched to offline mode.
  - Migration to the new JSON-based localization system was completed (tr() function integration).
  - Month names and date formats were aligned with the system locale.
- **File Search Widget**:
  - The JSON-based localization system was implemented, and both the configuration interface and the main UI were localized into 10 languages.
  - A new feature was added to launch history items directly (matchId, runnerId).
  - An issue preventing items from being clickable in tile view was resolved.
  - Icon size settings are now properly saved and applied.
  - Parent directory paths are now displayed for file and folder results.
  - Smart timestamp formatting was added for the history list.
- **Project Structure**:
  - The install_all.sh script was updated, and successful installation of all widgets was verified.
  - New preview icons/screenshots were added for the Analog Clock and Calendar widgets.
- **Music Player**:
  - **Configuration Screen**: Added a "General" settings page for default media player selection. Migrated from a static app list to a dynamic one listing currently active MPRIS players.
  - **Advanced Player Discovery**: Implemented scanning through all active MPRIS sources to find the preferred player (e.g., Spotify), even if it's not the currently active one.
  - **System Icon Integration**: Updated playback controls (Previous, Play/Pause, Next) to use system icon theme names (`media-*`) instead of local SVGs for better theme compatibility.
  - **App Launching Fix**: clicking the widget when no media is playing now reliably launches the preferred app via its .desktop file.
  - **Dynamic App Badge (Pill Badge)**:
    - Implemented a system-themed **pill-shaped badge** in the top-left that displays both the application icon and name.
    - The badge width responds dynamically to the application name.
    - Font sizes and alignment (14px) were harmonized with the artist info text.
    - Added a status indicator dot (playing/paused) for the icon in compact mode.
  - **Bug Fixes**: Resolved layout overlapping in the configuration screen, fixed reactivity issues, and improved overall UI alignment.

---

## 2025-12-30

### TR-TR
- **Minimal Analog Clock**: Proje yapısı oluşturuldu. Temel analog saat çizim mantığı (akrep, yelkovan) ve minimal tasarım uygulandı.
- **File Search Widget**: Döşeme görünümü (Tile View) iyileştirildi, görünürlük sorunu giderildi. Ekstra Geniş Mod (Extra Wide Mode) paneli eklendi.
- **Music Player**: Oynatma kontrol butonları için yönlü genişleme/daralma animasyonu (squeeze effect) eklendi.

### EN-US
- **Minimal Analog Clock**: The project structure was created. Basic analog clock rendering logic (hour and minute hands) and a minimal design were implemented.
- **File Search Widget**: Tile View was improved and visibility issues were fixed. An Extra Wide Mode panel was added.
- **Music Player**: A directional expand/collapse animation (squeeze effect) was added to the playback control buttons.

---

## 2025-12-29

### TR-TR
- **Music Player**: Önceki/Sonraki butonları asimetrik yuvarlatılmış dikdörtgen formuna dönüştürüldü.
- **Battery Widget**: Düzen esnekliği artırıldı (4 cihaza kadar). Genişleme animasyonu eklendi. "Doluyor" yazı tipi Roboto Condensed yapıldı. Şarj göstergesi boyutu büyütüldü ve ikon dinamikleştirildi. Widget arka planı opak hale getirildi ve kenar boşlukları kaldırıldı.

### EN-US
- **Music Player**: The Previous and Next buttons were redesigned with asymmetrically rounded rectangular shapes.
- **Battery Widget**: Layout flexibility was increased (support for up to four devices). An expansion animation was added. The “Charging” label font was changed to Roboto Condensed. The charging indicator size was increased and the icon was made dynamic. The widget background was made opaque and internal padding was removed.

---

## 2025-12-27

### TR-TR
- **Advanced Reboot Widget**: Özel yeniden başlatma onay arayüzü eklendi ("Yeniden Başlatılsın mı?" metni kaldırıldı). Sayfa göstergesi (page indicator) düzenlendi. Önyükleme girdilerini listeleme ve seçme (bootctl) özelliği eklendi.
- **Analog Clock**: Akrep ve elkovan opaklığı 0.8 yapıldı.
- **Digital Clock**: Tema entegrasyonu sağlandı. Yazı tipi `Roboto Condensed Variable` yapıldı. Saniye göstergesi fare üzerine gelince görünecek şekilde ayarlandı.
- **Analog Clock**: Başlangıç pozisyonu ve elkovan uzunluğu dinamik hale getirildi.

### EN-US
- **Advanced Reboot Widget**: A custom reboot confirmation interface was added. The “Reboot?” text was removed. The page indicator was redesigned. Boot entry listing and selection functionality (bootctl) was implemented.
- **Analog Clock**: Hour and minute hand opacity was set to 0.8. Initial hand position and minute hand length were made dynamic.
- **Digital Clock**: Theme integration was completed. The font was changed to Roboto Condensed Variable. The seconds display was configured to appear on hover.

---

## 2025-12-26

### TR-TR
- **Analog Clock**: Saat kolları ve tik işaretleri için görsel iyileştirmeler yapıldı. Squircle şekline uygun düzeltmeler uygulandı.

### EN-US
- **Analog Clock**: Visual improvements were applied to the clock hands and tick marks. Adjustments were made to better match the squircle shape.

---

## 2025-12-20

### TR-TR
- **Calendar Widget**: Etkinlik başlıklarının kayması, dinamik yükseklik ve satır sayısı ayarları yapıldı. Seçili tarih için dairesel gösterge eklendi.

### EN-US
- **Calendar Widget**: Issues related to event title shifting were resolved. Dynamic height and line count settings were implemented. A circular indicator was added for the selected date.

---

## 2025-12-06

### TR-TR
- **Notes Widget**: Liste tabanlı arayüze geçildi. Sürükle-bırak sıralama, girintileme ve tamamlama özellikleri eklendi. Karanlık mod zorunlu hale getirildi.

### EN-US
- **Notes Widget**: The interface was migrated to a list-based layout. Drag-and-drop reordering, indentation, and completion features were added. Dark mode was enforced.
