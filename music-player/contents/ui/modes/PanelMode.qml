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
    property int maxWidth: 350
    property int scrollingSpeed: 0 // 0: Fast, 1: Medium, 2: Slow
    
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
    
    RowLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: panelMode.layoutMode === 2 ? 5 : 10
        layoutDirection: Qt.LeftToRight
        
        // --- RIGHT ALIGN SPACER (Right/Center Mode) ---
        Item {
            visible: panelMode.layoutMode === 1 || panelMode.layoutMode === 2
            Layout.fillWidth: true
        }

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
        }

        // --- TEXT GROUP ---
        Item {
            id: textContainer
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            clip: true
            
            implicitHeight: textColumn.implicitHeight
            
            ColumnLayout {
                id: textColumn
                anchors.centerIn: parent
                width: parent.width
                spacing: 0
                
                // Font Logic - Cached
                readonly property int calculatedPixelSize: panelMode.autoFontSize 
                    ? Math.max(10, Math.min(panelMode.height * 0.5, 16)) 
                    : panelMode.manualFontSize
                
                readonly property int artistPixelSize: panelMode.autoFontSize
                    ? Math.max(9, Math.min(panelMode.height * 0.4, 13))
                    : Math.max(9, panelMode.manualFontSize - 2)
                
                // Text Alignment - Cached
                readonly property int textAlign: {
                    if (panelMode.layoutMode === 1) return Text.AlignRight
                    if (panelMode.layoutMode === 2) return Text.AlignHCenter
                    return Text.AlignLeft
                }
                
                // Title Text with optimized scrolling
                Text {
                    id: titleText
                    text: _displayText
                    color: Kirigami.Theme.textColor
                    font.family: "Roboto Condensed"
                    font.bold: true
                    font.pixelSize: parent.calculatedPixelSize
                    elide: _shouldScroll ? Text.ElideNone : Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: parent.textAlign
                    verticalAlignment: Text.AlignVCenter
                    visible: panelMode.showTitle
                    
                    // Scrolling Logic - Optimized
                    property string fullText: panelMode.title || i18n("No Media")
                    property string _displayText: fullText
                    property bool _shouldScroll: false
                    property int _scrollIndex: 0
                    property string _scrollBuffer: ""
                    
                    // Lazy text measurement - only measure when needed
                    readonly property real measuredWidth: _textMetrics.advanceWidth
                    readonly property bool textOverflows: panelMode.scrollingText && measuredWidth > textContainer.width && textContainer.width > 0
                    
                    TextMetrics {
                        id: _textMetrics
                        font: titleText.font
                        text: titleText.fullText
                    }
                    
                    function startScrolling() {
                        if (!_shouldScroll && textOverflows) {
                            _shouldScroll = true
                            _scrollIndex = 0
                            _scrollBuffer = fullText + "   •   "
                            _displayText = _scrollBuffer
                        }
                    }
                    
                    function stopScrolling() {
                        _shouldScroll = false
                        _scrollIndex = 0
                        _displayText = fullText
                    }
                    
                    function updateScroll() {
                        if (!_shouldScroll) return
                        _scrollIndex = (_scrollIndex + 1) % _scrollBuffer.length
                        _displayText = _scrollBuffer.substring(_scrollIndex) + _scrollBuffer.substring(0, _scrollIndex)
                    }
                    
                    onTextOverflowsChanged: {
                        if (textOverflows) {
                            Qt.callLater(startScrolling)
                        } else {
                            stopScrolling()
                        }
                    }
                    
                    onFullTextChanged: {
                        stopScrolling()
                        Qt.callLater(() => { if (textOverflows) startScrolling() })
                    }
                    
                    Connections {
                        target: panelMode
                        function onScrollingTextChanged() { 
                            if (panelMode.scrollingText) {
                                Qt.callLater(() => { if (titleText.textOverflows) titleText.startScrolling() })
                            } else {
                                titleText.stopScrolling()
                            }
                        }
                    }
                    
                    Connections {
                        target: textContainer
                        function onWidthChanged() {
                            if (titleText.textOverflows && !titleText._shouldScroll) {
                                Qt.callLater(titleText.startScrolling)
                            } else if (!titleText.textOverflows && titleText._shouldScroll) {
                                titleText.stopScrolling()
                            }
                        }
                    }
                    
                    Timer {
                        interval: panelMode.scrollInterval
                        running: titleText._shouldScroll && panelMode.scrollingText
                        repeat: true
                        onTriggered: titleText.updateScroll()
                    }
                }
                
                // Artist Text with optimized scrolling
                Text {
                    id: artistText
                    text: _displayText
                    color: Kirigami.Theme.textColor
                    opacity: 0.8
                    font.family: "Roboto Condensed"
                    font.pixelSize: parent.artistPixelSize
                    elide: _shouldScroll ? Text.ElideNone : Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: parent.textAlign
                    verticalAlignment: Text.AlignVCenter
                    visible: panelMode.showArtist && panelMode.artist && panelMode.artist.trim() !== ""
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    Layout.minimumHeight: 0
                    Layout.maximumHeight: visible ? implicitHeight : 0
                    
                    // Scrolling Logic - Optimized
                    property string fullText: panelMode.artist || ""
                    property string _displayText: fullText
                    property bool _shouldScroll: false
                    property int _scrollIndex: 0
                    property string _scrollBuffer: ""
                    
                    // Lazy text measurement
                    readonly property real measuredWidth: _artistMetrics.advanceWidth
                    readonly property bool textOverflows: panelMode.scrollingText && measuredWidth > textContainer.width && textContainer.width > 0
                    
                    TextMetrics {
                        id: _artistMetrics
                        font: artistText.font
                        text: artistText.fullText
                    }
                    
                    function startScrolling() {
                        if (!_shouldScroll && textOverflows) {
                            _shouldScroll = true
                            _scrollIndex = 0
                            _scrollBuffer = fullText + "   •   "
                            _displayText = _scrollBuffer
                        }
                    }
                    
                    function stopScrolling() {
                        _shouldScroll = false
                        _scrollIndex = 0
                        _displayText = fullText
                    }
                    
                    function updateScroll() {
                        if (!_shouldScroll) return
                        _scrollIndex = (_scrollIndex + 1) % _scrollBuffer.length
                        _displayText = _scrollBuffer.substring(_scrollIndex) + _scrollBuffer.substring(0, _scrollIndex)
                    }
                    
                    onTextOverflowsChanged: {
                        if (textOverflows) {
                            Qt.callLater(startScrolling)
                        } else {
                            stopScrolling()
                        }
                    }
                    
                    onFullTextChanged: {
                        stopScrolling()
                        Qt.callLater(() => { if (textOverflows) startScrolling() })
                    }
                    
                    Connections {
                        target: panelMode
                        function onScrollingTextChanged() { 
                            if (panelMode.scrollingText) {
                                Qt.callLater(() => { if (artistText.textOverflows) artistText.startScrolling() })
                            } else {
                                artistText.stopScrolling()
                            }
                        }
                    }
                    
                    Connections {
                        target: textContainer
                        function onWidthChanged() {
                            if (artistText.textOverflows && !artistText._shouldScroll) {
                                Qt.callLater(artistText.startScrolling)
                            } else if (!artistText.textOverflows && artistText._shouldScroll) {
                                artistText.stopScrolling()
                            }
                        }
                    }
                    
                    Timer {
                        interval: panelMode.scrollInterval
                        running: artistText._shouldScroll && panelMode.scrollingText && artistText.visible
                        repeat: true
                        onTriggered: artistText.updateScroll()
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
        }

        // --- LEFT ALIGN SPACER (Left/Center Mode) ---
        Item {
            visible: panelMode.layoutMode === 0 || panelMode.layoutMode === 2
            Layout.fillWidth: true
        }
    }
}
