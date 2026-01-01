import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../js/localization.js" as LocalizationData

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
        text: tr("search_info") || "Aşağıdaki KRunner komutlarını ve öneklerini (prefix) kullanabilirsiniz:"
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.8
    }

    GridLayout {
        columns: 2
        rowSpacing: 5
        columnSpacing: 10
        Layout.fillWidth: true

        // Header
        Label { 
            text: tr("prefix") 
            font.bold: true 
            color: Kirigami.Theme.highlightColor
        }
        Label { 
            text: tr("description") || "Açıklama"
            font.bold: true 
            color: Kirigami.Theme.highlightColor
        }

        // Items
        Label { text: "timeline:/today" ; font.family: "Monospace" }
        Label { text: tr("prefix_timeline") || "Bugün değiştirilen dosyaları listeler" }

        Label { text: "gg: [term]" ; font.family: "Monospace" }
        Label { text: tr("prefix_google") || "Google üzerinde arama yapar" }

        Label { text: "dd: [term]" ; font.family: "Monospace" }
        Label { text: tr("prefix_ddg") || "DuckDuckGo üzerinde arama yapar" }

        Label { text: "kill [pid]" ; font.family: "Monospace" }
        Label { text: tr("prefix_kill") || "İşlemleri sonlandırır" }

        Label { text: "spell [word]" ; font.family: "Monospace" }
        Label { text: tr("prefix_spell") || "Yazım denetimi yapar" }

        Label { text: "#[char]" ; font.family: "Monospace" }
        Label { text: tr("prefix_unicode") || "Unicode karakter kodlarını arar" }
    }
}
