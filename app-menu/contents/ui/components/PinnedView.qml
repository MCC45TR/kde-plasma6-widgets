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
        anchors.fill: parent
        onEntered: (drag) => {
            // Check if valid app drag
            // In Plasma, app drags usually have mimeData
        }
        onDropped: (drop) => {
            if (drop.hasUrls) {
                // Parse URL to find .desktop file or similar
                // This is simplified; robust implementation needs MimeType checking
                 var url = drop.urls[0].toString()
                 // Mock item for now, needs real resolution logic
                 if (url.endsWith(".desktop")) {
                     // Need to resolve name/icon from desktop file. 
                     // Since we can't easily read files here without a helper, 
                     // we might need to rely on what data is available in drop keys.
                     // Often drop.text contains the url.
                     // For now, let's assume we can get some info.
                     // LogicController in file-search handles this via history adds.
                     
                     // Placeholder:
                     // root.pinItem({url: url, display: "App", decoration: "application-x-executable"})
                 }
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
