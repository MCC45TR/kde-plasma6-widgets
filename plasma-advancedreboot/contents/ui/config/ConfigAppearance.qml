import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: page
    
    // Configuration properties (automatically synced)
    property alias cfg_viewMode: viewModeCombo.currentIndex
    property alias cfg_viewModeDefault: viewModeCombo.currentIndex
    
    property string cfg_cachedBootEntries: ""
    property string cfg_cachedBootEntriesDefault: ""
    
    property double cfg_backgroundOpacity
    property int cfg_edgeMargin
    
    // Defaults needed for KCM logic
    property double cfg_backgroundOpacityDefault
    property int cfg_edgeMarginDefault

    // Logic for loading entries from the config page
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        onNewData: (sourceName, data) => {
            if (sourceName.indexOf("bootctl list") !== -1 && data["stdout"]) {
                // Determine if valid JSON
                try {
                    var test = JSON.parse(data["stdout"])
                    if (test.length > 0) {
                        // Success - Update Config
                        page.cfg_cachedBootEntries = data["stdout"]
                        feedbackLabel.text = i18n("Success! Entries updated.")
                        feedbackLabel.color = Kirigami.Theme.positiveTextColor
                    }
                } catch(e) {
                    feedbackLabel.text = i18n("Error parsing output.")
                    feedbackLabel.color = Kirigami.Theme.negativeTextColor
                }
                loadingSpinner.running = false
                execSource.disconnectSource(sourceName)
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Kirigami.Units.gridUnit
        spacing: Kirigami.Units.largeSpacing

        // Section: Display Logic
        Kirigami.FormLayout {
            Layout.fillWidth: true
            
            ComboBox {
                id: viewModeCombo
                Kirigami.FormData.label: i18n("Display Mode:")
                model: [
                    i18n("Single Card (Large)"),
                    i18n("Standard List (Compact)")
                ]
                Layout.fillWidth: true
            }
            
            Label {
                text: i18n("Single Card mode allows paging through entries one by one.")
                font.italic: true
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.disabledTextColor
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // Section: Visual Adjustments
        GroupBox {
            title: i18n("Visual Adjustments")
            Layout.fillWidth: true
            
            ColumnLayout {
                spacing: 10
                width: parent.width

                Label {
                    text: i18n("Background Opacity:")
                    font.bold: true
                }

                ComboBox {
                    id: opacityCombo
                    Layout.fillWidth: true
                    model: ["100%", "90%", "75%", "50%", "25%", "10%", "0%"]
                    property var opacityValues: [1.0, 0.9, 0.75, 0.5, 0.25, 0.1, 0.0]

                    onCurrentIndexChanged: {
                         page.cfg_backgroundOpacity = opacityValues[currentIndex]
                    }
                }

                Label {
                    text: i18n("Widget Margin:")
                    font.bold: true
                }
                
                ComboBox {
                    id: edgeMarginCombo
                    Layout.fillWidth: true
                    model: [i18n("Normal (10px)"), i18n("Less (5px)"), i18n("None (0px)")]
                    
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) page.cfg_edgeMargin = 10
                        else if (currentIndex === 1) page.cfg_edgeMargin = 5
                        else if (currentIndex === 2) page.cfg_edgeMargin = 0
                    }
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // Section: Data & Troubleshooting
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: i18n("Troubleshooting & Data")
                font.bold: true
                color: Kirigami.Theme.textColor
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                
                Button {
                    icon.name: "edit-clear-history"
                    text: i18n("Reset Cache")
                    onClicked: {
                        page.cfg_cachedBootEntries = ""
                        feedbackLabel.text = i18n("Cache cleared.")
                        feedbackLabel.color = Kirigami.Theme.neutralTextColor
                    }
                }

                Button {
                    icon.name: "view-refresh"
                    text: i18n("Reload with Sudo")
                    enabled: !loadingSpinner.running
                    onClicked: {
                        loadingSpinner.running = true
                        feedbackLabel.text = i18n("Requesting permissions...")
                        feedbackLabel.color = Kirigami.Theme.textColor
                        execSource.connectSource("pkexec bootctl list --json=short")
                    }
                }
                
                BusyIndicator {
                    id: loadingSpinner
                    running: false
                    implicitHeight: 24
                    implicitWidth: 24
                }
            }

            Label {
                id: feedbackLabel
                text: ""
                visible: text !== ""
                Layout.topMargin: 5
            }
        }
        
        Item { Layout.fillHeight: true } // Spacer
    }
}
