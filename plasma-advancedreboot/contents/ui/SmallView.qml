import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
Item {
    id: root
    property var bootManager
    property var bootEntries: [] // Required for model
    property int activeIndex: -1
    
    readonly property int itemHeight: height 
    property real scrollBarHeight: (bootEntries.length > 0) ? (height / bootEntries.length) : 0
    property real scrollBarY: (bootEntries.length > 0) ? (listView.contentY / listView.contentHeight) * height : 0

    ListView {
        id: listView
        anchors.fill: parent
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: 0
        preferredHighlightEnd: 0
        cacheBuffer: Math.max(0, itemHeight) 
        model: root.bootEntries
        clip: true
        delegate: Item {
            width: ListView.view.width
            height: root.itemHeight
            
            readonly property bool isActive: index === root.activeIndex
            property int clickState: 0 // 0: Idle, 1: Green, 2: Red
            
            // Reset state if another item is clicked
            Connections {
                target: root
                function onActiveIndexChanged() {
                    if (!isActive) {
                        clickState = 0
                        rebootTimer.stop()
                    }
                }
            }
            
            Timer {
                id: rebootTimer
                interval: 2000
                repeat: false
                onTriggered: {
                     if (root.bootManager) {
                         root.bootManager.rebootToEntry(modelData.id)
                     }
                }
            }

            Rectangle {
                id: delegateRect
                anchors.fill: parent
                // Background color logic
                color: {
                    if (clickState === 1) return Qt.rgba(0, 0.5, 0, 0.5) // Green tint
                    if (clickState === 2) return Qt.rgba(0.5, 0, 0, 0.5) // Red tint
                    return "transparent"
                }
                radius: 10
                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.activeIndex = index
                        if (clickState === 0) {
                            clickState = 1
                        } else if (clickState === 1) {
                            clickState = 2
                            rebootTimer.start()
                        } else {
                            // Already in red state (waiting), maybe cancel? 
                            // User request didn't specify cancellation, but clicking again usually confirms or does nothing.
                            // Let's leave it running or maybe restart timer?
                            // For safety, let's just let the timer run.
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: root.itemHeight * 0.04
                    width: parent.width - 32

                    // Large Centered Icon (No background)
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 96
                        
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 96
                            height: 96
                            source: {
                                var t = (modelData.title || "").toLowerCase()
                                var i = (modelData.id || "").toLowerCase()
                                if (modelData.isFirmware || t.includes("bios") || i === "auto-reboot-to-firmware-setup") return "application-x-firmware"
                                if (t.includes("limine") || i.includes("limine")) return "org.xfce.terminal-settings"
                                
                                // Distro Detection
                                if (t.includes("arch") || i.includes("arch")) return "distributor-logo-archlinux"
                                if (t.includes("manjaro")) return "distributor-logo-manjaro"
                                if (t.includes("endeavour")) return "distributor-logo-endeavouros"
                                if (t.includes("garuda")) return "distributor-logo-garuda"
                                if (t.includes("cachyos")) return "distributor-logo-cachyos"
                                if (t.includes("gentoo")) return "distributor-logo-gentoo"
                                if (t.includes("windows") || i.includes("windows")) return "distributor-logo-windows"
                                if (t.includes("kubuntu")) return "distributor-logo-kubuntu"
                                if (t.includes("xubuntu")) return "distributor-logo-xubuntu"
                                if (t.includes("lubuntu")) return "distributor-logo-lubuntu"
                                if (t.includes("neon")) return "distributor-logo-neon"
                                if (t.includes("ubuntu")) return "distributor-logo-ubuntu"
                                if (t.includes("fedora")) return "distributor-logo-fedora"
                                if (t.includes("opensuse") || t.includes("suse")) return "distributor-logo-opensuse"
                                if (t.includes("debian")) return "distributor-logo-debian"
                                if (t.includes("kali")) return "distributor-logo-kali"
                                if (t.includes("mint")) return "distributor-logo-linuxmint"
                                if (t.includes("elementary")) return "distributor-logo-elementary"
                                if (t.includes("pop") && t.includes("os")) return "distributor-logo-pop-os"
                                if (t.includes("centos")) return "distributor-logo-centos"
                                if (t.includes("alma")) return "distributor-logo-almalinux"
                                if (t.includes("rocky")) return "distributor-logo-rocky"
                                if (t.includes("rhel") || t.includes("redhat")) return "distributor-logo-redhat"
                                if (t.includes("nixos")) return "distributor-logo-nixos"
                                if (t.includes("void")) return "distributor-logo-void"
                                if (t.includes("mageia")) return "distributor-logo-mageia"
                                if (t.includes("zorin")) return "distributor-logo-zorin"
                                if (t.includes("freebsd")) return "distributor-logo-freebsd"
                                if (t.includes("android")) return "distributor-logo-android"
                                if (t.includes("qubes")) return "distributor-logo-qubes"
                                if (t.includes("slackware")) return "distributor-logo-slackware"
                                
                                return "system-run" 
                            }
                            color: "white" // Icon should be white on colored background
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: { 
                                if (clickState === 2) return i18n("Rebooting in 2s...")
                                if (clickState === 1) return i18n("Press again to reboot")
                                return modelData.title || modelData.id
                            }
                            font.pixelSize: 18
                            font.weight: Font.Light
                            color: "white" // Text should be white on colored background
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                        }
                        Text {
                            text: modelData.version ? modelData.version : (modelData.isFirmware ? i18n("UEFI Settings") : "")
                            visible: text !== "" && clickState === 0
                            font.pixelSize: 12
                            color: Qt.rgba(1,1,1,0.7)
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
    Item {
        id: scrollBarContainer
        width: 6
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: root.bootEntries.length > 1
        Rectangle {
            id: scrollThumb
            width: 6
            height: root.scrollBarHeight 
            y: root.scrollBarY 
            radius: 3
            color: Kirigami.Theme.highlightColor
            Behavior on y { NumberAnimation { duration: 100 } }
        }
    }
}
