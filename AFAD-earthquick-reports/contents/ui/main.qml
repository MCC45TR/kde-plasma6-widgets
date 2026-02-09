import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/AfadApi.js" as AfadApi

PlasmoidItem {
    id: root

    Layout.preferredWidth: 400
    Layout.preferredHeight: 300
    Layout.minimumWidth: 300
    Layout.minimumHeight: 200
    
    property bool isLoading: false
    property string lastUpdate: ""
    
    ListModel {
        id: earthquakeModel
    }

    function refreshData() {
        isLoading = true
        // Default options: last 24 hours, min magnitude 0
        var options = {
            hours: 24,
            minMag: 0,
            limit: 100
        }
        
        AfadApi.fetchEarthquakes(function(err, data) {
            isLoading = false
            if (err) {
                console.error("AFAD Widget Error:", err)
                return
            }
            
            if (data) {
                earthquakeModel.clear()
                // AFAD returns newest first usually, but let's just append
                for (var i = 0; i < data.length; i++) {
                    earthquakeModel.append(data[i])
                }
                lastUpdate = new Date().toLocaleTimeString()
            }
        }, options)
    }

    Timer {
        interval: 600000 // 10 minutes
        running: true
        repeat: true
        onTriggered: refreshData()
    }

    Component.onCompleted: {
        refreshData()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            
            PlasmaComponents.Label {
                text: "AFAD Son Depremler"
                font.bold: true
            }
            
            Item { Layout.fillWidth: true }
            
            PlasmaComponents.Label {
                text: lastUpdate
                font.pointSize: Qt.application.font.pointSize * 0.8
                opacity: 0.6
            }
            
            PlasmaComponents.Button {
                icon.name: "view-refresh"
                display: PlasmaComponents.Button.IconOnly
                onClicked: refreshData()
                enabled: !isLoading
            }
        }
        
        PlasmaComponents.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ListView {
                id: listView
                model: earthquakeModel
                delegate: EarthquakeDelegate {}
                clip: true
                spacing: 5
                
                PlasmaComponents.BusyIndicator {
                    anchors.centerIn: parent
                    running: isLoading
                    visible: isLoading
                }
                
                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    text: i18n("No earthquakes found.")
                    visible: !isLoading && earthquakeModel.count === 0
                }
            }
        }
    }
}
