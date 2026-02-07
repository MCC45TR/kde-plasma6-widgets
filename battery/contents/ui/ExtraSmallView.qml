import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import "Formatter.js" as Formatter

Item {
    id: root
    
    // Props passed from main
    property var devices: []
    property var mainDevice: null
    property string hostName: ""
    property string finishTime: "" // New property
    property real remainingMsec: 0 // New property for relative time
    property string currentPowerProfile: "balanced"
    property bool hasPowerProfiles: true
    signal setPowerProfile(string profile)
    
    // View Mode (Adaptive) - Used for styling logic if needed
    property string viewMode: "extrasmall" 
    property string iconShape: "square" 
    property bool showChargingIcon: true
    property bool pillGeometry: false

    // Design Tokens (Passed from Main via BigView)
    property int backgroundRadius: 20
    property double opacityValue: 1.0
    property int barRadius: 10
    property int switchRadius: 10
    property int contentGap: 4 

    // Background Rectangle covering the whole view
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: root.backgroundRadius
        color: Kirigami.Theme.backgroundColor // Or transparent if main handles it? 
        // Based on previous code, the inner rectangle had this color. 
        // If main.qml has a background, this might be redundant or needed for the "card" look.
        // Let's assume we want a card look.
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.contentGap
            spacing: 2
            
            // 1. Top: Device Icon (Flexible Height)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    // Scale icon to fit, but leave space for text/switch
                    height: Math.min(parent.width, parent.height) * 1.0
                    width: height
                    source: mainDevice && mainDevice.deviceType === "desktop" ? "computer" : "computer-laptop"
                    color: Kirigami.Theme.textColor
                }
            }
            
            // 2. Middle: Hostname + Battery Percentage
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                
                text: {
                    var batt = mainDevice ? mainDevice.percentage : "--"
                    return hostName + " (" + batt + "%)"
                }
                
                color: Kirigami.Theme.textColor
                font.pixelSize: 12
                 // Matching other views
                elide: Text.ElideRight
                visible: true
            }
            
            // 3. Bottom: Power Profile Switcher
            PowerProfileSwitcher {
                Layout.fillWidth: true
                Layout.preferredHeight: 22 // Compact height
                currentProfile: root.currentPowerProfile
                radius: root.switchRadius
                onProfileChanged: (profile) => root.setPowerProfile(profile)
                visible: root.hasPowerProfiles && root.height > 100 // Hide if super small
            }
        }
    }
}
