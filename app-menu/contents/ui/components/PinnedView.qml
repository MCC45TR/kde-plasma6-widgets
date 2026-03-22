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
    
    visible: pinnedItems && pinnedItems.length > 0
    
    // Save function
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

    implicitHeight: (grid.cellHeight * Math.ceil(Math.min(14, Math.max(7, grid.count)) / 7)) + 20 // Approx height: max 2 rows or dynamic
    
    DropArea {
        id: dropArea
        anchors.fill: parent
        
        property bool isDragActive: containsDrag
        
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.highlightColor
            opacity: dropArea.isDragActive ? 0.3 : 0
            radius: Kirigami.Units.largeSpacing
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }
        
        onEntered: (drag) => {
            drag.accept(Qt.LinkAction)
        }
        
        onDropped: (drop) => {
            var serviceName = drop.getDataAsString("text/x-plasmoid-servicename")
            if (serviceName) {
                var title = serviceName.replace(".desktop", "").replace("org.kde.", "").split('.').pop()
                // Capitalize first letter
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

    GridView {
        id: grid
        anchors.fill: parent
        anchors.margins: 10
        cellWidth: width / 7
        cellHeight: cellWidth + 20
        
        model: root.pinnedItems
        
        delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    source: modelData.decoration
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Kirigami.Units.iconSizes.large
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: modelData.display
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: Kirigami.Theme.textColor
                }
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                         Qt.openUrlExternally(modelData.filePath)
                    } else {
                        contextMenu.popup()
                    }
                }
            }
            
            Menu {
                id: contextMenu
                MenuItem {
                    text: i18n("Unpin")
                    icon.name: "window-unpin"
                    onTriggered: root.unpinItem(modelData.matchId)
                }
            }
        }
    }
}
