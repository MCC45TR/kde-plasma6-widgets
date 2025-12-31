import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou

PlasmoidItem {
    id: root

    // Fix: Add searchText property to resolve undefined errors
    property string searchText: ""

    // Responsive font size based on height (40% of panel height)
    readonly property int responsiveFontSize: Math.max(10, Math.round(height * 0.4))
    
    // Configuration: 0 = Button, 1 = Medium, 2 = Wide, 3 = Extra Wide
    readonly property int displayMode: Plasmoid.configuration.displayMode
    readonly property bool isButtonMode: displayMode === 0
    readonly property bool isMediumMode: displayMode === 1
    readonly property bool isWideMode: displayMode === 2
    readonly property bool isExtraWideMode: displayMode === 3

    // Calculate minimum width needed for text
    readonly property real textContentWidth: isButtonMode ? 0 : (textMetrics.width + ((isWideMode || isExtraWideMode) ? (height + 30) : 20))
    // Base width based on mode
    readonly property real baseWidth: isButtonMode ? height : (isExtraWideMode ? (height * 6) : ((isWideMode) ? (height * 4) : 70))
    
    // Panel constraints - width adapts to text if needed
    Layout.preferredWidth: Math.max(baseWidth, textContentWidth)
    Layout.preferredHeight: 38
    Layout.minimumWidth: 50
    Layout.minimumHeight: 34
    
    // Character limits
    readonly property int maxCharsWide: 65
    readonly property int maxCharsMedium: 35
    readonly property int maxChars: isWideMode ? maxCharsWide : maxCharsMedium
    
    // Truncated text for display
    readonly property string placeholderText: isExtraWideMode ? "Arama yapmaya başla..." : (isWideMode ? "Arama yap..." : "Ara")
    readonly property string rawSearchText: searchText.length > 0 ? searchText : placeholderText
    readonly property string truncatedText: rawSearchText.length > maxChars ? rawSearchText.substring(0, maxChars) + "..." : rawSearchText
    
    // TextMetrics to measure TRUNCATED text width
    TextMetrics {
        id: textMetrics
        font.family: "Roboto Condensed"
        font.pixelSize: root.responsiveFontSize
        text: root.truncatedText
    }
    
    // No background - transparent
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    // View Mode: 0 = List, 1 = Tile
    readonly property int viewMode: Plasmoid.configuration.viewMode
    readonly property bool isTileView: viewMode === 1
    
    // Icon size for tile view (default 48 if undefined/0)
    readonly property int iconSize: Math.max(16, Plasmoid.configuration.iconSize || 48)
    
    // Icon size for list view (default 22 if undefined/0)
    readonly property int listIconSize: Math.max(16, Plasmoid.configuration.listIconSize || 22)
    
    // System theme colors
    readonly property color bgColor: Kirigami.Theme.backgroundColor
    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color accentColor: Kirigami.Theme.highlightColor
    
    // Search History (max 20 items)
    property var searchHistory: []
    readonly property int maxHistoryItems: 20
    
    // Load history from config on startup
    Component.onCompleted: {
        loadHistory()
    }
    
    function loadHistory() {
        try {
            var historyStr = Plasmoid.configuration.searchHistory || "[]"
            searchHistory = JSON.parse(historyStr)
        } catch (e) {
            searchHistory = []
        }
    }
    
    function saveHistory() {
        Plasmoid.configuration.searchHistory = JSON.stringify(searchHistory)
    }
    
    function addToHistory(display, decoration, category, matchId, filePath) {
        // Check if already exists (by matchId or display)
        for (var i = 0; i < searchHistory.length; i++) {
            var existing = searchHistory[i]
            if ((matchId && existing.matchId === matchId) || existing.display === display) {
                // Move to top and update timestamp
                var item = searchHistory.splice(i, 1)[0]
                item.timestamp = Date.now()
                searchHistory.unshift(item)
                saveHistory()
                return
            }
        }
        // Determine if it's an application
        var isApp = category === "Uygulamalar" || category === "Applications"
        // Add new item with all data needed for direct open
        searchHistory.unshift({
            display: display,
            decoration: decoration || "application-x-executable",
            category: category || "Diğer",
            isApplication: isApp,
            matchId: matchId || "",
            filePath: filePath || "",
            timestamp: Date.now()
        })
        // Limit to max items
        if (searchHistory.length > maxHistoryItems) {
            searchHistory = searchHistory.slice(0, maxHistoryItems)
        }
        saveHistory()
    }
    
    function formatHistoryTime(timestamp) {
        if (!timestamp) return ""
        
        var now = new Date()
        var then = new Date(timestamp)
        var diffMs = now.getTime() - then.getTime()
        var diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
        
        var hours = then.getHours().toString().padStart(2, '0')
        var minutes = then.getMinutes().toString().padStart(2, '0')
        var timeStr = hours + ":" + minutes
        
        // Today
        if (now.toDateString() === then.toDateString()) {
            return "Bugün " + timeStr
        }
        
        // Within last 6 days
        if (diffDays < 6) {
            var days = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
            return days[then.getDay()] + " " + timeStr
        }
        
        // Older than 6 days
        var day = then.getDate()
        var month = then.getMonth() + 1
        var year = then.getFullYear()
        return day + "." + month + "." + year + " " + timeStr
    }
    
    function clearHistory() {
        searchHistory = []
        saveHistory()
    }
    

    
    // Panel representation - just displays, click opens popup
    compactRepresentation: Item {
        id: compactRep
        anchors.fill: parent
        
        // Button Mode - icon only (no background)
        Kirigami.Icon {
            id: buttonModeIcon
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            source: "plasma-search"
            color: root.textColor
            visible: root.isButtonMode
            
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onEntered: buttonModeIcon.color = root.accentColor
                onExited: buttonModeIcon.color = root.textColor
                
                onClicked: {
                    root.expanded = !root.expanded
                }
            }
        }
        
        // Main Button Container (for non-button modes)
        Rectangle {
            id: mainButton
            anchors.fill: parent
            anchors.margins: 0
            radius: height / 2
            color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.95)
            visible: !root.isButtonMode
            
            // Border for definition
            border.width: 1
            border.color: root.expanded ? root.accentColor : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 4
                spacing: 6
                
                // Display text (not editable - shows placeholder or search text)
                Text {
                    id: displayText
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.truncatedText
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, root.searchText.length > 0 ? 1.0 : 0.6)
                    font.pixelSize: root.responsiveFontSize
                    font.family: "Roboto Condensed"
                    horizontalAlignment: (root.isWideMode || root.isExtraWideMode) ? Text.AlignLeft : Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                
                // Search Icon Button (Wide and Extra Wide Mode only)
                Rectangle {
                    id: searchIconButton
                    Layout.preferredWidth: (root.isWideMode || root.isExtraWideMode) ? (mainButton.height - 6) : 0
                    Layout.preferredHeight: mainButton.height - 6
                    Layout.alignment: Qt.AlignVCenter
                    radius: width / 2
                    color: root.accentColor
                    visible: root.isWideMode || root.isExtraWideMode
                    
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.55
                        height: width
                        source: "search"
                        color: "#ffffff"
                    }
                }
            }
            
            // Click handler - opens popup
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onEntered: mainButton.color = Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 1.0)
                onExited: mainButton.color = Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.95)
                
                onClicked: {
                    root.expanded = !root.expanded
                }
            }
        }
    }
    
    // Search Popup - has hidden input field that captures keyboard focus
    fullRepresentation: Item {
        id: popupContent
        
        Layout.preferredWidth: 500
        Layout.preferredHeight: 380
        Layout.minimumWidth: 400
        Layout.minimumHeight: 250
        
        // Local references to avoid ReferenceError
        readonly property var mainRoot: root
        readonly property color delegateTextColor: mainRoot.textColor
        readonly property color delegateAccentColor: mainRoot.accentColor
        
        // Hidden TextField that captures keyboard input
        TextField {
            id: hiddenSearchInput
            width: 1
            height: 1
            opacity: 0
            activeFocusOnPress: true
            text: mainRoot.searchText
            
            onTextChanged: {
                mainRoot.searchText = text
            }
            
            onAccepted: {
                if (resultsList.count > 0) {
                    var currentIdx = resultsList.currentIndex >= 0 ? resultsList.currentIndex : 0
                    var idx = resultsModel.index(currentIdx, 0)
                    // Get item data for history
                    var display = resultsModel.data(idx, Qt.DisplayRole) || ""
                    var decoration = resultsModel.data(idx, Qt.DecorationRole) || "application-x-executable"
                    var category = resultsModel.data(idx, resultsModel.CategoryRole) || "Diğer"
                    // Get matchId from DuplicateRole for direct open later
                    var matchId = resultsModel.data(idx, resultsModel.DuplicateRole) || display
                    mainRoot.addToHistory(display, decoration, category, matchId, "")
                    resultsModel.run(idx)
                    mainRoot.searchText = ""
                    mainRoot.expanded = false
                }
            }
            
            Keys.onEscapePressed: {
                mainRoot.searchText = ""
                text = ""
                mainRoot.expanded = false
            }
            
            // Arrow key navigation
            Keys.onDownPressed: {
                if (resultsList.currentIndex < resultsList.count - 1) {
                    resultsList.currentIndex++
                }
            }
            
            Keys.onUpPressed: {
                if (resultsList.currentIndex > 0) {
                    resultsList.currentIndex--
                }
            }
        }
        
        // Search results model - uses KRunner runners (all features)
        Milou.ResultsModel {
            id: resultsModel
            queryString: mainRoot.searchText
            limit: 50
            // KRunner runners are automatically included
        }
        
        // Results Area - List or Tile view based on configuration
        ScrollView {
            id: resultsScroll
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            
            // Hide scrollbar
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            
            // LIST VIEW
            ListView {
                id: resultsList
                model: resultsModel
                spacing: 2
                currentIndex: 0
                visible: !popupContent.mainRoot.isTileView
                
                highlight: Rectangle {
                    color: Qt.rgba(popupContent.delegateAccentColor.r, popupContent.delegateAccentColor.g, popupContent.delegateAccentColor.b, 0.2)
                    radius: 4
                }
                highlightFollowsCurrentItem: true
                
                // Category section header
                section.property: "category"
                section.delegate: Item {
                    width: resultsList.width
                    height: 28
                    
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: section
                        font.pixelSize: 11
                        font.bold: true
                        color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.6)
                    }
                }
                
                delegate: Rectangle {
                    id: resultItem
                    width: resultsList.width
                    height: Math.max(44, popupContent.mainRoot.listIconSize + 18)
                    color: resultMouseArea.containsMouse ? Qt.rgba(popupContent.delegateAccentColor.r, popupContent.delegateAccentColor.g, popupContent.delegateAccentColor.b, 0.15) : "transparent"
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10
                        
                        // Icon
                        Kirigami.Icon {
                            source: model.decoration || "application-x-executable"
                            Layout.preferredWidth: popupContent.mainRoot.listIconSize
                            Layout.preferredHeight: popupContent.mainRoot.listIconSize
                            color: popupContent.delegateTextColor
                        }
                        
                        // Result text with optional parent folder
                        Column {
                            Layout.fillWidth: true
                            spacing: 1
                            
                            Text {
                                text: model.display || ""
                                color: popupContent.delegateTextColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            
                            // Parent folder for files (shown only for file-like categories)
                            Text {
                                visible: {
                                    var cat = model.category || ""
                                    var isFileCategory = cat.indexOf("Dosya") >= 0 || cat.indexOf("Klasör") >= 0 || 
                                                        cat.indexOf("File") >= 0 || cat.indexOf("Folder") >= 0 ||
                                                        cat.indexOf("Document") >= 0 || cat.indexOf("Belge") >= 0
                                    return isFileCategory && model.url && model.url.toString().length > 0
                                }
                                text: {
                                    if (!model.url) return ""
                                    var path = model.url.toString()
                                    if (path.startsWith("file://")) path = path.substring(7)
                                    var lastSlash = path.lastIndexOf("/")
                                    if (lastSlash > 0) {
                                        return path.substring(0, lastSlash)
                                    }
                                    return ""
                                }
                                color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.5)
                                font.pixelSize: 10
                                elide: Text.ElideMiddle
                                width: parent.width
                            }
                        }
                    }
                    
                    MouseArea {
                        id: resultMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            // Add to history - use duplicateId as matchId and url as filePath
                            var matchId = model.duplicateId || model.display || ""
                            var filePath = model.url || ""
                            mainRoot.addToHistory(model.display || "", model.decoration || "application-x-executable", model.category || "Diğer", matchId, filePath)
                            var idx = resultsModel.index(index, 0)
                            resultsModel.run(idx)
                            mainRoot.searchText = ""
                            mainRoot.expanded = false
                        }
                    }
                }
                
                // Empty state for list (only when no history)
                Text {
                    anchors.centerIn: parent
                    text: mainRoot.searchText.length > 0 ? "Sonuç bulunamadı" : "Aramak için yazmaya başlayın"
                    color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.5)
                    font.pixelSize: 12
                    visible: resultsList.count === 0 && !popupContent.mainRoot.isTileView && mainRoot.searchText.length > 0
                }
            }
        }
        
        // History View - shown when no search text and history exists
        Item {
            id: historyContainer
            anchors.fill: parent
            anchors.margins: 12
            visible: mainRoot.searchText.length === 0 && mainRoot.searchHistory.length > 0
            
            // Categorized history data
            property var categorizedHistory: []
            
            function refreshHistoryGroups() {
                var apps = []
                var others = []
                
                for (var i = 0; i < mainRoot.searchHistory.length; i++) {
                    var item = mainRoot.searchHistory[i]
                    if (item.isApplication) {
                        apps.push(item)
                    } else {
                        others.push(item)
                    }
                }
                
                var result = []
                if (apps.length > 0) {
                    result.push({ categoryName: "Uygulamalar", items: apps })
                }
                if (others.length > 0) {
                    result.push({ categoryName: "Diğer", items: others })
                }
                categorizedHistory = result
            }
            
            Component.onCompleted: refreshHistoryGroups()
            
            onVisibleChanged: {
                if (visible) {
                    refreshHistoryGroups()
                }
            }
            
            // Header with title and clear button
            RowLayout {
                id: historyHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 32
                
                Text {
                    text: "Son Aramalar"
                    font.pixelSize: 13
                    font.bold: true
                    color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.7)
                    Layout.fillWidth: true
                }
                
                // Clear History Button
                Rectangle {
                    id: clearHistoryBtn
                    Layout.preferredWidth: clearBtnText.implicitWidth + 16
                    Layout.preferredHeight: 26
                    radius: 4
                    color: clearHistoryMouseArea.containsMouse ? Qt.rgba(popupContent.delegateAccentColor.r, popupContent.delegateAccentColor.g, popupContent.delegateAccentColor.b, 0.2) : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.2)
                    
                    Text {
                        id: clearBtnText
                        anchors.centerIn: parent
                        text: "Geçmişi Sil"
                        font.pixelSize: 11
                        color: popupContent.delegateTextColor
                    }
                    
                    MouseArea {
                        id: clearHistoryMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            mainRoot.clearHistory()
                            historyContainer.categorizedHistory = []
                        }
                    }
                }
            }
            
            // History List View (for List Mode)
            ScrollView {
                anchors.top: historyHeader.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true
                visible: !popupContent.mainRoot.isTileView
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                
                ListView {
                    id: historyListView
                    model: historyContainer.categorizedHistory
                    spacing: 8
                    
                    delegate: Column {
                        width: historyListView.width
                        spacing: 4
                        
                        // Category Header
                        Text {
                            text: modelData.categoryName
                            font.pixelSize: 11
                            font.bold: true
                            color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.6)
                        }
                        
                        // Items in category
                        Repeater {
                            model: modelData.items
                            
                            Rectangle {
                                width: historyListView.width
                                height: Math.max(42, popupContent.mainRoot.listIconSize + 16)
                                color: histListMouseArea.containsMouse ? Qt.rgba(popupContent.delegateAccentColor.r, popupContent.delegateAccentColor.g, popupContent.delegateAccentColor.b, 0.15) : "transparent"
                                radius: 4
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 10
                                    
                                    Kirigami.Icon {
                                        source: modelData.decoration || "application-x-executable"
                                        Layout.preferredWidth: popupContent.mainRoot.listIconSize
                                        Layout.preferredHeight: popupContent.mainRoot.listIconSize
                                        color: popupContent.delegateTextColor
                                    }
                                    
                                    // Name and parent folder column
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Text {
                                            text: modelData.display || ""
                                            color: popupContent.delegateTextColor
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                        
                                        // Parent folder for files
                                        Text {
                                            visible: modelData.filePath && modelData.filePath.length > 0 && !modelData.isApplication
                                            text: {
                                                if (!modelData.filePath) return ""
                                                var path = modelData.filePath.toString()
                                                // Remove file:// prefix if present
                                                if (path.startsWith("file://")) path = path.substring(7)
                                                // Get parent directory
                                                var lastSlash = path.lastIndexOf("/")
                                                if (lastSlash > 0) {
                                                    var parentPath = path.substring(0, lastSlash)
                                                    var parentSlash = parentPath.lastIndexOf("/")
                                                    if (parentSlash >= 0) {
                                                        return parentPath.substring(parentSlash + 1)
                                                    }
                                                    return parentPath
                                                }
                                                return ""
                                            }
                                            color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.5)
                                            font.pixelSize: 11
                                            elide: Text.ElideMiddle
                                            width: parent.width
                                        }
                                    }
                                    
                                    // Timestamp
                                    Text {
                                        text: mainRoot.formatHistoryTime(modelData.timestamp)
                                        color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.5)
                                        font.pixelSize: 11
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                                
                                MouseArea {
                                    id: histListMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: {
                                        // Search for item using display name (more reliable than matchId)
                                        var searchTerm = modelData.display || ""
                                        mainRoot.searchText = searchTerm
                                        hiddenSearchInput.text = searchTerm
                                        historyRunTimer.start()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // History Tile View (for Tile Mode)
            ScrollView {
                anchors.top: historyHeader.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true
                visible: popupContent.mainRoot.isTileView
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                
                ListView {
                    id: historyTileView
                    model: historyContainer.categorizedHistory
                    spacing: 16
                    interactive: false
                    
                    delegate: Column {
                        width: historyTileView.width
                        spacing: 8
                        
                        // Category Header
                        RowLayout {
                            width: parent.width
                            spacing: 8
                            
                            Text {
                                text: modelData.categoryName
                                font.pixelSize: 13
                                font.bold: true
                                color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.6)
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.2)
                            }
                        }
                        
                        // Tile Flow
                        Flow {
                            width: parent.width
                            spacing: 8
                            
                            Repeater {
                                model: modelData.items
                                
                                Item {
                                    width: popupContent.mainRoot.iconSize + 40
                                    height: popupContent.mainRoot.iconSize + 50
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: histTileMouseArea.containsMouse ? Qt.rgba(popupContent.delegateAccentColor.r, popupContent.delegateAccentColor.g, popupContent.delegateAccentColor.b, 0.15) : "transparent"
                                        
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            
                                            Kirigami.Icon {
                                                width: popupContent.mainRoot.iconSize
                                                height: popupContent.mainRoot.iconSize
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                source: modelData.decoration || "application-x-executable"
                                                color: popupContent.delegateTextColor
                                            }
                                            
                                            Text {
                                                width: popupContent.mainRoot.iconSize + 32
                                                text: modelData.display || ""
                                                color: popupContent.delegateTextColor
                                                font.pixelSize: popupContent.mainRoot.iconSize > 32 ? 11 : 9
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideMiddle
                                                maximumLineCount: 2
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: histTileMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            
                                            onClicked: {
                                                // Search for item using display name (more reliable)
                                                var searchTerm = modelData.display || ""
                                                mainRoot.searchText = searchTerm
                                                hiddenSearchInput.text = searchTerm
                                                historyRunTimer.start()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Timer to run search result after history item click
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
        
        // Empty state when no search and no history
        Text {
            anchors.centerIn: parent
            text: "Aramak için yazmaya başlayın"
            color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.5)
            font.pixelSize: 12
            visible: mainRoot.searchText.length === 0 && mainRoot.searchHistory.length === 0
        }
        
        // Data Extractor for Categorized View
        property var categorizedData: []
        
        function refreshGroups() {
            var groups = {};
            var displayOrder = [];
            
            // 1. Initial Grouping
            for (var i = 0; i < rawDataProxy.count; i++) {
                var item = rawDataProxy.itemAt(i);
                var cat = item.category || "Diğer";
                
                if (!groups[cat]) {
                    groups[cat] = [];
                    displayOrder.push(cat);
                }
                
                groups[cat].push({
                    display: item.display,
                    decoration: item.decoration,
                    category: cat,
                    url: item.url,
                    duplicateId: item.duplicateId,
                    index: item.itemIndex
                });
            }
            
            // 2. Consolidate sparse categories (<= 1 item)
            var otherItems = [];
            var finalOrder = [];
            
            // Check existing "Diğer Sonuçlar" to avoid overwriting if it exists naturally
            // though usually it comes from translation
            
            for (var k = 0; k < displayOrder.length; k++) {
                var catName = displayOrder[k];
                var items = groups[catName];
                
                // If category has 1 or fewer items, move to Others
                // EXCEPTION: Always keep "Applications" separate
                var isAppCategory = (catName === "Uygulamalar" || catName === "Applications");
                
                if (items.length <= 1 && !isAppCategory) {
                    for (var j = 0; j < items.length; j++) {
                        otherItems.push(items[j]);
                    }
                } else {
                    finalOrder.push(catName);
                }
            }
            
            // 3. Construct Final Result
            var result = [];
            
            // Add normal categories
            for (var m = 0; m < finalOrder.length; m++) {
                result.push({
                    categoryName: finalOrder[m],
                    items: groups[finalOrder[m]]
                });
            }
            
            // Add "Diğer Sonuçlar" if any
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
                required property int index
                required property var category
                required property var display
                required property var decoration
                required property var url
                required property var duplicateId
                property int itemIndex: index
            }
            onCountChanged: popupContent.refreshGroups()
        }

        // TILE VIEW (Categorized Flow)
        ScrollView {
            id: tileScroll
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            visible: popupContent.mainRoot.isTileView
            
            // Hide scrollbar
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            
            ListView {
                id: tileCategoryList
                width: parent.width
                model: popupContent.categorizedData
                spacing: 16
                interactive: false // Let ScrollView handle scrolling
                
                delegate: Column {
                    width: parent.width
                    spacing: 8
                    
                    // Category Header
                    RowLayout {
                        width: parent.width
                        spacing: 8
                        
                        Text {
                            text: modelData.categoryName
                            font.pixelSize: 13
                            font.bold: true
                            color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.6)
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.2)
                        }
                    }
                    
                    // Grid Flow
                    Flow {
                        width: parent.width
                        spacing: 8
                        
                        Repeater {
                            model: modelData.items
                            
                            delegate: Item {
                                width: popupContent.mainRoot.iconSize + 40
                                height: popupContent.mainRoot.iconSize + 50
                                
                                Rectangle {
                                    id: tileBg
                                    anchors.fill: parent
                                    radius: 8
                                    color: tileMouseArea.containsMouse ? Qt.rgba(popupContent.delegateAccentColor.r, popupContent.delegateAccentColor.g, popupContent.delegateAccentColor.b, 0.15) : "transparent"
                                    
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        
                                        // Icon with configurable size
                                        Kirigami.Icon {
                                            width: popupContent.mainRoot.iconSize
                                            height: popupContent.mainRoot.iconSize
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            source: modelData.decoration || "application-x-executable"
                                            color: popupContent.delegateTextColor
                                        }
                                        
                                        // Text below icon
                                        Text {
                                            width: parent.width - 8
                                            text: modelData.display || ""
                                            color: popupContent.delegateTextColor
                                            // Adjust font size based on icon size
                                            font.pixelSize: popupContent.mainRoot.iconSize > 32 ? 11 : 9
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideMiddle
                                            maximumLineCount: 2
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: tileMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        
                                        onClicked: {
                                            // Add to history - use duplicateId as matchId and url as filePath
                                            var matchId = modelData.duplicateId || modelData.display || ""
                                            var filePath = modelData.url || ""
                                            mainRoot.addToHistory(modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Diğer", matchId, filePath)
                                            var idx = resultsModel.index(modelData.index, 0)
                                            resultsModel.run(idx)
                                            mainRoot.searchText = ""
                                            mainRoot.expanded = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Empty state for tile view
        // Empty state for tile view
        Text {
            anchors.centerIn: parent
            text: popupContent.mainRoot.searchText.length > 0 ? "Sonuç bulunamadı" : "Aramak için yazmaya başlayın"
            color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.5)
            font.pixelSize: 12
            visible: popupContent.categorizedData.length === 0 && popupContent.mainRoot.isTileView
        }
        
        // Auto-focus hidden input when popup opens
        Component.onCompleted: {
            hiddenSearchInput.forceActiveFocus()
        }
        
        Connections {
            target: mainRoot
            function onExpandedChanged() {
                if (mainRoot.expanded) {
                    hiddenSearchInput.forceActiveFocus()
                    hiddenSearchInput.selectAll()
                    resultsList.currentIndex = 0
                } else {
                    mainRoot.searchText = ""
                }
            }
        }
    }
    
    // Start with compact representation
    preferredRepresentation: compactRepresentation
}
