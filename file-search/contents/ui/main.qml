import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou
import org.kde.plasma.plasma5support as Plasma5Support

// Import localization data
import "js/localization.js" as LocalizationData

// Import utility modules
import "js/utils.js" as Utils
import "js/HistoryManager.js" as HistoryManager
import "js/TelemetryManager.js" as TelemetryManager
import "js/PinnedManager.js" as PinnedManager
import "js/CategoryManager.js" as CategoryManager
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
    
    // Signals
    signal historyForceUpdate()
    
    // ===== THEME COLORS =====
    readonly property color bgColor: Kirigami.Theme.backgroundColor
    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color accentColor: Kirigami.Theme.highlightColor
    
    // ===== HISTORY MANAGEMENT =====
    property var searchHistory: []
    readonly property int maxHistoryItems: 20
    
    // ===== PINNED ITEMS MANAGEMENT =====
    property var pinnedItems: []
    property string currentActivityId: "global" // Can be connected to KActivities later
    
    // ===== CATEGORY SETTINGS =====
    property var categorySettings: {}


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
        console.log("FileSearch [History]: Loading history...")
        searchHistory = HistoryManager.loadHistory(Plasmoid.configuration.searchHistory)
    }
    
    function saveHistory() {
        Plasmoid.configuration.searchHistory = JSON.stringify(searchHistory)
    }
    
    function addToHistory(display, decoration, category, matchId, filePath, sourceType, queryText) {
        searchHistory = HistoryManager.addToHistory(searchHistory, display, decoration, category, matchId, filePath, sourceType, queryText, Plasmoid.configuration.maxHistoryItems)
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
    
    Timer {
        id: iconCheckTimer
        interval: 500
        repeat: false
        property string uuid
        property string filePath
        property string decoration
        property string category
        
        onTriggered: {
            if (!uuid) return
            
            // Only check if it has a file path
            if (filePath && filePath.toString().indexOf("file://") === 0) {
                // Milou returns QIcon object which renders as "QIcon()" string in QML.
                // We cannot extract the icon name from it directly.
                // So we fallback to checking .directory file for custom folder icons.
                if (decoration === "QIcon()" || decoration === "") {
                    // Set default folder icon temporarily if it's likely a folder
                    if (isFolder) {
                        HistoryManager.updateItemIcon(searchHistory, uuid, "folder");
                        saveHistory();
                        historyForceUpdate();
                    }
                    
                    // Try to fetch custom icon from .directory file
                    // Pass 'root' (id:root) as explicit context if needed, but functions in root scope see it.
                    fetchDirectoryIcon(filePath, uuid);
                }
            }
        }
    }

    // Map to store pending icon requests: command -> uuid
    property var pendingIconRequests: ({})

    Plasma5Support.DataSource {
        id: executableDataSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            console.log("FileSearch [Icon]: Data received for command:", sourceName)
            var uuid = root.pendingIconRequests[sourceName]
            if (uuid) {
                var output = data["stdout"]
                var exitCode = data["exit code"]
                
                if (output && output.toString().trim().length > 0) {
                    var iconName = output.toString().trim()
                    console.log("FileSearch [Icon]: Found custom icon via kreadconfig:", iconName, "for UUID:", uuid)
                    
                    if (HistoryManager.updateItemIcon(root.searchHistory, uuid, iconName)) {
                        root.saveHistory()
                        root.historyForceUpdate()
                    }
                } else {
                    console.log("FileSearch [Icon]: No icon found or empty output. Exit code:", exitCode)
                }
                
                disconnectSource(sourceName)
                delete root.pendingIconRequests[sourceName]
            }
        }
    }

    function fetchDirectoryIcon(folderPath, uuid) {
         if (!folderPath || folderPath.toString().indexOf("file://") !== 0) return;
         
         var path = folderPath.toString().substring(7); // Remove file://
         // Remove trailing slash if exists
         if (path.length > 1 && path.slice(-1) === "/") path = path.slice(0, -1);
         
         // Command to read Icon key from Desktop Entry group in .directory file
         // kreadconfig6 --file "/path/to/.directory" --group "Desktop Entry" --key Icon
         var configFile = path + "/.directory"
         var cmd = "kreadconfig6 --file '" + configFile + "' --group 'Desktop Entry' --key Icon"
         
         console.log("FileSearch [Icon]: Fetching icon for", path, "UUID:", uuid)
         console.log("FileSearch [Icon]: Command:", cmd)
         
         root.pendingIconRequests[cmd] = uuid
         executableDataSource.connectSource(cmd)
    }
    
    function formatHistoryTime(timestamp) {
        return Utils.formatHistoryTime(timestamp, root.tr)
    }
    
    function clearHistory() {
        searchHistory = HistoryManager.clearHistory()
        saveHistory()
    }
    
    // ===== PINNED FUNCTIONS (delegated to PinnedManager) =====
    function loadPinned() {
        console.log("FileSearch [Pinned]: Loading pinned items...")
        pinnedItems = PinnedManager.loadPinned(Plasmoid.configuration.pinnedItems)
    }
    
    function savePinned() {
        Plasmoid.configuration.pinnedItems = PinnedManager.savePinned(pinnedItems)
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
    
    // ===== CATEGORY SETTINGS FUNCTIONS (delegated to CategoryManager) =====
    function loadCategorySettings() {
        console.log("FileSearch [Category]: Loading category settings...")
        categorySettings = CategoryManager.loadCategorySettings(Plasmoid.configuration.categorySettings)
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

    // ===== INITIALIZATION =====
    Component.onCompleted: {
        loadHistory()
        loadPinned()
        loadCategorySettings()
        // Locale data is now synchronously loaded via import
    }

    // ===== CONTEXTUAL ACTIONS (Right-Click Menu) =====
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.tr("button_mode")
            checkable: true
            checked: root.displayMode === 0
            onTriggered: Plasmoid.configuration.displayMode = 0
        },
        PlasmaCore.Action {
            text: root.tr("medium_mode")
            checkable: true
            checked: root.displayMode === 1
            onTriggered: Plasmoid.configuration.displayMode = 1
        },
        PlasmaCore.Action {
            text: root.tr("wide_mode")
            checkable: true
            checked: root.displayMode === 2
            onTriggered: Plasmoid.configuration.displayMode = 2
        },
        PlasmaCore.Action {
            text: root.tr("extra_wide_mode")
            checkable: true
            checked: root.displayMode === 3
            onTriggered: Plasmoid.configuration.displayMode = 3
        }
    ]

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
        
        // ===== TELEMETRY & DEBUG =====
        property var telemetryStats: TelemetryManager.getStatsObject(Plasmoid.configuration.telemetryData || "{}")
        property int lastSearchLatency: 0
        property string activeBackend: "Milou"
        property real searchStartTime: 0

        function updateTelemetry(latency) {
            var newData = TelemetryManager.recordSearch(Plasmoid.configuration.telemetryData || "{}", latency)
            Plasmoid.configuration.telemetryData = newData
            telemetryStats = TelemetryManager.getStatsObject(newData)
        }
        
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
            
            onTextUpdated: (newText) => { 
                console.log("FileSearch [HiddenInput]: Text updated to:", newText)
                popupContent.searchStartTime = new Date().getTime()
                mainRoot.searchText = newText 
            }
            onSearchSubmitted: (idx) => {
                console.log("FileSearch [HiddenInput]: Search submitted for index:", idx)
                if (resultsList.count > 0) {
                    var modelIdx = resultsModel.index(idx, 0)
                    var display = resultsModel.data(modelIdx, Qt.DisplayRole) || ""
                    var decoration = resultsModel.data(modelIdx, Qt.DecorationRole) || "application-x-executable"
                    var category = resultsModel.data(modelIdx, resultsModel.CategoryRole) || "Diğer"
                    var matchId = resultsModel.data(modelIdx, resultsModel.DuplicateRole) || display
                    
                    // Fetch URL from proxy
                    var proxyItem = rawDataProxy.itemAt(idx)
                    var rawUrl = proxyItem ? ((proxyItem.url && proxyItem.url.toString) ? proxyItem.url.toString() : (proxyItem.url || "")) : ""
                    var subtext = proxyItem ? ((proxyItem.subtext && proxyItem.subtext.toString) ? proxyItem.subtext.toString() : "") : ""
                    var urls = proxyItem ? (proxyItem.urls || []) : []

                    // Fallback to urls list if url is empty
                    if (rawUrl === "" && urls.length > 0) {
                        rawUrl = urls[0].toString()
                    }
                    
                    // Fallback to subtext if url is empty and subtext looks like path
                    if (rawUrl === "") {
                        if (subtext.indexOf("/") === 0) rawUrl = "file://" + subtext
                        else if (subtext.indexOf("file://") === 0) rawUrl = subtext
                    }
                    
                    root.addToHistory(display, decoration, category, matchId, rawUrl, null, root.searchText)
                    
                    if (rawUrl.length > 0) {
                        Qt.openUrlExternally(rawUrl)
                    } else {
                        console.log("FileSearch: Running resultsModel for index:", modelIdx)
                        resultsModel.run(modelIdx)
                    }
                    root.searchText = ""
                    root.expanded = false
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
                console.log("FileSearch [ButtonInput]: Search submitted for text:", text, "index:", selectedIndex)
                if (resultsList.count > 0) {
                    var idx = resultsModel.index(selectedIndex, 0)
                    var display = resultsModel.data(idx, Qt.DisplayRole) || ""
                    var decoration = resultsModel.data(idx, Qt.DecorationRole) || "application-x-executable"
                    var category = resultsModel.data(idx, resultsModel.CategoryRole) || "Diğer"
                    var matchId = resultsModel.data(idx, resultsModel.DuplicateRole) || display
                    
                    // Fetch URL from proxy
                    var proxyItem = rawDataProxy.itemAt(selectedIndex)
                    var rawUrl = proxyItem ? ((proxyItem.url && proxyItem.url.toString) ? proxyItem.url.toString() : (proxyItem.url || "")) : ""
                    var subtext = proxyItem ? ((proxyItem.subtext && proxyItem.subtext.toString) ? proxyItem.subtext.toString() : "") : ""
                    var urls = proxyItem ? (proxyItem.urls || []) : []

                    // Fallback to urls list if url is empty
                    if (rawUrl === "" && urls.length > 0) {
                        rawUrl = urls[0].toString()
                    }
                    
                    // Fallback to subtext
                    if (rawUrl === "") {
                        if (subtext.indexOf("/") === 0) rawUrl = "file://" + subtext
                        else if (subtext.indexOf("file://") === 0) rawUrl = subtext
                    }
                    
                    root.addToHistory(display, decoration, category, matchId, rawUrl, null, root.searchText)
                    
                    if (rawUrl.length > 0) {
                        Qt.openUrlExternally(rawUrl)
                    } else {
                        console.log("FileSearch: Running resultsModel for index:", idx)
                        resultsModel.run(idx)
                    }
                    root.searchText = ""
                    buttonModeSearchInput.clear()
                    root.expanded = false
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
                console.log("FileSearch [PrimaryPreview]: Result clicked, running index:", idx)
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
        
        // ===== PINNED SECTION =====
        Components.PinnedSection {
            id: pinnedSection
            anchors.top: queryHints.visible ? queryHints.bottom : (primaryResultPreview.visible ? primaryResultPreview.bottom : parent.top)
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            
            visible: mainRoot.getVisiblePinnedItems().length > 0
            pinnedItems: mainRoot.getVisiblePinnedItems()
            textColor: mainRoot.textColor
            accentColor: mainRoot.accentColor
            iconSize: mainRoot.iconSize
            isTileView: mainRoot.isTileView
            trFunc: mainRoot.tr
            
            onItemClicked: (item) => {
                console.log("FileSearch [Pinned]: Item clicked:", item.display)
                // Open pinned item
                if (item.filePath && item.filePath.length > 0) {
                    Qt.openUrlExternally(item.filePath)
                } else {
                    // Search and run
                    mainRoot.searchText = item.display
                    if (!mainRoot.isButtonMode) {
                        hiddenSearchInput.text = item.display
                    } else {
                        buttonModeSearchInput.setText(item.display)
                    }
                    Qt.callLater(function() {
                        if (resultsList.count > 0) {
                            var idx = resultsModel.index(0, 0)
                            console.log("FileSearch [Pinned]: Running resultsModel for index 0")
                            resultsModel.run(idx)
                        }
                    })
                }
                mainRoot.expanded = false
            }
            
            onUnpinClicked: (matchId) => {
                mainRoot.unpinItem(matchId)
            }
        }
        
        // ===== RESULTS LIST VIEW =====
        Components.ResultsListView {
            id: resultsList
            anchors.top: pinnedSection.visible ? pinnedSection.bottom : (queryHints.visible ? queryHints.bottom : (primaryResultPreview.visible ? primaryResultPreview.bottom : parent.top))
            anchors.topMargin: pinnedSection.visible ? 8 : ((queryHints.visible || primaryResultPreview.visible) ? 8 : 12)
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
            
            // Pin support
            property var isPinnedFunc: mainRoot.isPinned
            property var togglePinFunc: mainRoot.togglePin
            
            onItemClicked: (index, display, decoration, category, matchId, filePath) => {
                console.log("FileSearch [ResultsList]: Item clicked at index:", index, "Display:", display)
                
                // Fallback inside Handler if UI didn't catch it
                if (!filePath || filePath === "") {
                     var mIdx = resultsModel.index(index, 0)
                     // Try to fetch from model custom roles if needed (omitted for clean code as we rely on UI Logic)
                }

                root.addToHistory(display, decoration, category, matchId, filePath, null, root.searchText)
                
                if (filePath && filePath.length > 0) {
                    Qt.openUrlExternally(filePath)
                } else {
                    var idx = resultsModel.index(index, 0)
                    console.log("FileSearch: Running resultsModel for index:", idx)
                    resultsModel.run(idx)
                }
                root.searchText = ""
                root.expanded = false
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
            
            property var categorizedHistory: []
            
            Connections {
                target: root
                function onSearchHistoryChanged() {
                    historyContainer.updateHistory()
                }
                function onHistoryForceUpdate() {
                    historyContainer.updateHistory()
                }
            }
            
            function updateHistory() {
                categorizedHistory = HistoryManager.categorizeHistory(mainRoot.searchHistory, mainRoot.tr("applications"), mainRoot.tr("other"))
            }
            
            Component.onCompleted: updateHistory()
            
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
                
                onItemClicked: (item) => historyContainer.handleHistoryItemClick(item)
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
                    
                    onItemClicked: (item) => historyContainer.handleHistoryItemClick(item)
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
                // Use display name as search term to ensure we find the specific item again
                // (queryText might be too broad, e.g. "c" -> "CMake" instead of "Calculator")
                var searchTerm = item.display || item.queryText || ""
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
                        console.log("FileSearch [HistoryTimer]: Running resultsModel for index 0")
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
                    console.log("FileSearch [ResultsTile]: Item clicked at index:", index, "Display:", display)
                    root.addToHistory(display, decoration, category, matchId, filePath, null, root.searchText)
                    
                    if (filePath && filePath.length > 0) {
                        Qt.openUrlExternally(filePath)
                    } else {
                        var idx = resultsModel.index(index, 0)
                        console.log("FileSearch: Running resultsModel for index:", idx)
                        resultsModel.run(idx)
                    }
                    root.searchText = ""
                    root.expanded = false
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
            onTriggered: popupContent.refreshGroups()
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
                property var urls: model.urls || []
                property var subtext: model.subtext || ""
                property var duplicateId: model.duplicateId || ""
            }
            onCountChanged: {
                console.log("FileSearch [Repeater]: Result count changed to:", count)
                refreshDebouncer.restart()
                
                // Latency Measurement
                if (popupContent.searchStartTime > 0) {
                    var now = new Date().getTime()
                    var latency = now - popupContent.searchStartTime
                    if (latency > 0 && latency < 5000) {
                        popupContent.lastSearchLatency = latency
                        popupContent.updateTelemetry(latency)
                        popupContent.searchStartTime = 0
                    }
                }
            }
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
            if (!mainRoot.isButtonMode && hiddenSearchInput) {
                hiddenSearchInput.forceActiveFocus()
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
        
        // ===== DEBUG OVERLAY =====
        Components.DebugOverlay {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            z: 9999
            visible: Plasmoid.configuration.debugOverlay && (Plasmoid.configuration.userProfile === 1)
            
            resultCount: resultsList.count
            activeBackend: popupContent.activeBackend
            lastLatency: popupContent.lastSearchLatency
            viewModeName: mainRoot.isTileView ? "Tile" : "List"
            displayModeName: mainRoot.isButtonMode ? "Button" : (mainRoot.isMediumMode ? "Medium" : (mainRoot.isWideMode ? "Wide" : "Extra Wide"))
            
            totalSearches: popupContent.telemetryStats.totalSearches || 0
            avgLatency: popupContent.telemetryStats.averageLatency || 0
            tr: mainRoot.tr
        }
    }
    
    // Start with compact representation
    preferredRepresentation: compactRepresentation
}
