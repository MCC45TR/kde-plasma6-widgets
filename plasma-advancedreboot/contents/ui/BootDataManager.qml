import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

Item {
    id: root

    property var bootEntries: []
    property bool isLoading: false

    // Signals
    signal entriesLoaded(var entries)
    
    // Command properties
    property string cmdWindowsVer: ""

    function updateWindowsVerCmd() {
        var scriptPath = Qt.resolvedUrl("../tools/find_windows_mount.sh").toString()
        if (scriptPath.startsWith("file://")) {
            scriptPath = scriptPath.substring(7)
        }
        root.cmdWindowsVer = "sh \"" + scriptPath + "\""
    }
    
    function processEntries(entries) {
        for (var k = 0; k < entries.length; k++) {
            // Clean Title Logic
            var t = entries[k].title || ""
            // Remove content in parentheses e.g. (KDE Plasma), (Workstation), (kernel version)
            // User requested "Fedora Linux 44" from "Fedora Linux 44 (KDE...)"
            t = t.replace(/\s*\(.*?\)/g, "")
            
            // Note: We are keeping "Linux" as per latest user request "sadece Fedora Linux 44 yazmalı"
            // If we wanted to remove Linux: t = t.replace(/ GNU\/Linux/g, "").replace(/ Linux/g, "")
            
            entries[k].title = t.trim()

            // Rename Firmware/BIOS entry
            if (entries[k].id === "auto-reboot-to-firmware-setup" || 
                entries[k].title === "Reboot Into Firmware Interface" || 
                entries[k].title.toLowerCase() === "reboot into firmware interface") {
                entries[k].title = i18n("BIOS / Firmware")
                entries[k].isFirmware = true
            }
        }
        return entries
    }

    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        
        onNewData: (sourceName, data) => {
            console.log("BootDataManager: New Data from " + sourceName)
            console.log("BootDataManager: Data keys: " + Object.keys(data).join(", "))
            
            if (data["exit code"] !== undefined && data["exit code"] > 0) {
                 console.error("BootDataManager: Command failed with exit code: " + data["exit code"])
                 if (data["stderr"]) console.error("BootDataManager: Stderr: " + data["stderr"])
            }

            if (sourceName.indexOf("bootctl list") !== -1 && data["stdout"]) {
                console.log("BootDataManager: Received bootctl output (length: " + data["stdout"].length + ")")
                try {
                    var rawEntries = JSON.parse(data["stdout"])
                    console.log("BootDataManager: Parsed " + rawEntries.length + " entries")
                    
                    var entries = processEntries(rawEntries)

                    root.bootEntries = entries
                    Plasmoid.configuration.cachedBootEntries = data["stdout"]
                    
                    checkForWindowsVersion()
                    root.isLoading = false
                    loadingTimer.stop() // Stop timer on success
                    entriesLoaded(entries)
                    console.log("BootDataManager: Loading finished successfully")
                } catch(e) {
                    console.error("BootDataManager: Error parsing bootctl JSON: " + e)
                    // Don't set isLoading false yet if we want to retry or debugging, but here it's fatal for this attempt
                    root.isLoading = false
                }
                execSource.disconnectSource(sourceName)
            } 
            // ... (Windows logic remains same, it triggers updates via object ref) ...
            else if (sourceName === cmdWindowsVer && data["stdout"]) {
                 // ... existing windows logic ...
                 console.log("BootDataManager: Received Windows Version")
                 var ver = data["stdout"].trim()
                 if (ver.length > 0) {
                     var formattedTitle = ""
                     try {
                         // ... (version parsing) ...
                         var parts = ver.split('.')
                         if (parts.length >= 3) {
                            var build = parseInt(parts[2])
                            if (!isNaN(build)) {
                                if (build >= 19041) formattedTitle = i18n("Windows 10") // Simplified
                                if (build >= 22000) formattedTitle = i18n("Windows 11")
                            }
                         }
                     } catch(err) {}

                     var entries = root.bootEntries
                     var updated = false
                     for (var i = 0; i < entries.length; i++) {
                        var t = (entries[i].title || "").toLowerCase()
                        var id = (entries[i].id || "").toLowerCase()
                        
                        if (t.includes("windows") || id.includes("windows")) {
                            entries[i].version = ver
                            if (formattedTitle !== "") entries[i].title = formattedTitle
                            updated = true
                        }
                     }
                     if (updated) {
                         root.bootEntries = entries
                         // We don't update cachedBootEntries with this processed data usually to keep raw source clean
                         // but we could. For now let's just update runtime.
                         entriesLoaded(entries)
                     }
                 }
                 execSource.disconnectSource(sourceName)
            }
        }
    }
    
    // ...

    Component.onCompleted: {
        updateWindowsVerCmd()
        var cached = Plasmoid.configuration.cachedBootEntries
        console.log("BootDataManager: Component completed. Cache size: " + (cached ? cached.length : 0))
        if (cached && cached.length > 0) {
            try {
                console.log("BootDataManager: Loading from cache")
                var rawCached = JSON.parse(cached)
                root.bootEntries = processEntries(rawCached)
                checkForWindowsVersion()
            } catch(e) { 
                console.error("BootDataManager: Cache corrupt")
                root.isLoading = false
            }
        } else {
             console.log("BootDataManager: No cache. NOT loading automatically.")
             root.isLoading = false
        }
    }
    
    function checkForWindowsVersion() {
        if (root.cmdWindowsVer !== "") {
             execSource.connectSource(root.cmdWindowsVer)
        }
    }

    function loadEntriesWithAuth() {
        console.log("BootDataManager: Requesting entries with Auth...")
        root.isLoading = true
        loadingTimer.restart()
        execSource.connectSource("pkexec bootctl list --json=short") 
    }

    function rebootToEntry(id) {
        console.log("BootDataManager: Rebooting to " + id)
        var cmd = ""
        if (id === "auto-reboot-to-firmware-setup" || id === "reboot-into-firmware-interface") {
            // SetRebootToFirmwareSetup b true
            cmd = "busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager SetRebootToFirmwareSetup b true"
        } else {
             // SetRebootToBootLoaderEntry s "id"
            cmd = "busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager SetRebootToBootLoaderEntry s \"" + id + "\""
        }
        // Chain with reboot
        cmd += " && systemctl reboot"
        
        console.log("BootDataManager: Command: " + cmd)
        execSource.connectSource(cmd)
    }
    
    Timer {
        id: loadingTimer
        interval: 30000
        repeat: false
        onTriggered: {
            console.log("BootDataManager: Timer triggered. IsLoading: " + root.isLoading)
            if (root.isLoading && root.bootEntries.length === 0) {
                console.warn("BootDataManager: Loading timed out. Forcing stop.")
                root.isLoading = false
            }
        }
    }
}
