import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
Item {
    id: root
    property var bootEntries: []
    signal entryClicked(string id, string title, real x, real y, real w, real h)
    ListView {
        id: customListView
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        model: root.bootEntries
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            id: delegateRect
            width: ListView.view.width
            height: 48
            radius: 8
            color: mouseArea.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1) 
                                           : "transparent"
            property var entryData: modelData
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                     var coords = delegateRect.mapToItem(root, 0, 0)
                     root.entryClicked(entryData.id, entryData.title || entryData.id, coords.x, coords.y, delegateRect.width, delegateRect.height)
                }
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12
                Kirigami.Icon {
                    source: {
                        var t = (entryData.title || "").toLowerCase()
                        var i = (entryData.id || "").toLowerCase()
                        if (entryData.isFirmware || t.includes("bios") || i === "auto-reboot-to-firmware-setup") return "application-x-firmware"
                        if (t.includes("limine") || i.includes("limine")) return "org.xfce.terminal-settings"
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
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    color: Kirigami.Theme.textColor
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: entryData.title || entryData.id
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: entryData.version ? entryData.version : (entryData.isFirmware ? i18n("UEFI Settings") : "")
                        visible: text !== ""
                        font.pixelSize: 11
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
        ScrollBar.vertical: ScrollBar {
            active: customListView.moving || customListView.contentHeight > customListView.height
            policy: ScrollBar.AsNeeded
        }
    }
}
