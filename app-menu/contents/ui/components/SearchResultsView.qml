import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

ListView {
    id: root
    
    required property var runnerModel
    
    clip: true
    focus: true
    
    property bool breezeStyle: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.breezeStyle ?? true) : true
    property int animDuration: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.animationSpeed ?? 200) : 200

    model: runnerModel
    
    ScrollBar.vertical: ScrollBar { active: true }
    
    delegate: Item {
        width: ListView.view.width
        height: Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 2
        
        property bool isHovered: hoverArea.containsMouse
        
        property bool breezeStyle: root.breezeStyle
        property int animDuration: root.animDuration
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 5
            color: breezeStyle 
                ? (isHovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent")
                : (isHovered ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2))
            opacity: 1
            border.color: breezeStyle ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2) : "transparent"
            border.width: breezeStyle ? 1 : 0
            
            Behavior on color {
                ColorAnimation { duration: animDuration }
            }
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
            
            Kirigami.Icon {
                source: model.decoration
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                
                Text {
                    Layout.fillWidth: true
                    text: model.display
                    elide: Text.ElideRight
                    color: Kirigami.Theme.textColor
                    font.weight: Font.Bold
                }
                Text {
                    Layout.fillWidth: true
                    text: model.description || ""
                    elide: Text.ElideRight
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    visible: text !== ""
                }
            }
        }
        
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    localContextMenu.actionItem = {
                        display: model.display,
                        decoration: model.decoration,
                        matchId: model.display, // fallback
                        category: "System",
                        filePath: model.url || "",
                        triggerFunc: function() {
                            if (root.runnerModel) {
                                root.runnerModel.trigger(index, "", null)
                                Plasmoid.expanded = false
                            }
                        }
                    };
                    localContextMenu.popup();
                } else {
                    if (root.runnerModel) {
                        root.runnerModel.trigger(index, "", null)
                        Plasmoid.expanded = false // close launcher on run
                    }
                }
            }
        }
    }
    
    AppContextMenu {
        id: localContextMenu
    }
}
