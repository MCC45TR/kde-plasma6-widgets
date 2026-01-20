import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou
import "../js/HistoryManager.js" as HistoryManager
import org.kde.plasma.plasmoid

Item {
    id: popupRoot
    
    // Dependencies
    required property var logic    
    
    // Properties synced with main
    property string searchText: ""
    property bool expanded: false
    property bool isInPanel: true // Default to true, overridden by Main
    
    onExpandedChanged: {
        if (expanded) {
            // Force focus when popup opens
            if (isButtonMode) {
                buttonModeSearchInput.focusInput()
            } else {
                hiddenSearchInput.forceActiveFocus()
            }
        } else {
            // Clear search text when popup closes
            requestSearchTextUpdate("")
            buttonModeSearchInput.clear()
            hiddenSearchInput.text = ""
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
    property var previewSettings: ({"images": true, "videos": false, "text": false, "documents": false})
    
    // Prefix Settings
    property bool prefixDateShowClock: true
    property bool prefixDateShowEvents: true
    property bool prefixPowerShowHibernate: false
    property bool prefixPowerShowSleep: true
    property bool showPinnedBar: true
    property bool autoMinimizePinned: false

    // property var trFunc removed
    
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
    readonly property bool isTileView: viewMode === 1
    
    // Layout
    Layout.preferredWidth: 500
    Layout.preferredHeight: 380
    Layout.minimumWidth: 400
    Layout.minimumHeight: 250
    
    // internal state
    property int focusSection: 0
    property string activeBackend: "Milou"
    
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
        
        onCategorizedDataChanged: {
             // propagated automatically to bindings
        }
    }
    
    // ===== SEARCH MODEL =====
    Milou.ResultsModel {
        id: resultsModel
        queryString: getEffectiveQuery(popupRoot.searchText)
        limit: 50
    }
    
    // ===== FUNCTIONS =====
    
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
        logic.addToHistory(display, decoration, category, matchId, filePath, null, popupRoot.searchText);
        
        var isApp = (category === "Uygulamalar" || category === "Applications") || (filePath && filePath.toString().indexOf(".desktop") > 0);
        var idx = resultsModel.index(index, 0);
        
        // FORCE RUN for command queries (gg:, help:, etc.) to avoid treating them as files
        if (isCommandOnlyQuery(popupRoot.searchText)) {
             resultsModel.run(idx);
        } 
        else if (isApp) {
             resultsModel.run(idx);
        } else if (filePath && filePath.length > 0) {
             Qt.openUrlExternally(filePath);
        } else {
             resultsModel.run(idx);
        }
        
        requestSearchTextUpdate("");
        requestExpandChange(false);
    }
    
    function handleHistoryClick(item) {
        // If it's a known file or application path, open/run it directly and instantly
        if (item.filePath && item.filePath.toString().length > 0) {
             if (item.filePath.toString().indexOf(".desktop") !== -1) {
                  // Direct application launch via kioclient
                  logic.runShellCommand("kioclient exec '" + item.filePath + "'");
             } else {
                  // Standard file open
                  Qt.openUrlExternally(item.filePath);
             }
             requestExpandChange(false);
             requestSearchTextUpdate("");
             return;
        }

        // Only fall back to search-run-timer for pure search strings (without stored paths)
        var searchTerm = item.display || item.queryText || "";
        requestSearchTextUpdate(searchTerm);
        
        if (!isButtonMode) hiddenSearchInput.text = searchTerm;
        else buttonModeSearchInput.setText(searchTerm);
        
        historyRunTimer.start();
    }
    
    Timer {
        id: historyRunTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (tileData.resultCount > 0) {
                var idx = resultsModel.index(0, 0);
                resultsModel.run(idx);
                requestSearchTextUpdate("");
                requestExpandChange(false);
            }
        }
    }

    // Navigation Helpers
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
    
    // Command Query Helper
    function isCommandOnlyQuery(text) {
        if (!text) return false;
        var t = text.toLowerCase();
        // Only specific full-view modes hide the results list
        return t === "date:" || t === "clock:" || t === "power:" || t === "help:" || t === i18nd("plasma_applet_com.mcc45tr.filesearch", "date") + ":" || t === i18nd("plasma_applet_com.mcc45tr.filesearch", "clock") + ":" || t === i18nd("plasma_applet_com.mcc45tr.filesearch", "power") + ":" || t === i18nd("plasma_applet_com.mcc45tr.filesearch", "help") + ":";
    }

    function getEffectiveQuery(text) {
        if (!text) return ""
        var t = text
        
        // Map localized prefixes back to internal English prefixes or strip them
        
        // 1. Check for "unit:"
        if (t.toLowerCase().startsWith("unit:")) return t.substring(5).trim()
        // Localized
        var locUnit = i18nd("plasma_applet_com.mcc45tr.filesearch", "unit")
        if (locUnit && t.toLowerCase().startsWith(locUnit + ":")) return t.substring(locUnit.length + 1).trim()
        
        // 2. Check for "date:" or "clock:"
        var locDate = i18nd("plasma_applet_com.mcc45tr.filesearch", "date")
        var locClock = i18nd("plasma_applet_com.mcc45tr.filesearch", "clock")
        
        // Check for "clock:"
        if (t.toLowerCase() === "clock:" || (locClock && t.toLowerCase() === locClock + ":")) return "clock:"
        
        // Check for "date:"
        if (t.toLowerCase() === "date:" || (locDate && t.toLowerCase() === locDate + ":")) return "date:"
        
        // 3. Check for "help:"
        var locHelp = i18nd("plasma_applet_com.mcc45tr.filesearch", "help")
        if (locHelp && t.toLowerCase() === locHelp + ":") return "help:"

        // 4. Check for "kill"
        var locKill = i18nd("plasma_applet_com.mcc45tr.filesearch", "kill")
        if (locKill && t.toLowerCase().startsWith(locKill + " ")) return "kill " + t.substring(locKill.length + 1)

        // 5. Check for "spell"
        var locSpell = i18nd("plasma_applet_com.mcc45tr.filesearch", "spell")
        if (locSpell && t.toLowerCase().startsWith(locSpell + " ")) return "spell " + t.substring(locSpell.length + 1)
        
        // 6. Check for "shell:"
        var locShell = i18nd("plasma_applet_com.mcc45tr.filesearch", "shell")
        if (locShell && t.toLowerCase().startsWith(locShell + ":")) return "shell:" + t.substring(locShell.length + 1)
        
        // 7. Check for "power:"
        var locPower = i18nd("plasma_applet_com.mcc45tr.filesearch", "power")
        if (t.toLowerCase() === "power:" || (locPower && t.toLowerCase() === locPower + ":")) return "power:"

        return t
    }

    // ===== UI COMPONENTS =====
    
    // Hidden Input - Active in NON-BUTTON modes
    HiddenSearchInput {
        id: hiddenSearchInput
        visible: !isButtonMode
        resultCount: tileData.resultCount
        currentIndex: resultsListLoader.active ? resultsListLoader.item.currentIndex : 0 // approximate
        
        onTextUpdated: (newText) => {
            tileData.startSearch();
            requestSearchTextUpdate(newText);
        }
        onSearchSubmitted: (idx) => {
             // Dispatch based on view mode
             if (isTileView && tileResultsLoader.item) {
                 tileResultsLoader.item.activateCurrentItem();
                 return;
             } else if (searchText.length === 0 && historyLoader.item && isTileView) {
                 // History Tile View activation
                 if (historyLoader.item.activateCurrentItem) { // If exposed
                     historyLoader.item.activateCurrentItem();
                     return;
                 }
                 // Actually historyLoader wrapper doesn't have activateCurrentItem, 
                 // but we can add it or access inner.
                 // Let's rely on focus being there OR add helper.
                 // For now let's handle Results Tile View explicitly here.
             }

             if (tileData.resultCount > 0) {
                 var modelIdx = resultsModel.index(idx, 0);
                 var display = resultsModel.data(modelIdx, Qt.DisplayRole) || "";
                 var decoration = resultsModel.data(modelIdx, Qt.DecorationRole) || "";
                 var category = resultsModel.data(modelIdx, resultsModel.CategoryRole) || "";
                 var matchId = resultsModel.data(modelIdx, resultsModel.DuplicateRole) || display;
                 var url = resultsModel.data(modelIdx, resultsModel.UrlRole) || ""; 
                 
                 handleResultClick(idx, display, decoration, category, matchId, url);
             }
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

    // Button Mode Input
    ButtonModeSearchInput {
        id: buttonModeSearchInput
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: isButtonMode
        z: 100
        
        bgColor: popupRoot.bgColor
        textColor: popupRoot.textColor
        accentColor: popupRoot.accentColor
        placeholderText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Here")
        resultCount: tileData.resultCount
        resultsModel: resultsModel
        
        // Manual binding for text (Popup -> Input)
        Connections {
             target: popupRoot
             function onSearchTextChanged() {
                 if (popupRoot.expanded && isButtonMode && buttonModeSearchInput.searchText !== popupRoot.searchText) {
                     buttonModeSearchInput.setText(popupRoot.searchText);
                 }
             }
        }
        
        // Sync Input -> Popup
        onSearchTextChanged: {
            if (isButtonMode && buttonModeSearchInput.searchText !== popupRoot.searchText) {
                // If the change initiated from input (user typing), sync up
                requestSearchTextUpdate(buttonModeSearchInput.searchText);
                tileData.startSearch();
            }
        }

        onSearchSubmitted: (text, idx) => {
             // Just run index 0 or selected
             if (tileData.resultCount > 0) {
                 var modelIdx = resultsModel.index(idx, 0);
                 var display = resultsModel.data(modelIdx, Qt.DisplayRole);
                 resultsModel.run(modelIdx);
                 requestSearchTextUpdate("");
                 buttonModeSearchInput.clear();
                 requestExpandChange(false);
             }
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

    // Primary Preview (Loader)
    Loader {
        id: primaryResultPreviewLoader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        asynchronous: true
        active: popupRoot.expanded && popupRoot.searchText.length > 0 && !isTileView
        
        sourceComponent: PrimaryResultPreview {
            resultsModel: popupRoot.resultsModel
            resultCount: tileData.resultCount
            searchText: popupRoot.searchText
            accentColor: popupRoot.accentColor
            textColor: popupRoot.textColor
            
            onResultClicked: (idx, display, decoration, category) => {
                logic.addToHistory(display, decoration, category, display, "", "calculator", popupRoot.searchText);
                resultsModel.run(resultsModel.index(idx, 0));
                requestSearchTextUpdate("");
                requestExpandChange(false);
            }
        }
    }

    // Query Hints (Loader)
    Loader {
        id: queryHintsLoader
        anchors.top: primaryResultPreviewLoader.active && primaryResultPreviewLoader.status === Loader.Ready ? primaryResultPreviewLoader.bottom : parent.top
        // Add extra top margin in button mode to prevent content from being hidden behind panel button
        anchors.topMargin: primaryResultPreviewLoader.active ? 8 : (isButtonMode ? 50 : 0)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        active: popupRoot.expanded && popupRoot.searchText.length > 0
        sourceComponent: QueryHints {
            searchText: popupRoot.searchText
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            bgColor: popupRoot.bgColor
            // trFunc removed
            logic: popupRoot.logic
            
            onHintSelected: (text) => {
                requestSearchTextUpdate(text)
                if (!isButtonMode) hiddenSearchInput.text = text
                else buttonModeSearchInput.setText(text)
            }
        }
    }
    
    onSearchTextChanged: {
        if (autoMinimizePinned && pinnedLoader.item) {
            if (searchText.length > 0) {
                pinnedLoader.item.isExpanded = false
            } else {
                pinnedLoader.item.isExpanded = true
            }
        }
    }

    // Pinned Section (Loader)
    Loader {
        id: pinnedLoader
        anchors.top: queryHintsLoader.bottom
        anchors.topMargin: active ? 8 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        
        property var items: logic.getVisiblePinnedItems()
        active: items.length > 0 && showPinnedBar
        
        // Reactively update when pins change
        Connections {
            target: logic
            function onPinnedItemsChanged() {
                pinnedLoader.items = logic.getVisiblePinnedItems()
            }
        }
        
        sourceComponent: PinnedSection {
            pinnedItems: pinnedLoader.items
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            iconSize: popupRoot.iconSize
            isTileView: popupRoot.isTileView
            // trFunc removed
            
            onItemClicked: (item) => {
                if (item.filePath) {
                     if (item.filePath.toString().indexOf(".desktop") !== -1) {
                          logic.runShellCommand("kioclient exec '" + item.filePath + "'");
                     } else {
                          Qt.openUrlExternally(item.filePath);
                     }
                } else {
                    requestSearchTextUpdate(item.display);
                    // delayed run...
                    Qt.callLater(() => {
                        if (tileData.resultCount > 0) resultsModel.run(resultsModel.index(0, 0));
                    });
                }
                requestExpandChange(false);
            }
            onUnpinClicked: (matchId) => logic.unpinItem(matchId)
            
            // Drag-drop reorder
            onReorderRequested: (fromIndex, toIndex) => {
                logic.reorderPinnedItems(fromIndex, toIndex)
            }
            
            // Context menu actions
            onCopyPathRequested: (item) => {
                if (item.filePath) {
                    var path = item.filePath.toString().replace("file://", "")
                    logic.runShellCommand("echo -n '" + path + "' | xclip -selection clipboard")
                }
            }
            
            onOpenLocationRequested: (item) => {
                if (item.filePath) {
                    var path = item.filePath.toString()
                    // Get parent directory
                    var lastSlash = path.lastIndexOf("/")
                    if (lastSlash > 0) {
                        var parentDir = path.substring(0, lastSlash)
                        Qt.openUrlExternally(parentDir)
                    }
                }
            }
        }
    }

    // Result List View (Loader)
    Loader {
        id: resultsListLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 12 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom // Anchor to parent bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        asynchronous: true
        // Use bottom margin to simulate anchoring to top of buttonModeSearchInput
        anchors.bottomMargin: isButtonMode ? 56 : 12
        
        active: popupRoot.expanded && !isTileView && searchText.length > 0 && !isCommandOnlyQuery(searchText)
        
        sourceComponent: ResultsListView {
             resultsModel: resultsModel
             flatSortedData: tileData.flatSortedData
             listIconSize: popupRoot.listIconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor
            // trFunc removed
             searchText: popupRoot.searchText
             previewEnabled: popupRoot.previewEnabled
             previewSettings: popupRoot.previewSettings
             logic: popupRoot.logic
             
             isPinnedFunc: logic.isPinned
             togglePinFunc: logic.togglePin
             
             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)
             
             onItemRightClicked: (item, x, y) => {
                 resultsContextMenu.historyItem = item
                 resultsContextMenu.popup()
             }
        }
    }
    
    // Result Tile View (Loader)
    Loader {
        id: tileResultsLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 12 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: isButtonMode ? 56 : 12

        asynchronous: true
        active: popupRoot.expanded && isTileView && searchText.length > 0 && !isCommandOnlyQuery(searchText)
        
        sourceComponent: ResultsTileView {
             categorizedData: tileData.categorizedData
             iconSize: popupRoot.iconSize
             textColor: popupRoot.textColor
             accentColor: popupRoot.accentColor
             // trFunc removed
             searchText: popupRoot.searchText
             previewSettings: popupRoot.previewSettings

             onItemClicked: (idx, disp, dec, cat, mid, path) => handleResultClick(idx, disp, dec, cat, mid, path)
             
             onItemRightClicked: (item, x, y) => {
                 resultsContextMenu.historyItem = item
                 resultsContextMenu.popup()
             }
             
             onTabPressed: cycleFocusSection(true)
             onShiftTabPressed: cycleFocusSection(false)
             onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
        }
    }

    // Date/Clock View (Special "date:" query)
    Loader {
        id: dateViewLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 12 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom // Anchor to parent bottom
        anchors.margins: 12
        anchors.bottomMargin: 12
        
        active: popupRoot.expanded && (getEffectiveQuery(searchText) === "date:" || getEffectiveQuery(searchText) === "clock:")
        
        sourceComponent: DateView {
            textColor: popupRoot.textColor
            viewMode: getEffectiveQuery(popupRoot.searchText) === "clock:" ? "clock" : "date"
            showClock: popupRoot.prefixDateShowClock
            showEvents: popupRoot.prefixDateShowEvents
        }
    }

    // Help View ("help:" query)
    Loader {
        id: helpViewLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 12 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: 12
        
        active: popupRoot.expanded && getEffectiveQuery(searchText) === "help:"
        
        sourceComponent: HelpView {
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            // trFunc removed
            
            onAidSelected: (prefix) => {
                // When selecting from Help, we put the LOCALIZED prefix in the box if possible?
                // Or just the standard one? 
                // Let's use standard for now or what comes from HelpView (which we will update to be localized?)
                // If HelpView sends "birim:", we put "birim:".
                requestSearchTextUpdate(prefix)
                if (!isButtonMode) hiddenSearchInput.text = prefix
                else buttonModeSearchInput.setText(prefix)
                // Focus input?
            }
        }
    }
    
    // Power View ("power:" query)
    Loader {
        id: powerViewLoader
        anchors.top: pinnedLoader.bottom
        anchors.topMargin: active ? 12 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.bottomMargin: 12
        
        active: popupRoot.expanded && getEffectiveQuery(searchText) === "power:"
        
        sourceComponent: PowerView {
            textColor: popupRoot.textColor
            accentColor: popupRoot.accentColor
            showHibernate: popupRoot.prefixPowerShowHibernate
            showSleep: popupRoot.prefixPowerShowSleep
            bgColor: popupRoot.bgColor
            showBootOptions: popupRoot.showBootOptions
            
            onRequestPreventClosing: (prevent) => {
                popupRoot.preventClosing = prevent
                popupRoot.requestPreventClosing(prevent) // Forward to main just in case
            }
        }
    }
    
    // History Container (Loader) - Show when no search text
    Loader {
         id: historyLoader
         anchors.top: pinnedLoader.active ? pinnedLoader.bottom : parent.top
         anchors.left: parent.left
         anchors.right: parent.right
         anchors.bottom: parent.bottom // Anchor to parent bottom
         anchors.leftMargin: 12
         anchors.rightMargin: 12
         // Add extra top margin in button mode to prevent content from being hidden behind panel button
         anchors.topMargin: isButtonMode ? 50 : 12
         asynchronous: true
         // Use bottom margin to simulate anchoring to top of buttonModeSearchInput
         anchors.bottomMargin: isButtonMode ? 56 : 12
         
         active: popupRoot.expanded && searchText.length === 0 && logic.searchHistory.length > 0
         
         property var categorizedHistory: []
         onActiveChanged: if(active) categorizedHistory = HistoryManager.categorizeHistory(logic.searchHistory, i18nd("plasma_applet_com.mcc45tr.filesearch", "Applications"), i18nd("plasma_applet_com.mcc45tr.filesearch", "Other"))
         
         Connections {
             target: logic
             function onHistoryForceUpdate() {
                 if (historyLoader.status === Loader.Ready) {
                      historyLoader.categorizedHistory = HistoryManager.categorizeHistory(logic.searchHistory, i18nd("plasma_applet_com.mcc45tr.filesearch", "Applications"), i18nd("plasma_applet_com.mcc45tr.filesearch", "Other"))
                 }
             }
         }
         
         sourceComponent: Item {
             // Helper to route navigation
             function moveUp() { 
                 if (isTileView) histTileView.moveUp();
             }
             function moveDown() { 
                 if (isTileView) histTileView.moveDown();
             }
             function moveLeft() { 
                 if (isTileView) histTileView.moveLeft();
             }
             function moveRight() { 
                 if (isTileView) histTileView.moveRight();
             }
             function activateCurrentItem() {
                 if (isTileView) histTileView.activateCurrentItem();
             }

             // History List
                             HistoryListView {
                 id: histListView
                 anchors.fill: parent
                 visible: !isTileView
                 categorizedHistory: historyLoader.categorizedHistory
                 listIconSize: popupRoot.listIconSize
                 textColor: popupRoot.textColor
                 accentColor: popupRoot.accentColor
                 formatTimeFunc: logic.formatHistoryTime
                 // trFunc removed
                 previewSettings: popupRoot.previewSettings
                 
                 onItemClicked: (item) => handleHistoryClick(item)
                 onClearClicked: logic.clearHistory()
             }
             
             // History Tile
             HistoryTileView {
                 id: histTileView
                 anchors.fill: parent
                 visible: isTileView
                 categorizedHistory: historyLoader.categorizedHistory
                 iconSize: popupRoot.iconSize
                 textColor: popupRoot.textColor
                 accentColor: popupRoot.accentColor
                 // trFunc removed
                 previewSettings: popupRoot.previewSettings
                 
                 onItemClicked: (item) => handleHistoryClick(item)
                 onClearClicked: logic.clearHistory()
                 
                 onTabPressed: cycleFocusSection(true)
                 onShiftTabPressed: cycleFocusSection(false)
                 onViewModeChangeRequested: (mode) => requestViewModeChange(mode)
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
              viewModeName: isTileView ? "Tile" : "List"
              displayModeName: isButtonMode ? "Button" : "Mode"
              totalSearches: logic.telemetryStats.totalSearches || 0
              avgLatency: logic.telemetryStats.averageLatency || 0
              // trFunc removed
         }
    }

    Component.onCompleted: {
         if (!isButtonMode && hiddenSearchInput) {
            hiddenSearchInput.forceActiveFocus();
         }
    }
}
