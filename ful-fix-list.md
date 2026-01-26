# Widget Düzeltme ve İyileştirme Listesi (Full Fix List)

Bu belge, `plasmalogs.txt` dosyasının analizine dayanarak oluşturulmuş kapsamlı bir hata düzeltme listesidir. Aşağıdaki sorunlar aciliyet sırasına ve bileşenlere göre kategorize edilmiştir.

## 🚨 Kritik Widget Sorunları

Bu sorunlar widget'ların çalışmasını tamamen engelliyor veya ciddi fonksiyon kaybına neden oluyor.

### 1. Dosya Arama Widget'ı (`com.mcc45tr.filesearch`)
**Log Hataları:**
- `file:///.../ConfigGeneral.qml: Setting initial properties failed: ConfigGeneral does not have a property called cfg_...` (Çok sayıda özellik eksik)
- `ReferenceError: Plasmoid is not defined` dosya: `ui/components/PowerView.qml:91`
- `TypeError: Cannot read property 'indexOf' of undefined` dosya: `ui/components/PowerView.qml:84`

**Düzeltilecekler:**
- **Yapılandırma Bağlantıları (Config Binding):** `ConfigGeneral.qml`, `ConfigCategories.qml` ve `ConfigDebug.qml` dosyalarındaki `property alias` tanımları ile `main.xml` dosyasındaki ayar anahtarları (kcfg) uyuşmuyor veya QML tarafında bu özellikler (`cfg_autoMinimizePinnedDefault`, `cfg_displayModeDefault` vb.) tanımlanmamış. Bu özelliklerin `Config*.qml` dosyalarında tanımlı olduğundan emin olun.
- **`Plasmoid` Erişimi:** `PowerView.qml` içinde `Plasmoid` nesnesine erişim hatası var. Eğer bu dosya ana `main.qml`'den ayrı bir bileşen ise, `plasmoid` nesnesini bu bileşene bir özellik (property) olarak geçirmeniz gerekebilir (örn. `property var plasmoidRef: plasmoid`). Kod içinde `Plasmoid` yerine `plasmoid` (küçük harf) kullanılması gerekip gerekmediğini kontrol edin.
- **Veri Kontrolü:** `indexOf` hatası, üzerinde işlem yapılmaya çalışılan dizinin veya string'in `undefined` olduğunu gösteriyor. Kullanmadan önce verinin varlığını kontrol edin (`if (data && data.indexOf) ...`).

### 2. Müzik Oynatıcı Widget'ı (`com.mcc45tr.musicplayer`)
**Log Hataları:**
- `ConfigGeneral.qml`: `cfg_panelAutoButtonSize`, `cfg_panelButtonSize`, `cfg_panelDynamicWidth` vb. özellikleri bulunamıyor.
- `ConfigAppearance.qml`: Grafik nesnesi sahneye yerleştirilemedi.
- `No QSGTexture provided from updateSampledImage(). This is wrong.` (Render hatası)
- `ComboBox.qml`: `TypeError: Property 'positionToRectangle' ... is not a function`.

**Düzeltilecekler:**
- **Ayarlar:** `ConfigGeneral.qml` içindeki eksik `cfg_` önekli özelliklerin (alias) tanımlarını düzeltin.
- **Görselleştirme:** Albüm kapağı veya görsel işleme mantığında (`updateSampledImage`), görselin bellekte olmadı veya yolunun hatalı olduğu durumlar için (null check) ekleyin.
- **ComboBox Uyumu:** KDE'nin `org.kde.desktop` bileşenlerindeki sürüm uyumsuzluğunu kontrol edin veya standart `QtQuick.Controls` kullanmayı deneyin.

### 3. Gelişmiş Yeniden Başlatma (`com.mcc45tr.advancedreboot`)
**Log Hataları:**
- `1 instead of 2 arguments to message "%2 ile %1 yazdırılıy..." supplied before conversion` (Çeviri/Argüman hatası)
- `Member availWidth/availHeight ... overrides a member of the base object.`
- `Deprecated signal QDBusConnectionInterface::serviceOwnerChanged`

**Düzeltilecekler:**
- **i18n Düzeltmesi:** `%2 ile %1 yazdırılıy...` mesajını kullanan kod satırını bulun (muhtemelen `i18n(...)` çağrısı). Mesajda 2 değişken yeri (`%1`, `%2`) varken koda sadece 1 değişken sağlanıyor. Eksik argümanı ekleyin.
- **Miras Alma (Override) Uyarısı:** `availWidth` ve `availHeight` özelliklerini tanımlarken çakışma yaşanıyor. Eğer `Plasmoid.availWidth` kastediliyorsa, kendi yerel değişkeninizin adını değiştirin (örn. `localAvailWidth`) veya sadece readonly property olarak tanımlı olduğundan emin olun.
- **DBus Sinyali:** `serviceOwnerChanged` kullanımını modern Qt/KDE standartlarına göre güncelleyin.

