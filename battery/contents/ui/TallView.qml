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
    
    // View Mode (Adaptive)
    property string viewMode: "big" // "small", "wide", "big"
    property string iconShape: "square" // "square", "rounded", "circle"
    property bool showChargingIcon: true
    property bool pillGeometry: false

    // Design Tokens (Passed from Main via BigView)
    property int backgroundRadius: 20
    property double opacityValue: 1.0
    property int barRadius: 10
    property int switchRadius: 10
    property int contentGap: 10

    // Layout: Vertical Stack
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.contentGap
        spacing: root.contentGap
        
        // --- TOP SECTION (Main Card) ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 134
            
            Shape {
                id: deviceInfoCard
                anchors.fill: parent
                
                // Radius Logic - ensure non-negative
                readonly property int topRadius: Math.max(0, root.backgroundRadius - root.contentGap)
                readonly property int bottomRadius: topRadius
                
                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1 * root.opacityValue)
                    
                    startX: 0; startY: deviceInfoCard.topRadius
                    
                    // Top Left Corner
                    PathArc { 
                        x: deviceInfoCard.topRadius
                        y: 0
                        radiusX: deviceInfoCard.topRadius
                        radiusY: deviceInfoCard.topRadius
                    }
                    
                    // Top Edge
                    PathLine { x: deviceInfoCard.width - deviceInfoCard.topRadius; y: 0 }
                    
                    // Top Right Corner
                    PathArc { 
                        x: deviceInfoCard.width
                        y: deviceInfoCard.topRadius
                        radiusX: deviceInfoCard.topRadius
                        radiusY: deviceInfoCard.topRadius
                    }
                    
                    // Right Edge
                    PathLine { x: deviceInfoCard.width; y: deviceInfoCard.height - deviceInfoCard.bottomRadius }
                    
                    // Bottom Right Corner
                    PathArc { 
                        x: deviceInfoCard.width - deviceInfoCard.bottomRadius
                        y: deviceInfoCard.height
                        radiusX: deviceInfoCard.bottomRadius
                        radiusY: deviceInfoCard.bottomRadius
                    }
                    
                    // Bottom Edge
                    PathLine { x: deviceInfoCard.bottomRadius; y: deviceInfoCard.height }
                    
                    // Bottom Left Corner
                    PathArc { 
                        x: 0
                        y: deviceInfoCard.height - deviceInfoCard.bottomRadius
                        radiusX: deviceInfoCard.bottomRadius
                        radiusY: deviceInfoCard.bottomRadius
                    }
                    
                    // Left Edge (Close path)
                    PathLine { x: 0; y: deviceInfoCard.topRadius }
                }
                
                // Main Device Content
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5
                    
                    // Left Side: Rounded Square with Laptop Icon
                    Item {
                        // Square slot relative to height. 
                        // RowLayout height is effectively parent.height - 10 (margins).
                        // We want this item to be square.
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
                                return deviceInfoCard.topRadius - 5
                            }
                            color: Kirigami.Theme.backgroundColor
                            
                            Kirigami.Icon {
                                id: deviceIcon
                                anchors.centerIn: parent
                                
                                property real iconSize: (parent.width - 20) * (root.iconShape === "circle" ? 0.66 : 1.0)
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
                            spacing: 4
                            Layout.fillWidth: true // Constrain to parent width
                            
                            Text {
                                id: percentageText
                                property bool usePercent: true
                                
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
                                font.pixelSize: Math.max(36, deviceInfoCard.height * 0.40) // Target size
                                font.family: "Roboto Condensed" 
                                font.weight: Font.Light
                                lineHeight: 0.8
                                Layout.fillWidth: true
                                elide: Text.ElideNone
                                
                                fontSizeMode: Text.HorizontalFit
                                minimumPixelSize: 24 // Don't go smaller than this
                            }
                            // Small Battery Icon next to it
                            Kirigami.Icon {
                                source: mainDevice && mainDevice.isCharging ? "battery-charging" : "battery-060" 
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignVCenter
                                color: Kirigami.Theme.textColor
                            }
                        }
                        
                        // Hostname
                        Text {
                            visible: true
                            text: hostName.toUpperCase().replace(/\n/g, " ")
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.9)
                            font.pixelSize: deviceInfoCard.height < 60 ? 14 : 20
                            font.bold: true
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        
                        // Estimated Time Remaining (below hostname)
                        Text {
                            visible: remainingMsec > 0
                            text: Formatter.formatDuration(remainingMsec)
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                            font.pixelSize: deviceInfoCard.height < 60 ? 12 : 14
                            Layout.fillWidth: true
                        }
                        
                        // Time Remaining (Absolute Timestamp)
                        Text {
                            text: finishTime ? i18n("Remaining to %1", finishTime) : ""
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                            font.pixelSize: 13
                            visible: finishTime.length > 0
                        }
                        
                        // Spacer
                        Item { height: 4 }
                        
                        // Power Profile Switcher
                        PowerProfileSwitcher {
                            visible: root.hasPowerProfiles
                            width: 140
                            height: 30
                            currentProfile: root.currentPowerProfile
                            radius: root.switchRadius
                            onProfileChanged: (profile) => root.setPowerProfile(profile)
                        }
                    }
                }
            }
        }
        

        // --- BOTTOM SECTION (Peripheral List) ---
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: true
            snapMode: ListView.SnapToItem
            spacing: 5
            clip: true
            
            model: devices.filter(d => !d.isMain)
            
            delegate: Item {
                id: delegateRoot
                width: ListView.view.width
                
                readonly property int itemCount: ListView.view.count
                readonly property real calculatedHeight: {
                    var totalH = ListView.view.height
                    var sp = ListView.view.spacing
                    var minH = 40
                    
                    var maxFit = Math.floor((totalH + sp) / (minH + sp))
                    maxFit = Math.max(1, maxFit)
                    
                    var effectiveCount = (itemCount > maxFit) ? maxFit : itemCount
                    
                    return (totalH - (sp * (effectiveCount - 1))) / effectiveCount
                }
                
                height: calculatedHeight
                
                HorizontalBatteryBar {
                    anchors.fill: parent
                    // If main device (and named generic "Laptop"), show real hostname
                    deviceName: modelData.isMain && (modelData.name === "Laptop" || modelData.name === "") ? root.hostName : modelData.name
                    deviceIcon: modelData.icon
                    percentage: modelData.percentage
                    isCharging: modelData.isCharging === true
                    showChargingIcon: root.showChargingIcon
                    barRadius: root.barRadius
                    pillGeometry: root.pillGeometry
                }
            }
        }
    }
}
