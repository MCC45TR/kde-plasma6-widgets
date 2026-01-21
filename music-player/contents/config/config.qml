import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Genel"
        icon: "multimedia-player"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-appearance"
        source: "config/ConfigAppearance.qml"
    }
}
