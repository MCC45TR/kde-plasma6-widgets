import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    property int cpuTemp: 0
    property int gpuTemp: 0
    property bool isAvailable: false
    
    implicitWidth: Kirigami.Units.iconSizes.medium
    implicitHeight: Kirigami.Units.iconSizes.medium
    
    function getTempColor(temp) {
        if (temp >= 85) return Kirigami.Theme.negativeColor
        if (temp >= 70) return Kirigami.Theme.neutralColor
        return Kirigami.Theme.positiveColor
    }
    
    Kirigami.Icon {
        anchors.fill: parent
        source: isAvailable ? "cpu" : "dialog-warning"
        color: isAvailable ? Kirigami.Theme.textColor : Kirigami.Theme.neutralColor
    }
    
    // Temperature badge
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -Kirigami.Units.smallSpacing
        anchors.bottomMargin: -Kirigami.Units.smallSpacing
        
        width: tempLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
        height: Kirigami.Units.gridUnit * 0.8
        radius: height / 2
        
        color: getTempColor(cpuTemp)
        visible: isAvailable && cpuTemp > 0
        
        PlasmaComponents.Label {
            id: tempLabel
            anchors.centerIn: parent
            text: cpuTemp + "°"
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.85
            font.bold: true
            color: "white"
        }
    }
    
    PlasmaComponents.ToolTip {
        id: tooltip
        text: isAvailable ? 
            i18n("CPU: %1°C\nGPU: %2°C", cpuTemp, gpuTemp) : 
            i18n("msi-ec driver not available")
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        onContainsMouseChanged: {
            if (containsMouse) {
                tooltip.show(tooltip.text)
            } else {
                tooltip.hide()
            }
        }
    }
}
