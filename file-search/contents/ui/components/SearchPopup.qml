import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou
import "../js/HistoryManager.js" as HistoryManager
import org.kde.plasma.plasmoid

Item {
    id: popupRoot
    
    // Dependencies
    required property var logic    
    property var plasmoidConfig // injected from main
    
    // Properties synced with main
    property string searchText: ""
    property bool expanded: false
    property bool isInPanel: true // Default to true, overridden by Main
    
    onExpandedChanged: {
        if (expanded) {
            // Force focus when popup opens
            if (isButtonMode) {
                searchBar.focusInput()
            } else {
                hiddenSearchInput.forceActiveFocus()
            }
        } else {
            // Clear search text when popup closes
            requestSearchTextUpdate("")
            searchBar.clear()
            hiddenSearchInput.text = ""
            activeFilter = "All"
            pendingHistoryRun = false
            pendingHistoryMatchId = ""
            pendingHistoryDisplay = ""
        }
    }
    
    // Configuration
    property int displayMode: 0
    property int viewMode: 0
    property int iconSize: 32
    property int listIconSize: 22
    
    property color textColor
    property color accentColor
    property color bgColor
    
    property bool showDebug: false
    property bool showBootOptions: false
    property bool previewEnabled: true
    property var previewSettings: ({"images": true, "videos": false, "text": false, "documents": false})
    
    // Prefix Settings
    property bool prefixDateShowClock: true
    property bool prefixDateShowEvents: true
    property bool prefixPowerShowHibernate: false
    property bool prefixPowerShowSleep: true
    property bool showPinnedBar: true
    property bool autoMinimizePinned: false
    
    // Tile size mode: 0=Normal, 1=All Compact, 2=Only Pinned Compact, 3=Only History Compact
    property int compactTileMode: 0
    
    // Computed compact properties based on mode
    readonly property bool compactPinnedItems: compactTileMode === 1 || compactTileMode === 2
    readonly property bool compactHistoryItems: compactTileMode === 1 || compactTileMode === 3

    
    // Signals to Main
    signal requestSearchTextUpdate(string text)
    signal requestExpandChange(bool expanded)
    signal requestViewModeChange(int mode)
    signal requestPreventClosing(bool prevent)
    
    // Prevent closing logic for popup
    property bool preventClosing: false
    // Plasmoid.hideOnWindowDeactivate assignment removed due to "non-existent property" error
    
    // Read-only helpers
    readonly property bool isButtonMode: displayMode === 0
    readonly property bool isRssOnlyQuery: searchText.toLowerCase().startsWith("rss:")
    readonly property bool isTileView: {
        if (searchText.toLowerCase().startsWith("rss:")) return false;
        return plasmoidConfig ? (plasmoidConfig.viewMode === 1) : true
    }
    
    // Active filter from chips
    property string activeFilter: "All"
    
    // Layout
    Layout.preferredWidth: 500
    Layout.preferredHeight: 380
    Layout.minimumWidth: 400
    Layout.minimumHeight: 250
    
    // internal state
    property int focusSection: 0
    property string activeBackend: "Milou"
    property bool isLoadingResults: false
    property bool pendingHistoryRun: false
    property string pendingHistoryMatchId: ""
    property string pendingHistoryDisplay: ""
    
    // Context Menu for Results
    HistoryContextMenu {
        id: resultsContextMenu
        logic: popupRoot.logic
    }
    
    // ===== DATA MANAGER =====
    TileDataManager {
        id: tileData
        resultsModel: resultsModel
        logic: popupRoot.logic
        searchText: popupRoot.searchText
        activeFilter: popupRoot.activeFilter
        maxResults: popupRoot.activeFilter === "All" 
            ? (popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.maxResults || 20) : 20)
            : 450
        
        onCategorizedDataChanged: {
             // propagated automatically to bindings
        }
    }
    
    // ===== SEARCH MODEL =====
    Milou.ResultsModel {
        id: resultsModel
        // Use debounced query string to prevent stutter during rapid typing
        queryString: popupRoot.delayedQueryString
        limit: popupRoot.activeFilter === "All"
            ? (popupRoot.plasmoidConfig ? Math.max(10, popupRoot.plasmoidConfig.maxResults || 20) : 20)
            : 450
    }
    
    // Debounce the query string update to Milou
    property string delayedQueryString: ""
    Timer {
        id: queryDebouncer
        interval: 90
        repeat: false
        onTriggered: {
            popupRoot.delayedQueryString = getBackendQuery(popupRoot.searchText, popupRoot.activeFilter)
        }
    }

    Timer {
        id: loadingFallbackTimer
        interval: 900
        repeat: false
        onTriggered: popupRoot.isLoadingResults = false
    }
    
    onSearchTextChanged: {
        popupRoot.isLoadingResults = searchText.length > 0
        if (searchText.length > 0) loadingFallbackTimer.restart()
        else loadingFallbackTimer.stop()
        queryDebouncer.restart()
        // If query is cleared, update immediately for responsive feel
        if (searchText.length === 0) {
            queryDebouncer.stop()
            delayedQueryString = ""
            popupRoot.isLoadingResults = false
        }
        
        // Auto-minimize pinned items logic
        if (autoMinimizePinned && pinnedLoader.item) {
            if (searchText.length > 0) {
                pinnedLoader.item.isExpanded = false
            } else {
                pinnedLoader.item.isExpanded = true
            }
        }
    }
    
    onActiveFilterChanged: {
        popupRoot.isLoadingResults = searchText.length > 0
        if (searchText.length > 0) loadingFallbackTimer.restart()
        queryDebouncer.restart()
    }

    Connections {
        target: tileData
        function onRefreshVersionChanged() {
            popupRoot.isLoadingResults = false
            loadingFallbackTimer.stop()
            popupRoot.tryRunPendingHistory()
        }
    }
    
    // ===== FUNCTIONS =====
    
    function getFilteredQuery(text, filter) {
        // Backend prefixes (like "services:" or "baloo:") are unreliable across different Plasma versions and locales.
        // We rely entirely on TileDataManager to filter the results locally based on activeFilter.
        // This ensures consistent results because Milou fetches up to 450 items when a filter is active.
        return text || "";
    }

    function getBackendQuery(text, filter) {
        var effectiveQuery = getEffectiveQuery(text)
        if (!effectiveQuery && filter === "All") return ""

        var lower = effectiveQuery.toLowerCase()
        if (lower.startsWith("rss:")) return ""

        if (isCommandOnlyQuery(effectiveQuery)) {
            return ""
        }

        return getFilteredQuery(effectiveQuery, filter)
    }
    
    // Background for Desktop Mode (Matte)
    Rectangle {
        anchors.fill: parent
        // Extend slightly to cover margins if needed, or fill parent
        z: -100
        color: popupRoot.bgColor
        radius: 12
        visible: !popupRoot.isInPanel
        opacity: 0.95 // Almost solid matte
        
        // Add a subtle border or shadow if needed for contrast
        border.color: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.1)
        border.width: 1
    }

    function cycleFocusSection(forward) {
        if (forward) {
            if (focusSection === 0) {
                focusSection = 1;
                if (isTileView && searchText.length > 0 && tileResultsLoader.item) {
                    tileResultsLoader.item.forceActiveFocus();
                } else if (searchText.length === 0 && logic.searchHistory.length > 0) {
                     if (isTileView && historyTileLoader.item) historyTileLoader.item.forceActiveFocus();
                }
            }
        } else {
            if (focusSection === 1) {
                focusSection = 0;
                hiddenSearchInput.forceActiveFocus();
            }
        }
    }

    function handleResultClick(index, display, decoration, category, matchId, filePath) {
        // Record to history
        logic.addToHistory(display, decoration, category, matchId, filePath, (index === -1 ? "rss" : null), popupRoot.searchText);
        
        // Handle non-milou results (like RSS)
        if (index === -1) {
            if (filePath && filePath.toString().length > 0) {
                Qt.openUrlExternally(filePath);
            }
            requestSearchTextUpdate("");
            requestExpandChange(false);
            return;
        }

        var isApp = (category.toLowerCase().indexOf("app") !== -1 || category.toLowerCase().indexOf("uygulama") !== -1) || (filePath && filePath.toString().indexOf(".desktop") > 0);
        var idx = resultsModel.index(index, 0);
        
        // FORCE RUN for command queries (gg:, help:, etc.) to avoid treating them as files
        if (isCommandOnlyQuery(popupRoot.searchText)) {
             resultsModel.run(idx);
        } 
        else if (isApp) {
             resultsModel.run(idx);
        } else if (filePath && filePath.length > 0 && filePath.toString().indexOf("http") !== 0) {
             // For files, open externally
             Qt.openUrlExternally(filePath);
        } else {
             // For bookmarks or others, use Milou run
             resultsModel.run(idx);
        }
        
        requestSearchTextUpdate("");
        requestExpandChange(false);
    }
    
    function handleHistoryClick(item) {
        // Move clicked item to top of history
        logic.addToHistory(item.display, item.decoration, item.category, item.matchId, item.filePath, item.sourceType, item.queryText);

        // If it's a known file or application path, open/run it directly and instantly
           var directPath = item.filePath || item.url || ""
           if (directPath && directPath.toString().length > 0) {
               if (directPath.toString().indexOf(".desktop") !== -1) {
                  // Direct application launch via safe helper
                   logic.launchApp(directPath);
             } else {
                  // Standard file open
                   Qt.openUrlExternally(directPath);
             }
             requestExpandChange(false);
             requestSearchTextUpdate("");
             return;
        }

           if (item.matchId && item.matchId.toString().indexOf(".desktop") !== -1) {
               logic.launchApp(item.matchId.toString())
               requestExpandChange(false);
               requestSearchTextUpdate("");
               return;
           }

        // Only fall back to search-run-timer for pure search strings (without stored paths)
        var searchTerm = item.display || item.queryText || "";
        requestSearchTextUpdate(searchTerm);
        
        if (!isButtonMode) hiddenSearchInput.text = searchTerm;
        else searchBar.setText(searchTerm);
        
        queueHistoryRun(item)
        historyRunTimer.start();
    }
    
    Timer {
        id: historyRunTimer
        interval: 400
        repeat: false
        onTriggered: {
            popupRoot.tryRunPendingHistory()
        }
    }

    function queueHistoryRun(item) {
        pendingHistoryRun = true
        pendingHistoryMatchId = item && item.matchId ? item.matchId.toString() : ""
        pendingHistoryDisplay = item && item.display ? item.display.toString() : ""
    }

    function tryRunPendingHistory() {
        if (!pendingHistoryRun) return
        if (!tileData || tileData.resultCount <= 0) return

        var items = tileData.flatSortedData || []
        var target = null
        for (var i = 0; i < items.length; i++) {
            var it = items[i]
            if (pendingHistoryMatchId && it.duplicateId === pendingHistoryMatchId) {
                target = it
                break
            }
        }
        if (!target && pendingHistoryDisplay) {
            for (var j = 0; j < items.length; j++) {
                var cand = items[j]
                if (cand.display === pendingHistoryDisplay) {
                    target = cand
                    break
                }
            }
        }
        if (!target) {
            target = items.length > 0 ? items[0] : null
        }
        if (!target) return

        pendingHistoryRun = false
        pendingHistoryMatchId = ""
        pendingHistoryDisplay = ""

        handleResultClick(
            target.index,
            target.display || "",
            target.decoration || "application-x-executable",
            target.category || "Other",
            target.duplicateId || target.display || "",
            target.url || ""
        )
    }

    // Navigation Helpers
    function moveSelectionUp() {
        if (searchText.length === 0) {
            if (historyLoader.item) historyLoader.item.moveUp();
            return;
        }

        if (isTileView && tileResultsLoader.item) {
             tileResultsLoader.item.moveUp(); // Spatial Up
        } else if (resultsListLoader.item) {
             resultsListLoader.item.moveUp();
        }
    }

    function moveSelectionDown() {
        if (searchText.length === 0) {
            if (historyLoader.item) historyLoader.item.moveDown();
            return;
        }

        if (isTileView && tileResultsLoader.item) {
             tileResultsLoader.item.moveDown(); // Spatial Down
        } else if (resultsListLoader.item) {
             resultsListLoader.item.moveDown();
        }
    }
    
    function moveSelectionLeft() {
        if (searchText.length === 0) {
            if (historyLoader.item) historyLoader.item.moveLeft();
            return;
        }

        if (isTileView && tileResultsLoader.item) {
             tileResultsLoader.item.moveLeft();
        }
    }
    
    function moveSelectionRight() {
        if (searchText.length === 0) {
            if (historyLoader.item) historyLoader.item.moveRight();
            return;
        }

        if (isTileView && tileResultsLoader.item) {
             tileResultsLoader.item.moveRight();
        }
    }
    
    // Command Query Helper
    function isCommandOnlyQuery(text) {
        if (!text) return false;
        var t = text.toLowerCase();
        var canShowWeather = plasmoidConfig && plasmoidConfig.weatherEnabled
        var locWeather = i18nd("plasma_applet_com.mcc45tr.filesearch", "weather")
        var isWeather = canShowWeather && (t === "weather:" || (locWeather && t === locWeather + ":"))
        
        // Only specific full-view modes hide the results list
        return isWeather || t === "date:" || t === "clock:" || t === "power:" || t === "help:" || 
               t === i18nd("plasma_applet_com.mcc45tr.filesearch", "date") + ":" || 
               t === i18nd("plasma_applet_com.mcc45tr.filesearch", "clock") + ":" || 
               t === i18nd("plasma_applet_com.mcc45tr.filesearch", "power") + ":" || 
               t === i18nd("plasma_applet_com.mcc45tr.filesearch", "help") + ":";
    }

    function getEffectiveQuery(text) {
        if (!text) return ""
        var t = text
        
        // Map localized prefixes back to internal English prefixes or strip them
        
        // 1. Check for "unit:"
        if (t.toLowerCase().startsWith("unit:")) return t.substring(5).trim()
        // Localized
        var locUnit = i18nd("plasma_applet_com.mcc45tr.filesearch", "unit")
        if (locUnit && t.toLowerCase().startsWith(locUnit + ":")) return t.substring(locUnit.length + 1).trim()
        
        // 2. Check for "date:" or "clock:"
        var locDate = i18nd("plasma_applet_com.mcc45tr.filesearch", "date")
        var locClock = i18nd("plasma_applet_com.mcc45tr.filesearch", "clock")
        
        // Check for "clock:"
        if (t.toLowerCase() === "clock:" || (locClock && t.toLowerCase() === locClock + ":")) return "clock:"
        
        // Check for "date:"
        if (t.toLowerCase() === "date:" || (locDate && t.toLowerCase() === locDate + ":")) return "date:"
        
        // Check for "weather:"
        var canShowWeather = plasmoidConfig && plasmoidConfig.weatherEnabled
        var locWeather = i18nd("plasma_applet_com.mcc45tr.filesearch", "weather")
        if (canShowWeather && (t.toLowerCase() === "weather:" || (locWeather && t.toLowerCase() === locWeather + ":"))) return "weather:"
        
        // 3. Check for "help:"
        var locHelp = i18nd("plasma_applet_com.mcc45tr.filesearch", "help")
        if (locHelp && t.toLowerCase() === locHelp + ":") return "help:"

        // 4. Check for "kill"
        var locKill = i18nd("plasma_applet_com.mcc45tr.filesearch", "kill")
        if (locKill && t.toLowerCase().startsWith(locKill + " ")) return "kill " + t.substring(locKill.length + 1)

        // 5. Check for "spell"
        var locSpell = i18nd("plasma_applet_com.mcc45tr.filesearch", "spell")
        if (locSpell && t.toLowerCase().startsWith(locSpell + " ")) return "spell " + t.substring(locSpell.length + 1)
        
        // 6. Check for "shell:"
        var locShell = i18nd("plasma_applet_com.mcc45tr.filesearch", "shell")
        if (locShell && t.toLowerCase().startsWith(locShell + ":")) return "shell:" + t.substring(locShell.length + 1)
        
        // 7. Check for "power:"
        var locPower = i18nd("plasma_applet_com.mcc45tr.filesearch", "power")
        if (t.toLowerCase() === "power:" || (locPower && t.toLowerCase() === locPower + ":")) return "power:"

        return t
    }

    // ===== UI COMPONENTS =====
    
    // Hidden Input - Active in NON-BUTTON modes
    HiddenSearchInput {
        id: hiddenSearchInput
        visible: !isButtonMode
        resultCount: tileData.resultCount
        currentIndex: resultsListLoader.active ? resultsListLoader.item.currentIndex : 0 // approximate
        
        onTextUpdated: (newText) => {
            tileData.startSearch();
            requestSearchTextUpdate(newText);
        }
        onSearchSubmitted: (idx) => {
             // Dispatch based on view mode
             if (isTileView && tileResultsLoader.item) {
                 tileResultsLoader.item.activateCurrentItem();
                 return;
             } else if (searchText.length === 0 && historyLoader.item && isTileView) {
                 // History Tile View activation
                 if (historyLoader.item.activateCurrentItem) { // If exposed
                     historyLoader.item.activateCurrentItem();
                     return;
                 }
                 // Actually historyLoader wrapper doesn't have activateCurrentItem, 
                 // but we can add it or access inner.
                 // Let's rely on focus being there OR add helper.
                 // For now let's handle Results Tile View explicitly here.
             }

             if (tileData.resultCount > 0) {
                 var modelIdx = resultsModel.index(idx, 0);
                 var display = resultsModel.data(modelIdx, Qt.DisplayRole) || "";
                 var decoration = resultsModel.data(modelIdx, Qt.DecorationRole) || "";
                 var category = resultsModel.data(modelIdx, resultsModel.CategoryRole) || "";
                 var matchId = resultsModel.data(modelIdx, resultsModel.DuplicateRole) || display;
                 var url = resultsModel.data(modelIdx, resultsModel.UrlRole) || ""; 
                 
                 handleResultClick(idx, display, decoration, category, matchId, url);
             }
         }
        onEscapePressed: {
             requestSearchTextUpdate("");
             requestExpandChange(false);
        }
        onUpPressed: moveSelectionUp()
        onDownPressed: moveSelectionDown()
        onLeftPressed: moveSelectionLeft()
        onRightPressed: moveSelectionRight()
        onTabPressedSignal: cycleFocusSection(true)
        onShiftTabPressedSignal: cycleFocusSection(false)
        onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
    }

    // New Search Bar (matches app-menu style, placed at top)
    SearchBar {
        id: searchBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        visible: isButtonMode
        resultCount: tileData.resultCount
        resultsModel: resultsModel
        logic: popupRoot.logic
        rssPlaceholderCycling: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssPlaceholderCycling || false) : false
        rssFrequency: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssFrequency !== undefined ? popupRoot.plasmoidConfig.rssFrequency : 3) : 3
        rssShowFullHeadline: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssShowFullHeadline !== undefined ? popupRoot.plasmoidConfig.rssShowFullHeadline : true) : true
        rssShowSource: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssShowSource || false) : false
        
        onTextUpdated: (newText) => {
             if (isButtonMode && newText !== popupRoot.searchText) {
                 requestSearchTextUpdate(newText);
                 tileData.startSearch();
             }
        }
        
        // Manual binding for text (Popup -> Input)
        Connections {
             target: popupRoot
             function onSearchTextChanged() {
                 if (popupRoot.expanded && isButtonMode && searchBar.text !== popupRoot.searchText) {
                     searchBar.setText(popupRoot.searchText);
                 }
             }
        }
        
        onSearchSubmitted: (text, idx) => {
             if (tileData.resultCount > 0) {
                 var modelIdx = resultsModel.index(idx, 0);
                 resultsModel.run(modelIdx);
                 requestSearchTextUpdate("");
                 searchBar.clear();
                 requestExpandChange(false);
             }
         }
        
        onEscapePressed: {
             requestSearchTextUpdate("");
             requestExpandChange(false);
        }
        onUpPressed: moveSelectionUp()
        onDownPressed: moveSelectionDown()
        onLeftPressed: moveSelectionLeft()
        onRightPressed: moveSelectionRight()
        onTabPressedSignal: cycleFocusSection(true)
        onShiftTabPressedSignal: cycleFocusSection(false)
        onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
    }

    // Filter Chips (Categories) - Moved to top
    Item {
        id: filterChipsWrapper
        anchors.top: searchBar.visible ? searchBar.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        
        property bool isVisible: {
            var hintsVisible = queryHintsLoader.active && queryHintsLoader.item && queryHintsLoader.item.visible;
            return popupRoot.expanded && popupRoot.searchText.length > 0 && !popupRoot.isRssOnlyQuery && !isCommandOnlyQuery(popupRoot.searchText) && !hintsVisible;
        }
        
        anchors.topMargin: isVisible ? 10 : 0
        height: isVisible ? 32 : 0
        opacity: isVisible ? 1 : 0
        clip: true
        visible: height > 0 || opacity > 0
        
        Behavior on height { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        
        Loader {
            anchors.fill: parent
            active: filterChipsWrapper.visible
            sourceComponent: FilterChips {
                textColor: popupRoot.textColor
                accentColor: popupRoot.accentColor
                bgColor: popupRoot.bgColor
                activeFilter: popupRoot.activeFilter
                breezeStyle: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.filterChipStyle === 1) : false
                
                onFilterSelected: (name) => {
                    popupRoot.activeFilter = name;
                    queryDebouncer.restart();
                    tileData.startSearch();
                }
            }
        }
    }

    // Primary Preview (Loader)
    Loader {
        id: primaryResultPreviewLoader
        anchors.top: filterChipsWrapper.bottom
        anchors.topMargin: (active && filterChipsWrapper.isVisible) ? 8 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        asynchronous: true
        active: popupRoot.expanded && popupRoot.searchText.length > 0 && !isTileView
        
        sourceComponent: PrimaryResultPreview {
            resultsModel: popupRoot.resultsModel
            resultCount: tileData.resultCount
            searchText: popupRoot.searchText
            accentColor: popupRoot.accentColor
            textColor: popupRoot.textColor
            
            onResultClicked: (idx, display, decoration, category) => {
                logic.addToHistory(display, decoration, category, display, "", "calculator", popupRoot.searchText);
                resultsModel.run(resultsModel.index(idx, 0));
                requestSearchTextUpdate("");
                requestExpandChange(false);
            }
        }
    }

    // Query Hints (Loader)
    Loader {
        id: queryHintsLoader
        anchors.top: (primaryResultPreviewLoader.active && primaryResultPreviewLoader.status === Loader.Ready) 
                     ? primaryResultPreviewLoader.bottom 
                     : filterChipsWrapper.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        active: popupRoot.expanded && popupRoot.searchText.length > 0 && !popupRoot.isRssOnlyQuery
        sourceComponent: QueryHints {
            searchText: popupRoot.searchText
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            bgColor: popupRoot.bgColor

            logic: popupRoot.logic
            plasmoidConfig: popupRoot.plasmoidConfig
            
            onHintSelected: (text) => {
                requestSearchTextUpdate(text)
                if (!isButtonMode) hiddenSearchInput.text = text
                else searchBar.setText(text)
            }
        }
    }
    


    // Pinned Section (Loader)
    Loader {
        id: pinnedLoader
        anchors.top: queryHintsLoader.active ? queryHintsLoader.bottom : (primaryResultPreviewLoader.active ? primaryResultPreviewLoader.bottom : filterChipsWrapper.bottom)
        anchors.topMargin: active ? 4 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        
        property var items: logic.visiblePinnedItems
        active: showPinnedBar && !popupRoot.isRssOnlyQuery
        
        // Connections removed as binding handles updates now
        
        sourceComponent: PinnedSection {
            pinnedItems: pinnedLoader.items
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            iconSize: popupRoot.iconSize
            isTileView: popupRoot.isTileView
            isSearching: popupRoot.searchText.length > 0
            compactPinnedView: popupRoot.compactPinnedItems
            breezeStyle: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.filterChipStyle === 1) : false

            
            onItemClicked: (item) => {
                if (item.filePath) {
                     if (item.filePath.toString().indexOf(".desktop") !== -1) {
                          logic.launchApp(item.filePath);
                     } else {
                          Qt.openUrlExternally(item.filePath);
                     }
                } else {
                    requestSearchTextUpdate(item.display);
                    // delayed run...
                    Qt.callLater(() => {
                        if (tileData.resultCount > 0) resultsModel.run(resultsModel.index(0, 0));
                    });
                }
                requestExpandChange(false);
            }
            onUnpinClicked: (matchId) => logic.unpinItem(matchId)
            
            // Drag-drop reorder
            onReorderRequested: (fromIndex, toIndex) => {
                logic.reorderPinnedItems(fromIndex, toIndex)
            }
            
            // Context menu actions
            onCopyPathRequested: (item) => {
                if (item.filePath) {
                    var path = item.filePath.toString().replace("file://", "")
                    logic.copyToClipboard(path)
                }
            }
            
            onOpenLocationRequested: (item) => {
                if (item.filePath) {
                    var path = item.filePath.toString()
                    // Get parent directory
                    var lastSlash = path.lastIndexOf("/")
                    if (lastSlash > 0) {
                        var parentDir = path.substring(0, lastSlash)
                        Qt.openUrlExternally(parentDir)
                    }
                }
            }
            width: parent.width
        }
    }





    // Result List View (Loader)
    Loader {
        id: resultsListLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom // Anchor to parent bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        // Use bottom margin to simulate anchoring to top of buttonModeSearchInput
        anchors.bottomMargin: 12
        
        active: popupRoot.expanded && !isTileView && searchText.length > 0 && !isCommandOnlyQuery(searchText)
        
        sourceComponent: ResultsListView {
             resultsModel: resultsModel
             flatSortedData: tileData.flatSortedData
             listIconSize: popupRoot.listIconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor

             searchText: popupRoot.searchText
             isLoading: popupRoot.isLoadingResults
             previewEnabled: popupRoot.previewEnabled
             previewSettings: popupRoot.previewSettings
             logic: popupRoot.logic
             
             isPinnedFunc: logic.isPinned
             togglePinFunc: logic.togglePin
             
             rssShowImages: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssShowImages !== undefined ? popupRoot.plasmoidConfig.rssShowImages : true) : true
             rssExpandableCards: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssExpandableCards !== undefined ? popupRoot.plasmoidConfig.rssExpandableCards : true) : true

             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)
             
             onItemRightClicked: (item, x, y) => {
                 resultsContextMenu.historyItem = item
                 resultsContextMenu.popup()
             }
             anchors.fill: parent
        }
    }
    
    // Result Tile View (Loader)
    Loader {
        id: tileResultsLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 12

        asynchronous: true
        active: popupRoot.expanded && isTileView && searchText.length > 0 && !isCommandOnlyQuery(searchText)
        
        sourceComponent: ResultsTileView {
             categorizedData: tileData.categorizedData
             iconSize: popupRoot.iconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor

             searchText: popupRoot.searchText
             isLoading: popupRoot.isLoadingResults
             previewEnabled: popupRoot.previewEnabled
             previewSettings: popupRoot.previewSettings
             scrollBarStyle: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.scrollBarStyle || 0) : 0
             compactTileView: popupRoot.compactHistoryItems

             rssShowImages: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssShowImages !== undefined ? popupRoot.plasmoidConfig.rssShowImages : true) : true
             rssExpandableCards: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssExpandableCards !== undefined ? popupRoot.plasmoidConfig.rssExpandableCards : true) : true

             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)
             
             onItemRightClicked: (item, x, y) => {
                 resultsContextMenu.historyItem = item
                 resultsContextMenu.popup()
             }
             
             onTabPressed: cycleFocusSection(true)
             onShiftTabPressed: cycleFocusSection(false)
             onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
             anchors.fill: parent
        }
    }

    // Date/Clock View (Special "date:" query)
    Loader {
        id: dateViewLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom // Anchor to parent bottom
        anchors.margins: 12
        anchors.bottomMargin: 12
        
        active: popupRoot.expanded && (getEffectiveQuery(searchText) === "date:" || getEffectiveQuery(searchText) === "clock:")
        
        sourceComponent: DateView {
            textColor: popupRoot.textColor
            viewMode: getEffectiveQuery(popupRoot.searchText) === "clock:" ? "clock" : "date"
            showClock: popupRoot.prefixDateShowClock
            showEvents: popupRoot.prefixDateShowEvents
            anchors.fill: parent
        }
    }

    // Help View ("help:" query)
    Loader {
        id: helpViewLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: 12
        
        active: popupRoot.expanded && getEffectiveQuery(searchText) === "help:"
        
        sourceComponent: HelpView {
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor

            
            onAidSelected: (prefix) => {
                // When selecting from Help, we put the LOCALIZED prefix in the box if possible?
                // Or just the standard one? 
                // Let's use standard for now or what comes from HelpView (which we will update to be localized?)
                // If HelpView sends "birim:", we put "birim:".
                requestSearchTextUpdate(prefix)
                if (!isButtonMode) hiddenSearchInput.text = prefix
                else searchBar.setText(prefix)
                // Focus input?
            }
            anchors.fill: parent
        }
    }
    
    // Weather View ("weather:" query)
    Loader {
        id: weatherViewLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: 12
        
        active: popupRoot.expanded && getEffectiveQuery(searchText) === "weather:"
        
        sourceComponent: WeatherView {
            // WeatherView handles its own fetching on visible
            plasmoidConfig: popupRoot.plasmoidConfig
            anchors.fill: parent
        }
    }

    // Power View ("power:" query)
    Loader {
        id: powerViewLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: 12
        
        active: popupRoot.expanded && getEffectiveQuery(searchText) === "power:"
        
        sourceComponent: PowerView {
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            showHibernate: popupRoot.prefixPowerShowHibernate
            showSleep: popupRoot.prefixPowerShowSleep
            bgColor: popupRoot.bgColor
            showBootOptions: popupRoot.showBootOptions
            plasmoidConfig: popupRoot.plasmoidConfig
            
            onRequestPreventClosing: (prevent) => {
                popupRoot.preventClosing = prevent
                popupRoot.requestPreventClosing(prevent) // Forward to main just in case
            }
            anchors.fill: parent
        }
    }
    
    // History Container (Loader) - Show when no search text
    Loader {
         id: historyLoader
         anchors.top: pinnedLoader.bottom
         anchors.left: parent.left
         anchors.right: parent.right
         anchors.bottom: parent.bottom // Anchor to parent bottom
         anchors.leftMargin: 12
         anchors.rightMargin: 12
         // History top margin is now fixed
         anchors.topMargin: 6 
         asynchronous: true
         anchors.bottomMargin: 12
         
         active: popupRoot.expanded && searchText.length === 0
         
         property var categorizedHistory: {
             if (!(logic.historyVersion >= 0 && logic.searchHistory.length > 0)) return [];
             var hist = logic.searchHistory;
             if (activeFilter !== "All") {
                 var filtered = [];
                 var filterLower = activeFilter.toLowerCase();
                 for (var i = 0; i < hist.length; i++) {
                     var item = hist[i];
                     var catLower = (item.category || "").toLowerCase();
                     var decLower = (item.decoration || "").toLowerCase();
                     var urlLower = (item.filePath || "").toLowerCase();
                     var shouldKeep = false;
                     
                     if (filterLower === "apps" && item.isApplication) shouldKeep = true;
                     else if (filterLower === "docs" && (catLower.indexOf("belge") !== -1 || catLower.indexOf("doc") !== -1)) shouldKeep = true;
                     else if (filterLower === "images" && (catLower.indexOf("resim") !== -1 || catLower.indexOf("image") !== -1 || decLower.indexOf("image") !== -1)) shouldKeep = true;
                     else if (filterLower === "folders" && (catLower.indexOf("klasör") !== -1 || catLower.indexOf("folder") !== -1 || catLower.indexOf("place") !== -1)) shouldKeep = true;
                     else if (filterLower === "web" && (catLower.indexOf("web") !== -1 || catLower.indexOf("internet") !== -1)) shouldKeep = true;
                     
                     if (shouldKeep) filtered.push(item);
                 }
                 hist = filtered;
             }
             return HistoryManager.categorizeHistory(hist, i18nd("plasma_applet_com.mcc45tr.filesearch", "Applications"), i18nd("plasma_applet_com.mcc45tr.filesearch", "Other"));
         }
         
         sourceComponent: Item {
             anchors.fill: parent
             // Helper to route navigation
             function moveUp() { 
                 if (isTileView) histTileView.moveUp();
             }
             function moveDown() { 
                 if (isTileView) histTileView.moveDown();
             }
             function moveLeft() { 
                 if (isTileView) histTileView.moveLeft();
             }
             function moveRight() { 
                 if (isTileView) histTileView.moveRight();
             }
             function activateCurrentItem() {
                 if (isTileView) histTileView.activateCurrentItem();
             }

             // History List
                             HistoryListView {
                 id: histListView
                 anchors.fill: parent
                 visible: !isTileView
                 categorizedHistory: historyLoader.categorizedHistory
                 listIconSize: popupRoot.listIconSize
                 textColor: popupRoot.textColor
                 accentColor: popupRoot.accentColor
                 formatTimeFunc: logic.formatHistoryTime

                 logic: popupRoot.logic
                 previewEnabled: popupRoot.previewEnabled
                 previewSettings: popupRoot.previewSettings
                 
                 onItemClicked: (item) => handleHistoryClick(item)
                 onClearClicked: logic.clearHistory()
             }
             
             // History Tile
             HistoryTileView {
                 id: histTileView
                 previewEnabled: popupRoot.previewEnabled
                 anchors.fill: parent
                 visible: isTileView
                 categorizedHistory: historyLoader.categorizedHistory
                 iconSize: popupRoot.iconSize
                 textColor: popupRoot.textColor
                 accentColor: popupRoot.accentColor

                 logic: popupRoot.logic
                 previewSettings: popupRoot.previewSettings
                 scrollBarStyle: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.scrollBarStyle || 0) : 0
                 compactTileView: popupRoot.compactHistoryItems
                 
                 onItemClicked: (item) => handleHistoryClick(item)
                 onClearClicked: logic.clearHistory()
                 
                 onTabPressed: cycleFocusSection(true)
                 onShiftTabPressed: cycleFocusSection(false)
                 onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
             }
         }
    }
    
    // Debug Overlay (Loader)
    Loader {
         id: debugOverlayLoader
         anchors.top: parent.top
         anchors.right: parent.right
         anchors.margins: 8
         z: 9999
         asynchronous: true
         active: popupRoot.expanded && popupRoot.showDebug
         
         sourceComponent: DebugOverlay {
              resultCount: tileData.resultCount
              activeBackend: popupRoot.activeBackend
              lastLatency: tileData.lastLatency
              viewModeName: isTileView ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Tile") : i18nd("plasma_applet_com.mcc45tr.filesearch", "List")
              displayModeName: isButtonMode ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Button") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Mode")
              totalSearches: logic.telemetryStats.totalSearches || 0
              avgLatency: logic.telemetryStats.averageLatency || 0

         }
    }

    Component.onCompleted: {
         if (!isButtonMode && hiddenSearchInput) {
            hiddenSearchInput.forceActiveFocus();
         }
    }
}
