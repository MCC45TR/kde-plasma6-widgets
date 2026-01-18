import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configSearch
    
    property string title: i18n("Search")
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Search Settings")
    }
    
    // Preview Toggle
    Switch {
        id: previewToggle
        Kirigami.FormData.label: i18n("Enable File Previews")
        checked: true
    }
    
    Label {
        text: i18n("Show file previews on hover (can also be triggered with Ctrl+Space)")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.7
        font.pixelSize: 11
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Search Behavior")
    }
    
    Label {
        text: i18n("You can use the following KRunner commands and prefixes:")
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
            text: i18n("Prefix") 
            font.bold: true 
            color: Kirigami.Theme.highlightColor
        }
        Label { 
            text: i18n("Description")
            font.bold: true 
            color: Kirigami.Theme.highlightColor
        }

        // Items
        Label { text: "timeline:/today" ; font.family: "Monospace" }
        Label { text: i18n("List files modified today") }

        Label { text: "gg: [term]" ; font.family: "Monospace" }
        Label { text: i18n("Search on Google") }

        Label { text: "dd: [term]" ; font.family: "Monospace" }
        Label { text: i18n("Search on DuckDuckGo") }

        Label { text: "kill [pid]" ; font.family: "Monospace" }
        Label { text: i18n("Terminate processes") }

        Label { text: "spell [word]" ; font.family: "Monospace" }
        Label { text: i18n("Check spelling") }

        Label { text: "#[char]" ; font.family: "Monospace" }
        Label { text: i18n("Search Unicode characters") }
    }
}
