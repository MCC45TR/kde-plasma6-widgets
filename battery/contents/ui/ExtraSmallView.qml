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
    property int contentGap: 5 

    // Main Content - Directly filling the parent, no card Shape
    RowLayout {
        anchors.fill: parent
        anchors.margins: root.contentGap
        spacing: 5
        
        // Left Side: Rounded Square with Laptop Icon
        Item {
            // Square slot relative to height. 
            // RowLayout height is effectively parent.height - margins.
            Layout.preferredWidth: height
            Layout.fillHeight: true
            
            Rectangle {
                id: cihazSimgeKarosu
                anchors.fill: parent
                // Shape Logic
                radius: {
                    if (root.iconShape === "circle") return width / 2
                    if (root.iconShape === "rounded") return 20
                    // "square" (Default/Adaptive)
                    return root.backgroundRadius > 5 ? root.backgroundRadius - 5 : 5
                }
                color: Kirigami.Theme.backgroundColor // Keep the icon background for contrast
                
                Kirigami.Icon {
                    id: deviceIcon
                    anchors.centerIn: parent
                    
                    property real iconSize: (parent.width - 10) * (root.iconShape === "circle" ? 0.66 : 1.0)
                    width: iconSize
                    height: iconSize
                    source: "computer-laptop"
                    color: Kirigami.Theme.textColor
                }

                TextMetrics {
                    id: tm
                    font.pixelSize: deviceIcon.height * 0.8
                    font.family: "Roboto Condensed"
                    font.weight: Font.Light
                    text: "%" + (mainDevice ? mainDevice.percentage : "")
                }
            }
        }

        // Right Side: Text Info
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            Layout.alignment: Qt.AlignVCenter
            
            // Percentage Row
            RowLayout {
                visible: true
                spacing: 2
                Layout.fillWidth: true 
                
                    Text {
                    id: percentageText
                    
                    TextMetrics {
                        id: tmPercentage
                        font: percentageText.font
                        text: "%" + (mainDevice ? mainDevice.percentage : "")
                    }
                    
                    text: {
                        if (!mainDevice) return "--"
                        if (mainDevice.deviceType === "desktop") return mainDevice.percentage + " W"
                        
                        // Check overflow
                        var available = parent.width - 36 - 5
                        // If full text is wider than available, drop the '%'
                        if (tmPercentage.width > available && available > 0) return mainDevice.percentage
                        
                        return "%" + mainDevice.percentage
                    }
                    color: Kirigami.Theme.textColor
                    font.pixelSize: Math.max(20, Math.min(36, parent.height * 0.40)) // Adaptive font size
                    font.family: "Roboto Condensed" 
                    font.weight: Font.Light
                    lineHeight: 0.8
                    Layout.fillWidth: true
                    elide: Text.ElideNone
                    
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 16 
                }
                // Small Battery Icon next to it
                Kirigami.Icon {
                    source: mainDevice && mainDevice.isCharging ? "battery-charging" : "battery-060" 
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    color: Kirigami.Theme.textColor
                }
            }
            
            // Hostname
            Text {
                visible: true
                text: hostName.toUpperCase().replace(/\n/g, " ")
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.9)
                font.pixelSize: 14 // Fİxed small size
                font.bold: true
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            
            // Power Profile Switcher (Compact version if possible, or same)
            // If space is very tight, checking visibility
            PowerProfileSwitcher {
                visible: root.hasPowerProfiles && root.height > 80 // Only show if height allows
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                Layout.topMargin: 2
                currentProfile: root.currentPowerProfile
                radius: root.switchRadius
                onProfileChanged: (profile) => root.setPowerProfile(profile)
            }
        }
    }
}
