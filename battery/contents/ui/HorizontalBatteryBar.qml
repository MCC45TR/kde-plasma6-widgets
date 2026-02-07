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
        color: Qt.rgba(0.3, 0.3, 0.3, 0.5)
        radius: root.effectiveRadius
    }
    
    // Filled Progress
    Rectangle {
        id: barFill
        height: parent.height
        width: parent.width * (root.percentage / 100)
        radius: root.effectiveRadius
        
        // Color Logic
        property color barColor: {
            if (root.isCharging) return "#2ecc71" // Green
            var p = root.percentage
            if (p <= 15) return Kirigami.Theme.negativeColor
            if (p <= 30) return "#FFAA00"
            return Kirigami.Theme.highlightColor
        }
        color: barColor
        
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 200 } }
    }
    
    // Content Row (Inside Bar)
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.height < 60 ? 5 : 10
        anchors.rightMargin: root.height < 60 ? 5 : 10
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        spacing: root.height < 60 ? 5 : 8
        
        // Icon
        Kirigami.Icon {
            source: root.deviceIcon
            Layout.preferredWidth: root.height < 60 ? 32 : 48
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            color: Kirigami.Theme.textColor
        }
        
        // Text
        Text {
            text: root.deviceName + " (%" + root.percentage + ")"
            font.bold: true
            font.pixelSize: root.height < 60 ? 14 : 20
            color: Kirigami.Theme.textColor
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
        
        // Charging Indicator with circular background
        Item {
            visible: root.isCharging && root.showChargingIcon
            Layout.preferredWidth: root.height < 60 ? 28 : 36
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
