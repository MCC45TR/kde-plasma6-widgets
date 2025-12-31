import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General") // ConfigModel usually supports i18n directly from C++ side, but we want our json
        // Actually ConfigModel QML might not support our custom `tr`.
        // Let's stick to i18n for ConfigModel category name as it's part of System Settings usually.
        // But inside ConfigGeneral.qml we can use our JSON.
        name: "General" 
        icon: "preferences-system-search"
        source: "config/ConfigGeneral.qml"
    }
}
