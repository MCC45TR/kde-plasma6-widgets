import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

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
    
    function formatDuration(msec) {
        if (msec <= 0) return ""
        var totalMins = Math.floor(msec / 60000)
        
        if (totalMins < 60) {
            return i18nc("minutes", "%1 m", totalMins)
        } else if (totalMins < 1440) {
            var h = Math.floor(totalMins / 60)
            var m = totalMins % 60
            return i18nc("hours and minutes", "%1 h %2 m", h, m)
        } else {
            var d = Math.floor(totalMins / 1440)
            var h = Math.round((totalMins % 1440) / 60)
            if (h === 24) { d++; h = 0; }
            return i18nc("days and hours", "%1 d %2 h", d, h)
        }
    }

    // View Mode (Adaptive)
    property string viewMode: "big" // "small", "wide", "big"
    property string iconShape: "square" // "square", "rounded", "circle"
    property bool showChargingIcon: true
    property string backgroundOpacity: "full"
    property string cornerRadius: "normal"
    property bool pillGeometry: false

    // Design Tokens
    readonly property int backgroundRadius: cornerRadius === "normal" ? 20 : (cornerRadius === "small" ? 10 : 0)
    readonly property double opacityValue: {
        switch(backgroundOpacity) {
            case "full": return 1.0
            case "high": return 0.75
            case "medium": return 0.5
            case "low": return 0.25
            case "none": return 0.0
            default: return 1.0
        }
    }
    readonly property int barRadius: cornerRadius === "normal" ? 10 : (cornerRadius === "small" ? 5 : 0)
    readonly property int switchRadius: Math.max(0, backgroundRadius - contentGap)
    readonly property int contentGap: 10

    // Layout: 50/50 vertical split
    // Layout: Adaptive
    GridLayout {
        anchors.fill: parent
        anchors.margins: root.contentGap
        rowSpacing: root.contentGap
        columnSpacing: root.contentGap
        columns: 2
        

        // --- TOP SECTION (Main Card) ---
        Item {
            Layout.fillWidth: false
            Layout.preferredWidth: height < (root.width / 2) ? height : (root.width / 2)
            Layout.fillHeight: true
            
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
                    
                    // Left Side: Rounded Square with Laptop Icon (Swapped)
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
                            color: "transparent"
                            
                            Kirigami.Icon {
                                id: deviceIcon
                                anchors.centerIn: null
                                anchors.top: parent.top
                                anchors.left: parent.left
                                
                                property real iconSize: (parent.width - 20) * (root.iconShape === "circle" ? 0.66 : 1.0) * 0.44
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

                            Text {
                                id: widePercentText
                                visible: true
                                anchors.left: deviceIcon.right
                                anchors.verticalCenter: deviceIcon.verticalCenter
                                anchors.right: parent.right
                                anchors.leftMargin: 5
                                
                                color: Kirigami.Theme.textColor
                                font.pixelSize: deviceIcon.height * 0.8
                                font.family: "Roboto Condensed" 
                                font.weight: Font.Light
                                elide: Text.ElideRight
                                
                                text: {
                                    if (!mainDevice) return "--"
                                    if (mainDevice.deviceType === "desktop") {
                                        return mainDevice.percentage + " W"
                                    }
                                    return "%" + mainDevice.percentage
                                }
                            }
                            
                            Column {
                                visible: true
                                anchors.top: deviceIcon.bottom
                                anchors.left: deviceIcon.left
                                anchors.leftMargin: 5
                                anchors.topMargin: -5
                                spacing: 0
                                
                                Text {
                                    text: hostName.toUpperCase().replace(/\n/g, " ")
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.9)
                                    font.pixelSize: deviceInfoCard.height < 60 ? 14 : 20
                                    font.bold: true
                                }
                                
                                Text {
                                    text: formatDuration(remainingMsec)
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
                                    font.pixelSize: 12
                                    font.bold: false
                                    visible: remainingMsec > 0
                                }
                            }
                        }
                    }

                    // Right Side: Text Info (Not used in Wide mode mostly)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter
                        
                        // Percentage Row
                        RowLayout {
                            visible: false // Not visible in wide mode
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
                            visible: false // Not visible in wide mode
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
                            visible: false // Not visible in wide mode
                            text: formatDuration(remainingMsec)
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
                            visible: false // Not visible in wide mode
                            width: 140
                            height: 30
                            currentProfile: root.currentPowerProfile
                            radius: root.switchRadius
                            onProfileChanged: (profile) => root.setPowerProfile(profile)
                        }
                    }
                }

                PowerProfileSwitcher {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 5
                    visible: root.hasPowerProfiles
                    width: parent.width - 10
                    height: 30
                    currentProfile: root.currentPowerProfile
                    radius: root.switchRadius
                    onProfileChanged: (profile) => root.setPowerProfile(profile)
                }
            }
        }
        

        // --- BOTTOM SECTION (Peripheral List) ---
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: true
            spacing: 5
            clip: true
            
            model: {
                if (root.viewMode === "small" || root.viewMode === "extrasmall") {
                    // Show all devices, ensure Main is first
                    var main = devices.filter(d => d.isMain);
                    var others = devices.filter(d => !d.isMain);
                    return main.concat(others);
                }
                return devices.filter(d => !d.isMain)
            }
            
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
