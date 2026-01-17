import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Results Tile View - Displays search results in tile/grid format
// Features: Keyboard navigation, Category collapse/expand, File preview tooltip
FocusScope {
    id: resultsTileRoot
    
    // Required properties
    required property var categorizedData
    required property int iconSize
    required property color textColor
    required property color accentColor
    
    // Signals
    signal itemClicked(int index, string display, string decoration, string category, string matchId, string filePath)
    
    // Localization
    property var trFunc: function(key) { return key }
    property string searchText: ""
    
    // Navigation state
    property int currentCategoryIndex: 0
    property int currentItemIndex: 0
    property var collapsedCategories: ({})
    
    // Computed flat list for keyboard navigation
    property var flatItemList: {
        var list = []
        for (var i = 0; i < categorizedData.length; i++) {
            var cat = categorizedData[i]
            if (collapsedCategories[cat.categoryName]) continue
            for (var j = 0; j < cat.items.length; j++) {
                list.push({
                    catIndex: i,
                    itemIndex: j,
                    globalIndex: list.length,
                    data: cat.items[j]
                })
            }
        }
        return list
    }
    
    property int totalItems: flatItemList.length
    property int selectedFlatIndex: 0
    
    // Signals for Tab navigation
    signal tabPressed()
    signal shiftTabPressed()
    signal viewModeChangeRequested(int mode)
    
    focus: true
    
    // Keyboard handling
    Keys.onUpPressed: smartMoveVertical(-1)
    Keys.onDownPressed: smartMoveVertical(1)
    Keys.onLeftPressed: moveSelection(-1)
    Keys.onRightPressed: moveSelection(1)
    Keys.onReturnPressed: activateCurrentItem()
    Keys.onEnterPressed: activateCurrentItem()
    Keys.onTabPressed: (event) => {
        if (event.modifiers & Qt.ShiftModifier) {
            shiftTabPressed()
        } else {
            tabPressed()
        }
        event.accepted = true
    }
    Keys.onPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_1) {
                viewModeChangeRequested(0)
                event.accepted = true
            } else if (event.key === Qt.Key_2) {
                viewModeChangeRequested(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Space) {
                // Toggle preview for selected item
                previewForceVisible = !previewForceVisible
                event.accepted = true
            }
        }
    }
    
    // Preview visibility state
    property bool previewForceVisible: false
    
    function columnsInRow() {
        var itemWidth = iconSize + 48
        return Math.max(1, Math.floor(width / itemWidth))
    }
    
    // Calculate current column position
    function getCurrentColumn() {
        if (totalItems === 0) return 0
        var cols = columnsInRow()
        // Find position within current category row
        var item = flatItemList[selectedFlatIndex]
        if (!item) return 0
        return item.itemIndex % cols
    }
    
    // Smart vertical movement that maintains column position
    function smartMoveVertical(direction) {
        if (totalItems === 0) return
        
        var cols = columnsInRow()
        var currentCol = getCurrentColumn()
        var currentItem = flatItemList[selectedFlatIndex]
        if (!currentItem) return
        
        // Find the next row in the same or different category
        var targetIndex = selectedFlatIndex + (direction * cols)
        
        // Clamp to valid range
        if (targetIndex < 0) {
            targetIndex = 0
        } else if (targetIndex >= totalItems) {
            targetIndex = totalItems - 1
        }
        
        // Try to maintain column position
        var targetItem = flatItemList[targetIndex]
        if (targetItem) {
            var targetCol = targetItem.itemIndex % cols
            // If we moved to a different column, try to find same column
            if (targetCol !== currentCol && direction !== 0) {
                // Look for item in same column in next row
                for (var i = targetIndex; i < Math.min(targetIndex + cols, totalItems) && i >= 0; i++) {
                    var item = flatItemList[i]
                    if (item && (item.itemIndex % cols) === currentCol) {
                        targetIndex = i
                        break
                    }
                }
            }
        }
        
        selectedFlatIndex = targetIndex
        ensureItemVisible()
    }
    
    function moveSelection(delta) {
        if (totalItems === 0) return
        var newIndex = Math.max(0, Math.min(totalItems - 1, selectedFlatIndex + delta))
        selectedFlatIndex = newIndex
        ensureItemVisible()
    }
    
    // Scroll to make selected item visible
    function ensureItemVisible() {
        // Will be handled by ListView's positionViewAtIndex if we refactor
        // For now, the ScrollView should follow focus naturally
    }
    
    function activateCurrentItem() {
        if (totalItems === 0) return
        var item = flatItemList[selectedFlatIndex]
        if (item) {
            var data = item.data
            var matchId = data.duplicateId || data.display || ""
            var filePath = (data.url && data.url.toString) ? data.url.toString() : (data.url || "")
            var subtext = data.subtext || ""
            var urls = data.urls || []
            
            if (filePath === "" && urls.length > 0) {
                filePath = urls[0].toString()
            }
            
            if (filePath === "") {
                if (subtext.indexOf("/") === 0) filePath = "file://" + subtext
                else if (subtext.indexOf("file://") === 0) filePath = subtext
            }
            
            itemClicked(data.index, data.display || "", data.decoration || "application-x-executable", data.category || "Diğer", matchId, filePath)
        }
    }
    
    function toggleCategory(categoryName) {
        var newCollapsed = Object.assign({}, collapsedCategories)
        newCollapsed[categoryName] = !newCollapsed[categoryName]
        collapsedCategories = newCollapsed
    }
    
    function isItemSelected(catIdx, itemIdx) {
        if (totalItems === 0) return false
        var item = flatItemList[selectedFlatIndex]
        return item && item.catIndex === catIdx && item.itemIndex === itemIdx
    }
    
    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        
        ListView {
            id: tileCategoryList
            width: parent.width
            model: resultsTileRoot.categorizedData
            spacing: 16
            interactive: false
            
            delegate: Column {
                id: categoryDelegate
                width: tileCategoryList.width
                spacing: 8
                
                property int catIdx: index
                property bool isCollapsed: resultsTileRoot.collapsedCategories[modelData.categoryName] || false
                
                // Category Header (Clickable to collapse/expand)
                Rectangle {
                    width: parent.width
                    height: 28
                    color: categoryHeaderMouse.containsMouse ? Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.1) : "transparent"
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        
                        // Collapse indicator
                        Kirigami.Icon {
                            source: categoryDelegate.isCollapsed ? "arrow-right" : "arrow-down"
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            color: resultsTileRoot.textColor
                            opacity: 0.6
                        }
                        
                        Text {
                            text: modelData.categoryName + " (" + modelData.items.length + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.2)
                        }
                    }
                    
                    MouseArea {
                        id: categoryHeaderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: resultsTileRoot.toggleCategory(modelData.categoryName)
                    }
                }
                
                // Grid Flow (Hidden when collapsed)
                Flow {
                    width: parent.width
                    spacing: 8
                    visible: !categoryDelegate.isCollapsed
                    
                    Repeater {
                        model: modelData.items
                        
                        delegate: Item {
                            id: tileDelegate
                            width: resultsTileRoot.iconSize + 40
                            height: resultsTileRoot.iconSize + 50
                            
                            property int itemIdx: index
                            property bool isSelected: resultsTileRoot.isItemSelected(categoryDelegate.catIdx, itemIdx)
                            
                            Rectangle {
                                id: tileBg
                                anchors.fill: parent
                                radius: 8
                                color: {
                                    if (tileDelegate.isSelected) 
                                        return Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.3)
                                    if (tileMouseArea.containsMouse) 
                                        return Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.15)
                                    return "transparent"
                                }
                                border.width: tileDelegate.isSelected ? 2 : 0
                                border.color: resultsTileRoot.accentColor
                                
                                Behavior on border.width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                // Focus glow effect for accessibility
                                Rectangle {
                                    id: focusGlow
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    radius: parent.radius + 3
                                    color: "transparent"
                                    border.width: tileDelegate.isSelected ? 2 : 0
                                    border.color: Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.4)
                                    visible: tileDelegate.isSelected
                                    opacity: visible ? 1 : 0
                                    
                                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                }
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    
                                    Kirigami.Icon {
                                        width: resultsTileRoot.iconSize
                                        height: resultsTileRoot.iconSize
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: modelData.decoration || "application-x-executable"
                                        color: resultsTileRoot.textColor
                                    }
                                    
                                    Text {
                                        width: parent.width - 8
                                        text: modelData.display || ""
                                        color: resultsTileRoot.textColor
                                        font.pixelSize: resultsTileRoot.iconSize > 32 ? 11 : 9
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
                                        var matchId = modelData.duplicateId || modelData.display || ""
                                        var filePath = (modelData.url && modelData.url.toString) ? modelData.url.toString() : (modelData.url || "")
                                        var subtext = modelData.subtext || ""
                                        var urls = modelData.urls || []
                                        
                                        if (filePath === "" && urls.length > 0) {
                                            filePath = urls[0].toString()
                                        }
                                        
                                        if (filePath === "") {
                                            if (subtext.indexOf("/") === 0) filePath = "file://" + subtext
                                            else if (subtext.indexOf("file://") === 0) filePath = subtext
                                        }
                                        
                                        resultsTileRoot.itemClicked(modelData.index, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Diğer", matchId, filePath)
                                    }
                                }
                                
                                // File Preview Tooltip
                                ToolTip {
                                    id: previewTooltip
                                    visible: (tileMouseArea.containsMouse || (tileDelegate.isSelected && resultsTileRoot.previewForceVisible)) && (modelData.url || "").length > 0
                                    delay: tileDelegate.isSelected && resultsTileRoot.previewForceVisible ? 0 : 500
                                    timeout: 10000
                                    x: tileDelegate.width + 4
                                    y: 0
                                    
                                    contentItem: Column {
                                        spacing: 6
                                        
                                        // Title
                                        Text {
                                            text: modelData.display || ""
                                            font.bold: true
                                            font.pixelSize: 12
                                            color: resultsTileRoot.textColor
                                        }
                                        
                                        // Thumbnail for images
                                        Image {
                                            id: thumbnailImage
                                            source: {
                                                var url = modelData.url || ""
                                                if (url.length === 0) return ""
                                                var ext = url.split('.').pop().toLowerCase()
                                                var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg"]
                                                if (imageExts.indexOf(ext) >= 0) {
                                                    return url
                                                }
                                                return ""
                                            }
                                            width: source.length > 0 ? Math.min(150, sourceSize.width) : 0
                                            height: source.length > 0 ? Math.min(100, sourceSize.height) : 0
                                            fillMode: Image.PreserveAspectFit
                                            visible: source.length > 0
                                            cache: true
                                            asynchronous: true
                                        }
                                        
                                        // Category
                                        Text {
                                            text: resultsTileRoot.trFunc("category") + ": " + (modelData.category || "")
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            visible: (modelData.category || "").length > 0
                                        }
                                        
                                        // File Type (from extension)
                                        Text {
                                            property string fileExt: {
                                                var url = modelData.url || ""
                                                if (url.length === 0) return ""
                                                var parts = url.split('.')
                                                return parts.length > 1 ? parts.pop().toUpperCase() : ""
                                            }
                                            text: resultsTileRoot.trFunc("file_type") + ": " + fileExt
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            visible: fileExt.length > 0
                                        }
                                        
                                        // Path
                                        Text {
                                            text: resultsTileRoot.trFunc("path") + ": " + (modelData.url || "")
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            wrapMode: Text.WrapAnywhere
                                            width: Math.min(300, implicitWidth)
                                            visible: (modelData.url || "").length > 0
                                        }
                                        
                                        // Shortcut hint
                                        Text {
                                            text: "💡 " + resultsTileRoot.trFunc("preview_shortcut")
                                            font.pixelSize: 9
                                            font.italic: true
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
                                            visible: !resultsTileRoot.previewForceVisible
                                        }
                                    }
                                    
                                    background: Rectangle {
                                        color: Kirigami.Theme.backgroundColor
                                        border.color: resultsTileRoot.accentColor
                                        border.width: 1
                                        radius: 6
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Empty state
    Text {
        anchors.centerIn: parent
        text: resultsTileRoot.searchText.length > 0 ? resultsTileRoot.trFunc("no_results") : resultsTileRoot.trFunc("type_to_search")
        color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
        font.pixelSize: 12
        visible: resultsTileRoot.categorizedData.length === 0
    }
    
    // Reset selection when data changes
    onCategorizedDataChanged: {
        selectedFlatIndex = 0
    }
}
