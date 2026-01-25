import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components" as Components
import "../js/PlayerData.js" as PlayerData

// LargeSquareMode.qml - Büyük kare mod UI with lazy loading
Item {
    id: largeSquareMode
    
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
    property string noMediaText: "No Media"
    property bool showPlayerBadge: true
    
    // Callbacks
    property var onPrevious: function() {}
    property var onPlayPause: function() {}
    property var onNext: function() {}
    property var onSeek: function(pos) {}
    property var onLaunchApp: function() {}
    property var getPlayerIcon: function(id) { return "multimedia-player" }
    
    // Cached color
    readonly property color controlButtonBgColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
    
    // Album Cover (Top) - Lazy loaded
    Loader {
        id: albumCoverLoader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomControls.top
        anchors.margins: 10
        anchors.bottomMargin: 0
        asynchronous: true
        
        sourceComponent: Components.AlbumCover {
            radius: 10
            
            artUrl: largeSquareMode.artUrl
            hasArt: largeSquareMode.hasArt
            noMediaText: largeSquareMode.noMediaText
            playerIdentity: largeSquareMode.playerIdentity
            playerIcon: largeSquareMode.getPlayerIcon(largeSquareMode.playerIdentity)
            hasPlayer: largeSquareMode.hasPlayer
            preferredPlayer: largeSquareMode.preferredPlayer
            onLaunchApp: largeSquareMode.onLaunchApp
            showPlayerBadge: largeSquareMode.showPlayerBadge
            
            pillMode: true
            showNoMediaText: false
            showDimOverlay: false
            showGradient: false
            showCenterPlayIcon: false
            isPlaying: largeSquareMode.isPlaying
        }
    }
    
    // Bottom Controls
    Item {
        id: bottomControls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: colLayout.implicitHeight
        anchors.margins: 15
        
        ColumnLayout {
            id: colLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 5
            
            // Title
            Text {
                text: largeSquareMode.title === "" ? i18n("No Media Playing") : largeSquareMode.title
                font.family: "Roboto Condensed"
                font.bold: true
                font.pixelSize: 22
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }
            
            // Bottom Row: Slider/Info + Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                
                // Left: Info & Slider
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                    spacing: 2
                    
                    // Seek Bar - Only visible when there's a track
                    Loader {
                        id: seekBarLoader
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        active: largeSquareMode.length > 0
                        
                        sourceComponent: MouseArea {
                            id: seekArea
                            property bool dragging: false
                            
                            onPressed: dragging = true
                            onReleased: {
                                dragging = false
                                largeSquareMode.onSeek((mouseX / width) * largeSquareMode.length)
                            }
                            
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                            }
                            
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                height: 6
                                radius: 3
                                color: Kirigami.Theme.highlightColor
                                width: {
                                    if (largeSquareMode.length <= 0) return 0
                                    var pos = seekArea.dragging ? (seekArea.mouseX / seekArea.width) * largeSquareMode.length : largeSquareMode.currentPosition
                                    return Math.max(0, Math.min(parent.width, (pos / largeSquareMode.length) * parent.width))
                                }
                            }
                            
                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: Kirigami.Theme.highlightColor
                                anchors.verticalCenter: parent.verticalCenter
                                x: {
                                    if (largeSquareMode.length <= 0) return -width / 2
                                    var pos = seekArea.dragging ? (seekArea.mouseX / seekArea.width) * largeSquareMode.length : largeSquareMode.currentPosition
                                    return (parent.width * (pos / largeSquareMode.length)) - width / 2
                                }
                            }
                        }
                    }
                    
                    // Time & Artist Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Text {
                            text: PlayerData.formatTime(largeSquareMode.currentPosition)
                            font.pixelSize: 11
                            color: Kirigami.Theme.textColor
                            opacity: 0.7
                        }
                        
                        Text {
                            text: largeSquareMode.artist === "" ? "..." : largeSquareMode.artist
                            font.family: "Roboto Condensed"
                            font.pixelSize: 14
                            color: Kirigami.Theme.textColor
                            opacity: 0.7
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: PlayerData.formatTime(largeSquareMode.length)
                            font.pixelSize: 11
                            color: Kirigami.Theme.textColor
                            opacity: 0.7
                        }
                    }
                }
                
                // Right: Buttons
                Components.MediaControlRow {
                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    
                    baseSize: 36
                    expandAmount: 20
                    iconScale: 0.6
                    bgColor: largeSquareMode.controlButtonBgColor
                    
                    isPlaying: largeSquareMode.isPlaying
                    onPrevious: largeSquareMode.onPrevious
                    onPlayPause: largeSquareMode.onPlayPause
                    onNext: largeSquareMode.onNext
                }
            }
        }
    }
}
