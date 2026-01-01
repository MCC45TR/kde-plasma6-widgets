import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../localization.js" as LocalizationData

Kirigami.FormLayout {
    id: helpPage
    
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
        Kirigami.FormData.label: tr("keyboard_shortcuts") || "Klavye Kısayolları"
    }
    
    Label {
        text: "• ↑↓←→ - " + (tr("help_navigation") || "Sonuçlar arasında gezin")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Tab / Shift+Tab - " + (tr("help_section_nav") || "Bölümler arası geçiş")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Ctrl+1 / Ctrl+2 - " + (tr("help_view_mode") || "Liste / Döşeme görünümü")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Ctrl+Space - " + (tr("help_preview") || "Dosya önizlemesini aç/kapat")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Enter - " + (tr("help_activate") || "Seçili öğeyi aç")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Esc - " + (tr("help_close") || "Widget'ı kapat")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("search_prefixes") || "Arama Prefix'leri"
    }
    
    Label {
        text: "• timeline:/today - " + (tr("hint_timeline_today") || "Bugün değiştirilen dosyalar")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• gg:arama - " + (tr("hint_google") || "Google araması")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• dd:arama - " + (tr("hint_duckduckgo") || "DuckDuckGo araması")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• kill uygulama - " + (tr("hint_kill") || "Uygulamayı sonlandır")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• spell kelime - " + (tr("hint_spell") || "Yazım kontrolü")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("profiles") || "Profiller"
    }
    
    Label {
        text: "• Minimal - " + (tr("profile_minimal_desc") || "Basit arayüz, temel özellikler")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Developer - " + (tr("profile_developer_desc") || "Debug sekmesi açılır, geliştirici özellikleri")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Power User - " + (tr("profile_power_desc") || "Tüm özellikler aktif, gelişmiş ayarlar")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
