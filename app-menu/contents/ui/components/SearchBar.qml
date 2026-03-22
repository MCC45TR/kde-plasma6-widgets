import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

PlasmaExtras.SearchField {
    id: root
    
    signal textChangedEvent(string query)
    signal escapePressed()
    signal enterPressed()
    
    placeholderText: i18n("Search applications, files & settings...")
    
    onTextChanged: root.textChangedEvent(text)
    
    Keys.onEscapePressed: {
        text = ""
        root.escapePressed()
        event.accepted = true
    }
    
    Keys.onReturnPressed: {
        root.enterPressed()
        event.accepted = true
    }
    
    // Quick focus behavior
    Component.onCompleted: {
        forceActiveFocus()
    }
}
