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

    function refreshDevices() {
        var newList = []
        var mainBat = null
        
        // 1. Laptop/Main Battery
        // Check if "Battery" source exists and has capacity
        var hasBattery = pmSource.data["Battery"] && pmSource.data["Battery"]["Has Battery"]
        
        if (hasBattery) {
            mainBat = {
                name: "Laptop", // Hostname will be fetched in UI
                icon: "computer-laptop",
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
                            icon: getBluetoothIcon(dev),
                            percentage: per,
                            isCharging: false, // Bluetooth usually doesn't report charging state reliable via this API?
                            isMain: false
                        })
                    }
                }
            }
        }
        
        // Sort: Main first, then by low battery?
        // Requirement doesn't specify sort order, but Main should usually be prominent.
        
        devices = newList
        mainDevice = mainBat
    }
    
    function getBluetoothIcon(dev) {
        var name = dev.name ? dev.name.toLowerCase() : ""
        var icon = dev.iconName || ""
        
        // 1. Name based overriding (most specific)
        if (name.includes("mouse") || name.includes("fare") || name.includes("mx master") || name.includes("mx any") || name.includes("logitech m") || name.includes("mi mouse")) return "input-mouse";
        if (name.includes("keyboard") || name.includes("klavye") || name.includes("keychron") || name.includes("mx keys") || name.includes("logitech k")) return "input-keyboard";
        if (name.includes("headset") || name.includes("kulaklık") || name.includes("wh-") || name.includes("quietcomfort")) return "audio-headset";
        if (name.includes("headphone") || name.includes("buds") || name.includes("airpods") || name.includes("freebuds") || name.includes("tws") || name.includes("wf-") || name.includes("dots")) return "audio-headphones";
        if (name.includes("speaker") || name.includes("hoparlör") || name.includes("jbl") || name.includes("boom") || name.includes("soundcore") || name.includes("flip") || name.includes("charge")) return "audio-speakers";
        if (name.includes("phone") || name.includes("telefon") || name.includes("iphone") || name.includes("galaxy")) return "device-smartphone";
        if (name.includes("watch") || name.includes("saat") || name.includes("watch gt") || name.includes("galaxy watch") || name.includes("apple watch") || name.includes("mi band")) return "device-watch";
        if (name.includes("gamepad") || name.includes("controller") || name.includes("xbox") || name.includes("dualsense") || name.includes("dualshock")) return "input-gaming";
        if (name.includes("esp32") || name.includes("arduino") || name.includes("raspberry")) return "applications-electronics";

        // 2. Icon Name based fallback
        if (icon.includes("mouse")) return "input-mouse";
        if (icon.includes("keyboard")) return "input-keyboard";
        if (icon.includes("headset")) return "audio-headset";
        if (icon.includes("headphone") || icon.includes("earbud")) return "audio-headphones";
        if (icon.includes("audio") || icon.includes("speaker")) return "audio-speakers";
        if (icon.includes("phone") || icon.includes("smartphone")) return "device-smartphone";
        if (icon.includes("computer") || icon.includes("laptop")) return "computer-laptop";
        if (icon.includes("watch")) return "device-watch";
        
        // 3. Fallback to generic bluetooth icon
        return icon && icon !== "" ? icon : "network-bluetooth";
    }
}
