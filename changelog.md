# Değişiklik Günlüğü (Changelog)

## 2025-12-31
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
- **Project Structure**: `install_all.sh` betiği güncellendi ve tüm widget'ların sorunsuz kurulduğu doğrulandı.

## 2025-12-30
- **Minimal Analog Clock**: Proje yapısı oluşturuldu. Temel analog saat çizim mantığı (akrep, yelkovan) ve minimal tasarım uygulandı.
- **File Search Widget**: Döşeme görünümü (Tile View) iyileştirildi, görünürlük sorunu giderildi. Ekstra Geniş Mod (Extra Wide Mode) paneli eklendi.
- **Music Player**: Oynatma kontrol butonları için yönlü genişleme/daralma animasyonu (squeeze effect) eklendi.

## 2025-12-29
- **Music Player**: Önceki/Sonraki butonları asimetrik yuvarlatılmış dikdörtgen formuna dönüştürüldü.
- **Battery Widget**: Düzen esnekliği artırıldı (4 cihaza kadar). Genişleme animasyonu eklendi. "Doluyor" yazı tipi Roboto Condensed yapıldı. Şarj göstergesi boyutu büyütüldü ve ikon dinamikleştirildi. Widget arka planı opak hale getirildi ve kenar boşlukları kaldırıldı.

## 2025-12-27
- **Advanced Reboot Widget**: Özel yeniden başlatma onay arayüzü eklendi ("Yeniden Başlatılsın mı?" metni kaldırıldı). Sayfa göstergesi (page indicator) düzenlendi. Önyükleme girdilerini listeleme ve seçme (bootctl) özelliği eklendi.
- **Analog Clock**: Akrep ve elkovan opaklığı 0.8 yapıldı.
- **Digital Clock**: Tema entegrasyonu sağlandı. Yazı tipi `Roboto Condensed Variable` yapıldı. Saniye göstergesi fare üzerine gelince görünecek şekilde ayarlandı.
- **Analog Clock**: Başlangıç pozisyonu ve elkovan uzunluğu dinamik hale getirildi.

## 2025-12-26
- **Analog Clock**: Saat kolları ve tik işaretleri için görsel iyileştirmeler yapıldı. Squircle şekline uygun düzeltmeler uygulandı.

## 2025-12-20
- **Calendar Widget**: Etkinlik başlıklarının kayması, dinamik yükseklik ve satır sayısı ayarları yapıldı. Seçili tarih için dairesel gösterge eklendi.

## 2025-12-06
- **Notes Widget**: Liste tabanlı arayüze geçildi. Sürükle-bırak sıralama, girintileme ve tamamlama özellikleri eklendi. Karanlık mod zorunlu hale getirildi.
