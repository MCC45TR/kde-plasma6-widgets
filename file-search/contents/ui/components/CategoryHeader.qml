import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Reusable category heading with a separator.
RowLayout {
    id: root
    
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
