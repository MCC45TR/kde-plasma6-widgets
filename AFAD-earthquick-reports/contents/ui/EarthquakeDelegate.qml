import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: delegate
    width: ListView.view.width
    height: 60

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "transparent"
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: bg.color = Qt.rgba(0, 0, 0, 0.05)
            onExited: bg.color = "transparent"
        }
    }

    Rectangle {
        id: magnitudeBox
        width: 48
        height: 48
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        radius: 8
        
        color: {
            var m = parseFloat(model.magnitude)
            if (isNaN(m)) return Kirigami.Theme.backgroundColor
            
            if (m >= 7.0) return "#721c24" // Dark Red
            if (m >= 6.0) return "#dc3545" // Red
            if (m >= 5.0) return "#fd7e14" // Orange
            if (m >= 4.0) return "#ffc107" // Yellow
            if (m >= 3.0) return "#28a745" // Green
            return "#17a2b8" // Blue/Teal for minor
        }
        
        Text {
            anchors.centerIn: parent
            text: model.magnitude
            color: "white"
            font.bold: true
            font.pointSize: 12
        }
    }
    
    ColumnLayout {
        anchors.left: magnitudeBox.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        
        PlasmaComponents.Label {
            text: model.location
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        
        RowLayout {
            spacing: 15
            
            PlasmaComponents.Label {
                // Parse AFAD date string if necessary, but new Date() usually works
                // AFAD format: YYYY-MM-DDThh:mm:ss
                text: {
                    var d = new Date(model.date)
                    if (isNaN(d.getTime())) return model.date || ""
                    return Qt.formatDateTime(d, "dd.MM HH:mm")
                }
                opacity: 0.7
                font.pointSize: Qt.application.font.pointSize * 0.9
            }
            
            PlasmaComponents.Label {
                text: model.depth + " km"
                opacity: 0.7
                font.pointSize: Qt.application.font.pointSize * 0.9
            }
            
            Item { Layout.fillWidth: true }
        }
    }
    
    Rectangle {
        height: 1
        width: parent.width - 20
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        color: Kirigami.Theme.textColor
        opacity: 0.1
    }
}
