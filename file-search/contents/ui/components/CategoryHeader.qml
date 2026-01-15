import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Category Header with separator line
// NOTE: This component is currently NOT USED. Consider using it in 
// ResultsTileView/HistoryTileView to replace inline category headers,
// or remove it in a future cleanup.
RowLayout {
    id: root
    
    // Required properties
    required property string categoryName
    required property color textColor
    
    width: parent ? parent.width : 200
    spacing: 8
    
    Text {
        text: root.categoryName
        font.pixelSize: 13
        font.bold: true
        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
    }
    
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.2)
    }
}
