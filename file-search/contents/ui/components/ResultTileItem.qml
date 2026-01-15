import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Single tile item delegate for tile/grid view
// NOTE: This component is currently NOT USED. ResultsTileView uses inline delegate.
// Consider integrating this component for better modularity or remove in future cleanup.
Item {
    id: root
    
    // Required properties
    required property string displayText
    required property string iconSource
    required property int iconSize
    required property color textColor
    required property color accentColor
    
    // Signals
    signal clicked()
    
    width: iconSize + 40
    height: iconSize + 50
    
    Rectangle {
        id: tileBg
        anchors.fill: parent
        radius: 8
        color: mouseArea.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15) : "transparent"
        
        Column {
            anchors.centerIn: parent
            spacing: 6
            
            // Icon with configurable size
            Kirigami.Icon {
                width: root.iconSize
                height: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
                source: root.iconSource || "application-x-executable"
                color: root.textColor
            }
            
            // Text below icon
            Text {
                width: root.iconSize + 32
                text: root.displayText
                color: root.textColor
                font.pixelSize: root.iconSize > 32 ? 11 : 9
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
