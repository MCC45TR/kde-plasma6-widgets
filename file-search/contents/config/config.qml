import QtQuick
import org.kde.plasma.configuration

import "../ui/js/localization.js" as LocalizationData

ConfigModel {
    
    // Localization Logic
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

    ConfigCategory {
        name: tr("config_appearance")
        icon: "preferences-desktop-display"
        source: "../ui/config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: tr("config_search")
        icon: "preferences-system-search"
        source: "../ui/config/ConfigSearch.qml"
    }
    ConfigCategory {
        name: tr("config_categories")
        icon: "view-list-icons"
        source: "../ui/config/ConfigCategories.qml"
    }
    ConfigCategory {
        name: tr("config_debug")
        icon: "tools-report-bug"
        source: "../ui/config/ConfigDebug.qml"
    }
    ConfigCategory {
        name: tr("config_help")
        icon: "help-contents"
        source: "../ui/config/ConfigHelp.qml"
    }
}
