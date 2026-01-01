import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Görünüm"
        icon: "preferences-desktop-display"
        source: "../ui/config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: "Arama"
        icon: "preferences-system-search"
        source: "../ui/config/ConfigSearch.qml"
    }
    ConfigCategory {
        name: "Debug"
        icon: "tools-report-bug"
        source: "../ui/config/ConfigDebug.qml"
    }
    ConfigCategory {
        name: "Kılavuz"
        icon: "help-contents"
        source: "../ui/config/ConfigHelp.qml"
    }
}
