import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import "../js/PinnedManager.js" as PinnedManager

Item {
    id: root
    
    // Config properties
    property var pinnedItems: PinnedManager.loadPinned(Plasmoid.configuration.pinnedItems)
    
    // View state
    property bool isExpanded: true
    property int draggedIndex: -1
    property int dropTargetIndex: -1
    
    // Full width layout binding logic
    visible: true 
    implicitHeight: topLayout.implicitHeight
    
    Behavior on implicitHeight {
        NumberAnimation { 
            duration: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.animationSpeed ?? 200) : 200
            easing.type: Easing.InOutQuad 
        }
    }

    // Save and load functions
    function saveItems() {
        Plasmoid.configuration.pinnedItems = PinnedManager.savePinned(root.pinnedItems)
    }

    function pinItem(item) {
        root.pinnedItems = PinnedManager.pinItem(root.pinnedItems, item, "global")
        saveItems()
    }
    
    function unpinItem(matchId) {
        root.pinnedItems = PinnedManager.unpinItem(root.pinnedItems, matchId, "global")
        saveItems()
    }

    function reorderPinned(fromIndex, toIndex) {
        root.pinnedItems = PinnedManager.reorderPinned(root.pinnedItems, fromIndex, toIndex)
        saveItems()
    }

    ColumnLayout {
        id: topLayout
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 0
        anchors.bottomMargin: 10
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
                    source: root.isExpanded ? "arrow-down" : "arrow-right"
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    color: Kirigami.Theme.highlightColor
                    
                    Behavior on rotation { NumberAnimation { duration: Plasmoid.configuration.animationSpeed ?? 200 } }
                }
                
                Kirigami.Icon {
                    source: "pin"
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    color: Kirigami.Theme.highlightColor
                }
                
                Text {
                    text: i18n("Pinned Items")
                    font.pixelSize: 12
                    font.bold: true
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: root.pinnedItems.length > 0 ? root.pinnedItems.length : ""
                    font.pixelSize: 10
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
                }
            }
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.isExpanded = !root.isExpanded
            }
        }
        
        // Pinned Container with DropArea
        Rectangle {
            id: containerRect
            property bool breezeStyle: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.breezeStyle ?? true) : true
            property int animDuration: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.animationSpeed ?? 200) : 200
            
            Layout.fillWidth: true
            Layout.preferredHeight: {
                if (!root.isExpanded) return 0;
                if (root.pinnedItems.length === 0) return 60; // Height for empty placeholder
                return tileFlow.implicitHeight + 16;
            }
            radius: 10
            color: breezeStyle ? "transparent" : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            border.color: breezeStyle ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3) : "transparent"
            border.width: breezeStyle ? 1 : 0
            clip: true
            
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: containerRect.animDuration; easing.type: Easing.InOutQuad }
            }
            
            DropArea {
                id: dropArea
                anchors.fill: parent
                
                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.highlightColor
                    opacity: dropArea.containsDrag ? 0.3 : 0
                    radius: 10
                    Behavior on opacity { NumberAnimation { duration: animDuration } }
                }
                
                onEntered: (drag) => {
                    drag.accept(Qt.LinkAction)
                }
                
                onDropped: (drop) => {
                    var serviceName = drop.getDataAsString("text/x-plasmoid-servicename")
                    if (serviceName) {
                        var title = serviceName.replace(".desktop", "").replace("org.kde.", "").split('.').pop()
                        title = title.charAt(0).toUpperCase() + title.slice(1)
                        var iconName = serviceName.replace(".desktop", "")
                        
                        root.pinItem({
                            filePath: "applications:" + serviceName,
                            matchId: serviceName,
                            display: title,
                            decoration: iconName
                        })
                        drop.accept()
                        return
                    }
                    if (drop.hasUrls) {
                        var url = drop.urls[0].toString()
                        var filename = url.split('/').pop()
                        var titleUrl = decodeURIComponent(filename.replace(".desktop", ""))
                        
                        root.pinItem({
                            filePath: url,
                            matchId: url,
                            display: titleUrl,
                            decoration: "application-x-executable"
                        })
                        drop.accept()
                    }
                }
            }
            
            // Empty State Text
            Text {
                anchors.centerIn: parent
                text: i18n("Drag applications here to pin")
                font.pixelSize: 12
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
                visible: root.pinnedItems.length === 0
            }
            
            // Tile Flow Container
            Flow {
                id: tileFlow
                visible: root.pinnedItems.length > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 8
                spacing: 8
                
                Repeater {
                    model: root.pinnedItems
                    
                    delegate: Item {
                        property real cellWidth: (tileFlow.width - (8 * 6)) / 7
                        width: Math.floor(cellWidth)
                        height: width + 30
                        
                        property bool isDragging: root.draggedIndex === index
                        
                        // Drop indicator
                        Rectangle {
                            visible: root.dropTargetIndex === index && root.draggedIndex !== index
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: parent.height - 8
                            radius: 1.5
                            color: Kirigami.Theme.highlightColor
                        }
                        
                        property bool breezeStyle: Plasmoid.configuration.breezeStyle ?? true
                        property int animDuration: (Plasmoid.configuration.animationSpeed ?? 200)
                        
                        Rectangle {
                            id: tileContent
                            anchors.fill: parent
                            color: breezeStyle 
                                ? ((tileMouse.containsMouse || isDragging) ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent")
                                : ((tileMouse.containsMouse || isDragging) ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05))
                            border.color: breezeStyle ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2) : "transparent"
                            border.width: breezeStyle ? 1 : 0
                            radius: 6
                            opacity: isDragging ? 0.6 : 1.0
                            
                            Behavior on color { ColorAnimation { duration: animDuration } }
                            Behavior on opacity { NumberAnimation { duration: animDuration } }
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                
                                Item {
                                    width: Kirigami.Units.iconSizes.large
                                    height: Kirigami.Units.iconSizes.large
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    
                                    Kirigami.Icon {
                                        anchors.fill: parent
                                        source: modelData.decoration || "application-x-executable"
                                        color: Kirigami.Theme.textColor
                                    }
                                    
                                    // Pin indicator
                                    Kirigami.Icon {
                                        source: "pin"
                                        width: 12
                                        height: 12
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: -2
                                        color: Kirigami.Theme.highlightColor
                                    }
                                }
                                
                                Text {
                                    text: modelData.display || ""
                                    width: parent.width - 4
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Kirigami.Theme.textColor
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    anchors.horizontalCenter: parent.horizontalCenter
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
                                    root.draggedIndex = index
                                }
                            }
                            
                            onReleased: (mouse) => {
                                if (root.draggedIndex !== -1 && root.dropTargetIndex !== -1) {
                                    if (root.draggedIndex !== root.dropTargetIndex) {
                                        root.reorderPinned(root.draggedIndex, root.dropTargetIndex)
                                    }
                                }
                                root.draggedIndex = -1
                                root.dropTargetIndex = -1
                                if (tileContent) {
                                    tileContent.x = 0
                                    tileContent.y = 0
                                }
                            }
                            
                            onPositionChanged: (mouse) => {
                                if (drag.active) {
                                    var globalPos = mapToItem(tileFlow, mouse.x, mouse.y)
                                    var tileTotalW = width + 8
                                    var targetIndex = Math.floor(globalPos.x / tileTotalW)
                                    targetIndex = Math.max(0, Math.min(targetIndex, root.pinnedItems.length - 1))
                                    root.dropTargetIndex = targetIndex
                                }
                            }
                            
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    contextMenu.actionItem = {
                                        display: modelData.display,
                                        decoration: modelData.decoration,
                                        matchId: modelData.matchId,
                                        filePath: modelData.filePath,
                                        category: "System" // Treat as app usually
                                    };
                                    contextMenu.popup()
                                } else if (!drag.active) {
                                    Qt.openUrlExternally(modelData.filePath)
                                    Plasmoid.expanded = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    AppContextMenu {
        id: contextMenu
    }
}
