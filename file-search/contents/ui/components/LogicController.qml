import QtQuick
import org.kde.plasma.plasmoid
import "../js/HistoryManager.js" as HistoryManager
import "../js/PinnedManager.js" as PinnedManager
import "../js/CategoryManager.js" as CategoryManager
import "../js/TelemetryManager.js" as TelemetryManager
import "../js/utils.js" as Utils

Item {
    id: logicRoot
    
    // Required dependencies
    required property var plasmoidConfig
    required property var trFunc
    
    // Signals
    signal historyForceUpdate()
    
    // ===== HISTORY MANAGEMENT =====
    property var searchHistory: []
    readonly property int maxHistoryItems: 20
    
    // ===== PINNED ITEMS MANAGEMENT =====
    property var pinnedItems: []
    property string currentActivityId: "global"
    
    // ===== CATEGORY SETTINGS =====
    property var categorySettings: {}
    
    // ===== TELEMETRY =====
    property var telemetryStats: TelemetryManager.getStatsObject(plasmoidConfig.telemetryData || "{}")
    
    // ===== HISTORY FUNCTIONS =====
    function loadHistory() {
        console.log("FileSearch [History]: Loading history...")
        searchHistory = HistoryManager.loadHistory(plasmoidConfig.searchHistory)
    }
    
    function saveHistory() {
        plasmoidConfig.searchHistory = JSON.stringify(searchHistory)
    }
    
    function addToHistory(display, decoration, category, matchId, filePath, sourceType, queryText) {
        searchHistory = HistoryManager.addToHistory(searchHistory, display, decoration, category, matchId, filePath, sourceType, queryText, plasmoidConfig.maxHistoryItems)
        saveHistory()
        
        // Schedule delayed icon check (1s)
        if (searchHistory.length > 0) {
            iconCheckTimer.uuid = searchHistory[0].uuid
            iconCheckTimer.filePath = filePath
            iconCheckTimer.decoration = decoration
            iconCheckTimer.category = category
            iconCheckTimer.restart()
        }
    }
    
    function formatHistoryTime(timestamp) {
        return Utils.formatHistoryTime(timestamp, trFunc)
    }
    
    function clearHistory() {
        searchHistory = HistoryManager.clearHistory()
        saveHistory()
    }
    
    // ===== ICON CHECK TIMER =====
    Timer {
        id: iconCheckTimer
        interval: 1000
        repeat: false
        property string uuid
        property string filePath
        property string decoration
        property string category
        
        onTriggered: {
            if (!uuid) return
            
            /// Only check if it has a file path
            if (filePath && filePath.toString().indexOf("file://") === 0) {
                // If decoration is broken (QIcon()) or missing
                if (decoration === "QIcon()" || decoration === "") {
                    // Set default folder icon temporarily if it's likely a folder
                    var isFolder = (category === "Yerler" || category === "Places" || category === "Klasörler");
                    
                    if (isFolder) {
                        HistoryManager.updateItemIcon(searchHistory, uuid, "folder");
                        saveHistory();
                        historyForceUpdate();
                    }
                    
                    // Try to fetch custom icon from .directory file
                    fetchDirectoryIcon(filePath, uuid);
                }
            }
        }
    }

    function fetchDirectoryIcon(folderPath, uuid) {
         if (!folderPath || folderPath.toString().indexOf("file://") !== 0) return;
         
         var request = new XMLHttpRequest();
         // Add .directory to path. Ensure no double slash if path ends with /
         var path = folderPath.toString();
         if (path.slice(-1) === "/") path = path.slice(0, -1);
         var url = path + "/.directory";
         
         request.open("GET", url);
         request.onreadystatechange = function() {
             if (request.readyState === XMLHttpRequest.DONE) {
                 if (request.status === 200 || request.status === 0) {
                     var content = request.responseText;
                     // Look for Icon=...
                     var lines = content.split('\n');
                     for (var i = 0; i < lines.length; i++) {
                         var line = lines[i].trim();
                         if (line.indexOf("Icon=") === 0) {
                             var iconName = line.substring(5).trim();
                             if (iconName.length > 0) {
                                 console.log("FileSearch [Icon]: Found custom icon:", iconName);
                                 if (HistoryManager.updateItemIcon(logicRoot.searchHistory, uuid, iconName)) {
                                     logicRoot.saveHistory();
                                     logicRoot.historyForceUpdate();
                                 }
                                 return;
                             }
                         }
                     }
                 }
             }
         };
         request.send();
    }
    
    // ===== PINNED FUNCTIONS =====
    function loadPinned() {
        console.log("FileSearch [Pinned]: Loading pinned items...")
        pinnedItems = PinnedManager.loadPinned(plasmoidConfig.pinnedItems)
    }
    
    function savePinned() {
        plasmoidConfig.pinnedItems = PinnedManager.savePinned(pinnedItems)
    }
    
    function pinItem(item) {
        pinnedItems = PinnedManager.pinItem(pinnedItems, item, currentActivityId)
        savePinned()
    }
    
    function unpinItem(matchId) {
        pinnedItems = PinnedManager.unpinItem(pinnedItems, matchId, currentActivityId)
        savePinned()
    }
    
    function isPinned(matchId) {
        return PinnedManager.isPinned(pinnedItems, matchId, currentActivityId)
    }
    
    function togglePin(item) {
        pinnedItems = PinnedManager.togglePin(pinnedItems, item, currentActivityId)
        savePinned()
    }
    
    function getVisiblePinnedItems() {
        return PinnedManager.getPinnedForActivity(pinnedItems, currentActivityId)
    }
    
    // ===== CATEGORY SETTINGS FUNCTIONS =====
    function loadCategorySettings() {
        console.log("FileSearch [Category]: Loading category settings...")
        categorySettings = CategoryManager.loadCategorySettings(plasmoidConfig.categorySettings)
    }
    
    function processCategories(categories) {
        return CategoryManager.processCategories(categories, categorySettings)
    }
    
    function isCategoryVisible(categoryName) {
        return CategoryManager.isCategoryVisible(categorySettings, categoryName)
    }
    
    function getEffectiveIcon(categoryName, defaultIcon) {
        return CategoryManager.getEffectiveIcon(categorySettings, categoryName, defaultIcon)
    }
    
    function updateTelemetry(latency) {
        var newData = TelemetryManager.recordSearch(plasmoidConfig.telemetryData || "{}", latency)
        plasmoidConfig.telemetryData = newData
        telemetryStats = TelemetryManager.getStatsObject(newData)
    }

    // ===== INITIALIZATION =====
    Component.onCompleted: {
        loadHistory()
        loadPinned()
        loadCategorySettings()
    }
}
