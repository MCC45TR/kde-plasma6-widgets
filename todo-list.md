# Proje Yapılacaklar ve İyileştirmeler Listesi (Todo List)

Bu dosya, Plasma 6 Widget projesindeki her bir bileşen için potansiyel iyileştirmeleri, eksiklikleri ve düzeltilmesi gereken hataları içermektedir.

---

## 🌍 Global (Tüm Widgetlar)
- [ ] **Lokalizasyon Geçişi**: Tüm widget'ları File Search'te olduğu gibi senkron `localization.js` modül yapısına geçir. (`XMLHttpRequest` yerine `import` kullanımı).
- [ ] **Modülerleştirme**: Büyük `main.qml` dosyalarını küçük, yönetilebilir bileşenlere (`components/` klasörü altına) ayır.
- [ ] **Versiyonlama**: Tüm `metadata.json` dosyalarındaki versiyonları 1.1.0 standardına çek.
- [ ] **Kod Temizliği**: Kullanılmayan `i18n` çağrılarını ve gereksiz importları temizle.
### 📦 Yapılandırma & Ayarlar
- [ ] **Unified Config Schema**: Tüm `config.qml` dosyaları ortak şema kullansın.
- [ ] **Backward Compatibility**: Eski config’ler otomatik migrate edilsin.
- [ ] **Reset-to-default**: Her widget için tek tuşla fabrika ayarları.
- [ ] **Per-Widget Debug Toggle**: Ayarlardan debug overlay aç/kapat.
### 🔐 Güvenlik & Sağlamlık
- [ ] **Input Sanitization**: Kullanıcı girdileri normalize edilsin.
- [ ] **Fail-Safe Defaults**: Hata durumunda safe mode.
- [ ] **Exception Guard**: JS hataları UI’yi kilitlememeli.
- [ ] **Permission Awareness**: Dosya / servis erişimlerinde açık hata mesajları.
### 📄 Dokümantasyon & Bakım
- [ ] **Widget README Template**: Her widget için standart README.
- [ ] **Architecture Notes**: Mimari kararların dokümantasyonu.
- [ ] **Changelog Discipline**: breaking / feature / fix ayrımı.
- [ ] **Deprecation Policy**: Kaldırılacak API’lerin önceden işaretlenmesi.
### 🧪 Geliştirici Deneyimi
- [ ] **Global Debug Mode**: Ortak `DEBUG` flag (focus, bounds, timing overlay).
- [ ] **Logging Utility**: Seviyeli logger (`info / warn / error`).
- [ ] **Mock Data Providers**: İzole testler için sahte veri kaynakları.
- [ ] **Dev-only Shortcuts**: Reload, layout inspect, state dump kısayolları.
### 🌐 Lokalizasyon & Metin Yönetimi
- [ ] **Key Naming Convention**: `widget.section.action.label` formatı.
- [ ] **Missing Translation Detector**: Eksik çeviri varsa dev modda uyarı.
- [ ] **RTL Readiness**: RTL diller için layout testleri.
- [ ] **Plural Rules Audit**: Çoğul kurallarının doğrulanması.
### ⚙️ Performans & Stabilite
- [ ] **Lazy Initialization**: Görünmeyen bileşenler `Loader` ile gecikmeli yüklensin.
- [ ] **Binding Audit**: Aşırı re-evaluate olan binding’ler refactor edilsin.
- [ ] **Animation Budget**: Aynı anda çalışan animasyon sayısı sınırlandırılsın.
- [ ] **Memory Watchpoints**: Image cache ve model lifecycle kontrolü.

## 🔍 File Finder (File Search)
- [x] UI Modülerleştirmesi (CompactView, ResultsListView vb.)
- [x] Senkron Lokalizasyon Sistemi
- [x] Geçmiş Yönetimi Modülü
- [x] Kategori Filtreleme (kategori başlığına tıklayarak gizle/göster)
- [x] Klavye Navigasyonu (temel destek)
- [x] Döşeme görünümünde ok tuşları ile **tam yönlü gezinme**
- [x] Focus state senkronizasyonu (Tile / List / Compact)
- [x] `Tab / Shift+Tab` ile bölümler arası geçiş
- [x] `Ctrl + 1 / 2` ile görünüm modu değiştirme
- [x] Aktif öğe için erişilebilirlik vurgusu (focus highlight)
### 🔎 Akıllı Arama Girişi (Smart Query)
- [x] Gelişmiş sözdizimi:
  - KRunner native: `timeline:/today`, `gg:`, `dd:`, `kill`, `spell`, `#unicode`
- [x] KRunner uyumlu query parsing
- [x] Hatalı sözdizimi için inline uyarı mesajları
### 📊 Sonuç Önceliklendirme
- [ ] Skor bazlı sıralama:
  - Son kullanılan
  - En sık açılan
  - Kategori eşleşmesi
