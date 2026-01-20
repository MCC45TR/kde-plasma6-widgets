import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-display-color"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Search")
        icon: "search"
        source: "config/ConfigCategories.qml"
    }


    ConfigCategory {
        name: i18n("Debug")
        icon: "tools-report-bug"
        source: "config/ConfigDebug.qml"
    }
    ConfigCategory {
        name: i18n("Help")
        icon: "help-hint"
        source: "config/ConfigHelp.qml"
    }
}
