import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

Item {
    id: root

    property var bootEntries: []
    property bool isLoading: false
    property string errorMessage: ""

    // Signals
    signal entriesLoaded(var entries)
    
    // Command properties
    property string cmdWindowsVer: ""
    property string cmdGrubParse: ""
    property string activeBootloader: "systemd-boot"

    function updateWindowsVerCmd() {
        var scriptPath = Qt.resolvedUrl("../tools/find_windows_mount.sh").toString()
        if (scriptPath.startsWith("file://")) {
            scriptPath = scriptPath.substring(7)
        }
        root.cmdWindowsVer = "sh \"" + scriptPath + "\""
        
        var grubScriptPath = Qt.resolvedUrl("../tools/find_grub_entries.sh").toString()
        if (grubScriptPath.startsWith("file://")) {
            grubScriptPath = grubScriptPath.substring(7)
        }
        root.cmdGrubParse = "sh \"" + grubScriptPath + "\""
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
                entries[k].id === "uefi-firmware" || 
                entries[k].title === "UEFI Firmware Settings" || 
                entries[k].title === "Reboot Into Firmware Interface" || 
                entries[k].title.toLowerCase() === "reboot into firmware interface") {
                entries[k].title = i18n("BIOS / Firmware")
                entries[k].isFirmware = true
            }
        }
        
        // --- Apply Custom Rules --- //
        var rulesStr = Plasmoid.configuration.customEntryRules || ""
        if (rulesStr.trim() !== "") {
            try {
                var rules = JSON.parse(rulesStr)
                var finalEntries = []
                
                // Map rules by id for quick lookup
                var rulesMap = {}
                for (var r = 0; r < rules.length; r++) {
                    rulesMap[rules[r].id] = rules[r]
                }
                
                // Track which entries from rules were added
                var addedIds = {}
                
                // 1. Add known entries based on rules order
                for (var r = 0; r < rules.length; r++) {
                    var rule = rules[r]
                    if (rule.isHidden) continue
                    
                    var foundEntry = null
                    for (var e = 0; e < entries.length; e++) {
                        if (entries[e].id === rule.id) {
                            foundEntry = entries[e]
                            break
                        }
                    }
                    
                    if (foundEntry) {
                        if (rule.customTitle && rule.customTitle !== "") {
                            foundEntry.title = rule.customTitle
                        }
                        if (rule.customIcon && rule.customIcon !== "") {
                            foundEntry.customIcon = rule.customIcon
                        }
                        finalEntries.push(foundEntry)
                        addedIds[rule.id] = true
                    }
                }
                
                // 2. Append any new/unconfigured entries
                for (var e = 0; e < entries.length; e++) {
                    if (!addedIds[entries[e].id]) {
                        finalEntries.push(entries[e])
                    }
                }
                
                return finalEntries
            } catch(jsonErr) {
                console.error("BootDataManager: Failed to parse custom rules: " + jsonErr)
            }
        }
        
        return entries
    }

    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        
        onNewData: function(sourceName, data) {
            console.log("BootDataManager: New Data from " + sourceName)
            console.log("BootDataManager: Data keys: " + Object.keys(data).join(", "))
            
            if (data["exit code"] !== undefined && data["exit code"] > 0) {
                 console.error("BootDataManager: Command failed with exit code: " + data["exit code"])
                 if (data["stderr"]) console.error("BootDataManager: Stderr: " + data["stderr"])
                 
                 if (sourceName.indexOf("bootctl list") !== -1) {
                     if (data["stderr"]) {
                         var errStr = data["stderr"].toLowerCase();
                         if (errStr.includes("not booted with efi") || errStr.includes("systemd-boot not installed") || errStr.includes("efi variables") || errStr.includes("couldn't find efi")) {
                             root.errorMessage = i18n("System is not booted with systemd-boot or EFI is not active.")
                         } else if (data["exit code"] === 126 || data["exit code"] === 127 || errStr.includes("polkit")) {
                             root.errorMessage = i18n("Authorization failed or canceled.")
                         } else {
                             root.errorMessage = i18n("Systemd-boot error: ") + data["stderr"]
                         }
                     } else {
                         root.errorMessage = i18n("Systemd-boot failed with exit code: ") + data["exit code"]
                     }
                     root.isLoading = false
                     loadingTimer.stop()
                 } else if (sourceName.indexOf("find_grub_entries") !== -1) {
                      var grubErrStr = data["stderr"] ? data["stderr"].toLowerCase() : "";
                      if (data["exit code"] === 126 || data["exit code"] === 127 || grubErrStr.includes("polkit")) {
                          root.errorMessage = i18n("Authorization failed or canceled.")
                      } else {
                          root.errorMessage = i18n("Error reading GRUB configuration or requires root.")
                      }
                      root.isLoading = false
                      loadingTimer.stop()
                 }
            } else {
                 if (sourceName.indexOf("bootctl list") !== -1 || sourceName.indexOf("find_grub_entries") !== -1) {
                     root.errorMessage = ""
                 }
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
            } else if (sourceName.indexOf("find_grub_entries") !== -1 && data["stdout"]) {
                console.log("BootDataManager: Received GRUB output")
                try {
                    var rawEntries = JSON.parse(data["stdout"])
                    console.log("BootDataManager: Parsed " + rawEntries.length + " GRUB entries")
                    
                    if (rawEntries.length === 0) {
                        root.errorMessage = i18n("System is not booted with systemd-boot and GRUB returns no entries.")
                        root.isLoading = false
                        loadingTimer.stop()
                        execSource.disconnectSource(sourceName)
                        return
                    }

                    var entries = processEntries(rawEntries)
                    root.bootEntries = entries
                    Plasmoid.configuration.cachedBootEntries = data["stdout"]
                    Plasmoid.configuration.cachedBootloader = "grub"
                    
                    checkForWindowsVersion()
                    root.isLoading = false
                    loadingTimer.stop()
                    entriesLoaded(entries)
                } catch(e) {
                    console.error("BootDataManager: Error parsing GRUB JSON: " + e)
                    root.errorMessage = i18n("Error parsing GRUB configuration.")
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
                         var parts = ver.split('.')
                         if (parts.length >= 3) {
                            var build = parseInt(parts[2])
                            if (!isNaN(build)) {
                                if (build >= 22000) formattedTitle = i18n("Windows 11")
                                else if (build >= 10240) formattedTitle = i18n("Windows 10")
                                else if (build >= 9600) formattedTitle = i18n("Windows 8.1")
                                else if (build >= 9200) formattedTitle = i18n("Windows 8")
                                else if (build >= 7600) formattedTitle = i18n("Windows 7")
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
        var cachedLoader = Plasmoid.configuration.cachedBootloader
        if (cachedLoader) root.activeBootloader = cachedLoader
        
        console.log("BootDataManager: Component completed. Cache size: " + (cached ? cached.length : 0))
        if (cached && cached.length > 0) {
            try {
                console.log("BootDataManager: Loading from cache (" + root.activeBootloader + ")")
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
    
    Connections {
        target: Plasmoid.configuration
        function onCustomEntryRulesChanged() {
            var cached = Plasmoid.configuration.cachedBootEntries
            if (cached && cached.length > 0) {
                try {
                    var rawCached = JSON.parse(cached)
                    root.bootEntries = processEntries(rawCached)
                    checkForWindowsVersion()
                } catch(e) {}
            }
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
        root.errorMessage = ""
        loadingTimer.restart()
        
        var cfgLoader = Plasmoid.configuration.cachedBootloader
        if (cfgLoader) root.activeBootloader = cfgLoader
        
        if (root.activeBootloader === "grub") {
             execSource.connectSource("pkexec " + root.cmdGrubParse)
        } else {
             execSource.connectSource("pkexec bootctl list --json=short") 
        }
    }

    function rebootToEntry(id) {
        console.log("BootDataManager: Rebooting to " + id)
        var cmd = ""
        if (root.activeBootloader === "grub") {
             // Basic grub-reboot vs grub2-reboot check with bash-safe quoting
             var safeId = id.replace(/'/g, "'\\''")
             cmd = "if command -v grub-reboot >/dev/null 2>&1; then pkexec grub-reboot '" + safeId + "'; elif command -v grub2-reboot >/dev/null 2>&1; then pkexec grub2-reboot '" + safeId + "'; else exit 1; fi"
        } else {
             if (id === "auto-reboot-to-firmware-setup" || id === "reboot-into-firmware-interface") {
                 // SetRebootToFirmwareSetup b true
                 cmd = "busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager SetRebootToFirmwareSetup b true"
             } else {
                  // SetRebootToBootLoaderEntry s "id"
                 cmd = "busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager SetRebootToBootLoaderEntry s \"" + id + "\""
             }
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
