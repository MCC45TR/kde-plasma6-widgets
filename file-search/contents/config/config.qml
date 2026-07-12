import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Panel")
        icon: "dashboard-show"
        source: "config/ConfigPanel.qml"
    }
    ConfigCategory {
        name: i18n("Popup")
        icon: "window-new"
        source: "config/ConfigPopup.qml"
    }
    ConfigCategory {
        name: i18n("Preview")
        icon: "view-preview"
        source: "config/ConfigPreview.qml"
    }
    ConfigCategory {
        name: i18n("Prefixes")
        icon: "code-context"
        source: "config/ConfigPrefixes.qml"
    }
    ConfigCategory {
        name: i18n("Search")
        icon: "search"
        source: "config/ConfigCategories.qml"
    }

    ConfigCategory {
        name: i18n("RSS")
        icon: "news-subscribe"
        source: "config/ConfigRSS.qml"
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
