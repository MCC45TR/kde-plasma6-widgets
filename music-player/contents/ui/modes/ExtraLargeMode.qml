import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components" as Components
import "../js/PlayerData.js" as PlayerData

// ExtraLargeMode.qml - Ekstra büyük mod: Panel popup için varsayılan
Item {
    id: extraLargeMode
    
    // Properties from parent (set by Loader)
    property bool hasArt: false
    property string artUrl: ""
    property string title: ""
    property string artist: ""
    property string playerIdentity: ""
    property bool hasPlayer: false
    property string preferredPlayer: ""
    property bool isPlaying: false
    property real currentPosition: 0
    property real length: 0
    property string noMediaText: i18n("No Media")
    property bool showPlayerBadge: true
    property int radius: 20
    
    // Callbacks
    property var onPrevious: function() {}
    property var onPlayPause: function() {}
    property var onNext: function() {}
    property var onSeek: function(pos) {}
    property var onLaunchApp: function() {}
    property var getPlayerIcon: function(id) { return "multimedia-player" }
    
    property var playersModel: null
    property var onSwitchPlayer: function(id) {}
    
    // Shuffle and Loop
    property bool shuffle: false
    property int loopStatus: 0  // 0=None, 1=Track, 2=Playlist
    property var onToggleShuffle: function() {}
    property var onCycleLoop: function() {}
    
    // 10-second seek
    property var onSeekBack10: function() {}
    property var onSeekForward10: function() {}
    
    // Button visibility settings
    property bool showShuffleButton: true
    property bool showLoopButton: true
    property bool showSeekButtons: true
    
    // Cached colors
    readonly property color buttonBgColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
    readonly property color buttonHoverColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
    
    // Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10
        
        // Album Cover with App Badge
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height * 0.55
            
            Loader {
                id: albumCoverLoader
                anchors.fill: parent
                asynchronous: true
                
                sourceComponent: Components.AlbumCover {
                    radius: Math.max(0, extraLargeMode.radius - 15)
                    
                    artUrl: extraLargeMode.artUrl
                    hasArt: extraLargeMode.hasArt
                    noMediaText: extraLargeMode.noMediaText
                    playerIdentity: extraLargeMode.playerIdentity
                    playerIcon: extraLargeMode.getPlayerIcon(extraLargeMode.playerIdentity)
                    hasPlayer: extraLargeMode.hasPlayer
                    preferredPlayer: extraLargeMode.preferredPlayer
                    onLaunchApp: extraLargeMode.onLaunchApp
                    showPlayerBadge: extraLargeMode.showPlayerBadge
                    placeholderSource: "../placeholders/NoMediaLarge.qml"
                    
                    pillMode: true
                    showNoMediaText: false
                    showDimOverlay: false
                    showGradient: false
                    showCenterPlayIcon: false
                    isPlaying: extraLargeMode.isPlaying
                    
                    playersModel: extraLargeMode.playersModel
                    onSwitchPlayer: extraLargeMode.onSwitchPlayer
                }
            }
        }
        
        // Song Title (Normal weight, centered, large)
        Text {
            text: extraLargeMode.title === "" ? i18n("No Media Playing") : extraLargeMode.title
            font.family: "Roboto Condensed"
            font.bold: false // Normal weight as per user request
            font.pixelSize: 28
            color: Kirigami.Theme.textColor
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }
        
        // Seek Bar Section
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            visible: extraLargeMode.length > 0
            
            MouseArea {
                id: seekArea
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 24
                property bool dragging: false
                
                onPressed: dragging = true
                onReleased: {
                    dragging = false
                    extraLargeMode.onSeek((mouseX / width) * extraLargeMode.length)
                }
                
                // Track background
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                }
                
                // Progress fill (Kirigami highlight color)
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: 6
                    radius: 3
                    color: Kirigami.Theme.highlightColor
                    width: {
                        if (extraLargeMode.length <= 0) return 0
                        var pos = seekArea.dragging ? (seekArea.mouseX / seekArea.width) * extraLargeMode.length : extraLargeMode.currentPosition
                        return Math.max(0, Math.min(parent.width, (pos / extraLargeMode.length) * parent.width))
                    }
                }
                
                // Seek handle (round)
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: Kirigami.Theme.highlightColor
                    anchors.verticalCenter: parent.verticalCenter
                    x: {
                        if (extraLargeMode.length <= 0) return -width / 2
                        var pos = seekArea.dragging ? (seekArea.mouseX / seekArea.width) * extraLargeMode.length : extraLargeMode.currentPosition
                        return (parent.width * (pos / extraLargeMode.length)) - width / 2
                    }
                }
            }
            
            // Time indicators and Artist row
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: seekArea.bottom
                anchors.topMargin: 4
                
                // Current time (left)
                Text {
                    text: PlayerData.formatTime(extraLargeMode.currentPosition)
                    font.pixelSize: 12
                    color: Kirigami.Theme.textColor
                    opacity: 0.7
                }
                
                // Artist name (center)
                Text {
                    text: extraLargeMode.artist === "" ? "..." : extraLargeMode.artist
                    font.family: "Roboto Condensed"
                    font.pixelSize: 14
                    color: Kirigami.Theme.textColor
                    opacity: 0.7
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
                
                // Total time (right)
                Text {
                    text: PlayerData.formatTime(extraLargeMode.length)
                    font.pixelSize: 12
                    color: Kirigami.Theme.textColor
                    opacity: 0.7
                }
            }
        }
        
        // Spacer for when no track is playing
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            visible: extraLargeMode.length <= 0
            
            Text {
                anchors.centerIn: parent
                text: extraLargeMode.artist === "" ? "..." : extraLargeMode.artist
                font.family: "Roboto Condensed"
                font.pixelSize: 14
                color: Kirigami.Theme.textColor
                opacity: 0.7
            }
        }
        
        // Control Buttons Row with Shuffle and Loop
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            
            // Button states for press animation
            property bool shufflePressed: false
            property bool loopPressed: false
            property bool seekBack10Pressed: false
            property bool seekForward10Pressed: false
            
            // Shuffle Button (same style as MediaControlRow)
            Item {
                visible: extraLargeMode.showShuffleButton
                Layout.preferredWidth: 42 + (parent.shufflePressed ? 20 : 0)
                Layout.preferredHeight: 42
                
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: 5
                    color: extraLargeMode.shuffle 
                           ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                           : extraLargeMode.buttonBgColor
                }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 42 * 0.6
                    height: width
                    source: "media-playlist-shuffle"
                    color: extraLargeMode.shuffle ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    opacity: extraLargeMode.shuffle ? 1.0 : 0.9
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPressed: parent.parent.shufflePressed = true
                    onReleased: { parent.parent.shufflePressed = false; extraLargeMode.onToggleShuffle() }
                    onCanceled: parent.parent.shufflePressed = false
                }
            }
            
            // Seek Back 10 seconds Button
            Item {
                visible: extraLargeMode.showSeekButtons
                Layout.preferredWidth: 42 + (parent.seekBack10Pressed ? 20 : 0)
                Layout.preferredHeight: 42
                
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: extraLargeMode.buttonBgColor
                }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 42 * 0.6
                    height: width
                    source: "media-seek-backward"
                    color: Kirigami.Theme.textColor
                    opacity: 0.9
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPressed: parent.parent.seekBack10Pressed = true
                    onReleased: { parent.parent.seekBack10Pressed = false; extraLargeMode.onSeekBack10() }
                    onCanceled: parent.parent.seekBack10Pressed = false
                }
            }
            
            // Main Controls (Previous, Play/Pause, Next)
            Components.MediaControlRow {
                baseSize: 42
                expandAmount: 20
                iconScale: 0.6
                bgColor: extraLargeMode.buttonBgColor
                
                isPlaying: extraLargeMode.isPlaying
                onPrevious: extraLargeMode.onPrevious
                onPlayPause: extraLargeMode.onPlayPause
                onNext: extraLargeMode.onNext
            }
            
            // Seek Forward 10 seconds Button
            Item {
                visible: extraLargeMode.showSeekButtons
                Layout.preferredWidth: 42 + (parent.seekForward10Pressed ? 20 : 0)
                Layout.preferredHeight: 42
                
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: extraLargeMode.buttonBgColor
                }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 42 * 0.6
                    height: width
                    source: "media-seek-forward"
                    color: Kirigami.Theme.textColor
                    opacity: 0.9
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPressed: parent.parent.seekForward10Pressed = true
                    onReleased: { parent.parent.seekForward10Pressed = false; extraLargeMode.onSeekForward10() }
                    onCanceled: parent.parent.seekForward10Pressed = false
                }
            }
            
            // Loop/Repeat Button (same style as MediaControlRow)
            Item {
                visible: extraLargeMode.showLoopButton
                Layout.preferredWidth: 42 + (parent.loopPressed ? 20 : 0)
                Layout.preferredHeight: 42
                
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: 5
                    color: extraLargeMode.loopStatus > 0
                           ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                           : extraLargeMode.buttonBgColor
                }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 42 * 0.6
                    height: width
                    source: extraLargeMode.loopStatus === 1 ? "media-playlist-repeat-song" : "media-playlist-repeat"
                    color: extraLargeMode.loopStatus > 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    opacity: extraLargeMode.loopStatus > 0 ? 1.0 : 0.9
                }
                
                // Badge for loop mode indicator
                Rectangle {
                    visible: extraLargeMode.loopStatus > 0
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 4
                    anchors.bottomMargin: 4
                    width: 12
                    height: 12
                    radius: 6
                    color: Kirigami.Theme.highlightColor
                    
                    Text {
                        anchors.centerIn: parent
                        text: extraLargeMode.loopStatus === 1 ? "1" : "∞"
                        font.pixelSize: extraLargeMode.loopStatus === 1 ? 8 : 10
                        font.bold: true
                        color: Kirigami.Theme.highlightedTextColor
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPressed: parent.parent.loopPressed = true
                    onReleased: { parent.parent.loopPressed = false; extraLargeMode.onCycleLoop() }
                    onCanceled: parent.parent.loopPressed = false
                }
            }
        }
    }
}
