
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
    Layout.preferredWidth: 200
    Layout.preferredHeight: 200
    Layout.minimumWidth: 80
    Layout.minimumHeight: 80
    
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Update Boot Entries")
            icon.name: "view-refresh"
            onTriggered: bootManager.loadEntriesWithAuth()
        }
    ]
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
                        if (item.hasOwnProperty("bootManager")) {
                            item.bootManager = bootManager
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
                    property bool isCompact: root.width < 170 || root.height < 170
                    spacing: isCompact ? 0 : 15
                    
                    Kirigami.Icon { 
                        source: "dialog-error-symbolic"
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48 
                        Layout.alignment: Qt.AlignHCenter 
                        color: Kirigami.Theme.disabledTextColor
                        visible: !parent.isCompact 
                    }
                    
                    Text { 
                        text: i18n("No boot entries found")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                        visible: !parent.isCompact
                    }
                    
                    Button { 
                        text: i18n("Authorize & Refresh")
                        icon.name: "lock"
                        display: parent.isCompact ? AbstractButton.IconOnly : AbstractButton.TextBesideIcon
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: parent.isCompact ? 64 : implicitWidth
                        Layout.preferredHeight: parent.isCompact ? 64 : implicitHeight
                        Layout.topMargin: parent.isCompact ? 0 : 10
                        onClicked: bootManager.loadEntriesWithAuth()
                    }
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
    }
}
