import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou
import "../js/HistoryManager.js" as HistoryManager

Item {
    id: popupRoot
    
    // Dependencies
    required property var logic    
    
    // Properties synced with main
    property string searchText: ""
    property bool expanded: false
    
    onExpandedChanged: {
        if (expanded) {
            // Force focus when popup opens
            if (isButtonMode) {
                buttonModeSearchInput.focusInput()
            } else {
                hiddenSearchInput.forceActiveFocus()
            }
        } else {
            // Clear search text when popup closes
            requestSearchTextUpdate("")
            buttonModeSearchInput.clear()
            hiddenSearchInput.text = ""
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
    property bool previewEnabled: true

    property var trFunc
    
    // Signals to Main
    signal requestSearchTextUpdate(string text)
    signal requestExpandChange(bool expanded)
    signal requestViewModeChange(int mode)
    
    // Read-only helpers
    readonly property bool isButtonMode: displayMode === 0
    readonly property bool isTileView: viewMode === 1
    
    // Layout
    Layout.preferredWidth: 500
    Layout.preferredHeight: 380
    Layout.minimumWidth: 400
    Layout.minimumHeight: 250
    
    // internal state
    property int focusSection: 0
    property string activeBackend: "Milou"
    
    // Mat Background
    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        radius: 12
        z: -1
    }
    
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
        
        onCategorizedDataChanged: {
             // propagated automatically to bindings
        }
    }
    
    // ===== SEARCH MODEL =====
    Milou.ResultsModel {
        id: resultsModel
        queryString: popupRoot.searchText
        limit: 50
    }
    
    // ===== FUNCTIONS =====
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
        logic.addToHistory(display, decoration, category, matchId, filePath, null, popupRoot.searchText);
        
        var isApp = (category === "Uygulamalar" || category === "Applications") || (filePath && filePath.toString().indexOf(".desktop") > 0);
        var idx = resultsModel.index(index, 0);
        
        if (isApp) {
             resultsModel.run(idx);
        } else if (filePath && filePath.length > 0) {
             Qt.openUrlExternally(filePath);
        } else {
             resultsModel.run(idx);
        }
        
        requestSearchTextUpdate("");
        requestExpandChange(false);
    }
    
    function handleHistoryClick(item) {
        // If it's a known file or application path, open/run it directly and instantly
        if (item.filePath && item.filePath.toString().length > 0) {
             if (item.filePath.toString().indexOf(".desktop") !== -1) {
                  // Direct application launch via kioclient
                  logic.runShellCommand("kioclient exec '" + item.filePath + "'");
             } else {
                  // Standard file open
                  Qt.openUrlExternally(item.filePath);
             }
             requestExpandChange(false);
             requestSearchTextUpdate("");
             return;
        }

        // Only fall back to search-run-timer for pure search strings (without stored paths)
        var searchTerm = item.display || item.queryText || "";
        requestSearchTextUpdate(searchTerm);
        
        if (!isButtonMode) hiddenSearchInput.text = searchTerm;
        else buttonModeSearchInput.setText(searchTerm);
        
        historyRunTimer.start();
    }
    
    Timer {
        id: historyRunTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (tileData.resultCount > 0) {
                var idx = resultsModel.index(0, 0);
                resultsModel.run(idx);
                requestSearchTextUpdate("");
                requestExpandChange(false);
            }
        }
    }

    // Navigation Helpers
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

    // Button Mode Input
    ButtonModeSearchInput {
        id: buttonModeSearchInput
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: isButtonMode
        z: 100
        
        bgColor: popupRoot.bgColor
        textColor: popupRoot.textColor
        accentColor: popupRoot.accentColor
        placeholderText: trFunc("search_placeholder") || "Arama Yapın"
        resultCount: tileData.resultCount
        resultsModel: resultsModel
        
        // Manual binding for text (Popup -> Input)
        Connections {
             target: popupRoot
             function onSearchTextChanged() {
                 if (popupRoot.expanded && isButtonMode && buttonModeSearchInput.searchText !== popupRoot.searchText) {
                     buttonModeSearchInput.setText(popupRoot.searchText);
                 }
             }
        }
        
        // Sync Input -> Popup
        onSearchTextChanged: {
            if (isButtonMode && buttonModeSearchInput.searchText !== popupRoot.searchText) {
                // If the change initiated from input (user typing), sync up
                requestSearchTextUpdate(buttonModeSearchInput.searchText);
                tileData.startSearch();
            }
        }

        onSearchSubmitted: (text, idx) => {
             // Just run index 0 or selected
             if (tileData.resultCount > 0) {
                 var modelIdx = resultsModel.index(idx, 0);
                 var display = resultsModel.data(modelIdx, Qt.DisplayRole);
                 resultsModel.run(modelIdx);
                 requestSearchTextUpdate("");
                 buttonModeSearchInput.clear();
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

    // Primary Preview (Loader)
    Loader {
        id: primaryResultPreviewLoader
        anchors.top: parent.top
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
        anchors.top: primaryResultPreviewLoader.active && primaryResultPreviewLoader.status === Loader.Ready ? primaryResultPreviewLoader.bottom : parent.top
        anchors.topMargin: (primaryResultPreviewLoader.active) ? 8 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        active: popupRoot.expanded && popupRoot.searchText.length > 0
        sourceComponent: QueryHints {
            searchText: popupRoot.searchText
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            bgColor: popupRoot.bgColor
            trFunc: popupRoot.trFunc
            logic: popupRoot.logic
            
            onHintSelected: (text) => {
                requestSearchTextUpdate(text)
                if (!isButtonMode) hiddenSearchInput.text = text
                else buttonModeSearchInput.setText(text)
            }
        }
    }
    
    // Pinned Section (Loader)
    Loader {
        id: pinnedLoader
        anchors.top: queryHintsLoader.bottom
        anchors.topMargin: active ? 8 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        
        property var items: logic.getVisiblePinnedItems()
        active: items.length > 0
        
        sourceComponent: PinnedSection {
            pinnedItems: pinnedLoader.items
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            iconSize: popupRoot.iconSize
            isTileView: popupRoot.isTileView
            trFunc: popupRoot.trFunc
            
            onItemClicked: (item) => {
                if (item.filePath) Qt.openUrlExternally(item.filePath);
                else {
                    requestSearchTextUpdate(item.display);
                    // delayed run...
                    Qt.callLater(() => {
                        if (tileData.resultCount > 0) resultsModel.run(resultsModel.index(0, 0));
                    });
                }
                requestExpandChange(false);
            }
            onUnpinClicked: (matchId) => logic.unpinItem(matchId)
        }
    }

    // Result List View (Loader)
    Loader {
        id: resultsListLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 12 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom // Anchor to parent bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        // Use bottom margin to simulate anchoring to top of buttonModeSearchInput
        anchors.bottomMargin: isButtonMode ? (buttonModeSearchInput.height + 12) : 12
        
        active: !isTileView && searchText.length > 0
        
        sourceComponent: ResultsListView {
             resultsModel: resultsModel
             flatSortedData: tileData.flatSortedData
             listIconSize: popupRoot.listIconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor
             trFunc: popupRoot.trFunc
             searchText: popupRoot.searchText
             previewEnabled: popupRoot.previewEnabled
             logic: popupRoot.logic
             
             isPinnedFunc: logic.isPinned
             togglePinFunc: logic.togglePin
             
             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)
             
             onItemRightClicked: (item, x, y) => {
                 resultsContextMenu.historyItem = item
                 resultsContextMenu.popup()
             }
        }
    }
    
    // Result Tile View (Loader)
    Loader {
        id: tileResultsLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 12 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 12 // Standard bottom margin

        asynchronous: true
        active: popupRoot.expanded && isTileView && searchText.length > 0
        
        sourceComponent: ResultsTileView {
             categorizedData: tileData.categorizedData
             iconSize: popupRoot.iconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor
             trFunc: popupRoot.trFunc
             searchText: popupRoot.searchText

             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)
             
             onItemRightClicked: (item, x, y) => {
                 resultsContextMenu.historyItem = item
                 resultsContextMenu.popup()
             }
             
             onTabPressed: cycleFocusSection(true)
             onShiftTabPressed: cycleFocusSection(false)
             onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
        }
    }
    
    // History Container (Loader) - Show when no search text
    Loader {
         id: historyLoader
         anchors.top: parent.top
         anchors.left: parent.left
         anchors.right: parent.right
         anchors.bottom: parent.bottom // Anchor to parent bottom
         anchors.margins: 12
         asynchronous: true
         // Use bottom margin to simulate anchoring to top of buttonModeSearchInput
         anchors.bottomMargin: isButtonMode ? (buttonModeSearchInput.height + 12) : 12
         
         active: popupRoot.expanded && searchText.length === 0 && logic.searchHistory.length > 0
         
         property var categorizedHistory: []
         onActiveChanged: if(active) categorizedHistory = HistoryManager.categorizeHistory(logic.searchHistory, trFunc("applications"), trFunc("other"))
         
         Connections {
             target: logic
             function onHistoryForceUpdate() {
                 if (historyLoader.status === Loader.Ready) {
                      historyLoader.categorizedHistory = HistoryManager.categorizeHistory(logic.searchHistory, trFunc("applications"), trFunc("other"))
                 }
             }
         }
         
         sourceComponent: Item {
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
                 trFunc: popupRoot.trFunc
                 
                 onItemClicked: (item) => handleHistoryClick(item)
                 onClearClicked: logic.clearHistory()
             }
             
             // History Tile
             HistoryTileView {
                 id: histTileView
                 anchors.fill: parent
                 visible: isTileView
                 categorizedHistory: historyLoader.categorizedHistory
                 iconSize: popupRoot.iconSize
                 textColor: popupRoot.textColor
                 accentColor: popupRoot.accentColor
                 trFunc: popupRoot.trFunc
                 
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
              viewModeName: isTileView ? "Tile" : "List"
              displayModeName: isButtonMode ? "Button" : "Mode"
              totalSearches: logic.telemetryStats.totalSearches || 0
              avgLatency: logic.telemetryStats.averageLatency || 0
              tr: popupRoot.trFunc
         }
    }

    Component.onCompleted: {
         if (!isButtonMode && hiddenSearchInput) {
            hiddenSearchInput.forceActiveFocus();
         }
    }
}
