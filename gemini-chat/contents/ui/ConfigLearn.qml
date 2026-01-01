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
    
    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        
        // Welcome Header
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Positive
            text: root.tr("guide_welcome")
            visible: true
        }
        
        // Step 1
        Kirigami.Heading {
            level: 4
            text: root.tr("guide_step1_title")
        }
        
        QQC2.Label {
            text: root.tr("guide_step1_desc")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        QQC2.Button {
            text: root.tr("guide_open_aistudio")
            icon.name: "internet-web-browser"
            onClicked: Qt.openUrlExternally("https://aistudio.google.com/apikey")
        }
        
        Kirigami.Separator { Layout.fillWidth: true }
        
        // Step 2
        Kirigami.Heading {
            level: 4
            text: root.tr("guide_step2_title")
        }
        
        QQC2.Label {
            text: root.tr("guide_step2_desc")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        Kirigami.Separator { Layout.fillWidth: true }
        
        // Step 3
        Kirigami.Heading {
            level: 4
            text: root.tr("guide_step3_title")
        }
        
        QQC2.Label {
            text: root.tr("guide_step3_desc")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        Kirigami.Separator { Layout.fillWidth: true }
        
        // Step 4
        Kirigami.Heading {
            level: 4
            text: root.tr("guide_step4_title")
        }
        
        QQC2.Label {
            text: root.tr("guide_step4_desc")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        Kirigami.Separator { Layout.fillWidth: true }
        
        // Notes
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: root.tr("guide_notes")
            visible: true
        }
        
        // Features Section
        Kirigami.Heading {
            level: 4
            text: root.tr("guide_features_title")
            Layout.topMargin: Kirigami.Units.largeSpacing
        }
        
        QQC2.Label {
            text: root.tr("guide_features_text")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // Spacer
        Item { Layout.fillHeight: true }
    }
}
