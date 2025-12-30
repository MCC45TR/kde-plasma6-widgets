import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.bluezqt as BluezQt

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    // Battery data properties
    property int batteryPercent: 0
    property bool isCharging: false
    property bool hasBattery: false
    property string batteryState: ""

    // Bluetooth device properties
    readonly property BluezQt.Manager btManager: BluezQt.Manager
    property var bluetoothDevices: []

    // KDE Connect device properties
    property var kdeConnectDevices: [] // Array of devices

    // Layout mode properties
    property bool isCompact: width < 200 || height < 150
    property bool isLarge: !isCompact && width > 350 && height > 350
    property bool isWide: !isCompact && !isLarge

    // Theme colors
    property color backgroundColor: Kirigami.Theme.backgroundColor
    property color textColor: Kirigami.Theme.textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property color tileColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.1)
    property color criticalColor: "#ff4444"
    
    // State for expansion
    property int expandedDeviceIndex: -1

    // Helper function to update Bluetooth device list
    function updateBluetoothDevices() {
        var devices = []
        if (btManager.operational) {
            for (var i = 0; i < btManager.devices.length; i++) {
                var device = btManager.devices[i]
                // Only include connected devices with battery information
                if (device.connected && device.battery) {
                    var deviceName = device.name || device.alias || "Unknown Device"
                    var deviceInfo = {
                        name: deviceName,
                        address: device.address,
                        percentage: device.battery.percentage,
                        icon: getDeviceIcon(device, deviceName),
                        device: device
                    }
                    devices.push(deviceInfo)
                }
            }
        }
        bluetoothDevices = devices
    }

    // Helper function to determine device icon based on device type
    function getDeviceIcon(device, deviceName) {
        var iconName = device && device.icon ? device.icon : "network-bluetooth"
        
        // Ensure iconName is a string safely
        iconName = String(iconName)
        
        // Map common device icons to Kirigami icons
        if (iconName.includes("audio") || iconName.includes("headset") || iconName.includes("headphone")) {
            if (iconName.includes("earbud")) {
                return "audio-headphones"
            }
            return "audio-headset"
        } else if (iconName.includes("mouse")) {
            return "input-mouse"
        } else if (iconName.includes("keyboard")) {
            return "input-keyboard"
        } else if (iconName.includes("phone") || iconName.includes("watch")) {
            return "smartphone"
        } else if (iconName.includes("computer")) {
            return "computer"
        } else if (iconName.includes("speaker")) {
            return "speaker"
        } else if (iconName.includes("controller") || iconName.includes("gamepad")) {
            return "input-gaming"
        } else {
            return iconName !== "" ? iconName : "network-bluetooth"
        }
    }

    // Monitor Bluetooth manager state
    Connections {
        target: btManager
        function onDeviceAdded() { updateBluetoothDevices() }
        function onDeviceRemoved() { updateBluetoothDevices() }
        function onDeviceChanged() { updateBluetoothDevices() }
        function onOperationalChanged() { updateBluetoothDevices() }
    }

    // Initial Bluetooth device update
    Component.onCompleted: {
        updateBluetoothDevices()
        updateKdeConnectDevices()
    }

    // Periodic update for battery percentage changes
    Timer {
        interval: 10000  // Update every 10 seconds
        running: true
        repeat: true
        onTriggered: updateBluetoothDevices()
    }

    // Power Management Data Source (Plasma 6)
    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        interval: 5000  // Update every 5 seconds

        onNewData: function(source, data) {
            if (source === "Battery") {
                root.hasBattery = data["Has Battery"] || false
                root.batteryPercent = data["Percent"] || 0
                root.batteryState = data["State"] || ""
            } else if (source === "AC Adapter") {
                root.isCharging = data["Plugged in"] || false
            }
        }

        Component.onCompleted: {
            // Initial data load
            if (pmSource.data["Battery"]) {
                root.hasBattery = pmSource.data["Battery"]["Has Battery"] || false
                root.batteryPercent = pmSource.data["Battery"]["Percent"] || 0
                root.batteryState = pmSource.data["Battery"]["State"] || ""
            }
            if (pmSource.data["AC Adapter"]) {
                root.isCharging = pmSource.data["AC Adapter"]["Plugged in"] || false
            }
        }
    }

    // KDE Connect Data Source (Real Implementation)
    P5Support.DataSource {
        id: kdeConnectSource
        engine: "kdeconnect"
        connectedSources: sources
        
        onSourceAdded: function(source) {
            connectSource(source)
        }
        
        onSourceRemoved: function(source) {
            disconnectSource(source)
            var newList = []
            for (var i = 0; i < root.kdeConnectDevices.length; i++) {
                if (root.kdeConnectDevices[i].deviceId !== source) {
                    newList.push(root.kdeConnectDevices[i])
                }
            }
            root.kdeConnectDevices = newList
        }
        
        onNewData: function(source, data) {
            // Check for battery info (keys vary by version but typically 'battery' or 'charge')
            var battery = data["battery"]
            if (battery === undefined) battery = data["Battery"] 
            
            // Only process if we have battery data
            if (battery !== undefined) {
                var deviceName = data["name"] || data["Name"] || "Device"
                var icon = data["icon"] || data["Icon"] || "smartphone"
                var isCharging = data["charge"] || data["isCharging"] || false
                // Handle case where charge might be int 0/1 or bool
                if (typeof isCharging === 'number') isCharging = (isCharging === 1)

                var newDevice = {
                    deviceId: source,
                    name: deviceName,
                    percentage: battery,
                    icon: icon,
                    isCharging: !!isCharging // Force boolean
                }
                
                // Update existing device or add new one
                var found = false
                var newList = []
                for (var i = 0; i < root.kdeConnectDevices.length; i++) {
                    if (root.kdeConnectDevices[i].deviceId === source) {
                        newList.push(newDevice)
                        found = true
                    } else {
                        newList.push(root.kdeConnectDevices[i])
                    }
                }
                if (!found) {
                    newList.push(newDevice)
                }
                root.kdeConnectDevices = newList
            }
        }
    }

    fullRepresentation: Item {
        anchors.fill: parent

        Rectangle {
            id: mainRect
            anchors.fill: parent
            anchors.margins: 10
            color: root.backgroundColor
            radius: 20
            clip: true

            // All devices (laptop + bluetooth)
            property var allDevices: {
                var devices = []
                
                // Add laptop battery if available
                if (root.hasBattery) {
                    devices.push({
                        name: "Laptop",
                        percentage: root.batteryPercent,
                        icon: "computer-laptop",
                        isCharging: root.isCharging
                    })
                }
                
                // Add bluetooth devices
                for (var i = 0; i < root.bluetoothDevices.length; i++) {
                    var deviceName = root.bluetoothDevices[i].name
                    
                    // Shorten common device names
                    if (deviceName.toLowerCase().includes("mouse")) {
                        deviceName = "Mouse"
                    } else if (deviceName.toLowerCase().includes("keyboard")) {
                        deviceName = "Klavye"
                    } else if (deviceName.toLowerCase().includes("headphone") || 
                               deviceName.toLowerCase().includes("headset") ||
                               deviceName.toLowerCase().includes("earbud")) {
                        deviceName = "Kulaklık"
                    } else if (deviceName.toLowerCase().includes("speaker")) {
                        deviceName = "Hoparlör"
                    } else {
                        // Keep first word only for other devices
                        deviceName = deviceName.split(" ")[0]
                    }
                    
                    devices.push({
                        name: deviceName,
                        percentage: root.bluetoothDevices[i].percentage,
                        icon: root.bluetoothDevices[i].icon || "network-bluetooth",
                        isCharging: false
                    })
                }

                // Add KDE Connect devices
                for (var i = 0; i < root.kdeConnectDevices.length; i++) {
                    devices.push({
                        name: root.kdeConnectDevices[i].name,
                        percentage: root.kdeConnectDevices[i].percentage,
                        icon: root.kdeConnectDevices[i].icon,
                        isCharging: root.kdeConnectDevices[i].isCharging
                    })
                }
                
                return devices
            }

            // Grid Layout calculation
            property real gridMargin: 10 // Internal margin for the grid
            property real gridSpacing: 10
            // Margin*2 (left+right) + Spacing (1 gap for 2 cols)
            property real effectiveWidth: width - (gridMargin * 2) - gridSpacing
            property real effectiveHeight: height - (gridMargin * 2) - gridSpacing
            property real cellWidth: Math.max(1, effectiveWidth / 2)
            property real cellHeight: Math.max(1, effectiveHeight / 2)
            
            // Tile radius calculation: Widget Radius - Gap
            // Gap here is the gridMargin (distance from mainRect edge to tile edge)
            // If mainRect.radius is 20 and margin is 10, tile radius should be 10 for concentric look.
            property real tileRadius: Math.max(5, radius - gridMargin)

            // Grid Container for 2x2 layout
            Grid {
                anchors.fill: parent
                anchors.margins: mainRect.gridMargin // Apply internal margins
                rows: 2
                columns: 2
                spacing: mainRect.gridSpacing

                Repeater {
                    model: mainRect.allDevices
                    
                    // Wrapper Item for Grid positioning
                    Item {
                        width: mainRect.cellWidth
                        height: mainRect.cellHeight
                        
                        // Z-order management
                        z: root.expandedDeviceIndex === index ? 100 : 1

                        // Actual Device Tile
                        Rectangle {
                            id: tile
                            
                            readonly property bool isExpanded: root.expandedDeviceIndex === index
                            
                            color: root.tileColor
                            radius: mainRect.tileRadius

                            // States for expansion
                            states: [
                                State {
                                    name: "expanded"
                                    when: tile.isExpanded
                                    ParentChange {
                                        target: tile
                                        parent: mainRect
                                        x: 0
                                        y: 0
                                        width: mainRect.width
                                        height: mainRect.height
                                    }
                                    PropertyChanges {
                                        target: tile
                                        radius: mainRect.radius
                                        z: 100
                                        // Slight color boost for readability if needed, or keep tileColor
                                    }
                                }
                            ]
                            
                            // Default geometry relative to wrapper
                            width: parent.width
                            height: parent.height
                            
                            transitions: Transition {
                                ParallelAnimation {
                                    NumberAnimation { properties: "x,y,width,height,radius,z"; duration: 400; easing.type: Easing.OutQuint }
                                    ColorAnimation { duration: 400 }
                                }
                            }

                            // MouseArea for expansion
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.expandedDeviceIndex === index) {
                                        root.expandedDeviceIndex = -1 // Collapse
                                    } else {
                                        root.expandedDeviceIndex = index // Expand
                                    }
                                }
                            }

                            // Content Container
                            Item {
                                id: contentItem
                                anchors.fill: parent
                                
                                Item {
                                    id: progressBackground
                                    anchors.fill: parent
                                    visible: true 
                                    
                                    // Background border (unfilled)
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        border.color: root.textColor
                                        border.width: 6
                                        radius: tile.radius 
                                        opacity: 0.3
                                    }

                                    // Progress border
                                    Canvas {
                                        id: progressCanvas
                                        anchors.fill: parent
                                        visible: width > 0 && height > 0
                                        property real percentage: modelData.percentage
                                        property color progressColor: modelData.percentage <= 25 ? root.criticalColor : root.accentColor
                                        property real currentRadius: tile.radius
                                        
                                        onPercentageChanged: requestPaint()
                                        onProgressColorChanged: requestPaint()
                                        onWidthChanged: requestPaint()
                                        onHeightChanged: requestPaint()
                                        onCurrentRadiusChanged: requestPaint()
                                        
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.reset()
                                            if (percentage <= 0) return
                                            
                                            var borderWidth = 6
                                            var cornerRadius = currentRadius
                                            var w = width
                                            var h = height
                                            var inset = borderWidth / 2
                                            
                                            if (w <= 0 || h <= 0) return

                                            var topWidth = w - 2 * cornerRadius
                                            var rightHeight = h - 2 * cornerRadius
                                            var bottomWidth = w - 2 * cornerRadius
                                            var leftHeight = h - 2 * cornerRadius
                                            
                                            var totalPerimeter = topWidth + rightHeight + bottomWidth + leftHeight + (2 * Math.PI * cornerRadius)
                                            var progressLength = totalPerimeter * (percentage / 100)
                                            
                                            ctx.strokeStyle = progressColor
                                            ctx.lineWidth = borderWidth
                                            ctx.lineCap = percentage >= 100 ? "square" : "round"
                                            ctx.lineJoin = "round"
                                            ctx.beginPath()
                                            
                                            var currentLength = 0
                                            var x = inset + cornerRadius
                                            var y = inset
                                            ctx.moveTo(x, y)
                                            
                                            // Top
                                            if (progressLength > currentLength) {
                                                var seg = Math.min(topWidth, progressLength - currentLength)
                                                ctx.lineTo(x + seg, y)
                                                currentLength += seg
                                                x += seg
                                            }
                                            // Top-Right
                                            if (progressLength > currentLength && currentLength >= topWidth) {
                                                var arcLen = Math.PI * cornerRadius / 2
                                                var arcProg = Math.min(1, (progressLength - currentLength) / arcLen)
                                                var endAng = -Math.PI / 2 + (Math.PI / 2 * arcProg)
                                                ctx.arc(w - inset - cornerRadius, inset + cornerRadius, cornerRadius, -Math.PI / 2, endAng, false)
                                                currentLength += arcLen * arcProg
                                            }
                                            // Right
                                            if (progressLength > currentLength && currentLength >= topWidth + (Math.PI * cornerRadius / 2)) {
                                                var seg = Math.min(rightHeight, progressLength - currentLength)
                                                ctx.lineTo(w - inset, inset + cornerRadius + seg)
                                                currentLength += seg
                                            }
                                            // Bottom-Right
                                            if (progressLength > currentLength && currentLength >= topWidth + (Math.PI * cornerRadius / 2) + rightHeight) {
                                                var arcLen = Math.PI * cornerRadius / 2
                                                var arcProg = Math.min(1, (progressLength - currentLength) / arcLen)
                                                var endAng = 0 + (Math.PI / 2 * arcProg)
                                                ctx.arc(w - inset - cornerRadius, h - inset - cornerRadius, cornerRadius, 0, endAng, false)
                                                currentLength += arcLen * arcProg
                                            }
                                            // Bottom
                                            if (progressLength > currentLength && currentLength >= topWidth + Math.PI * cornerRadius + rightHeight) {
                                                var seg = Math.min(bottomWidth, progressLength - currentLength)
                                                ctx.lineTo(w - inset - cornerRadius - seg, h - inset)
                                                currentLength += seg
                                            }
                                            // Bottom-Left
                                            if (progressLength > currentLength && currentLength >= topWidth + Math.PI * cornerRadius + rightHeight + bottomWidth) {
                                                var arcLen = Math.PI * cornerRadius / 2
                                                var arcProg = Math.min(1, (progressLength - currentLength) / arcLen)
                                                var endAng = Math.PI / 2 + (Math.PI / 2 * arcProg)
                                                ctx.arc(inset + cornerRadius, h - inset - cornerRadius, cornerRadius, Math.PI / 2, endAng, false)
                                                currentLength += arcLen * arcProg
                                            }
                                            // Left
                                            if (progressLength > currentLength && currentLength >= topWidth + 1.5 * Math.PI * cornerRadius + rightHeight + bottomWidth) {
                                                var seg = Math.min(leftHeight, progressLength - currentLength)
                                                ctx.lineTo(inset, h - inset - cornerRadius - seg)
                                                currentLength += seg
                                            }
                                            // Top-Left
                                            if (progressLength > currentLength && currentLength >= topWidth + 1.5 * Math.PI * cornerRadius + rightHeight + bottomWidth + leftHeight) {
                                                 var arcLen = Math.PI * cornerRadius / 2
                                                 var arcProg = Math.min(1, (progressLength - currentLength) / arcLen)
                                                 var endAng = Math.PI + (Math.PI / 2 * arcProg)
                                                 ctx.arc(inset + cornerRadius, inset + cornerRadius, cornerRadius, Math.PI, endAng, false)
                                            }
                                            ctx.stroke()
                                        }
                                        
                                        Behavior on percentage { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    }
                                }

                                // Device Icon
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: tile.isExpanded ? 0 : -parent.height * 0.08
                                    width: tile.isExpanded ? 96 : parent.width * 0.4
                                    height: tile.isExpanded ? 96 : parent.height * 0.4
                                    source: modelData.icon || "battery-missing"
                                    color: root.textColor
                                    opacity: 0.9
                                    visible: width > 0 && height > 0 && source !== ""

                                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                                    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                                    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 400 } }
                                }

                                // Percentage Text
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: tile.isExpanded ? parent.height * 0.15 : parent.height * 0.12
                                    text: "%" + modelData.percentage + " " + (modelData.isCharging ? "Doluyor" : "Pilde")
                                    // Use Roboto Condensed if available
                                    font.family: "Roboto Condensed"
                                    font.pixelSize: tile.isExpanded ? 24 : Math.max(9, parent.height * 0.11)
                                    font.bold: false
                                    color: root.textColor
                                    horizontalAlignment: Text.AlignHCenter
                                    
                                    Behavior on anchors.bottomMargin { NumberAnimation { duration: 400 } }
                                    Behavior on font.pixelSize { NumberAnimation { duration: 400 } }
                                }
                                
                                // Extra details when expanded
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: 80
                                    visible: tile.isExpanded
                                    opacity: tile.isExpanded ? 1 : 0
                                    
                                    Text {
                                        text: modelData.name
                                        color: root.textColor
                                        font.bold: true
                                        font.pixelSize: 20
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: "Durum: " + (modelData.isCharging ? "Şarj Oluyor" : "Deşarj Oluyor")
                                        color: root.textColor
                                        font.pixelSize: 14
                                        Layout.alignment: Qt.AlignHCenter
                                        visible: tile.isExpanded
                                    }
                                    
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                }
                            }

                            // Charging indicator / Status icon
                            Rectangle {
                                id: chargingIndicator
                                anchors.top: parent.top
                                anchors.right: parent.right
                                // Anchor adjustments for smoother animation
                                anchors.topMargin: tile.isExpanded ? 15 : -width * 0.15
                                anchors.rightMargin: tile.isExpanded ? 15 : -width * 0.15
                                
                                // Size logic
                                property real relativeSize: tile.isExpanded ? 50 : parent.width * 0.35
                                width: relativeSize
                                height: relativeSize
                                radius: width / 2
                                color: modelData.percentage <= 25 ? root.criticalColor : root.accentColor
                                
                                // Always visible as per request (battery icon on battery, charging on charging)
                                visible: true 
                                border.color: root.backgroundColor
                                border.width: 2

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    height: parent.height * 0.6
                                    source: modelData.isCharging ? "battery-charging" : "battery-060" 
                                    color: root.backgroundColor
                                    visible: width > 0 && height > 0
                                }
                                
                                Behavior on width { NumberAnimation { duration: 400 } }
                                Behavior on height { NumberAnimation { duration: 400 } }
                                Behavior on anchors.topMargin { NumberAnimation { duration: 400 } }
                                Behavior on anchors.rightMargin { NumberAnimation { duration: 400 } }
                            }
                        }
                    }
                }
            }
        }

        // Empty state
        Item {
            anchors.centerIn: parent
            visible: mainRect.allDevices.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    source: "battery-missing"
                    color: root.textColor
                    opacity: 0.5
                    visible: width > 0 && height > 0
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Batarya bulunamadı"
                    font.pixelSize: 14
                    color: root.textColor
                    opacity: 0.7
                }
            }
        }
    }
}
