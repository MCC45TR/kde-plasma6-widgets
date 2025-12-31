import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_selectedModel: modelComboBox.currentText
    // We can add panel icon config if we map it to something. 
    // Plasma widgets usually use specific property or metadata. Main icon is in metadata.
    // Changing metadata icon at runtime is hard, but we can change the wrapper icon in CompactRepresentation.
    
    Kirigami.FormLayout {

        QQC2.TextField {
            id: apiKeyField
            Kirigami.FormData.label: "Google AI Studio API Key:"
            placeholderText: "Enter your API key..."
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: modelComboBox
            Kirigami.FormData.label: "Select Model:"
            Layout.fillWidth: true
            
            textRole: "text"
            valueRole: "value"
            
            model: [
                { text: "Gemini 2.0 Flash (New)", value: "gemini-2.0-flash-exp", description: "Hız + Zeka Dengesi (Dinamik müşteri hizmetleri, gerçek zamanlı veri analizi)." },
                { text: "Gemini 1.5 Pro", value: "gemini-1.5-pro", description: "Geniş Bağlam (2M+ Token) (Büyük döküman analizleri, tüm codebase'i anlama)." },
                { text: "Gemini 1.5 Flash", value: "gemini-1.5-flash", description: "Düşük Maliyet & Kararlılık (Form işleme, özetleme, sınıflandırma)." },
                { text: "Gemini 1.0 Pro", value: "gemini-1.0-pro", description: "Dengeli ve hızlı, genel kullanım için ideal." },
                { text: "Gemma 2 (Geliştirici)", value: "gemma-2-9b-it", description: "Açık Kaynak / Hafif (Yerel denemeler ve cihaz üstü çözümler)." }
            ]
            
            // Map current text to index
            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === cfg_selectedModel) {
                        currentIndex = i;
                        break;
                    }
                }
            }
            
            onActivated: {
                cfg_selectedModel = model[currentIndex].value
            }
        }
        
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: modelComboBox.model[modelComboBox.currentIndex] ? modelComboBox.model[modelComboBox.currentIndex].description : ""
            visible: true
        }
        
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: "Get your free API key from Google AI Studio (aistudio.google.com)"
            actions: [
                Kirigami.Action {
                    text: "Get Keys"
                    icon.name: "internet-services"
                    onTriggered: Qt.openUrlExternally("https://aistudio.google.com/app/apikey")
                }
            ]
        }
    }
}
