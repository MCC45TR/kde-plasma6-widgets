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
    property string currentPowerProfile: "balanced"
    signal setPowerProfile(string profile)
    
    // View Mode (Adaptive)
    property string viewMode: "large" // "small", "broad", "large"
    property string iconShape: "square" // "square", "rounded", "circle"

    // Design Tokens
    readonly property int backgroundRadius: 20
    readonly property int contentGap: 10

    // Layout: 50/50 vertical split
    // Layout: Adaptive
    GridLayout {
        anchors.fill: parent
        anchors.margins: root.contentGap
        rowSpacing: root.contentGap
        columnSpacing: root.contentGap
        columns: root.viewMode === "broad" ? 2 : 1
        
        // --- TOP SECTION (Main Card) ---
        Item {
            Layout.fillWidth: root.viewMode !== "broad"
            Layout.preferredWidth: {
                if (root.viewMode === "broad") {
                     return height < (root.width / 2) ? height : (root.width / 2)
                }
                return -1
            }
            // Fill height only if it's the only item (small/extrasmall) or side-by-side (broad)
            Layout.fillHeight: root.viewMode === "small" || root.viewMode === "extrasmall" || root.viewMode === "broad"
            
            // Fixed 134px height for Large/Tall modes (where it stacks vertically with list)
            Layout.preferredHeight: (root.viewMode === "large" || root.viewMode === "tall") ? 134 : -1
            
            Shape {
                id: deviceInfoCard
                anchors.fill: parent
                
                // Radius Logic
                readonly property int topRadius: root.backgroundRadius - root.contentGap
                readonly property int bottomRadius: topRadius
                
                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                    
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
                            color: root.viewMode === "broad" ? "transparent" : Kirigami.Theme.backgroundColor
                            
                            Kirigami.Icon {
                                id: deviceIcon
                                anchors.centerIn: root.viewMode === "broad" ? null : parent
                                anchors.top: root.viewMode === "broad" ? parent.top : undefined
                                anchors.left: root.viewMode === "broad" ? parent.left : undefined
                                
                                property real iconSize: (parent.width - 20) * (root.iconShape === "circle" ? 0.66 : 1.0) * (root.viewMode === "broad" ? 0.66 : 1.0)
                                width: iconSize
                                height: iconSize
                                source: "computer-laptop"
                                color: "white"
                            }

                            TextMetrics {
                                id: tm
                                font: broadPercentText.font
                                text: "%" + (mainDevice ? mainDevice.percentage : "")
                            }

                            Text {
                                id: broadPercentText
                                visible: root.viewMode === "broad"
                                anchors.left: deviceIcon.right
                                anchors.verticalCenter: deviceIcon.verticalCenter
                                anchors.right: parent.right
                                anchors.leftMargin: 5
                                
                                color: "white"
                                font.pixelSize: deviceIcon.height * 0.8
                                font.family: "Roboto Condensed" 
                                font.weight: Font.Light
                                
                                text: mainDevice ? (tm.width > width ? mainDevice.percentage : tm.text) : "--"
                            }
                            
                            Text {
                                visible: root.viewMode === "broad"
                                anchors.top: deviceIcon.bottom
                                anchors.left: deviceIcon.left
                                anchors.leftMargin: 5
                                anchors.topMargin: -5
                                
                                text: hostName.toUpperCase().replace(/\n/g, " ")
                                color: Qt.rgba(1,1,1,0.9)
                                font.pixelSize: 12
                                font.bold: true
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
                            visible: root.viewMode !== "broad"
                            spacing: 4
                            Text {
                                text: mainDevice ? "%" + mainDevice.percentage : "--"
                                color: "white"
                                font.pixelSize: Math.max(36, deviceInfoCard.height * 0.40) // Adaptive font size
                                font.family: "Roboto Condensed" 
                                font.weight: Font.Light
                                lineHeight: 0.8
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
                            visible: root.viewMode !== "broad"
                            text: hostName.toUpperCase().replace(/\n/g, " ")
                            color: Qt.rgba(1,1,1,0.9)
                            font.pixelSize: 15
                            font.bold: true
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            maximumLineCount: 2
                            elide: Text.ElideRight
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
                        Loader {
                            sourceComponent: powerSwitcherComponent
                            visible: root.viewMode !== "broad"
                        }
                    }
                }

                Loader {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 5
                    sourceComponent: powerSwitcherComponent
                    visible: root.viewMode === "broad"
                    onLoaded: item.width = Qt.binding(() => parent.width - 10)
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
                
                // Bar Background (Track)
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.3, 0.3, 0.3, 0.5)
                    radius: 10
                }
                
                // Filled Progress
                Rectangle {
                    id: barFill
                    height: parent.height
                    width: parent.width * (modelData.percentage / 100)
                    radius: 10
                    
                    // Color Logic
                    property color barColor: {
                        if (modelData.isCharging) return "#2ecc71" // Green
                        var p = modelData.percentage
                        if (p <= 15) return Kirigami.Theme.negativeColor
                        if (p <= 30) return "#FFAA00"
                        return Kirigami.Theme.highlightColor
                    }
                    color: barColor
                }
                
                // Content Row (Inside Bar)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: parent.height < 60 ? 10 : 20 // Adaptive margins
                    spacing: 15
                    
                    // Icon
                    Kirigami.Icon {
                        source: modelData.icon
                        Layout.preferredWidth: parent.height < 60 ? 32 : 48
                        Layout.preferredHeight: Layout.preferredWidth
                        color: modelData.percentage > 15 && modelData.percentage <= 30 ? "black" : "white"
                    }
                    
                    // Text
                    Text {
                        text: modelData.name + " (%" + modelData.percentage + ")"
                        font.bold: true
                        font.pixelSize: parent.height < 60 ? 14 : 20
                        color: modelData.percentage > 15 && modelData.percentage <= 30 ? "black" : "white"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    // Charging Indicator
                    Kirigami.Icon {
                        source: "battery-charging"
                        visible: modelData.isCharging === true
                        Layout.preferredWidth: parent.height < 60 ? 24 : 32
                        Layout.preferredHeight: Layout.preferredWidth
                        color: modelData.percentage > 15 && modelData.percentage <= 30 ? "black" : "white"
                    }
                }
            }
        }
    }

    Component {
        id: powerSwitcherComponent
        Rectangle {
            id: track
            height: 30
            width: 140
            color: Qt.rgba(0,0,0,0.3)
            radius: 10
            
            // Highlight Indicator
            Rectangle {
                id: highlightRect
                width: parent.width / 3
                height: parent.height
                radius: 10
                color: Qt.rgba(1,1,1,0.2)
                
                // Position Logic:
                x: {
                    if (switcherMouseArea.drag.active) return x
                    if (currentPowerProfile === "balanced") return width
                    if (currentPowerProfile === "performance") return width * 2
                    return 0 // "power-saver"
                }
                
                Behavior on x {
                    enabled: !switcherMouseArea.drag.active
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 0.8
                    }
                }
            }
            
            // Icons Layer
            RowLayout {
                anchors.fill: parent
                spacing: 0
                
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "battery-profile-powersave"
                        width: 20; height: 20
                        color: currentPowerProfile === "power-saver" ? "#4CAF50" : "white"
                    }
                }
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: width <= 22 ? "power-profile-balanced-symbolic" : "battery-profile-balanced"
                        width: 20; height: 20
                        color: currentPowerProfile === "balanced" ? "#FFC107" : "white"
                    }
                }
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "battery-profile-performance"
                        width: 20; height: 20
                        color: currentPowerProfile === "performance" ? "#FF5252" : "white"
                    }
                }
            }
            
            // Interaction Layer
            MouseArea {
                id: switcherMouseArea
                anchors.fill: parent
                
                drag.target: highlightRect
                drag.axis: Drag.XAxis
                drag.minimumX: 0
                drag.maximumX: track.width - highlightRect.width
                
                onClicked: (mouse) => {
                    var slotWidth = width / 3
                    if (mouse.x < slotWidth) root.setPowerProfile("power-saver")
                    else if (mouse.x < slotWidth * 2) root.setPowerProfile("balanced")
                    else root.setPowerProfile("performance")
                }
                
                onReleased: {
                    if (drag.active) {
                        var center = highlightRect.x + highlightRect.width / 2
                        var slotWidth = width / 3
                        var targetProfile = "power-saver"
                        if (center > slotWidth && center < slotWidth * 2) targetProfile = "balanced"
                        else if (center >= slotWidth * 2) targetProfile = "performance"
                        root.setPowerProfile(targetProfile)
                    }
                }
            }
        }
    }
}
