import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// History Tile View - Displays search history in tile/grid format
// Features: Keyboard navigation, Category collapse/expand
FocusScope {
    id: historyTile
    
    // Required properties
    required property var categorizedHistory
    required property int iconSize
    required property color textColor
    required property color accentColor
    required property var previewSettings
    
    // Signals
    signal itemClicked(var item)
    signal clearClicked()
    
    // Localization removed
    // Use standard i18nd("plasma_applet_com.mcc45tr.filesearch", )
    
    // Navigation state
    property var collapsedCategories: ({})
    property int selectedFlatIndex: 0
    
    // Computed flat list for keyboard navigation
    property var flatItemList: {
        var list = []
        for (var i = 0; i < categorizedHistory.length; i++) {
            var cat = categorizedHistory[i]
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
    Keys.onReturnPressed: (event) => {
        activateCurrentItem()
        event.accepted = true
    }
    Keys.onEnterPressed: (event) => {
        activateCurrentItem()
        event.accepted = true
    }
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
            }
        }
    }
    
    function columnsInRow() {
        var itemWidth = iconSize + 48
        return Math.max(1, Math.floor(width / itemWidth))
    }
    
    // Calculate current column position
    function getCurrentColumn() {
        if (totalItems === 0) return 0
        var cols = columnsInRow()
        var item = flatItemList[selectedFlatIndex]
        if (!item) return 0
        return item.itemIndex % cols
    }
    
    // Navigation methods
    function moveUp() { smartMoveVertical(-1) }
    function moveDown() { smartMoveVertical(1) }
    function moveLeft() { moveSelection(-1) }
    function moveRight() { moveSelection(1) }
    function movePrev() { moveSelection(-1) }
    function moveNext() { moveSelection(1) }

    // Smart vertical movement that maintains column position
    function smartMoveVertical(direction) {
        if (totalItems === 0) return
        
        var cols = columnsInRow()
        var currentItem = flatItemList[selectedFlatIndex]
        if (!currentItem) return
        
        var currentCatIdx = currentItem.catIndex
        var currentItemIdx = currentItem.itemIndex
        var currentCol = currentItemIdx % cols
        
        var targetGlobalIndex = -1
        
        if (direction === 1) { // Down
             var nextRowIndex = currentItemIdx + cols
             
             // Scan for target
             for (var i = selectedFlatIndex + 1; i < totalItems; i++) {
                 var nextItem = flatItemList[i]
                 
                 // Case 1: Same category
                 if (nextItem.catIndex === currentCatIdx) {
                    if (nextItem.itemIndex === nextRowIndex) {
                        targetGlobalIndex = i
                        break
                    }
                 } 
                 // Case 2: Changed category (Found start of next category)
                 else {
                     // We hit the next category. Find item in row 0 matching currentCol.
                     var newCatIdx = nextItem.catIndex
                     var bestMatch = i // default to first item
                     
                     for (var j = i; j < totalItems; j++) {
                         var cand = flatItemList[j]
                         if (cand.catIndex !== newCatIdx) break; 
                         if (cand.itemIndex >= cols) break; // Went past first row
                         
                         if ((cand.itemIndex % cols) === currentCol) {
                             targetGlobalIndex = j
                             break
                         }
                         bestMatch = j
                     }
                     if (targetGlobalIndex === -1) targetGlobalIndex = bestMatch
                     break;
                 }
             }
        } else { // Up
             var prevRowIndex = currentItemIdx - cols
             
             if (prevRowIndex >= 0) {
                 // Scan backwards for same cat
                 for (var i = selectedFlatIndex - 1; i >= 0; i--) {
                     var prevItem = flatItemList[i]
                     if (prevItem.catIndex === currentCatIdx && prevItem.itemIndex === prevRowIndex) {
                         targetGlobalIndex = i
                         break
                     }
                     if (prevItem.catIndex !== currentCatIdx) break; 
                 }
             } else {
                 // Fell off top of category. Find last row of previous category.
                 for (var i = selectedFlatIndex - 1; i >= 0; i--) {
                     var prevItem = flatItemList[i]
                     if (prevItem.catIndex !== currentCatIdx) {
                         var prevCatIdx = prevItem.catIndex
                         // prevItem is the last item of prev category. 
                         var endpointRow = Math.floor(prevItem.itemIndex / cols)
                         var desiredIndex = endpointRow * cols + currentCol
                         
                         if (desiredIndex > prevItem.itemIndex) {
                             // Column doesn't exist in last row, pick last item
                             targetGlobalIndex = i
                         } else {
                             // Find exact match
                             for (var j = i; j >= 0; j--) {
                                 var cand = flatItemList[j]
                                 if (cand.catIndex !== prevCatIdx) break 
                                 if (cand.itemIndex === desiredIndex) {
                                     targetGlobalIndex = j
                                     break
                                 }
                             }
                         }
                         break
                     }
                 }
             }
        }
        
        if (targetGlobalIndex !== -1) {
            selectedFlatIndex = targetGlobalIndex
        }
    }
    
    function moveSelection(delta) {
        if (totalItems === 0) return
        var newIndex = Math.max(0, Math.min(totalItems - 1, selectedFlatIndex + delta))
        selectedFlatIndex = newIndex
    }
    
    function activateCurrentItem() {
        if (totalItems === 0) return
        var item = flatItemList[selectedFlatIndex]
        if (item) {
            historyTile.itemClicked(item.data)
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
    
    // Header with title and clear button
    RowLayout {
        id: historyHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        
        Text {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Recent Searches")
            font.pixelSize: 13
            font.bold: true
            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
            Layout.fillWidth: true
        }
        
        // Clear History Button
        Rectangle {
            id: clearHistoryBtn
            Layout.preferredWidth: clearBtnText.implicitWidth + 16
            Layout.preferredHeight: 26
            radius: 4
            color: clearHistoryMouseArea.containsMouse ? Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.2) : "transparent"
            border.width: 1
            border.color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.2)
            
            Text {
                id: clearBtnText
                anchors.centerIn: parent
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Clear History")
                font.pixelSize: 11
                color: historyTile.textColor
            }
            
            MouseArea {
                id: clearHistoryMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: historyTile.clearClicked()
            }
        }
    }
    
    // Context Menu
    HistoryContextMenu {
        id: contextMenu
        logic: popupRoot.logic
    }

    // Tile Grid
    ScrollView {
        visible: historyTile.categorizedHistory.length > 0
        anchors.top: historyHeader.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        
        ListView {
            id: tileView
            model: historyTile.categorizedHistory
            spacing: 16
            interactive: false
            
            delegate: Column {
                id: histCategoryDelegate
                width: tileView.width
                spacing: 8
                
                property int catIdx: index
                property bool isCollapsed: historyTile.collapsedCategories[modelData.categoryName] || false
                
                // Category Header (Clickable)
                Rectangle {
                    width: parent.width
                    height: 28
                    color: histCategoryHeaderMouse.containsMouse ? Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.1) : "transparent"
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        
                        Kirigami.Icon {
                            source: histCategoryDelegate.isCollapsed ? "arrow-right" : "arrow-down"
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            color: historyTile.textColor
                            opacity: 0.6
                        }
                        
                        Text {
                            text: modelData.categoryName + " (" + modelData.items.length + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.6)
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.2)
                        }
                    }
                    
                    MouseArea {
                        id: histCategoryHeaderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: historyTile.toggleCategory(modelData.categoryName)
                    }
                }
                
                // Tile Flow
                Flow {
                    width: parent.width
                    spacing: 8
                    visible: !histCategoryDelegate.isCollapsed
                    
                    Repeater {
                        model: modelData.items
                        
                        Item {
                            id: histTileDelegate
                            width: historyTile.iconSize + 40
                            height: historyTile.iconSize + 50
                            
                            property int itemIdx: index
                            property bool isSelected: historyTile.isItemSelected(histCategoryDelegate.catIdx, itemIdx)
                            
                            Rectangle {
                                id: histTileBg
                                anchors.fill: parent
                                radius: 8
                                color: {
                                    if (histTileDelegate.isSelected)
                                        return Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.3)
                                    if (histTileMouseArea.containsMouse || (contextMenu.visible && contextMenu.historyItem === modelData)) 
                                        return Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.15)
                                    return "transparent"
                                }
                                border.width: histTileDelegate.isSelected ? 2 : 0
                                border.color: historyTile.accentColor
                                
                                Behavior on border.width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                // Focus glow effect for accessibility
                                Rectangle {
                                    id: histFocusGlow
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    radius: parent.radius + 3
                                    color: "transparent"
                                    border.width: histTileDelegate.isSelected ? 2 : 0
                                    border.color: Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.4)
                                    visible: histTileDelegate.isSelected
                                    opacity: visible ? 1 : 0
                                    
                                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                }
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    
                                    Kirigami.Icon {
                                        width: historyTile.iconSize
                                        height: historyTile.iconSize
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: {
                                            // standard icon if small
                                            if (historyTile.iconSize <= 22) return modelData.decoration || "application-x-executable";
                                            
                                            var url = (modelData.filePath || "").toString();
                                            // Fallback to url property if filePath is missing (some history items might have different structure)
                                            if (!url) url = (modelData.url || "").toString();
                                            
                                            if (!url) return modelData.decoration || "application-x-executable";
                                            
                                            var ext = url.split('.').pop().toLowerCase();
                                            
                                            if (historyTile.previewSettings.images) {
                                                var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tiff"]
                                                if (imageExts.indexOf(ext) >= 0) return url
                                            }
                                            
                                            if (historyTile.previewSettings.videos) {
                                                var videoExts = ["mp4", "mkv", "avi", "webm", "mov", "flv", "wmv", "mpg", "mpeg"]
                                                if (videoExts.indexOf(ext) >= 0) return "image://preview/" + url
                                            }
                                            
                                            if (historyTile.previewSettings.documents) {
                                                var docExts = ["pdf", "odt", "docx", "pptx", "xlsx"]
                                                if (docExts.indexOf(ext) >= 0) return "image://preview/" + url
                                            }
                                            
                                            return modelData.decoration || "application-x-executable"
                                        }
                                        color: historyTile.textColor
                                    }
                                    
                                    Text {
                                        width: historyTile.iconSize + 32
                                        text: modelData.display || ""
                                        color: historyTile.textColor
                                        font.pixelSize: historyTile.iconSize > 32 ? 11 : 9
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideMiddle
                                        maximumLineCount: 2
                                        wrapMode: Text.Wrap
                                    }
                                    
                                    // Parent folder name (Grid mode)
                                    Text {
                                        width: historyTile.iconSize + 32
                                        text: {
                                            if (modelData.isApplication) return "";
                                            
                                            var path = modelData.filePath ? modelData.filePath.toString() : "";
                                            if (path && path.length > 0) {
                                                path = path.replace("file://", "");
                                                if (path.endsWith("/")) path = path.slice(0, -1);
                                                var parts = path.split("/");
                                                if (parts.length > 1) {
                                                    // Return parent folder name
                                                    return parts[parts.length - 2];
                                                }
                                            }
                                            return "";
                                        }
                                        color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.6)
                                        font.pixelSize: 9
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideMiddle
                                        visible: text.length > 0
                                    }
                                }
                                
                                MouseArea {
                                    id: histTileMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            contextMenu.historyItem = modelData
                                            contextMenu.popup()
                                        } else {
                                            historyTile.itemClicked(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Reset selection when data changes
    onCategorizedHistoryChanged: {
        selectedFlatIndex = 0
    }

    // Empty State
    ColumnLayout {
        anchors.centerIn: parent
        visible: historyTile.categorizedHistory.length === 0
        spacing: 16

        Kirigami.Icon {
            source: "search"
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            Layout.alignment: Qt.AlignHCenter
            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.3)
        }

        Text {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Type to search")
            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.5)
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
