import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
Item {
    id: root
    property var bootEntries: []
    signal entryClicked(string id, string title, real x, real y, real w, real h)
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
        cacheBuffer: itemHeight 
        model: root.bootEntries
        clip: true
        delegate: Item {
            width: ListView.view.width
            height: root.itemHeight
            Rectangle {
                id: delegateRect
                anchors.fill: parent
                // Removed margins and visual card style
                color: "transparent"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var coords = delegateRect.mapToItem(root, 0, 0)
                        root.entryClicked(modelData.id, modelData.title || modelData.id, coords.x, coords.y, delegateRect.width, delegateRect.height)
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
                            color: Kirigami.Theme.textColor
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: modelData.title || modelData.id
                            font.pixelSize: 18
                            font.weight: Font.Light
                            color: Kirigami.Theme.textColor
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                        }
                        Text {
                            text: modelData.version ? modelData.version : (modelData.isFirmware ? i18n("UEFI Settings") : "")
                            visible: text !== ""
                            font.pixelSize: 12
                            color: Kirigami.Theme.disabledTextColor
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
