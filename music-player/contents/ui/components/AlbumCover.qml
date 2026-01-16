import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects

// AlbumCover.qml - Albüm kapağı bileşeni
Rectangle {
    id: albumCover
    
    // Properties (with defaults for Loader compatibility)
    property string artUrl: ""
    property bool hasArt: false
    property string noMediaText: "No Media"
    property string playerIdentity: ""
    property string playerIcon: "multimedia-player"
    property bool hasPlayer: false
    property string preferredPlayer: ""
    property var onLaunchApp: function() {}
    
    // Mode flags
    property bool pillMode: false
    property bool showNoMediaText: true
    
    // Overlay properties
    property bool showDimOverlay: false
    property bool showGradient: false
    property bool showCenterPlayIcon: false
    property bool isPlaying: false
    
    radius: 10
    color: hasArt ? "#2a2a2a" : Kirigami.Theme.backgroundColor
    clip: true
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: maskRectItem
    }
    
    Rectangle {
        id: maskRectItem
        anchors.fill: parent
        radius: albumCover.radius
        visible: false
    }
    
    // Album Art Image
    Image {
        anchors.fill: parent
        source: albumCover.artUrl
        fillMode: Image.PreserveAspectCrop
        visible: albumCover.hasArt
    }
    
    // App Icon Badge
    AppBadge {
        id: appBadge
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 5
        anchors.topMargin: 5
        
        pillMode: albumCover.pillMode
        iconSize: pillMode ? 16 : Math.max(16, parent.width * 0.09)
        playerIdentity: albumCover.playerIdentity
        iconSource: albumCover.playerIcon
        visible: albumCover.playerIdentity !== "" || albumCover.hasPlayer
    }
    
    // Click to launch app when no media
    MouseArea {
        anchors.fill: parent
        visible: !albumCover.hasPlayer && albumCover.preferredPlayer !== ""
        z: 15
        onClicked: albumCover.onLaunchApp()
    }
    
    // Empty/No Media Placeholder
    Item {
        anchors.fill: parent
        visible: !albumCover.hasArt
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width * 0.8
            
            Image {
                Layout.preferredWidth: parent.width * 0.5
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignHCenter
                source: "../../images/album.png"
                fillMode: Image.PreserveAspectFit
                opacity: 0.8
            }
            
            Text {
                text: albumCover.noMediaText
                font.family: "Roboto Condensed"
                font.bold: true
                font.pixelSize: 16
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
                visible: albumCover.showNoMediaText
            }
        }
    }
    
    // Dim Overlay
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: albumCover.showDimOverlay ? 0.4 : 0.1
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: albumCover.hasArt
    }
    
    // Bottom Gradient
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "black" }
        }
        visible: albumCover.hasArt && albumCover.showGradient
        opacity: albumCover.showGradient ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    
    // Center Play Icon
    Kirigami.Icon {
        anchors.centerIn: parent
        width: 48
        height: 48
        source: albumCover.isPlaying ? "media-playback-pause" : "media-playback-start"
        color: "white"
        visible: albumCover.showCenterPlayIcon && albumCover.hasArt
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
