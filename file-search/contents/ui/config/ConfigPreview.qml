import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Import localization
import "../js/localization.js" as LocalizationData

Item {
    id: configPreview
    implicitWidth: 600
    implicitHeight: 400
    
    // Localization
    property var locales: LocalizationData.data
    property string currentLocale: Qt.locale().name.substring(0, 2)
    
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) {
            return locales[currentLocale][key]
        }
        if (locales["en"] && locales["en"][key]) {
            return locales["en"][key]
        }
        return key
    }
    
    // KCM Configuration Properties
    property string cfg_previewSettings
    property bool cfg_previewEnabled
    
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
            text: tr("config_preview")
            font.bold: true
            font.pixelSize: 16
        }
        
        Label {
            text: tr("preview_settings_desc")
            opacity: 0.7
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // Master Preview Toggle
        GroupBox {
            title: tr("enable_preview")
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
                    text: masterPreviewSwitch.checked ? tr("preview_enabled") : tr("preview_disabled")
                    opacity: 0.7
                }
            }
        }
        
        // Preview Types
        GroupBox {
            title: tr("preview_types")
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
                            text: tr("preview_images")
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
                            text: tr("preview_videos")
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
                            text: tr("preview_text")
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
                            text: tr("preview_documents")
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
                    text: "ℹ️ " + tr("preview_info_title")
                    font.bold: true
                }
                
                Label {
                    text: tr("preview_info_desc")
                    opacity: 0.8
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
