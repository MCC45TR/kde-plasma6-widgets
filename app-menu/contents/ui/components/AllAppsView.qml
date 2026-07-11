import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

ScrollView {
    id: root
    
    required property var model // The flat Kicker model
    
    contentWidth: availableWidth
    
    property bool breezeStyle: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.breezeStyle ?? true) : true
    property int animDuration: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.animationSpeed ?? 200) : 200
    property int iconSize: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.iconSize ?? 48) : 48
    property bool showLabels: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.showLabelsInTiles ?? true) : true

    property var sectionsList: []

    function refreshModel() {
        var tempList = []
        if (!root.model) {
            sectionsList = tempList
            return
        }

        let count = root.model.count
        let groups = {}

        for (let i = 0; i < count; i++) {
            let idx = root.model.index(i, 0);
            let name = root.model.data(idx, Qt.DisplayRole)
            let icon = root.model.data(idx, Qt.DecorationRole)
            
            if (!name) continue;
            
            let char = name.charAt(0).toUpperCase()
            
            // Case conversion detects letters without relying on Unicode regex support.
            if (char.toLowerCase() === char.toUpperCase()) {
                 // Group numbers and symbols together.
                 char = "#"
            }

            
            // Preserve the source index because Kicker does not expose URL roles consistently.
            
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
            tempList.push({
                section: key,
                apps: groups[key]
            })
        }
        sectionsList = tempList
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
        model: sectionsList
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
                    text: modelData.section
                    font.bold: true
                    color: Kirigami.Theme.highlightColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
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
                    model: modelData.apps
                    
                    delegate: Item {
                        // Tile dimensions
                        width: Kirigami.Units.gridUnit * 6
                        height: width + 30
                        
                        property bool isHovered: hoverArea.containsMouse
                        
                        property bool breezeStyle: root.breezeStyle
                        property int animDuration: root.animDuration
                        
                        Rectangle {
                            anchors.fill: parent
                            color: breezeStyle 
                                ? (isHovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent")
                                : (isHovered ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2))
                            opacity: 1
                            border.color: breezeStyle ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2) : "transparent"
                            border.width: breezeStyle ? 1 : 0
                            radius: Kirigami.Units.smallSpacing
                            
                            Behavior on color {
                                ColorAnimation { duration: animDuration }
                            }
                        }
                        
                        // Content
                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            width: parent.width
                            
                            Kirigami.Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: modelData.icon
                                width: root.iconSize
                                height: width
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
                                visible: root.showLabels
                            }
                        }
                        
                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    contextMenu.actionItem = {
                                        display: modelData.name,
                                        decoration: modelData.icon,
                                        matchId: modelData.name, // Usually matchId is desktop entry name, but we only have name here
                                        category: "System", // Treat as app to show "Edit Application"
                                        triggerFunc: function() {
                                            if (root.model) {
                                                root.model.trigger(modelData.originalIndex, "", null)
                                                Plasmoid.expanded = false
                                            }
                                        }
                                    };
                                    contextMenu.popup();
                                } else {
                                    if (root.model) {
                                        root.model.trigger(modelData.originalIndex, "", null)
                                        Plasmoid.expanded = false
                                    }
                                }
                            }
                        }
                    }
                } // Ends Repeater
            } // Ends Flow
        } // Ends delegate ColumnLayout
    } // Ends ListView
    
    AppContextMenu {
        id: contextMenu
    }
} // Ends ScrollView
