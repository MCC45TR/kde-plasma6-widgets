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
        
        // "General" Mode: Prioritize Playing players
        var count = probeModel.rowCount()
        var bestCandidate = null
        
        for (var i = 0; i < count; i++) {
            probeModel.currentIndex = i
            var player = probeModel.currentPlayer
            
            if (player) {
                // If we find a playing one, return it immediately (or prioritize it)
                if (player.playbackStatus === Mpris.PlaybackStatus.Playing) {
                    return player
                }
                // Keep the "current" one as a fallback if no one is playing
                if (mpris2Model.currentPlayer && player.identity === mpris2Model.currentPlayer.identity) {
                    bestCandidate = player
                }
            }
        }
        
        // Fallback to system default if no one is playing
        return bestCandidate || mpris2Model.currentPlayer
    }
    
    // Reactively determine the smart player
    property var currentPlayer: null
    
    function updateCurrentPlayer() {
        // Use the probe model logic
        currentPlayer = findSmartPlayer()
    }
    
    // Watch for players appearing/disappearing
    Connections {
        target: mpris2Model
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

    preferredRepresentation: fullRepresentation
    
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
            if (isLargeSq) return "largeSquare"
            if (isWide) return "wide"
            return "compact"
        }
        
        Rectangle {
            id: mainRect
            anchors.fill: parent
            anchors.margins: 10
            color: Kirigami.Theme.backgroundColor
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
                        case "wide": return "modes/WideMode.qml"
                        case "largeSquare": return "modes/LargeSquareMode.qml"
                        default: return "modes/CompactMode.qml"
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
