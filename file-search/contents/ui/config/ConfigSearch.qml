import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../localization.js" as LocalizationData

Kirigami.FormLayout {
    id: searchPage
    
    property alias cfg_previewEnabled: previewToggle.checked
    
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
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("search_settings") || "Arama Ayarları"
    }
    
    // Preview Toggle
    Switch {
        id: previewToggle
        Kirigami.FormData.label: tr("enable_preview") || "Dosya Önizlemesi"
        checked: true
    }
    
    Label {
        text: tr("preview_description") || "Hover ile dosya bilgisi göster (Ctrl+Space ile de tetiklenebilir)"
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.7
        font.pixelSize: 11
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("search_behavior") || "Arama Davranışı"
    }
    
    Label {
        text: tr("search_info") || "Arama sonuçları Milou/KRunner tarafından sağlanmaktadır. Desteklenen prefix'ler: timeline:, gg:, dd:, kill, spell"
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.6
        font.pixelSize: 11
    }
}
