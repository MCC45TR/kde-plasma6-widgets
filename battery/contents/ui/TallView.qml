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
                    
                    // Left Side: Device Info Container
                    // In Big Mode: Fill width (text left, icon right)
                    // Other modes: Square (icon top-left, text next to it)
                    Item {
                        Layout.preferredWidth: root.viewMode === "big" ? parent.width : height
                        Layout.fillWidth: root.viewMode === "big"
                        Layout.fillHeight: true
                        
                        Rectangle {
                            id: cihazSimgeKarosu
                            anchors.fill: parent
                            radius: {
                                if (root.iconShape === "circle") return width / 2
                                if (root.iconShape === "rounded") return 20
                                return deviceInfoCard.topRadius - 5
                            }
                            color: "transparent"
                            
                            // Original small icon (hidden in Big Mode)
                            Kirigami.Icon {
                                id: deviceIcon
                                visible: root.viewMode !== "big"
                                anchors.top: parent.top
                                anchors.left: parent.left
                                
                                property real iconSize: (parent.width - 20) * (root.iconShape === "circle" ? 0.66 : 1.0) * 0.44
                                width: iconSize
                                height: iconSize
                                source: mainDevice && mainDevice.deviceType === "desktop" ? "computer" : "computer-laptop"
                                color: Kirigami.Theme.textColor
                            }
                            
                            // Big Mode Icon (right side, vertically centered, height-filling)
                            Kirigami.Icon {
                                id: bigModeIcon
                                visible: root.viewMode === "big"
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 0
                                
                                property real iconSize: parent.height
                                width: iconSize
                                height: iconSize
                                source: mainDevice && mainDevice.deviceType === "desktop" ? "computer" : "computer-laptop"
                                color: Kirigami.Theme.textColor
                            }

                            TextMetrics {
                                id: tm
                                font.pixelSize: deviceIcon.height * 0.8
                                font.weight: Font.Light
                                text: (root.viewMode === "big" ? "%" : "") + (mainDevice ? mainDevice.percentage : "")
                            }

                            Text {
                                id: percentText
                                visible: true
                                
                                // Big Mode: anchor to parent left
                                // Other modes: anchor to deviceIcon right
                                anchors.left: root.viewMode === "big" ? parent.left : deviceIcon.right
                                anchors.top: root.viewMode === "big" ? parent.top : undefined
                                anchors.verticalCenter: root.viewMode === "big" ? undefined : deviceIcon.verticalCenter
                                anchors.right: root.viewMode === "big" ? bigModeIcon.left : parent.right
                                anchors.leftMargin: root.viewMode === "big" ? 10 : 5
                                anchors.topMargin: root.viewMode === "big" ? 5 : 0
                                anchors.rightMargin: root.viewMode === "big" ? 10 : 0
                                
                                color: Kirigami.Theme.textColor
                                // Larger font for tall and big modes
                                font.pixelSize: (root.viewMode === "big" || root.viewMode === "tall") ? 48 : deviceIcon.height * 0.8
                                font.weight: Font.Normal
                                elide: Text.ElideRight
                                
                                text: {
                                    if (!mainDevice) return "--"
                                    if (mainDevice.deviceType === "desktop") {
                                        return mainDevice.percentage + " W"
                                    }
                                    if (root.viewMode === "big") {
                                        return "%" + mainDevice.percentage
                                    }
                                    return mainDevice.percentage
                                }
                            }
                            
                            Column {
                                visible: true
                                
                                // Big Mode: anchor to parent, below percentage text
                                // Other modes: anchor to deviceIcon
                                // Big Mode: anchor to profileSwitcher top (to avoid overlap)
                                // Other modes: anchor to deviceIcon bottom
                                // Big Mode: anchor to parent bottom with margin for switcher
                                // Other modes: anchor to deviceIcon bottom
                                anchors.top: root.viewMode === "big" ? undefined : deviceIcon.bottom
                                anchors.bottom: root.viewMode === "big" ? parent.bottom : undefined
                                anchors.left: root.viewMode === "big" ? parent.left : deviceIcon.left
                                anchors.right: root.viewMode === "big" ? bigModeIcon.left : parent.right
                                anchors.leftMargin: root.viewMode === "big" ? 10 : 5
                                anchors.topMargin: root.viewMode === "big" ? 0 : -5
                                anchors.bottomMargin: root.viewMode === "big" ? (root.hasPowerProfiles ? profileSwitcher.height + 5 : 5) : 0
                                anchors.rightMargin: root.viewMode === "big" ? 10 : 0
                                spacing: 0
                                
                                Text {
                                    text: hostName.toUpperCase().replace(/\n/g, " ")
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.9)
                                    font.pixelSize: root.viewMode === "big" ? 16 : (deviceInfoCard.height < 60 ? 14 : 20)
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                
                                Text {
                                    text: {
                                        var duration = Formatter.formatDuration(remainingMsec)
                                        if (mainDevice && mainDevice.isCharging) {
                                            return i18nc("Time to full", "Time to full: %1", duration)
                                        } else {
                                            return i18nc("Time remaining", "Remaining: %1", duration)
                                        }
                                    }
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
                                    font.pixelSize: 12
                                    font.bold: false
                                    visible: remainingMsec > 0
                                }
                            }
                        }
                    }

                    // Right Side: Empty (not used in this layout)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }

                PowerProfileSwitcher {
                    id: profileSwitcher
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                    anchors.bottomMargin: 5
                    visible: root.hasPowerProfiles
                    
                    // In Big Mode: width stops where the icon starts
                    // Other modes: full width minus margins
                    width: root.viewMode === "big" 
                        ? (parent.width - bigModeIcon.width - 25) // 5 left + 10 icon margin + 10 gap
                        : (parent.width - 10)
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
