import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root

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
    readonly property var currentPlayer: mpris2Model.currentPlayer
    readonly property bool hasPlayer: !!currentPlayer
    readonly property bool isPlaying: currentPlayer ? currentPlayer.playbackStatus === Mpris.PlaybackStatus.Playing : false
    readonly property string artUrl: currentPlayer ? currentPlayer.artUrl : ""
    readonly property bool hasArt: artUrl != ""
    readonly property string title: currentPlayer ? currentPlayer.track : "Müzik Yok"
    readonly property string artist: currentPlayer ? currentPlayer.artist : ""
    readonly property real length: currentPlayer ? currentPlayer.length : 0
    
    property real currentPosition: 0
    
    // Sync Logic
    Connections {
        target: currentPlayer
        function onPositionChanged() {
            var diff = Math.abs(root.currentPosition - currentPlayer.position)
            if (diff > 2000000) root.currentPosition = currentPlayer.position
        }
    }
    Timer {
        interval: 1000; running: root.isPlaying; repeat: true
        onTriggered: if (root.currentPosition < root.length) root.currentPosition += 1000 * 1000
    }
    onCurrentPlayerChanged: root.currentPosition = currentPlayer ? currentPlayer.position : 0
    
    function togglePlayPause() { if (currentPlayer) currentPlayer.PlayPause() }
    function seek(micros) {
        if (currentPlayer) {
            currentPlayer.Seek(micros - root.currentPosition)
            root.currentPosition = micros
        }
    }

    // ---------------------------------------------------------
    // Visual Layout (Carousel Style)
    // ---------------------------------------------------------
    
    // Internal Hover States
    property bool leftHovered: false
    property bool rightHovered: false
    property bool centerHovered: false
    
    readonly property color controlButtonBgColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)

    preferredRepresentation: fullRepresentation
    
    fullRepresentation: Item {
        id: fullRep
        anchors.fill: parent
        
        // Large Square Mode Trigger:
        // Height > 350 AND Aspect Ratio Difference < 0.15 (Square-ish)
        readonly property bool isLargeSq: (root.height > 350) && (root.width < root.height * 1.05)

        // Wide Mode is active only if NOT Large Square and Width > Height * 1.05
        readonly property bool isWide: !isLargeSq && (root.width > (root.height * 1.05))
        
        Rectangle {
            id: mainRect
            anchors.fill: parent
            anchors.margins: 10
            color: Kirigami.Theme.backgroundColor
            radius: 20
            clip: true
            
            // ------------------------------------------------------------------
            // COMPACT MODE: Side Reveal Texts (Background Layer)
            // ------------------------------------------------------------------
            Item {
                id: compactSideTexts
                anchors.fill: parent
                opacity: (fullRep.isWide || fullRep.isLargeSq) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                Item {
                    id: prevTextContainer
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: prevText.implicitHeight + 20
                    Text {
                        id: prevText
                        anchors.centerIn: parent
                        text: "Önceki Müzik"; color: Kirigami.Theme.textColor
                        font.bold: true; font.pixelSize: 13; rotation: 270
                    }
                }
                Item {
                    id: nextTextContainer
                    anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: nextText.implicitHeight + 20
                    Text {
                        id: nextText
                        anchors.centerIn: parent
                        text: "Sonraki Müzik"; color: Kirigami.Theme.textColor
                        font.bold: true; font.pixelSize: 13; rotation: 90
                    }
                }
            }

            // ------------------------------------------------------------------
            // SHARED: Album Cover Container
            // ------------------------------------------------------------------
            Item {
                id: albumCoverContainer
                
                // Layout Logic:
                // Wide: Anchored Left, Square Aspect
                // Compact: Fills Parent (minus animated margins)
                
                anchors.top: parent.top
                anchors.bottom: fullRep.isLargeSq ? largeSquareControls.top : parent.bottom
                anchors.left: parent.left
                
                // Layout Logic:
                // Wide: Left anchor, Square (width=height)
                // LargeSq: Top anchor, Full Width (minus margin), Height fills space above controls
                // Compact: Full Fill
                
                anchors.right: (fullRep.isWide || fullRep.isLargeSq) ? (fullRep.isLargeSq ? parent.right : undefined) : parent.right
                
                width: fullRep.isWide ? height : undefined 
                height: undefined // Fully dynamic based on anchors
                
                // Margins Logic
                // Wide: Fixed standard margin
                // Compact: Animated slide margin
                property real slideLeftMargin: (!fullRep.isWide && root.leftHovered) ? prevTextContainer.width : 0
                property real slideRightMargin: (!fullRep.isWide && root.rightHovered) ? nextTextContainer.width : 0
                
                anchors.leftMargin: fullRep.isWide ? 10 : (fullRep.isLargeSq ? 10 : slideLeftMargin)
                anchors.rightMargin: fullRep.isWide ? 0 : (fullRep.isLargeSq ? 10 : slideRightMargin)
                anchors.topMargin: (fullRep.isWide || fullRep.isLargeSq) ? 10 : 0
                anchors.bottomMargin: fullRep.isWide ? 10 : 0 // In LargeSq, bottom isn't anchored, height is set

                // Animations for smooth transition
                Behavior on anchors.leftMargin { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on anchors.rightMargin { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on anchors.bottomMargin { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                
                z: 10 

                Rectangle {
                    id: bgRect
                    anchors.fill: parent
                    radius: 10
                    color: root.hasArt ? "#2a2a2a" : Kirigami.Theme.backgroundColor
                    clip: true
                    
                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: root.hasArt
                    }
                    
                    // Compact Overlays (Dimming etc)
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        // Only show dimming in compact mode (Not Wide, Not LargeSq)
                        opacity: (!fullRep.isWide && !fullRep.isLargeSq && root.centerHovered && root.isPlaying) ? 0.4 : 0.1
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        visible: root.hasArt
                    }
                    
                    // Compact Gradient
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                        height: parent.height / 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: "black" }
                        }
                        visible: root.hasArt && !fullRep.isWide && !fullRep.isLargeSq
                        opacity: (fullRep.isWide || fullRep.isLargeSq) ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }

                    // Compact: Center Play Icon
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 48; height: 48
                        source: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                        color: "white"
                        visible: (!fullRep.isWide && !fullRep.isLargeSq) && (root.centerHovered || !root.isPlaying)
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // Compact: Bottom Controls
                    Item {
                        id: compactBottomControls
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.margins: 15
                        height: 50
                        visible: root.length > 0
                        opacity: (fullRep.isWide || fullRep.isLargeSq) ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        
                        // Seek Bar (Compact)
                        MouseArea {
                            id: seekAreaCompact
                            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: timeRowCompact.top; anchors.bottomMargin: 8
                            height: 10
                            property bool dragging: false
                            onPressed: dragging = true
                            onReleased: { dragging = false; root.seek((mouseX / width) * root.length) }
                            
                            Rectangle { anchors.centerIn: parent; width: parent.width; height: 4; radius: 2; color: "#4dffffff" }
                            Rectangle {
                                height: 4; radius: 2; color: Kirigami.Theme.highlightColor
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(0, Math.min(parent.width, ((seekAreaCompact.dragging ? (seekAreaCompact.mouseX/seekAreaCompact.width)*root.length : root.currentPosition)/root.length)*parent.width))
                            }
                        }
                        
                        Item {
                            id: timeRowCompact
                            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 20
                            Text { text: formatTime(root.currentPosition); color: "white"; font.bold: true; anchors.left: parent.left }
                            Text { text: formatTime(root.length); color: "white"; font.bold: true; anchors.right: parent.right }
                            Text { text: root.title; color: "white"; elide: Text.ElideRight; anchors.centerIn: parent; width: parent.width - 80; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }
            }
            
            // ------------------------------------------------------------------
            // WIDE MODE: Right Side Controls
            // ------------------------------------------------------------------
            Item {
                id: wideControls
                anchors.left: albumCoverContainer.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 10
                
                opacity: fullRep.isWide ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
                
                // 1. Song Info (Top-Left)
                ColumnLayout {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: progressItem.top
                    spacing: 0
                    
                    Text {
                        id: titleText
                        text: root.title
                        color: Kirigami.Theme.textColor
                        font.family: "Roboto Condensed"
                        font.bold: true
                        
                        // Adaptive Font Logic
                        property real maxFontSize: Math.min(30, parent.width * 0.14)
                        property real animFontSize: maxFontSize
                        
                        font.pixelSize: animFontSize
                        Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                        
                        onMaxFontSizeChanged: animFontSize = maxFontSize
                        onTextChanged: animFontSize = maxFontSize
                        
                        // Shrink if truncated
                        Timer {
                            id: shrinkTimer
                            interval: 200 // Wait slightly longer than animation
                            running: titleText.truncated && titleText.animFontSize > 12 && titleText.visible
                            repeat: true
                            onTriggered: {
                                if (titleText.truncated) {
                                    titleText.animFontSize -= 2
                                }
                            }
                        }
                        // Trigger check immediately on truncate change
                        onTruncatedChanged: if (truncated) shrinkTimer.start()

                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        Layout.maximumHeight: parent.height * 0.55 // Limit height so Artist is visible
                    }
                    Text {
                        text: root.artist
                        color: Kirigami.Theme.textColor
                        opacity: 0.7
                        font.family: "Roboto Condensed"
                        font.pixelSize: Math.min(14, parent.width * 0.07) // Responsive font
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Item { Layout.fillHeight: true } // Spacer
                }
                
                // 2. Progress Section (Middle)
                Item {
                    id: progressItem
                    anchors.bottom: controlsRow.top
                    anchors.bottomMargin: 0 // Touching the buttons
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 30
                    visible: root.length > 0
                    
                    // Slider Background
                    MouseArea {
                        id: seekAreaWide
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        height: 20
                        property bool dragging: false
                        onPressed: dragging = true
                        onReleased: { dragging = false; root.seek((mouseX / width) * root.length) }
                        
                        Rectangle {
                            anchors.centerIn: parent; width: parent.width; height: 6; radius: 3
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                        }
                        Rectangle {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            height: 6; radius: 3; color: Kirigami.Theme.highlightColor
                            width: Math.max(0, Math.min(parent.width, ((seekAreaWide.dragging ? (seekAreaWide.mouseX/seekAreaWide.width)*root.length : root.currentPosition)/root.length)*parent.width))
                        }
                        Rectangle {
                            width: 16; height: 16; radius: 8; color: Kirigami.Theme.highlightColor
                            anchors.verticalCenter: parent.verticalCenter
                            x: (parent.width * ((seekAreaWide.dragging ? (seekAreaWide.mouseX/seekAreaWide.width)*root.length : root.currentPosition)/root.length)) - width/2
                        }
                    }
                    
                    Text {
                        anchors.left: parent.left; anchors.top: seekAreaWide.bottom
                        text: formatTime(root.currentPosition); font.pixelSize: 11; color: Kirigami.Theme.textColor; opacity: 0.7
                    }
                    Text {
                        anchors.right: parent.right; anchors.top: seekAreaWide.bottom
                        text: formatTime(root.length); font.pixelSize: 11; color: Kirigami.Theme.textColor; opacity: 0.7
                    }
                }
                
                // 3. Controls Row (Bottom Center)
                RowLayout {
                    id: controlsRow
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    
                    // Shared press state tracking
                    property bool prevPressed: false
                    property bool playPressed: false
                    property bool nextPressed: false
                    property real baseSize: Math.min(42, parent.width * 0.18)
                    property real expandAmount: 20
                    
                    // Previous Button - Rectangle anchored LEFT (expands to right)
                    Item {
                        id: prevBtnWide
                        Layout.preferredWidth: controlsRow.baseSize + (controlsRow.prevPressed ? controlsRow.expandAmount : 0) - (controlsRow.playPressed ? controlsRow.expandAmount / 2 : 0)
                        Layout.preferredHeight: controlsRow.baseSize
                        
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: 5
                            color: root.controlButtonBgColor
                            
                            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                        
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            source: "media-skip-backward"
                            width: controlsRow.baseSize * 0.6; height: controlsRow.baseSize * 0.6
                            color: Kirigami.Theme.textColor
                            opacity: 0.9
                        }
                        MouseArea { 
                            anchors.fill: parent
                            onPressed: controlsRow.prevPressed = true
                            onReleased: { controlsRow.prevPressed = false; if(currentPlayer) currentPlayer.Previous() }
                            onCanceled: controlsRow.prevPressed = false
                        }
                    }
                    
                    // Play/Pause Button (Middle) - Rectangle stays centered
                    Item {
                        id: playBtnWide
                        Layout.preferredWidth: controlsRow.baseSize + (controlsRow.playPressed ? controlsRow.expandAmount : 0) - (controlsRow.prevPressed ? controlsRow.expandAmount / 2 : 0) - (controlsRow.nextPressed ? controlsRow.expandAmount / 2 : 0)
                        Layout.preferredHeight: controlsRow.baseSize
                        
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: 5
                            color: root.controlButtonBgColor
                        }
                        
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            source: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                            width: controlsRow.baseSize * 0.6; height: controlsRow.baseSize * 0.6
                            color: Kirigami.Theme.textColor
                            opacity: 0.9
                        }
                        MouseArea { 
                            anchors.fill: parent
                            onPressed: controlsRow.playPressed = true
                            onReleased: { controlsRow.playPressed = false; root.togglePlayPause() }
                            onCanceled: controlsRow.playPressed = false
                        }
                    }
                    
                    // Next Button - Rectangle anchored RIGHT (expands to left)
                    Item {
                        id: nextBtnWide
                        Layout.preferredWidth: controlsRow.baseSize + (controlsRow.nextPressed ? controlsRow.expandAmount : 0) - (controlsRow.playPressed ? controlsRow.expandAmount / 2 : 0)
                        Layout.preferredHeight: controlsRow.baseSize
                        
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: 5
                            color: root.controlButtonBgColor
                        }
                        
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            source: "media-skip-forward"
                            width: controlsRow.baseSize * 0.6; height: controlsRow.baseSize * 0.6
                            color: Kirigami.Theme.textColor
                            opacity: 0.9
                        }
                        MouseArea { 
                            anchors.fill: parent
                            onPressed: controlsRow.nextPressed = true
                            onReleased: { controlsRow.nextPressed = false; if(currentPlayer) currentPlayer.Next() }
                            onCanceled: controlsRow.nextPressed = false
                        }
                    }
                }

            } // End Wide Controls

            // ------------------------------------------------------------------
            // LARGE SQUARE MODE: Bottom Controls
            // ------------------------------------------------------------------
            Item {
                id: largeSquareControls
                // Remove anchors.top to allow it to sit at bottom with intrinsic height
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: colLayout.implicitHeight // Autosize to content
                anchors.margins: 15
                
                opacity: fullRep.isLargeSq ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
                
                ColumnLayout {
                    id: colLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: 5
                    
                    // Top: Title Full Width
                    Text {
                        text: root.title
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

                    // Bottom: Slider/Info + Buttons
                    RowLayout {
                        Layout.fillWidth: true

                        spacing: 15
                        
                        // LEFT: Info & Slider
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignBottom
                            spacing: 2
                            
                            // Slider Box
                            MouseArea {
                                id: seekAreaLarge
                                Layout.fillWidth: true
                                height: 16 // Touch area
                                property bool dragging: false
                                onPressAndHold: dragging = true // Actually onPressed is better
                                onPressed: dragging = true
                                onReleased: { dragging = false; root.seek((mouseX / width) * root.length) }
                                
                                Rectangle {
                                    anchors.centerIn: parent; width: parent.width; height: 6; radius: 3
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                                }
                                Rectangle {
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                    height: 6; radius: 3; color: Kirigami.Theme.highlightColor
                                    width: Math.max(0, Math.min(parent.width, ((seekAreaLarge.dragging ? (seekAreaLarge.mouseX/seekAreaLarge.width)*root.length : root.currentPosition)/root.length)*parent.width))
                                }
                                Rectangle {
                                    width: 14; height: 14; radius: 7; color: Kirigami.Theme.highlightColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: (parent.width * ((seekAreaLarge.dragging ? (seekAreaLarge.mouseX/seekAreaLarge.width)*root.length : root.currentPosition)/root.length)) - width/2
                                }
                            }
                            
                            // Time & Artist Row (Under Slider)
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: formatTime(root.currentPosition); font.pixelSize: 11; color: Kirigami.Theme.textColor; opacity: 0.7 }
                                Item { Layout.fillWidth: true }
                                Text { 
                                    text: root.artist
                                    font.family: "Roboto Condensed"
                                    font.pixelSize: 13
                                    color: Kirigami.Theme.textColor
                                    opacity: 0.7
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: parent.width * 0.4 
                                }
                                Item { Layout.fillWidth: true }
                                Text { text: formatTime(root.length); font.pixelSize: 11; color: Kirigami.Theme.textColor; opacity: 0.7 }
                            }
                        }
                        
                        // RIGHT: Buttons
                        RowLayout {
                            id: controlsRowLarge
                            Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                            spacing: 4
                            
                            // Shared press state tracking
                            property bool prevPressed: false
                            property bool playPressed: false
                            property bool nextPressed: false
                            property real baseSize: 36
                            property real expandAmount: 20
                            
                            // Prev - Rectangle anchored LEFT (expands to right)
                            Item {
                                id: prevBtnLarge
                                Layout.preferredWidth: controlsRowLarge.baseSize + (controlsRowLarge.prevPressed ? controlsRowLarge.expandAmount : 0) - (controlsRowLarge.playPressed ? controlsRowLarge.expandAmount / 2 : 0)
                                Layout.preferredHeight: controlsRowLarge.baseSize
                                
                                Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    radius: 5
                                    color: root.controlButtonBgColor
                                }
                                Kirigami.Icon { 
                                    anchors.centerIn: parent
                                    source: "media-skip-backward"; width: 22; height: 22; color: Kirigami.Theme.textColor; opacity: 0.9 
                                }
                                MouseArea { 
                                    anchors.fill: parent
                                    onPressed: controlsRowLarge.prevPressed = true
                                    onReleased: { controlsRowLarge.prevPressed = false; if(currentPlayer) currentPlayer.Previous() }
                                    onCanceled: controlsRowLarge.prevPressed = false
                                }
                            }
                            
                            // Play - Rectangle stays centered
                            Item {
                                id: playBtnLarge
                                Layout.preferredWidth: controlsRowLarge.baseSize + (controlsRowLarge.playPressed ? controlsRowLarge.expandAmount : 0) - (controlsRowLarge.prevPressed ? controlsRowLarge.expandAmount / 2 : 0) - (controlsRowLarge.nextPressed ? controlsRowLarge.expandAmount / 2 : 0)
                                Layout.preferredHeight: controlsRowLarge.baseSize
                                
                                Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    radius: 5
                                    color: root.controlButtonBgColor
                                }
                                Kirigami.Icon { anchors.centerIn: parent; source: root.isPlaying ? "media-playback-pause" : "media-playback-start"; width: 22; height: 22; color: Kirigami.Theme.textColor; opacity: 0.9 }
                                MouseArea { 
                                    anchors.fill: parent
                                    onPressed: controlsRowLarge.playPressed = true
                                    onReleased: { controlsRowLarge.playPressed = false; root.togglePlayPause() }
                                    onCanceled: controlsRowLarge.playPressed = false
                                }
                            }
                            
                            // Next - Rectangle anchored RIGHT (expands to left)
                            Item {
                                id: nextBtnLarge
                                Layout.preferredWidth: controlsRowLarge.baseSize + (controlsRowLarge.nextPressed ? controlsRowLarge.expandAmount : 0) - (controlsRowLarge.playPressed ? controlsRowLarge.expandAmount / 2 : 0)
                                Layout.preferredHeight: controlsRowLarge.baseSize
                                
                                Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    radius: 5
                                    color: root.controlButtonBgColor
                                }
                                Kirigami.Icon { 
                                    anchors.centerIn: parent
                                    source: "media-skip-forward"; width: 22; height: 22; color: Kirigami.Theme.textColor; opacity: 0.9 
                                }
                                MouseArea { 
                                    anchors.fill: parent
                                    onPressed: controlsRowLarge.nextPressed = true
                                    onReleased: { controlsRowLarge.nextPressed = false; if(currentPlayer) currentPlayer.Next() }
                                    onCanceled: controlsRowLarge.nextPressed = false
                                }
                            }
                        }



                    }
                }
            }
        } // End MainRect
        
        // ---------------------------------------------------------
        // Hit Test Zones for Compact Mode (Disable in Wide)
        // ---------------------------------------------------------
        Item {
            anchors.fill: parent
            visible: !(fullRep.isWide || fullRep.isLargeSq) // Only active in Compact Mode
            
            MouseArea {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: prevTextContainer.width + 10
                hoverEnabled: true; z: 100
                onEntered: root.leftHovered = true; onExited: root.leftHovered = false
                onClicked: if (root.currentPlayer) root.currentPlayer.Previous()
            }
            MouseArea {
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: nextTextContainer.width + 10
                hoverEnabled: true; z: 100
                onEntered: root.rightHovered = true; onExited: root.rightHovered = false
                onClicked: if (root.currentPlayer) root.currentPlayer.Next()
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: 60 // Approximate center
                hoverEnabled: true; z: 90
                onEntered: root.centerHovered = true; onExited: root.centerHovered = false
                onClicked: root.togglePlayPause()
            }
        }
        
        function formatTime(micros) {
            var s = Math.floor(micros / 1000000); var m = Math.floor(s / 60); s = s % 60
            return m + ":" + (s < 10 ? "0" + s : s)
        }
    }
}
