import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
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
            Kirigami.FormData.label: "Persona & Behavior"
            Kirigami.FormData.isSection: true
        }

        QQC2.TextArea {
            id: personaField
            Kirigami.FormData.label: "System Instruction:"
            placeholderText: "e.g., You are a helpful assistant who speaks like a pirate..."
            Layout.fillWidth: true
            Layout.minimumHeight: 100
        }
        
        QQC2.CheckBox {
            id: jsonModeCheck
            text: "Enable JSON Mode (Force structured output)"
            checked: cfg_jsonMode
            onToggled: cfg_jsonMode = checked
            Kirigami.FormData.label: "Output Format:"
        }
        
        Kirigami.Separator {
            Kirigami.FormData.label: "Safety Settings"
            Kirigami.FormData.isSection: true
        }
        
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: "Adjust safety thresholds. 'None' means minimal filtering."
        }

        // Harassment
        QQC2.ComboBox {
            Kirigami.FormData.label: "Harassment:"
            model: ["None", "Few", "Some", "Most"]
            currentIndex: cfg_safetyHarassment
            onActivated: cfg_safetyHarassment = currentIndex
        }
        
        // Hate Speech
        QQC2.ComboBox {
            Kirigami.FormData.label: "Hate Speech:"
            model: ["None", "Few", "Some", "Most"]
            currentIndex: cfg_safetyHateSpeech
            onActivated: cfg_safetyHateSpeech = currentIndex
        }
        
        // Sexual Content
        QQC2.ComboBox {
            Kirigami.FormData.label: "Sexual Content:"
            model: ["None", "Few", "Some", "Most"]
            currentIndex: cfg_safetySexual
            onActivated: cfg_safetySexual = currentIndex
        }
        
        // Dangerous Content
        QQC2.ComboBox {
            Kirigami.FormData.label: "Dangerous Content:"
            model: ["None", "Few", "Some", "Most"]
            currentIndex: cfg_safetyDangerous
            onActivated: cfg_safetyDangerous = currentIndex
        }
    }
}
