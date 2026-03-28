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
