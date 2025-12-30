import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: carouselRoot
    
    // Properties to control the animation and data
    property string artUrl: ""
    property bool isPlaying: false
    property bool canGoPrevious: false
    property bool canGoNext: false

    signal previousClicked()
    signal nextClicked()
    signal playPauseClicked()
    signal seek(real position)
    
    // Properties from parent (pass through)
    property string trackTitle: ""
    property real currentPosition: 0
    property real trackLength: 0
    
    // Internal State
    property bool leftHovered: false
    property bool rightHovered: false
    property bool centerHovered: false

    // Main Container Area
    Item {
        id: container
        anchors.fill: parent
        anchors.margins: 10 // Global margin
        
        // 1. Previous Button (Left Underlayer)
        Item {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            z: 0
            
            Kirigami.Icon {
                 anchors.centerIn: parent
                 width: 32
                 height: 32
                 source: "media-skip-backward"
                 color: Kirigami.Theme.textColor
                 visible: carouselRoot.canGoPrevious
            }
        }
        
        // 2. Next Button (Right Underlayer)
        Item {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            z: 0
            
            Kirigami.Icon {
                 anchors.centerIn: parent
                 width: 32
                 height: 32
                 source: "media-skip-forward"
                 color: Kirigami.Theme.textColor
                 visible: carouselRoot.canGoNext
            }
        }
        
        // 3. Album Art Card (The Sliding Part)
        Rectangle {
            id: albumCard
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            // Width is dynamic: parent width. 
            // Margins animate to reveal buttons.
            anchors.left: parent.left
            anchors.right: parent.right
            
            // Animation behaviors
            Behavior on anchors.leftMargin { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on anchors.rightMargin { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            
            // Logic: Hovering left -> Huge left margin? No, hovering Left means we want to see the Left button.
            // So we must shrink the card from the Left. i.e., increase Left Margin.
            anchors.leftMargin: carouselRoot.leftHovered ? 50 : 0
            
            // Hovering right -> Shrink from Right.
            anchors.rightMargin: carouselRoot.rightHovered ? 50 : 0
            
            radius: 20
            color: carouselRoot.artUrl ? "#2a2a2a" : Kirigami.Theme.backgroundColor
            clip: true // Round clip the art
            z: 10 // Above buttons
            
            // Art Image
            Image {
                anchors.fill: parent
                source: carouselRoot.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: carouselRoot.artUrl !== ""
            }
            
            // Dim Overlay
             Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.3
                visible: carouselRoot.artUrl !== ""
            }
            
            // Play/Pause Icon (Center)
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 48
                height: 48
                source: carouselRoot.isPlaying ? "media-playback-pause" : "media-playback-start"
                color: "white"
                visible: carouselRoot.centerHovered || !carouselRoot.isPlaying
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            
            // Bottom Info & Controls
            Item {
                 anchors.left: parent.left
                 anchors.right: parent.right
                 anchors.bottom: parent.bottom
                 height: 60
                 visible: carouselRoot.trackLength > 0
                 
                 // Reuse your seek bar and text logic here...
                 // Simplification for brevity in this structure test
                 Text {
                     anchors.centerIn: parent
                     text: carouselRoot.trackTitle
                     color: "white"
                     elide: Text.ElideRight
                 }
            }
        }
    }
    
    // Mouse Areas (Overlay on top of everything to catch hovers)
    
    // Left Zone (Includes the 50px area + some safety)
    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 60
        hoverEnabled: true
        z: 100
        onEntered: carouselRoot.leftHovered = true
        onExited: carouselRoot.leftHovered = false
        onClicked: carouselRoot.previousClicked()
    }
    
    // Right Zone
    MouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 60
        hoverEnabled: true
        z: 100
        onEntered: carouselRoot.rightHovered = true
        onExited: carouselRoot.rightHovered = false
        onClicked: carouselRoot.nextClicked()
    }
    
    // Center Zone
    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 60
        anchors.rightMargin: 60
        hoverEnabled: true
        z: 100
        onEntered: carouselRoot.centerHovered = true
        onExited: carouselRoot.centerHovered = false
        onClicked: carouselRoot.playPauseClicked()
    }
}
