import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "components" as Components
import "components/WeatherService.js" as WeatherService

PlasmoidItem {
    id: root

    // Match Plasma's configured interface font. A bundled condensed font made
    // the panel label and application names look noticeably smaller than
    // Kickoff, even at the same pixel size.
    readonly property string uiFontFamily: Kirigami.Theme.defaultFont.family

    // ===== CORE PROPERTIES =====
    property string searchText: ""
    property alias logic: controller

    // Keep panel text at least as large as the desktop's normal UI text while
    // still scaling gently with taller panels.
    readonly property int responsiveFontSize: Math.max(Kirigami.Theme.defaultFont.pixelSize, Math.round(height * 0.38))
    
    // ===== PANEL DETECTION =====
    // Check if widget is in a panel (horizontal or vertical)
    // FormFactor: 0=Planar (Desktop), 1=Horizontal, 2=Vertical, 3=Application
    readonly property bool isInPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || 
                                       Plasmoid.formFactor === PlasmaCore.Types.Vertical
    
    // ===== DISPLAY MODE CONFIGURATION =====
    // 0 = Button, 1 = Medium, 2 = Wide, 3 = Extra Wide
    // If not in panel, force button mode
    readonly property int configDisplayMode: Plasmoid.configuration.displayMode
    // Legacy values 1..4 all map to the single text-input representation.
    readonly property int displayMode: isInPanel ? (configDisplayMode === 0 ? 0 : 2) : 0
    readonly property bool isButtonMode: displayMode === 0 || !isInPanel
    readonly property bool isMediumMode: false
    readonly property bool isWideMode: isInPanel && displayMode === 2
    readonly property bool isExtraWideMode: false
    readonly property bool isUltraWideMode: false

    readonly property int legacyPanelWidthStep: configDisplayMode === 1 ? 0
        : (configDisplayMode === 2 ? 4 : (configDisplayMode === 3 ? 7 : 12))
    readonly property int panelWidthStep: Plasmoid.configuration.panelWidthStep >= 0
        ? Math.max(0, Math.min(12, Plasmoid.configuration.panelWidthStep))
        : legacyPanelWidthStep
    readonly property real panelContentOpacity: {
        var level = Plasmoid.configuration.panelContentOpacity
        return level === 0 ? 0.45 : (level === 1 ? 0.7 : 1.0)
    }

    // ===== LAYOUT CALCULATIONS =====
    readonly property real textContentWidth: isButtonMode ? 0 : (textMetrics.width + ((isWideMode || isExtraWideMode || isUltraWideMode) ? (height + 30) : 20))
    readonly property real minimumPanelWidth: 70
    readonly property real maximumPanelWidth: height * 9
    readonly property real steppedPanelWidth: minimumPanelWidth
        + (maximumPanelWidth - minimumPanelWidth) * panelWidthStep / 12
    readonly property real baseWidth: isButtonMode ? height : steppedPanelWidth
    
    Layout.preferredWidth: baseWidth
    Layout.preferredHeight: Plasmoid.configuration.panelHeight > 0 ? Plasmoid.configuration.panelHeight : 38
    Layout.minimumWidth: 50
    Layout.minimumHeight: Plasmoid.configuration.panelHeight > 0 ? Plasmoid.configuration.panelHeight : 34
    
    // Character limits
    readonly property int maxCharsWide: 65
    readonly property int maxCharsMedium: 35
    readonly property int maxCharsUltra: 110
    readonly property int maxChars: Math.round(maxCharsMedium + (maxCharsUltra - maxCharsMedium) * panelWidthStep / 12)
    
    // Truncated text for display
    readonly property string placeholderText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Start searching...")
    readonly property string rawSearchText: searchText.length > 0 ? searchText : placeholderText
    readonly property string truncatedText: rawSearchText.length > maxChars ? rawSearchText.substring(0, maxChars) + "..." : rawSearchText
    
    TextMetrics {
        id: textMetrics
        font.family: root.uiFontFamily
        font.pixelSize: root.responsiveFontSize
        text: root.truncatedText
    }
    
    TextMetrics {
        id: placeholderMetrics
        font.family: textMetrics.font.family
        font.pixelSize: textMetrics.font.pixelSize
        text: root.placeholderText
    }
    
    readonly property real placeholderContentWidth: isButtonMode ? 0 : (placeholderMetrics.width + ((isWideMode || isExtraWideMode || isUltraWideMode) ? (height + 30) : 20))
    
    // Keep the shell-provided frame disabled. Enabling StandardBackground adds
    // theme margins around our already rounded desktop surface, producing a
    // visible double frame.
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    // Prevent closing when interacting with external dialogs (like auth)
    property bool preventClosing: false
    hideOnWindowDeactivate: !preventClosing
    
    // ===== VIEW MODE CONFIGURATION =====
    readonly property int viewMode: Plasmoid.configuration.viewMode
    readonly property bool isTileView: viewMode === 1
    
    // Icon sizes
    readonly property int iconSize: Math.max(16, Plasmoid.configuration.iconSize || 48)
    readonly property int listIconSize: Math.max(16, Plasmoid.configuration.listIconSize || 22)
    
    // ===== THEME COLORS =====
    readonly property color bgColor: Kirigami.Theme.backgroundColor
    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color accentColor: Kirigami.Theme.highlightColor
    
    // ===== LOGIC CONTROLLER (Non-visual) =====
    Components.LogicController {
        id: controller
        plasmoidConfig: Plasmoid.configuration
    }
    
    // ===== LOCALIZATION =====
    // Localization removed
    // Use standard i18nd("plasma_applet_com.mcc45tr.filesearch", )
    
    // ===== CONTEXTUAL ACTIONS (Right-Click Menu) =====
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Button Mode (Icon only)")
            checkable: true
            checked: root.displayMode === 0
            onTriggered: Plasmoid.configuration.displayMode = 0
        },
        PlasmaCore.Action {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Text Input Mode")
            checkable: true
            checked: !root.isButtonMode
            onTriggered: Plasmoid.configuration.displayMode = 2
        }
    ]

    // ===== COMPACT REPRESENTATION (Panel Widget) =====
    compactRepresentation: Components.CompactView {
        anchors.fill: parent
        
        isButtonMode: root.isButtonMode
        isWideMode: root.isWideMode
        isExtraWideMode: root.isExtraWideMode
        isUltraWideMode: root.isUltraWideMode
        expanded: root.expanded
        truncatedText: root.truncatedText
        responsiveFontSize: root.responsiveFontSize
        fontFamily: root.uiFontFamily
        maxChars: root.maxChars
        bgColor: root.bgColor
        textColor: root.textColor
        accentColor: root.accentColor
        searchTextLength: root.searchText.length
        panelRadius: Plasmoid.configuration.panelRadius
        panelHeight: Plasmoid.configuration.panelHeight
        showSearchButton: Plasmoid.configuration.showSearchButton
        showSearchButtonBackground: Plasmoid.configuration.showSearchButtonBackground
        contentOpacity: root.panelContentOpacity
        
        logic: controller
        rssPlaceholderCycling: Plasmoid.configuration.rssPlaceholderCycling
        rssShowFullHeadline: Plasmoid.configuration.rssShowFullHeadline
        rssShowSource: Plasmoid.configuration.rssShowSource
        rssFrequency: Plasmoid.configuration.rssFrequency
        weatherFrequency: Plasmoid.configuration.weatherFrequency
        
        onToggleExpanded: root.expanded = !root.expanded
    }
    
    // ===== FULL REPRESENTATION (Popup) =====
    fullRepresentation: Components.SearchPopup {
        id: popup
        logic: controller
        plasmoidConfig: Plasmoid.configuration
        
        // Data binding
        searchText: root.searchText
        expanded: root.expanded
        
        displayMode: root.displayMode
        viewMode: root.viewMode
        iconSize: root.iconSize
        listIconSize: root.listIconSize
        
        textColor: root.textColor
        accentColor: root.accentColor
        bgColor: root.bgColor
        // Pass panel status for styling decisions
        isInPanel: root.isInPanel
        
        
        showDebug: Plasmoid.configuration.debugOverlay && Plasmoid.configuration.userProfile === 1
        showBootOptions: Plasmoid.configuration.showBootOptions
        showPinnedBar: Plasmoid.configuration.showPinnedBar
        autoMinimizePinned: Plasmoid.configuration.autoMinimizePinned
        compactTileMode: Plasmoid.configuration.compactPinnedView
        previewEnabled: Plasmoid.configuration.previewEnabled
        previewShowResults: Plasmoid.configuration.previewShowResults !== undefined ? Plasmoid.configuration.previewShowResults : true
        previewShowHistory: Plasmoid.configuration.previewShowHistory !== undefined ? Plasmoid.configuration.previewShowHistory : true
        previewInlineMode: Plasmoid.configuration.previewInlineMode !== undefined ? Plasmoid.configuration.previewInlineMode : 1
        previewSize: Plasmoid.configuration.previewSize !== undefined ? Plasmoid.configuration.previewSize : 1
        previewSettings: {
            try {
                return JSON.parse(Plasmoid.configuration.previewSettings || '{"images": false, "videos": false, "text": false, "documents": false, "applications": false}')
            } catch (e) {
                return {"images": false, "videos": false, "text": false, "documents": false, "applications": false}
            }
        }

        // Signal handlers
        onRequestSearchTextUpdate: (text) => root.searchText = text
        onRequestExpandChange: (exp) => root.expanded = exp
        onRequestViewModeChange: (mode) => Plasmoid.configuration.viewMode = mode
        onRequestPreventClosing: (prevent) => root.preventClosing = prevent
    }

    function refreshWeatherIfDue() {
        var config = Plasmoid.configuration;
        if (!config || !config.weatherEnabled || !controller.weatherCacheLoaded || !controller.weatherCache)
            return;

        var lastUpdate = config.weatherLastUpdate || 0;
        var refreshInterval = config.weatherRefreshInterval !== undefined ? config.weatherRefreshInterval : 15;
        var ageMs = Date.now() - lastUpdate;
        if (ageMs <= refreshInterval * 60 * 1000 && ageMs >= 0)
            return;

        var units = config.weatherUseSystemUnits
            ? (Qt.locale().measurementSystem === Locale.MetricSystem ? "metric" : "imperial")
            : (config.weatherUnits || "metric");
        var provider = config.weatherProvider || "openmeteo";
        // Keyed providers retrieve credentials from KWallet when their view opens.
        if (provider !== "openmeteo")
            return;

        var locationMode = config.weatherLocationMode || "auto";
        var loc = config.weatherLocation || "";
        WeatherService.fetchWeather({
            location: locationMode === "auto" ? "" : loc,
            autoDetect: locationMode === "auto",
            units: units,
            provider: provider,
            apiKey: "",
            apiKey2: "",
            refreshInterval: refreshInterval
        }, function(result) {
            if (!result.success)
                return;
            controller.saveWeatherCache(result);
            if (!result.fromCache)
                config.weatherLastUpdate = Date.now();
            config.weatherUpdateTrigger = (config.weatherUpdateTrigger || 0) + 1;
        });
    }

    Connections {
        target: controller
        function onBackgroundMaintenanceRequested() {
            root.refreshWeatherIfDue();
        }
    }
}
