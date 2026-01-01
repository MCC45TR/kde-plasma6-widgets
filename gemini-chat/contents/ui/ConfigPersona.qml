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

    property alias cfg_systemInstruction: personaField.text
    property bool cfg_jsonMode: false
    // Safety aliases - storing as simple ints (0=BLOCK_NONE to 3=BLOCK_LOW_AND_ABOVE)
    // Default 1 means BLOCK_MEDIUM_AND_ABOVE (standard)
    property int cfg_safetyHarassment: 1 
    property int cfg_safetyHateSpeech: 1
    property int cfg_safetySexual: 1
    property int cfg_safetyDangerous: 1
    
    Kirigami.FormLayout {
        
        Kirigami.Separator {
            Kirigami.FormData.label: root.tr("config_persona_section")
            Kirigami.FormData.isSection: true
        }

        QQC2.TextArea {
            id: personaField
            Kirigami.FormData.label: root.tr("config_system_instruction")
            placeholderText: root.tr("config_persona_placeholder")
            Layout.fillWidth: true
            Layout.minimumHeight: 100
        }
        
        QQC2.CheckBox {
            id: jsonModeCheck
            text: root.tr("config_json_mode")
            checked: cfg_jsonMode
            onToggled: cfg_jsonMode = checked
            Kirigami.FormData.label: root.tr("config_output_format")
        }
        
        Kirigami.Separator {
            Kirigami.FormData.label: root.tr("config_safety_section")
            Kirigami.FormData.isSection: true
        }
        
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: root.tr("config_safety_info")
        }

        // Harassment
        QQC2.ComboBox {
            Kirigami.FormData.label: root.tr("config_safety_harassment")
            model: [root.tr("config_safety_none"), root.tr("config_safety_few"), root.tr("config_safety_some"), root.tr("config_safety_most")]
            currentIndex: cfg_safetyHarassment
            onActivated: cfg_safetyHarassment = currentIndex
        }
        
        // Hate Speech
        QQC2.ComboBox {
            Kirigami.FormData.label: root.tr("config_safety_hate_speech")
            model: [root.tr("config_safety_none"), root.tr("config_safety_few"), root.tr("config_safety_some"), root.tr("config_safety_most")]
            currentIndex: cfg_safetyHateSpeech
            onActivated: cfg_safetyHateSpeech = currentIndex
        }
        
        // Sexual Content
        QQC2.ComboBox {
            Kirigami.FormData.label: root.tr("config_safety_sexual")
            model: [root.tr("config_safety_none"), root.tr("config_safety_few"), root.tr("config_safety_some"), root.tr("config_safety_most")]
            currentIndex: cfg_safetySexual
            onActivated: cfg_safetySexual = currentIndex
        }
        
        // Dangerous Content
        QQC2.ComboBox {
            Kirigami.FormData.label: root.tr("config_safety_dangerous")
            model: [root.tr("config_safety_none"), root.tr("config_safety_few"), root.tr("config_safety_some"), root.tr("config_safety_most")]
            currentIndex: cfg_safetyDangerous
            onActivated: cfg_safetyDangerous = currentIndex
        }
    }
}
