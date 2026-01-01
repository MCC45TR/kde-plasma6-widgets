import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou

// Import localization data
import "localization.js" as LocalizationData

// Import utility modules
import "utils.js" as Utils
import "HistoryManager.js" as HistoryManager

// Import components
import "components" as Components

PlasmoidItem {
    id: root
    
    // ===== CORE PROPERTIES =====
    property string searchText: ""

    // Responsive font size based on height (40% of panel height)
    readonly property int responsiveFontSize: Math.max(10, Math.round(height * 0.4))
    
    // ===== DISPLAY MODE CONFIGURATION =====
    // 0 = Button, 1 = Medium, 2 = Wide, 3 = Extra Wide
    readonly property int displayMode: Plasmoid.configuration.displayMode
    readonly property bool isButtonMode: displayMode === 0
    readonly property bool isMediumMode: displayMode === 1
    readonly property bool isWideMode: displayMode === 2
    readonly property bool isExtraWideMode: displayMode === 3

    // ===== LAYOUT CALCULATIONS =====
    readonly property real textContentWidth: isButtonMode ? 0 : (textMetrics.width + ((isWideMode || isExtraWideMode) ? (height + 30) : 20))
    readonly property real baseWidth: isButtonMode ? height : (isExtraWideMode ? (height * 6) : ((isWideMode) ? (height * 4) : 70))
    
    Layout.preferredWidth: Math.max(baseWidth, textContentWidth)
    Layout.preferredHeight: 38
    Layout.minimumWidth: 50
    Layout.minimumHeight: 34
    
    // Character limits
    readonly property int maxCharsWide: 65
    readonly property int maxCharsMedium: 35
    readonly property int maxChars: isWideMode ? maxCharsWide : maxCharsMedium
    
    // Truncated text for display
    readonly property string placeholderText: isExtraWideMode ? root.tr("start_searching") : (isWideMode ? root.tr("search_dots") : root.tr("search"))
    readonly property string rawSearchText: searchText.length > 0 ? searchText : placeholderText
    readonly property string truncatedText: rawSearchText.length > maxChars ? rawSearchText.substring(0, maxChars) + "..." : rawSearchText
    
    TextMetrics {
        id: textMetrics
        font.family: "Roboto Condensed"
        font.pixelSize: root.responsiveFontSize
        text: root.truncatedText
    }
    
    // No background - transparent
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    // ===== VIEW MODE CONFIGURATION =====
    // 0 = List, 1 = Tile
    readonly property int viewMode: Plasmoid.configuration.viewMode
    readonly property bool isTileView: viewMode === 1
    
    // Icon sizes
    readonly property int iconSize: Math.max(16, Plasmoid.configuration.iconSize || 48)
    readonly property int listIconSize: Math.max(16, Plasmoid.configuration.listIconSize || 22)
    
    // ===== THEME COLORS =====
    readonly property color bgColor: Kirigami.Theme.backgroundColor
    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color accentColor: Kirigami.Theme.highlightColor
    
    // ===== HISTORY MANAGEMENT =====
    property var searchHistory: []
    readonly property int maxHistoryItems: 20


    // ===== LOCALIZATION =====
    property var locales: LocalizationData.data
    property string currentLocale: Qt.locale().name.substring(0, 2)
    
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) {
            return locales[currentLocale][key]
        }
        if (locales["en"] && locales["en"][key]) {
            return locales["en"][key]
        }
        return key
    }

    // ===== HISTORY FUNCTIONS (delegated to HistoryManager) =====
    function loadHistory() {
        searchHistory = HistoryManager.loadHistory(Plasmoid.configuration.searchHistory)
    }
    
    function saveHistory() {
        Plasmoid.configuration.searchHistory = JSON.stringify(searchHistory)
    }
    
    function addToHistory(display, decoration, category, matchId, filePath, sourceType, queryText) {
        searchHistory = HistoryManager.addToHistory(
            searchHistory, display, decoration, category, 
            matchId, filePath, sourceType, queryText, maxHistoryItems
        )
        saveHistory()
    }
    
    function formatHistoryTime(timestamp) {
        return Utils.formatHistoryTime(timestamp, root.tr)
    }
    
    function clearHistory() {
        searchHistory = HistoryManager.clearHistory()
        saveHistory()
    }

    // ===== INITIALIZATION =====
    Component.onCompleted: {
        loadHistory()
        // Locale data is now synchronously loaded via import
    }

    // ===== COMPACT REPRESENTATION (Panel Widget) =====
    compactRepresentation: Components.CompactView {
        anchors.fill: parent
        
        isButtonMode: root.isButtonMode
        isWideMode: root.isWideMode
        isExtraWideMode: root.isExtraWideMode
        expanded: root.expanded
        truncatedText: root.truncatedText
        responsiveFontSize: root.responsiveFontSize
        bgColor: root.bgColor
        textColor: root.textColor
        accentColor: root.accentColor
        searchTextLength: root.searchText.length
        
        onToggleExpanded: root.expanded = !root.expanded
    }
    
    // ===== FULL REPRESENTATION (Popup) =====
    fullRepresentation: Item {
        id: popupContent
        
        Layout.preferredWidth: 500
        Layout.preferredHeight: 380
        Layout.minimumWidth: 400
        Layout.minimumHeight: 250
        
        // Local references
        readonly property var mainRoot: root
        readonly property color delegateTextColor: mainRoot.textColor
        readonly property color delegateAccentColor: mainRoot.accentColor
        
        // ===== FOCUS MANAGEMENT =====
        // 0 = search input, 1 = results/tile view
        property int focusSection: 0
        
        function cycleFocusSection(forward) {
            if (forward) {
                if (focusSection === 0) {
                    // From input to results
                    focusSection = 1
                    if (mainRoot.isTileView && mainRoot.searchText.length > 0 && tileResultsLoader.item) {
                        tileResultsLoader.item.forceActiveFocus()
                    } else if (mainRoot.searchText.length === 0 && mainRoot.searchHistory.length > 0) {
                        // Focus history
                        if (mainRoot.isTileView && historyTileLoader.item) {
                            historyTileLoader.item.forceActiveFocus()
                        }
                    }
                }
            } else {
                if (focusSection === 1) {
                    // From results back to input
                    focusSection = 0
                    if (mainRoot.isButtonMode) {
                        buttonModeSearchInput.focusInput()
                    } else {
                        hiddenSearchInput.forceActiveFocus()
                    }
                }
            }
        }
        
        function changeViewMode(mode) {
            Plasmoid.configuration.viewMode = mode
        }
        
        // ===== SEARCH MODELS =====
        Milou.ResultsModel {
            id: resultsModel
            queryString: mainRoot.searchText
            limit: 50
        }
        
        // ===== HIDDEN SEARCH INPUT (non-button modes) =====
        Components.HiddenSearchInput {
            id: hiddenSearchInput
            visible: !mainRoot.isButtonMode
            resultCount: resultsList.count
            currentIndex: resultsList.currentIndex
            
            onTextUpdated: (newText) => { mainRoot.searchText = newText }
            onSearchSubmitted: (idx) => {
                if (resultsList.count > 0) {
                    var modelIdx = resultsModel.index(idx, 0)
                    var display = resultsModel.data(modelIdx, Qt.DisplayRole) || ""
                    var decoration = resultsModel.data(modelIdx, Qt.DecorationRole) || "application-x-executable"
                    var category = resultsModel.data(modelIdx, resultsModel.CategoryRole) || "Diğer"
                    var matchId = resultsModel.data(modelIdx, resultsModel.DuplicateRole) || display
                    mainRoot.addToHistory(display, decoration, category, matchId, "", null, mainRoot.searchText)
                    resultsModel.run(modelIdx)
                    mainRoot.searchText = ""
                    mainRoot.expanded = false
                }
            }
            onEscapePressed: {
                mainRoot.searchText = ""
                text = ""
                mainRoot.expanded = false
            }
            onUpPressed: resultsList.moveUp()
            onDownPressed: resultsList.moveDown()
            onTabPressedSignal: popupContent.cycleFocusSection(true)
            onShiftTabPressedSignal: popupContent.cycleFocusSection(false)
            onViewModeChangeRequested: (mode) => popupContent.changeViewMode(mode)
        }
        
        // ===== BUTTON MODE SEARCH INPUT =====
        Components.ButtonModeSearchInput {
            id: buttonModeSearchInput
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            visible: mainRoot.isButtonMode
            z: 100
            
            bgColor: mainRoot.bgColor
            textColor: mainRoot.textColor
            accentColor: mainRoot.accentColor
            placeholderText: mainRoot.tr("search_placeholder") || "Arama Yapın"
            resultCount: resultsList.count
            resultsModel: resultsModel
            
            // Sync searchText to parent
            Binding {
                target: mainRoot
                property: "searchText"
                value: buttonModeSearchInput.searchText
            }
            onSearchSubmitted: (text, selectedIndex) => {
                if (resultsList.count > 0) {
                    var idx = resultsModel.index(selectedIndex, 0)
                    var display = resultsModel.data(idx, Qt.DisplayRole) || ""
                    var decoration = resultsModel.data(idx, Qt.DecorationRole) || "application-x-executable"
                    var category = resultsModel.data(idx, resultsModel.CategoryRole) || "Diğer"
                    var matchId = resultsModel.data(idx, resultsModel.DuplicateRole) || display
                    mainRoot.addToHistory(display, decoration, category, matchId, "", null, mainRoot.searchText)
                    resultsModel.run(idx)
                    mainRoot.searchText = ""
                    buttonModeSearchInput.clear()
                    mainRoot.expanded = false
                }
            }
            onEscapePressed: {
                mainRoot.searchText = ""
                mainRoot.expanded = false
            }
            onUpPressed: resultsList.moveUp()
            onDownPressed: resultsList.moveDown()
            onTabPressedSignal: popupContent.cycleFocusSection(true)
            onShiftTabPressedSignal: popupContent.cycleFocusSection(false)
            onViewModeChangeRequested: (mode) => popupContent.changeViewMode(mode)
            
            Connections {
                target: mainRoot
                function onExpandedChanged() {
                    if (mainRoot.expanded && mainRoot.isButtonMode) {
                        buttonModeSearchInput.focusInput()
                        buttonModeSearchInput.setText(mainRoot.searchText)
                    }
                }
            }
        }
        
        // ===== PRIMARY RESULT PREVIEW (Calculator) =====
        Components.PrimaryResultPreview {
            id: primaryResultPreview
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            
            resultsModel: resultsModel
            resultCount: resultsList.count
            searchText: mainRoot.searchText
            accentColor: mainRoot.accentColor
            textColor: mainRoot.textColor
            
            onResultClicked: (idx, display, decoration, category) => {
                mainRoot.addToHistory(display, decoration, category, display, "", "calculator", mainRoot.searchText)
                resultsModel.run(idx)
                mainRoot.searchText = ""
                mainRoot.expanded = false
            }
        }
        
        // ===== QUERY HINTS (KRunner Syntax) =====
        Components.QueryHints {
            id: queryHints
            anchors.top: primaryResultPreview.visible ? primaryResultPreview.bottom : parent.top
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            
            searchText: mainRoot.searchText
            textColor: mainRoot.textColor
            accentColor: mainRoot.accentColor
            bgColor: mainRoot.bgColor
            trFunc: mainRoot.tr
        }
        
        // ===== RESULTS LIST VIEW =====
        Components.ResultsListView {
            id: resultsList
            anchors.top: queryHints.visible ? queryHints.bottom : (primaryResultPreview.visible ? primaryResultPreview.bottom : parent.top)
            anchors.topMargin: (queryHints.visible || primaryResultPreview.visible) ? 8 : 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: mainRoot.isButtonMode ? buttonModeSearchInput.top : parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: mainRoot.isButtonMode ? 6 : 12
            
            visible: !mainRoot.isTileView && mainRoot.searchText.length > 0
            
            resultsModel: resultsModel
            listIconSize: mainRoot.listIconSize
            textColor: mainRoot.textColor
            accentColor: mainRoot.accentColor
            trFunc: mainRoot.tr
            searchText: mainRoot.searchText
            
            onItemClicked: (index, display, decoration, category, matchId, filePath) => {
                mainRoot.addToHistory(display, decoration, category, matchId, filePath, null, mainRoot.searchText)
                var idx = resultsModel.index(index, 0)
                resultsModel.run(idx)
                mainRoot.searchText = ""
                mainRoot.expanded = false
            }
        }
        
        // ===== HISTORY CONTAINER =====
        Item {
            id: historyContainer
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: mainRoot.isButtonMode ? buttonModeSearchInput.top : parent.bottom
            anchors.margins: 12
            anchors.bottomMargin: mainRoot.isButtonMode ? 6 : 12
            visible: mainRoot.searchText.length === 0 && mainRoot.searchHistory.length > 0
            
            property var categorizedHistory: HistoryManager.categorizeHistory(mainRoot.searchHistory, mainRoot.tr("applications"), mainRoot.tr("other"))
            
            // History List View
            Components.HistoryListView {
                anchors.fill: parent
                visible: !mainRoot.isTileView
                
                categorizedHistory: historyContainer.categorizedHistory
                listIconSize: mainRoot.listIconSize
                textColor: mainRoot.textColor
                accentColor: mainRoot.accentColor
                formatTimeFunc: mainRoot.formatHistoryTime
                trFunc: mainRoot.tr
                
                onItemClicked: (item) => handleHistoryItemClick(item)
                onClearClicked: {
                    mainRoot.clearHistory()
                    historyContainer.categorizedHistory = []
                }
            }
            
            // History Tile View - LAZY LOADED
            Loader {
                id: historyTileLoader
                anchors.fill: parent
                active: mainRoot.isTileView
                
                sourceComponent: Components.HistoryTileView {
                    categorizedHistory: historyContainer.categorizedHistory
                    iconSize: mainRoot.iconSize
                    textColor: mainRoot.textColor
                    accentColor: mainRoot.accentColor
                    trFunc: mainRoot.tr
                    
                    onItemClicked: (item) => handleHistoryItemClick(item)
                    onClearClicked: {
                        mainRoot.clearHistory()
                        historyContainer.categorizedHistory = []
                    }
                    
                    onTabPressed: popupContent.cycleFocusSection(true)
                    onShiftTabPressed: popupContent.cycleFocusSection(false)
                    onViewModeChangeRequested: (mode) => popupContent.changeViewMode(mode)
                }
            }
            
            // Shared history item click handler
            function handleHistoryItemClick(item) {
                // For files, open directly
                if (item.filePath && item.filePath.toString().length > 0) {
                    Qt.openUrlExternally(item.filePath)
                    mainRoot.expanded = false
                    return
                }
                
                // For apps and other items, search and run
                var searchTerm = item.queryText || item.display || ""
                mainRoot.searchText = searchTerm
                if (!mainRoot.isButtonMode) {
                    hiddenSearchInput.text = searchTerm
                } else {
                    buttonModeSearchInput.setText(searchTerm)
                }
                historyRunTimer.start()
            }
            
            Timer {
                id: historyRunTimer
                interval: 400
                repeat: false
                onTriggered: {
                    if (resultsList.count > 0) {
                        var idx = resultsModel.index(0, 0)
                        resultsModel.run(idx)
                        mainRoot.searchText = ""
                        mainRoot.expanded = false
                    }
                }
            }
        }
        
        // ===== TILE VIEW FOR RESULTS =====
        // ===== TILE VIEW - LAZY LOADED =====
        Loader {
            id: tileResultsLoader
            anchors.fill: parent
            anchors.margins: 12
            active: mainRoot.isTileView && mainRoot.searchText.length > 0
            
            sourceComponent: Components.ResultsTileView {
                id: tileResults
                
                categorizedData: popupContent.categorizedData
                iconSize: mainRoot.iconSize
                textColor: mainRoot.textColor
                accentColor: mainRoot.accentColor
                trFunc: mainRoot.tr
                searchText: mainRoot.searchText
                
                onItemClicked: (index, display, decoration, category, matchId, filePath) => {
                    mainRoot.addToHistory(display, decoration, category, matchId, filePath, null, mainRoot.searchText)
                    var idx = resultsModel.index(index, 0)
                    resultsModel.run(idx)
                    mainRoot.searchText = ""
                    mainRoot.expanded = false
                }
                
                onTabPressed: popupContent.cycleFocusSection(true)
                onShiftTabPressed: popupContent.cycleFocusSection(false)
                onViewModeChangeRequested: (mode) => popupContent.changeViewMode(mode)
            }
        }
        
        // ===== DATA EXTRACTION FOR TILE VIEW =====
        property var categorizedData: []
        
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

        Repeater {
            id: rawDataProxy
            model: resultsModel
            visible: false
            delegate: Item {
                property int itemIndex: index
                property var category: model.category || ""
                property var display: model.display || ""
                property var decoration: model.decoration || ""
                property var url: model.url || ""
                property var duplicateId: model.duplicateId || ""
            }
            onCountChanged: popupContent.refreshGroups()
        }
        
        // ===== EMPTY STATE =====
        Text {
            anchors.centerIn: parent
            text: mainRoot.tr("type_to_search")
            color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.5)
            font.pixelSize: 12
            visible: mainRoot.searchText.length === 0 && mainRoot.searchHistory.length === 0
        }
        
        // ===== AUTO-FOCUS ON POPUP OPEN =====
        Component.onCompleted: {
            if (!mainRoot.isButtonMode) {
                hiddenSearchInput.focus()
            }
        }
        
        Connections {
            target: mainRoot
            function onExpandedChanged() {
                if (mainRoot.expanded && !mainRoot.isButtonMode) {
                    hiddenSearchInput.clearAndFocus()
                    resultsList.currentIndex = 0
                } else if (!mainRoot.expanded) {
                    mainRoot.searchText = ""
                }
            }
        }
    }
    
    // Start with compact representation
    preferredRepresentation: compactRepresentation
}
