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
    property var locales: {
        "en": { "no_media_playing": "No Media Playing", "prev_track": "Previous", "next_track": "Next" },
        "tr": { "no_media_playing": "Çalan Medya Yok", "prev_track": "Önceki", "next_track": "Sonraki" }
    }
    property string currentLocale: Qt.locale().name.substring(0, 2)
    
    function loadLocales() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "localization.json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        locales = JSON.parse(xhr.responseText)
                    } catch (e) {
                        console.log("Error parsing localization.json: " + e)
                    }
                }
            }
        }
        xhr.send()
    }
    
    Component.onCompleted: loadLocales()

    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) {
            return locales[currentLocale][key]
        }
        if (locales["en"] && locales["en"][key]) {
            return locales["en"][key]
        }
        return key
    }

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
    
    // Find player matching the preferred player from all available players
    function findPreferredPlayer() {
        if (preferredPlayer === "") {
            return mpris2Model.currentPlayer
        }
        
        var count = mpris2Model.rowCount()
        for (var i = 0; i < count; i++) {
            var savedIndex = mpris2Model.currentIndex
            mpris2Model.currentIndex = i
            var player = mpris2Model.currentPlayer
            mpris2Model.currentIndex = savedIndex
            
            if (player && player.identity && player.identity.toLowerCase().includes(preferredPlayer.toLowerCase())) {
                return player
            }
        }
        return null
    }
    
    // Reactively determine the smart player
    property var currentPlayer: findPreferredPlayer()
    
    // Re-evaluate when model changes
    Connections {
        target: mpris2Model
        function onRowsInserted() { root.currentPlayer = Qt.binding(function() { return findPreferredPlayer() }) }
        function onRowsRemoved() { root.currentPlayer = Qt.binding(function() { return findPreferredPlayer() }) }
        function onDataChanged() { root.currentPlayer = Qt.binding(function() { return findPreferredPlayer() }) }
    }
    
    // Player state properties
    readonly property bool hasPlayer: !!currentPlayer
    readonly property bool isPlaying: currentPlayer ? currentPlayer.playbackStatus === Mpris.PlaybackStatus.Playing : false
    readonly property string artUrl: currentPlayer ? currentPlayer.artUrl : ""
    readonly property bool hasArt: artUrl != ""
    readonly property string title: currentPlayer ? currentPlayer.track : root.tr("no_media_playing")
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
                        item.noMediaText = Qt.binding(function() { return root.tr("no_media_playing") })
                        
                        // Artist (Wide and LargeSquare modes)
                        if (item.hasOwnProperty("artist")) {
                            item.artist = Qt.binding(function() { return root.artist })
                        }
                        
                        // Compact mode specific
                        if (item.hasOwnProperty("prevText")) {
                            item.prevText = Qt.binding(function() { return root.tr("prev_track") })
                        }
                        if (item.hasOwnProperty("nextText")) {
                            item.nextText = Qt.binding(function() { return root.tr("next_track") })
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
