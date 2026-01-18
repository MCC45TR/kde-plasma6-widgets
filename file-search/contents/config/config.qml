import QtQuick
import org.kde.plasma.configuration

    // Localization removed
    // Use standard i18n()

    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-display"
        source: "../ui/config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Search")
        icon: "preferences-system-search"
        source: "../ui/config/ConfigSearch.qml"
    }
    ConfigCategory {
        name: i18n("Preview")
        icon: "view-preview"
        source: "../ui/config/ConfigPreview.qml"
    }
    ConfigCategory {
        name: i18n("Categories")
        icon: "view-list-icons"
        source: "../ui/config/ConfigCategories.qml"
    }
    ConfigCategory {
        name: i18n("Debug")
        icon: "tools-report-bug"
        source: "../ui/config/ConfigDebug.qml"
    }
    ConfigCategory {
        name: i18n("Help")
        icon: "help-contents"
        source: "../ui/config/ConfigHelp.qml"
    }
}
