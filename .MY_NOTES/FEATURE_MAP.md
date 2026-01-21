# MFile Finder - Özellik Eşleştirme Analizi

Bu belge, widget'ın **Backend** (mantıksal katman) ve **Frontend** (kullanıcı arayüzü) özelliklerini karşılaştırarak uyumsuzlukları tespit etmek için hazırlanmıştır.

---

## 📊 Özet Tablosu

| Özellik            | Backend | Frontend | Config | Durum         |
|:-------------------|:-------:|:--------:|:------:|:--------------|
| Arama Geçmişi      | ✅      | ✅       | ✅     | ✅ Tam        |
| Sabitleme (Pin)    | ✅      | ✅       | ✅     | ✅ Tam        |
| Kategori Önceliği  | ✅      | ✅       | ✅     | ✅ Tam        |
| String Benzerliği  | ✅      | ✅       | ✅     | ✅ Tam        |
| Context Menu       | ✅      | ✅       | ✅     | ✅ Tam        |
| Telemetri          | ✅      | ✅       | ✅     | ✅ Tam        |
| Debug Overlay      | ✅      | ✅       | ✅     | ✅ Tam        |
| Dosya Önizleme     | ✅      | ✅       | ✅     | ✅ Tam        |
| Görünüm Profilleri | ✅      | ✅       | ✅     | ✅ Tam        |
| KRunner Prefixleri | ✅      | ✅       | ✅     | ✅ Tam        |

---

## 🔧 Backend Özellikleri

### 1. HistoryManager.js
| Fonksiyon             | Açıklama                          | Frontend Karşılığı                      |
|:----------------------|:----------------------------------|:----------------------------------------|
| `loadHistory()`       | Geçmişi yükle                     | ✅ `LogicController.loadHistory()`      |
| `addToHistory()`      | Geçmişe ekle                      | ✅ `SearchPopup.handleResultClick()`    |
| `removeFromHistory()` | Geçmişten sil                     | ✅ `HistoryContextMenu`                 |
| `clearHistory()`      | Geçmişi temizle                   | ✅ `HistoryListView.onClearClicked`     |
| `updateItemIcon()`    | İkon güncelle                     | ✅ `LogicController.iconCheckTimer`     |
| `categorizeHistory()` | Grupla                            | ✅ `HistoryListView`, `HistoryTileView` |

### 2. PinnedManager.js
| Fonksiyon               | Açıklama                          | Frontend Karşılığı                   |
|:------------------------|:----------------------------------|:-------------------------------------|
| `loadPinned()`          | Sabitleri yükle                   | ✅ `LogicController.loadPinned()`    |
| `pinItem()`             | Sabitle                           | ✅ `PinButton`                       |
| `unpinItem()`           | Sabitlemeyi kaldır                | ✅ `PinnedSection.unpinClicked`      |
| `togglePin()`           | Sabitlemeyi değiştir              | ✅ `ResultsListView.togglePinFunc`   |
| `isPinned()`            | Sabitli mi kontrol                | ✅ `ResultsListView.isPinnedFunc`    |
| `getPinnedForActivity()`| Aktiviteye göre al                | ✅ `SearchPopup.pinnedLoader`        |
| `getPinInfo()`          | Sabitleme bilgisi                 | ✅ `LogicController.getPinInfo()`    |

### 3. CategoryManager.js
| Fonksiyon                 | Açıklama                          | Frontend Karşılığı                   |
|:--------------------------|:----------------------------------|:-------------------------------------|
| `loadCategorySettings()`  | Ayarları yükle                    | ✅ `LogicController`                 |
| `saveCategorySettings()`  | Ayarları kaydet                   | ✅ `ConfigCategories`                |
| `setCategoryVisibility()` | Görünürlük ayarla                 | ✅ `ConfigCategories`                |
| `isCategoryVisible()`     | Görünür mü kontrol                | ✅ `TileDataManager.refreshGroups()`  |
| `setCategoryPriority()`   | Öncelik ayarla                    | ✅ `ConfigCategories`                |
| `getCategoryPriority()`   | Öncelik al                        | ✅ `TileDataManager.refreshGroups()`  |
| `setCategoryIcon()`       | Özel ikon ayarla                  | ✅ `ConfigCategories` (dialog)       |
| `getEffectiveIcon()`      | Etkin ikonu al                    | ✅ `ConfigCategories`                |
| `sortCategories()`        | Kategorileri sırala               | ✅ `TileDataManager.refreshGroups()`  |
| `filterHiddenCategories()`| Gizlileri filtrele                | ✅ `TileDataManager.refreshGroups()`  |
| `processCategories()`     | İşle (filtre + sırala)            | ✅ `TileDataManager.refreshGroups()`  |
| `applyPriorityToResults()`| Sonuçları sırala                  | ✅ `TileDataManager.refreshGroups()`  |
| `reorderCategories()`     | Drag-drop sırala                  | ✅ `ConfigCategories`                |
| `getSortedCategoryNames()`| Sıralı isimleri al                | ✅ `TileDataManager.refreshGroups()`  |

