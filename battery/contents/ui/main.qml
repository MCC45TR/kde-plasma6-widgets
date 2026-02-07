import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import Qt5Compat.GraphicalEffects

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    
    Layout.minimumWidth: 150
    Layout.minimumHeight: 150
    Layout.preferredWidth: 200
    Layout.preferredHeight: 200

    readonly property string currentViewMode: {
        // Width thresholds: 160 (tiny), 200 (normal)
        // Height thresholds: 160 (tiny), 200 (normal), 450 (tall)
        if (width < 160 && height < 160) return "extrasmall"   // Both tiny
        if (width < 200 && height < 200) return "small"        // Both small (includes 160-199)
        if (width >= 200 && height < 250) return "wide"        // Wide but short
        if (width < 200 && height >= 200) return "tall"        // Narrow but tall
        if (width >= 200 && height >= 350) return "big"        // Wide and very tall
        return "big"                                           // Wide, medium height (200-449)
    }
    
    onCurrentViewModeChanged: console.log("View Mode:", currentViewMode, "(" + width + "x" + height + ")")
    
    // Hostname
    property string localHostName: "Device Label"
    
    // Helper to get hostname
    property var sysNameSource: P5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
             if (data["exit code"] === 0) {
                 root.localHostName = data["stdout"].trim()
             }
             disconnectSource(source)
        }
        function fetch() {
            connectSource("uname -n")
        }
    }
    
    Component.onCompleted: {
        sysNameSource.fetch()
    }

    // Data Model
    DeviceModel {
        id: deviceModel
        useCustomIcons: Plasmoid.configuration.useCustomIcons
        iconVersion: Plasmoid.configuration.iconVersion
        laptopIcon: Plasmoid.configuration.laptopIcon
        deviceTypeConfig: Plasmoid.configuration.deviceType
    }

    readonly property int edgeMargin: Plasmoid.configuration.edgeMargin !== undefined ? Plasmoid.configuration.edgeMargin : 10
    
    readonly property int computedRadius: {
        switch(Plasmoid.configuration.cornerRadius) {
            case "normal": return 20
            case "small": return 10
            case "square": return 0
            default: return 20
        }
    }
    
    readonly property double computedOpacity: {
        switch(Plasmoid.configuration.backgroundOpacity) {
            case "full": return 1.0
            case "high": return 0.75
            case "medium": return 0.5
            case "low": return 0.25
            case "none": return 0.0
            default: return 1.0
        }
    }

    fullRepresentation: Item {
        id: fullRep
        anchors.fill: parent
        
        // Background
        Rectangle {
            anchors.fill: parent
            anchors.margins: root.edgeMargin
            // "Widgetin kenar boşlukları ... @[Plasma6Widgets/weather] widgetine bak"
             // Weather uses margin 0 if panel, else 'edgeMargin'.
             // Assuming desktop widget for now based on size descriptions.
            
            radius: root.computedRadius
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, root.computedOpacity)
            
            // Mask/Clip for rounded corners
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: maskItem
            }
            
            Rectangle {
                id: maskItem
                anchors.fill: parent
                radius: root.computedRadius
                visible: false
            }
            
            // Views Loader
            Loader {
                anchors.fill: parent
                // Pass properties
                property var devices: deviceModel.devices
                property var mainDevice: deviceModel.mainDevice
                property string hostName: root.localHostName
                
                sourceComponent: largeViewComp
            }
        }
    }

    Component {
        id: largeViewComp
        LargeView {
            devices: deviceModel.devices
            mainDevice: deviceModel.mainDevice
            hostName: root.localHostName
            finishTime: deviceModel.mainDevice ? deviceModel.formatFinishTime(deviceModel.pmSourceData["Battery"]["Remaining msec"] || 0) : ""
            remainingMsec: deviceModel.pmSourceData["Battery"] ? (deviceModel.pmSourceData["Battery"]["Remaining msec"] || 0) : 0
            currentPowerProfile: deviceModel.currentPowerProfile
            onSetPowerProfile: (profile) => deviceModel.setPowerProfile(profile)
            
            // Adaptive Mode
            property string mode: root.currentViewMode
            viewMode: mode
            iconShape: Plasmoid.configuration.iconShape
            showChargingIcon: Plasmoid.configuration.showChargingIcon
            backgroundOpacity: Plasmoid.configuration.backgroundOpacity
            cornerRadius: Plasmoid.configuration.cornerRadius
            pillGeometry: Plasmoid.configuration.pillGeometry
        }
    }
}
