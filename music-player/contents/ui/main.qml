import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

import "js/PlayerData.js" as PlayerData

PlasmoidItem {
    id: root

    // --- Widget Size Constraints ---
    Layout.preferredWidth: 200
    Layout.preferredHeight: 200
    Layout.minimumWidth: 150
    Layout.minimumHeight: 150
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ---------------------------------------------------------
    // Configuration (Lazy evaluated)
    // ---------------------------------------------------------
    readonly property string preferredPlayer: Plasmoid.configuration.preferredPlayer || ""
    readonly property bool showPlayerBadge: Plasmoid.configuration.showPlayerBadge !== undefined ? Plasmoid.configuration.showPlayerBadge : true
    readonly property bool showPanelControls: Plasmoid.configuration.showPanelControls !== undefined ? Plasmoid.configuration.showPanelControls : true
    readonly property bool cfg_panelShowTitle: Plasmoid.configuration.panelShowTitle !== undefined ? Plasmoid.configuration.panelShowTitle : true
    readonly property bool cfg_panelShowArtist: Plasmoid.configuration.panelShowArtist !== undefined ? Plasmoid.configuration.panelShowArtist : true
    readonly property bool cfg_panelAutoFontSize: Plasmoid.configuration.panelAutoFontSize !== undefined ? Plasmoid.configuration.panelAutoFontSize : true
    readonly property bool cfg_panelScrollingText: Plasmoid.configuration.panelScrollingText !== undefined ? Plasmoid.configuration.panelScrollingText : true
    readonly property int cfg_panelMaxWidth: Plasmoid.configuration.panelMaxWidth !== undefined ? Plasmoid.configuration.panelMaxWidth : 350
    readonly property int cfg_panelScrollingSpeed: Plasmoid.configuration.panelScrollingSpeed !== undefined ? Plasmoid.configuration.panelScrollingSpeed : 0
    readonly property int cfg_panelFontSize: Plasmoid.configuration.panelFontSize !== undefined ? Plasmoid.configuration.panelFontSize : 12
    readonly property int cfg_panelLayoutMode: Plasmoid.configuration.panelLayoutMode !== undefined ? Plasmoid.configuration.panelLayoutMode : 0
    readonly property bool cfg_panelAutoButtonSize: Plasmoid.configuration.panelAutoButtonSize !== undefined ? Plasmoid.configuration.panelAutoButtonSize : true
    readonly property int cfg_panelButtonSize: Plasmoid.configuration.panelButtonSize !== undefined ? Plasmoid.configuration.panelButtonSize : 32
    readonly property bool cfg_panelDynamicWidth: Plasmoid.configuration.panelDynamicWidth !== undefined ? Plasmoid.configuration.panelDynamicWidth : true
    readonly property int cfg_popupLayoutMode: Plasmoid.configuration.popupLayoutMode !== undefined ? Plasmoid.configuration.popupLayoutMode : 0
    readonly property double cfg_backgroundOpacity: Plasmoid.configuration.backgroundOpacity !== undefined ? Plasmoid.configuration.backgroundOpacity : 0.8

    // Panel Detection
    readonly property bool isInPanel: (Plasmoid.formFactor == PlasmaCore.Types.Horizontal || Plasmoid.formFactor == PlasmaCore.Types.Vertical)

    // ---------------------------------------------------------
    // Data Source - Lazy Loaded MPRIS Models
    // ---------------------------------------------------------
    
    // Main MPRIS model - always needed
    Mpris.Mpris2Model { id: mpris2Model }
    
    // Probe model - only created when needed for smart player detection
    Loader {
        id: probeModelLoader
        active: preferredPlayer === "" // Only active in "General" mode
        sourceComponent: Mpris.Mpris2Model {}
    }
    
    readonly property var probeModel: probeModelLoader.item

    // ---------------------------------------------------------
    // Smart Player Selection
    // ---------------------------------------------------------
    property var currentPlayer: null
    
    function findSmartPlayer() {
        // If a specific player is pinned, look for it in the main model
        if (preferredPlayer !== "") {
            var count = mpris2Model.rowCount()
            for (var i = 0; i < count; i++) {
                mpris2Model.currentIndex = i
                var player = mpris2Model.currentPlayer
                if (player && player.identity && player.identity.toLowerCase().includes(preferredPlayer.toLowerCase())) {
                    return player
                }
            }
            return null
        }
        
        // "General" Mode: Use probe model if available
        if (!probeModel) return mpris2Model.currentPlayer
        
        var count = probeModel.rowCount()
        var pausedCandidate = null
        var anyCandidate = null
        
        for (var i = 0; i < count; i++) {
            probeModel.currentIndex = i
            var player = probeModel.currentPlayer
            
            if (player) {
                // Priority 1: Playing
                if (player.playbackStatus === Mpris.PlaybackStatus.Playing) {
                    return player
                }
                // Priority 2: Paused
                if (player.playbackStatus === Mpris.PlaybackStatus.Paused) {
                    if (!pausedCandidate || (mpris2Model.currentPlayer && player.identity === mpris2Model.currentPlayer.identity)) {
                        pausedCandidate = player
                    }
                }
                // Priority 3: Any
                if (!anyCandidate) {
                    anyCandidate = player
                }
            }
        }
        
        return pausedCandidate || anyCandidate || mpris2Model.currentPlayer
    }
    
    function updateCurrentPlayer() {
        currentPlayer = findSmartPlayer()
    }
    
    // Watch for players appearing/disappearing - connect to appropriate model
    Connections {
        target: probeModel || mpris2Model
        function onRowsInserted() { root.updateCurrentPlayer() }
        function onRowsRemoved() { root.updateCurrentPlayer() }
        function onModelReset() { root.updateCurrentPlayer() }
    }
    
    // Smart player switch timer - only active in General mode
    Timer {
        interval: 1500 // Slightly longer interval for better performance
        running: preferredPlayer === "" && root.visible
        repeat: true
        onTriggered: {
            var smart = findSmartPlayer()
            if (smart !== currentPlayer) {
                currentPlayer = smart
            }
        }
    }
    
    onPreferredPlayerChanged: updateCurrentPlayer()
    
    Component.onCompleted: {
        // Defer initial player detection for faster startup
        Qt.callLater(updateCurrentPlayer)
    }

    // ---------------------------------------------------------
    // Player State Properties (Computed on-demand)
    // ---------------------------------------------------------
    readonly property bool hasPlayer: !!currentPlayer
    readonly property bool isPlaying: currentPlayer ? currentPlayer.playbackStatus === Mpris.PlaybackStatus.Playing : false
    readonly property string artUrl: currentPlayer ? currentPlayer.artUrl : ""
    readonly property bool hasArt: artUrl !== ""
    readonly property string title: currentPlayer ? currentPlayer.track : i18n("No Media Playing")
    readonly property string artist: currentPlayer ? currentPlayer.artist : ""
    readonly property real length: currentPlayer ? currentPlayer.length : 0
    readonly property string playerIdentity: currentPlayer ? currentPlayer.identity : preferredPlayer
    
    property real currentPosition: 0
    
    // Position Sync - Lazy connection
    Connections {
        target: currentPlayer
        enabled: !!currentPlayer
        function onPositionChanged() {
            var diff = Math.abs(root.currentPosition - currentPlayer.position)
            if (diff > 2000000) root.currentPosition = currentPlayer.position
        }
    }
    
    // Position timer - only runs when playing
    Timer {
        interval: 1000
        running: root.isPlaying && root.visible
        repeat: true
        onTriggered: if (root.currentPosition < root.length) root.currentPosition += 1000000
    }
    
    onCurrentPlayerChanged: root.currentPosition = currentPlayer ? currentPlayer.position : 0

    // ---------------------------------------------------------
    // Player Control Functions
    // ---------------------------------------------------------
    function togglePlayPause() {
        if (currentPlayer) currentPlayer.PlayPause()
    }
    
    function previous() {
        if (currentPlayer) currentPlayer.Previous()
    }
    
    function next() {
        if (currentPlayer) currentPlayer.Next()
    }
    
    function seek(micros) {
        if (currentPlayer) {
            currentPlayer.Seek(micros - root.currentPosition)
            root.currentPosition = micros
        }
    }
    
    function launchApp(appId) {
        var desktopFile = PlayerData.getDesktopFile(appId || preferredPlayer)
        Qt.openUrlExternally("file:///usr/share/applications/" + desktopFile)
    }
    
    function getPlayerIcon(identity) {
        return PlayerData.getPlayerIcon(identity)
    }

    // ---------------------------------------------------------
    // Representations
    // ---------------------------------------------------------
    preferredRepresentation: isInPanel ? compactRepresentation : fullRepresentation
    
    // ---------------------------------------------------------
    // Compact Representation (Panel Mode)
    // ---------------------------------------------------------
    compactRepresentation: Item {
        id: compactRep
        
        // Text measurement for dynamic width
        TextMetrics {
            id: titleMetrics
            font.family: "Roboto Condensed"
            font.bold: true
            font.pixelSize: root.cfg_panelAutoFontSize 
                ? Math.max(10, Math.min(compactRep.height * 0.5, 16)) 
                : root.cfg_panelFontSize
            text: root.title || i18n("No Media")
        }
        
        TextMetrics {
            id: artistMetrics
            font.family: "Roboto Condensed"
            font.pixelSize: root.cfg_panelAutoFontSize
                ? Math.max(9, Math.min(compactRep.height * 0.4, 13))
                : Math.max(9, root.cfg_panelFontSize - 2)
            text: root.artist || ""
        }
        
        // Calculate controls width
        readonly property int controlsWidth: {
            if (!root.showPanelControls) return 0
            var btnSize = root.cfg_panelAutoButtonSize ? Math.min(compactRep.height * 0.9, 36) : root.cfg_panelButtonSize
            if (root.cfg_panelLayoutMode === 2) return btnSize * 2 + 20
            return btnSize * 3 + 10
        }
        
        // Calculate text width
        readonly property int textWidth: {
            var titleW = titleMetrics.advanceWidth
            var artistW = root.cfg_panelShowArtist && root.artist ? artistMetrics.advanceWidth : 0
            return Math.max(titleW, artistW)
        }
        
        // Calculate total dynamic width
        readonly property int dynamicContentWidth: {
            var spacing = root.showPanelControls ? 20 : 10
            var total = textWidth + controlsWidth + spacing
            return Math.min(Math.max(total, 100), root.cfg_panelMaxWidth)
        }
        
        Layout.preferredWidth: root.cfg_panelDynamicWidth ? dynamicContentWidth : root.cfg_panelMaxWidth
        Layout.maximumWidth: root.cfg_panelMaxWidth
        Layout.minimumWidth: 50
        
        Loader {
            id: panelModeLoader
            anchors.fill: parent
            asynchronous: true
            source: "modes/PanelMode.qml"
            
            onLoaded: {
                if (item) {
                    // Bind all properties
                    item.hasArt = Qt.binding(() => root.hasArt)
                    item.artUrl = Qt.binding(() => root.artUrl)
                    item.title = Qt.binding(() => root.title)
                    item.artist = Qt.binding(() => root.artist)
                    item.playerIdentity = Qt.binding(() => root.playerIdentity)
                    item.hasPlayer = Qt.binding(() => root.hasPlayer)
                    item.preferredPlayer = Qt.binding(() => root.preferredPlayer)
                    item.isPlaying = Qt.binding(() => root.isPlaying)
                    item.currentPosition = Qt.binding(() => root.currentPosition)
                    item.length = Qt.binding(() => root.length)
                    item.showPanelControls = Qt.binding(() => root.showPanelControls)
                    item.showTitle = Qt.binding(() => root.cfg_panelShowTitle)
                    item.showArtist = Qt.binding(() => root.cfg_panelShowArtist)
                    item.autoFontSize = Qt.binding(() => root.cfg_panelAutoFontSize)
                    item.scrollingText = Qt.binding(() => root.cfg_panelScrollingText)
                    item.maxWidth = Qt.binding(() => root.cfg_panelMaxWidth)
                    item.scrollingSpeed = Qt.binding(() => root.cfg_panelScrollingSpeed)
                    item.manualFontSize = Qt.binding(() => root.cfg_panelFontSize)
                    item.layoutMode = Qt.binding(() => root.cfg_panelLayoutMode)
                    item.dynamicWidth = Qt.binding(() => root.cfg_panelDynamicWidth)
                    item.autoButtonSize = Qt.binding(() => root.cfg_panelAutoButtonSize)
                    item.buttonSize = Qt.binding(() => root.cfg_panelButtonSize)
                    
                    // Callbacks
                    item.onPrevious = root.previous
                    item.onPlayPause = root.togglePlayPause
                    item.onNext = root.next
                    item.onSeek = root.seek
                    item.onExpand = () => { root.expanded = !root.expanded }
                    item.onLaunchApp = () => { root.launchApp(root.preferredPlayer) }
                }
            }
        }
        
        // Fallback click handler
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.expanded = !root.expanded
        }
    }
    
    // ---------------------------------------------------------
    // Full Representation (Desktop/Popup Mode)
    // ---------------------------------------------------------
    fullRepresentation: Item {
        id: fullRep
        anchors.fill: parent
        
        // Mode Detection - Computed properties
        readonly property bool isLargeSq: (root.height > 350) && (root.width < root.height * 1.05)
        readonly property bool isWide: !isLargeSq && (root.width > (root.height * 1.05))
        
        // Current mode for loader
        readonly property string currentMode: {
            if (cfg_popupLayoutMode === 1) return "compact"
            if (cfg_popupLayoutMode === 2) return "wide"
            if (cfg_popupLayoutMode === 3) return "largeSquare"
            
            // Auto Mode
            if (root.isInPanel) return "largeSquare"
            if (isLargeSq) return "largeSquare"
            if (isWide) return "wide"
            return "compact"
        }
        
        Rectangle {
            id: mainRect
            anchors.fill: parent
            anchors.margins: Plasmoid.configuration.edgeMargin !== undefined ? Plasmoid.configuration.edgeMargin : 10
            color: root.isInPanel ? "transparent" : Kirigami.Theme.backgroundColor
            opacity: root.isInPanel ? 1 : root.cfg_backgroundOpacity
            radius: 20
            clip: true
            
            // Lazy Loader for Mode Components
            Loader {
                id: modeLoader
                anchors.fill: parent
                asynchronous: true
                active: root.visible || root.expanded // Only load when visible
                
                source: {
                    switch (fullRep.currentMode) {
                        case "compact": return "modes/CompactMode.qml"
                        case "wide": return "modes/WideMode.qml"
                        case "largeSquare": return "modes/LargeSquareMode.qml"
                        default: return "modes/LargeSquareMode.qml" 
                    }
                }
                
                // Loading indicator
                BusyIndicator {
                    anchors.centerIn: parent
                    running: modeLoader.status === Loader.Loading
                    visible: running
                    width: 32
                    height: 32
                }
                
                onLoaded: {
                    if (item) {
                        // Common properties - use arrow function bindings for efficiency
                        item.hasArt = Qt.binding(() => root.hasArt)
                        item.artUrl = Qt.binding(() => root.artUrl)
                        item.title = Qt.binding(() => root.title)
                        item.playerIdentity = Qt.binding(() => root.playerIdentity)
                        item.hasPlayer = Qt.binding(() => root.hasPlayer)
                        item.preferredPlayer = Qt.binding(() => root.preferredPlayer)
                        item.isPlaying = Qt.binding(() => root.isPlaying)
                        item.currentPosition = Qt.binding(() => root.currentPosition)
                        item.length = Qt.binding(() => root.length)
                        item.noMediaText = Qt.binding(() => i18n("No Media Playing"))
                        
                        // Optional properties
                        if (item.hasOwnProperty("showPlayerBadge")) {
                            item.showPlayerBadge = Qt.binding(() => root.showPlayerBadge)
                        }
                        if (item.hasOwnProperty("artist")) {
                            item.artist = Qt.binding(() => root.artist)
                        }
                        if (item.hasOwnProperty("prevText")) {
                            item.prevText = Qt.binding(() => i18n("Previous Track"))
                        }
                        if (item.hasOwnProperty("nextText")) {
                            item.nextText = Qt.binding(() => i18n("Next Track"))
                        }
                        
                        // Callbacks
                        item.onPrevious = root.previous
                        item.onPlayPause = root.togglePlayPause
                        item.onNext = root.next
                        item.onSeek = root.seek
                        item.onLaunchApp = () => { root.launchApp(root.preferredPlayer) }
                        item.getPlayerIcon = root.getPlayerIcon
                    }
                }
            }
        }
    }
}
