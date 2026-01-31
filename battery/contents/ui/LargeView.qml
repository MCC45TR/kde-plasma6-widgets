import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    property var devices: []
    property var mainDevice: null
    property string hostName: ""
    property string timeToEvent: ""
    property string currentPowerProfile: "balanced"
    signal setPowerProfile(string profile)

    // Large View: > 350 width, > 350 height
    // Image 3: 3 Tall Vertical Bars. 
    // Left: Main Laptop (Purple)
    // Center: Headset (Red)
    // Right: Mouse (Yellow)
    // No "Main Info Card" visible in Image 3??
    // WAIT. Image 3 (uploaded_media_2) is ONLY vertical bars.
    // Do I show Hostname/Time in Large logic?
    // Requirement 9: "Ayrıca HOST adı yazılacak geniş ve büyük görünümde."
    // So Large view MUST have Hostname.
    // Maybe Image 3 is just the 'Device List' part of Large view, or implies the style of bars.
    
    // Design Decision:
    // Container with multiple large vertical bars side-by-side.
    // Overlay host name somewhere or have a header?
    // Let's assume the bars take most space.
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        anchors.topMargin: 60 // Leave room for overlay header
        spacing: 16
        
        Repeater {
            model: devices // ALL devices including laptop
            
            BatteryBar {
                Layout.fillHeight: true
                Layout.fillWidth: true // Distribute evenly
                
                percentage: modelData.percentage
                iconName: modelData.icon
                isCharging: modelData.isCharging
                
                // Radius Logic:
                // First Item (Left): TopLeft & BottomLeft = 8
                // Last Item (Right): TopRight & BottomRight = 8
                // Others: 4
                radiusTopLeft: index === 0 ? 8 : 4
                radiusBottomLeft: index === 0 ? 8 : 4
                radiusTopRight: index === devices.length - 1 ? 8 : 4
                radiusBottomRight: index === devices.length - 1 ? 8 : 4
            }
        }
    }
    
    // Header Overlay with Hostname, Time-to-Event, and Power Profiles
    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 4
        
        Row {
            spacing: 12
            
            Text {
                text: hostName.toUpperCase()
                color: Kirigami.Theme.textColor
                font.pixelSize: 14
                font.bold: true
                opacity: 0.8
            }
            
            // Time-to-Event
            Text {
                text: timeToEvent
                visible: timeToEvent.length > 0
                font.pixelSize: 12
                font.bold: true
                color: mainDevice && mainDevice.isCharging ? Kirigami.Theme.positiveColor : Kirigami.Theme.neutralColor
            }
        }
        
        // Power Profile Row
        Row {
            spacing: 6
            
            Repeater {
                model: ["power-saver", "balanced", "performance"]
                
                Rectangle {
                    width: 28
                    height: 22
                    radius: 11
                    color: currentPowerProfile === modelData ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData === "power-saver" ? "🔋" : (modelData === "balanced" ? "⚖️" : "⚡")
                        font.pixelSize: 11
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.setPowerProfile(modelData)
                    }
                }
            }
        }
    }
}

