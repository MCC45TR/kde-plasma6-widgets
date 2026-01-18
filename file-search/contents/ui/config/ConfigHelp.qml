import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

    // Localization removed
    // Use standard i18n()
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Keyboard Shortcuts")
    }
    
    Label {
        text: "• ↑↓←→ - " + i18n("Navigate between results")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Tab / Shift+Tab - " + i18n("Navigate between sections")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Ctrl+1 / Ctrl+2 - " + i18n("List / Tile view")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Ctrl+Space - " + i18n("Toggle file preview")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Enter - " + i18n("Open selected item")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Esc - " + i18n("Close widget")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Search Prefixes")
    }
    
    Label {
        text: "• timeline:/today - " + i18n("List files modified today")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• gg:arama - " + i18n("Search on Google")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• dd:arama - " + i18n("Search on DuckDuckGo")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• kill uygulama - " + i18n("Terminate processes")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• spell kelime - " + i18n("Check spelling")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("User Profiles")
    }
    
    Label {
        text: "• Minimal - " + i18n("A simplified interface with essential features.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Developer - " + i18n("Debug tab active, developer features enabled.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Power User - " + i18n("All features active, advanced settings available.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
