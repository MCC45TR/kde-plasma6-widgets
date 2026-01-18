import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configHelp
    
    property string title: i18n("Help")
    
    // Define all config properties to avoid "Setting initial properties failed" warnings
    property int cfg_displayMode: 1
    property int cfg_displayModeDefault: 1
    property int cfg_viewMode: 0
    property int cfg_viewModeDefault: 0
    property int cfg_iconSize: 48
    property int cfg_iconSizeDefault: 48
    property int cfg_listIconSize: 22
    property int cfg_listIconSizeDefault: 22
    property int cfg_userProfile: 0
    property int cfg_userProfileDefault: 0
    property bool cfg_previewEnabled: true
    property bool cfg_previewEnabledDefault: true
    property string cfg_previewSettings: "{}"
    property string cfg_previewSettingsDefault: "{}"
    property bool cfg_debugOverlay: false
    property bool cfg_debugOverlayDefault: false
    property string cfg_telemetryData: "{}"
    property string cfg_telemetryDataDefault: "{}"
    property string cfg_searchHistory: ""
    property string cfg_searchHistoryDefault: ""
    property string cfg_pinnedItems: "[]"
    property string cfg_pinnedItemsDefault: "[]"
    property string cfg_categorySettings: "{}"
    property string cfg_categorySettingsDefault: "{}"
    property int cfg_searchAlgorithm: 0
    property int cfg_searchAlgorithmDefault: 0
    property int cfg_minResults: 3
    property int cfg_minResultsDefault: 3
    property int cfg_maxResults: 20
    property int cfg_maxResultsDefault: 20
    property bool cfg_smartResultLimit: true
    property bool cfg_smartResultLimitDefault: true
    property bool cfg_showBootOptions: false
    property bool cfg_showBootOptionsDefault: false
    
    // Missing properties that were causing warnings
    property bool cfg_prefixDateShowClock: true
    property bool cfg_prefixDateShowClockDefault: true
    property bool cfg_prefixDateShowEvents: true
    property bool cfg_prefixDateShowEventsDefault: true
    property bool cfg_prefixPowerShowHibernate: false
    property bool cfg_prefixPowerShowHibernateDefault: false
    property bool cfg_prefixPowerShowSleep: true
    property bool cfg_prefixPowerShowSleepDefault: true
    property bool cfg_showPinnedBar: true
    property bool cfg_showPinnedBarDefault: true
    
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
        text: "• gg:search - " + i18n("Search on Google")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• dd:search - " + i18n("Search on DuckDuckGo")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• kill app - " + i18n("Terminate processes")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• spell word - " + i18n("Check spelling")
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
