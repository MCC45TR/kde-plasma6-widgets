import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: root
    property var bootEntries: []
    property int activeIndex: -1
    property var bootManager
    property bool isPanel: false
    
    signal entryClicked(string id, string title, real x, real y, real w, real h)

    ListView {
        id: customListView
        anchors.fill: parent
        anchors.margins: (Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical) ? 0 : 8
        spacing: 0
        
        // --- WEATHER WIDGET ALGORITHM (Fixed Scroll Bounds) ---
        property int minHeight: Plasmoid.configuration.listItemHeight > 0 ? Plasmoid.configuration.listItemHeight : 55
        property int visibleCount: Math.max(1, Math.floor(height / minHeight))
        property real itemHeight: height / visibleCount

        // --- SCROLLBAR VISIBILITY LOGIC ---
        property bool scrollbarVisible: scrollOpacityTimer.running || moving || mouseAtEdgeArea.containsMouse
        
        onContentYChanged: {
            scrollOpacityTimer.restart()
        }

        Timer {
            id: scrollOpacityTimer
            interval: 3000
            running: false
            repeat: false
        }
        
        snapMode: ListView.SnapToItem
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 250
        clip: true
        
        model: root.bootEntries
        
        delegate: Item {
            id: delegateRoot
            width: ListView.view.width
            height: ListView.view.itemHeight
            
            readonly property var entryData: modelData
            readonly property bool isActive: root.activeIndex === index
            
            property int clickState: 0 // 0: Idle, 1: Confirm, 2: Countdown
            property int countdown: 2

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
                    if (countdown > 0) {
                        countdown--
                    } else {
                        rebootTimer.stop()
                        if (root.bootManager) {
                            root.bootManager.rebootToEntry(entryData.id)
                        }
                    }
                }
            }

            Timer {
                id: resetTimer
                interval: 3000
                onTriggered: {
                    clickState = 0
                    countdown = 2
                }
            }

            Rectangle {
                id: delegateRect
                anchors.fill: parent
                anchors.margins: 2 // Restore previous visual spacing
                radius: root.isPanel ? Kirigami.Units.cornerRadius : Math.max(0, 20 - customListView.anchors.margins - 1)
                
                color: {
                    if (clickState === 1) return Qt.rgba(0, 0.5, 0, 0.2)
                    if (clickState === 2) return Qt.rgba(0.5, 0, 0, 0.5)
                    return (delegateMouseArea.containsMouse || isActive) ? 
                        Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : 
                        Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                }
                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    id: delegateMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.activeIndex = index
                        if (entryData.isFolder) {
                             if (root.bootManager) root.bootManager.openSubMenu(entryData)
                        } else {
                            if (clickState === 0) {
                                clickState = 1
                                resetTimer.start()
                            } else if (clickState === 1) {
                                resetTimer.stop()
                                clickState = 2
                                countdown = 2
                                rebootTimer.start()
                            } else if (clickState === 2) {
                                // Cancel reboot
                                rebootTimer.stop()
                                clickState = 0
                                countdown = 2
                            }
                        }
                    }
                }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Item {
                            // Restore dynamic icon size: row height - 20px padding (min 20px)
                            Layout.preferredWidth: Math.max(20, delegateRect.height - 20)
                            Layout.preferredHeight: Layout.preferredWidth
                            
                            Kirigami.Icon {
                                anchors.fill: parent
                                source: {
                                    if (entryData.isFolder) return "folder-boot"
                                    if (entryData.customIcon && (typeof entryData.customIcon === 'string') && entryData.customIcon !== "") return entryData.customIcon;
                                    
                                    var title = (entryData.title || "").toLowerCase()
                                    var id = (entryData.id || "").toLowerCase()
                                    
                                    if (title.includes("arch") || id.includes("arch")) return "distributor-logo-archlinux"
                                    if (title.includes("cachyos") || id.includes("cachyos")) return "distributor-logo-cachyos"
                                    if (title.includes("manjaro")) return "distributor-logo-manjaro"
                                    if (title.includes("endeavour")) return "distributor-logo-endeavouros"
                                    if (title.includes("garuda")) return "distributor-logo-garuda"
                                    if (title.includes("gentoo")) return "distributor-logo-gentoo"
                                    if (title.includes("windows") || id.includes("windows")) return "distributor-logo-windows"
                                    if (title.includes("kubuntu")) return "distributor-logo-kubuntu"
                                    if (title.includes("xubuntu")) return "distributor-logo-xubuntu"
                                    if (title.includes("lubuntu")) return "distributor-logo-lubuntu"
                                    if (title.includes("neon")) return "distributor-logo-neon"
                                    if (title.includes("ubuntu")) return "distributor-logo-ubuntu"
                                    if (title.includes("fedora")) return "distributor-logo-fedora"
                                    if (title.includes("opensuse") || title.includes("suse")) return "distributor-logo-opensuse"
                                    if (title.includes("debian")) return "distributor-logo-debian"
                                    if (title.includes("kali")) return "distributor-logo-kali"
                                    if (title.includes("mint")) return "distributor-logo-linuxmint"
                                    if (title.includes("elementary")) return "distributor-logo-elementary"
                                    if (title.includes("pop") && title.includes("os")) return "distributor-logo-pop-os"
                                    if (title.includes("centos")) return "distributor-logo-centos"
                                    if (title.includes("alma")) return "distributor-logo-almalinux"
                                    if (title.includes("rocky")) return "distributor-logo-rocky"
                                    if (title.includes("rhel") || title.includes("redhat")) return "distributor-logo-redhat"
                                    if (title.includes("nixos")) return "distributor-logo-nixos"
                                    if (title.includes("void")) return "distributor-logo-void"
                                    if (title.includes("mageia")) return "distributor-logo-mageia"
                                    if (title.includes("zorin")) return "distributor-logo-zorin"
                                    if (title.includes("freebsd")) return "distributor-logo-freebsd"
                                    if (title.includes("android")) return "distributor-logo-android"
                                    if (title.includes("qubes")) return "distributor-logo-qubes"
                                    if (title.includes("slackware")) return "distributor-logo-slackware"
                                    if (title.includes("alpine")) return "distributor-logo-alpine"
                                    if (title.includes("deepin")) return "distributor-logo-deepin"
                                    if (title.includes("mx ") || title.includes("mxlinux")) return "distributor-logo-mx"
                                    if (title.includes("parrot")) return "distributor-logo-parrot"
                                    if (title.includes("solus")) return "distributor-logo-solus"
                                    if (title.includes("steamos")) return "distributor-logo-steamos"
                                    
                                    if (title.includes("limine") || id.includes("limine")) return "org.xfce.terminal-settings"
                                    return "system-run" 
                                }
                                isMask: false
                                smooth: true
                            }
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
                                color: clickState > 0 ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                opacity: 0.8
                            }
                        }
                    }
            }
        }
        
        ScrollBar.vertical: ScrollBar {
            id: verticalScrollBar
            policy: ScrollBar.AsNeeded
            opacity: (customListView.contentHeight > customListView.height && customListView.scrollbarVisible) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
    }

    // Right-edge detection for scrollbar (10px zone)
    MouseArea {
        id: mouseAtEdgeArea
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 10
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
    }
}
