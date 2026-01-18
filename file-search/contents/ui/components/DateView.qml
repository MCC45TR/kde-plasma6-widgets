import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    required property color textColor
    
    // Timer to update time
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateTime()
    }
    
    property string timeStr: ""
    property string dayStr: ""
    property string datePartStr: ""
    property string yearStr: ""
    
    function updateTime() {
        var now = new Date()
        timeStr = now.toLocaleTimeString(Qt.locale(), "HH:mm")
        dayStr = now.toLocaleDateString(Qt.locale(), "dddd")
        datePartStr = now.toLocaleDateString(Qt.locale(), "d MMMM")
        yearStr = now.toLocaleDateString(Qt.locale(), "yyyy")
    }
    
    Component.onCompleted: updateTime()

    // Font Loaders
    FontLoader { id: barlowMedium; source: "../../fonts/BarlowCondensed-Medium.ttf" }
    FontLoader { id: barlowLight; source: "../../fonts/BarlowCondensed-Light.ttf" }
    FontLoader { id: barlowLightItalic; source: "../../fonts/BarlowCondensed-LightItalic.ttf" }
    
    Rectangle {
        anchors.fill: parent
        anchors.margins: 0
        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
        radius: 12
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.height * 0.05 // Dynamic margins
            spacing: 0
            
            // Time Area - Takes remaining space
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.fill: parent
                    text: root.timeStr

                    // Fit to width/height automatically
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 20
                    font.pixelSize: 1000 // Arbitrary max

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom // Push text down to reduce gap with Day text

                    font.weight: Font.Light
                    font.italic: true
                    font.family: barlowLightItalic.name
                    color: root.textColor
                }
            }

            // Day
            Text {
                Layout.preferredWidth: parent.width * 0.5
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter

                text: root.dayStr

                // Fit to 50% width
                fontSizeMode: Text.Fit
                minimumPixelSize: 10
                // Relative max size to prevent exploding on short text
                font.pixelSize: root.height * 0.25

                font.weight: Font.Medium
                font.family: barlowMedium.name
                color: root.textColor
            }

            // Date + Year
            Text {
                Layout.preferredWidth: parent.width * 0.5
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter

                text: root.datePartStr + " " + root.yearStr

                // Fit to 50% width
                fontSizeMode: Text.Fit
                minimumPixelSize: 10
                // Relative max size
                font.pixelSize: root.height * 0.15

                font.weight: Font.Light
                font.family: barlowLight.name
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.85)
            }
        }
    }
}
