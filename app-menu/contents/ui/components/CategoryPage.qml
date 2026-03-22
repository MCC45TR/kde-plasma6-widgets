import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

GridView {
    id: root
    
    required property var categoryModel
    
    clip: true
    anchors.margins: Kirigami.Units.smallSpacing
    cellWidth: Kirigami.Units.gridUnit * 6
    cellHeight: cellWidth + 30
    
    model: categoryModel
    
    ScrollBar.vertical: ScrollBar { active: true }
    
    delegate: Item {
        width: GridView.view.cellWidth
        height: GridView.view.cellHeight
        
        required property int index
        required property string display
        required property var decoration
        
        property bool isHovered: hoverArea.containsMouse
        
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.highlightColor
            opacity: isHovered ? 0.2 : 0
            radius: Kirigami.Units.smallSpacing
            
            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }
        }
        
        Column {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            width: parent.width
            
            Kirigami.Icon {
                source: decoration
                width: Kirigami.Units.iconSizes.medium
                height: Kirigami.Units.iconSizes.medium
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: display
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }
        }
        
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (root.categoryModel && root.categoryModel.trigger) {
                    root.categoryModel.trigger(index, "", null)
                    try { Plasmoid.expanded = false; } catch(e) {}
                }
            }
        }
    }
}
