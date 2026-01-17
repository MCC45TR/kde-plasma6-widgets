import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../js/localization.js" as LocalizationData

Kirigami.FormLayout {
    id: debugPage
    
    property alias cfg_debugOverlay: debugOverlayToggle.checked
    property int cfg_userProfile: 0
    property int cfg_displayMode: 1
    property int cfg_viewMode: 0
    property int cfg_iconSize: 48
    property int cfg_listIconSize: 22
    property bool cfg_previewEnabled: true
    property string cfg_searchHistory: ""
    
    // Localization
    property var locales: LocalizationData.data
    property string currentLocale: Qt.locale().name.split("_")[0]
    
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) {
            return locales[currentLocale][key]
        }
        if (locales["en"] && locales["en"][key]) {
            return locales["en"][key]
        }
        return key
    }
    
    // Warning if not in Developer mode
    Label {
        visible: cfg_userProfile !== 1
        text: "⚠️ " + (tr("debug_warning") || "Bu sekme sadece Developer modunda aktif olur. Görünüm sekmesinden profili değiştirin.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        color: Kirigami.Theme.negativeTextColor
        font.bold: true
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("debug_settings") || "Debug Ayarları"
    }
    
    // Debug Overlay Toggle
    Switch {
        id: debugOverlayToggle
        Kirigami.FormData.label: tr("debug_overlay") || "Debug Overlay"
        checked: false
        enabled: cfg_userProfile === 1
    }
    
    Label {
        text: tr("debug_overlay_desc") || "Widget üzerinde debug bilgilerini göster (aktif mod, öğe sayısı, index kaynağı)"
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.7
        font.pixelSize: 11
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("debug_data") || "Debug Verileri"
    }
    
    // Debug Data Display
    GridLayout {
        columns: 2
        rowSpacing: 6
        columnSpacing: 12
        Layout.fillWidth: true
        
        Label { text: tr("timestamp") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: new Date().toISOString(); font.family: "Monospace" }
        
        Label { text: tr("locale") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: debugPage.currentLocale; font.family: "Monospace" }
        
        Label { text: tr("user_profile") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: cfg_userProfile === 0 ? "Minimal (0)" : (cfg_userProfile === 1 ? "Developer (1)" : "Power User (2)")
            font.family: "Monospace" 
        }
        
        Label { text: tr("display_mode") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: cfg_displayMode === 0 ? "Button (0)" : (cfg_displayMode === 1 ? "Medium (1)" : (cfg_displayMode === 2 ? "Wide (2)" : "Extra Wide (3)"))
            font.family: "Monospace" 
        }
        
        Label { text: tr("view_mode") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: cfg_viewMode === 0 ? "List (0)" : "Tile (1)"
            font.family: "Monospace" 
        }
        
        Label { text: tr("tile_icon_size") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: cfg_iconSize + " px"; font.family: "Monospace" }
        
        Label { text: tr("list_icon_size") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: cfg_listIconSize + " px"; font.family: "Monospace" }
        
        Label { text: tr("enable_preview") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: cfg_previewEnabled ? "true" : "false"; font.family: "Monospace" }
        
        Label { text: tr("debug_overlay") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { text: cfg_debugOverlay ? "true" : "false"; font.family: "Monospace" }
        
        Label { text: tr("history_count") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            id: historyCountLabel
            text: {
                try {
                    var hist = JSON.parse(cfg_searchHistory || "[]")
                    return hist.length + " " + tr("items")
                } catch(e) {
                    return "Error: " + e.message
                }
            }
            font.family: "Monospace" 
        }
        Label { text: tr("telemetry") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.columnSpan: 2 }
        
        Label { text: tr("total_searches") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: {
                try {
                    var stats = JSON.parse(Plasmoid.configuration.telemetryData || "{}")
                    return (stats.totalSearches || 0)
                } catch(e) { return "0" }
            }
            font.family: "Monospace" 
        }
        
        Label { text: tr("avg_latency") + ":"; font.bold: true; color: Kirigami.Theme.highlightColor }
        Label { 
            text: {
                try {
                    var stats = JSON.parse(Plasmoid.configuration.telemetryData || "{}")
                    return (stats.averageLatency || 0) + " ms"
                } catch(e) { return "0 ms" }
            }
            font.family: "Monospace" 
        }
        
        // Reset Stats Button
        Button {
            text: tr("reset_stats") || "İstatistikleri Sıfırla"
            icon.name: "edit-clear-all"
            Layout.columnSpan: 2
            Layout.topMargin: 8
            enabled: cfg_userProfile === 1
            
            onClicked: {
                Plasmoid.configuration.telemetryData = JSON.stringify({
                    totalSearches: 0,
                    averageLatency: 0,
                    totalLatencySum: 0,
                    lastReset: new Date().toISOString(),
                    backend: "Milou/KRunner"
                })
            }
        }
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("history_sample") || "Geçmiş Örnekleri"
    }
    
    // Privacy Notice
    Kirigami.InlineMessage {
        Layout.fillWidth: true
        type: Kirigami.MessageType.Information
        text: tr("telemetry_privacy_notice") || "Gizlilik Bildirimi: Toplanan tüm debug ve telemetri verileri SADECE yerel olarak saklanır (~/.config/plasma-org.kde.plasma.desktop-appletsrc). İnternete hiçbir veri gönderilmez."
        visible: true
    }
    
    // History Sample
    ColumnLayout {
        Layout.fillWidth: true
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
            text: tr("no_history") || "Geçmiş boş"
            opacity: 0.5
            font.italic: true
        }
    }
}