## ⚠️ Eksik Dosya ve Yapılandırma Hataları

Widget'ların temel dosyaları veya yapılandırma dosyaları bulunamıyor.

### 4. Metadata.json Bulunamayanlar
Aşağıdaki widget'lar için sistem `metadata.json` dosyasını okuyamıyor. Bu, paketleme hatası veya dosya yolunun yanlış olmasından kaynaklıdır:
- `com.mcc45tr.mweather`
- `com.mcc45tr.analogclock`
- `com.mcc45tr.battery`
- `com.mcc45tr.browsersearch`

**Düzeltilecekler:**
- Bu projelerin klasör yapısını kontrol edin. `metadata.json` dosyasının kök dizinde veya `contents/` altında doğru yerde olduğundan emin olun (Plasma 6 standardına göre `root` dizininde olmalı).
- Dosyaların izinlerini kontrol edin.

### 5. Tarayıcı ve Uygulama Yolları
**Log Hataları:**
- `Failed to resolve executable from service. Error: "“/opt/brave-bin/brave” programı bulunamadı"`
- `"/usr/share/applications/onlyoffice-desktopeditors.desktop" ... doesn't use %u or %U`

**Düzeltilecekler:**
- Brave tarayıcısı sistemde kurulu değil veya yolu yanlış (`/opt/brave-bin/brave`). Eğer bu bir varsayılan ayarsa, daha genel bir yol (örn. `brave-browser` veya sadece komut adı) kullanın veya kullanıcıya tarayıcı seçme imkanı verin.
- `.desktop` dosyası hatası sistem genelindeki bir yapılandırma ile ilgili olabilir ama widget'larınız bu dosyaları tarıyorsa, `%u` veya `%U` parametrelerini kontrol eden mantığı daha esnek hale getirin.

## 🛠️ Genel Sistem ve KDE Hataları (Widget'ları Etkileyen)

### 6. Bildirimler (`org.kde.plasma.notifications`)
**Log Hataları:**
- `Globals.qml:515:13: Unable to assign [undefined] to bool` (Sürekli tekrar ediyor)
- `TypeError: Cannot read property 'screenGeometry' of null`

**Düzeltilecekler:**
- Bu hatalar KDE'nin kendi bildirim widget'ından kaynaklanıyor gibi görünüyor ancak sizin widget'larınız bildirim gönderiyorsa (özellikle `JobItem` hataları), gönderilen bildirimin parametrelerini (örneğin hedef URL, dosya boyutu vb.) tam ve doğru gönderdiğinizden emin olun. Null değerler bu hataları tetikliyor.

### 7. Grafik ve Performans
**Log Hataları:**
- `plasmashell` ve `kwin` için çok sayıda **Core Dump**.
- `GL_INVALID_VALUE in glTexStorage2D`.
- `load glyph failed err=6` (Font yükleme sorunları).

**Düzeltilecekler:**
- Widget'larınızda `ShaderEffect` veya yoğun grafik işlemi kullanan yerlerde doku (texture) boyutlarının 0 veya negatif olmadığından emin olun. `width` veya `height` 0 iken grafik çizdirmeye çalışmak bu GL hatalarına ve çökmelere neden olabilir.
- Widget'ların `width` ve `height` değerlerinin başlatma sırasında `0` gelip gelmediğini kontrol edin ve buna göre önlem alın.

## 📝 Özet Eylem Planı

1.  **Tüm `metadata.json` dosyalarını kontrol et:** Özellikle hata veren 4 widget için dosya yerleşimini düzelt.
2.  **File Search Config'i Onar:** `ConfigGeneral.qml` ve diğer config dosyalarındaki `property alias` tanımlarını `main.xml` ile eşleştir.
3.  **PowerView.qml Düzeltmesi:** `Plasmoid` referans hatasını gider. Global nesne yerine prop olarak geçirmeyi dene.
4.  **Advanced Reboot i18n:** Eksik metin argümanını tamamla.
5.  **Music Player Config:** Eksik config propertylerini tanımla.
6.  **Yol Kontrolleri:** Sabit kodlanmış `/opt/brave-bin/brave` gibi yolları kaldır veya dinamik hale getir.
