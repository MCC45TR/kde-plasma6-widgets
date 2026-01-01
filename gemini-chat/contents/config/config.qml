import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance") // TR: Görünüş
        icon: "preferences-desktop-appearance"
        source: "../ui/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Account Management")
        icon: "im-user"
        source: "../ui/ConfigAccount.qml"
    }
    ConfigCategory {
        name: i18n("Persona & Safety")
        icon: "actor-symbolic" // or "preferences-system-security"
        source: "../ui/ConfigPersona.qml"
    }
    ConfigCategory {
        name: i18n("Guide")
        icon: "help-about"
        source: "../ui/ConfigLearn.qml"
    }
}
