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

    // --- Localization Logic ---
    // Standard Plasma i18n is used now.
    
    // Widget Size Constraints
    Layout.preferredWidth: 200
    Layout.preferredHeight: 200
    Layout.minimumWidth: 150
    Layout.minimumHeight: 150
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ---------------------------------------------------------
    // Data Source
    // ---------------------------------------------------------
    Mpris.Mpris2Model { id: mpris2Model }
    
    // Configuration
    readonly property string preferredPlayer: Plasmoid.configuration.preferredPlayer || ""
    readonly property bool showPlayerBadge: Plasmoid.configuration.showPlayerBadge !== undefined ? Plasmoid.configuration.showPlayerBadge : true
    
    // Secondary model for probing without affecting the main one's state
    Mpris.Mpris2Model { id: probeModel }

    // Smartly find the best player to show
    function findSmartPlayer() {
        // If a specific player is pinned, look for it
        if (preferredPlayer !== "") {
            var count = probeModel.rowCount()
            for (var i = 0; i < count; i++) {
                probeModel.currentIndex = i
                var player = probeModel.currentPlayer
                
                if (player && player.identity && player.identity.toLowerCase().includes(preferredPlayer.toLowerCase())) {
                    return player
                }
            }
            return null
        }
        
        // "General" Mode: Prioritize Playing > Paused > Any
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
                    // If we have multiple paused players, prefer the one that matches system selection
                    if (!pausedCandidate || (mpris2Model.currentPlayer && player.identity === mpris2Model.currentPlayer.identity)) {
                        pausedCandidate = player
                    }
                }
                // Priority 3: Any (Stopped/Unknown)
                if (!anyCandidate) {
                     anyCandidate = player
                }
            }
        }
        
        // Return best match
        return pausedCandidate || anyCandidate || mpris2Model.currentPlayer
    }
    
    // Reactively determine the smart player
    property var currentPlayer: null
    
    function updateCurrentPlayer() {
        // Use the probe model logic
        currentPlayer = findSmartPlayer()
    }
    
    // Watch for players appearing/disappearing
    Connections {
        target: probeModel
        function onRowsInserted() { root.updateCurrentPlayer() }
        function onRowsRemoved() { root.updateCurrentPlayer() }
        function onModelReset() { root.updateCurrentPlayer() }
    }
    
    // Also watch for playback status changes to switch to the playing one dynamically
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            // Periodically check if we should switch focus (e.g. if another player started playing)
            if (preferredPlayer === "") {
                var smart = findSmartPlayer()
                if (smart !== currentPlayer) {
                    currentPlayer = smart
                }
            }
        }
    }
    
    onPreferredPlayerChanged: updateCurrentPlayer()
    
    Component.onCompleted: {
        updateCurrentPlayer()
    }
    
    // Player state properties
    readonly property bool hasPlayer: !!currentPlayer
    readonly property bool isPlaying: currentPlayer ? currentPlayer.playbackStatus === Mpris.PlaybackStatus.Playing : false
    readonly property string artUrl: currentPlayer ? currentPlayer.artUrl : ""
    readonly property bool hasArt: artUrl != ""
    readonly property string title: currentPlayer ? currentPlayer.track : i18n("No Media Playing")
    readonly property string artist: currentPlayer ? currentPlayer.artist : ""
    readonly property real length: currentPlayer ? currentPlayer.length : 0
    readonly property string playerIdentity: currentPlayer ? currentPlayer.identity : preferredPlayer
    
    property real currentPosition: 0
    
    // Position Sync Logic
    Connections {
        target: currentPlayer
        function onPositionChanged() {
            var diff = Math.abs(root.currentPosition - currentPlayer.position)
            if (diff > 2000000) root.currentPosition = currentPlayer.position
        }
    }
    
    Timer {
        interval: 1000
        running: root.isPlaying
        repeat: true
        onTriggered: if (root.currentPosition < root.length) root.currentPosition += 1000 * 1000
    }
    
    onCurrentPlayerChanged: root.currentPosition = currentPlayer ? currentPlayer.position : 0
    
    // Player Control Functions
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

    readonly property bool showPanelControls: Plasmoid.configuration.showPanelControls !== undefined ? Plasmoid.configuration.showPanelControls : true
    readonly property bool cfg_panelShowTitle: Plasmoid.configuration.panelShowTitle !== undefined ? Plasmoid.configuration.panelShowTitle : true
    readonly property bool cfg_panelShowArtist: Plasmoid.configuration.panelShowArtist !== undefined ? Plasmoid.configuration.panelShowArtist : true
    readonly property bool cfg_panelAutoFontSize: Plasmoid.configuration.panelAutoFontSize !== undefined ? Plasmoid.configuration.panelAutoFontSize : true
    readonly property bool cfg_panelScrollingText: Plasmoid.configuration.panelScrollingText !== undefined ? Plasmoid.configuration.panelScrollingText : true
    readonly property int cfg_panelMaxWidth: Plasmoid.configuration.panelMaxWidth !== undefined ? Plasmoid.configuration.panelMaxWidth : 350
    readonly property int cfg_panelScrollingSpeed: Plasmoid.configuration.panelScrollingSpeed !== undefined ? Plasmoid.configuration.panelScrollingSpeed : 0
    readonly property int cfg_panelFontSize: Plasmoid.configuration.panelFontSize !== undefined ? Plasmoid.configuration.panelFontSize : 12
    readonly property int cfg_panelLayoutMode: Plasmoid.configuration.panelLayoutMode !== undefined ? Plasmoid.configuration.panelLayoutMode : 0
    readonly property int cfg_popupLayoutMode: Plasmoid.configuration.popupLayoutMode !== undefined ? Plasmoid.configuration.popupLayoutMode : 0
    readonly property double cfg_backgroundOpacity: Plasmoid.configuration.backgroundOpacity !== undefined ? Plasmoid.configuration.backgroundOpacity : 0.8
    
    // Panel Detection
    readonly property bool isInPanel: (Plasmoid.formFactor == PlasmaCore.Types.Horizontal || Plasmoid.formFactor == PlasmaCore.Types.Vertical)

    preferredRepresentation: isInPanel ? compactRepresentation : fullRepresentation
    
    compactRepresentation: Item {
        id: compactRep
        
        // Use PanelMode from separate file
        Loader {
            anchors.fill: parent
            source: "modes/PanelMode.qml"
            onLoaded: {
                if (item) {
                     item.hasArt = Qt.binding(function() { return root.hasArt })
                     item.artUrl = Qt.binding(function() { return root.artUrl })
                     item.title = Qt.binding(function() { return root.title })
                     item.artist = Qt.binding(function() { return root.artist })
                     item.playerIdentity = Qt.binding(function() { return root.playerIdentity })
                     item.hasPlayer = Qt.binding(function() { return root.hasPlayer })
                     item.preferredPlayer = Qt.binding(function() { return root.preferredPlayer })
                     item.isPlaying = Qt.binding(function() { return root.isPlaying })
                     item.currentPosition = Qt.binding(function() { return root.currentPosition })
                     item.length = Qt.binding(function() { return root.length })
                     
                     item.showPanelControls = Qt.binding(function() { return root.showPanelControls })
                     
                     // New Config Bindings
                     item.showTitle = Qt.binding(function() { return root.cfg_panelShowTitle })
                     item.showArtist = Qt.binding(function() { return root.cfg_panelShowArtist })
                     item.autoFontSize = Qt.binding(function() { return root.cfg_panelAutoFontSize })
                     item.scrollingText = Qt.binding(function() { return root.cfg_panelScrollingText })
                     item.maxWidth = Qt.binding(function() { return root.cfg_panelMaxWidth })
                     item.scrollingSpeed = Qt.binding(function() { return root.cfg_panelScrollingSpeed })
                     item.manualFontSize = Qt.binding(function() { return root.cfg_panelFontSize })
                     item.layoutMode = Qt.binding(function() { return root.cfg_panelLayoutMode })
                     
                     item.onPrevious = root.previous
                     item.onPlayPause = root.togglePlayPause
                     item.onNext = root.next
                     item.onSeek = root.seek
                     item.onExpand = function() { root.expanded = true }
                     item.onLaunchApp = function() { root.launchApp(root.preferredPlayer) }
                }
            }
        }
        
        // Ensure popup opens on click (if not handled by buttons)
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.expanded = true
        }
    }
    
    fullRepresentation: Item {
        id: fullRep
        anchors.fill: parent
        
        // Mode Detection
        // Large Square Mode: Height > 350 AND Aspect Ratio Difference < 0.15 (Square-ish)
        readonly property bool isLargeSq: (root.height > 350) && (root.width < root.height * 1.05)
        // Wide Mode: Not Large Square and Width > Height * 1.05
        readonly property bool isWide: !isLargeSq && (root.width > (root.height * 1.05))
        // Compact Mode: Neither Wide nor Large Square
        readonly property bool isCompact: !isWide && !isLargeSq
        
        // Current mode for loader
        readonly property string currentMode: {
            // View Mode Mapping: 
            // 0: Auto, 1: Small (Compact), 2: Wide, 3: Large
            
            if (cfg_popupLayoutMode === 1) return "compact"
            if (cfg_popupLayoutMode === 2) return "wide"
            if (cfg_popupLayoutMode === 3) return "largeSquare"
            
            // Auto Mode (0)
            
            // If in panel (popup mode), default to LargeSquare
            if (root.isInPanel) return "largeSquare"

            // Fallback to responsive logic (Desktop Auto)
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
                
                // Source based on current mode
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
                }
                
                // Bind properties when loaded
                onLoaded: {
                    if (item) {
                        // Common properties
                        item.hasArt = Qt.binding(function() { return root.hasArt })
                        item.artUrl = Qt.binding(function() { return root.artUrl })
                        item.title = Qt.binding(function() { return root.title })
                        item.playerIdentity = Qt.binding(function() { return root.playerIdentity })
                        item.hasPlayer = Qt.binding(function() { return root.hasPlayer })
                        item.preferredPlayer = Qt.binding(function() { return root.preferredPlayer })
                        item.isPlaying = Qt.binding(function() { return root.isPlaying })
                        item.currentPosition = Qt.binding(function() { return root.currentPosition })
                        item.length = Qt.binding(function() { return root.length })
                        item.noMediaText = Qt.binding(function() { return i18n("No Media Playing") })
                        
                        // Show player badge setting
                        if (item.hasOwnProperty("showPlayerBadge")) {
                            item.showPlayerBadge = Qt.binding(function() { return root.showPlayerBadge })
                        }
                        
                        // Artist (Wide and LargeSquare modes)
                        if (item.hasOwnProperty("artist")) {
                            item.artist = Qt.binding(function() { return root.artist })
                        }
                        
                        // Compact mode specific
                        if (item.hasOwnProperty("prevText")) {
                            item.prevText = Qt.binding(function() { return i18n("Previous Track") })
                        }
                        if (item.hasOwnProperty("nextText")) {
                            item.nextText = Qt.binding(function() { return i18n("Next Track") })
                        }
                        
                        // Callbacks
                        item.onPrevious = root.previous
                        item.onPlayPause = root.togglePlayPause
                        item.onNext = root.next
                        item.onSeek = root.seek
                        item.onLaunchApp = function() { root.launchApp(root.preferredPlayer) }
                        item.getPlayerIcon = root.getPlayerIcon
                    }
                }
            }
        }
    }
}
