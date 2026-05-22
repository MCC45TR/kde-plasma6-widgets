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
    property int rssFrequency: 3
    property bool rssShowFullHeadline: true
    property bool rssShowSource: false
    
    placeholderText: "" // Hidden to use our animated labels
    
    // Animated Placeholder Logic
    RssTicker {
        id: placeholderContainer
        anchors.fill: parent
        anchors.leftMargin: 36 // Space for search icon
        anchors.rightMargin: 32
        visible: root.text.length === 0
        
        logic: root.logic
        rssFrequency: root.rssFrequency
        rssPlaceholderCycling: root.rssPlaceholderCycling
        rssShowFullHeadline: root.rssShowFullHeadline
        rssShowSource: root.rssShowSource
        maxChars: 100 // fallback
        
        textColor: Kirigami.Theme.textColor
        fontSize: root.font.pixelSize
        fontFamily: root.font.family
        defaultText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Start searching...")
        horizontalAlignment: Text.AlignLeft
        
        rightMarginValue: searchIconRight.width + 24
        textOpacity: 0.35
        isSearching: root.text.length > 0
    }
    
    Kirigami.Icon {
        id: searchIconRight
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        source: "plasma-search"
        color: Kirigami.Theme.textColor
        opacity: root.text.length === 0 ? 0.35 : 0.7
        Behavior on opacity { NumberAnimation { duration: 250 } }
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
