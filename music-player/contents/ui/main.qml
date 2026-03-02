import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

import "js/PlayerData.js" as PlayerData
import "components" as Components

PlasmoidItem {
    id: root

    // --- Widget Size Constraints ---
    Layout.preferredWidth: 200
    Layout.preferredHeight: (root.isInPanel && fullRep.badgeExpanded) ? 550 : 200
    Layout.minimumWidth: 150
    Layout.minimumHeight: 150
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ---------------------------------------------------------
    // Configuration (Lazy evaluated)
    // ---------------------------------------------------------
    readonly property string preferredPlayer: Plasmoid.configuration.preferredPlayer || ""
    readonly property bool showPlayerBadge: Plasmoid.configuration.showPlayerBadge !== undefined ? Plasmoid.configuration.showPlayerBadge : true
    readonly property bool autoHideWhenInactive: Plasmoid.configuration.autoHideWhenInactive !== undefined ? Plasmoid.configuration.autoHideWhenInactive : false
    readonly property bool hideWhenNotPlaying: Plasmoid.configuration.hideWhenNotPlaying !== undefined ? Plasmoid.configuration.hideWhenNotPlaying : false
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
    readonly property bool cfg_showShuffleButton: Plasmoid.configuration.showShuffleButton !== undefined ? Plasmoid.configuration.showShuffleButton : true
    readonly property bool cfg_showLoopButton: Plasmoid.configuration.showLoopButton !== undefined ? Plasmoid.configuration.showLoopButton : true
    readonly property bool cfg_showSeekButtons: Plasmoid.configuration.showSeekButtons !== undefined ? Plasmoid.configuration.showSeekButtons : true
    readonly property bool cfg_showVolumeSlider: Plasmoid.configuration.showVolumeSlider !== undefined ? Plasmoid.configuration.showVolumeSlider : false
    readonly property bool cfg_panelShowAlbumArt: Plasmoid.configuration.panelShowAlbumArt !== undefined ? Plasmoid.configuration.panelShowAlbumArt : false
    readonly property int cfg_widgetRadius: Plasmoid.configuration.widgetRadius !== undefined ? Plasmoid.configuration.widgetRadius : 20

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
    
    // Get priority score for a player identity (lower = higher priority)
    function _getPlayerPriorityScore(identity) {
        if (!identity) return 999
        var id = identity.toLowerCase()
        for (var i = 0; i < PlayerData.playerPriority.length; i++) {
            if (id.indexOf(PlayerData.playerPriority[i]) !== -1) {
                return i
            }
        }
        return 500 // Unknown player
    }
    
    // Choose the best player from a list based on PlayerData priority
    function _bestByPriority(candidates) {
        if (candidates.length === 0) return null
        if (candidates.length === 1) return candidates[0]
        
        var best = candidates[0]
        var bestScore = _getPlayerPriorityScore(best.identity)
        
        for (var i = 1; i < candidates.length; i++) {
            var score = _getPlayerPriorityScore(candidates[i].identity)
            if (score < bestScore) {
                bestScore = score
                best = candidates[i]
            }
        }
        return best
    }
    
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
        var playingCandidates = []
        var pausedCandidates = []
        var anyCandidates = []
        
        for (var i = 0; i < count; i++) {
            probeModel.currentIndex = i
            var player = probeModel.currentPlayer
            
            if (player) {
                if (player.playbackStatus === Mpris.PlaybackStatus.Playing) {
                    playingCandidates.push(player)
                } else if (player.playbackStatus === Mpris.PlaybackStatus.Paused) {
                    pausedCandidates.push(player)
                } else {
                    anyCandidates.push(player)
                }
            }
        }
        
        // Priority: Playing > Paused > Any, with PlayerData ranking within each group
        if (playingCandidates.length > 0) return _bestByPriority(playingCandidates)
        if (pausedCandidates.length > 0) return _bestByPriority(pausedCandidates)
        if (anyCandidates.length > 0) return _bestByPriority(anyCandidates)
        
        return mpris2Model.currentPlayer
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
    
    // Smart player switch timer - adaptive intervals
    Timer {
        interval: root.isPlaying ? 2000 : 5000 // Faster when playing, slower when idle
        running: preferredPlayer === "" && root.visible
        repeat: true
        onTriggered: {
            var smart = findSmartPlayer()
            if (smart !== currentPlayer) {
                currentPlayer = smart
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => { updateCurrentPlayer(); updateStatus() })
    }

    // ---------------------------------------------------------
    // Player State Properties (Computed on-demand)
    // ---------------------------------------------------------
    readonly property bool hasPlayer: !!currentPlayer
    readonly property bool isPlaying: currentPlayer ? currentPlayer.playbackStatus === Mpris.PlaybackStatus.Playing : false

    // ---------------------------------------------------------
    // Plasmoid Status (visibility) Logic
    // ---------------------------------------------------------
    function updateStatus() {
        // Rule 1: Not in panel → always passive (desktop widget, no panel slot needed)
        if (!isInPanel) {
            Plasmoid.status = PlasmaCore.Types.PassiveStatus
            return
        }
        // Rule 2: Locked player is missing → passive (autoHide option)
        if (autoHideWhenInactive && preferredPlayer !== "" && !hasPlayer) {
            Plasmoid.status = PlasmaCore.Types.PassiveStatus
            return
        }
        // Rule 3: Nothing playing in panel → passive (hideWhenNotPlaying option)
        if (hideWhenNotPlaying && !isPlaying) {
            Plasmoid.status = PlasmaCore.Types.PassiveStatus
            return
        }
        // Otherwise: active
        Plasmoid.status = PlasmaCore.Types.ActiveStatus
    }

    // Trigger status update on any relevant change
    onIsInPanelChanged: updateStatus()
    onHasPlayerChanged: updateStatus()
    onIsPlayingChanged: updateStatus()
    onAutoHideWhenInactiveChanged: updateStatus()
    onHideWhenNotPlayingChanged: updateStatus()
    onPreferredPlayerChanged: { updateCurrentPlayer(); updateStatus() }
    
    // Album Art Fallback Logic
    Components.AlbumArtFetcher {
        id: artFetcher
        mprisArtUrl: currentPlayer ? currentPlayer.artUrl : ""
        trackUrl: (currentPlayer && currentPlayer.url) ? currentPlayer.url : ""
        artist: currentPlayer ? currentPlayer.artist : ""
        album: (currentPlayer && currentPlayer.album) ? currentPlayer.album : ""
        title: (currentPlayer && currentPlayer.track) ? currentPlayer.track : ""
    }
    
    readonly property string artUrl: artFetcher.effectiveArtUrl
    readonly property bool hasArt: artUrl !== ""
    readonly property string title: currentPlayer ? currentPlayer.track : i18n("No Media Playing")
    readonly property string artist: currentPlayer ? currentPlayer.artist : ""
    readonly property real length: currentPlayer ? currentPlayer.length : 0
    readonly property string playerIdentity: currentPlayer ? currentPlayer.identity : preferredPlayer
    
    // Shuffle and Loop status - use local state for immediate UI feedback
    readonly property bool canControlShuffle: currentPlayer ? currentPlayer.canControl : false
    property bool shuffle: false
    property int loopStatus: 0  // 0=None, 1=Track, 2=Playlist
    
    property real currentPosition: 0
    
    // Sync shuffle/loop/art from player
    Connections {
        target: currentPlayer
        enabled: !!currentPlayer
        
        function onShuffleChanged() {
            var val = currentPlayer.shuffle
            console.log("[MPRIS] Shuffle changed from player:", val, typeof val)
            root.shuffle = val === true || val === 1
        }
        
        function onLoopStatusChanged() {
            var val = currentPlayer.loopStatus
            console.log("[MPRIS] LoopStatus changed from player:", val, typeof val)
            root.loopStatus = Number(val) || 0
        }
        
        // Immediately refresh art when player's art URL changes
        function onArtUrlChanged() {
            artFetcher.mprisArtUrl = currentPlayer.artUrl || ""
            artFetcher.refresh()
        }
        
        // Refresh art on track change
        function onTrackChanged() {
            artFetcher.refresh()
        }
    }
    
    // Initialize shuffle/loop/position when player changes
    onCurrentPlayerChanged: {
        // Clear stale album art from previous player immediately
        artFetcher.clearAndRefresh()
        
        if (currentPlayer) {
            var sh = currentPlayer.shuffle
            var ls = currentPlayer.loopStatus
            console.log("[MPRIS] Player changed. Shuffle:", sh, typeof sh, "| LoopStatus:", ls, typeof ls)
            root.shuffle = sh === true || sh === 1
            root.loopStatus = Number(ls) || 0
            root.currentPosition = currentPlayer.position || 0
        } else {
            root.shuffle = false
            root.loopStatus = 0
            root.currentPosition = 0
        }
    }
    
    // Position Sync - Lazy connection
    Connections {
        target: currentPlayer
        enabled: !!currentPlayer
        function onPositionChanged() {
            // Sync from player on significant difference (>1s)
            var diff = Math.abs(root.currentPosition - currentPlayer.position)
            if (diff > 1000000) root.currentPosition = currentPlayer.position
        }
    }
    
    // Position timer - only runs when playing
    Timer {
        interval: 1000
        running: root.isPlaying && root.visible
        repeat: true
        onTriggered: if (root.currentPosition < root.length) root.currentPosition += 1000000
    }

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
    
    // Absolute seek to a position (microseconds) — used by seek bar drag
    function seek(micros) {
        if (!currentPlayer || !currentPlayer.canSeek) return
        
        var targetPos = Math.max(0, Math.min(root.length, micros))
        
        // Update UI immediately
        root.currentPosition = targetPos
        
        // MPRIS: Use Seek(offset) — this is the standard MPRIS method
        // Seek takes a RELATIVE offset in microseconds
        var offset = targetPos - (currentPlayer.position || 0)
        currentPlayer.Seek(offset)
    }
    
    // Relative seek backward by 10 seconds
    function seekBack10() {
        if (!currentPlayer || !currentPlayer.canSeek) return
        
        var newPos = Math.max(0, root.currentPosition - 10000000)
        root.currentPosition = newPos
        
        // MPRIS Seek() takes relative offset in microseconds
        currentPlayer.Seek(-10000000)
    }
    
    // Relative seek forward by 10 seconds
    function seekForward10() {
        if (!currentPlayer || !currentPlayer.canSeek) return
        
        var newPos = Math.min(root.length, root.currentPosition + 10000000)
        root.currentPosition = newPos
        
        // MPRIS Seek() takes relative offset in microseconds
        currentPlayer.Seek(10000000)
    }
    
    function launchApp(appId) {
        var desktopFile = PlayerData.getDesktopFile(appId || preferredPlayer)
        Qt.openUrlExternally("file:///usr/share/applications/" + desktopFile)
    }
    
    function getPlayerIcon(identity) {
        return PlayerData.getPlayerIcon(identity)
    }
    
    function switchPlayer(identity) {
        Plasmoid.configuration.preferredPlayer = identity
        root.updateCurrentPlayer()
    }
    
    function toggleShuffle() {
        if (!currentPlayer || !currentPlayer.canControl) return
        
        var newShuffle = !root.shuffle
        console.log("[MPRIS] Toggle shuffle:", root.shuffle, "->", newShuffle)
        root.shuffle = newShuffle
        currentPlayer.shuffle = newShuffle
    }
    
    function cycleLoopStatus() {
        if (!currentPlayer || !currentPlayer.canControl) return
        
        var current = root.loopStatus
        var newStatus
        
        // Cycle: None(0) -> Track(1) -> Playlist(2) -> None(0)
        if (current === 0) {
            newStatus = 1
        } else if (current === 1) {
            newStatus = 2
        } else {
            newStatus = 0
        }
        
        console.log("[MPRIS] Cycle loop:", current, "->", newStatus)
        root.loopStatus = newStatus
        currentPlayer.loopStatus = newStatus
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
                ? Math.max(5, Math.min(compactRep.height * 0.5, 16)) 
                : root.cfg_panelFontSize
            text: root.title || i18n("No Media")
        }
        
        TextMetrics {
            id: artistMetrics
            font.family: "Roboto Condensed"
            font.pixelSize: root.cfg_panelAutoFontSize
                ? Math.max(5, Math.min(compactRep.height * 0.4, 13))
                : Math.max(5, root.cfg_panelFontSize - 2)
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
            var total = textWidth + controlsWidth + spacing + 30 // Extra buffer to prevent truncation
            return Math.max(total, 100)
        }
        
        Layout.preferredWidth: root.cfg_panelDynamicWidth ? dynamicContentWidth : root.cfg_panelMaxWidth
        Layout.maximumWidth: root.cfg_panelDynamicWidth ? -1 : root.cfg_panelMaxWidth
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
                    if (item.hasOwnProperty("showAlbumArt")) {
                        item.showAlbumArt = Qt.binding(() => root.cfg_panelShowAlbumArt)
                    }

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
        
        readonly property bool badgeExpanded: modeLoader.item ? modeLoader.item.badgeExpanded : false
        
        // Mode Detection - Computed properties
        readonly property bool isWide: root.width > 300
        readonly property bool isLargeSq: (root.height > 250) && isWide
        
        // Current mode for loader
        readonly property string currentMode: {
            if (cfg_popupLayoutMode === 1) return "compact"
            if (cfg_popupLayoutMode === 2) return "wide"
            if (cfg_popupLayoutMode === 3) return "largeSquare"
            if (cfg_popupLayoutMode === 4) return "extraLarge"
            
            // Auto Mode
            if (root.isInPanel) return "extraLarge"  // Extra Large for panel popup
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
            radius: root.cfg_widgetRadius
            clip: modeLoader.item ? !modeLoader.item.badgeExpanded : true
            
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
                        case "extraLarge": return "modes/ExtraLargeMode.qml"
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
                        item.radius = Qt.binding(() => root.cfg_widgetRadius)
                        
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
                        
                        // Shuffle and Loop (optional - only for ExtraLargeMode)
                        if (item.hasOwnProperty("shuffle")) {
                            item.shuffle = Qt.binding(() => root.shuffle)
                        }
                        if (item.hasOwnProperty("loopStatus")) {
                            item.loopStatus = Qt.binding(() => root.loopStatus)
                        }
                        if (item.hasOwnProperty("onToggleShuffle")) {
                            item.onToggleShuffle = root.toggleShuffle
                        }
                        if (item.hasOwnProperty("onCycleLoop")) {
                            item.onCycleLoop = root.cycleLoopStatus
                        }
                        
                        // 10-second seek (optional - only for ExtraLargeMode)
                        if (item.hasOwnProperty("onSeekBack10")) {
                            item.onSeekBack10 = root.seekBack10
                        }
                        if (item.hasOwnProperty("onSeekForward10")) {
                            item.onSeekForward10 = root.seekForward10
                        }
                        
                        // Button visibility settings (only for ExtraLargeMode)
                        if (item.hasOwnProperty("showShuffleButton")) {
                            item.showShuffleButton = Qt.binding(() => root.cfg_showShuffleButton)
                        }
                        if (item.hasOwnProperty("showLoopButton")) {
                            item.showLoopButton = Qt.binding(() => root.cfg_showLoopButton)
                        }
                        if (item.hasOwnProperty("showSeekButtons")) {
                            item.showSeekButtons = Qt.binding(() => root.cfg_showSeekButtons)
                        }
                        if (item.hasOwnProperty("showVolumeSlider")) {
                            item.showVolumeSlider = Qt.binding(() => root.cfg_showVolumeSlider)
                        }
                        if (item.hasOwnProperty("currentVolume")) {
                            item.currentVolume = Qt.binding(() => root.currentPlayer ? root.currentPlayer.volume : 1.0)
                        }
                        if (item.hasOwnProperty("onSetVolume")) {
                            item.onSetVolume = (vol) => { if (root.currentPlayer) root.currentPlayer.volume = vol }
                        }
                        
                        // Player Selection
                        if (item.hasOwnProperty("playersModel")) {
                            item.playersModel = mpris2Model
                        }
                        item.onSwitchPlayer = root.switchPlayer
                    }
                }
            }
        }
    }
}
