import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as IconThemes
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
    
    property alias cfg_selectedModel: modelComboBox.value
    // We can add panel icon config if we map it to something. 
    // Plasma widgets usually use specific property or metadata. Main icon is in metadata.
    // Changing metadata icon at runtime is hard, but we can change the wrapper icon in CompactRepresentation.
    
    property alias cfg_panelIcon: iconButton.iconName
    
    IconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: iconButton.iconName = iconName
    }

    Kirigami.FormLayout {

        QQC2.Button {
            id: iconButton
            Kirigami.FormData.label: root.tr("config_launcher_icon")
            
            property string iconName: "internet-chat"
            
            text: iconName
            icon.name: iconName || "internet-chat"
            
            onClicked: iconMenu.open()
            
            QQC2.Menu {
                id: iconMenu
                
                QQC2.MenuItem {
                    text: root.tr("config_choose")
                    icon.name: "document-open-folder"
                    onTriggered: iconDialog.open()
                }
                
                QQC2.MenuItem {
                    text: root.tr("config_reset_icon")
                    icon.name: "edit-undo"
                    onTriggered: iconButton.iconName = "internet-chat"
                }
                
                QQC2.MenuItem {
                    text: root.tr("config_remove_icon")
                    icon.name: "edit-delete"
                    onTriggered: iconButton.iconName = ""
                }
            }
        }

        QQC2.ComboBox {
            id: modelComboBox
            Kirigami.FormData.label: root.tr("config_select_model")
            Layout.fillWidth: true
            
            textRole: "text"
            valueRole: "value"
            
            // Custom property for KConfig binding (alias target)
            property string value
            
            model: [
                { text: "Gemini 2.0 Flash (New)", value: "gemini-2.0-flash-exp", description: "Hız + Zeka Dengesi (Dinamik müşteri hizmetleri, gerçek zamanlı veri analizi)." },
                { text: "Gemini 1.5 Pro", value: "gemini-1.5-pro", description: "Geniş Bağlam (2M+ Token) (Büyük döküman analizleri, tüm codebase'i anlama)." },
                { text: "Gemini 1.5 Flash", value: "gemini-1.5-flash", description: "Düşük Maliyet & Kararlılık (Form işleme, özetleme, sınıflandırma)." },
                { text: "Gemini 1.0 Pro", value: "gemini-1.0-pro", description: "Dengeli ve hızlı, genel kullanım için ideal." },
                { text: "Gemma 2 (Geliştirici)", value: "gemma-2-9b-it", description: "Açık Kaynak / Hafif (Yerel denemeler ve cihaz üstü çözümler)." }
            ]
            
            // When KConfig writes to 'value', update selection
            onValueChanged: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === value) {
                        currentIndex = i;
                        break;
                    }
                }
            }
            
            // When user selects, update 'value' (which updates KConfig)
            onActivated: {
                value = model[currentIndex].value
            }
        }
        
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: modelComboBox.model[modelComboBox.currentIndex] ? modelComboBox.model[modelComboBox.currentIndex].description : ""
            visible: true
        }
    }
}