- [ ] “Bu sonuç neden üstte?” tooltip açıklaması
### 📌 Sabitlenmiş (Pinned) Öğeler
- [ ] Dosya / klasör pinleme
- [ ] Aramadan bağımsız üstte gösterim
- [ ] Activity-aware pinleme
### 🕓 Arama Oturumu Snapshot
- [ ] Aramayı kaydetme (history’den bağımsız)
- [ ] Donmuş sonuç seti
- [ ] Snapshot yeniden açma
### 🧩 Çoklu Seçim & Toplu İşlemler
- [ ] Shift / Ctrl ile çoklu seçim
- [ ] Toplu işlemler:
  - Aç
  - Konuma git
  - Yol kopyala
  - Etiketle
### 👁️ Hover / Focus Önizleme
- [x] Hover ile küçük bilgi pop-up’ı:
  - Dosya türü
  - Boyut
  - Son değiştirilme tarihi
  - Varsayılan uygulama
- [x] Görseller için thumbnail cache
- [x] Klavye ile tetikleme (`Ctrl+Space`)
### 🚀 Performans İyileştirmeleri
- [x] Lazy loading (Loader ile)
- [x] Virtualized list rendering (ListView yerleşik)
- [x] Büyük sonuç setleri için incremental render
### 🗂️ Arama Backend Yönetimi
- [ ] Baloo entegrasyonu
- [ ] Fallback filesystem search
- [ ] Ayarlar üzerinden backend seçimi
- [ ] Index yoksa graceful degrade
### 🎨 Görünüm Profilleri
- [x] Ayarlar üzerinden profil seçimi (Genel sekemsi adı "Görünüm" olarak değiştirilecek)
- [x] Ayarlar'a "Arama" sekmesi eklenecek (arama sekmesi altında arama algotiması ve sonuç listesi ayarları yer alacak)
- [x] Profil setleri:
  - Minimal
  - Developer 
   - Developer mod seçildiğinde ayarlar'da debug sekmesi açılacak ve özellikleri kullanıcı tarafından ayarlanabilecektir.
   - Debug verilerini $HOME dizinine DUMP'et düğmesi bu sekme altında görünecektir.
  - Power User
- [x] Profil bazlı:
  - Varsayılan filtreler
  - Önizleme açık/kapalı
  - Tile yoğunluğu
  - Ayarlada kalvuz sekmesi
   - Vidgetin tüm özellikleri lokalizasyonla kullanıcıya açıklanacak
### 🧷 Kategori Bazlı Ayarlar
- [ ] Kategori özel görünürlük
- [ ] Önceliklendirme
- [ ] Özel ikon tanımı
### 📈 Debug & Telemetry (Opt-in)
- [ ] Debug overlay:
  - Aktif mod
  - Render edilen öğe sayısı
  - Index kaynağı
  - Arama gecikmesi
- [ ] Lokal ve anonim kullanım verisi
- [ ] **Dosya Önizleme**: Dosyaların üzerine gelince (hover) küçük bir önizleme veya detaylı bilgi pop-up'ı.

## 🎵 Music Player
- [ ] **Şarkı Sözleri**: Çalan şarkının sözlerini (Lyrics) gösterecek bir panel/mod ekle (API entegrasyonu gerekebilir).
- [ ] **Performans**: Albüm kapağı bulanıklık efekti (FastBlur) bazen animasyonları takılmaya uğratıyor; optimize edilmeli.
- [ ] **Spotify Gelişmiş Kontrol**: Sadece MPRIS değil, Spotify API kullanarak çalma listelerine erişim.
- [ ] **Seek Bar**: İlerleme çubuğunda tıklanan yere tam saniyesinde atlama hassasiyeti artırılmalı.

## 🗓️ Calendar (Takvim)
### 📅 Resmi Tatiller
- [ ] Yerel **JSON tabanlı tatil veri kaynağı** desteği
- [ ] Opsiyonel **uzak API** üzerinden resmi tatil çekme
- [ ] Ülke / bölge bazlı tatil seti seçimi
- [ ] Tatillerin takvim görünümünde görsel olarak işaretlenmesi
- [ ] Offline kullanım için **cache + fallback** mekanizması
- [ ] Resmi tatiller, yerel ve harici etkinlikler için **renk kodlaması**
### ⚙️ Performans & Altyapı
- [ ] Lazy loading ile ay bazlı veri yükleme
- [ ] Gereksiz yeniden render’ların önlenmesi
- [ ] Büyük etkinlik listeleri için optimized model yapısı
- [ ] Tatil / etkinlik veri kaynağı test modu

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
