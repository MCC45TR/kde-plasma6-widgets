import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components" as Components
import "../js/PlayerData.js" as PlayerData

// WideMode.qml - Geniş mod UI
Item {
    id: wideMode
    
    // Properties from parent (not required, set by Loader)
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
    
    // Callbacks
    property var onPrevious: function() {}
    property var onPlayPause: function() {}
    property var onNext: function() {}
    property var onSeek: function(pos) {}
    property var onLaunchApp: function() {}
    property var getPlayerIcon: function(id) { return "multimedia-player" }
    
    readonly property color controlButtonBgColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
    
    // Album Cover (Left Side)
    Item {
        id: albumCoverContainer
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 10
        width: height // Square
        
        Components.AlbumCover {
            anchors.fill: parent
            radius: 10
            
            artUrl: wideMode.artUrl
            hasArt: wideMode.hasArt
            noMediaText: wideMode.noMediaText
            playerIdentity: wideMode.playerIdentity
            playerIcon: wideMode.getPlayerIcon(wideMode.playerIdentity)
            hasPlayer: wideMode.hasPlayer
            preferredPlayer: wideMode.preferredPlayer
            onLaunchApp: wideMode.onLaunchApp
            
            pillMode: true
            showNoMediaText: false
            showDimOverlay: false
            showGradient: false
            showCenterPlayIcon: false
            isPlaying: wideMode.isPlaying
        }
    }
    
    // Right Side Controls
    Item {
        id: controlsContainer
        anchors.left: albumCoverContainer.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 10
        
        // Song Info (Top)
        ColumnLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: progressItem.top
            spacing: 0
            
            Text {
                id: titleText
                text: wideMode.title
                color: Kirigami.Theme.textColor
                font.family: "Roboto Condensed"
                font.bold: true
                
                property real maxFontSize: Math.min(30, parent.width * 0.14)
                property real animFontSize: maxFontSize
                
                font.pixelSize: animFontSize
                Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                
                onMaxFontSizeChanged: animFontSize = maxFontSize
                onTextChanged: animFontSize = maxFontSize
                
                Timer {
                    id: shrinkTimer
                    interval: 200
                    running: titleText.truncated && titleText.animFontSize > 12 && titleText.visible
                    repeat: true
                    onTriggered: {
                        if (titleText.truncated) {
                            titleText.animFontSize -= 2
                        }
                    }
                }
                onTruncatedChanged: if (truncated) shrinkTimer.start()
                
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.maximumHeight: parent.height * 0.55
            }
            
            Text {
                text: wideMode.artist
                color: Kirigami.Theme.textColor
                opacity: 0.7
                font.family: "Roboto Condensed"
                font.pixelSize: Math.min(14, parent.width * 0.07)
                elide: Text.ElideRight
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            }
            
            Item { Layout.fillHeight: true }
        }
        
        // Progress Section (Middle)
        Item {
            id: progressItem
            anchors.bottom: controlsRow.top
            anchors.bottomMargin: 0
            anchors.left: parent.left
            anchors.right: parent.right
            height: 30
            visible: wideMode.length > 0
            
            MouseArea {
                id: seekArea
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 20
                property bool dragging: false
                onPressed: dragging = true
                onReleased: {
                    dragging = false
                    wideMode.onSeek((mouseX / width) * wideMode.length)
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
                        if (wideMode.length <= 0) return 0
                        var pos = seekArea.dragging ? (seekArea.mouseX / seekArea.width) * wideMode.length : wideMode.currentPosition
                        return Math.max(0, Math.min(parent.width, (pos / wideMode.length) * parent.width))
                    }
                }
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: Kirigami.Theme.highlightColor
                    anchors.verticalCenter: parent.verticalCenter
                    x: {
                        if (wideMode.length <= 0) return -width / 2
                        var pos = seekArea.dragging ? (seekArea.mouseX / seekArea.width) * wideMode.length : wideMode.currentPosition
                        return (parent.width * (pos / wideMode.length)) - width / 2
                    }
                }
            }
            
            Text {
                anchors.left: parent.left
                anchors.top: seekArea.bottom
                text: PlayerData.formatTime(wideMode.currentPosition)
                font.pixelSize: 11
                color: Kirigami.Theme.textColor
                opacity: 0.7
            }
            Text {
                anchors.right: parent.right
                anchors.top: seekArea.bottom
                text: PlayerData.formatTime(wideMode.length)
                font.pixelSize: 11
                color: Kirigami.Theme.textColor
                opacity: 0.7
            }
        }
        
        // Controls Row (Bottom)
        Components.MediaControlRow {
            id: controlsRow
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            
            baseSize: Math.min(42, parent.width * 0.18)
            expandAmount: 20
            iconScale: 0.6
            bgColor: wideMode.controlButtonBgColor
            
            isPlaying: wideMode.isPlaying
            onPrevious: wideMode.onPrevious
            onPlayPause: wideMode.onPlayPause
            onNext: wideMode.onNext
        }
    }
}
