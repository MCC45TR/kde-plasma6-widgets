import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// ForecastItem.qml - Responsive Forecast Card Component
Item {
    id: itemRoot
    
    // Required properties from delegate
    required property string label // "FRI" or "5 PM"
    required property string iconPath
    required property int temp
    required property bool isHourly
    
    // Responsive sizing properties
    property real availableWidth: 300  // Total ListView width
    property int cardCount: 5           // Number of cards
    property real cardSpacing: 2        // Spacing between cards
    
    // Calculate responsive width: divide available space equally
    readonly property real calculatedWidth: Math.max(55, Math.min(110, 
        (availableWidth - cardSpacing * (cardCount - 1)) / Math.max(1, cardCount)))
    
    implicitWidth: calculatedWidth
    implicitHeight: parent ? parent.height : 120
    
    // Card Background - Simple uniform radius (no patch approach)
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1  // Slight margin to prevent edge clipping
        radius: Math.min(25, width * 0.25)  // Responsive radius
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
        
        // Hover effect
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Kirigami.Theme.highlightColor
            opacity: mouseArea.containsMouse ? 0.15 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
    
    // Content Column (centered)
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4
        
        // Weather Icon (scales with card size)
        Image {
            source: itemRoot.iconPath
            Layout.preferredWidth: Math.min(itemRoot.width * 0.5, 60)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignHCenter
            sourceSize.width: 120
            sourceSize.height: 120
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
        }
        
        // Day/Time Label
        Text {
            text: itemRoot.label
            color: Kirigami.Theme.textColor
            font.family: "Roboto Condensed"
            font.bold: true
            font.pixelSize: Math.max(10, Math.min(16, itemRoot.width * 0.18))
            Layout.alignment: Qt.AlignHCenter
            elide: Text.ElideRight
            Layout.maximumWidth: parent.width - 8
        }
        
        // Temperature
        Text {
            text: itemRoot.temp + "°"
            color: Kirigami.Theme.textColor
            font.family: "Roboto Condensed"
            font.bold: true
            font.pixelSize: Math.max(12, Math.min(22, itemRoot.width * 0.25))
            Layout.alignment: Qt.AlignHCenter
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
