import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

Item {
    id: root

    property var bootEntries: []
    property var viewEntries: [] // What is currently displayed (main or folder)
    property bool isViewingSubMenu: false
    property string subMenuTitle: ""
    property bool isLoading: false
    property string errorMessage: ""

    // Signals
    signal entriesLoaded(var entries)

    // Command properties
    property string cmdEntryFinder: ""
    property string cmdWindowsVer: ""
    property string activeBootloader: "systemd-boot"

    function updatePaths() {
        var winScriptPath = Qt.resolvedUrl("../tools/find_windows_mount.sh").toString()
        if (winScriptPath.startsWith("file://")) {
            winScriptPath = winScriptPath.substring(7)
        }
        root.cmdWindowsVer = "sh \"" + winScriptPath + "\""
        
        var finderScriptPath = Qt.resolvedUrl("../tools/boot_entry_finder.sh").toString()
        if (finderScriptPath.startsWith("file://")) {
            finderScriptPath = finderScriptPath.substring(7)
        }
        root.cmdEntryFinder = "sh \"" + finderScriptPath + "\""
    }
    
    function processEntries(entries) {
        for (var k = 0; k < entries.length; k++) {
            var t = entries[k].title || ""
            var lowT = t.toLowerCase()
            var isSnapshot = lowT.includes("snapper") || lowT.includes("snapshot") || lowT.includes("|") || t.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)
            
            if (!isSnapshot) {
                // Remove content in parentheses e.g. (KDE Plasma), (Workstation), (kernel version)
                // Snapshot titles keep their version details in parentheses or brackets.
                t = t.replace(/\s*\(.*?\)/g, "")
                t = t.replace(/\s*\[.*?\]/g, "")
            }
            
            entries[k].title = t.trim()
            entries[k].isSnapshot = !!isSnapshot

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
                
                // 3. Automatic Grouping for Snapshots (Limine-specific or general)
                var loader = Plasmoid.configuration.cachedBootloader
                if (loader === "limine") {
                    var groupedFinal = []
                    var snapshots = []
                    for (var j = 0; j < finalEntries.length; j++) {
                        var entry = finalEntries[j]
                        if (entry.isSnapshot) {
                            snapshots.push(entry)
                        } else {
                            groupedFinal.push(entry)
                        }
                    }
                    
                    if (snapshots.length > 0) {
                        // Create a special folder entry
                        var folder = {
                            id: "folder-snapshots",
                            title: "BTRFS Snapshots", // User requested this exact name
                            isFolder: true,
                            subEntries: snapshots
                        }
                        // Insert new groups before firmware entries when possible.
                        groupedFinal.push(folder)
                    }
                    return groupedFinal
                }
                
                return finalEntries
            } catch(jsonErr) {
                console.error("BootDataManager: Failed to parse custom rules: " + jsonErr)
            }
        }
        
        return entries
    }
    
    function setRootEntries(entries) {
        root.bootEntries = entries
        if (!root.isViewingSubMenu) {
            root.viewEntries = entries
        }
    }
    
    function openSubMenu(folder) {
        root.viewEntries = folder.subEntries
        root.subMenuTitle = folder.title
        root.isViewingSubMenu = true
    }
    
    function closeSubMenu() {
        root.viewEntries = root.bootEntries
        root.subMenuTitle = ""
        root.isViewingSubMenu = false
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
                  
                  if (sourceName.indexOf("boot_entry_finder.sh fetch") !== -1 || sourceName.indexOf("bootctl list") !== -1) {
                      var errStr = data["stderr"] ? data["stderr"].toLowerCase() : "";
                      if (data["exit code"] === 126 || data["exit code"] === 127 || errStr.includes("polkit")) {
                          root.errorMessage = i18n("Authorization failed or canceled.")
                      } else {
                          root.errorMessage = i18n("Failed to fetch boot entries. Check permissions.")
                      }
                      root.isLoading = false
                      loadingTimer.stop()
                  }
             } else {
                  if (sourceName.indexOf("boot_entry_finder.sh") !== -1 || sourceName.indexOf("bootctl list") !== -1) {
                      root.errorMessage = ""
                  }
             }

            if (sourceName.indexOf("boot_entry_finder.sh") !== -1 && data["stdout"]) {
                console.log("BootDataManager: Received unified entry data")
                try {
                    var response = JSON.parse(data["stdout"])
                    if (response.bootloader) {
                        root.activeBootloader = response.bootloader
                        Plasmoid.configuration.cachedBootloader = response.bootloader
                    }
                    
                    var rawEntries = response.entries || []
                    console.log("BootDataManager: Parsed " + rawEntries.length + " entries for " + root.activeBootloader)
                    
                    var entries = processEntries(rawEntries)

                    root.bootEntries = entries
                    root.viewEntries = entries
                    Plasmoid.configuration.cachedBootEntries = JSON.stringify(rawEntries)
                    
                    checkForWindowsVersion()
                    root.isLoading = false
                    loadingTimer.stop() 
                    entriesLoaded(entries)
                    console.log("BootDataManager: Loading finished successfully")
                } catch(e) {
                    console.error("BootDataManager: Error parsing unified JSON: " + e)
                    root.isLoading = false
                    loadingTimer.stop()
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
                         // Preserve the raw cache and publish normalized entries for this session.
                         entriesLoaded(entries)
                     }
                 }
                 execSource.disconnectSource(sourceName)
            }
        }
    }
    
    // ...

    Component.onCompleted: {
        updatePaths()
        var cached = Plasmoid.configuration.cachedBootEntries
        var cachedLoader = Plasmoid.configuration.cachedBootloader
        if (cachedLoader) root.activeBootloader = cachedLoader
        
        console.log("BootDataManager: Component completed. Cache size: " + (cached ? cached.length : 0))
        if (cached && cached.length > 0) {
            try {
                console.log("BootDataManager: Loading from cache (" + root.activeBootloader + ")")
                var rawCached = JSON.parse(cached)
                var entries = processEntries(rawCached)
                root.bootEntries = entries
                root.viewEntries = entries
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
        console.log("BootDataManager: Requesting entries with Auth (Unified)...")
        root.errorMessage = ""
        root.isLoading = true
        loadingTimer.restart()
        
        if (root.cmdEntryFinder !== "") {
            // No arguments needed, script handles detection
            execSource.connectSource("pkexec " + root.cmdEntryFinder)
        } else {
            // Fallback
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
        } else if (root.activeBootloader === "limine") {
             // Limine supports setting default entry via limine-entry-tool
             var safeLimineId = id.replace(/'/g, "'\\''")
             cmd = "if command -v limine-entry-tool >/dev/null 2>&1; then pkexec limine-entry-tool --set-default '" + safeLimineId + "'; elif command -v limine-reboot >/dev/null 2>&1; then pkexec limine-reboot '" + safeLimineId + "'; else echo 'Limine reboot tool not found' >&2; exit 1; fi"
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
