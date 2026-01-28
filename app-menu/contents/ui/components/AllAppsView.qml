import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

ScrollView {
    id: root
    
    required property var model // The flat Kicker model
    
    contentWidth: availableWidth
    
    ListModel {
        id: sectionsModel
    }

    function refreshModel() {
        sectionsModel.clear()
        if (!root.model) return

        let count = root.model.count
        let groups = {}

        for (let i = 0; i < count; i++) {
            let idx = root.model.index(i, 0);
            let name = root.model.data(idx, Qt.DisplayRole)
            let icon = root.model.data(idx, Qt.DecorationRole)
            
            if (!name) continue;
            
            let char = name.charAt(0).toUpperCase()
            
            // Check if it's a letter (including extended latin/turkish)
            // Regex for letters: \p{L}. But JS regex support depends on engine.
            // Simple check: toUpperCase != toLowerCase usually implies letter.
            if (char.toLowerCase() === char.toUpperCase()) {
                 // Likely number or symbol
                 char = "#"
            }

            if (!groups[char]) {
                groups[char] = []
            }
            groups[char].push({
                name: name,
                icon: icon,
                originalIndex: i
            })
        }

        let sortedKeys = Object.keys(groups).sort((a, b) => a.localeCompare(b, Qt.locale().name))
        
        for (let key of sortedKeys) {
            sectionsModel.append({
                section: key,
                apps: groups[key]
            })
        }
    }
    
    Connections {
        target: root.model
        function onCountChanged() { refreshModel() }
        function onModelReset() { refreshModel() }
    }
    
    Component.onCompleted: {
        refreshModel()
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: sectionsModel
        clip: true
        
        delegate: ColumnLayout {
            width: ListView.view.width
            spacing: 5
            
            // Section Header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 10
                spacing: 10
                
                Text {
                    text: model.section
                    font.bold: true
                    color: Kirigami.Theme.highlightColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Kirigami.Theme.separatorColor
                    opacity: 0.5
                }
            }
            
            // Grid of Apps (Flow)
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: 10
                spacing: 10
                
                Repeater {
                    model: model.apps
                    
                    delegate: Item {
                        // Tile dimensions
                        width: Kirigami.Units.gridUnit * 6
                        height: width + 30
                        
                        // Content
                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            width: parent.width
                            
                            Kirigami.Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: modelData.icon
                                width: Kirigami.Units.iconSizes.medium
                                height: Kirigami.Units.iconSizes.medium
                            }
                            
                            Text {
                                text: modelData.name
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                color: Kirigami.Theme.textColor
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                visible: Plasmoid.configuration.showLabelsInTiles
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.model) {
                                    root.model.trigger(modelData.originalIndex, "", null)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
