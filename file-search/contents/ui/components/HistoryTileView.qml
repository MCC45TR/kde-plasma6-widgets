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
    
    // Signals
    signal itemClicked(var item)
    signal clearClicked()
    
    // Localization function
    property var trFunc: function(key) { return key }
    
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
    
    focus: true
    
    // Keyboard handling
    Keys.onUpPressed: moveSelection(-columnsInRow())
    Keys.onDownPressed: moveSelection(columnsInRow())
    Keys.onLeftPressed: moveSelection(-1)
    Keys.onRightPressed: moveSelection(1)
    Keys.onReturnPressed: activateCurrentItem()
    Keys.onEnterPressed: activateCurrentItem()
    
    function columnsInRow() {
        var itemWidth = iconSize + 48
        return Math.max(1, Math.floor(width / itemWidth))
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
            text: historyTile.trFunc("recent_searches")
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
                text: historyTile.trFunc("clear_history")
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
    
    // Tile Grid
    ScrollView {
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
                                anchors.fill: parent
                                radius: 8
                                color: {
                                    if (histTileDelegate.isSelected)
                                        return Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.3)
                                    if (histTileMouseArea.containsMouse) 
                                        return Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.15)
                                    return "transparent"
                                }
                                border.width: histTileDelegate.isSelected ? 2 : 0
                                border.color: historyTile.accentColor
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    
                                    Kirigami.Icon {
                                        width: historyTile.iconSize
                                        height: historyTile.iconSize
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: modelData.decoration || "application-x-executable"
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
                                }
                                
                                MouseArea {
                                    id: histTileMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: historyTile.itemClicked(modelData)
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
}