### 4. SimilarityUtils.js
| Fonksiyon                       | Açıklama                          | Frontend Karşılığı                  |
|:--------------------------------|:----------------------------------|:------------------------------------|
| `levenshteinDistance()`         | Mesafe hesapla                    | ✅ `TileDataManager` (internal)      |
| `similarityScore()`             | Benzerlik puanı                   | ✅ `TileDataManager` (internal)      |
| `sortBySimilarity()`            | Benzerliğe göre sırala            | ✅ `TileDataManager` (internal)      |
| `sortByPriorityAndSimilarity()` | Birleşik sıralama                 | ✅ `TileDataManager.refreshGroups()` |

### 5. TelemetryManager.js
| Fonksiyon           | Açıklama                          | Frontend Karşılığı                   |
|:--------------------|:----------------------------------|:-------------------------------------|
| `getEmptyStats()`   | Boş istatistik                    | ✅ Internal                          |
| `loadStats()`       | İstatistik yükle                  | ✅ `LogicController`                 |
| `recordSearch()`    | Aramayı kaydet                    | ✅ `TileDataManager.startSearch()`   |
| `resetStats()`      | Sıfırla                           | ✅ `ConfigDebug` (Reset Button)      |
| `getStatsObject()`  | Obje olarak al                    | ✅ `DebugOverlay`                    |

---

## 🖼️ Frontend Özellikleri

### 1. main.qml (Ana Widget)
| Özellik             | Açıklama                          | Backend Karşılığı                   |
|:--------------------|:----------------------------------|:------------------------------------|
| Display Mode        | Button/Medium/Wide/Extra Wide      | ✅ `displayMode` config             |
| View Mode           | Liste/Döşeme                      | ✅ `viewMode` config                |
| Responsive Font     | Panel yüksekliğine göre           | ❌ Sadece UI                        |
| Contextual Actions  | Sağ tık mod değiştirme            | ❌ Sadece UI                        |

### 2. SearchPopup.qml
| Özellik             | Açıklama                          | Backend Karşılığı                   |
|:--------------------|:----------------------------------|:------------------------------------|
| Lazy Loading        | 7 Loader bileşeni                 | ❌ Sadece UI                        |
| Focus Section       | Tab ile bölüm geçişi              | ❌ Sadece UI                        |
| History Click       | Geçmişten tıklama                 | ✅ `HistoryManager`                 |
| Result Click        | Sonuç tıklama                     | ✅ `HistoryManager.addToHistory`    |

### 3. HistoryContextMenu.qml
| Menü Öğesi           | Açıklama                          | Backend Karşılığı                   |
|:---------------------|:----------------------------------|:------------------------------------|
| Aç                   | Dosya/uygulama aç                 | ✅ `kioclient exec`                 |
| Birlikte Aç          | Open With dialog                  | ✅ `kioclient openProperties`       |
| Yolu Kopyala         | Panoya kopyala                    | ✅ `xclip`                          |
| Terminalde Aç        | Konsole başlat                    | ✅ `konsole --workdir`              |
| Çöp Kutusuna Taşı    | Sil                               | ✅ `kioclient move trash:/`         |
| Bulunduğu Klasörü Aç | Dolphin ile aç                    | ✅ `dolphin --select`               |
| Özellikler           | Dosya özellikleri                 | ✅ `kioclient openProperties`       |
| Geçmişten Kaldır     | Kaldır                            | ✅ `HistoryManager.removeFromHistory`|

### 4. QueryHints.qml
| Prefix              | Açıklama                          | Backend Karşılığı                   |
|:--------------------|:----------------------------------|:------------------------------------|
| `timeline:/`        | Etkileşimli zaman tüneli          | ✅ KRunner (Sub-menu support)       |
| `file:/`            | Dosya yolu gezinme                | ✅ KRunner                          |
| `man:/`             | Man sayfaları (Kurulum kontrolü)  | ✅ `command -v man` check           |
| `gg:`               | Google arama                      | ✅ KRunner                          |
| `dd:`               | DuckDuckGo arama                  | ✅ KRunner                          |
| `wp:`               | Wikipedia arama                   | ✅ KRunner                          |
| `kill`              | Uygulama sonlandır                | ✅ KRunner                          |
| `spell`             | Yazım denetimi                    | ✅ KRunner                          |
| `#`                 | Unicode karakter                  | ✅ KRunner                          |
| `app:` / `shell:`   | Uygulama ve kabuk komutları       | ✅ KRunner                          |
| `power:`            | Güç seçenekleri                   | ✅ KRunner                          |
| `services:`         | Sistem servisleri                 | ✅ KRunner                          |
| `date` / `define:`  | Tarih ve Sözlük                   | ✅ KRunner                          |
| `unit:`             | Birim dönüştürücü                 | ✅ KRunner                          |

### 5. DebugOverlay.qml
| Gösterge            | Açıklama                          | Backend Karşılığı                   |
|:--------------------|:----------------------------------|:------------------------------------|
| Result Count        | Sonuç sayısı                      | ✅ `TileDataManager.resultCount`    |
| Latency             | Gecikme süresi                    | ✅ `TelemetryManager`               |
| Total Searches      | Toplam arama                      | ✅ `TelemetryManager`               |
| Avg Latency         | Ortalama gecikme                  | ✅ `TelemetryManager`               |
| Save Dump           | Debug verisi kaydet               | ❌ Sadece UI (dosyaya yazar)         |

