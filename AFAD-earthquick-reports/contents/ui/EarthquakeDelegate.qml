import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaComponents.ItemDelegate {
    id: delegate
    width: ListView.view.width
    
    // Use contentItem for the custom delegate layout.
    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        // Magnitude Box
        Rectangle {
            id: magnitudeBox
            width: 48
            height: 48
            radius: Kirigami.Units.smallSpacing
            
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
            
            PlasmaComponents.Label {
                anchors.centerIn: parent
                text: model.magnitude
                color: "white"
                font.bold: true
                font.pointSize: 12
            }
        }
        
        // Information Column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing / 2
            
            PlasmaComponents.Label {
                text: model.location
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                
                PlasmaComponents.Label {
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
    }
}
