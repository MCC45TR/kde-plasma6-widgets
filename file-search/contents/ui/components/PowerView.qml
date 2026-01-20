import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import Qt.labs.platform as Platform

Item {
    id: root
    
    required property color textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property color bgColor: Kirigami.Theme.backgroundColor
    
    property var bootEntries: []
    property bool bootEntriesVisible: false
    property bool canHibernate: false
    property bool isBootctlInstalled: false
    property bool showBootOptions: false
    property bool showHibernate: false
    property bool showSleep: true
    property bool isLoading: false
    
    // Cache File Path - Robust handling
    // Removes file:// prefix if present
    property string cacheFile: {
        var path = Platform.StandardPaths.writableLocation(Platform.StandardPaths.CacheLocation)
        return String(path).replace("file://", "") + "/plasma_com_mcc45tr_filesearch_bootentries.json"
    }
    
    // Buffer for accumulating data
    property var cmdDataBuffer: ({})

    // Data Source for executing commands
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        onNewData: (sourceName, data) => {
            if (data["stdout"]) {
                if (!root.cmdDataBuffer[sourceName]) root.cmdDataBuffer[sourceName] = ""
                root.cmdDataBuffer[sourceName] += data["stdout"]
            }
            
            // We try to process immediately, assuming small JSON comes fast or in one chunk.
            var fullData = root.cmdDataBuffer[sourceName]
            
            if (sourceName.indexOf("bootctl list") !== -1) {
                // Auth successful
                root.requestPreventClosing(false)
                authSafetyTimer.stop()
                try {
                    console.log("[PowerView] Captured Boot Entries (Sudo): " + fullData)
                    var entries = JSON.parse(fullData)
                    root.processEntries(entries)
                    root.isLoading = false
                    
                    if (sourceName.indexOf("pkexec") !== -1) {
                         console.log("[PowerView] Saving to cache...")
                         root.saveCache(entries)
                    }
                    execSource.disconnectSource(sourceName)
                    delete root.cmdDataBuffer[sourceName]
                } catch(e) {
                    // Incomplete JSON, wait for more? 
                }
            } else if (sourceName.indexOf("cat_cache") !== -1) {
                try {
                    if (fullData.indexOf("CACHE_MISS") !== -1) {
                         console.log("[PowerView] Cache MISS")
                         root.isLoading = false
                         execSource.disconnectSource(sourceName)
                         delete root.cmdDataBuffer[sourceName]
                    } else if (fullData.trim().length > 0) {
                        console.log("[PowerView] Loaded from Cache: " + fullData)
                        var entries = JSON.parse(fullData)
                        root.processEntries(entries)
                        root.isLoading = false
                        execSource.disconnectSource(sourceName)
                        delete root.cmdDataBuffer[sourceName]
                    }
                } catch(e) {
                     console.error("[PowerView] JSON Parse Error (Cache): " + e)
                }
            } else if (fullData.indexOf("CACHE_SAVED") !== -1) {
                console.log("[PowerView] Database functionality: Cache successfully saved.")
                execSource.disconnectSource(sourceName)
                delete root.cmdDataBuffer[sourceName]
            } else if (fullData.indexOf("CACHE_SAVE_FAILED") !== -1) {
                console.error("[PowerView] Database functionality: Cache SAVE FAILED.")
                execSource.disconnectSource(sourceName)
                delete root.cmdDataBuffer[sourceName]
            } else if (sourceName.indexOf("CanHibernate") !== -1 && data["stdout"]) {
                var res = data["stdout"].trim()
                root.canHibernate = (res === "yes")
                execSource.disconnectSource(sourceName)
            } else if (sourceName.indexOf("checkBootctl") !== -1) {
                if(data["stdout"] && data["stdout"].trim().length > 0) {
                     root.isBootctlInstalled = true
                }
                execSource.disconnectSource(sourceName)
            }
        }
    }
    
    // Signal to main window to prevent closing during auth
    signal requestPreventClosing(bool prevent)
    
    // Safety timer to ensure we don't lock the popup open forever if something goes wrong
    Timer {
         id: authSafetyTimer
         interval: 10000 // Reduced to 10s for loading timeout
         repeat: false
         onTriggered: {
             if (root.isLoading) {
                 console.warn("Loading timed out")
                 root.isLoading = false
             }
             root.requestPreventClosing(false)
         }
    }
    
    function loadEntries() {
        root.isLoading = true
        // Start safety timer for cache load too, just in case
        authSafetyTimer.start()
        loadCache()
    }

    function loadEntriesWithAuth() {
        root.isLoading = true
        root.requestPreventClosing(true)
        authSafetyTimer.start()
        // Reset buffer
        root.cmdDataBuffer = {} 
        execSource.connectSource("pkexec bootctl list --json=short")
    }
    
    function loadCache() {
        root.cmdDataBuffer = {}
        // Use bash to check file existence. If exists, cat it. If not, echo CACHE_MISS.
        var cmd = "bash -c 'if [ -f \"" + root.cacheFile + "\" ]; then cat \"" + root.cacheFile + "\"; else echo \"CACHE_MISS\"; fi' # cat_cache"
        execSource.connectSource(cmd)
    }
    
    function saveCache(data) {
        var jsonStr = JSON.stringify(data)
        // Escape single quotes: ' -> '\''
        var escapedJson = jsonStr.replace(/'/g, "'\\''")
        var path = root.cacheFile
        
        // Command: Create dir, write file, check success
        var cmd = "bash -c \"mkdir -p \\\"$(dirname \\\"" + path + "\\\")\\\" && echo '" + escapedJson + "' > \\\"" + path + "\\\" && echo CACHE_SAVED || echo CACHE_SAVE_FAILED\""
        
        console.log("[PowerView] Executing Save Command for: " + path)
        execSource.connectSource(cmd)
    }
    
    // Auto-load if visible and empty (fail-safe)
    onVisibleChanged: {
        if (visible && root.bootEntries.length === 0) {
            loadEntries()
        }
    }

    function processEntries(entries) {
        // Customize text for BIOS/Firmware and assign icons
        for (var k = 0; k < entries.length; k++) {
            if (entries[k].id === "auto-reboot-to-firmware-setup" || 
                entries[k].title === "Reboot Into Firmware Interface" || 
                entries[k].title === "reboot into firmware interface") {
                entries[k].title = "BIOS"
                entries[k].iconName = "configure"
            } else {
                var t = (entries[k].title || "").toLowerCase()
                var i = (entries[k].id || "").toLowerCase()
                if (t.includes("arch") || i.includes("arch")) entries[k].iconName = "distributor-logo-archlinux"
                else if (t.includes("windows") || i.includes("windows")) entries[k].iconName = "distributor-logo-windows"
                else if (t.includes("ubuntu")) entries[k].iconName = "distributor-logo-ubuntu"
                else if (t.includes("fedora")) entries[k].iconName = "distributor-logo-fedora"
                else entries[k].iconName = "system-run"
            }
        }
        root.bootEntries = entries
    }
    
    function checkHibernate() {
        execSource.connectSource("qdbus org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager.CanHibernate")
    }

    function checkBootctl() {
        execSource.connectSource("bash -c 'command -v bootctl'")
    }
    
    Component.onCompleted: {
        // loadEntries() // Called by onVisibleChanged or manually if needed, but let's call it here too?
        // Actually, if we rely on onVisibleChanged, it might be better, but main.qml loads this always?
        loadEntries()
        checkHibernate()
        checkBootctl()
    }
    
    Component.onDestruction: {
        root.requestPreventClosing(false)
    }
    
    function executeCommand(cmd) {
        execSource.connectSource(cmd)
    }

    function rebootToEntry(id) {
        var cmd = ""
        if (id === "auto-reboot-to-firmware-setup") {
            cmd = "systemctl reboot --firmware-setup"
        } else {
            cmd = "systemctl reboot --boot-loader-entry=\"" + id + "\""
        }
        executeCommand(cmd)
    }

    // ScrollView to allow scrolling if content overflows
    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainLayout.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainLayout
            width: parent.width
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 0
            spacing: 8 // Unified spacing
            
            // --- TOP ROW: POWER ACTIONS (Double Click Required) ---
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 8
                rowSpacing: 8
                
                // Hibernate (Derin Uyut) - Only if supported
                PowerButton {
                    visible: root.canHibernate && root.showHibernate
                    text: i18n("Hibernate")
                    iconName: "system-suspend-hibernate"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.neutralTextColor // Purple/Neutral
                    confirmMessage: i18n("(Press again to hibernate)")
                    onTriggered: root.executeCommand("systemctl hibernate")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Suspend (Uyut)
                PowerButton {
                    visible: root.showSleep
                    text: i18n("Sleep")
                    iconName: "system-suspend"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.highlightColor // Blue/Highlight
                    confirmMessage: i18n("(Press again to sleep)")
                    onTriggered: root.executeCommand("systemctl suspend")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Reboot (Yeniden Başlat) - Special Logic
                PowerButton {
                    text: i18n("Reboot")
                    iconName: "system-reboot"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.positiveTextColor // Green
                    confirmMessage: i18n("(Press again to reboot)")
                    
                    // Single Click toggles boot entries if enabled in settings
                    onSingleClicked: {
                        // Trust the user setting provided in config
                        if (root.showBootOptions) {
                            if (root.bootEntries.length === 0) {
                                root.loadEntries()
                            }
                            root.bootEntriesVisible = !root.bootEntriesVisible
                        }
                    }
                    
                    onTriggered: root.executeCommand("systemctl reboot")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Shutdown (Kapat)
                PowerButton {
                    text: i18n("Shutdown")
                    iconName: "system-shutdown"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.negativeTextColor // Red
                    confirmMessage: i18n("(Press again to shutdown)")
                    onTriggered: root.executeCommand("systemctl poweroff")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
            }
            
            // --- BOOT ENTRIES SECTION ---
            Item {
                Layout.fillWidth: true
                visible: implicitHeight > 0
                // Animation for height
                implicitHeight: root.bootEntriesVisible ? (Math.max(bootFlow.implicitHeight, 40) + 20) : 0
                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                clip: true

                // Opacity animation as well for smoother look
                opacity: root.bootEntriesVisible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.05)
                    radius: 8
                }
                
                // Refresh Button (Top Right)
                Kirigami.Icon {
                    source: "view-refresh"
                    width: 16
                    height: 16
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    // Visible if entries exist OR if we have processed entries (even if empty, but usually we want refresh if user suspects new ones)
                    // Let's make it visible if boot options are visible
                    visible: root.bootEntriesVisible && !root.isLoading && root.bootEntries.length > 0
                    color: refreshMouse.containsMouse ? root.accentColor : Qt.alpha(root.textColor, 0.5)
                    
                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            // Force refresh
                            root.bootEntries = []
                            root.loadEntriesWithAuth()
                        }
                    }
                    
                    ToolTip.visible: refreshMouse.containsMouse
                    ToolTip.text: i18n("Refresh boot entries")
                }
                
                // Loading Indicator
                BusyIndicator {
                    running: root.isLoading
                    visible: root.isLoading && root.bootEntriesVisible
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    z: 10
                }

                Flow {
                    id: bootFlow
                    width: parent.width - 20
                    anchors.centerIn: parent
                    spacing: 8 // Unified spacing
                    padding: 6
                    opacity: root.isLoading ? 0.3 : 1.0 // Dim content when loading
                    
                    // Dynamic Width Calculation
                    property int minTileWidth: 140
                    property int columns: Math.max(1, Math.floor((width - 2 * padding) / minTileWidth))
                    property real tileWidth: ((width - 2 * padding) - (columns - 1) * spacing) / columns
                    
                    Repeater {
                        model: root.bootEntries
                        delegate: Rectangle {
                            width: bootFlow.tileWidth
                            height: 80
                            color: entryMouse.containsMouse ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.15) : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
                            radius: 6
                            
                            MouseArea {
                                id: entryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.rebootToEntry(modelData.id)
                            }
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                width: parent.width - 10
                                
                                Kirigami.Icon {
                                    source: modelData.iconName
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: modelData.title || modelData.id
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.textColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: modelData.version || " "
                                    visible: text !== " "
                                    font.pixelSize: 11
                                    color: Qt.alpha(root.textColor, 0.7)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                    
                    // Scan Button - Only visible if NO entries and NOT loading
                    Rectangle {
                        visible: root.bootEntries.length === 0 && !root.isLoading
                        width: bootFlow.width - 12
                        height: 40
                        color: scanMouse.containsMouse ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1) : "transparent"
                        border.color: Qt.alpha(root.textColor, 0.3)
                        radius: 4
                        
                        RowLayout {
                             anchors.centerIn: parent
                             spacing: 8
                             Kirigami.Icon {
                                 source: "system-search"
                                 Layout.preferredWidth: 16
                                 Layout.preferredHeight: 16
                                 color: root.textColor
                             }
                             Text {
                                text: i18n("Scan for boot entries")
                                color: root.textColor
                                font.bold: true
                             }
                        }

                        MouseArea {
                            id: scanMouse
                            anchors.fill: parent
                            onClicked: root.loadEntriesWithAuth()
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                        }
                    }
                }
            }
            
            // --- BOTTOM ROW: SESSION ACTIONS (Single Click) ---
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 8
                rowSpacing: 8
                
                // Lock (Ekranı Kilitle)
                PowerButton {
                    text: i18n("Lock Screen")
                    iconName: "system-lock-screen"
                    doubleClickRequired: false
                    onTriggered: root.executeCommand("loginctl lock-session")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Logout (Oturumu Kapat)
                PowerButton {
                    text: i18n("Log Out")
                    iconName: "system-log-out"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.negativeTextColor
                    confirmMessage: i18n("(Press again to log out)")
                    onTriggered: root.executeCommand("qdbus org.kde.ksmserver /KSMServer logout 0 0 0")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Switch User (Kullanıcı Değiştir)
                PowerButton {
                    text: i18n("Switch User")
                    iconName: "system-switch-user"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.highlightColor
                    confirmMessage: i18n("(Press again to switch)")
                    onTriggered: root.executeCommand("dm-tool switch-to-greeter")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Save Session (Oturumu Kaydet)
                PowerButton {
                    text: i18n("Save Session")
                    iconName: "system-save-session"
                    doubleClickRequired: false
                    onTriggered: root.executeCommand("qdbus org.kde.ksmserver /KSMServer saveCurrentSession")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
            }
        }
    }
    
    // --- INNER COMPONENT: POWER BUTTON ---
    component PowerButton : Rectangle {
        id: btn
        
        property string text
        property string iconName
        property bool doubleClickRequired: false
        property color confirmColor: Kirigami.Theme.highlightColor
        property string confirmMessage: i18n("(Press again)")
        property bool pendingConfirmation: false
        
        signal triggered()
        signal singleClicked()
        
        radius: 12
        
        // Timer to reset confirmation state after 5 seconds
        Timer {
            id: resetTimer
            interval: 5000
            running: btn.pendingConfirmation
            repeat: false
            onTriggered: btn.pendingConfirmation = false
        }
        
        // Color Logic with Animation
        property color targetColor: {
            if (btn.pendingConfirmation) {
                return Qt.rgba(btn.confirmColor.r, btn.confirmColor.g, btn.confirmColor.b, 0.5)
            }
            if (btnMouse.containsMouse) {
                return Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
            }
            return Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.05)
        }
        
        color: targetColor
        Behavior on color { ColorAnimation { duration: 200 } }
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4 
            width: parent.width - 10
            
            Kirigami.Icon {
                id: iconItem
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: btn.height * 0.4
                Layout.preferredWidth: btn.height * 0.4
                source: btn.iconName
            }
            
            Text {
                text: btn.text
                font.pixelSize: 14
                font.bold: true
                color: root.textColor
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
            
            Text {
                visible: btn.pendingConfirmation
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                text: btn.confirmMessage
                font.pixelSize: 10
                color: Qt.alpha(root.textColor, 0.8)
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
        
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                if (btn.doubleClickRequired) {
                    if (btn.pendingConfirmation) {
                        btn.triggered()
                        btn.pendingConfirmation = false
                    } else {
                        btn.pendingConfirmation = true
                        btn.singleClicked()
                        resetTimer.restart()
                    }
                } else {
                    btn.triggered()
                }
            }
        }
    }
}
