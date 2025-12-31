import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance") // TR: Görünüş
        icon: "preferences-desktop-appearance"
        source: "../ui/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Persona & Safety")
        icon: "actor-symbolic" // or "preferences-system-security"
        source: "../ui/ConfigPersona.qml"
    }
    ConfigCategory {
        name: i18n("Learn")
        icon: "help-about"
        source: "../ui/ConfigLearn.qml"
    }
}