---

## ⚙️ Yapılandırma Eşleştirme (main.xml)

| Config Entry       | Type   | Backend Kullanımı                      | Frontend Kullanımı                      |
|:-------------------|:-------|:---------------------------------------|:----------------------------------------|
| `displayMode`      | Int    | ✅ `ConfigManager.sanitizeConfig()`    | ✅ `main.qml`                           |
| `viewMode`         | Int    | ✅ `ConfigManager.sanitizeConfig()`    | ✅ `main.qml`, `SearchPopup`            |
| `iconSize`         | Int    | ✅ `ConfigManager.getRecommendedIconSize()`| ✅ Tile görünümler                  |
| `listIconSize`     | Int    | ✅ `ConfigManager.isValidListIconSize()`| ✅ Liste görünümler                    |
| `userProfile`      | Int    | ✅ `ConfigManager.getProfileDefaults()`| ✅ `ConfigGeneral`, `LogicController`   |
| `previewEnabled`   | Bool   | ✅ `ConfigManager.isFeatureEnabled()`  | ✅ `ResultsListView` (Tooltip)          |
| `debugOverlay`     | Bool   | ✅ `ConfigManager.isFeatureEnabled()`  | ✅ `SearchPopup.showDebug`              |
| `searchHistory`    | String | ✅ `HistoryManager`                    | ✅ `HistoryListView/TileView`           |
| `telemetryData`    | String | ✅ `TelemetryManager`                  | ✅ `DebugOverlay`                       |
| `pinnedItems`      | String | ✅ `PinnedManager`                     | ✅ `PinnedSection`                      |
| `categorySettings` | String | ✅ `CategoryManager`                   | ✅ `ConfigCategories`, `TileDataManager`|

---

---

## ✅ Tamamlanan İyileştirmeler

### 1. Backend-Frontend Entegrasyonu
- `TileDataManager.qml` artık `CategoryManager` ve `SimilarityUtils` fonksiyonlarını tam olarak kullanıyor.
- Sonuçlar hem kategori önceliğine hem de başlık benzerliğine göre sıralanıyor.
- Gizli kategoriler (ayarlardan kapatılanlar) sonuç listesinden anında filtreleniyor.

### 2. Modern Mimari
- Logic, Data ve UI katmanları birbirinden ayrıldı (`LogicController`, `TileDataManager`, `SearchPopup`).
- Loader tabanlı **Lazy Loading** ile bellek kullanımı optimize edildi.
- Navigasyon için klavye desteği (ok tuşları, Enter, Tab) eklendi.

### 3. Etkileşimli KRunner İpuçları
- `QueryHints.qml` artık sadece metin değil, butonlar ve dinamik seçenekler sunuyor.
- `timeline:/` için alt menüler ve dinamik ay/gün hesaplaması eklendi.
- Sistem bağımlılıkları (örn. `man`) için çalışma zamanı kontrolleri eklendi.

### 4. Stabilite ve UX
- Geçmişten uygulama başlatma (`.desktop`) hızı `kioclient exec` ile artırıldı.
- Sağ tık menüleri tüm görünüm modlarında tutarlı hale getirildi.
- Telemetri istatistikleri için sıfırlama mekanizması eklendi.

---

## 🐞 Önemli Hata Düzeltmeleri

### 1. Kategori Ayarları Sayfası (Kritik)
- **Sorun:** Ayarlar penceresinde "Kategoriler" sekmesine tıklandığında sayfa açılmıyordu.
- **Neden:** `ConfigCategories.qml` dosyasında `KCM.SimpleKCM` kök elemanının yanlış kullanımı ve `Plasmoid.configuration` nesnesine ConfigModel bağlamında güvensiz erişim.
- **Çözüm:** Kök eleman `Item` olarak değiştirildi, `implicitWidth/Height` tanımlandı ve `cfg_` tabanlı null-safe mülk (property) erişimine geçildi.
- **Sonuç:** Kategoriler sayfası tüm Plasma 6 sürümlerinde stabil şekilde açılır ve yapılandırılabilir hale getirildi.

### 2. Konfigürasyon Lokalizasyonu
- **Sorun:** Ayarlar menüsündeki sekme başlıkları çeviri dosyasına rağmen İngilizce kalıyordu.
- **Çözüm:** `config.qml` dosyasına widget'ın yerleşik localization motoru entegre edildi ve tüm başlıklar dinamik hale getirildi.

### 3. Zaman Çizelgesi (Timeline) Butonları
- **Sorun:** `timeline:/` komutu yazıldığında butonlar hiyerarşik (Ay/Gün) olarak görünmüyor veya yanlış tarih formatı sunuyordu.
- **Çözüm:** Hiyerarşik navigasyon (Calendar -> Months -> Days) eklendi. Yerel tarih formatları (`toLocaleDateString`) ve "Bugün", "Dün" gibi özel klasör isimleri için KIO uyumlu dinamik buton üretimi sağlandı.
