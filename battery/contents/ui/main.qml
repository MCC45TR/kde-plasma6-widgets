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
    
    Layout.minimumWidth: 200
    Layout.minimumHeight: 200

    readonly property string currentViewMode: {
        switch (true) {
            case (width < 250 && height < 250): return "extrasmall"
            case (width < 350 && height < 350): return "small"
            case (width >= 350 && height < 350): return "broad"
            case (width < 350 && height >= 350): return "tall"
            case (width >= 350 && height >= 350): return "large"
            default: return "large"
        }
    }
    
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
    }

    readonly property int edgeMargin: Plasmoid.configuration.edgeMargin !== undefined ? Plasmoid.configuration.edgeMargin : 10

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
            
            radius: 20
            color: Kirigami.Theme.backgroundColor
            
            // Mask/Clip for rounded corners
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: maskItem
            }
            
            Rectangle {
                id: maskItem
                anchors.fill: parent
                radius: 20
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
            currentPowerProfile: deviceModel.currentPowerProfile
            onSetPowerProfile: (profile) => deviceModel.setPowerProfile(profile)
            
            // Adaptive Mode
            property string mode: root.currentViewMode
            // We need to aliasing this property in LargeView to use it
            // Assuming we added 'viewMode' to LargeView, let's pass it as such
            viewMode: mode
            iconShape: Plasmoid.configuration.iconShape
        }
    }
}
