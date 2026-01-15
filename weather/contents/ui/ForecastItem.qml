import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// ForecastItem.qml - Reusable forecast item component
Item {
    id: itemRoot
    
    required property string label // "FRI" or "5 PM"
    required property string iconPath
    required property int temp
    required property bool isHourly
    
    implicitWidth: isHourly ? 50 : 55
    implicitHeight: column.implicitHeight
    
    ColumnLayout {
        id: column
        anchors.centerIn: parent
        width: parent.width
        spacing: 2
        
        // Label (Day or Time)
        Text {
            text: itemRoot.label
            color: Kirigami.Theme.textColor
            font.bold: true
            font.pixelSize: 11
            Layout.alignment: Qt.AlignHCenter
            opacity: 0.9
        }
        
        // Weather Icon
        Image {
            source: itemRoot.iconPath
            Layout.preferredWidth: isHourly ? 32 : 38
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignHCenter
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        
        // Temperature
        Text {
            text: itemRoot.temp + "°"
            color: Kirigami.Theme.textColor
            font.bold: true
            font.pixelSize: isHourly ? 12 : 13
            Layout.alignment: Qt.AlignHCenter
        }
    }
    
    // Hover effect
    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.highlightColor
        opacity: mouseArea.containsMouse ? 0.1 : 0
        radius: 5
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
