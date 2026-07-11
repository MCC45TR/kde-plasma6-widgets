import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-display"
        source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Boot List")
        icon: "view-list-details"
        source: "config/ConfigBootList.qml"
    }
}
