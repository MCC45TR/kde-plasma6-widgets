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
    
    // Configuration
    property int displayMode: 0
    property int viewMode: 0
    property int iconSize: 32
    property int listIconSize: 22
    
    property color textColor
    property color accentColor
    property color bgColor
    
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
    
    // ===== DATA MANAGER =====
    TileDataManager {
        id: tileData
        resultsModel: resultsModel
        logic: popupRoot.logic
        
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
                if (isButtonMode) buttonModeSearchInput.focusInput();
                else hiddenSearchInput.forceActiveFocus();
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
        if (item.filePath && item.filePath.toString().length > 0) {
            Qt.openUrlExternally(item.filePath);
            requestExpandChange(false);
            return;
        }
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
            if (resultsModel.rowCount() > 0) {
                var idx = resultsModel.index(0, 0);
                resultsModel.run(idx);
                requestSearchTextUpdate("");
                requestExpandChange(false);
            }
        }
    }

    // ===== UI COMPONENTS =====
    
    // Hidden Input
    HiddenSearchInput {
        id: hiddenSearchInput
        visible: !isButtonMode
        resultCount: resultsListLoader.active ? resultsListLoader.item.count : 0
        currentIndex: resultsListLoader.active ? resultsListLoader.item.currentIndex : 0 // approximate
        
        onTextUpdated: (newText) => {
            tileData.startSearch();
            requestSearchTextUpdate(newText);
        }
        onSearchSubmitted: (idx) => {
             // Logic to find item at idx and run it
             // Simplified: use handleResultClick logic but need data
             if (resultsModel.rowCount() > 0) {
                 var modelIdx = resultsModel.index(idx, 0);
                 var display = resultsModel.data(modelIdx, Qt.DisplayRole) || "";
                 var decoration = resultsModel.data(modelIdx, Qt.DecorationRole) || "";
                 var category = resultsModel.data(modelIdx, resultsModel.CategoryRole) || "";
                 var matchId = resultsModel.data(modelIdx, resultsModel.DuplicateRole) || display;
                 
                 // Proxy lookup tricky here as Repeater is inside TileDataManager.
                 // We can use resultsModel directly or helper.
                 // For now, let's assume direct URL role or standard Milou run behavior + history
                 
                 // We need distinct logic for URL resolution if possible.
                 // Ideally TileDataManager could expose a helper but it's internal.
                 // Let's rely on standard model run for simplicity OR move URL resolution logic to LogicController helper?
                 // For now, standard run:
                 
                 // Capture URL logic locally
                 var url = resultsModel.data(modelIdx, resultsModel.UrlRole) || ""; 
                 // (Milou UrlRole might differ, check main.qml used Proxy).
                 // main.qml used Proxy to get specific 'url', 'urls', 'subtext'.
                 // We can't access TileDataManager's internal repeater easily.
                 // BUT hiddenSearchInput is mainly for list view or direct typing.
                 // List View logic works.
                 
                 handleResultClick(idx, display, decoration, category, matchId, url);
             }
        }
        onEscapePressed: {
             requestSearchTextUpdate("");
             requestExpandChange(false);
        }
        onUpPressed: if (resultsListLoader.item) resultsListLoader.item.moveUp()
        onDownPressed: if (resultsListLoader.item) resultsListLoader.item.moveDown()
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
        resultCount: resultsModel.rowCount()
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
             if (resultsModel.rowCount() > 0) {
                 var modelIdx = resultsModel.index(idx, 0);
                 var display = resultsModel.data(modelIdx, Qt.DisplayRole);
                 // ... simplify
                 handleResultClick(idx, display, "", "", "", ""); // URL fallback handled inside? No.
                 // We should ideally fix URL resolution. For now, basic run.
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
        onUpPressed: if (resultsListLoader.item) resultsListLoader.item.moveUp()
        onDownPressed: if (resultsListLoader.item) resultsListLoader.item.moveDown()
        onTabPressedSignal: cycleFocusSection(true)
        onShiftTabPressedSignal: cycleFocusSection(false)
        onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
    }

    // Primary Preview
    PrimaryResultPreview {
        id: primaryResultPreview
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        
        resultsModel: resultsModel
        resultCount: resultsModel.rowCount()
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

    // Query Hints (Loader)
    Loader {
        id: queryHintsLoader
        anchors.top: primaryResultPreview.visible ? primaryResultPreview.bottom : parent.top
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        
        active: true // Light component, keep active?
        sourceComponent: QueryHints {
            searchText: popupRoot.searchText
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            bgColor: popupRoot.bgColor
            trFunc: popupRoot.trFunc
        }
    }
    
    // Pinned Section (Loader)
    Loader {
        id: pinnedLoader
        anchors.top: queryHintsLoader.item ? queryHintsLoader.item.bottom : (primaryResultPreview.visible ? primaryResultPreview.bottom : parent.top)
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        
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
                        if (resultsModel.rowCount() > 0) resultsModel.run(resultsModel.index(0, 0));
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
        anchors.top: pinnedLoader.item ? pinnedLoader.item.bottom : (queryHintsLoader.item ? queryHintsLoader.item.bottom : (primaryResultPreview.visible ? primaryResultPreview.bottom : parent.top))
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: isButtonMode ? buttonModeSearchInput.top : parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: isButtonMode ? 6 : 12
        
        active: !isTileView && searchText.length > 0
        
        sourceComponent: ResultsListView {
             resultsModel: resultsModel
             listIconSize: popupRoot.listIconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor
             trFunc: popupRoot.trFunc
             searchText: popupRoot.searchText
             
             isPinnedFunc: logic.isPinned
             togglePinFunc: logic.togglePin
             
             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)
        }
    }
    
    // Result Tile View (Loader)
    Loader {
        id: tileResultsLoader
        anchors.fill: parent
        anchors.margins: 12
        active: isTileView && searchText.length > 0
        
        sourceComponent: ResultsTileView {
             categorizedData: tileData.categorizedData
             // ... other props
             iconSize: popupRoot.iconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor
             trFunc: popupRoot.trFunc
             searchText: popupRoot.searchText

             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)
             
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
         anchors.bottom: isButtonMode ? buttonModeSearchInput.top : parent.bottom
         anchors.margins: 12
         anchors.bottomMargin: isButtonMode ? 6 : 12
         
         active: searchText.length === 0 && logic.searchHistory.length > 0
         
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
             // History List
             HistoryListView {
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
    
    // Debug Overlay
    DebugOverlay {
         anchors.top: parent.top
         anchors.right: parent.right
         anchors.margins: 8
         z: 9999
         // ... bind to tileData stats ...
         resultCount: tileData.resultCount
         activeBackend: popupRoot.activeBackend
         lastLatency: tileData.lastLatency
         viewModeName: isTileView ? "Tile" : "List"
         displayModeName: isButtonMode ? "Button" : "Mode"
         totalSearches: logic.telemetryStats.totalSearches || 0
         avgLatency: logic.telemetryStats.averageLatency || 0
         tr: popupRoot.trFunc
    }

    Component.onCompleted: {
        if (!isButtonMode && hiddenSearchInput) {
             hiddenSearchInput.forceActiveFocus();
        }
    }
}
