import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// PinnedSection - Displays pinned items at the top of results
// Supports drag-and-drop reordering and context menu
Item {
    id: pinnedSectionRoot
    
    // Required properties
    required property var pinnedItems
    required property color textColor
    required property color accentColor
    required property int iconSize
    required property bool isTileView
    
    // Collapsed state
    property bool isExpanded: true
    
    // Localization function
    property var trFunc: function(key) { return key }
    
    // Signals
    signal itemClicked(var item)
    signal unpinClicked(string matchId)
    signal reorderRequested(int fromIndex, int toIndex)
    signal openRequested(var item)
    signal copyPathRequested(var item)
    signal openLocationRequested(var item)
    
    // Drag state
    property int draggedIndex: -1
    property int dropTargetIndex: -1
    
    // Height calculation
    implicitHeight: pinnedItems.length > 0 ? contentColumn.implicitHeight : 0
    visible: pinnedItems.length > 0
    
    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 8
        
        // Section header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: headerRow.implicitHeight
            
            RowLayout {
                id: headerRow
                anchors.fill: parent
                spacing: 8
                
                Kirigami.Icon {
                    source: pinnedSectionRoot.isExpanded ? "arrow-down" : "arrow-right"
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    color: pinnedSectionRoot.accentColor
                    
                    Behavior on rotation { NumberAnimation { duration: 200 } }
                }
                
                Kirigami.Icon {
                    source: "pin"
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    color: pinnedSectionRoot.accentColor
                }
                
                Text {
                    text: pinnedSectionRoot.trFunc("pinned_items")
                    font.pixelSize: 12
                    font.bold: true
                    color: Qt.rgba(pinnedSectionRoot.textColor.r, pinnedSectionRoot.textColor.g, pinnedSectionRoot.textColor.b, 0.7)
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: pinnedSectionRoot.pinnedItems.length
                    font.pixelSize: 10
                    color: Qt.rgba(pinnedSectionRoot.textColor.r, pinnedSectionRoot.textColor.g, pinnedSectionRoot.textColor.b, 0.5)
                }
            }
            
            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pinnedSectionRoot.isExpanded = !pinnedSectionRoot.isExpanded
            }
        }
        
        // Pinned Container
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: pinnedSectionRoot.isExpanded ? (pinnedContent.implicitHeight + 8) : 0
            radius: 10
            color: Qt.rgba(pinnedSectionRoot.textColor.r, pinnedSectionRoot.textColor.g, pinnedSectionRoot.textColor.b, 0.05)
            clip: true
            
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            
            ColumnLayout {
                id: pinnedContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 4
                spacing: 8
                
                // Pinned items - List view
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: !pinnedSectionRoot.isTileView && pinnedSectionRoot.pinnedItems.length > 0
                    
                    sourceComponent: Column {
                        spacing: 2
                        
                        Repeater {
                            model: pinnedSectionRoot.pinnedItems
                            
                            delegate: Rectangle {
                                width: parent.width
                                height: 40
                                color: itemMouse.containsMouse 
                                    ? Qt.rgba(pinnedSectionRoot.accentColor.r, pinnedSectionRoot.accentColor.g, pinnedSectionRoot.accentColor.b, 0.15)
                                    : "transparent"
                                radius: 4
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 10
                                    
                                    Kirigami.Icon {
                                        source: modelData.decoration || "application-x-executable"
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        color: pinnedSectionRoot.textColor
                                    }
                                    
                                    Text {
                                        text: modelData.display || ""
                                        Layout.fillWidth: true
                                        color: pinnedSectionRoot.textColor
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }
                                    
                                    // Unpin button
                                    PinButton {
                                        isPinned: true
                                        accentColor: pinnedSectionRoot.accentColor
                                        textColor: pinnedSectionRoot.textColor
                                        trFunc: pinnedSectionRoot.trFunc
                                        
                                        onToggled: {
                                            pinnedSectionRoot.unpinClicked(modelData.matchId)
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: 30
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: {
                                        pinnedSectionRoot.itemClicked(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Pinned items - Tile view with drag-drop support
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: pinnedSectionRoot.isTileView && pinnedSectionRoot.pinnedItems.length > 0
                    
                    sourceComponent: Flow {
                        id: tileFlow
                        spacing: 8
                        
                        Repeater {
                            id: tileRepeater
                            model: pinnedSectionRoot.pinnedItems
                            
                            delegate: Item {
                                id: tileDelegate
                                width: pinnedSectionRoot.iconSize + 16
                                height: pinnedSectionRoot.iconSize + 36
                                
                                property int visualIndex: index
                                property bool isDragging: pinnedSectionRoot.draggedIndex === index
                                
                                // Drop indicator
                                Rectangle {
                                    visible: pinnedSectionRoot.dropTargetIndex === index && pinnedSectionRoot.draggedIndex !== index
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 3
                                    height: parent.height - 8
                                    radius: 1.5
                                    color: pinnedSectionRoot.accentColor
                                }
                                
                                Rectangle {
                                    id: tileContent
                                    anchors.fill: parent
                                    color: tileMouse.containsMouse || isDragging
                                        ? Qt.rgba(pinnedSectionRoot.accentColor.r, pinnedSectionRoot.accentColor.g, pinnedSectionRoot.accentColor.b, 0.15)
                                        : "transparent"
                                    radius: 6
                                    opacity: isDragging ? 0.6 : 1.0
                                    
                                    Behavior on opacity { NumberAnimation { duration: 100 } }
                                    
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        
                                        Item {
                                            width: pinnedSectionRoot.iconSize
                                            height: pinnedSectionRoot.iconSize
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            
                                            Kirigami.Icon {
                                                anchors.fill: parent
                                                source: modelData.decoration || "application-x-executable"
                                                color: pinnedSectionRoot.textColor
                                            }
                                            
                                            // Pin indicator
                                            Kirigami.Icon {
                                                source: "pin"
                                                width: 12
                                                height: 12
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: -2
                                                color: pinnedSectionRoot.accentColor
                                                visible: true
                                            }
                                        }
                                        
                                        Text {
                                            text: modelData.display || ""
                                            width: pinnedSectionRoot.iconSize + 8
                                            horizontalAlignment: Text.AlignHCenter
                                            color: pinnedSectionRoot.textColor
                                            font.pixelSize: 10
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    
                                    drag.target: tileContent
                                    drag.axis: Drag.XAxis
                                    
                                    onPressed: (mouse) => {
                                        if (mouse.button === Qt.LeftButton) {
                                            pinnedSectionRoot.draggedIndex = index
                                        }
                                    }
                                    
                                    onReleased: (mouse) => {
                                        if (pinnedSectionRoot.draggedIndex !== -1 && pinnedSectionRoot.dropTargetIndex !== -1) {
                                            if (pinnedSectionRoot.draggedIndex !== pinnedSectionRoot.dropTargetIndex) {
                                                pinnedSectionRoot.reorderRequested(pinnedSectionRoot.draggedIndex, pinnedSectionRoot.dropTargetIndex)
                                            }
                                        }
                                        pinnedSectionRoot.draggedIndex = -1
                                        pinnedSectionRoot.dropTargetIndex = -1
                                        if (tileContent) {
                                            tileContent.x = 0
                                            tileContent.y = 0
                                        }
                                    }
                                    
                                    onPositionChanged: (mouse) => {
                                        if (drag.active) {
                                            // Calculate drop target based on mouse position
                                            var globalPos = mapToItem(tileFlow, mouse.x, mouse.y)
                                            var targetIndex = Math.floor(globalPos.x / (pinnedSectionRoot.iconSize + 24))
                                            targetIndex = Math.max(0, Math.min(targetIndex, pinnedSectionRoot.pinnedItems.length - 1))
                                            pinnedSectionRoot.dropTargetIndex = targetIndex
                                        }
                                    }
                                    
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            pinnedContextMenu.currentItem = modelData
                                            pinnedContextMenu.selectedIndex = index
                                            pinnedContextMenu.popup()
                                        } else if (!drag.active) {
                                            pinnedSectionRoot.itemClicked(modelData)
                                        }
                                    }
                                }
                                
                                ToolTip {
                                    visible: tileMouse.containsMouse && !tileMouse.drag.active
                                    text: modelData.display + "\n" + pinnedSectionRoot.trFunc("drag_to_reorder")
                                    delay: 500
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Context Menu for pinned items
    Menu {
        id: pinnedContextMenu
        
        property var currentItem: null
        property int selectedIndex: -1
        
        MenuItem {
            text: pinnedSectionRoot.trFunc("open")
            icon.name: "document-open"
            onTriggered: {
                if (pinnedContextMenu.currentItem) {
                    pinnedSectionRoot.itemClicked(pinnedContextMenu.currentItem)
                }
            }
        }
        
        MenuItem {
            text: pinnedSectionRoot.trFunc("copy_path")
            icon.name: "edit-copy"
            visible: pinnedContextMenu.currentItem && pinnedContextMenu.currentItem.filePath
            onTriggered: {
                if (pinnedContextMenu.currentItem) {
                    pinnedSectionRoot.copyPathRequested(pinnedContextMenu.currentItem)
                }
            }
        }
        
        MenuItem {
            text: pinnedSectionRoot.trFunc("open_location")
            icon.name: "folder-open"
            visible: pinnedContextMenu.currentItem && pinnedContextMenu.currentItem.filePath
            onTriggered: {
                if (pinnedContextMenu.currentItem) {
                    pinnedSectionRoot.openLocationRequested(pinnedContextMenu.currentItem)
                }
            }
        }
        
        MenuSeparator {}
        
        MenuItem {
            text: pinnedSectionRoot.trFunc("unpin_item")
            icon.name: "window-unpin"
            onTriggered: {
                if (pinnedContextMenu.currentItem) {
                    pinnedSectionRoot.unpinClicked(pinnedContextMenu.currentItem.matchId)
                }
            }
        }
    }
}
