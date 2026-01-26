import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

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
    // Loading state
    property bool isLoading: false
    
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
                         console.log("[PowerView] Saving to config cache...")
                         Plasmoid.configuration.cachedBootEntries = fullData
                    }
                    execSource.disconnectSource(sourceName)
                    delete root.cmdDataBuffer[sourceName]
                } catch(e) {
                    // Incomplete JSON, wait for more? 
                }
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
        var cached = Plasmoid.configuration.cachedBootEntries
        if (cached && cached.length > 0) {
            try {
                console.log("[PowerView] Loading from config cache")
                var rawCached = JSON.parse(cached)
                root.processEntries(rawCached)
                return
            } catch(e) {
                console.error("[PowerView] Cache corrupt")
            }
        }
        // If no cache, we stop loading. User must click "Scan" to trigger auth load.
        root.isLoading = false
    }

    function loadEntriesWithAuth() {
        root.isLoading = true
        root.requestPreventClosing(true)
        authSafetyTimer.start()
        // Reset buffer
        root.cmdDataBuffer = {} 
        execSource.connectSource("pkexec bootctl list --json=short")
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
            var t = (entries[k].title || "").toLowerCase()
            var i = (entries[k].id || "").toLowerCase()
            
            if (entries[k].id === "auto-reboot-to-firmware-setup" || 
                entries[k].title === "Reboot Into Firmware Interface" || 
                t === "reboot into firmware interface") {
                entries[k].title = "BIOS"
                entries[k].iconName = "application-x-firmware"
            } else {
                if (t.includes("limine") || i.includes("limine")) entries[k].iconName = "org.xfce.terminal-settings"
                else if (t.includes("arch") || i.includes("arch")) entries[k].iconName = "distributor-logo-archlinux"
                else if (t.includes("manjaro")) entries[k].iconName = "distributor-logo-manjaro"
                else if (t.includes("endeavour")) entries[k].iconName = "distributor-logo-endeavouros"
                else if (t.includes("garuda")) entries[k].iconName = "distributor-logo-garuda"
                else if (t.includes("cachyos")) entries[k].iconName = "distributor-logo-cachyos"
                else if (t.includes("gentoo")) entries[k].iconName = "distributor-logo-gentoo"
                else if (t.includes("windows") || i.includes("windows")) entries[k].iconName = "distributor-logo-windows"
                else if (t.includes("kubuntu")) entries[k].iconName = "distributor-logo-kubuntu"
                else if (t.includes("xubuntu")) entries[k].iconName = "distributor-logo-xubuntu"
                else if (t.includes("lubuntu")) entries[k].iconName = "distributor-logo-lubuntu"
                else if (t.includes("neon")) entries[k].iconName = "distributor-logo-neon"
                else if (t.includes("ubuntu")) entries[k].iconName = "distributor-logo-ubuntu"
                else if (t.includes("fedora")) entries[k].iconName = "distributor-logo-fedora"
                else if (t.includes("opensuse") || t.includes("suse")) entries[k].iconName = "distributor-logo-opensuse"
                else if (t.includes("debian")) entries[k].iconName = "distributor-logo-debian"
                else if (t.includes("kali")) entries[k].iconName = "distributor-logo-kali"
                else if (t.includes("mint")) entries[k].iconName = "distributor-logo-linuxmint"
                else if (t.includes("elementary")) entries[k].iconName = "distributor-logo-elementary"
                else if (t.includes("pop") && t.includes("os")) entries[k].iconName = "distributor-logo-pop-os"
                else if (t.includes("centos")) entries[k].iconName = "distributor-logo-centos"
                else if (t.includes("alma")) entries[k].iconName = "distributor-logo-almalinux"
                else if (t.includes("rocky")) entries[k].iconName = "distributor-logo-rocky"
                else if (t.includes("rhel") || t.includes("redhat")) entries[k].iconName = "distributor-logo-redhat"
                else if (t.includes("nixos")) entries[k].iconName = "distributor-logo-nixos"
                else if (t.includes("void")) entries[k].iconName = "distributor-logo-void"
                else if (t.includes("mageia")) entries[k].iconName = "distributor-logo-mageia"
                else if (t.includes("zorin")) entries[k].iconName = "distributor-logo-zorin"
                else if (t.includes("freebsd")) entries[k].iconName = "distributor-logo-freebsd"
                else if (t.includes("android")) entries[k].iconName = "distributor-logo-android"
                else if (t.includes("qubes")) entries[k].iconName = "distributor-logo-qubes"
                else if (t.includes("slackware")) entries[k].iconName = "distributor-logo-slackware"
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
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Hibernate")
                    iconName: "system-suspend-hibernate"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.neutralTextColor // Purple/Neutral
                    confirmMessage: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Press again to hibernate)")
                    onTriggered: root.executeCommand("systemctl hibernate")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Suspend (Uyut)
                PowerButton {
                    visible: root.showSleep
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Sleep")
                    iconName: "system-suspend"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.highlightColor // Blue/Highlight
                    confirmMessage: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Press again to sleep)")
                    onTriggered: root.executeCommand("systemctl suspend")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Reboot (Yeniden Başlat) - Special Logic
                PowerButton {
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Reboot")
                    iconName: "system-reboot"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.positiveTextColor // Green
                    confirmMessage: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Press again to reboot)")
                    
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
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Shutdown")
                    iconName: "system-shutdown"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.negativeTextColor // Red
                    confirmMessage: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Press again to shutdown)")
                    onTriggered: root.executeCommand("systemctl poweroff")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
            }
            
            // --- BOOT ENTRIES SECTION ---
            Item {
                Layout.fillWidth: true
                visible: true // implicitHeight controls visibility
                // Animation for height
                // Show if toggled ON via reboot button, OR if we have no entries (to show scan button)
                property bool shouldShow: root.bootEntriesVisible || root.bootEntries.length === 0
                implicitHeight: shouldShow ? (Math.max(bootFlow.implicitHeight, 40) + 20) : 0
                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                clip: true

                // Opacity animation as well for smoother look
                opacity: shouldShow ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.05)
                    radius: 8
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
                    
                    // Refresh Tile (Appended to the end)
                    Rectangle {
                        visible: root.bootEntriesVisible && !root.isLoading && root.bootEntries.length > 0
                        width: bootFlow.tileWidth
                        height: 80
                        color: refreshTileMouse.containsMouse ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.15) : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
                        radius: 6
                        
                        MouseArea {
                            id: refreshTileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.bootEntries = []
                                root.loadEntriesWithAuth()
                            }
                        }
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            
                            Kirigami.Icon {
                                source: "view-refresh"
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignHCenter
                                color: root.textColor
                            }
                            
                            Text {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Refresh")
                                font.pixelSize: 12
                                font.bold: true
                                color: root.textColor
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Scan Button - Visible if NO entries, OR if we have entries but user wants to refresh/scan
                    Rectangle {
                        visible: (root.bootEntries.length === 0) && !root.isLoading
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
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Scan for boot entries")
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
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Lock Screen")
                    iconName: "system-lock-screen"
                    doubleClickRequired: false
                    onTriggered: root.executeCommand("loginctl lock-session")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Logout (Oturumu Kapat)
                PowerButton {
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Log Out")
                    iconName: "system-log-out"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.negativeTextColor
                    confirmMessage: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Press again to log out)")
                    onTriggered: root.executeCommand("qdbus org.kde.ksmserver /KSMServer logout 0 0 0")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Switch User (Kullanıcı Değiştir)
                PowerButton {
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Switch User")
                    iconName: "system-switch-user"
                    doubleClickRequired: true
                    confirmColor: Kirigami.Theme.highlightColor
                    confirmMessage: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Press again to switch)")
                    onTriggered: root.executeCommand("dm-tool switch-to-greeter")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                }
                
                // Save Session (Oturumu Kaydet)
                PowerButton {
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Save Session")
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
        property string confirmMessage: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Press again)")
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
