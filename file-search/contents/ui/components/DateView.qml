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
        
        RowLayout {
            anchors.centerIn: parent
            spacing: root.height * 0.05
            
            // Big Time - Scaled to fill height
            Text {
                text: root.timeStr
                // Scale based on height (roughly 40% of widget height)
                font.pixelSize: Math.min(root.height * 0.45, root.width * 0.3)
                font.weight: Font.Medium
                font.family: barlowMedium.name
                color: root.textColor
            }
            
            // Vertical Separator
            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: root.height * 0.35
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.3)
            }
            
            // Date Info
            ColumnLayout {
                spacing: -root.height * 0.02
                
                Text {
                    text: root.dayStr
                    font.pixelSize: Math.min(root.height * 0.15, root.width * 0.1)
                    font.weight: Font.Medium
                    font.family: barlowMedium.name
                    color: root.textColor
                }
                
                RowLayout {
                    spacing: root.height * 0.02
                    Text {
                        text: root.datePartStr
                        font.pixelSize: Math.min(root.height * 0.08, root.width * 0.06)
                        font.weight: Font.Light
                        font.family: barlowLight.name
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.7)
                    }
                    Text {
                        text: root.yearStr
                        font.pixelSize: Math.min(root.height * 0.08, root.width * 0.06)
                        font.weight: Font.Light
                        font.italic: true
                        font.family: barlowLightItalic.name
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.7)
                    }
                }
            }
        }
    }
}
