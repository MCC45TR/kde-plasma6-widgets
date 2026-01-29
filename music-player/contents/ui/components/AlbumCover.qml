import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects

// AlbumCover.qml - Albüm kapağı bileşeni with lazy loading
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
    property string placeholderSource: ""
    
    property var playersModel: null
    property var onSwitchPlayer: function(id) {}
    
    // Mode flags
    property bool pillMode: false
    property bool showNoMediaText: true
    property bool showPlayerBadge: true
    
    // Overlay properties
    property bool showDimOverlay: false
    property bool showGradient: false
    property bool showCenterPlayIcon: false
    property bool isPlaying: false
    
    radius: 10
    color: hasArt ? "#2a2a2a" : Kirigami.Theme.backgroundColor
    clip: true
    
    // Only enable layer effect when mask is properly sized
    layer.enabled: maskRectItem.width > 0 && maskRectItem.height > 0
    layer.effect: OpacityMask {
        maskSource: maskRectItem
    }
    
    Rectangle {
        id: maskRectItem
        anchors.fill: parent
        radius: albumCover.radius
        visible: false
    }
    
    // Album Art Image - Lazy loaded when artUrl is available
    Loader {
        id: artImageLoader
        anchors.fill: parent
        active: albumCover.hasArt && albumCover.artUrl !== ""
        asynchronous: true
        
        sourceComponent: Image {
            source: albumCover.artUrl || ""
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            // Use fixed sourceSize to prevent reload during resize animations
            sourceSize.width: 512
            sourceSize.height: 512
        }
    }
    
    // App Badge - Lazy loaded when visible
    // App Badge - Lazy loaded when visible
    Loader {
        id: appBadgeLoader
        
        // Distance from edge (equal for top and left)
        readonly property real distance: 4
        
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: distance
        anchors.topMargin: distance
        active: albumCover.showPlayerBadge && albumCover.hasPlayer && albumCover.playerIdentity !== ""
        
        sourceComponent: AppBadge {
            pillMode: albumCover.pillMode
            
            // User Request: Tile Radius = Background Radius - Distance
            // Therefore: Tile Diameter (Header Height) = 2 * (Background Radius - Distance)
            readonly property real targetDiameter: 2 * (albumCover.radius - appBadgeLoader.distance)
            
            // Calculate iconSize based on targetDiameter
            // AppBadge logic: headerHeight = pillMode ? (iconSize + 9) : (iconSize * 1.25)
            iconSize: {
                var calculated = pillMode ? (targetDiameter - 9) : (targetDiameter / 1.25)
                return Math.max(12, calculated) // Minimum size safe-guard
            }
            
            playerIdentity: albumCover.playerIdentity
            iconSource: albumCover.playerIcon
            preferredPlayer: albumCover.preferredPlayer
            
            playersModel: albumCover.playersModel
            onSwitchPlayer: albumCover.onSwitchPlayer
        }
    }
    
    // Click to launch app when no media
    MouseArea {
        anchors.fill: parent
        visible: !albumCover.hasPlayer && albumCover.preferredPlayer !== ""
        z: 15
        onClicked: albumCover.onLaunchApp()
    }
    
    // Empty/No Media Placeholder - Lazy loaded when no art
    Loader {
        id: placeholderLoader
        anchors.fill: parent
        active: !albumCover.hasArt
        source: albumCover.placeholderSource
        asynchronous: true
        
        onLoaded: {
            if (item) {
                if (item.hasOwnProperty("noMediaText")) item.noMediaText = Qt.binding(() => albumCover.noMediaText)
                if (item.hasOwnProperty("hasPlayer")) item.hasPlayer = Qt.binding(() => albumCover.hasPlayer)
                if (item.hasOwnProperty("showText")) item.showText = Qt.binding(() => albumCover.showNoMediaText)
            }
        }
    }
    
    // Dim Overlay - Lazy loaded when needed
    Loader {
        id: dimOverlayLoader
        anchors.fill: parent
        active: albumCover.hasPlayer
        
        sourceComponent: Rectangle {
            color: "black"
            opacity: albumCover.showDimOverlay ? 0.4 : 0.1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
    
    // Bottom Gradient - Lazy loaded when needed
    Loader {
        id: gradientLoader
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height / 2
        active: albumCover.hasArt && albumCover.showGradient
        
        sourceComponent: Rectangle {
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "black" }
            }
            opacity: albumCover.showGradient ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
    }
    
    // Center Play Icon - Lazy loaded when needed
    Loader {
        id: playIconLoader
        anchors.centerIn: parent
        active: albumCover.showCenterPlayIcon && albumCover.hasPlayer
        
        sourceComponent: Kirigami.Icon {
            width: 48
            height: 48
            source: albumCover.isPlaying ? "media-playback-pause" : "media-playback-start"
            color: "white"
            opacity: 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
