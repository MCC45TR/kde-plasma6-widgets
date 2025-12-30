import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // Widget Preferences
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    
    Layout.preferredWidth: 300
    Layout.preferredHeight: 400
    Layout.minimumWidth: 200
    Layout.minimumHeight: 200

    property var bootEntries: []
    property string cmdWindowsVer: ""

    // Overlay state
    property string pendingEntryId: ""
    property string pendingEntryTitle: ""

    function updateWindowsVerCmd() {
        var scriptPath = Qt.resolvedUrl("../tools/find_windows_mount.sh").toString()
        if (scriptPath.startsWith("file://")) {
            scriptPath = scriptPath.substring(7)
        }
        root.cmdWindowsVer = "sh \"" + scriptPath + "\""
    }
    
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        onNewData: (sourceName, data) => {
            if (sourceName.indexOf("bootctl list") !== -1 && data["stdout"]) {
                try {
                    var entries = JSON.parse(data["stdout"])
                    
                    // Customize text for BIOS/Firmware
                    for (var k = 0; k < entries.length; k++) {
                        if (entries[k].id === "auto-reboot-to-firmware-setup" || entries[k].title === "Reboot Into Firmware Interface" || entries[k].title === "reboot into firmware interface") {
                            entries[k].title = "BIOS"
                        }
                    }

                    root.bootEntries = entries
                    Plasmoid.configuration.cachedBootEntries = data["stdout"]
                    checkForWindowsVersion()
                } catch(e) {
                    print("Error parsing bootctl JSON: " + e)
                }
                execSource.disconnectSource(sourceName)
            } else if (sourceName === cmdWindowsVer && data["stdout"]) {
                var ver = data["stdout"].trim()
                if (ver.length > 0) {
                    var formattedTitle = ""
                    try {
                        var parts = ver.split('.')
                        if (parts.length >= 3) {
                            var build = parseInt(parts[2])
                            if (!isNaN(build)) {
                                if (build >= 26200) formattedTitle = "Windows 11 25H2 (Insider)"
                                else if (build >= 26100) formattedTitle = "Windows 11 24H2"
                                else if (build >= 22631) formattedTitle = "Windows 11 23H2"
                                else if (build >= 22621) formattedTitle = "Windows 11 22H2"
                                else if (build >= 22000) formattedTitle = "Windows 11 21H2"
                                else if (build >= 19041) formattedTitle = "Windows 10"
                            }
                        }
                    } catch (err) { console.log(err) }

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
                        // Ensure BIOS rename persists if windows update triggers reload
                         if (id === "auto-reboot-to-firmware-setup" || t === "reboot into firmware interface" || t === "bios") {
                            entries[i].title = "BIOS";
                        }
                    }
                    if (updated) {
                        root.bootEntries = entries
                        Plasmoid.configuration.cachedBootEntries = JSON.stringify(entries)
                    }
                }
                execSource.disconnectSource(sourceName)
            }
        }
    }
    
    function checkForWindowsVersion() {
        var entries = root.bootEntries
        for (var i = 0; i < entries.length; i++) {
            var t = (entries[i].title || "").toLowerCase()
            var id = (entries[i].id || "").toLowerCase()
            if (t.includes("windows") || id.includes("windows")) {
                if (!entries[i].version || entries[i].version.indexOf("(") !== -1 || !entries[i].version.startsWith("10.")) {
                    execSource.connectSource(cmdWindowsVer)
                }
                break 
            }
        }
    }
    
    function loadEntries() {
        execSource.connectSource("bootctl list --json=short")
    }

    function loadEntriesWithAuth() {
        execSource.connectSource("pkexec bootctl list --json=short")
    }

    Component.onCompleted: {
        updateWindowsVerCmd()
        var cached = Plasmoid.configuration.cachedBootEntries
        if (cached && cached.length > 0) {
            try {
                root.bootEntries = JSON.parse(cached)
                checkForWindowsVersion()
            } catch(e) { loadEntries() }
        } else {
            loadEntries()
        }
    }
    
    function rebootToEntry(id) {
        // Use systemctl to reboot into a specific entry without needing root password (handled by logind)
        var cmd = ""
        if (id === "auto-reboot-to-firmware-setup") {
            cmd = "systemctl reboot --firmware-setup"
        } else {
            cmd = "systemctl reboot --boot-loader-entry=\"" + id + "\""
        }
        execSource.connectSource(cmd)
    }

    fullRepresentation: Item {
        anchors.fill: parent
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            color: Kirigami.Theme.backgroundColor
            radius: 12
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: root.pendingEntryId === "" ? "Yeniden Başlat..." : "Onaylayın"
                    font.pixelSize: 15
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
                
                ToolButton {
                    icon.name: "view-refresh"
                    text: "Yenile"
                    display: AbstractButton.IconOnly
                    visible: root.pendingEntryId === ""
                    ToolTip.visible: hovered
                    ToolTip.text: "Listeyi Yenile"
                    onClicked: root.loadEntriesWithAuth()
                }
            }
            
            // List
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.bootEntries.length > 0
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                
                ListView {
                    id: entrySystem
                    model: root.bootEntries
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: root.pendingEntryId === ""

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 64
                        radius: 10
                        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                        
                        Behavior on color { ColorAnimation { duration: 150 } }

                        property var entryData: modelData

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.pendingEntryId = entryData.id
                                root.pendingEntryTitle = entryData.title || entryData.id
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 14
                            
                            Kirigami.Icon {
                                source: {
                                    var t = (entryData.title || "").toLowerCase()
                                    var i = (entryData.id || "").toLowerCase()
                                    // Custom BIOS icon
                                    if (t === "bios" || i === "auto-reboot-to-firmware-setup") return "configure"
                                    
                                    if (t.includes("arch") || i.includes("arch")) return "distributor-logo-archlinux"
                                    if (t.includes("windows") || i.includes("windows")) return "distributor-logo-windows"
                                    if (t.includes("ubuntu")) return "distributor-logo-ubuntu"
                                    if (t.includes("fedora")) return "distributor-logo-fedora"
                                    return "system-run" 
                                }
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                color: mouseArea.containsMouse ? "white" : Kirigami.Theme.textColor
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Text {
                                    text: entryData.title || entryData.id
                                    font.bold: true
                                    font.pixelSize: 15
                                    color: mouseArea.containsMouse ? "white" : Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                Text {
                                    text: entryData.version || ""
                                    visible: text !== ""
                                    font.pixelSize: 12
                                    color: mouseArea.containsMouse ? "#E0E0E0" : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }

            // Fallback UI
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                visible: root.bootEntries.length === 0
                spacing: 10
                
                Kirigami.Icon {
                    source: "dialog-password"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: "Girişler listelenemedi"
                    font.pixelSize: 13
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                }

                Button {
                    text: "Yetki Ver ve Yenile"
                    icon.name: "lock"
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: root.loadEntriesWithAuth()
                }
            }
        }
        
        // Confirmation Overlay
        Rectangle {
            id: overlay
            anchors.fill: parent
            color: "#CC000000" // Matte Black background
            visible: root.pendingEntryId !== ""
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            z: 999 

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true 
                // Close on click outside
                onClicked: root.pendingEntryId = ""
            }

            Rectangle {
                id: dialogCard
                width: parent.width * 0.9
                height: cardLayout.implicitHeight + 40
                anchors.centerIn: parent
                color: Kirigami.Theme.backgroundColor
                radius: 16
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.1)

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: cardLayout
                    width: parent.width - 30
                    anchors.centerIn: parent
                    spacing: 12



                    Text {
                        text: root.pendingEntryTitle
                        font.pixelSize: 13
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.8)
                        elide: Text.ElideMiddle
                        maximumLineCount: 3
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                    }
                    
                    Button {
                        text: "Evet, Başlat"
                        icon.name: "system-reboot"
                        Layout.fillWidth: true
                        onClicked: {
                            var id = root.pendingEntryId
                            root.pendingEntryId = ""
                            root.rebootToEntry(id)
                        }
                    }

                    Button {
                        text: "İptal"
                        icon.name: "dialog-cancel"
                        Layout.fillWidth: true
                        onClicked: root.pendingEntryId = ""
                    }
                }
            }
        }
    }
}
