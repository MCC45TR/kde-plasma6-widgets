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
    
    // Album Art Image - Lazy loaded when artUrl is available
    Loader {
        id: artImageLoader
        anchors.fill: parent
        active: albumCover.hasArt && albumCover.artUrl !== ""
        asynchronous: true
        
        sourceComponent: Image {
            source: albumCover.artUrl
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
        }
    }
    
    // App Badge - Lazy loaded when visible
    Loader {
        id: appBadgeLoader
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 5
        anchors.topMargin: 5
        active: albumCover.showPlayerBadge && (albumCover.playerIdentity !== "" || albumCover.hasPlayer)
        
        sourceComponent: AppBadge {
            pillMode: albumCover.pillMode
            iconSize: pillMode ? 16 : Math.max(16, albumCover.width * 0.09)
            playerIdentity: albumCover.playerIdentity
            iconSource: albumCover.playerIcon
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
        
        sourceComponent: Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                width: parent.width * 0.8
                
                // Default Placeholder (Always show if no art)
                Loader {
                    Layout.preferredWidth: parent.width * 0.5
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignHCenter
                    active: true
                    
                    sourceComponent: Image {
                        source: "../../images/album.png"
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.8
                        asynchronous: true
                    }
                }

                // Player Icon (Disabled in center, we used album.png instead)
                Loader {
                    Layout.preferredWidth: parent.width * 0.5
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignHCenter
                    active: false
                    
                    sourceComponent: Kirigami.Icon {
                        source: albumCover.playerIcon
                        opacity: albumCover.showCenterPlayIcon ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                }
                
                Text {
                    text: albumCover.noMediaText
                    font.family: "Roboto Condensed"
                    font.bold: true
                    font.pixelSize: 16
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                    visible: albumCover.showNoMediaText && !albumCover.hasPlayer
                }
            }
        }
    }
    
    // Dim Overlay - Lazy loaded when needed
    Loader {
        id: dimOverlayLoader
        anchors.fill: parent
        active: albumCover.hasArt || albumCover.hasPlayer
        
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
        active: albumCover.showCenterPlayIcon && (albumCover.hasArt || albumCover.hasPlayer)
        
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
