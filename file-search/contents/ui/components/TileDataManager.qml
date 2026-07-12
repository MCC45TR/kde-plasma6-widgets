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
    property int searchAlgorithm: 0
    property int minResults: 3
    property bool smartResultLimit: true
    property string lastRefreshSignature: ""
    property var itemMetadataCache: ({})
    property var itemMetadataCacheKeys: []
    property int itemMetadataCacheHead: 0
    property int itemMetadataCacheSize: 0
    property int metadataCacheHits: 0
    property int metadataCacheMisses: 0
    property int queryCacheHitsStart: 0
    property int queryCacheMissesStart: 0
    // Large enough for the bounded RSS cache plus the normal Milou result set.
    readonly property int itemMetadataCacheLimit: 2048

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
        function onDiscoverAvailableChanged() {
            dataManager.settingsRevision++
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
    readonly property string _applicationsLabel: i18nd("plasma_applet_com.mcc45tr.filesearch", "Applications")

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
        // Publish cached/local results immediately; subsequent model events are coalesced.
        refreshGroups();
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
        itemMetadataCacheKeys = [];
        itemMetadataCacheHead = 0;
        itemMetadataCacheSize = 0;
        metadataCacheHits = 0;
        metadataCacheMisses = 0;
        queryCacheHitsStart = 0;
        queryCacheMissesStart = 0;
    }

    function trimMetadataCache() {
        while (itemMetadataCacheSize > itemMetadataCacheLimit && itemMetadataCacheHead < itemMetadataCacheKeys.length) {
            var oldestKey = itemMetadataCacheKeys[itemMetadataCacheHead++];
            if (itemMetadataCache[oldestKey] !== undefined) {
                delete itemMetadataCache[oldestKey];
                itemMetadataCacheSize--;
            }
        }
        // Periodically compact the tombstoned prefix; eviction itself remains
        // O(1) and compaction is amortized across hundreds of insertions.
        if (itemMetadataCacheHead > 512 && itemMetadataCacheHead * 2 > itemMetadataCacheKeys.length) {
            itemMetadataCacheKeys = itemMetadataCacheKeys.slice(itemMetadataCacheHead);
            itemMetadataCacheHead = 0;
        }
    }

    function metadataForItem(item, includeIndexedContent) {
        var category = (item.category || "Other").toString();
        var display = (item.display || item.name || "").toString();
        var url = (item.url || "").toString();
        var decoration = (item.decoration || "").toString();
        var subtext = (item.subtext || "").toString();
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
                && cached.sourceSubtext === subtext
                && cached.indexedLength === indexedLength
                && cached.indexedHead === indexedHead
                && cached.indexedTail === indexedTail) {
            metadataCacheHits++;
            if (includeIndexedContent && !cached.indexedNormalized) {
                cached.lowerIndexedContent = indexedContent.toLocaleLowerCase().replace(/\u0307/g, "");
                cached.indexedNormalized = true;
            }
            return cached;
        }

        metadataCacheMisses++;
        var metadata = {
            sourceDisplay: display,
            sourceCategory: category,
            sourceUrl: url,
            sourceDecoration: decoration,
            sourceSubtext: subtext,
            indexedLength: indexedLength,
            indexedHead: indexedHead,
            indexedTail: indexedTail,
            lowerDisplay: display.toLocaleLowerCase().replace(/\u0307/g, ""),
            lowerCategory: category.toLocaleLowerCase().replace(/\u0307/g, ""),
            lowerUrl: url.toLowerCase(),
            lowerDecoration: decoration.toLowerCase(),
            lowerSubtext: subtext.toLocaleLowerCase().replace(/\u0307/g, ""),
            lowerIndexedContent: includeIndexedContent && indexedContent ? indexedContent.toLocaleLowerCase().replace(/\u0307/g, "") : "",
            indexedNormalized: !!includeIndexedContent || !indexedContent,
            extension: PreviewUtils.getExtension(url),
            categoryVisible: CategoryManager.isCategoryVisible(logic.categorySettings || {}, category),
            categoryPriority: CategoryManager.getCategoryPriority(logic.categorySettings || {}, category),
            mappedDecoration: IconMapper.getIconForUrl(url, decoration, category)
        };
        if (!cached) {
            itemMetadataCacheSize++;
            itemMetadataCacheKeys.push(key);
        }
        itemMetadataCache[key] = metadata;
        trimMetadataCache();
        return metadata;
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
            searchAlgorithm,
            minResults,
            smartResultLimit,
            logic.discoverAvailable,
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
        var lowerSearch = Utils.normalized(searchText);
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
                    if (!Utils.matchesResultFilter(activeFilterLower, cat, urlString, item.duplicateId || "", item.decoration || "", metadata.extension))
                        continue;
                }

                if (isFileOnlyMode) {
                    var isFileUrl = urlString.indexOf("file://") === 0;
                    if (!isFileUrl && !Utils.isFileLikeResult(cat, urlString, item.duplicateId || "", item.decoration || "", metadata.extension))
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
                    _normalizedUrl: metadata.lowerUrl,
                    _normalizedSubtext: metadata.lowerSubtext,
                    _normalizedCategory: metadata.lowerCategory,
                    _normalizedIndexedContent: metadata.lowerIndexedContent,
                    _categoryPriority: metadata.categoryPriority,
                    _isPinned: logic.isPinned(item.duplicateId || item.display || "")
                });
            }
        }

        var activeF = dataManager.activeFilter;
        // RSS logic: Include if in RSS mode OR if RSS is enabled and a relevant filter is active
        if (isRSSOnlyMode || (logic.rssEnabled && (activeF === "All" || activeF === "Web" || activeF === "RSS"))) {
            for (var r = 0; r < rssItems.length; r++) {
                var rssEntry = rssItems[r];
                var rssMetadata = metadataForItem(rssEntry, isRSSOnlyMode || lowerSearch.length > 0);
                if (isRSSOnlyMode && rssQuery.length > 0) {
                    var title = rssMetadata.lowerDisplay;
                    var content = rssMetadata.lowerIndexedContent;
                    if (title.indexOf(rssQuery) === -1 && content.indexOf(rssQuery) === -1)
                        continue;
                }
                if (!isRSSOnlyMode && lowerSearch.length > 0) {
                    var normalTitle = rssMetadata.lowerDisplay;
                    var normalContent = rssMetadata.lowerIndexedContent;
                    if (normalTitle.indexOf(lowerSearch) === -1 && normalContent.indexOf(lowerSearch) === -1)
                        continue;
                }

                if (rssMetadata.categoryVisible) {
                    // RSS entries are private cache objects; normalize them once in place so
                    // a 1500-item feed does not allocate a second full object graph per query.
                    rssEntry._normalizedDisplay = rssMetadata.lowerDisplay;
                    rssEntry._normalizedIndexedContent = rssMetadata.lowerIndexedContent;
                    rssEntry._categoryPriority = rssMetadata.categoryPriority;
                    rawItems.push(rssEntry);
                }
            }
        }

        // Final fallback for empty RSS query results
        if (isRSSOnlyMode && rssQuery.length === 0 && rawItems.length === 0) {
            for (var fallbackIndex = 0; fallbackIndex < rssItems.length; fallbackIndex++) {
                var fallbackItem = rssItems[fallbackIndex];
                if (metadataForItem(fallbackItem, false).categoryVisible)
                    rawItems.push(fallbackItem);
            }
        }

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
                    true,
                    {
                        searchAlgorithm: searchAlgorithm,
                        minResults: minResults,
                        smartResultLimit: smartResultLimit
                    }
                );
            }
        } else if (searchText && searchText.length > 0) {
            rawItems = SimilarityUtils.sortByPriorityAndSimilarity(
                rawItems,
                searchText,
                categorySettings,
                CategoryManager.getCategoryPriority,
                effectiveMaxResults,
                false,
                {
                    searchAlgorithm: searchAlgorithm,
                    minResults: minResults,
                    smartResultLimit: smartResultLimit
                }
            );
        } else {
            rawItems = CategoryManager.applyPriorityToResults(rawItems, categorySettings);
        }
        var sortCompletedAt = Date.now();

        if (effectiveMaxResults > 0 && rawItems.length > effectiveMaxResults)
            rawItems = rawItems.slice(0, effectiveMaxResults);

        var discoverQuery = searchText.trim();
        var discoverFilterAllowed = activeFilterLower === "all" || activeFilterLower === "apps";
        var discoverQueryAllowed = discoverQuery.length >= 2
                && discoverQuery.length <= 80
                && discoverQuery.indexOf(":") === -1
                && !isFileOnlyMode
                && !isRSSOnlyMode;
        if (logic.discoverAvailable && discoverFilterAllowed && discoverQueryAllowed
                && !hasStrongApplicationMatch(rawItems, discoverQuery)) {
            var discoverResult = {
                display: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search in Discover: %1", discoverQuery),
                decoration: "plasmadiscover",
                category: _applicationsLabel,
                url: "",
                urls: [],
                subtext: i18nd("plasma_applet_com.mcc45tr.filesearch", "Download Software"),
                duplicateId: "discover:" + Utils.normalized(discoverQuery),
                index: -2,
                _fixedRelevance: 0.08,
                _categoryPriority: 10000
            };
            if (effectiveMaxResults > 0 && rawItems.length >= effectiveMaxResults)
                rawItems = rawItems.slice(0, Math.max(0, effectiveMaxResults - 1));
            rawItems.push(discoverResult);
        }

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
            var isRSSCategory = Utils.getCategoryKind(catName) === "rss";

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
            previewQueueLength: (logic.snippetQueue ? logic.snippetQueue.length : 0)
                    + (logic.thumbnailQueue ? logic.thumbnailQueue.length : 0),
            previewActiveRequests: (logic.snippetActiveRequests || 0) + (logic.thumbnailActiveRequests || 0),
            thumbnailQueueLength: logic.thumbnailQueue ? logic.thumbnailQueue.length : 0,
            thumbnailActiveRequests: logic.thumbnailActiveRequests || 0,
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

    function hasStrongApplicationMatch(items, query) {
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            if (item.index === -2)
                continue;
            if (!Utils.isAppCategory(item.category || "", item.url || "", item.duplicateId || "", item.decoration || ""))
                continue;
            if (SimilarityUtils.advancedResultScore(query, item) >= 0.88)
                return true;
        }
        return false;
    }

    // Debounce timer for refreshGroups to prevent excessive updates
    Timer {
        id: refreshDebouncer
        interval: 24
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
