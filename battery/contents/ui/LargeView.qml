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
        columns: root.viewMode === "wide" ? 2 : 1
        
        // --- TOP SECTION (Main Card) ---
        Item {
            Layout.fillWidth: root.viewMode !== "wide"
            Layout.preferredWidth: {
                if (root.viewMode === "wide") {
                     return height < (root.width / 2) ? height : (root.width / 2)
                }
                return -1
            }
            // Fill height only if it's the only item (small/extrasmall) or side-by-side (wide)
            Layout.fillHeight: root.viewMode === "small" || root.viewMode === "extrasmall" || root.viewMode === "wide"
            
            // Fixed 134px height for Large/Tall modes (where it stacks vertically with list)
            Layout.preferredHeight: (root.viewMode === "big" || root.viewMode === "tall") ? 134 : -1
            
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
                            color: root.viewMode === "wide" ? "transparent" : Kirigami.Theme.backgroundColor
                            
                            Kirigami.Icon {
                                id: deviceIcon
                                anchors.centerIn: root.viewMode === "wide" ? null : parent
                                anchors.top: root.viewMode === "wide" ? parent.top : undefined
                                anchors.left: root.viewMode === "wide" ? parent.left : undefined
                                
                                property real iconSize: (parent.width - 20) * (root.iconShape === "circle" ? 0.66 : 1.0) * (root.viewMode === "wide" ? 0.44 : 1.0)
                                width: iconSize
                                height: iconSize
                                source: "computer-laptop"
                                color: "white"
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
                                visible: root.viewMode === "wide"
                                anchors.left: deviceIcon.right
                                anchors.verticalCenter: deviceIcon.verticalCenter
                                anchors.right: parent.right
                                anchors.leftMargin: 5
                                
                                color: "white"
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
                                visible: root.viewMode === "wide"
                                anchors.top: deviceIcon.bottom
                                anchors.left: deviceIcon.left
                                anchors.leftMargin: 5
                                anchors.topMargin: -5
                                spacing: 0
                                
                                Text {
                                    text: hostName.toUpperCase().replace(/\n/g, " ")
                                    color: Qt.rgba(1,1,1,0.9)
                                    font.pixelSize: deviceInfoCard.height < 60 ? 14 : 20
                                    font.bold: true
                                }
                                
                                Text {
                                    text: formatDuration(remainingMsec)
                                    color: Qt.rgba(1,1,1,0.7)
                                    font.pixelSize: 12
                                    font.bold: false
                                    visible: remainingMsec > 0
                                }
                            }
                        }
                    }

                    // Right Side: Text Info (Swapped)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter
                        
                        // Percentage Row
                        RowLayout {
                            visible: root.viewMode !== "wide"
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
                                color: "white"
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
                                color: "white"
                            }
                        }
                        
                        // Hostname
                        Text {
                            visible: root.viewMode !== "wide"
                            text: hostName.toUpperCase().replace(/\n/g, " ")
                            color: Qt.rgba(1,1,1,0.9)
                            font.pixelSize: deviceInfoCard.height < 60 ? 14 : 20
                            font.bold: true
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        
                        // Estimated Time Remaining (below hostname)
                        Text {
                            visible: root.viewMode !== "wide" && remainingMsec > 0
                            text: formatDuration(remainingMsec)
                            color: Qt.rgba(1,1,1,0.6)
                            font.pixelSize: deviceInfoCard.height < 60 ? 12 : 14
                            Layout.fillWidth: true
                        }
                        
                        // Time Remaining (Absolute Timestamp)
                        Text {
                            text: finishTime ? i18n("Remaining to %1", finishTime) : ""
                            color: Qt.rgba(1,1,1,0.6)
                            font.pixelSize: 13
                            visible: finishTime.length > 0
                        }
                        
                        // Spacer
                        Item { height: 4 }
                        
                        // Power Profile Switcher
                        PowerProfileSwitcher {
                            visible: root.viewMode !== "wide"
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
                    visible: root.viewMode === "wide"
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
            visible: root.viewMode !== "small" && root.viewMode !== "extrasmall"
            spacing: 10 // Requested spacing
            clip: true // Enable scrolling if content overflows
            
            // Filter non-main devices
            model: devices.filter(d => !d.isMain)
            
            delegate: Item {
                width: ListView.view.width
                
                // Height Logic:
                // 1. Calculate available height per item based on count
                // 2. Minimum 50px
                // 3. If it fits, expand to fill available space
                readonly property int itemCount: ListView.view.count
                readonly property real availableHeight: ListView.view.height - (ListView.view.spacing * (itemCount - 1))
                readonly property real calculatedHeight: availableHeight / itemCount
                
                height: Math.max(50, calculatedHeight)
                
                HorizontalBatteryBar {
                    width: parent.width
                    height: parent.height
                    deviceName: modelData.name
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
