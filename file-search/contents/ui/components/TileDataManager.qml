import QtQuick
import org.kde.milou as Milou
import "../js/CategoryManager.js" as CategoryManager
import "../js/PreviewUtils.js" as PreviewUtils
import "../js/SimilarityUtils.js" as SimilarityUtils
import "../js/IconMapper.js" as IconMapper

Item {
    id: dataManager
    
    required property var resultsModel
    required property var logic
    
    // Search text for similarity scoring
    property string searchText: ""
    property string activeFilter: "Tümü"
    property int maxResults: 20
    property string lastRefreshSignature: ""
    
    onSearchTextChanged: {
        refreshDebouncer.restart()
    }
    
    onActiveFilterChanged: {
        refreshDebouncer.restart()
    }
    
    Connections {
        target: logic
        function onRssCacheChanged() {
            refreshDebouncer.restart()
        }
    }

    Connections {
        target: resultsModel
        function onRowsInserted() { refreshDebouncer.restart() }
        function onRowsRemoved() { refreshDebouncer.restart() }
        function onModelReset() { refreshDebouncer.restart() }
        function onDataChanged() { refreshDebouncer.restart() }
    }
    
    property var categorizedData: []
    property var flatSortedData: []
    property int resultCount: 0
    property int lastLatency: 0
    property int refreshVersion: 0
    
    // Internal state
    property real searchStartTime: 0
    readonly property var fileOnlyCategories: ["Files", "Dosyalar", "Folders", "Klasörler", "Documents", "Belgeler", "Images", "Resimler", "Audio", "Ses", "Video", "Videolar", "Places", "Yerler"]
    
    function startSearch() {
        searchStartTime = new Date().getTime()
    }
    
    function refreshGroups() {
        var rssItems = (logic.rssCache && Array.isArray(logic.rssCache)) ? logic.rssCache : [];
        var firstItem = rawDataProxy.count > 0 ? rawDataProxy.itemAt(0) : null;
        var lastItem = rawDataProxy.count > 0 ? rawDataProxy.itemAt(rawDataProxy.count - 1) : null;
        var signature = [
            searchText,
            activeFilter,
            maxResults,
            rawDataProxy.count,
            firstItem ? (firstItem.display || "") : "",
            firstItem ? (firstItem.url || "") : "",
            lastItem ? (lastItem.display || "") : "",
            lastItem ? (lastItem.url || "") : "",
            rssItems.length,
            rssItems.length > 0 ? (rssItems[0].duplicateId || rssItems[0].display || "") : "",
            rssItems.length > 0 ? (rssItems[rssItems.length - 1].duplicateId || rssItems[rssItems.length - 1].display || "") : ""
        ].join("||");

        if (signature === lastRefreshSignature)
            return;
        lastRefreshSignature = signature;

        var groups = {};
        var displayOrder = [];
        var categorySettings = logic.categorySettings || {};
        var rawItems = [];
        var lowerSearch = searchText.toLowerCase();
        var isFileOnlyMode = lowerSearch.startsWith("file:/");
        var isRSSOnlyMode = lowerSearch.startsWith("rss:");
        var activeFilterLower = (dataManager.activeFilter || "").toLowerCase();
        
        // Extract RSS query: everything after 'rss:' prefix
        var rssQuery = "";
        if (isRSSOnlyMode) {
            rssQuery = lowerSearch.substring(4).trim();
        }

        if (!isRSSOnlyMode) {
            for (var i = 0; i < rawDataProxy.count; i++) {
                var item = rawDataProxy.itemAt(i);
                if (!item)
                    continue;

                var cat = item.category || "Diğer";
                if (!CategoryManager.isCategoryVisible(categorySettings, cat))
                    continue;

                var urlString = (item.url || "").toString();
                var lowerCategory = cat.toLowerCase();
                var lowerDecoration = (item.decoration || "").toString().toLowerCase();
                var lowerUrl = urlString.toLowerCase();
                var ext = PreviewUtils.getExtension(urlString);

                if (dataManager.activeFilter !== "Tümü") {
                    var shouldKeep = false;

                    if (activeFilterLower === "belgeler") {
                        shouldKeep = (lowerCategory.indexOf("belge") !== -1 || lowerCategory.indexOf("document") !== -1 || lowerCategory.indexOf("text") !== -1 ||
                                     lowerDecoration.indexOf("document") !== -1 || lowerDecoration.indexOf("text") !== -1 || PreviewUtils.isDocumentLikeExtension(ext));
                    } else if (activeFilterLower === "resimler") {
                        shouldKeep = (lowerCategory.indexOf("resim") !== -1 || lowerCategory.indexOf("image") !== -1 || lowerCategory.indexOf("picture") !== -1 ||
                                     lowerCategory.indexOf("photo") !== -1 || lowerCategory.indexOf("görsel") !== -1 || lowerCategory.indexOf("görüntü") !== -1 ||
                                     lowerDecoration.indexOf("image") !== -1 || lowerDecoration.indexOf("photo") !== -1 || lowerDecoration.indexOf("picture") !== -1 ||
                                     PreviewUtils.isImageExtension(ext));
                    } else if (activeFilterLower === "klasörler") {
                        shouldKeep = (lowerCategory.indexOf("klasör") !== -1 || lowerCategory.indexOf("folder") !== -1 || lowerCategory.indexOf("yerler") !== -1 ||
                                     lowerCategory.indexOf("place") !== -1 || lowerDecoration.indexOf("folder") !== -1 || lowerUrl.endsWith("/"));
                    } else if (activeFilterLower === "uygulamalar") {
                        shouldKeep = (lowerCategory.indexOf("uygulama") !== -1 || lowerCategory.indexOf("application") !== -1 || lowerCategory.indexOf("app") !== -1 ||
                                     lowerCategory.indexOf("program") !== -1 || lowerDecoration.indexOf("app") !== -1 || lowerUrl.endsWith(".desktop"));
                    } else if (activeFilterLower === "web") {
                        shouldKeep = (lowerCategory.indexOf("web") !== -1 || lowerCategory.indexOf("bookmark") !== -1 || lowerCategory.indexOf("yer imi") !== -1 ||
                                     lowerCategory.indexOf("internet") !== -1 || lowerCategory.indexOf("browser") !== -1 || lowerDecoration.indexOf("globe") !== -1 ||
                                     lowerDecoration.indexOf("web") !== -1 || lowerUrl.startsWith("http") || lowerUrl.startsWith("www"));
                    } else if (activeFilterLower === "haberler" || activeFilterLower === "rss") {
                        shouldKeep = (lowerCategory.indexOf("haber") !== -1 || lowerCategory.indexOf("news") !== -1 || lowerCategory.indexOf("rss") !== -1 || lowerDecoration.indexOf("news") !== -1);
                    }

                    if (!shouldKeep)
                        continue;
                }

                if (isFileOnlyMode) {
                    var isFileUrl = urlString.indexOf("file://") === 0;
                    if (!isFileUrl && fileOnlyCategories.indexOf(cat) === -1)
                        continue;
                }

                rawItems.push({
                    display: item.display || "",
                    decoration: IconMapper.getIconForUrl(urlString, item.decoration || "", cat),
                    category: cat,
                    url: urlString,
                    urls: item.urls || [],
                    subtext: item.subtext || "",
                    duplicateId: item.duplicateId || "",
                    index: item.itemIndex
                });
            }
        }

        var activeF = dataManager.activeFilter;
        // RSS logic: Include if in RSS mode OR if RSS is enabled and a relevant filter is active
        if (isRSSOnlyMode || (logic.rssEnabled && (activeF === "Tümü" || activeF === "All" || activeF === "Web" || activeF === "RSS" || activeF === "Haberler"))) {
            for (var r = 0; r < rssItems.length; r++) {
                var rssEntry = rssItems[r];
                if (isRSSOnlyMode && rssQuery.length > 0) {
                    var title = (rssEntry.display || "").toLowerCase();
                    var content = (rssEntry.indexedContent || "").toLowerCase();
                    if (title.indexOf(rssQuery) === -1 && content.indexOf(rssQuery) === -1)
                        continue;
                }

                if (CategoryManager.isCategoryVisible(categorySettings, rssEntry.category))
                    rawItems.push(rssEntry);
            }
        }

        // Final fallback for empty RSS query results
        if (isRSSOnlyMode && rssQuery.length === 0 && rawItems.length === 0)
            rawItems = rssItems.slice();

        if (isRSSOnlyMode) {
            if (rssQuery && rssQuery.length > 3) {
                rawItems = SimilarityUtils.sortByPriorityAndSimilarity(
                    rawItems,
                    rssQuery,
                    categorySettings,
                    CategoryManager.getCategoryPriority
                );
            }
        } else if (searchText && searchText.length > 0) {
            rawItems = SimilarityUtils.sortByPriorityAndSimilarity(
                rawItems,
                searchText,
                categorySettings,
                CategoryManager.getCategoryPriority
            );
        } else {
            rawItems = CategoryManager.applyPriorityToResults(rawItems, categorySettings);
        }

        var effectiveMaxResults = isRSSOnlyMode ? 400 : maxResults;
        if (effectiveMaxResults > 0 && rawItems.length > effectiveMaxResults)
            rawItems = rawItems.slice(0, effectiveMaxResults);

        for (var j = 0; j < rawItems.length; j++) {
            var sortedItem = rawItems[j];
            var sortedCat = sortedItem.category;

            if (!groups[sortedCat]) {
                groups[sortedCat] = [];
                displayOrder.push(sortedCat);
            }

            groups[sortedCat].push(sortedItem);
        }

        var otherItems = [];
        var finalOrder = [];
        for (var k = 0; k < displayOrder.length; k++) {
            var catName = displayOrder[k];
            var items = groups[catName];
            var isAppCategory = (catName === "Uygulamalar" || catName === "Applications");
            var isRSSCategory = (catName === "RSS" || catName === "Haberler");

            // Don't merge RSS or Applications into "Other Results" even if there is only one
            if (items.length <= 1 && !isAppCategory && !isRSSCategory) {
                for (var m = 0; m < items.length; m++)
                    otherItems.push(items[m]);
            } else {
                finalOrder.push(catName);
            }
        }


        finalOrder = CategoryManager.getSortedCategoryNames(categorySettings, finalOrder);

        var result = [];
        for (var n = 0; n < finalOrder.length; n++) {
            result.push({
                categoryName: finalOrder[n],
                items: groups[finalOrder[n]]
            });
        }

        if (otherItems.length > 0) {
            result.push({
                categoryName: i18nd("plasma_applet_com.mcc45tr.filesearch", "Other Results"),
                items: otherItems
            });
        }

        categorizedData = result;

        var flatList = [];
        for (var p = 0; p < result.length; p++) {
            var groupedCategoryName = result[p].categoryName;
            var catItems = result[p].items;
            for (var q = 0; q < catItems.length; q++) {
                var groupedItem = catItems[q];
                groupedItem.category = groupedCategoryName;
                flatList.push(groupedItem);
            }
        }

        flatSortedData = flatList;
        resultCount = flatList.length;
        refreshVersion++;
    }

    // Debounce timer for refreshGroups to prevent excessive updates
    Timer {
        id: refreshDebouncer
        interval: 150
        onTriggered: dataManager.refreshGroups()
    }

    Repeater {
        id: rawDataProxy
        model: dataManager.resultsModel
        visible: false
        delegate: Item {
            property int itemIndex: index
            // Role name fallback for different Milou/Plasma versions
            property var category: (model.category !== undefined ? model.category : (model.matchCategory !== undefined ? model.matchCategory : (model.categoryName !== undefined ? model.categoryName : "")))
            property var display: model.display || ""
            property var decoration: model.decoration || ""
            property var url: model.url || ""
            property var urls: model.urls || []
            property var subtext: model.subtext || ""
            property var duplicateId: model.duplicateId || ""
        }
        onCountChanged: {
            dataManager.resultCount = count
            refreshDebouncer.restart()
            
            // Latency Measurement
            if (dataManager.searchStartTime > 0) {
                var now = new Date().getTime()
                var latency = now - dataManager.searchStartTime
                if (latency > 0 && latency < 5000) {
                    dataManager.lastLatency = latency
                    dataManager.logic.updateTelemetry(latency)
                    dataManager.searchStartTime = 0
                }
            }
        }
    }
}
