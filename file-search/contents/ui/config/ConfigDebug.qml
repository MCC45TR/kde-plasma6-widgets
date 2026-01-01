import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../localization.js" as LocalizationData

Kirigami.FormLayout {
    id: debugPage
    
    property alias cfg_debugOverlay: debugOverlayToggle.checked
    property int cfg_userProfile: 0
    
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
        Kirigami.FormData.label: tr("debug_actions") || "Debug İşlemleri"
    }
    
    // Dump Debug Data Button
    Button {
        text: tr("dump_debug") || "Debug Verilerini Kaydet"
        icon.name: "document-save"
        enabled: cfg_userProfile === 1
        
        onClicked: {
            var debugData = {
                timestamp: new Date().toISOString(),
                profile: cfg_userProfile,
                debugOverlay: cfg_debugOverlay,
                locale: debugPage.currentLocale
            }
            
            var content = JSON.stringify(debugData, null, 2)
            console.log("Debug dump:", content)
            
            // Note: Actual file writing requires C++ backend
            // For now, log to console
        }
    }
    
    Label {
        text: tr("dump_debug_desc") || "Debug verilerini $HOME dizinine kaydeder"
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.6
        font.pixelSize: 11
    }
}
