import QtQuick
import QtQuick.Controls

// Hidden Search Input - Captures keyboard focus in non-button modes
TextField {
    id: hiddenInput
    
    // Signals (renamed to avoid conflict with property change signals)
    signal textUpdated(string newText)
    signal searchSubmitted(int selectedIndex)
    signal escapePressed()
    signal upPressed()
    signal downPressed()
    signal tabPressedSignal()
    signal shiftTabPressedSignal()
    signal leftPressed()
    signal rightPressed()
    signal viewModeChangeRequested(int mode)
    
    // For referencing result count
    property int resultCount: 0
    property int currentIndex: 0
    
    width: 1
    height: 1
    opacity: 0
    activeFocusOnPress: true
    
    onTextChanged: {
        hiddenInput.textUpdated(text)
    }
    
    onAccepted: {
        if (resultCount > 0) {
            var idx = currentIndex >= 0 ? currentIndex : 0
            hiddenInput.searchSubmitted(idx)
        }
    }
    
    Keys.onEscapePressed: {
        hiddenInput.escapePressed()
    }
    
    Keys.onDownPressed: {
        hiddenInput.downPressed()
    }
    
    Keys.onUpPressed: {
        hiddenInput.upPressed()
    }
    
    Keys.onLeftPressed: {
        hiddenInput.leftPressed()
    }
    
    Keys.onRightPressed: {
        hiddenInput.rightPressed()
    }
    
    Keys.onTabPressed: (event) => {
        if (event.modifiers & Qt.ShiftModifier) {
            hiddenInput.shiftTabPressedSignal()
        } else {
            hiddenInput.tabPressedSignal()
        }
        event.accepted = true
    }
    
    Keys.onPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_1) {
                hiddenInput.viewModeChangeRequested(0)
                event.accepted = true
            } else if (event.key === Qt.Key_2) {
                hiddenInput.viewModeChangeRequested(1)
                event.accepted = true
            }
        }
    }
    
    // Force focus
    function focus() {
        forceActiveFocus()
    }
    
    // Clear and focus
    function clearAndFocus() {
        text = ""
        forceActiveFocus()
        selectAll()
    }
}
