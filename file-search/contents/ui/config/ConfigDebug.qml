import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: debugPage
    
    property string title: i18n("Debug")
    
    // =========================================================================
    // CONFIGURATION PROPERTIES (Injectibles)
    // =========================================================================
    // We define all properties here to avoid "Property not found" warnings from Plasma
    
    // Display & View
    property int cfg_displayMode: 1
    property int cfg_displayModeDefault: 1
    property int cfg_viewMode: 0
    property int cfg_viewModeDefault: 0
    property int cfg_iconSize: 48
    property int cfg_iconSizeDefault: 48
    property int cfg_listIconSize: 22
    property int cfg_listIconSizeDefault: 22
    property int cfg_userProfile: 0
    property int cfg_userProfileDefault: 0
    
    // Preview
    property bool cfg_previewEnabled: true
    property bool cfg_previewEnabledDefault: true
    property string cfg_previewSettings: "{}"
    property string cfg_previewSettingsDefault: "{}"
    
    // Debug & Telemetry
    property bool cfg_debugOverlay: false
    property bool cfg_debugOverlayDefault: false
    property string cfg_telemetryData: "{}"
    property string cfg_telemetryDataDefault: "{}"
    
    // Data
    property string cfg_searchHistory: ""
    property string cfg_searchHistoryDefault: ""
    property string cfg_pinnedItems: "[]"
    property string cfg_pinnedItemsDefault: "[]"
    property string cfg_categorySettings: "{}"
    property string cfg_categorySettingsDefault: "{}"
    
    // Search
    property int cfg_searchAlgorithm: 0
    property int cfg_searchAlgorithmDefault: 0
    property int cfg_minResults: 3
    property int cfg_minResultsDefault: 3
    property int cfg_maxResults: 20
    property int cfg_maxResultsDefault: 20
    property bool cfg_smartResultLimit: true
    property bool cfg_smartResultLimitDefault: true
    property bool cfg_showBootOptions: false
    property bool cfg_showBootOptionsDefault: false

    // =========================================================================
    
    // Helper property
    property string currentLocale: Qt.locale().name
    
    // Warning if not in Developer mode
    Label {
        visible: cfg_userProfile !== 1
        text: "⚠️ " + i18n("This tab is only active in Developer mode. Change profile in General settings.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        color: Kirigami.Theme.negativeTextColor
        font.bold: true
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Debug Settings")
    }
    
    // Debug Overlay Toggle
    Switch {
        id: debugOverlayToggle
        Kirigami.FormData.label: i18n("Debug Overlay")
        checked: debugPage.cfg_debugOverlay
        enabled: cfg_userProfile === 1
        onToggled: debugPage.cfg_debugOverlay = checked
    }
    
    Label {
        text: i18n("Show debug info on widget (active mode, item count, index source)")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.7
        font.pixelSize: 11
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Debug Data")
    }
    
    // Debug Data Display
    GridLayout {
        columns: 2
        rowSpacing: 6
        columnSpacing: 12
        Layout.fillWidth: true
        
        Label { text: i18n("Timestamp") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: new Date().toISOString(); font.family: "Monospace" }
        
        Label { text: i18n("Locale") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: debugPage.currentLocale; font.family: "Monospace" }
        
        Label { text: i18n("User Profile") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: cfg_userProfile === 0 ? "Minimal (0)" : (cfg_userProfile === 1 ? "Developer (1)" : "Power User (2)")
            font.family: "Monospace" 
        }
        
        Label { text: i18n("Display Mode") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: cfg_displayMode === 0 ? "Button (0)" : (cfg_displayMode === 1 ? "Medium (1)" : (cfg_displayMode === 2 ? "Wide (2)" : "Extra Wide (3)"))
            font.family: "Monospace" 
        }
        
        Label { text: i18n("View Mode") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: cfg_viewMode === 0 ? "List (0)" : "Tile (1)"
            font.family: "Monospace" 
        }
        
        Label { text: i18n("Tile Icon Size") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: cfg_iconSize + " px"; font.family: "Monospace" }
        
        Label { text: i18n("List Icon Size") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: cfg_listIconSize + " px"; font.family: "Monospace" }
        
        Label { text: i18n("Enable Preview") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: cfg_previewEnabled ? "true" : "false"; font.family: "Monospace" }
        
        Label { text: i18n("Debug Overlay") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: cfg_debugOverlay ? "true" : "false"; font.family: "Monospace" }
        
        Label { text: i18n("History Count") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            id: historyCountLabel
            text: {
                try {
                    var hist = JSON.parse(cfg_searchHistory || "[]")
                    return hist.length + " " + i18n("items")
                } catch(e) {
                    return "Error: " + e.message
                }
            }
            font.family: "Monospace" 
        }
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Telemetry")
    }
    
    GridLayout {
        columns: 2
        rowSpacing: 6
        columnSpacing: 12
        Layout.fillWidth: true
        
        Label { text: i18n("Total Searches") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: {
                try {
                    var stats = JSON.parse(cfg_telemetryData || "{}")
                    return (stats.totalSearches || 0).toString()
                } catch(e) { return "0" }
            }
            font.family: "Monospace" 
        }
        
        Label { text: i18n("Avg Latency") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: {
                try {
                    var stats = JSON.parse(cfg_telemetryData || "{}")
                    return (stats.averageLatency || 0) + " ms"
                } catch(e) { return "0 ms" }
            }
            font.family: "Monospace" 
        }
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("History Sample")
    }
    
    // Privacy Notice
    Kirigami.InlineMessage {
        Layout.fillWidth: true
        type: Kirigami.MessageType.Information
        text: i18n("Privacy Notice: All debug and telemetry data is stored LOCALLY only. No data is sent to the internet.")
        visible: true
    }
    
    // History Sample
    Item {
        Kirigami.FormData.label: " "
        Layout.fillWidth: true
        Layout.preferredHeight: historyColumn.implicitHeight + 10
        
        ColumnLayout {
            id: historyColumn
            anchors.fill: parent
            spacing: 4
            
            Repeater {
                model: {
                    try {
                        var hist = JSON.parse(cfg_searchHistory || "[]")
                        return hist.slice(0, 5) // Show first 5 items
                    } catch(e) {
                        return []
                    }
                }
                
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1)
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8
                        
                        Kirigami.Icon {
                            source: modelData.decoration || "application-x-executable"
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            Label {
                                text: modelData.display || "Unknown"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                text: modelData.category || ""
                                font.pixelSize: 10
                                opacity: 0.6
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
            
            Label {
                visible: {
                    try {
                        var hist = JSON.parse(cfg_searchHistory || "[]")
                        return hist.length === 0
                    } catch(e) {
                        return true
                    }
                }
                text: i18n("History is empty")
                opacity: 0.5
                font.italic: true
            }
        }
    }
}
