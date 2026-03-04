import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: root

    // === SYSTEM PROPERTIES ===
    property bool isAvailable: false

    // Permission state: "unknown" | "needs_setup" | "needs_relogin" | "ready"
    property string permissionStatus: "unknown"
    property bool setupInProgress: false

    // Convenience: controls should be enabled only when ready
    readonly property bool canWrite: permissionStatus === "ready"

    // Feature availability flags (auto-detected from sysfs)
    property bool hasWebcam: false
    property bool hasWebcamBlock: false
    property bool hasCoolerBoost: false
    property bool hasSuperBattery: false
    property bool hasShiftMode: false
    property bool hasFanMode: false
    property bool hasFnKey: false
    property bool hasWinKey: false
    property bool hasUsbPower: false
    property bool hasKbdBacklight: false
    property bool hasBatteryThreshold: false
    property bool hasCpuTemp: false
    property bool hasGpuTemp: false
    property bool hasCpuFan: false
    property bool hasGpuFan: false
    property bool hasCpuBasicFanSpeed: false
    property bool hasGpuBasicFanSpeed: false

    // Metrics
    property int cpuTemp: 0
    property int gpuTemp: 0
    property int cpuFan: 0
    property int gpuFan: 0

    // Modes (dynamic)
    property string shiftMode: "comfort"
    property var availableShiftModes: []
    property string fanMode: "auto"
    property var availableFanModes: []

    // Toggles
    property bool coolerBoost: false
    property bool webcamEnabled: true
    property bool webcamBlocked: false
    property bool superBattery: false
    property bool fnKeySwap: false
    property bool winKeySwap: false
    property bool usbPower: false

    // Battery
    property int batteryLimit: 100
    property int batteryStartLimit: 90
    property int batteryPercentage: 0
    property string batteryStatus: "Unknown"

    // Keyboard Backlight (0=Off, 1=On, 2=Half, 3=Full)
    property int kbdBacklight: 0

    // Basic Fan Speed (percent, for "basic" fan mode)
    property int cpuBasicFanSpeed: 0
    property int gpuBasicFanSpeed: 0

    // Firmware
    property string fwVersion: ""
    property string fwDate: ""

    // === SYSFS PATHS ===
    readonly property string basePath: "/sys/devices/platform/msi-ec"
    readonly property string batteryLimitPath: "/sys/class/power_supply/BAT1/charge_control_end_threshold"
    readonly property string batteryLimitStartPath: "/sys/class/power_supply/BAT1/charge_control_start_threshold"
    readonly property string batteryCapacityPath: "/sys/class/power_supply/BAT1/capacity"
    readonly property string batteryStatusPath: "/sys/class/power_supply/BAT1/status"
    readonly property string kbdBacklightPath: "/sys/class/leds/msiacpi::kbd_backlight/brightness"
    readonly property string cpuBasicFanSpeedPath: basePath + "/cpu/basic_fan_speed"
    readonly property string gpuBasicFanSpeedPath: basePath + "/gpu/basic_fan_speed"
    readonly property string availableShiftModesPath: basePath + "/available_shift_modes"
    readonly property string availableFanModesPath: basePath + "/available_fan_modes"
    readonly property string rulesPath: "/etc/udev/rules.d/99-msi-ec.rules"

    // === DATA SOURCES ===
    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            handleCommandResult(source, data)
            disconnectSource(source)
        }
    }

    // Fast timer — metrics only (temps + fan speeds): 1 second
    Timer {
        id: metricsPollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refreshMetrics()
    }

    // Slow timer — everything else: 2 seconds
    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    Component.onCompleted: {
        checkAvailability()
    }

    // ═══════════════════════════════════════════════
    //  PERMISSION CHECK (3-condition state machine)
    // ═══════════════════════════════════════════════

    // Internal state for the 3 checks
    property bool _permGroupExists: false
    property bool _permUserInGroup: false
    property bool _permRulesInstalled: false
    property bool _permSysfsWritable: false
    property int _permChecksCompleted: 0

    function checkPermissions() {
        _permChecksCompleted = 0
        // Check 1: Does group 'msi-ec' exist?
        execSource.connectSource("getent group msi-ec >/dev/null 2>&1 && echo '1' || echo '0':::permGroupExists")
        // Check 2: Is current user in 'msi-ec' group? (active session OR persistent /etc/group)
        execSource.connectSource("(id -nG 2>/dev/null | grep -qw msi-ec || grep -q '^msi-ec:.*\\b'\"$(id -un)\"'\\b' /etc/group 2>/dev/null) && echo '1' || echo '0':::permUserInGroup")
        // Check 3: Are udev rules installed?
        execSource.connectSource("test -f " + rulesPath + " && echo '1' || echo '0':::permRulesInstalled")
        // Check 4: Can we actually write to sysfs?
        execSource.connectSource("test -w " + basePath + "/shift_mode 2>/dev/null && echo '1' || echo '0':::permSysfsWritable")
    }

    function _handlePermCheck(tag, val) {
        var result = (val === "1")
        switch (tag) {
            case "permGroupExists": _permGroupExists = result; break
            case "permUserInGroup": _permUserInGroup = result; break
            case "permRulesInstalled": _permRulesInstalled = result; break
            case "permSysfsWritable": _permSysfsWritable = result; break
        }
        _permChecksCompleted++

        // All 4 checks done — determine state
        if (_permChecksCompleted >= 4) {
            if (_permSysfsWritable) {
                // Everything works — write access confirmed
                permissionStatus = "ready"
            } else if (_permGroupExists && _permRulesInstalled) {
                // Setup was done, but sysfs isn't writable yet:
                //   - User not in active session group (needs relogin)
                //   - OR udev rules haven't been re-triggered yet
                permissionStatus = "needs_relogin"
            } else {
                // Something is missing — need to run setup
                permissionStatus = "needs_setup"
            }
        }
    }

    // ═══════════════════════════════════════════════
    //  AVAILABILITY & FEATURE DETECTION
    // ═══════════════════════════════════════════════

    function checkAvailability() {
        execSource.connectSource("test -d " + basePath + " && echo '1' || echo '0'")
    }

    function detectFeatures() {
        _checkFeature(basePath + "/webcam", "hasWebcam")
        _checkFeature(basePath + "/webcam_block", "hasWebcamBlock")
        _checkFeature(basePath + "/cooler_boost", "hasCoolerBoost")
        _checkFeature(basePath + "/super_battery", "hasSuperBattery")
        _checkFeature(basePath + "/shift_mode", "hasShiftMode")
        _checkFeature(basePath + "/fan_mode", "hasFanMode")
        _checkFeature(basePath + "/fn_key", "hasFnKey")
        _checkFeature(basePath + "/win_key", "hasWinKey")
        _checkFeature(basePath + "/usb_power", "hasUsbPower")
        _checkFeature(kbdBacklightPath, "hasKbdBacklight")
        _checkFeature(batteryLimitPath, "hasBatteryThreshold")
        _checkFeature(basePath + "/cpu/realtime_temperature", "hasCpuTemp")
        _checkFeature(basePath + "/gpu/realtime_temperature", "hasGpuTemp")
        _checkFeature(basePath + "/cpu/realtime_fan_speed", "hasCpuFan")
        _checkFeature(basePath + "/gpu/realtime_fan_speed", "hasGpuFan")
        _checkFeature(cpuBasicFanSpeedPath, "hasCpuBasicFanSpeed")
        _checkFeature(gpuBasicFanSpeedPath, "hasGpuBasicFanSpeed")

        _read(availableShiftModesPath, "availShiftModes")
        _read(availableFanModesPath, "availFanModes")
    }

    function _checkFeature(path, tag) {
        execSource.connectSource("test -e " + path + " && echo '1' || echo '0':::" + tag)
    }

    // ═══════════════════════════════════════════════
    //  POLLING
    // ═══════════════════════════════════════════════

    // Fast metrics refresh (1 second) — temps + fan speeds only
    function refreshMetrics() {
        if (!isAvailable) return

        if (hasCpuTemp) _read(basePath + "/cpu/realtime_temperature", "cpuTemp")
        if (hasGpuTemp) _read(basePath + "/gpu/realtime_temperature", "gpuTemp")
        if (hasCpuFan) _read(basePath + "/cpu/realtime_fan_speed", "cpuFan")
        if (hasGpuFan) _read(basePath + "/gpu/realtime_fan_speed", "gpuFan")
    }

    function refresh() {
        if (!isAvailable) {
            checkAvailability()
            return
        }

        // Re-check permissions whenever not yet ready
        if (permissionStatus !== "ready") {
            checkPermissions()
        }

        // Modes
        if (hasShiftMode) _read(basePath + "/shift_mode", "shiftMode")
        if (hasFanMode) _read(basePath + "/fan_mode", "fanMode")

        // Toggles
        if (hasCoolerBoost) _read(basePath + "/cooler_boost", "coolerBoost")
        if (hasWebcam) _read(basePath + "/webcam", "webcam")
        if (hasWebcamBlock) _read(basePath + "/webcam_block", "webcam_block")
        if (hasSuperBattery) _read(basePath + "/super_battery", "superBattery")
        if (hasFnKey) _read(basePath + "/fn_key", "fnKey")
        if (hasWinKey) _read(basePath + "/win_key", "winKey")
        if (hasUsbPower) _read(basePath + "/usb_power", "usbPower")

        // Battery
        if (hasBatteryThreshold) {
            _read(batteryLimitPath, "batteryLimit")
            _read(batteryLimitStartPath, "batteryStartLimit")
        }
        _read(batteryCapacityPath, "batteryPercentage")
        _read(batteryStatusPath, "batteryStatus")

        // Keyboard backlight
        if (hasKbdBacklight) _read(kbdBacklightPath, "kbdBacklight")

        // Basic fan speed
        if (hasCpuBasicFanSpeed) _read(cpuBasicFanSpeedPath, "cpuBasicFanSpeed")
        if (hasGpuBasicFanSpeed) _read(gpuBasicFanSpeedPath, "gpuBasicFanSpeed")

        // Static info (once)
        if (fwVersion === "") {
            _read(basePath + "/fw_version", "fwVersion")
            _read(basePath + "/fw_release_date", "fwDate")
        }
    }

    function _read(path, tag) {
        execSource.connectSource("cat " + path + " 2>/dev/null || echo '':::" + tag)
    }

    // ═══════════════════════════════════════════════
    //  COMMAND RESULT HANDLER
    // ═══════════════════════════════════════════════

    function handleCommandResult(source, data) {
        var output = (data["stdout"] || "").trim()

        // Driver availability check
        if (source === "test -d " + basePath + " && echo '1' || echo '0'") {
            var wasAvailable = isAvailable
            isAvailable = (output === "1")
            if (isAvailable && !wasAvailable) {
                detectFeatures()
                checkPermissions()
            }
            return
        }

        if (source.includes(":::")) {
            var tag = source.split(":::")[1]

            // Permission checks
            if (tag.startsWith("perm")) {
                _handlePermCheck(tag, output)
                return
            }

            // Feature availability checks
            if (tag.startsWith("has")) {
                _parseFeature(tag, output)
                return
            }

            // Available modes parsing
            if (tag === "availShiftModes") {
                availableShiftModes = output.split("\n").filter(function(m) { return m.trim() !== "" })
                return
            }
            if (tag === "availFanModes") {
                availableFanModes = output.split("\n").filter(function(m) { return m.trim() !== "" })
                return
            }

            _parse(tag, output)
        } else if (source.includes("> /sys/")) {
            refresh() // Reload after write
        } else if (source.includes("pkexec") && source.includes("install_permissions")) {
            // Setup script finished — re-check everything
            setupInProgress = false
            checkPermissions()
        }
    }

    function _parseFeature(tag, val) {
        root[tag] = (val === "1")
    }

    function _parse(tag, val) {
        switch (tag) {
            case "cpuTemp": cpuTemp = parseInt(val) || 0; break
            case "gpuTemp": gpuTemp = parseInt(val) || 0; break
            case "cpuFan": cpuFan = parseInt(val) || 0; break
            case "gpuFan": gpuFan = parseInt(val) || 0; break
            case "shiftMode": shiftMode = val || "comfort"; break
            case "fanMode": fanMode = val || "auto"; break
            case "coolerBoost": coolerBoost = (val === "on"); break
            case "webcam": webcamEnabled = (val === "on"); break
            case "webcam_block": webcamBlocked = (val === "on"); break
            case "superBattery": superBattery = (val === "on"); break
            case "fnKey": fnKeySwap = (val === "left"); break
            case "winKey": winKeySwap = (val === "left"); break
            case "usbPower": usbPower = (val === "on"); break
            case "batteryLimit": batteryLimit = parseInt(val) || 100; break
            case "batteryStartLimit": batteryStartLimit = parseInt(val) || 0; break
            case "batteryPercentage": batteryPercentage = parseInt(val) || 0; break
            case "batteryStatus": batteryStatus = val || "Unknown"; break
            case "kbdBacklight": kbdBacklight = parseInt(val) || 0; break
            case "cpuBasicFanSpeed": cpuBasicFanSpeed = parseInt(val) || 0; break
            case "gpuBasicFanSpeed": gpuBasicFanSpeed = parseInt(val) || 0; break
            case "fwVersion": fwVersion = val; break
            case "fwDate": fwDate = val; break
        }
    }

    // ═══════════════════════════════════════════════
    //  WRITERS (no pkexec — group-based access only)
    // ═══════════════════════════════════════════════

    function setCoolerBoost(on) { _write(basePath + "/cooler_boost", on ? "on" : "off") }
    function setWebcam(on) { _write(basePath + "/webcam", on ? "on" : "off") }
    function setWebcamBlock(blocked) { _write(basePath + "/webcam_block", blocked ? "on" : "off") }
    function setSuperBattery(on) { _write(basePath + "/super_battery", on ? "on" : "off") }
    function setFnKeySwap(on) { _write(basePath + "/fn_key", on ? "left" : "right") }
    function setWinKeySwap(on) { _write(basePath + "/win_key", on ? "left" : "right") }
    function setUsbPower(on) { _write(basePath + "/usb_power", on ? "on" : "off") }
    function setShiftMode(mode) { _write(basePath + "/shift_mode", mode) }
    function setFanMode(mode) { _write(basePath + "/fan_mode", mode) }
    function setBatteryLimit(limit) { _write(batteryLimitPath, limit.toString()) }
    function setKbdBacklight(level) { _write(kbdBacklightPath, level.toString()) }
    function setCpuBasicFanSpeed(pct) { _write(cpuBasicFanSpeedPath, pct.toString()) }
    function setGpuBasicFanSpeed(pct) { _write(gpuBasicFanSpeedPath, pct.toString()) }

    function setBatteryThresholds(start, end) {
        // Battery thresholds need atomic write (start before end)
        var cmd = "sh -c 'echo \"" + start + "\" > " + batteryLimitStartPath + " && echo \"" + end + "\" > " + batteryLimitPath + "'"
        execSource.connectSource(cmd)
    }

    // One-time setup — the ONLY place pkexec is used
    function setupPermissions() {
        setupInProgress = true
        var scriptPath = Qt.resolvedUrl("../scripts/install_permissions.sh").toString().replace("file://", "")
        execSource.connectSource("pkexec " + scriptPath)
    }

    // Pure group-based write — NO pkexec, NO sudo
    function _write(path, val) {
        if (!canWrite) return  // Silently refuse if no permission
        execSource.connectSource("sh -c 'echo \"" + val + "\" > " + path + "'")
    }

    // Log out current session (KDE Plasma)
    function execLogout() {
        execSource.connectSource("qdbus org.kde.Shutdown /Shutdown logout")
    }
}
