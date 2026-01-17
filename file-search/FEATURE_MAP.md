# MFile Finder - Özellik Eşleştirme Analizi

Bu belge, widget'ın **Backend** (mantıksal katman) ve **Frontend** (kullanıcı arayüzü) özelliklerini karşılaştırarak uyumsuzlukları tespit etmek için hazırlanmıştır.

---

## 📊 Özet Tablosu

| Özellik            | Backend | Frontend | Config | Durum         |
|:-------------------|:-------:|:--------:|:------:|:--------------|
| Arama Geçmişi      | ✅      | ✅       | ✅     | ✅ Tam        |
| Sabitleme (Pin)    | ✅      | ✅       | ✅     | ⚠️ Kısmi      |
| Kategori Önceliği  | ✅      | ❌       | ✅     | ⚠️ Eksik      |
| String Benzerliği  | ✅      | ❌       | ❌     | ⚠️ Eksik      |
| Context Menu       | ✅      | ✅       | ❌     | ✅ Tam        |
| Telemetri          | ✅      | ✅       | ✅     | ✅ Tam        |
| Debug Overlay      | ✅      | ✅       | ✅     | ✅ Tam        |
| Dosya Önizleme     | ❌      | ✅       | ✅     | ⚠️ Beklemede |
| Görünüm Profilleri | ❌      | ✅       | ✅     | ⚠️ Kısmi      |

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
| `timeline:today`    | Bugünkü dosyalar                  | ✅ KRunner                          |
| `gg:`               | Google arama                      | ✅ KRunner                          |
| `dd:`               | DuckDuckGo arama                  | ✅ KRunner                          |
| `kill`              | Uygulama sonlandır                | ✅ KRunner                          |
| `spell`             | Yazım denetimi                    | ✅ KRunner                          |
| `#`                 | Unicode karakter                  | ✅ KRunner                          |

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

## ⚠️ Tespit Edilen Uyumsuzluklar

### 1. Backend'de Var, Frontend'de Yok
| Özellik                         | Dosya               | Sorun                          | Durum        |
|:--------------------------------|:--------------------|:-------------------------------|:-------------|
| `applyPriorityToResults()`      | CategoryManager.js  | Sonuçlar sıralanmıyor          | ✅ Çözüldü   |
| `filterHiddenCategories()`      | CategoryManager.js  | Gizli kategoriler gösteriliyor | ✅ Çözüldü   |
| `processCategories()`           | CategoryManager.js  | Kategoriler işlenmiyor         | ✅ Çözüldü   |
| `sortBySimilarity()`            | SimilarityUtils.js  | Benzerlik sıralaması yok       | ✅ Çözüldü   |
| `sortByPriorityAndSimilarity()` | SimilarityUtils.js  | Birleşik sıralama yok          | ✅ Çözüldü   |
| `resetStats()`                  | TelemetryManager.js | Sıfırlama butonu yok           | ✅ Çözüldü   |
| `getPinInfo()`                  | PinnedManager.js    | Kullanılmıyor                  | ✅ Çözüldü   |
| `getSortedCategoryNames()`      | CategoryManager.js  | Kullanılmıyor                  | ✅ Çözüldü   |

### 2. Frontend'de Var, Backend'de Yok
| Özellik             | Dosya            | Sorun                                   | Durum        |
|:--------------------|:-----------------|:----------------------------------------|:-------------|
| `previewEnabled`    | Config           | Backend mantığı yok (sadece UI toggle)  | ✅ Çözüldü   |
| `userProfile`       | Config           | Profil değişikliği backend'i etkilemiyor| ✅ Çözüldü   |
| File Thumbnail      | ResultsListView  | Backend'de dosya okuma yok              | ✅ Çözüldü   |

### 3. Kısmi Entegrasyon
| Özellik            | Sorun                                                      | Durum        |
|:-------------------|:-----------------------------------------------------------|:-------------|
| Category Priority  | ConfigCategories'de ayarlanıyor ama sonuçlara uygulanmıyor | ✅ Çözüldü   |
| Category Visibility| ConfigCategories'de ayarlanıyor ama filtre yok             | ✅ Çözüldü   |
| Pin by Activity    | Backend destekliyor, UI'da aktivite seçimi yok             | ✅ Çözüldü   |

---

## 🛠️ Önerilen Düzeltmeler

### Öncelik 1: Kategori Önceliği Entegrasyonu
**Dosya:** `TileDataManager.qml`
```qml
// Sonuçları önceliklendirme
import "../js/CategoryManager.js" as CategoryManager

property var prioritizedData: CategoryManager.applyPriorityToResults(
    rawData, 
    logic.categorySettings
)
```

### Öncelik 2: Benzerlik Sıralaması Entegrasyonu
**Dosya:** `TileDataManager.qml`
```qml
import "../js/SimilarityUtils.js" as SimilarityUtils

property var sortedData: SimilarityUtils.sortByPriorityAndSimilarity(
    rawData,
    searchText,
    logic.categorySettings,
    CategoryManager.getCategoryPriority
)
```

### Öncelik 3: Gizli Kategori Filtreleme
**Dosya:** `TileDataManager.qml`
```qml
property var visibleData: {
    return rawData.filter(item => 
        CategoryManager.isCategoryVisible(logic.categorySettings, item.category)
    )
}
```

### Öncelik 4: Telemetri Sıfırlama Butonu
**Dosya:** `ConfigDebug.qml`
- "Reset Stats" butonu ekle
- `TelemetryManager.resetStats()` çağrısı yap
