import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "localization.js" as Localization

KCM.SimpleKCM {
    id: root
    
    // Localization helper
    property var locales: Localization.data
    property string currentLocale: Qt.locale().name.substring(0, 2)
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) return locales[currentLocale][key]
        if (locales["en"] && locales["en"][key]) return locales["en"][key]
        return key
    }
    
    property alias cfg_apiKey: apiKeyField.text
    
    Kirigami.FormLayout {
        QQC2.TextField {
            id: apiKeyField
            Kirigami.FormData.label: root.tr("config_api_key_label")
            placeholderText: root.tr("config_api_key_placeholder")
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }
        
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: root.tr("config_api_key_info")
        }
        
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: root.tr("config_get_keys_text")
            actions: [
                Kirigami.Action {
                    text: root.tr("config_get_keys_action")
                    icon.name: "internet-services"
                    onTriggered: Qt.openUrlExternally("https://aistudio.google.com/app/apikey")
                }
            ]
        }
    }
}
