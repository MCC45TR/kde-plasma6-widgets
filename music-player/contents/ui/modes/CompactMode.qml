import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components" as Components
import "../js/PlayerData.js" as PlayerData

// CompactMode.qml - Kompakt mod UI
Item {
    id: compactMode
    
    // Properties from parent (not required, set by Loader)
    property bool hasArt: false
    property string artUrl: ""
    property string title: ""
    property string playerIdentity: ""
    property bool hasPlayer: false
    property string preferredPlayer: ""
    property bool isPlaying: false
    property real currentPosition: 0
    property real length: 0
    property string prevText: "Previous"
    property string nextText: "Next"
    property string noMediaText: "No Media"
    
    // Callbacks
    property var onPrevious: function() {}
    property var onPlayPause: function() {}
    property var onNext: function() {}
    property var onSeek: function(pos) {}
    property var onLaunchApp: function() {}
    property var getPlayerIcon: function(id) { return "multimedia-player" }
    
    // Hover states
    property bool leftHovered: false
    property bool rightHovered: false
    property bool centerHovered: false
    
    // Side Reveal Texts (Background Layer)
    Item {
        id: sideTexts
        anchors.fill: parent
        
        Item {
            id: prevTextContainer
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: prevTextLabel.implicitHeight + 20
            
            Text {
                id: prevTextLabel
                anchors.centerIn: parent
                text: compactMode.prevText
                color: Kirigami.Theme.textColor
                font.bold: true
                font.pixelSize: 13
                rotation: 270
            }
        }
        
        Item {
            id: nextTextContainer
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: nextTextLabel.implicitHeight + 20
            
            Text {
                id: nextTextLabel
                anchors.centerIn: parent
                text: compactMode.nextText
                color: Kirigami.Theme.textColor
                font.bold: true
                font.pixelSize: 13
                rotation: 90
            }
        }
    }
    
    // Album Cover Container with slide animation
    Item {
        id: albumCoverContainer
        anchors.fill: parent
        
        property real slideLeftMargin: compactMode.leftHovered ? prevTextContainer.width : 0
        property real slideRightMargin: compactMode.rightHovered ? nextTextContainer.width : 0
        
        anchors.leftMargin: slideLeftMargin
        anchors.rightMargin: slideRightMargin
        
        Behavior on anchors.leftMargin { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        
        z: 10
        
        Components.AlbumCover {
            anchors.fill: parent
            radius: 20
            
            artUrl: compactMode.artUrl
            hasArt: compactMode.hasArt
            noMediaText: compactMode.noMediaText
            playerIdentity: compactMode.playerIdentity
            playerIcon: compactMode.getPlayerIcon(compactMode.playerIdentity)
            hasPlayer: compactMode.hasPlayer
            preferredPlayer: compactMode.preferredPlayer
            onLaunchApp: compactMode.onLaunchApp
            
            pillMode: false
            showNoMediaText: true
            showDimOverlay: compactMode.centerHovered && compactMode.isPlaying
            showGradient: true
            showCenterPlayIcon: (compactMode.centerHovered || !compactMode.isPlaying)
            isPlaying: compactMode.isPlaying
        }
        
        // Bottom Controls
        Item {
            id: bottomControls
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 15
            height: 50
            visible: compactMode.length > 0
            
            // Seek Bar
            MouseArea {
                id: seekArea
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: timeRow.top
                anchors.bottomMargin: 8
                height: 10
                property bool dragging: false
                onPressed: dragging = true
                onReleased: {
                    dragging = false
                    compactMode.onSeek((mouseX / width) * compactMode.length)
                }
                
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 4
                    radius: 2
                    color: "#4dffffff"
                }
                Rectangle {
                    height: 4
                    radius: 2
                    color: Kirigami.Theme.highlightColor
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: {
                        if (compactMode.length <= 0) return 0
                        var pos = seekArea.dragging ? (seekArea.mouseX / seekArea.width) * compactMode.length : compactMode.currentPosition
                        return Math.max(0, Math.min(parent.width, (pos / compactMode.length) * parent.width))
                    }
                }
            }
            
            Item {
                id: timeRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 20
                
                Text {
                    text: PlayerData.formatTime(compactMode.currentPosition)
                    color: "white"
                    font.bold: true
                    anchors.left: parent.left
                }
                Text {
                    text: PlayerData.formatTime(compactMode.length)
                    color: "white"
                    font.bold: true
                    anchors.right: parent.right
                }
                Text {
                    text: compactMode.title
                    color: "white"
                    elide: Text.ElideRight
                    anchors.centerIn: parent
                    width: parent.width - 80
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    
    // Hit Test Zones
    Item {
        anchors.fill: parent
        z: 100
        
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: prevTextContainer.width + 10
            hoverEnabled: true
            onEntered: compactMode.leftHovered = true
            onExited: compactMode.leftHovered = false
            onClicked: compactMode.onPrevious()
        }
        
        MouseArea {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: nextTextContainer.width + 10
            hoverEnabled: true
            onEntered: compactMode.rightHovered = true
            onExited: compactMode.rightHovered = false
            onClicked: compactMode.onNext()
        }
        
        MouseArea {
            anchors.fill: parent
            anchors.margins: 60
            hoverEnabled: true
            z: -1
            onEntered: compactMode.centerHovered = true
            onExited: compactMode.centerHovered = false
            onClicked: compactMode.onPlayPause()
        }
    }
}
