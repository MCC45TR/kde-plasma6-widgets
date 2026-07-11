
/*
 * MSelective Reboot Widget
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
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : null
    Plasmoid.icon: "system-reboot-symbolic"
    Component.onCompleted: {
        if (!Plasmoid.configuration.panelDefaultsApplied && Plasmoid.formFactor !== PlasmaCore.Types.Planar) {
            Plasmoid.configuration.backgroundOpacity = 0.0
            Plasmoid.configuration.edgeMargin = 0
            Plasmoid.configuration.viewMode = 1
            Plasmoid.configuration.panelDefaultsApplied = true
        }
    }
    
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
        Layout.preferredWidth: 200
        Layout.preferredHeight: 200
        Layout.minimumWidth: 80
        Layout.minimumHeight: 80
        
        anchors.fill: parent
        
        // Configuration Properties
        readonly property bool isPanel: Plasmoid.formFactor !== PlasmaCore.Types.Planar
        readonly property double backgroundOpacity: isPanel ? 0.0 : ((Plasmoid.configuration.backgroundOpacity !== undefined) ? Plasmoid.configuration.backgroundOpacity : 1.0)
        readonly property int edgeMargin: isPanel ? 0 : ((Plasmoid.configuration.edgeMargin !== undefined) ? Plasmoid.configuration.edgeMargin : 10)

        // Background
        Rectangle {
            anchors.fill: parent
            anchors.margins: edgeMargin
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, backgroundOpacity)
            radius: isPanel ? Kirigami.Units.cornerRadius : 20
            border.width: 0
            border.color: "transparent"
            
            Loader {
                id: mainLoader
                anchors.fill: parent
                clip: true
                anchors.margins: 1
                source: {
                    if (bootManager.isViewingSubMenu) return "RegularListView.qml"
                    if (root.showLargeMode) return "LargeView.qml"
                    if (root.showWideMode) return "WideView.qml"
                    if (Plasmoid.configuration.viewMode === 1) return "RegularListView.qml"
                    return "SmallView.qml" 
                }
                onLoaded: {
                    if (item) {
                        item.bootEntries = bootManager.viewEntries
                        if (item.hasOwnProperty("bootManager")) {
                            item.bootManager = bootManager
                        }
                        if (item.hasOwnProperty("edgeMargin")) {
                            item.edgeMargin = edgeMargin
                        }
                        if (item.hasOwnProperty("isPanel")) {
                            item.isPanel = isPanel
                        }
                    }
                }
                Connections {
                    target: bootManager
                    function onEntriesLoaded(entries) {
                        if (mainLoader.item) mainLoader.item.bootEntries = bootManager.viewEntries
                    }
                    function onViewEntriesChanged() {
                         if (mainLoader.item) mainLoader.item.bootEntries = bootManager.viewEntries
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
                id: emptyStateContainer
                anchors.fill: parent
                visible: bootManager.bootEntries.length === 0 && !bootManager.isLoading
                z: 1 
                
                property bool isCompact: root.width < 170 || root.height < 170

                // Compact Mode
                Button {
                    visible: emptyStateContainer.isCompact
                    anchors.fill: parent
                    anchors.margins: 10
                    icon.name: "lock"
                    display: AbstractButton.IconOnly
                    onClicked: bootManager.loadEntriesWithAuth()
                }

                // Normal Mode
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !emptyStateContainer.isCompact
                    spacing: 15
                    
                    Kirigami.Icon { 
                        source: "dialog-error-symbolic"
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48 
                        Layout.alignment: Qt.AlignHCenter 
                        color: Kirigami.Theme.disabledTextColor
                    }
                    
                    Text { 
                        text: bootManager.errorMessage !== "" ? bootManager.errorMessage : i18n("No boot entries found")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.maximumWidth: parent.width - 20
                    }
                    
                    Button { 
                        text: i18n("Authorize & Refresh")
                        icon.name: "lock"
                        display: AbstractButton.TextBesideIcon
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: bootManager.loadEntriesWithAuth()
                    }
                }
            }
            
            ToolButton {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 4
                z: 11
                icon.name: "go-previous"
                display: AbstractButton.IconOnly
                visible: bootManager.isViewingSubMenu
                onClicked: bootManager.closeSubMenu()
                background: Rectangle { color: parent.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent"; radius: 8 }
                
                ToolTip.visible: hovered
                ToolTip.text: i18n("Back to Main List")
            }

            ToolButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 4
                z: 10
                icon.name: "view-refresh"
                display: AbstractButton.IconOnly
                visible: !bootManager.isLoading && !bootManager.isViewingSubMenu
                onClicked: bootManager.loadEntriesWithAuth()
                background: Rectangle { color: parent.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent"; radius: 8 }
            }
        }
    }
}
