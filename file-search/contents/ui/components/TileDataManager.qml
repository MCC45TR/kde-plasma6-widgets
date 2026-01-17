import QtQuick
import org.kde.milou as Milou

Item {
    id: dataManager
    
    required property var resultsModel
    required property var logic
    
    property var categorizedData: []
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
        
        for (var i = 0; i < rawDataProxy.count; i++) {
            var item = rawDataProxy.itemAt(i);
            if (!item) continue;
            var cat = item.category || "Diğer";
            
            if (!groups[cat]) {
                groups[cat] = [];
                displayOrder.push(cat);
            }
            
            groups[cat].push({
                display: item.display || "",
                decoration: item.decoration || "",
                category: cat,
                url: item.url || "", 
                urls: item.urls || [],
                subtext: item.subtext || "",
                duplicateId: item.duplicateId || "",
                index: item.itemIndex
            });
        }
        
        // Consolidate sparse categories
        var otherItems = [];
        var finalOrder = [];
        
        for (var k = 0; k < displayOrder.length; k++) {
            var catName = displayOrder[k];
            var items = groups[catName];
            var isAppCategory = (catName === "Uygulamalar" || catName === "Applications");
            
            if (items.length <= 1 && !isAppCategory) {
                for (var j = 0; j < items.length; j++) {
                    otherItems.push(items[j]);
                }
            } else {
                finalOrder.push(catName);
            }
        }
        
        var result = [];
        for (var m = 0; m < finalOrder.length; m++) {
            result.push({
                categoryName: finalOrder[m],
                items: groups[finalOrder[m]]
            });
        }
        
        if (otherItems.length > 0) {
            result.push({
                categoryName: "Diğer Sonuçlar",
                items: otherItems
            });
        }
        
        categorizedData = result;
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
