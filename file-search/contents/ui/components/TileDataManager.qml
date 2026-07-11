import QtQuick
import org.kde.milou as Milou
import "../js/CategoryManager.js" as CategoryManager
import "../js/PreviewUtils.js" as PreviewUtils
import "../js/SimilarityUtils.js" as SimilarityUtils
import "../js/IconMapper.js" as IconMapper
import "../js/utils.js" as Utils

Item {
    id: dataManager
    
    required property var resultsModel
    required property var logic
    
    // Search text for similarity scoring
    property string searchText: ""
    property string activeFilter: "All"
    property int maxResults: 20
    property string lastRefreshSignature: ""
    property var itemMetadataCache: ({})
    property int itemMetadataCacheSize: 0
    property int metadataUseCounter: 0
    property int metadataCacheHits: 0
    property int metadataCacheMisses: 0
    property int queryCacheHitsStart: 0
    property int queryCacheMissesStart: 0
    readonly property int itemMetadataCacheLimit: 768
    readonly property int itemMetadataCacheSlack: 64
    
    Connections {
        target: logic
        function onRssCacheChanged() {
            dataManager.rssRevision++
            refreshDebouncer.restart()
        }
        function onCategorySettingsChanged() {
            dataManager.settingsRevision++
            dataManager.clearMetadataCache()
            refreshDebouncer.restart()
        }
    }

    Connections {
        target: resultsModel
        function onRowsInserted() { dataManager.noteModelEvent() }
        function onRowsRemoved() { dataManager.noteModelEvent() }
        function onModelReset() { dataManager.noteModelEvent() }
        function onDataChanged() { dataManager.noteModelEvent() }
    }
    
    property var categorizedData: []
    property var flatSortedData: []
    property int resultCount: 0
    property int lastLatency: 0
    property int refreshVersion: 0
    property int activeQueryGeneration: 0
    property int lastRecordedQueryGeneration: -1
    property int modelRevision: 0
    property int rssRevision: 0
    property int settingsRevision: 0
    property real queryIssuedAt: 0
    property real firstModelEventAt: 0
    property real lastModelEventAt: 0
    property var lastPerformanceTrace: ({})
    
    // Internal state
    property real searchStartTime: 0
    readonly property var fileOnlyCategories: ["Files", "Dosyalar", "Folders", "Klasörler", "Documents", "Belgeler", "Images", "Resimler", "Audio", "Ses", "Video", "Videolar", "Places", "Yerler"]
    // Cached i18n string to avoid calling i18nd() on every refresh cycle
    readonly property string _otherResultsLabel: i18nd("plasma_applet_com.mcc45tr.filesearch", "Other Results")
    
    function beginSearch(generation, startedAt) {
        activeQueryGeneration = generation;
        searchStartTime = startedAt || Date.now();
        queryIssuedAt = 0;
        firstModelEventAt = 0;
        lastModelEventAt = 0;
        queryCacheHitsStart = metadataCacheHits;
        queryCacheMissesStart = metadataCacheMisses;
    }

    function markQueryIssued(generation) {
        if (generation !== activeQueryGeneration)
            return;
        queryIssuedAt = Date.now();
        refreshDebouncer.restart();
    }

    function noteModelEvent() {
        var now = Date.now();
        modelRevision++;
        if (firstModelEventAt === 0)
            firstModelEventAt = now;
        lastModelEventAt = now;
        refreshDebouncer.restart();
    }

    function clearMetadataCache() {
        itemMetadataCache = ({});
        itemMetadataCacheSize = 0;
        metadataUseCounter = 0;
        metadataCacheHits = 0;
        metadataCacheMisses = 0;
        queryCacheHitsStart = 0;
        queryCacheMissesStart = 0;
    }

    function trimMetadataCache() {
        if (itemMetadataCacheSize <= itemMetadataCacheLimit + itemMetadataCacheSlack)
            return;

        var entries = [];
        for (var key in itemMetadataCache)
            entries.push({ key: key, lastUsed: itemMetadataCache[key].lastUsed });
        entries.sort(function(a, b) { return a.lastUsed - b.lastUsed; });

        var removeCount = itemMetadataCacheSize - itemMetadataCacheLimit;
        for (var i = 0; i < removeCount; i++)
            delete itemMetadataCache[entries[i].key];
        itemMetadataCacheSize -= removeCount;
    }

    function metadataForItem(item, includeIndexedContent) {
        var category = (item.category || "Other").toString();
        var display = (item.display || item.name || "").toString();
        var url = (item.url || "").toString();
        var decoration = (item.decoration || "").toString();
        var duplicateId = (item.duplicateId || "").toString();
        var indexedContent = (item.indexedContent || "").toString();
        var key = duplicateId || url || (category + "\u001f" + display);
        var indexedLength = indexedContent.length;
        var indexedHead = indexedLength > 0 ? indexedContent.substring(0, 64) : "";
        var indexedTail = indexedLength > 64 ? indexedContent.substring(indexedLength - 64) : indexedHead;
        var cached = itemMetadataCache[key];
        if (cached
                && cached.sourceDisplay === display
                && cached.sourceCategory === category
                && cached.sourceUrl === url
                && cached.sourceDecoration === decoration
                && cached.indexedLength === indexedLength
                && cached.indexedHead === indexedHead
                && cached.indexedTail === indexedTail) {
            metadataCacheHits++;
            if (includeIndexedContent && !cached.indexedNormalized) {
                cached.lowerIndexedContent = indexedContent.toLocaleLowerCase().replace(/\u0307/g, "");
                cached.indexedNormalized = true;
            }
            cached.lastUsed = ++metadataUseCounter;
            return cached;
        }

        metadataCacheMisses++;
        var metadata = {
            sourceDisplay: display,
            sourceCategory: category,
            sourceUrl: url,
            sourceDecoration: decoration,
            indexedLength: indexedLength,
            indexedHead: indexedHead,
            indexedTail: indexedTail,
            lowerDisplay: display.toLocaleLowerCase().replace(/\u0307/g, ""),
            lowerCategory: category.toLocaleLowerCase().replace(/\u0307/g, ""),
            lowerUrl: url.toLowerCase(),
            lowerDecoration: decoration.toLowerCase(),
            lowerIndexedContent: includeIndexedContent && indexedContent ? indexedContent.toLocaleLowerCase().replace(/\u0307/g, "") : "",
            indexedNormalized: !!includeIndexedContent || !indexedContent,
            extension: PreviewUtils.getExtension(url),
            categoryVisible: CategoryManager.isCategoryVisible(logic.categorySettings || {}, category),
            categoryPriority: CategoryManager.getCategoryPriority(logic.categorySettings || {}, category),
            mappedDecoration: IconMapper.getIconForUrl(url, decoration, category),
            lastUsed: ++metadataUseCounter
        };
        if (!cached)
            itemMetadataCacheSize++;
        itemMetadataCache[key] = metadata;
        trimMetadataCache();
        return metadata;
    }

    function copyWithMetadata(item, metadata) {
        var copy = Object.assign({}, item);
        copy._normalizedDisplay = metadata.lowerDisplay;
        copy._normalizedIndexedContent = metadata.lowerIndexedContent;
        copy._categoryPriority = metadata.categoryPriority;
        return copy;
    }
    
    function refreshGroups() {
        var refreshStartedAt = Date.now();
        var generation = activeQueryGeneration;
        var rssItems = (logic.rssCache && Array.isArray(logic.rssCache)) ? logic.rssCache : [];
        var firstItem = rawDataProxy.count > 0 ? rawDataProxy.objectAt(0) : null;
        var lastItem = rawDataProxy.count > 0 ? rawDataProxy.objectAt(rawDataProxy.count - 1) : null;
        var signature = [
            searchText,
            activeFilter,
            maxResults,
            modelRevision,
            rssRevision,
            settingsRevision,
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
                var item = rawDataProxy.objectAt(i);
                if (!item)
                    continue;

                var cat = item.category || "Other";
                var metadata = metadataForItem(item, false);
                if (!metadata.categoryVisible)
                    continue;

                var urlString = (item.url || "").toString();

                if (dataManager.activeFilter !== "All") {
                    var lowerCategory = metadata.lowerCategory;
                    var lowerDecoration = metadata.lowerDecoration;
                    var lowerUrl = metadata.lowerUrl;
                    var ext = metadata.extension;
                    var shouldKeep = false;

                    if (activeFilterLower === "docs") {
                        shouldKeep = (lowerCategory.indexOf("belge") !== -1 || lowerCategory.indexOf("document") !== -1 || lowerCategory.indexOf("text") !== -1 ||
                                     lowerDecoration.indexOf("document") !== -1 || lowerDecoration.indexOf("text") !== -1 || PreviewUtils.isDocumentLikeExtension(ext));
                    } else if (activeFilterLower === "images") {
                        shouldKeep = (lowerCategory.indexOf("resim") !== -1 || lowerCategory.indexOf("image") !== -1 || lowerCategory.indexOf("picture") !== -1 ||
                                     lowerCategory.indexOf("photo") !== -1 || lowerCategory.indexOf("görsel") !== -1 || lowerCategory.indexOf("görüntü") !== -1 ||
                                     lowerDecoration.indexOf("image") !== -1 || lowerDecoration.indexOf("photo") !== -1 || lowerDecoration.indexOf("picture") !== -1 ||
                                     PreviewUtils.isImageExtension(ext));
                    } else if (activeFilterLower === "folders") {
                        shouldKeep = (lowerCategory.indexOf("klasör") !== -1 || lowerCategory.indexOf("folder") !== -1 || lowerCategory.indexOf("yerler") !== -1 ||
                                     lowerCategory.indexOf("place") !== -1 || lowerDecoration.indexOf("folder") !== -1 || lowerUrl.endsWith("/"));
                    } else if (activeFilterLower === "apps") {
                        shouldKeep = (lowerCategory.indexOf("app") !== -1 || lowerCategory.indexOf("uygulama") !== -1 || lowerCategory.indexOf("program") !== -1 ||
                                      lowerCategory.indexOf("ayar") !== -1 || lowerCategory.indexOf("setting") !== -1 ||
                                      lowerCategory.indexOf("oyun") !== -1 || lowerCategory.indexOf("game") !== -1 ||
                                      lowerCategory.indexOf("ofis") !== -1 || lowerCategory.indexOf("office") !== -1 ||
                                      lowerCategory.indexOf("sistem") !== -1 || lowerCategory.indexOf("system") !== -1 ||
                                      lowerCategory.indexOf("araç") !== -1 || lowerCategory.indexOf("util") !== -1 ||
                                      lowerCategory.indexOf("internet") !== -1 || lowerCategory.indexOf("grafik") !== -1 || lowerCategory.indexOf("graphic") !== -1 ||
                                      lowerCategory.indexOf("geliştirme") !== -1 || lowerCategory.indexOf("develop") !== -1 ||
                                      lowerCategory.indexOf("ortam") !== -1 || lowerCategory.indexOf("multimedia") !== -1 ||
                                      lowerCategory.indexOf("eğitim") !== -1 || lowerCategory.indexOf("educat") !== -1 ||
                                      lowerUrl.endsWith(".desktop") || (item.duplicateId && item.duplicateId.toString().indexOf(".desktop") !== -1));
                    } else if (activeFilterLower === "web") {
                        shouldKeep = (lowerCategory.indexOf("web") !== -1 || lowerCategory.indexOf("bookmark") !== -1 || lowerCategory.indexOf("yer imi") !== -1 ||
                                     lowerCategory.indexOf("internet") !== -1 || lowerCategory.indexOf("browser") !== -1 || lowerDecoration.indexOf("globe") !== -1 ||
                                     lowerDecoration.indexOf("web") !== -1 || lowerUrl.startsWith("http") || lowerUrl.startsWith("www"));
                    } else if (activeFilterLower === "rss") {
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
                    decoration: metadata.mappedDecoration,
                    category: cat,
                    url: urlString,
                    urls: item.urls || [],
                    subtext: item.subtext || "",
                    duplicateId: item.duplicateId || "",
                    index: item.itemIndex,
                    _normalizedDisplay: metadata.lowerDisplay,
                    _normalizedIndexedContent: metadata.lowerIndexedContent,
                    _categoryPriority: metadata.categoryPriority
                });
            }
        }

        var activeF = dataManager.activeFilter;
        // RSS logic: Include if in RSS mode OR if RSS is enabled and a relevant filter is active
        if (isRSSOnlyMode || (logic.rssEnabled && (activeF === "All" || activeF === "Web" || activeF === "RSS"))) {
            for (var r = 0; r < rssItems.length; r++) {
                var rssEntry = rssItems[r];
                var rssMetadata = metadataForItem(rssEntry, isRSSOnlyMode);
                if (isRSSOnlyMode && rssQuery.length > 0) {
                    var title = rssMetadata.lowerDisplay;
                    var content = rssMetadata.lowerIndexedContent;
                    if (title.indexOf(rssQuery) === -1 && content.indexOf(rssQuery) === -1)
                        continue;
                }

                if (rssMetadata.categoryVisible)
                    rawItems.push(copyWithMetadata(rssEntry, rssMetadata));
            }
        }

        // Final fallback for empty RSS query results
        if (isRSSOnlyMode && rssQuery.length === 0 && rawItems.length === 0)
            rawItems = rssItems.slice();

        var scanCompletedAt = Date.now();

        var effectiveMaxResults = isRSSOnlyMode ? 400 : maxResults;
        if (isRSSOnlyMode) {
            if (rssQuery && rssQuery.length > 3) {
                rawItems = SimilarityUtils.sortByPriorityAndSimilarity(
                    rawItems,
                    rssQuery,
                    categorySettings,
                    CategoryManager.getCategoryPriority,
                    effectiveMaxResults,
                    true
                );
            }
        } else if (searchText && searchText.length > 0) {
            rawItems = SimilarityUtils.sortByPriorityAndSimilarity(
                rawItems,
                searchText,
                categorySettings,
                CategoryManager.getCategoryPriority,
                effectiveMaxResults,
                false
            );
        } else {
            rawItems = CategoryManager.applyPriorityToResults(rawItems, categorySettings);
        }
        var sortCompletedAt = Date.now();

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
            var isAppCategory = Utils.isAppCategory(catName);
            var isRSSCategory = (catName === "RSS" || catName.toLowerCase().indexOf("haber") !== -1 || catName.toLowerCase().indexOf("news") !== -1);

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
                categoryName: _otherResultsLabel,
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
                groupedItem.sectionCategory = groupedCategoryName;
                flatList.push(groupedItem);
            }
        }

        flatSortedData = flatList;
        resultCount = flatList.length;
        refreshVersion++;

        var refreshCompletedAt = Date.now();
        lastPerformanceTrace = {
            generation: generation,
            resultCount: flatList.length,
            modelCount: rawDataProxy.count,
            rssCount: rssItems.length,
            metadataCacheHits: metadataCacheHits - queryCacheHitsStart,
            metadataCacheMisses: metadataCacheMisses - queryCacheMissesStart,
            metadataCacheSize: itemMetadataCacheSize,
            rssCacheRebuildCount: logic.rssCacheRebuildCount || 0,
            previewQueueLength: logic.snippetQueue ? logic.snippetQueue.length : 0,
            previewActiveRequests: logic.snippetActiveRequests || 0,
            inputToIssueMs: queryIssuedAt > 0 && searchStartTime > 0 ? queryIssuedAt - searchStartTime : -1,
            backendToFirstRowMs: firstModelEventAt > 0 && queryIssuedAt > 0 ? firstModelEventAt - queryIssuedAt : -1,
            modelSettleMs: lastModelEventAt > 0 && firstModelEventAt > 0 ? lastModelEventAt - firstModelEventAt : -1,
            scanMs: scanCompletedAt - refreshStartedAt,
            sortMs: sortCompletedAt - scanCompletedAt,
            groupAndPublishMs: refreshCompletedAt - sortCompletedAt,
            refreshMs: refreshCompletedAt - refreshStartedAt,
            endToEndMs: searchStartTime > 0 ? refreshCompletedAt - searchStartTime : -1
        };
        if (logic.debugEnabled)
            console.info("FileSearch performance:", JSON.stringify(lastPerformanceTrace));

        var completedGeneration = generation;
        var startedAt = searchStartTime;
        Qt.callLater(function() {
            if (completedGeneration !== activeQueryGeneration
                    || completedGeneration === lastRecordedQueryGeneration
                    || startedAt <= 0)
                return;
            lastRecordedQueryGeneration = completedGeneration;
            lastLatency = Date.now() - startedAt;
            logic.updateTelemetry(lastLatency);
            searchStartTime = 0;
        });
    }

    // Debounce timer for refreshGroups to prevent excessive updates
    Timer {
        id: refreshDebouncer
        interval: 60
        onTriggered: dataManager.refreshGroups()
    }

    Instantiator {
        id: rawDataProxy
        model: dataManager.resultsModel
        delegate: QtObject {
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
        onCountChanged: dataManager.noteModelEvent()
    }
}
