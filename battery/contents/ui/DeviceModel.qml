import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.bluezqt as BluezQt
import org.kde.kdeconnect as KDEConnect

Item {
    id: root
    
    // Combined list of all power sources
    property var devices: []
    property var mainDevice: null 

    readonly property BluezQt.Manager btManager: BluezQt.Manager

    // KDE Connect devices model
    KDEConnect.DevicesModel {
        id: kdeConnectDevices
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }

    // Store KDE Connect battery interfaces
    property var kdeBatteryInterfaces: ({})

    // === POWER PROFILES ===
    property string currentPowerProfile: "balanced"
    property var availableProfiles: ["power-saver", "balanced", "performance"]
    
    P5Support.DataSource {
        id: powerProfileSource
        engine: "executable"
        connectedSources: []
        
        onNewData: (source, data) => {
            if (source === "powerprofilesctl get" && data["exit code"] === 0) {
                root.currentPowerProfile = data["stdout"].trim()
            }
            disconnectSource(source)
        }
        
        function fetchProfile() {
            connectSource("powerprofilesctl get")
        }
        
        function setProfile(profile) {
            connectSource("powerprofilesctl set " + profile)
            Qt.callLater(fetchProfile)
        }
    }
    
    function setPowerProfile(profile) {
        powerProfileSource.setProfile(profile)
    }
    
    // === TIME TO EVENT ===
    property string timeToEvent: ""
    property bool isTimeToFull: false
    
    function formatTimeToEvent(msec, charging) {
        if (msec <= 0) return ""
        
        var totalMins = Math.floor(msec / 60000)
        var h = Math.floor(totalMins / 60)
        var m = totalMins % 60
        
        var timeStr = ""
        if (h > 0) {
            timeStr = h + "h " + m + "m"
        } else {
            timeStr = m + "m"
        }
        
        if (charging) {
            return i18n("Full in %1", timeStr)
        } else {
            return i18n("Empty in %1", timeStr)
        }
    }

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        interval: 2000 
        onNewData: {
            refreshDevices()
            powerProfileSource.fetchProfile()
        }
    }
    
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: refreshDevices()
    }
    
    Component.onCompleted: refreshDevices()
    
    Connections {
        target: btManager
        function onDeviceAdded() { refreshDevices() }
        function onDeviceChanged() { refreshDevices() }
        function onDeviceRemoved() { refreshDevices() }
        function onOperationalChanged() { refreshDevices() }
    }

    Connections {
        target: kdeConnectDevices
        function onRowsInserted() { refreshDevices() }
        function onRowsRemoved() { refreshDevices() }
        function onDataChanged() { refreshDevices() }
    }

    property bool useCustomIcons: Plasmoid.configuration.useCustomIcons
    property string iconVersion: Plasmoid.configuration.iconVersion || "v1"
    
    function refreshDevices() {
        var newList = []
        var mainBat = null
        
        // 1. Laptop/Main Battery
        // Check if "Battery" source exists and has capacity
        var hasBattery = pmSource.data["Battery"] && pmSource.data["Battery"]["Has Battery"]
        
        if (hasBattery) {
            var msec = pmSource.data["Battery"]["Remaining msec"] || 0
            var charging = pmSource.data["AC Adapter"] ? pmSource.data["AC Adapter"]["Plugged in"] : false
            
            mainBat = {
                name: "Laptop", 
                icon: resolveIcon("laptop", "computer-laptop"),
                percentage: pmSource.data["Battery"]["Percent"] || 0,
                isCharging: charging,
                isMain: true,
                deviceType: "laptop",
                remainingTime: (function() {
                    if (msec > 0) {
                        var totalMins = Math.floor(msec / 60000)
                        var h = Math.floor(totalMins / 60)
                        var m = totalMins % 60
                        return h + ":" + (m < 10 ? "0" + m : m)
                    }
                    return ""
                })(),
                timeToEvent: formatTimeToEvent(msec, charging)
            }
            newList.push(mainBat)
            
            // Update root-level time to event
            root.timeToEvent = mainBat.timeToEvent
            root.isTimeToFull = charging
        }
        
        // 2. Bluetooth Devices
        if (btManager.operational) {
            for (var i = 0; i < btManager.devices.length; i++) {
                var dev = btManager.devices[i]
                if (dev.connected && dev.battery) {
                    var per = dev.battery.percentage
                    if (per >= 0) { // Valid battery
                        newList.push({
                            name: dev.name,
                            icon: resolveIcon(dev.name, dev.iconName),
                            percentage: per,
                            isCharging: false, 
                            isMain: false,
                            deviceType: "bluetooth"
                        })
                    }
                }
            }
        }
        
        // 3. KDE Connect Devices
        for (var j = 0; j < kdeConnectDevices.count; j++) {
            var deviceId = kdeConnectDevices.data(kdeConnectDevices.index(j, 0), Qt.UserRole + 1) // deviceId role
            if (!deviceId) continue
            
            try {
                var deviceInterface = KDEConnect.DeviceDbusInterfaceFactory.create(deviceId)
                if (!deviceInterface) continue
                
                // Check if battery plugin is available
                var pluginChecker = Qt.createQmlObject(
                    'import org.kde.kdeconnect as KDEConnect; KDEConnect.PluginChecker { pluginName: "battery" }',
                    root, "pluginChecker"
                )
                pluginChecker.device = deviceInterface
                
                if (pluginChecker.available) {
                    var batteryInterface = KDEConnect.DeviceBatteryDbusInterfaceFactory.create(deviceId)
                    if (batteryInterface && batteryInterface.charge >= 0) {
                        var kdeDeviceType = getKdeConnectDeviceType(deviceInterface)
                        newList.push({
                            name: deviceInterface.name,
                            icon: resolveIcon(deviceInterface.name, getKdeConnectIcon(kdeDeviceType)),
                            percentage: batteryInterface.charge,
                            isCharging: batteryInterface.isCharging,
                            isMain: false,
                            deviceType: kdeDeviceType
                        })
                    }
                }
                
                pluginChecker.destroy()
            } catch (e) {
                console.log("KDE Connect device error:", e)
            }
        }
        
        devices = newList
        mainDevice = mainBat
    }
    
    function getKdeConnectDeviceType(device) {
        // KDE Connect device types: smartphone, tablet, desktop, laptop, tv
        var type = device.type || ""
        type = type.toLowerCase()
        if (type === "smartphone" || type === "phone") return "phone"
        if (type === "tablet") return "tablet"
        if (type === "desktop") return "desktop"
        if (type === "laptop") return "laptop"
        if (type === "tv") return "tv"
        return "phone" // Default to phone for unknown KDE Connect devices
    }
    
    function getKdeConnectIcon(deviceType) {
        switch (deviceType) {
            case "phone": return "smartphone"
            case "tablet": return "tablet"
            case "desktop": return "computer"
            case "laptop": return "computer-laptop"
            case "tv": return "video-television"
            default: return "smartphone"
        }
    }
    
    function resolveIcon(name, sysIcon) {
        var n = name ? name.toLowerCase() : ""
        var i = sysIcon || ""
        
        if (!useCustomIcons) {
            // System Icon Logic
            if (n.includes("mouse") || n.includes("fare") || n.includes("mx") || n.includes("logitech m")) return "input-mouse";
            if (n.includes("keyboard") || n.includes("klavye") || n.includes("keychron")) return "input-keyboard";
            if (n.includes("headset") || n.includes("kulaklık") || n.includes("wh-")) return "audio-headset";
            if (n.includes("headphone") || n.includes("buds") || n.includes("airpods") || n.includes("tws")) return "audio-headphones";
            if (n.includes("speaker") || n.includes("hoparlör") || n.includes("jbl")) return "audio-speakers";
            if (n.includes("phone") || n.includes("telefon") || n.includes("iphone") || n.includes("galaxy") || n.includes("pixel") || n.includes("oneplus") || n.includes("xiaomi") || n.includes("huawei") || n.includes("samsung")) return "smartphone";
            if (n.includes("tablet") || n.includes("ipad") || n.includes("tab")) return "tablet";
            if (n.includes("tv") || n.includes("android tv") || n.includes("fire tv")) return "video-television";
            if (n.includes("watch") || n.includes("saat") || n.includes("mi band")) return "device-watch";
            if (n.includes("gamepad") || n.includes("xbox") || n.includes("dual")) return "input-gaming";
            if (n.includes("esp32")) return "applications-electronics";
            // Check icon hints
            if (i.includes("mouse")) return "input-mouse";
            if (i.includes("keyboard")) return "input-keyboard";
            if (i.includes("headset")) return "audio-headset";
            if (i.includes("headphone")) return "audio-headphones";
            if (i !== "") return i;
            return "network-bluetooth";
        } else {
            // Custom Icon Logic (Map to ../../icons/<version>/filename.svg)
            var file = ""
            var isV2 = (iconVersion === "v2" || iconVersion === "v2/") // Handle potential trailing slash just in case

            if (n.includes("laptop")) file = "laptop.svg";
            else if (n.includes("mouse") || n.includes("fare") || n.includes("mx")) file = "mouse.svg";
            else if (n.includes("keyboard") || n.includes("klavye")) file = "keyboard.svg";
            else if (n.includes("headset") || n.includes("kulaklık") || n.includes("wh-")) file = "headset.svg";
            else if (n.includes("headphone")) file = isV2 ? "headphones.svg" : "headset.svg";
            else if (n.includes("buds") || n.includes("airpods") || n.includes("tws")) file = isV2 ? "earbuds.svg" : "tws.svg"; 
            else if (n.includes("speaker") || n.includes("hoparlör") || n.includes("jbl")) file = "speaker.svg";
            else if (n.includes("smart") && (n.includes("watch") || n.includes("saat"))) file = isV2 ? "watch-smart.svg" : "smartwatch.svg";
            else if (n.includes("watch") || n.includes("saat")) file = "watch.svg";
            else if (n.includes("gamepad") || n.includes("xbox") || n.includes("dual") || n.includes("controller")) file = isV2 ? "console-controller.svg" : "gamepad.svg";
            else if (n.includes("esp32")) file = "esp32.svg";
            else if (n.includes("desktop")) file = "desktop.svg";
            else if (n.includes("phone") || n.includes("telefon") || n.includes("galaxy") || n.includes("pixel") || n.includes("iphone") || n.includes("samsung")) file = isV2 ? "phone.svg" : "smartphone.svg";
            else if (n.includes("tablet") || n.includes("ipad") || n.includes("tab")) file = isV2 ? "tablet.svg" : "tablet.svg";
            else if (n.includes("tv") || n.includes("android tv")) file = "tv.svg";
            else {
                if (i.includes("mouse")) file = "mouse.svg";
                else if (i.includes("keyboard")) file = "keyboard.svg";
                else if (i.includes("laptop")) file = "laptop.svg";
                else file = "laptop.svg"; 
            }
            
            return Qt.resolvedUrl("../../icons/" + iconVersion + "/" + file);
        }
    }
}
