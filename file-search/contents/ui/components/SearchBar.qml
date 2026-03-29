import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

/**
 * SearchBar component for file-search, matching app-menu's style.
 * Uses standard Plasma SearchField at the top of the popup.
 */
PlasmaExtras.SearchField {
    id: root
    
    // Properties for compatibility with file-search logic
    property int resultCount: 0
    property var resultsModel: null
    property var logic: null
    property bool rssPlaceholderCycling: true
    
    placeholderText: "" // Hidden to use our animated labels
    
    // Animated Placeholder Logic
    Item {
        id: placeholderContainer
        anchors.fill: parent
        anchors.leftMargin: 36 // Space for search icon
        anchors.rightMargin: 32
        visible: root.text.length === 0
        clip: true
        
        property int currentIndex: 0
        property string defaultText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Arama yapmaya başla...")
        
        // Cache management
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
            if (rssTitles.length > 0) combined = combined.concat(rssTitles)
            return combined
        }
        
        Label {
            id: currentLabel
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: placeholderContainer.allTitles[0] || ""
            elide: Text.ElideRight
            opacity: 0.5
            color: Kirigami.Theme.textColor
            font.pixelSize: root.font.pixelSize
        }
        
        Label {
            id: nextLabel
            anchors.fill: parent
            y: -height
            verticalAlignment: Text.AlignVCenter
            text: ""
            elide: Text.ElideRight
            opacity: 0
            color: Kirigami.Theme.textColor
            font.pixelSize: root.font.pixelSize
        }
        
        ParallelAnimation {
            id: switchAnim
            
            property string targetText: ""
            
            SequentialAnimation {
                PropertyAction { target: nextLabel; property: "text"; value: switchAnim.targetText }
                PropertyAction { target: nextLabel; property: "y"; value: -placeholderContainer.height }
                PropertyAction { target: nextLabel; property: "opacity"; value: 0 }
                
                ParallelAnimation {
                    NumberAnimation { target: currentLabel; property: "y"; to: placeholderContainer.height; duration: 600; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: currentLabel; property: "opacity"; to: 0; duration: 600 }
                    
                    NumberAnimation { target: nextLabel; property: "y"; to: 0; duration: 600; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: nextLabel; property: "opacity"; to: 0.5; duration: 600 }
                }
            }
            
            onFinished: {
                 currentLabel.text = nextLabel.text
                 currentLabel.y = 0
                 currentLabel.opacity = 0.5
                 nextLabel.y = -placeholderContainer.height
                 nextLabel.opacity = 0
            }
        }
        
        Timer {
            interval: 3500
            running: placeholderContainer.visible && placeholderContainer.allTitles.length > 1 && root.rssPlaceholderCycling
            repeat: true
            onTriggered: {
                placeholderContainer.currentIndex = (placeholderContainer.currentIndex + 1) % placeholderContainer.allTitles.length
                switchAnim.targetText = placeholderContainer.allTitles[placeholderContainer.currentIndex]
                switchAnim.restart()
            }
        }
    }
    
    // Signals for navigation and control
    signal textUpdated(string newText)
    signal searchSubmitted(string text, int selectedIndex)
    signal escapePressed()
    signal upPressed()
    signal downPressed()
    signal leftPressed()
    signal rightPressed()
    signal tabPressedSignal()
    signal shiftTabPressedSignal()
    signal viewModeChangeRequested(int mode)
    
    // Ensure text is synced
    onTextChanged: {
        root.textUpdated(text)
    }
    
    onAccepted: {
        if (text.length > 0) {
            root.searchSubmitted(text, 0)
        }
    }
    
    // Keyboard navigation
    Keys.onEscapePressed: {
        root.escapePressed()
    }
    
    Keys.onDownPressed: {
        root.downPressed()
    }
    
    Keys.onUpPressed: {
        root.upPressed()
    }
    
    Keys.onLeftPressed: (event) => {
        if (cursorPosition === 0) {
            root.leftPressed()
            event.accepted = true
        } else {
            event.accepted = false
        }
    }
    
    Keys.onRightPressed: (event) => {
        if (cursorPosition === text.length) {
            root.rightPressed()
            event.accepted = true
        } else {
            event.accepted = false
        }
    }
    
    Keys.onTabPressed: (event) => {
        if (event.modifiers & Qt.ShiftModifier) {
            root.shiftTabPressedSignal()
        } else {
            root.tabPressedSignal()
        }
        event.accepted = true
    }
    
    Keys.onPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_1) {
                root.viewModeChangeRequested(0)
                event.accepted = true
            } else if (event.key === Qt.Key_2) {
                root.viewModeChangeRequested(1)
                event.accepted = true
            }
        }
    }
    
    // Focus helper
    function focusInput() {
        forceActiveFocus()
    }
    
    function setText(newText) {
        text = newText
    }
    
    function clear() {
        text = ""
    }
}
