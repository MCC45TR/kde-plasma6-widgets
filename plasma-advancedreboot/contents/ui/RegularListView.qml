import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
Item {
    id: root
    property var bootEntries: []
    property int activeIndex: -1
    property var bootManager
    signal entryClicked(string id, string title, real x, real y, real w, real h)
    ListView {
        id: customListView
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        
        property int minHeight: Plasmoid.configuration.listItemHeight > 0 ? Plasmoid.configuration.listItemHeight : 40
        property int visibleItemCount: Math.max(1, Math.floor((height + spacing) / (minHeight + spacing)))
        property real optimalItemHeight: (height - (visibleItemCount - 1) * spacing) / visibleItemCount
        
        // Setup paging behavior
        snapMode: ListView.SnapToItem
        highlightMoveDuration: 250 // smooth transition

        model: root.bootEntries
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        
        NumberAnimation {
            id: scrollAnim
            target: customListView
            property: "contentY"
            duration: 200
            easing.type: Easing.InOutQuad
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                if (scrollAnim.running) return;
                
                var itemsPerScroll = customListView.visibleItemCount
                var firstVisibleIndex = customListView.indexAt(0, customListView.contentY + 1)
                if (firstVisibleIndex === -1) firstVisibleIndex = 0
                
                var targetIndex = firstVisibleIndex;
                if (wheel.angleDelta.y < 0) {
                    targetIndex = Math.min(customListView.model.length - 1, firstVisibleIndex + itemsPerScroll)
                } else {
                    targetIndex = Math.max(0, firstVisibleIndex - itemsPerScroll)
                }
                
                var currentY = customListView.contentY
                customListView.positionViewAtIndex(targetIndex, ListView.Beginning)
                
                var maxContentY = Math.max(0, customListView.contentHeight - customListView.height)
                var targetY = Math.min(Math.max(0, customListView.contentY), maxContentY)
                
                customListView.contentY = currentY
                
                if (Math.abs(currentY - targetY) > 0.5) {
                    scrollAnim.to = targetY
                    scrollAnim.start()
                }
            }
        }
        delegate: Rectangle {
            id: delegateRect
            width: ListView.view.width
            height: customListView.optimalItemHeight
            radius: Math.max(0, 20 - customListView.anchors.margins - 1)
            
            property var entryData: modelData
            property bool isActive: root.activeIndex === index
            property int clickState: 0 // 0: Idle, 1: Green, 2: Red
            property int countdown: 2

            // Reset state if another item is clicked
            Connections {
                target: root
                function onActiveIndexChanged() {
                    if (!isActive) {
                        clickState = 0
                        rebootTimer.stop()
                        resetTimer.stop()
                        countdown = 2
                    }
                }
            }
            
            Timer {
                id: rebootTimer
                interval: 1000
                repeat: true
                onTriggered: {
                     countdown--
                     if (countdown < 0) {
                         rebootTimer.stop()
                         if (root.bootManager) {
                             root.bootManager.rebootToEntry(entryData.id)
                         }
                     }
                }
            }
            
            Timer {
                id: resetTimer
                interval: 2000
                repeat: false
                onTriggered: clickState = 0
            }

            color: {
                if (clickState === 1) return Qt.rgba(0, 0.5, 0, 0.2) // Green tint
                if (clickState === 2) return Qt.rgba(0.5, 0, 0, 0.5) // Red tint
                return mouseArea.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) 
                                               : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
            }
            Behavior on color { ColorAnimation { duration: 200 } }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.activeIndex = index
                    if (clickState === 0) {
                        clickState = 1
                        resetTimer.start()
                    } else if (clickState === 1) {
                        resetTimer.stop()
                        clickState = 2
                        countdown = 2
                        rebootTimer.start()
                    } else if (clickState === 2) {
                        // Cancel
                        rebootTimer.stop()
                        clickState = 0
                        countdown = 2
                    }
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
                        if (t.includes("alpine")) return "distributor-logo-alpine"
                        if (t.includes("deepin")) return "distributor-logo-deepin"
                        if (t.includes("mx ") || t.includes("mxlinux")) return "distributor-logo-mx"
                        if (t.includes("parrot")) return "distributor-logo-parrot"
                        if (t.includes("solus")) return "distributor-logo-solus"
                        if (t.includes("steamos")) return "distributor-logo-steamos"
                        return "system-run" 
                    }
                    Layout.preferredWidth: Math.max(16, delegateRect.height - 20)
                    Layout.preferredHeight: Math.max(16, delegateRect.height - 20)
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
                        text: {
                            if (clickState === 2) return i18n("Rebooting in %1s...", countdown+1)
                            if (clickState === 1) return i18n("Click again to confirm")
                            return entryData.version ? entryData.version : (entryData.isFirmware ? i18n("UEFI Settings") : "")
                        }
                        visible: text !== ""
                        font.pixelSize: 11
                        color: clickState > 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
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
