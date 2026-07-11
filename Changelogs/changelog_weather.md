# 🌤️ MWeather (`weather`)

### v1.2.1 (2026-02-09)
**TR-TR:**
- **Gelişmiş Rutin Bildirimler**: "Bugünün Hava Değişimleri" seçeneği eklendi. Artık gün içindeki önemli hava durumu değişimlerini (örn. güneşliden yağmura geçiş) saatlik bazda bildirim olarak alabilirsiniz.
- **Bildirim Kontrol Mekanizması**: Bildirim kontrol sıklığı 30 saniyeye düşürüldü. Ayrıca, rutin bildirimler için 2 dakikalık bekleme süresi (cooldown) eklenerek spam önlendi.
- **Küresel Yerelleştirme Güncellemesi**: Yeni eklenen bildirim ayarları ve içerikleri 20'den fazla dilde tamamen yerelleştirildi.
- **Tavsiye Metinleri**: Bildirimlere "Görüş mesafesi düşük, dikkatli sürün" gibi hava durumuna özel güvenli sürüş ve yaşam tavsiyeleri eklendi.
- **Teknik Düzeltmeler**: Yapılandırma sayfalarındaki "Setting initial properties failed" hataları giderildi ve sistem kararlılığı artırıldı.

**EN-US:**
- **Advanced Routine Notifications**: Added "Today's Weather Changes" option. You can now receive notifications detailing significant weather shifts (e.g., from sunny to rainy) on an hourly basis.
- **Notification Timing & Logic**: Reduced system check interval to 30 seconds and implemented a 2-minute cooldown for routine notifications to prevent spamming.
- **Global Localization Update**: Fully localized new notification settings and strings for over 20 supported languages.
- **Smart Advice**: Added weather-specific safety advice to notifications (e.g., "Visibility is low, drive carefully").
- **Technical Fixes**: Resolved "Setting initial properties failed" initialization errors and improved configuration binding stability.

### v1.2.0 (2026-01-30)
**TR-TR:**
- **Kapsamlı Yerelleştirme**: 20'den fazla dil için (Azerice, Bengalce, Çekçe, Almanca, Yunanca, İspanyolca, Farsça, Fransızca, Hintçe, Ermenice, Endonezyaca, İtalyanca, Japonca, Portekizce, Rumence, Rusça, Türkçe, Urduca, Çince) çeviriler eklendi ve güncellendi.
- **Hava Durumu Detayları**: "Bulutluluk", "Çiy Noktası", "UV İndeksi", "Yağış Olasılığı" ve "Yağış Miktarı" gibi detaylı veriler eklendi.
- **Gelişmiş Görünüm**:
    - Rüzgar yönleri için tam isimler ve kısaltmalar eklendi.
    - Gün doğumu ve gün batımı bilgileri tahmin detaylarına eklendi.
    - "Kapatmak için tıkla/dokun" ipuçları eklendi.
    - Her gün için detaylı hava durumu görünümü eklendi.
- **Teknik İyileştirmeler**: Çeviri sistemi modernize edildi (`translations/` dizini), gereksiz dosya ve kayıtlar temizlendi.
- **Ayar Geliştirmeleri**: "Sistem Teması", "Tahminde Birimleri Göster" ve "Köşe Yuvarlama" seçenekleri için yerelleştirme desteği tamamlandı.
- **Metadata Yerelleştirme**: Widget adı ve açıklaması tüm desteklenen diller için `metadata.json` içinde yerelleştirildi.

**EN-US:**
- **Massive Localization**: Added and updated translations for over 20 languages (Azerbaijani, Bengali, Czech, German, Greek, Spanish, Persian, French, Hindi, Armenian, Indonesian, Italian, Japanese, Portuguese, Romanian, Russian, Turkish, Urdu, Chinese).
- **Weather Insights**: Added detailed weather points including "Cloud Cover", "Dew Point", "UV Index", "Rain Chance", and "Precipitation".
- **Visual Enhancements**:
    - Added full cardinal directions and short abbreviations for wind.
    - Added sunrise and sunset information to the forecast view.
    - Added "Click/Tap to close" interaction hints.
    - Added detailed weather view for each day.
- **Technical Refactor**: Modernized translation architecture (unified `translations/` directory) and cleaned up obsolete entries.
- **Configuration Polish**: Completed localization for "System Theme", "Show Units in Forecast", and "Corner Radius" settings.
- **Metadata Localization**: Localized widget name and description in `metadata.json` for all supported languages.

### v1.1.9 (2026-01-29)
**TR-TR:**
- **Düzeltme:** Sistem birim (Metrik/İmperyal) algılaması düzeltildi, artık KDE bölgesel ayarlarını kullanıyor.
- **Düzeltme:** Görünüm ayarlarındaki arayüz kayması ve üst üste binme sorunları giderildi.
- **İyileştirme:** Panel ayarları, widget panelde değilse artık pasif (devre dışı) görünüyor.
- **Düzeltme:** İbranice çeviri dosyasındaki sözdizimi hatası düzeltildi.

**EN-US:**
- **Fix:** Fixed automatic unit detection (Metric/Imperial) to correctly use KDE regional settings.
- **Fix:** Resolved UI overlap and layout issues in Appearance settings.
- **Improvement:** Panel settings are now disabled when the widget is not in a panel.
- **Fix:** Fixed syntax error in Hebrew translation.

### v1.1.8 (2026-01-22)
**TR-TR:**
- **Yeni Özellik**: Widget kenar boşluğu (Normal, Az, Yok) seçeneği eklendi.

**EN-US:**
- **New Feature**: Added "Widget Edge Margin" (Normal, Less, None) configuration.

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
