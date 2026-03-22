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
    model: runnerModel
    
    ScrollBar.vertical: ScrollBar { active: true }
    
    delegate: Item {
        width: ListView.view.width
        height: Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 2
        
        property bool isHovered: hoverArea.containsMouse
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 5
            color: Kirigami.Theme.highlightColor
            opacity: isHovered ? 0.2 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
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
            onClicked: {
                if (root.runnerModel) {
                    root.runnerModel.trigger(index, "", null)
                    Plasmoid.expanded = false // close launcher on run
                }
            }
        }
    }
}
