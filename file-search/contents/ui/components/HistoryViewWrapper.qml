import QtQuick
import "../js/HistoryManager.js" as HistoryManager

Item {
    id: historyWrapperRoot
    
    // Required properties
    required property var logic
    required property var popupRoot
    required property var categorizedHistory
    
    // Properties from popupRoot needed for children
    property bool isTileView: popupRoot.isTileView
    property int listIconSize: popupRoot.listIconSize
    property int iconSize: popupRoot.iconSize
    property color textColor: popupRoot.textColor
    property color accentColor: popupRoot.accentColor
    property bool previewEnabled: popupRoot.previewEnabled
    property var previewSettings: popupRoot.previewSettings
    property var plasmoidConfig: popupRoot.plasmoidConfig
    property bool compactHistoryItems: popupRoot.compactHistoryItems
    
    // Signal for item clicks (to be handled by SearchPopup)
    signal itemClicked(var item)
    
    // Helper to route navigation
    function moveUp() { 
        if (isTileView && histTileLoader.item && histTileLoader.item.moveUp) histTileLoader.item.moveUp();
    }
    function moveDown() { 
        if (isTileView && histTileLoader.item && histTileLoader.item.moveDown) histTileLoader.item.moveDown();
    }
    function moveLeft() { 
        if (isTileView && histTileLoader.item && histTileLoader.item.moveLeft) histTileLoader.item.moveLeft();
    }
    function moveRight() { 
        if (isTileView && histTileLoader.item && histTileLoader.item.moveRight) histTileLoader.item.moveRight();
    }
    function activateCurrentItem() {
        if (isTileView && histTileLoader.item && histTileLoader.item.activateCurrentItem) histTileLoader.item.activateCurrentItem();
    }

    // History List View (Loader)
    Loader {
        id: histListLoader
        anchors.fill: parent
        active: !isTileView
        asynchronous: true
        
        sourceComponent: HistoryListView {
            categorizedHistory: historyWrapperRoot.categorizedHistory
            listIconSize: historyWrapperRoot.listIconSize
            textColor: historyWrapperRoot.textColor
            accentColor: historyWrapperRoot.accentColor
            formatTimeFunc: logic.formatHistoryTime
            
            previewEnabled: historyWrapperRoot.previewEnabled
            previewSettings: historyWrapperRoot.previewSettings
            
            onItemClicked: (item) => historyWrapperRoot.itemClicked(item)
            onClearClicked: logic.clearHistory()
        }
    }
    
    // History Tile View (Loader)
    Loader {
        id: histTileLoader
        anchors.fill: parent
        active: isTileView
        asynchronous: true
        
        sourceComponent: HistoryTileView {
            id: histTileView // id here refers to the loaded item instance
            previewEnabled: historyWrapperRoot.previewEnabled
            categorizedHistory: historyWrapperRoot.categorizedHistory
            iconSize: historyWrapperRoot.iconSize
            textColor: historyWrapperRoot.textColor
            accentColor: historyWrapperRoot.accentColor
            
            previewSettings: historyWrapperRoot.previewSettings
            scrollBarStyle: historyWrapperRoot.plasmoidConfig ? (historyWrapperRoot.plasmoidConfig.scrollBarStyle || 0) : 0
            compactTileView: historyWrapperRoot.compactHistoryItems
            
            onItemClicked: (item) => historyWrapperRoot.itemClicked(item)
            onClearClicked: logic.clearHistory()
            
            onTabPressed: popupRoot.cycleFocusSection(true)
            onShiftTabPressed: popupRoot.cycleFocusSection(false)
            onViewModeChangeRequested: (mode) => popupRoot.requestViewModeChange(mode)
        }
    }
}
