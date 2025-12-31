import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 15
        
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Positive
            text: "Welcome to Gemini KChat Improvements!"
            visible: true
        }

        QQC2.Label {
            text: "<b>Features:</b>"
            font.pixelSize: 16
        }
        
        QQC2.Label {
            text: "1. <b>Math Support:</b> Formulas like $$ E = mc^2 $$ will be formatted as distinct blocks.\n" +
                  "2. <b>Persona & Behavior:</b> Define a custom persona (e.g., 'You are a pirate') in settings.\n" +
                  "3. <b>Safety Settings:</b> Adjust filters for harassment, hate speech, etc.\n" +
                  "4. <b>JSON Mode:</b> Force the model to output valid JSON for structured data tasks.\n" +
                  "5. <b>Multimodal:</b> You can attach images (mock support) to questions.\n" +
                  "6. <b>Localization:</b> Fully translated to Turkish and English."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        QQC2.Label {
            text: "<b>How to use:</b>"
            font.pixelSize: 16
        }
        
        QQC2.Label {
            text: "- <b>Persona:</b> Go to 'Persona & Safety' tab to set system instructions.\n" +
                  "- <b>Safety:</b> Select 'None' to 'Most' to control content filtering.\n" +
                  "- <b>JSON Mode:</b> Enable for API-ready output."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
