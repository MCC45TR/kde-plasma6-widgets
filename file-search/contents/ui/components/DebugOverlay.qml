import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Rectangle {
    id: root
    
    property int resultCount: 0
    property string activeBackend: "Milou"
    property int lastLatency: 0
    property string viewModeName: "List"
    property string displayModeName: "Button"
    
    // Localization
    property var tr: function(k) { return k }
    
    // Telemetry data
    property int totalSearches: 0
    property int avgLatency: 0
    property var telemetryDataRaw: "{}" // Passed from parent if needed
    
    color: Qt.rgba(0, 0, 0, 0.85)
    radius: 6
    border.color: Kirigami.Theme.highlightColor
    border.width: 1
    
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: layout.implicitHeight + 24
    
    // Data Source for file writing
    Plasma5Support.DataSource {
        id: executableDataSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            saveBtn.text = root.tr("saved")
            saveBtnTimer.start()
        }
    }
    
    Timer {
        id: saveBtnTimer
        interval: 2000
        onTriggered: saveBtn.text = root.tr("save_dump")
    }
    
    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4
        
        Label {
            text: root.tr("debug_overlay_title")
            font.bold: true
            font.pixelSize: 10
            color: Kirigami.Theme.highlightColor
            Layout.alignment: Qt.AlignHCenter
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Kirigami.Theme.highlightColor
            opacity: 0.5
        }
        
        GridLayout {
            columns: 2
            rowSpacing: 0
            columnSpacing: 10
            
            // Current Session
            Label { text: root.tr("backend") + ":"; color: "white"; font.pixelSize: 10 }
            Label { text: root.activeBackend; color: "#00ff00"; font.pixelSize: 10; font.bold: true }
            
            Label { text: root.tr("items") + ":"; color: "white"; font.pixelSize: 10 }
            Label { text: root.resultCount.toString(); color: "white"; font.pixelSize: 10 }
            
            Label { text: root.tr("latency") + ":"; color: "white"; font.pixelSize: 10 }
            Label { 
                text: root.lastLatency + " ms"; 
                color: root.lastLatency > 150 ? "red" : (root.lastLatency > 50 ? "yellow" : "#00ff00"); 
                font.pixelSize: 10 
            }
            
            Label { text: root.tr("view") + ":"; color: "white"; font.pixelSize: 10 }
            Label { text: root.viewModeName; color: "white"; font.pixelSize: 10 }
            
            Label { text: root.tr("display") + ":"; color: "white"; font.pixelSize: 10 }
            Label { text: root.displayModeName; color: "white"; font.pixelSize: 10 }

            // Divider
            Item { Layout.columnSpan: 2; height: 4; width: 1 }

            // Telemetry (Persistent)
            Label { text: root.tr("total") + ":"; color: "#aaaaaa"; font.pixelSize: 9 }
            Label { text: root.totalSearches.toString(); color: "#aaaaaa"; font.pixelSize: 9 }

            Label { text: root.tr("avg_lat") + ":"; color: "#aaaaaa"; font.pixelSize: 9 }
            Label { text: root.avgLatency + " ms"; color: "#aaaaaa"; font.pixelSize: 9 }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Kirigami.Theme.highlightColor
            opacity: 0.3
            Layout.topMargin: 4
        }
        
        // Save Button
        Button {
            id: saveBtn
            text: root.tr("save_dump")
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            font.pixelSize: 10
            
            contentItem: Text {
                text: saveBtn.text
                font: saveBtn.font
                color: Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            background: Rectangle {
                color: saveBtn.down ? Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.1)
                radius: 4
                border.width: 1
                border.color:  Qt.rgba(1,1,1,0.3)
            }
            
            onClicked: {
                var now = new Date()
                var filename = "Search-Debug-" + now.toISOString().replace(/[:.]/g, "-") + ".json"
                
                var dumpData = {
                    timestamp: now.toISOString(),
                    session: {
                        backend: root.activeBackend,
                        latency: root.lastLatency,
                        viewMode: root.viewModeName,
                        displayMode: root.displayModeName,
                        results: root.resultCount
                    },
                    telemetry: {
                        total: root.totalSearches,
                        avgLatency: root.avgLatency
                    },
                    system: {
                        locale: Qt.locale().name
                    }
                }
                
                var content = JSON.stringify(dumpData, null, 2)
                var b64 = Qt.btoa(unescape(encodeURIComponent(content)))
                var cmd = 'sh -c "echo ' + b64 + ' | base64 -d > $HOME/' + filename + '"'
                
                executableDataSource.connectedSources = [cmd]
            }
        }
    }
    
    Behavior on opacity { NumberAnimation { duration: 200 } }
}
