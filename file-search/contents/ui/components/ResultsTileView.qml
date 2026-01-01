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
            var data = item.data
            var matchId = data.duplicateId || data.display || ""
            var filePath = data.url || ""
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
                                        var filePath = modelData.url || ""
                                        resultsTileRoot.itemClicked(modelData.index, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Diğer", matchId, filePath)
                                    }
                                }
                                
                                // File Preview Tooltip
                                ToolTip {
                                    id: previewTooltip
                                    visible: tileMouseArea.containsMouse && (modelData.url || "").length > 0
                                    delay: 500
                                    timeout: 5000
                                    
                                    contentItem: Column {
                                        spacing: 4
                                        
                                        Text {
                                            text: modelData.display || ""
                                            font.bold: true
                                            font.pixelSize: 12
                                            color: resultsTileRoot.textColor
                                        }
                                        
                                        Text {
                                            text: resultsTileRoot.trFunc("category") + ": " + (modelData.category || "")
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            visible: (modelData.category || "").length > 0
                                        }
                                        
                                        Text {
                                            text: resultsTileRoot.trFunc("path") + ": " + (modelData.url || "")
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            wrapMode: Text.WrapAnywhere
                                            width: Math.min(300, implicitWidth)
                                            visible: (modelData.url || "").length > 0
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
