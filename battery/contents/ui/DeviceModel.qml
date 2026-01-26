import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.bluezqt as BluezQt

Item {
    id: root
    
    // Combined list of all power sources
    property var devices: []
    property var mainDevice: null 

    readonly property BluezQt.Manager btManager: BluezQt.Manager

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        interval: 2000 
        onNewData: refreshDevices()
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

    property bool useCustomIcons: Plasmoid.configuration.useCustomIcons
    property string iconVersion: Plasmoid.configuration.iconVersion || "v1"
    
    function refreshDevices() {
        var newList = []
        var mainBat = null
        
        // 1. Laptop/Main Battery
        // Check if "Battery" source exists and has capacity
        var hasBattery = pmSource.data["Battery"] && pmSource.data["Battery"]["Has Battery"]
        
        if (hasBattery) {
            mainBat = {
                name: "Laptop", 
                icon: resolveIcon("laptop", "computer-laptop"),
                percentage: pmSource.data["Battery"]["Percent"] || 0,
                isCharging: pmSource.data["AC Adapter"] ? pmSource.data["AC Adapter"]["Plugged in"] : false,
                isMain: true,
                remainingTime: (function() {
                    var msec = pmSource.data["Battery"]["Remaining msec"] || 0
                    if (msec > 0) {
                        var totalMins = Math.floor(msec / 60000)
                        var h = Math.floor(totalMins / 60)
                        var m = totalMins % 60
                        return h + ":" + (m < 10 ? "0" + m : m)
                    }
                    return ""
                })()
            }
            newList.push(mainBat)
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
                            isMain: false
                        })
                    }
                }
            }
        }
        
        devices = newList
        mainDevice = mainBat
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
            if (n.includes("phone") || n.includes("telefon") || n.includes("iphone")) return "device-smartphone";
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
