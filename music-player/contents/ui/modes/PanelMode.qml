import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../components" as Components

// PanelMode.qml - Panel representation with enhanced customization and lazy loading
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
    property bool dynamicWidth: true
    property bool autoButtonSize: true
    property int buttonSize: 32
    property int maxWidth: 350
    property int scrollingSpeed: 0 // 0: Fast, 1: Medium, 2: Slow
    property bool showAlbumArt: false
    property bool smoothScrolling: false
    
    // Callbacks
    property var onPrevious: function() {}
    property var onPlayPause: function() {}
    property var onNext: function() {}
    property var onSeek: function(pos) {}
    property var onExpand: function() {}
    property var onLaunchApp: function() {}
    
    // Computed once
    readonly property color controlButtonBgColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
    readonly property int scrollInterval: scrollingSpeed === 1 ? 300 : (scrollingSpeed === 2 ? 400 : 200)
    
    readonly property int calculatedButtonSize: autoButtonSize ? Math.min(panelMode.height * 0.9, 36) : buttonSize
    
    // Dynamic Width Calculation
    readonly property int controlsWidth: {
        if (!showPanelControls) return 0
        var btnSize = calculatedButtonSize
        if (layoutMode === 2) return btnSize * 2 + 20 // Two single buttons + spacing
        return btnSize * 3 + 10 // Full control row (prev, play, next)
    }
    
    readonly property int calculatedTextWidth: {
        var titleW = titleMetrics.advanceWidth
        var artistW = showArtist && panelMode.artist ? artistMetrics.advanceWidth : 0
        return Math.max(titleW, artistW)
    }
    
    readonly property int dynamicImplicitWidth: {
        if (!dynamicWidth) return maxWidth
        var textW = calculatedTextWidth
        var ctrlW = controlsWidth
        var artW = showAlbumArt ? (Math.min(panelMode.height, 28) + 6) : 0
        var spacing = showPanelControls ? 20 : 10
        var total = textW + ctrlW + artW + spacing + 30
        return Math.max(total, 100)
    }
    
    implicitWidth: dynamicImplicitWidth
    
    // Text measurement for dynamic width
    TextMetrics {
        id: titleMetrics
        font.family: "Roboto Condensed"
        font.bold: true
        font.pixelSize: panelMode.autoFontSize 
            ? Math.max(5, Math.min(panelMode.height * 0.5, 16)) 
            : panelMode.manualFontSize
        text: panelMode.title || i18n("No Media")
    }
    
    TextMetrics {
        id: artistMetrics
        font.family: "Roboto Condensed"
        font.pixelSize: panelMode.autoFontSize
            ? Math.max(5, Math.min(panelMode.height * 0.4, 13))
            : Math.max(5, panelMode.manualFontSize - 2)
        text: panelMode.artist || ""
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: panelMode.layoutMode === 2 ? 5 : 10
        layoutDirection: Qt.LeftToRight

        // --- ALBUM ART THUMBNAIL (optional) ---
        Item {
            visible: panelMode.showAlbumArt
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: visible ? Math.min(panelMode.height, 28) : 0
            Layout.preferredHeight: Math.min(panelMode.height, 28)

            Rectangle {
                id: artThumb
                anchors.fill: parent
                radius: width / 2
                clip: true
                color: panelMode.hasArt ? "transparent" : Kirigami.Theme.highlightColor
                opacity: 0.85

                Image {
                    anchors.fill: parent
                    source: panelMode.hasArt ? panelMode.artUrl : ""
                    visible: panelMode.hasArt
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // Placeholder music note when no art
                Text {
                    anchors.centerIn: parent
                    visible: !panelMode.hasArt
                    text: "♪"
                    font.pixelSize: parent.width * 0.55
                    color: Kirigami.Theme.highlightedTextColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Spacers removed - buttons now anchor to edges in all modes

        // --- LEFT CONTROL GROUP (Visible in Right & Center Modes) ---
        Loader {
            id: leftControlsLoader
            active: panelMode.showPanelControls && (panelMode.layoutMode === 1 || panelMode.layoutMode === 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Math.min(panelMode.height, 36)
            Layout.preferredWidth: item ? (panelMode.layoutMode === 2 ? Layout.preferredHeight : item.implicitWidth) : 0
            
            sourceComponent: Item {
                implicitWidth: controlRow.implicitWidth
                implicitHeight: controlRow.implicitHeight
                
                // Full Controls (Right Mode)
                Components.MediaControlRow {
                    id: controlRow
                    anchors.centerIn: parent
                    visible: panelMode.layoutMode === 1
                    
                    baseSize: panelMode.calculatedButtonSize
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
                    width: panelMode.calculatedButtonSize
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
        }

        // --- TEXT GROUP ---
        Item {
            id: textContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 40
            clip: true
            
            ColumnLayout {
                id: textColumn
                anchors.fill: parent
                spacing: 0
                
                // Font Logic - Cached
                readonly property int calculatedPixelSize: panelMode.autoFontSize 
                    ? Math.max(5, Math.min(panelMode.height * 0.5, 16)) 
                    : panelMode.manualFontSize
                
                readonly property int artistPixelSize: panelMode.autoFontSize
                    ? Math.max(5, Math.min(panelMode.height * 0.4, 13))
                    : Math.max(5, panelMode.manualFontSize - 2)
                
                // Text Alignment - Cached
                readonly property int textAlign: {
                    if (panelMode.layoutMode === 1) return Text.AlignRight
                    if (panelMode.layoutMode === 2) return Text.AlignHCenter
                    return Text.AlignLeft
                }

                // Title Section
                Item {
                    id: titleItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: titleMetrics.height
                    Layout.alignment: panelMode.layoutMode === 1 ? Qt.AlignRight : (panelMode.layoutMode === 2 ? Qt.AlignHCenter : Qt.AlignLeft)
                    visible: panelMode.showTitle
                    clip: true

                    readonly property bool overflows: titleMetrics.advanceWidth > parent.width
                    readonly property bool shouldScroll: panelMode.scrollingText && overflows

                    // Smooth Scroll Layer
                    Row {
                        id: titleSmoothRow
                        visible: panelMode.smoothScrolling && parent.shouldScroll
                        x: 0
                        spacing: 40
                        
                        Text {
                            text: titleMetrics.text
                            color: Kirigami.Theme.textColor
                            font: titleMetrics.font
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: titleMetrics.text
                            color: Kirigami.Theme.textColor
                            font: titleMetrics.font
                            verticalAlignment: Text.AlignVCenter
                        }

                        NumberAnimation on x {
                            id: titleSmoothAnim
                            from: 0
                            to: -(titleMetrics.advanceWidth + titleSmoothRow.spacing)
                            duration: (titleMetrics.advanceWidth + titleSmoothRow.spacing) * (panelMode.scrollingSpeed === 1 ? 40 : (panelMode.scrollingSpeed === 2 ? 60 : 30))
                            loops: Animation.Infinite
                            running: titleSmoothRow.visible
                        }
                    }

                    // Stepped Scroll / Static Layer
                    Text {
                        id: titleSteppedText
                        visible: !titleSmoothRow.visible
                        anchors.fill: parent
                        text: parent.shouldScroll ? _charDisplayText : titleMetrics.text
                        color: Kirigami.Theme.textColor
                        font: titleMetrics.font
                        horizontalAlignment: textColumn.textAlign
                        verticalAlignment: Text.AlignVCenter
                        elide: parent.shouldScroll ? Text.ElideNone : Text.ElideRight

                        property string _charDisplayText: titleMetrics.text
                        property int _scrollIndex: 0
                        property string _scrollBuffer: titleMetrics.text + "   •   "

                        function updateScroll() {
                            _scrollIndex = (_scrollIndex + 1) % _scrollBuffer.length
                            _charDisplayText = _scrollBuffer.substring(_scrollIndex) + _scrollBuffer.substring(0, _scrollIndex)
                        }

                        Timer {
                            interval: panelMode.scrollInterval
                            running: titleSteppedText.visible && titleItem.shouldScroll && !panelMode.smoothScrolling
                            repeat: true
                            onTriggered: titleSteppedText.updateScroll()
                            onRunningChanged: if (!running) titleSteppedText._scrollIndex = 0
                        }
                    }
                }

                // Artist Section
                Item {
                    id: artistItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: artistMetrics.height
                    Layout.alignment: panelMode.layoutMode === 1 ? Qt.AlignRight : (panelMode.layoutMode === 2 ? Qt.AlignHCenter : Qt.AlignLeft)
                    visible: panelMode.showArtist && panelMode.artist && panelMode.artist.trim() !== ""
                    clip: true

                    readonly property bool overflows: artistMetrics.advanceWidth > parent.width
                    readonly property bool shouldScroll: panelMode.scrollingText && overflows

                    // Smooth Scroll Layer
                    Row {
                        id: artistSmoothRow
                        visible: panelMode.smoothScrolling && parent.shouldScroll
                        x: 0
                        spacing: 40
                        
                        Text {
                            text: artistMetrics.text
                            color: Kirigami.Theme.textColor
                            opacity: 0.8
                            font: artistMetrics.font
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: artistMetrics.text
                            color: Kirigami.Theme.textColor
                            opacity: 0.8
                            font: artistMetrics.font
                            verticalAlignment: Text.AlignVCenter
                        }

                        NumberAnimation on x {
                            id: artistSmoothAnim
                            from: 0
                            to: -(artistMetrics.advanceWidth + artistSmoothRow.spacing)
                            duration: (artistMetrics.advanceWidth + artistSmoothRow.spacing) * (panelMode.scrollingSpeed === 1 ? 40 : (panelMode.scrollingSpeed === 2 ? 60 : 30))
                            loops: Animation.Infinite
                            running: artistSmoothRow.visible
                        }
                    }

                    // Stepped Scroll / Static Layer
                    Text {
                        id: artistSteppedText
                        visible: !artistSmoothRow.visible
                        anchors.fill: parent
                        text: parent.shouldScroll ? _charDisplayText : artistMetrics.text
                        color: Kirigami.Theme.textColor
                        opacity: 0.8
                        font: artistMetrics.font
                        horizontalAlignment: textColumn.textAlign
                        verticalAlignment: Text.AlignVCenter
                        elide: parent.shouldScroll ? Text.ElideNone : Text.ElideRight

                        property string _charDisplayText: artistMetrics.text
                        property int _scrollIndex: 0
                        property string _scrollBuffer: artistMetrics.text + "   •   "

                        function updateScroll() {
                            _scrollIndex = (_scrollIndex + 1) % _scrollBuffer.length
                            _charDisplayText = _scrollBuffer.substring(_scrollIndex) + _scrollBuffer.substring(0, _scrollIndex)
                        }

                        Timer {
                            interval: panelMode.scrollInterval
                            running: artistSteppedText.visible && artistItem.shouldScroll && !panelMode.smoothScrolling
                            repeat: true
                            onTriggered: artistSteppedText.updateScroll()
                            onRunningChanged: if (!running) artistSteppedText._scrollIndex = 0
                        }
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
        Loader {
            id: rightControlsLoader
            active: panelMode.showPanelControls && (panelMode.layoutMode === 0 || panelMode.layoutMode === 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Math.min(panelMode.height, 36)
            Layout.preferredWidth: item ? (panelMode.layoutMode === 2 ? Layout.preferredHeight : item.implicitWidth) : 0
            
            sourceComponent: Item {
                implicitWidth: rightControlRow.implicitWidth
                implicitHeight: rightControlRow.implicitHeight
                
                // Full Controls (Left Mode - shows on Right)
                Components.MediaControlRow {
                    id: rightControlRow
                    anchors.centerIn: parent
                    visible: panelMode.layoutMode === 0
                    
                    baseSize: panelMode.calculatedButtonSize
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
                    width: panelMode.calculatedButtonSize
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
        }
    }

    WheelHandler {
        onWheel: (wheel) => {
            if (typeof root !== "undefined" && root.cfg_mouseWheelVolume) {
                var delta = (wheel.angleDelta.y > 0) ? 0.05 : -0.05
                root.adjustVolume(delta)
            }
        }
    }
}
