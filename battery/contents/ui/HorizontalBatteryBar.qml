import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    // Required properties
    property string deviceName: ""
    property string deviceIcon: ""
    property int percentage: 0
    property bool isCharging: false
    property bool showChargingIcon: true  // User configurable
    property int barRadius: 10  // Configurable radius
    property bool pillGeometry: false  // Pill mode: radius = height/2
    
    // Effective radius calculation
    readonly property int effectiveRadius: pillGeometry ? Math.round(root.height / 2) : barRadius
    
    // Bar Background (Track)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
        radius: root.effectiveRadius
    }
    
    // Filled Progress
    Rectangle {
        id: barFill
        height: parent.height
        width: parent.width * (root.percentage / 100)
        radius: root.effectiveRadius
        
        // Color Logic
        property color chargeColor: "#2ecc71"
        property color criticalColor: Kirigami.Theme.negativeColor || "#e74c3c"
        property color warningColor: "#FFAA00"
        property color normalColor: Kirigami.Theme.highlightColor || "#3498db"
        
        property color barColor: {
            if (root.isCharging) return chargeColor
            var p = root.percentage
            if (p <= 15) return criticalColor
            if (p <= 30) return warningColor
            return normalColor
        }
        color: barColor
        
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad } }
    }
    
    // Content Row
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.max(2, root.height * 0.15)
        anchors.rightMargin: Math.max(2, root.height * 0.15)
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        spacing: Math.max(2, root.height * 0.1)
        
        Kirigami.Icon {
            source: root.deviceIcon
            Layout.preferredWidth: Math.min(root.height * 0.8, 48)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            color: Kirigami.Theme.textColor
        }
        
        Text {
            text: root.height >= 60 ? i18n("%1\n%2%", root.deviceName, root.percentage) : i18n("%1 (%2%)", root.deviceName, root.percentage)
            font.bold: true
            font.pixelSize: Math.max(10, Math.min(root.height * 0.35, 16))
            color: Kirigami.Theme.textColor
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
        
        Item {
            visible: root.isCharging && root.showChargingIcon
            Layout.preferredWidth: Math.min(root.height * 0.7, 36)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Kirigami.Theme.backgroundColor
            }
            
            Kirigami.Icon {
                anchors.centerIn: parent
                width: parent.width - 4
                height: width
                source: "sensors-voltage-symbolic"
                color: Kirigami.Theme.textColor
            }
        }
    }
}
