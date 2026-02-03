import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: root
    
    // === PROPERTIES ===
    property bool isAvailable: false
    
    // Temperatures
    property int cpuTemp: 0
    property int gpuTemp: 0
    
    // Fan speeds (percent)
    property int cpuFan: 0
    property int gpuFan: 0
    
    // Modes
    property string shiftMode: "comfort"
    property var availableShiftModes: []
    property string fanMode: "auto"
    property var availableFanModes: []
    
    // Toggles
    property bool coolerBoost: false
    property bool webcamEnabled: true
    property bool superBattery: false
    // New Toggles
    property bool fnKeySwap: false 
    property bool usbPower: false
    
    // Battery
    property int batteryLimit: 100
    property int batteryPercentage: 0
    
    // Firmware info
    property string fwVersion: ""
    property string fwDate: ""
    
    // Base path
    readonly property string basePath: "/sys/devices/platform/msi-ec"
    readonly property string batteryLimitPath: "/sys/class/power_supply/BAT1/charge_control_end_threshold"
    readonly property string batteryCapacityPath: "/sys/class/power_supply/BAT1/capacity"
    
    // === DATA SOURCE ===
    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        
        onNewData: (source, data) => {
            handleCommandResult(source, data)
            disconnectSource(source)
        }
    }
    
    // === POLLING TIMER ===
    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refreshAll()
    }
    
    Component.onCompleted: {
        checkAvailability()
    }
    
    // === FUNCTIONS ===
    
    function checkAvailability() {
        execSource.connectSource("test -d " + basePath + " && echo 'available' || echo 'unavailable'")
    }
    
    function refreshAll() {
        if (!isAvailable) {
            checkAvailability()
            return
        }
        
        // Read temperatures
        readFile(basePath + "/cpu/realtime_temperature", "cpuTemp")
        readFile(basePath + "/gpu/realtime_temperature", "gpuTemp")
        
        // Read fan speeds
        readFile(basePath + "/cpu/realtime_fan_speed", "cpuFan")
        readFile(basePath + "/gpu/realtime_fan_speed", "gpuFan")
        
        // Read modes
        readFile(basePath + "/shift_mode", "shiftMode")
        readFile(basePath + "/fan_mode", "fanMode")
        readFile(basePath + "/available_shift_modes", "availableShiftModes")
        readFile(basePath + "/available_fan_modes", "availableFanModes")
        
        // Read toggles
        readFile(basePath + "/cooler_boost", "coolerBoost")
        readFile(basePath + "/webcam", "webcam")
        readFile(basePath + "/super_battery", "superBattery")
        // New toggles (paths are guesses, adjust if needed)
        readFile(basePath + "/fn_key_swap", "fnKeySwap")
        readFile(basePath + "/usb_power", "usbPower")
        
        // Read battery
        readFile(batteryLimitPath, "batteryLimit")
        readFile(batteryCapacityPath, "batteryPercentage")
        
        // Read firmware info
        readFile(basePath + "/fw_version", "fwVersion")
        readFile(basePath + "/fw_release_date", "fwDate")
    }
    
    function readFile(path, tag) {
        execSource.connectSource("cat " + path + " 2>/dev/null || echo '':::" + tag)
    }
    
    function handleCommandResult(source, data) {
        if (data["exit code"] !== 0 && !source.includes(":::")) return
        
        var output = (data["stdout"] || "").trim()
        
        // Check availability
        if (source.includes("test -d")) {
            isAvailable = (output === "available")
            if (isAvailable) refreshAll()
            return
        }
        
        // Parse tagged results
        if (source.includes(":::")) {
            var tag = source.split(":::")[1]
            parseResult(tag, output)
            return
        }
        
        // Handle write confirmations
        if (source.includes("pkexec")) {
            refreshAll() // Refresh after write
        }
    }
    
    function parseResult(tag, value) {
        switch (tag) {
            case "cpuTemp":
                cpuTemp = parseInt(value) || 0
                break
            case "gpuTemp":
                gpuTemp = parseInt(value) || 0
                break
            case "cpuFan":
                cpuFan = parseInt(value) || 0
                break
            case "gpuFan":
                gpuFan = parseInt(value) || 0
                break
            case "shiftMode":
                shiftMode = value || "comfort"
                break
            case "fanMode":
                fanMode = value || "auto"
                break
            case "availableShiftModes":
                availableShiftModes = value.split("\n").filter(s => s.length > 0)
                break
            case "availableFanModes":
                availableFanModes = value.split("\n").filter(s => s.length > 0)
                break
            case "coolerBoost":
                coolerBoost = (value === "on")
                break
            case "webcam":
                webcamEnabled = (value === "on")
                break
            case "superBattery":
                superBattery = (value === "on")
                break
            case "fnKeySwap":
                fnKeySwap = (value === "on")
                break
            case "usbPower":
                usbPower = (value === "on")
                break
            case "batteryLimit":
                batteryLimit = parseInt(value) || 100
                break
            case "batteryPercentage":
                batteryPercentage = parseInt(value) || 0
                break
            case "fwVersion":
                fwVersion = value
                break
            case "fwDate":
                fwDate = value
                break
        }
    }
    
    // === WRITE FUNCTIONS ===
    
    function setShiftMode(mode) {
        writeFile(basePath + "/shift_mode", mode)
    }
    
    function setFanMode(mode) {
        writeFile(basePath + "/fan_mode", mode)
    }
    
    function setCoolerBoost(enabled) {
        writeFile(basePath + "/cooler_boost", enabled ? "on" : "off")
    }
    
    function setWebcam(enabled) {
        writeFile(basePath + "/webcam", enabled ? "on" : "off")
    }
    
    function setSuperBattery(enabled) {
        writeFile(basePath + "/super_battery", enabled ? "on" : "off")
    }
    
    function setFnKeySwap(enabled) {
        writeFile(basePath + "/fn_key_swap", enabled ? "on" : "off")
    }
    
    function setUsbPower(enabled) {
        writeFile(basePath + "/usb_power", enabled ? "on" : "off")
    }
    
    function setBatteryLimit(limit) {
        writeFile(batteryLimitPath, limit.toString())
    }
    
    function writeFile(path, value) {
        // Use pkexec for privileged write
        var cmd = "pkexec bash -c 'echo \"" + value + "\" > " + path + "'"
        execSource.connectSource(cmd)
    }
}
