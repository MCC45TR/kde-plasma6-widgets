import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.milou as Milou
import "../js/HistoryManager.js" as HistoryManager
import "../js/QueryPolicy.js" as QueryPolicy
import "../js/PrefixRegistry.js" as PrefixRegistry
import "../js/utils.js" as Utils
import org.kde.plasma.plasmoid

Item {
    id: popupRoot

    // Dependencies
    required property var logic
    property var plasmoidConfig // injected from main

    // Properties synced with main
    property string searchText: ""
    property bool expanded: false
    property bool isInPanel: true // Default to true, overridden by Main

    onExpandedChanged: {
        if (expanded) {
            // Force focus when popup opens
            if (isButtonMode) {
                searchBar.focusInput()
            } else {
                hiddenSearchInput.forceActiveFocus()
            }
        } else {
            // Clear search text when popup closes
            requestSearchTextUpdate("")
            searchBar.clear()
            hiddenSearchInput.text = ""
            activeFilter = "All"
            pendingHistoryRun = false
            pendingHistoryMatchId = ""
            pendingHistoryDisplay = ""
        }
    }

    // Configuration
    property int displayMode: 0
    property int viewMode: 0
    property int iconSize: 32
    property int listIconSize: 22

    property color textColor
    property color accentColor
    property color bgColor
    property bool showDebug: false
    property bool showBootOptions: false
    property bool previewEnabled: true
    property bool previewShowResults: true
    property bool previewShowHistory: true
    property int previewInlineMode: 1
    property int previewSize: 1
    property var previewSettings: ({"images": false, "videos": false, "text": false, "documents": false, "applications": false})

    // Prefix Settings
    property bool prefixDateShowClock: true
    property bool prefixDateShowEvents: true
    property bool prefixPowerShowHibernate: false
    property bool prefixPowerShowSleep: true
    property bool showPinnedBar: true
    property bool autoMinimizePinned: false

    // Tile size mode: 0=Normal, 1=All Compact, 2=Only Pinned Compact, 3=Only History Compact
    property int compactTileMode: 0

    // Computed compact properties based on mode
    readonly property bool compactPinnedItems: compactTileMode === 1 || compactTileMode === 2
    readonly property bool compactHistoryItems: compactTileMode === 1 || compactTileMode === 3


    // Signals to Main
    signal requestSearchTextUpdate(string text)
    signal requestExpandChange(bool expanded)
    signal requestViewModeChange(int mode)
    signal requestPreventClosing(bool prevent)

    // Prevent closing logic for popup
    property bool preventClosing: false
    // Plasmoid.hideOnWindowDeactivate assignment removed due to "non-existent property" error

    // Read-only helpers
    readonly property bool isButtonMode: displayMode === 0
    readonly property bool isRssOnlyQuery: searchText.toLowerCase().startsWith("rss:")
    readonly property bool isPrefixMenuOpen: searchText.trim() === ":"
    readonly property bool isTileView: {
        if (searchText.toLowerCase().startsWith("rss:")) return false;
        return plasmoidConfig ? (plasmoidConfig.viewMode === 1) : true
    }

    // ===== CACHED LOCALIZED PREFIXES (computed once at startup) =====
    // These avoid calling i18nd() on every keystroke
    readonly property string _locDate: i18nd("plasma_applet_com.mcc45tr.filesearch", "date").toLowerCase()
    readonly property string _locClock: i18nd("plasma_applet_com.mcc45tr.filesearch", "clock").toLowerCase()
    readonly property string _locWeather: i18nd("plasma_applet_com.mcc45tr.filesearch", "weather").toLowerCase()
    readonly property string _locPower: i18nd("plasma_applet_com.mcc45tr.filesearch", "power").toLowerCase()
    readonly property string _locHelp: i18nd("plasma_applet_com.mcc45tr.filesearch", "help").toLowerCase()
    readonly property string _locUnit: i18nd("plasma_applet_com.mcc45tr.filesearch", "unit").toLowerCase()
    readonly property string _locKill: i18nd("plasma_applet_com.mcc45tr.filesearch", "kill").toLowerCase()
    readonly property string _locSpell: i18nd("plasma_applet_com.mcc45tr.filesearch", "spell").toLowerCase()
    readonly property string _locShell: i18nd("plasma_applet_com.mcc45tr.filesearch", "shell").toLowerCase()
    readonly property string _locCalendar: i18nd("plasma_applet_com.mcc45tr.filesearch", "Calendar").toLowerCase()
    readonly property bool _canShowWeather: plasmoidConfig && plasmoidConfig.weatherEnabled
    readonly property bool _prefixShellEnabled: plasmoidConfig ? (plasmoidConfig.prefixShellEnabled !== undefined ? plasmoidConfig.prefixShellEnabled : true) : true
    readonly property bool _prefixTimelineEnabled: plasmoidConfig ? (plasmoidConfig.prefixTimelineEnabled !== undefined ? plasmoidConfig.prefixTimelineEnabled : true) : true
    readonly property bool _prefixWebSearchEnabled: plasmoidConfig ? (plasmoidConfig.prefixWebSearchEnabled !== undefined ? plasmoidConfig.prefixWebSearchEnabled : true) : true
    readonly property bool _prefixKillEnabled: plasmoidConfig ? (plasmoidConfig.prefixKillEnabled !== undefined ? plasmoidConfig.prefixKillEnabled : true) : true
    readonly property bool _prefixSpellEnabled: plasmoidConfig ? (plasmoidConfig.prefixSpellEnabled !== undefined ? plasmoidConfig.prefixSpellEnabled : true) : true
    readonly property bool _prefixUnitEnabled: plasmoidConfig ? (plasmoidConfig.prefixUnitEnabled !== undefined ? plasmoidConfig.prefixUnitEnabled : true) : true
    readonly property var _localizedPrefixes: ({
        date: _locDate, clock: _locClock, weather: _locWeather,
        power: _locPower, help: _locHelp, unit: _locUnit,
        kill: _locKill, spell: _locSpell, shell: _locShell,
        calendar: _locCalendar
    })
    readonly property var _prefixSettings: ({
        weatherEnabled: _canShowWeather,
        prefixShellEnabled: _prefixShellEnabled,
        prefixTimelineEnabled: _prefixTimelineEnabled,
        prefixWebSearchEnabled: _prefixWebSearchEnabled,
        prefixKillEnabled: _prefixKillEnabled,
        prefixSpellEnabled: _prefixSpellEnabled,
        prefixUnitEnabled: _prefixUnitEnabled
    })

    // ===== CACHED QUERY RESULTS (recomputed once per searchText change) =====
    readonly property string effectiveQuery: _computeEffectiveQuery(searchText)
    readonly property bool isCommandOnly: _computeIsCommandOnly(searchText)
    readonly property bool queryMayHaveHint: {
        var value = searchText.trim();
        return value === ":"
            || value.indexOf(":") !== -1
            || value.startsWith("#")
            || value.toLowerCase().startsWith("spell ")
            || (_locSpell && value.toLowerCase().startsWith(_locSpell + " "));
    }
    readonly property bool hasPrimaryResult: {
        if (tileData.resultCount <= 0)
            return false;
        var category = resultsModel.data(resultsModel.index(0, 0), resultsModel.CategoryRole) || "";
        var decoration = resultsModel.data(resultsModel.index(0, 0), Qt.DecorationRole) || "";
        var matchId = resultsModel.data(resultsModel.index(0, 0), resultsModel.DuplicateRole) || "";
        return Utils.isPrimaryCategory(category, decoration, matchId);
    }

    // Active filter from chips
    property string activeFilter: "All"

    // Layout
    Layout.preferredWidth: 500
    Layout.preferredHeight: 380
    Layout.minimumWidth: 400
    Layout.minimumHeight: 250

    // internal state
    property int focusSection: 0
    property string activeBackend: "Milou"
    property bool isLoadingResults: false
    property int searchGeneration: 0
    readonly property int filteredResultLimit: 120
    property bool pendingHistoryRun: false
    property string pendingHistoryMatchId: ""
    property string pendingHistoryDisplay: ""

    // Context Menu for Results
    HistoryContextMenu {
        id: resultsContextMenu
        logic: popupRoot.logic
    }

    // ===== DATA MANAGER =====
    TileDataManager {
        id: tileData
        resultsModel: resultsModel
        logic: popupRoot.logic
        searchText: popupRoot.searchText
        activeFilter: popupRoot.activeFilter
        searchAlgorithm: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.searchAlgorithm || 0) : 0
        minResults: popupRoot.plasmoidConfig ? Math.max(0, popupRoot.plasmoidConfig.minResults || 0) : 3
        smartResultLimit: popupRoot.plasmoidConfig ? popupRoot.plasmoidConfig.smartResultLimit !== false : true
        maxResults: popupRoot.activeFilter === "All"
            ? (popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.maxResults || 20) : 20)
            : popupRoot.filteredResultLimit

        onCategorizedDataChanged: {
             // propagated automatically to bindings
        }
    }

    // ===== SEARCH MODEL =====
    Milou.ResultsModel {
        id: resultsModel
        // Use debounced query string to prevent stutter during rapid typing
        queryString: popupRoot.delayedQueryString
        limit: popupRoot.activeFilter === "All"
            ? (popupRoot.plasmoidConfig ? Math.max(10, popupRoot.plasmoidConfig.maxResults || 20) : 20)
            : popupRoot.filteredResultLimit
    }

    // Debounce the query string update to Milou
    property string delayedQueryString: ""
    Timer {
        id: queryDebouncer
        interval: 60
        repeat: false
        onTriggered: {
            popupRoot.delayedQueryString = getBackendQuery(popupRoot.searchText, popupRoot.activeFilter)
            tileData.markQueryIssued(popupRoot.searchGeneration)
        }
    }

    Timer {
        id: loadingFallbackTimer
        interval: 900
        repeat: false
        onTriggered: popupRoot.isLoadingResults = false
    }

    onSearchTextChanged: {
        searchGeneration++
        tileData.beginSearch(searchGeneration, Date.now())
        popupRoot.isLoadingResults = searchText.length > 0
        if (searchText.length > 0) loadingFallbackTimer.restart()
        else loadingFallbackTimer.stop()
        queryDebouncer.restart()
        // If query is cleared, update immediately for responsive feel
        if (searchText.length === 0) {
            queryDebouncer.stop()
            delayedQueryString = ""
            popupRoot.isLoadingResults = false
        }

        // Auto-minimize pinned items logic
        if (autoMinimizePinned && pinnedLoader.item) {
            if (searchText.length > 0) {
                pinnedLoader.item.isExpanded = false
            } else {
                pinnedLoader.item.isExpanded = true
            }
        }
    }

    onActiveFilterChanged: {
        searchGeneration++
        tileData.beginSearch(searchGeneration, Date.now())
        popupRoot.isLoadingResults = searchText.length > 0
        if (searchText.length > 0) loadingFallbackTimer.restart()
        queryDebouncer.restart()
    }

    Connections {
        target: tileData
        function onRefreshVersionChanged() {
            popupRoot.isLoadingResults = false
            loadingFallbackTimer.stop()
            popupRoot.tryRunPendingHistory()
        }
    }

    // ===== FUNCTIONS =====

    function getFilteredQuery(text, filter) {
        // Backend prefixes (like "services:" or "baloo:") are unreliable across different Plasma versions and locales.
        // TileDataManager applies activeFilter locally.
        // This ensures consistent results because Milou fetches up to 120 items when a filter is active.
        return text || "";
    }

    function getBackendQuery(text, filter) {
        if (!isQueryAllowed(text))
            return ""
        var eq = popupRoot.effectiveQuery
        if (!eq && filter === "All") return ""

        var lower = eq.toLowerCase()
        if (lower.startsWith("rss:")) return ""

        if (popupRoot.isCommandOnly) {
            return ""
        }

        return getFilteredQuery(eq, filter)
    }

    // Background for Desktop Mode (Matte)
    Rectangle {
        anchors.fill: parent
        // Extend slightly to cover margins if needed, or fill parent
        z: -100
        color: popupRoot.bgColor
        radius: 12
        visible: !popupRoot.isInPanel
        opacity: 0.95 // Almost solid matte

        // Add a subtle border or shadow if needed for contrast
        border.color: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.1)
        border.width: 1
    }

    function cycleFocusSection(forward) {
        if (forward) {
            if (focusSection === 0) {
                focusSection = 1;
                if (isTileView && searchText.length > 0 && tileResultsLoader.item) {
                    tileResultsLoader.item.forceActiveFocus();
                } else if (searchText.length === 0 && logic.searchHistory.length > 0) {
                     if (isTileView && historyTileLoader.item) historyTileLoader.item.forceActiveFocus();
                }
            }
        } else {
            if (focusSection === 1) {
                focusSection = 0;
                hiddenSearchInput.forceActiveFocus();
            }
        }
    }

    function handleResultClick(index, display, decoration, category, matchId, filePath) {
        if (index !== -1 && !isQueryAllowed(popupRoot.searchText))
            return;
        // Record to history
        logic.addToHistory(display, decoration, category, matchId, filePath, (index === -1 ? "rss" : null), popupRoot.searchText);

        // Handle non-milou results (like RSS)
        if (index === -1) {
            if (filePath && filePath.toString().length > 0) {
                if (Utils.isSafeExternalUrl(filePath)) Qt.openUrlExternally(filePath);
            }
            requestSearchTextUpdate("");
            requestExpandChange(false);
            return;
        }

        var isApp = Utils.isAppCategory(category, filePath, matchId, decoration);
        var idx = resultsModel.index(index, 0);

        // FORCE RUN for command queries (gg:, help:, etc.) to avoid treating them as files
        if (isCommandOnlyQuery(popupRoot.searchText)) {
             runResultSafely(idx);
        }
        else if (isApp) {
             runResultSafely(idx);
        } else if (filePath && filePath.length > 0 && filePath.toString().indexOf("http") !== 0) {
             // For files, open externally
             if (Utils.isSafeExternalUrl(filePath)) Qt.openUrlExternally(filePath);
        } else {
             // For bookmarks or others, use Milou run
             runResultSafely(idx);
        }

        requestSearchTextUpdate("");
        requestExpandChange(false);
    }

    function handleHistoryClick(item) {
        // Move clicked item to top of history
        logic.addToHistory(item.display, item.decoration, item.category, item.matchId, item.filePath, item.sourceType, item.queryText);

        // If it's a known file or application path, open/run it directly and instantly
           var directPath = item.filePath || item.url || ""
           if (directPath && directPath.toString().length > 0) {
               if (Utils.isDesktopEntry(directPath)) {
                  // Direct application launch via safe helper
                   logic.launchApp(directPath);
             } else {
                  // Standard file open
                   if (Utils.isSafeExternalUrl(directPath)) Qt.openUrlExternally(directPath);
             }
             requestExpandChange(false);
             requestSearchTextUpdate("");
             return;
        }

           if (Utils.isDesktopEntry(item.matchId)) {
               logic.launchApp(item.matchId.toString())
               requestExpandChange(false);
               requestSearchTextUpdate("");
               return;
           }

        // Only fall back to search-run-timer for pure search strings (without stored paths)
        var searchTerm = item.display || item.queryText || "";
        requestSearchTextUpdate(searchTerm);

        if (!isButtonMode) hiddenSearchInput.text = searchTerm;
        else searchBar.setText(searchTerm);

        queueHistoryRun(item)
        historyRunTimer.start();
    }

    Timer {
        id: historyRunTimer
        interval: 400
        repeat: false
        onTriggered: {
            popupRoot.tryRunPendingHistory()
        }
    }

    function queueHistoryRun(item) {
        pendingHistoryRun = true
        pendingHistoryMatchId = item && item.matchId ? item.matchId.toString() : ""
        pendingHistoryDisplay = item && item.display ? item.display.toString() : ""
    }

    function tryRunPendingHistory() {
        if (!pendingHistoryRun) return
        if (!tileData || tileData.resultCount <= 0) return

        var items = tileData.flatSortedData || []
        var target = null
        for (var i = 0; i < items.length; i++) {
            var it = items[i]
            if (pendingHistoryMatchId && it.duplicateId === pendingHistoryMatchId) {
                target = it
                break
            }
        }
        if (!target && pendingHistoryDisplay) {
            for (var j = 0; j < items.length; j++) {
                var cand = items[j]
                if (cand.display === pendingHistoryDisplay) {
                    target = cand
                    break
                }
            }
        }
        if (!target) {
            pendingHistoryRun = false
            pendingHistoryMatchId = ""
            pendingHistoryDisplay = ""
            return
        }
        if (!target) return

        pendingHistoryRun = false
        pendingHistoryMatchId = ""
        pendingHistoryDisplay = ""

        handleResultClick(
            target.index,
            target.display || "",
            target.decoration || "application-x-executable",
            target.category || "Other",
            target.duplicateId || target.display || "",
            target.url || ""
        )
    }

    // Navigation Helpers
    function moveSelectionUp() {
        if (searchText.length === 0) {
            if (historyLoader.item) historyLoader.item.moveUp();
            return;
        }

        if (isTileView && tileResultsLoader.item) {
             tileResultsLoader.item.moveUp(); // Spatial Up
        } else if (resultsListLoader.item) {
             resultsListLoader.item.moveUp();
        }
    }

    function moveSelectionDown() {
        if (searchText.length === 0) {
            if (historyLoader.item) historyLoader.item.moveDown();
            return;
        }

        if (isTileView && tileResultsLoader.item) {
             tileResultsLoader.item.moveDown(); // Spatial Down
        } else if (resultsListLoader.item) {
             resultsListLoader.item.moveDown();
        }
    }

    function moveSelectionLeft() {
        if (searchText.length === 0) {
            if (historyLoader.item) historyLoader.item.moveLeft();
            return;
        }

        if (isTileView && tileResultsLoader.item) {
             tileResultsLoader.item.moveLeft();
        }
    }

    function moveSelectionRight() {
        if (searchText.length === 0) {
            if (historyLoader.item) historyLoader.item.moveRight();
            return;
        }

        if (isTileView && tileResultsLoader.item) {
             tileResultsLoader.item.moveRight();
        }
    }

    function activateCurrentResult() {
        if (searchText.length === 0 && historyLoader.item && historyLoader.item.activateCurrentItem)
            return historyLoader.item.activateCurrentItem();
        if (isTileView && tileResultsLoader.item && tileResultsLoader.item.activateCurrentItem)
            return tileResultsLoader.item.activateCurrentItem();
        if (resultsListLoader.item && resultsListLoader.item.activateCurrentItem)
            return resultsListLoader.item.activateCurrentItem();
        return false;
    }

    // Command Query Helper
    // Uses cached locale strings — no i18nd() calls per invocation
    function _computeIsCommandOnly(text) {
        return PrefixRegistry.opensInternalView(text, _localizedPrefixes, _prefixSettings)
    }

    // Uses cached locale strings — no i18nd() calls per invocation
    function _computeEffectiveQuery(text) {
        var canonical = PrefixRegistry.canonicalize(text, _localizedPrefixes, _prefixSettings)
        if (canonical.startsWith("calendar:")) return "date:" + canonical.substring(9)
        return canonical
    }

    // Feature flags are an execution policy, not merely hint visibility. This
    // guard is used both before issuing a backend query and immediately before
    // ResultsModel.run(), so stale model rows cannot bypass a disabled prefix.
    function isQueryAllowed(text) {
        return QueryPolicy.isAllowed(text, {
            shellEnabled: _prefixShellEnabled,
            killEnabled: _prefixKillEnabled,
            spellEnabled: _prefixSpellEnabled,
            unitEnabled: _prefixUnitEnabled,
            timelineEnabled: _prefixTimelineEnabled,
            webSearchEnabled: _prefixWebSearchEnabled,
            weatherEnabled: _canShowWeather,
            locShell: _locShell,
            locKill: _locKill,
            locSpell: _locSpell,
            locUnit: _locUnit,
            locWeather: _locWeather
        });
    }

    function runResultSafely(modelIndex, queryOverride) {
        var query = queryOverride === undefined ? popupRoot.searchText : queryOverride;
        if (!isQueryAllowed(query))
            return false;
        resultsModel.run(modelIndex);
        return true;
    }

    // Legacy wrappers for backward compatibility (e.g. handleResultClick)
    function isCommandOnlyQuery(text) { return _computeIsCommandOnly(text) }
    function getEffectiveQuery(text) { return _computeEffectiveQuery(text) }

    // ===== UI COMPONENTS =====

    // Hidden Input - Active in NON-BUTTON modes
    HiddenSearchInput {
        id: hiddenSearchInput
        visible: !isButtonMode
        resultCount: tileData.resultCount
        currentIndex: resultsListLoader.active && resultsListLoader.item ? resultsListLoader.item.currentIndex : 0

        onTextUpdated: (newText) => {
            requestSearchTextUpdate(newText);
        }
        onSearchSubmitted: (idx) => {
             activateCurrentResult();
         }
        onEscapePressed: {
             requestSearchTextUpdate("");
             requestExpandChange(false);
        }
        onUpPressed: moveSelectionUp()
        onDownPressed: moveSelectionDown()
        onLeftPressed: moveSelectionLeft()
        onRightPressed: moveSelectionRight()
        onTabPressedSignal: cycleFocusSection(true)
        onShiftTabPressedSignal: cycleFocusSection(false)
        onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
    }

    // New Search Bar (matches app-menu style, placed at top)
    SearchBar {
        id: searchBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        visible: isButtonMode
        resultCount: tileData.resultCount
        resultsModel: resultsModel
        logic: popupRoot.logic
        rssPlaceholderCycling: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssPlaceholderCycling || false) : false
        rssFrequency: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssFrequency !== undefined ? popupRoot.plasmoidConfig.rssFrequency : 3) : 3
        weatherFrequency: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.weatherFrequency !== undefined ? popupRoot.plasmoidConfig.weatherFrequency : 2) : 2
        rssShowFullHeadline: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssShowFullHeadline !== undefined ? popupRoot.plasmoidConfig.rssShowFullHeadline : true) : true
        rssShowSource: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssShowSource || false) : false

        onTextUpdated: (newText) => {
             if (isButtonMode && newText !== popupRoot.searchText) {
                 requestSearchTextUpdate(newText);
             }
        }

        // Manual binding for text (Popup -> Input)
        Connections {
             target: popupRoot
             function onSearchTextChanged() {
                 if (popupRoot.expanded && isButtonMode && searchBar.text !== popupRoot.searchText) {
                     searchBar.setText(popupRoot.searchText);
                 }
             }
        }

        onSearchSubmitted: (text, idx) => {
             activateCurrentResult();
         }

        onEscapePressed: {
             requestSearchTextUpdate("");
             requestExpandChange(false);
        }
        onUpPressed: moveSelectionUp()
        onDownPressed: moveSelectionDown()
        onLeftPressed: moveSelectionLeft()
        onRightPressed: moveSelectionRight()
        onTabPressedSignal: cycleFocusSection(true)
        onShiftTabPressedSignal: cycleFocusSection(false)
        onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
    }

    // Filter Chips (Categories) - Moved to top
    Item {
        id: filterChipsWrapper
        anchors.top: searchBar.visible ? searchBar.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        property bool isVisible: {
            var hintsVisible = queryHintsLoader.active && queryHintsLoader.item && queryHintsLoader.item.visible;
            return popupRoot.expanded && popupRoot.searchText.length > 0 && !popupRoot.isRssOnlyQuery && !popupRoot.isCommandOnly && !hintsVisible;
        }

        anchors.topMargin: isVisible ? 10 : 0
        height: isVisible ? 32 : 0
        opacity: isVisible ? 1 : 0
        clip: true
        visible: height > 0 || opacity > 0

        Behavior on height { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }

        Loader {
            anchors.fill: parent
            active: filterChipsWrapper.visible
            sourceComponent: FilterChips {
                textColor: popupRoot.textColor
                accentColor: popupRoot.accentColor
                bgColor: popupRoot.bgColor
                activeFilter: popupRoot.activeFilter
                breezeStyle: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.filterChipStyle === 1) : false

                onFilterSelected: (name) => {
                    popupRoot.activeFilter = name;
                    queryDebouncer.restart();
                }
            }
        }
    }

    // Primary Preview (Loader)
    Loader {
        id: primaryResultPreviewLoader
        anchors.top: filterChipsWrapper.bottom
        anchors.topMargin: (active && filterChipsWrapper.isVisible) ? 8 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        asynchronous: true
        active: popupRoot.expanded && !isTileView && searchText.length > 0 && !popupRoot.isCommandOnly && !popupRoot.isRssOnlyQuery

        sourceComponent: PrimaryResultPreview {
            resultsModel: resultsModel
            resultCount: tileData.resultCount
            flatSortedData: tileData.flatSortedData
            searchText: popupRoot.searchText
            accentColor: popupRoot.accentColor
            textColor: popupRoot.textColor
            previewEnabled: popupRoot.previewEnabled && popupRoot.previewShowResults
            previewSettings: popupRoot.previewSettings

            onResultClicked: (idx, display, decoration, category, matchId, filePath) => {
                if (!isQueryAllowed(popupRoot.searchText))
                    return;
                handleResultClick(idx, display, decoration, category, matchId || display, filePath || "");
            }
        }
    }

    // Query Hints (Loader)
    Loader {
        id: queryHintsLoader
        anchors.top: (primaryResultPreviewLoader.active && primaryResultPreviewLoader.status === Loader.Ready)
                     ? primaryResultPreviewLoader.bottom
                     : filterChipsWrapper.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        active: popupRoot.expanded && popupRoot.queryMayHaveHint && !popupRoot.isRssOnlyQuery
        sourceComponent: QueryHints {
            searchText: popupRoot.searchText
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            bgColor: popupRoot.bgColor

            logic: popupRoot.logic
            plasmoidConfig: popupRoot.plasmoidConfig

            onHintSelected: (text) => {
                requestSearchTextUpdate(text)
                if (!isButtonMode) hiddenSearchInput.text = text
                else searchBar.setText(text)
            }
        }
    }



    // Pinned Section (Loader)
    Loader {
        id: pinnedLoader
        anchors.top: queryHintsLoader.active ? queryHintsLoader.bottom : (primaryResultPreviewLoader.active ? primaryResultPreviewLoader.bottom : filterChipsWrapper.bottom)
        anchors.topMargin: active ? 4 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true

        property var items: logic.visiblePinnedItems
        active: popupRoot.expanded && showPinnedBar && !popupRoot.isRssOnlyQuery

        // Connections removed as binding handles updates now

        sourceComponent: PinnedSection {
            pinnedItems: pinnedLoader.items
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            iconSize: popupRoot.iconSize
            isTileView: popupRoot.isTileView
            isSearching: popupRoot.searchText.length > 0 || popupRoot.isPrefixMenuOpen
            compactPinnedView: popupRoot.compactPinnedItems

            onItemClicked: (item) => {
                if (item.filePath) {
                     if (Utils.isDesktopEntry(item.filePath)) {
                          logic.launchApp(item.filePath);
                     } else {
                          if (Utils.isSafeExternalUrl(item.filePath)) Qt.openUrlExternally(item.filePath);
                     }
                } else {
                    requestSearchTextUpdate(item.display);
                    // delayed run...
                    Qt.callLater(() => {
                        if (tileData.resultCount > 0)
                            runResultSafely(resultsModel.index(0, 0), item.display);
                    });
                }
                requestExpandChange(false);
            }
            onUnpinClicked: (matchId) => logic.unpinItem(matchId)

            // Drag-drop reorder
            onReorderRequested: (fromUuid, toUuid) => {
                logic.reorderPinnedItems(fromUuid, toUuid)
            }

            // Context menu actions
            onCopyPathRequested: (item) => {
                if (item.filePath) {
                    var path = item.filePath.toString().replace("file://", "")
                    logic.copyToClipboard(path)
                }
            }

            onOpenLocationRequested: (item) => {
                if (item.filePath) {
                    var path = item.filePath.toString()
                    // Get parent directory
                    var lastSlash = path.lastIndexOf("/")
                    if (lastSlash > 0) {
                        var parentDir = path.substring(0, lastSlash)
                        if (Utils.isSafeExternalUrl(parentDir)) Qt.openUrlExternally(parentDir)
                    }
                }
            }
            width: parent.width
        }
    }





    // Start screen prefix shortcuts. Keep them as a single horizontal strip so
    // the history grid below stays visible and keeps its old structure.
    Item {
        id: startupPrefixStrip
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? Kirigami.Units.smallSpacing * 2 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12 + Kirigami.Units.largeSpacing
        anchors.rightMargin: 12 + Kirigami.Units.largeSpacing
        height: active ? Kirigami.Units.gridUnit * 1.8 : 0
        visible: active
        clip: true

        property bool active: popupRoot.expanded && popupRoot.searchText.length === 0 && !popupRoot.isRssOnlyQuery
        property var prefixActions: [
            { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Help"), prefix: "help:", icon: "help-contents" },
            { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Weather"), prefix: "weather:", icon: "weather-clear" },
            { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unit Converter"), prefix: "unit:", icon: "accessories-calculator" },
            { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Date and Time"), prefix: "date:", icon: "view-calendar" }
        ]

        ListView {
            id: startupPrefixList
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.smallSpacing
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentWidth > width
            model: startupPrefixStrip.prefixActions

            delegate: PlasmaComponents.Button {
                width: implicitWidth
                height: startupPrefixStrip.height
                text: modelData.label + "  " + modelData.prefix
                icon.name: modelData.icon
                onClicked: {
                    requestSearchTextUpdate(modelData.prefix)
                    if (!isButtonMode) hiddenSearchInput.text = modelData.prefix
                    else searchBar.setText(modelData.prefix)
                }
            }
        }
    }

    // Result List View (Loader)
    Loader {
        id: resultsListLoader
        anchors.top: startupPrefixStrip.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom // Anchor to parent bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        // Use bottom margin to simulate anchoring to top of buttonModeSearchInput
        anchors.bottomMargin: 12

        active: popupRoot.expanded && !isTileView && searchText.length > 0 && !popupRoot.isCommandOnly && !popupRoot.isPrefixMenuOpen

        sourceComponent: ResultsListView {
             resultsModel: resultsModel
             flatSortedData: tileData.flatSortedData
             listIconSize: popupRoot.listIconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor

             searchText: popupRoot.searchText
             isLoading: popupRoot.isLoadingResults
             previewEnabled: popupRoot.previewEnabled
             previewShowResults: popupRoot.previewShowResults
             previewInlineMode: popupRoot.previewInlineMode
             previewSize: popupRoot.previewSize
             previewSettings: popupRoot.previewSettings
             logic: popupRoot.logic

             isPinnedFunc: logic.isPinned
             togglePinFunc: logic.togglePin

             rssShowImages: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssShowImages !== undefined ? popupRoot.plasmoidConfig.rssShowImages : true) : true
             rssExpandableCards: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssExpandableCards !== undefined ? popupRoot.plasmoidConfig.rssExpandableCards : true) : true

             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)

             onItemRightClicked: (item, visualParent, x, y) => {
                 resultsContextMenu.historyItem = item
                 resultsContextMenu.popup(visualParent, x, y)
             }
             anchors.fill: parent
        }
    }

    // Result Tile View (Loader)
    Loader {
        id: tileResultsLoader
        anchors.top: startupPrefixStrip.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 12

        asynchronous: true
        active: popupRoot.expanded && isTileView && searchText.length > 0 && !popupRoot.isCommandOnly && !popupRoot.isPrefixMenuOpen

        sourceComponent: ResultsTileView {
             categorizedData: tileData.categorizedData
             iconSize: popupRoot.iconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor

             searchText: popupRoot.searchText
             isLoading: popupRoot.isLoadingResults
             previewEnabled: popupRoot.previewEnabled
             previewShowResults: popupRoot.previewShowResults
             previewInlineMode: popupRoot.previewInlineMode
             previewSize: popupRoot.previewSize
             previewSettings: popupRoot.previewSettings
             scrollBarStyle: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.scrollBarStyle || 0) : 0
             compactTileView: popupRoot.compactHistoryItems

             rssShowImages: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssShowImages !== undefined ? popupRoot.plasmoidConfig.rssShowImages : true) : true
             rssExpandableCards: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.rssExpandableCards !== undefined ? popupRoot.plasmoidConfig.rssExpandableCards : true) : true

             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)

             onItemRightClicked: (item, visualParent, x, y) => {
                 resultsContextMenu.historyItem = item
                 resultsContextMenu.popup(visualParent, x, y)
             }

             onTabPressed: cycleFocusSection(true)
             onShiftTabPressed: cycleFocusSection(false)
             onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
             anchors.fill: parent
        }
    }

    // Date/Clock View (Special "date:" query)
    Loader {
        id: dateViewLoader
        anchors.top: startupPrefixStrip.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom // Anchor to parent bottom
        anchors.margins: 12
        anchors.bottomMargin: 12

        active: popupRoot.expanded && (popupRoot.effectiveQuery === "date:" || popupRoot.effectiveQuery === "clock:")

        sourceComponent: DateView {
            textColor: popupRoot.textColor
            viewMode: popupRoot.effectiveQuery === "clock:" ? "clock" : "date"
            showClock: popupRoot.prefixDateShowClock
            showEvents: popupRoot.prefixDateShowEvents
            anchors.fill: parent
        }
    }

    // Help View ("help:" query)
    Loader {
        id: helpViewLoader
        anchors.top: startupPrefixStrip.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: 12

        active: popupRoot.expanded && popupRoot.effectiveQuery === "help:"

        sourceComponent: HelpView {
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor


            onAidSelected: (prefix) => {
                // HelpView returns the prefix in the active locale.
                requestSearchTextUpdate(prefix)
                if (!isButtonMode) hiddenSearchInput.text = prefix
                else searchBar.setText(prefix)
            }
            anchors.fill: parent
        }
    }

    // Weather View ("weather:" query)
    Loader {
        id: weatherViewLoader
        anchors.top: startupPrefixStrip.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: 12

        active: popupRoot.expanded && popupRoot.effectiveQuery.startsWith("weather:")

        sourceComponent: WeatherView {
            // WeatherView handles its own fetching on visible
            plasmoidConfig: popupRoot.plasmoidConfig
            logic: popupRoot.logic
            anchors.fill: parent
            queryCity: {
                var eq = popupRoot.effectiveQuery;
                if (eq.startsWith("weather:")) {
                    return eq.substring(8).trim();
                }
                return "";
            }
        }
    }

    // Power View ("power:" query)
    Loader {
        id: powerViewLoader
        anchors.top: startupPrefixStrip.bottom
        anchors.topMargin: active ? 6 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: 12

        active: popupRoot.expanded && popupRoot.effectiveQuery === "power:"

        sourceComponent: PowerView {
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            showHibernate: popupRoot.prefixPowerShowHibernate
            showSleep: popupRoot.prefixPowerShowSleep
            bgColor: popupRoot.bgColor
            showBootOptions: popupRoot.showBootOptions
            plasmoidConfig: popupRoot.plasmoidConfig

            onRequestPreventClosing: (prevent) => {
                popupRoot.preventClosing = prevent
                popupRoot.requestPreventClosing(prevent) // Forward to main just in case
            }
            anchors.fill: parent
        }
    }

    // History Container (Loader) - Show when no search text
    Loader {
         id: historyLoader
         anchors.top: startupPrefixStrip.bottom
         anchors.left: parent.left
         anchors.right: parent.right
         anchors.bottom: parent.bottom // Anchor to parent bottom
         anchors.leftMargin: 12
         anchors.rightMargin: 12
         // History top margin is now fixed
         anchors.topMargin: 6
         asynchronous: true
         anchors.bottomMargin: 12

         active: popupRoot.expanded && (searchText.length === 0 || popupRoot.isPrefixMenuOpen)

         property var categorizedHistory: {
             if (logic.searchHistory.length === 0) return [];
             var hist = logic.searchHistory;
             if (activeFilter !== "All") {
                 var filtered = [];
                 var filterLower = activeFilter.toLowerCase();
                 for (var i = 0; i < hist.length; i++) {
                     var item = hist[i];
                     if (Utils.matchesResultFilter(filterLower, item.category || "", item.filePath || "", item.matchId || "", item.decoration || "", Utils.getPathExtension(item.filePath || "")))
                         filtered.push(item);
                 }
                 hist = filtered;
             }
             return HistoryManager.categorizeHistory(hist, i18nd("plasma_applet_com.mcc45tr.filesearch", "Applications"), i18nd("plasma_applet_com.mcc45tr.filesearch", "Other"));
         }

         sourceComponent: Item {
             anchors.fill: parent
             // Helper to route navigation
             function moveUp() {
                 var view = isTileView ? histTileLoader.item : histListLoader.item;
                 if (view) view.moveUp();
             }
             function moveDown() {
                 var view = isTileView ? histTileLoader.item : histListLoader.item;
                 if (view) view.moveDown();
             }
             function moveLeft() {
                 if (histTileLoader.item) histTileLoader.item.moveLeft();
             }
             function moveRight() {
                 if (histTileLoader.item) histTileLoader.item.moveRight();
             }
             function activateCurrentItem() {
                 var view = isTileView ? histTileLoader.item : histListLoader.item;
                 if (view) view.activateCurrentItem();
             }

             // History List
             Loader {
                 id: histListLoader
                 anchors.fill: parent
                 asynchronous: true
                 active: !isTileView
                 sourceComponent: HistoryListView {
                     categorizedHistory: historyLoader.categorizedHistory
                     listIconSize: popupRoot.listIconSize
                     textColor: popupRoot.textColor
                     accentColor: popupRoot.accentColor
                     formatTimeFunc: logic.formatHistoryTime
                     logic: popupRoot.logic
                     previewEnabled: popupRoot.previewEnabled
                     previewShowHistory: popupRoot.previewShowHistory
                     previewInlineMode: popupRoot.previewInlineMode
                     previewSize: popupRoot.previewSize
                     previewSettings: popupRoot.previewSettings
                     onItemClicked: (item) => handleHistoryClick(item)
                     onClearClicked: logic.clearHistory()
                 }
             }

             // History Tile
             Loader {
                 id: histTileLoader
                 anchors.fill: parent
                 asynchronous: true
                 active: isTileView
                 sourceComponent: HistoryTileView {
                     previewEnabled: popupRoot.previewEnabled
                     previewShowHistory: popupRoot.previewShowHistory
                     previewInlineMode: popupRoot.previewInlineMode
                     previewSize: popupRoot.previewSize
                     categorizedHistory: historyLoader.categorizedHistory
                     iconSize: popupRoot.iconSize
                     textColor: popupRoot.textColor
                     accentColor: popupRoot.accentColor
                     logic: popupRoot.logic
                     previewSettings: popupRoot.previewSettings
                     scrollBarStyle: popupRoot.plasmoidConfig ? (popupRoot.plasmoidConfig.scrollBarStyle || 0) : 0
                     compactTileView: popupRoot.compactHistoryItems
                     onItemClicked: (item) => handleHistoryClick(item)
                     onClearClicked: logic.clearHistory()
                     onHintSelected: (text) => {
                         requestSearchTextUpdate(text)
                         if (!isButtonMode) hiddenSearchInput.text = text
                         else searchBar.setText(text)
                     }
                     onTabPressed: cycleFocusSection(true)
                     onShiftTabPressed: cycleFocusSection(false)
                     onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
                 }
             }
         }
    }

    // Debug Overlay (Loader)
    Loader {
         id: debugOverlayLoader
         anchors.top: parent.top
         anchors.right: parent.right
         anchors.margins: 8
         z: 9999
         asynchronous: true
         active: popupRoot.expanded && popupRoot.showDebug

         sourceComponent: DebugOverlay {
              resultCount: tileData.resultCount
              activeBackend: popupRoot.activeBackend
              lastLatency: tileData.lastLatency
              viewModeName: isTileView ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Tile") : i18nd("plasma_applet_com.mcc45tr.filesearch", "List")
              displayModeName: isButtonMode ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Button") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Mode")
              totalSearches: logic.telemetryStats.totalSearches || 0
              avgLatency: logic.telemetryStats.averageLatency || 0
              performanceTrace: tileData.lastPerformanceTrace

         }
    }

    Component {
        id: articleWindowComponent
        Window {
            id: artWin
            width: 650
            height: 550
            title: articleTitle
            visible: true

            property string articleTitle: ""
            property string articleText: ""
            property string articleUrl: ""

            color: popupRoot.bgColor

            Shortcut {
                sequence: "Escape"
                onActivated: artWin.close()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: artWin.articleTitle
                    color: popupRoot.textColor
                    font.bold: true
                    font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.5)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                PlasmaComponents.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    PlasmaComponents.TextArea {
                        text: artWin.articleText
                        color: popupRoot.textColor
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        background: null
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    PlasmaComponents.Button {
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open in Browser")
                        icon.name: "internet-services"
                        onClicked: {
                            if (Utils.isSafeExternalUrl(artWin.articleUrl)) Qt.openUrlExternally(artWin.articleUrl)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents.Button {
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Close")
                        onClicked: artWin.close()
                    }
                }
            }
        }
    }

    function showArticleInWindow(title, text, url) {
        articleWindowComponent.createObject(popupRoot, {
            articleTitle: title,
            articleText: text,
            articleUrl: url
        });
    }

    Component.onCompleted: {
         if (!isButtonMode && hiddenSearchInput) {
            hiddenSearchInput.forceActiveFocus();
         }
    }
}
