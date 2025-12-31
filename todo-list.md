# Proje Yapılacaklar ve İyileştirmeler Listesi (Todo List)

Bu dosya, Plasma 6 Widget projesindeki her bir bileşen için potansiyel iyileştirmeleri, eksiklikleri ve düzeltilmesi gereken hataları içermektedir.

---

## 🌍 Global (Tüm Widgetlar)
- [ ] **Lokalizasyon Geçişi**: Tüm widget'ları File Search'te olduğu gibi senkron `localization.js` modül yapısına geçir. (`XMLHttpRequest` yerine `import` kullanımı).
- [ ] **Modülerleştirme**: Büyük `main.qml` dosyalarını küçük, yönetilebilir bileşenlere (`components/` klasörü altına) ayır.
- [ ] **Versiyonlama**: Tüm `metadata.json` dosyalarındaki versiyonları 1.1.0 standardına çek.
- [ ] **Kod Temizliği**: Kullanılmayan `i18n` çağrılarını ve gereksiz importları temizle.

## 🔍 File Finder (File Search)
- [x] UI Modülerleştirmesi (CompactView, ResultsListView vb.)
- [x] Senkron Lokalizasyon sistemi
- [x] Geçmiş Yönetimi modülü
- [ ] **Klavye Navigasyonu**: Döşeme (Tile) görünümünde ok tuşlarıyla gezinme tam olarak çalışmıyor.
- [ ] **Kategori Filtreleme**: Kategori başlıklarına tıklayarak o kategoriyi gizleme/gösterme özelliği.
- [ ] **Dosya Önizleme**: Dosyaların üzerine gelince (hover) küçük bir önizleme veya detaylı bilgi pop-up'ı.

## 🎵 Music Player
- [ ] **Şarkı Sözleri**: Çalan şarkının sözlerini (Lyrics) gösterecek bir panel/mod ekle (API entegrasyonu gerekebilir).
- [ ] **Performans**: Albüm kapağı bulanıklık efekti (FastBlur) bazen animasyonları takılmaya uğratıyor; optimize edilmeli.
- [ ] **Spotify Gelişmiş Kontrol**: Sadece MPRIS değil, Spotify API kullanarak çalma listelerine erişim.
- [ ] **Seek Bar**: İlerleme çubuğunda tıklanan yere tam saniyesinde atlama hassasiyeti artırılmalı.

## 🗓️ Calendar (Takvim)
- [ ] **Resmi Tatiller**: Yerel bir JSON dosyasından veya API'den resmi tatilleri çekip takvimde işaretle.
- [ ] **Etkinlik Yönetimi**: Widget üzerinden basit etkinlik/hatırlatıcı ekleme arayüzü (yerel depolama ile).
- [ ] **Dış Servisler**: İsteğe bağlı (opsiyonel) Google Calendar veya iCal aboneliği desteği (Sadece okuma).

## 🔋 Battery (Pil)
- [ ] **Çevre Birimleri**: Bluetooth kulaklık, mouse, klavye gibi cihazların pil seviyelerini de listede göster.
- [ ] **Güç Profilleri**: "Performans", "Dengeli", "Güç Tasarrufu" modları arasında geçiş yapabilen butonlar.
- [ ] **Grafik**: Son 24 saatlik pil kullanım grafiği.

## ⏰ Analog Clock (Analog Saat)
- [ ] **Temalar**: Kullanıcının seçebileceği farklı saat kadranı (face) tasarımları.
- [ ] **Alarm Entegrasyonu**: Kadranda kurulu bir sonraki alarmı gösteren küçük bir ibre veya ikon.
- [ ] **Saniye İbresi**: Saniye ibresinin "tık-tık" veya "akıcı" (sweep) hareket etmesi için ayar.

## 📟 Digital Clock (Dijital Saat)
- [ ] **Dünya Saatleri**: Birden fazla zaman dilimini (örneğin New York, Tokyo) alt alta gösterebilme.
- [ ] **Font Özelleştirme**: Kullanıcının sistem fontları arasından seçim yapabilmesi.
- [ ] **Kronometre/Zamanlayıcı**: Basit bir geri sayım veya kronometre modu.

## 💻 System Monitor (Sistem İzleyici)
- [ ] **GPU İzleme**: Ekran kartı kullanımı ve sıcaklık bilgisi.
- [ ] **Ağ (Network)**: Anlık indirme/yükleme hızlarını gösteren grafik.
- [ ] **Sıcaklık Sensörleri**: CPU ve kasa sıcaklıklarını okuma desteği.

## 🔄 Advanced Reboot (Gelişmiş Başlatma)
- [ ] **UEFI/BIOS**: Doğrudan BIOS ayarlarına önyükleme yapma butonu.
- [ ] **Güvenlik**: Yanlışlıkla tıklamaları önlemek için "Kaydırarak onayla" veya 3 saniye geri sayım.

## 🌦️ Weather (Hava Durumu)
- [ ] **API Seçeneği**: OpenMeteo dışında alternatif sağlayıcılar (OpenWeatherMap vb.) ekleme.
- [ ] **Detaylı Görünüm**: Tıklayınca açılan pencerede saatlik tahmin grafiği ve rüzgar/nem detayları.
- [ ] **Konum**: IP tabanlı otomatik konum algılama.

##  Notes (Notlar)
- [ ] **Markdown**: Kalın, italik, liste gibi basit Markdown formatlama desteği.
- [ ] **Kategoriler**: Notları renklere veya etiketlere göre filtreleme.
- [ ] **Dışa Aktar**: Notları `.txt` veya `.md` dosyası olarak kaydetme.

##  Gemini KChat Fork
- [x] **Kod Blokları**: Yanıtlardaki kod bloklarını renklendirme/ayırma.
- [x] **Persona**: Sistem talimatları ile yapay zekaya kimlik kazandırma (Örn: Korsan gibi konuş).
- [x] **Güvenlik**: Güvenlik filtrelerini (Taciz, Nefret vb.) yapılandırma.
- [x] **JSON Modu**: Çıktıyı JSON formatına zorlama.
- [ ] **Geçmiş**: Sohbet geçmişini kalıcı olarak diske kaydetme (şu an sadece oturum bazlı).
- [ ] **Ses**: Sesli komut girişi (Speech-to-Text).

##  Notifications (Bildirimler)
- [ ] **Gruplama**: Bildirimleri uygulamaya göre gruplama.
- [ ] **Hızlı Yanıt**: Mesaj bildirimlerine widget üzerinden hızlı yanıt verme.

## 📸 Photos (Fotoğraflar)
- [ ] **Albümler**: Tek bir klasör yerine birden fazla klasörden slayt gösterisi.
- [ ] **Efektler**: Fotoğraf geçişlerinde farklı animasyon seçenekleri (Fade, Slide, Zoom).

---
*Son Güncelleme: 2026-01-01*
