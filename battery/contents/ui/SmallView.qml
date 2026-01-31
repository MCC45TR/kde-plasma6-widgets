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
    
    // Small Mode: < 350w
    // Image 1: Looks like a compact vertical card.
    // Content: Big Percentage, Laptop Icon (right), Hostname, Remaining Time.
    // Bottom: Progress bars for peripherals?
    // Wait, Image 1 (uploaded_media_0) shows:
    // Top Half: %78, DEVICE_HOST_NAME, Remaining to 20:45. Right side: Laptop Icon in Circle.
    // Bottom Half: 3 horizontal bars (Yellow Mouse %25, Red Headset %12, Purple Keyboard %60).
    
    // Correct interpretation of Image 1: It is a vertical layout with "Main Info" on top, "Device List" on bottom.
    // Is this "Small"? 
    // User Requirement 8: "Küçüklük şartı genişlik 350 altında olacak."
    // If layout is vertical list, it fits "Small" (narrow) nicely.
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12
        
        // Top Card: Main Device
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 120 // Estimated
            
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(1, 1, 1, 0.05)
                radius: 16
                
                // Icon Circle Right
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 10
                    width: 90
                    height: 90
                    radius: 45
                    color: Qt.rgba(0,0,0,0.2)
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 50
                        height: 50
                        source: mainDevice ? mainDevice.icon : "computer-laptop"
                    }
                    Kirigami.Icon {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter // approx position
                        width: 20
                        height: 20
                        source: "battery-charging"
                        visible: mainDevice ? mainDevice.isCharging : false
                    }
                }
                
                // Text Info Left
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 110 // Avoid circle
                    
                    Text {
                        text: mainDevice ? "%" + mainDevice.percentage : "--"
                        font.pixelSize: 42
                        color: Kirigami.Theme.textColor
                    }
                    Text {
                        text: hostName.toUpperCase()
                        font.pixelSize: 12
                        color: Kirigami.Theme.textColor
                        opacity: 0.7
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    // Time-to-Event (dynamic estimation)
                    Text {
                        text: timeToEvent
                        font.pixelSize: 11
                        font.bold: true
                        color: mainDevice && mainDevice.isCharging ? Kirigami.Theme.positiveColor : Kirigami.Theme.neutralColor
                        opacity: 0.9
                        visible: timeToEvent.length > 0
                    }
                }
            }
        }
        
        // Power Profile Toggle Row
        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 6
            
            Repeater {
                model: ["power-saver", "balanced", "performance"]
                
                Rectangle {
                    width: (parent.width - 12) / 3
                    height: 28
                    radius: 14
                    color: currentPowerProfile === modelData ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData === "power-saver" ? "🔋" : (modelData === "balanced" ? "⚖️" : "⚡")
                        font.pixelSize: 14
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setPowerProfile(modelData)
                    }
                    
                    ToolTip.visible: profileMouse.containsMouse
                    ToolTip.text: modelData === "power-saver" ? i18n("Power Saver") : (modelData === "balanced" ? i18n("Balanced") : i18n("Performance"))
                    
                    MouseArea {
                        id: profileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setPowerProfile(modelData)
                    }
                }
            }
        }
        
        // Bottom List: Peripherals
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            
            Repeater {
                model: devices.filter(d => !d.isMain)
                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    
                    // Item bg (or just bar?)
                    // Image 1 shows colorful bars with icon inside, text inside.
                    // Like a horizontal progress bar but specific style.
                    
                    // Custom Horizontal Bar for Small View
                    Rectangle {
                        id: barBg
                        anchors.fill: parent
                        radius: 8
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) // Track color
                        
                        // Fill
                        Rectangle {
                            height: parent.height
                            width: parent.width * (modelData.percentage / 100)
                            radius: 8
                            
                            // Color logic
                            property color dynamicColor: {
                                if (modelData.percentage < 15) return Kirigami.Theme.negativeColor
                                if (modelData.percentage < 25) return Kirigami.Theme.neutralColor
                                return Kirigami.Theme.highlightColor // System Accent
                            }
                            color: dynamicColor
                            
                            // Blink animation logic (Requirement 6)
                            // "Pili çok az kalan cihazların (kırmızı renge geçen) ... blink animasyonu"
                            SequentialAnimation on opacity {
                                running: modelData.percentage < 15 && !modelData.isCharging
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.5; duration: 200 }
                                NumberAnimation { from: 0.5; to: 1.0; duration: 200 }
                                PauseAnimation { duration: 3000 }
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            
                            Kirigami.Icon {
                                source: modelData.icon
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                
                                property color monoColor: {
                                    if (modelData.percentage <= 10) return Kirigami.Theme.textColor
                                    if (modelData.percentage >= 15 && modelData.percentage < 25) return "black"
                                    return "white"
                                }
                                color: monoColor
                            }
                            
                            Text {
                                text: "%" + modelData.percentage
                                font.bold: true
                                color: Kirigami.Theme.textColor
                            }
                            
                            Item { Layout.fillWidth: true } // Spacer
                        }
                    }
                }
            }
        }
    }
}
