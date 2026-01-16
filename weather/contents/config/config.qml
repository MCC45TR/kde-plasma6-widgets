import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: "Hava Durumu"
        icon: "weather-clear"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: "Görünüm"
        icon: "preferences-desktop-theme"
        source: "config/ConfigAppearance.qml"
    }
}
