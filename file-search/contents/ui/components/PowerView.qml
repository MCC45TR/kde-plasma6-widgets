import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

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
    
    // Data Source for executing commands
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        onNewData: (sourceName, data) => {
            if (sourceName.indexOf("bootctl list") !== -1 && data["stdout"]) {
                try {
                    var entries = JSON.parse(data["stdout"])
                    // Customize text for BIOS/Firmware
                    for (var k = 0; k < entries.length; k++) {
                        if (entries[k].id === "auto-reboot-to-firmware-setup" || 
                            entries[k].title === "Reboot Into Firmware Interface" || 
                            entries[k].title === "reboot into firmware interface") {
                            entries[k].title = "BIOS"
                            entries[k].iconName = "configure"
                        } else {
                            // Assign icons based on ID/Title
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
                } catch(e) {
                    console.error("Error parsing bootctl JSON: " + e)
                }
                execSource.disconnectSource(sourceName)
            } else if (sourceName.indexOf("CanHibernate") !== -1 && data["stdout"]) {
                var res = data["stdout"].trim()
                root.canHibernate = (res === "yes")
                execSource.disconnectSource(sourceName)
            } else if (sourceName.indexOf("checkBootctl") !== -1) {
                // If we get checkBootctl output, assuming if it returns a path it is installed
                if(data["stdout"] && data["stdout"].trim().length > 0) {
                     root.isBootctlInstalled = true
                } else {
                     root.isBootctlInstalled = false
                }
                execSource.disconnectSource(sourceName)
            }
        }
    }
    
    function loadEntries() {
        execSource.connectSource("bootctl list --json=short")
    }

    function loadEntriesWithAuth() {
        execSource.connectSource("pkexec bootctl list --json=short")
    }
    
    function checkHibernate() {
        execSource.connectSource("qdbus org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager.CanHibernate")
    }

    function checkBootctl() {
        execSource.connectSource("bash -c 'command -v bootctl'")
    }
    
    Component.onCompleted: {
        loadEntries()
        checkHibernate()
        checkBootctl()
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
                    confirmColor: Kirigami.Theme.neutralColor // Purple/Neutral
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
                    
                    // Single Click toggles boot entries if not executing logic
                    onSingleClicked: {
                        // Check if bootctl is installed AND configured to show
                        if (root.showBootOptions && root.isBootctlInstalled) {
                            if (root.bootEntries.length === 0) root.loadEntries()
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
                implicitHeight: root.bootEntriesVisible ? bootFlow.implicitHeight + 20 : 0
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
                
                Flow {
                    id: bootFlow
                    width: parent.width - 20
                    anchors.centerIn: parent
                    spacing: 8 // Unified spacing
                    padding: 6
                    
                    Repeater {
                        model: root.bootEntries
                        delegate: Rectangle {
                            width: (bootFlow.width - 24) / 4 // 4 columns approx
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
                                    Layout.maximumWidth: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Text {
                                    text: modelData.version || " "
                                    visible: text !== " "
                                    font.pixelSize: 11
                                    color: Qt.alpha(root.textColor, 0.7)
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                    
                    // Auth Button if no entries
                    Rectangle {
                        visible: root.bootEntries.length === 0
                        width: 200
                        height: 40
                        color: "transparent"
                        border.color: Qt.alpha(root.textColor, 0.3)
                        radius: 4
                        Text {
                            anchors.centerIn: parent
                            text: i18n("Authorize to list entries")
                            color: root.textColor
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.loadEntriesWithAuth()
                            cursorShape: Qt.PointingHandCursor
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
                    confirmColor: Kirigami.Theme.negativeTextColor // Use distinct color if wanted, or highlight
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
                    iconName: "system-save-session" // or document-save
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
            spacing: 4 // Tighter spacing
            width: parent.width - 10
            
            // Icon
            Kirigami.Icon {
                id: iconItem
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: btn.height * 0.4 // Slightly smaller
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
            
            // Confirmation Text (Small, in parentheses)
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
