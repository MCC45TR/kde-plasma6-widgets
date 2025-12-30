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
    
    // Configuration: 0 = Wide Mode, 1 = Medium Mode, 2 = Extra Wide Mode
    readonly property int displayMode: Plasmoid.configuration.displayMode
    readonly property bool isCompactMode: displayMode === 1
    readonly property bool isWideMode: !isCompactMode

    // Calculate minimum width needed for text
    readonly property real textContentWidth: textMetrics.width + (isWideMode ? (height + 30) : 20)
    // Base width: 4x for Wide, 6x for Extra Wide, Fixed small for Compact
    readonly property real baseWidth: displayMode === 2 ? (height * 6) : (isWideMode ? (height * 4) : 70)
    
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
    readonly property string placeholderText: displayMode === 2 ? "Arama yapmaya başla..." : (displayMode === 0 ? "Arama yap..." : "Ara")
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
    

    
    // Panel representation - just displays, click opens popup
    compactRepresentation: Item {
        id: compactRep
        anchors.fill: parent
        
        // Main Button Container
        Rectangle {
            id: mainButton
            anchors.fill: parent
            anchors.margins: 0
            radius: height / 2
            color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.95)
            
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
                    horizontalAlignment: root.isWideMode ? Text.AlignLeft : Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                
                // Search Icon Button (Wide Mode only)
                Rectangle {
                    id: searchIconButton
                    Layout.preferredWidth: root.isWideMode ? (mainButton.height - 6) : 0
                    Layout.preferredHeight: mainButton.height - 6
                    Layout.alignment: Qt.AlignVCenter
                    radius: width / 2
                    color: root.accentColor
                    visible: root.isWideMode
                    
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
                    var idx = resultsModel.index(0, 0)
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
                    height: Math.max(36, popupContent.mainRoot.listIconSize + 14)
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
                        
                        // Result text
                        Text {
                            text: model.display || ""
                            color: popupContent.delegateTextColor
                            font.pixelSize: 15
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    
                    MouseArea {
                        id: resultMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            var idx = resultsModel.index(index, 0)
                            resultsModel.run(idx)
                            popupContent.mainRoot.searchText = ""
                            popupContent.mainRoot.expanded = false
                        }
                    }
                }
                
                // Empty state for list
                Text {
                    anchors.centerIn: parent
                    text: mainRoot.searchText.length > 0 ? "Sonuç bulunamadı" : "Aramak için yazmaya başlayın"
                    color: Qt.rgba(popupContent.delegateTextColor.r, popupContent.delegateTextColor.g, popupContent.delegateTextColor.b, 0.5)
                    font.pixelSize: 12
                    visible: resultsList.count === 0 && !popupContent.mainRoot.isTileView
                }
            }
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
                    index: item.index
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
            Item {
                property var category: model.category
                property var display: model.display
                property var decoration: model.decoration
                property int index: index
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
                                            var idx = resultsModel.index(modelData.index, 0)
                                            resultsModel.run(idx)
                                            popupContent.mainRoot.searchText = ""
                                            popupContent.mainRoot.expanded = false
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
