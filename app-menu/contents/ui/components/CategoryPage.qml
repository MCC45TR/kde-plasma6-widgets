import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

GridView {
    id: root
    
    required property var categoryModel
    
    clip: true
    property bool breezeStyle: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.breezeStyle ?? true) : true
    property int animDuration: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.animationSpeed ?? 200) : 200
    property int iconSize: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.iconSize ?? 48) : 48
    property bool showLabels: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.showLabelsInTiles ?? true) : true

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
        property bool breezeStyle: root.breezeStyle
        property int animDuration: root.animDuration

        Rectangle {
            anchors.fill: parent
            color: breezeStyle 
                ? (isHovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent")
                : (isHovered ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15))
            opacity: 1
            border.color: breezeStyle ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2) : "transparent"
            border.width: breezeStyle ? 1 : 0
            radius: Kirigami.Units.smallSpacing
            
            Behavior on color { ColorAnimation { duration: animDuration } }
        }
        
        Column {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            width: parent.width
            
            Kirigami.Icon {
                source: decoration
                width: root.iconSize
                height: width
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
                visible: root.showLabels
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
