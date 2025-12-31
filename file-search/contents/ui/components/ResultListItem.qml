import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Single result item delegate for list view
Rectangle {
    id: root
    
    // Required properties
    required property string displayText
    required property string iconSource
    required property string parentFolder
    required property int iconSize
    required property color textColor
    required property color accentColor
    
    // Optional
    property bool showParentFolder: false
    
    // Signals
    signal clicked()
    
    width: parent ? parent.width : 200
    height: Math.max(44, iconSize + 18)
    color: mouseArea.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : "transparent"
    radius: 4
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10
        
        // Icon
        Kirigami.Icon {
            source: root.iconSource || "application-x-executable"
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
            color: root.textColor
        }
        
        // Result text with optional parent folder
        Column {
            Layout.fillWidth: true
            spacing: 1
            
            Text {
                text: root.displayText
                color: root.textColor
                font.pixelSize: 14
                elide: Text.ElideRight
                width: parent.width
            }
            
            // Parent folder for files
            Text {
                visible: root.showParentFolder && root.parentFolder.length > 0
                text: root.parentFolder
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)
                font.pixelSize: 10
                elide: Text.ElideMiddle
                width: parent.width
            }
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
