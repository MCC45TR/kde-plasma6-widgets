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
    readonly property double minMagnitude: Plasmoid.configuration.minMagnitude !== undefined ? Plasmoid.configuration.minMagnitude : 0.0
    readonly property int timeRange: Plasmoid.configuration.timeRange || 24
    readonly property int limit: Plasmoid.configuration.limit || 100
    readonly property int updateIntervalMinutes: Plasmoid.configuration.updateInterval || 10
    
    property bool isLoading: false
    property string lastUpdate: ""
    
    ListModel {
        id: earthquakeModel
    }

    function refreshData() {
        isLoading = true
        var options = {
            hours: root.timeRange,
            minMag: root.minMagnitude,
            limit: root.limit
        }
        
        AfadApi.fetchEarthquakes(function(err, data) {
            isLoading = false
            if (err) {
                console.error("AFAD Widget Error:", err)
                return
            }
            
            if (data) {
                // Sort by date DESC (AFAD usually returns newest first, but let's be sure)
                data.sort(function(a, b) {
                    return new Date(b.date) - new Date(a.date);
                });

                earthquakeModel.clear()
                for (var i = 0; i < data.length; i++) {
                    earthquakeModel.append(data[i])
                }
                lastUpdate = new Date().toLocaleTimeString()
            }
        }, options)
    }

    Connections {
        target: Plasmoid.configuration
        function onMinMagnitudeChanged() { refreshData() }
        function onTimeRangeChanged() { refreshData() }
        function onLimitChanged() { refreshData() }
    }

    Timer {
        id: refreshTimer
        interval: updateIntervalMinutes * 60000
        running: true
        repeat: true
        onTriggered: refreshData()
        
        onIntervalChanged: {
            restart()
        }
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
