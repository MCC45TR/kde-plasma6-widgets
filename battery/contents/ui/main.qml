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
    
    Layout.minimumWidth: 140
    Layout.minimumHeight: 140
    Layout.preferredWidth: 200
    Layout.preferredHeight: 200

    readonly property string currentViewMode: {
        // Extrasmall Mode Definition (0   <= height < 160)       and (0   <= width < 160)
        // Small Mode Definition      (160 <= height < 250)       and (160 <= width < 280)
        // Wide Mode Definition       (0   <= height < 250)       and (280 <= width < infinite)
        // Tall Mode Definition       (250 <= height < infinite)  and (0   <= width < 280)
        // Big Mode Definition        (250 <= height < infinite)  and (280 <= width < infinite)
        // Height bucket: 0 = <160, 1 = 160-249, 2 = >=250
        var hBucket = height < 160 ? 0 : (height < 250 ? 1 : 2)
        // Width bucket: 0 = <160, 1 = 160-279, 2 = >=280
        var wBucket = width < 160 ? 0 : (width < 280 ? 1 : 2)
        // Combined key: hBucket * 3 + wBucket
        var key = hBucket * 3 + wBucket

        switch(key) {
            case 0: return "extrasmall" // h<160, w<160
            case 1: return "extrasmall" // h<160, 160<=w<280 (fallback - doesn't fit small)
            case 2: return "wide"       // h<160, w>=280 (wide: h<250 && w>=280)
            case 3: return "extrasmall" // 160<=h<250, w<160 (fallback)
            case 4: return "small"      // 160<=h<250, 160<=w<280
            case 5: return "wide"       // 160<=h<250, w>=280 (wide: h<250 && w>=280)
            case 6: return "tall"       // h>=250, w<160 (tall: h>=250 && w<280)
            case 7: return "tall"       // h>=250, 160<=w<280 (tall: h>=250 && w<280)
            case 8: return "big"        // h>=250, w>=280
            default: return "extrasmall"
        }
    }
    
    onCurrentViewModeChanged: console.log("View Mode:", currentViewMode, "(" + width + "x" + height + ")")
    
    // Hostname
    property string localHostName: i18n("Device Label")
    
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
        useAlternativeIcons: Plasmoid.configuration.useAlternativeIcons
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
    
    readonly property int contentGap: 10
    readonly property int barRadius: computedRadius === 20 ? 10 : (computedRadius === 10 ? 5 : 0)
    readonly property int switchRadius: Math.max(0, computedRadius - contentGap)


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
            
            // Views Loader - Lazy Loading
            Loader {
                anchors.fill: parent
                asynchronous: true
                
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
        BigView {
            devices: deviceModel.devices
            mainDevice: deviceModel.mainDevice
            hostName: root.localHostName
            finishTime: deviceModel.mainDevice ? deviceModel.formatFinishTime(deviceModel.pmSourceData["Battery"]["Remaining msec"] || 0) : ""
            remainingMsec: deviceModel.pmSourceData["Battery"] ? (deviceModel.pmSourceData["Battery"]["Remaining msec"] || 0) : 0
            currentPowerProfile: deviceModel.currentPowerProfile
            hasPowerProfiles: deviceModel.hasPowerProfiles
            onSetPowerProfile: (profile) => deviceModel.setPowerProfile(profile)
            
            // Adaptive Mode
            property string mode: root.currentViewMode
            viewMode: mode
            iconShape: Plasmoid.configuration.iconShape
            showChargingIcon: Plasmoid.configuration.showChargingIcon
            pillGeometry: Plasmoid.configuration.batteryBarsStyle === "pill"

            // Styles (Calculated)
            backgroundRadius: root.computedRadius
            opacityValue: root.computedOpacity
            barRadius: root.barRadius
            switchRadius: root.switchRadius
            contentGap: root.contentGap
        }
    }
}
