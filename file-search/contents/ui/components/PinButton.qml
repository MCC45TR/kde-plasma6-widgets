import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

// PinButton - Reusable pin/unpin toggle button
Item {
    id: pinButton
    
    width: 24
    height: 24
    
    // State
    property bool isPinned: false
    property color accentColor: Kirigami.Theme.highlightColor
    property color textColor: Kirigami.Theme.textColor
    
    // Localization function
    // Localization function property removed
    
    // Signals
    signal toggled(bool pinned)
    
    Rectangle {
        id: background
        anchors.fill: parent
        radius: width / 2
        color: pinButton.isPinned 
            ? Qt.rgba(pinButton.accentColor.r, pinButton.accentColor.g, pinButton.accentColor.b, 0.2)
            : (mouseArea.containsMouse ? Qt.rgba(pinButton.textColor.r, pinButton.textColor.g, pinButton.textColor.b, 0.1) : "transparent")
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    Kirigami.Icon {
        id: pinIcon
        anchors.centerIn: parent
        width: 16
        height: 16
        source: pinButton.isPinned ? "pin" : "pin-off"
        color: pinButton.isPinned ? pinButton.accentColor : Qt.rgba(pinButton.textColor.r, pinButton.textColor.g, pinButton.textColor.b, 0.6)
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        
        // Rotation animation on pin
        rotation: pinButton.isPinned ? 0 : -45
        Behavior on rotation {
            RotationAnimation { duration: 200; easing.type: Easing.OutBack }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            pinButton.toggled(!pinButton.isPinned)
        }
    }
    
    ToolTip {
        visible: mouseArea.containsMouse
        text: pinButton.isPinned ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Unpin") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Pin")
        delay: 500
    }
}
