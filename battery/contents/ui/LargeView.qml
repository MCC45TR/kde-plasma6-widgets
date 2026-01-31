import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    property var devices: []
    property var mainDevice: null
    property string hostName: ""

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
    
    // Overlay Text for Hostname?
    // "HOST adı yazılacak ... büyük görünümde"
    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        text: hostName.toUpperCase()
        color: Kirigami.Theme.textColor
        style: Text.Outline
        styleColor: Kirigami.Theme.backgroundColor
        visible: devices.length > 0
    }
}
