import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configSearch
    
    property string title: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search")
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Settings")
    }
    
    // Preview Toggle
    Switch {
        id: previewToggle
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Enable File Previews")
        checked: true
    }
    
    Label {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show file previews on hover (can also be triggered with Ctrl+Space)")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.7
        font.pixelSize: 11
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Behavior")
    }
    
    Label {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "You can use the following KRunner commands and prefixes:")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.8
    }

    GridLayout {
        columns: 2
        rowSpacing: 5
        columnSpacing: 10
        Layout.fillWidth: true

        // Header
        Label { 
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Prefix") 
            font.bold: true 
            color: Kirigami.Theme.highlightColor
        }
        Label { 
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Description")
            font.bold: true 
            color: Kirigami.Theme.highlightColor
        }

        // Items
        Label { text: "timeline:/today" ; font.family: "Monospace" }
        Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "List files modified today") }

        Label { text: "gg: [term]" ; font.family: "Monospace" }
        Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on Google") }

        Label { text: "dd: [term]" ; font.family: "Monospace" }
        Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on DuckDuckGo") }

        Label { text: "kill [pid]" ; font.family: "Monospace" }
        Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Terminate processes") }

        Label { text: "spell [word]" ; font.family: "Monospace" }
        Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Check spelling") }

        Label { text: "#[char]" ; font.family: "Monospace" }
        Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Unicode characters") }
    }
}
