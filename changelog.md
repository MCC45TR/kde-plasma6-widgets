# Değişiklik Günlüğü (Changelog)

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
