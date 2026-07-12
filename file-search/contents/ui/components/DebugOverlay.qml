import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../js/RSSManager.js" as RSSManager

Rectangle {
    id: root

    property int resultCount: 0
    property string activeBackend: "Milou"
    property int lastLatency: 0
    property string viewModeName: "List"
    property string displayModeName: "Button"

    // Localization
    // Localization removed
    // Use standard i18nd("plasma_applet_com.mcc45tr.filesearch", )

    // Telemetry data
    property int totalSearches: 0
    property int avgLatency: 0
    property var telemetryDataRaw: "{}" // Passed from parent if needed
    property var performanceTrace: ({})

    color: Qt.rgba(0, 0, 0, 0.85)
    radius: 6
    border.color: Kirigami.Theme.highlightColor
    border.width: 1

    implicitWidth: layout.implicitWidth + 24
    implicitHeight: layout.implicitHeight + 24

    AsyncProcess {
        id: processRunner
    }

    function saveDump(command) {
        processRunner.run(command, function(stdout, isFinished, exitCode) {
            if (!isFinished || exitCode !== 0)
                return
            saveBtn.text = i18nd("plasma_applet_com.mcc45tr.filesearch", "Saved!")
            saveBtnTimer.start()
        })
    }

    Timer {
        id: saveBtnTimer
        interval: 2000
        onTriggered: saveBtn.text = i18nd("plasma_applet_com.mcc45tr.filesearch", "Save Dump")
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4

        PlasmaComponents.Label {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Debug Overlay")
            font.bold: true
            font.family: Kirigami.Theme.smallFont.family
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
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
            PlasmaComponents.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Backend") + ":"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: root.activeBackend; color: "#00ff00"; font.family: Kirigami.Theme.smallFont.family; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; font.bold: true }

            PlasmaComponents.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Items") + ":"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: root.resultCount.toString(); color: "white"; font: Kirigami.Theme.smallFont }

            PlasmaComponents.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Latency") + ":"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label {
                text: root.lastLatency + " ms";
                color: root.lastLatency > 150 ? "red" : (root.lastLatency > 50 ? "yellow" : "#00ff00");
                font.family: Kirigami.Theme.smallFont.family
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }

            PlasmaComponents.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "View") + ":"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: root.viewModeName; color: "white"; font: Kirigami.Theme.smallFont }

            PlasmaComponents.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Display") + ":"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: root.displayModeName; color: "white"; font: Kirigami.Theme.smallFont }

            PlasmaComponents.Label { text: "Input → query:"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: (root.performanceTrace.inputToIssueMs ?? -1) + " ms"; color: "white"; font: Kirigami.Theme.smallFont }

            PlasmaComponents.Label { text: "Backend → first row:"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: (root.performanceTrace.backendToFirstRowMs ?? -1) + " ms"; color: "white"; font: Kirigami.Theme.smallFont }

            PlasmaComponents.Label { text: "Scan / sort:"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: (root.performanceTrace.scanMs ?? -1) + " / " + (root.performanceTrace.sortMs ?? -1) + " ms"; color: "white"; font: Kirigami.Theme.smallFont }

            PlasmaComponents.Label { text: "Refresh total:"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: (root.performanceTrace.refreshMs ?? -1) + " ms"; color: "white"; font: Kirigami.Theme.smallFont }

            PlasmaComponents.Label { text: "Cache hit / miss:"; color: "white"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: (root.performanceTrace.metadataCacheHits ?? 0) + " / " + (root.performanceTrace.metadataCacheMisses ?? 0); color: "white"; font: Kirigami.Theme.smallFont }

            // Divider
            Item { Layout.columnSpan: 2; height: 4; width: 1 }

            // Telemetry (Persistent)
            PlasmaComponents.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Total Searches") + ":"; color: "#aaaaaa"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: root.totalSearches.toString(); color: "#aaaaaa"; font: Kirigami.Theme.smallFont }

            PlasmaComponents.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Avg Latency") + ":"; color: "#aaaaaa"; font: Kirigami.Theme.smallFont }
            PlasmaComponents.Label { text: root.avgLatency + " ms"; color: "#aaaaaa"; font: Kirigami.Theme.smallFont }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Kirigami.Theme.highlightColor
            opacity: 0.3
            Layout.topMargin: 4
        }

        // Save Button
        PlasmaComponents.Button {
            id: saveBtn
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Save Dump")
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            font.family: Kirigami.Theme.smallFont.family
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
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
                    performance: root.performanceTrace,
                    system: {
                        locale: Qt.locale().name
                    }
                }

                var content = JSON.stringify(dumpData, null, 2)
                var b64 = RSSManager.encodeBase64(content)
                var cmd = 'sh -c "echo ' + b64 + ' | base64 -d > $HOME/' + filename + '"'

                root.saveDump(cmd)
            }
        }
    }

    Behavior on opacity { NumberAnimation { duration: 200 } }
}
