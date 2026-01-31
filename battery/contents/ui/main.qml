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
    
    // Layout Logic
    readonly property bool isSmall: width < 350 && height < 350
    readonly property bool isBroad: width >= 350 && height < 350
    readonly property bool isLarge: width >= 350 && height >= 350
    
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
            connectSource("hostname")
        }
    }
    
    Component.onCompleted: {
        sysNameSource.fetch()
    }

    // Data Model
    DeviceModel {
        id: deviceModel
    }

    fullRepresentation: Item {
        id: fullRep
        anchors.fill: parent
        
        // Background
        Rectangle {
            anchors.fill: parent
            anchors.margins: 0 // Widget handles internal margins usually?
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
                
                sourceComponent: {
                    if (root.isSmall) return largeViewComp
                    if (root.isBroad) return broadViewComp
                    return smallViewComp
                }
            }
        }
    }

    Component {
        id: smallViewComp
        SmallView {
            devices: deviceModel.devices
            mainDevice: deviceModel.mainDevice
            hostName: root.localHostName
        }
    }
    
    Component {
        id: broadViewComp
        BroadView {
            devices: deviceModel.devices
            mainDevice: deviceModel.mainDevice
            hostName: root.localHostName
        }
    }
    
    Component {
        id: largeViewComp
        LargeView {
            devices: deviceModel.devices
            mainDevice: deviceModel.mainDevice
            hostName: root.localHostName
        }
    }
}
