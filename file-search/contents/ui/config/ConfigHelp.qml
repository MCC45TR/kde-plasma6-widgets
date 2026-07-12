import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configHelp

    property int cfg_panelWidthStep
    property int cfg_panelWidthStepDefault
    property int cfg_panelContentOpacity
    property int cfg_panelContentOpacityDefault

    // Weather configuration
    property string cfg_weatherProvider
    property string cfg_weatherProviderDefault
    property string cfg_weatherLocationMode
    property string cfg_weatherLocationModeDefault
    property string cfg_weatherLocation
    property string cfg_weatherLocationDefault
    property string cfg_weatherApiKey
    property string cfg_weatherApiKeyDefault
    property string cfg_weatherApiKey2
    property string cfg_weatherApiKey2Default
    property int cfg_weatherUpdateTrigger
    property int cfg_weatherUpdateTriggerDefault
    // Shared configuration properties
    property bool cfg_showSearchButton
    property bool cfg_showSearchButtonDefault
    property bool cfg_showSearchButtonBackground
    property bool cfg_showSearchButtonBackgroundDefault
    property int cfg_compactPinnedView
    property int cfg_compactPinnedViewDefault
    property int cfg_filterChipStyle
    property int cfg_filterChipStyleDefault
    property bool cfg_previewShowResults
    property bool cfg_previewShowResultsDefault
    property bool cfg_previewShowHistory
    property bool cfg_previewShowHistoryDefault
    property int cfg_previewInlineMode
    property int cfg_previewInlineModeDefault
    property int cfg_previewSize
    property int cfg_previewSizeDefault
    property bool cfg_prefixShellEnabled
    property bool cfg_prefixShellEnabledDefault
    property bool cfg_prefixTimelineEnabled
    property bool cfg_prefixTimelineEnabledDefault
    property bool cfg_prefixWebSearchEnabled
    property bool cfg_prefixWebSearchEnabledDefault
    property bool cfg_prefixKillEnabled
    property bool cfg_prefixKillEnabledDefault
    property bool cfg_prefixSpellEnabled
    property bool cfg_prefixSpellEnabledDefault
    property bool cfg_prefixUnitEnabled
    property bool cfg_prefixUnitEnabledDefault
    property bool cfg_rssEnabled
    property bool cfg_rssEnabledDefault
    property string cfg_rssSources
    property string cfg_rssSourcesDefault
    property int cfg_rssMaxEntries
    property int cfg_rssMaxEntriesDefault
    property int cfg_rssSyncInterval
    property int cfg_rssSyncIntervalDefault
    property string cfg_rssCache
    property string cfg_rssCacheDefault
    property double cfg_rssLastSyncAll
    property double cfg_rssLastSyncAllDefault
    property bool cfg_rssPlaceholderCycling
    property bool cfg_rssPlaceholderCyclingDefault
    property bool cfg_weatherPlaceholderCycling
    property bool cfg_weatherPlaceholderCyclingDefault
    property string cfg_weatherIconPack
    property string cfg_weatherIconPackDefault
    property string cfg_weatherViewMode
    property string cfg_weatherViewModeDefault
    property int cfg_rssFrequency
    property int cfg_rssFrequencyDefault
    property int cfg_weatherFrequency
    property int cfg_weatherFrequencyDefault
    property bool cfg_rssShowImages
    property bool cfg_rssShowImagesDefault
    property bool cfg_rssExpandableCards
    property bool cfg_rssExpandableCardsDefault
    property bool cfg_rssShowSource
    property bool cfg_rssShowSourceDefault
    property bool cfg_rssShowFullHeadline
    property bool cfg_rssShowFullHeadlineDefault
    property var titleDefault
    property int maxHistoryItems
    property int maxHistoryItemsDefault
    
    property string title: i18nd("plasma_applet_com.mcc45tr.filesearch", "Help")
    
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

    // Missing Properties
    property int cfg_panelRadius: 0
    property int cfg_panelRadiusDefault: 0
    property int cfg_panelHeight: 0
    property int cfg_panelHeightDefault: 0
    property int cfg_scrollBarStyle: 0
    property int cfg_scrollBarStyleDefault: 0
    property bool cfg_autoMinimizePinned: false
    property bool cfg_autoMinimizePinnedDefault: false
    property string cfg_cachedBootEntries: ""
    property string cfg_cachedBootEntriesDefault: ""
    property bool cfg_weatherEnabled: true
    property bool cfg_weatherEnabledDefault: true
    property string cfg_weatherUnits: "metric"
    property string cfg_weatherUnitsDefault: "metric"
    property bool cfg_weatherUseSystemUnits: true
    property bool cfg_weatherUseSystemUnitsDefault: true
    property int cfg_weatherRefreshInterval: 15
    property int cfg_weatherRefreshIntervalDefault: 15
    property double cfg_weatherLastUpdate: 0
    property double cfg_weatherLastUpdateDefault: 0
    property string cfg_weatherCache: "{}"
    property string cfg_weatherCacheDefault: "{}"
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Keyboard Shortcuts")
    }
    
    Label {
        text: "• ↑↓←→ - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Navigate between results")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Tab / Shift+Tab - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Navigate between sections")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Ctrl+1 / Ctrl+2 - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "List / Tile view")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Ctrl+Space - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Toggle file preview")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Enter - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Open selected item")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Esc - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Close widget")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Prefixes")
    }
    
    Label {
        text: "• timeline:/today - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "List files modified today")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• gg:search - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on Google")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• dd:search - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on DuckDuckGo")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• kill app - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Terminate processes")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• spell word - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Check spelling")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "User Profiles")
    }
    
    Label {
        text: "• Minimal - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "A simplified interface with essential features.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Developer - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Debug tab active, developer features enabled.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    
    Label {
        text: "• Power User - " + i18nd("plasma_applet_com.mcc45tr.filesearch", "All features active, advanced settings available.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
