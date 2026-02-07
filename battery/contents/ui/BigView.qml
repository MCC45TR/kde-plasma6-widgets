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
    
    function formatDuration(msec) {
        if (msec <= 0) return ""
        var totalMins = Math.floor(msec / 60000)
        
        if (totalMins < 60) {
            return i18nc("minutes", "%1 m", totalMins)
        } else if (totalMins < 1440) {
            var h = Math.floor(totalMins / 60)
            var m = totalMins % 60
            return i18nc("hours and minutes", "%1 h %2 m", h, m)
        } else {
            var d = Math.floor(totalMins / 1440)
            var h = Math.round((totalMins % 1440) / 60)
            if (h === 24) { d++; h = 0; }
            return i18nc("days and hours", "%1 d %2 h", d, h)
        }
    }

    // View Mode (Adaptive)
    property string viewMode: "big" // "small", "wide", "big"
    property string iconShape: "square" // "square", "rounded", "circle"
    property bool showChargingIcon: true
    property string backgroundOpacity: "full"
    property string cornerRadius: "normal"
    property bool pillGeometry: false

    // Design Tokens
    readonly property int backgroundRadius: cornerRadius === "normal" ? 20 : (cornerRadius === "small" ? 10 : 0)
    readonly property double opacityValue: {
        switch(backgroundOpacity) {
            case "full": return 1.0
            case "high": return 0.75
            case "medium": return 0.5
            case "low": return 0.25
            case "none": return 0.0
            default: return 1.0
        }
    }
    readonly property int barRadius: cornerRadius === "normal" ? 10 : (cornerRadius === "small" ? 5 : 0)
    readonly property int switchRadius: Math.max(0, backgroundRadius - contentGap)
    readonly property int contentGap: 10

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
                item.backgroundOpacity = Qt.binding(() => root.backgroundOpacity)
                item.cornerRadius = Qt.binding(() => root.cornerRadius)
                item.pillGeometry = Qt.binding(() => root.pillGeometry)
                
                // Connect signal
                if (item.setPowerProfile) {
                    item.setPowerProfile.connect(root.setPowerProfile)
                }
            }
        }
    }
}
