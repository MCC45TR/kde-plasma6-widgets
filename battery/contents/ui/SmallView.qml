import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import "Formatter.js" as Formatter

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

    // Design Tokens (Passed from Main via BigView)
    property int backgroundRadius: 20
    property double opacityValue: 1.0
    property int barRadius: 10
    property int switchRadius: 10
    property int contentGap: 10

    // --- BOTTOM SECTION (Peripheral List) ---
    ListView {
        id: deviceList
        anchors.fill: parent
        anchors.margins: root.contentGap
        spacing: 5
        snapMode: ListView.SnapToItem
        clip: true
        
        model: {
            // Show all devices, ensure Main is first
            var main = devices.filter(d => d.isMain);
            var others = devices.filter(d => !d.isMain);
            return main.concat(others);
        }
        
        delegate: Item {
            id: delegateRoot
            width: ListView.view.width
            
            readonly property int itemCount: ListView.view.count
            readonly property real calculatedHeight: {
                var totalH = ListView.view.height
                var sp = ListView.view.spacing
                var minH = 40
                
                // How many items can fully fit?
                var maxFit = Math.floor((totalH + sp) / (minH + sp))
                maxFit = Math.max(1, maxFit)
                
                // If we have more items than fit, use maxFit to calculate height (triggers scroll)
                // Otherwise use actual count to spread evenly
                var effectiveCount = (itemCount > maxFit) ? maxFit : itemCount
                
                return (totalH - (sp * (effectiveCount - 1))) / effectiveCount
            }
            
            height: calculatedHeight
            
            HorizontalBatteryBar {
                anchors.fill: parent
                // If main device (and named generic "Laptop"), show real hostname
                deviceName: modelData.isMain && (modelData.name === "Laptop" || modelData.name === "") ? root.hostName : modelData.name
                deviceIcon: modelData.icon
                percentage: modelData.percentage
                isCharging: modelData.isCharging === true
                showChargingIcon: root.showChargingIcon
                barRadius: root.barRadius
                pillGeometry: root.pillGeometry
            }
        }
    }
}
