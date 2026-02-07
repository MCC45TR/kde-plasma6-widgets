import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

    Item {
    id: root
    
    // Props passed from main
    property var devices: []
    property var mainDevice: null
    property string hostName: ""
    property string finishTime: "" // New property
    property real remainingMsec: 0 // New property for relative time
    property string currentPowerProfile: "balanced"
    property bool hasPowerProfiles: true
    signal setPowerProfile(string profile)
    
    // View Mode (Adaptive)
    property string viewMode: "big" // "small", "wide", "big"
    property string iconShape: "square" // "square", "rounded", "circle"
    property bool showChargingIcon: true
    property bool pillGeometry: false

    // Design Tokens (Passed from Main)
    property int backgroundRadius: 20
    property double opacityValue: 1.0
    property int barRadius: 10
    property int switchRadius: 10
    property int contentGap: 10

    // Switcher Logic
    Loader {
        id: viewLoader
        anchors.fill: parent
        asynchronous: false // Load directly to avoid flicker, since we are already inside an asynchronous Loader in main.qml
        
        source: {
            if (root.viewMode === "small" || root.viewMode === "extrasmall") {
                return "SmallView.qml"
            } else if (root.viewMode === "wide") {
                return "WideView.qml"
            } else {
                return "TallView.qml"
            }
        }
        
        // Pass properties to loaded item
        onLoaded: {
            if (item) {
                // Binding properties to ensure updates propagate
                item.devices = Qt.binding(() => root.devices)
                item.mainDevice = Qt.binding(() => root.mainDevice)
                item.hostName = Qt.binding(() => root.hostName)
                item.finishTime = Qt.binding(() => root.finishTime)
                item.remainingMsec = Qt.binding(() => root.remainingMsec)
                item.currentPowerProfile = Qt.binding(() => root.currentPowerProfile)
                item.hasPowerProfiles = Qt.binding(() => root.hasPowerProfiles)
                item.viewMode = Qt.binding(() => root.viewMode)
                item.iconShape = Qt.binding(() => root.iconShape)
                item.showChargingIcon = Qt.binding(() => root.showChargingIcon)
                item.pillGeometry = Qt.binding(() => root.pillGeometry)
                
                // Pass Calculated Styles
                item.backgroundRadius = Qt.binding(() => root.backgroundRadius)
                item.opacityValue = Qt.binding(() => root.opacityValue)
                item.barRadius = Qt.binding(() => root.barRadius)
                item.switchRadius = Qt.binding(() => root.switchRadius)
                item.contentGap = Qt.binding(() => root.contentGap)
                
                // Connect signal
                if (item.setPowerProfile) {
                    item.setPowerProfile.connect(root.setPowerProfile)
                }
            }
        }
    }
}
