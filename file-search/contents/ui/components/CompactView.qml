import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Compact panel representation for the File Search widget
Item {
    id: compactRoot
    
    // Required properties from parent
    required property bool isButtonMode
    required property bool isWideMode
    required property bool isExtraWideMode
    required property bool expanded
    required property string truncatedText
    required property int responsiveFontSize
    required property color bgColor
    required property color textColor
    required property color accentColor
    required property int searchTextLength
    required property int panelRadius
    required property int panelHeight
    required property bool showSearchButton
    required property bool showSearchButtonBackground
    // New properties for animated ticker
    property var logic: null
    property bool rssPlaceholderCycling: true
    
    // Signals
    signal toggleExpanded()
    
    // Button Mode - icon only (no background)
    Kirigami.Icon {
        id: buttonModeIcon
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        source: "plasma-search"
        color: compactRoot.textColor
        visible: compactRoot.isButtonMode
        
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onEntered: buttonModeIcon.color = compactRoot.accentColor
            onExited: buttonModeIcon.color = compactRoot.textColor
            
            onClicked: compactRoot.toggleExpanded()
        }
    }

    // Animated Ticker Logic (Shared with SearchBar)
    Item {
        id: tickerContainer
        anchors.left: mainButton.left
        anchors.right: searchIconButton.left
        anchors.top: mainButton.top
        anchors.bottom: mainButton.bottom
        anchors.leftMargin: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? 10 : 0
        anchors.rightMargin: 6
        visible: !compactRoot.isButtonMode && compactRoot.searchTextLength === 0
        clip: true
        
        property int currentIndex: 0
        property string defaultText: compactRoot.isExtraWideMode ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Arama yapmaya başla...") : (compactRoot.isWideMode ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Search...") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Search"))
        
        property var rssTitles: {
            var list = []
            var cache = (logic && logic.rssCache) ? logic.rssCache : []
            if (rssPlaceholderCycling && cache.length > 0) {
                var count = 0
                for (var i = 0; i < cache.length && count < 8; i++) {
                    var title = cache[i].display
                    if (title && title.length < 50 && title.length > 3 && title !== defaultText) {
                        list.push(title)
                        count++
                    }
                }
            }
            return list
        }
        
        property var allTitles: {
            var combined = [defaultText]
            if (rssTitles.length > 0) {
                // Interleave defaultText and RSS titles if requested
                var interleaved = []
                for (var i = 0; i < rssTitles.length; i++) {
                    interleaved.push(defaultText)
                    interleaved.push(rssTitles[i])
                }
                return interleaved
            }
            return combined
        }
        
        Label {
            id: currentLabel
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? Text.AlignLeft : Text.AlignHCenter
            text: tickerContainer.allTitles[0] || ""
            elide: Text.ElideRight
            opacity: 0.6
            color: compactRoot.textColor
            font.pixelSize: compactRoot.responsiveFontSize
            font.family: "Roboto Condensed"
        }
        
        Label {
            id: nextLabel
            anchors.fill: parent
            y: -height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: currentLabel.horizontalAlignment
            text: ""
            elide: Text.ElideRight
            opacity: 0
            color: compactRoot.textColor
            font.pixelSize: compactRoot.responsiveFontSize
            font.family: "Roboto Condensed"
        }
        
        ParallelAnimation {
            id: switchAnim
            
            property string targetText: ""
            
            SequentialAnimation {
                PropertyAction { target: nextLabel; property: "text"; value: switchAnim.targetText }
                PropertyAction { target: nextLabel; property: "y"; value: -tickerContainer.height }
                PropertyAction { target: nextLabel; property: "opacity"; value: 0 }
                
                ParallelAnimation {
                    NumberAnimation { target: currentLabel; property: "y"; to: tickerContainer.height; duration: 600; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: currentLabel; property: "opacity"; to: 0; duration: 600 }
                    
                    NumberAnimation { target: nextLabel; property: "y"; to: 0; duration: 600; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: nextLabel; property: "opacity"; to: 0.6; duration: 600 }
                }
            }
            
            onFinished: {
                 currentLabel.text = nextLabel.text
                 currentLabel.y = 0
                 currentLabel.opacity = 0.6
                 nextLabel.y = -tickerContainer.height
                 nextLabel.opacity = 0
            }
        }
        
        Timer {
            interval: 3500
            running: tickerContainer.visible && tickerContainer.allTitles.length > 1 && compactRoot.rssPlaceholderCycling
            repeat: true
            onTriggered: {
                tickerContainer.currentIndex = (tickerContainer.currentIndex + 1) % tickerContainer.allTitles.length
                switchAnim.targetText = tickerContainer.allTitles[tickerContainer.currentIndex]
                switchAnim.restart()
            }
        }
    }
    
    // Main Button Container (for non-button modes)
    Rectangle {
        id: mainButton
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: compactRoot.panelHeight > 0 ? compactRoot.panelHeight : parent.height
        radius: compactRoot.panelRadius === 0 ? height / 2 : (compactRoot.panelRadius === 1 ? 12 : (compactRoot.panelRadius === 2 ? 6 : 0))
        color: Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 0.95)
        visible: !compactRoot.isButtonMode
        
        // Border for definition
        border.width: 1
        border.color: compactRoot.expanded ? compactRoot.accentColor : Qt.rgba(compactRoot.textColor.r, compactRoot.textColor.g, compactRoot.textColor.b, 0.1)
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? 10 : 0
            anchors.rightMargin: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? (compactRoot.showSearchButton ? 4 : 10) : 0
            spacing: 6
            
            // Display text (Static when searching, Hidden when ticker is running)
            Text {
                id: displayText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: compactRoot.truncatedText
                color: compactRoot.textColor
                font.pixelSize: compactRoot.responsiveFontSize
                font.family: "Roboto Condensed"
                horizontalAlignment: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                visible: compactRoot.searchTextLength > 0 // Only show static text when user is typing
            }
            
            // Search Icon Button (Wide and Extra Wide Mode only)
            Rectangle {
                id: searchIconButton
                Layout.preferredWidth: ((compactRoot.isWideMode || compactRoot.isExtraWideMode) && compactRoot.showSearchButton) ? (mainButton.height - 6) : 0
                Layout.preferredHeight: mainButton.height - 6
                Layout.alignment: Qt.AlignVCenter
                radius: compactRoot.panelRadius === 0 ? width / 2 : (compactRoot.panelRadius === 1 ? 8 : (compactRoot.panelRadius === 2 ? 4 : 0))
                color: compactRoot.showSearchButtonBackground ? compactRoot.accentColor : "transparent"
                visible: (compactRoot.isWideMode || compactRoot.isExtraWideMode) && compactRoot.showSearchButton
                
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.55
                    height: width
                    source: "search"
                    color: compactRoot.showSearchButtonBackground ? "#ffffff" : compactRoot.textColor
                }
            }
        }
        
        // Click handler - opens popup
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onEntered: mainButton.color = Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 1.0)
            onExited: mainButton.color = Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 0.95)
            
            onClicked: compactRoot.toggleExpanded()
        }
    }
}
