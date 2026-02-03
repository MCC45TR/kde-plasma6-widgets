import QtQuick
import QtQml
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
    property string powerBackend: "" // "tuned", "ppd", or ""
    
    P5Support.DataSource {
        id: powerProfileSource
        engine: "executable"
        connectedSources: []
        
        onNewData: (source, data) => {
            if (data["exit code"] > 0) return
            
            var stdout = data["stdout"].trim()
            
            // Backend Detection & Reading
            if (source === "check_backend") {
                // Determine backend based on output
                disconnectSource("check_backend")
                return
            }
            
            if (source === "powerprofilesctl get") {
                root.powerBackend = "ppd"
                root.currentPowerProfile = stdout
            } 
            else if (source === "tuned-adm active") {
                root.powerBackend = "tuned"
                // Output format: "Current active profile: balanced"
                var parts = stdout.split(": ")
                if (parts.length > 1) {
                    var profile = parts[1].trim()
                    // Map tuned profile to UI profile
                    if (profile === "powersave") root.currentPowerProfile = "power-saver"
                    else if (profile === "throughput-performance") root.currentPowerProfile = "performance"
                    else root.currentPowerProfile = "balanced"
                }
            }
            
            disconnectSource(source)
        }
        
        function detectBackend() {
            // Try PPD first, then Tuned
            // We connect to both, whichever returns valid data first/wins dictates backend, 
            // but effectively we prefer PPD if both exist (rare), or just whatever works.
            connectSource("powerprofilesctl get")
            connectSource("tuned-adm active")
        }
        
        function fetchProfile() {
            if (powerBackend === "ppd") {
                connectSource("powerprofilesctl get")
            } else if (powerBackend === "tuned") {
                connectSource("tuned-adm active")
            } else {
                detectBackend()
            }
        }
        
        function setProfile(profile) {
            if (powerBackend === "ppd") {
                connectSource("powerprofilesctl set " + profile)
            } else if (powerBackend === "tuned") {
                // Map UI profile to Tuned profile
                var tunedProfile = "balanced"
                if (profile === "power-saver") tunedProfile = "powersave"
                else if (profile === "performance") tunedProfile = "throughput-performance"
                
                connectSource("tuned-adm profile " + tunedProfile)
            }
            
            // Re-fetch after short delay
            Qt.callLater(fetchProfile)
        }
    }
    
    function setPowerProfile(profile) {
        powerProfileSource.setProfile(profile)
    }
    
    Component.onCompleted: {
        powerProfileSource.detectBackend()
        refreshDevices()
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

    // === HOSTNAME ===
    property string hostName: ""
    
    P5Support.DataSource {
        id: hostNameSource
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (data["exit code"] === 0) {
                root.hostName = data["stdout"].trim()
            }
            disconnectSource(source)
        }
        function fetchHostName() {
            connectSource("uname -n")
        }
    }
    
    // === TIME HELPER ===
    function formatFinishTime(msec) {
        if (msec <= 0) return ""
        var now = new Date()
        var finish = new Date(now.getTime() + msec)
        var h = finish.getHours()
        var m = finish.getMinutes()
        return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m)
    }

    property alias pmSourceData: pmSource.data

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        interval: 2000 
        onNewData: {
            refreshDevices()
            powerProfileSource.fetchProfile()
            if (root.hostName === "") hostNameSource.fetchHostName()
        }
    }
    
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: refreshDevices()
    }
    

    
    Connections {
        target: btManager
        function onDeviceAdded() { refreshDevices() }
        function onDeviceChanged() { refreshDevices() }
        function onDeviceRemoved() { refreshDevices() }
        function onOperationalChanged() { refreshDevices() }
    }

    // === KDE Connect Integration via Instantiator ===
    Instantiator {
        id: kdeConnectInstantiator
        model: kdeConnectDevices
        
        delegate: QtObject {
            id: deviceWrapper
            
            // Access roles from the model
            readonly property string deviceId: model.deviceId
            readonly property string deviceName: model.name
            readonly property string deviceType: model.type || ""
            readonly property string deviceIcon: model.iconName
            
            // Interfaces
            readonly property var deviceInterface: KDEConnect.DeviceDbusInterfaceFactory.create(deviceId)
            readonly property var batteryInterface: KDEConnect.DeviceBatteryDbusInterfaceFactory.create(deviceId)
            
            // Plugin Checker
            readonly property var pluginChecker: KDEConnect.PluginChecker {
                pluginName: "battery"
                device: deviceWrapper.deviceInterface
            }
            
            readonly property bool hasBatteryConfig: pluginChecker.available
            readonly property int charge: batteryInterface ? batteryInterface.charge : -1
            readonly property bool isCharging: batteryInterface ? batteryInterface.isCharging : false
            
            // Trigger refresh when relevant properties change
            onHasBatteryConfigChanged: root.scheduleRefresh()
            onChargeChanged: root.scheduleRefresh()
            onIsChargingChanged: root.scheduleRefresh()
        }
        
        onObjectAdded: root.scheduleRefresh()
        onObjectRemoved: root.scheduleRefresh()
    }

    property bool useCustomIcons: false
    property string iconVersion: "v1"
    
    // De-bounce refresh to avoid too many updates
    Timer {
        id: refreshTimer
        interval: 100
        repeat: false
        onTriggered: refreshDevices()
    }
    
    function scheduleRefresh() {
        refreshTimer.restart()
    }

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
        
        // 3. KDE Connect Devices (via Instantiator)
        for (var j = 0; j < kdeConnectInstantiator.count; j++) {
            var wrapper = kdeConnectInstantiator.objectAt(j)
            
            if (wrapper.hasBatteryConfig && wrapper.charge >= 0) {
                var kdeDeviceType = getKdeConnectDeviceType(wrapper.deviceType)
                newList.push({
                    name: wrapper.deviceName,
                    icon: resolveIcon(wrapper.deviceName, getKdeConnectIcon(kdeDeviceType)),
                    percentage: wrapper.charge,
                    isCharging: wrapper.isCharging,
                    isMain: false,
                    deviceType: kdeDeviceType
                })
            }
        }
        
        devices = newList
        mainDevice = mainBat
    }
    
    function getKdeConnectDeviceType(typeStr) {
        // KDE Connect device types: smartphone, tablet, desktop, laptop, tv
        var type = typeStr || ""
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
