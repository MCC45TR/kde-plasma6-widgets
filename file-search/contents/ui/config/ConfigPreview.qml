import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: configPreview
    
    property string title: i18n("Preview")
    
    // KCM Configuration Properties (Preview specific)
    property string cfg_previewSettings
    property string cfg_previewSettingsDefault
    property bool cfg_previewEnabled
    property bool cfg_previewEnabledDefault

    // Other Config Properties (to silence warnings)
    property int cfg_displayMode
    property int cfg_displayModeDefault
    property int cfg_viewMode
    property int cfg_viewModeDefault
    property int cfg_iconSize
    property int cfg_iconSizeDefault
    property int cfg_listIconSize
    property int cfg_listIconSizeDefault
    property int cfg_userProfile
    property int cfg_userProfileDefault
    
    property bool cfg_debugOverlay
    property bool cfg_debugOverlayDefault
    property string cfg_telemetryData
    property string cfg_telemetryDataDefault
    property string cfg_pinnedItems
    property string cfg_pinnedItemsDefault
    property string cfg_categorySettings
    property string cfg_categorySettingsDefault
    property int cfg_searchAlgorithm
    property int cfg_searchAlgorithmDefault
    property int cfg_minResults
    property int cfg_minResultsDefault
    property int cfg_maxResults
    property int cfg_maxResultsDefault
    property bool cfg_smartResultLimit
    property bool cfg_smartResultLimitDefault
    property string cfg_searchHistory
    property string cfg_searchHistoryDefault
    property bool cfg_showBootOptions
    property bool cfg_showBootOptionsDefault
    
    property bool cfg_prefixDateShowClock
    property bool cfg_prefixDateShowClockDefault
    property bool cfg_prefixDateShowEvents
    property bool cfg_prefixDateShowEventsDefault
    property bool cfg_prefixPowerShowHibernate
    property bool cfg_prefixPowerShowHibernateDefault
    property bool cfg_prefixPowerShowSleep
    property bool cfg_prefixPowerShowSleepDefault
    
    // Internal state
    property var previewSettings: ({})
    
    // Load settings when config property changes
    onCfg_previewSettingsChanged: {
        try {
            previewSettings = JSON.parse(cfg_previewSettings || '{"images": true, "videos": false, "text": false, "documents": false}')
        } catch (e) {
            previewSettings = {"images": true, "videos": false, "text": false, "documents": false}
        }
    }
    
    Component.onCompleted: {
        try {
            previewSettings = JSON.parse(cfg_previewSettings || '{"images": true, "videos": false, "text": false, "documents": false}')
        } catch (e) {
            previewSettings = {"images": true, "videos": false, "text": false, "documents": false}
        }
    }
    
    function saveSettings() {
        cfg_previewSettings = JSON.stringify(previewSettings)
    }
    
    function updateSetting(key, value) {
        var newSettings = Object.assign({}, previewSettings)
        newSettings[key] = value
        previewSettings = newSettings
        saveSettings()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // Header
        Label {
            text: i18n("Preview Settings")
            font.bold: true
            font.pixelSize: 16
        }
        
        Label {
            text: i18n("Enable or disable file previews for different file types.")
            opacity: 0.7
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // Master Preview Toggle
        GroupBox {
            title: i18n("Enable File Previews")
            Layout.fillWidth: true
            
            RowLayout {
                anchors.fill: parent
                spacing: 10
                
                Switch {
                    id: masterPreviewSwitch
                    checked: configPreview.cfg_previewEnabled
                    onToggled: configPreview.cfg_previewEnabled = checked
                }
                
                Label {
                    text: masterPreviewSwitch.checked ? i18n("Enabled") : i18n("Disabled")
                    opacity: 0.7
                }
            }
        }
        
        // Preview Types
        GroupBox {
            title: i18n("Preview Types")
            Layout.fillWidth: true
            enabled: masterPreviewSwitch.checked
            opacity: enabled ? 1.0 : 0.5
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 12
                
                // Images
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Kirigami.Icon {
                        source: "image-x-generic"
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: i18n("Images")
                            font.bold: true
                        }
                        Label {
                            text: "PNG, JPG, GIF, WEBP, SVG, BMP"
                            font.pixelSize: 10
                            opacity: 0.6
                        }
                    }
                    
                    Switch {
                        checked: previewSettings.images || false
                        onToggled: updateSetting("images", checked)
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                }
                
                // Videos
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Kirigami.Icon {
                        source: "video-x-generic"
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: i18n("Videos")
                            font.bold: true
                        }
                        Label {
                            text: "MP4, MKV, AVI, WEBM, MOV"
                            font.pixelSize: 10
                            opacity: 0.6
                        }
                    }
                    
                    Switch {
                        checked: previewSettings.videos || false
                        onToggled: updateSetting("videos", checked)
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                }
                
                // Text Files
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Kirigami.Icon {
                        source: "text-x-generic"
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: i18n("Text Files")
                            font.bold: true
                        }
                        Label {
                            text: "TXT, MD, JSON, XML, LOG"
                            font.pixelSize: 10
                            opacity: 0.6
                        }
                    }
                    
                    Switch {
                        checked: previewSettings.text || false
                        onToggled: updateSetting("text", checked)
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                }
                
                // Documents
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Kirigami.Icon {
                        source: "x-office-document"
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: i18n("Documents")
                            font.bold: true
                        }
                        Label {
                            text: "PDF, ODT, DOCX (Icon only)"
                            font.pixelSize: 10
                            opacity: 0.6
                        }
                    }
                    
                    Switch {
                        checked: previewSettings.documents || false
                        onToggled: updateSetting("documents", checked)
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // Info box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: infoColumn.implicitHeight + 16
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1)
            radius: 8
            
            ColumnLayout {
                id: infoColumn
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                
                Label {
                    text: "ℹ️ " + i18n("Performance Information")
                    font.bold: true
                }
                
                Label {
                    text: i18n("Video and document previews may increase memory usage.")
                    opacity: 0.8
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
