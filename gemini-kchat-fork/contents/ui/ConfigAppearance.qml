import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_apiKey: apiKeyField.text
    property string cfg_selectedModel
    
    Kirigami.FormLayout {

        QQC2.TextField {
            id: apiKeyField
            Kirigami.FormData.label: i18nc("@label", "Google AI Studio API Key:")
            placeholderText: i18nc("@info:placeholder", "Enter your API key here...")
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: modelComboBox
            Kirigami.FormData.label: i18nc("@label", "Gemini Model:")
            Layout.fillWidth: true
            
            property var modelOptions: [
                "gemini-2.5-flash",
                "gemini-2.5-pro", 
                "gemini-2.5-flash-lite",
                "gemini-2.0-flash",
                "gemini-2.0-flash-lite"
            ]
            
            property var modelLabels: [
                i18nc("@item:inlistbox", "Gemini 2.5 Flash (Recommended)"),
                i18nc("@item:inlistbox", "Gemini 2.5 Pro"),
                i18nc("@item:inlistbox", "Gemini 2.5 Flash-Lite"),
                i18nc("@item:inlistbox", "Gemini 2.0 Flash"),
                i18nc("@item:inlistbox", "Gemini 2.0 Flash-Lite")
            ]
            
            model: modelLabels
            
            currentIndex: {
                var index = modelOptions.indexOf(cfg_selectedModel);
                return index >= 0 ? index : 0;
            }
            
            onActivated: {
                if (currentIndex >= 0 && currentIndex < modelOptions.length) {
                    cfg_selectedModel = modelOptions[currentIndex];
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: {
                var descriptions = [
                    i18nc("@info", "Best balance of speed and performance"),
                    i18nc("@info", "Most advanced model with enhanced reasoning"),
                    i18nc("@info", "Ultra-fast model optimized for cost-efficiency"),
                    i18nc("@info", "Previous generation workhorse model"),
                    i18nc("@info", "Previous generation lightweight model")
                ];
                return modelComboBox.currentIndex >= 0 && modelComboBox.currentIndex < descriptions.length 
                    ? descriptions[modelComboBox.currentIndex] 
                    : "";
            }
            visible: text.length > 0
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18nc("@info", "Get your free API key from Google AI Studio")
            actions: [
                Kirigami.Action {
                    text: i18nc("@action:button", "Open Google AI Studio")
                    icon.name: "internet-services"
                    onTriggered: Qt.openUrlExternally("https://makersuite.google.com/app/apikey")
                }
            ]
        }
    }
}
