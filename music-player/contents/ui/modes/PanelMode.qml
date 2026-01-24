import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../components" as Components

// PanelMode.qml - Panel representation with enhanced customization
Item {
    id: panelMode
    
    // Properties from parent (Loader)
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
    property bool showPanelControls: true
    
    // Config Properties
    property bool showTitle: true
    property bool showArtist: true
    property bool autoFontSize: true
    property int manualFontSize: 12
    property int layoutMode: 0 // 0: Left, 1: Right, 2: Center
    property bool scrollingText: true
    property int maxWidth: 350
    property int scrollingSpeed: 0 // 0: Fast, 1: Medium, 2: Slow
    
    // Callbacks
    property var onPrevious: function() {}
    property var onPlayPause: function() {}
    property var onNext: function() {}
    property var onSeek: function(pos) {}
    property var onExpand: function() {}
    property var onLaunchApp: function() {}
    
    readonly property color controlButtonBgColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
    
    // Layout Logic
    // Left Mode (0): [Text] [Buttons] [Spacer]
    // Right Mode (1): [Spacer] [Buttons] [Text]
    // Center Mode (2): [Spacer] [Prev] [Text] [Next] [Spacer]
    
    RowLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: panelMode.layoutMode === 2 ? 5 : 10
        layoutDirection: Qt.LeftToRight
        
        // --- RIGHT ALIGN SPACER (Right/Center Mode) ---
        // Pushes content to right in Mode 1.
        // Acts as flexible spring in Mode 2 (Center).
        Item {
            visible: panelMode.layoutMode === 1 || panelMode.layoutMode === 2
            Layout.fillWidth: true
        }

        // --- LEFT CONTROL GROUP (Visible in Right & Center Modes) ---
        // Mode 1 (Right): Full Controls (Buttons on Left of Text)
        // Mode 2 (Center): Prev Button
        Item {
            id: leftControls
            visible: panelMode.showPanelControls && (panelMode.layoutMode === 1 || panelMode.layoutMode === 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Math.min(panelMode.height, 36)
            Layout.preferredWidth: panelMode.layoutMode === 2 ? height : implicitWidth
            
            // Full Controls (Right Mode)
            Components.MediaControlRow {
                anchors.centerIn: parent
                visible: panelMode.layoutMode === 1
                
                baseSize: Math.min(panelMode.height * 0.9, 36)
                expandAmount: 20
                iconScale: 0.6
                bgColor: panelMode.controlButtonBgColor
                
                isPlaying: panelMode.isPlaying
                onPrevious: panelMode.onPrevious
                onPlayPause: panelMode.onPlayPause
                onNext: panelMode.onNext
            }
            
            // Prev Button (Center Mode)
            Rectangle {
                visible: panelMode.layoutMode === 2
                anchors.centerIn: parent
                width: Math.min(panelMode.height * 0.9, 36)
                height: width
                radius: 5
                color: panelMode.controlButtonBgColor
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "media-skip-backward"
                    width: parent.width * 0.6
                    height: width
                    color: Kirigami.Theme.textColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: panelMode.onPrevious()
                }
            }
        }

        // --- TEXT GROUP ---
        Item {
            // Wrapper to hold ColumnLayout and overlapping MouseArea
            Layout.fillWidth: false 
            
            readonly property real maxTextWidth: {
                var spacing = panelMode.layoutMode === 2 ? 5 : 10
                var controlsW = (leftControls.visible ? leftControls.width + spacing : 0) + 
                                (rightControls.visible ? rightControls.width + spacing : 0) +
                                20 // Extra safety for margins
                
                // Limit text width so Total Widget Width ~= maxWidth
                return Math.max(50, panelMode.maxWidth - controlsW)
            }
            
            Layout.maximumWidth: maxTextWidth
            Layout.preferredWidth: panelMode.layoutMode === 2 ? -1 : Math.min(textColumn.implicitWidth, maxTextWidth)
            Layout.alignment: Qt.AlignVCenter
            
            implicitWidth: textColumn.implicitWidth
            implicitHeight: textColumn.implicitHeight
            
            ColumnLayout {
                id: textColumn
                anchors.centerIn: parent
                width: parent.width
                spacing: 0
                
                // Font Logic
                readonly property int calculatedPixelSize: panelMode.autoFontSize 
                    ? Math.max(10, Math.min(panelMode.height * 0.5, 16)) 
                    : panelMode.manualFontSize
                
                readonly property int artistPixelSize: panelMode.autoFontSize
                    ? Math.max(9, Math.min(panelMode.height * 0.4, 13))
                    : Math.max(9, panelMode.manualFontSize - 2)
                
                // Text Alignment
                readonly property int textAlign: {
                    if (panelMode.layoutMode === 1) return Text.AlignRight
                    if (panelMode.layoutMode === 2) return Text.AlignHCenter
                    return Text.AlignLeft
                }
                
                Text {
                    id: titleText
                    text: _scrolledText
                    color: Kirigami.Theme.textColor
                    font.family: "Roboto Condensed"
                    font.bold: true
                    font.pixelSize: parent.calculatedPixelSize
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: parent.textAlign
                    visible: panelMode.showTitle
                    
                    // Scrolling Logic
                    property string fullText: panelMode.title || i18n("No Media")
                    property string _scrolledText: fullText
                    property bool _shouldScroll: false
                    
                    function checkScroll() {
                        if (!panelMode.scrollingText) {
                            _shouldScroll = false
                            _scrolledText = fullText
                            return
                        }
                        if (truncated && !_shouldScroll) {
                            _shouldScroll = true
                            _scrolledText = fullText
                        }
                    }
                    
                    onTruncatedChanged: checkScroll()
                    onFullTextChanged: { _shouldScroll = false; _scrolledText = fullText; Qt.callLater(checkScroll) }
                    
                    Connections {
                        target: panelMode
                        function onScrollingTextChanged() { titleText.checkScroll() }
                    }
                    
                    Timer {
                        interval: panelMode.scrollingSpeed === 1 ? 300 : (panelMode.scrollingSpeed === 2 ? 400 : 200)
                        running: parent._shouldScroll && panelMode.scrollingText
                        repeat: true
                        onTriggered: parent._scrolledText = parent._scrolledText.substring(1) + parent._scrolledText.charAt(0)
                    }
                }
                
                Text {
                    id: artistText
                    text: _scrolledText
                    color: Kirigami.Theme.textColor
                    opacity: 0.8
                    font.family: "Roboto Condensed"
                    font.pixelSize: parent.artistPixelSize
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: parent.textAlign
                    visible: panelMode.showArtist && panelMode.artist !== ""
                    Layout.preferredHeight: visible ? implicitHeight : 0 // Ensure 0 height when hidden
                    Layout.topMargin: visible ? 0 : 0 // Remove margin if hidden
                    
                    // Scrolling Logic
                    property string fullText: panelMode.artist || i18n("Unknown Artist")
                    property string _scrolledText: fullText
                    property bool _shouldScroll: false
                    
                    function checkScroll() {
                         if (!panelMode.scrollingText) {
                            _shouldScroll = false
                            _scrolledText = fullText
                            return
                        }
                        if (truncated && !_shouldScroll) {
                            _shouldScroll = true
                            _scrolledText = fullText
                        }
                    }
                    
                    onTruncatedChanged: checkScroll()
                    onFullTextChanged: { _shouldScroll = false; _scrolledText = fullText; Qt.callLater(checkScroll) }
                     
                    Connections {
                        target: panelMode
                        function onScrollingTextChanged() { artistText.checkScroll() }
                    }
                    
                    Timer {
                        interval: panelMode.scrollingSpeed === 1 ? 300 : (panelMode.scrollingSpeed === 2 ? 400 : 200)
                        running: parent._shouldScroll && panelMode.scrollingText
                        repeat: true
                        onTriggered: parent._scrolledText = parent._scrolledText.substring(1) + parent._scrolledText.charAt(0)
                    }
                }
            }
            
            // Middle Click Area
            MouseArea {
                anchors.fill: parent
                z: 10
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton && panelMode.layoutMode === 2) {
                        panelMode.onPlayPause()
                    } else {
                        panelMode.onExpand()
                    }
                }
            }
        }
        
        // --- RIGHT CONTROL GROUP (Visible in Left & Center Modes) ---
        // Mode 0 (Left): Full Controls (Buttons on Right of Text)
        // Mode 2 (Center): Next Button
        Item {
            id: rightControls
            visible: panelMode.showPanelControls && (panelMode.layoutMode === 0 || panelMode.layoutMode === 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Math.min(panelMode.height, 36)
            Layout.preferredWidth: panelMode.layoutMode === 2 ? height : implicitWidth
            
            // Full Controls (Left Mode - shows on Right)
            Components.MediaControlRow {
                anchors.centerIn: parent
                visible: panelMode.layoutMode === 0
                
                baseSize: Math.min(panelMode.height * 0.9, 36)
                expandAmount: 20
                iconScale: 0.6
                bgColor: panelMode.controlButtonBgColor
                
                isPlaying: panelMode.isPlaying
                onPrevious: panelMode.onPrevious
                onPlayPause: panelMode.onPlayPause
                onNext: panelMode.onNext
            }
            
            // Next Button (Center Mode)
            Rectangle {
                visible: panelMode.layoutMode === 2
                anchors.centerIn: parent
                width: Math.min(panelMode.height * 0.9, 36)
                height: width
                radius: 5
                color: panelMode.controlButtonBgColor
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "media-skip-forward"
                    width: parent.width * 0.6
                    height: width
                    color: Kirigami.Theme.textColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: panelMode.onNext()
                }
            }
        }

        // --- LEFT ALIGN SPACER (Left/Center Mode) ---
        // Pushes content to left in Mode 0.
        // Acts as flexible spring in Mode 2 (Center).
        Item {
            visible: panelMode.layoutMode === 0 || panelMode.layoutMode === 2
            Layout.fillWidth: true
        }
    }
}
