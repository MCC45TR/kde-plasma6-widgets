import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
// localized import removed
import "components" as Components

PlasmoidItem {
    id: root

    // ===== CORE PROPERTIES =====
    property string searchText: ""
    
    // Responsive font size based on height (40% of panel height)
    readonly property int responsiveFontSize: Math.max(10, Math.round(height * 0.4))
    
    // ===== PANEL DETECTION =====
    // Check if widget is in a panel (horizontal or vertical)
    // FormFactor: 0=Planar (Desktop), 1=Horizontal, 2=Vertical, 3=Application
    readonly property bool isInPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || 
                                       Plasmoid.formFactor === PlasmaCore.Types.Vertical
    
    // ===== DISPLAY MODE CONFIGURATION =====
    // 0 = Button, 1 = Medium, 2 = Wide, 3 = Extra Wide
    // If not in panel, force button mode
    readonly property int configDisplayMode: Plasmoid.configuration.displayMode
    readonly property int displayMode: isInPanel ? configDisplayMode : 0
    readonly property bool isButtonMode: displayMode === 0 || !isInPanel
    readonly property bool isMediumMode: isInPanel && displayMode === 1
    readonly property bool isWideMode: isInPanel && displayMode === 2
    readonly property bool isExtraWideMode: isInPanel && displayMode === 3

    // ===== LAYOUT CALCULATIONS =====
    readonly property real textContentWidth: isButtonMode ? 0 : (textMetrics.width + ((isWideMode || isExtraWideMode) ? (height + 30) : 20))
    readonly property real baseWidth: isButtonMode ? height : (isExtraWideMode ? (height * 6) : ((isWideMode) ? (height * 4) : 70))
    
    Layout.preferredWidth: Math.max(baseWidth, textContentWidth)
    Layout.preferredHeight: 38
    Layout.minimumWidth: 50
    Layout.minimumHeight: 34
    
    // Character limits
    readonly property int maxCharsWide: 65
    readonly property int maxCharsMedium: 35
    readonly property int maxChars: isWideMode ? maxCharsWide : maxCharsMedium
    
    // Truncated text for display
    readonly property string placeholderText: isExtraWideMode ? i18n("Start searching...") : (isWideMode ? i18n("Search...") : i18n("Search"))
    readonly property string rawSearchText: searchText.length > 0 ? searchText : placeholderText
    readonly property string truncatedText: rawSearchText.length > maxChars ? rawSearchText.substring(0, maxChars) + "..." : rawSearchText
    
    TextMetrics {
        id: textMetrics
        font.family: "Roboto Condensed"
        font.pixelSize: root.responsiveFontSize
        text: root.truncatedText
    }
    
    // No background - transparent
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
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
        // trFunc removed
    }
    
    // ===== LOCALIZATION =====
    // Localization removed
    // Use standard i18n()
    
    // ===== CONTEXTUAL ACTIONS (Right-Click Menu) =====
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Button Mode (Icon only)")
            checkable: true
            checked: root.displayMode === 0
            onTriggered: Plasmoid.configuration.displayMode = 0
        },
        PlasmaCore.Action {
            text: i18n("Medium Mode (Button only)")
            checkable: true
            checked: root.displayMode === 1
            onTriggered: Plasmoid.configuration.displayMode = 1
        },
        PlasmaCore.Action {
            text: i18n("Wide Mode (Search bar + icon)")
            checkable: true
            checked: root.displayMode === 2
            onTriggered: Plasmoid.configuration.displayMode = 2
        },
        PlasmaCore.Action {
            text: i18n("Extra Wide Mode (Wide + Long Placeholder)")
            checkable: true
            checked: root.displayMode === 3
            onTriggered: Plasmoid.configuration.displayMode = 3
        }
    ]

    // ===== COMPACT REPRESENTATION (Panel Widget) =====
    compactRepresentation: Components.CompactView {
        anchors.fill: parent
        
        isButtonMode: root.isButtonMode
        isWideMode: root.isWideMode
        isExtraWideMode: root.isExtraWideMode
        expanded: root.expanded
        truncatedText: root.truncatedText
        responsiveFontSize: root.responsiveFontSize
        bgColor: root.bgColor
        textColor: root.textColor
        accentColor: root.accentColor
        searchTextLength: root.searchText.length
        panelRadius: Plasmoid.configuration.panelRadius
        
        onToggleExpanded: root.expanded = !root.expanded
    }
    
    // ===== FULL REPRESENTATION (Popup) =====
    fullRepresentation: Components.SearchPopup {
        id: popup
        logic: controller
        
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
        
        // trFunc removed
        
        showDebug: Plasmoid.configuration.debugOverlay && Plasmoid.configuration.userProfile === 1
        showBootOptions: Plasmoid.configuration.showBootOptions
        showPinnedBar: Plasmoid.configuration.showPinnedBar
        previewEnabled: Plasmoid.configuration.previewEnabled
        previewSettings: {
            try {
                return JSON.parse(Plasmoid.configuration.previewSettings || '{"images": true, "videos": false, "text": false, "documents": false}')
            } catch (e) {
                return {"images": true, "videos": false, "text": false, "documents": false}
            }
        }

        // Signal handlers
        onRequestSearchTextUpdate: (text) => root.searchText = text
        onRequestExpandChange: (exp) => root.expanded = exp
        onRequestViewModeChange: (mode) => Plasmoid.configuration.viewMode = mode
    }
}
