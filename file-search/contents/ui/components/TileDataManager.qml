import QtQuick
import org.kde.milou as Milou
import "../js/CategoryManager.js" as CategoryManager
import "../js/SimilarityUtils.js" as SimilarityUtils
import "../js/IconMapper.js" as IconMapper

Item {
    id: dataManager
    
    required property var resultsModel
    required property var logic
    
    // Search text for similarity scoring
    property string searchText: ""
    
    property var categorizedData: []
    property var flatSortedData: []
    property int resultCount: 0
    property int lastLatency: 0
    
    // Internal state
    property real searchStartTime: 0
    
    function startSearch() {
        searchStartTime = new Date().getTime()
    }
    
    function refreshGroups() {
        var groups = {};
        var displayOrder = [];
        var categorySettings = logic.categorySettings || {};
        
        // Step 1: Collect raw items and filter hidden categories
        var rawItems = [];
        var isFileOnlyMode = searchText.toLowerCase().startsWith("file:/");
        
        for (var i = 0; i < rawDataProxy.count; i++) {
            var item = rawDataProxy.itemAt(i);
            if (!item) continue;
            var cat = item.category || "Diğer";
            
            // Filter hidden categories
            if (!CategoryManager.isCategoryVisible(categorySettings, cat)) {
                continue;
            }
            
            // FILE ONLY MODE FILTER
            if (isFileOnlyMode) {
                 // Check if category implies file/folder (Folders, Documents, Audio, Video, Files, Yerler, Klasörler, Dosyalar... etc)
                 // Or we can check if it is NOT "Applications", "System Settings"...
                 // A simple inclusive check:
                 var allowedCats = ["Files", "Dosyalar", "Folders", "Klasörler", "Documents", "Belgeler", 
                                    "Images", "Resimler", "Audio", "Ses", "Video", "Videolar", "Places", "Yerler"];
                 
                 // Also handle "Diğer" / "Other" if it points to path?
                 // Milou might return file paths as "Diğer" sometimes?
                 // Safer to check item.url?
                 var isFileUrl = item.url && item.url.toString().startsWith("file://");
                 
                 // If item IS NOT a file url AND category IS NOT in allowed list, skip it.
                 var isAllowed = isFileUrl || allowedCats.indexOf(cat) !== -1;
                 
                 if (!isAllowed) continue;
            }
            
            rawItems.push({
                display: item.display || "",
                decoration: IconMapper.getIconForUrl(item.url || "", item.decoration || "", cat),
                category: cat,
                url: item.url || "", 
                urls: item.urls || [],
                subtext: item.subtext || "",
                duplicateId: item.duplicateId || "",
                index: item.itemIndex
            });
        }
        
        // Step 2: Sort by priority and similarity
        if (searchText && searchText.length > 0) {
            rawItems = SimilarityUtils.sortByPriorityAndSimilarity(
                rawItems,
                searchText,
                categorySettings,
                CategoryManager.getCategoryPriority
            );
        } else {
            // Sort by priority only
            rawItems = CategoryManager.applyPriorityToResults(rawItems, categorySettings);
        }
        
        // Step 3: Group by category (maintaining sorted order)
        for (var j = 0; j < rawItems.length; j++) {
            var sortedItem = rawItems[j];
            var sortedCat = sortedItem.category;
            
            if (!groups[sortedCat]) {
                groups[sortedCat] = [];
                displayOrder.push(sortedCat);
            }
            
            groups[sortedCat].push(sortedItem);
        }
        
        // Step 4: Consolidate sparse categories
        var otherItems = [];
        var finalOrder = [];
        
        for (var k = 0; k < displayOrder.length; k++) {
            var catName = displayOrder[k];
            var items = groups[catName];
            var isAppCategory = (catName === "Uygulamalar" || catName === "Applications");
            
            if (items.length <= 1 && !isAppCategory) {
                for (var m = 0; m < items.length; m++) {
                    otherItems.push(items[m]);
                }
            } else {
                finalOrder.push(catName);
            }
        }
        
        // Step 5: Sort final categories by priority
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
                categoryName: "Diğer Sonuçlar",
                items: otherItems
            });
        }
        
        categorizedData = result;
        
        // Step 6: Create flat sorted list matchin the categorized structure
        var flatList = [];
        for (var i = 0; i < result.length; i++) {
            var catName = result[i].categoryName;
            var catItems = result[i].items;
            for (var j = 0; j < catItems.length; j++) {
                var item = catItems[j];
                // Ensure item has the final category name for section grouping
                item.category = catName;
                flatList.push(item);
            }
        }
        flatSortedData = flatList;
    }

    // Debounce timer for refreshGroups to prevent excessive updates
    Timer {
        id: refreshDebouncer
        interval: 50
        onTriggered: dataManager.refreshGroups()
    }

    Repeater {
        id: rawDataProxy
        model: dataManager.resultsModel
        visible: false
        delegate: Item {
            property int itemIndex: index
            property var category: model.category || ""
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

