
/*
 * Advanced Reboot Widget
 * v2.0 - Modular Architecture
 * Author: MCC45TR
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    Layout.preferredWidth: 250
    Layout.preferredHeight: 250
    Layout.minimumWidth: 100
    Layout.minimumHeight: 100
    BootDataManager {
        id: bootManager
    }
    property string pendingEntryId: ""
    property string pendingEntryTitle: ""
    property real animStartX: 0
    property real animStartY: 0
    property real animStartW: 0
    property real animStartH: 0
    readonly property bool showWideMode: width >= 380
    readonly property bool showLargeMode: height >= 500 && width >= 380
    fullRepresentation: Item {
        anchors.fill: parent
        
        // Configuration Properties
        readonly property double backgroundOpacity: (Plasmoid.configuration.backgroundOpacity !== undefined) ? Plasmoid.configuration.backgroundOpacity : 1.0
        readonly property int edgeMargin: (Plasmoid.configuration.edgeMargin !== undefined) ? Plasmoid.configuration.edgeMargin : 10

        // Background
        Rectangle {
            anchors.fill: parent
            anchors.margins: (Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical) ? 0 : edgeMargin
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, backgroundOpacity)
            radius: 20
            border.width: 0
            border.color: "transparent"
            
            Loader {
                id: mainLoader
                anchors.fill: parent
                clip: true
                anchors.margins: 1
                source: {
                    if (root.showLargeMode) return "LargeView.qml"
                    if (root.showWideMode) return "WideView.qml"
                    if (Plasmoid.configuration.viewMode === 1) return "RegularListView.qml"
                    return "SmallView.qml" 
                }
                onLoaded: {
                    if (item) {
                        item.bootEntries = bootManager.bootEntries
                        if (item.hasOwnProperty("entryClicked")) {
                            item.entryClicked.disconnect(onEntryClicked)
                            item.entryClicked.connect(onEntryClicked)
                        }
                    }
                }
                Connections {
                    target: bootManager
                    function onEntriesLoaded(entries) {
                        if (mainLoader.item) mainLoader.item.bootEntries = entries
                    }
                }
            }
            
            // Helper function for signal
            function onEntryClicked(id, title, x, y, w, h) {
                root.pendingEntryId = id
                root.pendingEntryTitle = title
                // Calculate center of clicked item relative to loader
                root.animStartX = x + mainLoader.x + (w / 2)
                root.animStartY = y + mainLoader.y + (h / 2)
                // Start animation
                confirmAnim.restart()
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: bootManager.isLoading
                visible: running
            }
            
            // Empty State
            Item {
                anchors.fill: parent
                visible: bootManager.bootEntries.length === 0 && !bootManager.isLoading
                z: 1 
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    Kirigami.Icon { source: "dialog-error-symbolic"; Layout.preferredWidth: 48; Layout.preferredHeight: 48; Layout.alignment: Qt.AlignHCenter; color: Kirigami.Theme.disabledTextColor }
                    Text { text: i18n("No boot entries found"); color: Kirigami.Theme.disabledTextColor; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
                    Button { text: i18n("Authorize & Refresh"); icon.name: "lock"; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10; onClicked: bootManager.loadEntriesWithAuth() }
                }
            }
            
            ToolButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 4
                z: 10
                icon.name: "view-refresh"
                display: AbstractButton.IconOnly
                visible: !bootManager.isLoading
                onClicked: bootManager.loadEntriesWithAuth()
                background: Rectangle { color: parent.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent"; radius: 8 }
            }
        }
        
        // Animation Controller
        ParallelAnimation {
            id: confirmAnim
            NumberAnimation { target: confirmationOverlay; property: "opacity"; from: 0; to: 1; duration: 200 }
            NumberAnimation { target: dialogRect; property: "width"; from: 0; to: parent.width * 0.9; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { target: dialogRect; property: "height"; from: 0; to: Math.min(300, contentLayout.implicitHeight + 40); duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { target: dialogRect; property: "radius"; from: 100; to: 16; duration: 200 }
            NumberAnimation { 
                target: dialogRect
                property: "x"
                from: root.animStartX
                to: (root.width - (root.width * 0.9)) / 2
                duration: 200
                easing.type: Easing.OutQuad 
            }
            NumberAnimation { 
                target: dialogRect
                property: "y"
                from: root.animStartY
                to: (root.height - Math.min(300, contentLayout.implicitHeight + 40)) / 2
                duration: 200
                easing.type: Easing.OutQuad 
            }
        }
        
        ParallelAnimation {
            id: closeAnim
            onFinished: root.pendingEntryId = ""
            NumberAnimation { target: confirmationOverlay; property: "opacity"; from: 1; to: 0; duration: 200 }
            NumberAnimation { target: dialogRect; property: "width"; to: 0; duration: 200; easing.type: Easing.InQuad }
            NumberAnimation { target: dialogRect; property: "height"; to: 0; duration: 200; easing.type: Easing.InQuad }
            NumberAnimation { target: dialogRect; property: "radius"; to: 100; duration: 200 }
            NumberAnimation { target: dialogRect; property: "x"; to: root.animStartX; duration: 200; easing.type: Easing.InQuad }
            NumberAnimation { target: dialogRect; property: "y"; to: root.animStartY; duration: 200; easing.type: Easing.InQuad }
        }

        Rectangle {
            id: confirmationOverlay
            anchors.fill: parent
            color: "#80000000" 
            visible: root.pendingEntryId !== "" || closeAnim.running
            opacity: 0 // Controlled by animation
            z: 999 
            
            MouseArea {
                anchors.fill: parent
                onClicked: closeAnim.start() 
            }
            
            Rectangle {
                id: dialogRect
                // Initial properties set by animation, but we need defaults to avoid NaN
                width: 0
                height: 0
                x: root.animStartX
                y: root.animStartY
                radius: 100
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                clip: true // Important so content doesn't spill during anim

                ColumnLayout {
                    id: contentLayout
                    // anchor center in parent (dialogRect). Since dialogRect grows, this keeps content centered
                    anchors.centerIn: parent
                    width: parent.width - 32
                    spacing: 16
                    opacity: (dialogRect.width > 100) ? 1 : 0 // Hide content when too small
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    Kirigami.Icon {
                        source: "system-reboot"
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        Layout.alignment: Qt.AlignHCenter
                        color: Kirigami.Theme.highlightColor
                    }
                    Text {
                        text: i18n("Confirm Reboot")
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        color: Kirigami.Theme.textColor
                    }
                    Text {
                        text: root.pendingEntryTitle
                        font.pixelSize: 14
                        font.bold: true
                        color: Kirigami.Theme.highlightColor
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Layout.topMargin: 8
                        Button {
                            text: i18n("Cancel")
                            icon.name: "dialog-cancel"
                            Layout.fillWidth: true
                            onClicked: closeAnim.start()
                        }
                        Button {
                            text: i18n("Reboot")
                            icon.name: "system-reboot"
                            highlighted: true
                            Layout.fillWidth: true
                            onClicked: {
                                var id = root.pendingEntryId
                                root.pendingEntryId = "" 
                                bootManager.rebootToEntry(id)
                            }
                        }
                    }
                }
            }
        }
    }
}
